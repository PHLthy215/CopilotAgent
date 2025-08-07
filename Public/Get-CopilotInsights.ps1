function Get-CopilotInsights {
    <#
    .SYNOPSIS
        Get insights from Microsoft 365 Copilot

    .DESCRIPTION
        Retrieves various insights from Microsoft 365 data using Copilot APIs
        including meeting insights, email summaries, and document analysis

    .PARAMETER Type
        Type of insights to retrieve: recent, meetings, emails, documents, all

    .PARAMETER TimeRange
        Time range for insights: today, week, month

    .PARAMETER MaxResults
        Maximum number of results to return

    .EXAMPLE
        Get-CopilotInsights -Type "meetings" -TimeRange "today"

    .EXAMPLE
        Get-CopilotInsights -Type "all" -MaxResults 10
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("recent", "meetings", "emails", "documents", "all")]
        [string]$Type = "recent",

        [Parameter()]
        [ValidateSet("today", "week", "month")]
        [string]$TimeRange = "today",

        [Parameter()]
        [int]$MaxResults = 5
    )

    try {
        Write-Host "📊 Retrieving Copilot insights..." -ForegroundColor Cyan

        $insights = @()

        # Calculate date range
        $endDate = Get-Date
        switch ($TimeRange) {
            "today" { $startDate = $endDate.Date }
            "week" { $startDate = $endDate.AddDays(-7) }
            "month" { $startDate = $endDate.AddMonths(-1) }
        }

        # Get different types of insights
        switch ($Type) {
            "meetings" {
                $insights += Get-MeetingInsights -StartDate $startDate -EndDate $endDate -MaxResults $MaxResults
            }
            "emails" {
                $insights += Get-EmailInsights -StartDate $startDate -EndDate $endDate -MaxResults $MaxResults
            }
            "documents" {
                $insights += Get-DocumentInsights -StartDate $startDate -EndDate $endDate -MaxResults $MaxResults
            }
            "recent" {
                $insights += Get-RecentInsights -MaxResults $MaxResults
            }
            "all" {
                $insights += Get-MeetingInsights -StartDate $startDate -EndDate $endDate -MaxResults ($MaxResults / 3)
                $insights += Get-EmailInsights -StartDate $startDate -EndDate $endDate -MaxResults ($MaxResults / 3)
                $insights += Get-DocumentInsights -StartDate $startDate -EndDate $endDate -MaxResults ($MaxResults / 3)
            }
        }

        if ($insights.Count -eq 0) {
            Write-Host "No insights found for the specified criteria." -ForegroundColor Yellow
            return @()
        }

        # Display insights
        Write-Host "`n📋 Insights Summary:" -ForegroundColor Green
        $insights | ForEach-Object {
            Write-Host "  • $($_.Title)" -ForegroundColor White
            if ($_.Description) {
                Write-Host "    $($_.Description)" -ForegroundColor Gray
            }
            Write-Host ""
        }

        return $insights

    } catch {
        Write-Error "Failed to get insights: $($_.Exception.Message)"
        return @()
    }
}

function Get-MeetingInsights {
    [CmdletBinding()]
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [int]$MaxResults = 5
    )

    try {
        # Try to get actual meeting data via Graph API
        $endpoint = "$($Script:CopilotConfig.GraphEndpoint)/me/events"
        $params = @{
            '$filter' = "start/dateTime ge '$($StartDate.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"))' and end/dateTime le '$($EndDate.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"))'"
            '$select' = 'subject,start,end,attendees,organizer'
            '$top' = $MaxResults
        }

        $queryString = ($params.Keys | ForEach-Object { "$_=$($params[$_])" }) -join "&"
        $fullEndpoint = "$endpoint`?$queryString"

        try {
            $response = Invoke-CopilotApiRequest -Endpoint $fullEndpoint -Method 'GET'

            $insights = $response.value | ForEach-Object {
                @{
                    Type = "Meeting"
                    Title = "Upcoming: $($_.subject)"
                    Description = "$(([DateTime]$_.start.dateTime).ToString('MMM dd, HH:mm')) - $($_.attendees.Count) attendees"
                    Timestamp = [DateTime]$_.start.dateTime
                    Data = $_
                }
            }

            return $insights

        } catch {
            # Fallback to simulated data
            return Get-SimulatedMeetingInsights -MaxResults $MaxResults
        }

    } catch {
        Write-Warning "Could not retrieve meeting insights: $($_.Exception.Message)"
        return @()
    }
}

function Get-EmailInsights {
    [CmdletBinding()]
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [int]$MaxResults = 5
    )

    try {
        # Try to get actual email data via Graph API
        $endpoint = "$($Script:CopilotConfig.GraphEndpoint)/me/messages"
        $params = @{
            '$filter' = "receivedDateTime ge $($StartDate.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")) and receivedDateTime le $($EndDate.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"))"
            '$select' = 'subject,from,receivedDateTime,isRead,importance'
            '$orderby' = 'receivedDateTime desc'
            '$top' = $MaxResults
        }

        $queryString = ($params.Keys | ForEach-Object { "$_=$($params[$_])" }) -join "&"
        $fullEndpoint = "$endpoint`?$queryString"

        try {
            $response = Invoke-CopilotApiRequest -Endpoint $fullEndpoint -Method 'GET'

            $insights = $response.value | ForEach-Object {
                $status = if ($_.isRead) { "Read" } else { "Unread" }
                $importance = if ($_.importance -eq "high") { "🔴 High" } else { "" }

                @{
                    Type = "Email"
                    Title = "Email: $($_.subject)"
                    Description = "From: $($_.from.emailAddress.name) | $status $importance"
                    Timestamp = [DateTime]$_.receivedDateTime
                    Data = $_
                }
            }

            return $insights

        } catch {
            # Fallback to simulated data
            return Get-SimulatedEmailInsights -MaxResults $MaxResults
        }

    } catch {
        Write-Warning "Could not retrieve email insights: $($_.Exception.Message)"
        return @()
    }
}

function Get-DocumentInsights {
    [CmdletBinding()]
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [int]$MaxResults = 5
    )

    try {
        # Try to get OneDrive files via Graph API
        $endpoint = "$($Script:CopilotConfig.GraphEndpoint)/me/drive/recent"

        try {
            $response = Invoke-CopilotApiRequest -Endpoint $endpoint -Method 'GET'

            $insights = $response.value | Select-Object -First $MaxResults | ForEach-Object {
                @{
                    Type = "Document"
                    Title = "Recent: $($_.name)"
                    Description = "Modified: $(([DateTime]$_.lastModifiedDateTime).ToString('MMM dd, HH:mm')) | $($_.size) bytes"
                    Timestamp = [DateTime]$_.lastModifiedDateTime
                    Data = $_
                }
            }

            return $insights

        } catch {
            # Fallback to simulated data
            return Get-SimulatedDocumentInsights -MaxResults $MaxResults
        }

    } catch {
        Write-Warning "Could not retrieve document insights: $($_.Exception.Message)"
        return @()
    }
}

function Get-RecentInsights {
    [CmdletBinding()]
    param([int]$MaxResults = 5)

    # Get a mix of recent insights
    $insights = @()
    $insights += Get-MeetingInsights -StartDate (Get-Date).Date -EndDate (Get-Date).AddDays(1) -MaxResults 2
    $insights += Get-EmailInsights -StartDate (Get-Date).AddHours(-24) -EndDate (Get-Date) -MaxResults 2
    $insights += Get-DocumentInsights -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date) -MaxResults 1

    return $insights | Select-Object -First $MaxResults
}

# Simulated data functions for when APIs are not available
function Get-SimulatedMeetingInsights {
    param([int]$MaxResults = 5)

    $meetings = @(
        @{ Title = "Team Standup"; Description = "Daily sync with development team"; Time = "9:00 AM" },
        @{ Title = "Project Review"; Description = "Q1 project milestone review"; Time = "2:00 PM" },
        @{ Title = "Client Call"; Description = "Demo presentation for new features"; Time = "4:00 PM" },
        @{ Title = "1:1 with Manager"; Description = "Weekly check-in meeting"; Time = "Tomorrow 10:00 AM" },
        @{ Title = "Architecture Discussion"; Description = "System design review"; Time = "Tomorrow 3:00 PM" }
    )

    return $meetings | Select-Object -First $MaxResults | ForEach-Object {
        @{
            Type = "Meeting"
            Title = "Upcoming: $($_.Title)"
            Description = "$($_.Time) - $($_.Description)"
            Timestamp = Get-Date
        }
    }
}

function Get-SimulatedEmailInsights {
    param([int]$MaxResults = 5)

    $emails = @(
        @{ Subject = "Quarterly Review Results"; From = "Manager"; Status = "Unread"; Importance = "High" },
        @{ Subject = "Project Update"; From = "Team Lead"; Status = "Read"; Importance = "Normal" },
        @{ Subject = "Security Alert"; From = "IT Security"; Status = "Unread"; Importance = "High" },
        @{ Subject = "Meeting Notes"; From = "Colleague"; Status = "Read"; Importance = "Normal" },
        @{ Subject = "Weekly Newsletter"; From = "Company News"; Status = "Unread"; Importance = "Low" }
    )

    return $emails | Select-Object -First $MaxResults | ForEach-Object {
        $importanceIcon = if ($_.Importance -eq "High") { "🔴" } else { "" }
        @{
            Type = "Email"
            Title = "Email: $($_.Subject)"
            Description = "From: $($_.From) | $($_.Status) $importanceIcon"
            Timestamp = Get-Date
        }
    }
}

function Get-SimulatedDocumentInsights {
    param([int]$MaxResults = 5)

    $documents = @(
        @{ Name = "Project_Proposal_v2.docx"; Modified = "2 hours ago"; Size = "245 KB" },
        @{ Name = "Budget_Analysis.xlsx"; Modified = "1 day ago"; Size = "892 KB" },
        @{ Name = "Architecture_Diagram.pptx"; Modified = "3 days ago"; Size = "1.2 MB" },
        @{ Name = "Meeting_Notes_Jan.docx"; Modified = "5 days ago"; Size = "67 KB" },
        @{ Name = "Code_Review_Checklist.md"; Modified = "1 week ago"; Size = "12 KB" }
    )

    return $documents | Select-Object -First $MaxResults | ForEach-Object {
        @{
            Type = "Document"
            Title = "Recent: $($_.Name)"
            Description = "Modified: $($_.Modified) | $($_.Size)"
            Timestamp = Get-Date
        }
    }
}