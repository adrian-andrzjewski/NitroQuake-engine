# Assembly BSP frame-count snapshot promoted (2026-11-03)

Status: promoted after a positive three-run uninstrumented 320x200 mean, exact
fixed-step per-frame parity, and the complete strict i486 gate.

## Optimization

`R_RecursiveWorldNode_asm486` used to reload `r_framecount` at every node and
save it in each parent continuation record. The `local` variant now snapshots
the value once at traversal entry. The continuation record shrinks from 28 to
24 bytes, removing the saved frame-count word and its per-child save and restore.
The `control` selector remains available; `local` is now the default in the DOS
build, benchmark, smoke, and timedemo runners.

## Benchmark

Control and candidate used the pinned DOSBox-X 2026.08.31 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, and 320x200 output. Runs had no FPS instrumentation or frame-checksum
recording.

| Variant | FPS samples | Mean FPS | Median FPS | Range |
|---|---|---:|---:|---:|
| Control | 16.349325 / 16.349262 / 16.349264 | 16.349283667 | 16.349264 | 0.000063 |
| Local snapshot | 16.349323 / 16.349265 / 16.349328 | 16.349305333 | 16.349323 | 0.000063 |

The candidate mean increased by **0.000021667 FPS (+0.0001325%)**. Every
included run rendered 969 frames, ended at checksum `1047377823`, and retained
the same timedemo event trace. Other attempts were excluded when Q2 or a CMake
build overlapped, or could not be ruled out at the end of the run.

## Correctness and compatibility

For deterministic parity, both variants were replayed with
`host_framerate 0.0783`. Their 970-record checksum files were byte-identical
(SHA-256
`2AB5336E08A79381D81C23900E933F3D5D709B6F4AE5FC0558C9511C5202D381`).
The checksum-enabled replay runs are instrumented and are not used as timing
results.

The candidate passed the complete source-bound i486 audit: 403 exact installed
object proofs, 314,672 linked instructions, 529 startup instruction rows, and
9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt
instructions. These results qualify the pinned DOSBox-X workload and do not
establish physical-486 performance.

## Artifacts

- Control timing: `out/worktree-bspframeentry-retest-20261103/out/dos-timedemo-20261103-200122/timedemo-result.json`
- Candidate timing: `out/worktree-bspframeentry-retest-20261103/out/dos-timedemo-20261103-203322/timedemo-result.json` (first two clean runs) and `out/worktree-bspframeentry-retest-20261103/out/dos-timedemo-20261103-220007/timedemo-result.json`
- Strict candidate and ISA audit: `out/worktree-bspframeentry-retest-20261103/out/dos-timedemo-20261103-215627/timedemo-result.json` and `out/worktree-bspframeentry-retest-20261103/out/profile-93148481b41cf1f3/isa-qbench/isa-audit-linked.json`
- Fixed-step parity: `out/worktree-bspframeentry-retest-20261103/out/dos-timedemo-20261103-222103/runs/run-01/framechecksums.txt` and `out/worktree-bspframeentry-retest-20261103/out/dos-timedemo-20261103-222256/runs/run-01/framechecksums.txt`
