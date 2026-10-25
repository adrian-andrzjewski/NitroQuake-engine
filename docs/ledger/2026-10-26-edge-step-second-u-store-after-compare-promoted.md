# Second `R_StepActiveU` U-store after compare promoted (2026-10-26)

The second edge update in the four-edge `R_StepActiveU` block now stores its
advanced U value after the order comparison and before `jl LPushBack2`. The
intervening `movl` preserves the comparison flags, and the updated value is
still stored before either control-flow path uses the edge.

The strict candidate used DOSBox-X 2026.08.31, the pinned i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
CWSDPMI, and the `demo1` timedemo:

| Variant | Run FPS | Mean FPS | Spread | Frames/checksum |
|---|---|---:|---:|---|
| Control (`out/dos-timedemo-20261025-212734/timedemo-result.json`) | 15.940524 / 15.940551 / 15.940522 | 15.940532333 | 0.000027 | 969 / `1047377823` |
| Candidate (`out/dos-timedemo-20261025-231013/timedemo-result.json`) | 15.940509 / 15.940555 / 15.940556 | 15.940540000 | 0.000047 | 969 / `1047377823` |

The strict mean increased by **0.000007667 FPS (+0.0000481%)**. All six
timedemo runs completed 969 frames with the exact expected checksum. The full
linked i486 gate passed: 314,394 linked instructions, 529 startup rows, and
9,207 provider instructions; zero above-i486, unknown, or exempt instructions.
The final source mapping covered 435 contributions, 2,376 CODE ranges, and 35
DATA ranges.

The candidate source-tree fingerprint was
`29E6FB90252DE762C745B6967A531A7BC5C9F6154D0C5CD4D2D773486B37E163`.
