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
failure mask `0x0`. The subsequent non-BENCH release gate and link map are
recorded below.

## Current non-BENCH i486 release verification

The default non-BENCH release build passed with `CpuTarget=i486`,
`profileBuild=false`, and `ZoneHeapImplementation=asm`. The project-object
audit covered 127,065 instructions across 161 objects; the linked-object
audit covered 165,362 instructions across 396 objects. The relocated
executable proof verified all 165,362 opcodes across 235 runtime inputs,
with zero unknown, above-i486, exempted, skipped, or relocation bytes. Final
mapping bound 412 source contributions across 1,470 CODE ranges and 33 DATA
ranges. Startup proof covered 1,660 loaded bytes and 529 CODE rows; provider
proof covered 9,207 instructions with zero exemptions.

The release link map resolves public `Z_Malloc` to `zone_heapasm.obj` at
`0x00075224`; `Z_Malloc_C` is absent. Evidence is under
`out/profile-fefff301cb4a2276/`. This verifies the non-BENCH assembly default
and i486 encoding; it is not full-scene framebuffer parity or an FPS result.

## Ownership and remaining work

The core zone allocator and the named low/high hunk allocators now use
assembly in the i486 release profile. The cache allocation path is also
assembly-backed: lookup, allocation, free, allocation search, move, flush, and
low/high hunk reclamation each have selectable assembly entries. `Cache_Init`
and `Memory_Init` now use the i486 zone-heap selector; C references remain for
parity. `Z_CheckHeap`, `Hunk_Check`, and the internal cache LRU helpers also
use the zone-heap assembly selector. `Z_Print` now has an assembly list walk
and structural-check path, while its shared `Zone_PrintTrace` C adapter keeps
the existing console formatting. `Hunk_Print`, `Cache_Print`, and
`Cache_Report` remain C-owned diagnostics. `Cache_Compact` is an empty stub.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Z_ClearZone_C`, `src/zone.c:Z_Free_C`, `src/zone.c:Z_TagMalloc_C`, `src/zone.c:Z_Malloc_C` | `src/zone_heapasm.s:Z_ClearZone`, `src/zone_heapasm.s:Z_Free`, `src/zone_heapasm.s:Z_TagMalloc`, `src/zone_heapasm.s:Z_Malloc` | Fifteen exact zone setup, allocation, failure, split, scan, coalescing, rover, zero-fill, and reuse cases; complete arena, result offsets, counters, and zero-fill expectations compared | DOSBox-X parity passes; strict BENCH and non-BENCH i486 release gates pass |
| `src/zone.c:Cache_Init_C`, `src/zone.c:Memory_Init_C` | `src/zone_heapasm.s:Cache_Init`, `src/zone_heapasm.s:Memory_Init` | Sentinel/LRU initialization and flush-command registration; default zone size and `-zone 32` startup with complete arena and hunk/cache state comparison | DOSBox-X fixture PASS (`0x0`); strict BENCH and non-BENCH i486 gates pass with zero above-target or unknown instructions |
| `src/zone.c:Z_Print_C` | `src/zone_heapasm.s:Z_Print` | Six cases compare event sequence, zone/block pointers, sizes and tags, including bad boundary, bad backlink and adjacent-free reports | DOSBox-X fixture PASS (`0x0`); strict BENCH and non-BENCH i486 gates pass; release map resolves `Z_Print` to `zone_heapasm.obj` and omits `Z_Print_C` |

### Cache and memory initialization follow-up (2026-10-17)

The focused BENCH run used `-ZoneHeapImplementation asm-fixture`,
`-MemoryImplementation asm`, and `-VideoUpdateImplementation c`. DOSBox-X
reported `zone heap C/ASM cases PASS failure mask 0x0` and
`486 benchmark correctness PASS`. In addition to the fifteen existing zone
allocator cases, the fixture compares cache sentinel setup, the registered
`flush` callback, default memory initialization, and the `-zone 32` override.
The run is recorded at `out/dos-bench-20261017-170056/`.

The strict BENCH build mapped 426 executable code contributions and audited
284,123 linked instructions; the non-BENCH release build mapped 412 code
contributions and audited 165,347 instructions. Both passed the i486 gate with
zero above-target, unknown, exempt, or skipped instructions. The production
release command explicitly selected `ZoneHeapImplementation=asm`; its build
root is `out/profile-fefff301cb4a2276/`.

### Zone listing diagnostic follow-up (2026-10-17)

`ZoneHeapImplementation=asm` now selects the `Z_Print` traversal from
`zone_heapasm.s`. BENCH retains `Z_Print_C`; the C-reference profile keeps the
C implementation. The C `Zone_PrintTrace` adapter preserves the original
`Con_Printf` formats. The six-case fixture captures and compares the sequence
and exact values passed to that adapter for a valid free zone, allocated and
freed blocks, and each of the three structural warnings. DOSBox-X reported
`zone heap C/ASM cases PASS failure mask 0x0` and
`486 benchmark correctness PASS` in
`out/dos-bench-20261017-195649/bench-result.json`.

The strict BENCH gate audited 247,319 project instructions across 162 objects
and 285,616 linked instructions across 397 objects. The executable proof
verified all 285,616 opcodes across 235 runtime inputs; final mapping bound
428 source contributions across 2,227 CODE ranges and 34 DATA ranges. Startup
proof covered 1,660 loaded bytes and 529 CODE rows; provider proof covered
9,207 instructions. There were zero above-i486 or unknown instructions,
exemptions, skipped bytes, or unclassified sites.

The non-BENCH release gate audited 125,390 project instructions and 163,687
linked instructions across the same 162/397 objects. It verified all 163,687
opcodes across 235 runtime inputs and mapped 414 source contributions across
1,464 CODE ranges and 34 DATA ranges. Startup and provider proofs covered
1,660 bytes / 529 CODE rows and 9,207 instructions, with zero exemptions.
The release manifest records `ZoneHeapImplementation=asm`; the link map places
`Z_Print` at `0x00073bfc` in `zone_heapasm.obj`, with no `Z_Print_C` symbol.
Build evidence is under `out/profile-8bfc40771f2b70a4/`. This diagnostic
fixture proves output-call parity, not FPS or full-scene framebuffer parity.
