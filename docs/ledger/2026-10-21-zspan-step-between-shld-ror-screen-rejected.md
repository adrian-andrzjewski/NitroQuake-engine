# Z-span second step between SHLD and ROR rejected (2026-10-21)

Status: rejected on the negative strict pooled mean. The previously promoted
second-step-before-store schedule remains active in `src/renderer/d_draw.s`.

The experiment moved the second Z-accumulator add/subtract between `SHLD` and
`ROR` in all four packed-pair macros. It retained the high-word preparation
and the original pixel packing; the i386 fallback order was unchanged.

The three-run parity screen used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and
the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
All runs completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS |
|---|---|---|---:|
| Fresh control | `out/dos-timedemo-20261021-163338` | 15.537284 / 15.537290 / 15.537282 | 15.537285333 |
| Interleaved screen | `out/dos-timedemo-20261021-164113` | 15.537288 / 15.537295 / 15.537288 | 15.537290333 |

The parity-only screen was positive by **+0.000005000 FPS**. The strict
candidate then averaged **15.537294333 FPS** across runs at 15.537290,
15.537300, and 15.537293 FPS. Against the latest strict control mean of
**15.537297000 FPS** from `out/dos-timedemo-20261021-155525`, the strict delta
was **−0.000002667 FPS (−0.00001717%)**. All strict runs retained exact frame
and checksum parity, but the negative strict mean rejects the schedule.

The full strict i486 gate passed: 313,315 linked instructions across 435 code
ranges, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The strict result is
`out/dos-timedemo-20261021-170815`; its executable SHA-256 is
`C805C74EC242B8D50C0BF899D90C1C4E4D642B8899D09F79ABB75E9E5F7C0938`.
The candidate source-tree fingerprint was
`76CC66D8CD489463E9A386778E2BA27AB718A9417A15582DEAF0FE94647363D1`.
