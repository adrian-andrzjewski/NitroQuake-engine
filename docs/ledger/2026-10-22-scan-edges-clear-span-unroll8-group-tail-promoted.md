# Promote grouped tail for eight-span `R_ScanEdges` clearing

The promoted eight-span clear loop now handles the remaining surfaces in
4-, 2-, and 1-span groups. Its matched strict three-run mean improved over
the sequential-tail control. The gain is below the observed run spread, but
the positive mean qualifies under the any-positive promotion rule. All runs
retained exact framebuffer checksum parity, and the complete strict i486 audit
passed.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 assembly selector profile, and uninstrumented timedemo
runs with per-frame FPS collection disabled. All six runs rendered 969 frames
with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Eight-span sequential-tail control | 15.601256, 15.601256, 15.601281 | 15.601264333 | 0.000025 |
| Eight-span grouped-tail candidate | 15.601253, 15.601282, 15.601279 | 15.601271333 | 0.000029 |

The candidate gains **0.000007 FPS (+0.00004487%)**. This positive mean
qualifies under the any-positive rule even though the gain is smaller than the
run spread; individual samples overlap.

The complete strict i486 audit passed: 313,346 relocated instructions, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486
opcodes, unknown instructions, or exemptions. The linked-object and final
executable checks also verified 313,346 instructions with no exceptions. Exact
checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-111408/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-121711/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edge-clear-span-unroll8-group-tail-20261022/`

Candidate fingerprints:

- Build source fingerprint: `05A8B41AE5051FC2292FCD71E3248D2F67E86114F3DAFCC5F7E90C77247D9224`
- Source-tree fingerprint: `7653BF32F585A742FAC3941A4D4363840DE9776367151D0BA1D447A9F02B3600`
