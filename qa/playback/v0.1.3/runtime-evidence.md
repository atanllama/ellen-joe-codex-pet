# Runtime evidence — 2026-10-12 (Europe/Budapest)

Application package: `OpenAI.Codex_26.1007.2314.0_x64__2p2nqsd0c76g0`; running executable `app/ChatGPT.exe`. Internal package.json version: **26.1007.21434**. These are separate version identifiers.

Read-only source: `C:/Program Files/WindowsApps/OpenAI.Codex_26.1007.2314.0_x64__2p2nqsd0c76g0/app/resources/app.asar`.
ASAR SHA-256: `c5fdef328cfa2ad9095786f9c3a7aaa447e68834d31299d6ef2592da02029038`.

## Evidence E1 — STATIC_VERIFIED

`webview/assets/app-initial-b8e1c8014bb4.js`, SHA-256 `799331dde54905c4df5e360f23a9621141759e2c0acb230aeab909f9904b646f`.
Decoded UTF-8 character offsets: `elo` 6578687, `BQ` 6579050; `clo`, `glo`, `_lo` immediately follow. Offsets are character positions, not byte offsets. Source extracts are temporary and are not redistributed.

Normal-motion component with `loop=false`: idle loops six frames with durations **1680, 660, 660, 840, 840, 1920 ms** (base durations multiplied by 6). Other sequences repeat **3** times, then switch to this idle loop. `loop=true` overrides that with continuous selected-action repetition. Reduced-motion mode holds the first action frame. The preview Codex profile covers only the normal-motion, loop=false branch; it does not model reduced motion or claim overlay triggers.

| State | Row | Columns | Normal frame / last frame ms |
|---|---:|---|---|
| idle | 0 | 0–5 | values above |
| movingRight (runtime running-right) | 1 | 0–7 | 120 / 220 |
| movingLeft (runtime running-left) | 2 | 0–7 | 120 / 220 |
| waving | 3 | 0–3 | 140 / 280 |
| jumping | 4 | 0–4 | 140 / 280 |
| failed | 5 | 0–7 | 140 / 240 |
| waiting | 6 | 0–5 | 150 / 260 |
| running | 7 | 0–5 | 120 / 220 |
| review | 8 | 0–5 | 150 / 280 |

The component effect resets to frame zero when state/look/loop/reduced-motion/row-count dependencies change. This is component behavior, not a complete event-transition policy. Look mapping quantizes clockwise screen angles in 22.5-degree steps into rows 9–10; radius <=1 returns null. Native pointer hover optionally requests jumping when respondToHover is enabled; enabling this at the actual overlay is not established here.

## Evidence E2 — STATIC_VERIFIED, incomplete event policy

`webview/assets/avatar-overlay-native-page-c254d4864d6b.js`, SHA-256 `0723ddd4ef7324ca857f0db19ec16190ac9aa650878bb25b5270f68bed6edbfd`.
The current overlay combines notification status, transient state and look targets. At character 213882 the look target includes conditional points and caretPoint; at 225689 these feed the pet component. The complete live condition/notification/transient precedence and interruption semantics have not been established. **priority / transitions / lookTrigger = UNKNOWN** in the profile; event simulation remains disabled. Do not infer these rules from the historical build.

## Installed bytes and observation boundary

Current process CODEX_HOME: `F:/Codex/home`. Existing pet: `F:/Codex/home/pets/ellen-joe-pixel`; manifest identity/version checked read-only. Installed and repository WebP SHA-256 both `c6f4ed31f670e00cda1b596f35372b3b60ba5a6cb94dbd6e049b2e1950fc15e6`.

APP_OBSERVED: **none**. Native application control is unavailable in this text session. No application upgrade, asset replacement or installation occurred. Static renderer rules establish preview parameters only.
