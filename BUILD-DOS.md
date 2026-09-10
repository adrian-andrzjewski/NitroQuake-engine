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

The build uses all 83 C files and 20 preprocessed x86 assembly files in
WinQuake.  net_comx.c is textually included by net_ser.c, so the build
compiles 82 standalone C files and obtains the remaining C implementation
through that include.  Object files and a generated build-manifest.json remain
under out\dos, which is ignored by Git.  The linker output is checked with
the DJGPP objdump and must report coff-go32.

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

### Current baseline

The reported **13 FPS** is reproducible on the pinned profile.  A three-run
`demo1` measurement on 2026-09-09 produced 969 frames per run and a median of
**13.917 FPS** (`13.917069 FPS`, `69.626730` seconds for the median run).
The runs used
`qbench.exe`, the default `baseline` optimization profile, DOSBox-X 2026.08.31,
`cputype=486`, and fixed 33445 cycles.  The result is recorded under
`out\dos-timedemo-*\timedemo-result.json` and is emulator evidence, not a native
Windows performance measurement.

Use the repository runner for repeatable measurements instead of manually
copying executables:

~~~powershell
.\tools\timedemo-dos.ps1 -DataRoot 'C:\path\to\Quake\id1' -Runs 3
~~~

It stages a fresh DOS directory for every run, writes six-decimal timing data,
and reports the median FPS.  Keep the demo name, DOSBox-X version, 486 profile,
fixed cycle count, video mode, optimization profile, and command-line options
unchanged when comparing results.  The current default renderer pass completed
all 969 frames at a 13.995823 FPS median (69.234944 seconds), about 0.57%
above the baseline.  It is a narrow measured improvement and does not support
a claim of a 5% end-to-end gain.

For an odd number of runs, the runner selects the middle sorted sample.  Older
generated JSON records may contain the highest sample in `medianFps`; use the
individual `results` entries when auditing those records.

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

The `bench486` command measures the 486-specific memory, rectangle-fill, and
alias-edge setup paths.  It prints results to the console and writes
`bench486.txt` in the Quake directory.  Compare runs using the same DOSBox-X
version, profile, cycle count, executable mode, and data set.  The benchmark is
diagnostic evidence for these routines; timedemo FPS remains the end-to-end
renderer check.

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
and collect renderer call/cache counters through the timedemo runner:

~~~powershell
.\tools\timedemo-dos.ps1 -Instrumentation `
  -DataRoot 'C:\path\to\Quake\id1' -Runs 1
~~~

Instrumentation changes timing, so its FPS is diagnostic only.  The profile
reports repeated texture-axis transforms avoided by the per-frame cache;
compare release-style `qbench.exe` runs for performance conclusions.  It also
reports coarse phase timings.  A post-validation demo1 diagnostic run
recorded 5,473 alias models, 58,107 surfaces, 46,932 cache hits, 11,175
misses, 9.878070 seconds in alias-model work, 39.383286 seconds in surface
drawing, 1.941758 seconds in turbulent spans, and 135,542 particles in
0.619560 seconds of particle work.  These counters identify
where the 486 renderer spends time; they are not a visual-parity or release
performance claim.

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
