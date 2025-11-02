<#
Minimal local patch installer (PowerShell)
Targets: .msu / .cab / .msi / .msp / .exe
Run: Elevated PowerShell (Run as Administrator)
Patch folder: -Path (e.g., C:\patches). Default: current directory (.)
#>

param(
  [string]$Path = '.',                 # Patch folder
  [switch]$Recurse,                    # Include subdirectories
  [switch]$Reboot,                     # Reboot at the end if required
  [string]$ExeArgs = '/quiet /norestart' # Silent args for EXE
)

# Resolve path and collect files
$root = (Resolve-Path -LiteralPath $Path).Path
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Directory not found: $root" }
$files = Get-ChildItem -LiteralPath $root -File -Recurse:$Recurse |
  Where-Object { $_.Extension -match '^\.(msu|cab|msi|msp|exe)$' } |
  Sort-Object Name
if (-not $files) { Write-Host 'No patch files found'; return }

# Log folder
$out = Join-Path $env:ProgramData ("PatchApply\{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $out | Out-Null
$summary = Join-Path $out 'summary.log'

$rebootNeeded = $false

foreach ($f in $files) {
  $ext = $f.Extension.ToLowerInvariant()
  $exit = 0
  switch ($ext) {
    '.msu' { $exit = (Start-Process -FilePath (Join-Path $env:WINDIR 'system32\wusa.exe')  -ArgumentList @("`"$($f.FullName)`"","/quiet","/norestart") -Wait -PassThru).ExitCode }
    '.cab' { $exit = (Start-Process -FilePath (Join-Path $env:WINDIR 'system32\dism.exe')  -ArgumentList @('/Online','/Add-Package',"/PackagePath:`"$($f.FullName)`"",'/Quiet','/NoRestart') -Wait -PassThru).ExitCode }
    '.msi' { $exit = (Start-Process -FilePath (Join-Path $env:WINDIR 'system32\msiexec.exe') -ArgumentList @('/i',"`"$($f.FullName)`"",'/qn','/norestart') -Wait -PassThru).ExitCode }
    '.msp' { $exit = (Start-Process -FilePath (Join-Path $env:WINDIR 'system32\msiexec.exe') -ArgumentList @('/p',"`"$($f.FullName)`"",'/qn','/norestart') -Wait -PassThru).ExitCode }
    '.exe' { $exit = (Start-Process -FilePath $f.FullName -ArgumentList $ExeArgs -Wait -PassThru).ExitCode }
  }
  if ($exit -in 3010,1641) { $rebootNeeded = $true }
  "{0}`tExit:{1}" -f $f.FullName, $exit | Add-Content -Path $summary
}

Write-Host "Summary: $summary"
if ($Reboot -and $rebootNeeded) { Restart-Computer -Force }

