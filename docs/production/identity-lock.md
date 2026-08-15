# Ellen Joe Pixel identity lock

**Status:** Approved canonical base  
**Generation completed:** 2026-08-15T16:59:57Z  
**Canonical artifact:** `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\references\canonical-base.png`  
**Canonical SHA-256:** `E5AEF69D7F10FFD8A6EEFC25E29D5CEE56B0AC91973209A66D1045028ABAA11F`  
**Normal-size QA preview:** `F:\Codex Pet\artifacts\ellen-joe-pixel\v0.1.0-run\qa\base-normal-size.png`

This file records geometry and identity decisions only. It does not embed or
redistribute any studied source image.

## Approved identity

- Original full-body pixel redraw with approximately 3.5-head proportions and
  a sleepy/cool expression with restrained cute styling.
- Large readable maid-combat color blocks: near-black and graphite dress,
  white headpiece and apron, muted dark-red accents, warm dark stockings, and
  red-soled black shoes.
- Short black hair, muted red tips, red eyes, maid headpiece, connected shark
  tail, and red shoes remain the primary recognition cues.
- Front-facing neutral pose is intentionally unarmed. Compact shears remain
  reserved for directional movement, work, failure, and review states.

## Palette lock

The generated master contains natural shade variants around these anchor
colors. Animation rows must preserve the same value ordering and must not use
green-key-adjacent colors in the sprite.

| Role | Anchor |
| --- | --- |
| Outline / deepest value | `#020101` |
| Hair and dress graphite | `#2B2730`, `#37323D` |
| Secondary dark material | `#3C3A41`, `#5B4A4F` |
| White fabric | `#F5EEEF` |
| Cool trim grey | `#989693` |
| Skin lights / shade | `#F8E3DA`, `#E8CCC4` |
| Muted hair-tip red | `#5F2D34` |
| Eye and shoe red | approximately `#C84151`, `#B12926` |
| Stocking brown | `#75595C` |

## Geometry lock at 192 x 208

The approved source is `1205 x 1306`. A nearest-neighbor normal-size review
fits its detected full-body bounds into the standard safe area.

- Full source silhouette box: `(341, 79)` through `(953, 1227)`.
- Normal-size silhouette box: `x=49..142`, `y=16..191` (`94 x 176`).
- Foot baseline: `y=192`; the red soles and heels are complete above it.
- Face-feature box: approximately `x=60..109`, `y=51..84`. Keep both eyes,
  eyelids, brow attitude, nose/mouth pixels, and cheek spacing inside this box.
- Head and headpiece remain centered over the torso; do not enlarge the head or
  compress the legs in later rows.
- Tail attachment: character screen-right hip/back at approximately
  `(98, 111)`. The tail overlaps the body at the root and occupies roughly
  `x=94..142`, `y=103..149` in the neutral silhouette; it must never become a
  detached component.
- Weapon dimensions in this neutral master: `0 x 0` pixels (correctly absent).
  When a state requires shears, use a shortened thickened tool with a nominal
  closed envelope near `42 x 18` pixels and an opened envelope no larger than
  `48 x 30` pixels at normal size. Keep the grip attached and visible blade or
  handle thickness at least 3 pixels.

## Explicit pass evidence

- **Identity:** maid headpiece, black hair with muted red tips, red eyes,
  simplified maid-combat outfit, connected shark tail, and red shoes are all
  readable in the 192 x 208 QA preview.
- **Full body:** no crop touches the cell boundary; margins are 49 pixels left,
  49 pixels right, 16 pixels top, and 16 pixels below the foot baseline.
- **Weapon rule:** the master has no shears or other prop.
- **Background:** the generated field is visually flat green keyed to
  `#00FF00`; every exterior pixel is removable within chroma distance 96. The
  rejected first candidate was not used.
- **Forbidden effects:** no cast/contact shadow, floor patch, motion mark,
  detached symbol, text, logo, UI, scenery, glow, halo, smear, or guide mark is
  present.
- **Readability:** eyes, headpiece, apron, tail root/tip, legs, and both red
  shoes remain distinct at normal pet size.

Only this canonical base may ground later animation-row generation. Any row
that changes these palette, face, baseline, tail, weapon, or silhouette rules
must be regenerated as a complete row.
