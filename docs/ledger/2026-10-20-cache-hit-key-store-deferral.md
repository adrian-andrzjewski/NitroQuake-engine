# Surface-cache hit key-store deferral (2026-10-20)

Status: promoted assembly-only optimization in the working source.

`D_CacheSurface` now compares the cached texture and light-style values before
writing `r_drawsurf.texture` and `r_drawsurf.lightadj`. A cache hit returns the
cache directly and does not consume these fields; cache misses and contributing
dynamic lights still fill all five fields before rebuilding the surface. The
implementation is in `src/renderer/asm486_experiments.s`.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the same saved 32 MB 486 profile
(`out/dosbox-x-486-high-32m-baseline.conf`, SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`), the same
153 selector values, `demo1`, CWSDPMI, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control | `out/dos-timedemo-20261020-173438/timedemo-result.json` | 62.508420 / 62.508410 / 62.508409 | 15.501912 / 15.501914 / 15.501915 | 15.501913667 | 969 / `1047377823` every run |
| Deferred hit stores | `out/dos-timedemo-20261020-181754/timedemo-result.json` | 62.490796 / 62.490810 / 62.490763 | 15.506284 / 15.506280 / 15.506292 | 15.506285333 | 969 / `1047377823` every run |

Mean FPS improved by **0.0282%**. Every candidate run was faster than every
control run; control timing spread was 0.000011 s and candidate spread was
0.000047 s. The candidate passed the full linked i486 executable audit: 313,018
relocated instructions, 529 startup rows, and 9,207 provider instructions,
with no above-i486 instructions or exemptions.

This is promoted under the current no-minimum-gain policy. The measured delta
was positive across all three samples and exceeded the observed within-variant
timing spreads. The source remains uncommitted.
