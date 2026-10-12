# `SCR_DrawCenterString` -> i486 assembly parity (2026-10-10)

## SCR_DrawCenterString reference and assembly boundary

`src/screen.c:SCR_DrawCenterString_Screen_C` is the retained BENCH486 oracle.
`src/screen_centerasm.s:SCR_DrawCenterString_asm486` is the 32-bit assembly
implementation, and `SCR_DrawCenterString` dispatches to it when
`ScreenCenterStringImplementation=asm`. Normal builds retain the C routine when
the selector is `c`. The new assembly module is limited to this centered-message
routine; the renderer remains broadly C-owned and the default remains C.

The focused profiles are `tools/renderer-profiles/i486-screencenter-c.json` and
`tools/renderer-profiles/i486-screencenter-asm.json`. The fixture is
`src/bench486_screencenter.h` and can be run with:

```powershell
rtk pwsh -NoProfile -File .\tools\bench-dos.ps1 `
  -ScreenCenterStringImplementation asm -ScreenCenterStringOnly
```

The trace is:

| Reference or implementation | Role | Verification |
| --- | --- | --- |
| `screen.c:SCR_DrawCenterString_Screen_C` | Original 40-character scan, line handling and print-budget behavior | Retained direct C oracle |
| `screen_centerasm.s:SCR_DrawCenterString_asm486` | Runtime i486 implementation | Exact guarded-frame and character-call comparison |
| `screen.c:SCR_DrawCenterString` | Public selector entry | Compared against the C oracle for every fixture case |

Execution acceptance uses `tools/dosbox-x-486-high.conf` (`cputype=486`,
`fpu=true`), the selected 486DX-with-x87 profile. `CpuTarget=i486` is the
machine-code floor checked by the strict binary audit.

## x87 arithmetic, state and calling convention

The implementation follows Quake's per-line scan, unsigned horizontal-width
subtraction, 8-pixel character advance, signed glyph-byte argument, and vertical
placement at 35% of the video height for up to four lines (48 pixels for more).
The first implementation defect was loading `cl.time` as a 32-bit float even
though Quake stores it as an 8-byte `double`. The assembly now loads the full
double before subtracting the float start time and multiplying by the float
print speed. A compile-time layout assertion fixes the time-field size at eight
bytes.

The resulting floating-point print budget is converted to `int` by truncation
toward zero, independent of the incoming x87 rounding mode. The routine saves
and restores the caller's x87 control word around conversions, preserves cdecl
callee-saved registers, and leaves the x87 stack balanced. The fixture checks
register preservation and control-word preservation for the C, assembly, and
public-entry calls.

## 19-case C/assembly differential fixture

Nineteen deterministic cases cover empty and ordinary strings, wrapped and
five-line text, a 40-character line, the overlong-line suffix, signed high-byte
glyphs, wide off-screen centering, high-bit and maximum unsigned dimensions,
480-line output, and zero, positive, negative, and fractional intermission
budgets. `narrow-view-40-char-line` makes a 40-character line wider than a
240-pixel view and pins the C expression's unsigned wrap before division.
Each case runs under four x87 rounding modes and three precision-control
settings. The fixture compares every byte of the guarded indexed framebuffer,
every character call and its coordinates, ABI probe results, x87 control words,
and guard regions.

The exact 19-case by 12-mode matrix passed with zero mismatches under DOSBox-X.
The runtime fixture also reports progress after each case with the saved video
state restored, so the 480-line case cannot make the progress message draw into
the smaller test framebuffer. The high-bit scenarios were chosen so the C
reference's centered coordinates remain representable; maximum-width cases
return on a zero print budget before the C loop increment can overflow.

On 2026-10-12, the narrow-view case confirmed that `vid.width` is unsigned:
`vid.width - l*8` wraps modulo 2^32 before the logical divide by two. The
assembly retains `shrl`; signed division would disagree with the C oracle for
this view. The strict run passed all 19 cases, all 12 x87 modes, and the live
8-bit/16-bit `Draw_Character` framebuffer routes. Its log and run report are
`out/dos-bench-20261012-191700/quake/BENCH486.TXT` and
`out/dos-bench-20261012-191700/bench-result.json`.

## Strict 486DX+x87 executable evidence

The latest strict `-ScreenCenterStringOnly` build decoded 172,543 instructions
across 143 project objects. Its linked proof covered 378 exact native or
annotated objects and verified all 210,840 linked instructions in the relocated
executable. Both audits found zero above-i486 or unknown instructions, byte
mismatches, or exemptions. The actual DOSBox-X run used the 486DX+x87 profile
above and passed all 19 fixture cases.

The same build passed the startup and provider proofs: all 1,660 loaded startup
bytes and 529 instruction rows, plus 9,207 CWSDPMI instructions and its one
runtime branch variant, with zero instruction exemptions. A separate exact
`demo2-entity-workload` comparison also matched all 64,000 indexed pixels and
the palette, with 986 frame checks and zero changed pixels; its report is
`out/render-validation-center-asm-final-demo2-20261012/render-validation-result.json`.
Complete-scene parity and the broader renderer migration remain open; these are
routine-level and one-scene results.
