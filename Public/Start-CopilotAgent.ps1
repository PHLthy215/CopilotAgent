function Start-CopilotAgent {
    <#
    .SYNOPSIS
        Start an interactive Copilot Agent session
    
    .DESCRIPTION
        Launches an interactive command-line interface for chatting with Microsoft Copilot.
        Provides a rich conversational experience with built-in commands, context management,
        and integration with Microsoft 365 services through Microsoft Graph.
        
        Features:
        • Interactive chat with Microsoft Copilot AI
        • Persistent conversation context
        • Built-in commands (/help, /connect, /status, etc.)
        • Microsoft 365 integration (emails, calendar, documents)
        • Automatic conversation saving (optional)
        • Rich terminal interface with color coding
        • Error handling and recovery
        
        Security:
        • Requires explicit authentication via Microsoft Graph
        • Respects organizational policies and permissions  
        • No local storage of sensitive data
        • Audit trail through Microsoft 365 logs
    
    .PARAMETER AutoConnect
        Automatically connect to Microsoft Graph on startup using required scopes:
        - User.Read: Basic profile information
        - Mail.Read: Email access for insights
        - Calendars.Read: Calendar integration
        - Files.Read.All: Document access
        - Chat.Read: Teams chat integration (when available)
        
        If connection fails, users can manually connect using /connect command.
    
    .PARAMETER SystemPrompt
        Custom system prompt to guide the AI's behavior and personality.
        Default: "You are a helpful Microsoft 365 Copilot assistant integrated with PowerShell..."
        
        Examples:
        - "You are a PowerShell scripting expert"
        - "You are a business productivity consultant"
        - "You are a Microsoft 365 administrator assistant"
        
        Maximum length: 1000 characters
    
    .PARAMETER SaveConversation
        Automatically save conversation history to disk after each interaction.
        When enabled, creates conversation files in JSON format for later analysis.
        Files are saved with timestamps and can be exported in various formats.
        
        Note: No sensitive data (tokens, passwords) is included in saved conversations.
    
    .EXAMPLE
        Start-CopilotAgent
        
        Starts the interactive agent with default settings.
        User must manually connect to Microsoft Graph using /connect command.
    
    .EXAMPLE
        Start-CopilotAgent -AutoConnect
        
        Starts the agent and automatically attempts to connect to Microsoft Graph.
        Will prompt for authentication if not already signed in.
    
    .EXAMPLE
        Start-CopilotAgent -AutoConnect -SystemPrompt "You are a PowerShell scripting expert" -SaveConversation
        
        Starts with automatic connection, custom AI personality, and conversation saving enabled.
        Perfect for PowerShell learning and script development sessions.
    
    .EXAMPLE
        Start-CopilotAgent -SystemPrompt "You are a business analyst assistant focused on Microsoft 365 productivity"
        
        Customizes the AI to focus on business analysis and productivity tasks.
        User connects manually when needed for specific integrations.
        
    .NOTES
        Interactive Commands Available:
        /help      - Show help and available commands
        /connect   - Connect to Microsoft Graph
        /status    - Show connection and user information
        /insights  - Get recent Microsoft 365 insights
        /save      - Save current conversation
        /clear     - Clear conversation history
        /exit      - Exit the agent gracefully
        
        Tips for Best Results:
        • Use natural language questions
        • Be specific about what you need
        • Mention specific Microsoft 365 apps when relevant
        • Ask follow-up questions for clarification
        • Use /insights for productivity information
        
        Troubleshooting:
        • If connection fails, check network and permissions
        • Use /status to verify authentication state  
        • Enable verbose logging with $VerbosePreference = 'Continue'
        • Export diagnostics with Export-CopilotDiagnostics
        
    .LINK
        https://github.com/yourusername/CopilotAgent
        
    .LINK
        https://docs.microsoft.com/graph/overview
        
    .LINK  
        Get-CopilotInsights
        
    .LINK
        Invoke-CopilotChat
        
    .LINK
        Export-CopilotConversation
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$AutoConnect,
        
        [Parameter()]
        [ValidateLength(10, 1000)]
        [string]$SystemPrompt = "You are a helpful Microsoft 365 Copilot assistant integrated with PowerShell. You can help with productivity tasks, document analysis, meeting insights, and PowerShell scripting.",
        
        [Parameter()]
        [switch]$SaveConversation
    )
    
    # Display welcome banner
    Show-CopilotBanner
    
    # Auto-connect if requested
    if ($AutoConnect) {
        Write-Host "🔗 Auto-connecting to Microsoft Graph..." -ForegroundColor Yellow
        try {
            Connect-MgGraph -Scopes @(
                "User.Read",
                "Mail.Read", 
                "Calendars.Read",
                "Files.Read.All",
                "Chat.Read"
            ) -NoWelcome
            Write-Host "✅ Connected successfully!" -ForegroundColor Green
        } catch {
            Write-Warning "Auto-connect failed: $($_.Exception.Message)"
            Write-Host "Use '/connect' command to connect manually." -ForegroundColor Yellow
        }
    }
    
    # Create new conversation
    $conversation = New-CopilotConversation -InitialContext @{
        SystemPrompt = $SystemPrompt
        StartTime = Get-Date
        SaveEnabled = $SaveConversation.IsPresent
    }
    
    Write-Host "`n💡 Type your message, or use commands like:" -ForegroundColor Cyan
    Write-Host "   /help     - Show help" -ForegroundColor Gray
    Write-Host "   /connect  - Connect to Microsoft Graph" -ForegroundColor Gray
    Write-Host "   /status   - Show connection status" -ForegroundColor Gray
    Write-Host "   /save     - Save conversation" -ForegroundColor Gray
    Write-Host "   /clear    - Clear conversation history" -ForegroundColor Gray
    Write-Host "   /exit     - Exit the agent" -ForegroundColor Gray
    Write-Host ""
    
    # Main interaction loop
    do {
        Write-Host "You: " -ForegroundColor Blue -NoNewline
        $userInput = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($userInput)) {
            continue
        }
        
        # Handle commands
        switch ($userInput.ToLower()) {
            "/exit" { 
                $continue = $false 
                break
            }
            
            "/help" {
                Show-CopilotHelp
                continue
            }
            
            "/connect" {
                try {
                    Connect-MgGraph -Scopes @(
                        "User.Read",
                        "Mail.Read", 
                        "Calendars.Read",
                        "Files.Read.All",
                        "Chat.Read"
                    ) -NoWelcome
                    Write-Host "✅ Connected to Microsoft Graph" -ForegroundColor Green
                } catch {
                    Write-Error "Connection failed: $($_.Exception.Message)"
                }
                continue
            }
            
            "/status" {
                Show-ConnectionStatus
                continue
            }
            
            "/save" {
                if ($SaveConversation -or $conversation.GetContext("SaveEnabled")) {
                    Save-ConversationHistory -Conversation $conversation
                } else {
                    Write-Host "💾 Conversation saving not enabled. Use -SaveConversation parameter." -ForegroundColor Yellow
                }
                continue
            }
            
            "/clear" {
                $conversation = New-CopilotConversation -InitialContext @{
                    SystemPrompt = $SystemPrompt
                    StartTime = Get-Date
                    SaveEnabled = $SaveConversation.IsPresent
                }
                Write-Host "🧹 Conversation history cleared." -ForegroundColor Green
                continue
            }
            
            "/insights" {
                try {
                    $insights = Get-CopilotInsights -Type "recent"
                    Write-Host "📊 Recent Insights:" -ForegroundColor Cyan
                    $insights | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }
                } catch {
                    Write-Warning "Could not retrieve insights: $($_.Exception.Message)"
                }
                continue
            }
            
            default {
                # Regular chat message
                try {
                    $response = Invoke-CopilotChat -Message $userInput -Conversation $conversation -SystemPrompt $SystemPrompt -IncludeContext
                    $conversation = $response.Conversation
                    
                    # Auto-save if enabled
                    if ($SaveConversation -or $conversation.GetContext("SaveEnabled")) {
                        Save-ConversationHistory -Conversation $conversation
                    }
                    
                } catch {
                    Write-Error "Error processing message: $($_.Exception.Message)"
                }
            }
        }
        
        Write-Host ""
        
    } while ($continue -ne $false)
    
    # Farewell message
    Write-Host "👋 Thanks for using Copilot Agent! Goodbye!" -ForegroundColor Cyan
    
    # Final save if enabled
    if ($SaveConversation -or $conversation.GetContext("SaveEnabled")) {
        Save-ConversationHistory -Conversation $conversation
    }
}

function Show-CopilotBanner {
    Write-Host @"
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║    🤖 Microsoft Copilot Agent for PowerShell                                    ║
║    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                                    ║
║                                                                                  ║
║    AI-Powered Assistant with Microsoft 365 Integration                          ║
║    Version 1.0.0                                                               ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
}

function Show-CopilotHelp {
    Write-Host @"
🤖 Copilot Agent Commands:

Chat Commands:
  /help           Show this help message
  /connect        Connect to Microsoft Graph
  /status         Show connection status
  /insights       Get recent Microsoft 365 insights
  
Conversation Management:
  /save           Save current conversation
  /clear          Clear conversation history
  /exit           Exit the agent

Tips:
• Ask about your emails, meetings, or documents
• Request PowerShell scripts or automation help
• Use natural language for best results
• The agent maintains conversation context

Examples:
  "What meetings do I have today?"
  "Help me write a script to backup files"
  "Summarize my recent emails from the team"

"@ -ForegroundColor Yellow
}

function Show-ConnectionStatus {
    if (Test-CopilotConnection) {
        Write-Host "🟢 Status: Connected to Microsoft Graph" -ForegroundColor Green
        
        try {
            $me = Invoke-CopilotApiRequest -Endpoint "$($Script:CopilotConfig.GraphEndpoint)/me" -Method 'GET'
            Write-Host "👤 User: $($me.displayName) ($($me.userPrincipalName))" -ForegroundColor White
            Write-Host "🏢 Organization: $($me.companyName)" -ForegroundColor White
        } catch {
            Write-Host "⚠️  Could not retrieve user details" -ForegroundColor Yellow
        }
    } else {
        Write-Host "🔴 Status: Not connected" -ForegroundColor Red
        Write-Host "Use '/connect' to establish connection" -ForegroundColor Yellow
    }
}