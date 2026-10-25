# Alias normal load order removes an FXCH (2026-10-25)

Status: promoted in `src/r_aliasa.s` after exact frame parity, a positive strict
mean, and the complete i486 ISA gate.

The alias lighting dot product previously loaded normal components 0, 1, and 2,
then used `fxch %st(1)` before adding component 0 and component 1. It now loads
components 0, 2, and 1, placing component 1 on top for the same component
0-plus-1 addition. This removes one `FXCH` per transformed alias vertex while
keeping the dot-product addition order.

Both strict variants used DOSBox-X 2026.08.31, `demo1`, three uninstrumented
runs, CWSDPMI, and the pinned 32 MB i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261025-143648/timedemo-result.json` | 15.923560 / 15.923549 / 15.923532 | 15.923547000 | 15.923549 |
| Reordered x87 loads | `out/dos-timedemo-20261025-151430/timedemo-result.json` | 15.925717 / 15.925727 / 15.925726 | 15.925723333 | 15.925726 |

The candidate mean increased by **0.002176333 FPS (0.0136674%)**. Its parity
screen also passed: `out/dos-timedemo-20261025-145052/timedemo-result.json`.

The complete strict i486 gate passed: 314,389 linked opcodes, 529 startup
code rows, and 9,207 DPMI-provider instructions; zero above-i486, unknown, or
exempt instructions. Final mapping covered 435 source-bound contributions.
The result records `visualParityOnly: false` and `isaAuditStatus: PASS`.
