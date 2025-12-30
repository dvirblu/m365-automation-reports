function Get-RawMailboxDataset {
  param([Parameter(Mandatory)]$Context)

  # Load mappings
  $licenseMap = Get-Content $Context.Mapping.LicenseMapPath -Raw | ConvertFrom-Json

  # Mailboxes
  $rtype = @("UserMailbox")
  if ($Context.Scope.IncludeShared) { $rtype += "SharedMailbox" }
  if ($Context.Scope.IncludeRooms)  { $rtype += "RoomMailbox" }

  $mbxs = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $rtype `
    -Properties DisplayName,PrimarySmtpAddress,RecipientTypeDetails,RetentionPolicy,ProhibitSendReceiveQuota,ArchiveQuota

  # Preload users (Graph) for licensing
  # Use Graph lookup per user (simple, OK for medium tenants). For large tenants you may want batching.
  $rows = foreach ($m in $mbxs) {
    $stats = Get-EXOMailboxStatistics -Identity $m.PrimarySmtpAddress
    $archiveStats = $null
    if ($m.ArchiveStatus -eq "Active") {
      $archiveStats = Get-EXOMailboxStatistics -Identity $m.PrimarySmtpAddress -Archive
    }

    $u = $null
    try { $u = Get-MgUser -UserId $m.PrimarySmtpAddress -Property "id,displayName,userPrincipalName,assignedLicenses" } catch {}

    $skuNames = @()
    if ($u -and $u.AssignedLicenses) {
      foreach ($sku in $u.AssignedLicenses) {
        $match = $licenseMap.items | Where-Object { $_.skuId -eq $sku.SkuId.Guid }
        if ($match) { $skuNames += $match.displayName } else { $skuNames += ("Unknown SKU: " + $sku.SkuId.Guid) }
      }
    }

    [pscustomobject]@{
      DisplayName = $m.DisplayName
      Email = $m.PrimarySmtpAddress.ToString()
      RecipientType = $m.RecipientTypeDetails.ToString()

      MailboxTotalItemSize = $stats.TotalItemSize.ToString()
      MailboxQuota = $m.ProhibitSendReceiveQuota.ToString()

      ArchiveStatus = $m.ArchiveStatus.ToString()
      ArchiveTotalItemSize = if ($archiveStats) { $archiveStats.TotalItemSize.ToString() } else { "" }
      ArchiveQuota = $m.ArchiveQuota.ToString()

      RetentionPolicy = if ($m.RetentionPolicy) { $m.RetentionPolicy } else { "" }
      License = ($skuNames -join "; ")
    }
  }

  return $rows
}

Export-ModuleMember -Function Get-RawMailboxDataset
