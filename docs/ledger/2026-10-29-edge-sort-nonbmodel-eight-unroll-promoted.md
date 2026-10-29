# `R_GenerateSpans` non-bmodel sort eight-way unroll promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete linked i486 ISA gate.

`Lsortloopnb` now advances and compares eight active-surface nodes per back-edge. Each signed less-than check exits directly to `LInsertAndExit`; the back-edge runs only when all eight checked keys require continuing the search. This preserves the original ordering and signed comparison. The `PROFILE486` iteration counter and `EDGE_SCAN_PROBE_SORT` probe remain at each comparison so diagnostic counts stay per surface node.

## Matched timedemo

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Committed strict control | `out/dos-timedemo-20261029-052054/timedemo-result.json` | 16.321688 / 16.321651 / 16.321653 | 0.000037 | 16.321664000 |
| Candidate parity screen | `out/dos-timedemo-20261029-053847/timedemo-result.json` | 16.321760 / 16.321701 / 16.321692 | 0.000068 | 16.321717667 |
| Strict candidate | `out/dos-timedemo-20261029-061124/timedemo-result.json` | 16.321721 / 16.321702 / 16.321694 | 0.000027 | 16.321705667 |

The strict candidate gained **0.000041667 FPS (+0.0002553%)** over the committed strict control. Every run rendered 969 frames with framebuffer checksum `1047377823`. The candidate source-tree fingerprint was `AB3D9C47E9A9C82E80B28BDD990F17837D62D30EE8D24902CB54D183DFC4E761`.

## i486 proof

The complete executable gate passed with 314,240 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions; there were zero above-i486, unknown, or exempt instructions. The run verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. The strict result records `isaAuditStatus=PASS` and `visualParityOnly=false`.
