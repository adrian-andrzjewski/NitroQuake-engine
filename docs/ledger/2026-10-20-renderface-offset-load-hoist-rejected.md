# RenderFace cached-offset load hoist (2026-10-20)

Status: rejected after a three-run parity screen; the hoist was removed from
the working assembly source.

This candidate loaded the cached edge offset into `%edx` before the
`edge_p - r_edges` bounds check, then reused it for the owner lookup. It was
intended to avoid reading the offset twice on cache-check paths. The comparison
was made against the immediately preceding promoted build with DOSBox-X
2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and CWSDPMI. Both sets completed all 969 frames with framebuffer
checksum `1047377823`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS |
|---|---|---|---|---:|
| Prior promoted source, strict set | `out/dos-timedemo-20261020-213827/timedemo-result.json` | 62.367481 / 62.367287 / 62.367295 | 15.536943 / 15.536991 / 15.536990 | 15.536974667 |
| Cached-offset load hoist, parity screen | `out/dos-timedemo-20261020-215145/timedemo-result.json` | 62.373768 / 62.373758 / 62.373791 | 15.535377 / 15.535380 / 15.535371 | 15.535376000 |

The candidate averaged **0.001598667 FPS slower (−0.0102894%)**; all three
candidate samples were below the prior strict set. Exact frame and checksum
parity passed. This visual-only screen skipped the renderer ISA audit, and the
slower result was rejected without a strict run. The repeated offset load and
compare remain in the promoted `R_RenderFace` path.
