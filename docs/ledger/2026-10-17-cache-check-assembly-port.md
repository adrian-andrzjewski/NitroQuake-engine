# Cache_Check i486 assembly port (2026-10-17)

## Behavior and selector

`src/zone_cacheasm.s` now owns the production `Cache_Check` entry when
`CacheCheckImplementation=asm` is selected in the current i486 profile. The
C-reference profile selects C, and BENCH builds retain `Cache_Check_C` as the
direct oracle. The assembly performs the null miss check, cache-header lookup,
and exact LRU promotion in place; it also maintains the existing PROFILE486
hit, miss, check and relink counters.

`src/asm_cachecheck.h` pins the private cache-header size and LRU link offsets
against `zone.c` at compile time. The cache allocator, eviction policy and hunk
management remain C-owned.

## Direct C/assembly parity

`Bench486CacheCheckCases` constructs isolated three-entry LRU rings, saves and
restores the live cache sentinel and profile counters, and compares C against
assembly for a miss, an already-newest hit, a middle-entry promotion and an
oldest-entry promotion. It checks the returned user pointer, exact list order,
bidirectional link consistency, untouched users and the four PROFILE486
counters. All four cases passed with failure mask `0x0`:

```text
out/dos-bench-20261017-054202/bench-result.json
```

## Strict i486 verification

The strict BENCH build passed the project-object, linked-object, relocated
executable, startup, CRT-helper and maintained CWSDPMI provider gates. It
verified 244,048 project instructions across 152 objects, then 282,345 linked
instructions across 387 objects and 412 executable source-bound contributions.
There were zero above-i486 or unknown instructions, data-site exemptions or
skipped bytes. Startup verification covered 1,660 loaded bytes and 529 CODE
rows; the provider proof covered 9,207 instructions with zero exemptions.
DOSBox-X then passed all four direct Cache_Check parity cases:

```text
out/dos-bench-20261017-054202/bench-result.json
```

The focused run measures correctness, not full-scene FPS or framebuffer parity.

## Ownership and remaining work

The BENCH ownership report records 891 renderer entries, 371 directly
reachable entries, 70 directly reachable C renderer/support entries, and 62
unresolved direct callees. `Cache_Check` is no longer one of those C entries.
At the time of this ownership snapshot, `Cache_Alloc`, `Cache_Free`,
`Cache_TryAlloc`, cache moves and hunk management remained C-owned. The later
[`Cache_Alloc`](2026-10-17-cache-alloc-assembly-port.md),
[`Cache_Free`](2026-10-17-cache-free-assembly-port.md), and
[`Cache_TryAlloc`](2026-10-17-cache-allocation-search-assembly-port.md) ports
close the first three entries. `Cache_Move` is covered by its separate
[`port ledger`](2026-10-17-cache-move-assembly-port.md). `Cache_FreeLow`,
`Cache_FreeHigh`, cache compaction and hunk management remain C-owned. The VGA
linear and planar pixel-copy routines are already
hand-written assembly; higher-level `VID_Update`, mode changes and VESA page
presentation remain C-owned.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Cache_Check` | `src/zone_cacheasm.s:_Cache_Check` | Four exact hit/miss and LRU cases, including counter parity | Strict i486 gates pass; DOSBox-X fixture passes |
