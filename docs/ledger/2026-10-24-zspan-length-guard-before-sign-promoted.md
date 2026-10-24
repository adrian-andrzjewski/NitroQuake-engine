# D_DrawZSpans length guard before sign check (2026-10-24)

Status: promoted in the working source under the no-minimum-gain policy.

In the i486-only nonnegative Z-span path in `src/d_draw.s`, the 18-pixel span
length check now runs before the nonnegative-start test. Short spans go to the
general path without testing the start sign; long spans still pass the same
start-sign and complete-endpoint proof before using the sign-branch-free pixel
copy. The endpoint arithmetic, pixel order, tails, and `TARGET_I386` path are
unchanged.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 aggressive selectors, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, sign check first | `out/dos-timedemo-20261024-002538/timedemo-result.json` | 61.313929 / 61.314009 / 61.313947 | 15.803913 / 15.803892 / 15.803909 | 15.803904667 | 15.803909 | 969 / `1047377823` every run |
| Screen, length check first | `out/dos-timedemo-20261024-010335/timedemo-result.json` | 61.268940 / 61.268928 / 61.268935 | 15.815518 / 15.815521 / 15.815519 | 15.815519333 | 15.815519 | 969 / `1047377823` every run |
| Strict, length check first | `out/dos-timedemo-20261024-012605/timedemo-result.json` | 61.268952 / 61.268940 / 61.268951 | 15.815515 / 15.815518 / 15.815515 | 15.815516000 | 15.815515 | 969 / `1047377823` every run |

The strict candidate mean increased by **0.011611333 FPS** (**0.07347%**),
and its median increased by 0.011606 FPS. Every screen and strict run retained
exact frame and framebuffer-checksum parity.

The strict linked i486 audit passed: 314,024 relocated instructions, 529
startup code rows, and 9,207 DPMI provider instructions, with zero instructions
above i486, unclassified instructions, or exemptions. All 403 native/annotated
object proofs and the 435 source-bound executable contributions passed.

Control source fingerprints: source
`82A53AB25CCF7F8DF5CF4094BD684BAAF760BFC74CEAD3E58585BC06B5E4191A`, tree
`DE978CCEFF9A3C54C9170324B836CED0CA6694ABA11C2556DE7D964C0A08A0EE`.
Strict candidate source fingerprints: source
`3F97FF6E4D68078319FFDCCEAA8E9262F2DEBF67DB76038C0C8D51E51294DE85`, tree
`4A824AED18B08529648949D7F2B78F722DE5DA6E4B81F526FFB07593CD2FC5B7`.
