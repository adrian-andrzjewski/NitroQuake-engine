# Surface-cache key preparation and comparison fusion (2026-10-20)

Status: promoted assembly-only micro-optimization in the working source.

The `D_DrawSurface` assembly path now fuses per-style cache-key preparation
with the comparison. On the common path it reads `styles[1]` once; all five
`r_drawsurf` key fields are still written on every cache-miss path. The change
is in `src/renderer/asm486_experiments.s` near the surface-key setup around line 4544.

## Matched strict timedemo

Both variants used the same 32 MB DOSBox-X 486 profile, profile hash
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, identical
153 selector values, the same `demo1` workload and CWSDPMI host, with FPS
instrumentation disabled.

| Variant | Artifact | Run times (s) | Mean FPS | Frames/checksum |
|---|---|---|---:|---|
| Control | `out/dos-timedemo-20261020-150012/timedemo-result.json` | 62.533462 / 62.533442 / 62.533414 | 15.495709 | 969 / `1047377823` every run |
| Fused key setup | `out/dos-timedemo-20261020-165435/timedemo-result.json` | 62.508471 / 62.508458 / 62.508425 | 15.501904 | 969 / `1047377823` every run |

The candidate median is 0.024984 seconds faster (**0.039953%** by duration).
Mean FPS rose by 0.006194 (**0.039975%**). Every candidate run was faster than
every control run; the candidate and control run-to-run spreads were 0.000046
and 0.000048 seconds.

The release executable passed the source-bound strict linked i486 audit. The
measured build and exact profile hash are recorded in the candidate result.
This qualifies under the current no-minimum-gain policy. The source remains
uncommitted.
