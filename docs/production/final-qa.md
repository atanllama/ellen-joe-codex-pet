# Final QA — Ellen Joe Pixel v0.1.0

**Status:** accepted for private packaging  
**Visual verdict:** `visual_qa=pass`  
**QA date:** 2026-08-25  
**Artifact run:** `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run`

This record describes the exact final-v2 evidence used for the staged package.
The F-drive run is the source of truth for generation and QA evidence; only
curated final media and reports belong in the private repository.

## Final artifact identity

| Artifact | Evidence | SHA-256 |
| --- | --- | --- |
| Final PNG atlas | `final-v2/spritesheet.png` | `C253482A02875673CB844F38CE4FC8C4992B8B8CCCF96E5A1B8427CD4DF08356` |
| Packaged WebP atlas | `final-v2/spritesheet.webp`; staged copy `pet/ellen-joe-pixel/spritesheet.webp` | `C6F4ED31F670E00CDA1B596F35372B3B60BA5A6CB94DBD6E049B2E1950FC15E6` |
| Final manifest | `final-v2/final-manifest.json` | records `v2ValidationOk=true`, `visualQa=pass` |

The atlas is RGBA, `1536 x 2288`, 8 columns x 11 rows, with `192 x 208`
cells and sprite version `2`. The package manifest uses id
`ellen-joe-pixel`, display name `Ellen Joe Pixel`, and
`spritesheetPath: "spritesheet.webp"`.

## Deterministic validation

Evidence: `final-v2/validation-v2.json`.

- `ok=true`; errors and validator warnings are empty.
- Dimensions, grid, RGBA mode, and sprite version match the package contract.
- Transparent RGB residue is `0`; chroma-fringe diagnostics are `0`.
- Two isolated opaque key-color pixels remain listed in the cell diagnostics;
  the installed v2 validator accepts them, and native-size visual review found
  no visible defect.

The exact repository validator is also run against
`pet/ellen-joe-pixel` before packaging:

```text
python scripts/validate_pet.py pet/ellen-joe-pixel
```

## Look-row evidence and continuity

The final look loop contains, in order:

`000, 022.5, 045, 067.5, 090, 112.5, 135, 157.5, 180, 202.5, 225, 247.5, 270, 292.5, 315, 337.5`.

Row 9 v2 was independently reviewed and promoted from
`qa/task-8-final-row9-candidate-v2.png` with SHA-256
`17E7D8A372325F2ECA9ED484E964E609239A6E08409EEA784B89B78EC2D3FC63`.
Row 10's accepted registered candidate is recorded at
`qa/task-9-row10-attempt1-registered-candidate.png` with SHA-256
`E30D37468A8976447C6638A050CB3AE4CEE47F664F9E7A9AF004FE96672818DA`.

Evidence for the cross-row and internal geometry gates is:

- `qa/task-9-row10-mechanical-qa-report.md`
- `qa/task-9-row10-mechanical-qa.json`
- `qa/task-9-row10-continuity-metrics.json`
- `final-v2/qa/look-continuity.json`
- `final-v2/qa/direction-semantics.json`

The required `157.5 -> 180` and `337.5 -> 000` boundaries pass the reviewed
geometry and native-size visual checks. The final visual reviewer found no
quadrant reversal, registration jump, tail detachment, clipping, or identity
drift.

## Blind reviews and accepted warnings

Three isolated reviewers saw only the unlabeled A/B direction sheet. Evidence:

- `final-v2/qa/blind-review-1.json`
- `final-v2/qa/blind-review-2.json`
- `final-v2/qa/blind-review-3.json`
- `final-v2/qa/blind-review-summary.md`
- `final-v2/qa/look-directions-blind-validation.json`
- `final-v2/qa/labeled-warning-resolution.md`

The blind validator reports `ok=true`, zero hard errors, zero hard unconfirmed
pairs, and correct cardinal pairs (`000/180` and `090/270`). Seven review-only
intermediate axes were ambiguous in the strict blind majority:
`022.5`, `112.5`, `135`, `157.5`, `247.5`, `292.5`, and `337.5`.
Labeled native-size review confirms that every one remains in the intended
clockwise quadrant, so these are recorded as **accepted minor warnings**, not
failures. The continuity report's heuristic hole rows at `247.5`, `270`, and
`292.5`, plus local diff outliers, were likewise reviewed as intentional
negative space or normal direction changes with no visible defect.

The fresh final visual review is `final-v2/qa/final-visual-qa.md`; its verdict
is exactly `visual_qa=pass` across the standard animations and the full look
loop. Weapons appear only in permitted work/review states; look rows are
unarmed. No shadow, text, detached effect, clipping, or broken attachment was
accepted.

## Single completed-atlas despill

Evidence: `final-v2/single-despill-evidence.json` and
`final-v2/despill-report.json`.

- `pipelineInvocationCount=1`
- Input: `spritesheet-pre-despill.png`, SHA-256
  `E906944F4A89236589F97ECDF987A59623FE22893546DB3B73AA3F5936EE0FEB`
- Output: `spritesheet.png`, SHA-256
  `C253482A02875673CB844F38CE4FC8C4992B8B8CCCF96E5A1B8427CD4DF08356`
- `changedPixels=147127`; `alphaPreserved=true`
- `rowRegistrationDespillApplied=false`

No row-level despill was run. The one chroma-edge cleanup was applied only to
the completed 8 x 11 atlas, after registration and review, as required.
