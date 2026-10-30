# Span16 no-row-cross path current-source recheck rejected (2026-10-29)

Status: rejected after a matched three-run 320x200 recheck against the current
renderer measured a repeatable slowdown. `TextureSpanRowPath=control` remains
the default.

The opt-in `norowcross` path adds a same-texture-row test for full 16-pixel
segments and uses an S-only texture-address update when the clamped T endpoints
stay in that row. It falls back to the control DDA for row crossings and
negative T movement. The path had lost on a September build; this recheck tests
it against the current source and the active twelve-way edge-sort control.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, `-stdvid`, the
aggressive i486 selector profile, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Measurements used `VisualParityOnly`; both sets completed 969 frames per run
and every run ended with framebuffer checksum `1047377823`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261029-220104/timedemo-result.json` | 16.329109 / 16.329121 / 16.329118 | 0.000012 | 16.329116 |
| `norowcross` | `out/dos-timedemo-20261029-220529/timedemo-result.json` | 16.233641 / 16.233652 / 16.233644 | 0.000011 | 16.233645667 |

The candidate lost **0.095470333 FPS (-0.584663%)**. The slowdown is far larger
than either run set's spread and repeats the direction and approximate size of
the September result (-0.580537%). No strict ISA audit or per-frame stream
comparison was run after the negative timing result; only final-frame checksum
parity was enforced. The candidate remains opt-in and is not used by the
default renderer.

Both runs used source-tree fingerprint
`32CE86078CC63ED86A8E24ADD52B9FD51D4743AC937EBB5EA2D8B9516187D228`; the
control/candidate source fingerprints were
`1317F4FE11F2459AE4C487607CB8F63E483475C0ADB15F09042EC4F9F5DA2206` /
`10CF74704C7C0EDD762073D063460043B945261B2DB7397DA7C0B82500D1AB6A`.
