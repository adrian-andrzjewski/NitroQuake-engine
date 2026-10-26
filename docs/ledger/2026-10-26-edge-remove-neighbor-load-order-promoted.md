# Legacy `R_RemoveEdges` neighbor-pointer load order promoted (2026-10-26)

In both iterations of the two-edge removal loop, load `et_prev` before
`et_next`. The neighbor-pointer reads are independent; the unlink stores and
`et_nextremove` traversal order are unchanged.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI
(`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`), and
the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Parity control | `out/dos-timedemo-20261026-065833` | 15.942835 / 15.823197 / 15.942871 | 15.902967667 | 0.119674 |
| Strict candidate | `out/dos-timedemo-20261026-084516` | 15.942828 / 15.942819 / 15.942864 | 15.942837000 | 0.000045 |

The candidate mean increased by **0.039869333 FPS (+0.250704%)** under the
current positive pooled-mean acceptance rule. The control contains one slow
sample; all samples and spread are retained here for review. All six runs
completed 969 frames with framebuffer checksum `1047377823`. The candidate's
complete strict i486 audit passed: 314,408 linked instructions, 529 startup
rows, and 9,207 provider instructions, with zero above-i486, unknown, or exempt
instructions. The control used the parity-only gate and skipped its ISA audit.

The candidate source-tree fingerprint is
`1ECE0CC6E09C88C6AB7F958F5140C5CDB039859D9064C2D9B0DA3BAD30E88C66`.
