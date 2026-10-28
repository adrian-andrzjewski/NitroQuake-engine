# Reject moving the first `R_StepActiveU` U-store after its compare (2026-10-26)

Moving the first edge's `et_u` store after its order comparison, but before the
conditional branch, preserves the compare flags and updates memory on both
paths. The change was screened against the current committed source after the
second-edge store scheduling promotion.

Both variants used the pinned DOSBox-X 2026.08.31 i486 `demo1` profile with the
same aggressive assembly selectors, three uninstrumented runs, and the
expected 969 frames/checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Spread | ISA audit |
|---|---|---|---:|---:|---|
| Control | `out/dos-timedemo-20261026-012035/timedemo-result.json` | 15.942832 / 15.942878 / 15.942877 | 15.942862333 | 0.000046 | SKIPPED |
| First-store after compare | `out/dos-timedemo-20261026-015340/timedemo-result.json` | 15.942835 / 15.942862 / 15.942839 | 15.942845333 | 0.000027 | SKIPPED |

The screen mean fell by **0.000017 FPS (0.00010663%)**. All runs retained exact
frame and framebuffer-checksum parity. The candidate source-tree fingerprint
was `4ADE7BF5FCEB1B8A3F470A2B809E0C3D794B8350FEA3B327959872D68C7AA2FE`; the
control fingerprint was
`55E9EF2E87DAB15E6D91A16AF984ED9D6C3A3151BB5A11E2ACD6C8A124EFB5B9`. The
negative screen mean rejects the schedule before the strict audit; the original
store-before-compare order remains active.
