$org = "IowaComputerGurus"
$templateRoot = "C:\Dev\org-standards\templates"
$targetFile = ".editorconfig"
$branchName = "standardize-editorconfig"

$repos = gh repo list $org --limit 200 --json nameWithOwner,isArchived |
    ConvertFrom-Json |
    Where-Object { -not $_.isArchived }

foreach ($repo in $repos) {
    $repoName = $repo.nameWithOwner
    $localPath = "C:\Temp\repo-sync\$($repo.nameWithOwner.Replace('/','-'))"

    Write-Host ""
    Write-Host "Checking $repoName" -ForegroundColor Cyan

    if (Test-Path $localPath) {
        Push-Location $localPath
        git fetch --all --prune
        git checkout default 2>$null
        git pull
    }
    else {
        gh repo clone $repoName $localPath
        Push-Location $localPath
    }

    $defaultBranch = gh repo view $repoName --json defaultBranchRef --jq ".defaultBranchRef.name"

    git checkout $defaultBranch
    git pull

    $sourceFile = Join-Path $templateRoot $targetFile
    $destinationFile = Join-Path $localPath $targetFile

    $needsUpdate = $true

    if (Test-Path $destinationFile) {
        $sourceHash = Get-FileHash $sourceFile -Algorithm SHA256
        $destHash = Get-FileHash $destinationFile -Algorithm SHA256
        $needsUpdate = $sourceHash.Hash -ne $destHash.Hash
    }

    if (-not $needsUpdate) {
        Write-Host "Already matches template. Skipping." -ForegroundColor Green
        Pop-Location
        continue
    }

    $choice = Read-Host "File differs or is missing. Create PR? [y/N]"
    if ($choice -ne "y") {
        Pop-Location
        continue
    }

    git checkout -B $branchName

    New-Item -ItemType Directory -Force -Path (Split-Path $destinationFile) | Out-Null
    Copy-Item $sourceFile $destinationFile -Force

    git add $targetFile

    if (-not (git status --porcelain)) {
        Write-Host "No changes after copy. Skipping."
        Pop-Location
        continue
    }

    git commit -m "Standardize $targetFile"
    git push --set-upstream origin $branchName --force-with-lease

    gh pr create `
        --repo $repoName `
        --base $defaultBranch `
        --head $branchName `
        --title "Standardize $targetFile" `
        --body "Updates `$targetFile` to match the organization-approved template."

    Pop-Location
}
