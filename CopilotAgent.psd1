@{
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'CopilotAgent Contributors'
    CompanyName = 'Open Source'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'PowerShell module for interactive Microsoft 365 Copilot integration with enterprise security, conversation management, and productivity insights.'

    PowerShellVersion = '5.1'

    # RequiredModules = @(
    #     'Microsoft.Graph.Authentication',
    #     'Microsoft.Graph.Applications'
    # )

    FunctionsToExport = @(
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

    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    PrivateData = @{
        PSData = @{
            Tags = @('Copilot', 'AI', 'Agent', 'Microsoft', 'Graph', 'Productivity', 'Automation', 'M365')
            LicenseUri = 'https://github.com/yourusername/CopilotAgent/blob/main/LICENSE'
            ProjectUri = 'https://github.com/yourusername/CopilotAgent'
            IconUri = 'https://raw.githubusercontent.com/yourusername/CopilotAgent/main/docs/icon.png'
            ReleaseNotes = 'See CHANGELOG.md for detailed release notes'
            RequireLicenseAcceptance = $false
            ExternalModuleDependencies = @()
        }
    }
}