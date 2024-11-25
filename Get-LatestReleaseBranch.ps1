Param(
    [Parameter(HelpMessage = "The GitHub Token running the action", Mandatory = $true)]
    [string] $GH_TOKEN,
    [Parameter(HelpMessage = "The GitHub repo name in 'owner/repo' format", Mandatory = $false)]
    [string] $REPO
)

function Get-LatestReleaseBranch {
    $ErrorActionPreference = "Stop"
    Set-StrictMode -Version 2.0

    # Authenticate GitHub CLI
    $env:GITHUB_TOKEN = $GH_TOKEN
    $GH_TOKEN | gh auth login --with-token

    # Fetch all branches and filter for those starting with "release/"
    $branches = gh api repos/$REPO/branches | ConvertFrom-Json | Where-Object { $_.name -like 'release/*' }

    if ($branches.Count -eq 0) {
        Write-Error "No branches starting with 'release/' found."
    }

    # For each release branch, get the date of the latest commit
    $latestBranches = foreach ($branch in $branches) {
        $commit = gh api repos/$REPO/commits/$($branch.name) | ConvertFrom-Json
        [PSCustomObject]@{
            Branch = $branch.name
            Date = $commit.commit.committer.date
        }
    }

    # Sort the branches by date in descending order and take the latest one
    $latestBranch = $latestBranches | Sort-Object Date -Descending | Select-Object -First 1

    if (-not $latestBranch) {
        Write-Error "No commit data found for release branches."
    }

    $latestReleaseBranch = $latestBranch.Branch

    # Set outputs
    Write-Output "Latest release branch is: $latestReleaseBranch"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "latestRelease=$latestReleaseBranch"
}

Get-LatestReleaseBranch -GH_TOKEN $GH_TOKEN -REPO $REPO
