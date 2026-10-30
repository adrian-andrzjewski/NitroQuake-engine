# Span16 power-of-two cache-width multiply rejected (2026-10-29)

Status: rejected after a repeated negative 320x200 parity screen. The candidate
code and selector were removed; `TextureSpanAddressing=control` remains the
active path.

The candidate checked `cachewidth` once per `D_DrawSpans16` call, cached its
shift count with `BSR` for power-of-two widths, and replaced the initial and
full-segment `tstep * cachewidth` multiplies with `SHL CL`. Non-power-of-two
widths retained the original `IMUL` fallback. The source assembled and linked
in the i486 visual-parity build; the full renderer ISA audit was skipped after
the negative screen.

## Matched 320x200 screens

All runs used DOSBox-X 2026.08.31, the pinned i486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
CWSDPMI, the verified `testdata/id1` root, `demo1`, and the same source-tree
fingerprint `92EF8BA2320E12E402861FDEDD1F213E86154F0AB5DB41CA86BB422578F61BBD`.
These were `VisualParityOnly` runs, so the renderer ISA audit was skipped.
Every run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS | Seconds |
|---|---|---:|---:|
| `pow2mul` screen 1 | `out/dos-timedemo-20261029-174203/timedemo-result.json` | 16.209384 | 59.780184 |
| Fresh control | `out/dos-timedemo-20261029-174450/timedemo-result.json` | 16.321706 | 59.368792 |
| `pow2mul` screen 2 | `out/dos-timedemo-20261029-174608/timedemo-result.json` | 16.209386 | 59.780179 |

The two candidate samples averaged **16.209385 FPS**, **0.112321 FPS
(0.688169%) slower** than the fresh control sample. Their spread was only
0.000002 FPS, confirming the loss on a repeat. The candidate passed checksum
parity but was rejected before a strict timedemo and full ISA audit.

## Disposition

The variable-shift path's extra test, branch, and register preservation cost
more than the removed multiply in this workload. The original `IMUL` setup
remains in `src/d_draw16.s`; the temporary selector plumbing was removed.
