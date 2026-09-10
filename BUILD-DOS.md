# Building the MS-DOS WinQuake software renderer on Windows

This checkout builds the retained WinQuake MS-DOS/software-renderer source
directly from Windows 10.  The compiler is a Windows-hosted DJGPP cross
toolchain; DOSBox-X is used only to run the resulting DOS executable.

The bootstrapper installs both tools in:

~~~text
%LOCALAPPDATA%\486quake\tools
~~~

It does not modify the system PATH or install anything globally.  Archive
URLs and SHA-256 values are pinned in tools/dos-toolchain.json.

## Build

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
files in WinQuake, including the selected texture-animation and lightmap
normalization experiments.  net_comx.c is
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

`c` is the default and writes to `out\dos`; `asm` writes to
`out\dos-memasm`.  The ASM build includes `asm486_experiments.s` and defines
`ASM486_RUNTIME_MEMOPS`; all other compiler flags and source inputs remain the
same.  The switch is deliberately opt-in while the end-to-end gain is being
evaluated.

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
directory, or -SkipBuild when the executable is already available.

## 486-class timedemo

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

### Reference baseline

The earlier reported **14 FPS** (rounded) is reproducible on the pinned
profile.  A three-run raw `demo1` reference measurement on 2026-09-09
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
and reports the median FPS.  Keep the demo name, DOSBox-X version, 486 profile,
fixed cycle count, video mode, optimization profile, and command-line options
unchanged when comparing results.  By default it adds `-fpsstats`, preserving
the original average-FPS line while also measuring every timedemo frame.
Use `-NoFpsStats` for a raw comparison when measuring the cost of collecting
the extra statistics.  The raw result is the authority for small engine-speed
comparisons; the rich result is the authority for frame-time consistency.

For an odd number of runs, the runner selects the middle sorted sample.  Older
generated JSON records may contain the highest sample in `medianFps`; use the
individual `results` entries when auditing those records.

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
builds through the explicit `-MemoryImplementation asm` switch; the default
normal build continues to use the original C helpers.

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
  -DataRoot 'C:\path\to\Quake\id1'
.\tools\bench-dos.ps1 -TextureAxisImplementation c `
  -SurfaceCacheImplementation c `
  -MipLevelImplementation c `
  -TurbulentImplementation asm `
  -DataRoot 'C:\path\to\Quake\id1'
~~~

Individual C/ASM implementation switches can be omitted; the existing probes
default to `c`; the turbulent selector defaults to the measured `stosb` path,
and the alias projection, texture-animation, and lightmap-normalization
selectors default to their measured `asm` paths; the BSP plane-dot and BSP
clip selectors default to their C paths.  Pass
`-TurbulentImplementation asm` for the existing ASM control.  The runner
records all ten selections in `bench-result.json` and uses a matching output
directory suffix.  Use `-TurbulentOnly`, `-AliasProjectOnly`,
`-TextureAnimationOnly`, `-LightMapNormalizeOnly`, `-BspPlaneDotOnly`, or
`-BspClipOnly` to run only the corresponding focused experiment instead of the
longer general matrix.

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

### Optimization profiles and instrumentation

The default build is the fidelity-preserving `baseline` profile (`-O2`,
`-march=i486`, and no newer instruction-set requirement).  An isolated `-O3`
variant is available for comparison and is written beside the default build:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -OptimizationProfile aggressive
.\tools\timedemo-dos.ps1 -OptimizationProfile aggressive `
  -DataRoot 'C:\path\to\Quake\id1' -Runs 3
~~~

On the same pinned `demo1` measurement, this profile reached a **14.122 FPS**
median (14.121687 FPS; `68.617862` seconds for the median run) versus
**13.917 FPS** for `baseline` (13.917069 FPS),
about 1.5% faster.  It remains
an opt-in comparison build; no visual-quality switch or newer CPU instruction
set is enabled.

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

A matched 2026-09-10 diagnostic comparison measured the instrumented profile
at `77.017236` seconds and the raw release timedemo at `69.162451` seconds, an
estimated **11.36% profiling overhead**.  The profile run also used 520,782
profile timer reads plus 1,939 frame-statistics timer reads, reached stack
depth 8, and reported zero stack errors; two open scopes were intentionally
discarded when timedemo exit occurred inside the final demo message.  This
overhead is acceptable for diagnosis but the instrumented FPS must not be used
as an optimization result.

The current self-time ranking from that profile is:

| Rank | Node | Self seconds | % of profiled frame | Work |
| ---: | --- | ---: | ---: | --- |
| 1 | Texture spans | 19.708498 | 25.60% | 1,454,414 spans / 43,956,202 pixels |
| 2 | Surface cache | 11.194143 | 14.54% | 55,300 normal surfaces |
| 3 | Alias model | 9.965974 | 12.95% | 5,470 models / 417,090 vertices |
| 4 | Z spans | 8.346734 | 10.84% | 58,051 surface calls |
| 5 | World BSP | 8.312930 | 10.80% | 375,709 BSP node visits |
| 6 | Edge scan self | 6.780973 | 8.81% | 147,288 scanlines |

These are measured diagnostic hotspots, not optimization instructions.  The
next investigation should compare the texture-span, surface-cache, and alias
model leaves separately, using the same timedemo and visual checks after each
change.  A texture row-lookup experiment was reverted after its faster run
failed the exact framebuffer check (`2955717646` versus the known-good
`4154140932`).  The accepted texture-span change is limited to equivalent
address-arithmetic forms and passed the same exact checksum check.

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
- The historical q.bat, qa.bat, qb.bat, and qt.bat launchers are kept;
  the new smoke runner supplies a deterministic local staging layout instead.
- A successful host build proves compilation and linking.  The DOSBox-X smoke
  test is required before claiming runtime functionality.
