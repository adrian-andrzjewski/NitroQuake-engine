# SCR_DrawTurtle i486 assembly port

## Scope and mapping

This slice ports the screen turtle warning routine from `src/client/screen.c` to
`src/client/screen_turtleasm.s`. The C routine remains selectable as the reference.
The assembly entry is wired through the screen overlay path and can be
selected independently with `ScreenTurtleImplementation`.

The original behavior is retained: return if `scr_showturtle` is zero; reset
the persistent frame counter when `host_frametime < 0.1`; otherwise increment
the counter and draw `scr_turtle` at the viewport origin once the count reaches
three. The assembly preserves the C routine's x87 comparison sequence,
including unordered floating point cases.

| Original routine | Assembly replacement | Correctness evidence |
| --- | --- | --- |
| `SCR_DrawTurtle` | `SCR_DrawTurtle_asm486` in `src/client/screen_turtleasm.s` | `bench486_screenturtle.h`; focused C/assembly DOSBox-X parity |

## Validation

- `python tools/test-rendering.py`: 109 tests passed, including the selector,
  fixture wiring, and conditional C alias scanner regression.
- `python tools/test-build-dos.py`: passed for i386 and i486 source inventories
  and golden build flags.
- The direct DOSBox-X fixture passed 14 exact input cases under each of four
  x87 rounding modes and a 2,048-frame state sequence under all four modes.
  It checks draw calls and arguments, counter state, calling convention, and
  x87 control/status state.
- Both focused profiles passed the complete strict i486 gates. The C profile
  verified 277,827 linked instructions; the assembly profile verified
  278,666. The respective renderer object audits decoded 239,530 and 240,369
  instructions. Both profile builds also passed the 529-row startup loader
  audit and the 9,207-instruction CWSDPMI provider audit. Every report showed
  zero above-i486 or unclassified instructions and zero exemptions.
- `demo2-screenturtle-visible` ran twice per profile under DOSBox-X configured
  as a 32 MB 486. The paired profiles differ only in
  `ScreenTurtleImplementation`. After six warmup frames, all 980 compared
  frame checksums matched exactly on each run. Both 320x200 indexed captures
  matched all 64,000 pixels and all palette bytes: zero pixel and palette
  mismatches. Each timedemo ended at framebuffer checksum `2048962232`, with
  no frame overflow.
- The current renderer ownership scanner resolved all selected roots. Its
  inventory remains a partial call graph with C dependencies and unresolved
  callees; this slice does not certify the full renderer.

## Benchmark

The paired Demo 2 medians were 12.178681 FPS for C and 12.1786815 FPS for
assembly. This is effectively unchanged at the precision of the measurement.

## Reproduction

Run from `workspace\quake`. The pinned 32 MB DOSBox-X profile
is `out\screen-update-dosbox-32m.conf`; its normalized SHA-256 is
`BA2C0D205FE5E123781C7396BB758856BF31B1CB6ADFB8E5E9D2F0D62704D929`.
Keep temporary files and reports under `out`.

```powershell
$repo = 'workspace\quake'
Set-Location $repo
$env:TEMP = Join-Path $repo 'out\tmp-screen-turtle-parity'
$env:TMP = $env:TEMP
$env:TMPDIR = $env:TEMP
$env:PYTHONPYCACHEPREFIX = Join-Path $repo 'out\pycache'
pwsh -NoProfile -File tools\render-parity-dos.ps1 `
  -ReferenceProfile tools\renderer-profiles\i486-screen-turtle-c.json `
  -CandidateProfile tools\renderer-profiles\i486-screen-turtle-asm.json `
  -ScenarioFile tools\render-scenarios-screenturtle.json `
  -OutputRoot out\render-parity-screen-turtle-repro `
  -LocalOutputDirectoryPrefix screenturtlerepro `
  -ToolRoot (Join-Path $repo 'out\tools') `
  -DataRoot (Join-Path $repo 'testdata\id1') `
  -DosboxProfilePath out\screen-update-dosbox-32m.conf `
  -ExpectedProfileSha256 BA2C0D205FE5E123781C7396BB758856BF31B1CB6ADFB8E5E9D2F0D62704D929 `
  -CpuTarget i486 -NoBootstrap
```

## Remaining scope

The full renderer remains incomplete. BSP/world traversal, edge and span
work, surface generation, texturing, lighting, sky, water, particles, alias
models, screen and supporting paths still contain substantial C code or
unclosed ownership and stress-test paths. The broader renderer ledger remains
the authority for the current remaining-work inventory.
