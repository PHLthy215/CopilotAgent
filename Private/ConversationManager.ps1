class CopilotConversation {
    [string]$Id
    [DateTime]$StartTime
    [System.Collections.ArrayList]$Messages
    [hashtable]$Context
    
    CopilotConversation() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.StartTime = Get-Date
        $this.Messages = @()
        $this.Context = @{}
    }
    
    [void]AddMessage([string]$Role, [string]$Content, [hashtable]$Metadata = @{}) {
        $message = @{
            Id = [Guid]::NewGuid().ToString()
            Timestamp = Get-Date
            Role = $Role
            Content = $Content
            Metadata = $Metadata
        }
        $this.Messages.Add($message) | Out-Null
    }
    
    [object[]]GetMessages() {
        return $this.Messages.ToArray()
    }
    
    [void]SetContext([string]$Key, [object]$Value) {
        $this.Context[$Key] = $Value
    }
    
    [object]GetContext([string]$Key) {
        return $this.Context[$Key]
    }
}

function New-CopilotConversation {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$InitialContext = @{}
    )
    
    $conversation = [CopilotConversation]::new()
    
    # Set initial context
    $InitialContext.Keys | ForEach-Object {
        $conversation.SetContext($_, $InitialContext[$_])
    }
    
    # Add system message
    $systemMessage = "You are a helpful AI assistant integrated with Microsoft 365 Copilot. You can help with various tasks including document analysis, meeting insights, and general productivity."
    $conversation.AddMessage("system", $systemMessage)
    
    return $conversation
}

function Save-ConversationHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CopilotConversation]$Conversation,
        
        [Parameter()]
        [string]$Path = "$env:TEMP\CopilotAgent_$($Conversation.Id).json"
    )
    
    try {
        $conversationData = @{
            Id = $Conversation.Id
            StartTime = $Conversation.StartTime
            Messages = $Conversation.GetMessages()
            Context = $Conversation.Context
        }
        
        $conversationData | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        Write-Host "💾 Conversation saved to: $Path" -ForegroundColor Blue
        
    } catch {
        Write-Error "Failed to save conversation: $($_.Exception.Message)"
    }
}

function Load-ConversationHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    try {
        if (-not (Test-Path $Path)) {
            throw "Conversation file not found: $Path"
        }
        
        $conversationData = Get-Content -Path $Path -Raw | ConvertFrom-Json
        
        $conversation = [CopilotConversation]::new()
        $conversation.Id = $conversationData.Id
        $conversation.StartTime = [DateTime]::Parse($conversationData.StartTime)
        
        # Load messages
        $conversationData.Messages | ForEach-Object {
            $conversation.Messages.Add($_) | Out-Null
        }
        
        # Load context
        $conversationData.Context.PSObject.Properties | ForEach-Object {
            $conversation.Context[$_.Name] = $_.Value
        }
        
        return $conversation
        
    } catch {
        Write-Error "Failed to load conversation: $($_.Exception.Message)"
        return $null
    }
}