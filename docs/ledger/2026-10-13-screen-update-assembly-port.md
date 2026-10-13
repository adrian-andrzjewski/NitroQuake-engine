# `SCR_UpdateScreen` i486 assembly port (2026-10-13)

## Reference mapping and ABI

| Reference behavior | Assembly implementation | C reference boundary |
| --- | --- | --- |
| `src/screen.c:SCR_UpdateScreen` full frame-update orchestration | `src/screen_updateasm.s:SCR_UpdateScreen_asm486`, selected by `ScreenUpdateImplementation=asm` | The C implementation remains the default; BENCH486 retains `SCR_UpdateScreen_Screen_C` as the direct oracle |

The assembly preserves the source order for loading timeout checks, refdef
recalculation, back-buffer access, page clears, console setup, center-string
erase, buffer locking, `V_RenderView`, overlays, palette update and final
`VID_Update` rectangle selection. Drawing algorithms reached through those
calls retain their own selectors and ownership.

`src/asm_screenupdate.h` pins the `vrect_t`, `viddef_t`, `cvar_t` and
`client_static_t` offsets with compile-time `offsetof` checks. The routine uses
cdecl, preserves EBX, establishes an EBP frame and declares its stack locals in
the assembly comments. Its x87 comparison keeps the original float branch
behavior, including unordered values. The module declares `.arch i486`,
`.arch .387` and `.code32`; no Pentium or SIMD instructions are used.

## Direct C/assembly fixture

`src/bench486_screenupdate.h` runs fifteen paired control-flow cases. It checks
early-return and loading states, refdef changes, exact call order, page-clear
behavior, the three update-rectangle branches, float edge cases, ABI state and
x87 state. Fixture calls stop at recorded C-call boundaries, so the test
isolates orchestration without asking a synthetic video state to draw pixels.
The DOS report records:

```text
SCR_UpdateScreen 15 exact C/assembly control, call-order and update-rectangle cases PASS
486 benchmark correctness PASS
```

The fixture result is retained at
`out/dos-bench-20261013-120348/bench-result.json`.

## Exact paired framebuffer and ISA evidence

The focused C and assembly profiles differ only in
`ScreenUpdateImplementation`. Both strict i486 validation suites passed all
seven scenarios. Across two runs per scenario, the pair compared 13,770
post-warmup checksums with zero mismatches. All fourteen frame-169 captures
matched exactly: zero indexed-pixel differences and zero palette-byte
differences. The source-tree fingerprints match. The report is
`out/render-parity-screen-update-32m-20261013-145244/render-parity-result.json`.

A separate D:-only rebuild and Demo 2 pair passed 980 post-warmup checksums,
with zero mismatches and an exact indexed framebuffer/palette capture. Both
the C reference and assembly candidate passed the full i486 ISA gate. Evidence
is in `out/render-parity-screen-update-d-only-20261013-154632/`.

The cumulative 109-selector release build also passed the blocking ISA gate.
Its 148 selected objects decoded to 129,883 instructions with zero above-i486,
unknown or exempt instructions. The linked-object set contained 383 exact
source proofs and 168,180 decoded instructions with the same zero-violation
result. The relocated executable verified all 168,180 opcodes across 389
source-bound contributions, with zero data-site exemptions. The final startup
proof covers 1,660 loaded bytes and 529 CODE rows; the maintained CWSDPMI
provider proof covers 9,207 instructions with zero exemptions. The normal
release executable then passed the DOSBox-X i486 smoke run with the complete
assembly selector profile. See `out/profile-b7dbb184ec4076a7/` and
`out/dos-smoke/smoke-result.json`.

The seven-scene pair showed no material timing regression: six scenario medians
were unchanged to the displayed precision, and the VGA path measured 0.29%
higher for assembly. The focused Demo 2 medians were 12.168143 FPS for C and
12.168051 FPS for assembly. These are regression checks, not an optimization
target.

## Refreshed ownership inventory and remaining C paths

The production release inventory is
`out/renderer-ownership-screen-update-release-20261013.json`. The scanner now
includes console, menu, status-bar, video-driver and zone/cache support modules
alongside the renderer modules. It finds 640 renderer entries, 389 directly
reachable entries, 69 directly reachable C renderer/support functions, 118
indirect call/jump sites across 36 reachable functions, and 37 unresolved
direct callees. The call graph remains explicitly incomplete: indirect targets
and initialization/debug paths still need closure.

The remaining direct C inventory includes console drawing and printing,
menu drawing, status-bar rendering, video update/palette/mode paths, cache and
hunk management, plus screen routines `SCR_DrawConsole`, `SCR_DrawLoading`,
`SCR_DrawNet`, `SCR_DrawPause`, `SCR_DrawTurtle` and
`SCR_CheckDrawCenterString`. Porting `_SCR_UpdateScreen` therefore closes only
the top-level orchestration entry, not its remaining visual and support
callees.

## Reproduction

Keep build, emulator and temporary files on D:. The custom 32 MB DOSBox-X
profile is a copy of the pinned default profile with only `memsize` changed from
16 to 32; its normalized content hash is
`BA2C0D205FE5E123781C7396BB758856BF31B1CB6ADFB8E5E9D2F0D62704D929`.

```powershell
$repo = 'workspace\quake'
Set-Location $repo
$env:TEMP = Join-Path $repo 'out\tmp-screen-update-repro'
$env:TMP = $env:TEMP
$env:TMPDIR = $env:TEMP
$profile = Join-Path $repo 'out\screen-update-dosbox-32m.conf'
Copy-Item (Join-Path $repo 'tools\dosbox-x-486-high.conf') $profile
$text = [IO.File]::ReadAllText($profile)
$text = [regex]::Replace($text, '(?m)^memsize[ \t]*=[ \t]*16[ \t]*$', 'memsize = 32')
[IO.File]::WriteAllText($profile, $text, [Text.Encoding]::ASCII)

pwsh -NoProfile -File tools/render-parity-dos.ps1 `
  -ReferenceProfile tools/renderer-profiles/i486-screen-update-c.json `
  -CandidateProfile tools/renderer-profiles/i486-screen-update-asm.json `
  -DosboxProfilePath out/screen-update-dosbox-32m.conf `
  -ExpectedProfileSha256 BA2C0D205FE5E123781C7396BB758856BF31B1CB6ADFB8E5E9D2F0D62704D929 `
  -CpuTarget i486 -NoBootstrap -ToolRoot out/tools -DataRoot testdata/id1 `
  -OutputRoot out/render-parity-screen-update-repro `
  -LocalOutputDirectoryPrefix screen-update-repro
```

To run the full cumulative release smoke against the current profile, load its
selector map into the runner's explicit selector parameters:

```powershell
$current = Get-Content tools/renderer-profiles/i486-asm-selectable-current.json -Raw | ConvertFrom-Json
$repo = 'workspace\quake'
Set-Location $repo
$env:TEMP = Join-Path $repo 'out\tmp-screen-update-smoke'
$env:TMP = $env:TEMP
$env:TMPDIR = $env:TEMP
$smoke = @{ NoBootstrap = $true; ToolRoot = 'out/tools'; DataRoot = 'testdata/id1'; CpuTarget = 'i486' }
foreach ($selector in $current.selectors.PSObject.Properties) {
  $smoke[$selector.Name] = [string]$selector.Value
}
& ./tools/smoke-dos.ps1 @smoke
```

This command builds when needed, runs the pinned DOSBox-X i486 smoke, checks
the build manifest against the requested selector values and writes
`out/dos-smoke/smoke-result.json`. Full renderer ownership, indirect-call
closure, stress scenarios and long-run stability remain open.
