# VGA linear dirty-rectangle tail copy fix

## Failure mechanism

`VGA_SwapBuffersCopy` sends dirty-rectangle widths directly to
`VGA_UpdateLinearScreen`. That helper copied `width / 4` dwords per row and
never copied the remaining one to three bytes. Any unaligned dirty-rectangle
edge could therefore leave stale pixels at the right edge of each copied row,
appearing as visible gaps or artifacts in VGA mode.

The existing C-versus-assembly renderer comparison did not catch this: both
presentation wrappers call the same low-level assembly copy helper, and the
scene capture checks `vid.buffer` before it observes the displayed VGA page.
The seven-scene paired run remained pixel-exact, including the assembly
`VID_Update` selector, but could not validate this transfer.

## Correction and fixture

`src/d_copy.s` now copies the remaining `width & 3` bytes after each dword
transfer. The VGA fixture uses rectangle widths 11, 14, and 9 to exercise all
three tail sizes. It compares both presentation wrappers against an
independently constructed expected display buffer, including unchanged row
padding and guard bytes.

The timedemo wrapper also now accepts and forwards `VideoUpdateImplementation`
to `build-dos.ps1`, so selector profiles can build the video-update path they
declare instead of failing before the render comparison.

## Verification

The focused command was:

```powershell
tools/bench-dos.ps1 -VgaPresentationOnly -VgaPresentationImplementation asm-fixture -CpuTarget i486 -NoBootstrap -TimeoutSeconds 180
```

DOSBox-X reported `VGA C/ASM linear, planar, and retrace presentation cases
PASS failure mask 0x0` and `486 benchmark correctness PASS`. The result is
`out/dos-bench-20261028-155531/bench-result.json`.

The strict object, linked, relocated-executable, and startup i486 audits
passed. The linked proof verified 314,665 opcodes across 403 exact
native/annotated objects, with zero above-i486, unknown, or exempt
instructions. The focused fixture proves the emulated VGA destination bytes;
it did not capture a DOSBox host-window screenshot.
