# R_RenderFace prelinked all-mask clip chains rejected (2026-11-04)

Status: rejected because exact frame parity failed. The strict i486 audit and
matching final checksum do not override the per-frame differences.

## Candidate

The scratch candidate built linked clip-plane chains for the 15 nonempty masks
in `R_BuildRenderFaceClipChains_asm486` and selected a head from
`view_clipplane_mask_heads_asm486` in `R_RenderFace_asm486`. The existing
all-four-plane private chain remained the mask-15 path. The candidate was
isolated in `out/worktree-renderface-maskchains-20261104`; the main renderer
source was not changed.

## Fixed-step parity

Control and candidate used DOSBox-X 2026.08.31, the pinned i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, `demo1`,
320x200 output, `host_framerate 0.0783`, and `con_notifytime -1`. The 970-frame
control stream came from the stable packed-BSP worktree. Both candidate replays
were byte-identical to each other, but differed from control at **436 of 970
frame records**, beginning at frame 2 and continuing through frame 948. The
candidate and control both ended at framebuffer checksum `1047377823`.

The captured frame 695 differs: control is 65,161 bytes with SHA-256
`4F00A71AB1F11B53AFC83984D07A0CAA44F354245B029AC06471B7E97705642F`; candidate
is 65,168 bytes with SHA-256
`BC9A0C6E6FB6A4436DA9FDF59595385D475692B4B344DB0D8269D69D779555D5`.

## Timing disposition

Two candidate-only uninstrumented three-run groups reported median FPS values
of **16.355623** and **16.355634**. Both groups passed the strict i486 audit,
but these timings are invalid for promotion because the candidate failed exact
per-frame parity. No speed claim is retained.

## Artifacts

- Control replay: `out/worktree-bsp-state-pack-20261103/out/dos-timedemo-20261104-064004/`
- Candidate replay: `out/worktree-renderface-maskchains-20261104/out/dos-timedemo-20261104-014415/`
- Candidate timing groups: `out/worktree-renderface-maskchains-20261104/out/dos-timedemo-20261104-015542/timedemo-result.json` and `out/worktree-renderface-maskchains-20261104/out/dos-timedemo-20261104-020353/timedemo-result.json`
