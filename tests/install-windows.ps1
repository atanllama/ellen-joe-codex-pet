$ErrorActionPreference = 'Stop'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("ellen-installer-test-" + [guid]::NewGuid())
try {
    $fixture = Join-Path $tempRoot 'repo'
    $codexHome = Join-Path $tempRoot 'codex home'
    New-Item -ItemType Directory -Path (Join-Path $fixture 'scripts'), (Join-Path $fixture 'pet\ellen-joe-pixel'), (Join-Path $codexHome 'pets\sentinel') -Force | Out-Null
    Copy-Item "$PSScriptRoot\..\scripts\install.ps1", "$PSScriptRoot\..\scripts\uninstall.ps1" -Destination (Join-Path $fixture 'scripts')
    '{"id":"sentinel"}' | Set-Content -LiteralPath (Join-Path $codexHome 'pets\sentinel\pet.json') -Encoding UTF8
    '{"id":"ellen-joe-pixel","displayName":"Ellen Joe Pixel","description":"fixture","spriteVersionNumber":2,"spritesheetPath":"spritesheet.webp"}' | Set-Content -LiteralPath (Join-Path $fixture 'pet\ellen-joe-pixel\pet.json') -Encoding UTF8
    [IO.File]::WriteAllBytes((Join-Path $fixture 'pet\ellen-joe-pixel\spritesheet.webp'), [byte[]](1, 2, 3))
    function Invoke-Code([string]$Name, [string[]]$Arguments) {
        & pwsh -NoProfile -File (Join-Path $fixture "scripts\$Name") @Arguments *> $null
        return $LASTEXITCODE
    }
    if ((Invoke-Code 'install.ps1' @('-CodexHome', $codexHome)) -ne 0) { throw 'first install failed' }
    $target = Join-Path $codexHome 'pets\ellen-joe-pixel'
    if (-not (Test-Path "$target\pet.json") -or -not (Test-Path "$target\spritesheet.webp")) { throw 'installed files missing' }
    if ((Invoke-Code 'install.ps1' @('-CodexHome', $codexHome)) -ne 2) { throw 'duplicate install did not return 2' }
    'old' | Set-Content -LiteralPath (Join-Path $target 'marker.txt')
    if ((Invoke-Code 'install.ps1' @('-CodexHome', $codexHome, '-Force')) -ne 0) { throw 'forced install failed' }
    $backup = @(Get-ChildItem -LiteralPath (Join-Path $codexHome 'pets') -Directory | Where-Object Name -Like 'ellen-joe-pixel.backup.*')
    if ($backup.Count -ne 1 -or -not (Test-Path (Join-Path $backup.FullName 'marker.txt'))) { throw 'backup missing marker' }
    if ((Invoke-Code 'uninstall.ps1' @('-CodexHome', $codexHome)) -ne 0) { throw 'uninstall failed' }
    if (Test-Path -LiteralPath $target) { throw 'target survived uninstall' }
    if ((Invoke-Code 'uninstall.ps1' @('-CodexHome', $codexHome)) -ne 2) { throw 'second uninstall did not return 2' }
    if ((Get-Content -Raw -LiteralPath (Join-Path $codexHome 'pets\sentinel\pet.json')).Trim() -ne '{"id":"sentinel"}') { throw 'sentinel changed' }
    Write-Host 'OK: Windows installer isolation and rollback contract'
} finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
