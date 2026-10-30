# Span16 `loadfirst` recheck against the FILD-window control rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; `TextureSpanLoadOrder=control` remains the default.

This recheck compared the existing `loadfirst` schedule with the newly promoted Span16 FILD-window setup. It verifies whether the earlier load-order result changes when measured against the current integer-load schedule.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict FILD-window control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| `loadfirst` parity screen | `out/dos-timedemo-20261029-151814/timedemo-result.json` | 16.321719 / 16.321715 / 16.321716 | 0.000004 | 16.321716667 |

The `loadfirst` mean was **0.000006333 FPS slower** (**−0.0000388%**). All six runs completed 969 frames with framebuffer checksum `1047377823`. The candidate used `VisualParityOnly`, so the strict i486 ISA audit was skipped after its negative mean.

## Disposition

No candidate source change remains. Keep `TextureSpanLoadOrder=control` as the default; `loadfirst` remains opt-in and did not improve the current FILD-window schedule.
