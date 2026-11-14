# Alias light dot product completes before the X partial (2026-10-25)

Status: promoted in `src/renderer/r_aliasa.s` after exact frame parity, a positive strict
mean, and the complete i486 ISA gate.

The alias vertex loop previously calculated the X transform partial between
the first and final additions of the normal-light dot product, then exchanged
the x87 stack to finish the dot product. It now completes the light dot product
first and calculates the independent X partial after the lighting branch. This
removes one `FXCH` per transformed alias vertex and leaves the same stack state
for the projection code at `Lp1`.

Both strict variants used DOSBox-X 2026.08.31, `demo1`, three uninstrumented
runs, CWSDPMI, and the pinned 32 MB i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261025-165547/timedemo-result.json` | 15.932178 / 15.932214 / 15.932215 | 15.932202333 | 15.932214 |
| Light dot product first | `out/dos-timedemo-20261025-172600/timedemo-result.json` | 15.934333 / 15.934332 / 15.934336 | 15.934333667 | 15.934333 |

The candidate mean increased by **0.002131333 FPS (0.0133775%)**. Its parity
screen also passed: `out/dos-timedemo-20261025-170128/timedemo-result.json`.

The complete strict i486 gate passed: 314,390 linked opcodes, 529 startup
code rows, and 9,207 DPMI-provider instructions; zero above-i486, unknown, or
exempt instructions. Final mapping covered 435 source-bound contributions.
The result records `visualParityOnly: false` and `isaAuditStatus: PASS`.
