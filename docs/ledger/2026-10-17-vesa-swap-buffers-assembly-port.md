# VESA page-flip orchestration i486 assembly port (2026-10-17)

## Behavior and selector

`VesaSwapBuffersImplementation=asm` selects the assembly page-flip and
single-page presentation dispatch for `VID_ExtraSwapBuffers`. The assembly
updates page bookkeeping, calculates VBE display-start coordinates, and
chooses between page flipping and the dirty-rectangle copy path. BIOS/DPMI
operations and runtime-specific waits remain in narrow C adapters. The C
implementation remains available to BENCH fixtures and the C-reference
profile.

## Direct C/assembly parity

`Bench486VesaSwapBuffersCases` compares C and assembly with hardware calls
intercepted. It covers page-flip state and coordinates, plus the single-page
dirty-copy presentation path. `VesaCopyRectsImplementation=c` isolates this
fixture from the separately ported rectangle-copy loop. DOSBox-X reported:

```text
VESA C/ASM page-flip and copy presentation cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-092605/bench-result.json`.

The fixture checks presentation orchestration with hardware calls stubbed. It
does not measure full-scene FPS or establish full-frame visual parity.

## Strict i486 verification

The strict BENCH build passed project-object, linked-object, executable,
relocated-image, startup, CRT-helper, and maintained CWSDPMI provider gates.
It verified 244,599 project instructions across 155 objects and 282,896
linked instructions across 390 objects. The executable proof checked all
282,896 opcodes across 235 runtime inputs and 415 source-bound contributions,
covering 2,200 CODE ranges and 29 DATA ranges. Startup proof covered 1,660
loaded bytes and 529 CODE rows; the provider proof covered 9,207 instructions.

The assembly-selected i486 release build passed the same gates. It verified
127,690 project instructions across 155 objects, 165,987 linked and relocated
instructions across 390 objects, and all 165,987 opcodes across 235 runtime
inputs and 402 source-bound contributions, covering 1,469 CODE ranges and 29
DATA ranges. Both profiles had zero instructions above i486, unknown
encodings, exemptions, or skipped bytes.

BENCH output: `out/profile-a0b739e75b62e60b`.
Release output: `out/profile-556e8271fc8bb76d/quake.exe`.

## Ownership and remaining scope

The i486 assembly selector profile now contains 125 entries. VESA page-flip
orchestration is assembly-backed, while VESA mode discovery, wait probing,
palette programming, mode changes, and the outer `VID_Update` state machine
remain C-owned.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/vid_ext.c:VID_ExtraSwapBuffers_C` | `src/vid_vesaswapasm.s:VID_ExtraSwapBuffers_ASM` | Stubbed page-flip, display-coordinate, and single-page copy cases against C | Strict BENCH and release i486 gates pass; DOSBox-X fixture passes |
