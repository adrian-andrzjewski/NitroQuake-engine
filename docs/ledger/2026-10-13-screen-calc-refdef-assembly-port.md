# `SCR_CalcRefdef` i486 assembly port

## Original behavior and selected assembly

`screen.c:SCR_CalcRefdef` clears the full-update and refdef-recalculation flags,
notifies the status bar, clamps `viewsize` and `fov` through `Cvar_Set`, computes
vertical FOV, selects the status-bar line count (including the intermission
override), constructs the local view rectangle, clamps console height, then
calls `R_SetVrect` and `R_ViewChanged`.

`src/client/screen_refdefasm.s` implements that order directly using only `.arch i486`
and `.arch .387` instructions. The C implementation stays available as
`SCR_CalcRefdef_Screen_C` for the BENCH486 oracle and as the default
`ScreenRefdefImplementation=c` path. The assembly is selected with
`ScreenRefdefImplementation=asm`; `SCR_UpdateScreen` calls it through the
selector-controlled branch.

The shared layout constants and compile-time C structure checks live in
`src/client/asm_screenrefdef.h`. FOV calculation follows the existing view-control
selector: when `ViewControlImplementation=asm`, the assembly calls
`CalcFov_asm486`; otherwise it calls the C `CalcFov`. BENCH486-only observer
calls are guarded by `bench486_screen_refdef_fixture_active`. With that flag
clear, the assembly calls the live `Sbar_Changed`, `Cvar_Set`, and
`R_ViewChanged` routines.

## Differential state fixture

`src/tests/bench486/bench486_screenrefdef.h` runs twelve cases covering low/high clamps,
status-bar boundaries, multiple resolutions, view sizes, FOV values, console
heights and all three intermission values. Each case runs under four x87
rounding modes. The fixture compares the resulting screen/refdef state,
float-bit values, callback order and arguments, ABI status, x87 control word,
and x87 stack depth. The final i486 DOSBox-X run passed **48/48 exact
C/assembly cases**.

The original C routine's local `vrect.pnext` is uninitialized and unused by
`R_SetVrect`/`R_ViewChanged`. The fixture observer sets that field to null before
comparing it, so the test compares defined behavior without changing renderer
state or the production algorithm.

## Paired framebuffer parity and strict i486 audit

The C-reference and assembly profiles differ only in
`ScreenRefdefImplementation`. One run per profile passed all seven matched
scenes: `demo1-vesa-full`, `demo1-drawspans8`, `demo1-vga-full`,
`demo1-fullbright`, `demo1-viewsize-50`, `demo2-entity-workload`, and
`demo3-world-workload`. The pair matched **6,885 post-warmup frame checksums**,
all seven indexed framebuffer captures, and every palette byte exactly.

The strict cumulative candidate passed the complete i486 gate after the
fixture-hook routing fix: 273,734 relocated instructions, 529 startup
instructions, and 9,207 CWSDPMI provider instructions; zero post-486
instructions, unknown encodings, or exemptions. A strict one-scene runtime
smoke also passed: 969 frames in 80.867827 seconds of DOSBox timedemo time
(11.982515 FPS). The runner's 1,203.76-second total includes build and audit
time and is not the timedemo duration. The visual parity pair used
`-VisualParityOnly`, so its reports do not certify ISA compatibility; the
strict smoke report supplies that separate evidence.

## Traceability and reproduction

| Original function | Assembly replacement | Correctness evidence |
|---|---|---|
| `screen.c:SCR_CalcRefdef` | `src/client/screen_refdefasm.s:SCR_CalcRefdef_asm486` | `src/tests/bench486/bench486_screenrefdef.h`; seven-scene exact pair |

Run the focused exact state fixture (this diagnostic command skips its own ISA
audit; use the strict command below for compatibility proof):

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -FrameControlImplementation asm -ViewControlImplementation asm -ScreenRefdefImplementation asm -ScreenRefdefOnly -SkipIsaAudit
```

Run exact C/assembly framebuffer parity:

```powershell
rtk pwsh -NoProfile -File tools/render-parity-dos.ps1 -ReferenceProfile tools/renderer-profiles/i486-screen-refdef-c.json -CandidateProfile tools/renderer-profiles/i486-screen-refdef-asm.json -CpuTarget i486 -RunsOverride 1 -VisualParityOnly
```

Run the strict cumulative i486 executable audit and runtime smoke:

```powershell
rtk pwsh -NoProfile -File tools/render-validation-dos.ps1 -Scenario demo1-vesa-full -RendererSelectorProfile tools/renderer-profiles/i486-screen-refdef-asm.json -CpuTarget i486 -RunsOverride 1 -SkipGoldenImageComparison
```

The recorded reports are under `out/screen-refdef-parity-20261013-064203`,
`out/screen-refdef-strict-final-20261013-070401`, and the fixture run's
`out/dos-bench-20261013-052539`. The broader screen update, overlays,
initialization paths and complete renderer call graph remain outside this
slice.
