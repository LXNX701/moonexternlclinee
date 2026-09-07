# Script to push Moon Place to GitHub
# Run this script after setting up your GitHub token

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "external-cline",
    
    [Parameter(Mandatory=$false)]
    [string]$Username = ""
)

if ([string]::IsNullOrEmpty($Username)) {
    Write-Host "Enter your GitHub username:" -ForegroundColor Yellow
    $Username = Read-Host
}

Write-Host "`n=== Moon Place GitHub Uploader ===" -ForegroundColor Cyan
Write-Host "Repository: $Username/$RepoName" -ForegroundColor White

# Set remote
$remoteUrl = "https://${GitHubToken}@github.com/${Username}/${RepoName}.git"

Write-Host "`n[1/4] Adding remote origin..." -ForegroundColor Green
git remote add origin $remoteUrl 2>$null
git remote set-url origin $remoteUrl

Write-Host "[2/4] Verifying files..." -ForegroundColor Green
$files = git ls-files
Write-Host "Total files: $($files.Count)" -ForegroundColor White

# Check for sensitive files
$sensitiveFiles = $files | Where-Object { $_ -match "GoogleService-Info\.plist$" -and $_ -notmatch "\.example$" }
if ($sensitiveFiles) {
    Write-Host "`nWARNING: Sensitive files detected!" -ForegroundColor Red
    $sensitiveFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "These should NOT be committed!" -ForegroundColor Red
    exit 1
}

Write-Host "[3/4] Creating GitHub repository..." -ForegroundColor Green
$body = @{
    name = $RepoName
    description = "Moon Place - iOS App with Firebase Auth and Premium UI"
    private = $false
    has_issues = $true
    has_projects = $true
    has_wiki = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
        -Method Post `
        -Headers @{
            Authorization = "token $GitHubToken"
            Accept = "application/vnd.github.v3+json"
        } `
        -Body $body `
        -ContentType "application/json"
    
    Write-Host "Repository created: $($response.html_url)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "Error: Invalid GitHub token!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Repository may already exist, continuing..." -ForegroundColor Yellow
}

Write-Host "[4/4] Pushing to GitHub..." -ForegroundColor Green
git branch -M main
git push -u origin main

Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
Write-Host "Repository uploaded to: https://github.com/$Username/$RepoName" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor White
Write-Host "1. Go to repository Settings > Secrets > Actions" -ForegroundColor White
Write-Host "2. Add GOOGLE_SERVICE_INFO_PLIST secret with your Firebase config" -ForegroundColor White
Write-Host "3. The GitHub Actions workflow will build automatically on push" -ForegroundColor White