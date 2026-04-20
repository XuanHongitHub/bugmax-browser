param(
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

$ErrorActionPreference = "Stop"
$required = @(
  "001-branding.patch",
  "010-omnibox-profile-badge.patch",
  "020-search-defaults.patch",
  "030-first-run-defaults.patch"
)

$patchRoot = Join-Path $RepoRoot "patches/chromium"
if (!(Test-Path $patchRoot)) {
  throw "Missing patch directory: $patchRoot"
}

$missing = @()
foreach ($name in $required) {
  $path = Join-Path $patchRoot $name
  if (!(Test-Path $path)) {
    $missing += $name
    continue
  }
  $len = (Get-Item $path).Length
  if ($len -le 0) {
    $missing += "$name (empty)"
  }
}

if ($missing.Count -gt 0) {
  Write-Host "Required Bugmax patchset is incomplete."
  $missing | ForEach-Object { Write-Host " - $_" }
  throw "Stop build until one-shot custom patchset is complete."
}

Write-Host "Required Bugmax patchset present."
