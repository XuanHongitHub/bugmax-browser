param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$ChromiumSrc
)

$ErrorActionPreference = "Stop"

$patchDir = Join-Path $RepoRoot "patches/chromium"
if (Test-Path $patchDir) {
  $patches = Get-ChildItem -Path $patchDir -Filter *.patch | Sort-Object Name
  foreach ($patch in $patches) {
    Write-Host "Applying patch $($patch.Name)"
    git -C $ChromiumSrc apply --3way --whitespace=nowarn $patch.FullName
  }
}

# Branding defaults that do not require source tree edits.
Write-Host "Bugmax customization layer applied (Windows)."
