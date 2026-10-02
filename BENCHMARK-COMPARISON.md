# Quake DOS benchmark comparison

Measured on 2026-09-29 to compare the current 486quake build with the supplied
optimized and original DOS executables. This document is intended as the source
record for a later README benchmark section.

## Method

- Runtime: DOSBox-X 2026.08.31.
- Profile: `tools/dosbox-x-486-high.conf`, fixed 33445 cycles, 486 CPU profile.
- Workload: Quake `demo1`, with sound, joystick, mouse, and CD audio disabled.
- Game data: `C:\Program Files (x86)\Steam\steamapps\common\Quake\id1`.
- DPMI host: `WinQuake\cwsdpmi.exe`.
- Each valid run completed 969 frames.
- The current build was measured with three runs and the median is reported.
- The supplied executables were measured with one run each because they display
  their result on-screen but do not produce the repository runner's
  machine-readable `timedemo.txt` or framebuffer-checksum report.

**Per-frame FPS collection was OFF for every number in the table.** It costs two
`Sys_FloatTime` reads per frame, which is 0.0117 s over 969 frames — 0.020%, or
**39% of the 0.05% promotion gate** — so it is now opt-in via `-FpsStats`
rather than on by default. A run with it enabled prints a warning that its
result is a diagnostic and not a promotion measurement, and the resolved value
is written to the report JSON as `frameFpsStats`. Confirmed 2026-10-01: with it
off the tree reproduces this baseline at 59.227628 s median
(59.227596 / 59.227628 / 59.227631), a 0.0005% difference; with it on, the same
binary measures 59.239011 s.

Profile SHA-256:

`F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45`

This hash is recorded, not enforced: `tools\timedemo-dos.ps1` computes it and
writes it into each report, but no code compares it to this constant. A change
to the DOSBox-X configuration or core would therefore re-baseline every number
here without being detected. See `ASM486-HANDOFF.md`, "What this harness can
and cannot measure".

## Results

| Version | Executable | Runs | Time | FPS | Frames | Checksum | Evidence |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- |
| Current project build | `out\dos-memasm-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm\qbench.exe` | 3 | **59.160558 s** median | **16.379156** | 969 each | `1047377823` each | `out\dos-timedemo-20261002-181621` |
| Previous build (mip-1 flat off) | same path, `-SurfaceBlockMip1HorizontalFlat control` | 3 | 59.227632 s median | 16.360597 | 969 each | `1047377823` each | `out\dos-timedemo-20261001-184432` |
| Previous build (1800 KB surface cache) | same path, previous binary | 3 | 59.264965 s median | 16.350301 | 969 each | `1047377823` each | `out\dos-timedemo-20260929-175705` |
| 486quake optimization project | `tools\486quake.exe` | 1 | ~68.2 s | ~14.2 | 969 | Not emitted | On-screen timedemo result |
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
`ASM486-HANDOFF.md`, "`surf8` flat axis: three measured wins bundled and
**PROMOTED, 0.0620%**".

The row below it, 59.227632 s, is the same source with
`SurfaceBlockMip1HorizontalFlat` set to `control`, measured as three alternating
control/candidate pairs: 0.030368 s, **0.0513% faster**, about 353x the
0.000086 s control spread, with
every candidate run faster than every control run. That is the
`SurfaceBlockMip1HorizontalFlat=fast` promotion; see `ASM486-HANDOFF.md`,
"mip-1 horizontal-flat surface blocks". The 1800 KB row is the same selector set
with the surface cache at 1800 KB; the 2400 KB default measured **0.0635%
faster** (delta 0.037636 s, about 770x the run spread), and the checksum was
`1047377823` on all six A/B runs. See `ASM486-HANDOFF.md`, "The 1800 KB
surface-cache wall does not exist". This build
uses the promoted `SurfaceBlockMip0Rows=unroll4`,
`SurfaceBlockMip0HorizontalFlat=fast`, `SurfaceBlockMip1Rows=unroll8`, and
`SurfaceBlockMip1HorizontalFlat=fast` defaults. See
`docs/PURE-ASSEMBLER-CANDIDATES.md` for the matched samples and
correctness evidence behind those promotions.

## Relative result

Using the rounded on-screen values for the two supplied executables:

- Current project build is approximately **18.3% faster** than the original.
- `486quake.exe` is approximately **5.8% faster** than the original.
- Current project build is approximately **13.4% faster** than `486quake.exe`.

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
| `tools\486quake.exe` (supplied) | SHA-256, 834,560 bytes | `CF461CFA0FEA989AA1E2E834B6D5482B7C64F3279BD7BE56C52F92752FFF429E` |
| `tools\QUAKE.EXE` (supplied) | SHA-256, 409,600 bytes | `E0A1936400CA56E94D44D585097BD9E490035FCFB6E7D806D7E879F423928642` |
| `tools\dosbox-x-486-high.conf` (profile) | SHA-256 | `F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45` |

`qbench.exe` deliberately has **no SHA-256 recorded here**. It embeds
`__TIME__`/`__DATE__` in a startup banner (`WinQuake\host.c:912`), so it is not
byte-reproducible: six stamp bytes differ between any two builds of identical
source, and any hash would describe one incidental build rather than the code.
Recording a checksum and not a hash is the accurate choice, not a
provisional one. The framebuffer checksum is the stable identity of the
build's output: it must be `1047377823` on every run for the build to be
considered correct.

`tools\QUAKE.EXE` and `tools\486quake.exe` are untracked supplied inputs and
were not modified; their hashes are stable and are recorded for provenance.
