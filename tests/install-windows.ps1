$ErrorActionPreference = 'Stop'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("ellen-installer-test-" + [guid]::NewGuid())
$priorCodexHome = [Environment]::GetEnvironmentVariable('CODEX_HOME', 'Process')
$priorFailFinal = [Environment]::GetEnvironmentVariable('ELLEN_TEST_FAIL_FINAL_MOVE', 'Process')
$priorFailRollback = [Environment]::GetEnvironmentVariable('ELLEN_TEST_FAIL_ROLLBACK', 'Process')
try {
    $fixture = Join-Path $tempRoot 'repo'
    $codexHome = Join-Path $tempRoot 'codex home'
    $fallbackHome = Join-Path $tempRoot 'fallback home'
    New-Item -ItemType Directory -Path (Join-Path $fixture 'scripts'), (Join-Path $fixture 'pet\ellen-joe-pixel') -Force | Out-Null
    Copy-Item "$PSScriptRoot\..\scripts\install.ps1", "$PSScriptRoot\..\scripts\uninstall.ps1" -Destination (Join-Path $fixture 'scripts')
    $env:CODEX_HOME = $fallbackHome
    $manifestPath = Join-Path $fixture 'pet\ellen-joe-pixel\pet.json'
    $sheetPath = Join-Path $fixture 'pet\ellen-joe-pixel\spritesheet.webp'
    $validManifest = '{"id":"ellen-joe-pixel","displayName":"Ellen Joe Pixel","spriteVersionNumber":2,"spritesheetPath":"spritesheet.webp"}'
    $validManifest | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    [IO.File]::WriteAllBytes($sheetPath, [byte[]](1, 2, 3))

    function Invoke-Code([string]$Name, [string[]]$Arguments) {
        Push-Location $fixture
        try {
            & pwsh -NoProfile -File (Join-Path $fixture "scripts\$Name") @Arguments *> $null
            return $LASTEXITCODE
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

    $linkedHome = Join-Path $tempRoot 'linked home'
    $outside = Join-Path $tempRoot 'outside'
    New-TestHome $outside
    New-Item -ItemType Directory -Path $linkedHome | Out-Null
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

    Assert-Code 0 'install.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome
    $target = Join-Path $codexHome 'pets\ellen-joe-pixel'
    if (-not (Test-Path "$target\pet.json") -or -not (Test-Path "$target\spritesheet.webp")) { throw 'installed files missing' }
    Assert-Code 2 'install.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome
    'old' | Set-Content -LiteralPath (Join-Path $target 'marker.txt')
    Assert-Code 0 'install.ps1' @('-CodexHome', $codexHome, '-Force')
    Assert-Sentinel $codexHome
    $backup = @(Get-ChildItem -LiteralPath (Join-Path $codexHome 'pets') -Directory | Where-Object Name -Like 'ellen-joe-pixel.backup.*')
    if ($backup.Count -ne 1 -or -not (Test-Path (Join-Path $backup.FullName 'marker.txt'))) { throw 'backup missing marker' }
    Assert-Code 0 'uninstall.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome
    if (Test-Path -LiteralPath $target) { throw 'target survived uninstall' }
    Assert-Code 2 'uninstall.ps1' @('-CodexHome', $codexHome)
    Assert-Sentinel $codexHome

    $installerCopy = Join-Path $fixture 'scripts\install.ps1'
    $installerText = Get-Content -Raw -LiteralPath $installerCopy
    $installerText = $installerText.Replace(
        '    Move-Item -LiteralPath $stage -Destination $target',
        ('    if ($env:ELLEN_TEST_FAIL_FINAL_MOVE -eq ''1'') { throw ''Injected final move failure.'' }' + [Environment]::NewLine + '    Move-Item -LiteralPath $stage -Destination $target'))
    $installerText = $installerText.Replace(
        '            try { Move-Item -LiteralPath $backup -Destination $target } catch { $rollbackOk = $false }',
        ('            try { if ($env:ELLEN_TEST_FAIL_ROLLBACK -eq ''1'') { throw ''Injected rollback failure.'' }; Move-Item -LiteralPath $backup -Destination $target } catch { $rollbackOk = $false }'))
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
    Assert-NoStages $rollbackHome
    $env:ELLEN_TEST_FAIL_FINAL_MOVE = '1'
    $env:ELLEN_TEST_FAIL_ROLLBACK = '1'
    Assert-Code 5 'install.ps1' @('-CodexHome', $rollbackHome, '-Force')
    Assert-Sentinel $rollbackHome
    Remove-Item Env:ELLEN_TEST_FAIL_FINAL_MOVE
    Remove-Item Env:ELLEN_TEST_FAIL_ROLLBACK
    if (Test-Path -LiteralPath $rollbackTarget) { throw 'rollback-failure target unexpectedly exists' }
    $rollbackBackup = @(Get-ChildItem -LiteralPath (Join-Path $rollbackHome 'pets') -Directory | Where-Object Name -Like 'ellen-joe-pixel.backup.*')
    if ($rollbackBackup.Count -ne 1 -or -not (Test-Path (Join-Path $rollbackBackup.FullName 'marker.txt'))) { throw 'rollback-failure backup missing prior target' }
    Assert-NoStages $rollbackHome
    Write-Host 'OK: Windows installer isolation and safety contract'
} finally {
    foreach ($entry in @(@('CODEX_HOME', $priorCodexHome), @('ELLEN_TEST_FAIL_FINAL_MOVE', $priorFailFinal), @('ELLEN_TEST_FAIL_ROLLBACK', $priorFailRollback))) {
        if ($null -eq $entry[1]) { Remove-Item ("Env:" + $entry[0]) -ErrorAction SilentlyContinue } else { Set-Item ("Env:" + $entry[0]) $entry[1] }
    }
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
