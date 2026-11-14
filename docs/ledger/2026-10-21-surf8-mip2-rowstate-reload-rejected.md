# Mip-2 row-state reload schedule rejected (2026-10-21)

Status: reverted after a negative strict three-run mean. The earlier mip-2
texel-load schedule remains promoted in `src/renderer/surf8.s`.

This candidate moved the `lightright` and `lightdelta` row-state reloads ahead
of the final two colormap reads in the general mip-2 surface-block loop. The
intent was to overlap the reloads with the lookup latency after preparing both
sample indices. The original reload order has been restored.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the uninstrumented
runner, and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Promoted texel-load control | `out/dos-timedemo-20261021-065729/timedemo-result.json` | 15.537297 / 15.537297 / 15.537306 | 15.537300000 | 0.000009 |
| Row-state reload schedule | `out/dos-timedemo-20261021-072910/timedemo-result.json` | 15.537291 / 15.537288 / 15.537293 | 15.537290667 | 0.000005 |

The pooled delta was **−0.000009333 FPS (−0.00006007%)**. The candidate passed
the full strict i486 audit: 313,315 linked instructions, zero opcode
mismatches, and zero above-target or unknown instructions. All six timedemos
passed exact frame/checksum parity. Its negative mean rejects this schedule
under the positive-mean rule.
