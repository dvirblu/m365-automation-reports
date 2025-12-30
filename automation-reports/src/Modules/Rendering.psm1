function New-ExcelReport {
  param([Parameter(Mandatory)]$Context,[Parameter(Mandatory)]$Rows)

  Import-Module ImportExcel -ErrorAction Stop

  $date = (Get-Date).ToString("yyyy-MM-dd")
  $file = "MailboxUsage_{0}_{1}.xlsx" -f $Context.Customer.Name, $date
  $path = Join-Path $Context.Paths.Output $file

  # Sort so warnings first
  $sorted = $Rows | Sort-Object @{Expression="MailboxStatus";Descending=$true}, @{Expression="MailboxFreePercent";Ascending=$true}

  $sorted | Export-Excel -Path $path -WorksheetName "All" -AutoSize -FreezeTopRow -AutoFilter -BoldTopRow -ClearSheet

  # Optional: Warnings sheet
  $warnOnly = $sorted | Where-Object { $_.MailboxStatus -eq "Warning" -or $_.ArchiveStatusFlag -eq "Warning" }
  $warnOnly | Export-Excel -Path $path -WorksheetName "Warnings" -AutoSize -FreezeTopRow -AutoFilter -BoldTopRow -ClearSheet -Append

  return $path
}

Export-ModuleMember -Function New-ExcelReport
