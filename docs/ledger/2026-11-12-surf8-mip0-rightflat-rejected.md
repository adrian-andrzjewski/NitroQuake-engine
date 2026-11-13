# Mip-0 right-flat surface rows rejected (2026-11-12)

<!-- optimization-attempt: surf8-mip0-rightflat rejected -->

## Candidate

The general sixteen-row mip-0 surface body adds lightrightstep to the right
light value and stores the result after every row. For blocks with a zero right
step, the candidate checked the step once per block and dispatched to a second
sixteen-row body that omitted the zero add and same-value store. It retained the
light-delta add that controls the carry loop. The opt-in selector and code stayed
in the isolated D:\NitroQuake-surf8-mip0-rightflat-20261112 worktree.

### Exact output parity

Control and candidate used demo1, the same data and renderer settings, and
DOSBox-X 2026.08.31 with the pinned 320x200 i486 profile
(532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA).
Each completed 969 timed frames and ended at framebuffer checksum
1047377823. All 970 color and Z checksum entries matched byte-for-byte, as
did the captured frame-169 PCX:

| Artifact | SHA-256 |
| --- | --- |
| Color checksum stream | FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C |
| Z checksum stream | 4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37 |
| Frame-169 PCX | 28E8D79CE925D4ACA40EF1EC56B21292A624CF814C809A8E8E826A0D89CE1C01 |

### Strict i486 gates

The control and candidate release builds passed the complete strict gate with
165,085 and 166,347 relocated instructions, respectively. The qbench builds
passed with 317,499 and 318,761 instructions. All four builds reported zero
above-i486, unknown, or exempt instructions and passed the 529-row startup and
9,207-instruction DPMI-provider proofs. The candidate's additional row body
accounts for 1,262 more linked instructions in both profiles.

### Matched timing

Three alternating uninstrumented demo1 pairs used one run per invocation.
Frame checksums, Z checksums, FPS instrumentation, and profiling were disabled
during timing. Every run passed the final framebuffer checksum gate.

| Pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| 1 | 57.240584 / 16.928548 | 57.244401 / 16.927420 |
| 2 | 57.240546 / 16.928559 | 57.244387 / 16.927424 |
| 3 | 57.240555 / 16.928557 | 57.244389 / 16.927423 |

The means were 16.928554667 FPS for control and 16.927422333 FPS for the
candidate, a -0.0066889% change. All three candidate samples were slower,
so this candidate is rejected. This is pinned DOSBox-X evidence, not a
physical-486 performance claim.

### Artifacts and disposition

- Candidate worktree: D:\NitroQuake-surf8-mip0-rightflat-20261112\
- Release builds: out/local-surf8-rflat-rel-control-20261112/ and
  out/local-surf8-rflat-rel-candidate-20261112/
- Qbench builds: out/local-surf8-rflat-qbench-control-20261112/ and
  out/local-surf8-rflat-qbench-candidate-20261112/
- Parity handoffs:
  benchmarks/out/surf8-rflat-control-parity-20261112.json and
  benchmarks/out/surf8-rflat-candidate-parity-20261112.json
- Timing handoffs:
  benchmarks/out/surf8-rflat-{control,candidate}-time-p{1,2,3}-20261112.json
- DOSBox-X run directories:
  benchmarks/out/dos-timedemo-20261112-{172508,173834,174235,174355,174516,174634,174754,174912}/

The candidate remains in its isolated worktree for review. The active renderer
source changes were not modified. Temporary selector plumbing in the benchmark
runner was removed after the experiment. No commit was created.
