[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
$ErrorActionPreference = 'Stop'
function Stop-With([int]$Code, [string]$Message) { [Console]::Error.WriteLine($Message); exit $Code }
function Resolve-CodexHome([string]$InputHome) {
    try { $lexicalHome = [IO.Path]::GetFullPath($InputHome) } catch { Stop-With 3 ("Invalid Codex home: " + $_.Exception.Message) }
    if ($lexicalHome.TrimEnd('\') -eq [IO.Path]::GetPathRoot($lexicalHome).TrimEnd('\')) { Stop-With 3 'Codex home cannot be a filesystem root.' }
    if (-not (Test-Path -LiteralPath $lexicalHome)) { Stop-With 2 'Pet is not installed.' }
    $homeItem = Get-Item -LiteralPath $lexicalHome -Force
    if (-not $homeItem.PSIsContainer -or ($homeItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-With 3 'Refusing a non-directory or reparse-point Codex home.' }
    $resolvedHome = (Resolve-Path -LiteralPath $lexicalHome).Path
    if (-not [StringComparer]::OrdinalIgnoreCase.Equals($resolvedHome, $lexicalHome)) { Stop-With 3 'Codex home must not traverse a reparse point.' }
    return $resolvedHome
}
function Resolve-PetsDirectory([string]$CodexHome) {
    $candidate = Join-Path $CodexHome 'pets'
    if (-not (Test-Path -LiteralPath $candidate)) { Stop-With 2 'Pet is not installed.' }
    $item = Get-Item -LiteralPath $candidate -Force
    if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-With 3 'Refusing a non-directory or reparse-point pets directory.' }
    $resolvedPets = (Resolve-Path -LiteralPath $candidate).Path
    if (-not [StringComparer]::OrdinalIgnoreCase.Equals($resolvedPets, $candidate)) { Stop-With 3 'Pets directory escapes Codex home.' }
    return $resolvedPets
}

$homeInput = $null
$homeSpecified = $false
for ($index = 0; $index -lt $Arguments.Count; $index++) {
    switch ($Arguments[$index]) {
        '-CodexHome' {
            if ($homeSpecified -or $index + 1 -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$index + 1]) -or $Arguments[$index + 1].StartsWith('-')) { Stop-With 3 'Invalid -CodexHome value.' }
            $homeInput = $Arguments[$index + 1]
            $homeSpecified = $true
            $index++
        }
        default { Stop-With 3 ("Unknown argument: " + $Arguments[$index]) }
    }
}
if (-not $homeSpecified) {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) { $homeInput = $env:CODEX_HOME }
    elseif (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) { $homeInput = Join-Path $env:USERPROFILE '.codex' }
    else { Stop-With 3 'Codex home is empty.' }
}

$codexHome = Resolve-CodexHome $homeInput
$pets = Resolve-PetsDirectory $codexHome
$target = Join-Path $pets 'ellen-joe-pixel'
if ([IO.Path]::GetFileName($target) -ne 'ellen-joe-pixel' -or [IO.Path]::GetDirectoryName($target) -ne [IO.Path]::GetFullPath($pets)) { Stop-With 3 'Target verification failed.' }
if (-not (Test-Path -LiteralPath $target)) { Stop-With 2 "Target is not installed: $target" }
$item = Get-Item -LiteralPath $target -Force
if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-With 3 'Refusing a non-directory or reparse-point target.' }
try { Remove-Item -LiteralPath $target -Recurse -Force } catch { Stop-With 5 ("Uninstall failed: " + $_.Exception.Message) }
Write-Host "Uninstalled: $target"
exit 0
