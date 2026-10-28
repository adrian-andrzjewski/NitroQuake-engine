# Quake DOS benchmark comparison

Measured on 2026-09-29 to compare the current NitroQuake build with the supplied
optimized and original DOS executables. This document is intended as the source
record for a later README benchmark section.

## Method

- Runtime: DOSBox-X 2026.08.31.
- Profile: `tools/dosbox-x-486-high.conf`, fixed 33445 cycles, 486 CPU profile.
- Workload: Quake `demo1`, with sound, joystick, mouse, and CD audio disabled.
- Game data: `C:\Program Files (x86)\Steam\steamapps\common\Quake\id1`.
- DPMI host: `src\cwsdpmi.exe`.
- Each valid run completed 969 frames.
- The current build was measured with three runs and the median is reported.
- The supplied executables were measured with one run each because they display
  their result on-screen but do not produce the repository runner's
  machine-readable `timedemo.txt` or framebuffer-checksum report.

**Per-frame FPS collection was OFF for every number in the table.** It costs two
`Sys_FloatTime` reads per frame, about 0.0117 s over 969 frames, so it remains
opt-in via `-FpsStats` to keep promotion comparisons uninstrumented. The 0.05%
floor referenced in the historical measurements below was removed on
2026-10-20. Promotion accepts any positive pooled mean from at least three
matched runs per variant, including a delta smaller than run-to-run variation;
record the samples and spread with the result. Exact parity and the strict i486
audit remain required gates. A run with FPS collection enabled prints a warning
that its result is diagnostic rather than a promotion measurement, and the
resolved value is written to the report JSON as `frameFpsStats`. Confirmed
2026-10-01: with it off the tree reproduces this baseline at 59.227628 s median
(59.227596 / 59.227628 / 59.227631), a 0.0005% difference; with it on, the same
binary measures 59.239011 s.

Profile SHA-256:

`F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45`

This hash **is enforced**, as of the 2026-09-30 harness-integrity pass:
`tools\timedemo-dos.ps1:548-556` compares it against
`-ExpectedProfileSha256` and throws unless `-AllowGateOverride` is passed.
`timedemo-dos.ps1:104` holds the constant. An earlier revision of this file
correctly recorded it as *"recorded, not enforced"*; that is no longer true, and
the same correction applies to `BUILD-DOS.md`, which now says to grep
`ExpectedProfileSha256` rather than trust a line number. See
`docs/ledger/2026-09-29-harness-and-cost-model.md`, under "What this harness can and cannot measure".

## Results

| Version | Executable | Runs | Time | FPS | Frames | Checksum | Evidence |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- |
| Current project build | `out\dos-memasm-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm\qbench.exe` | 3 | **59.160558 s** median | **16.379156** | 969 each | `1047377823` each | `out\dos-timedemo-20261002-181621` |
| Previous build (mip-1 flat off) | same path, `-SurfaceBlockMip1HorizontalFlat control` | 3 | 59.227632 s median | 16.360597 | 969 each | `1047377823` each | `out\dos-timedemo-20261001-184432` |
| Previous build (1800 KB surface cache) | same path, previous binary | 3 | 59.264965 s median | 16.350301 | 969 each | `1047377823` each | `out\dos-timedemo-20260929-175705` |
| NitroQuake optimization project | `tools\NitroQuake.exe` | 1 | ~68.2 s | ~14.2 | 969 | Not emitted | On-screen timedemo result |
| Original Quake | `tools\QUAKE.EXE` | 1 | ~72.4 s | ~13.4 | 969 | Not emitted | On-screen timedemo result |

The current-build samples were 59.160558 s, 59.160577 s and 59.160502 s, with
the same framebuffer checksum on every run and a spread of 0.000075 s. This row
is the `surf8` flat-axis promotion: `SurfaceBlockMip0Rows=unroll16` and
`SurfaceBlockMip1IndexHoist=hoist`, three components worth 0.0132%, 0.0353% and
0.0126% individually, bundled because the gate applies to the total delta. The
matched A/B measured **0.06198% faster** (delta 0.036689 s, 1,359x the clean
control spread, every candidate run faster than every control run), against a
predicted 0.036716 s from the instruction model — 0.07% error. `bench486`
correctness PASS with end checksum `2378409472` and DOS smoke clean. See
`docs/ledger/2026-10-02-surf8-bundle-and-promotion.md`, under "`surf8` flat axis: three measured wins bundled and
**PROMOTED, 0.0620%**".

**The row above was re-verified five more times on 2026-10-02 and 2026-10-03 and
the baseline has not moved.** Twelve dead-scratch probes were run across
`-EdgeScanProbe`, `-RenderFaceProbe` and `-SpanSetupProbe`; each pair re-measured
the control, which is what a probe is priced against. Those control medians were
59.160585, 59.160560, 59.160577, 59.160532, 59.160566, 59.160577, 59.160605,
59.160535, 59.160541, 59.160577, 59.160569 and the release re-measures closed at
**59.160535 s**, **59.160569 s** and **59.160545 s** — every one inside 0.0001% of
the recorded 59.160558 s. Nothing was promoted on either day, so this row is
unchanged and remains the current project build.

`tools\probe-ab.ps1` is the runner those pairs used: three control runs, three
probe runs and a trailing control, checksum enforced on all seven. The trailing
control exists because **this host produces isolated ~0.36 s timedemo outliers**
— one probe control block had its first run be the outlier, which understated its
signal ratio by about 14,000x. See `BUILD-DOS.md` for the invocation traps, all
five of which produce a wrong answer rather than an error.

The row below it, 59.227632 s, is the same source with
`SurfaceBlockMip1HorizontalFlat` set to `control`, measured as three alternating
control/candidate pairs: 0.030368 s, **0.0513% faster**, about 353x the
0.000086 s control spread, with
every candidate run faster than every control run. That is the
`SurfaceBlockMip1HorizontalFlat=fast` promotion; see `docs/ledger/2026-10-01-attribution-corrections.md`,
"mip-1 horizontal-flat surface blocks". The 1800 KB row is the same selector set
with the surface cache at 1800 KB; the 2400 KB default measured **0.0635%
faster** (delta 0.037636 s, about 770x the run spread), and the checksum was
`1047377823` on all six A/B runs. See `docs/ledger/2026-09-30-harness-fidelity-and-sourcing.md`, under "The 1800 KB
surface-cache wall does not exist". This build
uses the promoted `SurfaceBlockMip0Rows=unroll16`,
`SurfaceBlockMip0HorizontalFlat=fast`, `SurfaceBlockMip1Rows=unroll8`,
`SurfaceBlockMip1HorizontalFlat=fast`, and `SurfaceBlockMip1IndexHoist=hoist`
defaults. `unroll16` and the index hoist were bundled with a fully-flat mip-1
body on 2026-10-02 for 0.0620%; this line previously said `unroll4`, which was
correct when written and is now two promotions out of date.
`tools\build-dos.ps1:36-46` is the authority. See
`docs/PURE-ASSEMBLER-CANDIDATES.md` for the matched samples and
correctness evidence behind those promotions.

## Relative result

Using the rounded on-screen values for the two supplied executables:

- Current project build is approximately **18.3% faster** than the original.
- `NitroQuake.exe` is approximately **5.8% faster** than the original.
- Current project build is approximately **13.4% faster** than `NitroQuake.exe`.

These percentages are comparative DOSBox-X results. They are not a claim about
timing on physical 486 hardware. The emulator does not model 486 costs in the
dimensions most 486-specific optimizations target: nine serialized x87
operations measure about 1.04 cycles each here, where a 486DX spends roughly 12
per op and 30-90 on `FISTP` alone. Treat a win measured here as real, and a null
as weak evidence.

## Reproducibility

The built executable is identified by its **framebuffer checksum**, not by a
file hash:

| Artifact | Identity | Value |
| --- | --- | --- |
| `qbench.exe` (this build's output) | framebuffer checksum, 969 frames | `1047377823` |
| `tools\NitroQuake.exe` (supplied) | SHA-256, 834,560 bytes | `CF461CFA0FEA989AA1E2E834B6D5482B7C64F3279BD7BE56C52F92752FFF429E` |
| `tools\QUAKE.EXE` (supplied) | SHA-256, 409,600 bytes | `E0A1936400CA56E94D44D585097BD9E490035FCFB6E7D806D7E879F423928642` |
| `tools\dosbox-x-486-high.conf` (profile) | SHA-256 | `F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45` |

`qbench.exe` deliberately has **no SHA-256 recorded here**. It embeds
`__TIME__`/`__DATE__` in a startup banner (`src\host.c:912`), so it is not
byte-reproducible: six stamp bytes differ between any two builds of identical
source, and any hash would describe one incidental build rather than the code.
Recording a checksum and not a hash is the accurate choice, not a
provisional one. The framebuffer checksum is the stable identity of the
build's output: it must be `1047377823` on every run for the build to be
considered correct.

`tools\QUAKE.EXE` and `tools\NitroQuake.exe` are untracked supplied inputs and
were not modified; their hashes are stable and are recorded for provenance.
