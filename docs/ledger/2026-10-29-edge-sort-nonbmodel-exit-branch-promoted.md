# `R_GenerateSpans` non-bmodel sort exit branch promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete linked i486 ISA gate.

`Lsortloopnb` now branches directly to `LInsertAndExit` when the key comparison finishes the search (`jl`), and takes an unconditional backward branch only when the search must continue. This preserves the original signed comparison and surface ordering.

## Matched timedemo

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Committed strict control | `out/dos-timedemo-20261029-032931/timedemo-result.json` | 16.312516 / 16.312559 / 16.312559 | 0.000043 | 16.312544667 |
| Candidate parity screen | `out/dos-timedemo-20261029-035040/timedemo-result.json` | 16.318162 / 16.318143 / 16.318174 | 0.000031 | 16.318159667 |
| Strict candidate | `out/dos-timedemo-20261029-041531/timedemo-result.json` | 16.318161 / 16.318171 / 16.318144 | 0.000027 | 16.318158667 |

The strict candidate gained **0.005614 FPS (+0.03441523%)** over the committed strict control. Every run rendered 969 frames with framebuffer checksum `1047377823`. The candidate source-tree fingerprint was `8F16A24BBEBB4124286919B655990138E2E885D7142A2B7365EC561C8D740407`.

## i486 proof

The complete executable gate passed with 314,218 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions; there were zero above-i486, unknown, or exempt instructions. The run verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. The strict result records `isaAuditStatus=PASS` and `visualParityOnly=false`.
