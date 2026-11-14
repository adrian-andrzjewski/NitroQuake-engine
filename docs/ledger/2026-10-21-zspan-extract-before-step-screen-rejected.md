# Z-span extraction-before-step schedule rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted
accumulator-before-store schedule remains active in `src/renderer/d_draw.s`.

The experiment moved the independent high-word extraction (`shrl $16,%eax`)
before the first Z accumulator add/subtract in the normal and negative packed
pair macros. The packed pixel values and accumulator sequence were unchanged.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261021-065729/timedemo-result.json` | 15.537297 / 15.537297 / 15.537306 | 15.537300000 | 0.000009 |
| Extraction before step | `out/dos-timedemo-20261021-082853/timedemo-result.json` | 15.537276 / 15.537298 / 15.537297 | 15.537290333 | 0.000022 |

The screen delta was **−0.000009667 FPS (−0.00006223%)**. This was a
`VisualParityOnly` run, so its ISA audit was skipped. Exact output parity held,
but the negative pooled mean rejected the schedule; the original macro order
was restored.
