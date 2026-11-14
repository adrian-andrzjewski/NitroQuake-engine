# Mip-2 light-delta reload prefetch rejected (2026-10-21)

Status: reverted after a negative strict three-run mean. The promoted mip-2
texel-load schedule remains active in `src/renderer/surf8.s`.

This candidate moved only the `lightdelta` reload from after the final
colormap lookup to between the last two lookups. The `lightright` reload kept
its existing position between those lookups. The original `lightdelta` reload
position has been restored.

Both strict variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the
uninstrumented runner, and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
strict run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Promoted texel-load control | `out/dos-timedemo-20261021-065729/timedemo-result.json` | 15.537297 / 15.537297 / 15.537306 | 15.537300000 | 0.000009 |
| Light-delta prefetch | `out/dos-timedemo-20261021-080330/timedemo-result.json` | 15.537298 / 15.537291 / 15.537287 | 15.537292000 | 0.000011 |

The pooled delta was **−0.000008 FPS (−0.00005149%)**. The candidate passed
the full strict i486 audit: 313,315 linked instructions across 435 executable
ranges, 529 startup code rows, and 9,207 provider instructions, with zero
above-target or unknown instructions and zero exemptions. Its negative mean
rejects this schedule under the positive-mean rule.

A preceding three-run parity-only screen included a **15.452168 FPS** outlier
between two samples near 15.5373 FPS. That screen skipped the ISA audit and is
not used for the promotion comparison; all three screen runs still matched the
expected frame count and checksum.
