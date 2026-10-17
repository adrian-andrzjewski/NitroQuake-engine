# Hunk named low/high allocation i486 assembly port (2026-10-17)

## Behavior and selector

`HunkNamedAllocImplementation=asm` selects `Hunk_AllocName` and
`Hunk_HighAllocName` from `src/zone_hunknamedallocasm.s` in the current i486
release profile. BENCH builds retain `Hunk_AllocName_C` and
`Hunk_HighAllocName_C` as parity references; the C-reference profile selects
those entries. The i386 profile keeps the C implementations.

Both entries reject negative sizes through `Sys_Error`, align payload sizes to
16 bytes, reserve and clear the hunk header plus payload, and copy the
truncated eight-byte name. The low allocator advances the low mark and calls
`Cache_FreeLow`. The high allocator first releases any active temporary hunk,
then advances the high mark and calls `Cache_FreeHigh`; on insufficient space
it prints the existing diagnostic and returns null. The assembly preserves
`HUNK_TRACE` phases 72 through 81 in BENCH trace builds, as well as profiling
counters and the C ABI.

## Direct C/assembly parity

`Bench486HunkNamedAllocCases` compares six low and six high allocations using
payload sizes 0, 1, 15, 16, 17, and 33 bytes. The cases exercise alignment
edges, name truncation, active temporary-mark cleanup, and existing low/high
usage. Each pair compares the full 1024-byte arena, cache sentinel, marks,
temporary state, result offset, and profiling counters, then restores the live
state.

DOSBox-X reported:

```text
hunk low/high named-allocation C/ASM cases PASS failure mask 0x0
486 benchmark correctness PASS
```

The latest trace-enabled BENCH rebuild used the diagnostic ISA-skip mode for
the fixture. Its updated named-allocation assembly object passed a targeted
i486 audit: 189 instructions, all classified i386. The earlier full strict
BENCH linked gate for this allocator slice passed 282,740 relocated
instructions, 529 startup CODE rows, and 9,207 provider instructions with zero
exemptions. That full BENCH gate preceded the trace-only callback preservation;
the callback-enabled object was separately audited after that change.

## Strict i486 release verification

The current non-BENCH i486 release gate passed. It audited 127,127 project
instructions across 160 objects and 165,424 linked instructions across 395
objects. The linked proof matched all 165,424 opcodes across 235 runtime
inputs, with zero above-i486 or unknown instructions, exemptions, skipped
bytes, or misclassified data sites. Final mapping bound 410 source
contributions across 1,470 CODE ranges and 32 DATA ranges. Startup proof
covered 1,660 loaded bytes and 529 CODE rows; the maintained provider proof
covered 9,207 instructions.

The release manifest selects `HunkNamedAllocImplementation=asm`. The map
resolves `Hunk_AllocName` and `Hunk_HighAllocName` to
`zone_hunknamedallocasm.obj` and omits both C oracle symbols. This routine
fixture and the strict ISA gates do not measure frame rate or establish
full-scene framebuffer parity.

## Ownership and remaining work

The named low/high hunk allocators now use assembly in the i486 release
profile. Hunk diagnostics and the zone heap routines remain C-owned, including
`Hunk_HighMark`, `Hunk_Check`, `Hunk_Print`, `Z_ClearZone`, `Z_Free`,
`Z_FreeTags`, `Z_Malloc`, `Z_TagMalloc`, `Z_CheckHeap`, and `Z_Print`.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Hunk_AllocName_C`, `src/zone.c:Hunk_HighAllocName_C` | `src/zone_hunknamedallocasm.s:Hunk_AllocName`, `src/zone_hunknamedallocasm.s:Hunk_HighAllocName` | Twelve exact cases across both allocators; complete arena, cache sentinel, marks, temp state, result offsets, and profiling state compared | DOSBox-X fixture passes; latest trace-enabled assembly object audit and strict i486 release gate pass |
