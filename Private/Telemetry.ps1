function Send-CopilotTelemetry {
    <#
    .SYNOPSIS
        Sends anonymous usage telemetry to help improve the module
    
    .DESCRIPTION
        Collects anonymous usage statistics to understand feature usage and improve the module.
        No personal or sensitive data is collected.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EventName,
        
        [Parameter()]
        [hashtable]$Properties = @{},
        
        [Parameter()]
        [hashtable]$Measurements = @{}
    )
    
    # Check if telemetry is enabled
    if (-not $Script:CopilotConfig.EnableTelemetry) {
        return
    }
    
    try {
        # Create anonymous session ID (persisted for session)
        if (-not $Script:CopilotConfig.SessionId) {
            $Script:CopilotConfig.SessionId = [Guid]::NewGuid().ToString()
        }
        
        # Collect basic system information (anonymous)
        $systemInfo = @{
            PowerShellVersion = $PSVersionTable.PSVersion.Major.ToString()
            OSPlatform = $PSVersionTable.Platform
            ModuleVersion = (Get-Module CopilotAgent).Version.ToString()
            SessionId = $Script:CopilotConfig.SessionId
            Timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        }
        
        # Combine with provided properties
        $telemetryData = @{
            EventName = $EventName
            Properties = $Properties + $systemInfo
            Measurements = $Measurements
        }
        
        # Only send telemetry if endpoint is configured
        if ($Script:CopilotConfig.TelemetryEndpoint) {
            # Send telemetry asynchronously (don't block user operations)
            $job = Start-Job -ScriptBlock {
                param($Data, $Endpoint)
                
                try {
                    # Validate endpoint is HTTPS for security
                    if (-not $Endpoint.StartsWith('https://')) {
                        Write-Verbose "Telemetry endpoint must use HTTPS. Skipping telemetry."
                        return
                    }
                    
                    $body = $Data | ConvertTo-Json -Depth 5
                    $headers = @{
                        'Content-Type' = 'application/json'
                        'User-Agent' = 'CopilotAgent-PowerShell'
                    }
                    
                    # Send to configured telemetry endpoint
                    Invoke-RestMethod -Uri $Endpoint -Method POST -Body $body -Headers $headers -TimeoutSec 10 -UseBasicParsing
                    
                } catch {
                    # Silently fail - don't impact user experience
                    Write-Verbose "Telemetry send failed: $($_.Exception.Message)"
                }
            } -ArgumentList $telemetryData, $Script:CopilotConfig.TelemetryEndpoint
        
        # Clean up completed jobs
        Get-Job | Where-Object { $_.State -eq 'Completed' } | Remove-Job -Force
        
    } catch {
        # Never let telemetry failures impact user experience
        Write-Verbose "Telemetry collection failed: $($_.Exception.Message)"
    }
}

function Measure-CopilotUsage {
    <#
    .SYNOPSIS
        Measures and tracks usage patterns for analytics
    
    .DESCRIPTION
        Tracks feature usage to understand user behavior and improve the module
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Feature,
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter()]
        [System.Diagnostics.Stopwatch]$Timer
    )
    
    if (-not $Script:CopilotConfig.UsageStats) {
        $Script:CopilotConfig.UsageStats = @{}
    }
    
    # Track feature usage count
    if (-not $Script:CopilotConfig.UsageStats[$Feature]) {
        $Script:CopilotConfig.UsageStats[$Feature] = @{
            Count = 0
            FirstUsed = Get-Date
            LastUsed = $null
            TotalDuration = [TimeSpan]::Zero
            Errors = 0
        }
    }
    
    $stats = $Script:CopilotConfig.UsageStats[$Feature]
    $stats.Count++
    $stats.LastUsed = Get-Date
    
    # Add timing if provided
    if ($Timer) {
        $stats.TotalDuration = $stats.TotalDuration.Add($Timer.Elapsed)
        $Context.Duration = $Timer.Elapsed.TotalMilliseconds
    }
    
    # Track error if this is an error context
    if ($Context.ContainsKey('Error')) {
        $stats.Errors++
    }
    
    # Send telemetry event
    Send-CopilotTelemetry -EventName "FeatureUsed" -Properties (@{
        Feature = $Feature
        Success = (-not $Context.ContainsKey('Error'))
    } + $Context)
}

function Get-CopilotUsageReport {
    <#
    .SYNOPSIS
        Generates a usage report for the current session
    
    .DESCRIPTION
        Creates a summary report of feature usage and performance metrics
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IncludeDetails
    )
    
    if (-not $Script:CopilotConfig.UsageStats) {
        Write-Host "No usage data available for this session." -ForegroundColor Yellow
        return
    }
    
    $report = @{
        SessionStarted = $Script:CopilotConfig.SessionStart
        SessionDuration = (Get-Date) - $Script:CopilotConfig.SessionStart
        Features = @{}
        Summary = @{
            TotalFeatureUsage = 0
            UniqueFeatures = 0
            TotalErrors = 0
            MostUsedFeature = $null
        }
    }
    
    # Process each feature
    foreach ($feature in $Script:CopilotConfig.UsageStats.Keys) {
        $stats = $Script:CopilotConfig.UsageStats[$feature]
        
        $featureReport = @{
            UsageCount = $stats.Count
            FirstUsed = $stats.FirstUsed
            LastUsed = $stats.LastUsed
            AverageResponseTime = if ($stats.Count -gt 0) { 
                [Math]::Round($stats.TotalDuration.TotalMilliseconds / $stats.Count, 2) 
            } else { 
                0 
            }
            ErrorRate = if ($stats.Count -gt 0) { 
                [Math]::Round(($stats.Errors / $stats.Count) * 100, 2) 
            } else { 
                0 
            }
        }
        
        if ($IncludeDetails) {
            $featureReport.TotalDuration = $stats.TotalDuration
            $featureReport.Errors = $stats.Errors
        }
        
        $report.Features[$feature] = $featureReport
        
        # Update summary
        $report.Summary.TotalFeatureUsage += $stats.Count
        $report.Summary.TotalErrors += $stats.Errors
    }
    
    $report.Summary.UniqueFeatures = $Script:CopilotConfig.UsageStats.Keys.Count
    
    # Find most used feature
    if ($report.Features.Count -gt 0) {
        $mostUsed = $report.Features.GetEnumerator() | Sort-Object { $_.Value.UsageCount } -Descending | Select-Object -First 1
        $report.Summary.MostUsedFeature = $mostUsed.Key
    }
    
    # Display formatted report
    Write-Host "`n📊 CopilotAgent Usage Report" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host "Session Duration: $($report.SessionDuration.ToString('hh\:mm\:ss'))" -ForegroundColor White
    Write-Host "Total Feature Usage: $($report.Summary.TotalFeatureUsage)" -ForegroundColor White
    Write-Host "Unique Features Used: $($report.Summary.UniqueFeatures)" -ForegroundColor White
    Write-Host "Total Errors: $($report.Summary.TotalErrors)" -ForegroundColor White
    
    if ($report.Summary.MostUsedFeature) {
        Write-Host "Most Used Feature: $($report.Summary.MostUsedFeature)" -ForegroundColor White
    }
    
    Write-Host "`nFeature Breakdown:" -ForegroundColor Yellow
    foreach ($feature in $report.Features.GetEnumerator() | Sort-Object { $_.Value.UsageCount } -Descending) {
        $stats = $feature.Value
        Write-Host "  $($feature.Key):" -ForegroundColor White
        Write-Host "    Usage: $($stats.UsageCount) times" -ForegroundColor Gray
        Write-Host "    Avg Response: $($stats.AverageResponseTime) ms" -ForegroundColor Gray
        Write-Host "    Error Rate: $($stats.ErrorRate)%" -ForegroundColor Gray
    }
    
    return $report
}

function Enable-CopilotTelemetry {
    <#
    .SYNOPSIS
        Enables anonymous telemetry collection
    
    .DESCRIPTION
        Enables collection of anonymous usage statistics to help improve the module
    #>
    [CmdletBinding()]
    param()
    
    $Script:CopilotConfig.EnableTelemetry = $true
    Write-Host "✅ Telemetry enabled. Anonymous usage data will help improve CopilotAgent." -ForegroundColor Green
    Write-Host "   No personal or sensitive information is collected." -ForegroundColor Gray
    Write-Host "   Use Disable-CopilotTelemetry to opt out at any time." -ForegroundColor Gray
    
    Send-CopilotTelemetry -EventName "TelemetryEnabled"
}

function Disable-CopilotTelemetry {
    <#
    .SYNOPSIS
        Disables anonymous telemetry collection
    
    .DESCRIPTION
        Stops collection of usage statistics and analytics
    #>
    [CmdletBinding()]
    param()
    
    Send-CopilotTelemetry -EventName "TelemetryDisabled"
    $Script:CopilotConfig.EnableTelemetry = $false
    
    Write-Host "🚫 Telemetry disabled. No usage data will be collected." -ForegroundColor Yellow
}

function Get-CopilotTelemetryStatus {
    <#
    .SYNOPSIS
        Shows current telemetry and analytics status
    
    .DESCRIPTION
        Displays information about telemetry collection and local usage tracking
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`n📈 Telemetry & Analytics Status" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    
    $telemetryStatus = if ($Script:CopilotConfig.EnableTelemetry) { "Enabled" } else { "Disabled" }
    $statusColor = if ($Script:CopilotConfig.EnableTelemetry) { "Green" } else { "Yellow" }
    
    Write-Host "Telemetry Collection: $telemetryStatus" -ForegroundColor $statusColor
    Write-Host "Session ID: $($Script:CopilotConfig.SessionId)" -ForegroundColor White
    Write-Host "Usage Tracking: Always Active (Local Only)" -ForegroundColor Green
    
    if ($Script:CopilotConfig.UsageStats) {
        Write-Host "Local Stats: $($Script:CopilotConfig.UsageStats.Keys.Count) features tracked" -ForegroundColor White
    }
    
    Write-Host "`nWhat data is collected:" -ForegroundColor Yellow
    Write-Host "✅ Feature usage counts (anonymous)" -ForegroundColor Green
    Write-Host "✅ Performance metrics (response times)" -ForegroundColor Green  
    Write-Host "✅ Error rates (for reliability)" -ForegroundColor Green
    Write-Host "✅ PowerShell/OS version (for compatibility)" -ForegroundColor Green
    Write-Host "❌ No personal information" -ForegroundColor Red
    Write-Host "❌ No Microsoft 365 data" -ForegroundColor Red
    Write-Host "❌ No conversation content" -ForegroundColor Red
    Write-Host "❌ No authentication details" -ForegroundColor Red
    
    Write-Host "`nCommands:" -ForegroundColor Yellow
    Write-Host "  Enable-CopilotTelemetry   - Enable anonymous telemetry" -ForegroundColor Gray
    Write-Host "  Disable-CopilotTelemetry  - Disable telemetry collection" -ForegroundColor Gray
    Write-Host "  Get-CopilotUsageReport    - View local usage statistics" -ForegroundColor Gray
}

# Initialize telemetry system
if (-not $Script:CopilotConfig.ContainsKey('EnableTelemetry')) {
    # Default to DISABLED - require explicit opt-in for privacy
    $Script:CopilotConfig.EnableTelemetry = $false
    $Script:CopilotConfig.SessionStart = Get-Date
    $Script:CopilotConfig.SessionId = [Guid]::NewGuid().ToString()
    # Remove hardcoded endpoint - make configurable or disable
    $Script:CopilotConfig.TelemetryEndpoint = $null
}

# Export telemetry functions
Export-ModuleMember -Function Enable-CopilotTelemetry, Disable-CopilotTelemetry, Get-CopilotTelemetryStatus, Get-CopilotUsageReport