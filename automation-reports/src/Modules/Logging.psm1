function Initialize-Logger {
  param([Parameter(Mandatory)]$Context)
  $Context.Paths.ProcessLog = Join-Path $Context.Paths.RunRoot "process.log"
  New-Item -ItemType File -Path $Context.Paths.ProcessLog -Force | Out-Null
}

function Write-Log {
  param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)][ValidateSet("INFO","WARN","ERROR")]$Level,
    [Parameter(Mandatory)][string]$Stage,
    [Parameter(Mandatory)][string]$Message,
    [hashtable]$Data
  )
  $entry = [ordered]@{
    ts = (Get-Date).ToString("o")
    runId = $Context.RunId
    customer = $Context.Customer.Name
    level = $Level
    stage = $Stage
    message = $Message
    data = $Data
  }
  ($entry | ConvertTo-Json -Depth 6 -Compress) | Add-Content -Path $Context.Paths.ProcessLog -Encoding UTF8
}

Export-ModuleMember -Function Initialize-Logger, Write-Log
