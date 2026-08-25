# Ellen Joe Pixel — private Codex Pet

Ellen Joe Pixel is an unofficial, non-commercial, private fan project: a
full-body Ellen Joe Codex Pet with a Codex v2 spritesheet. It is intended for
Boss's personal use. The rights and non-reuse terms are in [NOTICE.md](NOTICE.md).

This page is a how-to guide. It covers installation, replacement, verification,
selection, and removal. The scripts install only the exact target
`pets/ellen-joe-pixel`.

## Package at a glance

- Display name: `Ellen Joe Pixel`
- Package id: `ellen-joe-pixel`
- Sprite format: Codex v2, `1536 x 2288` atlas, 8 columns x 11 rows
- Cell size: `192 x 208`
- Look directions: 16 directions, clockwise in screen coordinates from `000`
  (up) through `090` (right), `180` (down), and `270` (left)
- Supported hosts: Windows PowerShell, macOS, and Linux

## Install on Windows

From a clone or an extracted private release, open PowerShell at the project
directory:

```powershell
pwsh -NoProfile -File .\scripts\install.ps1
```

Windows PowerShell 5.1 can use the same script:

```powershell
powershell -NoProfile -File .\scripts\install.ps1
```

To choose a different Codex home, pass `-CodexHome`. This is useful for a test
home or a second local profile:

```powershell
pwsh -NoProfile -File .\scripts\install.ps1 `
  -CodexHome 'F:\Codex Home\private'
```

The default resolution is:

1. `-CodexHome`, when supplied;
2. the `CODEX_HOME` environment variable;
3. `%USERPROFILE%\.codex`.

The exact destination is `<CodexHome>\pets\ellen-joe-pixel`. A normal install
returns exit code `0`. If that exact target already exists, the script stops
with exit code `2` and leaves the existing installation untouched.

### Replace an existing Windows install

Use `-Force` only after confirming that the existing target is the package you
intend to replace:

```powershell
pwsh -NoProfile -File .\scripts\install.ps1 `
  -CodexHome 'F:\Codex Home\private' -Force
```

The installer stages the two package files first, moves the old target to a
timestamped sibling such as
`ellen-joe-pixel.backup.20260825T120000Z.1234`, and then installs the staged
target. A successful forced replacement reports the backup path. Backups and
neighboring pets are not removed by uninstall.

## Install on macOS or Linux

From the project directory:

```sh
sh ./scripts/install.sh
```

To choose a different Codex home:

```sh
sh ./scripts/install.sh --codex-home "$HOME/.codex-private"
```

To replace an existing exact target:

```sh
sh ./scripts/install.sh --codex-home "$HOME/.codex-private" --force
```

The POSIX default resolution is:

1. `--codex-home`, when supplied;
2. the `CODEX_HOME` environment variable;
3. `$HOME/.codex`.

The exact destination is `<CodexHome>/pets/ellen-joe-pixel`. The POSIX script
uses Python 3 to validate the source manifest before staging it. It refuses
symbolic-link or reparse-point paths that could escape the selected Codex home.
Both installers also verify the complete manifest and the approved v2 WebP
SHA-256 before touching the target; that pinned atlas hash carries the validated
dimensions, transparency, and used-cell layout without requiring Pillow.

## Verify the package

Run the repository contract validator from the project directory:

```sh
python scripts/validate_pet.py pet/ellen-joe-pixel
```

On Windows the equivalent is:

```powershell
python .\scripts\validate_pet.py .\pet\ellen-joe-pixel
```

The command exits `0` when the manifest and atlas satisfy the package contract.
It exits `1` for a package-contract validation failure. To verify the staged
WebP byte-for-byte, the v0.1.0 SHA-256 is:

```powershell
(Get-FileHash -Algorithm SHA256 .\pet\ellen-joe-pixel\spritesheet.webp).Hash
# C6F4ED31F670E00CDA1B596F35372B3B60BA5A6CB94DBD6E049B2E1950FC15E6
```

```sh
sha256sum pet/ellen-joe-pixel/spritesheet.webp
# C6F4ED31F670E00CDA1B596F35372B3B60BA5A6CB94DBD6E049B2E1950FC15E6  pet/ellen-joe-pixel/spritesheet.webp
```

macOS, where `sha256sum` may not be installed, can use:

```sh
shasum -a 256 pet/ellen-joe-pixel/spritesheet.webp
```

For a local install, run the validator against the exact installed directory
as well. For example, with an explicit POSIX home:

```sh
python scripts/validate_pet.py "$HOME/.codex-private/pets/ellen-joe-pixel"
```

## Select Ellen in Codex

Open the Codex Pet selector, choose the entry named `Ellen Joe Pixel`, and
confirm that its package id is `ellen-joe-pixel`. The atlas contains the normal
animation rows plus the complete 16-direction look loop. If the pet list was
already open during installation, close and reopen the selector so it reloads
the installed package.

## Uninstall

Windows:

```powershell
pwsh -NoProfile -File .\scripts\uninstall.ps1 `
  -CodexHome 'F:\Codex Home\private'
```

macOS/Linux:

```sh
sh ./scripts/uninstall.sh --codex-home "$HOME/.codex-private"
```

If no home option is provided, each uninstaller resolves `CODEX_HOME` and then
its platform default in the same way as the installer. Uninstall removes only
`<CodexHome>/pets/ellen-joe-pixel`; it does not remove timestamped backups,
`pets/sentinel`, or any other neighboring pet. Running uninstall when the
exact target is absent returns exit code `2`.

## Exit-code reference

The installer and uninstaller use these safety-oriented codes. Shells should
inspect the code before treating a non-zero result as a completed operation.

| Code | Meaning | Typical action |
| ---: | --- | --- |
| `0` | Operation succeeded. | Continue; inspect the printed target or backup path if needed. |
| `2` | The install target already exists without force, or the uninstall target/home is absent. | Use `-Force`/`--force` only after checking the target, or treat an absent uninstall as already removed. |
| `3` | Invalid source, argument, manifest, Codex-home path, or unsafe link/reparse-point target. | Correct the input; do not retry against a broader path. |
| `4` | Installation failed, but staging cleanup and restoration of the prior target succeeded. | Read the error, keep the restored prior install, and retry only after addressing the cause. |
| `5` | An unrecoverable install/rollback or uninstall failure occurred. | Stop and perform manual recovery using the reported backup path; verify the exact target before retrying. |

On a forced replacement, code `4` means the old target was restored. Code `5`
means restoration or cleanup could not be proven; preserve the reported backup
and stage paths until recovery is complete. The scripts never use a broad
recursive delete for neighboring pets or backups.

## Release files

The private v0.1.0 release contains:

- `ellen-joe-pixel-v0.1.0.zip`
- `ellen-joe-pixel-v0.1.0.tar.gz`
- `SHA256SUMS.txt`

Use the checksum manifest before installing an archive, then run the validator
after extraction. This project is intentionally private and unofficial; see
[NOTICE.md](NOTICE.md) before sharing any artifact.
