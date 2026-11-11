# Mip-0 horizontal-flat surface rows unrolled four at a time promoted (2026-11-11)

## Candidate

`LSurf8Mip0HorizontalFlat` now emits four row bodies per loop iteration. It
keeps the 16 output rows and the order of texture, destination, and row-step
updates, while reducing the stack-counter decrement and branch from 16
iterations to four. The four row copies have distinct colormap patch labels;
`LPatchTable8` registers all 64 copied lookup sites and `R_Surf8Patch` includes
them in its patch count.

The current i486 selectable profile already selects this assembly fast path.
The change adds no selector or runtime policy.

## Exact rendering parity

The candidate passed the committed golden checks for `demo1-vesa-full` and
`demo3-world-workload`. Demo1 retained its known 12 changed pixels against the
golden image, within the committed tolerance; demo3 changed zero pixels.

A fixed-clock control/candidate replay used `host_framerate 0.0783` and
`con_notifytime -1`. All 970 color checksum records and all 970 Z checksum
records matched exactly, including the six startup records. The final timedemo
framebuffer checksum was `1047377823`, with no checksum overflow. The frame-169
PCX captures were byte-identical:

`D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96`

`compare-rendering.py` accepted the complete color stream. Its generic parser
does not accept the Z stream's `frames 970` footer, so the 970 Z records and
footer were checked line-by-line and recorded in `z-parity-raw.json`.

## Strict i486 gate

The Build 869 candidate passed the complete source-bound qbench ISA gate:
316,257 relocated instructions, 529 startup rows, and 9,207 provider
instructions. There were zero above-i486, unknown, or exempt instructions.
The proof covered 403 exact source/runtime objects and 435 linked
contributions. The candidate executable SHA-256 is
`B1E2D23BD43B80D93E6148763ACB008F2C6318DD021E9EB58286801DB51EEC42`.

## Matched timing

Three uninstrumented `demo1` runs per variant used DOSBox-X 2026.08.31, the
pinned 486 profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
969 timed frames, and final checksum `1047377823`:

| Run | Control FPS | Candidate FPS |
| ---: | ---: | ---: |
| 1 | 16.909244 | 16.909644 |
| 2 | 16.909254 | 16.909633 |
| 3 | 16.909254 | 16.909687 |
| Mean | 16.909250667 | 16.909654667 |

The candidate mean improved by `0.000403917` FPS (`+0.0023887%`); all three
candidate samples exceeded all three controls. A trailing control run measured
16.909251 FPS, consistent with the initial control set. The positive mean
meets the current acceptance rule regardless of its magnitude. This is a
DOSBox-X result for this pinned workload, not a physical-486 performance claim.

## Artifacts and scope

- Candidate render validation: `workspace\benchmarks\out\surf8-mip0-flat-unroll4-candidate-20261111\render-validation-result.json`
- Matched timings and exact parity reports: `workspace\benchmarks\out\surf8-mip0-flat-unroll4-timing-20261111\`
- Control qbench SHA-256: `6481B780E9F76C73E0022E00012112A9DD642B2CC2E32B2FAEF57C8EF80AA034`
- Candidate qbench source-tree fingerprint: `DD687BF320FA982259AD077F1269BB289ECEABD5AB69F74B7FFFEB0CAED01C4C`
- Candidate worktree: `D:\NitroQuake-surf8-mip0-flat-unroll4-20261111`
