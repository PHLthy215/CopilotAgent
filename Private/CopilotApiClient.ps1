function Invoke-CopilotApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Endpoint,

        [Parameter(Mandatory)]
        [string]$Method,

        [Parameter()]
        [hashtable]$Body,

        [Parameter()]
        [hashtable]$Headers = @{},

        [Parameter()]
        [int]$TimeoutSeconds = 30
    )

    try {
        # Ensure we have a valid Graph token
        $token = Get-MgAccessToken
        if (-not $token) {
            throw "No valid Microsoft Graph token found. Please run Connect-MgGraph first."
        }

        # Prepare headers
        $defaultHeaders = @{
            'Authorization' = "Bearer $token"
            'Content-Type' = 'application/json'
            'Accept' = 'application/json'
        }

        $Headers.Keys | ForEach-Object {
            $defaultHeaders[$_] = $Headers[$_]
        }

        # Prepare request parameters
        $requestParams = @{
            Uri = $Endpoint
            Method = $Method
            Headers = $defaultHeaders
            TimeoutSec = $TimeoutSeconds
        }

        if ($Body -and $Method -in @('POST', 'PUT', 'PATCH')) {
            $requestParams.Body = ($Body | ConvertTo-Json -Depth 10)
        }

        # Make the API request
        $response = Invoke-RestMethod @requestParams
        return $response

    } catch {
        Write-Error "API request failed: $($_.Exception.Message)"
        throw
    }
}

function Test-CopilotConnection {
    [CmdletBinding()]
    param()

    try {
        $endpoint = "$($Script:CopilotConfig.GraphEndpoint)/me"
        $response = Invoke-CopilotApiRequest -Endpoint $endpoint -Method 'GET'

        if ($response) {
            Write-Host "✅ Connected to Microsoft Graph as: $($response.displayName)" -ForegroundColor Green
            return $true
        }

        return $false
    } catch {
        Write-Warning "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        return $false
    }
}

function Get-CopilotToken {
    [CmdletBinding()]
    param()

    try {
        return Get-MgAccessToken
    } catch {
        Write-Error "Failed to get access token: $($_.Exception.Message)"
        return $null
    }
}