<#
Builds Cull for Windows and wraps it into ONE portable .exe with Enigma Virtual
Box - runs from a virtual filesystem, no install, nothing extracted to disk.

Output:  dist\Cull-<version>-portable.exe

Flutter itself can't emit a lone .exe (the app needs flutter_windows.dll,
pdfium.dll, libmpv-2.dll, the plugin DLLs and data\flutter_assets\). Enigma
Virtual Box packs that folder in. Install it first:

  choco install enigmavirtualbox        # or https://enigmaprotector.com

tool\gen_evb.ps1 generates the .evb project from the real build output, so the
file list never drifts and there is no GUI step.

Usage:
  powershell -File tool\build_portable.ps1            # full build + wrap
  powershell -File tool\build_portable.ps1 -SkipBuild # wrap an existing build
#>
param(
  [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$m = Select-String -Path (Join-Path $root 'pubspec.yaml') `
  -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)'
if (-not $m) { throw "Could not read version from pubspec.yaml" }
$version = $m.Matches[0].Groups[1].Value

$dist     = Join-Path $root 'dist'
$buildOut = Join-Path $root 'build\windows\x64\runner\Release'
$exe      = Join-Path $dist "Cull-$version-portable.exe"
$evb      = Join-Path $dist 'cull.evb'

if (-not $SkipBuild) {
  Write-Host "==> flutter build windows --release" -ForegroundColor Cyan
  # A stray running copy locks the output and breaks INSTALL.vcxproj.
  Get-Process cull -ErrorAction SilentlyContinue | Stop-Process -Force
  & flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw "flutter build failed" }
}
if (-not (Test-Path (Join-Path $buildOut 'cull.exe'))) {
  throw "Build output not found at $buildOut - run without -SkipBuild first."
}

$enigma =
  @('enigmavbconsole.exe',
    (Join-Path $env:ProgramFiles 'Enigma Virtual Box\enigmavbconsole.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Enigma Virtual Box\enigmavbconsole.exe')) |
  ForEach-Object { Get-Command $_ -ErrorAction SilentlyContinue } |
  Select-Object -First 1

if (-not $enigma) {
  throw "Enigma Virtual Box not found. Install it:  choco install enigmavirtualbox  (or https://enigmaprotector.com)"
}

New-Item -ItemType Directory -Path $dist -Force | Out-Null

Write-Host "==> generating $evb from the build output" -ForegroundColor Cyan
& powershell -NoProfile -File (Join-Path $PSScriptRoot 'gen_evb.ps1') `
  -ReleaseDir $buildOut -OutputExe $exe -EvbPath $evb
if ($LASTEXITCODE -ne 0) { throw "gen_evb.ps1 failed" }

Write-Host "==> Enigma Virtual Box: $($enigma.Source)" -ForegroundColor Cyan
if (Test-Path $exe) { Remove-Item $exe -Force }
& $enigma.Source $evb
if (-not (Test-Path $exe)) {
  throw "Enigma Virtual Box did not produce $exe. The generated .evb may need a schema tweak for this Enigma version - see docs\RELEASING.md."
}

Write-Host ""
Write-Host "==> $exe" -ForegroundColor Green
