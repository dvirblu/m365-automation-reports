function Connect-AutomationM365 {
  param([Parameter(Mandatory)]$Context)

  Import-Module ExchangeOnlineManagement -ErrorAction Stop
  Import-Module Microsoft.Graph -ErrorAction Stop

  Connect-ExchangeOnline `
    -AppId $Context.Auth.ClientId `
    -CertificateThumbprint $Context.Auth.CertificateThumbprint `
    -Organization $Context.Auth.Organization `
    -ShowBanner:$false

  Connect-MgGraph `
    -TenantId $Context.Auth.TenantId `
    -ClientId $Context.Auth.ClientId `
    -CertificateThumbprint $Context.Auth.CertificateThumbprint `
    -NoWelcome

  Select-MgProfile -Name "v1.0" | Out-Null
}

function Disconnect-AutomationM365 {
  param([Parameter(Mandatory)]$Context)
  try { Disconnect-ExchangeOnline -Confirm:$false | Out-Null } catch {}
  try { Disconnect-MgGraph | Out-Null } catch {}
}

Export-ModuleMember -Function Connect-AutomationM365, Disconnect-AutomationM365
