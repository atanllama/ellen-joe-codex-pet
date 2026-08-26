# Ellen Joe Codex Pet Design Specification

**Status:** Approved for implementation  
**Date:** 2026-08-15  
**Target release:** v0.1.0  
**Repository:** `ellen-joe-codex-pet` (private at design time; historical)
**Pet id:** `ellen-joe-pixel`

> **Historical policy note:** This is a private-first design record. Its original
> private-release policy was later superseded by the public-release policy in
> `LICENSE`, `NOTICE.md`, and `THIRD_PARTY_NOTICES.md`; those files govern
> current distribution.

## 1. Objective

Create an original, full-body Ellen Joe fan-art pet for Codex. The pet must use
the Codex v2 animation contract, remain readable in a 192 x 208 pixel cell, and
install safely on Windows, macOS, and Linux.

The visual direction is a compact pixel-art Ellen with approximately 3.5-head
proportions. Her animation personality is 70% sleepy/cool and 30% cute. The
delivery includes the validated pet package, cross-platform installers, retained
QA evidence, and a private GitHub release (the historical release target).

## 2. Scope and non-goals

### In scope

- One complete Codex Pet v2 atlas with all standard states and 16 look directions.
- An all-new full-body Ellen redraw derived from visual study, not copied pixels.
- AI-assisted visual drafts followed by deterministic extraction, alignment,
  transparency cleanup, validation, and visual QA.
- PowerShell installation and uninstallation for Windows.
- POSIX shell installation and uninstallation for macOS and Linux.
- CI validation on Windows, macOS, and Ubuntu.
- A private GitHub repository and a validated `v0.1.0` release (the historical
  private-first target).

### Out of scope

- Reusing or redistributing ANI, PSD, sprites, or source code from either studied
  repository.
- Chat, planning, TTS, caption, or PyQt functionality from the Ellen desktop app.
- At design time, public distribution, commercial use, or an official character
  endorsement was out of scope.
- A one-off v1 atlas or a partial pet without look directions.

## 3. Source and rights policy

The following repositories are visual and format-study references only:

- `T-yi-feng/PlanningStudy-with-ellen-ai-pet-`
- `zc-xu/frieren-codex-pet`

Neither repository provides a reusable license at the time of design. No files,
pixels, animation frames, or code from them will be copied into this project.
The Ellen repository's bust animations may inform personality only; their icons,
speech elements, framing, and pixels are excluded. The Frieren repository may
inform the observed Codex package shape, while the installed `hatch-pet` v2
contract remains the technical authority.

The then-private repository was to include `NOTICE.md` stating that this is an
unofficial, non-commercial fan project; Ellen Joe and Zenless Zone Zero belong
to their respective rights holders; and the artwork is not offered for public
redistribution. The original design added no broad public art license by
default; that private-first policy was later superseded as noted above.

## 4. Visual identity

### Character construction

- Full-body pixel-art Ellen, approximately 3.5 heads tall.
- Simplified maid-combat hybrid outfit with large readable color blocks.
- Preserve the maid headpiece, short black hair with muted red tips, red eyes,
  shark tail, and red shoes as the strongest identifiers.
- Palette: graphite, deep navy, white, and restrained dark red accents.
- Reduce tiny lace, mechanical, and fabric details that would become noise at
  pet size.
- No readable logos, labels, UI, text, or franchise marks.

### Weapon rule

Use a shortened, thickened pair of closed/opening shears sized for the pet.
They are absent from idle and social states, but appear during directional
movement, work, failure, and review states. Their construction, scale, hand
attachment, and occlusion must remain consistent.

### Forbidden visual elements

- Cast or contact shadows and floor patches.
- Motion arcs, speed lines, dust, landing marks, glows, halos, or smears.
- Detached stars, hearts, punctuation, tears, speech bubbles, or icons.
- Scenery, visible layout guides, checkerboards, and opaque backgrounds.
- Accidental transparent holes, disconnected outline pieces, or cropped limbs.

## 5. Master-frame approach

Production begins with one approved full-body front master. A compact identity
sheet then locks the front, left/right three-quarter views, side silhouette,
palette, expressions, face box, head size, foot baseline, tail attachment, and
weapon dimensions.

Every animation row is grounded by the canonical master and its row-specific
layout guide. AI generation produces one coherent strip per state; it never
produces the complete atlas directly. Deterministic scripts extract frames,
normalize geometry, remove the chroma background, and assemble the atlas.
Artistic errors require regeneration of the complete affected row rather than
local patchwork between unrelated generations.

## 6. Atlas contract

- Cell size: `192 x 208` pixels.
- Grid: 8 columns x 11 rows.
- Final atlas: `1536 x 2288` pixels, PNG or WebP source and packaged WebP.
- Manifest: `spriteVersionNumber: 2`.
- Unused standard-row cells: fully transparent.
- All look-direction cells: populated.

| Row | State | Used frames | Animation intent |
| ---: | --- | ---: | --- |
| 0 | idle | 6 | Sleepy breathing, slow blink, small tail sway; no weapon. |
| 1 | running-right | 8 | Low, reluctant rightward trot with compact shears. |
| 2 | running-left | 8 | Independently drawn leftward trot with correct handedness. |
| 3 | waving | 4 | Lazy one-hand greeting and return; no weapon. |
| 4 | jumping | 5 | Small anticipation, hop, peak, descent, and settle. |
| 5 | failed | 8 | Shears lower, shoulders collapse, eyes close, tail droops. |
| 6 | waiting | 6 | Expectant lean and restrained asking gesture; no weapon. |
| 7 | running | 6 | Focused task processing through controlled shears work. |
| 8 | review | 6 | Blade inspection, head tilt, narrowed eyes, tiny nod. |
| 9 | look directions A | 8 | `000` through `157.5`, clockwise. |
| 10 | look directions B | 8 | `180` through `337.5`, clockwise. |

Directional running rows are generated independently because Ellen's outfit,
weapon grip, and shark tail are not assumed safe to mirror.

## 7. Look mechanics

Look directions use screen coordinates: `000` is up, `090` right, `180` down,
and `270` left. Neutral/front falls back to idle.

Ellen's eyes lead the gaze. Eyelids and eyebrows participate, followed by a
small rigid head/neck turn and restrained shoulder motion. The shark tail makes
a subtle continuous counterbalance while the feet, body scale, and baseline
remain anchored. The weapon is absent from look rows. Whole-sprite rotation,
skull stretching, pupil-only shortcuts, and broad raster warping are rejected.

Four cardinal anchors are generated and semantically approved first. Row 9 is
then generated as one coherent eight-pose family. Row 10 is generated only after
row 9 passes registration, edge, semantic, and continuity checks. Adjacent poses
must advance evenly, including the `157.5 -> 180` and `337.5 -> 000` boundaries.

## 8. Production and QA pipeline

1. Generate and approve the canonical full-body master.
2. Generate and incrementally validate idle and running-right as identity and
   cadence checks.
3. Generate running-left independently, then the remaining standard rows.
4. Extract frames and inspect clipping, component connectivity, scale, baseline,
   frame count, and state semantics after every row.
5. Assemble and visually review the intermediate nine-row atlas and row GIFs.
6. Write the pet-specific look-mechanics record and approve the four cardinals.
7. Generate, register, and review look row 9; then do the same for row 10.
8. Assemble the v2 atlas and apply the single deterministic edge-local chroma
   cleanup pass.
9. Run deterministic v2 atlas validation, direction continuity measurement, and
   explicit labeled semantic review for all 16 directions.
10. Run three isolated blind horizontal/vertical direction reviews and combine
    them by strict majority.
11. Run final independent visual QA on contact sheets, direction sheets, and all
    motion previews.
12. Package only when every hard gate passes.

### Hard gates

- Correct atlas dimensions, grid, manifest version, used cells, and transparency.
- Stable identity, face, proportions, palette, baseline, tail, and weapon.
- No clipped bodies, cross-cell overlap, size popping, reversed cadence, or
  forbidden effects.
- Unmistakable cardinal directions and no labeled wrong-quadrant look pose.
- No visible direction reversal, registration jump, identity change, or broken
  prop attachment.
- Passing chroma-despill, atlas-validation, frame-review, direction-semantics,
  blind-direction, and final visual-QA reports.

Minor intermediate-direction ambiguity may be accepted only when labeled review
and ordered-loop evidence both confirm the intended direction, with the override
recorded. Cardinal ambiguity and deterministic failures are never overridden.

## 9. Artifact and repository locations

All project and generated files stay under user-provided local staging roots:

```text
<local-reference-staging>\
├─ ellen-joe-codex-pet\        # Git repository and curated deliverables
└─ artifacts\
   └─ ellen-joe-pixel\         # Raw bounded generation/QA run artifacts
```

In the references below, `<artifact-root>` denotes the local `artifacts` root.

The retained repository layout is:

```text
ellen-joe-codex-pet/
├─ pet/ellen-joe-pixel/
│  ├─ pet.json
│  └─ spritesheet.webp
├─ scripts/
│  ├─ install.ps1
│  ├─ uninstall.ps1
│  ├─ install.sh
│  ├─ uninstall.sh
│  └─ validate_pet.py
├─ qa/
│  ├─ contact-sheet.png
│  ├─ look-directions.png
│  ├─ previews/
│  └─ validation reports
├─ docs/superpowers/specs/
├─ .github/workflows/
├─ README.md
└─ NOTICE.md
```

Raw prompts, layout guides, decoded strips, extracted frames, PNG intermediates,
and the image-generation job manifest remain in the local artifact area during
production. After successful packaging, keep only the bounded evidence required
for reproducibility and troubleshooting; curated QA evidence is copied into the
then-private repository.

## 10. Cross-platform installation

Windows uses `install.ps1` and `uninstall.ps1`. macOS and Linux use portable
POSIX `install.sh` and `uninstall.sh` scripts.

Install destination:

- Windows: `%CODEX_HOME%\pets\ellen-joe-pixel`, falling back to
  `%USERPROFILE%\.codex\pets\ellen-joe-pixel`.
- macOS/Linux: `${CODEX_HOME}/pets/ellen-joe-pixel`, falling back to
  `$HOME/.codex/pets/ellen-joe-pixel`.

Installers validate `pet.json` and `spritesheet.webp` before touching the target.
They stage both files in a temporary sibling directory and rename atomically.
An existing target causes a safe failure by default. Explicit `-Force` or
`--force` creates a uniquely named backup under `<CodexHome>/pet-backups`, outside
the pet discovery directory, before replacement.

Uninstallers resolve and verify the exact pet directory before removal and never
modify other pets or global Codex configuration. Backups are preserved. Repeated
install and uninstall operations return clear, deterministic results.

## 11. CI and release (historical private-first plan)

GitHub Actions runs on Windows, macOS, and Ubuntu. Each job validates the package
and performs install, duplicate-install protection, forced replacement, and
uninstall tests inside an isolated temporary `CODEX_HOME`. A sentinel neighboring
pet verifies that no unrelated directory changes.

After all local and CI checks pass:

1. Create or connect the private GitHub repository `ellen-joe-codex-pet`.
2. Push the reviewed default branch.
3. Create tag `v0.1.0`.
4. Publish a private-repository release containing the packaged pet and checksums.
5. Report the repository, commit, tag, release, local artifact paths, validation
   evidence, and cross-platform test results.

## 12. Completion criteria

The project was considered complete under this historical plan when the original
full-body Ellen pet passed the complete Codex v2 deterministic and visual QA
contract, installed and uninstalled safely on all three target operating-system
families, was visibly demonstrated where feasible, and was published as `v0.1.0`
in the requested private GitHub repository.
