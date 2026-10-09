# `R_BlobExplosion` -> i486 assembly port (2026-10-09)

## C reference and behavior

`R_BlobExplosion` in `src/r_part.c` is called by `CL_ParseTEnt` for
`TE_TAREXPLOSION`. It emits up to 1024 particles, stopping sooner if
`free_particles` is empty. Each node moves to the head of `active_particles`.
The routine sets the particle lifetime, alternates `pt_blob2` and `pt_blob`,
selects colors from the 150 and 66 ranges, and offsets each origin and velocity
with random values. Each emitted particle consumes eight random values in
source order: lifetime, color, then origin and velocity for x, y and z.

The BENCH486 C oracle is exposed as `R_BlobExplosion_C` when
`ASM486_BLOB_EXPLOSION` is selected. Its random calls go through
`Bench486BlobExplosionRand`, which allows the fixture to provide scripted
values while retaining libc `rand()` for the ordinary path. The assembly
implementation uses signed `IDIV` for `% 6`, `% 32` and `% 512`, including the
signed-remainder behavior exercised by negative fixture values.

## Assembly, selector and fixture

`src/r_blobexplosionasm.s:R_BlobExplosion_asm486` implements the list updates,
type/color selection, coordinate and velocity generation, and the x87 lifetime
calculation. It exports the public `R_BlobExplosion` name under
`ASM486_BLOB_EXPLOSION`. Its source declares `.arch i486` and `.arch .387`;
those declarations and the instruction choices do not replace the required
object and executable ISA audit. For `die`, the assembly follows the inspected
C-object operation order: save `cl.time` as a double before `rand`, multiply
double `0.05` by `rand() & 8`, add single-precision `1.0` to the saved time,
combine the x87 values, then narrow to the particle float field.

`BlobExplosionImplementation=asm` is the isolated selector in
`tools/renderer-profiles/i486-asm-blob-explosion.json`; the candidate is also
included in `i486-asm-selectable-92.json`. `src/bench486_blobexplosion.h`
contains `Bench486BlobExplosionCases`, with empty, one-node, alternating,
short, almost-full, full and one-extra-node cases. It compares the complete
guarded particle fixture and list links, checks ABI and unchanged `cl.time`,
verifies scripted signed-remainder outputs and eight calls per emitted
particle, and compares the next seeded libc RNG value. The libc-RNG case is
intended for the disposable `-benchexit` benchmark process.

## Event-driven scene trace

The BENCH486 `TE_TAREXPLOSION` branch in `src/cl_tent.c` calls
`Bench486RecordBlobExplosionEvent` immediately after `R_BlobExplosion`
returns. `host_cmd.c` records the current zero-based rendered-frame index for
up to 32 events, counts every call and records overflow. The frame index advances
independently of optional checksum output and aligns with the checksum stream
when checksum capture is enabled. The report line is
`blob-explosion-events <count> frames <indices...> overflow <overflow>`.

`tools/render-scenarios-blob-explosion.json` narrows the pinned
`demo2-entity-workload` scene and requires the `blobExplosion` event. It retains
the reference scene's 985 frames, checksum `1887495667`, capture frame 169 and
golden PCX reference. The manifest test verifies those pinned fields and the
required event. The host rendering test suite passed all 68 tests, including
that manifest test, and the PowerShell event-record parser regression passed.

## Validation status

The source, selector, direct fixture, event trace and focused scene manifest
are wired, but runtime acceptance is still pending. No result is claimed for
the strict i486 build and ISA gate, the direct DOSBox fixture, or the paired
C-reference/assembly framebuffer and checksum run. All three remain
**PENDING**; the assembly output has not yet been demonstrated equivalent in
the target runtime.
