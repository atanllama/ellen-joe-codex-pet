# Codex in-app demonstration feasibility waiver

Date: 2026-08-25

## Environment

- Codex package: `OpenAI.Codex`
- Codex version: `26.818.5229.0`
- Validated source commit: `96eec1b930b28e02ba0d2537641ff2ad7d334bb3`
- Installed package: `C:\Users\MDPI\.codex\pets\ellen-joe-pixel`

## Attempted demonstration

1. Built and validated the v2 package in `pet/ellen-joe-pixel`.
2. Installed it with `scripts/install.ps1` into the real local Codex home.
3. Compared the installed files byte-for-byte by SHA-256 with the repository files.
4. Attempted to locate the Codex pet selector through the supported Windows UI automation interface.

## Exact blocker

The supported Windows automation interface returned the application identifier
`OpenAI.Codex_2p2nqsd0c76g0!App` with the display name `ChatGPT`, no targetable
window, and `isRunning=false`. Its mandatory safety policy also prohibits
automating the ChatGPT desktop UI. A safe automated selection attempt therefore
cannot proceed, and an application screenshot cannot be captured without
fabricating evidence or violating that policy.

This waiver uses the implementation plan's allowed `UI automation is unavailable`
condition. It does not claim that the custom-pet renderer failed.

## Installed package proof

- `pet.json`: `CD9C2BB7CF3CC3D63113400DE8993C81A47C3AC924D2A93788E59196371D6643`
- `spritesheet.webp`: `C6F4ED31F670E00CDA1B596F35372B3B60BA5A6CB94DBD6E049B2E1950FC15E6`
- Both installed hashes matched their repository counterparts.
- `scripts/validate_pet.py` reported `OK: valid Ellen Joe Codex Pet v2 package`.

## Best available visual evidence

- `qa/contact-sheet.png`: all v2 atlas rows at native cell size.
- `qa/look-directions.png`: all 16 labeled look directions.
- `qa/look-directions.gif`: all 16 look directions in playback order.
- `qa/previews/standard/*.gif`: idle, work/review, movement, waiting, waving,
  jumping, and failure animation previews.
- `qa/final-visual-qa.md`: independent final visual QA result, `visual_qa=pass`.

The owner can complete the remaining manual confirmation by restarting Codex if
needed, choosing **Ellen Joe Pixel** in the pet selector, and observing idle plus
one work or review state.
