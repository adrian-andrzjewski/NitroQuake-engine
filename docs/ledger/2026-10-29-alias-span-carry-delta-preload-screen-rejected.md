# Alias span carry-delta preload rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; the original indexed-memory ADC was restored.

The candidate loaded the carry-selected `advancetable` delta into `%eax` before the independent S-fraction add, then used a register `ADC` for the source-pointer update. This moved the table read out of the carry-dependent memory-operand instruction while preserving the S-add/ADC carry chain.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Carry-delta preload parity screen | `out/dos-timedemo-20261029-155026/timedemo-result.json` | 16.299054 / 16.299069 / 16.299040 | 0.000029 | 16.299054333 |

The candidate was **0.022668667 FPS slower** (**−0.1389%**). Every run completed 969 frames with framebuffer checksum `1047377823`. The runner used `VisualParityOnly`; the strict i486 audit was skipped after the negative mean.

## Disposition

The extra load and register ADC did not hide enough table-read latency to offset the added work in DOSBox-X. The candidate was reverted; the original indexed-memory ADC remains active.
