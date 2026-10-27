# Span16 short-tail memory decrement promoted (2026-10-27)

In the final-segment setup path, decrement `counttemp` directly in memory and
branch on the resulting zero flag. Load ECX only when more endpoint math is
needed. This removes the register decrement and writeback sequence from the
one-pixel short-tail case.

The strict uninstrumented comparison used DOSBox-X 2026.08.31, `demo1`,
CWSDPMI, and the pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Control and candidate both rendered 969 frames with framebuffer checksum
`1047377823` and passed the complete i486 ISA gate with zero exemptions.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261027-031103/timedemo-result.json` | 16.128723 / 16.128731 / 16.128710 | 16.128721333 | 16.128723 |
| Memory decrement | `out/dos-timedemo-20261027-034245/timedemo-result.json` | 16.134742 / 16.134768 / 16.134757 | 16.134755667 | 16.134757 |

The candidate gained **0.006034333 FPS (+0.037414%)**. The strict linked audit
verified 314,320 relocated instructions, 529 startup rows, and 9,207 provider
instructions, with zero above-i486, unknown, or exempt instructions. The
candidate build and audit reports are in
`out/local-span16-shorttail-memory-decrement-20261027/`.
