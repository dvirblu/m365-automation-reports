function Get-AutomationReportsConfig {
  param(
    [Parameter(Mandatory)][string]$CustomerConfigPath,
    [Parameter(Mandatory)][string]$EnvConfigPath,
    [Parameter(Mandatory)][string]$RunId
  )

  $customer = Get-Content $CustomerConfigPath -Raw | ConvertFrom-Json
  $env = Get-Content $EnvConfigPath -Raw | ConvertFrom-Json

  $ctx = [ordered]@{
    RunId = $RunId
    Customer = @{
      Name = $customer.customerName
    }
    Thresholds = @{
      WarningFreePercent = [double]$customer.thresholds.warningFreePercent
    }
    Scope = @{
      IncludeShared = [bool]$customer.scope.includeShared
      IncludeRooms = [bool]$customer.scope.includeRooms
    }
    Paths = @{
      BasePath = $env.paths.basePath
      RunsRoot = (Join-Path $env.paths.basePath $env.paths.runsRoot)
      ArchiveRoot = if ($env.paths.archiveRoot) { (Join-Path $env.paths.basePath $env.paths.archiveRoot) } else { $null }
    }
    Auth = @{
      TenantId = $env.auth.tenantId
      ClientId = $env.auth.clientId
      CertificateThumbprint = $env.auth.certificateThumbprint
      Organization = $env.auth.organization  # tenant domain for EXO
    }
    Delivery = @{
      FromMailbox = $customer.delivery.fromMailbox
      Recipients = @($customer.delivery.recipients)
      AdminRecipients = @($customer.delivery.adminRecipients)
      SubjectPrefix = $customer.delivery.subjectPrefix
      Language = $customer.delivery.language
    }
    Mapping = @{
      LicenseMapPath = $env.mapping.licenseMapPath
      RecommendationsPath = $env.mapping.recommendationsPath
    }
  }

  # Ensure directories exist
  New-Item -ItemType Directory -Path $ctx.Paths.RunsRoot -Force | Out-Null
  if ($ctx.Paths.ArchiveRoot) { New-Item -ItemType Directory -Path $ctx.Paths.ArchiveRoot -Force | Out-Null }

  return $ctx
}

Export-ModuleMember -Function Get-AutomationReportsConfig
