# `R_TransformFrustum` assembly candidate (2026-10-09)

## Opt-in frustum transform candidate

**Traceability.**

The original implementation is `R_TransformFrustum` in `src/r_misc.c`. Its C
calculation remains available as `R_TransformFrustumCore_C` for the benchmark
oracle. The selectable replacement is `R_TransformFrustum` and
`R_TransformFrustumCore_asm486` in `src/r_frustumasm.s`; layout contracts are in
`src/asm_frustum.h`, and the guarded direct fixture is in
`src/bench486_frustum.h`.

The assembly uses an unrolled `.arch i486`/`.arch .387` x87 schedule. It follows
the target compiler's expression order and retains the extended intermediates
through the same float-store and distance-dot-product boundaries as the C
reference. The `i486-asm-frustum-transform` renderer profile changes only
`TransformFrustumImplementation`; C remains the default.

**Verification.**

The direct DOSBox-X i486 fixture passed against the exact executable that passed
the object and linked-code audits. It compared the transformed plane vectors,
distances, x87 status, guard regions and calling-convention state: 5,760 cases,
12 x87 control words and 4,096 consecutive calls, with zero failures. The
staged executable's SHA-256 matched the audited executable.
That executable's SHA-256 is
`1D1BF0306C5EF75978120CA9FBE0474A8177CC6EBF7060449592AED832B97150`.

The strict object audit checked 164,030 instructions in 123 project objects and
found zero instructions above i486. Exact source proofs passed for all 123
project objects and 235 installed runtime objects. The linked-object audit
checked 202,295 instructions across 358 objects; the independent relocated
executable audit checked the same 202,295 opcodes across 341 text ranges. Both
reported zero post-i486 or unknown instructions, exemptions, skipped bytes or
relocation gaps. Source-to-executable mapping passed for 341 contributions and
1,599 ranges.

The main renderer suite passes 54 tests. `tools/test-build-dos.py`, the
documentation structure check and `git diff --check` also pass.

**Promotion status and remaining checks.**

This candidate is not promoted. Full C-versus-assembly scene captures have not
completed, so the C implementation remains the default and the candidate profile
is isolated. The normal i486 build reached and passed the project, runtime,
linked-object and relocated-executable audits, then stopped at the separate
startup-source reproduction gate: `tools/djgpp-assembler-tool.py` could not find
a Windows MinGW GCC. The executable therefore has no complete startup/provider
manifest from that build.

An attempted paired run on the i386 build path stopped at its independent ISA
baseline gate before DOSBox launched; it produced no scene captures and is not
parity evidence. The next acceptance step is a paired i486 C-reference and
assembly run through `tools/render-parity-dos.ps1`, followed by timing only if
the parity gate passes. No performance claim is made for this setup routine.
