# Surface-cache key preparation only on misses (2026-10-29)

Status: promoted under the positive pooled-mean rule. The assembly cache check
now compares the existing entry before writing `r_drawsurf.texture` and the
four `lightadj` values. A valid hit returns immediately; a miss calls the
existing key-preparation helper before rebuilding. The `R_DlightContributes`
predicate is unchanged.

## Matched 320x200 timedemo screens

Both variants used DOSBox-X 2026.08.31, the pinned i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, CWSDPMI, and the complete `i486-asm-selectable-current` selector
profile. Timings were uninstrumented and used the default 320x200 demo path.
All six runs rendered 969 frames and ended with framebuffer checksum
`1047377823`.

| Variant | Artifact | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Original two-call path | `out/dos-timedemo-20261029-182208/timedemo-result.json` | 16.321720 / 16.321724 / 16.321698 | 0.000026 | 16.321714 |
| Prepare keys only on misses | `out/dos-timedemo-20261029-181709/timedemo-result.json` | 16.321765 / 16.321722 / 16.321706 | 0.000059 | 16.321731 |

The candidate mean improved by **0.000017 FPS (+0.000104%)**. This is a small
positive result and is retained under the no-minimum-gain rule; its spread is
larger than the mean difference.

## Image and ISA validation

The named `demo1-vga-full` visual-validation run used the same selector profile,
captured frame 169 at 320x200, rendered 969 frames, and retained checksum
`1047377823`. The committed golden comparison passed: 12 of 64,000 pixels
changed (fraction 0.0001875; mean absolute channel error 0.0009375). Report:
`out/render-validation-20261029-181413/render-validation-result.json`.

The strict build and linked-runtime i486 audits passed separately. They covered
276,021 build instructions and 314,318 linked-runtime instructions, with zero
above-i486, unknown, or exempt instructions. The timing runs were
`VisualParityOnly`; the strict timedemo wrapper was stopped after both audits
passed while it remained in a post-audit PowerShell step using over 1 GB of
memory, before launching another DOSBox run.

Control source-tree fingerprint: `E868748B19BC30F95ABE7F5D2BD64ABB5BEE7530C310A05597F218B03F72A071`.
Candidate source-tree fingerprint: `7D3A9B65B6327CAD371DF630438B2015C51E504D2F7640A198F2C1AAD9905A4C`.
