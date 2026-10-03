# How the timedemo baseline was arrived at

Moved verbatim out of `BUILD-DOS.md`, section `## 486-class timedemo`, which
mixed result write-ups into the operational build reference. Each section is
now top-level here, so its heading lost one `#`; the prose is unchanged.
Ledger index: [`../INDEX.md`](../INDEX.md).

## Lightmap style accumulation

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

## VGA full-frame copy experiment

The guarded VGA_SwapBuffersCopy full-frame shortcut was tested in standard VGA
mode using -stdvid. Direct VGA, planar, partial, chained, padded, and sentinel
tests passed, and all forced-VGA runs retained 969 frames/checksum 1047377823.
The candidate was rejected because its median was 16.302751 FPS versus 16.303103
FPS for the matched no-shortcut control. The shortcut was reverted; the direct
VGA coverage remains in tools/test-video-dos.py.

## Surface-cache capacity and churn

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

## Surface-cache header locality experiment

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

## Lazy viewspantable rebuild

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

## Measured texture-span change

After the profiling pass identified texture spans as the largest self-time
consumer, the 16-pixel drawer received two narrow 486-targeted changes in
`src\d_draw16.s`: the initial row address uses a memory-source multiply,
and the common zero-row-step setup adds `cachewidth` directly from memory.
Both preserve the original fixed-point arithmetic and leave the inner sampling
loop unchanged.

A matched three-run raw `demo1` comparison on 2026-09-10 measured a median of
**14.010492 FPS** (`69.162451` seconds) after the change, versus the documented
pre-change median of **13.995834 FPS** (`69.234885` seconds), or approximately
**0.10% faster**.  All runs produced the same final framebuffer checksum,
`4154140932`.  This is DOSBox-X 486 evidence; it is not a claim about every
physical 486 or a native Windows build.

