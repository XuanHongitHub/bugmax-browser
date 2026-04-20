param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$ChromiumSrc
)

$ErrorActionPreference = "Stop"

$validator = Join-Path $RepoRoot "scripts/validate-customization-patchset.ps1"
& $validator -RepoRoot $RepoRoot

$python = (Get-Command python -ErrorAction SilentlyContinue)
if (-not $python) {
  $python = (Get-Command python3 -ErrorAction SilentlyContinue)
}
if (-not $python) {
  throw "Python is required to apply Bugmax customizations."
}

& $python.Source (Join-Path $RepoRoot "scripts/apply-customizations.py") $ChromiumSrc

# Branding defaults that do not require source tree edits.
Write-Host "Bugmax customization layer applied (Windows)."
