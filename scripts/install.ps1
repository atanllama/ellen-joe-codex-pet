[CmdletBinding()]
param([string]$CodexHome, [switch]$Force)
$ErrorActionPreference = 'Stop'
function Stop-With([int]$Code, [string]$Message) { [Console]::Error.WriteLine($Message); exit $Code }
$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot 'pet\ellen-joe-pixel'
try {
    $manifestPath = Join-Path $source 'pet.json'
    $sheetPath = Join-Path $source 'spritesheet.webp'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf) -or -not (Test-Path -LiteralPath $sheetPath -PathType Leaf)) { Stop-With 3 'Invalid source: package files are missing.' }
    $source = (Resolve-Path -LiteralPath $source).Path
    $manifestPath = Join-Path $source 'pet.json'
    $sheetPath = Join-Path $source 'spritesheet.webp'
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.id -ne 'ellen-joe-pixel' -or $manifest.spriteVersionNumber -ne 2 -or $manifest.spritesheetPath -ne 'spritesheet.webp') { Stop-With 3 'Invalid source: manifest contract mismatch.' }
} catch { Stop-With 3 ("Invalid source: " + $_.Exception.Message) }
$homeInput = if ($CodexHome) { $CodexHome } elseif ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
if ([string]::IsNullOrWhiteSpace($homeInput)) { Stop-With 3 'Codex home is empty.' }
try { $codexHome = [IO.Path]::GetFullPath($homeInput) } catch { Stop-With 3 ("Invalid Codex home: " + $_.Exception.Message) }
if ($codexHome.TrimEnd('\') -eq [IO.Path]::GetPathRoot($codexHome).TrimEnd('\')) { Stop-With 3 'Codex home cannot be a filesystem root.' }
$pets = Join-Path $codexHome 'pets'
$target = Join-Path $pets 'ellen-joe-pixel'
try { New-Item -ItemType Directory -Path $pets -Force | Out-Null } catch { Stop-With 4 ("Cannot create pets directory: " + $_.Exception.Message) }
if (Test-Path -LiteralPath $target) {
    if ((Get-Item -LiteralPath $target -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { Stop-With 3 'Refusing a reparse-point target.' }
    if (-not $Force) { Stop-With 2 "Target already exists: $target" }
}
$stage = Join-Path $pets ('.ellen-joe-pixel.stage.' + [guid]::NewGuid().ToString('N'))
$backup = $null
try {
    New-Item -ItemType Directory -Path $stage | Out-Null
    Copy-Item -LiteralPath $manifestPath, $sheetPath -Destination $stage
    if (Test-Path -LiteralPath $target) {
        $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
        $backup = "$target.backup.$stamp.$PID"
        Move-Item -LiteralPath $target -Destination $backup
    }
    Move-Item -LiteralPath $stage -Destination $target
} catch {
    $failure = $_.Exception.Message
    if (Test-Path -LiteralPath $stage) { try { Remove-Item -LiteralPath $stage -Recurse -Force } catch { } }
    if ($backup -and (Test-Path -LiteralPath $backup) -and -not (Test-Path -LiteralPath $target)) {
        try { Move-Item -LiteralPath $backup -Destination $target } catch { Stop-With 5 ("Install failed and rollback failed: " + $_.Exception.Message) }
    }
    Stop-With 4 ("Install failed; prior target restored when present: $failure")
}
Write-Host "Installed: $target"
if ($backup) { Write-Host "Backup: $backup" }
exit 0
