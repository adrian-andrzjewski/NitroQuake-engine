# Span16 `tfracf` load hoist rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; the original load position was restored.

The candidate moved `movl tfracf,%edx` in both Span16 setup arms to immediately after `%edx` had contributed the S-step to the address-table value. This put the independent load before the address-table store and cache-width add, increasing its distance from the later T-fraction add without changing arithmetic or instruction count.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Each run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Fresh parity control | `out/dos-timedemo-20261029-171107/timedemo-result.json` | 16.321760 / 16.321726 / 16.321705 | 0.000055 | 16.321730333 |
| `tfracf` load hoist parity screen | `out/dos-timedemo-20261029-171546/timedemo-result.json` | 16.321725 / 16.321716 / 16.321710 | 0.000015 | 16.321717000 |

The candidate was **0.000013333 FPS slower** (**−0.00008169%**). All runs retained exact frame and checksum parity; the full strict i486 audit was skipped after the negative mean.

## Disposition

The earlier load did not improve the matched mean. Both setup arms retain the original `tfracf` load after the cache-width addition.
