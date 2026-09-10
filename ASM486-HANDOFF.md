# 486 ASM experiment handoff

This checkout is a DOS WinQuake/software-renderer preservation project.  The
purpose of the ASM work is experimental: compare small hand-written 486 paths
with the original C under the same DJGPP build and DOSBox-X workload, then
promote only changes that preserve the exact framebuffer and win the complete
timedemo.  This is a continuation note for the next agent; operational build
and run details remain in `BUILD-DOS.md`.

## Current state

The nested repository is the Git boundary: `D:\Project\486quake\quake`.
The current source uses the `baseline` profile (`-O2 -march=i486`) and the
repository-owned `tools\dosbox-x-486-high.conf` profile (`cputype=486`, fixed
33445 cycles, DOSBox-X 2026.08.31, 16 MB).  The current default selections are:

- ASM: alias projection, alias bounding-box projection, clipped alias
  transform/lighting, texture-animation selection, and lightmap normalization.
- `stosb`: turbulent-span stores.
- C: memory helpers, texture-axis cache predicate, surface-cache predicate,
  mip-level selection, BSP plane-dot, and BSP frustum clipping.

Every ASM candidate retains its C implementation.  `build-dos.ps1`,
`bench-dos.ps1`, and `timedemo-dos.ps1` expose independent `c|asm` selectors
and write separate ignored output directories when needed.  `out\` contains
generated executables, staged data, logs, JSON reports, and object files; it is
not source and must not be committed.

## Completed experiments and decisions

All focused runs used alternating C/ASM samples and ended with
`486 benchmark correctness PASS`; accepted paths also passed matched `demo1`
timedemos with 969 frames and framebuffer checksum `4154140932` on every run.
The percentages below are DOSBox-X evidence, not a claim about all physical
486 variants.

| Experiment | Focused result | Timedemo result | Decision |
| --- | --- | --- | --- |
| Texture-span setup (`d_draw16.s`) | Narrow address-arithmetic change | About 0.10% faster | Kept |
| Turbulent stores | Existing ASM 20.6--28.8% faster than C; `stosb` tied it in isolation | `stosb` 0.086207% faster than existing ASM | `stosb` default |
| Alias projection (`R_AliasProjectFinalVert`) | 7.316--7.317% faster | 0.017696% faster | ASM default |
| Texture animation (`R_TextureAnimationFrame`) | 1.052--31.999% faster | 0.009406% faster | ASM default |
| Lightmap normalization (`R_BuildLightMap`) | 9.447--9.969% faster | 0.0275% faster | ASM default |
| Alias bbox projection (`R_AliasCheckBBox`) | 16.667--20.120% faster | 0.0264% faster | ASM default |
| Clipped alias transform (`R_AliasTransformFinalVert`) | 20.000--25.218% faster | 0.150883% faster | ASM default |
| Memory helpers (`Q_memset`/`Q_memcpy`) | About 4.6--64.4% faster by case | 0.0208% faster | C default; ASM opt-in |
| Texture-axis predicate (`D_GetTextureAxes`) | 0.000% to -0.002% | Not promoted | C default |
| Surface-cache predicate (`D_CacheSurface`) | 3.846--5.000% faster | 0.030% slower | C default |
| Mip selector (`D_MipLevelForScale`) | Mixed: -8.697% to +7.143% | 0.0092% slower | C default |
| BSP plane dot (`R_RecursiveWorldNode`) | Mixed: -13.334% to +21.052% | 0.0367% slower | C default |
| BSP clipping (`R_RecursiveWorldNode`) | Mixed: -4.651% to +55.931% | 0.2749% slower | C default |

The last accepted clipped-transform comparison used three runs per variant:

```text
C:   69.063022 / 69.062948 / 69.062989 s, median 69.062989 s, 14.030670 FPS
ASM: 68.958781 / 68.958804 / 68.958785 s, median 68.958785 s, 14.051872 FPS
```

The gain is 104.204 ms per timedemo.  Disassembly showed the useful 486-level
difference: the C helper reloads packed vertex bytes through compiler-generated
temporaries for each dot product, while ASM expands them once into scratch
storage and reuses them with x87 arithmetic.  The call boundary is shared.
The helper is intentionally small; it does not rewrite the larger alias path.

## Current baseline and evidence

- Historical pre-experiment reference: 69.234885 s / 13.995834 FPS median.
- Current committed default: 68.958785 s / 14.051872 FPS median over three
  runs; 969 frames and checksum `4154140932` each run.
- Final validation rerun: `69.566415 / 68.958835 / 68.958777` s, median
  68.958835 s / 14.051862 FPS, with the same 969-frame checksum on every run.
- A one-run current default confirmation measured 68.958772 s / 14.051875
  FPS.
- The diagnostic profile ranked self time as texture spans 25.60%, surface
  cache 14.54%, alias model 12.95%, Z spans 10.84%, world BSP 10.80%, and
  edge-scan self 8.81%.
- The profile took 77.017236 s versus a 69.162451 s raw release run, about
  11.36% overhead.  It is useful for hotspot direction only, not speed claims.

## Important decisions and assumptions

- Original C bodies stay intact as references; do not delete them to make ASM
  the only implementation.
- A focused microbenchmark win is not sufficient.  Require correctness,
  matched release timedemos, and a measured end-to-end gain before changing a
  default.
- Keep `-O2 -march=i486`, the same DOSBox-X version/profile/cycles, demo, data,
  and command-line options for A/B comparisons.  Do not enable newer ISA
  requirements.
- Exact framebuffer checksum is the automated parity gate.  It does not prove
  complete visual or gameplay parity outside the timedemo.
- `R_AliasTransformFinalVert_asm486` uses static scratch labels in
  `asm486_experiments.s`; this is acceptable for the current single-threaded
  DOS renderer, but the helper is not reentrant.
- DOSBox-X timing is an emulated 486-class model.  No physical 486 measurement
  has been made, and only `demo1` has been used for the documented matched
  end-to-end comparisons.

## Failed or inconclusive work

- A texture row-lookup experiment was reverted after a faster run produced
  checksum `2955717646` instead of `4154140932`.
- The isolated surface-cache, mip, BSP-dot, and BSP-clip wins did not survive
  the real call boundary and workload; their C paths remain defaults.
- The broad mixed benchmark matrix in
  `out\dos-bench-20260910-204331` exceeded its 300-second diagnostic bound
  before producing a result JSON.  It is not a passing benchmark and should
  not be used as evidence.
- The earlier aggressive `-O3` comparison reached about 14.122 FPS versus an
  older 13.917 FPS baseline, but it predates the latest default ASM selections;
  rerun it before treating it as a current compiler-profile result.

## Priority-ordered next steps

1. Reproduce the current baseline from a clean generated tree: build the
   default benchmark and normal executable, run the focused alias-transform
   correctness benchmark, run the DOS smoke test, then run a three-run
   `demo1` timedemo.  Record the new JSON paths before any code change.
2. Profile the current default once for hotspot confirmation, then focus on the
   texture-span leaf.  Start with the existing 16-pixel drawers in
   `WinQuake\d_draw16.s` and related span setup in `WinQuake\d_draw.s`; measure
   sequential loads, address increments, loop overhead, and unrolling at 1x,
   2x, and 4x.  Preserve the exact checksum gate.
3. Investigate surface-cache cost as an inline/data-locality problem, not as
   another standalone helper call.  Begin at `D_CacheSurface` in
   `WinQuake\d_surf.c` and `R_DrawSurface` in `WinQuake\r_surf.c`; the prior
   helper was slower end-to-end despite a 3.8--5.0% isolated win.
4. Audit remaining alias-model self time around `R_AliasPreparePoints`,
   `R_AliasSetupLighting`, and alias edge/span setup after avoiding the already
   accepted projection and clipped-transform helpers.
5. For every candidate, keep C and ASM selectable, add a focused case that
   exercises the real branch/data distributions, inspect DJGPP object
   disassembly, and run matched three-run release timedemos.  Do not promote
   based on a microbenchmark alone.

## Starting commands

Use a local, legally obtained `id1` directory containing `pak0.pak`:

```powershell
.\tools\build-dos.ps1 -Clean -Benchmark -NoBootstrap
.\tools\bench-dos.ps1 -SkipBuild -AliasTransformFinalOnly `
  -DataRoot 'C:\path\to\Quake\id1'
.\tools\smoke-dos.ps1 -SkipBuild -DataRoot 'C:\path\to\Quake\id1' `
  -TimeoutSeconds 90
.\tools\timedemo-dos.ps1 -DataRoot 'C:\path\to\Quake\id1' -Runs 3
```

For the direct C/ASM transform A/B, build each selected benchmark executable
and run the focused command with the matching selector:

```powershell
.\tools\build-dos.ps1 -Clean -Benchmark `
  -AliasTransformFinalImplementation c -NoBootstrap
.\tools\bench-dos.ps1 -SkipBuild -AliasTransformFinalOnly `
  -AliasTransformFinalImplementation c `
  -DataRoot 'C:\path\to\Quake\id1'
.\tools\build-dos.ps1 -Clean -Benchmark `
  -AliasTransformFinalImplementation asm -NoBootstrap
.\tools\bench-dos.ps1 -SkipBuild -AliasTransformFinalOnly `
  -AliasTransformFinalImplementation asm `
  -DataRoot 'C:\path\to\Quake\id1'
```

The relevant source entry points are
`R_AliasTransformFinalVert` and
`R_AliasTransformFinalVert_asm486` in `WinQuake\r_alias.c` and
`WinQuake\asm486_experiments.s`.  Use `WinQuake\host_cmd.c` for the focused
benchmark harness and `tools\profile-report.ps1` for profile JSON.
