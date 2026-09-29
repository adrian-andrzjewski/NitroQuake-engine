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
| Current project build | `out\dos-memasm-zneg4-surf0rows4-surf0hflat-surf1rows8-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm\qbench.exe` | 3 | **59.265411 s** median | **16.350178** | 969 each | `1047377823` each | Machine-readable timedemo report |
| 486quake optimization project | `tools\486quake.exe` | 1 | ~68.2 s | ~14.2 | 969 | Not emitted | On-screen timedemo result |
| Original Quake | `tools\QUAKE.EXE` | 1 | ~72.4 s | ~13.4 | 969 | Not emitted | On-screen timedemo result |

The three current-build samples were 59.265453 s, 59.265404 s, and 59.265411
s, with the same framebuffer checksum on every run and a spread of 0.000049 s.
This build uses the promoted `SurfaceBlockMip0Rows=unroll4`,
`SurfaceBlockMip1Rows=unroll8`, and `SurfaceBlockMip0HorizontalFlat=fast`
defaults. See `docs/PURE-ASSEMBLER-CANDIDATES.md` for the matched samples and
correctness evidence behind those promotions.

## Relative result

Using the rounded on-screen values for the two supplied executables:

- Current project build is approximately **18.1% faster** than the original.
- `486quake.exe` is approximately **5.8% faster** than the original.
- Current project build is approximately **13.1% faster** than `486quake.exe`.

These percentages are comparative DOSBox-X results. They are not a claim about
timing on physical 486 hardware. The emulator does not model 486 costs in the
dimensions most 486-specific optimizations target: nine serialized x87
operations measure about 1.04 cycles each here, where a 486DX spends roughly 12
per op and 30-90 on `FISTP` alone. Treat a win measured here as real, and a null
as weak evidence.

## Reproducibility hashes

| File | Size | SHA-256 |
| --- | ---: | --- |
| `out\dos-memasm-zneg4-surf0rows4-surf0hflat-surf1rows8-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm\qbench.exe` | 792,064 bytes | `9F6BEC673DCB16D16A14761920DBC8563D0CECA657776B70711CBE3A8224C5E7` |
| `tools\486quake.exe` | 834,560 bytes | `CF461CFA0FEA989AA1E2E834B6D5482B7C64F3279BD7BE56C52F92752FFF429E` |
| `tools\QUAKE.EXE` | 409,600 bytes | `E0A1936400CA56E94D44D585097BD9E490035FCFB6E7D806D7E879F423928642` |

`qbench.exe` embeds `__TIME__`/`__DATE__` in a startup banner
(`WinQuake\host.c:912`), so it is **not byte-reproducible**: the hash above
identifies that one build, not the source. Six stamp bytes differ between any
two builds of identical source. Framebuffer checksum `1047377823` is the
stable identity of the build's output.

`tools\QUAKE.EXE` is an untracked supplied input and was not modified.
