# Cache_TryAlloc allocation search i486 assembly port (2026-10-17)

## Behavior and selector

`CacheTryAllocImplementation=asm` selects the i486 implementation in
`src/memory/zone_cachetryallocasm.s`; the C implementation remains available as
`Cache_TryAlloc_C` in BENCH builds and through the C-reference profile. The
assembly preserves the allocator's address-ordered search, split and
sentinel behavior. `src/memory/asm_cachetryalloc.h` pins the private cache-header
layout against `zone.c` at compile time. `Cache_Alloc`, its LRU eviction loop
and `Cache_Move` are covered by separate
[`Cache_Alloc`](2026-10-17-cache-alloc-assembly-port.md) and
[`Cache_Move`](2026-10-17-cache-move-assembly-port.md) ledgers. Hunk
management remains C-owned.

## Direct C/assembly parity

`Bench486CacheTryAllocCases` compares C and assembly across five allocation
layouts, including the resulting address-list state and allocated block
headers. DOSBox-X reported:

```text
cache tryalloc C/ASM allocation cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-065322/bench-result.json`.

## Strict i486 verification

The focused strict BENCH proof passed the project-object, linked-object,
relocated executable, startup, CRT-helper and maintained CWSDPMI provider
gates. It verified 243,344 project instructions across 154 objects and
281,641 relocated executable instructions. Runtime source proof covered 235
exact installed objects. There were zero above-i486 or unknown instructions,
exemptions, or skipped bytes. The executable proof completed with no
unclassified opcode sites.

The direct fixture checks allocator behavior; it is not a full-scene FPS or
framebuffer-parity measurement.

## Ownership and remaining work

`Cache_TryAlloc` is no longer a C-owned renderer entry in the default i486
profile. `Cache_Alloc`, `Cache_Free` and `Cache_Move` now have separate
assembly entries and direct C/ASM fixture coverage. Hunk management remains
outside these slices.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/memory/zone.c:Cache_TryAlloc_C` | `src/memory/zone_cachetryallocasm.s:Cache_TryAlloc` | Five allocation layouts with exact C/ASM result and list-state comparison | Strict i486 gates pass; DOSBox-X fixture passes |
