# Z-span row-index load interleave promoted (2026-10-29)

## Strict 320x200 timing

In both `LFSpanLoop` and `LFNegSpanLoop` in [`src/renderer/d_draw.s`](../../src/renderer/d_draw.s),
the independent `movl espan_t_v(%ebp),%ecx` row-table index load moved between
the two coordinate `FILD` instructions. The x87 arithmetic order and stack
contents are unchanged. The selected renderer profile kept
`TextureSpanAddressing=control`; this change does not enable the rejected
Span16 branch-address experiment.

Both variants used DOSBox-X 2026.08.31, `demo1`, the aggressive i486 selector
profile, and the same pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA` at
320x200.

| Variant | Artifact | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261029-195024/timedemo-result.json` | 16.321729 / 16.321696 / 16.321709 | 0.000033 | 16.321711333 |
| Z-span row-load interleave | `out/dos-timedemo-20261029-202759/timedemo-result.json` | 16.321725 / 16.321708 / 16.321710 | 0.000017 | 16.321714333 |

The matched strict mean improved by **0.000003 FPS (+0.00001838%)**. All six
runs rendered 969 frames with checksum `1047377823`.

## Correctness, audit, and disposition

The candidate passed the complete linked i486 ISA audit: 314,318 relocated
instructions, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The two-run `demo1-vga-full`
320x200 visual validation passed at
`out/render-validation-20261029-204039/render-validation-result.json`. Both
captures matched the golden comparison at 12 of 64,000 pixels changed and mean
absolute channel error 0.0009375. Their full 970-entry frame-checksum streams
both match the control replay at
`out/dos-timedemo-20261029-193237/` with zero differing entries. The captured
frame shows no horizontal-line artifacts.

Promote the row-index load interleave under the recorded policy of accepting
any positive matched strict three-run mean. The separately rejected
Span16 branch-address path remains disabled.
