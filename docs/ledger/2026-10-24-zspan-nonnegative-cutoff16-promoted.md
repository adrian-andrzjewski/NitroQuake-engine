# D_DrawZSpans nonnegative fast-path cutoff 16 (2026-10-24)

Status: promoted in the working source under the no-minimum-gain policy.

The i486-only nonnegative-span path in `src/renderer/d_draw.s` now accepts spans of at
least 16 pixels, down from 24. The endpoint proof still checks the complete
span before entering the sign-branch-free copy; the 16-pixel groups and 8/4/2/
1-pixel tails preserve the original sample order. Negative-start, negative-end,
overflowing, and shorter spans continue through the general path. `TARGET_I386`
continues to use its prior implementation.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`), the
same `demo1` run, i486 aggressive build selectors, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, 24-pixel cutoff | `out/dos-timedemo-20261023-215042/timedemo-result.json` | 61.316385 / 61.316416 / 61.316394 | 15.803280 / 15.803272 / 15.803277 | 15.803276333 | 15.803277 | 969 / `1047377823` every run |
| Candidate, 16-pixel cutoff | `out/dos-timedemo-20261023-231850/timedemo-result.json` | 61.316257 / 61.316322 / 61.316364 | 15.803313 / 15.803296 / 15.803285 | 15.803298000 | 15.803296 | 969 / `1047377823` every run |

The candidate mean increased by **0.000021667 FPS** (**0.0001371%**); its median
increased by 0.000019 FPS. All three candidate runs retained exact frame and
framebuffer-checksum parity. This result passes the project's positive-mean
acceptance gate; the measured gain is small.

The strict linked i486 audit passed: 314,024 relocated instructions, 529
startup code rows, and 9,207 DPMI provider instructions, with zero instructions
above i486, unclassified instructions, or exemptions. All 403 native/annotated
object proofs and the 435 source-bound executable contributions passed.

Control source fingerprints: source `9F682B24E7ABDC486204B8347F5EFF0FFBD5A55F8D77C9895D78AC3B07AD1178`,
tree `7BE17091D3C94029FAABA5B110526EF5FE6B4C6BA1819DEA41DFA8549EA22ABD`.
Candidate source fingerprints: source `BDD107D56EDA5D10EC9D3E740E40E7380F27619A41BB6C0D084730B1125A3FB4`,
tree `AE6BE756787E4A2C722C9BA7C9A49861521F2D74514DB05B31AAE1A43650BEF0`.
