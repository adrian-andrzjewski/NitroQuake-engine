# R_RenderFace prelinked full-mask chain promoted (2026-11-03)

Status: promoted after a positive three-run uninstrumented 320x200 mean, exact
per-frame checksum and captured-frame parity, and the complete strict i486 gate.

## Optimization

`R_RenderFace_asm486` used to rebuild the four-node `view_clipplanes` chain on
every face whose low clip mask was 15. The assembly `R_TransformFrustum` entry
now copies the four freshly transformed planes to a private
`view_clipplanes_fullmask` array once per frustum update and links that copy in
the same 3-to-0 order. With the assembly frustum transform selected, the full
mask path reuses this stable chain. Partial masks and builds using the C
frustum transform retain the existing chain builder. The right-edge closing
clip also selects the matching tail node from the private chain.

## Benchmark

Control and candidate used DOSBox-X 2026.08.31, `cputype=486`, `fpu=387`, fixed
33,445 cycles, `demo1`, the pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, and
320x200 output. Both used `host_framerate 0.0783` and
`con_notifytime -1`. These timing runs were uninstrumented and did not record
per-frame checksums.

| Variant | FPS samples | Mean FPS | Median FPS | Range |
| --- | --- | ---: | ---: | ---: |
| Control | 16.491694 / 16.491695 / 16.491696 | 16.491695000 | 16.491695 | 0.000002 |
| Prelinked chain | 16.495428 / 16.495431 / 16.495436 | 16.495431667 | 16.495431 | 0.000008 |

The candidate mean increased by **0.003736667 FPS (+0.0226579%)**. Its three
paired runs were faster by 0.003734, 0.003736, and 0.003740 FPS. Every run
rendered 969 frames and ended at checksum `1047377823`; the timedemo event
traces matched.

## Correctness and compatibility

A separate fixed-cadence parity replay recorded 970 per-frame checksums and
captured frame 482. The control and candidate checksum files were byte-identical
(SHA-256 `3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B`),
and their PCX captures were byte-identical (SHA-256
`31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213`).

The candidate passed the source-bound i486 audit: 403 exact object proofs,
314,625 linked instructions, 529 startup instruction rows, and 9,207 DPMI
provider instructions, with zero above-i486, unknown, or exempt instructions.
The parity replay's FPS was about 12.83 for both variants because per-frame
checksum recording adds overhead; those runs are not used in the timing table.
These results are from DOSBox-X and do not establish physical-486 performance.

## Artifacts

- Control timing: `out/dos-timedemo-20261103-192038/timedemo-result.json`
- Candidate timing: `out/worktree-renderface-prelinked-chain-20261103/out/dos-timedemo-20261103-192555/timedemo-result.json`
- Candidate ISA audit: `out/worktree-renderface-prelinked-chain-20261103/out/local-dos-timedemo-renderface-prelinked-parity-20261103/isa-qbench/isa-audit-linked.json`
- Control parity capture: `out/dos-timedemo-20261103-192959/runs/run-01/`
- Candidate parity capture: `out/worktree-renderface-prelinked-chain-20261103/out/dos-timedemo-20261103-142807/runs/run-01/`
