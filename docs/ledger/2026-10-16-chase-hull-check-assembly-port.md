# BSP hull recursion in i486 assembly (2026-10-16)

## Function and selection boundary

The chase-camera path and general entity/world traces use the same
`SV_RecursiveHullCheck_asm486` implementation. `HullCheckImplementation=c|asm`
selects the `SV_ClipMoveToEntity` trace path independently of
`ChaseImplementation`; the current i486 profile selects assembly, while the
C-reference profile selects the original C routine. The implementation is in
`src/sv_hullcheck_asm.inc`, included with either selector in
`src/asm486_experiments.s`. In the fully selected release profile the C body is
omitted; BENCH builds retain it as the parity oracle.

The new body preserves the compiler-scheduled i486/387 instruction and
recursive argument order. It calls the existing assembly
`SV_HullPointContents` implementation from `src/worlda.s`. Layout assertions
in `src/asm_hullcheck.h` pin the hull, clipnode, plane, and trace fields used by
the body. In `PROFILE486` builds, each assembly recursion also updates the same
hull-check counter as the C routine.

The `PROFILE486` branch compiled successfully in the instrumented `qprof.exe`
build. That compile used `-SkipIsaAudit`, so it verifies assembly preprocessing
and linking but makes no profile-executable ISA claim or runtime counter claim.

The chase-call fixture preserves the original `0` and `1` float argument stack
bits. Its C side selects `SV_RecursiveHullCheck`; its assembly side selects
`SV_RecursiveHullCheck_asm486`, while comparing destination, trace state,
clamping, ABI, x87 behavior, and guards. A separate entity/world trace fixture
calls `SV_ClipMoveToEntity` through both dispatch choices for box and brush
hulls, compares the complete returned trace, checks guard sentinels, and
requires the assembly entry counter to advance.

## Exact parity fixture

The focused DOSBox-X chase fixture passed 14,336 exact cases with twelve x87
precision/rounding control words, 8,192 continuous sequence calls, and 48 guard
checks. No output, state, ABI, x87, or guard differences were reported. The
retained result is
`out/dos-bench-20261016-063949/bench-result.json`.

## i486 executable gate

The `HullCheckOnly` BENCH build passed source-bound verification for 151 exact
project objects and verified 386 installed runtime objects. The project-object
ISA audit covered 241,875 instructions; linked-object and final-executable
audits covered 280,172 instructions each. Startup mapping covered 529 code
rows and the provider audit covered 9,207 instructions. All reported zero
above-i486 instructions, unknown encodings, and exemptions. The complete gate
passed. Its runtime fixture result is
`out/dos-bench-20261016-072957/bench-result.json`.

The non-BENCH i486 release also passed its strict gate. Its project-object
audit covered 129,582 instructions; linked-object and executable audits covered
167,879 instructions across 386 objects and 394 executable text ranges. Startup
and provider checks again covered 529 rows and 9,207 instructions, with zero
above-i486 instructions, unknown encodings, or exemptions. The complete gate
passed, and `world.obj` contains `_SV_RecursiveHullCheck_asm486` without the C
`_SV_RecursiveHullCheck` body. `tools/guard-i486-release.py` now passes for 151
objects plus `quake.exe`.

These focused fixtures are correctness runs, not timedemos. They do not claim
an FPS or hull-routine timing result. Full gameplay and visual-scene acceptance
remain separate gates.

## Reproduction

```powershell
rtk proxy pwsh -NoProfile -File tools/bench-dos.ps1 -ChaseOnly -NoBootstrap
rtk proxy pwsh -NoProfile -File tools/bench-dos.ps1 -HullCheckOnly -NoBootstrap
```
