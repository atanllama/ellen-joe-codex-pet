# Ellen Joe Pixel standard-row production record

**Status:** Accepted rows 0–8

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
reviewed. No look-cardinal or look-direction row was generated in this stage.

## Acceptance summary

| State | Frames | Retries | Accepted extraction | Semantic result |
| --- | ---: | ---: | --- | --- |
| `idle` | 6 | 0 | components | Sleepy breathing/blink/tail micro-loop; visibly animated, unarmed, and planted. |
| `running-right` | 8 | 1 | components | Unmistakable right-facing alternating low trot with continuously attached shears. |
| `running-left` | 8 | 0 | components | Independently generated left-facing alternating low trot with preserved asymmetry, grip, and tail structure. |
| `waving` | 4 | 0 | components | Down/raise/tilt/return greeting through the hand and body only; unarmed. |
| `jumping` | 5 | 2 | stable-slots | Crouched anticipation, lift, airborne peak, descent, and upright settle with preserved vertical travel. |
| `failed` | 8 | 3 | components | Compact shears lower while shoulders collapse, eyes close, and tail droops. |
| `waiting` | 6 | 1 | components | Restrained expectant hand/lean sequence, distinct from idle and review and unarmed. |
| `running` | 6 | 1 | components | Planted-foot active shears work with eye tracking; no literal locomotion. |
| `review` | 6 | 1 | components | Existing blade inspection with head tilt, narrowed eyes, nod, and no new prop. |

## Row provenance and repair history

### `idle`

- Selected source: `C:\Users\MDPI\.codex\generated_images\01a00667-2b32-76e2-a108-67a08657c378\exec-8f02a311-63ef-4c57-a124-4f1d6fd09f77.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\idle.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\idle.png`
- Decoded SHA-256: `590090360DF33BEDAB48EB1A98A34FC184E2BBDE9EE6F5BACE93855718674A3A`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\idle\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\idle.gif`
- Repair history: none; the first attempt passed frame count, connectivity,
  identity, non-static micro-motion, baseline, and forbidden-effect review.

### `running-right`

- Selected source: `C:\Users\MDPI\.codex\generated_images\01a00667-4ead-7c60-8c76-ac6293862865\exec-5ac40af7-cd94-4967-8521-c7a5cb651dbc.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\running-right.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\running-right.png`
- Decoded SHA-256: `7C323C85D9E7BE67EE9002BA46F8D33B6D00DDA6B40FA2EF3320B528CAC77D81`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\running-right\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\running-right.gif`
- Repair history: the first source was rejected because shears appeared only
  in frames 5 and 7. One complete-row retry retained the passing rightward
  cadence and attached the same compact shears in all eight frames.

### `running-left`

- Selected source: `C:\Users\MDPI\.codex\generated_images\01a0066b-f9a2-7b12-8241-caef79e8b493\exec-28cd7374-113d-4964-8b44-959c403d5c5e.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\running-left.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\running-left.png`
- Decoded SHA-256: `623313CED12AFCE48CFB2D1F5A0CA99322EA29E7A959C26D41A32024B2B30467`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\running-left\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\running-left.gif`
- Repair history: none. This row came from its own grounded image-generation
  job; no mirror or derivation script was used. The accepted strip preserves
  the screen-left gait, outfit asymmetry, attached grip, and connected tail.

### `waving`

- Selected source: `C:\Users\MDPI\.codex\generated_images\01a0066a-6d1c-7011-bba7-7fab44d24429\exec-fe68b425-0908-4af8-b470-d4ffffa988ec.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\waving.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\waving.png`
- Decoded SHA-256: `2767D82998108038E0B059AC49A3C5F7CEAF334C4AADB39FD27A48351D69E0AF`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\waving\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\waving.gif`
- Repair history: none; first attempt passed with four unarmed poses and no
  wave marks, symbols, shadows, or detached effects.

### `jumping`

- Selected source: `C:\Users\MDPI\.codex\generated_images\01a0066c-d26c-7543-b84a-4f5d95f855d8\exec-f8797d88-d665-47fa-bdc6-df162e2dc658.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\jumping.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\jumping.png`
- Decoded SHA-256: `075CD71E2BB3C6434650984DFE221E5560224F6A485D4081C0F3285C280F1359`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\jumping\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\jumping.gif`
- Repair history: the first source had correct five-beat poses, but
  component-by-component fitting erased the vertical arc; stable-slots
  preserved it only with excessive in-cell shrink. Retry 1 constrained the
  arc and restored near-canonical height but made the body poses effectively
  static. Retry 2 restored a clear crouch, lift, peak, descent, and settle.
  The accepted stable-slots report retains its expected playback-review
  warning; normal-size review confirmed the vertical arc, complete silhouettes,
  stable source scale, and no clipping, shadow, dust, or landing mark.

### `failed`

- Selected source: `C:\Users\MDPI\.codex\generated_images\01a0066e-702c-7bb3-ab1c-41fb43791e61\exec-ba5e0e7d-ba38-4b5f-b27f-14d971ac170b.png`
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

### `waiting`

- Selected source: `C:\Users\MDPI\.codex\generated_images\01a0066e-f591-78f1-85a1-77b7c9b393f4\exec-1a0add4a-5c86-4f89-9095-45b6bb350fa3.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\waiting.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\waiting.png`
- Decoded SHA-256: `9B59EEEAF7EF8206DA64736E5F6C61D2A2C32EC6F4F91DD862A55C56FB98D701`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\waiting\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\waiting.gif`
- Repair history: the worker rejected its first candidate for a detached
  question-mark bubble and sparkles before selection. One complete-row retry
  removed all symbols and expressed the request only through posture and hands.

### `running`

- Selected source: `C:\Users\MDPI\.codex\generated_images\01a00673-8d65-7e12-89ac-7d5d0d3dbdb3\exec-99dcf988-0078-410f-a168-f1a04f584e31.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\running.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\running.png`
- Decoded SHA-256: `924329BC383C282893A15554A9D3D17BEE936C309BDCFC646EDE5DD79C8656B0`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\running\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\running.gif`
- Repair history: the first source added cyan/white sparkles around an
  oversized upright blade. One retry removed all effects, kept the shears
  compact and attached, and retained planted-foot work plus eye tracking.

### `review`

- Selected source: `C:\Users\MDPI\.codex\generated_images\01a00675-eba8-70c1-a99c-9f1acd8441d1\exec-bba60f0a-a233-4675-af88-152a53ac49d3.png`
- Prompt: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\prompts\rows\review.md`
- Decoded row: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\decoded\review.png`
- Decoded SHA-256: `E6C2739ADAE623A4FADEC5ED30F9A111CDA833BECD7049E528E78816ED09E199`
- Deterministic report: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\rows\review\review.json`
- GIF: `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\previews\review.gif`
- Repair history: the first source added books, a white document, and a
  folder/tablet. One complete-row retry removed every new prop and used only
  the attached compact shears for blade inspection and the restrained nod.

## Aggregate standard-row gate

- `qa/review.json` reports `ok: true`, no errors, and one reviewed warning for
  the deliberate `jumping` stable-slots correction.
- All 57 used frames are `192 x 208`, non-empty, clear of cell edges, and
  extracted with the run's chroma key and threshold.
- `final/spritesheet.webp` is the deterministic `1536 x 1872` rows 0–8
  intermediate only; it is not a packaged v2 pet.
- `qa/contact-sheet.png` and all nine files under `qa/previews/` were reviewed
  at normal pet size. Identity, palette, headpiece, face, tail attachment,
  shoes, prop rules, direction semantics, and forbidden-effect rules passed.
- The manifest marks exactly `base` plus these nine standard rows complete.
  `look-cardinals`, `look-row-9`, and `look-row-10` remain pending, and no
  decoded look asset exists.
