# Cache_Move i486 assembly port (2026-10-17)

## Behavior and selector

`CacheMoveImplementation=asm` selects `Cache_Move` in
`src/memory/zone_cachetryallocasm.s`; BENCH builds retain the C body as
`Cache_Move_C`, and the C-reference profile selects C. The routine requests a
same-sized block with `nobottom=true`. On success it copies the payload,
owner and name, frees the old block, then updates the user's data pointer. If
the new block cannot be allocated, it frees the old block as the C routine
does. The existing cache layout assertions pin the structure size and fields
used by the entry.

## Direct C/assembly parity

`Bench486CacheMoveCases` compares C and assembly for successful relocation to
the top of the cache and for a full-cache failure. The fixture compares the
complete arena, sentinel, user records, payload and name bytes, address/LRU
order, and `PROFILE486` move, byte, free and allocation-search counters.
DOSBox-X reported:

```text
cache move C/ASM relocation cases PASS failure mask 0x0
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261017-081313/bench-result.json`.

## Strict i486 verification

The focused strict BENCH proof passed project-object, linked-object,
relocated executable, startup, CRT-helper and maintained CWSDPMI provider
gates. It audited 243,861 project instructions across 154 objects and
282,158 linked instructions across 389 objects. Executable proof verified
all 282,158 opcodes across 235 runtime inputs and 415 source-bound
contributions. The final mapping covered 2,199 CODE ranges and 29 DATA
ranges; startup proof covered 1,660 loaded bytes and 529 CODE rows, and the
provider proof covered 9,207 instructions. There were zero above-i486 or
unknown instructions, exemptions, or skipped bytes.

The fixture checks relocation correctness and instruction compatibility; it
does not measure full-scene FPS or framebuffer parity.

## Ownership and remaining work

`Cache_Move` is no longer a C-owned renderer entry in the default i486
profile. `Cache_FreeLow` and `Cache_FreeHigh` still contain C control loops,
while hunk management remains C-owned. The BENCH inventory is recorded at
`out/local-cachemove/renderer-ownership-qbench.json`.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/memory/zone.c:Cache_Move_C` | `src/memory/zone_cachetryallocasm.s:Cache_Move` | Successful move and no-space fallback with full state comparison | Strict i486 gates pass; DOSBox-X fixture passes |
