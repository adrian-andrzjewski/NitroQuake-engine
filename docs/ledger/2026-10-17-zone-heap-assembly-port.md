# Zone heap i486 assembly port (2026-10-17)

## Behavior and selector

`ZoneHeapImplementation=asm` selects `Z_ClearZone`, `Z_Free`, `Z_TagMalloc`,
and `Z_Malloc` from `src/zone_heapasm.s` in the i486 release profile. BENCH
retains the C bodies as `Z_ClearZone_C`, `Z_Free_C`, `Z_TagMalloc_C`, and
`Z_Malloc_C` for direct comparison; the C-reference profile selects those C
implementations. The i386 profile continues to use C.

`src/asm_zoneheap.h` pins the 32-bit block and zone layout against the C
structures. The assembly initializes the zone sentinel and free block, keeps
the C allocator's eight-byte size alignment and 24-byte header, splits only
when the remainder is greater than 64 bytes, advances the rover consistently,
and frees blocks with the same previous/next coalescing and rover updates.
`Z_Malloc` keeps the C path's profiling, optional paranoid heap check,
tag-1 allocation, allocation-failure report, zero-fill, and return value.
Existing `Sys_Error` paths and PROFILE486 counters are retained.

## Direct C/assembly parity

`Bench486ZoneHeapCases` compares fifteen allocator scenarios. The first ten
cover zone
initialization, alignment edges, the exact 64-byte no-split threshold, a
72-byte split, allocation failure, list scanning and hole reuse, each
coalescing direction, two-sided coalescing, and a rover on an allocated block.
Five more exercise `Z_Malloc` with one and multiple allocations, inspect each
requested payload for zero fill, poison and reuse released payloads, and compare
allocation counters. Every case compares the entire arena, returned offsets,
and allocator counters.

DOSBox-X reported:

```text
zone heap C/ASM cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-142814/bench-result.json`. This is direct
allocator parity evidence; it does not measure FPS or full-scene framebuffer
parity.

## Initial non-BENCH release verification

The original three-entry non-BENCH i486 build and compatibility gate passed.
These recorded totals predate the `Z_Malloc` assembly extension. The source object
audit covered 127,092 instructions across 161 objects. The linked-object audit
covered 165,389 instructions across 396 objects. The executable audit
verified all 165,389 linked opcodes across 235 runtime inputs; there were no
above-i486 instructions, unknown instructions, exemptions, skipped bytes, or
unclassified instruction sites. Final mapping bound 412 source contributions
across 1,470 CODE ranges and 33 DATA ranges. Startup proof covered 1,660 loaded
bytes and 529 CODE rows; the maintained provider proof covered 9,207
instructions.

`tools/test-build-dos.py` completed with its 25 existing unrelated selector
and flag-contract failures; the ZoneHeap selector added no further failure.
The assembler-tool contract check passed.

The build manifest selected `ZoneHeapImplementation=asm`. At that revision,
the map resolved the three public routines to `zone_heapasm.obj`; the C oracle
symbols were absent from the release map.

## Current strict BENCH i486 verification

The expanded `asm-fixture` build passed the strict i486 gates with 245,255
project instructions across 161 objects and 283,552 linked executable
instructions. The relocated executable proof decoded all 283,552 opcodes
across 235 runtime inputs, with zero above-i486 or unknown instructions,
exemptions, or undecoded bytes. Final mapping bound 426 source contributions
across 2,221 CODE ranges and 33 DATA ranges. Startup proof covered 529 CODE
rows; the maintained provider proof covered 9,207 instructions with zero
exemptions. The fixture link map resolves public `Z_Malloc` to
`zone_heapasm.obj` and retains `Z_Malloc_C` as a distinct C reference.

DOSBox-X reported all fifteen zone heap and zero-fill parity cases passed with
failure mask `0x0`. This focused BENCH build does not replace a fresh
non-BENCH release-map check for the new `Z_Malloc` entry.

## Ownership and remaining work

The core zone allocator and the named low/high hunk allocators now use
assembly in the i486 release profile. The cache allocation path is also
assembly-backed: lookup, allocation, free, allocation search, move, and
low/high hunk reclamation each have selectable assembly entries. Remaining C
memory support is mostly cold setup, wrapper, or diagnostic code, including
`Memory_Init`, `Z_CheckHeap`, `Z_Print`, `Hunk_Check`, `Hunk_Print`,
`Cache_Init`, `Cache_Flush`, `Cache_Print`,
`Cache_Report`, and the internal LRU helpers. `Cache_Compact` is an empty stub.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Z_ClearZone_C`, `src/zone.c:Z_Free_C`, `src/zone.c:Z_TagMalloc_C`, `src/zone.c:Z_Malloc_C` | `src/zone_heapasm.s:Z_ClearZone`, `src/zone_heapasm.s:Z_Free`, `src/zone_heapasm.s:Z_TagMalloc`, `src/zone_heapasm.s:Z_Malloc` | Fifteen exact zone setup, allocation, failure, split, scan, coalescing, rover, zero-fill, and reuse cases; complete arena, result offsets, counters, and zero-fill expectations compared | DOSBox-X parity and strict i486 BENCH gate pass; new non-BENCH release map pending |
