# `R_LavaSplash` i486 assembly slice (2026-10-09)

## Scope and traceability

`CL_ParseTEnt` calls `R_LavaSplash` for `TE_LAVASPLASH` in
`src/cl_tent.c`. The C reference remains in `src/r_part.c`; when
`LavaSplashImplementation=asm`, it is exposed as `R_LavaSplash_C` for
`BENCH486`, while the assembly entry exports the normal `R_LavaSplash` symbol.
The implementation is isolated in `src/r_lavasplashasm.s` and selected with
`ASM486_LAVA_SPLASH`.

The emitter follows the original fixed 32-by-32 grid. It allocates at most
1,024 particles, prepends each allocation to the active list, and consumes six
random values per particle in source order: lifetime, color, X direction, Y
direction, Z origin offset, and velocity magnitude. The assembly keeps the
three grid loops and list mutation explicit and preserves the 32-bit cdecl
callee-saved registers.

The first assembly version calls the existing `VectorNormalize` and
`VectorScale` C helpers. That keeps the normalization and scaling operations
identical to the C oracle while this leaf is brought under the assembly
selector. The particle layout, client-time offset, and `pt_slowgrav` value are
checked in C at compile time. The assembly source declares `.arch i486` and
`.arch .387`; its source-level mnemonic allowlist is checked by
`tools/test-lavasplash.py`. The built object and executable still require the
normal mechanical ISA audit.

## Correctness fixture

`src/bench486_lavasplash.h` supplies a guarded pool and compares the C oracle
with `R_LavaSplash_asm486` byte-for-byte. It checks active/free heads and links,
all particle bytes, unchanged padding and ramp bytes, canaries, `cl.time`, ABI
preservation, random-call counts, and the next random value. Scripted cases
cover empty, one-node, partial, near-full, full 1,024-node, and 1,025-node
free lists; a seeded libc case checks RNG continuation. The fixture requires
`-benchexit` because the DOS C runtime does not expose a way to restore its
internal random state.

During fixture debugging, a scalar `float !=` check falsely rejected both
paths even though the stored one-particle `die` values had identical bits
(`0x41d1f5c3`); the x87 kept an excess-precision temporary. The checker now
compares the stored `die`, origin, and velocity bytes directly, retaining exact
stored-value checks without relying on scalar x87 rounding behavior.

## LavaSplash validation status

Run the direct fixture with the benchmark runner using
`-LavaSplashImplementation asm -LavaSplashOnly`. The combined i486 build
passed its full executable ISA gate in `out/profile-96593b38735b634c`: 205,914
linked instructions across 367 objects, 355 source-bound contributions and
1,635 CODE ranges, with zero post-486, unknown, or exempted instructions. Its
startup proof covered 529 rows, and the maintained CWS DPMI provider passed
with 9,207 audited instructions and zero exemptions.

The direct fixture passed all seven C/ASM cases in
`out/dos-bench-20261009-215511/bench-result.json`: empty, one particle,
partial, almost-full, full, one-extra, and libc-RNG continuation. All
particle/list/padding/ramp/canary state, ABI, `cl.time`, random-call counts,
and post-fixture RNG values matched. Its progress log recorded all seven case
indices and ended with `486 benchmark correctness PASS`.

The paired full-frame TE_LAVASPLASH run passed in
`out/render-parity-20261009-221059/render-parity-result.json`. Both i486
profiles passed their own strict executable, startup, and CWS DPMI ISA audits:
the C image had 204,361 linked instructions and 1,625 CODE ranges; the
assembly image had 204,768 linked instructions and 1,632 CODE ranges. Each
audit covered 367 objects, 355 source-bound contributions, the 529-row loader,
and 9,207 provider instructions, with zero post-486, unknown, or exempted
instructions.

Both profiles passed two DOSBox-X runs. Each run recorded exactly one
TE_LAVASPLASH at frame 10, zero event overflow, and 11 checksum records. After
excluding the four warmup records, all seven remaining frame checksums matched
exactly between C and assembly. All four captured frames matched exactly:
64,000 indexed pixels and palette bytes, with no mismatches. The final
framebuffer checksum was `897466993`; each profile reported a 12.15 fps median.
The timing is recorded for regression context, not as an optimization target.

This closes focused emitter state/RNG, 486 machine-code, event-execution, and
full-frame parity gates for `R_LavaSplash`. No completion claim is made for the
broader renderer port.
