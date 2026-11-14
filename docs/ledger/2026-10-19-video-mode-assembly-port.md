# DOS video mode and palette orchestration i486 assembly port (2026-10-19)

## Behavior and selector

`VideoUpdateImplementation=asm` now selects i486 assembly for
`VID_GetModePtr`, `VID_ModeInfo`, `VID_SetMode`, `VID_SetPalette`,
`VID_ShiftPalette`, and `VID_Shutdown` in `src/video/vid_updateasm.s`. The
C-reference profile keeps the original C behavior; BENCH retains named C oracle
entries while the public symbols resolve to assembly. The mode-layout header
asserts the `vmode_t`, `viddef_t`, and DOS register offsets used by the
assembly.

`VID_SetMode` owns the mode range check, startup fallback to VGA mode 13h,
screen-update suppression, driver callback dispatch, palette-ready check,
palette copy, cvar/refdef updates, and final status. Mode-specific hardware
operations remain behind the existing mode callbacks.

`VID_SetPalette` now owns the 768-byte palette state copy, mode callback
dispatch, and fallback to VGA mode 13h if the selected mode cannot accept the
palette. `VID_ShiftPalette` forwards to the same assembly entry. Hardware
palette programming remains inside the mode-specific callback.

`VID_Shutdown` requests BIOS text mode 3 through `dos_int86(0x10)`, releases
extended video resources through `VID_ShutdownExtra`, then clears
`vid_testingmode`. Its C oracle remains available in BENCH and the C-reference
profile.

## Direct C/assembly parity

The focused DOSBox-X fixture compares valid mode lookup and name/header
results, empty and broken-list error paths, and eight mode-transition cases:
already selected, invalid mode with and without a current mode, requested-mode
success, mode-set fallback, palette fallback, screen-suppression restoration,
and VGA initialization failure. It also covers palette pointer reuse, copying
through the shift entry, recovery to VGA when the selected mode rejects a
palette, and failed VGA recovery with error reporting. Shutdown parity stubs the
BIOS interrupt and extra-resource release to compare call order, requested
`AX=0003` text mode, register effects, and final testing-mode state. The strict
`asm-fixture` run reported:

```text
VID_Update C/ASM state and dispatch cases PASS failure mask 0x0
DOS video mode C/ASM lookup, palette, shutdown, and transition cases PASS failure mask 0x0
VGA direct-rectangle C/ASM parity PASS (6 mode cases and 13 guard cases, failure mask 0x0)
486 benchmark correctness PASS
```

Reproduce the focused fixture from `quake/` with:

```powershell
rtk pwsh -NoProfile -ExecutionPolicy Bypass -File tools/bench-dos.ps1 `
  -VideoUpdateOnly -VideoUpdateImplementation asm-fixture
```

## Strict i486 verification and ownership

The strict BENCH run passed the complete executable ISA gate for 303,294
relocated instructions, 529 startup CODE rows, and 9,207 provider
instructions, with zero exemptions. The non-BENCH release build used:

```powershell
rtk pwsh -NoProfile -ExecutionPolicy Bypass -File tools/build-dos.ps1 `
  -VideoUpdateImplementation asm -CpuTarget i486 -NoBootstrap
```

The release gate passed 161,589 relocated instructions, 529 startup CODE rows,
and 9,207 provider instructions, with zero above-i486, unknown, or exempted
instructions. `build-manifest.json` selects `videoUpdateImplementation=asm`.
`quake.exe.map` resolves all six public video mode, palette, and shutdown symbols to
`obj/vid_updateasm.obj`; the production map contains no `_C` oracle symbols.

The refreshed release inventory at
`out/profile-41090bd4aa6cb655/renderer-ownership-release.json` reports 605
renderer entries, 415 directly reachable entries, 9 direct C dependencies,
and 38 unresolved direct callees. By direct symbol count, that is 406/415, or
97.8%, assembly-owned. The graph is incomplete and the percentage is neither
weighted by routine size nor a whole-codebase completion measure. The remaining
direct C dependencies in this inventory are console and menu routines; no
directly reachable cache, zone-heap, or video C owner remains.

## Scope and remaining work

This slice ports the DOS mode lookup and transition orchestration, palette
state copy and callback dispatch, and video shutdown orchestration. It does not
port the hardware-specific mode or palette callbacks. It establishes neither
an FPS improvement nor full-scene visual parity; those remain separate gates
for the broader renderer port.
