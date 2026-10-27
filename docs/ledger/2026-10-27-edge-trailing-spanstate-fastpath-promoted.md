# Bypass backward trailing-edge calls on non-transition spans (2026-10-27)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete linked i486 ISA gate.

`R_GenerateSpansBackward_asm486` now decrements `st_spanstate` at the call site. When the resulting state is nonzero, it skips the helper call, argument pushes, and helper register saves. When the decrement reaches zero, the caller restores the state and invokes the existing helper, which performs the decrement and all transition side effects exactly as before.

## Matched timedemo

Control and candidate used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and the pinned 32 MB profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Mean FPS |
|---|---|---|---:|
| Current-worktree control parity screen | `out/trailing-edge-validation-20261027/control-parity.json` | 16.194887 / 16.194890 / 16.194897 | 16.194891333 |
| Candidate parity screen | `out/trailing-edge-validation-20261027/candidate-parity.json` | 16.194899 / 16.194906 / 16.194898 | 16.194901000 |
| Candidate strict run | `out/trailing-edge-validation-20261027/candidate-strict.json` | 16.194898 / 16.194906 / 16.194906 | 16.194903333 |

The strict candidate gained **0.000012 FPS (+0.0000741%)** over control. Every run rendered 969 frames with framebuffer checksum `1047377823`.

## i486 proof

The complete strict gate passed with 314,280 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt instructions. It verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. Compact reports are retained under `out/trailing-edge-validation-20261027`; large instruction dumps were omitted.

The candidate source-tree fingerprint was `FF2F232F00EBC52CDA887D9E731720AE15F3F3B6326D87985E134F83D2B1D1C5`.
