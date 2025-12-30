function Add-Recommendations {
  param([Parameter(Mandatory)]$Context,[Parameter(Mandatory)]$Rows)

  $rules = Get-Content $Context.Mapping.RecommendationsPath -Raw | ConvertFrom-Json

  foreach ($r in $Rows) {
    $rec = ""

    # Only recommend if Warning (mailbox or archive)
    if ($r.MailboxStatus -eq "Warning" -or $r.ArchiveStatusFlag -eq "Warning") {

      # Example logic:
      # - If archive not active: recommend enabling archive IF license supports, else upgrade.
      # - If archive active and under 100GB and warning: enable auto-expanding
      # - If archive >100GB warning: note auto expands (no action)
      $hasRetention = [string]::IsNullOrWhiteSpace($r.RetentionPolicy) -eq $false
      $licenseText = $r.License

      if ($r.ArchiveStatus -ne "Active") {
        if ($licenseText -match $rules.licenseRegex.archiveSupported) {
          $rec = "להפעיל Online Archive ולהחיל Retention Policy להעברת דואר ישן לארכיון."
        } else {
          $rec = "הרישוי הקיים אינו כולל Online Archive. מומלץ לשדרג לרישוי הכולל ארכיון (למשל Exchange Online Plan 2 / Microsoft 365 E3) ולהפעיל ארכיון."
        }
      } else {
        if (-not $hasRetention) {
          $rec = "מומלץ להחיל Retention Policy להעברת דואר ישן לארכיון ולצמצום צמיחת התיבה."
        } else {
          # Archive warning handling
          if ($r.ArchiveQuotaGB -gt 0 -and $r.ArchiveFreePercent -lt $Context.Thresholds.WarningFreePercent) {
            if ($r.ArchiveQuotaGB -lt 100) {
              $rec = "נפח הארכיון מתקרב למיצוי. מומלץ להפעיל Auto-Expanding Archive (עד 100GB)."
            } else {
              $rec = "נפח הארכיון מעל 100GB: הארכיון אמור להתרחב אוטומטית. אין פעולה נדרשת מעבר לניטור."
            }
          } else {
            $rec = "נפח התיבה מתקרב למיצוי. מומלץ לוודא שהארכיון מנוצל ולהמשיך העברה לפי מדיניות השמירה."
          }
        }
      }
    }

    [pscustomobject]@{
      DisplayName = $r.DisplayName
      Email = $r.Email
      MailboxUsedGB = $r.MailboxUsedGB
      MailboxQuotaGB = $r.MailboxQuotaGB
      MailboxFreePercent = $r.MailboxFreePercent
      MailboxStatus = $r.MailboxStatus

      ArchiveStatus = $r.ArchiveStatus
      ArchiveUsedGB = $r.ArchiveUsedGB
      ArchiveQuotaGB = $r.ArchiveQuotaGB
      ArchiveFreePercent = $r.ArchiveFreePercent
      ArchiveStatusFlag = $r.ArchiveStatusFlag

      RetentionPolicy = $r.RetentionPolicy
      License = $r.License
      Recommendation = $rec
    }
  }
}

Export-ModuleMember -Function Add-Recommendations


