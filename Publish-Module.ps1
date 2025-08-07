# PowerShell Gallery Publication Script
param(
    [Parameter()]
    [string]$ApiKey,

    [Parameter()]
    [switch]$WhatIf,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host "🚀 PowerShell Gallery Publication Script" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Validate module structure
Write-Host "`n1. Validating module structure..." -ForegroundColor Yellow

$requiredFiles = @(
    'CopilotAgent.psd1',
    'CopilotAgent.psm1',
    'README.md',
    'LICENSE',
    'CHANGELOG.md'
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    } else {
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
}

if ($missingFiles.Count -gt 0) {
    throw "Missing required files: $($missingFiles -join ', ')"
}

# Validate manifest
Write-Host "`n2. Validating module manifest..." -ForegroundColor Yellow

try {
    $manifest = Test-ModuleManifest -Path 'CopilotAgent.psd1'
    Write-Host "  ✓ Module manifest is valid" -ForegroundColor Green
    Write-Host "    Version: $($manifest.Version)" -ForegroundColor Gray
    Write-Host "    Author: $($manifest.Author)" -ForegroundColor Gray
    Write-Host "    Functions: $($manifest.ExportedFunctions.Count)" -ForegroundColor Gray
} catch {
    throw "Module manifest validation failed: $($_.Exception.Message)"
}

# Run PSScriptAnalyzer
Write-Host "`n3. Running PSScriptAnalyzer..." -ForegroundColor Yellow

if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
    $analysisResults = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Warning,Error

    if ($analysisResults.Count -eq 0) {
        Write-Host "  ✓ No issues found" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Found $($analysisResults.Count) issues:" -ForegroundColor Yellow
        $analysisResults | ForEach-Object {
            Write-Host "    $($_.Severity): $($_.Message) ($($_.ScriptName):$($_.Line))" -ForegroundColor Gray
        }

        if (-not $Force) {
            $continue = Read-Host "Continue with publication? (y/N)"
            if ($continue -ne 'y' -and $continue -ne 'Y') {
                throw "Publication cancelled due to PSScriptAnalyzer issues"
            }
        }
    }
} else {
    Write-Warning "PSScriptAnalyzer not installed. Skipping code analysis."
}

# Run tests
Write-Host "`n4. Running Pester tests..." -ForegroundColor Yellow

if ((Get-Module -ListAvailable -Name Pester) -and (Test-Path 'Tests')) {
    try {
        $config = New-PesterConfiguration
        $config.Run.Path = './Tests'
        $config.Output.Verbosity = 'Minimal'

        $testResults = Invoke-Pester -Configuration $config

        if ($testResults.FailedCount -eq 0) {
            Write-Host "  ✓ All tests passed ($($testResults.PassedCount) tests)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $($testResults.FailedCount) tests failed" -ForegroundColor Red

            if (-not $Force) {
                throw "Publication cancelled due to test failures"
            }
        }
    } catch {
        Write-Warning "Test execution failed: $($_.Exception.Message)"
        if (-not $Force) {
            throw "Publication cancelled due to test execution failure"
        }
    }
} else {
    Write-Warning "Pester not installed or Tests directory not found. Skipping tests."
}

# Check for API key
Write-Host "`n5. Validating API key..." -ForegroundColor Yellow

if (-not $ApiKey) {
    $ApiKey = $env:PSGALLERY_API_KEY
}

if (-not $ApiKey) {
    Write-Host "  ⚠️  No API key provided" -ForegroundColor Yellow
    Write-Host "    Set via -ApiKey parameter or PSGALLERY_API_KEY environment variable" -ForegroundColor Gray

    if ($WhatIf) {
        Write-Host "  ✓ WhatIf mode - skipping API key validation" -ForegroundColor Green
    } else {
        $ApiKey = Read-Host "Enter PowerShell Gallery API Key (or press Enter to cancel)"
        if ([string]::IsNullOrEmpty($ApiKey)) {
            throw "API key is required for publication"
        }
    }
} else {
    Write-Host "  ✓ API key provided" -ForegroundColor Green
}

# Publication summary
Write-Host "`n6. Publication Summary:" -ForegroundColor Yellow
Write-Host "   Module: $($manifest.Name)" -ForegroundColor White
Write-Host "   Version: $($manifest.Version)" -ForegroundColor White
Write-Host "   Author: $($manifest.Author)" -ForegroundColor White
Write-Host "   Description: $($manifest.Description)" -ForegroundColor White
Write-Host "   Functions: $($manifest.ExportedFunctions.Keys -join ', ')" -ForegroundColor White

if ($WhatIf) {
    Write-Host "`n🔍 WhatIf Mode - No actual publication will occur" -ForegroundColor Cyan
    Write-Host "`nThe following would be published to PowerShell Gallery:" -ForegroundColor Green
    Write-Host "  Module: CopilotAgent v$($manifest.Version)" -ForegroundColor White
    Write-Host "  Repository: PSGallery" -ForegroundColor White
    Write-Host "`nTo publish for real, run without -WhatIf parameter" -ForegroundColor Yellow
} else {
    # Actual publication
    Write-Host "`n7. Publishing to PowerShell Gallery..." -ForegroundColor Yellow

    try {
        $publishParams = @{
            Path = '.'
            Repository = 'PSGallery'
            NuGetApiKey = $ApiKey
            Verbose = $true
        }

        if ($Force) {
            $publishParams.Force = $true
        }

        Publish-Module @publishParams

        Write-Host "`n🎉 Successfully published CopilotAgent v$($manifest.Version) to PowerShell Gallery!" -ForegroundColor Green
        Write-Host "`nModule will be available at:" -ForegroundColor Cyan
        Write-Host "https://www.powershellgallery.com/packages/CopilotAgent/$($manifest.Version)" -ForegroundColor Blue

        Write-Host "`nUsers can install with:" -ForegroundColor Cyan
        Write-Host "Install-Module -Name CopilotAgent" -ForegroundColor Yellow

    } catch {
        Write-Error "Publication failed: $($_.Exception.Message)"
        throw
    }
}

Write-Host "`n✅ Publication process completed!" -ForegroundColor Green