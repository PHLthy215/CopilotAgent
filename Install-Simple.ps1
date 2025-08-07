# Simple installer for CopilotAgent module
param(
    [switch]$Force
)

Write-Host "Installing CopilotAgent PowerShell Module..." -ForegroundColor Cyan

# Get user's Documents path
$documentsPath = [Environment]::GetFolderPath('MyDocuments')
$installPath = Join-Path $documentsPath "WindowsPowerShell\Modules\CopilotAgent"

Write-Host "Installation path: $installPath" -ForegroundColor Yellow

# Create directory if it doesn't exist
if (-not (Test-Path $installPath)) {
    New-Item -Path $installPath -ItemType Directory -Force | Out-Null
    Write-Host "Created module directory" -ForegroundColor Green
}

# Copy files
$sourceFiles = @(
    "CopilotAgent.psd1",
    "CopilotAgent.psm1"
)

foreach ($file in $sourceFiles) {
    $sourcePath = Join-Path $PSScriptRoot $file
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $installPath -Force
        Write-Host "Copied $file" -ForegroundColor Green
    } else {
        Write-Warning "File not found: $file"
    }
}

# Copy directories
$sourceDirs = @("Private", "Public")
foreach ($dir in $sourceDirs) {
    $sourcePath = Join-Path $PSScriptRoot $dir
    $destPath = Join-Path $installPath $dir

    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
        Write-Host "Copied $dir directory" -ForegroundColor Green
    }
}

# Test import
try {
    Import-Module $installPath -Force
    Write-Host "Module installed and imported successfully!" -ForegroundColor Green

    $commands = Get-Command -Module CopilotAgent
    Write-Host "Available commands: $($commands.Count)" -ForegroundColor Cyan
    $commands.Name | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

} catch {
    Write-Error "Failed to import module: $($_.Exception.Message)"
}

Write-Host "`nTo get started, run: Start-CopilotAgent" -ForegroundColor Yellow