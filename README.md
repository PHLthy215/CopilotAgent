# 🤖 CopilotAgent PowerShell Module

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/CopilotAgent.svg)](https://www.powershellgallery.com/packages/CopilotAgent)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI/CD](https://github.com/yourusername/CopilotAgent/workflows/CI/CD%20Pipeline/badge.svg)](https://github.com/yourusername/CopilotAgent/actions)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207.x-blue.svg)](https://github.com/PowerShell/PowerShell)

> **Bring Microsoft 365 Copilot AI directly to your PowerShell command line!**

An intelligent PowerShell module that integrates with Microsoft 365 Copilot to provide AI-powered assistance, productivity insights, and automated workflows directly from your terminal.

---

## 🌟 Features

- 🗣️ **Interactive AI Chat** - Conversational interface with Microsoft Copilot
- 📊 **Microsoft 365 Integration** - Access emails, calendar, documents, and Teams data  
- 💭 **Smart Context** - Maintains conversation history and context awareness
- 📤 **Export Anywhere** - Save conversations in JSON, HTML, Markdown, CSV, or Text
- ⚙️ **Fully Configurable** - Customize API endpoints, timeouts, and behaviors
- 🔐 **Enterprise Ready** - Secure OAuth 2.0 authentication with conditional access support
- 🚀 **Cross-Platform** - Works on PowerShell 5.1+ and PowerShell 7.x

## 🎯 Quick Start

### Installation

```powershell
# From PowerShell Gallery (recommended)
Install-Module -Name CopilotAgent -Scope CurrentUser

# Or clone and install manually
git clone https://github.com/yourusername/CopilotAgent.git
cd CopilotAgent
.\Install-Simple.ps1
```

### First Run

```powershell
# Import the module
Import-Module CopilotAgent

# Start interactive session with auto-connect
Start-CopilotAgent -AutoConnect

# Or use direct commands
Invoke-CopilotChat -Message "What meetings do I have today?"
```

## 💻 Usage Examples

### Interactive Chat Session
```powershell
PS> Start-CopilotAgent -AutoConnect

╔══════════════════════════════════════════════════════════════════════════════════╗
║    🤖 Microsoft Copilot Agent for PowerShell                                    ║
║    AI-Powered Assistant with Microsoft 365 Integration                          ║
╚══════════════════════════════════════════════════════════════════════════════════╝

You: What's on my calendar today?
🤖 Copilot: You have 3 meetings today:
  • 9:00 AM - Team Standup (30 min)
  • 2:00 PM - Project Review (1 hour) 
  • 4:00 PM - Client Demo (45 min)

You: Help me write a PowerShell script to backup my documents
🤖 Copilot: Here's a PowerShell backup script for your documents:

# Backup script with date stamping
$backupPath = "C:\Backup\Documents_$(Get-Date -Format 'yyyy-MM-dd')"
Copy-Item -Path $env:USERPROFILE\Documents -Destination $backupPath -Recurse
```

### Direct Command Usage
```powershell
# Get meeting insights for today
Get-CopilotInsights -Type "meetings" -TimeRange "today"

# Analyze recent emails
Get-CopilotInsights -Type "emails" -TimeRange "week" -MaxResults 10

# Send a targeted question with context
Invoke-CopilotChat -Message "Summarize the key points from my team meeting yesterday" -IncludeContext

# Export your conversation
$conversation = Invoke-CopilotChat -Message "Hello!" -Conversation $myConv
Export-CopilotConversation -Conversation $conversation -Path "chat.html" -Format HTML
```

### Productivity Automation
```powershell
# Morning briefing script
function Get-MorningBriefing {
    Write-Host "📅 Your Morning Briefing" -ForegroundColor Cyan
    
    # Get today's meetings
    Get-CopilotInsights -Type "meetings" -TimeRange "today"
    
    # Check important emails
    Invoke-CopilotChat -Message "Show me high priority emails from the last 24 hours" -IncludeContext
    
    # Recent document activity
    Get-CopilotInsights -Type "documents" -MaxResults 5
}

Get-MorningBriefing
```

### Configuration Management
```powershell
# View current configuration
Set-CopilotConfiguration -ShowCurrent

# Customize settings
Set-CopilotConfiguration -TimeoutSeconds 60 -MaxRetries 5

# Export your configuration
Export-CopilotConfiguration -Path "my-copilot-config.json"

# Load configuration from file
Import-CopilotConfiguration -Path "my-copilot-config.json"
```

## 📋 Available Commands

| Command | Description | Example |
|---------|-------------|---------|
| `Start-CopilotAgent` | Launch interactive chat interface | `Start-CopilotAgent -AutoConnect` |
| `Invoke-CopilotChat` | Send direct messages to Copilot | `Invoke-CopilotChat -Message "Help me with emails"` |
| `Get-CopilotInsights` | Get Microsoft 365 insights | `Get-CopilotInsights -Type "all" -TimeRange "week"` |
| `Set-CopilotConfiguration` | Manage module settings | `Set-CopilotConfiguration -ShowCurrent` |
| `Export-CopilotConversation` | Export conversations | `Export-CopilotConversation -Path "chat.json" -Format JSON` |

### Interactive Commands
When using `Start-CopilotAgent`, you have access to these built-in commands:

| Command | Action |
|---------|--------|
| `/help` | Show available commands |
| `/connect` | Connect to Microsoft Graph |
| `/status` | Show connection status |
| `/insights` | Get recent productivity insights |
| `/save` | Save current conversation |
| `/clear` | Clear conversation history |
| `/exit` | Exit the agent |

## 🔧 Configuration

### Authentication Setup

The module uses Microsoft Graph authentication with OAuth 2.0:

```powershell
# Connect with required permissions
Connect-MgGraph -Scopes @(
    "User.Read",           # Basic user information
    "Mail.Read",           # Email access
    "Calendars.Read",      # Calendar access
    "Files.Read.All",      # OneDrive/SharePoint files
    "Chat.Read"            # Teams chat (when available)
)
```

### Environment Variables
You can also set configuration via environment variables:

```powershell
# PowerShell
$env:COPILOT_TIMEOUT_SECONDS = "60"
$env:COPILOT_MAX_RETRIES = "5"

# Command Prompt
set COPILOT_TIMEOUT_SECONDS=60
set COPILOT_MAX_RETRIES=5
```

### Configuration File
Create a `copilot-config.json` file for persistent settings:

```json
{
  "GraphEndpoint": "https://graph.microsoft.com/v1.0",
  "CopilotEndpoint": "https://graph.microsoft.com/v1.0/copilot",
  "TimeoutSeconds": 30,
  "MaxRetries": 3,
  "EnableTelemetry": true,
  "LogLevel": "Information"
}
```

## 🏢 Enterprise Features

### Conditional Access Support
The module respects your organization's conditional access policies and security requirements.

### Audit Logging
All API calls are logged and can be monitored through Microsoft 365 audit logs.

### Compliance
- Data residency compliance through Microsoft Graph
- Sensitivity label support for documents
- DLP (Data Loss Prevention) integration

### Scale Considerations
- Automatic throttling and retry logic
- Connection pooling for large organizations
- Efficient token management and refresh

## 🔒 Security & Privacy

- **🛡️ Secure Authentication** - OAuth 2.0 with PKCE
- **🏢 Enterprise Policies** - Respects conditional access and MFA requirements
- **📊 Audit Trail** - All activities logged in Microsoft 365 audit center
- **🔐 Zero Storage** - No credentials stored locally
- **🎯 Minimal Permissions** - Only requests necessary scopes
- **🌐 Data Residency** - All data processing through Microsoft Graph APIs
- **🚫 Privacy First** - Telemetry disabled by default, explicit opt-in required
- **🔍 Path Validation** - Prevents directory traversal in file operations
- **📋 Secure Logging** - No sensitive data in logs or telemetry

## 📊 Insights & Analytics

### Available Insight Types

```powershell
# Meeting insights
Get-CopilotInsights -Type "meetings" -TimeRange "today"
# Output: Today's meetings with attendee count, duration, and context

# Email analysis  
Get-CopilotInsights -Type "emails" -TimeRange "week"
# Output: Email volume, high-priority messages, sender analysis

# Document activity
Get-CopilotInsights -Type "documents" -MaxResults 10
# Output: Recently modified files, collaboration activity

# Combined insights
Get-CopilotInsights -Type "all" -TimeRange "month"
# Output: Comprehensive productivity overview
```

### Custom Insights
```powershell
# Create custom insight queries
Invoke-CopilotChat -Message "Show me productivity trends for Q1" -IncludeContext
Invoke-CopilotChat -Message "Which projects am I spending the most time on?" -IncludeContext
```

## 💾 Export Formats

Export your conversations in multiple formats:

### HTML Export
```powershell
Export-CopilotConversation -Conversation $conv -Path "meeting-prep.html" -Format HTML -Title "Meeting Preparation Chat"
```
Creates a styled HTML file perfect for sharing or archiving.

### Markdown Export  
```powershell
Export-CopilotConversation -Conversation $conv -Path "project-discussion.md" -Format Markdown
```
Great for documentation and version control.

### JSON Export
```powershell
Export-CopilotConversation -Conversation $conv -Path "data.json" -Format JSON -IncludeMetadata
```
Machine-readable format with full metadata for analysis.

### CSV Export
```powershell
Export-CopilotConversation -Conversation $conv -Path "chat-log.csv" -Format CSV
```
Perfect for data analysis in Excel or other tools.

## 🛠️ Development & Contributing

### Prerequisites
- PowerShell 5.1+ or PowerShell 7.x
- Microsoft 365 account with Copilot license
- Visual Studio Code (recommended)
- Pester for testing

### Setup Development Environment
```powershell
# Clone the repository
git clone https://github.com/yourusername/CopilotAgent.git
cd CopilotAgent

# Install development dependencies
Install-Module -Name Pester -Force
Install-Module -Name PSScriptAnalyzer -Force

# Run tests
Invoke-Pester .\Tests\

# Run code analysis
Invoke-ScriptAnalyzer -Path . -Recurse
```

### Contributing Guidelines
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Ensure all tests pass (`Invoke-Pester`)
5. Run code analysis (`Invoke-ScriptAnalyzer`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## ⚠️ Requirements

### System Requirements
- **Operating System**: Windows 10/11, Windows Server 2016+
- **PowerShell**: 5.1 or higher (PowerShell 7.x recommended)
- **Memory**: 100MB+ available RAM
- **Network**: Internet connection for Microsoft Graph API access

### Microsoft 365 Requirements
- **License**: Microsoft 365 with Copilot license (E3/E5 or Business Premium with Copilot)
- **Permissions**: Appropriate roles for accessing Graph APIs
- **Tenant**: Azure AD tenant with Microsoft 365 services enabled

### Dependencies
The following PowerShell modules are automatically installed:
- `Microsoft.Graph.Authentication` (≥2.0.0)
- `Microsoft.Graph.Applications` (≥2.0.0)
- `Microsoft.Graph.Users` (≥2.0.0)
- `Microsoft.Graph.Mail` (≥2.0.0)
- `Microsoft.Graph.Calendar` (≥2.0.0)
- `Microsoft.Graph.Files` (≥2.0.0)

## 🤝 Support

### Getting Help
- 📖 **Documentation**: [Full documentation](https://github.com/yourusername/CopilotAgent/wiki)
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/yourusername/CopilotAgent/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/yourusername/CopilotAgent/discussions)
- 💬 **Community**: [PowerShell Community Slack](https://powershellcommunity.slack.com)

### Built-in Help
```powershell
# Get help for any command
Get-Help Start-CopilotAgent -Full
Get-Help Invoke-CopilotChat -Examples
Get-Help Get-CopilotInsights -Parameter Type

# Show configuration help
Set-CopilotConfiguration -ShowCurrent
```

### Troubleshooting
```powershell
# Check connection status
Start-CopilotAgent
/status

# Test authentication
Connect-MgGraph -Scopes "User.Read"
Get-MgContext

# Enable verbose logging
Set-CopilotConfiguration -LogLevel "Verbose"
```

## 📈 Roadmap

### v1.1.0 (Q2 2025)
- [ ] Enhanced Teams integration
- [ ] Custom plugin system
- [ ] Advanced automation workflows
- [ ] Performance optimizations

### v1.2.0 (Q3 2025)  
- [ ] Multi-tenant support
- [ ] Advanced analytics dashboard
- [ ] Integration with Azure DevOps
- [ ] Custom AI model support

### v2.0.0 (Q4 2025)
- [ ] Complete Copilot API integration (when available)
- [ ] Real-time collaboration features
- [ ] Advanced security features
- [ ] Enterprise management portal

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Microsoft Graph team for the excellent APIs
- PowerShell community for continuous inspiration  
- Microsoft 365 Copilot team for the AI capabilities
- Contributors who make this project better

---

<div align="center">

**⭐ Star this repository if you find it useful!**

[Report Bug](https://github.com/yourusername/CopilotAgent/issues) · [Request Feature](https://github.com/yourusername/CopilotAgent/discussions) · [Documentation](https://github.com/yourusername/CopilotAgent/wiki)

</div>