# Promote two-span unrolling in `R_ScanEdges` span clearing

The promoted bottom-tested clear loop now clears two adjacent surface spans
per iteration. Its bounds checks keep empty ranges empty, clear a final single
surface through a tail path, and only enter the pair loop when a complete pair
fits. The strict three-run mean improved over the bottom-tested one-span
control, all candidate samples beat all control samples, framebuffer checksums
match, and the complete strict i486 audit passed.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 assembly selector profile, and uninstrumented timedemo
runs with per-frame FPS collection disabled. All six runs rendered 969 frames
with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Bottom-tested one-span control | 15.601024, 15.601039, 15.601029 | 15.601030667 | 0.000015 |
| Two-span unroll candidate | 15.601142, 15.601124, 15.601131 | 15.601132333 | 0.000018 |

The candidate gains **0.000101667 FPS (+0.00065167%)**. Every candidate sample
beats every control sample; the smallest candidate exceeds the largest control
by **0.000085 FPS**. The positive mean qualifies under the any-positive rule,
regardless of the small magnitude.

The complete strict i486 audit passed: 313,326 relocated instructions, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486
opcodes, unknown instructions, or exemptions. Exact checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-093238/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-100819/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edge-clear-loop-unroll2-20261022/`

Candidate fingerprints:

- Build source fingerprint: `8208F2316BFF8642654F669AA74A5BABE94AE49CAE64175A0A3CE1DDF58913A8`
- Source-tree fingerprint: `FDBD13EAE4B1BD32AEDE0489BBC7836F4A0D7FE1BA0012C481DE414F933CF100`
