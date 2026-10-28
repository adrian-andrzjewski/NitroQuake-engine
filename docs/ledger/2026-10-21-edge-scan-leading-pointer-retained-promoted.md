# Edge-scan leading-pointer retention promoted (2026-10-21)

Status: promoted in `src/r_edgea.s` under the any-positive pooled mean rule.

On edges with both surfaces present, `R_GenerateSpans` now forms the leading
surface pointer in `%edi` before calling `TrailingEdge`. The helper preserves
`%edi`, so the pointer remains valid after return. The path replaces the
post-call reload of the global `surfaces` base with a jump to the shared
leading-edge body. Leading-only edges still convert their index at
`Lgs_leading`. The timedemo retained exact output parity.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active control, parity screen | `out/dos-timedemo-20261021-183556` | 15.564263 / 15.564252 / 15.564256 | 15.564257000 | 0.000011 |
| Leading-pointer retention, parity screen | `out/dos-timedemo-20261021-191132` | 15.564267 / 15.564265 / 15.564244 | 15.564258667 | 0.000023 |
| Active control, strict | `out/dos-timedemo-20261021-190017` | 15.564265 / 15.564241 / 15.564256 | 15.564254000 | 0.000024 |
| Leading-pointer retention, strict | `out/dos-timedemo-20261021-193519` | 15.564265 / 15.564246 / 15.564259 | 15.564256667 | 0.000019 |

The strict pooled mean is **+0.000002667 FPS (+0.0000171354%)** over the
active control. This delta is smaller than the run spread, but it is positive
and qualifies under the user's rule. Every run completed 969 frames with
framebuffer checksum `1047377823`.

The complete strict i486 gate passed: 313,315 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 provider instructions, with
zero above-i486, unknown, or exempt instructions. The strict candidate
executable SHA-256 is
`FCD879180B3DD5591C4D2DC8BE8A6DABC5F76C015404689D03D54F03AC825467` and its
source-tree fingerprint is
`FFF056D9D12FDDC75BE3F181A5C4AA027B582C5C890014CDE009D94755A8ED3E`.
