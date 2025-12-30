function Get-DeliverySummary {
  param([Parameter(Mandatory)]$Context,[Parameter(Mandatory)]$Rows)

  $mw = ($Rows | Where-Object { $_.MailboxStatus -eq "Warning" }).Count
  $aw = ($Rows | Where-Object { $_.ArchiveStatusFlag -eq "Warning" }).Count
  $total = $Rows.Count

  $subject = "{0} - Mailbox & Archive Usage Report - {1}" -f $Context.Delivery.SubjectPrefix, (Get-Date).ToString("yyyy-MM-dd")

  return @{
    Subject = $subject
    Total = $total
    MailboxWarnings = $mw
    ArchiveWarnings = $aw
  }
}

function Send-ReportEmail {
  param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)][string]$ReportPath,
    [Parameter(Mandatory)]$Summary
  )

  $bodyTemplate = Join-Path (Split-Path $PSScriptRoot -Parent) "Templates\MailBody.he.md"
  $body = (Get-Content $bodyTemplate -Raw) `
    -replace "\{\{TOTAL\}\}", $Summary.Total `
    -replace "\{\{MBX_WARN\}\}", $Summary.MailboxWarnings `
    -replace "\{\{ARC_WARN\}\}", $Summary.ArchiveWarnings `
    -replace "\{\{DATE\}\}", (Get-Date).ToString("yyyy-MM-dd")

  $bytes = [System.IO.File]::ReadAllBytes($ReportPath)
  $b64 = [Convert]::ToBase64String($bytes)
  $fileName = Split-Path $ReportPath -Leaf

  $msg = @{
    message = @{
      subject = $Summary.Subject
      body = @{
        contentType = "HTML"
        content = $body
      }
      toRecipients = @($Context.Delivery.Recipients | ForEach-Object { @{ emailAddress = @{ address = $_ } } })
      attachments = @(
        @{
          "@odata.type" = "#microsoft.graph.fileAttachment"
          name = $fileName
          contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          contentBytes = $b64
        }
      )
    }
    saveToSentItems = $true
  }

  $from = $Context.Delivery.FromMailbox
  Invoke-MgGraphRequest -Method POST -Uri "/v1.0/users/$from/sendMail" -Body ($msg | ConvertTo-Json -Depth 10)
}

function Send-AdminFailureEmail {
  param([Parameter(Mandatory)]$Context,[Parameter(Mandatory)][string]$ErrorMessage)

  $subject = "Automation Reports - FAILED - {0}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm")
  $body = "<p>Run failed for customer <b>$($Context.Customer.Name)</b>.</p><p>Error: $ErrorMessage</p><p>RunId: $($Context.RunId)</p>"

  $msg = @{
    message = @{
      subject = $subject
      body = @{ contentType = "HTML"; content = $body }
      toRecipients = @($Context.Delivery.AdminRecipients | ForEach-Object { @{ emailAddress = @{ address = $_ } } })
    }
    saveToSentItems = $true
  }

  Invoke-MgGraphRequest -Method POST -Uri "/v1.0/users/$($Context.Delivery.FromMailbox)/sendMail" -Body ($msg | ConvertTo-Json -Depth 10)
}

Export-ModuleMember -Function Get-DeliverySummary, Send-ReportEmail, Send-AdminFailureEmail
