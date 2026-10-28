# D_DrawZSpans 16-pixel middle-loop unroll (2026-10-20)

Status: promoted in the working source under the no-minimum-gain policy.

The i486 path in `src/d_draw.s` now handles sixteen pixels per main-loop
iteration for both positive and negative depth gradients. Eight-, four-, two-,
and one-pixel tails preserve the original pixel order and depth arithmetic. The
`TARGET_I386` packing fallback remains on its prior path.

## Matched strict timedemo

All variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`), the same
153 selector values, `demo1`, CWSDPMI, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control (surface-cache hit stores already promoted) | `out/dos-timedemo-20261020-181754/timedemo-result.json` | 62.490796 / 62.490810 / 62.490763 | 15.506284 / 15.506280 / 15.506292 | 15.506285333 | 969 / `1047377823` every run |
| 16-pixel unroll, first strict set | `out/dos-timedemo-20261020-185806/timedemo-result.json` | 62.390217 / 62.853434 / 62.390177 | 15.531281 / 15.416818 / 15.531291 | 15.493130000 | 969 / `1047377823` every run |
| 16-pixel unroll, six added samples | `out/dos-timedemo-20261020-190238/timedemo-result.json` | 62.390208 / 62.390171 / 62.390172 / 62.390210 / 62.390211 / 62.390168 | 15.531283 / 15.531293 / 15.531293 / 15.531283 / 15.531282 / 15.531294 | 15.531288000 | 969 / `1047377823` every run |

The six added samples have a mean and median of **15.531288 FPS**, 0.1612%
above the control mean. Across all nine candidate runs, retaining the single
62.853434 s outlier, the mean is **15.518568667 FPS** and the median is
**15.531283 FPS**. The nine-run mean is still **0.0792% faster** than the
control mean, and its median is **0.1612% higher** than the control median;
eight candidate runs are faster than every control run.

The strict linked i486 audit passed: 313,319 relocated instructions across 435
executable ranges, 529 startup code rows, and 9,207 DPMI provider instructions,
with no above-i486 instructions, unclassified instructions, or exemptions.
Both candidate result files report `isaAuditStatus=PASS` and the same source
fingerprints.

The standalone `bench486` runner attempts in
`out/dos-bench-20261020-183458` and `out/dos-bench-20261020-183642` did not
produce `bench486.txt`. Promotion is based on the matched full-demo timedemo,
exact 969-frame framebuffer checksums, and strict ISA audit; this entry does
not claim a focused `bench486` fixture pass for the new unroll.
