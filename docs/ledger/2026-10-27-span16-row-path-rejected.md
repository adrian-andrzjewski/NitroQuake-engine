# Span16 same-row specialized path rejected (2026-10-27)

Status: rejected after a three-run strict comparison. The existing
`TextureSpanRowPath=norowcross` selector remains opt-in; the default control
path is unchanged.

The candidate checked that a full 16-pixel segment's clamped T endpoints were
monotonic and remained in one texture row. Eligible segments then skipped the
per-pixel T-axis address update and advanced the source address from S only.
This path was already present in `src/d_draw16.s`; this run evaluated it without
changing the source tree.

The comparison used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Both
variants used the same source-tree fingerprint
`48A111E71E264F53C125BDEF525EBD0008F1C6608469E87EA68EF0C97DC5DCDA`. Every
run rendered 969 frames with framebuffer checksum `1047377823`; the candidate
passed the complete linked i486 ISA audit with zero above-i486, unknown, or
exempt instructions.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261026-214707/timedemo-result.json` | 16.107101 / 16.107111 / 16.107108 | 16.107106667 | 16.107108 |
| Same-row path | `out/dos-timedemo-20261026-232351/timedemo-result.json` | 16.016055 / 16.016063 / 16.016072 | 16.016063333 | 16.016063 |

The candidate was **0.091043334 FPS slower (−0.565237%)**. Exact parity and
the ISA gate passed, but the performance regression rejects the path for the
canonical i486 build.
