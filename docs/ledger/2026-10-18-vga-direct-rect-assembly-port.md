# VGA direct-rectangle i486 assembly port (2026-10-18)

## Behavior and selector

`VideoUpdateImplementation=asm` now selects i486 assembly for
`D_BeginDirectRect`, `D_EndDirectRect`, `VGA_BeginDirectRect`, and
`VGA_EndDirectRect`. The public wrappers retain the original input checks and
dispatch through the active mode's callbacks. The VGA routines handle planar
and linear framebuffer backup/overlay/restore, including the original aspect
ratio row repetition behavior. `asm_viddirectrect.h` pins the 32-bit structure
offsets consumed by the assembly.

The C versions remain available as `_C` oracle entries in BENCH builds and as
the public implementations in the C-reference profile.

## Direct C/assembly parity

The DOSBox-X fixture compares six valid cases across planar/linear modes and
aspect ratios 1.0, 1.5, and 2.0. It compares the full test framebuffer and
backing buffer after begin and end, with guard bytes around the framebuffer.
Thirteen invalid-input cases cover null direct/mode state and invalid width or
height boundaries. The same run also passes the existing `VID_Update` parity
fixture:

```text
VID_Update C/ASM state and dispatch cases PASS failure mask 0x0
VGA direct-rectangle C/ASM parity PASS (6 mode cases and 13 guard cases, failure mask 0x0)
486 benchmark correctness PASS
```

Run record: `out/dos-bench-20261018-053624/bench-result.json`.

## Strict i486 verification

The focused BENCH project-object audit passed 246,804 instructions. The linked
object and relocated executable audits each passed 285,101 instructions; the
executable proof covered 431 source-bound contributions and 2,258 CODE ranges.
Startup validation covered 529 CODE rows and the maintained provider proof
covered 9,207 instructions. No above-i486 or unknown instructions, exemptions,
or skipped bytes were reported.

## Scope limits and reproduction

The planar fixture executes the plane-select I/O path and compares the routine's
addressed test-buffer and backing-buffer effects. It does not model four
independent VGA hardware planes, so it is not a substitute for broader planar
mode scene validation. This focused parity run measures neither FPS nor full
scene output. Video mode discovery and BIOS/DPMI mode setting remain outside
this slice.

Reproduce with:

```powershell
rtk proxy pwsh -NoProfile -ExecutionPolicy Bypass -File tools/bench-dos.ps1 -VideoUpdateOnly -VideoUpdateImplementation asm-fixture -CpuTarget i486 -TimeoutSeconds 180
```
