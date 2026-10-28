# Reject thirteen-span batch for `R_ScanEdges` clearing

The thirteen-span batch with grouped 8/4/2/1 tails rendered exactly, and its
complete strict i486 audit passed. Its three-run mean was slightly below the
active fourteen-span grouped-tail control. The any-positive rule therefore
rejects this variant; the fourteen-span loop remains in the source.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 assembly selector profile, and three uninstrumented
timedemo runs. Every run rendered 969 frames with framebuffer checksum
`1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Fourteen-span grouped-tail control | 15.601288, 15.601300, 15.601296 | 15.601294667 | 0.000012 |
| Thirteen-span grouped-tail candidate | 15.601293, 15.601305, 15.601285 | 15.601294333 | 0.000020 |

The candidate delta is **−0.000000333 FPS (−0.00000214%)**. The ranges
overlap and the delta is smaller than either spread; under the current rule the
negative mean is the deciding result.

The complete strict i486 audit passed: 313,363 relocated instructions, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486
opcodes, unknown instructions, or exemptions. The final executable audit
verified all 313,363 instructions across 2,376 code ranges and 35 data ranges.
All three timedemos retained exact checksum parity.

Artifacts:

- Control: `out/dos-timedemo-20261022-134214/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-144358/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edge-clear-span-unroll13-group-tail-20261022/`

Candidate fingerprints:

- Build source fingerprint: `AE114B7E3C4BC11A0AA6D27A8C31A19C73FC1CD95B408E7986071DE4DF287303`
- Source-tree fingerprint: `2DAD3ACB245E9883189A48BB01C437D914012C4F760AEEA65BF8DB68CD9F16A6`
- Executable SHA-256: `75FC32675ABE516FA685615BD9B4A18ECEB045CA0A969814F5B8E167BBFD5517`
