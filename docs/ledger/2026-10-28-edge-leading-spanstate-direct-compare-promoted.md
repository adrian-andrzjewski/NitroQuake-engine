# `R_GenerateSpans` leading-edge spanstate direct compare promoted (2026-10-28)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete executable i486 ISA gate.

The leading-edge path no longer loads `st_spanstate(%edi)` into `%edx`. After the bmodel dispatch, both the non-bmodel and bmodel paths compare the field directly with zero. The inverted-span exit uses `incl st_spanstate(%edi)` to preserve C's `++surf->spanstate`; the normal path stores one directly after proving the value was zero.

## Matched timedemo

Control and candidate used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and the pinned 32 MB profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Mean FPS |
|---|---|---|---:|
| Strict control | `out/dos-timedemo-20261028-221459/timedemo-result.json` | 16.261924 / 16.261889 / 16.261874 | 16.261895667 |
| Candidate parity screen | `out/dos-timedemo-20261028-222427/timedemo-result.json` | 16.281858 / 16.281852 / 16.281844 | 16.281851333 |
| Strict candidate | `out/dos-timedemo-20261028-225203/timedemo-result.json` | 16.281855 / 16.281848 / 16.281857 | 16.281853333 |

The strict candidate gained **0.019957666 FPS (+0.1227%)** over control. Every run rendered 969 frames with framebuffer checksum `1047377823`.

## i486 proof

The complete executable gate passed with 314,225 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt instructions. It verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. Compact reports are retained under `out/local-local-edge-spanstate-directcmp-strict-20261028`; large instruction dumps were omitted.

The candidate source-tree fingerprint was `199B63AD46C8C312BC49865B6484E02D0B6EB228D0A4A70BB2EB307F3E2A93DF`.
