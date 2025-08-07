function Export-CopilotConversation {
    <#
    .SYNOPSIS
        Export Copilot conversation to various formats
    
    .DESCRIPTION
        Export conversation history from Copilot Agent to different formats
        including JSON, CSV, HTML, and Markdown for analysis or sharing
    
    .PARAMETER Conversation
        The conversation object to export
    
    .PARAMETER Path
        Output file path
    
    .PARAMETER Format
        Export format: JSON, CSV, HTML, Markdown
    
    .PARAMETER IncludeMetadata
        Include technical metadata in the export
    
    .PARAMETER Title
        Custom title for HTML/Markdown exports
    
    .EXAMPLE
        Export-CopilotConversation -Conversation $conv -Path "conversation.html" -Format HTML
    
    .EXAMPLE
        Export-CopilotConversation -Conversation $conv -Path "chat.json" -Format JSON -IncludeMetadata
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [CopilotConversation]$Conversation,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            # Validate path is safe and doesn't contain path traversal
            $resolvedPath = Resolve-Path (Split-Path $_ -Parent) -ErrorAction SilentlyContinue
            if (-not $resolvedPath -or $_.Contains('..') -or $_.Contains('//') -or $_ -match '[\<\>\|]') {
                throw "Path contains invalid characters or attempts directory traversal: $_"
            }
            
            # Ensure we can write to the directory
            $directory = Split-Path $_ -Parent
            if ($directory -and -not (Test-Path $directory)) {
                throw "Directory does not exist: $directory"
            }
            
            $true
        })]
        [string]$Path,
        
        [Parameter()]
        [ValidateSet('JSON', 'CSV', 'HTML', 'Markdown', 'Text')]
        [string]$Format = 'JSON',
        
        [Parameter()]
        [switch]$IncludeMetadata,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Title = "Copilot Conversation Export"
    )
    
    try {
        Write-Host "📤 Exporting conversation to $Format format..." -ForegroundColor Cyan
        
        $messages = $Conversation.GetMessages()
        
        switch ($Format) {
            'JSON' {
                Export-ConversationToJson -Messages $messages -Path $Path -Conversation $Conversation -IncludeMetadata:$IncludeMetadata
            }
            'CSV' {
                Export-ConversationToCsv -Messages $messages -Path $Path -IncludeMetadata:$IncludeMetadata
            }
            'HTML' {
                Export-ConversationToHtml -Messages $messages -Path $Path -Title $Title -Conversation $Conversation
            }
            'Markdown' {
                Export-ConversationToMarkdown -Messages $messages -Path $Path -Title $Title -Conversation $Conversation
            }
            'Text' {
                Export-ConversationToText -Messages $messages -Path $Path -Conversation $Conversation
            }
        }
        
        Write-Host "✅ Conversation exported successfully to: $Path" -ForegroundColor Green
        
        # Show file size
        $fileInfo = Get-Item $Path
        Write-Host "📊 File size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
        
    } catch {
        Write-Error "Failed to export conversation: $($_.Exception.Message)"
    }
}

function Export-ConversationToJson {
    param(
        [array]$Messages,
        [string]$Path,
        [CopilotConversation]$Conversation,
        [switch]$IncludeMetadata
    )
    
    $exportData = @{
        ConversationId = $Conversation.Id
        StartTime = $Conversation.StartTime
        ExportTime = Get-Date
        MessageCount = $Messages.Count
        Messages = $Messages
    }
    
    if ($IncludeMetadata) {
        $exportData.Context = $Conversation.Context
        $exportData.ExportMetadata = @{
            Version = "1.0"
            ExportedBy = $env:USERNAME
            Computer = $env:COMPUTERNAME
        }
    }
    
    $exportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
}

function Export-ConversationToCsv {
    param(
        [array]$Messages,
        [string]$Path,
        [switch]$IncludeMetadata
    )
    
    $csvData = $Messages | ForEach-Object {
        $row = [PSCustomObject]@{
            Timestamp = $_.Timestamp
            Role = $_.Role
            Content = $_.Content -replace "`n", " " -replace "`r", ""
        }
        
        if ($IncludeMetadata -and $_.Metadata) {
            $row | Add-Member -NotePropertyName "Metadata" -NotePropertyValue ($_.Metadata | ConvertTo-Json -Compress)
        }
        
        return $row
    }
    
    $csvData | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
}

function Export-ConversationToHtml {
    param(
        [array]$Messages,
        [string]$Path,
        [string]$Title,
        [CopilotConversation]$Conversation
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #0078d4, #106ebe);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        .conversation-info {
            background: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .message {
            background: white;
            margin: 10px 0;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .message-header {
            padding: 10px 15px;
            font-weight: bold;
            font-size: 0.9em;
        }
        .message-content {
            padding: 15px;
            white-space: pre-wrap;
            line-height: 1.5;
        }
        .user-message .message-header {
            background-color: #e3f2fd;
            color: #1976d2;
        }
        .assistant-message .message-header {
            background-color: #f3e5f5;
            color: #7b1fa2;
        }
        .system-message .message-header {
            background-color: #fff3e0;
            color: #f57c00;
        }
        .timestamp {
            color: #666;
            font-size: 0.8em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🤖 $Title</h1>
        <p>Microsoft Copilot Agent Conversation</p>
    </div>
    
    <div class="conversation-info">
        <h3>📋 Conversation Details</h3>
        <p><strong>ID:</strong> $($Conversation.Id)</p>
        <p><strong>Start Time:</strong> $($Conversation.StartTime)</p>
        <p><strong>Message Count:</strong> $($Messages.Count)</p>
        <p><strong>Exported:</strong> $(Get-Date)</p>
    </div>
    
    <div class="messages">
"@
    
    foreach ($message in $Messages) {
        $roleClass = "$($message.Role.ToLower())-message"
        $roleIcon = switch ($message.Role) {
            "user" { "👤" }
            "assistant" { "🤖" }
            "system" { "⚙️" }
            default { "💬" }
        }
        
        $html += @"
        <div class="message $roleClass">
            <div class="message-header">
                $roleIcon $($message.Role.ToUpper()) <span class="timestamp">$(([DateTime]$message.Timestamp).ToString('yyyy-MM-dd HH:mm:ss'))</span>
            </div>
            <div class="message-content">$([System.Web.HttpUtility]::HtmlEncode($message.Content))</div>
        </div>
"@
    }
    
    $html += @"
    </div>
    
    <div style="text-align: center; margin-top: 40px; color: #666; font-size: 0.9em;">
        <p>Generated by Copilot Agent PowerShell Module</p>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $Path -Encoding UTF8
}

function Export-ConversationToMarkdown {
    param(
        [array]$Messages,
        [string]$Path,
        [string]$Title,
        [CopilotConversation]$Conversation
    )
    
    $markdown = @"
# $Title

**Conversation ID:** $($Conversation.Id)  
**Start Time:** $($Conversation.StartTime)  
**Message Count:** $($Messages.Count)  
**Exported:** $(Get-Date)

---

"@
    
    foreach ($message in $Messages) {
        $roleIcon = switch ($message.Role) {
            "user" { "👤" }
            "assistant" { "🤖" }
            "system" { "⚙️" }
            default { "💬" }
        }
        
        $markdown += @"
## $roleIcon $($message.Role.ToUpper())
**Timestamp:** $(([DateTime]$message.Timestamp).ToString('yyyy-MM-dd HH:mm:ss'))

$($message.Content)

---

"@
    }
    
    $markdown += @"

*Generated by Copilot Agent PowerShell Module*
"@
    
    $markdown | Out-File -FilePath $Path -Encoding UTF8
}

function Export-ConversationToText {
    param(
        [array]$Messages,
        [string]$Path,
        [CopilotConversation]$Conversation
    )
    
    $text = @"
COPILOT AGENT CONVERSATION EXPORT
================================

Conversation ID: $($Conversation.Id)
Start Time: $($Conversation.StartTime)
Message Count: $($Messages.Count)
Exported: $(Get-Date)

================================

"@
    
    foreach ($message in $Messages) {
        $text += @"
[$($message.Role.ToUpper())] $(([DateTime]$message.Timestamp).ToString('yyyy-MM-dd HH:mm:ss'))
$($message.Content)

---

"@
    }
    
    $text += @"

Generated by Copilot Agent PowerShell Module
"@
    
    $text | Out-File -FilePath $Path -Encoding UTF8
}