# Hunk high-mark query i486 assembly port

## Behavior and selector

`Hunk_HighMark` returns `hunk_high_used`. If a temporary high-hunk allocation is
active, it first clears `hunk_tempactive`, releases to `hunk_tempmark` through
`Hunk_FreeToHighMark`, then returns the updated high mark. The procedure is now
implemented in `src/zone_hunkmarkfreeasm.s` under the existing
`HunkMarkReleaseImplementation` selector. The default i486 profile already
selects this module as assembly. BENCH retains `Hunk_HighMark_C` as the C
reference.

## Direct C/assembly parity

The existing hunk mark fixture now covers 17 state cases: five low-mark
releases, seven high-mark releases, and five `Hunk_HighMark` states. The latter
include no active temporary allocation, an active unwind, an unwind to the
current mark, and a full high-hunk release. Each `Hunk_HighMark` case compares
the returned value, all 512 bytes of the synthetic arena, and the
low/high/temp-mark state. The fixture restores the live hunk globals afterward.

DOSBox-X reported:

```text
hunk low/high mark-management C/ASM cases PASS failure mask 0x0
486 benchmark correctness PASS
```

## Strict i486 verification

The focused strict BENCH i486 build passed with 244,701 project instructions
and 282,998 linked executable instructions. The linked executable proof decoded
all 282,998 opcodes, with zero above-i486 or unknown instructions, exemptions,
or undecoded bytes. Startup proof covered 529 CODE rows; the maintained
provider proof covered 9,207 instructions with zero exemptions. The benchmark
link map resolves public `Hunk_HighMark` to `zone_hunkmarkfreeasm.obj` and
retains `_Hunk_HighMark_C` as a distinct C oracle.

This validates state parity and i486 compatibility. It is not an FPS
measurement or full-scene framebuffer comparison.

## Cache and memory scope remaining

The cache block lookup, allocation/search, free, move, LRU operations,
low/high reclamation, zone heap allocation/free, hunk allocation, temporary
allocation, and mark release/query paths now select assembly in the i486
profile. Remaining C-owned memory entry points include startup `Memory_Init`,
`Cache_Init`/`Cache_Flush` and reporting commands, `Z_Malloc`'s zero-fill
wrapper, and heap/hunk consistency and print routines. `Cache_Compact` is an
empty no-op.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Hunk_HighMark_C` | `src/zone_hunkmarkfreeasm.s:Hunk_HighMark` | Five exact state comparisons, including temp unwind and full arena/state comparison | DOSBox-X fixture passes; strict i486 BENCH gate passes |
