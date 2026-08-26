[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
$ErrorActionPreference = 'Stop'
function Stop-With([int]$Code, [string]$Message) { [Console]::Error.WriteLine($Message); exit $Code }
function Resolve-CodexHome([string]$InputHome, [bool]$Create) {
    try { $lexicalHome = [IO.Path]::GetFullPath($InputHome) } catch { Stop-With 3 ("Invalid Codex home: " + $_.Exception.Message) }
    if ($lexicalHome.TrimEnd('\') -eq [IO.Path]::GetPathRoot($lexicalHome).TrimEnd('\')) { Stop-With 3 'Codex home cannot be a filesystem root.' }
    if (-not (Test-Path -LiteralPath $lexicalHome)) {
        if (-not $Create) { Stop-With 2 'Pet is not installed.' }
        try { New-Item -ItemType Directory -Path $lexicalHome | Out-Null } catch { Stop-With 4 ("Cannot create Codex home: " + $_.Exception.Message) }
    }
    $homeItem = Get-Item -LiteralPath $lexicalHome -Force
    if (-not $homeItem.PSIsContainer -or ($homeItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-With 3 'Refusing a non-directory or reparse-point Codex home.' }
    $resolvedHome = (Resolve-Path -LiteralPath $lexicalHome).Path
    if (-not [StringComparer]::OrdinalIgnoreCase.Equals($resolvedHome, $lexicalHome)) { Stop-With 3 'Codex home must not traverse a reparse point.' }
    return $resolvedHome
}
function Resolve-PetsDirectory([string]$CodexHome, [bool]$Create) {
    $candidate = Join-Path $CodexHome 'pets'
    if (Test-Path -LiteralPath $candidate) {
        $item = Get-Item -LiteralPath $candidate -Force
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-With 3 'Refusing a non-directory or reparse-point pets directory.' }
    } elseif (-not $Create) {
        Stop-With 2 'Pet is not installed.'
    } else {
        try { New-Item -ItemType Directory -Path $candidate | Out-Null } catch { Stop-With 4 ("Cannot create pets directory: " + $_.Exception.Message) }
    }
    $resolvedPets = (Resolve-Path -LiteralPath $candidate).Path
    if (-not [StringComparer]::OrdinalIgnoreCase.Equals($resolvedPets, $candidate)) { Stop-With 3 'Pets directory escapes Codex home.' }
    return $resolvedPets
}
function Resolve-BackupDirectory([string]$CodexHome, [bool]$Create) {
    $candidate = Join-Path $CodexHome 'pet-backups'
    $item = $null
    try {
        $item = Get-Item -LiteralPath $candidate -Force -ErrorAction Stop
    } catch {
        if ($_.CategoryInfo.Category -ne 'ObjectNotFound') { Stop-With 4 ("Cannot inspect pet-backups directory: " + $_.Exception.Message) }
    }
    if ($null -ne $item) {
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-With 3 'Refusing a non-directory or reparse-point pet-backups directory.' }
    } elseif (-not $Create) {
        Stop-With 2 'Pet backup directory is not available.'
    } else {
        try { New-Item -ItemType Directory -Path $candidate -ErrorAction Stop | Out-Null } catch { Stop-With 4 ("Cannot create pet-backups directory: " + $_.Exception.Message) }
        try { $item = Get-Item -LiteralPath $candidate -Force -ErrorAction Stop } catch { Stop-With 4 ("Cannot inspect created pet-backups directory: " + $_.Exception.Message) }
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-With 3 'Refusing a non-directory or reparse-point pet-backups directory.' }
    }
    try { $resolvedBackup = (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).Path } catch { Stop-With 4 ("Cannot resolve pet-backups directory: " + $_.Exception.Message) }
    if (-not [StringComparer]::OrdinalIgnoreCase.Equals($resolvedBackup, $candidate)) { Stop-With 3 'Pet-backups directory escapes Codex home.' }
    return $resolvedBackup
}
function Move-VerifiedDirectory([string]$Source, [string]$Destination) {
    $sourceItem = Get-Item -LiteralPath $Source -Force -ErrorAction Stop
    if (-not $sourceItem.PSIsContainer -or ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Source is not a real directory.' }
    $parentPath = [IO.Path]::GetDirectoryName($Destination)
    $parentItem = Get-Item -LiteralPath $parentPath -Force -ErrorAction Stop
    if (-not $parentItem.PSIsContainer -or ($parentItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Destination parent is not a real directory.' }
    $destinationItem = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
    if ($null -ne $destinationItem) { throw 'Destination already exists.' }
    [IO.Directory]::Move($Source, $Destination)
}
function New-BackupPath([string]$BackupDirectory) {
    for ($attempt = 0; $attempt -lt 16; $attempt++) {
        $candidate = Join-Path $BackupDirectory ('ellen-joe-pixel.backup.' + [guid]::NewGuid().ToString('N'))
        if ($null -eq (Get-Item -LiteralPath $candidate -Force -ErrorAction SilentlyContinue)) { return $candidate }
    }
    throw 'Cannot allocate a unique backup path.'
}
function Remove-VerifiedStage([string]$Stage, [string]$Pets) {
    if (-not (Test-Path -LiteralPath $Stage)) { return $true }
    if ([IO.Path]::GetDirectoryName($Stage) -ne $Pets -or [IO.Path]::GetFileName($Stage) -notlike '.ellen-joe-pixel.stage.*') { return $false }
    try { Remove-Item -LiteralPath $Stage -Recurse -Force; return -not (Test-Path -LiteralPath $Stage) } catch { return $false }
}

$homeInput = $null
$homeSpecified = $false
$force = $false
for ($index = 0; $index -lt $Arguments.Count; $index++) {
    switch ($Arguments[$index]) {
        '-CodexHome' {
            if ($homeSpecified -or $index + 1 -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$index + 1]) -or $Arguments[$index + 1].StartsWith('-')) { Stop-With 3 'Invalid -CodexHome value.' }
            $homeInput = $Arguments[$index + 1]
            $homeSpecified = $true
            $index++
        }
        '-Force' {
            if ($force) { Stop-With 3 'Duplicate -Force argument.' }
            $force = $true
        }
        default { Stop-With 3 ("Unknown argument: " + $Arguments[$index]) }
    }
}
if (-not $homeSpecified) {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) { $homeInput = $env:CODEX_HOME }
    elseif (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) { $homeInput = Join-Path $env:USERPROFILE '.codex' }
    else { Stop-With 3 'Codex home is empty.' }
}

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
    if ($manifest.id -ne 'ellen-joe-pixel' -or $manifest.displayName -ne 'Ellen Joe Pixel' -or $manifest.spriteVersionNumber -ne 2 -or $manifest.spritesheetPath -ne 'spritesheet.webp' -or $manifest.description -isnot [string] -or [string]::IsNullOrWhiteSpace($manifest.description)) { Stop-With 3 'Invalid source: manifest contract mismatch.' }
} catch { Stop-With 3 ("Invalid source: " + $_.Exception.Message) }

$expectedSpritesheetSha256 = 'C6F4ED31F670E00CDA1B596F35372B3B60BA5A6CB94DBD6E049B2E1950FC15E6'
try {
    $actualSpritesheetSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $sheetPath).Hash.ToUpperInvariant()
} catch { Stop-With 3 ("Invalid source: cannot hash spritesheet.webp: " + $_.Exception.Message) }
if ($actualSpritesheetSha256 -ne $expectedSpritesheetSha256) { Stop-With 3 'Invalid source: spritesheet.webp does not match the approved v2 atlas.' }

$codexHome = Resolve-CodexHome $homeInput $true
$pets = Resolve-PetsDirectory $codexHome $true
$target = Join-Path $pets 'ellen-joe-pixel'
$lockPath = Join-Path $pets '.ellen-joe-pixel.install.lock'
$lockStream = $null
$lockHeld = $false
$backupDir = $null
$stage = $null
$backup = $null
$backupCandidate = $null
try {
    try {
        $lockStream = [IO.File]::Open($lockPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $lockHeld = $true
    } catch {
        Stop-With 4 ("Cannot acquire install lock: " + $_.Exception.Message)
    }

    $targetItem = $null
    try {
        $targetItem = Get-Item -LiteralPath $target -Force -ErrorAction Stop
    } catch {
        if ($_.CategoryInfo.Category -ne 'ObjectNotFound') { throw }
    }
    if ($null -ne $targetItem) {
        if (-not $targetItem.PSIsContainer -or ($targetItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-With 3 'Refusing a non-directory or reparse-point target.' }
        if (-not $force) { Stop-With 2 "Target already exists: $target" }
        $backupDir = Resolve-BackupDirectory $codexHome $true
    }

    $stage = Join-Path $pets ('.ellen-joe-pixel.stage.' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage -ErrorAction Stop | Out-Null
    Copy-Item -LiteralPath $manifestPath, $sheetPath -Destination $stage -ErrorAction Stop

    $targetItem = $null
    try {
        $targetItem = Get-Item -LiteralPath $target -Force -ErrorAction Stop
    } catch {
        if ($_.CategoryInfo.Category -ne 'ObjectNotFound') { throw }
    }
    if ($null -ne $targetItem) {
        if (-not $targetItem.PSIsContainer -or ($targetItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-With 3 'Refusing a non-directory or reparse-point target.' }
        if ($null -eq $backupDir) { $backupDir = Resolve-BackupDirectory $codexHome $true }
        $backupCandidate = New-BackupPath $backupDir
        Move-VerifiedDirectory $target $backupCandidate
        $backup = $backupCandidate
    }
    Move-VerifiedDirectory $stage $target
} catch {
    $failure = $_.Exception.Message
    $cleanupOk = Remove-VerifiedStage $stage $pets
    $rollbackOk = $true
    if ($backup) {
        $backupItem = $null
        $targetItem = $null
        try { $backupItem = Get-Item -LiteralPath $backup -Force -ErrorAction Stop } catch { if ($_.CategoryInfo.Category -ne 'ObjectNotFound') { $rollbackOk = $false } }
        try { $targetItem = Get-Item -LiteralPath $target -Force -ErrorAction Stop } catch { if ($_.CategoryInfo.Category -ne 'ObjectNotFound') { $rollbackOk = $false } }
        if ($null -ne $backupItem -and $null -eq $targetItem) {
            try { Move-VerifiedDirectory $backup $target } catch { $rollbackOk = $false }
        } elseif ($null -ne $backupItem -or $null -ne $targetItem) { $rollbackOk = $false }
    }
    if ($cleanupOk -and $rollbackOk) { Stop-With 4 ("Install failed; prior target restored when present: $failure") }
    Stop-With 5 ("Install failed and rollback or cleanup failed: $failure")
} finally {
    if ($lockHeld) {
        $lockCleanupOk = $true
        try { $lockStream.Dispose() } catch { $lockCleanupOk = $false }
        try { [IO.File]::Delete($lockPath) } catch { $lockCleanupOk = $false }
        $lockHeld = $false
        if (-not $lockCleanupOk) { Stop-With 5 'Install failed and install-lock cleanup failed.' }
    }
}
Write-Host "Installed: $target"
if ($backup) { Write-Host "Backup: $backup" }
exit 0
