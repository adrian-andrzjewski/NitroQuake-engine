# D_DrawZSpans length-first guard with cutoff 22 (2026-10-24)

Status: promoted after a positive strict timedemo comparison.

The i486-only nonnegative Z-span path keeps the length check before the
nonnegative-start test and now admits spans of at least 22 pixels, up from 20.
The start-sign and complete-endpoint proof still precede the sign-branch-free
pixel copy. Pixel order, tails, endpoint arithmetic, and the `TARGET_I386` path
are unchanged.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, identical aggressive i486 selectors, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, length-first cutoff 20 | `out/dos-timedemo-20261024-015352/timedemo-result.json` | 61.264842 / 61.264919 / 61.264904 | 15.816575 / 15.816556 / 15.816560 | 15.816563667 | 15.816560 | 969 / `1047377823` every run |
| Screen, length-first cutoff 22 | `out/dos-timedemo-20261024-020035/timedemo-result.json` | 61.263773 / 61.263806 / 61.263777 | 15.816852 / 15.816843 / 15.816850 | 15.816848333 | 15.816850 | 969 / `1047377823` every run |
| Strict, length-first cutoff 22 | `out/dos-timedemo-20261024-022300/timedemo-result.json` | 61.263778 / 61.263771 / 61.263744 | 15.816850 / 15.816852 / 15.816859 | 15.816853667 | 15.816852 | 969 / `1047377823` every run |

The strict candidate mean increased by **0.000290000 FPS** (**0.00183%**),
and its median increased by 0.000292 FPS. Every screen and strict run retained
exact frame and framebuffer-checksum parity.

The complete strict i486 gate passed: 314,024 relocated executable
instructions, 529 startup rows, and 9,207 DPMI provider instructions, with
zero instructions above i486, unclassified instructions, or exemptions. All
403 native/annotated object proofs and 435 source-bound executable
contributions passed.

Strict candidate source fingerprint:
`4B53057CE9034204D8D96574BEB80D4332D35DDC9C1ED2D3BDE235C9966C1E24`; tree
fingerprint:
`23307F380F914DC77184FA992AD2F5F00E092302B94835E6969BB2920632461C`.
