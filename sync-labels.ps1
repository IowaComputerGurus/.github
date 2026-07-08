param(
    [Parameter(Mandatory = $true)]
    [string]$Org,

    [switch]$Apply
)

$labels = Get-Content ".\labels.yml" | ConvertFrom-Yaml

$repos = gh repo list $Org --limit 1000 --json name,isArchived |
    ConvertFrom-Json |
    Where-Object { -not $_.isArchived }

foreach ($repo in $repos) {
    $fullRepo = "$Org/$($repo.name)"
    Write-Host "`nRepository: $fullRepo"

    foreach ($label in $labels) {
        $name = $label.name
        $color = $label.color
        $description = $label.description

        if ($Apply) {
            gh label create $name `
                --repo $fullRepo `
                --color $color `
                --description $description `
                --force
        }
        else {
            Write-Host "Would ensure label '$name' color=$color"
        }
    }
}
