# Surface-cache hit pointer in EBX, current-source recheck (2026-10-30)

Status: retained after a positive three-run 320x200 comparison, exact fixed-step
frame-checksum and capture parity, a passing golden-image comparison, and the
complete linked i486 ISA gate.

## Candidate

In `D_CacheSurface` (`src/asm486_experiments.s`), keep the surface-cache pointer
in callee-saved `%ebx` while checking hit keys. This removes the unconditional
stack spill and the hit-path reload. On a miss, spill the pointer to the
existing local and restore the mip level from the original argument before
continuing through cache rebuild. The change affects the active i486 assembly
renderer only.

This is a current-source recheck of the register schedule tested in the
[2026-10-29 rejection](2026-10-29-surface-cache-hit-cache-register-rejected.md).
That earlier build lost with a large outlier. The 2026-10-30 control and
candidate were built from the current source state and differed only in this
schedule; the earlier result remains historical evidence for its older
baseline.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, the `cputype=486` profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and the aggressive i486 selector profile.

| Variant | Source-tree fingerprint | FPS samples | Mean FPS |
|---|---|---|---:|
| Control | `854ECA64246C18FAED41A1D981A57079C420A2B0FC21F3540FC2973029EF5FE7` | 16.328156 / 16.328166 / 16.328156 | 16.328159333 |
| EBX pointer | `FD83991C2451D64C6B7579499791395270C3B7C213213F420E4B606BBCBE614D` | 16.328477 / 16.328473 / 16.328474 | 16.328474667 |

The candidate gained **0.000315333 FPS (+0.0019312%)**. All six runs rendered
969 frames and ended with framebuffer checksum `1047377823`; recorded particle
and damage event traces also matched.

Control: `out/dos-timedemo-20261030-151117/timedemo-result.json`.
Candidate: `out/dos-timedemo-20261030-162411/timedemo-result.json`.

## Fixed-step and image parity

The control capture in `out/dos-timedemo-20261030-152629` and candidate capture
in `out/dos-timedemo-20261030-163555` have identical 970-record per-frame
checksum streams. Their frame-169 PCX captures are byte-identical (SHA-256
`D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96`). The
candidate frame also passes the committed 320x200 `demo1-vga-full` golden
comparison: 12 of 64,000 pixels differ, mean absolute channel error `0.0009375`,
within tolerance. The diff has no horizontal-line artifact.

Control stream: `out/dos-timedemo-20261030-152629/runs/run-01/framechecksums.txt`.
Candidate stream: `out/dos-timedemo-20261030-163555/runs/run-01/framechecksums.txt`.
Candidate image comparison: `out/dos-timedemo-20261030-163555/runs/run-01/surface-cache-ebx-vs-golden.json`.

## Genuine-486 instruction gate

The candidate QBench executable passed the full linked i486 audit: 314,303
relocated instructions, 529 startup instructions, and 9,207 CWSDPMI provider
instructions; zero above-i486, unknown, or exempt instructions. The timedemo
result records `isaAuditStatus=PASS`.

The gain is small, but it is positive under the current three-run acceptance
rule and survives full per-frame parity. Retain the register schedule for this
current source baseline; do not infer a corresponding physical-486 percentage
from DOSBox-X timing.
