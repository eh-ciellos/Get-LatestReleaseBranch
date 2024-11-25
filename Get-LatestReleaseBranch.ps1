Param(
    [Parameter(Mandatory = $true)]
    [string] $GH_TOKEN,
    [Parameter()]
    [string] $REPO
)

function Get-LatestReleaseBranch {
    $ErrorActionPreference = "Stop"
    Set-StrictMode -Version 2.0

    # Authenticate GitHub CLI
    $env:GITHUB_TOKEN = $GH_TOKEN
    $GH_TOKEN | gh auth login --with-token

    try {
        # Fetch branches and filter for "release/*"
        $branches = gh api repos/$REPO/branches | ConvertFrom-Json | Where-Object { $_.name -match '^release/[^/]+$' }
        
        if ($branches.Count -eq 0) {
            Write-Host "Error: No branches starting with 'release/' found."
            Add-Content -Path $env:GITHUB_OUTPUT -Value "latestRelease="
            exit 1
        }
        
        # Get the latest branch by commit date
        $latestBranches = foreach ($branch in $branches) {
            $commit = gh api repos/$REPO/commits/$($branch.name) | ConvertFrom-Json
            [PSCustomObject]@{
                Branch = $branch.name
                Date = $commit.commit.committer.date
            }
        }
        $latestBranch = $latestBranches | Sort-Object Date -Descending | Select-Object -First 1
        
        if (-not $latestBranch) {
            Write-Host "Error: No commit data found for release branches."
            Add-Content -Path $env:GITHUB_OUTPUT -Value "latestRelease="
            exit 1
        }
        
        $latestReleaseBranch = $latestBranch.Branch
        Add-Content -Path $env:GITHUB_OUTPUT -Value "latestRelease=$latestReleaseBranch"
        Write-Output "Latest release branch is: $latestReleaseBranch"
    } catch {
        Write-Host "::error::An unexpected error occurred: $_"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "latestRelease="
        exit 1
    }
}

Get-LatestReleaseBranch -GH_TOKEN $GH_TOKEN -REPO $REPO
