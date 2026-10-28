# Texture-span tail word stores (2026-10-20)

Status: rejected after a three-run parity screen; `TextureSpanTailStores=control`
remains the default.

The `TextureSpanTailStores=word` path packs adjacent texels from the final
short segment into word stores while retaining the existing sample order. It
was screened against the immediately preceding promoted build with DOSBox-X
2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and CWSDPMI. Both sets completed all 969 frames with framebuffer
checksum `1047377823`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS |
|---|---|---|---|---:|
| Current control, strict set | `out/dos-timedemo-20261020-213827/timedemo-result.json` | 62.367481 / 62.367287 / 62.367295 | 15.536943 / 15.536991 / 15.536990 | 15.536974667 |
| Tail word stores, parity screen | `out/dos-timedemo-20261020-214551/timedemo-result.json` | 63.093541 / 63.093383 / 63.093414 | 15.358149 / 15.358187 / 15.358180 | 15.358172000 |

The candidate averaged **0.178802667 FPS slower (−1.1508204%)**, and every
candidate sample was slower than every control sample. Exact frame and
checksum parity passed. The parity-only screen explicitly skipped the
renderer ISA audit, so this result does not establish strict i486
compatibility. The measured slowdown is sufficient to reject it; the
experimental selector remains available for reproduction, and the default
stays on control.
