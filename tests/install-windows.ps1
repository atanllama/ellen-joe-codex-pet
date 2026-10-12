param([string]$ShellPath = (Get-Process -Id $PID).Path)
$ErrorActionPreference = 'Stop'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("ellen-installer-test-" + [guid]::NewGuid())
$priorCodexHome = [Environment]::GetEnvironmentVariable('CODEX_HOME', 'Process')
$priorFailFinal = [Environment]::GetEnvironmentVariable('ELLEN_TEST_FAIL_FINAL_MOVE', 'Process')
$priorFailRollback = [Environment]::GetEnvironmentVariable('ELLEN_TEST_FAIL_ROLLBACK', 'Process')
$priorCreateTarget = [Environment]::GetEnvironmentVariable('ELLEN_TEST_CREATE_TARGET_BEFORE_FINAL_MOVE', 'Process')
try {
    $fixture = Join-Path $tempRoot 'repo'
    $codexHome = Join-Path $tempRoot 'codex home'
    $fallbackHome = Join-Path $tempRoot 'fallback home'
    New-Item -ItemType Directory -Path (Join-Path $fixture 'scripts'), (Join-Path $fixture 'pet\ellen-joe-pixel') -Force | Out-Null
    Copy-Item "$PSScriptRoot\..\scripts\install.ps1", "$PSScriptRoot\..\scripts\uninstall.ps1" -Destination (Join-Path $fixture 'scripts')
    Copy-Item "$PSScriptRoot\..\scripts\manifest-contract.ps1", "$PSScriptRoot\..\scripts\manifest_contract.py" -Destination (Join-Path $fixture 'scripts')
    Copy-Item "$PSScriptRoot\..\release-assets.json" -Destination $fixture
    $env:CODEX_HOME = $fallbackHome
    $manifestPath = Join-Path $fixture 'pet\ellen-joe-pixel\pet.json'
    $sheetPath = Join-Path $fixture 'pet\ellen-joe-pixel\spritesheet.webp'
    $validManifest = '{"id":"ellen-joe-pixel","displayName":"Ellen Joe Pixel","description":"A sleepy full-body Ellen Joe fan-art Codex Pet.","spriteVersionNumber":2,"spritesheetPath":"spritesheet.webp"}'
    $validManifest | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    [IO.File]::WriteAllBytes($sheetPath, [byte[]](1, 2, 3))

    function Invoke-Code([string]$Name, [string[]]$Arguments) {
        Push-Location $fixture
        try {
            $savedPreference = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            & $ShellPath -NoProfile -File (Join-Path $fixture "scripts\$Name") @Arguments *> $null
            $code = $LASTEXITCODE
            $ErrorActionPreference = $savedPreference
            return $code
        } finally { Pop-Location }
    }
    function Assert-Code([int]$Expected, [string]$Name, [string[]]$Arguments) {
        $actual = Invoke-Code $Name $Arguments
        if ($actual -ne $Expected) { throw "$Name expected exit $Expected, got $actual" }
    }
    function New-TestHome([string]$Path) {
        New-Item -ItemType Directory -Path (Join-Path $Path 'pets\sentinel') -Force | Out-Null
        '{"id":"sentinel"}' | Set-Content -LiteralPath (Join-Path $Path 'pets\sentinel\pet.json') -Encoding UTF8
    }
    function Assert-Sentinel([string]$Path) {
        if ((Get-Content -Raw -LiteralPath (Join-Path $Path 'pets\sentinel\pet.json')).Trim() -ne '{"id":"sentinel"}') { throw "sentinel changed under $Path" }
    }
    function Assert-NoStages([string]$Path) {
        if (@(Get-ChildItem -LiteralPath (Join-Path $Path 'pets') -Force | Where-Object Name -Like '.ellen-joe-pixel.stage.*').Count -ne 0) { throw "staging directory leaked under $Path" }
    }
    function Assert-NoPetBackupsInPets([string]$Path) {
        if (@(Get-ChildItem -LiteralPath (Join-Path $Path 'pets') -Directory -ErrorAction SilentlyContinue | Where-Object Name -Like 'ellen-joe-pixel.backup.*').Count -ne 0) { throw "backup leaked into pets under $Path" }
    }
    function Assert-NoInstallLocks([string]$Path) {
        $lockItem = Get-Item -LiteralPath (Join-Path $Path 'pets\.ellen-joe-pixel.install.lock') -Force -ErrorAction SilentlyContinue
        if ($null -ne $lockItem) { throw "install lock leaked under $Path" }
    }
    function Assert-InstalledBytes([string]$Path, [string]$SourceManifest, [string]$SourceSheet) {
        $expectedHash = 'C6F4ED31F670E00CDA1B596F35372B3B60BA5A6CB94DBD6E049B2E1950FC15E6'
        $installedSheet = Join-Path $Path 'pets\ellen-joe-pixel\spritesheet.webp'
        $installedManifest = Join-Path $Path 'pets\ellen-joe-pixel\pet.json'
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $installedSheet).Hash.ToUpperInvariant() -ne $expectedHash) { throw 'installed spritesheet bytes changed' }
        if (-not [Linq.Enumerable]::SequenceEqual([IO.File]::ReadAllBytes($SourceManifest), [IO.File]::ReadAllBytes($installedManifest))) { throw 'installed manifest bytes changed' }
    }

    New-TestHome $codexHome
    # RED-before-GREEN regression: automatic parameter binding returned 1 here.
    Assert-Code 3 'install.ps1' @('-Unknown')
    Assert-Sentinel $codexHome
    Assert-Code 3 'install.ps1' @('-CodexHome')
    Assert-Sentinel $codexHome
    Assert-Code 3 'install.ps1' @('-CodexHome', '')
    Assert-Sentinel $codexHome
    Assert-Code 3 'install.ps1' @('-CodexHome', '-Force')
    Assert-Sentinel $codexHome
    if (Test-Path -LiteralPath (Join-Path $fixture '-Force')) { throw 'option was treated as a Codex home value' }
    Assert-Code 3 'uninstall.ps1' @('-Unknown')
    Assert-Sentinel $codexHome
    Assert-Code 3 'uninstall.ps1' @('-CodexHome')
    Assert-Sentinel $codexHome
    Assert-Code 3 'uninstall.ps1' @('-CodexHome', '')
    Assert-Sentinel $codexHome
    Assert-Code 3 'uninstall.ps1' @('-CodexHome', '-Force')
    Assert-Sentinel $codexHome
    if (Test-Path -LiteralPath (Join-Path $fixture '-Force')) { throw 'uninstaller option was treated as a Codex home value' }

    $rootAlias = Join-Path ([IO.Path]::GetPathRoot($tempRoot)) '.'
    Assert-Code 3 'install.ps1' @('-CodexHome', $rootAlias)
    Assert-Sentinel $codexHome
    Assert-Code 3 'uninstall.ps1' @('-CodexHome', $rootAlias)
    Assert-Sentinel $codexHome

    '{"id":"ellen-joe-pixel","spriteVersionNumber":20,"spritesheetPath":"spritesheet.webp"}' | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Assert-Code 3 'install.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome
    '{"id":' | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Assert-Code 3 'install.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome
    $validManifest | Set-Content -LiteralPath $manifestPath -Encoding UTF8

    Assert-Code 3 'install.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome
    if (Test-Path -LiteralPath (Join-Path $codexHome 'pets\ellen-joe-pixel')) { throw 'invalid atlas was installed' }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\pet\ellen-joe-pixel\spritesheet.webp') -Destination $sheetPath

    $linkedHome = Join-Path $tempRoot 'linked home'
    $outside = Join-Path $tempRoot 'outside'
    New-TestHome $outside
    New-Item -ItemType Directory -Path $linkedHome | Out-Null

    $linkedCodexHome = Join-Path $tempRoot 'linked codex home'
    New-Item -ItemType Junction -Path $linkedCodexHome -Target $outside | Out-Null
    Assert-Code 3 'install.ps1' @('-CodexHome', $linkedCodexHome)
    Assert-Sentinel $outside
    if (Test-Path -LiteralPath (Join-Path $outside 'pets\ellen-joe-pixel')) { throw 'symlinked Codex home escaped selected home' }
    Assert-Code 3 'uninstall.ps1' @('-CodexHome', $linkedCodexHome)
    Assert-Sentinel $outside

    New-Item -ItemType Junction -Path (Join-Path $linkedHome 'pets') -Target (Join-Path $outside 'pets') | Out-Null
    Assert-Code 3 'install.ps1' @('-CodexHome', $linkedHome)
    Assert-Sentinel $outside
    Assert-Code 3 'uninstall.ps1' @('-CodexHome', $linkedHome)
    Assert-Sentinel $outside
    if (Test-Path -LiteralPath (Join-Path $outside 'pets\ellen-joe-pixel')) { throw 'linked parent escaped Codex home' }
    Assert-Sentinel $outside

    $fileHome = Join-Path $tempRoot 'file target home'
    New-TestHome $fileHome
    'not a pet directory' | Set-Content -LiteralPath (Join-Path $fileHome 'pets\ellen-joe-pixel')
    Assert-Code 3 'install.ps1' @('-CodexHome', $fileHome, '-Force')
    Assert-Sentinel $fileHome
    Assert-Code 3 'uninstall.ps1' @('-CodexHome', $fileHome)
    Assert-Sentinel $fileHome

    $lockedHome = Join-Path $tempRoot 'locked home'
    New-TestHome $lockedHome
    $lockPath = Join-Path $lockedHome 'pets\.ellen-joe-pixel.install.lock'
    New-Item -ItemType File -Path $lockPath -Force | Out-Null
    Assert-Code 4 'install.ps1' @('-CodexHome', $lockedHome)
    Assert-Sentinel $lockedHome
    if (-not (Test-Path -LiteralPath $lockPath)) { throw 'pre-existing install lock was removed' }
    Remove-Item -LiteralPath $lockPath -Force
    Assert-Code 0 'install.ps1' @('-CodexHome', $lockedHome)
    Assert-Sentinel $lockedHome
    Assert-NoInstallLocks $lockedHome
    New-Item -ItemType File -Path $lockPath -Force | Out-Null
    Assert-Code 4 'uninstall.ps1' @('-CodexHome', $lockedHome)
    if (-not (Test-Path -LiteralPath (Join-Path $lockedHome 'pets\ellen-joe-pixel'))) { throw 'locked uninstall removed target' }
    if ($null -eq (Get-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue)) { throw 'locked uninstall removed pre-existing lock' }
    Remove-Item -LiteralPath $lockPath -Force
    Assert-Code 0 'uninstall.ps1' @('-CodexHome', $lockedHome)
    Assert-NoInstallLocks $lockedHome

    Assert-Code 0 'install.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome
    $target = Join-Path $codexHome 'pets\ellen-joe-pixel'
    if (-not (Test-Path "$target\pet.json") -or -not (Test-Path "$target\spritesheet.webp")) { throw 'installed files missing' }
    Assert-Code 2 'install.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome
    'old' | Set-Content -LiteralPath (Join-Path $target 'marker.txt')
    Assert-Code 0 'install.ps1' @('-CodexHome', $codexHome, '-Force')
    Assert-Sentinel $codexHome
    Assert-NoInstallLocks $codexHome
    Assert-NoPetBackupsInPets $codexHome
    if (-not (Test-Path (Join-Path $target 'pet.json')) -or -not (Test-Path (Join-Path $target 'spritesheet.webp'))) { throw 'forced install nested the staged package' }
    Assert-InstalledBytes $codexHome $manifestPath $sheetPath
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $codexHome 'pet-backups') -Directory | Where-Object Name -Like 'ellen-joe-pixel.backup.*' | Sort-Object Name)
    if ($backups.Count -ne 1 -or -not (Test-Path (Join-Path $backups[0].FullName 'marker.txt'))) { throw 'backup missing marker' }
    $firstBackup = $backups[0].FullName
    'new' | Set-Content -LiteralPath (Join-Path $target 'marker.txt')
    Assert-Code 0 'install.ps1' @('-CodexHome', $codexHome, '-Force')
    Assert-Sentinel $codexHome
    Assert-NoInstallLocks $codexHome
    Assert-NoPetBackupsInPets $codexHome
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $codexHome 'pet-backups') -Directory | Where-Object Name -Like 'ellen-joe-pixel.backup.*' | Sort-Object Name)
    if ($backups.Count -ne 2 -or $backups[0].FullName -eq $backups[1].FullName) { throw 'backup names were not unique' }
    $backupMarkers = @($backups | ForEach-Object { (Get-Content -Raw -LiteralPath (Join-Path $_.FullName 'marker.txt')).Trim() })
    if (-not ($backupMarkers -contains 'old') -or -not ($backupMarkers -contains 'new')) { throw 'unique backups did not preserve both prior targets' }
    Assert-InstalledBytes $codexHome $manifestPath $sheetPath
    Assert-Code 0 'uninstall.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome
    if (Test-Path -LiteralPath $target) { throw 'target survived uninstall' }
    if (-not (Test-Path (Join-Path $firstBackup 'marker.txt'))) { throw 'uninstall removed backup' }
    Assert-Code 2 'uninstall.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome

    $installerCopy = Join-Path $fixture 'scripts\install.ps1'
    $installerText = Get-Content -Raw -LiteralPath $installerCopy
    $installerText = $installerText.Replace(
        '    Move-VerifiedDirectory $stage $target',
        ('    if ($env:ELLEN_TEST_FAIL_FINAL_MOVE -eq ''1'') { throw ''Injected final move failure.'' }' + [Environment]::NewLine + '    Move-VerifiedDirectory $stage $target'))
    $installerText = $installerText.Replace(
        '            try { Move-VerifiedDirectory $backup $target } catch { $rollbackOk = $false }',
        ('            try { if ($env:ELLEN_TEST_FAIL_ROLLBACK -eq ''1'') { throw ''Injected rollback failure.'' }; Move-VerifiedDirectory $backup $target } catch { $rollbackOk = $false }'))
    $installerText = $installerText.Replace(
        '    Move-VerifiedDirectory $stage $target',
        ('    if ($env:ELLEN_TEST_CREATE_TARGET_BEFORE_FINAL_MOVE -eq ''1'') { New-Item -ItemType Directory -Path $target | Out-Null; ''appeared'' | Set-Content -LiteralPath (Join-Path $target ''marker.txt'') }' + [Environment]::NewLine + '    Move-VerifiedDirectory $stage $target'))
    Set-Content -LiteralPath $installerCopy -Value $installerText -Encoding UTF8

    $rollbackHome = Join-Path $tempRoot 'rollback home'
    New-TestHome $rollbackHome
    $rollbackTarget = Join-Path $rollbackHome 'pets\ellen-joe-pixel'
    Assert-Code 0 'install.ps1' @('-CodexHome', $rollbackHome)
    Assert-Sentinel $rollbackHome
    'prior target' | Set-Content -LiteralPath (Join-Path $rollbackTarget 'marker.txt')
    $env:ELLEN_TEST_FAIL_FINAL_MOVE = '1'
    Assert-Code 4 'install.ps1' @('-CodexHome', $rollbackHome, '-Force')
    Assert-Sentinel $rollbackHome
    Remove-Item Env:ELLEN_TEST_FAIL_FINAL_MOVE
    if (-not (Test-Path (Join-Path $rollbackTarget 'marker.txt'))) { throw 'rollback did not restore prior target' }
    Assert-NoInstallLocks $rollbackHome
    Assert-NoStages $rollbackHome
    $env:ELLEN_TEST_FAIL_FINAL_MOVE = '1'
    $env:ELLEN_TEST_FAIL_ROLLBACK = '1'
    Assert-Code 5 'install.ps1' @('-CodexHome', $rollbackHome, '-Force')
    Assert-Sentinel $rollbackHome
    Remove-Item Env:ELLEN_TEST_FAIL_FINAL_MOVE
    Remove-Item Env:ELLEN_TEST_FAIL_ROLLBACK
    if (Test-Path -LiteralPath $rollbackTarget) { throw 'rollback-failure target unexpectedly exists' }
    Assert-NoPetBackupsInPets $rollbackHome
    Assert-NoInstallLocks $rollbackHome
    $rollbackBackup = @(Get-ChildItem -LiteralPath (Join-Path $rollbackHome 'pet-backups') -Directory | Where-Object Name -Like 'ellen-joe-pixel.backup.*')
    if ($rollbackBackup.Count -ne 1 -or -not (Test-Path (Join-Path $rollbackBackup.FullName 'marker.txt'))) { throw 'rollback-failure backup missing prior target' }
    Assert-NoStages $rollbackHome

    $appearedHome = Join-Path $tempRoot 'appeared target home'
    New-TestHome $appearedHome
    $env:ELLEN_TEST_CREATE_TARGET_BEFORE_FINAL_MOVE = '1'
    Assert-Code 4 'install.ps1' @('-CodexHome', $appearedHome)
    Remove-Item Env:ELLEN_TEST_CREATE_TARGET_BEFORE_FINAL_MOVE
    $appearedTarget = Join-Path $appearedHome 'pets\ellen-joe-pixel'
    if (-not (Test-Path (Join-Path $appearedTarget 'marker.txt'))) { throw 'target appearance was not preserved' }
    if (Test-Path (Join-Path $appearedTarget 'pet.json')) { throw 'target appearance regression nested the staged package' }
    $appearedBackups = @(Get-ChildItem -LiteralPath (Join-Path $appearedHome 'pet-backups') -Directory -ErrorAction SilentlyContinue | Where-Object Name -Like 'ellen-joe-pixel.backup.*')
    if ($appearedBackups.Count -ne 0) { throw 'target appearance created an unexpected backup' }
    Assert-NoInstallLocks $appearedHome
    Assert-NoPetBackupsInPets $appearedHome
    Write-Host 'OK: Windows installer isolation and safety contract'
} finally {
    foreach ($entry in @(@('CODEX_HOME', $priorCodexHome), @('ELLEN_TEST_FAIL_FINAL_MOVE', $priorFailFinal), @('ELLEN_TEST_FAIL_ROLLBACK', $priorFailRollback), @('ELLEN_TEST_CREATE_TARGET_BEFORE_FINAL_MOVE', $priorCreateTarget))) {
        if ($null -eq $entry[1]) { Remove-Item ("Env:" + $entry[0]) -ErrorAction SilentlyContinue } else { Set-Item ("Env:" + $entry[0]) $entry[1] }
    }
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
