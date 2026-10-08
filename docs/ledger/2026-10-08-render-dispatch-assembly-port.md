# Renderer dispatch assembly ownership

## Calling behavior and direct tests

`src/r_renderdispatchasm.s` replaces twelve original public/control adapters:
four sprite entries, alias view-matrix setup, public/helper light marking,
dynamic-light dispatch, world/brush gradients, face dispatch and particles.
Typed outgoing arguments, private canonical matrix storage, x87 time conversion,
profiling counters and phase order retain the pinned original algorithms.
Twenty-four layout assertions fail compilation when shared structures drift.
Original files and function hashes are recorded in
`docs/renderer-assembly/render-dispatch-provenance.json`. Normal builds assemble
the maintained source; independent C adapters are compiled only for testing.

Normal and profiling fixtures each passed 26,624 comparisons under twelve x87
settings, including 8,192 sequence calls, immutable descriptors, counter wrap,
register/stack preservation and nineteen negative detector checks. Evidence:
`out/dispatch-worktree-20261008/out/dos-bench-20261007-225246` and
`dos-bench-20261007-225729`. Mixed selection passed four active entries and
14,336 cases in `dos-bench-20261007-233107`.
The existing public-entry profiling fixture also passed 6,144 exact line-counter
cases and 6,144 hook calls, plus the previously accepted kernel fixtures, in
`dos-bench-20261007-225846`.

The isolated strict audit decoded 242 normal-test, 278 profiling-test and 109
release instructions in the new module: every instruction is i386-compatible,
with zero post-486 instructions, unknowns or instruction exemptions. Six C
support objects also passed source-bound strict inspection: 49,108 instructions,
zero unknowns and zero exemptions. Diagnostic pointer tables in `host_cmd.c`
now reside in `.data`; its compiler jump tables are disabled. Reassembly proves
their code/data boundaries without an opcode waiver.

## Dispatch scene acceptance and reviewed integration

The actual-selector pair passed three scenes twice per profile. All 6,058
post-warmup frame checksums and six indexed framebuffers, including every palette
byte, match exactly. The six leading checksums follow the existing startup
contract. Evidence is retained in
`out/dispatch-worktree-20261008/out/render-parity-dispatch-verified-selection-20261008`.
Source tree SHA256:
`A8669133F88A68338C462002A0DF238A23BF2E6606B9B010942AC3DF609BDA95`.
The reference and candidate executable SHA256 values are
`DBE5F081D7B1A0F5F43FAD510A371AA3D3222F5F3E0F77B51297BB668E23B587` and
`C36063B4BDFCBF713929B707B1892600D5EF498FF0797AA6093E6DC3BAC692E7`.
`accepted-artifacts.json` indexes executable, manifest and linked-proof snapshots
verified against the actual execution bindings before copying.

| Scene | C dispatch FPS | Assembly dispatch FPS |
|---|---:|---:|
| demo1-vga-full | 12.5538410 | 12.5559605 |
| demo2-entity-workload | 12.7062550 | 12.7082490 |
| demo3-world-workload | 11.9304890 | 11.9319340 |

These measurements show no material regression. A separate instrumented demo2
run completed all 985 frames with checksum 1887495667 and zero profiler stack
overflows or bad leaves. Its legacy turbulent-time scalar is negative and must
be corrected before relying on that scalar for stage regression measurements;
the normal paired frame timings above remain valid. That diagnostic run is
retained in `out/dispatch-worktree-20261008/out/dos-timedemo-20261007-233126`.

The negative scalar was subsequently corrected and accepted with exact
instrumented stream and capture comparison; see the
[timer correction](2026-10-08-turbulent-profile-timer.md).

Release inspection proves all twelve entries are assembly-owned and all 31
preceding assembly modules retain identical allocated bytes and normalized
relocations. Integration records an explicit allowlist and preimages in
`out/dispatch-integration-preimages-20261008/manifest.json`.
`RenderDispatchImplementation` defaults to C; the complete candidate profile
selects assembly. The resulting inventory has 36 reachable C renderer routines;
indirect targets and compiler clones still require separate closure review.
Full renderer ownership, provider ISA verification and full-frame soak/gameplay
acceptance remain outstanding.
