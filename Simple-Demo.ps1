function Start-CopilotDemo {
    Write-Host "Microsoft Copilot Agent Demo" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This PowerShell module provides:" -ForegroundColor Green
    Write-Host "- Interactive AI chat with Microsoft Copilot" -ForegroundColor White
    Write-Host "- Microsoft 365 integration for emails, meetings, documents" -ForegroundColor White
    Write-Host "- Conversation management and export capabilities" -ForegroundColor White
    Write-Host "- Configurable settings and authentication" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Demo conversation:" -ForegroundColor Yellow
    Write-Host "You: What meetings do I have today?" -ForegroundColor Blue
    Write-Host "Copilot: Based on your calendar, you have 3 meetings:" -ForegroundColor Green
    Write-Host "  - 9:00 AM Team Standup" -ForegroundColor Gray
    Write-Host "  - 2:00 PM Project Review" -ForegroundColor Gray
    Write-Host "  - 4:00 PM Client Demo" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "You: Help me write a PowerShell script" -ForegroundColor Blue
    Write-Host "Copilot: Here's a PowerShell template:" -ForegroundColor Green
    Write-Host "Get-Process | Where-Object CPU -gt 10" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Module is ready to install!" -ForegroundColor Green
    Write-Host "Location: C:\Users\filth\CopilotAgent\" -ForegroundColor Yellow
}

Start-CopilotDemo