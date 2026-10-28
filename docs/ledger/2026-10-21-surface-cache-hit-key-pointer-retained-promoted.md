# Surface-cache hit key-pointer retention promoted (2026-10-21)

Status: promoted in the working assembly source under the positive-mean rule.

In `D_CacheSurfaceHit_asm486`, the first light-style comparison loads
`r_drawsurf.lightadj` into `%edx`. The candidate keeps that pointer live while
`%ecx` temporarily holds the `surface` argument for the `styles[1]` sentinel
check. This removes the later stack reload of `r_drawsurf.lightadj` on the
common path where additional styles are active. The change is in
`src/asm486_experiments.s`.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the uninstrumented
runner, and the pinned 32 MB i486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Every
run completed 969 frames and reported framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261021-033929/timedemo-result.json` | 15.537289 / 15.537296 / 15.537289 | 15.537291333 | 0.000007 |
| Retained light-style pointer | `out/dos-timedemo-20261021-043143/timedemo-result.json` | 15.537299 / 15.537291 / 15.537288 | 15.537292667 | 0.000011 |

The candidate delta is **+0.000001333 FPS (+0.00000858%)**. The gain is smaller
than the measured spread, but the pooled mean is positive and qualifies under
the user's no-minimum-gain rule. All six runs passed frame/checksum parity.

The strict candidate build is
`out/local-current-cachehit-keyptr-retain-20261021/qbench.exe`. Its full i486
gate passed with 313,315 relocated instructions across 435 executable ranges,
529 startup code rows, and 9,207 provider instructions; there were no
above-i486 or unknown instructions, unverified bytes, or exemptions. The source
remains uncommitted.
