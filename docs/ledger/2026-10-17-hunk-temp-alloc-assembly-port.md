# Hunk_TempAlloc i486 assembly port (2026-10-17)

## Behavior and selector

`HunkTempAllocImplementation=asm` selects `Hunk_TempAlloc` from
`src/zone_hunktempallocasm.s` in the current i486 profile. BENCH builds retain
`Hunk_TempAlloc_C` for parity; the C-reference profile selects the C entry.

The assembly wrapper rounds the requested size to a 16-byte boundary, releases
an existing temporary high-hunk allocation through `Hunk_FreeToHighMark`,
records the new high mark, and delegates allocation to
`Hunk_HighAllocName(size, "temp")`. It then marks the temporary allocation
active and returns the allocator's pointer, including the C behavior when the
underlying allocation returns null. Callee-saved registers and the C ABI are
preserved.

## Direct C/assembly parity

`Bench486HunkTempAllocCases` compares ten states, including sizes 0, 1, 15, 16,
17, 33 and -1; active and inactive starting marks; cleanup of existing
temporary allocations; and a two-call replacement sequence. Each pair compares
the complete 512-byte arena, cache sentinel, hunk marks, active flag, and
returned pointer offsets. It restores the live hunk, cache, and profiling state
after the fixture.

DOSBox-X reported:

```text
hunk temp-allocation C/ASM cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-130823/bench-result.json`.

## Strict i486 verification

The strict BENCH i486 gate passed. It audited 244,339 project instructions
across 159 objects and 282,636 linked instructions across 394 objects. The
relocated executable proof decoded all 282,636 opcodes across 235 runtime
inputs with zero data exemptions or skipped bytes. Final mapping bound 422
source contributions across 2,214 CODE ranges and 31 DATA ranges. Startup proof
covered 1,660 loaded bytes and 529 CODE rows; the maintained provider proof
covered 9,207 instructions. There were zero above-i486 or unknown instructions
and zero exemptions.

The non-BENCH i486 release gate also passed. It audited 127,258 project
instructions across 159 objects and 165,555 linked instructions across 394
objects. The executable proof decoded all 165,555 opcodes across 235 runtime
inputs. Final mapping bound 408 source contributions across 1,472 CODE ranges
and 31 DATA ranges. Startup and provider totals were 1,660 bytes/529 CODE rows
and 9,207 instructions, respectively. There were zero above-i486 or unknown
instructions and zero exemptions. The release manifest selects
`HunkTempAllocImplementation=asm`; the release map resolves `Hunk_TempAlloc`
to `zone_hunktempallocasm.obj` and omits `Hunk_TempAlloc_C`.

## Ownership and remaining work

The temporary-allocation wrapper now uses assembly in the default i486 profile.
`Hunk_AllocName` and `Hunk_HighAllocName` have separate assembly ports and C
oracles; see the [named-allocation ledger](2026-10-17-hunk-named-alloc-assembly-port.md).
Hunk diagnostics and other hunk management remain C-owned. This routine-level
fixture and the ISA gates do not establish full-scene framebuffer parity or
measure FPS.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Hunk_TempAlloc_C` | `src/zone_hunktempallocasm.s:Hunk_TempAlloc` | Ten exact cases across alignment edges, active-mark cleanup, returned offsets, complete arena, cache sentinel, and temporary state | DOSBox-X fixture passes; strict i486 BENCH and release gates pass |
