# Alias nonnegative-light fallthrough — promoted (2026-10-25)

## Change

In `src/renderer/r_aliasa.s`, the common nonnegative-light case in
`R_AliasTransformAndProjectFinalVerts` now discards the dot-product value and
falls directly into the projection path. The shaded-light calculation and
clamp move to an out-of-line cold path. The arithmetic and x87 operation order
on the shaded path are unchanged.

This removes the taken cleanup branch and the unconditional jump back into
projection from the common path. The existing `jns` and zero clamp remain on
the cold path.

## Strict timedemo

The candidate was measured with DOSBox-X 2026.08.31, the pinned i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and FPS statistics disabled.

| Source | Run directory | FPS samples | Mean |
| --- | --- | --- | ---: |
| Control | `out/dos-timedemo-20261025-192417` | 15.939338, 15.939349, 15.939347 | 15.939344667 |
| Candidate | `out/dos-timedemo-20261025-203909` | 15.940503, 15.940522, 15.940552 | 15.940525667 |

The candidate gained **0.001181 FPS (+0.00740934%)** over the strict control
mean. A separate one-run strict control immediately before this experiment
measured 15.939344 FPS with the same profile.

All candidate runs completed 969 frames and retained framebuffer checksum
`1047377823`. The complete i486 gate passed: 168 source objects, 403 linked
objects, 314,394 relocated instructions, 529 startup code rows, and 9,207
CWSDPMI instructions; there were zero unsupported instructions, unknown
opcodes, or exemptions. The staged provider hash was
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`.

The positive strict mean qualifies under the project's any-positive promotion
rule. The candidate is promoted.
