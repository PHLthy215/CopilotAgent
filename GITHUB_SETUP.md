# 🌐 Manual GitHub Setup Guide

If you prefer to set up GitHub manually or don't have GitHub CLI, follow these steps:

## 📋 Prerequisites

1. **GitHub Account**: Make sure you have a GitHub account
2. **Git Installed**: Ensure Git is installed on your system
3. **Repository Access**: You'll need permissions to create repositories

## 🚀 Step-by-Step Setup

### Step 1: Create GitHub Repository

1. **Go to GitHub**: Navigate to [github.com](https://github.com)
2. **New Repository**: Click the "+" icon → "New repository"
3. **Repository Details**:
   - **Name**: `CopilotAgent`
   - **Description**: `PowerShell Agentic LLM using Microsoft 365 Copilot AI`
   - **Visibility**: Choose Public or Private
   - **Initialize**: ❌ Don't initialize (we have files already)
4. **Create Repository**: Click "Create repository"

### Step 2: Prepare Local Repository

Open PowerShell in the CopilotAgent directory:

```powershell
# Navigate to the CopilotAgent directory
cd C:\Users\filth\CopilotAgent

# Initialize Git (if not already done)
git init
git branch -M main

# Create .gitignore file
@"
# PowerShell
*.ps1xml
*.psd1.backup
*.psm1.backup
TestResults/
*.tmp
*.log

# Windows
Thumbs.db
Desktop.ini
.DS_Store

# IDEs
.vscode/
.idea/
*.swp
*.swo

# Temporary files
temp/
tmp/
*.bak

# Node modules
node_modules/

# Logs
logs/
*.log
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8

# Add all files
git add -A

# Make initial commit
git commit -m "Initial commit: CopilotAgent PowerShell module

- Complete PowerShell module for Microsoft 365 Copilot integration
- Interactive AI chat interface  
- Microsoft Graph API integration
- Conversation management and export
- Comprehensive documentation and tests
- Enterprise-ready with logging and diagnostics"
```

### Step 3: Connect to GitHub

Replace `YOUR_USERNAME` with your actual GitHub username:

```powershell
# Add remote origin (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/CopilotAgent.git

# Push to GitHub
git push -u origin main
```

### Step 4: Update Repository URLs

Update the URLs in your files to match your repository:

```powershell
# Update CopilotAgent.psd1
$manifest = Get-Content "CopilotAgent.psd1" -Raw
$manifest = $manifest -replace 'yourusername/CopilotAgent', 'YOUR_USERNAME/CopilotAgent'
$manifest | Out-File "CopilotAgent.psd1" -Encoding UTF8

# Update README.md
$readme = Get-Content "README.md" -Raw
$readme = $readme -replace 'yourusername/CopilotAgent', 'YOUR_USERNAME/CopilotAgent'
$readme | Out-File "README.md" -Encoding UTF8

# Update CHANGELOG.md
$changelog = Get-Content "CHANGELOG.md" -Raw
$changelog = $changelog -replace 'yourusername/CopilotAgent', 'YOUR_USERNAME/CopilotAgent'
$changelog | Out-File "CHANGELOG.md" -Encoding UTF8

# Commit and push updates
git add -A
git commit -m "Update repository URLs"
git push
```

## ⚙️ Configure GitHub Repository

### Enable GitHub Actions

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. GitHub will automatically detect the workflow in `.github/workflows/ci.yml`
4. Enable Actions if prompted

### Add Repository Secrets

For PowerShell Gallery publication:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add:
   - **Name**: `PSGALLERY_API_KEY`
   - **Value**: Your PowerShell Gallery API key

### Set Repository Topics

1. Go to your repository main page
2. Click the ⚙️ gear icon next to "About"
3. Add topics: `powershell`, `copilot`, `microsoft`, `ai`, `automation`, `productivity`

### Configure Repository Settings

1. **General Settings**:
   - Enable **Issues**
   - Enable **Discussions** (recommended)
   - Enable **Projects** (optional)

2. **Branch Protection** (recommended for collaboration):
   - Go to **Settings** → **Branches**
   - Add rule for `main` branch
   - Require status checks to pass
   - Require pull request reviews

## 📦 First Release

Create your first release:

### Option 1: Via Web Interface

1. Go to **Releases** → **Create a new release**
2. **Tag**: `v1.0.0`
3. **Title**: `CopilotAgent v1.0.0`
4. **Description**: Copy from CHANGELOG.md
5. **Publish release**

### Option 2: Via Command Line

```powershell
# Create and push tag
git tag v1.0.0
git push origin v1.0.0

# Then create release via web interface
```

## 🔧 Repository Customization

### Add Repository Badge

Add this to the top of your README.md:

```markdown
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/CopilotAgent.svg)](https://www.powershellgallery.com/packages/CopilotAgent)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Issues](https://img.shields.io/github/issues/YOUR_USERNAME/CopilotAgent)](https://github.com/YOUR_USERNAME/CopilotAgent/issues)
[![GitHub Stars](https://img.shields.io/github/stars/YOUR_USERNAME/CopilotAgent)](https://github.com/YOUR_USERNAME/CopilotAgent/stargazers)
```

### Create Repository Icon

1. Create a 512x512 PNG icon for your module
2. Add to `docs/icon.png` in your repository
3. Update the IconUri in CopilotAgent.psd1

## 🎯 Verification Checklist

After setup, verify everything works:

- [ ] Repository is accessible at `https://github.com/YOUR_USERNAME/CopilotAgent`
- [ ] All files are present and readable
- [ ] CI/CD workflow runs successfully
- [ ] Issues and Discussions are enabled
- [ ] Repository has proper description and topics
- [ ] README displays correctly with badges
- [ ] License file is recognized by GitHub

## 🚀 What's Next?

1. **Share Your Module**: 
   - Post on PowerShell communities
   - Share on social media
   - Submit to PowerShell Gallery

2. **Monitor and Maintain**:
   - Watch for issues and discussions
   - Respond to community feedback
   - Plan future features

3. **Collaborate**:
   - Accept pull requests
   - Recognize contributors
   - Build a community

## 🆘 Troubleshooting

### Common Issues

**Authentication Problems**:
```powershell
# Configure Git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Use GitHub CLI for authentication
gh auth login
```

**Push Rejected**:
```powershell
# If remote has changes you don't have locally
git pull origin main --allow-unrelated-histories
git push origin main
```

**Large File Issues**:
```powershell
# Remove large files from history if needed
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch large-file.ext' --prune-empty --tag-name-filter cat -- --all
```

---

🎉 **Congratulations!** Your CopilotAgent module is now on GitHub and ready for the community!