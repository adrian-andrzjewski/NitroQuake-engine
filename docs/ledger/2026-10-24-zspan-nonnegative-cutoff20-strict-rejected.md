# D_DrawZSpans nonnegative fast-path cutoff 20 (2026-10-24)

Status: rejected after the full strict three-run gate.

The three-run visual-parity screen for a 20-pixel cutoff was faster than the
accepted 16-pixel control. The strict three-run set retained exact output and
passed every i486 audit, but one slow timing sample brought its pooled mean
below control. The source was restored to the 16-pixel cutoff; this candidate
was not promoted.

All runs used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, 16-pixel cutoff | `out/dos-timedemo-20261023-231850/timedemo-result.json` | 61.316257 / 61.316322 / 61.316364 | 15.803313 / 15.803296 / 15.803285 | 15.803298000 | 15.803296 | 969 / `1047377823` every run |
| Screen, 20-pixel cutoff | `out/dos-timedemo-20261023-233529/timedemo-result.json` | 61.312837 / 61.312841 / 61.312875 | 15.804195 / 15.804194 / 15.804185 | 15.804191333 | 15.804194 | 969 / `1047377823` every run |
| Strict, 20-pixel cutoff | `out/dos-timedemo-20261023-235757/timedemo-result.json` | 61.312844 / 61.771898 / 61.312859 | 15.804193 / 15.686745 / 15.804189 | 15.765042333 | 15.804189 | 969 / `1047377823` every run |

The strict pooled mean was **0.038255667 FPS slower** (**0.24207%**) than
control, despite a higher median. The visual-parity screen mean was 0.000893333
FPS higher. Promotion follows the strict pooled mean, so the faster screen and
the two faster strict samples do not override the slower three-run result.

The strict linked i486 audit passed: 314,024 relocated instructions, 529
startup code rows, and 9,207 DPMI provider instructions, with zero instructions
above i486, unclassified instructions, or exemptions. All three strict runs
retained 969 frames and checksum `1047377823`.

Strict candidate source fingerprints: source
`639E827F549AA477430F40AB5A0841BD44D113A5C254CEFC0334E3E24CD4DFDC`, tree
`6B151FA8D4E31A009D3A6F16911FBFCE96A043466D8149F06C2241A7A6A59521`.
