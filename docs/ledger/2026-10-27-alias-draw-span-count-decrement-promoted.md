# Alias draw-span count decrement before the common path — promoted

## Change

In `src/d_polysa.s`, `D_PolysetDrawSpans8` now decrements the computed span
length once and uses one common-path conditional branch to separate multi-pixel
spans from the short/empty cases. The short block still sends length one to
`LExactlyOneLong` and skips lengths below one. For multi-pixel spans, the group
count changes from `(n + 7) >> 3` to `((n - 1) + 8) >> 3`, and the alignment
offset changes from `-n` to `~(n - 1)`; both expressions are identical for the
32-bit count values used here.

## Matched timedemo

Control and candidate used the same `demo1` workload, three uninstrumented
runs, DOSBox-X 486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, i486
aggressive selectors, 969 frames, and framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean FPS | Median FPS |
|---|---|---:|---:|
| Control | 16.194460, 16.194494, 16.194492 | 16.194482000 | 16.194492 |
| Candidate | 16.194893, 16.194905, 16.194909 | 16.194902333 | 16.194905 |

The pooled mean increased by **0.000420333 FPS (+0.0025955%)**. All six runs
retained exact frame and checksum parity.

## i486 audit and artifacts

The full candidate ISA gate passed: 275,979 object instructions and 314,276
linked instructions, plus the startup image and DPMI provider; zero above-i486,
unknown, or exempt instructions. The control and candidate result files are
`out/dos-timedemo-20261027-102642/timedemo-result.json` and
`out/dos-timedemo-20261027-105618/timedemo-result.json`.
