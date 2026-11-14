# `R_PrintTimes` -> i486 assembly port (2026-10-09)

## Time conversion, formatting, and ABI

`R_PrintTimes` in `src/renderer/r_misc.c` narrows the timer result to `float`, computes
elapsed milliseconds and narrows that result to `float`, then prints the same
format string and five values through `Con_Printf`. It resets `c_surf` only
after printing. `src/renderer/r_printtimesasm.s` preserves those narrowing points,
vararg order, reset order, x87 control word and stack depth. It exports
`R_PrintTimes_asm486`; the C oracle remains `R_PrintTimes_C` in BENCH486 builds.

`PrintTimesImplementation=c|asm` maps to `ASM486_PRINT_TIMES`. The focused
profile is `tools/renderer-profiles/i486-asm-print-times.json`. The current
combined selector profile includes this implementation; its cumulative
checkpoint is `i486-asm-selectable-87.json`.

## Deterministic console fixture and i486 results

`Bench486PrintTimesCases` in `src/tests/bench486/bench486_printtimes.h`, invoked by
`-benchprinttimes`, redirects output to a guarded 80 by 8 console ring. Seven
cases cover zero, float narrowing, positive and negative elapsed time,
negative-zero formatting, signed integer extremes and repeated ring wrap. The
fixture compares the complete ring and console state against an independent
formatting oracle, checks guards, buffer pointers, timer calls, x87 CW/TOP and
the assembly ABI probe. The probe's own ESP check is used for stack balance;
an outer C-level ESP snapshot was removed because it could include deferred
cdecl argument cleanup.

The combined i486 BENCH build selected both `PrintTimesImplementation=asm`
and `ParticleExplosion2Implementation=asm`. All ISA gates passed: 165,846
instructions across 127 selected objects; 204,143 instructions across 362
linked objects; all 204,143 executable opcodes were verified across 348 text
ranges. The relocated executable, 529 startup rows and 9,207 runtime-provider
instructions also passed with zero above-i486, unknown or exempt instructions.

DOSBox-X completed the PrintTimes fixture with all seven exact console/state
cases passing. This is direct leaf-level console parity, not framebuffer or
whole-scene renderer parity. Reproduce it with:

```powershell
rtk pwsh -NoProfile -File tools/build-dos.ps1 `
  -Benchmark -PrintTimesImplementation asm `
  -ParticleExplosion2Implementation asm -NoBootstrap
rtk pwsh -NoProfile -File tools/bench-dos.ps1 `
  -PrintTimesOnly -PrintTimesImplementation asm `
  -ParticleExplosion2Implementation asm -SkipBuild -NoBootstrap
```
