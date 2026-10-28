# D_DrawZSpans nonnegative fast-path cutoff 8 (2026-10-24)

Status: rejected by the three-run visual-parity performance screen.

This screen lowered the i486-only nonnegative-span fast-path cutoff from the
accepted 16 pixels to 8. It retained exact frame output, but was slower than
the current 16-pixel control, so the source was restored to 16 without running
the full ISA audit.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, 16-pixel cutoff | `out/dos-timedemo-20261023-231850/timedemo-result.json` | 61.316257 / 61.316322 / 61.316364 | 15.803313 / 15.803296 / 15.803285 | 15.803298000 | 969 / `1047377823` every run |
| Screen, 8-pixel cutoff | `out/dos-timedemo-20261023-232541/timedemo-result.json` | 61.353227 / 61.353145 / 61.353215 | 15.793791 / 15.793811 / 15.793794 | 15.793798667 | 969 / `1047377823` every run |

The candidate mean was **0.009499333 FPS slower** (**0.06011%**); its median
was 0.009502 FPS lower. The screen reports `visualParityOnly=true` and
`isaAuditStatus=SKIPPED`; the negative result ended the experiment before the
strict audit. The candidate source fingerprints were source
`9167587873A06570A67B17487137366DE653D4F176272FA7C15ECE896CDCE188` and tree
`886F0C241A5ABE4A62EBB870B6F4A6F3D1ABD21BD833B95FEBF6E475BB43EC2F`.
