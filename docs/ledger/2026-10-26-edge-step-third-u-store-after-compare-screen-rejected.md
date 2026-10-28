# Reject moving the third `R_StepActiveU` U-store after its compare (2026-10-26)

The third edge's `et_u` store in the four-edge update block was moved after
its order comparison and before `jl LPushBack`. `MOV` preserves the compare
flags, so the candidate retained the same control flow and store on both
paths.

Both variants used the pinned DOSBox-X 2026.08.31 i486 `demo1` profile with the
same aggressive assembly selectors, three uninstrumented runs, and exact
969-frame checksum parity (`1047377823`).

| Variant | Artifact | FPS samples | Mean FPS | Spread | ISA audit |
|---|---|---|---:|---:|---|
| Control | `out/dos-timedemo-20261026-012035/timedemo-result.json` | 15.942832 / 15.942878 / 15.942877 | 15.942862333 | 0.000046 | SKIPPED |
| Third-store after compare | `out/dos-timedemo-20261026-015907/timedemo-result.json` | 15.825517 / 15.942876 / 15.942829 | 15.903740667 | 0.117359 | SKIPPED |

The pooled mean fell by **0.039121667 FPS (0.24538672%)**. The slow first run
remains in the mean under the acceptance rule; all runs nevertheless retained
969 frames and the expected framebuffer checksum. The candidate source-tree
fingerprint was `9C9BC03A76B10453D83E4702E8E5EED077A8E9D8EDCB87684AE6FC90946FC645`;
the control fingerprint was
`55E9EF2E87DAB15E6D91A16AF984ED9D6C3A3151BB5A11E2ACD6C8A124EFB5B9`. The
negative parity-screen mean rejects the schedule before strict ISA auditing;
the original store-before-compare order remains active.
