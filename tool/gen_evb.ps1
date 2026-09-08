<#
Generates an Enigma Virtual Box project (.evb) from a built Release folder, so
the file list always matches the actual build (no drift when plugin DLLs change)
and there is no manual GUI step.

  powershell -File tool\gen_evb.ps1 `
    -ReleaseDir build\windows\x64\runner\Release `
    -OutputExe  dist\Cull-1.0.0-portable.exe `
    -EvbPath    dist\cull.evb

Then:  enigmavbconsole dist\cull.evb
#>
param(
  [Parameter(Mandatory)][string]$ReleaseDir,
  [Parameter(Mandatory)][string]$OutputExe,
  [Parameter(Mandatory)][string]$EvbPath,
  [string]$InputExeName = 'cull.exe'
)

$ErrorActionPreference = 'Stop'
$ReleaseDir = (Resolve-Path $ReleaseDir).Path
$inputFull  = Join-Path $ReleaseDir $InputExeName
if (-not (Test-Path $inputFull)) { throw "Input exe not found: $inputFull" }

$OutputExe = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputExe))
New-Item -ItemType Directory -Force -Path (Split-Path $OutputExe) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path ([System.IO.Path]::GetFullPath((Join-Path (Get-Location) $EvbPath)))) | Out-Null

$sb = [System.Text.StringBuilder]::new()
function W($s) { [void]$sb.AppendLine($s) }

function Emit-Tree($dirPath, $indent) {
  $items = Get-ChildItem -LiteralPath $dirPath -Force |
    Sort-Object @{ E = { -not $_.PSIsContainer } }, Name
  foreach ($it in $items) {
    if ($it.PSIsContainer) {
      W "$indent<File>"
      W "$indent`t<Type>3</Type>"
      W "$indent`t<Name>$($it.Name)</Name>"
      W "$indent`t<Files>"
      Emit-Tree $it.FullName "$indent`t`t"
      W "$indent`t</Files>"
      W "$indent</File>"
    }
    elseif ($it.FullName -ne $inputFull) {
      W "$indent<File>"
      W "$indent`t<Type>2</Type>"
      W "$indent`t<Name>$($it.Name)</Name>"
      W "$indent`t<File>$($it.FullName)</File>"
      W "$indent</File>"
    }
  }
}

W '<?xml version="1.0" encoding="windows-1251"?>'
W '<>'
W "`t<InputFile>$inputFull</InputFile>"
W "`t<OutputFile>$OutputExe</OutputFile>"
W "`t<Options>"
W "`t`t<DeleteExtractedOnExit>false</DeleteExtractedOnExit>"
W "`t`t<CompressFiles>true</CompressFiles>"
W "`t</Options>"
W "`t<Files>"
W "`t`t<Enabled>true</Enabled>"
W "`t`t<Files>"
W "`t`t`t<File>"
W "`t`t`t`t<Type>3</Type>"
W "`t`t`t`t<Name>%DEFAULT FOLDER%</Name>"
W "`t`t`t`t<Files>"
Emit-Tree $ReleaseDir "`t`t`t`t`t"
W "`t`t`t`t</Files>"
W "`t`t`t</File>"
W "`t`t</Files>"
W "`t</Files>"
W '</>'

$enc = [System.Text.Encoding]::GetEncoding('windows-1251')
[System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath((Join-Path (Get-Location) $EvbPath)), $sb.ToString(), $enc)
Write-Host "wrote $EvbPath  (input: $inputFull  ->  output: $OutputExe)"
