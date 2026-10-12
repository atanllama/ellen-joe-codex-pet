# Preview interaction checklist — 2026-10-12

Browser: Chromium 155.0.8059.39 through Playwright. Input WebP: `c6f4ed31f670e00cda1b596f35372b3b60ba5a6cb94dbd6e049b2e1950fc15e6`. Codex profile SHA-256: `907c6355c5eee46ee2efb455a27ef7411f18da044a3162ca2d1a016c2b811239`.

- PASS: all 26 diagnostic choices selected using actual DOM controls; standard rows 0–8, neutral (0,6), look rows 9–10 correctly displayed in row/column output.
- PASS: next/previous frame controls pause; replay starts again; once stops and loop continues (Node boundaries plus actual controls).
- PASS: paused at 80 ms; 5000 ms controlled browser clock elapsed with unchanged progress; resumed remainder. Display updates at requestAnimationFrame cadence (last display 157 ms before next repaint), while the subsequent visibility event settled exactly at col 1 / 0 ms.
- PASS: DOM visibility adapter injected hidden/restored events with 5000 ms gap retained col 1 / 0 ms; no catchup. Physical OS/tab hiding was NOT_RUN, distinct from this adapter check.
- PASS: 0.5/1/2 speed and 1/2 size controls; 2x sprite box exactly 384x416, CSS pixelated; deep/light/checker backgrounds selectable.
- PASS: Codex waving reached idle after 2100 ms at 1x. Missing event rules disable actual checkbox controls. Diagnostic-only page disables Codex option and gives the reason.
- PASS: loaded preview still responds with browser network offline; content has no remote dependencies. Tool blocks file: URLs, so browser interaction used a temporary localhost static server. Direct file double-click remains a manual check; generator has no module imports or external assets.
- PASS: invalid input returns exit 1, leaves prior HTML bytes untouched and prints no success path (Python regression).
- PASS: embedded WebP decodes to identical bytes; profile markup escapes remain data (Python regression).

Review evidence: `preview-dark.png`. Static UI capture does not prove loop semantics; the control observations above and deterministic tests supply that evidence. Native-size animation semantics are recorded separately in action-assessment.md.
## Remaining visual acceptance

The automated browser can expose frames and timing, but these observations do not establish a continuous human visual judgement of motion. Physical background-tab restoration and direct file opening remain unverified. PREVIEW overall therefore remains NOT_RUN (partial automation PASS), rather than an unconditional PASS.
