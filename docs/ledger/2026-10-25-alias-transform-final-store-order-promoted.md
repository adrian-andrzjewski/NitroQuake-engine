# Alias transform stores projected fields in stack order (2026-10-25)

Status: promoted in `src/r_aliasa.s` after exact frame parity, a positive strict
mean, and the complete i486 ISA gate.

After projection, the x87 stack already held the Y coordinate, X coordinate,
and reciprocal depth. The code exchanged the stack to place reciprocal depth
first, then stored the three values. It now stores those same values directly
to their matching `fv_v` fields in stack order, removing one `FXCH` per
transformed alias vertex.

Both strict variants used DOSBox-X 2026.08.31, `demo1`, three uninstrumented
runs, CWSDPMI, and the pinned 32 MB i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261025-162013/timedemo-result.json` | 15.930100 / 15.929903 / 15.929912 | 15.929971667 | 15.929912 |
| Reordered final stores | `out/dos-timedemo-20261025-165547/timedemo-result.json` | 15.932178 / 15.932214 / 15.932215 | 15.932202333 | 15.932214 |

The candidate mean increased by **0.002230667 FPS (0.0140030%)**. Its parity
screen also passed: `out/dos-timedemo-20261025-162851/timedemo-result.json`.

The complete strict i486 gate passed: 314,392 linked opcodes, 529 startup
code rows, and 9,207 DPMI-provider instructions; zero above-i486, unknown, or
exempt instructions. Final mapping covered 435 source-bound contributions.
The result records `visualParityOnly: false` and `isaAuditStatus: PASS`.
