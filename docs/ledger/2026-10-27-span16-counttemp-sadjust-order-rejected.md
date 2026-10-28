# Span16 count subtraction after S-adjust load rejected (2026-10-27)

The candidate moved `subl $16,counttemp` from before the `sadjust` load to
immediately after `movl C(sadjust),%ebp` in `LNotLastSegment`. The strict
uninstrumented comparison used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

Both variants rendered 969 frames with framebuffer checksum `1047377823` on
every run, and both passed the complete strict i486 ISA audit.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261027-044245/timedemo-result.json` | 16.156418 / 16.156441 / 16.156448 | 16.156435667 | 16.156441 |
| Count subtraction after S-adjust | `out/dos-timedemo-20261027-050947/timedemo-result.json` | 16.156414 / 16.156434 / 16.156450 | 16.156432667 | 16.156434 |

The candidate regressed by **0.000003 FPS (-0.00001857%)**. The full audit
verified 314,318 relocated instructions across 435 executable ranges, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486,
unknown, or exempt instructions. The candidate build and audit reports are in
`out/local-dos-timedemo-20261027-span16-count-sub-schedule/`. Its source
fingerprint is
`C35C8AA00BE46156E00AEEB43744029461E611DB7A6AD2BEBE929ACE93F56D13`; the
executable SHA-256 is
`598A79BF5D06D72DC2E5556C98E3B1E128F7126B7E287EDA5A85C033036FA2F8`.

The original instruction order was restored. This rejected experiment remains
uncommitted.
