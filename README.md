[English](README.md) | [简体中文](README.zh-CN.md)
Entirely produced by Codex; 完全交由 Codex 制作
# Ellen Joe Pixel — Codex Pet

> **Project status:** public, unofficial fan work. Latest release:
> [v0.1.2](https://github.com/atanllama/ellen-joe-codex-pet/releases/tag/v0.1.2).

![Ellen Joe Pixel preview](qa/contact-sheet-standard.png)

Ellen Joe Pixel is a full-body Ellen Joe Codex Pet package with a Codex v2
spritesheet, cross-platform installers, and a local package validator. It is
unofficial and non-commercial. It is not affiliated with HoYoverse, Cognosphere,
or OpenAI.

See the [v0.1.2 release notes](docs/releases/v0.1.2.md), [rights and
license](#rights-license-and-sources), and [简体中文 guide](README.zh-CN.md).

## Package facts

| Field | Value |
| --- | --- |
| Display name | `Ellen Joe Pixel` |
| Package id | `ellen-joe-pixel` |
| Sprite contract | Codex v2 |
| Atlas | WebP, `1536 x 2288`, 8 columns x 11 rows |
| Cell size | `192 x 208` |
| Look loop | 16 directions, clockwise screen coordinates |
| Install target | `<CodexHome>/pets/ellen-joe-pixel` |

The normal animation rows include idle, movement, waving, jumping, failure,
waiting, running/work, and review states. The look loop runs from `000` (up)
through `090` (right), `180` (down), and `270` (left).

## Support and prerequisites

| Platform | Current support evidence | Requirements |
| --- | --- | --- |
| Windows | Tested by the Windows CI job | PowerShell 5.1 or PowerShell 7 |
| macOS | Validated by the macOS CI job | POSIX `sh` and Python 3 |
| Ubuntu | Validated by the Ubuntu CI job | POSIX `sh` and Python 3 |
| Other Linux distributions | Not guaranteed by this repository | Check the scripts and test locally |

The POSIX installer uses Python 3 to validate the manifest. The repository
validator also uses Pillow; install the development requirements before running
it:

~~~sh
python -m pip install -r requirements-dev.txt
~~~

The CI matrix validates the package contract and installer behavior. It does
not automate the Codex desktop UI, so confirm the pet selection manually.

## Quick install

Run these commands from a clone or an extracted release directory.

### Windows

PowerShell 7:

~~~powershell
pwsh -NoProfile -File .\scripts\install.ps1
~~~

Windows PowerShell 5.1:

~~~powershell
powershell -NoProfile -File .\scripts\install.ps1
~~~

To select an explicit home, replace the placeholder with a real directory:

~~~powershell
pwsh -NoProfile -File .\scripts\install.ps1 -CodexHome '<CodexHome>'
~~~

The Windows installer resolves the home in this order:

1. `-CodexHome`, when supplied;
2. the `CODEX_HOME` environment variable;
3. `%USERPROFILE%\.codex`.

### macOS or Linux

~~~sh
sh ./scripts/install.sh
~~~

With an explicit home:

~~~sh
sh ./scripts/install.sh --codex-home "$HOME/.codex-test"
~~~

The POSIX installer resolves the home in this order:

1. `--codex-home`, when supplied;
2. the `CODEX_HOME` environment variable;
3. `$HOME/.codex`.

Both installers validate the source manifest and pinned WebP before changing
the target. A normal install returns exit code `0`. If the exact target
already exists, the installer returns `2` and leaves it untouched.

## Replace an existing installation

Use force only after confirming that the existing target is the package you
intend to replace:

~~~powershell
pwsh -NoProfile -File .\scripts\install.ps1 -CodexHome '<CodexHome>' -Force
~~~

~~~sh
sh ./scripts/install.sh --codex-home "$HOME/.codex-test" --force
~~~

The installer stages the new package, moves the old exact target to a uniquely
named backup under `<CodexHome>/pet-backups`, and then installs the staged
target. It reports the backup path. Keeping backups outside `pets` prevents
Codex from discovering a backup as a second pet. Uninstall does not remove
backups or neighboring pets. Release [v0.1.1](docs/releases/v0.1.1.md) includes
the backup-location fix for duplicate entries.

## Verify the package

From the repository root, after installing the requirements:

~~~sh
python scripts/validate_pet.py pet/ellen-joe-pixel
~~~

On Windows:

~~~powershell
python .\scripts\validate_pet.py .\pet\ellen-joe-pixel
~~~

The validator returns `0` for a valid package and `1` for a contract
failure. The current packaged WebP SHA-256 is:

~~~text
C6F4ED31F670E00CDA1B596F35372B3B60BA5A6CB94DBD6E049B2E1950FC15E6
~~~

Windows:

~~~powershell
(Get-FileHash -Algorithm SHA256 .\pet\ellen-joe-pixel\spritesheet.webp).Hash
~~~

Linux:

~~~sh
sha256sum pet/ellen-joe-pixel/spritesheet.webp
~~~

macOS:

~~~sh
shasum -a 256 pet/ellen-joe-pixel/spritesheet.webp
~~~

You can validate an installed copy too; substitute the home used for your
installation:

~~~sh
python scripts/validate_pet.py "$HOME/.codex/pets/ellen-joe-pixel"
~~~

## Select the pet in Codex

Open the Codex Pet selector, choose `Ellen Joe Pixel`, and confirm the package
id is `ellen-joe-pixel`. If the selector was already open during installation,
close and reopen it so the package list reloads.

## Uninstall

Windows:

~~~powershell
pwsh -NoProfile -File .\scripts\uninstall.ps1
~~~

macOS or Linux:

~~~sh
sh ./scripts/uninstall.sh
~~~

Pass `-CodexHome '<CodexHome>'` or
`--codex-home "$HOME/.codex-test"` when the installation used an explicit
home. Uninstall removes only `<CodexHome>/pets/ellen-joe-pixel`. It keeps
`<CodexHome>/pet-backups`, `pets/sentinel`, and other neighboring pets. If
the exact target is absent, it returns exit code `2`.

## Recover from a stale install lock

Installers and uninstallers coordinate through the exact path
`<CodexHome>/pets/.ellen-joe-pixel.install.lock`. First verify that no install
or uninstall process is active. Never remove the lock while an operation is
running.

On Windows, the lock is a file:

~~~powershell
$codexHome = Join-Path $env:USERPROFILE '.codex'
$lock = Join-Path $codexHome 'pets\.ellen-joe-pixel.install.lock'
Remove-Item -LiteralPath $lock -Force
~~~

On macOS or Linux, the lock is an empty directory:

~~~sh
codex_home="${CODEX_HOME:-$HOME/.codex}"
rmdir "$codex_home/pets/.ellen-joe-pixel.install.lock"
~~~

Replace the example home when `CODEX_HOME` or an explicit home was used.

## Exit codes

| Code | Meaning | Action |
| ---: | --- | --- |
| `0` | Operation succeeded. | Inspect the reported target or backup path if needed. |
| `2` | Install target already exists without force, or uninstall home/target is absent. | Check the target; use force only intentionally, or treat an absent uninstall as already removed. |
| `3` | Invalid source, argument, manifest, home, or unsafe link/reparse-point path. | Correct the input; do not retry against a broader path. |
| `4` | Recoverable operation failure. A forced install restored the prior target when applicable, or an operation could not acquire its lock. | Read the error, address the cause, and retry only when safe. |
| `5` | Unrecoverable install/rollback, uninstall, or cleanup failure. | Stop, preserve any reported backup/stage path, and perform manual recovery against the exact target. |

The scripts never recursively remove neighboring pets or backup directories.

## Release assets

Download the latest [v0.1.2 release](https://github.com/atanllama/ellen-joe-codex-pet/releases/tag/v0.1.2)
and verify `SHA256SUMS.txt` before installing:

- `ellen-joe-pixel-v0.1.2.zip`
- `ellen-joe-pixel-v0.1.2.tar.gz`
- `SHA256SUMS.txt`

After extraction, run the package validator. The version-specific details are
in the [v0.1.2 release notes](docs/releases/v0.1.2.md).

## Contributions and issues

Contributions to scripts, tests, and documentation are welcome. Before opening
a pull request, run the test suite and package validator:

~~~sh
python -m pytest -q
python scripts/validate_pet.py pet/ellen-joe-pixel
~~~

Do not submit third-party art, source material, credentials, or unreviewed
generated assets. For an issue, include the OS, shell/runtime version, release
or commit, exact command, exit code, and sanitized output. Remove local paths
and secrets before posting.

## Rights, license, and sources

This is an unofficial, non-commercial fan work. It is not affiliated with
HoYoverse, Cognosphere, or OpenAI. Character and franchise rights remain with
their respective owners.

Code and documentation are MIT-licensed only within the scope stated in
[LICENSE](LICENSE). The character, spritesheet, artwork, QA media, and other
excluded assets are not covered by that code/documentation license and are
governed by [NOTICE.md](NOTICE.md). Source credits and provenance notices are
collected in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The project studied these repositories as references only:

- [PlanningStudy with Ellen AI Pet](https://github.com/T-yi-feng/PlanningStudy-with-ellen-ai-pet-)
- [Frieren Codex Pet](https://github.com/zc-xu/frieren-codex-pet)

No ANI, PSD, sprites, pixels, prompts, source code, or animation frames from
either study repository are included here.
