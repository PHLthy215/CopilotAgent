#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a GitHub repository for CopilotAgent and pushes the code

.DESCRIPTION
    This script creates a new GitHub repository, sets up the remote, and pushes
    the improved CopilotAgent code with all security fixes and enhancements.

.PARAMETER RepositoryName
    Name for the GitHub repository (default: CopilotAgent)

.PARAMETER Description
    Repository description

.PARAMETER Private
    Create a private repository instead of public

.EXAMPLE
    .\create-github-repo.ps1

.EXAMPLE
    .\create-github-repo.ps1 -RepositoryName "my-copilot-agent" -Private
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryName = "CopilotAgent",

    [Parameter()]
    [string]$Description = "PowerShell module for interactive Microsoft 365 Copilot integration with enterprise security, conversation management, and productivity insights.",

    [Parameter()]
    [switch]$Private
)

Write-Host "🚀 Creating GitHub repository for CopilotAgent..." -ForegroundColor Cyan

try {
    # Check if we're in the right directory
    if (-not (Test-Path "CopilotAgent.psd1")) {
        throw "This script must be run from the CopilotAgent directory"
    }

    # Check if gh CLI is available
    $ghVersion = gh --version 2>$null
    if (-not $ghVersion) {
        throw "GitHub CLI (gh) is not installed or not in PATH. Please install it from https://cli.github.com/"
    }

    Write-Host "✅ GitHub CLI found: $($ghVersion[0])" -ForegroundColor Green

    # Check authentication
    Write-Host "🔐 Checking GitHub authentication..." -ForegroundColor Yellow
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Not authenticated with GitHub" -ForegroundColor Red
        Write-Host "Please run: gh auth login" -ForegroundColor Yellow
        Write-Host "Follow the prompts to authenticate with your GitHub account" -ForegroundColor Gray
        exit 1
    }

    Write-Host "✅ GitHub authentication verified" -ForegroundColor Green

    # Create the repository
    Write-Host "📝 Creating GitHub repository: $RepositoryName" -ForegroundColor Yellow

    $repoArgs = @(
        "repo", "create", $RepositoryName,
        "--description", $Description,
        "--source", ".",
        "--push"
    )

    if ($Private) {
        $repoArgs += "--private"
        Write-Host "🔒 Creating private repository" -ForegroundColor Yellow
    } else {
        $repoArgs += "--public"
        Write-Host "🌍 Creating public repository" -ForegroundColor Yellow
    }

    # Execute the repository creation
    & gh @repoArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Repository created successfully!" -ForegroundColor Green

        # Get the repository URL
        $repoUrl = gh repo view --json url --jq .url
        Write-Host "🌐 Repository URL: $repoUrl" -ForegroundColor Cyan

        Write-Host "`n🎉 Success! Your CopilotAgent project has been published to GitHub!" -ForegroundColor Green
        Write-Host "`nNext Steps:" -ForegroundColor Yellow
        Write-Host "1. Visit your repository: $repoUrl" -ForegroundColor White
        Write-Host "2. Add repository topics/tags in GitHub settings" -ForegroundColor White
        Write-Host "3. Configure branch protection rules (recommended)" -ForegroundColor White
        Write-Host "4. Set up GitHub Actions for CI/CD (optional)" -ForegroundColor White
        Write-Host "5. Consider adding issue/PR templates" -ForegroundColor White

        Write-Host "`n📋 Repository Features:" -ForegroundColor Cyan
        Write-Host "✅ Comprehensive README with usage examples" -ForegroundColor Green
        Write-Host "✅ Security documentation and best practices" -ForegroundColor Green
        Write-Host "✅ MIT License for open source usage" -ForegroundColor Green
        Write-Host "✅ Professional PowerShell module structure" -ForegroundColor Green
        Write-Host "✅ Security-first design with privacy protection" -ForegroundColor Green

    } else {
        Write-Error "Failed to create repository. Exit code: $LASTEXITCODE"
        exit 1
    }

} catch {
    Write-Error "Error creating repository: $($_.Exception.Message)"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure you have GitHub CLI installed: https://cli.github.com/" -ForegroundColor Gray
    Write-Host "2. Authenticate with GitHub: gh auth login" -ForegroundColor Gray
    Write-Host "3. Verify you have permission to create repositories" -ForegroundColor Gray
    Write-Host "4. Check your internet connection" -ForegroundColor Gray
    exit 1
}