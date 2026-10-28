# Promote four-span unrolling in `R_ScanEdges` span clearing

The promoted two-span clear loop now clears four adjacent surface spans per
iteration. Its bounds checks avoid touching empty ranges, and a tail path clears
zero to three remaining surfaces. The strict three-run mean improved over the
two-span control, all candidate samples beat all control samples, framebuffer
checksums match, and the complete strict i486 audit passed.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 assembly selector profile, and uninstrumented timedemo
runs with per-frame FPS collection disabled. All six runs rendered 969 frames
with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Two-span unroll control | 15.601142, 15.601124, 15.601131 | 15.601132333 | 0.000018 |
| Four-span unroll candidate | 15.601242, 15.601219, 15.601233 | 15.601231333 | 0.000023 |

The candidate gains **0.000099 FPS (+0.00063457%)**. Every candidate sample
beats every control sample; the smallest candidate exceeds the largest control
by **0.000077 FPS**. This positive mean qualifies under the any-positive rule.

The complete strict i486 audit passed: 313,335 relocated instructions, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486
opcodes, unknown instructions, or exemptions. Exact checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-100819/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-104135/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edge-clear-loop-unroll4-20261022/`

Candidate fingerprints:

- Build source fingerprint: `2F59C5D52E6BF597EE76CD8F65733125591871B0A0B93BCC357B163C5D606524`
- Source-tree fingerprint: `EF717BFC430163601927565E95F3179A7A075CA7E04A5FAE9CC70AB7C719C8B2`
