Write-Host "Testing CopilotAgent Module Files..." -ForegroundColor Cyan

# Check if main files exist
$files = @(
    "CopilotAgent.psd1",
    "CopilotAgent.psm1",
    "README.md"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing" -ForegroundColor Red
    }
}

# Check directories
$dirs = @("Private", "Public")
foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        $fileCount = (Get-ChildItem -Path "$dir\*.ps1").Count
        Write-Host "✅ $dir directory ($fileCount files)" -ForegroundColor Green
    } else {
        Write-Host "❌ $dir directory missing" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Module structure looks good!" -ForegroundColor Green
Write-Host "To install: .\Install-Simple.ps1" -ForegroundColor Yellow