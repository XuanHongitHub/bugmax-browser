param(
  [Parameter(Mandatory=$true)][string]$Profile,
  [string]$ChromiumRef=""
)

$ErrorActionPreference = "Stop"
$workspace = $env:GITHUB_WORKSPACE
$workDir = Join-Path $workspace "work"
$depotDir = Join-Path $workspace "depot_tools"
$srcDir = Join-Path $workDir "src"
$outDir = Join-Path $srcDir "out/Release"
$distDir = Join-Path $workspace "dist/windows-x64"

New-Item -ItemType Directory -Force -Path $workDir,$distDir | Out-Null

if (!(Test-Path $depotDir)) {
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git $depotDir
}
$env:Path = "$depotDir;$env:Path"

Set-Location $workDir
if (!(Test-Path $srcDir)) {
  fetch --nohooks chromium
}

Set-Location $srcDir
if ($ChromiumRef -ne "") {
  try { git fetch --tags --depth 1 origin $ChromiumRef } catch {}
  try { git checkout $ChromiumRef } catch {}
}

gclient sync -D --force --with_branch_heads --with_tags
gclient runhooks

$args = @"
is_debug=false
is_component_build=false
symbol_level=0
blink_symbol_level=0
enable_nacl=false
target_cpu="x64"
"@
New-Item -ItemType Directory -Force -Path (Join-Path $srcDir "out/Release") | Out-Null
Set-Content -Path (Join-Path $srcDir "out/Release/args.gn") -Value $args -Encoding utf8

gn gen out/Release
if ($Profile -eq "smoke") {
  autoninja -C out/Release chrome/test:unit_tests
} else {
  autoninja -C out/Release chrome
}

$runtimeFiles = @(
  "chrome.exe",
  "chrome_100_percent.pak",
  "chrome_200_percent.pak",
  "icudtl.dat",
  "resources.pak",
  "snapshot_blob.bin",
  "v8_context_snapshot.bin"
)
foreach ($f in $runtimeFiles) {
  $p = Join-Path $outDir $f
  if (Test-Path $p) { Copy-Item $p -Destination $distDir -Force }
}
if (Test-Path (Join-Path $outDir "locales")) { Copy-Item (Join-Path $outDir "locales") -Destination $distDir -Recurse -Force }
if (Test-Path (Join-Path $outDir "swiftshader")) { Copy-Item (Join-Path $outDir "swiftshader") -Destination $distDir -Recurse -Force }

Compress-Archive -Path (Join-Path $distDir "*") -DestinationPath (Join-Path $workspace "bugmax-windows-x64.zip") -Force
