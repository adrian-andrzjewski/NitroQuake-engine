# Edge-scan surface-index decode promoted (2026-10-21)

Status: promoted in `src/renderer/r_edgea.s` under the any-positive pooled mean rule.

`R_GenerateSpans` now loads `edge->surfs[0]` and `edge->surfs[1]` as separate
unsigned halfwords. This replaces the packed dword load, register copy, and two
masks on every edge. The high surface index is shifted left into its byte
offset at `Lgs_leading`; the low surface follows the existing pointer setup.
The loop's exact output parity passed.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active control, parity screen | `out/dos-timedemo-20261021-180313` | 15.538381 / 15.538376 / 15.538391 | 15.538382667 | 0.000015 |
| Surface-index decode, parity screen | `out/dos-timedemo-20261021-183556` | 15.564263 / 15.564252 / 15.564256 | 15.564257000 | 0.000011 |
| Active control, strict | `out/dos-timedemo-20261021-182741` | 15.538392 / 15.538370 / 15.538390 | 15.538384000 | 0.000022 |
| Surface-index decode, strict | `out/dos-timedemo-20261021-190017` | 15.564265 / 15.564241 / 15.564256 | 15.564254000 | 0.000024 |

The strict pooled mean is **+0.025870 FPS (+0.16649093%)** over the active
control. Every run completed 969 frames with framebuffer checksum
`1047377823`.

The complete strict i486 gate passed: 313,314 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 provider instructions, with
zero above-i486, unknown, or exempt instructions. The strict candidate
executable SHA-256 is
`E5257DC170E251DDB860CF2797A19684913875DFD3A7C19A29272C3D3D0FFBA6` and its
source-tree fingerprint is
`8D42B70B9DC15CC2E1634D5A72D3511B543FF543661C07667E7254FC58E26175`.

## Current-source recheck (2026-10-26)

The current working candidate also forms the leading-surface pointer before
`TrailingEdge`, then enters a shared leading-edge body. This recheck measured
that pointer hoist together with the 16-bit surface-index decode against the
nested HEAD control on the current source snapshot; it does not attribute the
two changes separately.

Both parity screens used the pinned profile above and completed 969 frames
with checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Current HEAD control | `out/dos-timedemo-20261026-010759` | 15.915530 / 15.915499 / 15.915482 | 15.915503667 | 0.000048 |
| Surface-index candidate | `out/dos-timedemo-20261026-011226` | 15.942843 / 15.942863 / 15.942849 | 15.942851667 | 0.000020 |

The matched mean improved by **+0.027348000 FPS (+0.17183245%)**. The candidate
screen and the existing strict candidate artifact
`out/dos-timedemo-20261026-005503` share source-tree fingerprint
`4083E4EB3B822EE8B1CB9963B728E839068CDC8C7B315C11F42D67B27A4D8595`. That
strict run passed the full i486 ISA audit and the same 969-frame checksum gate.
