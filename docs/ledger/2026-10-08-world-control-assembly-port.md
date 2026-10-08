# World control assembly ownership

## Original rotation, efrag and edge preparation remain traceable

`r_worldcontrolasm.s` owns nine original entries from `r_bsp.c`, `r_efrag.c`
and `r_edge.c`. Rotation, efrag traversal/linking and edge/surface preparation
have separate maintained release/profile include files. Original sources,
function hashes, eighteen instruction variants and 55 compile-time layout
facts are in `renderer-assembly/world-control-provenance.json` and its
`world-control-reference` directory. Normal builds assemble these files without
regenerating them from C.

`R_EntityRotate` preserves aliased input/output by copying the source vector.
`R_RotateBmodel` retains the original yaw/pitch/roll composition, x87 stores,
camera/model-vector updates and real frustum transformation. Its eight-entry
cache uses the original entity-pointer slot, frame stamp and collision rules;
lifted cache arrays remain shared data. Efrag routines preserve solid-leaf
rejection, first-split tracking, visible-leaf rules, free-list depletion and
entity/leaf chain ordering. Culled polygon dispatch retains original forward
or reverse order, clip flags and span/background exclusions. Edge-frame setup
clears only the original active scanline range and publishes the same cursors,
background key and span-generation function pointer.

Normal `dos-bench-20261008-072341` and profiling
`dos-bench-20261008-073751` each pass 11,648 exact cases under twelve x87
settings, 8,192 continuous calls and 144 guard checks. Coverage includes
aliased rotations, 648 cache hits and 648 misses per variant, cache collisions,
frame wrap, axial/nonaxial planes, solid/open/water leaves, balanced and deep
BSP trees, exhausted efrag storage, foreign chain links, large bounds, both
polygon orders and partial scanline clearing. Full state, typed dispatch,
immutable inputs and preserved registers match the original C oracle. The
cache persists through its sequence; other world inputs are reauthored for
defined cases. Both executed fixtures have retained immutable binary proofs.

## World ISA and exact scenes pass before reviewed integration

The nine release entries are assembly-owned. Each release, benchmark and
profiling module audit decodes 821 i386 instructions with zero unknowns,
exemptions or post-486 instructions. Full gates pass 169,310 release, 238,481
benchmark and 243,924 profiling instructions, with required runtime/startup/
provider checks. All 36 preceding assembly objects retain identical allocated
bytes and normalized relocations. The ownership inventory still reports
thirteen reachable C renderer entries in this independent parent snapshot,
including the separately tested alias pipeline; it is not complete ownership.

`WorldControlImplementation` defaults to C. The accepted pair is
`out/world-control-worktree-20261008/out/render-parity-world-control-verified-selection-20261008-2`.
It passes 6,058 deterministic frame checksums and six exact 320-by-200
indexed framebuffers with all 768 palette bytes, across three scenes and two
runs. Both profiles are bound to source tree
`8B9C5663179ED4F0B96E4F6A9975201A446D18CF9E4742AE7A9EAD750D9B029B`.
Each run retains the executed binary, manifest, complete linked ISA report,
relocated mapping, startup proof and verified provider. No unexplained output
difference remains in this cohort.

Secondary timing has no material regression: demo2 measures 12.70820 versus
12.70813 FPS and demo3 11.93190 versus 11.93176 FPS. Candidate demo1's first
run is a timing outlier, 77.623751 seconds versus 77.160546 on its second
run and 77.160095/77.160085 for the reference. Both candidate outputs are
exact. This roughly 0.6-percent timing spread is retained rather than used
to rewrite correct assembly; the second candidate run matches reference
timing closely.

The initial pair failed before guest execution when the original PAK reached
NTFS's 1,024-hardlink limit. A separately copied PAK pair with exact original
hashes supplied the accepted run. The failed staging artifacts remain available.
The direct normal-run wrapper initially misread a stale host native exit code;
its actual guest result and report were PASS, and the wrapper is corrected.
The integration preserves independently accepted alias changes through reviewed
three-way merges. Complete renderer ownership, the combined profile and long
full-frame sequences remain separate completion gates.
