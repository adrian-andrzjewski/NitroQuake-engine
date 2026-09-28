# Building the MS-DOS WinQuake software renderer on Windows

## Text-mode startup summary

Immediately before the first graphics mode, DOS Quake prints a compact ASCII
summary: DPMI-reported CPU class, successful FPU startup check, DOS/DPMI versions,
DPMI-reported physical RAM, and the separately allocated Quake heap. Unsupported
or failed diagnostic queries print `unknown` and do not stop startup. CPU reporting
does not require CPUID. Memory is shown in KiB (1024 bytes).

The video line describes the available automatic 320x200 candidate: VESA linear,
VESA banked (including BIOS mode and pitch), or VGA fallback. Discovery is reused;
saved configuration and explicit mode commands apply later, and a candidate can
still fail during activation. `-stdvid` reports forced VGA with VESA discovery
skipped.

Startup continues without input or delay by default. Add `-sysinfo-pause` to read
the text screen, then press and release Enter. The DOS interrupt input queue
consumes the dismissal and held-key releases before gameplay. Dedicated startup
prints the information once with video disabled. Dedicated and benchmark builds
ignore the pause switch.

Host-side focused checks: `python tools/test-sysinfo-dos.py` and
`python tools/test-video-dos.py`. These do not replace emulator or physical-machine
visual/input checks, or the existing benchmark acceptance gates.

This checkout builds the retained WinQuake MS-DOS/software-renderer source
directly from Windows 10.  The compiler is a Windows-hosted DJGPP cross
toolchain; DOSBox-X is used only to run the resulting DOS executable.

The experimental status and next-agent continuation plan are maintained in
`ASM486-HANDOFF.md`.  This document is the operational reference for building,
running, benchmarking, and interpreting the results.

The bootstrapper installs both tools in:

~~~text
%LOCALAPPDATA%\486quake\tools
~~~

It does not modify the system PATH or install anything globally.  Archive
URLs and SHA-256 values are pinned in tools/dos-toolchain.json.

## Build

### DOS video startup

Mode index `0` remains VGA mode 13h. After the startup configuration has run,
an unset/zero `_vid_default_mode` automatically selects a BIOS-reported VBE 2.0
320x200 packed 8-bit mode. Linear framebuffer modes take priority over banked
modes. Banked modes must fit completely in one readable/writable window.
Saved nonzero defaults and explicit `+vid_mode N` choices take precedence over
automatic selection. `-stdvid` forces VGA startup and skips VESA discovery;
runtime `vid_mode N` changes and `vid_testmode` remain available.

320x200 VESA renders into tightly packed RAM and copies dirty rectangles to
one display page. Matching full-width pitches use a single transfer through
the existing i486 assembly copier. Padded hardware pitches retain row copies.
The default path has no retrace waits, display-start calls, or per-frame bank
switches. `_vid_wait_override 1` requests the legacy vsync override; explicit
`vid_wait 1` (vsync) and `vid_wait 2` (display enable) are honored where the VGA
status register supports them. Tearing is possible with waits disabled.

Discovery/allocation/mapping/BIOS initialization failures fall back to mode
13h. A failed requested mode gets one VGA recovery attempt, with no recursive
restoration or automatic retry. Backend, BIOS mode, pitch and failures are
logged to the console (`-condebug` also writes `id1/qconsole.log`). Active
linear mappings are released on mode changes and shutdown.

Run `python tools/test-video-dos.py` with native GCC for the mocked BIOS,
startup/recovery, direct-rectangle, padded-pitch and copy-boundary checks.
See [VIDEO-DOS-VALIDATION.md](VIDEO-DOS-VALIDATION.md) for DOSBox validation and
the distinction between framebuffer parity and displayed-output inspection.

### Compiler invocation

From the repository root in Windows PowerShell 5.1:

~~~powershell
Set-ExecutionPolicy -Scope Process Bypass
.\tools\bootstrap-dos.ps1
.\tools\build-dos.ps1 -Clean
~~~

The executable is written to:

~~~text
out\dos\quake.exe
~~~

The default normal build uses all 83 C files and 21 preprocessed x86 assembly
files in WinQuake.  Its `aggressive` profile is `-O3 -march=i486` with the
measured ASM paths enabled for alias projection, alias bounding-box projection,
clipped alias transform/lighting, texture animation, and lightmap
normalization; the turbulent loop uses the measured `stosb` variant.  The
remaining experimental selectors stay on their C references.  `-O2` remains
available as `-OptimizationProfile baseline` and writes to `out\dos-baseline`.  net_comx.c is
textually included by net_ser.c, so the build compiles 82 standalone C files
and obtains the remaining C implementation through that include.  Object files
and a generated build-manifest.json remain under out\dos, which is ignored by
Git.  The linker output is checked with the DJGPP objdump and must report
coff-go32.

The memory-helper experiment can route the real `Q_memset` and `Q_memcpy`
entry points through the hand-written 486 routines without changing the C
reference bodies.  Select it at build time:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -MemoryImplementation c
.\tools\build-dos.ps1 -Benchmark -MemoryImplementation asm
~~~

`asm` is now the 486-oriented default and writes to `out\dos-memasm`; `c`
remains the callable reference path and writes to `out\dos`. The ASM build
includes `asm486_experiments.s` and defines `ASM486_RUNTIME_MEMOPS`; all other
compiler flags and source inputs remain the same. Three current 486 timedemo
runs measured 62.556866 / 62.556847 / 62.556874 seconds with ASM versus a C
reference median near 62.568974 seconds, with checksum `4154140932` every run.

The texture-axis cache-key probe is independently selectable with
`-TextureAxisImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -TextureAxisImplementation c
.\tools\build-dos.ps1 -Benchmark -TextureAxisImplementation asm
~~~

`c` is the default and shares `out\dos`; `asm` writes to `out\dos-axisasm`.
This switch changes only the three-key cache hit/miss probe in `D_GetTextureAxes`;
hashing, cache misses, and axis-vector transforms remain in C.

The surface-cache validity predicate is independently selectable with
`-SurfaceCacheImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -SurfaceCacheImplementation c
.\tools\build-dos.ps1 -Benchmark -SurfaceCacheImplementation asm
~~~

`c` is the default and shares `out\dos`; `asm` writes to
`out\dos-surfaceasm`.  This switch changes only the fast cache-validity
predicate in `D_CacheSurface`; texture animation, light-style loads, allocation,
and surface generation remain in C.

The mip-level threshold selector is independently selectable with
`-MipLevelImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -MipLevelImplementation c
.\tools\build-dos.ps1 -Benchmark -MipLevelImplementation asm
~~~

`c` is the default and shares `out\dos`; `asm` writes to `out\dos-mipasm`.
The ASM version uses 486 x87 comparisons for the three thresholds and preserves
the C implementation as the reference.

The turbulent-span store loop is independently selectable with
`-TurbulentImplementation c|asm|stosb`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -TurbulentImplementation c
.\tools\build-dos.ps1 -Benchmark -TurbulentImplementation asm
.\tools\build-dos.ps1 -Benchmark -TurbulentImplementation stosb
~~~

`stosb` is the measured target default, `asm` is the existing 486 assembly
control path, and `c` selects a callable C reference implementation.  The
variants use separate ignored output directories (`out\dos-turbc`,
`out\dos-turbasm`, and `out\dos`) and all keep the original portable C loop in
the source.

The 16-pixel texture-span store loop is independently selectable with
`-TextureSpanStores word|byte|dword|loop`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -TextureSpanStores word
.\tools\build-dos.ps1 -Benchmark -TextureSpanStores byte
.\tools\build-dos.ps1 -Benchmark -TextureSpanStores dword
.\tools\build-dos.ps1 -Benchmark -TextureSpanStores loop
~~~

The negative-gradient Z-span loop is selectable with
`-ZSpanNegativeUnroll unroll8|control`. `control` is the production
default; `unroll8` retains the eight-pixel experiment for matched correctness
and timing comparisons. The experiment was rejected after three matched runs:
both variants completed 969 frames with checksum `1047377823`, while control
measured `59.408069` seconds median and `unroll8` measured `59.408076` seconds.

The follow-up `PROFILE486` run (`out\dos-timedemo-20260928-060116`) completed
969 frames with checksum `1047377823`. Its instrumented self-time ranking was
texture spans 28.11%, alias models 13.38%, world BSP 11.49%, surface cache
10.03%, Z spans 9.37%, and edge scanning 9.00%. The instrumented 67.271233
second duration is attribution evidence, not a release timing claim; texture
span work is the next optimization target.

~~~powershell
.\tools\build-dos.ps1 -Benchmark -ZSpanNegativeUnroll unroll8
.\tools\build-dos.ps1 -Benchmark -ZSpanNegativeUnroll control
~~~

`word` is now the production default.  It preserves the original texture/DDA
sampling order and packs adjacent destination pixels with 16-bit stores in the
full 16-pixel path.  Three matched DOSBox-X timedemo runs measured
59.497438, 59.497242, and 59.497252 seconds (median 59.497252), all with
969 frames and framebuffer checksum `4154140932`.  The explicit `byte` control
uses the original unrolled stores and writes `out\dos-spanbyte`; `dword` packs
four destination pixels per `movl` and writes `out\dos-spandword`; `loop` uses
`stosb` in 7+8 pixel loops and writes `out\dos-spanloop`.  All variants retain
the exact checksum gate.

### Texture-span row-cross experiment (2026-09-28)

The full 16-pixel `D_DrawSpans16` path has a separate selector,
`-TextureSpanRowPath control|norowcross`.  `control` is the release default.
The opt-in `norowcross` build defines `ASM486_SPAN16_NO_ROW_CROSS` and uses an
S-only address advance when the clamped segment endpoints have a non-negative
T gradient and remain in the same texture row.  Negative gradients and possible
row crossings fall back to the original two-axis DDA.  `D_DrawSpans8` is not
part of this experiment.

The reproducible commands, using the aggressive i486 profile and the pinned
DOSBox-X profile, are:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -TextureSpanRowPath control
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -TextureSpanRowPath norowcross
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -TextureSpanRowPath control -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1' -TimeoutSeconds 600
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -TextureSpanRowPath norowcross -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1' -TimeoutSeconds 600
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -TextureSpanRowPath control -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1'
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -TextureSpanRowPath norowcross -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1'
~~~

Both builds passed the existing correctness harness (`486 benchmark correctness
PASS`, end checksum `2378409472`).  Three alternating release timedemo pairs
all completed 969 frames with framebuffer checksum `1047377823`:

| path | samples (seconds) | median | median FPS |
| --- | --- | ---: | ---: |
| control | 59.408221 / 59.408218 / 59.408243 | 59.408221 | 16.310874 |
| norowcross | 59.753011 / 59.753108 / 60.217335 | 59.753108 | 16.216730 |

The candidate was `0.344887` seconds, or `0.580537%`, slower than control.
Because the median delta exceeded the `0.05%` repeat threshold, the five-sample
escalation was not required.  The candidate is rejected for promotion but remains
available as an opt-in experiment; `control` remains the build, benchmark, and
timedemo default.  `textureSpanRowPath` is recorded in the build manifest,
`bench-result.json`, and `timedemo-result.json`; `norowcross` uses an ignored
`out\...-spannorow` directory.

The PROFILE486 runs (`out\dos-timedemo-20260928-070210` and
`out\dos-timedemo-20260928-070331`) recorded `row_eligible=0,
row_fast=0` for control and `row_eligible=209338, row_fast=209338` for the
candidate.  These counters confirm candidate exercise only; the instrumented
duration is attribution evidence, not a release timing claim.

### Texture-span tail-store experiment (2026-09-28)

The variable-length final segment of `D_DrawSpans16` has a separate selector,
`-TextureSpanTailStores control|word`.  `control` is the release default.  The
opt-in `word` build defines `ASM486_SPAN16_TAIL_WORD_STORES` and packs adjacent
pre-final texels with `movw`, while preserving the original fixed-point DDA
order and leaving the final sample unadvanced.  Full 16-pixel segments and
`D_DrawSpans8` are unchanged.

The reproducible commands, using the aggressive i486 profile and the pinned
DOSBox-X profile, are:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -TextureSpanTailStores control
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -TextureSpanTailStores word
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -TextureSpanTailStores control -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1' -TimeoutSeconds 600
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -TextureSpanTailStores word -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1' -TimeoutSeconds 600
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -TextureSpanTailStores control -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1'
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -TextureSpanTailStores word -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1'
~~~

Both builds passed the existing correctness harness (`486 benchmark correctness
PASS`, end checksum `2378409472`).  Three alternating release timedemo pairs
all completed 969 frames with framebuffer checksum `1047377823`:

| path | samples (seconds) | median | median FPS |
| --- | --- | ---: | ---: |
| control | 59.408215 / 59.868491 / 59.408242 | 59.408242 | 16.310868 |
| word | 60.135289 / 60.135318 / 60.135324 | 60.135318 | 16.113659 |

The candidate was `0.727076` seconds, or `1.223864%`, slower than control.
Because the median delta exceeded the `0.05%` repeat threshold, the five-sample
escalation was not required.  The candidate is rejected for promotion but remains
available as an opt-in experiment; `control` remains the build, benchmark, and
timedemo default.  `textureSpanTailStores` is recorded in the build manifest,
`bench-result.json`, and `timedemo-result.json`; `word` uses an ignored
`out\...-spantailword` directory.

The alias-model projection helper is independently selectable with
`-AliasProjectImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -AliasProjectImplementation c
.\tools\build-dos.ps1 -Benchmark -AliasProjectImplementation asm
~~~

`asm` is the measured target default and writes to `out\dos`; `c` is the
reference implementation and writes to `out\dos-aliasc`.  The ASM path keeps
the original x87 arithmetic and truncating conversions, but holds the x87
truncation mode across all three stores in `R_AliasProjectFinalVert`.

The animated-texture frame-selection loop is independently selectable with
`-TextureAnimationImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -TextureAnimationImplementation c
.\tools\build-dos.ps1 -Benchmark -TextureAnimationImplementation asm
~~~

`asm` is the measured target default and uses `out\dos`; `c` is the
reference/control implementation and uses `out\dos-textureanimc`.  Only the
pointer/branch loop is replaced.  Alternate-animation selection, the
no-animation fast path, relative-time calculation, and error handling remain
in C.

The lightmap normalization loop is independently selectable with
`-LightMapNormalizeImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -LightMapNormalizeImplementation c
.\tools\build-dos.ps1 -Benchmark -LightMapNormalizeImplementation asm
~~~

`asm` is the measured target default and uses `out\dos`; `c` is the
reference/control implementation and uses `out\dos-lightmapc`.  Only the
final bound/invert/shift loop in `R_BuildLightMap` is replaced.  Lightmap
setup, style accumulation, and dynamic-light work remain in C.

The BSP plane-dot calculation is independently selectable with
`-BspPlaneDotImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -BspPlaneDotImplementation c
.\tools\build-dos.ps1 -Benchmark -BspPlaneDotImplementation asm
~~~

`c` remains the default and keeps the original inline switch in
`R_RecursiveWorldNode`; `asm` writes to `out\dos-bspdotasm` and replaces only
the axis/generic plane-dot calculation.  This is an opt-in learning
experiment because the ASM version introduces a call boundary into the
recursive world walk.

The BSP frustum-clipping block is independently selectable with
`-BspClipImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -BspClipImplementation c
.\tools\build-dos.ps1 -Benchmark -BspClipImplementation asm
~~~

`c` remains the default and keeps the original inline four-plane clip loop in
`R_RecursiveWorldNode`; `asm` writes to `out\dos-bspclipasm` and replaces only
that loop with a hand-written x87 helper.  The reference C helper is retained
under `BENCH486` for direct correctness and timing comparisons.  This is an
opt-in learning experiment because its focused results are mixed and its
integrated timedemo result is slower.

The alias bounding-box projection loop is independently selectable with
`-AliasBBoxProjectImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -AliasBBoxProjectImplementation c
.\tools\build-dos.ps1 -Benchmark -AliasBBoxProjectImplementation asm
~~~

`asm` is the measured target default and uses `out\dos`; `c` is the
reference/control implementation and uses `out\dos-aliasbboxc`.  The ASM
helper replaces only the projection and XY clip loop in `R_AliasCheckBBox`.
The original C loop remains intact for controlled comparison.  It keeps the
vertex pointers, loop count, and clip masks in registers and uses one x87
reciprocal for both projected coordinates.  This is a controlled integration:
the C implementation remains available with `-AliasBBoxProjectImplementation c`.

The clipped alias vertex transform and lighting helper is independently
selectable with `-AliasTransformFinalImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -AliasTransformFinalImplementation c
.\tools\build-dos.ps1 -Benchmark -AliasTransformFinalImplementation asm
~~~

`asm` is the measured target default and uses `out\dos`; `c` is the
reference/control implementation and uses `out\dos-aliastransformc`.  The
candidate replaces only `R_AliasTransformFinalVert` for clipped alias vertices.
It expands the three packed vertex bytes once, keeps the matrix arithmetic in
x87 registers, and performs the lighting dot product in the same helper.  The
C path remains available for controlled comparison.

## Runtime smoke test

Place legally obtained Quake data in the ignored directory:

~~~text
testdata\id1\pak0.pak
~~~

Then run:

~~~powershell
.\tools\smoke-dos.ps1
~~~

The script stages a fresh DOS directory under out\dos-smoke, starts
DOSBox-X, initializes the DOS software renderer with sound/input/CD disabled,
and exits through the Quake command line.  It verifies both the DOSBox-X exit
code and a Quake exit marker.  The staged runtime uses the normal Quake layout:
`quake.exe`, `cwsdpmi.exe`, and the `id1` directory are siblings under the
mounted `quake` directory.  Use -DataRoot to point at another local data
directory, `-OptimizationProfile baseline` to smoke the `-O2` build, or
-SkipBuild when the executable is already available.
The runner copies only `pak*.pak` (not Steam configs or autoexec files),
writes a local `autoexec.cfg` containing `quit`, and launches with
`-stdvid -forcquit +quit` so the attract demos and the Y/N quit menu cannot
hold the 486 cycle cap.  `-forcquit` also skips `Con_NotifyBox` key waits and
the VGA sell screen.  The generated smoke configuration is the pinned
`dosbox-x-486-high.conf` profile with a replaced `[autoexec]` section
(`cputype=486`, fixed 33445 cycles, 16 MB).  On this host, DOSBox-X opened
its folder chooser with the otherwise-valid 32 MB setting.  The memory choice
is a compatibility setting, not a performance claim.

For interactive play, use the same mounted directory and omit the timedemo
commands.  The following starts the current default build with sound, joystick,
mouse, and CD audio disabled:

~~~powershell
$dosbox = Join-Path $env:LOCALAPPDATA '486quake\tools\dosbox-x-2026.08.31\dosbox-x.exe'
$profile = (Resolve-Path '.\tools\dosbox-x-486-high.conf').Path
$mount = (Resolve-Path '.\out\dos-smoke').Path.Replace('\', '/')
& $dosbox -conf $profile `
  -c ('mount c "' + $mount + '"') `
  -c 'c:' `
  -c 'cd \quake' `
  -c 'quake.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio'
~~~

## 486-class timedemo

### Current seeded A/B reference

For current PROFILE486 work, WinQuake/cl_demo.c seeds srand(1) when a timedemo
begins. This stabilizes random entity animation phases for performance
comparisons. The resulting current-worktree framebuffer checksum is
1047377823; the older 4154140932 value in historical experiment records is not
interchangeable with this seeded reference.

The current raw VGA reference is 969 frames in a median 59.506742 seconds
(16.283870 FPS) across three runs, with checksum 1047377823 on every run.
When comparing optional implementations, rebuild each selector separately and
hold the DOSBox-X profile, DPMI host, data directory, command line, and random
seed constant. Keep an implementation only when its complete timedemo improves
repeatably and preserves the current checksum.

### Lightmap style accumulation

The generic raw style-combination loop in R_BuildLightMap is selectable with
LightMapStylesImplementation c|asm. The i486 ASM path is now the default after
matching all focused maps-1..4, size, and alignment cases and passing the full
correctness harness. Three raw demo1 runs measured 59.503904, 59.503792, and
59.503771 seconds (median 16.284676 FPS), versus the matched C runs at
59.507049, 59.506949, and 59.507049 seconds (median 16.283812 FPS). Every run
completed 969 frames with checksum 1047377823. The fused/clamped lightmap
paths, dynamic-light accumulation, and final normalization remain independently
implemented in C/ASM as before.

The no-dynamic-light fused 2/3/4-style paths are selectable with
FusedLightMapImplementation c|asm and are now also defaulted to ASM. Full C and
ASM correctness harnesses passed. Three raw demo1 runs measured C at
59.504490, 59.504450, and 59.504481 seconds (median 16.284496 FPS), versus
ASM at 59.502617, 59.502563, and 59.502535 seconds (median 16.285013 FPS),
with checksum 1047377823 on every run.

The first alias transform composition is selectable with
AliasMatrixCompositionImplementation c|special and is now defaulted to the
specialized diagonal path. It retains AngleVectors and the second generic
composition. Three raw demo1 runs measured C at 59.502611, 59.502548, and
59.502529 seconds (median 16.285017 FPS), versus special at 59.455982,
59.455677, and 59.455756 seconds (median 16.297855 FPS), with checksum
1047377823 on every run. The full correctness harness passed.

The existing dynamic-light sample helper is selectable with
DynamicLightImplementation c|asm and is now defaulted to ASM. Three raw demo1
runs measured C at 59.422461, 59.422365, and 59.422373 seconds (median
16.306982 FPS), versus ASM at 59.410915, 59.410949, and 59.410930 seconds
(median 16.310130 FPS), with checksum 1047377823 on every run. The full ASM
correctness harness passed.

### VGA full-frame copy experiment

The guarded VGA_SwapBuffersCopy full-frame shortcut was tested in standard VGA
mode using -stdvid. Direct VGA, planar, partial, chained, padded, and sentinel
tests passed, and all forced-VGA runs retained 969 frames/checksum 1047377823.
The candidate was rejected because its median was 16.302751 FPS versus 16.303103
FPS for the matched no-shortcut control. The shortcut was reverted; the direct
VGA coverage remains in tools/test-video-dos.py.

### Latest validation notes

### Surface-cache capacity and churn

The timedemo was repeated with the supplied data root
out\video-qa\banked\quake\id1, the standard DOSBox-X 486 profile, and
CWSDPMI. The release control completed all 969 frames with checksum
1047377823; three samples measured 59.874099, 59.419778, and 59.419753
seconds (16.183960, 16.307701, and 16.307708 FPS). The first sample is a
startup outlier; the matched median is 59.419778 seconds / 16.307701 FPS.

The current 1800 KiB surface-cache default was compared with explicit
-surfcachesize 2048 and -surfcachesize 1024 runs:

| Surface cache | Seconds | FPS | Frames | Checksum |
| ---: | ---: | ---: | ---: | ---: |
| 1800 KiB control (median) | 59.419778 | 16.307701 | 969 | 1047377823 |
| 2048 KiB | 59.382324 | 16.317987 | 969 | 1047377823 |
| 1024 KiB | 59.707460 | 16.229128 | 969 | 1047377823 |

The 2048 KiB result is within the control spread and does not establish a
repeatable end-to-end improvement. The 1024 KiB result is slower and increases
surface-cache churn. In a PROFILE486 control run, the surface-cache path took
6.812082 seconds (10.03% of profiled frame time), with 46,391 hits, 8,894
rebuilds, 2,837 allocations, 4 wraps, and 0 thrash frames. The instrumented
1024 KiB run took 7.106158 seconds in the surface-cache path, with 45,760 hits,
9,530 rebuilds, 3,498 allocations, 8 wraps, and 0 thrash frames.

Retain the 1800 KiB default. The data supports avoiding a smaller cache, but
does not justify spending additional memory or changing the allocator policy.
The next performance targets remain texture spans, alias-model rendering,
world BSP traversal, and Z-span drawing. The release results are recorded in
out\dos-timedemo-20260927-175918, out\dos-timedemo-20260927-180035,
out\dos-timedemo-20260927-180148, out\dos-timedemo-20260927-180310,
and out\dos-timedemo-20260927-180423; profile artifacts are in
out\dos-timedemo-20260927-175544 and out\dos-timedemo-20260927-180540.

### Surface-cache header locality experiment

The alias-model rasterizer was reviewed against the current PROFILE486
hotspot ranking before attempting another change. `D_PolysetDrawSpans8` already
uses the 486-tuned eight-pixel loop, cached DDA state, optimized Z-buffer
addressing, zero-extended skin indices, and the established colormap fast
paths. The remaining work is register-pressure-sensitive and no additional
change was accepted without a checksum-preserving, repeatable timedemo win.
The current alias assembly remains the release control.


An experimental header reorder placed dlight, texture, and lightadj at the
front of surfcache_t so the validation fields would fit in two 486 cache lines.
The C-path candidate completed 969 frames with checksum 1047377823 at
16.307884, 16.181754, and 16.307892 FPS (median 16.307884 FPS), statistically
tied with the control. The reordered ASM predicate also preserved the checksum,
but its PROFILE486 surface-cache self time was 6.812257 seconds versus
6.743781 seconds for the C candidate. The layout change was rejected and
reverted; the existing structure offsets and ASM ABI remain the control.

### Lazy viewspantable rebuild

D_SetupFrame now caches the active view buffer pointer and effective row stride
and skips rebuilding viewspantable when neither changes. Mode changes and warp
entry/exit naturally invalidate the cache through those inputs. Full benchmark
correctness and video tests passed. Three raw demo1 runs measured 59.422468,
59.422417, and 59.422374 seconds (median 16.306977 FPS), versus the clean
16.297855 FPS baseline; every run completed 969 frames with checksum
1047377823.

Do not remove the lightright stores from the mip0/mip1/mip2 surf8 drawers: they
are consumed by the following loop iteration. A zero-punch-angle early-out in
DropPunchAngle was also tested; it passed correctness and checksum gates but
measured 16.283890 FPS versus the 16.283870 FPS baseline, which is noise. Both
experiments were reverted.

For a repeatable performance check, use the repository-owned
`tools/dosbox-x-486-high.conf` profile.  It targets a high-end 486DX4/100
class CPU (`cputype=486`, dynamic core, fixed 33445 cycles), an S3 SVGA
adapter, 16 MB of RAM, no frame skipping, no scaling, and no host vsync.

After running the smoke test so that `out\dos-smoke` contains the staged
executable and legally obtained data, launch a timedemo from the repository
root:

~~~powershell
$dosbox = Join-Path $env:LOCALAPPDATA '486quake\tools\dosbox-x-2026.08.31\dosbox-x.exe'
$profile = (Resolve-Path '.\tools\dosbox-x-486-high.conf').Path
$mount = (Resolve-Path '.\out\dos-smoke').Path.Replace('\', '/')
& $dosbox -conf $profile `
  -c ('mount c "' + $mount + '"') `
  -c 'c:' `
  -c 'cd \quake' `
  -c 'quake.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +toggleconsole +timedemo demo1'
~~~

The built-in `demo1.dem`, `demo2.dem`, and `demo3.dem` are in the supplied
Quake data.  Replace `demo1` with either other name to repeat the test.  The
result is printed in the Quake console as frames, seconds, and FPS.

### Historical pre-experiment reference

The earlier reported **14 FPS** (rounded) is reproducible on the pinned
profile.  A three-run raw `demo1` reference measurement on 2026-09-09, before
the currently selected ASM paths were promoted,
produced 969 frames per run and a median of **13.995834 FPS** (`69.234885`
seconds for the median run).
The runs used `qbench.exe`, the default `baseline` optimization profile,
DOSBox-X 2026.08.31, `cputype=486`, and fixed 33445 cycles.  The result is
recorded under `out\dos-timedemo-*\timedemo-result.json` and is emulator
evidence, not a native Windows performance measurement.

Use the repository runner for repeatable measurements instead of manually
copying executables:

~~~powershell
.\tools\timedemo-dos.ps1 -DataRoot 'C:\path\to\Quake\id1' -Runs 3
~~~

It stages a fresh DOS directory for every run, writes six-decimal timing data,
and reports the median FPS.  The runner only compiles `qbench.exe` when that
file is missing; after source changes run `.\tools\build-dos.ps1 -Benchmark`
first, then `timedemo-dos.ps1 -SkipBuild`.  Keep the demo name, DOSBox-X
version, 486 profile, fixed cycle count, video mode, optimization profile, and
command-line options unchanged when comparing results.  By default it adds `-fpsstats`, preserving
the original average-FPS line while also measuring every timedemo frame.
Use `-NoFpsStats` for a raw comparison when measuring the cost of collecting
the extra statistics.  The raw result is the authority for small engine-speed
comparisons; the rich result is the authority for frame-time consistency.

### Alternate DPMI host (HDPMI32 experiment)

The default staging still copies `cwsdpmi.exe` beside the EXE.  For an isolated
DPMI-server A/B without rebuilding Quake:

~~~powershell
.\tools\timedemo-dos.ps1 -SkipBuild -DpmiHost hdpmi32 -Runs 5 `
  -DataRoot 'C:\path\to\Quake\id1'
.\tools\compare-dpmi-dos.ps1 -SkipBuild -Runs 5 -DataRoot 'C:\path\to\Quake\id1'
~~~

`-DpmiHost hdpmi32` stages Japheth's `HDPMI32.EXE` from
`tools\thirdparty\hdpmi\`, omits `cwsdpmi.exe`, runs `HDPMI32 -r`, and records
a `DPMI.EXE` host probe.  A 2026-09-15 five-run matched comparison showed
HDPMI32 completes timedemos but fails the known-good framebuffer checksum
(`2955717646` vs `4154140932`) on every run, so **CWSDPMI remains the preferred
host**.  Full write-up: `DPMI-HDPMI32.md`.

For an odd number of runs, the runner selects the middle sorted sample.  Older
generated JSON records may contain the highest sample in `medianFps`; use the
individual `results` entries when auditing those records.

### Current committed default baseline

The current measured default after EmitEdge memory `subl C(surfaces)` on
LSide1/LSide0 is `62.580216 / 62.580291 / 62.580319` seconds, median
**15.484108 FPS** / **62.580291 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-211623\timedemo-result.json`).  That is about
8.0 ms faster than the prior EmitEdge u-clamp memory `cmpl` default at
**15.482121 FPS** / 62.588326 s (`out\dos-timedemo-20260915-210614`).

The prior EmitEdge u-clamp memory `cmpl` measured
`62.588579 / 62.588326 / 62.588325` seconds, median **15.482121 FPS** /
**62.588326 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-210614\timedemo-result.json`).  That is about
16.8 ms faster than the prior RecursiveTriangle-midpoint default at
**15.477961 FPS** / 62.605144 s (`out\dos-timedemo-20260915-205607`).

The prior RecursiveTriangle memory `addl` s/t/zi midpoints measured
`62.605330 / 62.605144 / 62.605103` seconds, median **15.477961 FPS** /
**62.605144 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-205607\timedemo-result.json`).  That is about
16.6 ms faster than the prior EmitEdge-`r_ceilv1` default at
**15.473853 FPS** / 62.621766 s (`out\dos-timedemo-20260915-204522`).

The prior EmitEdge defer `r_ceilv1` past horizontal EO measured
`62.621949 / 62.621766 / 62.621726` seconds, median **15.473853 FPS** /
**62.621766 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-204522\timedemo-result.json`).  That is about
2.0 ms faster than the prior leading `Lnewtop` memory `cmpl st_last_u`
default at **15.473368 FPS** / 62.623729 s
(`out\dos-timedemo-20260915-203108`).

The prior leading `Lnewtop` memory `cmpl st_last_u` measured
`62.623894 / 62.623729 / 62.623708` seconds, median **15.473368 FPS** /
**62.623729 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-203108\timedemo-result.json`).  That is about
25.9 ms faster than the prior StepActiveU-`et_u_step` default at
**15.466979 FPS** / 62.649598 s (`out\dos-timedemo-20260915-202546`).

The prior StepActiveU memory `addl et_u_step` measured
`62.651188 / 62.649598 / 62.649569` seconds, median **15.466979 FPS** /
**62.649598 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-202546\timedemo-result.json`).  That is about
104.3 ms faster than the prior ScanLeftEdge last-row Bresenham-skip default
at **15.441270 FPS** / 62.753905 s (`out\dos-timedemo-20260915-200539`).

The prior ScanLeftEdge skip dead last-row Bresenham measured
`62.810895 / 62.753822 / 62.753905` seconds, median **15.441270 FPS** /
**62.753905 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-200539\timedemo-result.json`).  That is about
28.7 ms faster than the prior TrailingEdge memory `cmpl st_last_u` default
at **15.434201 FPS** / 62.782647 s (`out\dos-timedemo-20260915-190100`).

The prior TrailingEdge memory `cmpl st_last_u` measured
`62.782709 / 62.782647 / 62.782532` seconds, median **15.434201 FPS** /
**62.782647 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-190100\timedemo-result.json`).  That is about
0.9 ms faster than the prior `LPushBackLoop` memory `cmpl et_u` default at
**15.433983 FPS** / 62.783533 s (`out\dos-timedemo-20260915-184357`).

The prior `LPushBackLoop` memory `cmpl et_u` measured
`62.783709 / 62.783486 / 62.783533` seconds, median **15.433983 FPS** /
**62.783533 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-184357\timedemo-result.json`).  That is about
3.7 ms faster than the prior InsertNewEdges memory `cmpl et_u` default at
**15.433068 FPS** / 62.787258 s (`out\dos-timedemo-20260915-183750`).

The prior InsertNewEdges memory `cmpl et_u` measured
`62.787043 / 62.787258 / 62.787362` seconds, median **15.433068 FPS** /
**62.787258 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-183750\timedemo-result.json`).  That is about
43.3 ms faster than the prior Aff8 multi last-group-skip default at
**15.422436 FPS** / 62.830543 s (`out\dos-timedemo-20260915-182515`).

The prior Aff8 multi skip dead last-group stepper measured
`62.830458 / 62.830543 / 62.830579` seconds, median **15.422436 FPS** /
**62.830543 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-182515\timedemo-result.json`).  That is about
123.2 ms faster than the prior leading sort-loop memory `cmpl st_key`
default at **15.392244 FPS** / 62.953783 s
(`out\dos-timedemo-20260915-180350`).

The prior leading sort-loop memory `cmpl st_key` measured
`62.953648 / 62.953783 / 62.953854` seconds, median **15.392244 FPS** /
**62.953783 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-180350\timedemo-result.json`).  That is about
52.8 ms faster than the prior RecursiveTriangle live-new-into-LDraw default
at **15.379351 FPS** / 63.006559 s (`out\dos-timedemo-20260915-174638`).

The prior RecursiveTriangle live `new[]` into LDraw measured
`63.006416 / 63.006581 / 63.006559` seconds, median **15.379351 FPS** /
**63.006559 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-174638\timedemo-result.json`).  That is about
5.5 ms faster than the prior leading memory `cmpl` first-`st_key` default at
**15.378020 FPS** / 63.012013 s (`out\dos-timedemo-20260915-173942`).

The prior leading memory `cmpl` first `st_key` measured
`63.011902 / 63.012013 / 63.012104` seconds, median **15.378020 FPS** /
**63.012013 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-173942\timedemo-result.json`).  That is about
72.4 ms faster than the prior FinalVerts light<<8 default at
**15.360381 FPS** / 63.084374 s (`out\dos-timedemo-20260915-172059`).

The prior FinalVerts Aff8-style light<<8 index measured
`63.084563 / 63.084374 / 63.084351` seconds, median **15.360381 FPS** /
**63.084374 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-172059\timedemo-result.json`).  That is about
2.9 ms faster than the prior RemoveEdges both-stores-then-advance default at
**15.359677 FPS** / 63.087263 s (`out\dos-timedemo-20260915-171204`).

The prior RemoveEdges both-stores-then-advance measured
`63.087380 / 63.087263 / 63.087206` seconds, median **15.359677 FPS** /
**63.087263 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-171204\timedemo-result.json`).  That is about
4.2 ms faster than the prior StepActiveU deferred step-loop `et_next`
default at **15.358664 FPS** / 63.091427 s
(`out\dos-timedemo-20260915-165144`).

The prior StepActiveU deferred step-loop `et_next` measured
`63.091567 / 63.091379 / 63.091427` seconds, median **15.358664 FPS** /
**63.091427 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-165144\timedemo-result.json`).  That is about
11.3 ms faster than the prior EmitEdge deferred `r_framecount` default at
**15.355923 FPS** / 63.102686 s (`out\dos-timedemo-20260915-163753`).

The prior EmitEdge defer `r_framecount` past cacheoffset EO measured
`63.102870 / 63.102606 / 63.102686` seconds, median **15.355923 FPS** /
**63.102686 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-163753\timedemo-result.json`).  That is about
0.5 ms faster than the prior `LPushBackLoop` deferred `et_prev` default at
**15.355803 FPS** / 63.103178 s (`out\dos-timedemo-20260915-160134`).

The prior StepActiveU `LPushBackLoop` deferred `et_prev` measured
`63.103349 / 63.103178 / 63.103124` seconds, median **15.355803 FPS** /
**63.103178 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-160134\timedemo-result.json`).  That is about
2.1 ms faster than the prior InsertNewEdges deferred `et_next` default at
**15.355295 FPS** / 63.105267 s (`out\dos-timedemo-20260915-154958`).

The prior InsertNewEdges defer `et_next` (probes 1–3) measured
`63.105419 / 63.105230 / 63.105267` seconds, median **15.355295 FPS** /
**63.105267 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-154958\timedemo-result.json`).  That is about
7.4 ms faster than the prior StepActiveU aftertail deferred-unlink default
at **15.353497 FPS** / 63.112658 s (`out\dos-timedemo-20260915-153501`).

The prior StepActiveU defer `et_prev`/`et_next` past `edge_aftertail`
measured `63.113353 / 63.112658 / 63.112628` seconds, median
**15.353497 FPS** / **63.112658 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-153501\timedemo-result.json`).  That is about
9.1 ms faster than the prior RecursiveTriangle deferred-`|dy|`-y-loads
default at **15.351272 FPS** / 63.121804 s
(`out\dos-timedemo-20260915-150014`).

The prior RecursiveTriangle defer same-edge y loads past `|dx|` early-out
measured `63.121965 / 63.121804 / 63.121646` seconds, median
**15.351272 FPS** / **63.121804 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-150014\timedemo-result.json`).  That is about
17.6 ms faster than the prior split-prefetch defer default at
**15.346986 FPS** / 63.139434 s (`out\dos-timedemo-20260915-144910`).

The prior RecursiveTriangle defer next-edge prefetches past `|dy|` split
measured `63.139641 / 63.139434 / 63.139417` seconds, median
**15.346986 FPS** / **63.139434 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-144910\timedemo-result.json`).  That is about
1.7 ms faster than the prior `lp2[0]`-defer default at **15.346585 FPS** /
63.141084 s (`out\dos-timedemo-20260915-140237`).

The prior RecursiveTriangle defer `lp2[0]` until equal-`y` measured
`63.141181 / 63.141050 / 63.141084` seconds, median **15.346585 FPS** /
**63.141084 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-140237\timedemo-result.json`).  That is about
2.2 ms faster than the prior Aff8-one-long deferred-`ptex` default at
**15.346044 FPS** / 63.143310 s (`out\dos-timedemo-20260915-133615`).

The prior Aff8 one-long defer `ptex` past Z measured
`63.143406 / 63.143310 / 63.143203` seconds, median **15.346044 FPS** /
**63.143310 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-133615\timedemo-result.json`).  That is about
2.5 ms faster than the prior DrawSubdiv deferred-colormap default at
**15.345430 FPS** / 63.145837 s (`out\dos-timedemo-20260915-132507`).

The prior DrawSubdiv defer `d_pcolormap` past backface cull measured
`63.146060 / 63.145728 / 63.145837` seconds, median **15.345430 FPS** /
**63.145837 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-132507\timedemo-result.json`).  That is about
32.3 ms faster than the prior FinalVerts `movzbl` skin-texel default at
**15.337574 FPS** / 63.178180 s (`out\dos-timedemo-20260915-131025`).

The prior FinalVerts `movzbl` skin texel measured
`63.178491 / 63.178164 / 63.178180` seconds, median **15.337574 FPS** /
**63.178180 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-131025\timedemo-result.json`).  That is about
1.4 ms faster than the prior Aff8 pixel `movzbl` default at
**15.337229 FPS** / 63.179599 s (`out\dos-timedemo-20260915-125058`).

The prior Aff8 pixel `movzbl` colormap index measured
`63.179791 / 63.179533 / 63.179599` seconds, median **15.337229 FPS** /
**63.179599 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-125058\timedemo-result.json`).  That is about
85.9 ms faster than the prior RecursiveTriangle live-`new[]` default at
**15.316416 FPS** / 63.265453 s (`out\dos-timedemo-20260915-124237`).

The prior RecursiveTriangle live `new[0]`/`new[1]` into LDraw measured
`63.265572 / 63.265453 / 63.265414` seconds, median **15.316416 FPS** /
**63.265453 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-124237\timedemo-result.json`).  That is about
1.8 ms faster than the prior EmitEdge deferred-`edge_p` default at
**15.315969 FPS** / 63.267301 s (`out\dos-timedemo-20260915-122259`).

The prior EmitEdge defer `edge_p` past horizontal EO measured
`63.267487 / 63.267234 / 63.267301` seconds, median **15.315969 FPS** /
**63.267301 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-122259\timedemo-result.json`).  That is about
14.2 ms faster than the prior leading spanstate `movl $1` default at
**15.312538 FPS** / 63.281476 s (`out\dos-timedemo-20260915-120825`).

The prior leading spanstate `movl $1` measured
`63.281763 / 63.281476 / 63.281405` seconds, median **15.312538 FPS** /
**63.281476 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-120825\timedemo-result.json`).  That is about
73.6 ms faster than the prior TrailingEdge memory-`decl`-spanstate default
at **15.294737 FPS** / 63.355125 s (`out\dos-timedemo-20260915-115111`).

The prior TrailingEdge memory `decl` of `spanstate` measured
`63.355242 / 63.355064 / 63.355125` seconds, median **15.294737 FPS** /
**63.355125 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-115111\timedemo-result.json`).  That is about
133.0 ms faster than the prior clipped-`r_pedge`-load-drop default at
**15.262705 FPS** / 63.488089 s (`out\dos-timedemo-20260915-113652`).

The prior drop unused clipped `r_pedge` load measured
`63.488166 / 63.488089 / 63.488004` seconds, median **15.262705 FPS** /
**63.488089 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-113652\timedemo-result.json`).  That is about
12.9 ms faster than the prior bmodel `incl`/`decl` default at
**15.259612 FPS** / 63.500960 s (`out\dos-timedemo-20260915-111815`).

The prior bmodel `incl`/`decl` of `r_bmodelactive` measured
`63.501194 / 63.500915 / 63.500960` seconds, median **15.259612 FPS** /
**63.500960 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-111815\timedemo-result.json`).  That is about
22.8 ms faster than the prior TrailingEdge world-skip default at
**15.254125 FPS** / 63.523798 s (`out\dos-timedemo-20260915-110651`).

The prior TrailingEdge skip of `r_bmodelactive` RMW measured
`63.523808 / 63.523798 / 63.523763` seconds, median **15.254125 FPS** /
**63.523798 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-110651\timedemo-result.json`).  That is about
49.4 ms faster than the prior EmitEdge-`r_pedge` single-load default at
**15.242273 FPS** / 63.573196 s (`out\dos-timedemo-20260915-104810`).

The prior EmitEdge single `r_pedge` load measured
`63.573476 / 63.573196 / 63.573176` seconds, median **15.242273 FPS** /
**63.573196 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-104810\timedemo-result.json`).  That is about
10.4 ms faster than the prior TrailingEdge-unlink default at
**15.239772 FPS** / 63.583628 s (`out\dos-timedemo-20260915-103948`).

The prior TrailingEdge unlink via live `%ecx` measured
`63.583853 / 63.583607 / 63.583628` seconds, median **15.239772 FPS** /
**63.583628 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-103948\timedemo-result.json`).  That is about
31.1 ms faster than the prior EmitEdge-pretouch-removal default at
**15.232323 FPS** / 63.614724 s (`out\dos-timedemo-20260915-102159`).

The prior EmitEdge next-edge pretouch removal measured
`63.615049 / 63.614724 / 63.614690` seconds, median **15.232323 FPS** /
**63.614724 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-102159\timedemo-result.json`).  That is about
8.5 ms faster than the prior ScanLeftEdge-pretouch default at
**15.230283 FPS** / 63.623244 s (`out\dos-timedemo-20260915-101018`).

The prior ScanLeftEdge pretouch removal measured
`63.623427 / 63.623209 / 63.623244` seconds, median **15.230283 FPS** /
**63.623244 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-101018\timedemo-result.json`).  That is about
29.0 ms faster than the prior dead-`st_key` default at **15.223339 FPS** /
63.652266 s (`out\dos-timedemo-20260915-094804`).

The prior dead `st_key` reload removal measured
`63.652309 / 63.652161 / 63.652266` seconds, median **15.223339 FPS** /
**63.652266 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-094804\timedemo-result.json`).  That is about
0.58 ms faster than the prior surfaces-CSE default at **15.223200 FPS** /
63.652849 s (`out\dos-timedemo-20260915-092321`).

The prior edge-scan `surfaces` CSE measured
`63.652962 / 63.652822 / 63.652849` seconds, median **15.223200 FPS** /
**63.652849 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-092321\timedemo-result.json`).  That is about
73.2 ms faster than the prior aspancount-spill default at **15.205710 FPS** /
63.726061 s (`out\dos-timedemo-20260915-080929`).

The prior ScanLeftEdge `%esi` package cursor measured
`63.783098 / 63.783005 / 63.782908` seconds, median **15.192135 FPS** /
**63.783005 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-064521\timedemo-result.json`).  That is about
112.1 ms faster than the prior Z-span `%ebp` default at **15.165488 FPS** /
63.895076 s (`out\dos-timedemo-20260915-055029`).

The prior Z-span `%ebp` list cursor measured
`63.895311 / 63.895076 / 63.895065` seconds, median **15.165488 FPS** /
**63.895076 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-055029\timedemo-result.json`).  That is about
89.3 ms faster than the prior left-edge CSE default at **15.144318 FPS** /
63.984395 s (`out\dos-timedemo-20260915-051520`).

The prior left-edge s/t step CSE measured
`63.984653 / 63.984268 / 63.984395` seconds, median **15.144318 FPS** /
**63.984395 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-051520\timedemo-result.json`).  That is about
18.9 ms faster than the prior advancetable default at **15.139851 FPS** /
64.003272 s (`out\dos-timedemo-20260914-182901`).  An earlier CSE set
(`out\dos-timedemo-20260915-051014`) matched the checksum with a run-2
hitch; the 051520 rebenchmark confirms the keep without the hitch.

The prior polyset span advancetable hoist measured
`64.003358 / 64.003148 / 64.003272` seconds, median **15.139851 FPS** /
**64.003272 s**, checksum `4154140932`
(`out\dos-timedemo-20260914-182901\timedemo-result.json`).  That is about
88.9 ms faster than the prior phantom-mark default at **15.118851 FPS** /
64.092171 s (`out\dos-timedemo-20260914-180707`).

The prior phantom-mark dlight probe measured
`64.092357 / 64.092171 / 64.092163` seconds, median **15.118851 FPS** /
**64.092171 s**, checksum `4154140932`
(`out\dos-timedemo-20260914-180707\timedemo-result.json`).  That is about
11.9 ms faster than the prior adivtab-64 default at **15.116037 FPS** /
64.104105 s (`out\dos-timedemo-20260914-164951`).

The prior alias `adivtab` 32→64 measured
`64.104105 / 64.103726 / 64.569991` seconds, median **15.116037 FPS** /
**64.104105 s**, checksum `4154140932`
(`out\dos-timedemo-20260914-164951\timedemo-result.json`).  That is about
9.7 ms faster than the prior sticky-dlight default at **15.113744 FPS** /
64.113828 s (`out\dos-timedemo-20260914-163457`).

The prior sticky `cache->dlight` flag measured
`64.114027 / 64.113796 / 64.113828` seconds, median **15.113744 FPS** /
**64.113828 s**, checksum `4154140932`
(`out\dos-timedemo-20260914-163457\timedemo-result.json`).  That is about
14.8 ms faster than the prior MarkLights idist-cull default at
**15.110264 FPS** / 64.128594 s (`out\dos-timedemo-20260914-143404`).

The prior MarkLights clamp-to-rect idist cull measured
`64.128632 / 64.128594 / 64.128523` seconds, median
**15.110264 FPS** / **64.128594 s**, checksum `4154140932`
(`out\dos-timedemo-20260914-143404\timedemo-result.json`).  That is about
125.4 ms faster than the prior AABB-expand default at **15.080783 FPS** /
64.253958 s (`out\dos-timedemo-20260914-142303`).  A follow-up 2x2 discrete
sample cull matched the checksum but was 112.5 ms slower
(`out\dos-timedemo-20260914-161209`) and was reverted.  An
`R_AddDynamicLights` s/t sample-window clamp failed checksum
`696680082` on run 2 (`out\dos-timedemo-20260914-162709`) and was
reverted.  An `R_AliasClip` aliasvrect hoist plus skip-Z-reflag matched
checksum `4154140932` but was 42.4 ms slower
(`out\dos-timedemo-20260914-181813`) and was reverted.  A polyset
`a_sstepxfrac`→BSS `sstep` hoist matched the checksum but was 9.1 ms
slower (`out\dos-timedemo-20260914-183707`) and was reverted.  Local
copies of polyset right-edge Bresenham constants matched the checksum
but were 36.7 ms slower (`out\dos-timedemo-20260914-184757`) and were
reverted.  A left-edge `d_ptexextrastep` rewrite via `a_ststepxwhole`
matched the checksum but was 76.5 ms slower
(`out\dos-timedemo-20260915-053730`) and was reverted.  Tagging the
Z-span `%ebp` cursor bit0 to drop the count push/pop matched the
checksum but was 64.6 ms slower (`out\dos-timedemo-20260915-060125`)
and was reverted.  A `D_PolysetScanLeftEdge` skinwidth stack hoist
matched the checksum but was 10.0 ms slower
(`out\dos-timedemo-20260915-061218`) and was reverted.  Stack-live
`d_aspancount`/`errorterm` in `D_PolysetDrawSpans8` matched the
checksum but was 36.7 ms slower (`out\dos-timedemo-20260915-065310`)
and was reverted.

A 2026-09-10 lock before this pass measured
`68.958977 / 68.958817 / 68.958799` seconds, median **14.051865 FPS**,
969 frames, checksum `4154140932`
(`out\dos-timedemo-20260910-221227\timedemo-result.json`).

An earlier checkpoint after skipping the unused `D_CacheSurface`
`surfscale` FDIV (plus inlined power-of-two surface wrap,
release-only skip of `D_CheckCacheGuard`, once-per-frame alias view
matrix, the `Mod_LoadTexinfo` nested-loop UB fix, `-O3`, cached bmodel
span rotations, fused lightmap writes, an integer dlight inner loop, a
per-plane Z-gradient cache, power-of-two column wrap, `zspantable`
Z-span addressing, `viewspantable` dest rows in texture spans,
polyset, sprites, and particles, `zspantable` Z addressing in
sprites and particles, a 1800 KB surface cache, `Turbulent8`
`viewspantable` dest rows, a static `D_CacheSurface` hit path, a
`D_PolysetDrawFinalVerts` clip-rect hoist, and unused extra light-style
skips on cache hits, `D_RasterizeAliasPolySmooth` dest/Z row tables,
`R_RenderFace` surfedges hoist plus clip unroll, the clipped-bmodel
surfedges hoist, `R_DrawSurface` 8-bit setup, and mipscale step tables)
completed
three `demo1` runs at
`67.085825 / 67.085569 / 67.085585` seconds, median **14.444235 FPS** /
**67.085585 s** (`out\dos-timedemo-20260911-191612\timedemo-result.json`).
That is about 6.3 ms faster than the mipscale-table default
(14.442880 FPS / 67.091882 s) with checksum `4154140932` on every run.
The `Turbulent8` dest-row default was about 1.3 ms faster than the 1800 KB default (14.409100 FPS /
67.249168 s).  1900 KB, 2000 KB, 2100 KB, and
2400 KB were faster but checksum `2955717646` (same hash as the
reverted texture-source row-lookup).  2x surface cache was **14.373452 FPS** / 67.415956 s
(`out\dos-timedemo-20260911-133815`).  Sprite/particle `zspantable`
was **14.252866 FPS** / 67.986326 s
(`out\dos-timedemo-20260911-065037`).  Extending `viewspantable` to polyset, sprites, and particles was
**14.251887 FPS** / 67.990997 s (`out\dos-timedemo-20260911-064221`).
Texture-span `viewspantable` dest addressing was **14.250078 FPS** /
67.999624 s (`out\dos-timedemo-20260911-063418`).  Z-span `zspantable`
addressing was **14.239663 FPS** / 68.049361 s
(`out\dos-timedemo-20260911-062059`).  Power-of-two column
wrap was **14.208790 FPS** / 68.197221 s
(`out\dos-timedemo-20260911-054347`).  The Z-gradient
cache was **14.208466 FPS** / 68.198777 s
(`out\dos-timedemo-20260911-053759`).  The integer dlight
inner loop was **14.206133 FPS** / 68.209972 s
(`out\dos-timedemo-20260911-052933`).  Extra-style fusion was **14.194657 FPS**
/ 68.265121 s (`out\dos-timedemo-20260911-051834`).  One-style-only
fusion was **14.194521 FPS** / 68.265779 s
(`out\dos-timedemo-20260911-051131`).  Both `-O2` and
`-O3` `quake.exe +quit` smokes now complete in about 12 seconds on the pinned
profile after `-forcquit` / local `autoexec.cfg`.  The older
14.185365 FPS / 68.309838 s figure is retained as the previous fused
first-style lightmap default.  14.170874 FPS / 68.379696 s is the previous
bmodel-cache default.  14.162237 FPS / 68.421397 s is the previous `-O3`
default.  The 14.054401 FPS / 68.946370 s figure is retained as the previous
`-O2` default.  The 14.051872 FPS / 68.958785 s figure is retained as the
previous ASM-default `-O2` baseline.

### Measured texture-span change

After the profiling pass identified texture spans as the largest self-time
consumer, the 16-pixel drawer received two narrow 486-targeted changes in
`WinQuake\d_draw16.s`: the initial row address uses a memory-source multiply,
and the common zero-row-step setup adds `cachewidth` directly from memory.
Both preserve the original fixed-point arithmetic and leave the inner sampling
loop unchanged.

A matched three-run raw `demo1` comparison on 2026-09-10 measured a median of
**14.010492 FPS** (`69.162451` seconds) after the change, versus the documented
pre-change median of **13.995834 FPS** (`69.234885` seconds), or approximately
**0.10% faster**.  All runs produced the same final framebuffer checksum,
`4154140932`.  This is DOSBox-X 486 evidence; it is not a claim about every
physical 486 or a native Windows build.

### Per-frame FPS statistics

When `-fpsstats` is enabled, the timedemo records one wall-clock sample at the
start and end of each measured frame.  The fixed 8192-sample buffer is suitable
for the built-in demos and reports an overflow count instead of allocating from
the DOS heap.  Sorting and statistical calculations happen after the timed
interval, so they do not enter the FPS measurement.

The first line remains the original average FPS result.  Additional lines in
`timedemo.txt` include minimum and maximum single-frame FPS, median FPS, the
arithmetic mean of the slowest 1% and 0.1% of frames, the arithmetic mean of
the fastest 1%, selected percentiles, FPS standard deviation and variance, and
the number of significant drops and spikes.  A drop is a frame below 75% of
the run's average FPS; a spike is above 125%.  The longest consecutive run of
each event is also reported.  `mean-frame` may be higher than the benchmark
average because the benchmark average is frames divided by total duration,
whereas `mean-frame` is the arithmetic mean of each frame's reciprocal time.

Example:

~~~text
969 frames 69.248328 seconds 13.993117 fps
fps-summary frames 969 measured 969 stored 969 overflow 0 timer-reads 1939 duration 69.248328 average 13.993118 min 6.222621 max 28.422380 median 15.235517 low1 6.717671 low0.1 6.222621 high1 27.658456 mean-frame 15.507868 stddev 4.755007 variance 22.610091
fps-percentiles p0.1 6.222621 p1 7.068009 p5 8.212089 p50 15.235517 p95 23.622576 p99 26.565144 p99.9 28.422380
fps-events drop-threshold 10.494838 drops 159 longest-drop 16 spike-threshold 17.491397 spikes 296 longest-spike 43 invalid 0
~~~

The same summary is written as DOS-safe `timedemo.jsn`.  The PowerShell
runner embeds it under each run's `fpsStats` property and adds a
multi-run `fpsSummary` containing median values for comparison.  The JSON
also records the number of stored/overflowed samples and the frame-statistics
timer-read count.

A matched one-run overhead check on the pinned profile measured 69.248276
seconds with frame statistics and 69.235233 seconds with `-NoFpsStats`, or
approximately **0.019%** collection overhead.  Both runs completed all 969
frames and produced framebuffer checksum `4154140932`.

The default pass keeps the z-buffer base in a register across each z-span list
and reuses a dead register for the second packed depth pair.  The turbulent
span routine also loads its invariant table pointer once per span call.  The
depth arithmetic, water sampling, and turbulent-span color results are unchanged.

The release surface-cache header keeps the variable pixel tail at a four-byte
boundary and omits the unused debug-only height field.  This moves the pixel
data from offset 48 to 44 and recovers 4 bytes per allocated cache block;
builds with `DEBUG` retain the height field and original layout.  The cache
manager also skips redundant LRU unlink/relink work for a block already at
the head and returns newly allocated blocks directly.  These are memory and
allocator-path improvements; the matched timedemo change is within run noise.

Sprite model loading no longer clears each sprite frame a second time after
Hunk_AllocName returns it.  Hunk_AllocName already zeroes the complete,
16-byte-rounded allocation; Mod_LoadSpriteFrame then assigns its metadata and
fully writes the pixel tail through either the 8-bit copy or 16-bit conversion
path.  The allocation size and model layout are unchanged.  The cleanup passed
the 486 correctness harness and three seeded demo1 timedemos: 969 frames and
checksum 1047377823 on every run, with times 59.408076, 59.408052, and
59.408186 seconds.  This is a load-time memory-traffic cleanup rather than
an observed frame-rate gain.

The particle record packs its palette index and type into one byte each while
keeping the assembly-used offsets stable.  This shrinks each record from 44
to 40 bytes and saves 8 KiB in the default 2048-particle pool.  The 486
assembly drawer loads the palette byte directly instead of converting it
through the FPU.  Particle expiry is handled in one pointer-to-link walk,
and empty particle frames return before projection setup.  Brightfield
particle initialization now uses an explicit one-shot flag and no longer
evaluates an unused third-axis sine/cosine pair.
The final matched release timedemo remained within normal run noise, so these
particle changes are footprint and hot-path cleanups rather than a claimed
end-to-end FPS gain.

The renderer's per-frame texture-axis cache can be screened at 64, 128, or
256 entries without editing source files.  Each value uses a separate ignored
build directory:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -TextureAxisCacheEntries 128
.\tools\timedemo-dos.ps1 -TextureAxisCacheEntries 128 -DataRoot 'C:\path\to\Quake\id1' -Runs 3
~~~

A one-run demo1 screen under the same pinned profile completed all 969 frames
at 13.917021 FPS (64 entries), 13.917025 FPS (128), and 13.917031 FPS (256).
Those differences are within run noise, so the fidelity-preserving default
remains 256 entries.  Use matched multi-run measurements before selecting a
different footprint for a specific target.

For an AMD 5x86/486DX5-133-class target, add this option to the DOSBox-X
command line:

~~~powershell
-set 'cpu cycles=fixed 47810'
~~~

Keep the DOSBox-X version, profile, demo, and cycle setting unchanged when
comparing results.  Timedemo FPS is emulator evidence, not a native Windows
performance measurement.

## 486 microbenchmark build

Build an isolated, DOS 8.3-compatible benchmark executable so the normal
`quake.exe` is not overwritten:

~~~powershell
.\tools\build-dos.ps1 -Benchmark
~~~

With Quake data available, the repository runner can stage and execute the
benchmark under the pinned 486 DOSBox-X profile:

~~~powershell
.\tools\bench-dos.ps1 -DataRoot 'C:\path\to\Quake\id1'
~~~

Stage `out\dos\qbench.exe` beside `cwsdpmi.exe` and the `id1` data
directory, then run it in DOSBox-X with the same 486 profile and this command:

~~~text
qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchexit
~~~

The `bench486` command compares the existing C `Q_memset`/`Q_memcpy`
implementations with separate hand-written 486 assembly functions, then also
measures the existing rectangle-fill and alias-edge setup paths.  It validates
the complete working region before timing, prints five alternating samples per
case, and writes `bench486.txt` in the Quake directory.  The matrix covers
small and large lengths, dword boundaries, aligned buffers, independently
unaligned buffers, and zero/negative counts.  The assembly experiment is
used directly by the benchmark and is also available to normal `quake.exe`
builds through the explicit `-MemoryImplementation asm` switch; the 486-oriented
default now uses the ASM helpers, while `-MemoryImplementation c` retains the
original C helpers for reference comparisons.

The focused benchmark can select each implementation independently:

~~~powershell
.\tools\bench-dos.ps1 -MemoryImplementation asm `
  -TextureAxisImplementation asm `
  -SurfaceCacheImplementation asm `
  -MipLevelImplementation asm `
  -TurbulentImplementation stosb `
  -LightMapNormalizeImplementation asm `
  -BspPlaneDotImplementation asm `
  -BspClipImplementation asm `
  -AliasTransformFinalImplementation asm `
  -DataRoot 'C:\path\to\Quake\id1'
.\tools\bench-dos.ps1 -TextureAxisImplementation c `
  -SurfaceCacheImplementation c `
  -MipLevelImplementation c `
  -TurbulentImplementation asm `
  -AliasBBoxProjectImplementation c `
  -AliasTransformFinalImplementation c `
  -DataRoot 'C:\path\to\Quake\id1'
~~~

Individual implementation switches can be omitted.  The defaults are C for
memory helpers, texture-axis, surface-cache, mip-level selection, BSP plane
dot, and BSP clipping; `stosb` for turbulent spans; and ASM for alias
projection, alias bounding-box projection, clipped alias transform/lighting,
texture animation, and lightmap normalization.  Pass
`-TurbulentImplementation asm` for the existing ASM control.  The runner
records all twelve selections in `bench-result.json` and uses a matching output
directory suffix.  Use `-TurbulentOnly`, `-AliasProjectOnly`,
`-AliasBBoxProjectOnly`, `-AliasTransformFinalOnly`, `-TextureAnimationOnly`,
`-LightMapNormalizeOnly`, `-BspPlaneDotOnly`, or `-BspClipOnly` to run only the
corresponding focused experiment instead of the longer general matrix.

Compare runs using the same DOSBox-X version, profile, cycle count, executable
mode, and data set.  The benchmark is diagnostic evidence for these routines;
timedemo FPS remains the end-to-end renderer check.

### Memory helper experiment result

A matched run on 2026-09-10 used DOSBox-X 2026.08.31, `cputype=486`, fixed
33445 cycles, the baseline `-O2 -march=i486` build, and the staged `id1`
payload.  All C and ASM checksums matched and the report ended with
`486 benchmark correctness PASS`.

The median results show that the assembly is promising but not yet an engine
integration decision:

| Case | ASM median versus C |
| --- | ---: |
| `memcpy`, aligned, 256 bytes | 12.273% faster |
| `memcpy`, aligned, 1024 bytes | 4.569% faster |
| `memcpy`, both pointers offset by one, 255 bytes | 8.198% faster |
| `memcpy`, source offset one/destination offset two, 255 bytes | 64.400% faster |
| `memset`, aligned, 256 bytes | 15.951% faster |
| `memset`, aligned, 1024 bytes | 6.104% faster |
| `memset`, destination offset by one, 255 bytes | 15.810% faster |

The first implementation used a hand-written byte loop for the
mismatched-alignment copy and was 94.743% slower.  Replacing that fallback
with 486-compatible `rep movsb` removed the regression.  The remaining gain
comes from keeping alignment/count handling in one assembly routine and using
`rep movsl`/`rep stosl` for dword-sized work; this is microbenchmark evidence,
not proof that every Quake call site benefits.

The normal build keeps these functions out of the real execution path.  The
following opt-in runtime variant uses the same routines only after identifying
call-site alignment and size distributions, then checking exact framebuffer
results with a matched multi-run `demo1` timedemo.

The runtime switch above is the controlled integration candidate.  It keeps
the original C implementations as the reference and changes only the helper
dispatch in the `asm` build.  Do not use `bench-dos.ps1` with the ASM runtime
variant for C-versus-ASM timing: in that build the public C entry points are
intentionally routed to ASM.  Use the C benchmark build for the focused
correctness/microbenchmark matrix, then use matched timedemos for the runtime
comparison:

~~~powershell
.\tools\timedemo-dos.ps1 -MemoryImplementation c `
  -DataRoot 'C:\path\to\Quake\id1' -Runs 3
.\tools\timedemo-dos.ps1 -MemoryImplementation asm `
  -DataRoot 'C:\path\to\Quake\id1' -Runs 3
~~~

The timedemo result records `memoryImplementation` and the build manifest
records the same choice, so the two executables can be audited without relying
on filenames alone.

### Runtime memory-helper result

The controlled runtime comparison used the same baseline `-O2 -march=i486`
build, DOSBox-X 2026.08.31, `cputype=486`, fixed 33445 cycles, `demo1`, and
the same staged `id1` data.  Three runs per variant produced 969 frames and
the exact final framebuffer checksum `4154140932` on every run.

| Variant | Timedemo seconds, three runs | Mean FPS | Median FPS |
| --- | --- | ---: | ---: |
| C reference | 69.174217 / 69.174208 / 69.174256 | 14.008107 | 14.008109 |
| ASM runtime | 69.159824 / 69.159891 / 69.159892 | 14.011016 | 14.011011 |

The ASM path is repeatably **0.0208% faster** in this DOSBox-X run, or about
14.4 ms over the 69.17-second timedemo.  The gain is real but too small to
justify changing the default build; `c` remains the shipped/reference
selection and `asm` remains available for target-specific testing.  The
profiled workload made 1,019 `memset` calls over 24,738 bytes and 35,945
`memcpy` calls over 4,277,631 bytes.  98.4% of `memset` calls were destination
aligned and 97.3% of `memcpy` calls had matching source/destination alignment.
This explains why the microbenchmark wins do not become a large engine win:
the helpers touch relatively little data compared with the renderer's major
hotspots.

The focused matrix was rerun against the current C reference and ASM routines
with five alternating samples per case; it ended with
`486 benchmark correctness PASS`.  The ASM path uses alignment-aware setup and
`rep movsl`/`rep stosl`, with `rep movsb` for mismatched-copy alignment.  The
full timedemo confirms functional equivalence, but the measured end-to-end
advantage is diagnostic rather than a reason to make ASM the default.

### Texture-axis cache probe result

The next isolated experiment kept the `D_GetTextureAxes` hash, miss path, and
vector transforms in C, and replaced only the three-key cache hit/miss condition
with a hand-written 486 helper.  The C helper and ASM helper were checked against
hit, each individual key mismatch, and a null entry before timing.

The focused benchmark used five alternating samples of 500,000 calls per case:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Cache hit | 0.358844 s | 0.358850 s | -0.002% |
| Early `texinfo` miss | 0.269138 s | 0.269138 s | 0.000% |

The run ended with `486 benchmark correctness PASS`.  A one-run full `demo1`
timedemo using the ASM probe completed all 969 frames at 14.001678 FPS with the
same framebuffer checksum `4154140932` as the C/reference runs.  Because the
focused result shows no measurable advantage, the original C condition remains
the default and the ASM probe remains an opt-in learning aid rather than an
integration candidate.

### Surface-cache predicate result

The surface-cache experiment replaced only the cache-validity predicate in
`D_CacheSurface`.  The ASM helper compares the cache pointer, dlight state,
surface/frame invalidation key, texture pointer, and four light adjustments;
allocation and `R_DrawSurface` remain untouched.  The original C predicate is
still the default path.

The focused benchmark used five alternating samples of 500,000 calls per case:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Cache hit | 0.598076 s | 0.568170 s | 5.000% |
| Texture miss | 0.388750 s | 0.373800 s | 3.846% |
| Early dlight rejection | 0.299037 s | 0.284088 s | 4.999% |

The matrix ended with `486 benchmark correctness PASS`.  Disassembly showed
why the isolated helper wins: the standalone C probe reloads the light-adjustment
pointer for its last comparison, while the ASM probe keeps it live.  That result
does not describe the real C path, where GCC already inlines the predicate and
allocates registers across the surrounding function.

Matched three-run `demo1` timedemos therefore rejected integration:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference | 69.174276 / 69.174257 / 69.174263 | 14.008100 |
| ASM predicate | 69.194989 / 69.194988 / 69.194975 | 14.003905 |

All runs completed 969 frames with framebuffer checksum `4154140932`.  The ASM
call boundary costs about 0.030% end-to-end, or 20.7 ms per timedemo, so C
remains the default and the surface-cache ASM path remains an opt-in experiment.

### Mip-level selector result

The mip-level experiment replaced the compact `D_MipLevelForScale` function with
a 486 x87 implementation.  The C and ASM selectors were checked at every
threshold, between thresholds, below the final threshold, and with a raised
`d_minmip` clamp.  Because the standalone benchmark command runs before a map
view initializes `d_scalemip`, the harness temporarily installs the known
baseline thresholds `1.0`, `0.4`, and `0.2`, then restores the renderer globals.

The focused benchmark used five alternating samples of 500,000 calls per case:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Level 0 | 0.284087 s | 0.299038 s | -5.263% |
| Level 1 | 0.358844 s | 0.358850 s | -0.002% |
| Level 2 | 0.418657 s | 0.418657 s | 0.000% |
| Level 3 | 0.418657 s | 0.388750 s | 7.143% |
| `d_minmip` clamp | 0.343894 s | 0.373801 s | -8.697% |

The corrected matrix ended with `486 benchmark correctness PASS`.  Disassembly
showed that keeping the scale on the x87 stack removes the initial ASM reload
penalty, but the resulting branch paths still trade wins and losses by mip
level.  The real C function already uses one x87 value across its comparisons.

Matched three-run `demo1` timedemos rejected integration:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference | 69.174320 / 69.174332 / 69.174286 | 14.008088 |
| ASM selector | 69.180708 / 69.180710 / 69.180694 | 14.006795 |

All runs completed 969 frames with framebuffer checksum `4154140932`.  The ASM
selector is about 0.0092% slower, or 6.4 ms per timedemo, so C remains the
default and the x87 implementation remains a reversible learning experiment.
The next candidate should be measured only after identifying a path where the
compiler cannot already retain the relevant state across the full function.

### Turbulent-span inner-loop result

The active turbulent sampler is a compact, sequential 486 loop: the sine
table, fixed-point coordinates, destination, and span count stay in registers;
the texture address is derived with shifts and indexed loads.  The preserved C
reference was benchmarked against the existing assembly at 4, 8, 16, and
64-pixel spans using five alternating samples of 50,000 calls per case.  All
four cases produced identical checksums and destination advancement.

| Span length | C median | Existing ASM median | ASM versus C |
| ---: | ---: | ---: | ---: |
| 4 | 0.231757 s | 0.183910 s | 20.645% |
| 8 | 0.435101 s | 0.327449 s | 24.742% |
| 16 | 0.841793 s | 0.614521 s | 26.999% |
| 64 | 3.281913 s | 2.336964 s | 28.793% |

The focused report is `out\dos-bench-20260910-163948\bench-result.json`.
This confirms the value of the existing hand-written loop, but it does not
justify a new rewrite by itself because the target already runs that ASM path.

The follow-up `stosb` variant removes the explicit destination increment and
uses `STOSB` for the sequential store.  Its corresponding focused ASM medians
were 0.183910, 0.327449, 0.614521, and 2.336965 seconds.  At the report
precision that is 0.000% versus the existing ASM in every case; the 64-pixel
case is fractionally slower in this isolated harness.  The matched end-to-end
result nevertheless favored `stosb`: current ASM measured 69.178593 seconds
versus 69.118956 seconds for `stosb` across three runs, or 0.086207% faster
(0.086284% by median FPS).  All six runs completed 969 frames with framebuffer
checksum `4154140932`.  This is
consistent with the shorter sequential-store instruction sequence in the real
renderer loop; the isolated harness is dominated by equal state-reset and
function-call overhead.  `stosb` is now the target default, while
`-TurbulentImplementation asm` remains the reversible control.  The variant
report is `out\dos-bench-20260910-161309\bench-result.json`.

The matched timedemo results are
`out\dos-timedemo-20260910-164048\timedemo-result.json` and
`out\dos-timedemo-20260910-164524\timedemo-result.json`.

### Alias-project projection result

The alias projection experiment targets the clipped-model path that remains in
C after the larger unclipped transform is already in assembly.  The C compiler
emits three separate x87 control-word save/set/restore sequences around the
truncating `fistp` stores.  The ASM version preserves the same divide,
multiplication order, truncation mode, and output layout, but performs one
control-word transition for all three stores.

The focused benchmark used five alternating samples of 100,000 calls for three
representative projected points.  All output structures and checksums matched:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Far | 0.122609 s | 0.113638 s | 7.317% |
| Near | 0.122608 s | 0.113638 s | 7.316% |
| Viewmodel | 0.122609 s | 0.113638 s | 7.317% |

The focused reports are `out\dos-bench-20260910-170809\bench-result.json` and
`out\dos-bench-20260910-170826\bench-result.json`; both ended with
`486 benchmark correctness PASS`.

Matched three-run `demo1` timedemos completed all 969 frames with framebuffer
checksum `4154140932` on every run:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference | 69.118988 / 69.118947 / 69.119012 | 14.019302 |
| ASM projection | 69.106757 / 69.106747 / 69.106757 | 14.021783 |

ASM is 12.231 ms faster per timedemo, or 0.017696%.  The focused gain is
larger because it isolates the helper; the whole-engine result is the authority.
The ASM implementation is now the target default, while
`-AliasProjectImplementation c` remains the reversible reference/control.
The matched timedemo results are `out\dos-timedemo-20260910-170850\timedemo-result.json`
and `out\dos-timedemo-20260910-171246\timedemo-result.json`.

### Texture-animation frame-selection result

This experiment kept alternate-animation selection, the no-animation fast
path, relative-time calculation, and error handling in C.  It replaced only
the loop that follows `anim_next` until `anim_min <= relative < anim_max`.
The ASM loop keeps the current texture pointer, relative phase, and traversal
count in registers and uses the 486's simple integer compare/branch path.

The focused benchmark used five alternating samples of 500,000 calls per
case.  Correctness checked every relative phase from every starting node in
2-, 4-, and 8-frame synthetic cycles:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| 2-frame first | 0.373801 s | 0.254188 s | 31.999% |
| 4-frame middle | 0.672833 s | 0.583126 s | 13.333% |
| 8-frame tail | 1.420422 s | 1.405472 s | 1.052% |
| 8-frame wrap | 0.493414 s | 0.388750 s | 21.212% |

Both runs ended with `486 benchmark correctness PASS`.  The focused reports
are `out\dos-bench-20260910-173504\bench-result.json` and
`out\dos-bench-20260910-173545\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31, `cputype=486`,
fixed 33445 cycles, the baseline `-O2 -march=i486` build, and the same staged
`id1` data.  Every run completed 969 frames with framebuffer checksum
`4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference | 69.106714 / 69.106726 / 69.106788 | 14.021790 |
| ASM frame loop | 69.100226 / 69.100204 / 69.100272 | 14.023109 |

ASM is 6.500 ms faster per timedemo, or 0.009406%.  The improvement is small
but repeatable on the pinned profile, so ASM is now the controlled default;
`-TextureAnimationImplementation c` remains the explicit reference/control
build.  The timedemo results are `out\dos-timedemo-20260910-173632\timedemo-result.json`
and `out\dos-timedemo-20260910-174027\timedemo-result.json`.

### Lightmap normalization result

This experiment extracted only the final `R_BuildLightMap` loop that inverts,
shifts, and clamps the accumulated light values.  The C reference preserves
the original arithmetic and clamp order.  On the DJGPP 486 build, its loop
stores the intermediate value before the clamp and stores again afterward;
the hand-written ASM keeps the lightmap pointer and count in registers and
stores only the final value once per element.

The focused benchmark used five alternating samples of 25,000 normalizations
per case.  It covered a normal 16-element lightmap, a fully clamped
64-element lightmap, and a mixed 324-element maximum-size lightmap.  All
checksums matched and both runs ended with `486 benchmark correctness PASS`:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| 16-element normal | 0.134575 s | 0.121861 s | 9.447% |
| 64-element clamped | 0.493414 s | 0.444819 s | 9.849% |
| 324-element mixed | 2.437136 s | 2.194174 s | 9.969% |

The focused reports are `out\dos-bench-20260910-180627\bench-result.json`
and `out\dos-bench-20260910-180708\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31, `cputype=486`,
fixed 33445 cycles, the baseline `-O2 -march=i486` build, and the same staged
`id1` data.  Every run completed 969 frames with framebuffer checksum
`4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference | 69.100305 / 69.100324 / 69.100226 | 14.023093 |
| ASM normalization loop | 69.081314 / 69.081262 / 69.081366 | 14.026948 |

ASM is 19.0 ms faster per timedemo, or 0.0275%.  The improvement is small but
repeatable on the pinned profile and the exact framebuffer checksum matches,
so ASM is now the controlled default; `-LightMapNormalizeImplementation c`
remains the explicit reference/control build.  The timedemo results are
`out\dos-timedemo-20260910-180756\timedemo-result.json` and
`out\dos-timedemo-20260910-181150\timedemo-result.json`.

### BSP plane-dot result

This experiment isolated the `R_RecursiveWorldNode` calculation that chooses
the front child from an axis-aligned or generic plane.  The original C path
remains inline in the production function; the ASM build calls a small helper
that uses direct x87 loads/subtracts for X/Y/Z planes and the C multiply/add
order for generic planes.

The focused benchmark used five alternating samples of 500,000 calls per
case.  All four cases produced identical C/ASM results and both runs ended
with `486 benchmark correctness PASS`:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Axis X | 0.284088 s | 0.224281 s | 21.052% |
| Axis Y | 0.224282 s | 0.254188 s | -13.334% |
| Axis Z | 0.254188 s | 0.284087 s | -11.763% |
| Generic | 0.403701 s | 0.388750 s | 3.703% |

The focused reports are `out\dos-bench-20260910-183819\bench-result.json`
and `out\dos-bench-20260910-183844\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31, `cputype=486`,
fixed 33445 cycles, the baseline `-O2 -march=i486` build, and the same staged
`id1` data.  Every run completed 969 frames with framebuffer checksum
`4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C inline switch | 69.081304 / 69.081398 / 69.081343 | 14.026942 |
| ASM helper call | 69.106675 / 69.106670 / 69.106686 | 14.021800 |

The ASM helper is 25.3 ms slower per timedemo, or 0.0367%.  The isolated
results do not overcome the call boundary and branch-layout cost in the real
recursive walk, so C remains the default and `-BspPlaneDotImplementation asm`
remains an opt-in 486 learning aid.

The timedemo results are `out\dos-timedemo-20260910-183914\timedemo-result.json`
and `out\dos-timedemo-20260910-184313\timedemo-result.json`.

### BSP frustum-clipping result

This experiment isolated the four-plane frustum clip block in
`R_RecursiveWorldNode`.  The original C loop remains intact as the production
default; the ASM build calls a helper that uses register-held pointers and
x87 dot products while preserving the C helper's reject/reduced-mask contract.

The focused benchmark used five alternating samples of 200,000 calls per
case.  All five cases produced identical C/ASM results and both runs ended
with `486 benchmark correctness PASS`:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| No active planes | 0.352864 s | 0.155505 s | 55.931% |
| All visible | 1.381551 s | 1.393505 s | -0.865% |
| Partial clip | 1.285852 s | 1.345659 s | -4.651% |
| Early reject | 0.352870 s | 0.316984 s | 10.170% |
| Single plane | 0.586115 s | 0.610036 s | -4.081% |

The focused reports are `out\dos-bench-20260910-194325\bench-result.json`
and `out\dos-bench-20260910-194526\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31, `cputype=486`,
fixed 33445 cycles, the baseline `-O2 -march=i486` build, and the same staged
`id1` data.  Every run completed 969 frames with framebuffer checksum
`4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C inline clip loop | 69.081318 / 69.081351 / 69.081286 | 14.026947 |
| ASM helper | 69.271228 / 69.271287 / 69.271216 | 13.988492 |

The ASM helper is 189.9 ms slower per timedemo, or 0.2749%.  The fast reject
cases do not dominate the real workload, while the visible and partial paths
pay for the helper's x87 work and call boundary.  C therefore remains the
default and `-BspClipImplementation asm` remains an opt-in 486 learning aid.

The timedemo results are
`out\dos-timedemo-20260910-194827\timedemo-result.json` and
`out\dos-timedemo-20260910-195220\timedemo-result.json`.

### Alias bounding-box projection result

This experiment isolated the projection and four-way XY clip loop in
`R_AliasCheckBBox`.  The original C loop remains in the source as the
reference implementation; the ASM build selects a small helper that keeps
the two vertex pointers, loop state, and clip masks in registers.  It uses
the x87 reciprocal once per eligible vertex and reuses it for the X and Y
projections.

The focused benchmark used five alternating samples of 200,000 calls per
case.  All four cases produced identical C/ASM results and ended with
`486 benchmark correctness PASS`:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Inside, 8 vertices | 2.476012 s | 2.015502 s | 18.599% |
| Mixed XY clipping, 8 vertices | 2.523859 s | 2.063348 s | 18.246% |
| Z-clipped, 16 vertices | 3.002316 s | 2.398260 s | 20.120% |
| All-left clipping, 8 vertices | 2.476012 s | 2.063341 s | 16.667% |

The focused report is `out\dos-bench-20260910-202504\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31,
`cputype=486`, fixed 33445 cycles, the baseline `-O2 -march=i486` build, and
the same staged `id1` data.  Every run completed 969 frames with framebuffer
checksum `4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference loop | 69.081275 / 69.081372 / 69.081242 | 14.026956 |
| ASM helper | 69.063016 / 69.062994 / 69.063055 | 14.030664 |

The ASM helper is 18.259 ms faster per timedemo, or 0.0264%.  A matching
instrumented one-run profile also preserved the checksum (instrumentation
changes timing): C took 76.930752 s and ASM took 76.912577 s.  The profile
workload contained 5,470 alias-model work items and 43,956,198 texture pixels,
which explains why a strong 16.7--20.1% isolated loop result becomes a small
end-to-end gain.  The repeatable release win is sufficient for the ASM path to
be the default, while the C path remains a build-time control for regression
testing.

The timedemo results are
`out\dos-timedemo-20260910-202746\timedemo-result.json` and
`out\dos-timedemo-20260910-203140\timedemo-result.json`.

### Clipped alias vertex transform result

This experiment isolated `R_AliasTransformFinalVert`, the C-only transform and
lighting helper used for clipped alias-model vertices.  The C body remains
intact as the reference implementation.  The ASM helper expands the three
packed vertex coordinates once, keeps the three matrix dot products on the
x87 stack, and combines the lighting dot product before returning the same
fields.

The focused benchmark used five alternating samples of 200,000 calls per
light case.  The C and ASM helpers matched byte-for-byte, including untouched
sentinel fields, and the run ended with `486 benchmark correctness PASS`:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Ambient light | 0.627982 s | 0.502383 s | 20.000% |
| Shaded light | 0.687788 s | 0.514343 s | 25.218% |
| Clamped light | 0.693769 s | 0.520329 s | 25.000% |

The focused reports are
`out\dos-bench-20260910-210423\bench-result.json` and
`out\dos-bench-20260910-211039\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31,
`cputype=486`, fixed 33445 cycles, the baseline `-O2 -march=i486` build, and
the same staged `id1` data.  Every run completed 969 frames with framebuffer
checksum `4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference helper | 69.063022 / 69.062948 / 69.062989 | 14.030670 |
| ASM helper | 68.958781 / 68.958804 / 68.958785 | 14.051872 |

The ASM helper is 104.204 ms faster per timedemo, or 0.150883%.  The gain is
consistent across the three runs and comes from removing repeated byte
loads and C-generated temporary traffic while using the same x87 arithmetic;
the function call boundary is shared by both variants.  This is a measured
end-to-end win, so the ASM path is now the default, while
`-AliasTransformFinalImplementation c` remains available for regression and
matched A/B runs.

The timedemo results are
`out\dos-timedemo-20260910-211835\timedemo-result.json` and
`out\dos-timedemo-20260910-211109\timedemo-result.json`.

### Optimization profiles and instrumentation

The default build is the measured `aggressive` profile (`-O3`,
`-march=i486`, and no newer instruction-set requirement).  `-O2` remains
available for A/B comparison and writes beside the default build:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -OptimizationProfile baseline
.\tools\timedemo-dos.ps1 -OptimizationProfile baseline `
  -DataRoot 'C:\path\to\Quake\id1' -Runs 3
~~~

A matched 2026-09-10 `-O3` rerun after the `Mod_LoadTexinfo` UB fix reached
**14.162237 FPS** (`68.421397` seconds median;
`out\dos-timedemo-20260910-232607`) versus **14.054401 FPS** for `-O2`,
about 0.76% faster, with checksum `4154140932` on every run.  `-O3`
`quake.exe +quit` smoke passed, so `aggressive` is now the default.
The subsequent bmodel span-rotation cache reached **14.170874 FPS**
(`68.379696` seconds median; `out\dos-timedemo-20260910-233942`).
Fusing ambient into the first lightmap style reached **14.185365 FPS**
(`68.309838` seconds median; `out\dos-timedemo-20260910-234742`).
Fusing invert/clamp into that one-style write reached **14.194521 FPS**
(`68.265779` seconds median; `out\dos-timedemo-20260911-051131`).
Extending that fusion to extra styles reached **14.194657 FPS**
(`68.265121` seconds median; `out\dos-timedemo-20260911-051834`).
The integer dlight inner loop reached **14.206133 FPS**
(`68.209972` seconds median; `out\dos-timedemo-20260911-052933`).
The face Z-gradient cache reached **14.208466 FPS**
(`68.198777` seconds median; `out\dos-timedemo-20260911-053759`).
Power-of-two column wrap reached **14.208790 FPS**
(`68.197221` seconds median; `out\dos-timedemo-20260911-054347`).
`D_DrawZSpans` `zspantable` addressing reached **14.239663 FPS**
(`68.049361` seconds median; `out\dos-timedemo-20260911-062059`).

### Rejected negative-gradient Z-span unroll

A 486-specific experiment mirrored the positive-gradient eight-pixel
`SHLD`/`ROR` packing schedule in the negative-gradient `D_DrawZSpans` loop.
The current seeded recheck is the authoritative result for this selector; the
older measurements below remain historical and are not mixed into acceptance.
All three optimized and control timedemos completed 969 frames and retained
the canonical seeded framebuffer checksum `1047377823`. The optimized runs
measured `59.419754`, `59.419747`, and `59.419764` seconds; the four-pixel
control measured `59.419770`, `59.419740`, and `59.419744` seconds.
The optimized median was marginally slower, so the experiment was reverted and
the existing four-pixel negative-gradient path remains the release default.

Texture-span `viewspantable` dest addressing reached **14.250078 FPS**
(`67.999624` seconds median; `out\dos-timedemo-20260911-063418`).
Extending `viewspantable` to polyset, sprites, and particles reached
**14.251887 FPS** (`67.990997` seconds median;
`out\dos-timedemo-20260911-064221`).
Sprite/particle `zspantable` Z addressing reached **14.252866 FPS**
(`67.986326` seconds median; `out\dos-timedemo-20260911-065037`).
A 1200 KB surface cache reached **14.373452 FPS**
(`67.415956` seconds median; `out\dos-timedemo-20260911-133815`).
A 1800 KB surface cache reached **14.409100 FPS**
(`67.249168` seconds median; `out\dos-timedemo-20260911-134300`).
`Turbulent8` `viewspantable` dest rows reached **14.409378 FPS**
(`67.247873` seconds median; `out\dos-timedemo-20260911-143822`).
The static `D_CacheSurface` hit path reached **14.413306 FPS**
(`67.229543` seconds median; `out\dos-timedemo-20260911-152128`).
The `D_PolysetDrawFinalVerts` clip-rect hoist reached **14.415652 FPS**
(`67.218606` seconds median; `out\dos-timedemo-20260911-152839`).
Skipping unused extra light styles on cache hits reached **14.419549 FPS**
(`67.200437` seconds median; `out\dos-timedemo-20260911-154031`).
`D_RasterizeAliasPolySmooth` dest/Z row tables reached **14.422704 FPS**
(`67.185736` seconds median; `out\dos-timedemo-20260911-161154`).
`R_RenderFace` surfedges hoist plus clip unroll reached **14.441731 FPS**
(`67.097222` seconds median; `out\dos-timedemo-20260911-173034`).
Clipped-bmodel `surfedges` hoist reached **14.441920 FPS**
(`67.096341` seconds median; `out\dos-timedemo-20260911-174206`).
`R_DrawSurface` 8-bit setup reached **14.442450 FPS**
(`67.093880` seconds median; `out\dos-timedemo-20260911-174904`).
Mipscale step tables in `D_CalcGradients` reached **14.442880 FPS**
(`67.091882` seconds median; `out\dos-timedemo-20260911-182120`).
Skipping the unused `D_CacheSurface` `surfscale` FDIV reached
**14.444235 FPS** (`67.085585` seconds median;
`out\dos-timedemo-20260911-191612`).
A 15-way last-segment divisor switch matched the checksum but was
27.6 ms slower (`out\dos-timedemo-20260911-150819`).
1900 KB, 2000 KB, 2100 KB, and 2400 KB all produced checksum
`2955717646` and were reverted.  A branched POT skinwidth shift in
`D_PolysetCalcGradients` matched the checksum but was 11.7 ms slower
(`out\dos-timedemo-20260911-140630`).
Hoisting `aliasvrect` locals in `R_AliasPreparePoints` matched the
checksum but was 15.7 ms slower (`out\dos-timedemo-20260911-153350`).
Unclipped alias `movzbl` expansion was noise
(`out\dos-timedemo-20260911-155009`).  Fused frustum `minmaxs`
multiplies hitched on run 3 (`out\dos-timedemo-20260911-155650`).
Stacking `acolormap` in `D_PolysetDrawFinalVerts` was 0.18 ms slower
(`out\dos-timedemo-20260911-160304`).
A last-used `D_CalcGradients` step-origin cache was 34.3 ms slower
(`out\dos-timedemo-20260911-161755`).
Unrolling `R_RenderBmodelFace` clip planes was noise
(`out\dos-timedemo-20260911-173554`).
Folding `R_DrawSurface` soffset wrap into the column POT test hitched
(`out\dos-timedemo-20260911-175849`).
Hoisting `currententity->model` in `R_RenderFace` was noise
(`out\dos-timedemo-20260911-180409`).
Skipping `R_AnimateLight` IDIV for `len==1` was 2.1 ms slower
(`out\dos-timedemo-20260911-180922`).
Hoisting `r_pcurrentvertbase` in `R_RenderFace` was 32.0 ms slower
(`out\dos-timedemo-20260911-182623`).
Precomputing mip-scaled `transformed_modelorg` was 4.2 ms slower
(`out\dos-timedemo-20260911-183436`).
Skipping no-op bmodel Restore/Set CALLs in `D_DrawSurfaces` was
1.4 ms slower (`out\dos-timedemo-20260911-184541`).
A per-surface compare/direct `D_DrawSpans16` call was 9.3 ms slower
(`out\dos-timedemo-20260911-185331`).
Hoisting `r_drawpolys` out of `R_RecursiveWorldNode` surface loops
hitched to 1.89 FPS (`out\dos-timedemo-20260911-185857`).
`skintable` start addressing in `D_RasterizeAliasPolySmooth` was
178.6 ms slower (`out\dos-timedemo-20260911-190512`).
Skipping live `blocksize` in `R_DrawSurface` produced checksum
`2281919689` (`out\dos-timedemo-20260911-192431`).
Hoisting `r_drawsurf.surfmip` in `R_DrawSurface` was noise
(`out\dos-timedemo-20260911-193158`).
`-OptimizationProfile baseline` still builds `-O2` into `out\dos-baseline`.
An older 14.122 vs 13.917 FPS comparison predates the current ASM defaults
and is superseded.

Use `-Instrumentation` with `-Benchmark` to build `out\dos-profile\qprof.exe`
and collect the hierarchical renderer profile through the timedemo runner:

~~~powershell
.\tools\timedemo-dos.ps1 -Instrumentation `
  -DataRoot 'C:\path\to\Quake\id1' -Runs 1
~~~

Instrumentation changes timing, so its FPS is diagnostic only.  The release
`qbench.exe` timedemo remains the authority for performance comparisons.  The
profile build writes three artifacts beside the executable in its DOS staging
directory:

- `timedemo.txt` contains the legacy flat counters plus a readable tree and a
  ranked self-time list.  With `-fpsstats`, it also contains the concise
  per-frame FPS summary.
- `timedemo.jsn` is an 8.3-safe JSON document containing the FPS summary,
  percentiles, variation, event counts, and sample-storage diagnostics.
- `profile.jsn` is an 8.3-safe JSON document containing node statistics,
  observed parent-to-child edges, benchmark metadata, workload metrics, and
  `memory` call/byte/alignment counters.
  The runner embeds both JSON documents under each run in
  `timedemo-result.json`.

Render the machine-readable profile as a tree and ranked views with:

~~~powershell
.\tools\profile-report.ps1 `
  -ProfileJson '.\out\dos-timedemo-YYYYMMDD-HHMMSS\quake\profile.jsn' `
  -BaselineResult '.\out\dos-timedemo-YYYYMMDD-HHMMSS\timedemo-result.json'
~~~

`-BaselineResult` is optional; when supplied, the report estimates profiling
overhead from the matched release timedemo.  It also reads a sibling
`timedemo.jsn` and prints the per-frame FPS summary.  `-BaselineSeconds
<seconds>` can be used instead when the release result is stored elsewhere.

The profile is a fixed-stack instrumentation layer designed for repeated
486-class runs.  Its observed execution graph is:

~~~text
frame
|- input
|- game
|- screen
|  |- view
|     |- view-lights
|     |- renderer
|        |- setup / visibility
|        |- edge-drawing
|           |- world-bsp
|           |- edge-scan
|              |- surfaces
|                 |- surface-cache / gradients
|                 |- texture-spans / z-spans
|                 |- turbulent-spans / sky-spans / solid-spans
|           |- brush-entities
|        |- entities -> sprites / alias-model
|        |- viewmodel -> alias-model
|        |- particles / warp
|  |- overlay / palette / present
|- audio -> sound-spatial / sound-mix / cd-audio
~~~

The JSON `edges` array is the authoritative parent-to-child relationship.  It
is collected from the actual runtime stack, so `sound-mix` can correctly
appear below an extra render update as well as below the normal audio phase.
The tree reports edge-inclusive and edge-self time for each occurrence, while
the node records aggregate totals across all parents.  Inclusive time answers
"how expensive is this subsystem with its children"; self time answers "what
remains in this node after measured children" and identifies expensive leaf
operations.  Nested percentages must not be added together.

The profiler times the stable frame, screen, view, renderer, edge, surface,
cache, gradient, span, entity, particle, sound, and present boundaries.  It
does not time every recursive BSP or scanline callback.  Instead it counts BSP
nodes/leaves/culls/surface tests, scanlines, edge insert/remove/step calls,
span flushes, surface classes, spans/pixels/16-pixel segments, alias models
and vertices, particles, presented rectangles/pixels, and sound updates/mixes.
That keeps the hot recursive paths lightweight while still explaining their
cost.

A matched 2026-09-10 diagnostic snapshot, collected before the clipped alias
transform promotion, measured the instrumented profile
at `77.017236` seconds and the raw release timedemo at `69.162451` seconds, an
estimated **11.36% profiling overhead**.  The profile run also used 520,782
profile timer reads plus 1,939 frame-statistics timer reads, reached stack
depth 8, and reported zero stack errors; two open scopes were intentionally
discarded when timedemo exit occurred inside the final demo message.  This
overhead is acceptable for diagnosis but the instrumented FPS must not be used
as an optimization result.

The current canonical seeded fixture was revalidated after adding the platform
coverage. The release run completed 969 frames in 59.419751 seconds
(16.307709 FPS) with framebuffer checksum 1047377823. The matched
instrumented run completed the same 969 frames in 67.282890 seconds
(14.401878 diagnostic FPS) with the same checksum. Its platform counters
were zero for joystick and collision work because the canonical timedemo uses
-nojoy; use an interactive PROFILE486 run with input enabled when measuring
those paths.

The current self-time ranking from that profile is:

The platform line in timedemo.txt has this form:

~~~text
platform joystick-reads <count> joystick-poll-iterations <count> joystick-timeouts <count> move-calls <count> hull-check-calls <count>
~~~text

| Rank | Node | Self seconds | % of profiled frame | Work |
| ---: | --- | ---: | ---: | --- |
| 1 | Texture spans | 19.708498 | 25.60% | 1,454,414 spans / 43,956,202 pixels |
| 2 | Surface cache | 11.194143 | 14.54% | 55,300 normal surfaces |
| 3 | Alias model | 9.965974 | 12.95% | 5,470 models / 417,090 vertices |
| 4 | Z spans | 8.346734 | 10.84% | 58,051 surface calls |
| 5 | World BSP | 8.312930 | 10.80% | 375,709 BSP node visits |
| 6 | Edge scan self | 6.780973 | 8.81% | 147,288 scanlines |

These are measured diagnostic hotspots, not optimization instructions.  A
later confirmation profile (`out\dos-timedemo-20260910-222107`) ranked the
same leaves: texture spans 25.67%, surface cache 14.55%, alias 12.83%,
Z spans 10.87%, world BSP 10.83%, edge-scan self 8.83%.  Unrolled 16-pixel
span stores remain the default after dword packing (noise) and a stosb loop
(~2.8% slower).  Surface-cache work should stay inline; a combined wrap-guard
plus alias view-matrix hoist won 12.4 ms.  A texture row-lookup experiment
was reverted after its faster run failed the exact framebuffer check
(`2955717646` versus the known-good `4154140932`).

## Reprovisioning

The bootstrapper reuses an existing archive only after verifying its SHA-256.
To replace the user-local installations and cached archives:

~~~powershell
.\tools\bootstrap-dos.ps1 -Force
~~~

-Force affects only the exact installation and download directories under
the selected tool root.

## Scope and limitations

- No Quake data, DOSBox-X binaries, DJGPP binaries, or build output is tracked.
  The ignored `out\` tree is disposable; historical report paths in this file
  document prior evidence but may not exist after cleanup or on a fresh clone.
- The historical q.bat, qa.bat, qb.bat, and qt.bat launchers are kept;
  the new smoke runner supplies a deterministic local staging layout instead.
- A successful host build proves compilation and linking.  The DOSBox-X smoke
  test is required before claiming runtime functionality.
- Timedemo checksum equality covers the recorded framebuffer only; it does not
  establish full visual, audio, gameplay, or physical-486 parity.
