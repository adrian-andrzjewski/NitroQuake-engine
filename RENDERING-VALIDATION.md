# Rendering benchmark and validation suite

## Run the suite

The scenario driven renderer suite supplements the function-level `bench486`
microbenchmarks and the single `demo1` promotion timedemo. It runs stock demos
through the benchmark build with `host_framerate 0.0783` to make renderer frame
content repeatable at the measured timedemo cadence. It saves a PCX snapshot and
checksum for every rendered frame, then compares snapshots with committed
references. The reported timedemo rate is incidental to this correctness run;
use `timedemo-dos.ps1` or `bench-dos.ps1` for performance comparisons.

```powershell
./tools/render-validation-dos.ps1 -NoBootstrap
./tools/render-validation-dos.ps1 -Scenario demo1-vga-full,demo1-fullbright,demo1-viewsize-50 -NoBootstrap
./tools/render-validation-dos.ps1 -ListScenarios
./tools/render-parity-dos.ps1 -Scenario demo1-vga-full,demo3-world-workload -NoBootstrap
python ./tools/test-rendering.py
python ./tools/test-rendering-reports.py
```

`tools/run-tests.ps1` runs the full rendering suite by default. Pass
`-SkipRendering` to omit it; pass `-SkipRendering -SkipSlow` for the shortest
full host/build pass. The complete DOSBox-X suite takes roughly 16 minutes on
the pinned 486 profile; use `-Scenario` to run a focused subset during
development. A rendering run writes a suite JSON report under
`out/render-validation-*`. Its per-run PCX captures, frame checksum logs, and
diff images remain in the corresponding `out/dos-timedemo-*` staging directory.
The suite JSON records each scenario's source fingerprint, DOSBox profile hash
and version, commands, expected frame/checksum pins, FPS, image metrics, and
artifact paths for comparison across runs. It also records a separate source
tree fingerprint that excludes selector-specific build flags.

The suite currently covers:

| Scenario | Workload and path |
| --- | --- |
| `demo1-vesa-full` | Default VESA presentation, full viewport |
| `demo1-vga-full` | Forced VGA mode 13h presentation, full viewport |
| `demo1-fullbright` | VESA presentation with Quake's fullbright lighting feature enabled |
| `demo1-viewsize-50` | VESA presentation with a reduced software viewport |
| `demo2-entity-workload` | Alternate stock demo and entity workload |
| `demo3-world-workload` | Alternate stock demo and world rendering workload |

Each listed scenario runs twice so repeatability covers both presentation
paths, quality settings, and demo workloads.

This DOS renderer exposes 320x200x8 output modes. VESA and VGA therefore exercise
different presentation paths at that output size; the fullbright and viewsize
scenarios check alternate lighting and viewport quality settings. The suite does
not claim to test unsupported video resolutions.

## Correctness gates

Each timedemo checks the scenario's expected frame count and final framebuffer
checksum when those values are pinned in `tools/render-scenarios.json`. The
per-frame checksum log must be complete, consecutive, and have no overflow. The
log count must be exactly one setup frame beyond the timedemo's measured frame
count. Every scenario runs twice. The first six recorded frames are startup
warmup; all later checksums must match, with the first differing frame reported
and both source logs retained. This catches timing or rendering instability
without treating initialization frames as scene output.

Per-frame checksum capture adds one full-buffer scan and a DOS file write after
each rendered frame. On a reduced-viewport timedemo this changed the final
checksum even with fixed `host_framerate`, so compare checksum streams only
between runs using the same instrumentation. Use captured PCX comparisons for
pixel error and uninstrumented timedemos for promotion timing.

Each PCX snapshot is decoded to RGB using its own palette and compared against
the scenario reference. The default tolerance allows channel differences up to
2 without counting a changed pixel, at most 0.05% of pixels above that channel
threshold, and mean absolute RGB error no higher than 0.5. The VGA case has a
separate tolerance for its known presentation-path variation. The thresholds
are in the scenario manifest so reviewers can see and adjust them with the
reference they protect.

The comparator reports image dimensions, changed-pixel count and fraction,
mean and maximum channel error, and whether the palettes match. It writes a PNG
diff: unchanged pixels are shown in grayscale and pixels beyond the channel
threshold are highlighted. A dimension mismatch always fails. These measures
keep a handful of small palette or rounding differences from failing the suite
while making larger visual changes easy to locate.

For a direct C-reference versus assembly timedemo comparison, preserve each
run's `framechecksums.txt` and compare the streams with:

```powershell
python ./tools/compare-rendering.py reference-framechecksums.txt candidate-framechecksums.txt --frame-checksums --report-json out/frame-stream-diff.json
python ./tools/compare-rendering.py reference-framechecksums.txt candidate-framechecksums.txt --frame-checksums --ignore-leading-frames 6 --require-exact
```

The report gives the compared frame count, mismatch count, and first and last
mismatching frames. `--require-exact` turns any mismatch into a failing gate.
A checksum difference locates a frame for inspection; it does not measure the
pixel error, so compare captured PCX images with the tolerance comparator before
accepting a non-exact frame.

For a complete paired-profile check, `render-parity-dos.ps1` runs the deterministic
scene suite once with the C-reference profile and once with the selected assembly
profile. It checks that the source tree stayed identical across both runs, then
compares every paired checksum stream after the configured warmup and every
captured framebuffer exactly: all 8-bit pixel indices and all 768 palette bytes
must match. It writes a combined JSON report and one PNG diff per captured run.
Any missing scenario/run, source-tree change, checksum difference, pixel-index
difference, palette difference, or failed input suite makes the parity gate fail.
The paired runner copies the scenario manifest under its output directory and
adds `con_notifytime -1` so wall-clock notification expiry cannot create
transient overlay differences in per-frame comparisons. Paired runs defer
committed-golden image and final-checksum pins, then compare every C checksum
stream and capture directly with its assembly counterpart. This still requires
matching frame counts, repeat stability within each profile, and exact
cross-profile checksum, pixel-index, and palette-byte equality. Run the ordinary
`render-validation-dos.ps1` suite with its unmodified manifest to enforce the
committed-golden images and checksum pins. Use `-KeepTransientNotifications`
when notifications themselves are the subject of a dedicated visual scenario;
the exact C-versus-assembly gates still apply.

```powershell
./tools/render-parity-dos.ps1 -NoBootstrap
./tools/render-parity-dos.ps1 -Scenario demo1-vesa-full,demo2-entity-workload -NoBootstrap
./tools/render-parity-dos.ps1 -ScenarioFile out/my-deterministic-scenes.json -NoBootstrap
```

The defaults use `i486-c-reference.json` and `i486-asm-selectable.json`; use
`-ReferenceProfile` and `-CandidateProfile` to compare other selector variants.
For already-generated reports, invoke `compare-rendering-reports.py` directly.
Reports created before `sourceTreeFingerprint` was added require
`--allow-unpinned-sources` for diagnostic comparisons and cannot pass the normal
paired-profile gate.

`tools/test-rendering.py` exercises PCX decoding, tolerance boundaries,
dimension failures, PNG output, and frame-log integrity without DOSBox.
`tools/test-rendering-reports.py` exercises exact paired-report checks, including
the case where different palette indices render to the same RGB color. These
host tests do not substitute for running the renderer scenarios.

## Reproduce the `SCR_UpdateScreen` assembly slice

The focused `i486-screen-update-c.json` and `i486-screen-update-asm.json`
profiles differ only in `ScreenUpdateImplementation`. The exact pair covers
seven deterministic demo workloads twice each and requires identical
post-warmup checksums, indexed pixels and all palette bytes. Demo 2 requires a
32 MB DOSBox-X memory profile. `render-parity-dos.ps1` accepts a custom profile
only with an explicit SHA-256 pin; the accepted profile is the pinned
`tools/dosbox-x-486-high.conf` with only `memsize` changed to 32.

Keep emulator, build and temporary files under D: and recreate the pinned
profile as follows:

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
. (Join-Path $repo 'tools\common.ps1')
$profileHash = Get-TextFileHash -Path $profile
if ($profileHash -ne 'BA2C0D205FE5E123781C7396BB758856BF31B1CB6ADFB8E5E9D2F0D62704D929') {
    throw "Unexpected screen-update DOSBox profile hash: $profileHash"
}

pwsh -NoProfile -File tools/render-parity-dos.ps1 `
  -ReferenceProfile tools/renderer-profiles/i486-screen-update-c.json `
  -CandidateProfile tools/renderer-profiles/i486-screen-update-asm.json `
  -DosboxProfilePath out/screen-update-dosbox-32m.conf `
  -ExpectedProfileSha256 $profileHash `
  -CpuTarget i486 -NoBootstrap -ToolRoot out/tools -DataRoot testdata/id1 `
  -OutputRoot out/render-parity-screen-update-repro `
  -LocalOutputDirectoryPrefix screen-update-repro
```

The direct fifteen-case fixture runs with
`bench-dos.ps1 -ScreenUpdateImplementation asm -ScreenUpdateOnly` and writes
`bench-result.json`. For a full cumulative release build and DOSBox-X i486
smoke, the current selector JSON can populate the smoke runner's explicit
parameters:

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

The smoke runner checks the selected build manifest and writes
`out/dos-smoke/smoke-result.json`. A host test ensures it continues to accept
every selector in the cumulative profile. Full scene parity and the strict
executable audit remain required after future renderer changes.

## Add or re-baseline a scene

Use an included deterministic Quake demo and keep the workload fixed. Add its
expected measured frame count, end framebuffer checksum, capture frame, repeat
count, reference path, and tolerance to `tools/render-scenarios.json`. Capture
references from the pinned DOSBox-X profile and current accepted executable.
Record the source fingerprint and command line in the suite result before
promoting new references. Do not replace a reference from an output that failed
its frame-count or checksum gate.

If an image comparison fails, the JSON report names the scenario, expected and
actual image paths, tolerance, and measured image metrics. The diff image and
frame checksum logs are retained with the timedemo output. If the benchmark
fails before producing a capture, the runner output and timedemo result path are
included in the failure record.
