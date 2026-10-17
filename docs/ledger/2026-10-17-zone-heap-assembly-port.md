# Zone heap i486 assembly port (2026-10-17)

## Behavior and selector

`ZoneHeapImplementation=asm` selects `Z_ClearZone`, `Z_Free`, and
`Z_TagMalloc` from `src/zone_heapasm.s` in the i486 release profile. BENCH
retains the C bodies as `Z_ClearZone_C`, `Z_Free_C`, and `Z_TagMalloc_C` for
direct comparison; the C-reference profile selects those C implementations.
The i386 profile continues to use C.

`src/asm_zoneheap.h` pins the 32-bit block and zone layout against the C
structures. The assembly initializes the zone sentinel and free block, keeps
the C allocator's eight-byte size alignment and 24-byte header, splits only
when the remainder is greater than 64 bytes, advances the rover consistently,
and frees blocks with the same previous/next coalescing and rover updates.
Existing `Sys_Error` paths and PROFILE486 counters are retained.

## Direct C/assembly parity

`Bench486ZoneHeapCases` compares ten allocator scenarios. They cover zone
initialization, alignment edges, the exact 64-byte no-split threshold, a
72-byte split, allocation failure, list scanning and hole reuse, each
coalescing direction, two-sided coalescing, and a rover on an allocated block.
Each case compares the entire arena, returned offsets, and allocator counters.

DOSBox-X reported:

```text
zone heap C/ASM cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-142814/bench-result.json`. This is direct
allocator parity evidence; it does not measure FPS or full-scene framebuffer
parity.

## Strict i486 release verification

The full non-BENCH i486 build and compatibility gate passed. The source object
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

The build manifest selects `ZoneHeapImplementation=asm`. The map resolves all
three public routines to `zone_heapasm.obj`; the C oracle symbols are absent
from the release map.

## Ownership and remaining work

The core zone allocator and the named low/high hunk allocators now use
assembly in the i486 release profile. The cache allocation path is also
assembly-backed: lookup, allocation, free, allocation search, move, and
low/high hunk reclamation each have selectable assembly entries. Remaining C
memory support is mostly cold setup, wrapper, or diagnostic code, including
`Memory_Init`, `Z_Malloc`, `Z_CheckHeap`, `Z_Print`, `Hunk_HighMark`,
`Hunk_Check`, `Hunk_Print`, `Cache_Init`, `Cache_Flush`, `Cache_Print`,
`Cache_Report`, and the internal LRU helpers. `Cache_Compact` is an empty stub.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Z_ClearZone_C`, `src/zone.c:Z_Free_C`, `src/zone.c:Z_TagMalloc_C` | `src/zone_heapasm.s:Z_ClearZone`, `src/zone_heapasm.s:Z_Free`, `src/zone_heapasm.s:Z_TagMalloc` | Ten exact zone setup, allocation, failure, split, scan, coalescing, and rover cases; complete arena, result offsets, and counters compared | DOSBox-X parity passes; strict i486 release gate passes |
