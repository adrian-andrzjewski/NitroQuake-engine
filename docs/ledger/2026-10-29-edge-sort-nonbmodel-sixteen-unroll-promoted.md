# `R_GenerateSpans` non-bmodel sort sixteen-way unroll promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and
framebuffer-checksum parity, and the complete executable i486 ISA gate.

`Lsortloopnb` now advances and compares sixteen active-surface nodes per
back-edge. Each signed less-than check exits directly to `LInsertAndExit`; the
back-edge runs only when all sixteen checked keys require continuing the
search. This preserves the original ordering and signed comparison.
`PROFILE486` counts and `EDGE_SCAN_PROBE_SORT` probes remain at every
individual comparison.

## Matched timedemo

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486
selector profile, and the pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Committed eight-way strict control | `out/dos-timedemo-20261029-061124/timedemo-result.json` | 16.321721 / 16.321702 / 16.321694 | 0.000027 | 16.321705667 |
| Candidate parity screen | `out/dos-timedemo-20261029-070419/timedemo-result.json` | 16.321720 / 16.321710 / 16.321698 | 0.000022 | 16.321709333 |
| Strict candidate | `out/dos-timedemo-20261029-071908/timedemo-result.json` | 16.321707 / 16.321724 / 16.321704 | 0.000020 | 16.321711667 |

The strict candidate gained **0.000006 FPS (+0.00003676%)** over its committed
eight-way parent. The gain is smaller than the within-variant spreads but is
positive under the current promotion rule. Every run completed 969 frames with
framebuffer checksum `1047377823`. The parity screen skipped ISA auditing; the
strict candidate's `isaAuditStatus` is `PASS` and `visualParityOnly` is false.

The strict source-tree fingerprint is
`403E0827A565E7A3A0AD577B5B50843924FAD58BE56ED32D755935D896E72718`.

## i486 proof

The complete executable gate passed with 314,263 relocated instructions, 529
startup code rows, and 9,207 DPMI provider instructions; there were zero
above-i486, unknown, or exempt instructions. The run verified 403 exact
native/annotated object proofs and mapped 435 source-bound contributions
across 2,376 CODE ranges and 35 DATA ranges.
