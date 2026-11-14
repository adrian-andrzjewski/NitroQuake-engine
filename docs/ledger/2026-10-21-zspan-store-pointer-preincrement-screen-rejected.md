# Z-span destination-pointer preincrement screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted
accumulator-before-store schedule and original store-address order remain active
in `src/renderer/d_draw.s`.

The experiment advanced `%edi` by four bytes immediately before each packed
word store and addressed the same destination with `-4(%edi)`. It covered the
normal and negative add/subtract pair macros.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261021-065729/timedemo-result.json` | 15.537297 / 15.537297 / 15.537306 | 15.537300000 | 0.000009 |
| Pointer preincrement | `out/dos-timedemo-20261021-083555/timedemo-result.json` | 15.537293 / 15.537297 / 15.537289 | 15.537293000 | 0.000008 |

The screen delta was **−0.000007 FPS (−0.00004505%)**. This was a
`VisualParityOnly` run, so its ISA audit was skipped. Exact output parity held,
but the negative pooled mean rejected the schedule; the original store and
pointer order was restored.
