# `R_TeleportSplash` i486 assembly slice (2026-10-10)

## Port mapping and contract

`CL_ParseTEnt` invokes `R_TeleportSplash` for `TE_TELEPORT` in
`src/client/cl_tent.c`. The C oracle remains in `src/renderer/r_part.c` as
`R_TeleportSplash_C` when `TeleportSplashImplementation=asm` is selected; the
assembly entry is `src/renderer/r_teleportsplashasm.s:R_TeleportSplash_asm486`, which
exports the normal `R_TeleportSplash` symbol under `ASM486_TELEPORT_SPLASH`.
The C and assembly profiles are
`tools/renderer-profiles/i486-teleportsplash-c.json` and
`tools/renderer-profiles/i486-teleportsplash-asm.json`.

The routine preserves the original 8-by-8-by-14 lattice: `i` and `j` each
range from -16 to 12 in steps of four, and `k` from -24 to 28 in steps of four,
for at most 896 particles. It removes each node from `free_particles`, prepends
it to `active_particles`, sets the slow-gravity type and color, applies the
three random origin offsets, normalizes the original direction, and scales it
by the original random speed. Each emitted node consumes six random calls in
source order: lifetime, color, X/Y/Z origin offsets, then speed. The assembly
uses the 32-bit cdecl interface, preserves callee-saved registers, and calls
the same `VectorNormalize` and `VectorScale` helpers as the C routine. Its
source declares `.arch i486` and `.arch .387`.

`src/tests/bench486/bench486_teleportsplash.h:Bench486TeleportSplashCases` is the direct
state/RNG oracle fixture. Its seven cases use free-list sizes 0, 1, 37, 895,
896, and 897, plus a seeded libc-RNG continuation case. It verifies complete
particle and list state, padding and ramp bytes, guard canaries, `cl.time`,
callee-saved register/stack ABI state, six random calls per emitted node, and
the next random value. `tools/test-teleportsplash.py` checks the source,
selector, and fixture contracts; `tools/run-tests.ps1` registers that host
test. The DOS fixture runs with `-benchteleportsplash -benchexit` so libc RNG
continuation is tested in a disposable process.

For event-driven full-frame validation, the `TE_TELEPORT` branch records
`Bench486RecordTeleportSplashEvent` after the emitter returns. The scenario is
`demo2-teleportsplash-event` in
`tools/render-scenarios-teleportsplash.json`; the parity runner requires the
event and checks its frame and overflow telemetry alongside the framebuffer.

## TeleportSplash validation status

The direct i486 assembly fixture passed all seven C-versus-assembly cases in
`out/dos-bench-20261009-231415/bench-result.json`. The log reached each case
and ended with `teleport-splash C/ASM full-state and RNG continuation PASS
(7 cases; 0 failures)` followed by `486 benchmark correctness PASS`.

The paired C/assembly scene passed in
`out/render-parity-20261009-231628/render-parity-result.json`. Each of the two
repeats recorded exactly one TeleportSplash event at zero-based checksum frame
10 in both profiles, with zero overflow. After the four startup checksum
records, all seven indices 4 through 10 matched exactly in each repeat. Each
captured 320-by-200 indexed framebuffer and palette matched exactly: zero of
64,000 pixel indices and zero palette bytes differed in either repeat.

Both strict linked i486 audits passed with full executable disassembly and
source-bound code/data. The C-reference image audited 204,649 instructions
across 368 input objects; the assembly image audited 205,128 instructions
across 368 objects. Each contained only i386/i486 instructions, with zero
i586, P6, or unknown instructions, zero instruction exemptions, zero linked
opcode mismatches, and zero exempted linked data sites. Their relocated
runtime reports also passed with zero above-i486, unknown, or exempted
instructions. Each startup proof matched the final bytes and covered 529
instruction rows / 1,660 loaded bytes with zero exemptions. The maintained
CWS DPMI provider passed for both builds with 9,207 audited instructions and
zero above-i486, unknown, or exempted instructions.

This closes the focused emitter state/RNG, i486 machine-code, event-execution,
and exact full-frame parity gates for `R_TeleportSplash`. It does not mark the
broader renderer port complete.
