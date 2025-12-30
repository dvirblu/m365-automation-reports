param(
  [Parameter(Mandatory=$true)]
  [string]$CustomerConfigPath,

  [Parameter(Mandatory=$true)]
  [string]$EnvConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Join-Path $root "Modules"

Import-Module (Join-Path $modulesPath "Logging.psm1") -Force
Import-Module (Join-Path $modulesPath "Snapshot.psm1") -Force
Import-Module (Join-Path $modulesPath "Config.psm1") -Force
Import-Module (Join-Path $modulesPath "Auth.psm1") -Force
Import-Module (Join-Path $modulesPath "DataCollection.psm1") -Force
Import-Module (Join-Path $modulesPath "Normalization.psm1") -Force
Import-Module (Join-Path $modulesPath "Calculation.psm1") -Force
Import-Module (Join-Path $modulesPath "Recommendation.psm1") -Force
Import-Module (Join-Path $modulesPath "Rendering.psm1") -Force
Import-Module (Join-Path $modulesPath "Delivery.psm1") -Force

$runId = (Get-Date).ToString("yyyyMMdd-HHmmss") + "-" + ([guid]::NewGuid().ToString("N").Substring(0,6))

# --- Load config ---
$cfg = Get-AutomationReportsConfig -CustomerConfigPath $CustomerConfigPath -EnvConfigPath $EnvConfigPath -RunId $runId

# --- Init folders + logger ---
Initialize-RunFolders -Context $cfg
Initialize-Logger -Context $cfg

Write-Log -Context $cfg -Level "INFO" -Stage "INIT" -Message "Run started" -Data @{ runId=$runId; customer=$cfg.Customer.Name }

try {
  # PRE-FLIGHT snapshot
  Save-SnapshotJson -Context $cfg -StageId 10 -Name "preflight" -Object @{
    runId=$runId
    psVersion=$PSVersionTable.PSVersion.ToString()
    machine=$env:COMPUTERNAME
    customerConfig=$CustomerConfigPath
    envConfig=$EnvConfigPath
  }

  # AUTH
  Write-Log -Context $cfg -Level "INFO" -Stage "AUTH" -Message "Connecting to M365 (EXO + Graph)"
  Connect-AutomationM365 -Context $cfg

  Save-SnapshotJson -Context $cfg -StageId 15 -Name "auth" -Object @{
    connected=$true
    tenantId=$cfg.Auth.TenantId
    clientId=$cfg.Auth.ClientId
    certThumbprint=$cfg.Auth.CertificateThumbprint
  }

  # COLLECT
  Write-Log -Context $cfg -Level "INFO" -Stage "COLLECT" -Message "Collecting mailbox, archive, licensing, retention"
  $raw = Get-RawMailboxDataset -Context $cfg

  Save-SnapshotCsv -Context $cfg -StageId 20 -Name "collected_raw" -Rows $raw

  # NORMALIZE
  $norm = Convert-ToNormalizedDataset -Context $cfg -Rows $raw
  Save-SnapshotCsv -Context $cfg -StageId 30 -Name "normalized" -Rows $norm

  # CALCULATE
  $calc = Add-CalculatedFields -Context $cfg -Rows $norm
  Save-SnapshotCsv -Context $cfg -StageId 40 -Name "calculated" -Rows $calc

  # RECOMMEND
  $final = Add-Recommendations -Context $cfg -Rows $calc
  Save-SnapshotCsv -Context $cfg -StageId 50 -Name "recommendations" -Rows $final

  # RENDER
  $reportPath = New-ExcelReport -Context $cfg -Rows $final
  Save-SnapshotJson -Context $cfg -StageId 70 -Name "render" -Object @{
    reportPath=$reportPath
    sizeBytes=(Get-Item $reportPath).Length
  }

  # DELIVER
  $summary = Get-DeliverySummary -Context $cfg -Rows $final
  Send-ReportEmail -Context $cfg -ReportPath $reportPath -Summary $summary

  Save-SnapshotJson -Context $cfg -StageId 90 -Name "delivery_payload" -Object @{
    from=$cfg.Delivery.FromMailbox
    to=$cfg.Delivery.Recipients
    subject=$summary.Subject
    reportPath=$reportPath
    saveToSentItems=$true
  }

  # ARCHIVE (optional)
  if ($cfg.Paths.ArchiveRoot) {
    Copy-Item -Path $reportPath -Destination (Join-Path $cfg.Paths.ArchiveRoot (Split-Path $reportPath -Leaf)) -Force
  }

  Write-Log -Context $cfg -Level "INFO" -Stage "DONE" -Message "Run finished successfully" -Data $summary
  exit 0
}
catch {
  Write-Log -Context $cfg -Level "ERROR" -Stage "FAIL" -Message "Run failed" -Data @{ error=$_.Exception.Message; stack=$_.ScriptStackTrace }
  try {
    # optional: notify admins (not customer)
    if ($cfg.Delivery.AdminRecipients -and $cfg.Delivery.AdminRecipients.Count -gt 0) {
      Send-AdminFailureEmail -Context $cfg -ErrorMessage $_.Exception.Message
    }
  } catch {}
  exit 1
}
finally {
  Disconnect-AutomationM365 -Context $cfg
}
