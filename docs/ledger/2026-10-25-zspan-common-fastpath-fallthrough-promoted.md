# Z-span nonnegative fast path falls through (2026-10-25)

Status: promoted in `src/d_draw.s` after exact frame parity, a positive strict
mean, and the complete i486 ISA gate.

The endpoint-proven nonnegative path in `D_DrawZSpans` previously jumped forward
to its fast loop, with the sign-checking general path laid out inline before it.
The successful endpoint checks now fall through into the fast loop, and the
general path sits after it out of line. The loop arithmetic and pixel stores are
unchanged.

The matched runs used DOSBox-X 2026.08.31, `demo1`, three uninstrumented runs,
CWSDPMI, and the pinned 32 MB i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every run
rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261025-172600/timedemo-result.json` | 15.934333 / 15.934332 / 15.934336 | 15.934333667 | 15.934333 |
| Fall-through candidate | `out/dos-timedemo-20261025-192417/timedemo-result.json` | 15.939338 / 15.939349 / 15.939347 | 15.939344667 | 15.939347 |

The candidate mean increased by **0.005011 FPS (0.031448%)**. Its parity screen
also passed with samples 15.939334 / 15.939336 / 15.939340:
`out/dos-timedemo-20261025-190023/timedemo-result.json`.

The complete strict i486 gate passed: 314,398 linked opcodes, 529 startup code
rows, and 9,207 DPMI-provider instructions; zero above-i486, unknown, or exempt
instructions. Final mapping covered 435 source-bound contributions. The result
records `visualParityOnly: false` and `isaAuditStatus: PASS`.
