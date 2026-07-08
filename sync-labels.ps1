param(
    [Parameter(Mandatory = $true)]
    [string]$Org,

    [string]$LabelsFile = ".\labels.json",

    [switch]$Apply,

    [switch]$IncludeArchived,

    [switch]$IncludeForks,

    [string[]]$OnlyRepos = @()
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI 'gh' was not found. Install it and run 'gh auth login'."
}

if (-not (Test-Path $LabelsFile)) {
    throw "Labels file not found: $LabelsFile"
}

$labels = Get-Content $LabelsFile -Raw | ConvertFrom-Json

if (-not $labels -or $labels.Count -eq 0) {
    throw "No labels found in $LabelsFile"
}

foreach ($label in $labels) {
    if (-not $label.name -or -not $label.color) {
        throw "Each label must have at least 'name' and 'color'."
    }

    if ($label.color -notmatch '^[0-9a-fA-F]{6}$') {
        throw "Invalid color '$($label.color)' for label '$($label.name)'. Use 6-character hex without #."
    }
}

Write-Host "Loading repositories for org: $Org"

$repos = gh repo list $Org --limit 1000 --json name,isArchived,isFork |
    ConvertFrom-Json

if (-not $IncludeArchived) {
    $repos = $repos | Where-Object { -not $_.isArchived }
}

if (-not $IncludeForks) {
    $repos = $repos | Where-Object { -not $_.isFork }
}

if ($OnlyRepos.Count -gt 0) {
    $repos = $repos | Where-Object { $OnlyRepos -contains $_.name }
}

$summary = [ordered]@{
    Repositories      = 0
    LabelsProcessed   = 0
    Errors            = 0
}

$desiredLabelNames = $labels.name

Write-Host ""
Write-Host "Mode: $($(if ($Apply) { 'APPLY' } else { 'DRY RUN' }))"
Write-Host "Repositories selected: $($repos.Count)"
Write-Host "Labels configured: $($labels.Count)"
Write-Host ""

foreach ($repo in $repos) {
    $repoFullName = "$Org/$($repo.name)"

    Write-Host ""
    Write-Host "Repository: $repoFullName" -ForegroundColor Cyan

    $choice = Read-Host "Process this repository? [Y]es / [N]o / [Q]uit"

    if ($choice -match '^[Qq]') {
        Write-Host "Stopping at user request."
        break
    }

    if ($choice -notmatch '^[Yy]') {
        Write-Host "Skipped: $repoFullName"
        continue
    }

    $summary.Repositories++

    foreach ($label in $labels) {
        $name = $label.name
        $color = $label.color
        $description = if ($null -ne $label.description) { $label.description } else { "" }

        $summary.LabelsProcessed++

        if ($Apply) {
            try {
                gh label create $name `
                    --repo $repoFullName `
                    --color $color `
                    --description $description `
                    --force | Out-Null

                Write-Host "  ensured: $name"
            }
            catch {
                $summary.Errors++
                Write-Warning "  failed: $name - $($_.Exception.Message)"
            }
        }
        else {
            Write-Host "  would ensure: $name color=$color"
        }
    }
}

Write-Host "Summary"
Write-Host "-------"
Write-Host "Repositories:      $($summary.Repositories)"
Write-Host "Labels processed:  $($summary.LabelsProcessed)"
Write-Host "Errors:            $($summary.Errors)"

if (-not $Apply) {
    Write-Host ""
    Write-Host "Dry run only. Re-run with -Apply to make changes."
}
