# QuakeC statement-store elision promoted (2026-11-13)

## Change

`PR_ExecuteProgram` no longer stores the current statement index to
`pr_xstatement` on every VM instruction. The global is refreshed when tracing
prints a statement, before a function or builtin call saves its caller site,
and before error paths or `PR_LeaveFunction` can consume it. This retains the
statement number used by stack traces, error reporting, and nested-call
bookkeeping while removing one global memory write from the common instruction
path.

The exact-positive-zero static-physics dispatch optimization is present in both
variants; this experiment changes only the QuakeC statement update.

## Profile basis

The 320x200 local-gameplay profile assigned corrected exclusive self time of
1.96 ms/frame to QuakeC on e1m1 and 2.83 ms/frame on e1m2 (4.28-5.65% of the
corrected frame scopes). This scope includes AI and other QuakeC game logic. It
is a measured secondary cost after rendering, collision, and server physics,
not evidence that AI alone occupies this share. The profile and its
instrumentation limits are recorded in
[`ENGINE-PROFILING-20261113.md`](../../../benchmarks/docs/ENGINE-PROFILING-20261113.md).

## Correctness and matched timing

Three alternating uninstrumented qbench pairs per map used DOSBox-X 2026.08.31,
`cputype=486`, FPU 387, 33,445 fixed cycles, 320x200, 64 warm-up frames, and 256
measured local-game frames with a 0.0625-second simulation step:

| Map / pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| e1m1 / 1 | 10.811644 / 23.678174 | 10.805390 / 23.691880 |
| e1m1 / 2 | 10.811643 / 23.678176 | 10.805394 / 23.691871 |
| e1m1 / 3 | 10.811633 / 23.678200 | 10.805396 / 23.691867 |
| e1m2 / 1 | 11.614758 / 22.040925 | 11.607127 / 22.055415 |
| e1m2 / 2 | 11.614754 / 22.040931 | 11.607126 / 22.055416 |
| e1m2 / 3 | 11.614751 / 22.040937 | 11.607133 / 22.055403 |

All runs matched these final checksums exactly:

| Map | Simulation checksum | Framebuffer checksum |
| --- | ---: | ---: |
| e1m1 | 2568184557 | 1299435123 |
| e1m2 | 1496920581 | 1246513233 |

Pooled FPS improved **0.05781%** on e1m1 and **0.06570%** on e1m2. Across
1,536 measured frames, pooled FPS rose from **22.830242** to **22.844372**
(**+0.06190%**). Each sample was faster and the timing spread was below the
gain. The candidate is retained under the project rule accepting any positive
mean after three matched runs per variant.

The twelve pinned result records are
[`baseline e1m1`](../../../benchmarks/out/vm-statement-store-match-baseline-e1m1-1.json),
[`candidate e1m1`](../../../benchmarks/out/vm-statement-store-match-candidate-e1m1-1.json),
[`baseline e1m2`](../../../benchmarks/out/vm-statement-store-match-baseline-e1m2-1.json),
and [`candidate e1m2`](../../../benchmarks/out/vm-statement-store-match-candidate-e1m2-1.json),
with pairs 2 and 3 in files using the corresponding `-2` and `-3` suffixes.

## i486 build evidence

The source-bound control and candidate qbench builds passed the complete strict
i486 gate with zero above-i486, unknown, or exempt instructions. The control
linked 317,517 instructions; the candidate linked 317,525. Their executable
SHA-256 values are `273988CE1E4DD532142618696E117DACAFB8C0727A7035CF79A69192306068C4`
and `74A3BED72619DB8412BFAD959AB8A77A917126C2B2005999BBF58BEA19CDAAE7`,
respectively. The qbench source-tree fingerprints were
`5EABE041FF239B3BC15C26C659EFA69CF0B2DEC30A1F67FB528A3AEC0AE4367F`
(control) and
`DCEA9DD46380298BE53135B3842622E315E22A096197785B97EFFE67BDF7D65B`
(candidate).

A release build of the retained code also passed the complete strict i486 gate:
165,097 linked instructions, 529 startup rows, and 9,207 DPMI-provider
instructions were verified, with zero exemptions and no instruction above
i486. DOSBox-X timing is emulator evidence and does not establish performance
on physical 486 hardware.

## Limits

This is a small measured gain and does not change the engine-wide ranking:
renderer work still dominates timedemos and most of local gameplay. The change
does not access the depth buffer; exact simulation and framebuffer checksums
show no visible or gameplay divergence in these captures. The profiling and
timing do not measure physical L1 misses, AGI stalls, or real-486 cycle counts.
