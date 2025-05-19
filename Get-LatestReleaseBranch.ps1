param (
    [Parameter(Mandatory=$true)]
    [string]$GH_TOKEN,
    [string]$REPO = $env:GITHUB_REPOSITORY
)

# Ensure REPO is set
if (-not $REPO) {
    throw "Repository not specified. Use -REPO parameter or ensure GITHUB_REPOSITORY environment variable is set."
}

Write-Host "Searching for latest release branch in $REPO"

# Set GitHub CLI token for authentication
$env:GH_TOKEN = $GH_TOKEN

try {
    # List all branches with 'release/' prefix
    $branches = gh api repos/$REPO/branches --jq '.[] | select(.name | startswith("release/")) | .name' 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to fetch branches: $branches"
    }
    
    # Filter and sort release branches
    $releaseBranches = $branches | Where-Object { $_ -match '^release\/\d+\.\d+' } | ForEach-Object { 
        if ($_ -match 'release\/(\d+)\.(\d+)') {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            [PSCustomObject]@{
                Name = $_
                Major = $major
                Minor = $minor
                SortKey = $major * 1000 + $minor
            }
        }
    } | Sort-Object -Property SortKey -Descending
    
    if (-not $releaseBranches -or $releaseBranches.Count -eq 0) {
        Write-Host "No release branches found"
        exit 1
    }
    
    # Get latest release branch
    $latestRelease = $releaseBranches[0].Name
    
    Write-Host "Latest release branch: $latestRelease"
    echo "latestRelease=$latestRelease" >> $env:GITHUB_OUTPUT
    
} catch {
    Write-Host "::error::Error while fetching release branches: $($_.Exception.Message)"
    exit 1
}
