# `R_GenerateSpans` edge-index/base load interleave rejected (2026-10-29)

Status: rejected after a negative three-run strict timedemo; the original load order was restored.

The candidate moved `movl C(surfaces),%eax` between the two `movzwl et_surfs` loads at `Lgs_edgeloop` in `src/r_edgea.s`. The intent was to overlap the independent global-base load with the first edge-index load on the 486.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Mean FPS |
|---|---|---|---:|
| Strict control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 16.321723000 |
| Load-interleave candidate | `out/dos-timedemo-20261029-135432/timedemo-result.json` | 16.321729 / 16.321710 / 16.321720 | 16.321719667 |

The candidate was **−0.000003333 FPS (−0.00002042%)** below control. Every run completed 969 frames with framebuffer checksum `1047377823`. The complete executable i486 gate passed: 314,263 relocated instructions, 529 startup rows, and 9,207 provider instructions, with zero above-i486, unknown, or exempt instructions. The candidate was rejected and the original load order restored.

Candidate source-tree fingerprint: `374C3766D92F0AD34B8E6FEECA173CED336E697F490E9FF1204585DA1EC2998E`.

## Disposition

The current schedule remains:

```asm
movzwl  et_surfs(%ebx),%esi
movzwl  et_surfs+2(%ebx),%edi
movl    C(surfaces),%eax
```
