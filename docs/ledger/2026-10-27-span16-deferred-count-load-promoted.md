# Span16 deferred count load promoted (2026-10-27)

After each full 16-pixel block, compare `counttemp` directly with 16 and branch
to the next full segment when more pixels remain. Load ECX only on the
final-segment path. The repeated path replaces ECX with `C(tadjust)` before
using it, so retrieving the remaining count there is unnecessary.

The strict uninstrumented comparison used DOSBox-X 2026.08.31, `demo1`,
CWSDPMI, and the pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Control and candidate both rendered 969 frames with framebuffer checksum
`1047377823` on every run.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261027-041306/timedemo-result.json` | 16.145639 / 16.145599 / 16.145616 | 16.145618000 | 16.145616 |
| Deferred count load | `out/dos-timedemo-20261027-044245/timedemo-result.json` | 16.156418 / 16.156441 / 16.156448 | 16.156435667 | 16.156441 |

The candidate gained **0.010817667 FPS (+0.067001%)**. The complete strict
i486 audit verified 314,318 relocated instructions across 435 executable
ranges, 529 startup rows, and 9,207 DPMI-provider instructions, with zero
above-i486, unknown, or exempt instructions. The candidate build and audit
reports are in
`out/local-dos-timedemo-20261027-span16-deferred-count-load/`. The source
fingerprint is
`0D1446E8408D10C3AB2A3D8FC3BDCAAAF63E3356747858B915823FE947B59BBB`; the
executable SHA-256 is
`D3236FB998D5DE2D5EBB46670636B622A94E50C39B16D54EDE257606EE34EABB`.
