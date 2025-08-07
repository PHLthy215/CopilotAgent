# GitHub Publication Script for CopilotAgent
param(
    [Parameter(Mandatory)]
    [string]$GitHubUsername,

    [Parameter()]
    [string]$RepositoryName = "CopilotAgent",

    [Parameter()]
    [switch]$Private,

    [Parameter()]
    [string]$Description = "PowerShell Agentic LLM using Microsoft 365 Copilot AI"
)

Write-Host "🚀 Publishing CopilotAgent to GitHub" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "CopilotAgent.psd1")) {
    Write-Error "Please run this script from the CopilotAgent directory"
    exit 1
}

# Check if GitHub CLI is installed
try {
    $ghVersion = gh --version
    Write-Host "✅ GitHub CLI is available: $($ghVersion[0])" -ForegroundColor Green
} catch {
    Write-Error "GitHub CLI (gh) is not installed. Please install it from: https://cli.github.com/"
    exit 1
}

# Initialize git repository if not already done
if (-not (Test-Path ".git")) {
    Write-Host "📁 Initializing Git repository..." -ForegroundColor Yellow
    git init
    git branch -M main
} else {
    Write-Host "✅ Git repository already initialized" -ForegroundColor Green
}

# Create .gitignore if it doesn't exist
if (-not (Test-Path ".gitignore")) {
    Write-Host "📝 Creating .gitignore..." -ForegroundColor Yellow
    @"
# PowerShell
*.ps1xml
*.psd1.backup
*.psm1.backup
TestResults/
*.tmp
*.log

# Windows
Thumbs.db
Desktop.ini
.DS_Store

# IDEs
.vscode/
.idea/
*.swp
*.swo

# Temporary files
temp/
tmp/
*.bak

# Node modules (if any)
node_modules/

# Logs
logs/
*.log
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8
}

# Add all files to git
Write-Host "📦 Adding files to Git..." -ForegroundColor Yellow
git add -A

# Commit if there are changes
$status = git status --porcelain
if ($status) {
    Write-Host "💾 Committing changes..." -ForegroundColor Yellow
    git commit -m "Initial commit: CopilotAgent PowerShell module

- Complete PowerShell module for Microsoft 365 Copilot integration
- Interactive AI chat interface
- Microsoft Graph API integration
- Conversation management and export
- Comprehensive documentation and tests
- Enterprise-ready with logging and diagnostics"
} else {
    Write-Host "✅ No new changes to commit" -ForegroundColor Green
}

# Create GitHub repository
Write-Host "🌐 Creating GitHub repository..." -ForegroundColor Yellow

$visibility = if ($Private) { "private" } else { "public" }
$repoUrl = "https://github.com/$GitHubUsername/$RepositoryName"

try {
    gh repo create "$GitHubUsername/$RepositoryName" --$visibility --description "$Description" --source . --push
    Write-Host "✅ Repository created successfully!" -ForegroundColor Green
    Write-Host "🌐 Repository URL: $repoUrl" -ForegroundColor Cyan
} catch {
    Write-Error "Failed to create repository: $($_.Exception.Message)"
    Write-Host "You may need to authenticate with GitHub CLI first:" -ForegroundColor Yellow
    Write-Host "gh auth login" -ForegroundColor Cyan
    exit 1
}

# Update URLs in module manifest and documentation
Write-Host "🔗 Updating repository URLs..." -ForegroundColor Yellow

# Update CopilotAgent.psd1
$manifestPath = "CopilotAgent.psd1"
$manifest = Get-Content $manifestPath -Raw
$manifest = $manifest -replace 'yourusername/CopilotAgent', "$GitHubUsername/$RepositoryName"
$manifest | Out-File $manifestPath -Encoding UTF8

# Update README.md
$readmePath = "README.md"
$readme = Get-Content $readmePath -Raw
$readme = $readme -replace 'yourusername/CopilotAgent', "$GitHubUsername/$RepositoryName"
$readme | Out-File $readmePath -Encoding UTF8

# Update CHANGELOG.md
$changelogPath = "CHANGELOG.md"
$changelog = Get-Content $changelogPath -Raw
$changelog = $changelog -replace 'yourusername/CopilotAgent', "$GitHubUsername/$RepositoryName"
$changelog | Out-File $changelogPath -Encoding UTF8

# Commit URL updates
git add -A
git commit -m "Update repository URLs to $GitHubUsername/$RepositoryName"
git push

Write-Host "`n🎉 Successfully published to GitHub!" -ForegroundColor Green
Write-Host "Repository: $repoUrl" -ForegroundColor Cyan

# Show next steps
Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Visit your repository: $repoUrl" -ForegroundColor White
Write-Host "2. Enable GitHub Actions (if not already enabled)" -ForegroundColor White
Write-Host "3. Add repository secrets for PowerShell Gallery:" -ForegroundColor White
Write-Host "   - Go to Settings > Secrets and variables > Actions" -ForegroundColor Gray
Write-Host "   - Add PSGALLERY_API_KEY secret" -ForegroundColor Gray
Write-Host "4. Create a release to trigger PowerShell Gallery publication" -ForegroundColor White
Write-Host "5. Share with the PowerShell community!" -ForegroundColor White

Write-Host "`n🔗 Useful Links:" -ForegroundColor Yellow
Write-Host "Repository: $repoUrl" -ForegroundColor Cyan
Write-Host "Issues: $repoUrl/issues" -ForegroundColor Cyan
Write-Host "Actions: $repoUrl/actions" -ForegroundColor Cyan
Write-Host "Releases: $repoUrl/releases" -ForegroundColor Cyan