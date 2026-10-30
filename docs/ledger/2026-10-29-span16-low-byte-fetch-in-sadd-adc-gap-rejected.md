# Span16 low-byte fetch in S-add/ADC gap rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; the original fetch order was restored.

The candidate moved each low-byte texture fetch (`movb (%esi),%al`) from before the T-fraction update into the gap between the S-fraction add and indexed ADC in the default word-store path of `D_DrawSpans16`. The byte load does not modify flags, so the carry into the ADC and the sampled address were preserved. The experiment tested whether that load could occupy otherwise unused integer-pipeline time.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Low-byte fetch parity screen | `out/dos-timedemo-20261029-143506/timedemo-result.json` | 16.321724 / 16.321697 / 16.321705 | 0.000027 | 16.321708667 |

The candidate was **0.000014333 FPS slower** (**−0.0000878%**). Every run completed 969 frames with framebuffer checksum `1047377823`. The runner used `VisualParityOnly`; the strict ISA audit was skipped because the candidate mean was negative.

## Disposition

The candidate load schedule was removed. The original low-byte fetch position remains active; no strict recheck or ISA audit was run after the negative parity screen.
