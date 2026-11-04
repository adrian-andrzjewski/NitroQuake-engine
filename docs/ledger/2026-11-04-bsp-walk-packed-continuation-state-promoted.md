# Assembly BSP walker packed continuation state promoted (2026-11-04)

Status: promoted after a positive three-run uninstrumented 320x200 mean, exact
fixed-step per-frame parity, and the complete strict i486 gate.

## Optimization

The local-frame-count assembly BSP walker stored the parent node, clip flags,
double plane dot, side, and traversal stage in a 24-byte continuation record.
The `local` variant now packs side and resume phase into one state word at offset
16. Values 2/3 mean the front child is pending; values 4/5 mean the back child
is pending. The saved record is 20 bytes. Child visit order is unchanged.

## Benchmark

Control and candidate used DOSBox-X 2026.08.31 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, 320x200 output, `BspWalk=asm`, and `BspFrameCount=local`. Both timing
groups were uninstrumented and ran without a concurrent Q2 DOSBox-X workload.

| Variant | FPS samples | Mean FPS | Median FPS | Range |
|---|---|---:|---:|---:|
| Control, 24-byte record | 16.365730 / 16.365648 / 16.365669 | 16.365682333 | 16.365669 | 0.000082 |
| Packed, 20-byte record | 16.365734 / 16.365669 / 16.365677 | 16.365693333 | 16.365677 | 0.000065 |

The candidate mean increased by **0.000011 FPS (+0.0000672%)**. This delta is
smaller than both sample ranges; the current acceptance rule explicitly allows
any positive mean from three matched runs when parity and the strict ISA gate
pass. Each of the six runs rendered 969 frames, ended at checksum `1047377823`,
and recorded the same timedemo event trace.

## Correctness and compatibility

Fixed-step replays used `host_framerate 0.0783`. Their 970-record
`framechecksums.txt` files were byte-identical (SHA-256
`2AB5336E08A79381D81C23900E933F3D5D709B6F4AE5FC0558C9511C5202D381`). The
checksum-enabled replays are instrumented and are not timing results.

The candidate passed the complete source-bound i486 audit: 403 exact installed
object proofs, 314,639 linked instructions, 529 startup instruction rows, and
9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt
instructions. The fresh uncompressed control rebuild passed the same gate with
314,638 linked instructions and zero exemptions.

## Artifacts

- Candidate timing: `out/worktree-bsp-state-pack-20261103/out/dos-timedemo-20261103-232407/timedemo-result.json`
- Control timing: `out/worktree-bspframeentry-retest-20261103/out/dos-timedemo-20261103-234120/timedemo-result.json`
- Candidate fixed-step parity: `out/worktree-bsp-state-pack-20261103/out/dos-timedemo-20261103-231440/runs/run-01/framechecksums.txt`
- Control fixed-step parity: `out/worktree-bspframeentry-retest-20261103/out/dos-timedemo-20261103-222256/runs/run-01/framechecksums.txt`
