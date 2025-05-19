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
$env:GITHUB_TOKEN = $GH_TOKEN  # GitHub CLI also recognizes GITHUB_TOKEN
$env:GH_TOKEN = $GH_TOKEN      # Set both to be safe

try {
    # Verify token works with a simple command
    Write-Host "Testing GitHub token..."
    gh auth status -t
    
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub token authentication failed. Please check token permissions."
    }
    
    # List all branches using REST API to avoid potential CLI issues
    Write-Host "Fetching branches via GitHub API..."
    $branchesRaw = gh api "repos/$REPO/branches" --paginate

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to fetch branches: $branchesRaw"
    }
    
    $branches = $branchesRaw | ConvertFrom-Json
    
    # Filter release branches
    Write-Host "Filtering release branches..."
    $releaseBranches = $branches | 
        Where-Object { $_.name -match '^release\/\d+\.\d+' } | 
        ForEach-Object {
            if ($_.name -match 'release\/(\d+)\.(\d+)') {
                [PSCustomObject]@{
                    Name = $_.name
                    Major = [int]$Matches[1]
                    Minor = [int]$Matches[2]
                    SortKey = ([int]$Matches[1]) * 1000 + ([int]$Matches[2])
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
    Write-Output "latestRelease=$latestRelease" >> $env:GITHUB_OUTPUT
    
} catch {
    Write-Host "::error::Error while fetching release branches: $($_.Exception.Message)"
    exit 1
}
