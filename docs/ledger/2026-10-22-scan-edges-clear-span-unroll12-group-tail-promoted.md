# Promote twelve-span batch for `R_ScanEdges` clearing

The scan-edge clear loop now clears twelve adjacent surfaces per iteration,
then handles a remainder with grouped 8-, 4-, 2-, and 1-span tails. Its matched
strict three-run mean improved over the eight-span grouped-tail control. The
gain is smaller than the run spread, but its positive mean qualifies under the
any-positive promotion rule. All runs retained exact framebuffer checksum
parity, and the complete strict i486 audit passed.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 assembly selector profile, and uninstrumented timedemo
runs with per-frame FPS collection disabled. All six runs rendered 969 frames
with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Eight-span grouped-tail control | 15.601253, 15.601282, 15.601279 | 15.601271333 | 0.000029 |
| Twelve-span grouped-tail candidate | 15.601291, 15.601270, 15.601278 | 15.601279667 | 0.000021 |

The candidate gains **0.000008333 FPS (+0.00005341%)**. This positive mean
qualifies under the any-positive rule even though the gain is smaller than the
run spread; individual samples overlap.

The complete strict i486 audit passed: 313,361 relocated instructions, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486
opcodes, unknown instructions, or exemptions. The linked-object and final
executable checks verified all 313,361 instructions with no data or relocation
exceptions. Exact checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-121711/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-130652/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edge-clear-span-unroll12-group-tail-20261022/`

Candidate fingerprints:

- Build source fingerprint: `01C0473299A1F09192179889CE33A54757F33F1EDC1792C5D1AA10503168F783`
- Source-tree fingerprint: `0529665DFBF519A48F014822573BFC10EECBDAC6BC3F6331C71478775AD8BE0B`
