function Start-CopilotAgent {
    param(
        [switch]$AutoConnect,
        [string]$SystemPrompt = "You are a helpful Microsoft 365 Copilot assistant."
    )
    
    Write-Host @"
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║    🤖 Microsoft Copilot Agent for PowerShell                                    ║
║    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                                    ║
║                                                                                  ║
║    AI-Powered Assistant with Microsoft 365 Integration                          ║
║    Demo Version 1.0.0                                                          ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    Write-Host "`n💡 Demo Commands:" -ForegroundColor Yellow
    Write-Host "   Type 'hello' to test the agent" -ForegroundColor Gray
    Write-Host "   Type 'meetings' to see meeting simulation" -ForegroundColor Gray
    Write-Host "   Type 'insights' to get productivity insights" -ForegroundColor Gray
    Write-Host "   Type 'help' for more commands" -ForegroundColor Gray
    Write-Host "   Type 'exit' to quit" -ForegroundColor Gray
    Write-Host ""
    
    $continue = $true
    do {
        Write-Host "You: " -ForegroundColor Blue -NoNewline
        $userInput = Read-Host
        
        if ($userInput -eq 'exit') {
            $continue = $false
            break
        }
        
        Write-Host "🤖 Copilot: " -ForegroundColor Green -NoNewline
        
        switch ($userInput.ToLower()) {
            'hello' {
                Write-Host "Hello! I'm your Microsoft Copilot assistant. I can help with emails, meetings, documents, and PowerShell tasks." -ForegroundColor White
            }
            'meetings' {
                Write-Host "Based on your calendar, you have 3 meetings today:" -ForegroundColor White
                Write-Host "  • 9:00 AM - Team Standup" -ForegroundColor Gray
                Write-Host "  • 2:00 PM - Project Review" -ForegroundColor Gray  
                Write-Host "  • 4:00 PM - Client Demo" -ForegroundColor Gray
            }
            'insights' {
                Write-Host "Here are your productivity insights:" -ForegroundColor White
                Write-Host "  • 12 unread emails (3 high priority)" -ForegroundColor Gray
                Write-Host "  • 5 documents modified today" -ForegroundColor Gray
                Write-Host "  • Next meeting in 2 hours" -ForegroundColor Gray
            }
            'help' {
                Write-Host "Available demo commands:" -ForegroundColor White
                Write-Host "  hello, meetings, insights, script, help, exit" -ForegroundColor Gray
            }
            'script' {
                Write-Host "Here's a PowerShell script template:" -ForegroundColor White
                Write-Host @"
# Get system information
Get-ComputerInfo | Select-Object WindowsProductName, TotalPhysicalMemory
Get-Process | Where-Object CPU -gt 10 | Select-Object Name, CPU
"@ -ForegroundColor Cyan
            }
            default {
                Write-Host "I understand you said '$userInput'. In a full version, I would process this with Microsoft Copilot AI and provide intelligent responses based on your Microsoft 365 data." -ForegroundColor White
            }
        }
        Write-Host ""
    } while ($continue)
    
    Write-Host "👋 Thanks for trying Copilot Agent! Install Microsoft Graph modules for full functionality." -ForegroundColor Cyan
}

function Invoke-CopilotChat {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )
    
    Write-Host "🤖 Processing: $Message" -ForegroundColor Cyan
    
    # Simulate AI response
    $responses = @{
        "email" = "You have 8 unread emails. The most recent is from your manager about the quarterly review."
        "meeting" = "Your next meeting is 'Project Standup' at 2:00 PM with 5 attendees."
        "document" = "I found 3 relevant documents in your OneDrive. Would you like me to summarize them?"
        "help" = "I can assist with emails, calendar, documents, and PowerShell scripting. What do you need help with?"
    }
    
    $keyword = $responses.Keys | Where-Object { $Message.ToLower().Contains($_) } | Select-Object -First 1
    
    if ($keyword) {
        $response = $responses[$keyword]
    } else {
        $response = "I'm a demo version of Microsoft Copilot Agent. In the full version, I would analyze your message and provide AI-powered assistance using your Microsoft 365 data."
    }
    
    Write-Host "Response: $response" -ForegroundColor Green
    return $response
}

function Get-CopilotInsights {
    param(
        [ValidateSet("meetings", "emails", "documents", "all")]
        [string]$Type = "all"
    )
    
    Write-Host "📊 Getting $Type insights..." -ForegroundColor Cyan
    
    $insights = @{
        "meetings" = @(
            "Team Standup - 9:00 AM (5 attendees)",
            "Project Review - 2:00 PM (8 attendees)", 
            "Client Demo - 4:00 PM (3 attendees)"
        )
        "emails" = @(
            "12 unread emails in inbox",
            "3 high priority messages",
            "Latest: Quarterly Review from Manager"
        )
        "documents" = @(
            "Project_Plan.docx modified 2 hours ago",
            "Budget_Analysis.xlsx modified today",
            "Meeting_Notes.docx created yesterday"
        )
    }
    
    if ($Type -eq "all") {
        foreach ($category in $insights.Keys) {
            Write-Host "`n$($category.ToUpper()):" -ForegroundColor Yellow
            $insights[$category] | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }
        }
    } else {
        Write-Host "`n$($Type.ToUpper()):" -ForegroundColor Yellow  
        $insights[$Type] | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }
    }
}

# Export functions
Export-ModuleMember -Function Start-CopilotAgent, Invoke-CopilotChat, Get-CopilotInsights

Write-Host "🤖 Copilot Agent Demo Module Loaded!" -ForegroundColor Green
Write-Host "Try: Start-CopilotAgent" -ForegroundColor Yellow