# Alias span texel load before Z comparison screen rejected (2026-10-26)

Moved the current texture-byte load before the Z-buffer comparison in the
sixteen unrolled sites of `D_PolysetDrawSpans8`, leaving the comparison and
conditional color/Z stores unchanged. All runs preserved exact output, but the
three-run parity screen was slower, so the source order was restored.

The runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive selector
set, and the pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | FPS samples | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Current strict control | `out/dos-timedemo-20261026-044845` | 15.942841 / 15.942874 / 15.942874 | 15.942863000 | 0.000033 |
| Candidate parity screen | `out/dos-timedemo-20261026-060527` | 15.937802 / 15.937821 / 15.937816 | 15.937813000 | 0.000019 |

The screen mean was **−0.005050 FPS (−0.03167562%)** against control. All
candidate runs rendered 969 frames with framebuffer checksum `1047377823`.
The parity-only screen skipped the strict i486 audit; its negative mean rejects
the candidate before strict validation. No promotion commit was made.
