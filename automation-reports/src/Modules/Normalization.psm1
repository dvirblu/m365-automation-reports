function Convert-SizeToBytes {
  param([string]$SizeString)
  if (-not $SizeString) { return 0 }
  # Handles strings like: "1.234 GB (1,325,123,456 bytes)"
  if ($SizeString -match "\((?<bytes>[\d,]+)\s+bytes\)") {
    return [int64]($Matches.bytes -replace ",","")
  }
  return 0
}

function Convert-ToGB {
  param([int64]$Bytes)
  if ($Bytes -le 0) { return 0.0 }
  return [math]::Round(($Bytes / 1GB), 2)
}

function Convert-ToNormalizedDataset {
  param([Parameter(Mandatory)]$Context,[Parameter(Mandatory)]$Rows)

  foreach ($r in $Rows) {
    $mbxBytes = Convert-SizeToBytes $r.MailboxTotalItemSize
    $archBytes = Convert-SizeToBytes $r.ArchiveTotalItemSize

    [pscustomobject]@{
      DisplayName = $r.DisplayName
      Email = $r.Email
      RecipientType = $r.RecipientType
      RetentionPolicy = $r.RetentionPolicy
      License = $r.License

      MailboxUsedGB = Convert-ToGB $mbxBytes
      MailboxQuotaRaw = $r.MailboxQuota

      ArchiveStatus = $r.ArchiveStatus
      ArchiveUsedGB = Convert-ToGB $archBytes
      ArchiveQuotaRaw = $r.ArchiveQuota
    }
  }
}

Export-ModuleMember -Function Convert-ToNormalizedDataset
