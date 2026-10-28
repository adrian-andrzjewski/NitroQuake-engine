# Reject 16-byte alignment of the full Span16 segment loop (2026-10-26)

The candidate placed `.p2align 4,,15` immediately before `LNotLastSegment`,
the full 16-pixel segment path in `D_DrawSpans16`. This changed code layout
only; it did not alter instructions or pixel arithmetic.

The source and three-run screen used DOSBox-X 2026.08.31, `demo1`, CWSDPMI,
and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | FPS samples | Mean FPS |
|---|---|---|---:|
| Strict control | `out/dos-timedemo-20261026-150012` | 15.948144 / 15.948137 / 15.948150 | 15.948143667 |
| Aligned-loop screen | `out/dos-timedemo-20261026-173533` | 15.936952 / 15.936955 / 15.936953 | 15.936953333 |

Every run rendered 969 frames with checksum `1047377823`. The candidate mean
was **−0.011190334 FPS (−0.0702%)** against the strict control mean. Its
screen skipped the ISA audit (`isaAuditStatus=SKIPPED`); the clear slowdown
rejects it before strict promotion. The candidate source-tree fingerprint was
`C76A289BF4673F86942D5D08E567FBC22BA87F40FBB48FEA92F8C4D55E516C5E`.
The alignment directive is removed.
