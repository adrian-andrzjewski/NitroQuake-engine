# Promote eight-span unrolling in `R_ScanEdges` span clearing

The promoted four-span clear loop now clears eight adjacent surface spans per
iteration. Its bounds checks avoid touching empty ranges, and a tail path clears
zero to seven remaining surfaces. The strict three-run mean improved over the
four-span control, all candidate samples beat all control samples, framebuffer
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
| Four-span unroll control | 15.601242, 15.601219, 15.601233 | 15.601231333 | 0.000023 |
| Eight-span unroll candidate | 15.601256, 15.601256, 15.601281 | 15.601264333 | 0.000025 |

The candidate gains **0.000033 FPS (+0.00021152%)**. Every candidate sample
beats every control sample; the smallest candidate exceeds the largest control
by **0.000014 FPS**. This positive mean qualifies under the any-positive rule.

The complete strict i486 audit passed: 313,355 relocated instructions, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486
opcodes, unknown instructions, or exemptions. Exact checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-104135/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-111408/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edge-clear-loop-unroll8-20261022/`

Candidate fingerprints:

- Build source fingerprint: `6302D421B8B057F45ADE9CF8A0324E23C17F332F7982E5EBE265EC5B05A9F911`
- Source-tree fingerprint: `1E8B0A313171C465F6A960B283C304A87996127BBD3A435CD9471068D855FC0A`
