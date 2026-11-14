# `SCR_EraseCenterString` -> i486 assembly port (2026-10-11)

## Reference and selector boundary

`src/client/screen.c:SCR_EraseCenterString_Screen_C` remains the BENCH486 reference.
`src/client/screen_eraseasm.s:SCR_EraseCenterString_asm486` implements the routine,
and `SCR_EraseCenterString` dispatches to it when
`ScreenEraseCenterStringImplementation=asm`. The normal default remains C.
The focused profiles are `tools/renderer-profiles/i486-screenerasecenter-c.json`
and `tools/renderer-profiles/i486-screenerasecenter-asm.json`.

The original post-increment comparison tests the old `scr_erase_center` value
against `vid.numpages`. An early exit clears `scr_erase_lines` and leaves
`scr_copytop` untouched. Otherwise the y coordinate is the truncated
`vid.height * 0.35` when `scr_center_lines <= 4`, or 48 for taller messages;
the routine sets `scr_copytop` and calls `Draw_TileClear(0, y, vid.width,
8*scr_erase_lines)`, including when the requested erase height is zero. The
assembly preserves those boundaries and the cdecl caller's registers.

## x87 arithmetic and the 486DX target

The assembly source declares `.arch i486` and `.arch .387`. `vid.height` is an
unsigned 32-bit field. The assembly zero-extends it into a stack qword and uses
`FILD m64int` before multiplying by the same double constant as the C
reference. This matches the actual GCC lowering and preserves behavior when
the high bit is set, including at 24-bit x87 precision. The integer conversion
temporarily selects round-toward-zero, then restores the complete control word;
the incoming precision and rounding modes otherwise remain in effect. The
routine returns with a balanced x87 stack.

Compile-time layout checks pin `vid.width`, `vid.height`, and `vid.numpages` to
offsets 20, 24, and 32 in the 68-byte `viddef_t`.

The target profile is explicit: `CpuTarget=i486` produces the 486DX code floor,
the DOSBox-X run profile requests `cputype=486` and `fpu=387`, and the build
records the required 387-compatible FPU and `-mfpmath=387` mode. The static
instruction and runtime/provider audits remain the compatibility authority.

## Exact differential fixture

`src/tests/bench486/bench486_screenerase.h` compares the retained C oracle, direct assembly
entry, and public selector for seven deterministic states under all four x87
rounding modes and all three precision-control settings: 252 calls in total.
Coverage includes the page-count equality boundary, early exits, zero erase
height, the four-line cutoff, and a high-bit unsigned video height. It compares
the complete `viddef_t`, affected screen globals, tile-clear call arguments,
guard words, ABI probe result, and control word. Progress is written for every
comparison; synthetic video dimensions are restored before printing so the
fixture can report progress safely.

The DOSBox-X 486DX+x87 run completed all 252 calls with zero mismatches:

```powershell
rtk pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\bench-dos.ps1 `
  -CpuTarget i486 -ScreenEraseCenterStringImplementation asm `
  -ScreenEraseCenterStringOnly -NoBootstrap -TimeoutSeconds 180
```

## Strict executable evidence

The strict build passed the project-object audit for 142 exact objects and
172,231 instructions, and the combined project/runtime object audit for 377
objects and 210,528 instructions. Both found zero instructions above i486,
unknown instructions, or exemptions. The linked executable audit matched all
210,528 opcodes across 370 executable text ranges; it found no undecoded bytes,
relocation data sites, or exemptions. Mapping validation covered 370 source
contributions, 1,690 CODE ranges, and 14 DATA ranges.

The final relocated image audit found zero above-i486 or unknown instructions.
Startup validation covered all 1,660 loaded bytes and 529 CODE rows; the
loader, `sbrk16`, and `exit16` checks decoded 489, 33, and 7 instructions. The
CWSDPMI provider proof covered 9,207 instructions and its runtime branch
variant, with zero exemptions. The strict DOSBox-X run then passed the same
252-case fixture.

The focused structural suite passed 93 rendering tests, the build-profile suite
passed its pinned i486/i386 flag checks, and the runner selector suite passed
1,800 checks. These results cover this routine and its executable build; full
scene parity and the remaining renderer migration are still open.
