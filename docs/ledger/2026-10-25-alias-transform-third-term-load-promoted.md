# Alias transform adds the first two terms before loading the third (2026-10-25)

Status: promoted in `src/renderer/r_aliasa.s` after exact frame parity, a positive strict
mean, and the complete i486 ISA gate.

The transform previously loaded and multiplied component 2, then exchanged the
x87 stack to add component 1 to the accumulated component 0 and translation.
It now adds component 1 to that accumulator first, then loads and multiplies
component 2 and performs the final addition. The arithmetic remains ordered as
`(component 0 * matrix + translation) + component 1 * matrix + component 2 * matrix`.
This removes one `FXCH` per transformed alias vertex.

Both strict variants used DOSBox-X 2026.08.31, `demo1`, three uninstrumented
runs, CWSDPMI, and the pinned 32 MB i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261025-154548/timedemo-result.json` | 15.927822 / 15.927835 / 15.927835 | 15.927830667 | 15.927835 |
| Reordered accumulation | `out/dos-timedemo-20261025-162013/timedemo-result.json` | 15.930100 / 15.929903 / 15.929912 | 15.929971667 | 15.929912 |

The candidate mean increased by **0.002141 FPS (0.0134419%)**. Its parity
screen also passed: `out/dos-timedemo-20261025-155206/timedemo-result.json`.

The complete strict i486 gate passed: 314,391 linked opcodes, 529 startup
code rows, and 9,207 DPMI-provider instructions; zero above-i486, unknown, or
exempt instructions. Final mapping covered 435 source-bound contributions.
The result records `visualParityOnly: false` and `isaAuditStatus: PASS`.
