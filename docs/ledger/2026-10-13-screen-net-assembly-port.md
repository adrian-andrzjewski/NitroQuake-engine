# SCR_DrawNet i486 assembly port

## Scope and mapping

This slice ports `SCR_DrawNet` from `src/screen.c` to `src/screen_netasm.s`.
The C implementation remains the reference and default. The new
`ScreenNetImplementation` selector wires the assembly entry into the screen
overlay dispatch while retaining the original C path for comparison.

The original behavior is unchanged: return when the most recent server message
is less than 0.3 seconds old, return during demo playback, otherwise draw
`scr_net` at `(scr_vrect.x + 64, scr_vrect.y)`. The assembly uses the 486
integer ISA and x87 operations for the original floating point threshold test.

Traceability:

| Original routine | Assembly replacement | Correctness evidence |
| --- | --- | --- |
| `SCR_DrawNet` | `SCR_DrawNet_asm486` in `src/screen_netasm.s` | `bench486_screennet.h`, paired DOSBox-X render parity |

## Validation

- `python tools/test-rendering.py`: 107 tests passed, including selector and
  assembly wiring assertions.
- `python tools/test-build-dos.py`: passed; both i386 and i486 source lists and
  golden flags include `screen_netasm.s`.
- The direct C/assembly fixture passed 40 exact cases (10 input cases under
  each of the four x87 rounding modes). It checks draw calls and arguments,
  calling-convention results, and x87 control/status state.
- The paired render harness passed on DOSBox-X 2026.08.31 with the pinned 32 MB
  i486 profile (SHA-256
  `BA2C0D205FE5E123781C7396BB758856BF31B1CB6ADFB8E5E9D2F0D62704D929`). The C
  and assembly profiles differ only in `ScreenNetImplementation`. Both runs
  had exact 320x200 indexed-frame and palette matches: zero pixel and palette
  differences. Their checksum streams matched exactly for all 980 compared
  frames per run after six warmup frames; each timedemo contained 985 frames.
- This demo is played back, so `SCR_DrawNet` takes its demo-playback early
  return. The paired scene validates integration and frame stability; the
  direct fixture covers the live drawing and decision branches.
- Complete candidate ISA gate passed: 277,409 linked opcodes, 529 DOS startup
  code rows, and 9,207 CWSDPMI instructions; zero above-i486, unknown, or
  exempt instructions. The candidate build also passed object, linked-object,
  source-mapping, and provider proofs.

## Benchmark

On the paired Demo 2 run, the C profile median was 12.1680555 FPS and the
assembly profile median was 12.1680385 FPS. They are effectively equal at the
precision of this measurement; speed was not the acceptance criterion.

## Reproduction

From `workspace\quake`, with build tools already installed under
`out\tools`, recreate the pinned 32 MB profile and run:

```powershell
$repo = 'workspace\quake'
Set-Location $repo
$env:TEMP = Join-Path $repo 'out\tmp-screen-net-parity'
$env:TMP = $env:TEMP
$env:TMPDIR = $env:TEMP
$env:PYTHONPYCACHEPREFIX = Join-Path $repo 'out\pycache'
$profile = Join-Path $repo 'out\screen-update-dosbox-32m.conf'
Copy-Item (Join-Path $repo 'tools\dosbox-x-486-high.conf') $profile
$profileText = [IO.File]::ReadAllText($profile)
$profileText = [regex]::Replace($profileText, '(?m)^memsize[ \t]*=[ \t]*16[ \t]*$', 'memsize = 32')
[IO.File]::WriteAllText($profile, $profileText, [Text.Encoding]::ASCII)
pwsh -NoProfile -File tools/render-parity-dos.ps1 `
  -NoBootstrap -ToolRoot 'workspace\quake\out\tools' `
  -DataRoot 'workspace\quake\testdata\id1' -CpuTarget i486 `
  -DosboxProfilePath $profile `
  -ExpectedProfileSha256 BA2C0D205FE5E123781C7396BB758856BF31B1CB6ADFB8E5E9D2F0D62704D929 `
  -ReferenceProfile tools/renderer-profiles/i486-screen-net-c.json `
  -CandidateProfile tools/renderer-profiles/i486-screen-net-asm.json `
  -Scenario demo2-entity-workload -RunsOverride 2 `
  -LocalOutputDirectoryPrefix screennet-repro `
  -OutputRoot out/render-parity-screennet-repro
```

The successful report from this port is
`out/render-parity-screennet-32m-retry-20261013/render-parity-result.json`.
Build, emulator, temporary, and report files are written under `D:`.

## Remaining scope

This slice does not complete the renderer port. Renderer ownership analysis,
indirect-call closure, remaining C renderer/support routines, broader stress
scenes, and long-running state and memory checks remain open.
