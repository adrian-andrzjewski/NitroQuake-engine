# Span16 coordinate-load interleave promoted (2026-10-26)

At the start of `D_DrawSpans16`, place the independent loads of the span's
vertical coordinate and `tadjust` between the two x87 coordinate loads. The
`FILD` order remains vertical then horizontal, preserving the x87 stack values
used by the existing setup.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI
(`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`), and
the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Strict control | `out/dos-timedemo-20261026-084516` | 15.942828 / 15.942819 / 15.942864 | 15.942837000 | 0.000045 |
| Strict candidate | `out/dos-timedemo-20261026-091621` | 15.942835 / 15.942864 / 15.942879 | 15.942859333 | 0.000044 |

The candidate mean increased by **0.000022333 FPS (+0.00014008%)**. All six
runs completed 969 frames with framebuffer checksum `1047377823`. The complete
strict i486 audit passed for both variants; the candidate verified 314,408
linked instructions, 529 startup rows, and 9,207 provider instructions, with
zero above-i486, unknown, or exempt instructions.

The candidate source-tree fingerprint is
`ACD611EDF92830501C70097453E2A058104221DF26515465491C00D70B41E6E9`.
