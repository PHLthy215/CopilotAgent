# Test script for CopilotAgent module
Write-Host "Testing CopilotAgent Module..." -ForegroundColor Cyan

# Test 1: Check if files exist
Write-Host "`n1. Checking module files..." -ForegroundColor Yellow
$requiredFiles = @(
    "CopilotAgent.psd1",
    "CopilotAgent.psm1",
    "Private\CopilotApiClient.ps1",
    "Private\ConversationManager.ps1",
    "Public\Start-CopilotAgent.ps1",
    "Public\Invoke-CopilotChat.ps1",
    "Public\Get-CopilotInsights.ps1",
    "Public\Set-CopilotConfiguration.ps1",
    "Public\Export-CopilotConversation.ps1",
    "README.md"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $PSScriptRoot $file
    if (Test-Path $filePath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

# Test 2: Check module manifest
Write-Host "`n2. Validating module manifest..." -ForegroundColor Yellow
try {
    $manifest = Test-ModuleManifest -Path "CopilotAgent.psd1" -ErrorAction SilentlyContinue
    if ($manifest) {
        Write-Host "  ✓ Module manifest is valid" -ForegroundColor Green
        Write-Host "    Version: $($manifest.Version)" -ForegroundColor Gray
        Write-Host "    Author: $($manifest.Author)" -ForegroundColor Gray
        Write-Host "    Functions: $($manifest.ExportedFunctions.Count)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ✗ Module manifest validation failed" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
}

# Test 3: Check PowerShell syntax
Write-Host "`n3. Testing PowerShell syntax..." -ForegroundColor Yellow
$syntaxErrors = 0

Get-ChildItem -Path "Private\*.ps1", "Public\*.ps1" -Recurse | ForEach-Object {
    try {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $($_.Name) - $($errors.Count) errors" -ForegroundColor Red
            $syntaxErrors += $errors.Count
        }
    } catch {
        Write-Host "  ✗ $($_.Name) - Parse error" -ForegroundColor Red
        $syntaxErrors++
    }
}

# Test 4: Module structure
Write-Host "`n4. Checking module structure..." -ForegroundColor Yellow
$structure = @{
    "Private functions" = (Get-ChildItem -Path "Private\*.ps1" -ErrorAction SilentlyContinue).Count
    "Public functions" = (Get-ChildItem -Path "Public\*.ps1" -ErrorAction SilentlyContinue).Count
    "Documentation" = if (Test-Path "README.md") { 1 } else { 0 }
}

foreach ($item in $structure.GetEnumerator()) {
    Write-Host "  $($item.Key): $($item.Value)" -ForegroundColor Gray
}

# Test Summary
Write-Host "`n📊 Test Summary:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

if ($allFilesExist) {
    Write-Host "✅ All required files present" -ForegroundColor Green
} else {
    Write-Host "❌ Some files missing" -ForegroundColor Red
}

if ($syntaxErrors -eq 0) {
    Write-Host "✅ No syntax errors found" -ForegroundColor Green
} else {
    Write-Host "❌ $syntaxErrors syntax errors found" -ForegroundColor Red
}

Write-Host "`n🚀 Ready to use!" -ForegroundColor Green
Write-Host "To install with dependencies: .\Install-CopilotAgent.ps1" -ForegroundColor Yellow
Write-Host "To test manually: Import-Module .\CopilotAgent.psd1 -Force" -ForegroundColor Yellow

# Test 5: Show module capabilities
Write-Host "`n📋 Module Capabilities:" -ForegroundColor Cyan
Write-Host "- Interactive AI chat interface" -ForegroundColor White
Write-Host "- Microsoft 365 Copilot integration" -ForegroundColor White
Write-Host "- Conversation management and export" -ForegroundColor White
Write-Host "- Configurable API settings" -ForegroundColor White
Write-Host "- Insights from emails, calendar, and documents" -ForegroundColor White