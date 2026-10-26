# Legacy `R_RemoveEdges` nextremove load after unlink promoted (2026-10-26)

Status: promoted in `src/r_edgea.s` under the positive pooled-mean rule.

In the legacy two-edge removal loop, each `et_nextremove` pointer is now loaded
after the two neighbor-link stores. The unlink stores touch `et_prev` and
`et_next`, so the delayed load still reads the same `et_nextremove` field and
preserves traversal order.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261026-014533` | 15.942837 / 15.942841 / 15.942879 | 15.942852333 | 0.000042 |
| Candidate parity screen | `out/dos-timedemo-20261026-023956` | 15.942841 / 15.942840 / 15.942877 | 15.942852667 | 0.000037 |
| Strict candidate | `out/dos-timedemo-20261026-030315` | 15.942841 / 15.942841 / 15.942879 | 15.942853667 | 0.000038 |

The strict candidate mean is **+0.000001333 FPS (+0.00000836%)** over control.
All six strict runs completed 969 frames with framebuffer checksum
`1047377823`. The complete strict i486 gate passed: 314,408 linked
instructions, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The candidate source-tree
fingerprint is
`3A2C2676F7410385E7635F5B600A2C38F8ECB9EB6E5751A356C59903685FDFF7`.
