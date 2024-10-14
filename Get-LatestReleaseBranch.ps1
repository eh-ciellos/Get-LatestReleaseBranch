Param(
        [Parameter(HelpMessage = "The GitHub Token running the action", Mandatory = $true)]
        [string] $GH_TOKEN,
        [Parameter(HelpMessage = "The GitHub repo name in 'owner/repo' format", Mandatory = $false)]
        [string] $REPO
    )
function Get-LatestReleaseBranch {
    Param(
        [Parameter(HelpMessage = "The GitHub Token running the action", Mandatory = $true)]
        [string] $GH_TOKEN,
        [Parameter(HelpMessage = "The GitHub repo name in 'owner/repo' format", Mandatory = $false)]
        [string] $REPO
    )

    $ErrorActionPreference = "Stop"
    Set-StrictMode -Version 2.0

    # Authenticate GitHub CLI
    $env:GITHUB_TOKEN = $GH_TOKEN
    $GH_TOKEN | gh auth login --with-token
    
    try {
        # Fetch all branches and filter for those starting with "release/"
        $branches = gh api repos/$REPO/branches | ConvertFrom-Json | Where-Object { $_.name -like 'release/*' }
        
        if ($branches.Count -eq 0) {
            return "Error: No branches starting with 'release/' found."
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
            return "Error: No commit data found for release branches."
        }

        # Return the latest release branch name
        return $latestBranch.Branch

    } catch {
        return "Error: An unexpected error occurred: $_"
    }
}

Get-LatestReleaseBranch -GH_TOKEN $GH_TOKEN -REPO $REPO