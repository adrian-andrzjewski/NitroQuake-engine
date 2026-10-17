# Hunk mark-release i486 assembly port (2026-10-17)

## Behavior and selector

`HunkMarkReleaseImplementation=asm` selects `Hunk_FreeToLowMark` and
`Hunk_FreeToHighMark` from `src/zone_hunkmarkfreeasm.s` in the current i486
profile. BENCH builds retain `Hunk_FreeToLowMark_C` and
`Hunk_FreeToHighMark_C` as independent parity references, and the C-reference
profile selects those C entries.

Both assembly entries validate the requested mark against the corresponding
used-byte count, report invalid marks through `Sys_Error`, clear released arena
bytes with `memset`, and update the used-byte count. The high-mark entry also
unwinds an active temporary hunk mark before applying the requested release.
The routines preserve the C ABI and callee-saved registers.

## Direct C/assembly parity

`Bench486HunkMarkFreeCases` compares five low-mark states and seven high-mark
states. Coverage includes unchanged and full-release marks, intermediate
releases, invalid marks, and high-mark release while temporary hunk state is
active. Each pair compares the full hunk arena and relevant low/high/temp mark
state, then restores the original live hunk globals.

DOSBox-X reported:

```text
hunk low/high free-mark C/ASM cases PASS failure mask 0x0
486 benchmark correctness PASS
```

## Strict i486 verification

The strict BENCH i486 gate passed. It audited 244,270 project instructions
across 158 objects and 282,567 linked instructions across 393 objects. The
relocated executable proof decoded all 282,567 opcodes across 235 runtime
inputs with zero data exemptions or skipped bytes. Final source mapping bound
420 contributions across 2,212 CODE ranges and 30 DATA ranges. Startup proof
covered 1,660 loaded bytes and 529 CODE rows; the maintained provider proof
covered 9,207 instructions. There were zero above-i486 or unknown instructions
and zero exemptions.

The non-BENCH i486 release gate also passed. It audited 127,336 project
instructions across 158 objects and 165,633 linked instructions across 393
objects. The executable proof decoded all 165,633 opcodes across 235 runtime
inputs. Final mapping bound 406 source contributions across 1,471 CODE ranges
and 30 DATA ranges. Startup and provider totals were 1,660 bytes/529 CODE rows
and 9,207 instructions, respectively. There were zero above-i486 or unknown
instructions and zero exemptions. The release manifest selects
`HunkMarkReleaseImplementation=asm`; the release map resolves both public
procedures to `zone_hunkmarkfreeasm.obj` and omits both C oracle symbols.

## Ownership and remaining work

The two mark-release routines now use assembly in the default i486 profile.
`Hunk_AllocName`, `Hunk_HighAllocName`, and other hunk-management routines
remain C-owned. `Hunk_TempAlloc` has a separate assembly port and C oracle; see
the [temporary-allocation ledger](2026-10-17-hunk-temp-alloc-assembly-port.md).
`Cache_Compact` remains an empty no-op. The direct fixture and instruction
gates establish routine-level state parity and i486 compatibility; they do not
establish full-scene framebuffer parity or measure FPS.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Hunk_FreeToLowMark_C`, `src/zone.c:Hunk_FreeToHighMark_C` | `src/zone_hunkmarkfreeasm.s:Hunk_FreeToLowMark`, `src/zone_hunkmarkfreeasm.s:Hunk_FreeToHighMark` | Twelve exact state cases across both procedures, including temp-mark unwind and full arena/state comparison | DOSBox-X fixture passes; strict i486 BENCH and release gates pass |
