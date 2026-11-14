# `R_ClipEdgeRegs` EBX save elimination rejected (2026-11-12)

<!-- optimization-attempt: r-clipedge-ebx-save-elimination rejected -->

## Candidate

The accepted stack-base-hoisted `R_ClipEdgeRegs` still pushed and popped EBX
for every clipped edge. The candidate replaced that private entry's `pushl
%ebx` with a four-byte stack reservation, leaving the shared `popl %ebx` to
consume the unused slot. Both `R_RenderFace_asm486` callers then reloaded
`r_pcurrentvertbase` after each call. The public cdecl `R_ClipEdge` entry was
unchanged. Relative to the active source snapshot, the candidate delta was
limited to `src/renderer/r_drawa.s` and `src/renderer/asm486_experiments.s`.

### Exact rendering and i486 compatibility

Control and candidate used the same `demo1` workload, data, selectors, and
pinned DOSBox-X 2026.08.31 486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Each
completed 969 timed frames and ended at framebuffer checksum `1047377823`.
All 970 recorded color and Z checksum entries and the captured 320x200
frame-169 PCX matched byte-for-byte:

| Artifact | SHA-256 |
| --- | --- |
| Color checksum stream | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksum stream | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 169 PCX | `28E8D79CE925D4ACA40EF1EC56B21292A624CF814C809A8E8E826A0D89CE1C01` |

The candidate release and qbench builds passed the complete source-bound
strict i486 gate. Release audited 165,084 relocated instructions; qbench
audited 317,498. Both reported zero above-i486, unknown, or exempt
instructions, and passed the 529-row startup and 9,207-instruction DPMI
provider proofs. The fresh control qbench also passed the gate with 317,499
relocated instructions.

### Matched timing

Three alternating uninstrumented `demo1` pairs used one run per invocation.
Frame checksums, Z checksums, FPS instrumentation, and profiling were disabled
during timing. Every timing run passed the final framebuffer checksum gate.

| Pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| 1 | 57.240532 / 16.928564 | 57.261902 / 16.922246 |
| 2 | 57.240486 / 16.928577 | 57.261900 / 16.922247 |
| 3 | 57.240471 / 16.928582 | 57.261884 / 16.922252 |

The means were 16.928574333 FPS for control and 16.922248333 FPS for the
candidate, a **-0.0373688%** change. Every candidate sample was slower. The
candidate is rejected under the positive-mean acceptance rule. This is pinned
DOSBox-X evidence, not a physical-486 performance claim.

### Artifacts and disposition

- Control qbench: `out/local-clipedge-ebx-control-qbench-20261112/`
- Candidate release and qbench:
  `D:\NitroQuake-r-clipedge-ebx-clobber-20261112\out\local-clipedge-ebx-candidate-release-20261112\`
  and `...\local-clipedge-ebx-candidate-qbench-20261112\`
- Parity handoffs:
  `benchmarks/out/clipedge-ebx-clobber-control-parity-20261112.json` and
  `benchmarks/out/clipedge-ebx-clobber-candidate-parity-20261112.json`
- Timing handoffs: `benchmarks/out/clipedge-ebx-clobber-{control,candidate}-r{1,2,3}-20261112.json`
- DOSBox-X run directories:
  `benchmarks/out/dos-timedemo-20261112-{160458,161853,162147,162304,162424,162541,162700,162818}/`

The candidate remains in its isolated worktree for review; the active renderer
sources were left unchanged. No commit was created.
