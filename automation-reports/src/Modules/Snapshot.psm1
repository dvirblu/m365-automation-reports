function Initialize-RunFolders {
  param([Parameter(Mandatory)]$Context)

  $date = (Get-Date).ToString("yyyy-MM-dd")
  $Context.Paths.RunRoot = Join-Path $Context.Paths.RunsRoot (Join-Path $Context.Customer.Name (Join-Path $date $Context.RunId))
  $Context.Paths.Snapshots = Join-Path $Context.Paths.RunRoot "snapshots"
  $Context.Paths.Output = Join-Path $Context.Paths.RunRoot "output"

  New-Item -ItemType Directory -Path $Context.Paths.RunRoot -Force | Out-Null
  New-Item -ItemType Directory -Path $Context.Paths.Snapshots -Force | Out-Null
  New-Item -ItemType Directory -Path $Context.Paths.Output -Force | Out-Null
}

function Save-SnapshotJson {
  param([Parameter(Mandatory)]$Context,[int]$StageId,[string]$Name,[Parameter(Mandatory)]$Object)
  $file = "{0:D2}_{1}.json" -f $StageId, $Name
  $path = Join-Path $Context.Paths.Snapshots $file
  $Object | ConvertTo-Json -Depth 10 | Set-Content -Path $path -Encoding UTF8
}

function Save-SnapshotCsv {
  param([Parameter(Mandatory)]$Context,[int]$StageId,[string]$Name,[Parameter(Mandatory)]$Rows)
  $file = "{0:D2}_{1}.csv" -f $StageId, $Name
  $path = Join-Path $Context.Paths.Snapshots $file
  $Rows | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
}

Export-ModuleMember -Function Initialize-RunFolders, Save-SnapshotJson, Save-SnapshotCsv
