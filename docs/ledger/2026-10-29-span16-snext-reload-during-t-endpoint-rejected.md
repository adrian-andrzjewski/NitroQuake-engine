# Span16 `snext` reload during T-endpoint math rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; the reload was restored after both endpoint FISTPs.

The candidate moved `movl snext,%eax` immediately after `fistpl snext`, allowing the T-endpoint multiply/FISTP to follow while the integer reload was independent. It left the x87 operations, memory destinations, and T-endpoint reload order unchanged.

## Matched 320x200 timedemo

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, 969 frames, and framebuffer checksum `1047377823`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict promoted control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Fresh control recheck | `out/dos-timedemo-20261029-160319/timedemo-result.json` | 16.321712 / 16.321705 / 16.321726 | 0.000021 | 16.321714333 |
| Split-reload parity screen | `out/dos-timedemo-20261029-163246/timedemo-result.json` | 16.321708 / 16.321717 / 16.321704 | 0.000013 | 16.321709667 |

The candidate was **0.000004667 FPS slower** (**−0.00002859%**) than the fresh control recheck and **0.000013333 FPS slower** than the original strict control. All runs retained exact frame and checksum parity. The strict i486 audit was skipped after the negative mean.

## Disposition

The candidate did not improve the matched mean. The `snext` reload remains after both endpoint FISTPs.
