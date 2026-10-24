# BSP walk solid-first cull promoted (2026-10-24)

Status: promoted after a positive strict timedemo and the complete i486 ISA
gate.

`R_RecursiveWorldNode_asm486` now checks `node->contents == CONTENTS_SOLID`
before loading and comparing `r_visframecount`. Solid nodes return immediately,
so they no longer pay for the global load and visibility comparison. Both
checks are read-only early-return predicates, so this order preserves traversal
behavior.

The profile run in
`out/dos-timedemo-20261024-160342/quake/PROFILE.JSN` counted 375,707 BSP nodes,
including 79,815 solid culls and 35,538 visibility culls.

The matched timedemos used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned
32 MB i486 profile with normalized SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Each run
completed 969 frames with checksum `1047377823`; selector verification passed,
the selected implementation was `asm`, and selector objects were byte-for-byte
identical.

| Variant | Artifact | Run FPS | Mean FPS | Median FPS | Spread |
|---|---|---|---:|---:|---:|
| Strict control | `out/dos-timedemo-20261024-162540/timedemo-result.json` | 15.900777 / 15.900727 / 15.900733 | 15.900745667 | 15.900733 | 0.000050 |
| Strict candidate | `out/dos-timedemo-20261024-174207/timedemo-result.json` | 15.900779 / 15.900826 / 15.900828 | 15.900811000 | 15.900826 | 0.000049 |

The candidate gained **0.000065333 FPS (+0.00041088%)** over the strict
control. Every candidate sample beat every control sample. The intermediate
parity screen in `out/dos-timedemo-20261024-171920/timedemo-result.json` also
preserved the checksum and measured a 15.900797667 FPS mean.

The complete i486 gate passed: 403 objects, 314,316 linked relocated
instructions, 529 startup rows, and 9,207 provider instructions were checked;
there were zero above-i486 instructions, unknown instructions, or exemptions.
Source proof and selector checks passed. The strict candidate source
fingerprint was
`C0B79F221B699B0E89E932A40ACB3B0DA7BE8CC296C7AB2F42182758D14C2F36`.
