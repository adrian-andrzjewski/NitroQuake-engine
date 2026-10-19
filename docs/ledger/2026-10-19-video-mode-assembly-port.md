# DOS video mode selection and lookup i486 assembly port (2026-10-19)

## Behavior and selector

`VideoUpdateImplementation=asm` now selects i486 assembly for
`VID_GetModePtr`, `VID_ModeInfo`, and `VID_SetMode` in
`src/vid_updateasm.s`. The C-reference profile keeps the original C behavior;
BENCH retains named C oracle entries while the public symbols resolve to
assembly. The mode-layout header asserts the `vmode_t` and `viddef_t` offsets
used by the assembly.

`VID_SetMode` owns the mode range check, startup fallback to VGA mode 13h,
screen-update suppression, driver callback dispatch, palette-ready check,
palette copy, cvar/refdef updates, and final status. Mode-specific hardware
operations remain behind the existing mode callbacks.

## Direct C/assembly parity

The focused DOSBox-X fixture compares valid mode lookup and name/header
results, empty and broken-list error paths, and eight mode-transition cases:
already selected, invalid mode with and without a current mode, requested-mode
success, mode-set fallback, palette fallback, screen-suppression restoration,
and VGA initialization failure. The strict `asm-fixture` run reported:

```text
VID_Update C/ASM state and dispatch cases PASS failure mask 0x0
DOS video mode C/ASM lookup and transition cases PASS failure mask 0x0
VGA direct-rectangle C/ASM parity PASS (6 mode cases and 13 guard cases, failure mask 0x0)
486 benchmark correctness PASS
```

Reproduce the focused fixture from `quake/` with:

```powershell
rtk pwsh -NoProfile -ExecutionPolicy Bypass -File tools/bench-dos.ps1 `
  -VideoUpdateOnly -VideoUpdateImplementation asm-fixture
```

## Strict i486 verification and ownership

The strict BENCH run passed the complete executable ISA gate for 302,565
relocated instructions, 529 startup CODE rows, and 9,207 provider
instructions, with zero exemptions. The non-BENCH release build used:

```powershell
rtk pwsh -NoProfile -ExecutionPolicy Bypass -File tools/build-dos.ps1 `
  -VideoUpdateImplementation asm -CpuTarget i486 -NoBootstrap
```

The release gate passed 161,620 relocated instructions, 529 startup CODE rows,
and 9,207 provider instructions, with zero above-i486, unknown, or exempted
instructions. `build-manifest.json` selects `videoUpdateImplementation=asm`.
`quake.exe.map` resolves `VID_GetModePtr`, `VID_ModeInfo`, and `VID_SetMode` to
`obj/vid_updateasm.obj`; the production map contains no `_C` oracle symbols.

The refreshed release inventory at
`out/profile-41090bd4aa6cb655/renderer-ownership-release.json` reports 605
renderer entries, 414 directly reachable entries, 11 direct C dependencies,
and 38 unresolved direct callees. By direct symbol count, that is 403/414, or
97.3%, assembly-owned. The graph is incomplete and the percentage is neither
weighted by routine size nor a whole-codebase completion measure. The two
directly reachable video C owners left in this inventory are
`VID_ShiftPalette` and `VID_Shutdown`.

## Scope and remaining work

This slice ports the mode lookup and orchestration layer. It does not port the
hardware-specific mode callbacks, palette shifting/programming, or the main
video shutdown routine. It establishes neither an FPS improvement nor
full-scene visual parity; those remain separate gates for the broader renderer
port.
