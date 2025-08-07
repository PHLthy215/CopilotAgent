# Contributing to CopilotAgent

Thank you for your interest in contributing to the CopilotAgent PowerShell module! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues
1. **Search existing issues** first to avoid duplicates
2. **Use issue templates** for bug reports and feature requests
3. **Provide detailed information** including:
   - PowerShell version
   - Operating system
   - Module version
   - Steps to reproduce
   - Expected vs actual behavior

### Suggesting Features
1. **Check the roadmap** in README.md first
2. **Open a discussion** in GitHub Discussions for major features
3. **Use the feature request template** for formal requests
4. **Explain the use case** and business value

### Pull Requests
1. **Fork the repository** and create a feature branch
2. **Follow naming conventions**: `feature/description` or `fix/description`
3. **Write clear commit messages** using conventional commits format
4. **Add tests** for new functionality
5. **Update documentation** as needed
6. **Ensure all checks pass** before submitting

## 🛠️ Development Setup

### Prerequisites
```powershell
# Required tools
Install-Module -Name Pester -Force
Install-Module -Name PSScriptAnalyzer -Force
Install-Module -Name platyPS -Force  # For help generation

# Microsoft Graph modules (for testing)
Install-Module -Name Microsoft.Graph.Authentication -Force
Install-Module -Name Microsoft.Graph.Applications -Force
```

### Local Development
```powershell
# Clone your fork
git clone https://github.com/yourusername/CopilotAgent.git
cd CopilotAgent

# Create a feature branch
git checkout -b feature/my-awesome-feature

# Import module for testing
Import-Module .\CopilotAgent.psd1 -Force

# Run tests
Invoke-Pester .\Tests\

# Run code analysis
Invoke-ScriptAnalyzer -Path . -Recurse
```

## 📝 Coding Standards

### PowerShell Style Guide
- Follow [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines)
- Use **PascalCase** for functions and parameters
- Use **camelCase** for variables
- Use **kebab-case** for file names
- **Indent with 4 spaces**, no tabs

### Function Structure
```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Brief description of what the function does
    
    .DESCRIPTION
        Detailed description with usage scenarios
    
    .PARAMETER ParameterName
        Description of the parameter
    
    .EXAMPLE
        Verb-Noun -ParameterName "value"
        
        Description of what this example does
    
    .NOTES
        Additional information
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ParameterName,
        
        [Parameter()]
        [switch]$OptionalSwitch
    )
    
    begin {
        # Initialization code
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    }
    
    process {
        try {
            # Main logic here
            
        } catch {
            Write-Error "Error in $($MyInvocation.MyCommand): $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        # Cleanup code
        Write-Verbose "Completed $($MyInvocation.MyCommand)"
    }
}
```

### Error Handling
- Use **try/catch blocks** for error handling
- **Write meaningful error messages** with context
- **Use Write-Error** for non-terminating errors
- **Use throw** for terminating errors
- **Include function name** in error messages

### Documentation
- **Comment-based help** for all public functions
- **Inline comments** for complex logic
- **Parameter validation** with appropriate attributes
- **Example usage** in help documentation

## 🧪 Testing Guidelines

### Test Structure
```powershell
Describe "Function Name Tests" {
    Context "Normal Operation" {
        It "Should do expected behavior" {
            # Arrange
            $input = "test value"
            
            # Act
            $result = Invoke-Function -Parameter $input
            
            # Assert
            $result | Should -Be "expected output"
        }
    }
    
    Context "Error Conditions" {
        It "Should throw when parameter is invalid" {
            { Invoke-Function -Parameter $null } | Should -Throw
        }
    }
}
```

### Test Coverage
- **Unit tests** for all public functions
- **Integration tests** for complex workflows
- **Error condition testing** for robustness
- **Mock external dependencies** (Microsoft Graph APIs)

### Running Tests
```powershell
# Run all tests
Invoke-Pester .\Tests\

# Run specific test file
Invoke-Pester .\Tests\CopilotAgent.Tests.ps1

# Run with coverage
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\Public\*.ps1', '.\Private\*.ps1'
Invoke-Pester -Configuration $config
```

## 📦 Module Structure

```
CopilotAgent/
├── .github/                    # GitHub templates and workflows
│   ├── workflows/
│   ├── ISSUE_TEMPLATE/
│   └── pull_request_template.md
├── Public/                     # Public functions (exported)
│   ├── Start-CopilotAgent.ps1
│   ├── Invoke-CopilotChat.ps1
│   └── ...
├── Private/                    # Internal functions
│   ├── CopilotApiClient.ps1
│   ├── ConversationManager.ps1
│   └── ...
├── Tests/                      # Pester tests
│   ├── CopilotAgent.Tests.ps1
│   └── ...
├── docs/                       # Additional documentation
├── CopilotAgent.psd1          # Module manifest
├── CopilotAgent.psm1          # Module loader
├── README.md                   # Main documentation
├── CHANGELOG.md               # Version history
├── CONTRIBUTING.md            # This file
├── LICENSE                    # MIT license
└── Publish-Module.ps1         # Publication script
```

## 🔄 Release Process

### Version Numbers
We follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist
1. **Update version** in CopilotAgent.psd1
2. **Update CHANGELOG.md** with new version
3. **Run full test suite** and ensure all pass
4. **Update documentation** if needed
5. **Create pull request** to main branch
6. **Tag release** after merge
7. **Publish to PowerShell Gallery** via CI/CD

### Changelog Format
```markdown
## [1.1.0] - 2025-02-01

### Added
- New feature X that enables Y
- Support for Z configuration

### Changed  
- Improved performance of function A
- Enhanced error messages in module B

### Fixed
- Bug where X would fail under condition Y
- Authentication issue with Graph API

### Deprecated
- Parameter X in function Y (use Z instead)

### Removed
- Legacy function X (replaced by Y)

### Security
- Fixed potential security issue in authentication flow
```

## 🏗️ Architecture Guidelines

### Separation of Concerns
- **Public functions**: User-facing cmdlets in `/Public`
- **Private functions**: Internal helpers in `/Private`
- **Classes**: Complex data structures
- **Configuration**: Centralized in module variables

### API Integration
- **Abstract API calls** in dedicated client functions
- **Handle authentication** centrally
- **Implement retry logic** for resilience
- **Mock APIs** in tests

### Performance Considerations
- **Lazy loading** of heavy modules
- **Connection reuse** for Graph API
- **Efficient data structures** for conversations
- **Minimal memory footprint**

## 🔒 Security Guidelines

### Authentication
- **Never store credentials** in code or logs
- **Use secure authentication flows** (OAuth 2.0)
- **Respect token lifetimes** and refresh appropriately
- **Handle MFA scenarios** gracefully

### Data Handling
- **Minimize data collection** 
- **Secure data transmission** via HTTPS
- **Respect sensitivity labels** on documents
- **Follow data residency requirements**

### Code Security
- **Validate all inputs** 
- **Sanitize outputs** 
- **Use parameterized queries** where applicable
- **Avoid code injection** vulnerabilities

## 📖 Documentation Standards

### README Updates
- Keep **feature lists** current
- Update **examples** with new functionality
- Maintain **compatibility information**
- Include **troubleshooting** for common issues

### Code Comments
```powershell
# Single-line comments for brief explanations

<#
Multi-line comments for complex explanations
that need more detail or context
#>

# TODO: Future enhancement needed
# HACK: Temporary workaround for issue #123
# NOTE: Important consideration for maintainers
```

### Help Documentation
- **Synopsis**: One-line description
- **Description**: Detailed explanation
- **Parameters**: All parameters documented
- **Examples**: Multiple real-world examples
- **Notes**: Implementation details or caveats

## 🤔 Questions?

- **General questions**: Use [GitHub Discussions](https://github.com/yourusername/CopilotAgent/discussions)
- **Bug reports**: Use [GitHub Issues](https://github.com/yourusername/CopilotAgent/issues)
- **Feature requests**: Use [GitHub Issues](https://github.com/yourusername/CopilotAgent/issues) with feature template
- **Security issues**: Email security@yourorganization.com

## 🙏 Recognition

Contributors will be recognized in:
- **CHANGELOG.md** for their contributions
- **README.md** acknowledgments section
- **GitHub contributors** page
- **Release notes** for significant contributions

Thank you for contributing to CopilotAgent! 🚀