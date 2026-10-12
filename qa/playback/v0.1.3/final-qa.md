# Final QA — v0.1.3 candidate, 2026-10-12

This is an engineering candidate with explicit acceptance gaps. It is not a four-dimension acceptance PASS. Branch: `codex/ellen-quality-playback`, based on `e758b3200b378205c67351fdbb288d00fcf1b65b`.

Original product/CI commit: `cd3d943a0b00e498efbf3ed9171fc83115afa3ac`. Independent review covered `e758b32..372e21d`; repair commit `c031917` fixed both playback findings. The user then explicitly requested both deferred-minor repairs and further local acceptance: the commit containing this update includes those repairs and the new evidence. Current archive hashes below supersede the earlier candidate. See [execution record](execution-record.md) and [local follow-up](local-acceptance-followup.md).

| Dimension | Status | Actual evidence / gap |
|---|---|---|
| PACKAGE | PASS | 252 Python tests on each of 3.12.9 and 3.14.6; exact final ZIP and tar.gz SHA verification, independent extraction, validation and isolated lifecycle |
| INSTALLER | NOT_RUN | Windows PS 5.1/7 and Windows Git sh PASS; native macOS/Ubuntu NOT_RUN, remote matrix not executed |
| PREVIEW | NOT_RUN | 22 Node tests and prior browser control/DOM-adapter checks PASS; continuous visual sign-off, direct file-open, physical tab hide remain unverified after the native tool stopped UI access |
| APP | NOT_RUN | Installed bytes read-only match; no selector/state/rendering observation in current application |

## Acceptance mapping

| AC | Result | Evidence |
|---|---|---|
| AC-01 | PASS | ZIP/tar independent extraction under Chinese/spaced paths; README links; final-archive-check.json |
| AC-02 | PASS | Fractional/exponent/string/bool version and duplicate keys refused; disguised PNG refused |
| AC-03 | PASS locally | Shared raw JSON corpus, Python/PS5.1/PS7/Git sh: 162 installer/helper checks per Python version; whitespace parity regression included |
| AC-04 | PASS | Static WebP, alpha, size, occupancy checks; six idle frames exclude neutral |
| AC-05 | PASS | Shared lock; invalid/missing lock and wrong approved bytes rejected before target/archive modification |
| AC-06 | NOT_RUN across three OS | PS5.1, PS7, Git sh isolated install/refusal/backup/rollback/uninstall PASS; macOS/Ubuntu pending |
| AC-07 | NOT_RUN full visual acceptance | Browser controls and synthetic visibility events PASS; physical hide and direct file opening pending |
| AC-08 | PASS scoped | Exact bytes embedded; current versioned renderer evidence; unknown event features disabled |
| AC-09 | Records complete; motion UNVERIFIED | Nine action rows, 16 directions, explicit observations; no confirmed ADJUST |
| AC-10 | PASS unchanged asset | Baseline SHA-256 unchanged; no repair or lock update |
| AC-11 | NOT_RUN | app-observation.md gives exact installed identity and human procedure |
| AC-12 | Configuration PASS; CI NOT_RUN | Reusable same-commit checks dependency verified structurally; no remote run or publication |

## Final inputs and outputs

- WebP SHA-256: `c6f4ed31f670e00cda1b596f35372b3b60ba5a6cb94dbd6e049b2e1950fc15e6` (repository = existing installation).
- Codex profile SHA-256: `907c6355c5eee46ee2efb455a27ef7411f18da044a3162ca2d1a016c2b811239`.
- ZIP: `beec6d00af04b1cdd100693c4753770dbd1d7e1db0d88265a3ba71eaa682bcd9`.
- tar.gz: `270db3f3b18c67353448e22bbe3f462e53597d88230ac8b731abca0e97edaaa9`.
- Candidate output directory: `F:/Codex Temp/ellen-local-acceptance-20261012/dist`.
- Self-contained preview: `F:/Codex Temp/ellen-local-acceptance-20261012/preview.html`; original diagnostic-only preview remains in `F:/Codex Temp/ellen-implementation-20261012/diagnostic.html`.
- These paths are local delivery artifacts, not published release URLs. Remote tag v0.1.3 was absent in the read-only 2026-10-12 lookup; recheck before publication.

## Tools and commands

Windows Python 3.12.9 and 3.14.6, Pillow 12.3.0, pytest 9.1.1, PyYAML 6.0.3; Node 24.13.0; PowerShell 7.6.5 and Windows PowerShell 5.1.26100.4484; prior browser Chromium 155.0.8059.39. Local Python 3.12 acceptance now PASS; remote three-OS matrix remains NOT_RUN. Application Store package 26.1007.2314.0; internal version 26.1007.21434.

Commands run from the isolated worktree; latest run root is `F:/Codex Temp/ellen-local-acceptance-20261012`. Python 3.12 is `<run>/venv312/Scripts/python.exe`; Python 3.14 uses the prior run's `venv/Scripts/python.exe`:

```text
python -B -m pytest -q -p no:cacheprovider --basetemp <run>/full312 -> 252 passed in 184.97s, exit 0
python -B -m pytest -q -p no:cacheprovider --basetemp <run>/full314 -> 252 passed in 188.84s, exit 0
node --test tests/playback.test.mjs -> 22 passed, exit 0
python -B scripts/validate_pet.py pet/ellen-joe-pixel --asset-lock release-assets.json -> exit 0
pwsh -NoProfile -File tests/install-windows.ps1 -ShellPath pwsh -> exit 0
powershell.exe -NoProfile -File tests/install-windows.ps1 -ShellPath powershell.exe -> exit 0
Git bash tests/install-posix.sh -> exit 0
python -B scripts/build_release.py --repo-root . --version v0.1.3 --output-dir <run>/dist -> exit 0
python -B <run>/verify-final.py -> both archives SHA/validate/install 0, repeat 2, force 0, uninstall 0; sentinel unchanged
```

Latest local output is under `F:/Codex Temp/ellen-local-acceptance-20261012`: full312.log, full314.log, node-tests.log, windows7.log, windows51.log, git-sh.log, final-archive-check.json. PS5.1 inherited module-path interference was removed at process scope; its harness correctly captures expected native stderr without aborting. No system environment settings changed.

## Evidence and remaining work

Independent review found no Critical issues and two Important playback defects. Both regressions failed first and passed after the single fix pass: stepping backward after completion now allows Play to resume that frame; returning to idle now respects the idle profile's repeat/hold policy and retains its effective frame identity when stopped. Regenerated HTML passed the real-browser Previous/Play check. Both rebuilt archives were re-extracted and passed the isolated lifecycle again with unchanged hashes. Post-review full-suite evidence is `review-fix-tests.log`; it supersedes the initial suite run for the repaired playback tree.

Both deferred minors are now resolved: Python and PowerShell share an explicit whitespace set, with 35 additional cross-entry checks; the two EOF blank lines are removed, and full branch whitespace verification passes. This is separate from the still-incomplete visual/application acceptance.

See [runtime evidence](runtime-evidence.md), [browser checklist](preview-checklist.md), [action assessment](action-assessment.md), [look regression](look-regression.md), [repair decision](repair-record.md), and [app observation procedure](app-observation.md).

To close acceptance: run the actual three-OS matrix on this final commit, open the generated HTML directly and check physical tab hide/restore, sign off all nine native-size motion rows, then observe the existing identical pet in Codex. Any newly confirmed art issue returns to ADJUST and candidate validation. No old waiver is reused.

No push, merge, tag, release, application upgrade or real pet replacement was performed. Keep this branch/worktree for review; publication is a separate decision after these concrete gaps are considered.
