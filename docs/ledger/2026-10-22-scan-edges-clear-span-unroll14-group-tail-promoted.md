# Promote fourteen-span batch for `R_ScanEdges` clearing

The scan-edge clear loop now clears fourteen adjacent surfaces per iteration,
then handles the remainder with grouped 8-, 4-, 2-, and 1-span tails. Its
matched strict three-run mean improved over the twelve-span grouped-tail
control. The means overlap at the sample level, but the candidate mean is
positive under the any-positive promotion rule. All runs retained exact
framebuffer checksum parity, and the complete strict i486 audit passed.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 assembly selector profile, and uninstrumented timedemo
runs with per-frame FPS collection disabled. All six runs rendered 969 frames
with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Twelve-span grouped-tail control | 15.601291, 15.601270, 15.601278 | 15.601279667 | 0.000021 |
| Fourteen-span grouped-tail candidate | 15.601288, 15.601300, 15.601296 | 15.601294667 | 0.000012 |

The candidate gains **0.000015 FPS (+0.00009615%)**. Its positive mean
qualifies under the any-positive rule; the gain is smaller than the control's
run spread, and the sample ranges overlap.

The complete strict i486 audit passed: 313,376 relocated instructions, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486
opcodes, unknown instructions, or exemptions. The linked-object and final
executable checks verified all 313,376 instructions with no data or relocation
exceptions. Exact checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-130652/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-134214/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edge-clear-span-unroll14-group-tail-20261022/`

Candidate fingerprints:

- Build source fingerprint: `EBBBFB5F55A670D5EE27C2F4E47DBCAD5BBD6ADBF8738530168AFBC78773D05C`
- Source-tree fingerprint: `BD256CF8A1FEC887D2370BCA6D1AA4B5CC5BC58550ACD600925CC26B708FB26C`
