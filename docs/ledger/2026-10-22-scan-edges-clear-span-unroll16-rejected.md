# Reject sixteen-span unrolling in `R_ScanEdges` span clearing

The sixteen-span clear loop passed exact framebuffer parity and the complete
strict i486 audit, but its three-run mean was negative against the promoted
eight-span loop. One sample ran much slower than the other two. Keep that sample
in the arithmetic mean: the acceptance rule promotes only a positive pooled
mean, with no magnitude floor and no outlier removal. The source is restored to
the eight-span loop.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 assembly selector profile, and uninstrumented timedemo
runs with per-frame FPS collection disabled. All six runs rendered 969 frames
with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Eight-span unroll control | 15.601256, 15.601256, 15.601281 | 15.601264333 | 0.000025 |
| Sixteen-span unroll candidate | 15.601283, 15.553785, 15.601291 | 15.585453 | 0.047506 |

The candidate loses **0.015811333 FPS (−0.10134649%)** on the arithmetic mean.
The slow sample was `15.553785 FPS` over `62.299951` seconds; the other two
samples were `15.601283` and `15.601291 FPS`. It still counts in the mean, so
the negative result rejects the change.

The complete strict i486 audit passed: 313,395 relocated instructions, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486
opcodes, unknown instructions, or exemptions. Exact checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-111408/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-114641/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edge-clear-span-unroll16-20261022/`

Candidate fingerprints:

- Build source fingerprint: `55838B508AD026A8D0D25E6F8FD55445DBFD08FB3F2FD321952942AAA7F824AE`
- Source-tree fingerprint: `51E6088115550F6CC556A827213886F276E89449947B888FC45AC0F7D0227445`
