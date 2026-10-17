# Cache_Alloc i486 assembly port (2026-10-17)

## Behavior and selector

`CacheAllocImplementation=asm` selects `Cache_Alloc` in
`src/zone_cachetryallocasm.s`; BENCH builds retain the C body as
`Cache_Alloc_C`, and the C-reference profile selects C. The assembly rounds
the requested payload with the 40-byte cache header to a 16-byte allocation,
tries the selected `Cache_TryAlloc`, and when needed frees the least-recently
used block through the selected `Cache_Free` before retrying. On success it
copies the cache name, sets the user and block pointers, and returns the data
pointer. `src/asm_cachealloc.h` pins the private structure layout and name
size against `zone.c` at compile time.

Cache moves, hunk management and other memory ownership paths remain
C-owned.

## Direct C/assembly parity

`Bench486CacheAllocCases` compares C and assembly over an empty cache and a
fragmented cache that forces eviction of the LRU block located between two
address-ordered blocks. It compares the sentinel, full arena and user records,
address and LRU order, name bytes, allocation size, result pointer, and cache
allocation/eviction/free counters. DOSBox-X reported:

```text
cache alloc C/ASM empty/eviction cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-074619/bench-result.json`.

## Strict i486 verification

The focused strict BENCH proof passed project-object, linked-object,
relocated executable, startup, CRT-helper and maintained CWSDPMI provider
gates. It audited 243,603 project instructions across 154 objects and
281,900 linked instructions across 389 objects. Executable proof verified
all 281,900 opcodes across 235 runtime inputs and 415 source-bound
contributions. The final mapping covered 2,200 CODE ranges and 29 DATA
ranges; startup proof covered 1,660 loaded bytes and 529 CODE rows, and the
provider proof covered 9,207 instructions. There were zero above-i486 or
unknown instructions, exemptions, or skipped bytes.

The broader `tools/test-build-dos.py` contract run still reports 25
unrelated existing build-flag, alias, sky, dynamic-light and particle
selector failures. The focused Cache_Alloc build, selector profile check,
strict i486 gates and DOSBox-X parity fixture passed. This fixture is a cache
correctness test, not full-scene FPS or framebuffer-parity evidence.

## Ownership and remaining work

`Cache_Alloc` is no longer a C-owned renderer entry in the default i486
profile. `Cache_Move`, hunk allocation and other cache/memory routines remain
C-owned. The current BENCH ownership report is
`out/local-cachealloc/renderer-ownership-qbench.json`.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Cache_Alloc_C` | `src/zone_cachetryallocasm.s:Cache_Alloc` | Empty-cache allocation and forced LRU eviction, with full state comparison | Strict i486 gates pass; DOSBox-X fixture passes |
