# Alias transform load order removes an FXCH (2026-10-25)

Status: promoted in `src/r_aliasa.s` after exact frame parity, a positive strict
mean, and the complete i486 ISA gate.

The per-vertex transform previously multiplied component 0, then component 1,
and exchanged the x87 stack before adding the translation to component 0. It
now multiplies component 1 first, then component 0, leaving component 0 on top
for the same translation add. The subsequent additions remain ordered as
`(component 0 * matrix + translation) + component 1 * matrix + component 2 * matrix`.
This removes one `FXCH` per transformed alias vertex.

Both strict variants used DOSBox-X 2026.08.31, `demo1`, three uninstrumented
runs, CWSDPMI, and the pinned 32 MB i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261025-151430/timedemo-result.json` | 15.925717 / 15.925727 / 15.925726 | 15.925723333 | 15.925726 |
| Reordered transform loads | `out/dos-timedemo-20261025-154548/timedemo-result.json` | 15.927822 / 15.927835 / 15.927835 | 15.927830667 | 15.927835 |

The candidate mean increased by **0.002107333 FPS (0.0132323%)**. Its parity
screen also passed: `out/dos-timedemo-20261025-152235/timedemo-result.json`.

The complete strict i486 gate passed: 314,390 linked opcodes, 529 startup
code rows, and 9,207 DPMI-provider instructions; zero above-i486, unknown, or
exempt instructions. Final mapping covered 435 source-bound contributions.
The result records `visualParityOnly: false` and `isaAuditStatus: PASS`.
