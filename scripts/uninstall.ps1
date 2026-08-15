[CmdletBinding()]
param([string]$CodexHome)
$ErrorActionPreference = 'Stop'
function Stop-With([int]$Code, [string]$Message) { [Console]::Error.WriteLine($Message); exit $Code }
$homeInput = if ($CodexHome) { $CodexHome } elseif ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
if ([string]::IsNullOrWhiteSpace($homeInput)) { Stop-With 3 'Codex home is empty.' }
try { $codexHome = [IO.Path]::GetFullPath($homeInput) } catch { Stop-With 3 ("Invalid Codex home: " + $_.Exception.Message) }
if ($codexHome.TrimEnd('\') -eq [IO.Path]::GetPathRoot($codexHome).TrimEnd('\')) { Stop-With 3 'Codex home cannot be a filesystem root.' }
$pets = Join-Path $codexHome 'pets'
$target = Join-Path $pets 'ellen-joe-pixel'
if ([IO.Path]::GetFileName($target) -ne 'ellen-joe-pixel' -or [IO.Path]::GetDirectoryName($target) -ne [IO.Path]::GetFullPath($pets)) { Stop-With 3 'Target verification failed.' }
if (-not (Test-Path -LiteralPath $target)) { Stop-With 2 "Target is not installed: $target" }
$item = Get-Item -LiteralPath $target -Force
if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-With 3 'Refusing a non-directory or reparse-point target.' }
try { Remove-Item -LiteralPath $target -Recurse -Force } catch { Stop-With 5 ("Uninstall failed: " + $_.Exception.Message) }
Write-Host "Uninstalled: $target"
exit 0
