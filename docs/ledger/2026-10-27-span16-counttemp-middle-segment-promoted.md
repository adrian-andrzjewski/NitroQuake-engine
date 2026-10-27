# Span16 middle-segment count write elimination promoted (2026-10-27)

The full-segment path now compares `counttemp` in memory and leaves it
unchanged when more than 16 pixels remain. Only the short-tail path loads,
decrements, and stores the updated count. This removes the repeated count load
and writeback from full middle segments.

The strict uninstrumented run used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and
the pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Control and candidate both rendered 969 frames with framebuffer checksum
`1047377823` and passed the complete i486 ISA gate with zero exemptions.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261026-214707/timedemo-result.json` | 16.107101 / 16.107111 / 16.107108 | 16.107106667 | 16.107108 |
| Count-write elimination | `out/dos-timedemo-20261027-031103/timedemo-result.json` | 16.128723 / 16.128731 / 16.128710 | 16.128721333 | 16.128723 |

The candidate gained **0.021614667 FPS (+0.134193%)**. The strict linked audit
verified 314,335 relocated instructions, 529 startup rows, and 9,207 provider
instructions, with zero above-i486, unknown, or exempt instructions. The
candidate build and audit reports are in
`out/local-span16-counttemp-no-store-20261027/`.
