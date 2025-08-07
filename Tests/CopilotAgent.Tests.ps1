BeforeAll {
    # Import the module for testing
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModuleRoot\CopilotAgent.psd1" -Force
}

Describe "CopilotAgent Module Tests" {

    Context "Module Loading" {
        It "Should import the module without errors" {
            { Import-Module CopilotAgent -Force } | Should -Not -Throw
        }

        It "Should export the expected functions" {
            $expectedFunctions = @(
                'Start-CopilotAgent',
                'Invoke-CopilotChat',
                'Get-CopilotInsights',
                'Set-CopilotConfiguration',
                'Export-CopilotConversation'
            )

            $exportedFunctions = (Get-Command -Module CopilotAgent).Name

            foreach ($function in $expectedFunctions) {
                $exportedFunctions | Should -Contain $function
            }
        }
    }

    Context "Module Manifest" {
        It "Should have a valid module manifest" {
            $manifest = Test-ModuleManifest -Path "$ModuleRoot\CopilotAgent.psd1"
            $manifest | Should -Not -BeNullOrEmpty
        }

        It "Should have correct module version format" {
            $manifest = Test-ModuleManifest -Path "$ModuleRoot\CopilotAgent.psd1"
            $manifest.Version | Should -Match '^\d+\.\d+\.\d+$'
        }

        It "Should have required metadata" {
            $manifest = Test-ModuleManifest -Path "$ModuleRoot\CopilotAgent.psd1"
            $manifest.Author | Should -Not -BeNullOrEmpty
            $manifest.Description | Should -Not -BeNullOrEmpty
            $manifest.GUID | Should -Not -BeNullOrEmpty
        }

        It "Should specify minimum PowerShell version" {
            $manifest = Test-ModuleManifest -Path "$ModuleRoot\CopilotAgent.psd1"
            $manifest.PowerShellVersion | Should -Not -BeNullOrEmpty
            [Version]$manifest.PowerShellVersion | Should -BeGreaterThan ([Version]'5.0')
        }
    }
}

Describe "Configuration Management Tests" {

    Context "Set-CopilotConfiguration" {
        It "Should show current configuration without errors" {
            { Set-CopilotConfiguration -ShowCurrent } | Should -Not -Throw
        }

        It "Should accept timeout parameter" {
            { Set-CopilotConfiguration -TimeoutSeconds 60 } | Should -Not -Throw
        }

        It "Should accept max retries parameter" {
            { Set-CopilotConfiguration -MaxRetries 5 } | Should -Not -Throw
        }
    }
}

Describe "Conversation Management Tests" {

    Context "Conversation Class" {
        BeforeAll {
            # Load the conversation manager
            . "$ModuleRoot\Private\ConversationManager.ps1"
        }

        It "Should create new conversation" {
            { New-CopilotConversation } | Should -Not -Throw
        }

        It "Should add messages to conversation" {
            $conv = New-CopilotConversation
            { $conv.AddMessage("user", "test message") } | Should -Not -Throw
            $conv.GetMessages().Count | Should -Be 2  # System + user message
        }

        It "Should maintain conversation context" {
            $conv = New-CopilotConversation
            $conv.SetContext("TestKey", "TestValue")
            $conv.GetContext("TestKey") | Should -Be "TestValue"
        }
    }
}

Describe "Export Functionality Tests" {

    Context "Export-CopilotConversation" {
        BeforeAll {
            # Create a test conversation
            . "$ModuleRoot\Private\ConversationManager.ps1"
            $testConv = New-CopilotConversation
            $testConv.AddMessage("user", "Hello")
            $testConv.AddMessage("assistant", "Hi there!")
        }

        It "Should export to JSON format" {
            $tempFile = [System.IO.Path]::GetTempFileName() + ".json"
            try {
                { Export-CopilotConversation -Conversation $testConv -Path $tempFile -Format JSON } | Should -Not -Throw
                Test-Path $tempFile | Should -Be $true

                # Verify JSON is valid
                $json = Get-Content $tempFile -Raw | ConvertFrom-Json
                $json | Should -Not -BeNullOrEmpty
            } finally {
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }

        It "Should export to HTML format" {
            $tempFile = [System.IO.Path]::GetTempFileName() + ".html"
            try {
                { Export-CopilotConversation -Conversation $testConv -Path $tempFile -Format HTML } | Should -Not -Throw
                Test-Path $tempFile | Should -Be $true

                # Verify HTML contains expected elements
                $html = Get-Content $tempFile -Raw
                $html | Should -Match '<html'
                $html | Should -Match 'Copilot'
            } finally {
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }

        It "Should export to Markdown format" {
            $tempFile = [System.IO.Path]::GetTempFileName() + ".md"
            try {
                { Export-CopilotConversation -Conversation $testConv -Path $tempFile -Format Markdown } | Should -Not -Throw
                Test-Path $tempFile | Should -Be $true

                # Verify Markdown contains expected formatting
                $md = Get-Content $tempFile -Raw
                $md | Should -Match '^#'  # Should have headers
                $md | Should -Match 'USER|ASSISTANT'  # Should have role indicators
            } finally {
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }
    }
}

Describe "Insights Tests" {

    Context "Get-CopilotInsights" {
        It "Should handle meeting insights request" {
            { Get-CopilotInsights -Type "meetings" -TimeRange "today" } | Should -Not -Throw
        }

        It "Should handle email insights request" {
            { Get-CopilotInsights -Type "emails" -TimeRange "week" } | Should -Not -Throw
        }

        It "Should handle document insights request" {
            { Get-CopilotInsights -Type "documents" -MaxResults 5 } | Should -Not -Throw
        }

        It "Should handle all insights request" {
            { Get-CopilotInsights -Type "all" -TimeRange "today" } | Should -Not -Throw
        }

        It "Should validate TimeRange parameter" {
            { Get-CopilotInsights -Type "meetings" -TimeRange "invalid" } | Should -Throw
        }

        It "Should validate Type parameter" {
            { Get-CopilotInsights -Type "invalid" } | Should -Throw
        }
    }
}

Describe "Chat Functionality Tests" {

    Context "Invoke-CopilotChat" {
        It "Should accept message parameter" {
            { Invoke-CopilotChat -Message "Hello" } | Should -Not -Throw
        }

        It "Should require message parameter" {
            { Invoke-CopilotChat } | Should -Throw
        }

        It "Should return response object" {
            $result = Invoke-CopilotChat -Message "test"
            $result | Should -Not -BeNullOrEmpty
            $result.Response | Should -Not -BeNullOrEmpty
        }
    }
}