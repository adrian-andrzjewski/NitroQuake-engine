# Span16 unrolled byte stores rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; packed word stores remain active.

The `TextureSpanStores=byte` selector used the existing unrolled byte-store path in `D_DrawSpans16`. It removed the paired `%al`/`%ah` word packing and one word store per pixel pair, but wrote each destination pixel separately. This tested whether byte stores avoided costs from unaligned word writes on 486-class hardware.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict word-store control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| `TextureSpanStores=byte` parity screen | `out/dos-timedemo-20261029-145000/timedemo-result.json` | 16.203569 / 16.203597 / 16.203572 | 0.000028 | 16.203579333 |

The byte-store variant was **0.118143667 FPS slower (−0.7238%)**. Every run completed 969 frames with framebuffer checksum `1047377823`. The runner used `VisualParityOnly`; the strict ISA audit was skipped because the candidate mean was negative.

## Disposition

No source change was made. `TextureSpanStores=word` remains the default; no strict recheck or ISA audit was run after the negative parity screen.
