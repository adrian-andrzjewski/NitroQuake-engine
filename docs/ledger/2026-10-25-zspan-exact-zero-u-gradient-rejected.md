# D_DrawZSpans exact zero-U-gradient shortcut (2026-10-25)

Status: both variants were rejected after their matched three-run means
decreased. The source has been restored to `HEAD`; no commit was made.

The candidate added a separate zero-step loop for an exactly zero
`d_zistepu`, skipping the per-span U load and multiply. Its entry also moved
the initial `flds d_zistepu` below the zero check, changing instruction order
for every nonzero-gradient call. The follow-up preserved the original entry
order and branched to the specialized loop only from the exact-zero step path.

Both timedemos used DOSBox-X 2026.08.31, `demo1`, the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`), and
three uninstrumented runs. Every run rendered 969 frames and produced checksum
`1047377823`.

| Variant | Artifact | FPS samples | Mean FPS |
|---|---|---|---:|
| Accepted control | `out/dos-timedemo-20261025-052211/timedemo-result.json` | 15.921197 / 15.921183 / 15.921183 | 15.921187667 |
| Exact zero-U loop | `out/dos-timedemo-20261025-072102/timedemo-result.json` | 15.920744 / 15.920762 / 15.920766 | 15.920757333 |
| Preserved entry order | `out/dos-timedemo-20261025-072659/timedemo-result.json` | 15.920607 / 15.920641 / 15.920633 | 15.920627000 |

The first candidate mean decreased by **0.000430334 FPS** and the follow-up
decreased by **0.000560667 FPS**. Their spreads were 0.000022 and 0.000034 FPS.
The linked i486 audit for the first source variant passed 314,407 instructions,
529 startup rows, and 9,207 provider instructions with zero exemptions.

An earlier launch used the 16 MB default profile and failed before rendering;
those runs are not included in the timing comparison.
