function Set-CopilotConfiguration {
    <#
    .SYNOPSIS
        Configure Copilot Agent settings

    .DESCRIPTION
        Set various configuration options for the Copilot Agent including
        API endpoints, timeouts, authentication, and behavioral settings

    .PARAMETER GraphEndpoint
        Microsoft Graph API endpoint URL

    .PARAMETER CopilotEndpoint
        Microsoft Copilot API endpoint URL

    .PARAMETER TimeoutSeconds
        Request timeout in seconds

    .PARAMETER MaxRetries
        Maximum number of retry attempts for failed requests

    .PARAMETER ConfigFile
        Path to configuration file to load settings from

    .PARAMETER ShowCurrent
        Display current configuration settings

    .EXAMPLE
        Set-CopilotConfiguration -TimeoutSeconds 60 -MaxRetries 5

    .EXAMPLE
        Set-CopilotConfiguration -ShowCurrent

    .EXAMPLE
        Set-CopilotConfiguration -ConfigFile "C:\MyConfig\copilot.json"
    #>

    [CmdletBinding(DefaultParameterSetName = 'Settings')]
    param(
        [Parameter(ParameterSetName = 'Settings')]
        [string]$GraphEndpoint,

        [Parameter(ParameterSetName = 'Settings')]
        [string]$CopilotEndpoint,

        [Parameter(ParameterSetName = 'Settings')]
        [int]$TimeoutSeconds,

        [Parameter(ParameterSetName = 'Settings')]
        [int]$MaxRetries,

        [Parameter(ParameterSetName = 'Settings')]
        [hashtable]$CustomSettings,

        [Parameter(ParameterSetName = 'ConfigFile')]
        [string]$ConfigFile,

        [Parameter(ParameterSetName = 'Show')]
        [switch]$ShowCurrent,

        [Parameter(ParameterSetName = 'Reset')]
        [switch]$Reset
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Show' {
            # Ensure config has default values
            if (-not $Script:CopilotConfig.TimeoutSeconds) { $Script:CopilotConfig.TimeoutSeconds = 30 }
            if (-not $Script:CopilotConfig.MaxRetries) { $Script:CopilotConfig.MaxRetries = 3 }
            if (-not $Script:CopilotConfig.GraphEndpoint) { $Script:CopilotConfig.GraphEndpoint = "https://graph.microsoft.com/v1.0" }
            if (-not $Script:CopilotConfig.CopilotEndpoint) { $Script:CopilotConfig.CopilotEndpoint = "https://graph.microsoft.com/v1.0/copilot" }
            if (-not $Script:CopilotConfig.ConversationHistory) { $Script:CopilotConfig.ConversationHistory = @() }
            
            Write-Host "📋 Current Copilot Agent Configuration:" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "API Settings:" -ForegroundColor Yellow
            Write-Host "  Graph Endpoint:   $($Script:CopilotConfig.GraphEndpoint)" -ForegroundColor White
            Write-Host "  Copilot Endpoint: $($Script:CopilotConfig.CopilotEndpoint)" -ForegroundColor White
            Write-Host ""
            Write-Host "Request Settings:" -ForegroundColor Yellow
            Write-Host "  Timeout:          $($Script:CopilotConfig.TimeoutSeconds) seconds" -ForegroundColor White
            Write-Host "  Max Retries:      $($Script:CopilotConfig.MaxRetries)" -ForegroundColor White
            Write-Host ""
            Write-Host "Conversation:" -ForegroundColor Yellow
            Write-Host "  History Count:    $($Script:CopilotConfig.ConversationHistory.Count) messages" -ForegroundColor White

            # Show custom settings if any
            $customKeys = $Script:CopilotConfig.Keys | Where-Object { $_ -notin @('GraphEndpoint', 'CopilotEndpoint', 'TimeoutSeconds', 'MaxRetries', 'ConversationHistory') }
            if ($customKeys) {
                Write-Host ""
                Write-Host "Custom Settings:" -ForegroundColor Yellow
                foreach ($key in $customKeys) {
                    $spaces = [Math]::Max(0, 15 - $key.Length)
                    Write-Host "  ${key}:$(' ' * $spaces)$($Script:CopilotConfig[$key])" -ForegroundColor White
                }
            }
            return
        }

        'Reset' {
            Write-Host "🔄 Resetting configuration to defaults..." -ForegroundColor Yellow
            $Script:CopilotConfig = @{
                GraphEndpoint = "https://graph.microsoft.com/v1.0"
                CopilotEndpoint = "https://graph.microsoft.com/v1.0/copilot"
                MaxRetries = 3
                TimeoutSeconds = 30
                ConversationHistory = @()
            }
            Write-Host "✅ Configuration reset successfully!" -ForegroundColor Green
            return
        }

        'ConfigFile' {
            if (-not (Test-Path $ConfigFile)) {
                Write-Error "Configuration file not found: $ConfigFile"
                return
            }

            try {
                $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json

                Write-Host "📁 Loading configuration from: $ConfigFile" -ForegroundColor Cyan

                # Apply settings from file
                if ($config.GraphEndpoint) { $Script:CopilotConfig.GraphEndpoint = $config.GraphEndpoint }
                if ($config.CopilotEndpoint) { $Script:CopilotConfig.CopilotEndpoint = $config.CopilotEndpoint }
                if ($config.TimeoutSeconds) { $Script:CopilotConfig.TimeoutSeconds = $config.TimeoutSeconds }
                if ($config.MaxRetries) { $Script:CopilotConfig.MaxRetries = $config.MaxRetries }

                # Apply custom settings
                $config.PSObject.Properties | Where-Object { $_.Name -notin @('GraphEndpoint', 'CopilotEndpoint', 'TimeoutSeconds', 'MaxRetries') } | ForEach-Object {
                    $Script:CopilotConfig[$_.Name] = $_.Value
                    Write-Host "  Set $($_.Name) = $($_.Value)" -ForegroundColor Gray
                }

                Write-Host "✅ Configuration loaded successfully!" -ForegroundColor Green

            } catch {
                Write-Error "Failed to load configuration file: $($_.Exception.Message)"
            }
            return
        }

        'Settings' {
            Write-Host "⚙️  Updating Copilot Agent configuration..." -ForegroundColor Cyan

            $updated = @()

            if ($GraphEndpoint) {
                $Script:CopilotConfig.GraphEndpoint = $GraphEndpoint
                $updated += "Graph Endpoint"
                Write-Host "  ✓ Graph Endpoint: $GraphEndpoint" -ForegroundColor Green
            }

            if ($CopilotEndpoint) {
                $Script:CopilotConfig.CopilotEndpoint = $CopilotEndpoint
                $updated += "Copilot Endpoint"
                Write-Host "  ✓ Copilot Endpoint: $CopilotEndpoint" -ForegroundColor Green
            }

            if ($TimeoutSeconds) {
                $Script:CopilotConfig.TimeoutSeconds = $TimeoutSeconds
                $updated += "Timeout"
                Write-Host "  ✓ Timeout: $TimeoutSeconds seconds" -ForegroundColor Green
            }

            if ($MaxRetries) {
                $Script:CopilotConfig.MaxRetries = $MaxRetries
                $updated += "Max Retries"
                Write-Host "  ✓ Max Retries: $MaxRetries" -ForegroundColor Green
            }

            if ($CustomSettings) {
                foreach ($key in $CustomSettings.Keys) {
                    $Script:CopilotConfig[$key] = $CustomSettings[$key]
                    $updated += $key
                    Write-Host "  ✓ $key`: $($CustomSettings[$key])" -ForegroundColor Green
                }
            }

            if ($updated.Count -gt 0) {
                Write-Host ""
                Write-Host "✅ Updated: $($updated -join ', ')" -ForegroundColor Green
            } else {
                Write-Host "ℹ️  No settings provided to update." -ForegroundColor Yellow
            }
        }
    }
}

function Export-CopilotConfiguration {
    <#
    .SYNOPSIS
        Export current configuration to a file

    .DESCRIPTION
        Exports the current Copilot Agent configuration to a JSON file
        that can be loaded later using Set-CopilotConfiguration -ConfigFile

    .PARAMETER Path
        Path where to save the configuration file

    .PARAMETER IncludeHistory
        Include conversation history in the export (default: false)

    .EXAMPLE
        Export-CopilotConfiguration -Path "C:\MyConfig\copilot.json"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [switch]$IncludeHistory
    )

    try {
        $config = $Script:CopilotConfig.Clone()

        # Remove conversation history unless explicitly requested
        if (-not $IncludeHistory -and $config.ContainsKey('ConversationHistory')) {
            $config.Remove('ConversationHistory')
        }

        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8

        Write-Host "💾 Configuration exported to: $Path" -ForegroundColor Green

        if ($IncludeHistory) {
            Write-Host "   (includes conversation history)" -ForegroundColor Gray
        }

    } catch {
        Write-Error "Failed to export configuration: $($_.Exception.Message)"
    }
}

function Import-CopilotConfiguration {
    <#
    .SYNOPSIS
        Import configuration from a file

    .DESCRIPTION
        Imports Copilot Agent configuration from a JSON file.
        This is an alias for Set-CopilotConfiguration -ConfigFile

    .PARAMETER Path
        Path to the configuration file to import

    .EXAMPLE
        Import-CopilotConfiguration -Path "C:\MyConfig\copilot.json"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    Set-CopilotConfiguration -ConfigFile $Path
}

# Create aliases for convenience
Set-Alias -Name "Get-CopilotConfig" -Value "Set-CopilotConfiguration" -Option ReadOnly -Scope Global -Force
Set-Alias -Name "Show-CopilotConfig" -Value "Set-CopilotConfiguration" -Option ReadOnly -Scope Global -Force