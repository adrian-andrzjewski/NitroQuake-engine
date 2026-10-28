# D_DrawZSpans length-first guard with cutoff 23 (2026-10-24)

Status: rejected after the strict three-run mean tied the cutoff-22 control;
the working source was restored to cutoff 22.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, identical aggressive i486 selectors, and uninstrumented strict timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, length-first cutoff 22 | `out/dos-timedemo-20261024-022300/timedemo-result.json` | 61.263778 / 61.263771 / 61.263744 | 15.816850 / 15.816852 / 15.816859 | 15.816853667 | 15.816852 | 969 / `1047377823` every run |
| Screen, length-first cutoff 23 | `out/dos-timedemo-20261024-023300/timedemo-result.json` | 61.263743 / 61.263775 / 61.263747 | 15.816859 / 15.816851 / 15.816858 | 15.816856000 | 15.816858 | 969 / `1047377823` every run |
| Strict, length-first cutoff 23 | `out/dos-timedemo-20261024-025532/timedemo-result.json` | 61.263763 / 61.263786 / 61.263746 | 15.816854 / 15.816848 / 15.816859 | 15.816853667 | 15.816854 | 969 / `1047377823` every run |

The parity screen was slightly positive, but the strict pooled mean tied the
control exactly, so this was not an FPS increase and was not promoted. The
strict median was 0.000002 FPS higher. Exact frame and framebuffer-checksum
parity held throughout.

The complete strict i486 gate passed: 314,024 relocated executable
instructions, 529 startup rows, and 9,207 DPMI provider instructions, with
zero instructions above i486, unclassified instructions, or exemptions. All
403 native/annotated object proofs and 435 source-bound executable
contributions passed.

Strict candidate source fingerprint:
`B2DE6FACC3F0D1C96E17CF13F5DB1A01BA302F6F058F6D9365B55B3CA66EFB5B`; tree
fingerprint:
`B3CF490949C540331F3EA6E5FEB223FEA9A7B428F4DA9305E92076478E3F3AB1`.
