# `surf8` mip-0 row lightdelta stack spill promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete executable i486 ISA gate.

In the `SURF8_MIP0_ROW` macro, the unshifted `%ebp` light delta is now saved with `pushl %ebp` and restored with `popl %ebp`. This replaces the absolute `C(lightdelta)` store and reload while preserving the delta recurrence and EFLAGS.

## Matched timedemo

Control and candidate used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and the pinned 32 MB profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Fresh strict control | `out/dos-timedemo-20261029-010107/timedemo-result.json` | 16.304907 / 16.304891 / 16.304905 | 0.000016 | 16.304901 |
| Candidate parity screen | `out/dos-timedemo-20261029-011214/timedemo-result.json` | 16.304927 / 16.304893 / 16.304894 | 0.000034 | 16.304904667 |
| Strict candidate | `out/dos-timedemo-20261029-013713/timedemo-result.json` | 16.304935 / 16.304928 / 16.304903 | 0.000032 | 16.304922 |

The strict candidate gained **0.000021 FPS (+0.0001288%)** over the fresh strict control. Every control, screen, and strict candidate run rendered 969 frames with framebuffer checksum `1047377823`.

## i486 proof

The complete executable gate passed with 314,222 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt instructions. It verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. Compact reports are retained under `out/profile-107ff6406936b458`.

The candidate source-tree fingerprint was `26EB8E75B78B8F73367D81945237E245ACE1A31BFE5E6DEFFBE99DB29A56F209`.

## Focused surface-draw harness

`bench-dos.ps1 -SurfaceDrawOnly` did not emit its required correctness PASS on either the stack-spill candidate (`out/dos-bench-20261029-014424/quake/bench486.txt`) or the original-spill baseline (`out/dos-bench-20261029-014808/quake/bench486.txt`); both reports stop after the startup banner. This harness failure is present on both variants and provides no comparative parity result. Promotion is based on the matched timedemo checksum and complete strict i486 gate above.
