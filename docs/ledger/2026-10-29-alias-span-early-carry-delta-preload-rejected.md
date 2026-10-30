# Alias-span early carry-delta preload rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; the temporary schedule and selector were removed.

This tested a distinct, earlier placement than the existing carry-delta preload. Immediately after `sbbl %eax,%eax` formed the T-carry mask, the candidate loaded the selected `advancetable` delta into `%eax`. The Z accumulator update and S-fraction add then ran before a register `ADC` advanced the texture pointer. The intent was to hide the table read under independent integer work on a 486 pipeline.

## Matched 320x200 timedemo

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Each run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Fresh parity control | `out/dos-timedemo-20261029-160319/timedemo-result.json` | 16.321712 / 16.321705 / 16.321726 | 0.000021 | 16.321714333 |
| Early carry-delta preload parity screen | `out/dos-timedemo-20261029-165456/timedemo-result.json` | 16.299061 / 16.299069 / 16.299061 | 0.000008 | 16.299063667 |

The candidate was **0.022650666 FPS slower** (**−0.138776%**). The full strict i486 audit was skipped after the negative mean; the parity build's provider ISA proof covered 9,207 instructions with zero exemptions. The strict promoted control from `out/dos-timedemo-20261029-115044/timedemo-result.json` averaged 16.321723 FPS, also faster than this candidate.

## Disposition

The earlier table read did not improve the matched mean. The temporary prefetch macro, its 16 call sites, selector mapping, and runner options were reverted. The indexed-memory `ADC` remains active.
