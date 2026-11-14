# Recheck D_DrawZSpans positive-gradient cutoff 20 (2026-10-27)

Status: rejected after the full strict three-run comparison. The 19-pixel
cutoff is restored in `src/renderer/d_draw.s`.

The candidate raised `LZDraw`'s minimum length for the endpoint-proven,
nonnegative fast path from 19 to 20 pixels. This recheck used the current
source after the newer Z-span STOSL store promotions, to see whether their
changed general-loop cost shifted the cutoff.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run rendered 969 frames with framebuffer checksum `1047377823`. The candidate
passed the complete linked i486 ISA gate with zero above-i486, unknown, or
exempt instructions.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Current strict control, cutoff 19 | `out/dos-timedemo-20261026-214707/timedemo-result.json` | 16.107101 / 16.107111 / 16.107108 | 16.107106667 | 16.107108 |
| Recheck, cutoff 20 | `out/dos-timedemo-20261026-235518/timedemo-result.json` | 16.106432 / 16.106454 / 16.106462 | 16.106449333 | 16.106454 |

The candidate was **0.000657334 FPS slower (−0.004082%)**. Exact parity and
the ISA gate passed, but the negative mean rejects the higher cutoff.
