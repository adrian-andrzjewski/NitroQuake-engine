# Fourth `R_StepActiveU` next-link load hoist promoted (2026-10-26)

The fourth edge step in the unrolled `R_StepActiveU` block now loads
`et_next(%esi)` before reading and updating the edge's U value. The resulting
`%edx` is still consumed only on the existing `jnl LNextEdge` path; the
pushback path and all state writes remain unchanged.

Both strict variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI
(`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`), and
the pinned 32 MB i486 profile (`cputype=486`, dynamic core, fixed 33,445
cycles; SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).

| Variant | Artifact | FPS samples | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261026-091621` | 15.942835 / 15.942864 / 15.942879 | 15.942859333 | 0.000044 |
| Strict candidate | `out/dos-timedemo-20261026-133532` | 15.942826 / 15.942878 / 15.942877 | 15.942860333 | 0.000052 |

The strict candidate mean increased by `0.000001 FPS`. This is smaller than
the run-to-run spread, but it is positive under the strict-mean promotion
criterion. All six strict runs completed 969 frames with framebuffer checksum
`1047377823`.

An initial parity screen had one slow sample (`15.823256 FPS`) alongside two
near-control samples. A repeat parity screen was stable at `15.942820 /
15.942888 / 15.942878 FPS`, mean `15.942862`; all screen runs also retained
969 frames and checksum `1047377823`.

The complete strict i486 audit passed: 314,408 linked instructions, 529 startup
rows, and 9,207 provider instructions, with zero above-i486, unknown, or exempt
instructions. The candidate was promoted by moving the fourth edge's next-link
load ahead of its U update; the pinned demo's frame count and final checksum
matched control.

Screen artifacts:

- `out/dos-timedemo-20261026-125942`
- `out/dos-timedemo-20261026-130352`

Strict artifact:

- `out/dos-timedemo-20261026-133532`
