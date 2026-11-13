# Mip-1 right-flat surface rows rejected (2026-11-12)

<!-- optimization-attempt: surf8-mip1-rightflat rejected -->

## Candidate

The general eight-row MIP1 surface body adds `lightrightstep` to the right
light value and stores the result after every row. For blocks with a zero right
step, the candidate dispatched to a second eight-row body that omitted the zero
add and same-value store. It retained the light-delta add that controls the
carry loop. The opt-in selector and code stayed in the isolated
`D:\NitroQuake-surf8-mip1-rightflat-20261112` worktree.

### Exact output parity

Control and candidate used `demo1`, the same data and renderer settings, and
DOSBox-X 2026.08.31 with the pinned 320x200 i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Each
completed 969 timed frames and ended at framebuffer checksum `1047377823`. All
970 color and Z checksum entries matched byte-for-byte, as did the captured
frame-169 PCX:

| Artifact | SHA-256 |
| --- | --- |
| Color checksum stream | FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C |
| Z checksum stream | 4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37 |
| Frame-169 PCX | 28E8D79CE925D4ACA40EF1EC56B21292A624CF814C809A8E8E826A0D89CE1C01 |

### Strict i486 gates

The control and candidate release builds passed the complete strict gate with
165,085 and 165,423 relocated instructions, respectively. The qbench builds
passed with 317,499 and 317,837 instructions. All four builds reported zero
above-i486, unknown, or exempt instructions and passed the 529-row startup and
9,207-instruction DPMI-provider proofs. The candidate's 64 patch sites account
for 338 additional linked instructions in both profiles.

### Matched timing

Three alternating uninstrumented `demo1` pairs used one run per invocation.
Frame checksums, Z checksums, FPS instrumentation, and profiling were disabled
during timing. Every run passed the final framebuffer checksum gate.

| Pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| 1 | 57.240493 / 16.928575 | 57.248005 / 16.926354 |
| 2 | 57.240551 / 16.928558 | 57.248028 / 16.926347 |
| 3 | 57.240667 / 16.928524 | 57.248042 / 16.926343 |

The means were 16.928552333 FPS for control and 16.926348 FPS for the
candidate, a -0.0130214% change. All three candidate samples were slower,
so this candidate is rejected. This is pinned DOSBox-X evidence, not a
physical-486 performance claim.

### Artifacts and disposition

- Candidate worktree: `D:\NitroQuake-surf8-mip1-rightflat-20261112\`
- Release builds: `out/local-surf8-m1-rflat-rel-{control,candidate}-20261112/`
- Qbench builds: `out/local-surf8-m1-rflat-qbench-{control,candidate}-20261112/`
- Parity handoffs:
  `benchmarks/out/surf8-m1-rflat-{control,candidate}-parity-20261112.json`
- Timing handoffs:
  `benchmarks/out/surf8-m1-rflat-{control,candidate}-time-p{1,2,3}-20261112.json`
- Successful DOSBox-X run directories:
  `benchmarks/out/dos-timedemo-20261112-{182823,184208,184531,184649,184808,184925,185045,185202}/`

The active renderer source changes were not modified. Temporary selector
plumbing in the benchmark runner was removed after the experiment. No commit
was created.
