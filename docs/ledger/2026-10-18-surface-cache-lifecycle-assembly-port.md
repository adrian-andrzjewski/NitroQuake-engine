# Surface-cache sizing and lifecycle i486 assembly port (2026-10-18)

## Behavior and selector

`SurfaceCacheImplementation=asm` now selects assembly entries for
`D_SurfaceCacheForRes`, `D_InitCaches`, and `D_FlushCaches` in the focused
cache-only drawing profile. `D_SurfaceCacheForRes` owns the default sizing and
resolution-scaling arithmetic while using the shared `COM_CheckParm` and
`Q_atoi` helpers for `-surfcachesize`. `D_InitCaches` owns the cache size,
base/rover pointers, sentinel, and four guard bytes; it uses `Con_Printf` only
for the existing status message. `D_FlushCaches` clears owner handles and
reinitializes the rover sentinel. The full drawing-driver assembly profile
continues to use its existing `D_FlushCaches` entry.

The C implementations remain available as `D_SurfaceCacheForRes_C`,
`D_InitCaches_C`, and `D_FlushCaches_C` in BENCH builds, and as the public C
entries in the C-reference profile.

## Direct C/assembly parity

`-benchsurfacecache` compares six default size cases and the 128 KiB override,
then checks complete cache-buffer contents, sentinel state, guard bytes and
canaries after initialization. Flush parity checks a three-node owner walk,
the reset sentinel and rover, preserved size, and the null-base no-op. DOSBox-X
reported:

```text
surface-cache sizing parity PASS (6 resolutions and override)
surface-cache init parity PASS (state, guard, canaries)
surface-cache flush parity PASS (owner walk, sentinel, null base)
486 benchmark correctness PASS
```

Run record: `out/dos-bench-20261018-044543/bench-result.json`. Its manifest
selects `SurfaceCacheImplementation=asm` and `MemoryImplementation=asm`.

## Strict i486 verification

The focused BENCH build passed project-object, linked-object, relocated
executable, startup, CRT-helper, and maintained CWSDPMI provider gates. The
project audit covered 244,522 instructions; the linked executable audit
verified all 282,819 instructions in 430 source-bound code contributions, with
2,249 CODE ranges and 34 DATA ranges. Startup validation covered 529 CODE rows
and the provider proof covered 9,207 instructions. There were zero
above-i486, unknown, exempt, or skipped instructions.

## Scope limits and reproduction

The measured hit and miss fast paths were 10.714% to 12.000% faster than their
C references in this DOSBox-X run. Those existing fast-path microbenchmarks do
not measure the newly ported sizing or lifecycle entries. This fixture makes
no full-scene FPS or complete-renderer parity claim.

Reproduce with:

```powershell
rtk proxy pwsh -NoProfile -ExecutionPolicy Bypass -File tools/bench-dos.ps1 -CpuTarget i486 -SurfaceCacheImplementation asm -DrawingDriverImplementation c -SurfaceCacheOnly
```
