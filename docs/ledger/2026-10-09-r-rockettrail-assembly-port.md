# `R_RocketTrail` assembly port (2026-10-09)

## Port and traceability

The reference is `R_RocketTrail` in `src/r_part.c`; the opt-in implementation
is `src/r_rockettrailasm.s`, selected by `RocketTrailImplementation=asm` and
included in the focused `i486-asm-rocket-trail.json` and combined
`i486-asm-selectable-91.json` profiles. The assembly follows the original
particle-list updates, trail-type dispatch, float-step behavior, RNG use,
tracer counter, and caller-visible advancement of `start`. The ordinary C
implementation remains available as the BENCH486 oracle.

## Reference fixture

`src/bench486_rockettrail.h` defines 16 deterministic C-versus-assembly cases.
They cover zero/exact/short steps, rocket/smoke/blood/slight-blood/tracer/
tracer2/Voor/default trails, encoded and negative types, tracer and free-list
exhaustion, and libc RNG continuation. The fixture checks particle memory and
list state, mutable `start` and unchanged `end`, RNG calls/continuation,
tracer state, ABI preservation, and guard words. `tools/bench-dos.ps1` routes
`-RocketTrailOnly` to `+bench486 -benchrockettrail -benchexit` when the assembly
selector is enabled. The 16-case direct fixture passed under DOSBox-X using the
strict candidate binary; its report is
`out/dos-bench-20261009-182711/bench-result.json`.

## Acceptance evidence

- Strict i486 build and complete instruction verification passed for
  `out/profile-60360318f8a973fb`. The object audit checked 130 project objects
  and 165,403 instructions; the linked audit checked 203,700 relocated
  instructions over 349 source-bound contributions and 1,595 code ranges. The
  final executable, 529 startup rows and 9,207 runtime-provider instructions
  all passed with zero above-i486, unknown or exempt instructions. Reports are
  under `out/profile-60360318f8a973fb/isa-qbench/`.
- The direct C/assembly fixture passed all 16 cases, comparing complete
  particle/list state, mutable `start`, RNG continuation, tracer counters, ABI
  preservation and guard words.
- The exact paired `demo2-entity-workload` capture passed in
  `out/render-parity-rocket-trail-20261009`. All 980 compared frame checksums
  matched after the six ignored warmup frames; the 320x200 indexed framebuffer
  and palette had zero differing bytes. Both profiles measured 12.78 FPS for
  this single scene. The source-tree fingerprints matched.

The direct and gameplay fixtures provide narrow acceptance for this entry; the
renderer-wide coverage and migration remain incomplete.
