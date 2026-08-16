# Ellen Joe Pixel standard-row production record

**Status:** Accepted; all nine standard rows are complete and eligible for the
Task 7 intermediate-atlas gate

**Run directory:** `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run`

**Canonical base:** `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\references\canonical-base.png`

**Canonical SHA-256:** `E5AEF69D7F10FFD8A6EEFC25E29D5CEE56B0AC91973209A66D1045028ABAA11F`

**Chroma contract:** run key `#00FF00`, deterministic threshold `96`; the
generated background is judged by that threshold rather than literal byte
equality.

Retry counts below mean additional complete-row generation attempts after the
first attempt. A row was accepted only after the selected source was copied to
its decoded path, the decoded copy matched the selected source by SHA-256,
deterministic inspection completed, and the normal-size strip plus GIF were
reviewed. Independent re-review invalidated the earlier candidate-2 jumping
selection for a forbidden prop. A later coherent, prop-free complete-row
imagegen result was accepted only after the user explicitly authorized scale
`1.00` placement: no resampling, horizontal centering, and whole-sprite vertical
translation to the five approved bottom anchors. No look-cardinal or
look-direction row was generated in this stage.

## Acceptance summary

| State | Frames | Retries | Accepted extraction | Semantic result |
| --- | ---: | ---: | --- | --- |
| `idle` | 6 | 0 | components | Sleepy breathing/blink/tail micro-loop; visibly animated, unarmed, and planted. |
| `running-right` | 8 | 1 | components | Unmistakable right-facing alternating low trot with continuously attached shears. |
| `running-left` | 8 | 0 | components | Independently generated left-facing alternating low trot with preserved asymmetry, grip, and tail structure. |
| `waving` | 4 | 0 | components | Down/raise/tilt/return greeting through the hand and body only; unarmed. |
| `jumping` | 5 | 2 initial + 5 SDD repair rounds + 5 post-review complete-row edits | stable-slots plus authorized scale-1.00 placement | Five empty-handed beats form crouch, lift, peak, descent, and settle with stable feature scale, no effect, and exclusive bottoms `203,193,183,193,203`. |
| `failed` | 8 | 3 | stable-slots | Compact shears lower while shoulders collapse, eyes close, and tail droops without extraction-induced growth. |
| `waiting` | 6 | 1 | components | Restrained expectant hand/lean sequence, distinct from idle and review and unarmed. |
| `running` | 6 | 1 | components | Planted-foot active shears work with eye tracking; no literal locomotion. |
| `review` | 6 | 1 | components | Existing blade inspection with head tilt, narrowed eyes, nod, and no new prop. |

## Row provenance and repair history

### `idle`

- Selected source: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\selected-sources\idle.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\idle.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\idle.png`
- Decoded SHA-256: `590090360DF33BEDAB48EB1A98A34FC184E2BBDE9EE6F5BACE93855718674A3A`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\idle\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\idle.gif`
- Repair history: none; the first attempt passed frame count, connectivity,
  identity, non-static micro-motion, baseline, and forbidden-effect review.

### `running-right`

- Selected source: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\selected-sources\running-right.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\running-right.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\running-right.png`
- Decoded SHA-256: `7C323C85D9E7BE67EE9002BA46F8D33B6D00DDA6B40FA2EF3320B528CAC77D81`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\running-right\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\running-right.gif`
- Repair history: the first source was rejected because shears appeared only
  in frames 5 and 7. One complete-row retry retained the passing rightward
  cadence and attached the same compact shears in all eight frames.

### `running-left`

- Selected source: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\selected-sources\running-left.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\running-left.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\running-left.png`
- Decoded SHA-256: `623313CED12AFCE48CFB2D1F5A0CA99322EA29E7A959C26D41A32024B2B30467`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\running-left\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\running-left.gif`
- Repair history: none. This row came from its own grounded image-generation
  job; no mirror or derivation script was used. The accepted strip preserves
  the screen-left gait, outfit asymmetry, attached grip, and connected tail.

### `waving`

- Selected source: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\selected-sources\waving.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\waving.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\waving.png`
- Decoded SHA-256: `2767D82998108038E0B059AC49A3C5F7CEAF334C4AADB39FD27A48351D69E0AF`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\waving\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\waving.gif`
- Repair history: none; first attempt passed with four unarmed poses and no
  wave marks, symbols, shadows, or detached effects.

### `jumping`

- Selected source: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\selected-sources\jumping.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\jumping.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\jumping.png`
- Decoded SHA-256: `D2F99F38686C391A1390E46EF9B39F2ACD373877A067C73FCA3D01226F9C072A`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\jumping\review.json`
- Authorized transform provenance: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\jumping-authorized-scale1-transform.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\jumping.gif`
- Repair history (RED): the originally accepted source and all five bounded SDD
  repairs failed independent normal-size review for major scale or head/torso
  registration popping. The final image-generation round still had a `51 px`
  head-top swing and missed the requested intermediate shoe-bottom anchors.
- Repair history (invalidated): the user explicitly authorized one narrow exception
  using the complete candidate-2 imagegen row and its stable-slots frames. A
  reviewable deterministic script applied the same nominal `0.90`
  nearest-neighbor sprite-content scale to every frame, centered each result,
  and set exclusive alpha-bbox bottoms to `203, 193, 183, 193, 203`. It did not
  redraw, tile, mirror, rotate, warp, or vary scale by frame. Integer
  quantization produced realized width/height scale `0.8985–0.9028`; alpha-area
  ratios are `0.8077–0.8167`, and all five frames have zero edge pixels.
  Independent re-review then found shears in frames 0–3, which violates the
  unarmed jumping contract and invalidates this otherwise deterministic result.
- Post-review fix 1 used the one permitted complete-row image edit. It removed
  every shears pair and left both hands empty with no new prop or effect, but
  stable-slots geometry shrank `17.4–24.9%` in width and `11.7–15.1%` in height
  relative to candidate 2. Per the review instruction, that is a material
  geometry change. The edit was rejected and was not copied to the selected,
  decoded, canonical-frame, atlas, contact-sheet, or preview paths.
- Rejected edit evidence:
  `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\jumping-post-review-fix1.json`.
- Post-review fix 2 used the fix-1 row as the authoritative empty-hand content
  source and candidate 2 only as the scale/layout reference. It preserved empty
  hands, five-pose order, green background, and zero edge pixels, but remained
  `16.7–24.3%` narrower and `10.7–14.1%` shorter than candidate 2. The common
  `0.90` transform would preserve that scale deficit, so the row was rejected
  without promotion. Evidence:
  `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\jumping-post-review-fix2.json`.
- Post-review fix 3 changed strategy after the repeated shrink root. A
  deterministic, non-packaging `960 x 208` target-layout guide was assembled
  from the already authorized final-cell frames without scaling or
  repositioning. One complete-row image edit used it as geometry authority and
  remained empty-handed with zero edge pixels, but the extracted figures were
  `24.2–32.2%` narrower, `10.7–14.6%` shorter, and `23.3–31.3%` smaller by the
  recorded face-width proxy. The generated row and local guide were both
  rejected for packaging. Evidence:
  `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\jumping-post-review-fix3.json`;
  guide provenance:
  `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\jumping\target-layout-reference.json`.
- Post-review prop fix rounds 4 and 5 kept the five hands empty and introduced
  no prop or effect. Round 4 retained a 28-pixel source-level baseline arc and
  was rejected. Round 5 aligned its source bottoms to `203,202,203,202,202`
  with zero edge pixels, but its `54–56 px` face proxy missed the then-required
  candidate-2 scale and was initially rejected. Historical evidence remains in
  `qa/jumping-post-review-prop-fix-round4.json` and
  `qa/jumping-post-review-prop-fix-round5.json`.
- Final resolution: the user explicitly authorized using that complete,
  prop-free round-5 source at common scale `1.00`. The guarded deterministic
  script used the reviewed stable-slots frames, performed no resampling or
  content edit, horizontally centered each unscaled sprite, and translated the
  complete frames vertically by `0,-9,-20,-9,+1 px`. The exclusive alpha-bbox
  bottoms are `203,193,183,193,203`. Machine-readable proof confirms every
  input/output RGBA crop is byte-identical, every visible-pixel RGBA sequence
  and alpha area is unchanged, and every frame has zero edge pixels. Normal-size
  review confirms the five-beat arc, stable head/face scale, empty hands, no
  prop discontinuity, and no clipping.

### `failed`

- Selected source: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\selected-sources\failed.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\failed.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\failed.png`
- Decoded SHA-256: `E246FD5BDDBE7DBF6CBBF3EA87CA2DCF5B195BF1FA1CD903C9A2683714B8E4FB`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\failed\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\failed.gif`
- Repair history: attempt 1 drifted into a body-height sword-like prop.
  Retry 1 restored compact shears but produced only seven pose groups, causing
  slot fallback and a tiny eighth frame. Retry 2 restored eight groups but
  reintroduced the long blade. A strategy-change retry simplified the tool to
  closed handspan-sized two-loop shears and passed all gates.
  Independent review then exposed component-fit growth during the slump; the
  verified stable-slots frames were promoted byte-for-byte. Normal-size review
  now shows a continuous collapse with stable feature scale and no playback
  growth; all eight frames have zero edge pixels.

### `waiting`

- Selected source: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\selected-sources\waiting.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\waiting.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\waiting.png`
- Decoded SHA-256: `9B59EEEAF7EF8206DA64736E5F6C61D2A2C32EC6F4F91DD862A55C56FB98D701`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\waiting\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\waiting.gif`
- Repair history: the worker rejected its first candidate for a detached
  question-mark bubble and sparkles before selection. One complete-row retry
  removed all symbols and expressed the request only through posture and hands.

### `running`

- Selected source: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\selected-sources\running.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\running.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\running.png`
- Decoded SHA-256: `924329BC383C282893A15554A9D3D17BEE936C309BDCFC646EDE5DD79C8656B0`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\running\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\running.gif`
- Repair history: the first source added cyan/white sparkles around an
  oversized upright blade. One retry removed all effects, kept the shears
  compact and attached, and retained planted-foot work plus eye tracking.

### `review`

- Selected source: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\selected-sources\review.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\review.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\review.png`
- Decoded SHA-256: `E6C2739ADAE623A4FADEC5ED30F9A111CDA833BECD7049E528E78816ED09E199`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\review\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\review.gif`
- Repair history: the first source added books, a white document, and a
  folder/tablet. One complete-row retry removed every new prop and used only
  the attached compact shears for blade inspection and the restrained nod.

## Aggregate standard-row gate

- **Overall gate: passed.** `qa/review.json` reports `ok: true`, 57 frames,
  zero errors, and only the two expected reviewed stable-slots warnings for
  `jumping` and `failed`.
- All 57 used frames are `192 x 208`, non-empty, and clear of cell edges. The
  active jumping source, selected copy, and decoded copy are byte-identical at
  SHA-256
  `D2F99F38686C391A1390E46EF9B39F2ACD373877A067C73FCA3D01226F9C072A`.
- `final/spritesheet.png` and `final/spritesheet.webp` are the regenerated
  deterministic `1536 x 1872` rows 0–8 intermediate accepted for Task 7.
- `qa/contact-sheet.png` and all nine `qa/previews/*.gif` files were regenerated
  from the current 57-frame tree. Normal-size review passes the five-beat jump
  and the stable failed collapse.
- The manifest marks `base` plus all nine standard rows complete and marks
  `jumping` packaging eligible. `look-cardinals`, `look-row-9`, and
  `look-row-10` remain pending, and no decoded look asset exists yet.
- Current base and all row selected-source manifest paths point under the F-drive
  run. Hash-verified C-drive temporary originals were removed only after their
  byte-identical F-drive copies existed; cleanup evidence is
  `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\selected-source-cleanup.json`.
- The round-2 generated original was likewise hash-matched to its retained F-drive
  evidence before exact deletion; see
  `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\fix2-selected-source-cleanup.json`.
- The same exact-file cleanup rule was applied to round 3; see
  `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\fix3-selected-source-cleanup.json`.
