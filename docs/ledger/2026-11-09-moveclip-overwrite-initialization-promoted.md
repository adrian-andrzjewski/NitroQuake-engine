# Remove overwritten move-clip initialization (2026-11-09)

## Change and invariant

SV_Move no longer clears its 124-byte moveclip_t before assigning every field.
Before SV_ClipToLinks consumes the object, assignments cover swept bounds (24),
four input pointers (16), monster bounds (24), the returned trace (52), movement
type (4) and passedict (4) bytes. Both C and assembly entity-trace helpers fully
initialize their returned trace. Debug swept-bounds and missile branches also
assign all their fields. No initialized field, trace operation or arithmetic
expression is removed. The i386 ABI has no unassigned padding in this layout.

## Native correctness and generated code

The actual i486 compiler previously emitted a 31-dword rep stosl; this clear is
absent in the candidate. The trace-copy remains. Across 435 normalized C/H/S/INC
files, only world.c differs from 682998a8a3eb. Candidate world.c SHA-256 is
`78a999bf521b2950a0a2b914223df2bfbd8aaaf5e8190b0848925ded23997357`.

The native differential fixture passes 18,432 cases using actual extracted
SV_Move/SV_MoveBounds code and explicit native trace/consumer stubs. It compares
all 124 bytes at the consumer and the entire returned 52-byte trace, with three
movement modes, null/non-null passedict, varied bounds including special float
patterns, two trace outcomes, distinct stack-poison patterns and twelve x87
precision/rounding settings. CW, TOP and tag state are checked. This isolates
initialization; it is complemented by real gameplay with the actual helpers.

The isolated BENCH486 build passes complete i486 auditing: 316,301 relocated
instructions, 529 startup rows, 9,207 provider instructions, zero above-target,
unknown or exempt instructions. The actual retained flags include fast-math.

## Independent matched gameplay

Three alternating pairs per group measure 256 local-server frames after 64
warm-up frames, god/forward/fire, fixed simulation step from startup, 320x200,
DOSBox-X 2026.08.31 dynamic 486/x87, fixed 33445 cycles and the pinned PAKs/provider.
Per-frame FPS and detailed profiling are disabled. Every group matches final
framebuffer/selected simulation checksums and complete QuakeC statement counts.

| Workload | Control median FPS | Candidate median FPS | FPS change |
|---|---:|---:|---:|
| e1m1, silent | 23.536090 | 23.554612 | +0.078696% |
| e1m2, silent | 21.900989 | 21.916318 | +0.069995% |
| e1m1, sound | 23.103402 | 23.121456 | +0.078143% |
| e1m2, sound | 21.231542 | 21.246178 | +0.068934% |

Pooling twelve samples per variant gives 22.405021 -> 22.421317 FPS,
**+0.072735%**. An e1m1 sound sample has a small timing spike; its +0.065138%
paired gain is retained alongside the other samples rather than discarded.
The retained-evidence audit passes all 24 result/report/count hashes and pins.

## Acceptance and integration boundary

Accept one redundant-work-removal optimization attempt for combined integration.
Final combined compatibility, replay parity, normal release and matched runtime
gates remain required before main-checkout promotion. Their results belong in
the benchmark suite's docs/I486-COLLISION-OPTIMIZATION-20261109.md, outside the
game build fingerprint. Native version identity remains inventory-derived.

Evidence: benchmarks/out/move-init-native-fixture-v2-20261109/ and
benchmarks/out/move-init-validation-20261109/. The latter session SHA-256 is
`7CAEC5F9569589C8F99505DB022D41EC19B46EE018BDCAF906A44C75FF69F4FB`.
These are emulator timings; physical 486 cache behavior and FPS are unmeasured.
