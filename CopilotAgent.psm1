# CopilotAgent PowerShell Module
# Main module file that loads all functions and classes

# Import private functions
Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" | ForEach-Object { . $_.FullName }

# Import public functions
Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" | ForEach-Object { . $_.FullName }

# Module variables with secure defaults
if (-not $Script:CopilotConfig) {
    $Script:CopilotConfig = @{
        GraphEndpoint = "https://graph.microsoft.com/v1.0"
        CopilotEndpoint = "https://graph.microsoft.com/v1.0/copilot"
        MaxRetries = 3
        Timeout = 30
        ConversationHistory = [System.Collections.ArrayList]::new()
        EnableTelemetry = $false  # Secure default - disabled
        LogLevel = 'Information'
        TelemetryEndpoint = $null  # No default endpoint
        SessionId = [Guid]::NewGuid().ToString()
        SessionStart = Get-Date
        UsageStats = @{}
        LogBuffer = [System.Collections.ArrayList]::new()
    }
}

# Export all functions
Export-ModuleMember -Function @(
    'Start-CopilotAgent',
    'Invoke-CopilotChat',
    'Get-CopilotInsights',
    'Set-CopilotConfiguration',
    'Export-CopilotConversation',
    'Enable-CopilotTelemetry',
    'Disable-CopilotTelemetry',
    'Get-CopilotTelemetryStatus',
    'Get-CopilotUsageReport',
    'Export-CopilotDiagnostics',
    'Get-CopilotDiagnostics'
)