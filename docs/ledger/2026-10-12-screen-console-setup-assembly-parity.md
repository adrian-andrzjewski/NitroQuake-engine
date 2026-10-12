# `SCR_SetUpToDrawConsole` -> i486+387 assembly parity (2026-10-12)

## Reference, implementation, and call boundary

`src/screen.c:SCR_SetUpToDrawConsole_Screen_C` is the retained BENCH486
reference. `src/screen_consolesetupasm.s:SCR_SetUpToDrawConsole_asm486` is the
32-bit assembly implementation selected by
`ScreenConsoleSetupImplementation=asm`; ordinary builds retain the C routine
by default. The assembly entry keeps the normal C calls to `Con_CheckResize`,
`Draw_TileClear`, and `Sbar_Changed`. BENCH486 substitutes trace hooks only
while its direct C/assembly fixture is active.

| Original behavior | Assembly implementation | Direct verification |
| --- | --- | --- |
| Resize console state, then return while a loading plaque is active | Initial `Con_CheckResize` call and loading guard | 14 deterministic C/assembly states |
| Force the console before world sign-on; otherwise choose half-height for the console key or zero | `cl.worldmodel`, `cls.signon`, `key_dest`, and unsigned `vid.height` handling | Full state comparison, including high-bit height |
| Animate `scr_con_current` by `scr_conspeed.value * host_frametime` and clamp to target | Ordered 387 loads/arithmetic/stores and explicit comparisons | All four x87 rounding modes and three precision modes |
| Respect page-clear post-increments and choose bottom or notify clear | Original strict comparisons, counter updates, and C backend call arguments | Exact tile-clear/status-bar call trace and resulting state |
| Convert the animated float to the tile Y coordinate by C truncation | Temporarily set x87 RC to chop for `FISTP`, then restore the full control word | Control-word and ABI preservation checks |

The assembly contract and compile-time layout checks are in
`src/asm_screenconsolesetup.h`. They pin `viddef_t` dimensions and page count,
`cl.worldmodel`, `cls.signon`, `cvar_t.value`, `key_console`, and `SIGNONS` to
the offsets/constants used by the assembly. The routine uses DJGPP 32-bit
cdecl, preserves callee-saved registers, and leaves the x87 stack balanced.
Its target is a 486DX-class CPU with a 387-compatible x87, matching the original
floating-point behavior; this is not a claim of 486SX operation without an FPU.

## Exact runtime fixture

`src/bench486_screenconsolesetup.h` runs 14 named states under four x87
rounding modes and three precision-control settings. For each mode it invokes
the C oracle and assembly entry, then compares the complete affected state,
backend-call trace, ABI probe, and control word. The fixture includes loading
early return, forced and sign-on boundaries, odd video heights, opening and
closing animation/clamps, clear-page boundaries, negative frame time, and a
high-bit unsigned video height.

The strict DOSBox-X 486DX+x87 run passed all 14 x 12 combinations with zero
mismatches. The execution log and machine-readable result are
`out/dos-bench-20261012-193632/quake/BENCH486.TXT` and
`out/dos-bench-20261012-193632/bench-result.json`.

## 486 instruction verification

The strict run used `CpuTarget=i486` and reported `isaAuditStatus=PASS`. The
project-object audit decoded 172,601 instructions across 143 objects; the
source-bound linked-object audit covered 378 objects and 210,898 instructions.
All 210,898 relocated executable opcodes were verified against their source
contributions. The audits found zero above-i486 or unknown instructions,
exemptions, relocation data sites, or undecoded bytes. Mapping covered 369
source-bound contributions, 1,685 CODE ranges, and 13 DATA ranges. Startup
validation covered all 1,660 loaded bytes and 529 instruction rows; CWSDPMI
validation covered 9,207 instructions and its runtime branch variant, with no
exemptions. The complete executable ISA gate passed.

Reproduce the focused strict build and fixture with:

```powershell
rtk pwsh -NoProfile -ExecutionPolicy Bypass -File tools/bench-dos.ps1 `
  -CpuTarget i486 -ScreenConsoleSetupImplementation asm `
  -ScreenConsoleSetupOnly -TimeoutSeconds 600
```

This proves routine state and backend-call parity under the supported 486DX+x87
environment. It does not establish complete-scene parity or close the remaining
renderer migration.
