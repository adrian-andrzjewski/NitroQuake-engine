# Cache_FreeHigh i486 assembly port (2026-10-17)

## Behavior and selector

`CacheFreeHighImplementation=asm` selects `Cache_FreeHigh` in
`src/zone_cachefreehighasm.s`. The C implementation remains
`Cache_FreeHigh_C` in BENCH builds and the C-reference profile. The current
i486 release profile selects assembly, records the selector in its build
manifest, links the assembly symbol, and omits `Cache_FreeHigh_C`.

The routine scans the address-ordered cache list from its highest block. It
returns when that block ends at or below `hunk_base + hunk_size -
new_high_hunk`. Otherwise it tries `Cache_Move`; if the same block remains at
the tail, it frees the associated user allocation, then repeats. The assembly
preserves the C ABI and delegates allocation, relocation, and LRU changes to
the existing selected `Cache_Move` and `Cache_Free` entries. The private cache
header size, user offset, and sentinel `prev` offset are compile-time checked
in `src/asm_cachefreehigh.h`.

## Direct C/assembly parity

`Bench486CacheFreeHighCases` compares the C and assembly entries in five
states: empty cache, exact-boundary no-op, successful relocation into a gap,
failed relocation and free, and repeated tail reclamation. It compares the
cache sentinel, full 512-byte arena, all user records and payloads, address and
LRU order, and link consistency. The fixture restores the live cache sentinel
and hunk globals after each pair.

DOSBox-X reported:

```text
cache free-high C/ASM hunk-boundary cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-113238/bench-result.json`.

## Strict i486 verification

The strict BENCH build passed the project-object, linked-object, relocated
executable, startup, CRT-helper and maintained CWSDPMI provider gates. It
audited 244,430 project instructions across 157 objects and 282,727 linked
instructions across 392 objects. The executable proof decoded all 282,727
opcodes across 235 runtime inputs and 418 executable text ranges. Final mapping
bound 418 source contributions across 2,208 CODE ranges and 29 DATA ranges.
Startup proof covered 1,660 loaded bytes and 529 CODE rows; the provider proof
covered 9,207 instructions. There were zero above-i486 or unknown instructions,
exemptions, or skipped bytes.

The non-BENCH i486 release selected `CacheFreeHighImplementation=asm` and
passed the same strict gates. It audited 127,907 project instructions and
166,204 linked instructions across 392 objects; executable proof decoded all
166,204 opcodes across 235 runtime inputs. Final mapping bound 404 source
contributions across 1,471 CODE ranges and 29 DATA ranges. Startup proof again
covered 1,660 bytes and 529 CODE rows; the provider proof covered 9,207
instructions. There were zero above-i486 or unknown instructions, exemptions,
or skipped bytes. The release map contains `Cache_FreeHigh` from
`zone_cachefreehighasm.obj` and does not contain `Cache_FreeHigh_C`.

These checks establish cache-state parity and instruction compatibility. They
do not measure full-scene FPS or framebuffer parity.

## Ownership and remaining work

`Cache_FreeHigh` is now assembly-owned in the default i486 profile. Hunk
allocation/free management remains C-owned; `Cache_Compact` is an empty no-op.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/zone.c:Cache_FreeHigh_C` | `src/zone_cachefreehighasm.s:Cache_FreeHigh` | Five exact empty, boundary, move, free, and repeated-reclamation states with full cache-state comparison and restoration | Strict i486 BENCH and release gates pass; DOSBox-X fixture passes |
