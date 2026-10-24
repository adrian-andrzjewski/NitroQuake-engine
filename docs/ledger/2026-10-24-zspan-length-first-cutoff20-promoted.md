# D_DrawZSpans length-first guard with cutoff 20 (2026-10-24)

Status: promoted in the working source under the no-minimum-gain policy.

The i486-only nonnegative Z-span path keeps the length check before the
nonnegative-start test and now admits spans of at least 20 pixels, up from 18.
The start-sign and complete-endpoint proof still precede the sign-branch-free
pixel copy. Pixel order, tails, endpoint arithmetic, and the `TARGET_I386` path
are unchanged.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 aggressive selectors, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, length-first cutoff 18 | `out/dos-timedemo-20261024-012605/timedemo-result.json` | 61.268952 / 61.268940 / 61.268951 | 15.815515 / 15.815518 / 15.815515 | 15.815516000 | 15.815515 | 969 / `1047377823` every run |
| Screen, length-first cutoff 20 | `out/dos-timedemo-20261024-013129/timedemo-result.json` | 61.264808 / 61.264894 / 61.264952 | 15.816584 / 15.816562 / 15.816547 | 15.816564333 | 15.816562 | 969 / `1047377823` every run |
| Strict, length-first cutoff 20 | `out/dos-timedemo-20261024-015352/timedemo-result.json` | 61.264842 / 61.264919 / 61.264904 | 15.816575 / 15.816556 / 15.816560 | 15.816563667 | 15.816560 | 969 / `1047377823` every run |

The strict candidate mean increased by **0.001047667 FPS** (**0.00662%**),
and its median increased by 0.001045 FPS. Every screen and strict run retained
exact frame and framebuffer-checksum parity.

The strict linked i486 audit passed: 314,024 relocated instructions, 529
startup code rows, and 9,207 DPMI provider instructions, with zero instructions
above i486, unclassified instructions, or exemptions. All 403 native/annotated
object proofs and the 435 source-bound executable contributions passed.

Control source fingerprints: source
`3F97FF6E4D68078319FFDCCEAA8E9262F2DEBF67DB76038C0C8D51E51294DE85`, tree
`4A824AED18B08529648949D7F2B78F722DE5DA6E4B81F526FFB07593CD2FC5B7`.
Strict candidate source fingerprints: source
`2BDFC53957C26648DEC35BB7EEF6030E36029AD9C35CA1EC386A442A4800352E`, tree
`8DBE8F5EBA012E95B98A3C776B7FB3439F4E513CD00F84A54491417D86D84810`.
