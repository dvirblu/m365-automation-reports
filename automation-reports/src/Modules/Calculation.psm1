function Parse-QuotaGB {
  param([string]$QuotaString)
  if (-not $QuotaString) { return 0.0 }
  # EXO quota strings often include GB; simplest approach:
  if ($QuotaString -match "(?<num>[\d\.]+)\s*GB") {
    return [double]$Matches.num
  }
  # If "Unlimited" or unknown:
  return 0.0
}

function Add-CalculatedFields {
  param([Parameter(Mandatory)]$Context,[Parameter(Mandatory)]$Rows)

  $warn = [double]$Context.Thresholds.WarningFreePercent

  foreach ($r in $Rows) {
    $mbxQuotaGB = Parse-QuotaGB $r.MailboxQuotaRaw
    $archQuotaGB = Parse-QuotaGB $r.ArchiveQuotaRaw

    $mbxFreeGB = if ($mbxQuotaGB -gt 0) { [math]::Round($mbxQuotaGB - $r.MailboxUsedGB, 2) } else { 0.0 }
    $mbxFreePct = if ($mbxQuotaGB -gt 0) { [math]::Round(($mbxFreeGB / $mbxQuotaGB) * 100, 2) } else { 0.0 }
    $mbxStatus = if ($mbxQuotaGB -gt 0 -and $mbxFreePct -lt $warn) { "Warning" } else { "OK" }

    $archFreeGB = if ($archQuotaGB -gt 0) { [math]::Round($archQuotaGB - $r.ArchiveUsedGB, 2) } else { 0.0 }
    $archFreePct = if ($archQuotaGB -gt 0) { [math]::Round(($archFreeGB / $archQuotaGB) * 100, 2) } else { 0.0 }
    $archStatus = if ($r.ArchiveStatus -eq "Active" -and $archQuotaGB -gt 0 -and $archFreePct -lt $warn) { "Warning" } else { "OK" }

    [pscustomobject]@{
      DisplayName = $r.DisplayName
      Email = $r.Email
      RecipientType = $r.RecipientType

      MailboxUsedGB = $r.MailboxUsedGB
      MailboxQuotaGB = $mbxQuotaGB
      MailboxFreeGB = $mbxFreeGB
      MailboxFreePercent = $mbxFreePct
      MailboxStatus = $mbxStatus

      ArchiveStatus = $r.ArchiveStatus
      ArchiveUsedGB = $r.ArchiveUsedGB
      ArchiveQuotaGB = $archQuotaGB
      ArchiveFreeGB = $archFreeGB
      ArchiveFreePercent = $archFreePct
      ArchiveStatusFlag = $archStatus

      RetentionPolicy = $r.RetentionPolicy
      License = $r.License
    }
  }
}

Export-ModuleMember -Function Add-CalculatedFields
