param(
  [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$OutDir = (Join-Path (Split-Path -Parent $PSScriptRoot) "release"),
  [string]$Version = (Get-Date).ToString("yyyyMMdd-HHmm")
)

$src = Join-Path $RepoRoot "src"
$zip = Join-Path $OutDir ("automation-reports-{0}.zip" -f $Version)

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
if (Test-Path $zip) { Remove-Item $zip -Force }

$temp = Join-Path $OutDir ("pkg-{0}" -f $Version)
if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
New-Item -ItemType Directory -Path $temp -Force | Out-Null

Copy-Item -Path (Join-Path $src "Run.ps1") -Destination $temp -Force
Copy-Item -Path (Join-Path $src "Modules") -Destination (Join-Path $temp "Modules") -Recurse -Force
Copy-Item -Path (Join-Path $src "Templates") -Destination (Join-Path $temp "Templates") -Recurse -Force
Copy-Item -Path (Join-Path $src "Schemas") -Destination (Join-Path $temp "Schemas") -Recurse -Force

Set-Content -Path (Join-Path $temp "VERSION.txt") -Value $Version -Encoding UTF8

Compress-Archive -Path (Join-Path $temp "*") -DestinationPath $zip -Force
Remove-Item $temp -Recurse -Force

Write-Host "Created: $zip"
