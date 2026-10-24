# D_DrawZSpans branch-free 32-pixel group (2026-10-24)

Status: promoted after a positive strict timedemo comparison.

The i486 nonnegative Z-span path now handles 32 pixels per main-loop group
instead of 16. Its remainder path explicitly handles the 16-pixel bit before
the existing 8/4/2-pixel tails and final odd pixel. The endpoint proof,
per-pair arithmetic, general sign-aware path, and `TARGET_I386` path are
unchanged.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, identical aggressive i486 selectors, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, length-first cutoff 22, 16-pixel group | `out/dos-timedemo-20261024-022300/timedemo-result.json` | 61.263778 / 61.263771 / 61.263744 | 15.816850 / 15.816852 / 15.816859 | 15.816853667 | 15.816852 | 969 / `1047377823` every run |
| Screen, 32-pixel group | `out/dos-timedemo-20261024-041142/timedemo-result.json` | 61.232868 / 61.232793 / 61.232859 | 15.824834 / 15.824854 / 15.824836 | 15.824841333 | 15.824836 | 969 / `1047377823` every run |
| Strict, 32-pixel group | `out/dos-timedemo-20261024-043416/timedemo-result.json` | 61.232867 / 61.232885 / 61.232879 | 15.824834 / 15.824830 / 15.824831 | 15.824831667 | 15.824831 | 969 / `1047377823` every run |

The strict candidate mean increased by **0.007978000 FPS** (**0.05044%**),
and its median increased by 0.007979 FPS. Every screen and strict run retained
exact frame and framebuffer-checksum parity.

The complete strict i486 gate passed: 314,158 relocated executable
instructions, 529 startup rows, and 9,207 DPMI provider instructions, with
zero instructions above i486, unclassified instructions, or exemptions. All
403 native/annotated object proofs and 435 source-bound executable
contributions passed.

Strict candidate source fingerprint:
`9172DCAE06DBCB06D80C63222E84DE98E80379459A23DE2372E9D9C3C5CE25A4`; tree
fingerprint:
`AB00DBEE806ADBE640432768521D450B5BA03FC40A27D13F02180A803952CCB5`.
