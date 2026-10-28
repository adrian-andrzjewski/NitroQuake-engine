# `R_GenerateSpans` leading-edge `insubmodel` direct compare promoted (2026-10-28)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete executable i486 ISA gate.

The leading-edge bmodel dispatch now uses `cmpl $0,st_insubmodel(%edi)` in place of `movl st_insubmodel(%edi),%eax` plus `testl %eax,%eax`. The loaded value was used only for the dispatch condition.

## Matched timedemo

Control and candidate used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and the pinned 32 MB profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Mean FPS |
|---|---|---|---:|
| Strict control | `out/dos-timedemo-20261028-204019/timedemo-result.json` | 16.241862 / 16.241913 / 16.241886 | 16.241887 |
| Candidate parity screen | `out/dos-timedemo-20261028-214920/timedemo-result.json` | 16.261939 / 16.261886 / 16.261884 | 16.261903 |
| Strict candidate | `out/dos-timedemo-20261028-221459/timedemo-result.json` | 16.261924 / 16.261889 / 16.261874 | 16.261895667 |

The strict candidate gained **0.020008667 FPS (+0.1232%)** over control. Every run rendered 969 frames with framebuffer checksum `1047377823`.

## i486 proof

The complete executable gate passed with 314,228 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt instructions. It verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. Compact reports are retained under `out/local-local-edge-insubmodel-directcmp-strict-20261028`; large instruction dumps were omitted.

The candidate source-tree fingerprint was `1CF2A2F91EA4B5641C21BAFAA21C831F1F494AE27CCAF63F29E306AED75A119C`.
