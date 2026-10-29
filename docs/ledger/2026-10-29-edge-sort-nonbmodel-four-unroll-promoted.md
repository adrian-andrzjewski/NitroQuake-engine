# `R_GenerateSpans` non-bmodel sort four-way unroll promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete linked i486 ISA gate.

`Lsortloopnb` now advances and compares four active-surface nodes per back-edge. Each signed less-than check exits directly to `LInsertAndExit`; the back-edge runs only when all four checked keys require continuing the search. This preserves the original ordering and signed comparison. The `PROFILE486` iteration counter and `EDGE_SCAN_PROBE_SORT` probe are duplicated at the third and fourth comparisons so their diagnostic counts remain per surface node.

## Matched timedemo

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Committed strict control | `out/dos-timedemo-20261029-044946/timedemo-result.json` | 16.321027 / 16.321013 / 16.321006 | 0.000021 | 16.321015333 |
| Candidate parity screen | `out/dos-timedemo-20261029-045543/timedemo-result.json` | 16.321686 / 16.321659 / 16.321657 | 0.000029 | 16.321667333 |
| Strict candidate | `out/dos-timedemo-20261029-052054/timedemo-result.json` | 16.321688 / 16.321651 / 16.321653 | 0.000037 | 16.321664000 |

The strict candidate gained **0.000648667 FPS (+0.00397443%)** over the committed strict control. Every run rendered 969 frames with framebuffer checksum `1047377823`. The candidate source-tree fingerprint was `8B79FE9B2DB2A267E9DD3043BDBB7FF1373914F772CBEAF6A51F9836BD2535DE`.

## i486 proof

The complete executable gate passed with 314,227 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions; there were zero above-i486, unknown, or exempt instructions. The run verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. The strict result records `isaAuditStatus=PASS` and `visualParityOnly=false`.
