# D_DrawZSpans nonnegative fast-path cutoff 12 (2026-10-24)

Status: rejected by the three-run visual-parity performance screen.

This screen lowered the i486-only nonnegative-span fast-path cutoff from the
accepted 16 pixels to 12. It retained exact frame output, but was slower than
the current 16-pixel control, so the source was restored to 16 without running
the full ISA audit.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, 16-pixel cutoff | `out/dos-timedemo-20261023-231850/timedemo-result.json` | 61.316257 / 61.316322 / 61.316364 | 15.803313 / 15.803296 / 15.803285 | 15.803298000 | 969 / `1047377823` every run |
| Screen, 12-pixel cutoff | `out/dos-timedemo-20261023-233049/timedemo-result.json` | 61.325791 / 61.325768 / 61.325729 | 15.800856 / 15.800862 / 15.800872 | 15.800863333 | 969 / `1047377823` every run |

The candidate mean was **0.002434667 FPS slower** (**0.01541%**); its median
was 0.002434 FPS lower. The screen reports `visualParityOnly=true` and
`isaAuditStatus=SKIPPED`; the negative result ended the experiment before the
strict audit. The candidate source fingerprints were source
`CF31C8F51C28DA1A9C96C8FEA9D71F3A70F7E85F0ECA59FFD8E1B21C4E59DC47` and tree
`97FBDD400AD7D7CB4BD9D46DB5F18C2568BC76E03F53EF41A8C7DC1F4039925C`.
