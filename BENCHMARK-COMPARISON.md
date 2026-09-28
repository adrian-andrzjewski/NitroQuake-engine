# Quake DOS benchmark comparison

Measured on 2026-09-28 to compare the current 486quake build with the supplied
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

Profile SHA-256:

`F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45`

## Results

| Version | Executable | Runs | Time | FPS | Frames | Checksum | Evidence |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- |
| Current project build | `out\dos-memasm-zneg4-surf0rows4-surf1rows8-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm\qbench.exe` | 3 | **59.344208 s** median | **16.328468** | 969 each | `1047377823` each | Machine-readable timedemo report |
| 486quake optimization project | `tools\486quake.exe` | 1 | ~68.2 s | ~14.2 | 969 | Not emitted | On-screen timedemo result |
| Original Quake | `tools\QUAKE.EXE` | 1 | ~72.4 s | ~13.4 | 969 | Not emitted | On-screen timedemo result |

The three current-build samples were 59.344208 s, 59.344257 s, and 59.344203
s, with the same framebuffer checksum on every run. This build uses the
promoted `SurfaceBlockMip0Rows=unroll4` and
`SurfaceBlockMip1Rows=unroll8` defaults. The mip-1 change was measured against
the mip-0-only default and cleared the 0.05% promotion gate; see
`docs/PURE-ASSEMBLER-CANDIDATES.md` for the matched samples and correctness
evidence.

## Relative result

Using the rounded on-screen values for the two supplied executables:

- Current project build is approximately **22.0% faster** than the original.
- `486quake.exe` is approximately **6.2% faster** than the original.
- Current project build is approximately **14.9% faster** than `486quake.exe`.

These percentages are comparative DOSBox-X results. They are not a claim about
timing on physical 486 hardware.

## Reproducibility hashes

| File | Size | SHA-256 |
| --- | ---: | --- |
| `out\dos-memasm-zneg4-surf0rows4-surf1rows8-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm\qbench.exe` | 791,040 bytes | `6CAA9DF25898C08F02A2B89027F7F37B8FAA99AC36B4320243C8A70DD2853313` |
| `tools\486quake.exe` | 834,560 bytes | `CF461CFA0FEA989AA1E2E834B6D5482B7C64F3279BD7BE56C52F92752FFF429E` |
| `tools\QUAKE.EXE` | 409,600 bytes | `E0A1936400CA56E94D44D585097BD9E490035FCFB6E7D806D7E879F423928642` |

`tools\QUAKE.EXE` is an untracked supplied input and was not modified.
