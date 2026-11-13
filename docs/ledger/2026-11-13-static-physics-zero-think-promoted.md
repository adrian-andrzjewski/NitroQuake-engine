# Static physics no-think dispatch skip promoted (2026-11-13)

## Change

In `SV_Physics`, `MOVETYPE_NONE` entities with `nextthink` represented by the
exact positive-zero bit pattern now skip `SV_Physics_None`. A local union reads
the field as an integer, avoiding the x87 `ftst` and status-word transfer in
the otherwise no-op `SV_RunThink` path. This is deliberately narrower than
`nextthink <= 0`: negative values, negative zero, scheduled values, and NaNs
continue through the existing function. The `force_retouch` handling still
runs before movement dispatch, and the loop increment still processes the next
entity.

`SV_Physics_None` has no behavior beyond calling `SV_RunThink`; that helper
returns immediately for positive zero before changing entity or VM state. The
skip therefore removes only work that cannot change output or depth/occlusion
state.

## Profile basis

The detailed 320x200 profile called the no-op branch 21,760 times in 256 e1m1
frames (85 calls/frame) and 31,744 times in e1m2 (124 calls/frame). It reported
0.162 / 0.236 seconds of exclusive self time. The calibrated profiler read
floor was 5.779 microseconds for each of these calls, accounting for 77.6% of
the self window. The residual profile estimate is only 0.141 / 0.206 ms/frame
and is affected by instrumentation code layout. This made the branch worth a
low-risk timing probe, but ranked it well below rendering, collision, and
QuakeC work. The detailed profile source-tree fingerprint was
`8AD0FA0F5D20A429FDCCD60FF2CBD71CDE5E4136E71E6F4B621EBAB94E338E13`.

## Correctness and matched timing

Control and candidate used DOSBox-X 2026.08.31 at `cputype=486`, FPU 387,
33,445 fixed cycles, 320x200, a 0.0625-second fixed simulation step, 64 warm-up
frames, and 256 measured frames. Three pairs per map alternated variant order.
The candidate won every pair:

| Map / pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| e1m1 / 1 | 10.814242 / 23.672488 | 10.811633 / 23.678200 |
| e1m1 / 2 | 10.814247 / 23.672477 | 10.811650 / 23.678162 |
| e1m1 / 3 | 10.814255 / 23.672458 | 10.811649 / 23.678163 |
| e1m2 / 1 | 11.618538 / 22.033754 | 11.614755 / 22.040929 |
| e1m2 / 2 | 11.618540 / 22.033749 | 11.614746 / 22.040947 |
| e1m2 / 3 | 11.618549 / 22.033732 | 11.614751 / 22.040937 |

All final-state simulation and framebuffer checksums matched:

| Map | Simulation checksum | Framebuffer checksum |
| --- | ---: | ---: |
| e1m1 | 2568184557 | 1299435123 |
| e1m2 | 1496920581 | 1246513233 |

The mean FPS change was **+0.024081%** on e1m1 and **+0.032644%** on e1m2.
Across all 1,536 measured frames, pooled FPS rose from **22.823732** to
**22.830241 (+0.028518%)**. The gain is small but repeatable under this pinned
emulator workload, so the candidate is retained.

## i486 build and acceptance

The final release and qbench builds passed the complete i486 gates. Release
linked 165,089 instructions; qbench linked 317,517. Both also passed the 529
startup-row and 9,207-instruction DPMI-provider audits with zero above-i486,
unknown, or exempt instructions. The qbench executable used for the candidate
has SHA-256
`B9A0803A4FE673DBBA2E118C8C8BDFC2329E8D2E28A525836B79F143C81C901E`.
The control qbench SHA-256 is
`FD9B92ED7F6DDB0EECE4A2B7F830C7357C2CC8B1E9197F8CD241ED66497F9ED5`; the
release executable SHA-256 is
`9AC8A2B8D71864406B2FC0E1662E6A2249D71C233B9558786A42828B1DA93CFD`.
The control and candidate source-tree fingerprints were
`8AD0FA0F5D20A429FDCCD60FF2CBD71CDE5E4136E71E6F4B621EBAB94E338E13` and
`B18492AD3A5E669C5D8306A5F3AE6C70F7B172B724F014844A520F73296DE5C3`.

## Limits

This is a DOSBox-X timing result, not a physical 486 cycle measurement. The
guard's measured whole-frame value is below one tenth of one percent, so it is
a small cleanup rather than a leading optimization target. The broader ranked
profile and retained benchmark artifacts are in
[`ENGINE-PROFILING-20261113.md`](../../../benchmarks/docs/ENGINE-PROFILING-20261113.md).
