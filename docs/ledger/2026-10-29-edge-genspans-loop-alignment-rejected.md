# `R_GenerateSpans` edge-loop alignment rejected (2026-10-29)

Status: rejected after a negative three-run parity screen; the alignment directive was removed.

The candidate added `.p2align 4,,15` immediately before `Lgs_edgeloop` in `src/renderer/r_edgea.s`, on the hypothesis that a 16-byte-aligned entry would reduce instruction-fetch stalls on the i486. The profile census counts 3,500,514 edge entries over `demo1`.

## Matched timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Committed strict control | `out/dos-timedemo-20261029-032931/timedemo-result.json` | 16.312516 / 16.312559 / 16.312559 | 0.000043 | 16.312544667 |
| Alignment candidate parity screen | `out/dos-timedemo-20261029-034250/timedemo-result.json` | 16.311290 / 16.311305 / 16.311340 | 0.000050 | 16.311311667 |

The candidate was **−0.001233 FPS (−0.00755860%)** below the committed control. Every run preserved 969 frames and framebuffer checksum `1047377823`. The result was parity-only, so the strict ISA audit was not run. The candidate was restored without promotion.
