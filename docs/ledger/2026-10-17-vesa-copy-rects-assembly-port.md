# VESA dirty-rectangle copy i486 assembly port (2026-10-17)

## Behavior and selector

`VesaCopyRectsImplementation=asm` now selects
`src/video/vid_vesacopyasm.s:VESA_CopyRects` for the dirty-rectangle validation and
copy loop used by `VID_ExtraSwapBuffers`. It preserves the C path's rejection
of invalid rectangles, exact source and destination pitches, contiguous
full-width collapse, and final one-to-three byte tails. The current i486
assembly profile selects ASM; the C-reference profile keeps the original C
algorithm. BENCH builds retain the C implementation as a direct oracle.

BIOS mode discovery, wait probing, page flips, mode changes, and the outer
`VID_Update` state machine remain C-owned. The VGA planar and linear pixel-copy
primitives remain in `src/renderer/d_copy.s`.

## Direct C/assembly parity

`Bench486VesaCopyRectsCases` compares both implementations with a scalar
reference over guarded source and destination buffers. Cases cover zero and
negative sizes, negative coordinates, right and bottom overruns, odd-width
tails, aligned rows, padded pitches, the contiguous full-frame shape, and a
null rectangle chain. DOSBox-X reported:

```text
VESA C/ASM rectangle-copy cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-061121/bench-result.json`.

## Strict i486 verification

The strict BENCH build passed the project-object, linked-object, relocated
executable, startup, CRT-helper, and maintained CWSDPMI provider gates. It
verified 243,645 project instructions across 153 objects, 281,942 linked
instructions across 388 objects, and all 281,942 relocated opcodes across 413
source-bound contributions. There were zero above-i486 or unknown
instructions, exemptions, or skipped bytes. Startup verification covered
1,660 loaded bytes and 529 CODE rows; CRT helpers contained 33 and 7
instructions, and the provider proof covered 9,207 instructions with zero
exemptions.

The direct fixture is correctness-focused and does not measure full-scene FPS
or framebuffer parity.

## Ownership and remaining scope

The BENCH ownership report records 892 renderer entries, 371 directly
reachable entries, 70 directly reachable C renderer/support entries, and 62
unresolved direct callees. `VESA_CopyRects` is assembly-backed in the selected
profile; VESA mode discovery and presentation orchestration remain C-owned.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/video/vid_ext.c:VESA_CopyRects_C` (extracted from `VID_ExtraSwapBuffers`) | `src/video/vid_vesacopyasm.s:VESA_CopyRects` | Guarded rectangle, bounds, pitch, collapse and tail cases against C and scalar reference | Strict i486 gates pass; DOSBox-X fixture passes |
