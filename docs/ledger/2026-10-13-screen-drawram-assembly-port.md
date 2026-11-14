# `SCR_DrawRam` i486 assembly slice (2026-10-13)

## Mapping

| Reference behavior | Assembly implementation | Oracle and fixture |
| --- | --- | --- |
| `src/client/screen.c:SCR_DrawRam` | `src/client/screen_drawramasm.s:SCR_DrawRam_asm486`, selected by `ScreenDrawRamImplementation=asm` | `SCR_DrawRam_Screen_C` retained as the BENCH486-only C oracle in `src/tests/bench486/bench486_screendrawram.h` |
| Skip when `scr_showram.value` is zero or `r_cache_thrash` is false; otherwise call `Draw_Pic(scr_vrect.x + 32, scr_vrect.y, scr_ram)` | Read binary32 bits, clear the sign bit to identify either signed zero, branch on the cache flag, then pass the original coordinates and icon to `Draw_Pic` | Independent expected indexed/16-bit framebuffer model in `Bench486ScreenDrawRamPrepare` |

The assembly uses integer instructions for the zero test and does not touch the
x87 state. The shared header pins the `cvar_t.value` and `vrect_t` offsets and
requires IEEE binary32. The routine follows cdecl, preserves the frame pointer,
passes the three `Draw_Pic` arguments on the stack, and removes those arguments
after the call. It is declared `.arch i486`.

## Direct differential fixture

The accepted fixture ran seven deterministic inputs under all four x87 rounding
modes and all three precision settings: 84 C/assembly pairs. Cases cover both
signed zeros, cache-clear early return, a quiet NaN with cache clearing, finite
positive and negative values, infinity, right-edge placement, and both 8-bit
and 16-bit drawing. It compares the complete 42,000-byte framebuffer against
the independent expected image and checks frame and picture guards, cdecl ABI,
x87 control word, and x87 stack top.

The retained DOSBox-X report says:

```text
screen RAM indicator 84 exact C/assembly cases across four RC and three PC modes; framebuffer parity PASS
486 benchmark correctness PASS
```

The C/assembly focused profiles differ only in `ScreenDrawRamImplementation`.
The cumulative assembly profile selects this routine. A paired gameplay-scene
comparison for this overlay has not been run, so the evidence is routine-level
and does not close screen-overlay or whole-renderer parity.

An attempted expansion adding a quiet-NaN draw case did not produce a fixture
result in DOSBox-X; it wrote only the start marker and exited before the summary.
The extra case was removed from the accepted fixture pending a diagnosis. The
current code and accepted 84-case record are the versions described here.

## Strict i486 verification

The accepted executable passed the complete source-bound compatibility gate:

- 146 project objects and 235 installed runtime objects were source-proved.
- 381 linked objects contained 211,926 decoded instruction sites, with zero
  above-i486 instructions, unknown instructions, or exemptions.
- All 211,926 relocated executable opcodes matched the audited inputs; no
  instruction bytes were skipped or exempted.
- The 1,660-byte startup image, its 529 code rows, CRT helpers, and the 9,207
  instruction CWSDPMI provider passed with zero exemptions.

## Reproduction and scope

Use a fresh local output name and put temporary files under `out` on D:. The
accepted run used `testdata/id1` and:

```powershell
.\tools\bench-dos.ps1 -NoBootstrap -ToolRoot .\out\tools `
  -DataRoot .\testdata\id1 -CpuTarget i486 -ScreenDrawRamOnly `
  -ScreenDrawRamImplementation asm `
  -LocalOutputDirectoryName screen-drawram-local-run
```

Set `TEMP`, `TMP`, and `TMPDIR` to a D:-local directory before running. The
accepted build and DOSBox-X records are under
`out/local-screen-drawram-20261013-run1/` and
`out/dos-bench-20261013-082703/`.

This slice verifies the RAM indicator routine only. BSP traversal, edge and
surface generation, span and texture rendering, and broad scene parity remain
open in the renderer port.
