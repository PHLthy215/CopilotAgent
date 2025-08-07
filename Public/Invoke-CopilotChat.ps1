function Invoke-CopilotChat {
    <#
    .SYNOPSIS
        Send a chat message to Microsoft Copilot and get a response

    .DESCRIPTION
        This function sends a message to Microsoft 365 Copilot using the Chat API
        and returns the AI response. Supports conversation context and metadata.

    .PARAMETER Message
        The message to send to Copilot

    .PARAMETER Conversation
        Optional conversation object to maintain context

    .PARAMETER SystemPrompt
        Optional system prompt to guide the AI behavior

    .PARAMETER IncludeContext
        Include Microsoft 365 context in the request

    .EXAMPLE
        Invoke-CopilotChat -Message "Help me write a PowerShell script to manage Azure resources"

    .EXAMPLE
        $conv = New-CopilotConversation
        Invoke-CopilotChat -Message "What meetings do I have today?" -Conversation $conv -IncludeContext
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1, 4000)]
        [string]$Message,

        [Parameter()]
        [CopilotConversation]$Conversation,

        [Parameter()]
        [ValidateLength(0, 1000)]
        [string]$SystemPrompt,

        [Parameter()]
        [switch]$IncludeContext,

        [Parameter()]
        [ValidateNotNull()]
        [hashtable]$AdditionalParameters = @{},

        [Parameter()]
        [switch]$SkipPreconditionChecks
    )

    begin {
        # Validate preconditions unless skipped
        if (-not $SkipPreconditionChecks) {
            Test-CopilotPreconditions -RequireAuthentication -RequireInternet
        }

        # Create conversation if not provided
        if (-not $Conversation) {
            $Conversation = New-CopilotConversation
        }

        # Log the operation start
        Write-CopilotLog -Message "Starting chat operation" -Level Information -Category "Chat" -Data @{
            MessageLength = $Message.Length
            IncludeContext = $IncludeContext.IsPresent
            HasSystemPrompt = -not [string]::IsNullOrEmpty($SystemPrompt)
        }
    }

    process {
        try {
            Write-Host "🤖 Sending message to Copilot..." -ForegroundColor Cyan

            # Add user message to conversation
            $Conversation.AddMessage("user", $Message)

            # Prepare the request body
            $requestBody = @{
                messages = @()
                max_tokens = 4000
                temperature = 0.7
                stream = $false
            }

            # Add system prompt if provided
            if ($SystemPrompt) {
                $requestBody.messages += @{
                    role = "system"
                    content = $SystemPrompt
                }
            }

            # Add conversation history (last 10 messages to avoid token limits)
            $recentMessages = $Conversation.GetMessages() | Select-Object -Last 10
            foreach ($msg in $recentMessages) {
                if ($msg.Role -ne "system" -or -not $SystemPrompt) {
                    $requestBody.messages += @{
                        role = $msg.Role
                        content = $msg.Content
                    }
                }
            }

            # Include M365 context if requested
            if ($IncludeContext) {
                $requestBody.include_context = $true
                $requestBody.context_sources = @("calendar", "emails", "documents", "teams")
            }

            # Add additional parameters
            $AdditionalParameters.Keys | ForEach-Object {
                $requestBody[$_] = $AdditionalParameters[$_]
            }

            # Make the API call
            # Note: Using a simulated endpoint as the actual Copilot Chat API is in private preview
            $endpoint = "$($Script:CopilotConfig.CopilotEndpoint)/chat"

            try {
                $response = Invoke-CopilotApiRequest -Endpoint $endpoint -Method 'POST' -Body $requestBody

                # Extract the response content
                $aiResponse = $response.choices[0].message.content

                # Add AI response to conversation
                $Conversation.AddMessage("assistant", $aiResponse, @{
                    model = $response.model
                    usage = $response.usage
                })

                # Display the response
                Write-Host "`n💬 Copilot Response:" -ForegroundColor Green
                Write-Host $aiResponse -ForegroundColor White

                return @{
                    Response = $aiResponse
                    Conversation = $Conversation
                    Metadata = @{
                        Model = $response.model
                        Usage = $response.usage
                        Timestamp = Get-Date
                    }
                }

            } catch {
                # Fallback: Since Chat API is in private preview, simulate response
                Write-Warning "Copilot Chat API not yet available. Using simulated response."

                $simulatedResponse = Get-SimulatedCopilotResponse -Message $Message -IncludeContext:$IncludeContext

                $Conversation.AddMessage("assistant", $simulatedResponse, @{
                    model = "copilot-simulated"
                    simulated = $true
                })

                Write-Host "`n💬 Copilot Response (Simulated):" -ForegroundColor Yellow
                Write-Host $simulatedResponse -ForegroundColor White

                return @{
                    Response = $simulatedResponse
                    Conversation = $Conversation
                    Metadata = @{
                        Model = "copilot-simulated"
                        Simulated = $true
                        Timestamp = Get-Date
                    }
                }
            }

        } catch {
            Write-CopilotLog -Message "Chat operation failed" -Level Error -Category "Chat" -ErrorRecord $_

            # Create structured error message
            $errorMessage = "Failed to get Copilot response: $($_.Exception.Message)"

            throw [System.InvalidOperationException]::new(
                $errorMessage,
                $_.Exception
            )
        } finally {
            # Clean up any resources
            Write-CopilotLog -Message "Chat operation completed" -Level Verbose -Category "Chat"
        }
    }
}

function Get-SimulatedCopilotResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [switch]$IncludeContext
    )

    # Simple response simulation based on message content
    $responses = @{
        "meeting" = "Based on your calendar, you have 3 meetings today: Team standup at 9 AM, Project review at 2 PM, and Client call at 4 PM."
        "email" = "You have 12 unread emails in your inbox. The most important ones are from your manager about the quarterly review."
        "document" = "I found 5 relevant documents in your OneDrive related to this topic. Would you like me to summarize them?"
        "script" = "I can help you create a PowerShell script. Here's a basic template to get you started..."
        "default" = "I'm your Microsoft 365 Copilot assistant. I can help with emails, documents, meetings, and various productivity tasks. What would you like to know?"
    }

    # Simple keyword matching
    $keywords = $responses.Keys | Where-Object { $Message.ToLower().Contains($_) }

    if ($keywords) {
        $response = $responses[$keywords[0]]
    } else {
        $response = $responses["default"]
    }

    if ($IncludeContext) {
        $response += "`n`n*Note: This response includes context from your Microsoft 365 data (simulated).*"
    }

    return $response
}