# Authorized installation and local main merge — 2026-10-12

The user explicitly requested updating the current pet and merging the source back to main. The approved source commit is `e76119d587281e14018b8117acf2d5f7d164825e`.

## Installed package

- Target: `F:/Codex/home/pets/ellen-joe-pixel`.
- Previous installation backup: `F:/Codex/home/pet-backups/ellen-joe-pixel.backup.d99bf26211ea43e592077a6636c91286`.
- Command: `pwsh -NoProfile -File scripts/install.ps1 -CodexHome F:/Codex/home -Force`; exit 0.
- Installed `pet.json` SHA-256: `db26194324b10046735371e5656023f458472f42e53d40f1ecea824e9bb63684`.
- Installed `spritesheet.webp` SHA-256: `c6f4ed31f670e00cda1b596f35372b3b60ba5a6cb94dbd6e049b2e1950fc15e6`.
- Both installed files match the approved source exactly; both backup files match the pre-installation hashes. Installed-package validator with the approved asset lock returned exit 0.
- Exactly one installed Ellen manifest was found; no installer lock or stage directory remained.

The artwork and package identity are unchanged. Reinstallation does not change Codex's built-in trigger policy, repetition or visual appearance. This confirms real file installation, not observation of live application behavior; APP remains NOT_RUN.

## Source integration

Local `main` in `F:/Codex Pet/ellen-joe-codex-pet` fast-forwarded from `e758b32` to `e76119d` using `git merge --ff-only codex/ellen-quality-playback`, without conflicts. The commit containing this receipt adds only installation/integration documentation.

Post-merge checks from the main checkout: Python 3.12.9 full suite **252 passed in 141.03s**; Node playback suite **22 passed**; branch whitespace check passed. These checks establish source/package correctness within their tested scope, not live app visual acceptance.

Raw receipts and merged-check logs: `F:/Codex Temp/ellen-install-merge-20261012` (`before-install.json`, `installation-receipt.json`, `install.log`, `merged-tests.log`, `merged-node.log`). No remote push, tag or release was requested or performed.
