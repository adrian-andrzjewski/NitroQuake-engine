# D_DrawZSpans nonnegative fast-path cutoff 18 (2026-10-24)

Status: promoted in the working source under the no-minimum-gain policy.

The i486-only nonnegative-span fast path in `src/renderer/d_draw.s` now accepts spans of
at least 18 pixels, down from 20 in the screen candidate and up from the
accepted 16-pixel control. The endpoint proof still checks the complete span
before entering the sign-branch-free copy; the 16-pixel groups and 8/4/2/1-pixel
tails preserve the original sample order. Negative-start, negative-end,
overflowing, and shorter spans continue through the general path.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 aggressive selectors, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, 16-pixel cutoff | `out/dos-timedemo-20261023-231850/timedemo-result.json` | 61.316257 / 61.316322 / 61.316364 | 15.803313 / 15.803296 / 15.803285 | 15.803298000 | 15.803296 | 969 / `1047377823` every run |
| Screen, 18-pixel cutoff | `out/dos-timedemo-20261024-000307/timedemo-result.json` | 61.313972 / 61.313967 / 61.313763 | 15.803902 / 15.803904 / 15.803956 | 15.803920667 | 15.803904 | 969 / `1047377823` every run |
| Strict, 18-pixel cutoff | `out/dos-timedemo-20261024-002538/timedemo-result.json` | 61.313929 / 61.314009 / 61.313947 | 15.803913 / 15.803892 / 15.803909 | 15.803904667 | 15.803909 | 969 / `1047377823` every run |

The strict candidate mean increased by **0.000606667 FPS** (**0.00384%**),
and its median increased by 0.000613 FPS. All screen and strict runs retained
exact frame and framebuffer-checksum parity. The result passes the project's
positive-mean acceptance gate; the measured gain is small.

The strict linked i486 audit passed: 314,024 relocated instructions, 529
startup code rows, and 9,207 DPMI provider instructions, with zero instructions
above i486, unclassified instructions, or exemptions. All 403 native/annotated
object proofs and the 435 source-bound executable contributions passed.

Control source fingerprints: source
`BDD107D56EDA5D10EC9D3E740E40E7380F27619A41BB6C0D084730B1125A3FB4`, tree
`AE6BE756787E4A2C722C9BA7C9A49861521F2D74514DB05B31AAE1A43650BEF0`.
Strict candidate source fingerprints: source
`82A53AB25CCF7F8DF5CF4094BD684BAAF760BFC74CEAD3E58585BC06B5E4191A`, tree
`DE978CCEFF9A3C54C9170324B836CED0CA6694ABA11C2556DE7D964C0A08A0EE`.
