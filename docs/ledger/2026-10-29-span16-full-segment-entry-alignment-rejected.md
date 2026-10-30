# Span16 full-segment entry alignment rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; the alignment directive was removed.

The candidate added `.p2align 4,,15` before `LNotLastSegment` in `D_DrawSpans16`, placing the repeated full-segment path on a 16-byte boundary to test the 486 instruction-fetch path. It changed code placement only; pixel arithmetic and store order were unchanged.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Each run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Fresh parity control | `out/dos-timedemo-20261029-160319/timedemo-result.json` | 16.321712 / 16.321705 / 16.321726 | 0.000021 | 16.321714333 |
| 16-byte aligned `LNotLastSegment` parity screen | `out/dos-timedemo-20261029-170126/timedemo-result.json` | 16.310036 / 16.145969 / 16.310008 | 0.164067 | 16.255337667 |

The candidate was **0.066376666 FPS slower** (**−0.406677%**). The slow sample is retained in the pooled mean. All runs kept exact frame and framebuffer parity; the full strict i486 audit was skipped after the negative mean.

## Disposition

The alignment did not improve the matched mean. The directive was removed, restoring the prior `LNotLastSegment` placement.
