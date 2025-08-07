function Write-CopilotLog {
    <#
    .SYNOPSIS
        Centralized logging function for CopilotAgent module
    
    .DESCRIPTION
        Provides structured logging with different levels and optional file output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Verbose', 'Information', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Information',
        
        [Parameter()]
        [string]$Category = 'General',
        
        [Parameter()]
        [hashtable]$Data = @{},
        
        [Parameter()]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    # Get timestamp
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    
    # Build log entry
    $logEntry = @{
        Timestamp = $timestamp
        Level = $Level
        Category = $Category
        Message = $Message
        Data = $Data
    }
    
    # Add error details if provided
    if ($ErrorRecord) {
        $logEntry.Error = @{
            Message = $ErrorRecord.Exception.Message
            Type = $ErrorRecord.Exception.GetType().Name
            StackTrace = $ErrorRecord.ScriptStackTrace
            Line = $ErrorRecord.InvocationInfo.ScriptLineNumber
            Command = $ErrorRecord.InvocationInfo.MyCommand.Name
        }
    }
    
    # Format message for console output
    $consoleMessage = "[$timestamp] [$Level] [$Category] $Message"
    
    # Output based on level
    switch ($Level) {
        'Verbose' { 
            Write-Verbose $consoleMessage 
            if ($Script:CopilotConfig.LogLevel -eq 'Verbose') {
                Write-Host $consoleMessage -ForegroundColor Gray
            }
        }
        'Information' { 
            Write-Information $consoleMessage -InformationAction Continue
        }
        'Warning' { 
            Write-Warning $consoleMessage 
        }
        'Error' { 
            Write-Error $consoleMessage 
        }
        'Debug' { 
            Write-Debug $consoleMessage 
        }
    }
    
    # Write to log file if configured
    if ($Script:CopilotConfig.LogFilePath) {
        try {
            $logEntry | ConvertTo-Json -Compress | Out-File -FilePath $Script:CopilotConfig.LogFilePath -Append -Encoding UTF8
        } catch {
            Write-Warning "Failed to write to log file: $($_.Exception.Message)"
        }
    }
    
    # Store in memory buffer (last 100 entries)
    if (-not $Script:CopilotConfig.LogBuffer) {
        $Script:CopilotConfig.LogBuffer = @()
    }
    
    $Script:CopilotConfig.LogBuffer += $logEntry
    if ($Script:CopilotConfig.LogBuffer.Count -gt 100) {
        $Script:CopilotConfig.LogBuffer = $Script:CopilotConfig.LogBuffer[-100..-1]
    }
}

function Invoke-WithErrorHandling {
    <#
    .SYNOPSIS
        Wrapper function that provides consistent error handling and retry logic
    
    .DESCRIPTION
        Executes a script block with automatic retry, logging, and error handling
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [string]$OperationName = "Operation",
        
        [Parameter()]
        [int]$MaxRetries = $Script:CopilotConfig.MaxRetries,
        
        [Parameter()]
        [int]$DelaySeconds = 1,
        
        [Parameter()]
        [string[]]$RetryableErrors = @('TimeoutException', 'HttpRequestException', 'WebException'),
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-CopilotLog -Message "Starting operation: $OperationName" -Level Verbose -Category "ErrorHandling" -Data $Context
    
    $attempt = 0
    $lastError = $null
    
    do {
        $attempt++
        
        try {
            Write-CopilotLog -Message "Executing $OperationName (attempt $attempt)" -Level Debug -Category "ErrorHandling"
            
            $result = & $ScriptBlock
            
            Write-CopilotLog -Message "Successfully completed $OperationName" -Level Verbose -Category "ErrorHandling"
            return $result
            
        } catch {
            $lastError = $_
            $errorType = $_.Exception.GetType().Name
            
            Write-CopilotLog -Message "Error in $OperationName (attempt $attempt): $($_.Exception.Message)" -Level Warning -Category "ErrorHandling" -ErrorRecord $_
            
            # Check if error is retryable
            $isRetryable = $RetryableErrors -contains $errorType -or 
                          $_.Exception.Message -match "timeout|throttl|rate limit|502|503|504"
            
            if ($isRetryable -and $attempt -lt $MaxRetries) {
                $waitTime = [Math]::Pow(2, $attempt - 1) * $DelaySeconds  # Exponential backoff
                Write-CopilotLog -Message "Retrying $OperationName in $waitTime seconds..." -Level Information -Category "ErrorHandling"
                Start-Sleep -Seconds $waitTime
            } else {
                # Max retries reached or non-retryable error
                Write-CopilotLog -Message "Failed $OperationName after $attempt attempts" -Level Error -Category "ErrorHandling" -ErrorRecord $_
                throw
            }
        }
    } while ($attempt -lt $MaxRetries)
    
    # This should never be reached, but just in case
    throw $lastError
}

function Test-CopilotPreconditions {
    <#
    .SYNOPSIS
        Validates system prerequisites and configuration
    
    .DESCRIPTION
        Checks for required modules, connectivity, and configuration before operations
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$RequireAuthentication,
        
        [Parameter()]
        [switch]$RequireInternet,
        
        [Parameter()]
        [string[]]$RequiredModules = @()
    )
    
    $issues = @()
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion -lt [Version]'5.1') {
        $issues += "PowerShell version $($PSVersionTable.PSVersion) is not supported. Minimum version is 5.1."
    }
    
    # Check required modules
    foreach ($module in $RequiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            $issues += "Required module '$module' is not installed."
        }
    }
    
    # Check internet connectivity
    if ($RequireInternet) {
        try {
            $response = Invoke-WebRequest -Uri "https://graph.microsoft.com" -Method Head -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -ne 200) {
                $issues += "Cannot connect to Microsoft Graph API (HTTP $($response.StatusCode))."
            }
        } catch {
            $issues += "Internet connectivity test failed: $($_.Exception.Message)"
        }
    }
    
    # Check authentication
    if ($RequireAuthentication) {
        try {
            $context = Get-MgContext -ErrorAction SilentlyContinue
            if (-not $context) {
                $issues += "Not authenticated to Microsoft Graph. Run Connect-MgGraph first."
            }
        } catch {
            $issues += "Authentication check failed: $($_.Exception.Message)"
        }
    }
    
    if ($issues.Count -gt 0) {
        Write-CopilotLog -Message "Precondition checks failed" -Level Error -Category "Validation" -Data @{ Issues = $issues }
        
        $errorMessage = "Prerequisites not met:`n" + ($issues | ForEach-Object { "• $_" }) -join "`n"
        throw [System.InvalidOperationException]::new($errorMessage)
    }
    
    Write-CopilotLog -Message "All precondition checks passed" -Level Verbose -Category "Validation"
}

function Get-CopilotDiagnostics {
    <#
    .SYNOPSIS
        Collects diagnostic information for troubleshooting
    
    .DESCRIPTION
        Gathers system information, configuration, and recent logs for support purposes
    #>
    [CmdletBinding()]
    param()
    
    $diagnostics = @{
        Timestamp = Get-Date
        System = @{
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            OSVersion = $PSVersionTable.OS
            Platform = $PSVersionTable.Platform
            Edition = $PSVersionTable.PSEdition
        }
        Module = @{
            Version = (Get-Module CopilotAgent).Version.ToString()
            Path = (Get-Module CopilotAgent).Path
            ExportedFunctions = (Get-Command -Module CopilotAgent).Name
        }
        Configuration = @{}
        Authentication = @{}
        RecentLogs = @()
        InstalledModules = @()
    }
    
    # Configuration (remove sensitive data)
    foreach ($key in $Script:CopilotConfig.Keys) {
        if ($key -notmatch 'token|key|secret|password') {
            $diagnostics.Configuration[$key] = $Script:CopilotConfig[$key]
        }
    }
    
    # Authentication status
    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if ($context) {
            $diagnostics.Authentication = @{
                Connected = $true
                Account = $context.Account
                Environment = $context.Environment
                Scopes = $context.Scopes
                TenantId = $context.TenantId
            }
        } else {
            $diagnostics.Authentication.Connected = $false
        }
    } catch {
        $diagnostics.Authentication = @{
            Connected = $false
            Error = $_.Exception.Message
        }
    }
    
    # Recent logs
    if ($Script:CopilotConfig.LogBuffer) {
        $diagnostics.RecentLogs = $Script:CopilotConfig.LogBuffer | Select-Object -Last 20
    }
    
    # Relevant installed modules
    $relevantModules = @('Microsoft.Graph.*', 'CopilotAgent')
    foreach ($pattern in $relevantModules) {
        $modules = Get-Module -ListAvailable -Name $pattern | Select-Object Name, Version
        $diagnostics.InstalledModules += $modules
    }
    
    return $diagnostics
}

function Export-CopilotDiagnostics {
    <#
    .SYNOPSIS
        Exports diagnostic information to a file
    
    .DESCRIPTION
        Creates a diagnostic report file for troubleshooting and support
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = "CopilotAgent_Diagnostics_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    )
    
    try {
        $diagnostics = Get-CopilotDiagnostics
        $diagnostics | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        
        Write-CopilotLog -Message "Diagnostics exported to: $Path" -Level Information -Category "Diagnostics"
        Write-Host "📋 Diagnostics exported to: $Path" -ForegroundColor Green
        
        return $Path
        
    } catch {
        Write-CopilotLog -Message "Failed to export diagnostics" -Level Error -Category "Diagnostics" -ErrorRecord $_
        throw
    }
}