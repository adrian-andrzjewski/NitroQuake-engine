# Cache_Free i486 assembly port (2026-10-17)

## Behavior and selector

`CacheFreeImplementation=asm` selects `Cache_Free` in
`src/zone_cachetryallocasm.s`; the C implementation remains available as
`Cache_Free_C` in BENCH builds and through the C-reference profile. The entry
checks the user handle, unlinks the block from the address-ordered list,
clears the user handle, validates and unlinks the LRU links, and preserves
the C error strings and PROFILE486 free counter. `src/asm_cachefree.h` pins
the cache-header size and field offsets against `zone.c` at compile time.

`Cache_Alloc` and `Cache_Move` now have separate assembly entries and parity
fixtures. Hunk management remains C-owned. The adjacent
[`Cache_TryAlloc` port ledger](2026-10-17-cache-allocation-search-assembly-port.md)
covers the allocation-search entry.

## Direct C/assembly parity

`Bench486CacheFreeCases` compares C and assembly when removing the first,
middle and last blocks from the address-ordered list. The LRU order is
independent of address order. The fixture compares the full sentinel, arena
and user records, list traversal order, cleared node links and free counter.
DOSBox-X reported:

```text
cache free C/ASM address/LRU cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-071949/bench-result.json`.

## Strict i486 verification

The focused strict BENCH proof passed project-object, linked-object,
relocated executable, startup, CRT-helper and maintained CWSDPMI provider
gates. It audited 243,456 project instructions across 154 objects and
281,753 linked instructions across 389 objects. Executable proof verified
all 281,753 linked opcodes across 235 runtime inputs and 415 source-bound
contributions. The final mapping covered 2,194 CODE ranges and 29 DATA
ranges; startup proof covered 1,660 loaded bytes and 529 CODE rows, and the
provider proof covered 9,207 instructions. There were zero above-i486 or
unknown instructions, exemptions, or skipped bytes.

This focused fixture validates cache state and instruction compatibility; it
does not measure full-scene FPS or framebuffer parity.

## Ownership and remaining work

`Cache_Free` is no longer a C-owned renderer entry in the default i486
profile. `Cache_Alloc`, `Cache_TryAlloc` and `Cache_Move` are covered by their
own assembly ports; hunk management remains C-owned. The BENCH inventory
for this slice is recorded at
`out/local-cachefree/renderer-ownership-qbench.json`.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Cache_Free_C` | `src/zone_cachetryallocasm.s:Cache_Free` | Three address positions with independent LRU order and full state/counter comparison | Strict i486 gates pass; DOSBox-X fixture passes |
