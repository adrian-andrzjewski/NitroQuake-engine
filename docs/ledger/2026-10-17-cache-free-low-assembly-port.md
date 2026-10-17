# Cache_FreeLow i486 assembly port (2026-10-17)

## Behavior and selector

`CacheFreeLowImplementation=asm` selects the i486 assembly entry in
`src/zone_cachefreelowasm.s`. The C body remains `Cache_FreeLow_C` in BENCH
builds and the C-reference profile. The release build map contains
`Cache_FreeLow` and omits `Cache_FreeLow_C`; its build manifest records the
`asm` selector and includes `zone_cachefreelowasm.s`.

The entry scans the address-ordered cache list from its lowest block. It
returns when the list is empty or its first block starts at or above the
requested low-hunk boundary. Otherwise it calls the existing `Cache_Move`
entry and repeats, preserving the original C routine's caller and callee
contracts. `src/asm_cachefreelow.h` pins the cache header size and `next`
offset against `zone.c` at compile time.

## Direct C/assembly parity

`Bench486CacheFreeLowCases` compares five cache states: an empty list, an
exact boundary no-op, a successful relocation, a failed relocation that frees
the block, and repeated reclamation until the boundary is clear. It compares
the complete sentinel and arena bytes, user pointers, payload contents,
address-list order, LRU order, and link integrity. The fixture restores the
engine's original cache sentinel and hunk globals after the comparison.

DOSBox-X reported:

```text
cache free-low C/ASM hunk-boundary cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-104817/bench-result.json`.

## Strict i486 verification

The strict BENCH build passed the project-object, linked-object, relocated
executable, startup, CRT-helper and maintained CWSDPMI provider gates. It
audited 244,205 project instructions across 156 objects and 282,502 linked
instructions across 391 objects. The executable proof verified 282,502
opcodes across 235 runtime inputs and 417 source-bound contributions. The
final mapping covered 2,205 CODE ranges and 29 DATA ranges. Startup proof
covered 1,660 loaded bytes and 529 CODE rows; provider proof covered 9,207
instructions. There were zero above-i486 or unknown instructions, exemptions,
or skipped bytes.

The non-BENCH release build selected `CacheFreeLowImplementation=asm` and
passed the same strict gates: 127,752 project instructions across 156
objects, 166,049 linked instructions across 391 objects, 403 source-bound
contributions, 1,470 CODE ranges, 29 DATA ranges, 529 startup CODE rows, and
9,207 provider instructions. There were zero above-i486 or unknown
instructions, exemptions, or skipped bytes.

This fixture proves cache-state parity and instruction compatibility. It does
not measure full-scene FPS or framebuffer parity.

## Ownership and remaining work

`Cache_FreeLow` is now an assembly-owned entry in the default i486 profile.
`Cache_FreeHigh` and hunk allocation/free management remain C-owned;
`Cache_Compact` is an empty no-op. `Cache_Move`, `Cache_TryAlloc`, and
`Cache_Free` remain separate assembly ports with their own direct fixtures.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Cache_FreeLow_C` | `src/zone_cachefreelowasm.s:Cache_FreeLow` | Five boundary, relocation, failure/free, and repeated-reclamation states with full cache/hunk restoration | Strict i486 BENCH and release gates pass; DOSBox-X C/ASM fixture passes |
