# Alias-span Z-store before texel load rejected (2026-10-29)

Status: rejected after a neutral-to-negative three-run 320x200 parity screen; the original Z-store schedule was restored.

In `D_PolysetDrawSpans8`, the candidate moved the passing pixel's Z-buffer store ahead of the independent texture fetch in each pixel block of both unrolled eight-pixel groups. The depth comparison still controls whether depth and color are written, and the palette lookup and framebuffer store remain in their original order. The experiment tested whether the 486 could overlap the Z write with texture and colormap memory access.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Z-store-first parity screen | `out/dos-timedemo-20261029-151033/timedemo-result.json` | 16.321716 / 16.321726 / 16.321718 | 0.000010 | 16.321720000 |

The candidate mean was **0.000003 FPS slower (−0.00001838%)**. Every run completed 969 frames with framebuffer checksum `1047377823`. The runner used `VisualParityOnly`; the strict ISA audit was skipped because the mean was negative.

## Disposition

No source change was retained. Z-buffer writes remain after the texture load in the unrolled color-pass path.
