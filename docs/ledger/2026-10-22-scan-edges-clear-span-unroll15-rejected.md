# Reject fifteen-span batch for `R_ScanEdges` clearing

The fifteen-span clear loop used the same grouped 8-, 4-, 2-, and 1-span tail
as the promoted fourteen-span implementation. It passed exact framebuffer
checksum parity and the complete strict i486 audit, but its matched strict
three-run mean was lower than the fourteen-span control. The negative mean
rejects the candidate; fourteen-span batching remains active.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 assembly selector profile, and uninstrumented timedemo
runs with per-frame FPS collection disabled. All six runs rendered 969 frames
with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Fourteen-span grouped-tail control | 15.601288, 15.601300, 15.601296 | 15.601294667 | 0.000012 |
| Fifteen-span grouped-tail candidate | 15.601309, 15.601281, 15.601291 | 15.601293667 | 0.000028 |

The candidate loses **0.000001 FPS (−0.00000641%)**. The sample ranges
overlap; the candidate's positive highest sample does not change the negative
pooled mean.

The complete strict i486 audit passed: 313,365 relocated instructions, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486
opcodes, unknown instructions, or exemptions. The linked-object and final
executable checks verified all 313,365 instructions with no data or relocation
exceptions. Exact checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-134214/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-141239/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edge-clear-span-unroll15-group-tail-20261022/`

Candidate fingerprints:

- Build source fingerprint: `2A89D80A3BB7175B63567E47914E86979770D6AF0B2B6B1EB716FE2F223CCD28`
- Source-tree fingerprint: `2141D5F5588855EC0D313B18B6D08320597978AF7A93347A8CCA6E9DB8B799AC`
