# `V_Init` -> i486 assembly port (2026-10-10)

## Original command, cvar and gamma order

`src/view.c:V_Init` registers three view commands (`v_cshift`, `bf`,
`centerview`), registers 25 cvars in source order, builds the initial gamma
table with `BuildGammaTable(1.0)`, then registers `v_gamma`. The C body remains
available as `V_Init_View_C` in BENCH486 builds and the default implementation
when `ViewControlImplementation=c`.

`src/v_viewcontrolasm.s:V_Init_asm486` preserves that call order. The
`BuildGammaTable` parameter is a `float`, so the assembly passes the single
word `0x3f800000` for 1.0. It uses cdecl pushes, calls, stack cleanup, and
`ret`, without allocating callee-saved registers. Under
`ViewControlImplementation=asm`, it owns the public `V_Init` entry. BENCH486
registration hooks forward to the real command and cvar registries unless the
direct fixture installs capture callbacks. The benchmark-only C oracle routes
gamma generation through `BuildGammaTable_C`, preserving a C reference even
when another profile selects assembly for the public palette routine.

## Direct registration, gamma and ABI fixture

`src/bench486_vinit.h:Bench486VInitCases` runs the retained C oracle, direct
assembly entry, and selected public entry through the ABI checker. It captures
the three registered command names and handler pointers, all 25 cvar pointers
before gamma construction, and the final `gamma` cvar registration. Each call
starts with a non-identity table and must leave all 256 gamma bytes equal to
their identity values. The capture hooks avoid mutating the process's live
registries. DOSBox-X passed all three paths with 3 commands, 26 cvar events,
25 before gamma, and zero state or ABI failures. This is initialization-state
parity, not a frame or scene comparison.

## Strict i486 audit for the view-control profile

The focused `ViewControlImplementation=asm` build passed the complete
executable gate. Its 173,673 source-object instructions and 211,970 linked
instructions contained only i386/i486 instructions, with one i486 instruction,
zero post-i486 or unknown instructions, and zero exemptions. All 365
source-bound executable contributions mapped to 1,689 CODE ranges and 12 DATA
ranges; the startup image passed its 529-CODE-row audit and the maintained
CWSDPMI provider passed its 9,207-instruction audit. DOSBox-X exited with code
zero and reported the full view-control benchmark correct.

## V_Init traceability and reproduction

| Reference behavior | Assembly implementation | Correctness evidence | Compatibility evidence |
| --- | --- | --- | --- |
| `src/view.c:V_Init` | `src/v_viewcontrolasm.s:V_Init_asm486` | `src/bench486_vinit.h:Bench486VInitCases`; exact command/cvar registration, identity gamma table and ABI across C/ASM/public entries | Complete strict i486 executable, startup and CWSDPMI audits |

From `quake/`, reproduce the direct fixture and strict instruction checks with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -ViewControlImplementation asm -ViewControlOnly -NoBootstrap
```

The C path remains selectable, and the assembly entry joins the existing view
control selector without introducing a second initialization profile. Full
renderer profile parity, indirect startup dependencies, and broader scene
coverage remain open.
