# Fourth `R_StepActiveU` U-store after compare ties on strict recheck (2026-10-26)

The fourth edge's `et_u` store was moved after its order comparison and before
`jnl LNextEdge`; the existing `et_next` load remains between the addition and
comparison. The parity-only screen was positive, so the candidate proceeded
through the complete strict i486 gate.

All variants used the pinned DOSBox-X 2026.08.31 i486 `demo1` profile with the
same aggressive selectors, three uninstrumented runs, and exact 969-frame
checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS | ISA audit |
|---|---|---|---:|---:|---|
| Strict control | `out/dos-timedemo-20261026-014533/timedemo-result.json` | 15.942837 / 15.942841 / 15.942879 | 15.942852333 | 15.942841 | PASS |
| Strict candidate | `out/dos-timedemo-20261026-022729/timedemo-result.json` | 15.942840 / 15.942827 / 15.942890 | 15.942852333 | 15.942840 | PASS |

The strict means tie exactly, so the positive-mean rule does not promote the
change. The candidate's full i486 gate passed: 314,408 linked instructions,
529 startup rows, and 9,207 provider instructions, with zero exemptions. The
candidate source-tree fingerprint is
`BEB65581BCEEA409AF64758647DE40D354554D2E89EC85D4D2BC53E2459F7518`; the
control fingerprint is
`55E9EF2E87DAB15E6D91A16AF984ED9D6C3A3151BB5A11E2ACD6C8A124EFB5B9`.
The source was restored to store-before-compare order.

For reference, the parity screen averaged 15.942868667 FPS for the candidate
(`out/dos-timedemo-20261026-020405`) and 15.942862333 FPS for control
(`out/dos-timedemo-20261026-012035`). The screen-only gain did not reproduce in
the strict comparison.
