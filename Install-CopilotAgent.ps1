#Requires -Version 5.1
<#
.SYNOPSIS
    Installation script for Copilot Agent PowerShell Module

.DESCRIPTION
    This script installs and configures the Copilot Agent PowerShell module
    with all required dependencies and authentication setup.

.PARAMETER InstallPath
    Custom installation path for the module

.PARAMETER Force
    Force reinstallation even if module already exists

.PARAMETER SkipDependencies
    Skip installation of required PowerShell modules

.EXAMPLE
    .\Install-CopilotAgent.ps1

.EXAMPLE
    .\Install-CopilotAgent.ps1 -Force -InstallPath "C:\MyModules"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallPath,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$SkipDependencies
)

$ErrorActionPreference = 'Stop'

function Write-Banner {
    Write-Host @"
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║    🚀 Copilot Agent PowerShell Module Installer                                 ║
║    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                                ║
║                                                                                  ║
║    Installing Microsoft 365 Copilot integration for PowerShell                 ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
}

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-RequiredModules {
    Write-Host "📦 Installing required PowerShell modules..." -ForegroundColor Yellow

    $requiredModules = @(
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.Applications',
        'Microsoft.Graph.Users',
        'Microsoft.Graph.Mail',
        'Microsoft.Graph.Calendar',
        'Microsoft.Graph.Files'
    )

    foreach ($module in $requiredModules) {
        Write-Host "  Installing $module..." -ForegroundColor Gray
        try {
            if (Get-Module -ListAvailable -Name $module) {
                Write-Host "    ✓ Already installed" -ForegroundColor Green
            } else {
                Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
                Write-Host "    ✓ Installed successfully" -ForegroundColor Green
            }
        } catch {
            Write-Warning "Failed to install $module`: $($_.Exception.Message)"
        }
    }
}

function Copy-ModuleFiles {
    param([string]$DestinationPath)

    Write-Host "📁 Copying module files..." -ForegroundColor Yellow

    $sourceDir = $PSScriptRoot

    # Create destination directory
    if (-not (Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }

    # Copy all module files
    $filesToCopy = @(
        'CopilotAgent.psd1',
        'CopilotAgent.psm1'
    )

    foreach ($file in $filesToCopy) {
        $sourcePath = Join-Path $sourceDir $file
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $DestinationPath -Force
            Write-Host "  ✓ Copied $file" -ForegroundColor Green
        }
    }

    # Copy directories
    $dirsToCopy = @('Private', 'Public')
    foreach ($dir in $dirsToCopy) {
        $sourcePath = Join-Path $sourceDir $dir
        $destPath = Join-Path $DestinationPath $dir

        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
            Write-Host "  ✓ Copied $dir directory" -ForegroundColor Green
        }
    }
}

function Register-Module {
    param([string]$ModulePath)

    Write-Host "📝 Registering module..." -ForegroundColor Yellow

    # Add to PSModulePath if not already there
    $currentPSModulePath = $env:PSModulePath -split ';'
    $moduleParentPath = Split-Path $ModulePath -Parent

    if ($moduleParentPath -notin $currentPSModulePath) {
        $env:PSModulePath += ";$moduleParentPath"

        # Make it permanent for current user
        $userPath = [Environment]::GetEnvironmentVariable('PSModulePath', 'User')
        if ($userPath) {
            $userPath += ";$moduleParentPath"
        } else {
            $userPath = $moduleParentPath
        }
        [Environment]::SetEnvironmentVariable('PSModulePath', $userPath, 'User')

        Write-Host "  Added to PSModulePath" -ForegroundColor Green
    }
}

function Test-Installation {
    Write-Host "🧪 Testing installation..." -ForegroundColor Yellow

    try {
        Import-Module CopilotAgent -Force

        $commands = Get-Command -Module CopilotAgent
        Write-Host "  ✓ Module imported successfully" -ForegroundColor Green
        Write-Host "  ✓ Available commands: $($commands.Count)" -ForegroundColor Green

        foreach ($cmd in $commands.Name) {
            Write-Host "    - $cmd" -ForegroundColor Gray
        }

        return $true

    } catch {
        Write-Error "Installation test failed: $($_.Exception.Message)"
        return $false
    }
}

function Show-PostInstallInstructions {
    Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║    ✅ Installation Complete!                                                     ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝

🚀 Getting Started:

1. Import the module (if not already imported):
   Import-Module CopilotAgent

2. Start the interactive agent:
   Start-CopilotAgent -AutoConnect

3. Or use individual functions:
   Invoke-CopilotChat -Message "Hello, Copilot!"
   Get-CopilotInsights -Type "meetings"

📋 Available Commands:
   Start-CopilotAgent        - Interactive chat interface
   Invoke-CopilotChat        - Send messages to Copilot
   Get-CopilotInsights       - Get Microsoft 365 insights
   Set-CopilotConfiguration  - Configure the agent
   Export-CopilotConversation - Export conversations

📖 Documentation:
   Get-Help Start-CopilotAgent -Full
   Get-Help Invoke-CopilotChat -Examples

🔐 Authentication:
   The module uses Microsoft Graph authentication. You'll be prompted
   to sign in when first connecting to Microsoft 365 services.

🆘 Support:
   For issues or questions, check the module documentation or
   use Set-CopilotConfiguration -ShowCurrent for troubleshooting.

"@ -ForegroundColor Green
}

# Main installation logic
try {
    Write-Banner

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.1 or higher is required. Current version: $($PSVersionTable.PSVersion)"
    }

    Write-Host "✅ PowerShell version check passed" -ForegroundColor Green

    # Determine installation path
    if (-not $InstallPath) {
        if (Test-IsAdmin) {
            $InstallPath = Join-Path $env:ProgramFiles "WindowsPowerShell\Modules\CopilotAgent"
        } else {
            $documentPath = [Environment]::GetFolderPath('MyDocuments')
            $InstallPath = Join-Path $documentPath "WindowsPowerShell\Modules\CopilotAgent"
        }
    }

    Write-Host "📂 Installation path: $InstallPath" -ForegroundColor Cyan

    # Check if module already exists
    if ((Test-Path $InstallPath) -and -not $Force) {
        $response = Read-Host "Module already exists. Overwrite? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Installation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }

    # Install dependencies
    if (-not $SkipDependencies) {
        Install-RequiredModules
    }

    # Copy module files
    Copy-ModuleFiles -DestinationPath $InstallPath

    # Register module
    Register-Module -ModulePath $InstallPath

    # Test installation
    if (Test-Installation) {
        Show-PostInstallInstructions
    } else {
        throw "Installation validation failed"
    }

} catch {
    Write-Error "Installation failed: $($_.Exception.Message)"
    exit 1
}