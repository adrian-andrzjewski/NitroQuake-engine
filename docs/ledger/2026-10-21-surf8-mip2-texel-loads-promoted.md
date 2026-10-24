# Mip-2 surface texel-load schedule promoted (2026-10-21)

Status: promoted in `src/surf8.s` under the positive-mean rule.

The general mip-2 surface-block loop now loads source texels at offsets 2 and 3
before saving and scaling the light delta. This starts the independent texture
reads earlier, with the same instructions, outputs, and branch structure.

The matched runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the uninstrumented
runner, and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Promoted-source control | `out/dos-timedemo-20261021-043143/timedemo-result.json` | 15.537299 / 15.537291 / 15.537288 | 15.537292667 | 0.000011 |
| Mip-2 texel-load schedule | `out/dos-timedemo-20261021-065729/timedemo-result.json` | 15.537297 / 15.537297 / 15.537306 | 15.537300000 | 0.000009 |

The pooled delta was **+0.000007333 FPS (+0.00004720%)**. The gain is smaller
than the run spread, but the positive mean qualifies under the user's no-floor
rule. All six timedemos passed exact frame/checksum parity. The candidate passed
the complete strict i486 audit: 313,315 linked instructions across 435
executable ranges, 529 startup code rows, and 9,207 provider instructions, with
zero above-i486 instructions, unknown instructions, or exemptions.
