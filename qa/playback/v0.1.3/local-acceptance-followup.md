# Local acceptance follow-up — 2026-10-12

Scope: user requested repair of both deferred minors and completion of remaining checks possible on this machine. This supersedes the deferred-minor disposition in the historical execution record. Work stays on `codex/ellen-quality-playback`; no remote publication or real pet replacement.

## Repairs

- Description blankness now uses the same explicit 29-character set in Python and PowerShell: Unicode White_Space plus U+001C–U+001F, preserving the original Python contract. U+200B is intentionally not whitespace. Shared fixtures include every separator U+001C–U+001F, the other Unicode whitespace characters, surrounding whitespace with content, and U+200B.
- RED: U+001C failed on both PowerShell installers (accepted invalid input), while Python/POSIX rejected it. GREEN: all 35 new fixture/entry combinations passed, including target/sentinel preservation.
- Removed the extra EOF blank line from both reported test files; full branch `git diff --check e758b32` now passes.

## Local checks

- Nine action timing cases cover once, three loop cycles and Codex completion at each of 0.5x/1x/2x. They also check pause and synthetic hidden-state time retention for every action. Cycle durations are independently transcribed from the existing renderer evidence. Node suite: 22 passed.
- Python 3.12.9 isolated environment added under the run directory to test the CI-selected Python minor version locally. Python 3.14.6 retained for the existing environment. Full-suite results are recorded in final-qa.md.
- Both rebuilt archives have independently verified SHA-256 sums, extraction, Python 3.12 validation, install/refusal/force/uninstall exit codes 0/2/0/0, and an unchanged unrelated-pet sentinel.
- Existing installed WebP and repository WebP still match `c6f4ed31f670e00cda1b596f35372b3b60ba5a6cb94dbd6e049b2e1950fc15e6`.
- Running Store package still 26.1007.2314.0; app.asar still `c5fdef328cfa2ad9095786f9c3a7aaa447e68834d31299d6ef2592da02029038`. Existing source-backed profile evidence remains tied to these bytes.

## UI stop and remaining acceptance

Computer Use initialized successfully and listed a Chrome window titled Ellen Joe Playback lab. Its first browser state capture then stopped the turn's Computer Use because it could not determine the current browser URL with enough confidence to enforce policy. No further UI automation was attempted in this turn. This is a tool-policy stop, not a product failure or a permission question.

Direct file-open, physical background-tab hide/restore, continuous perceptual animation assessment and native-app behavior therefore remain NOT_RUN/UNVERIFIED. Numeric timeline checks do not replace those observations. Computer Use also lists the Codex package as ChatGPT with no targetable window; its bundled guidance explicitly forbids automating the ChatGPT desktop UI. No alternate native UI mechanism was used to bypass that boundary.

WSL reports that it is not installed. Native macOS/Ubuntu and remote CI are outside the available local environment; no OS installation or remote push was performed. Existing historical artwork warnings remain unchanged, and no new ADJUST was established.

## Artifacts

Run root: `F:/Codex Temp/ellen-local-acceptance-20261012`.

- `green.log`, `full312.log`, `full314.log`, `node-tests.log`
- `windows7.log`, `windows51.log`, `git-sh.log`
- `final-archive-check.json`, `archives.log`, `verify-final.py`
- `dist/ellen-joe-pixel-v0.1.3.zip`, `dist/ellen-joe-pixel-v0.1.3.tar.gz`, `dist/SHA256SUMS.txt`
- `preview.html` regenerated from the current tree; previous browser interaction evidence applies to the unchanged preview implementation, while this turn's direct-file UI check was blocked as above.
