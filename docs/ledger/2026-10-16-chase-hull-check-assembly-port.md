# Chase BSP hull recursion in i486 assembly (2026-10-16)

## Function and selection boundary

The assembly chase-camera path now calls `SV_RecursiveHullCheck_asm486` for
its BSP collision trace. The implementation is in
`src/sv_hullcheck_asm.inc`, included with `ASM486_CHASE` in
`src/asm486_experiments.s`. The C implementation in `src/world.c` remains the
reference and continues to serve non-assembly callers; this change does not
redirect general entity movement or server world traces.

The new body preserves the compiler-scheduled i486/387 instruction and
recursive argument order. It calls the existing assembly
`SV_HullPointContents` implementation from `src/worlda.s`. Layout assertions
in `src/asm_chase.h` pin the hull, clipnode, and plane fields consumed by the
body. In `PROFILE486` builds, each assembly recursion also updates the same
hull-check counter as the C routine.

The `PROFILE486` branch compiled successfully in the instrumented `qprof.exe`
build. That compile used `-SkipIsaAudit`, so it verifies assembly preprocessing
and linking but makes no profile-executable ISA claim or runtime counter claim.

The chase-call fixture preserves the original `0` and `1` float argument stack
bits. Its C side selects `SV_RecursiveHullCheck`; its assembly side selects
`SV_RecursiveHullCheck_asm486`, while comparing destination, trace state,
clamping, ABI, x87 behavior, and guards.

## Exact parity fixture

The focused DOSBox-X chase fixture passed 14,336 exact cases with twelve x87
precision/rounding control words, 8,192 continuous sequence calls, and 48 guard
checks. No output, state, ABI, x87, or guard differences were reported. The
retained result is
`out/dos-bench-20261016-063949/bench-result.json`.

## i486 executable gate

The candidate build passed source-bound verification for 151 exact project
objects and verified 386 installed runtime objects. Its project-object ISA
audit covered 241,603 instructions. Linked-object and final-executable audits
covered 279,900 instructions each; all reported zero instructions above i486,
unknown instructions, or exemptions. Startup mapping covered 529 code rows,
and the provider audit covered 9,207 instructions. The complete executable
gate passed.

This `ChaseOnly` fixture is a correctness run, not a timedemo. No FPS or hull
routine timing was collected. General non-chase hull callers remain C-owned.

## Reproduction

```powershell
rtk proxy pwsh -NoProfile -File tools/bench-dos.ps1 -ChaseOnly -NoBootstrap
```
