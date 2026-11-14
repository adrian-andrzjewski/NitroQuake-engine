# `R_BlobExplosion` -> i486 assembly port (2026-10-09)

## C reference and behavior

`R_BlobExplosion` in `src/renderer/r_part.c` is called by `CL_ParseTEnt` for
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

`src/renderer/r_blobexplosionasm.s:R_BlobExplosion_asm486` implements the list updates,
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
included in `i486-asm-selectable-92.json`. `src/tests/bench486/bench486_blobexplosion.h`
contains `Bench486BlobExplosionCases`, with empty, one-node, alternating,
short, almost-full, full and one-extra-node cases. It compares the complete
guarded particle fixture and list links, checks ABI and unchanged `cl.time`,
verifies scripted signed-remainder outputs and eight calls per emitted
particle, and compares the next seeded libc RNG value. The libc-RNG case is
intended for the disposable `-benchexit` benchmark process.

## Event-driven scene trace

The BENCH486 `TE_TAREXPLOSION` branch in `src/client/cl_tent.c` calls
`Bench486RecordBlobExplosionEvent` immediately after `R_BlobExplosion`
returns. `host_cmd.c` records the current zero-based rendered-frame index for
up to 32 events, counts every call and records overflow. The frame index advances
independently of optional checksum output and aligns with the checksum stream
when checksum capture is enabled. The report line is
`blob-explosion-events <count> frames <indices...> overflow <overflow>`.

`tools/render-scenarios-blob-explosion.json` defines a short event-driven
fixture. The generator reads `demo2.dem` from `pak0.pak`, preserves source
records 0 through 14, and appends the `TE_TAREXPLOSION` to source record 14.
That record is the eleventh retained post-signon record: the fixture starts its
post-signon prefix at record 4 and keeps 11 records. The event coordinates are
protocol shorts `[-2136, 17413, 9968]` (each coordinate is in eighths of a world
unit). The generator then appends a separate one-byte `svc_disconnect` record
using the last retained view angles. The timedemo runner wraps the short demo in
a tiny root-entry `demo2.dem` override at the next contiguous PAK index, hashes
both generated artifacts, and removes the loose temporary `.dem` before
launching Quake. This lets `timedemo demo2` reach Quake's ordinary timedemo
completion path without copying the full game data or reading the rest of the
source demo.

The scene manifest fixes `host_framerate` at `0.0783`, runs twice by default,
requires a non-overflowing `blobExplosion` event, and requires the capture to
land on that event. Its C-reference baseline is 10 reported timedemo frames,
final checksum `2074560903`, capture/checksum-stream frame index 10, and the
committed 320x200 PCX. Image tolerance is zero for both changed pixels and mean
channel error.

The C-reference validation report at
`out/render-validation-20261009-205727/render-validation-result.json` passed
both runs. Each run reported 10 timedemo frames and 11 checksum records; the
extra record is the setup frame that `CL_FinishTimeDemo` excludes from its
reported count. Both runs recorded exactly one event at absolute checksum
index 10, with overflow 0, and captured index 10. Both captured PCX files
matched the committed golden exactly: all 64,000 indexed pixels and the full
palette matched. The first four checksum records varied between the repeated
C runs; indices 4 through 10 matched. Accordingly, this fixture manifest
excludes only its four leading checksum records from repeat and paired-stream
stability comparisons. The final event frame remains compared and is also
checked against the exact golden image. These results validate the fixture,
termination, event/capture alignment, and C-reference baseline.

The paired report at `out/render-parity-20261009-211014` passed both C and
assembly profiles for two runs each. Every run recorded one event at frame 10
with zero overflow and 11 checksum records. After excluding the four startup
records, all seven remaining checksums matched exactly between C and assembly.
Both captured frames from each profile matched exactly: all 64,000 pixel
indices and the palette bytes matched. The C and assembly profiles each
reported a median of 12.1 fps. This verifies exact rendering parity for this
focused BlobExplosion scene; the timing is recorded for regression context,
not as an optimization target.

## Validation status

The combined LavaSplash and BlobExplosion assembly candidate passed the full
executable ISA gate in `out/profile-96593b38735b634c`. The linked image
contains 205,914 audited instructions across 367 objects, with zero post-486,
unknown, or exempted instructions; 355 source-bound contributions and 1,635
CODE ranges were verified. The startup proof audited 529 rows, and the
maintained CWS DPMI provider passed with 9,207 instructions and zero
exemptions. The paired C-reference/assembly framebuffer and checksum run
passed as described above. The direct `Bench486BlobExplosionCases` fixture
also passed all seven C/ASM cases in
`out/dos-bench-20261009-215537/bench-result.json`, including full pool/list
state, ABI, and RNG-continuation checks. This evidence establishes this
slice's machine-code compatibility and focused scene parity; it does not
establish completion of the broader renderer port.

## 2026-10-10 i486 release-default promotion

`BlobExplosionImplementation` now defaults to assembly only when
`CpuTarget=i486` and the caller did not explicitly choose an implementation.
An explicit C selection remains available for reference runs; i386 stays on C.
`tools/test-build-dos.py` passes with the new suffix and flag golden (44 C and
42 assembly flags for i486; the i386 profile remains 37 and 35).

Fresh validation used the 486DX/x87 DOSBox-X profile and retained:

- `out/dos-bench-20261010-130928/bench-result.json`: all seven C/ASM fixture
  cases passed, including full pool/list state, ABI, guards, call count and
  libc RNG continuation. Its linked benchmark executable passed the strict
  210,938-instruction gate with zero above-i486, unknown or exempt instructions.
- `out/render-parity-20261010-130946/render-parity-result.json`: both profiles
  passed twice. Each run recorded one `TE_TAREXPLOSION` at frame 10 with no
  overflow. After excluding only the four documented startup checksum records,
  all seven remaining frame checksums matched exactly. Both 320x200 captures
  matched all 64,000 indexed pixels and every palette byte, with zero
  differences. C and assembly both measured 12.1 FPS on this focused scene.
- `out/profile-68899b4f74c77192/isa-qbench/isa-audit-linked.json`: the paired
  assembly-profile benchmark image passed with 206,247 relocated instructions,
  529 startup rows and the 9,207-instruction CWS DPMI provider; there were no
  post-486, unknown or exempt instructions.
- `out/profile-6bb5ccc5c741aec3/quake.exe` and
  `out/profile-6bb5ccc5c741aec3/isa-quake/isa-audit-linked.json`: the normal
  non-BENCH release build selected BlobExplosion assembly and passed with
  171,561 relocated instructions, 529 startup rows and the same provider
  closure, with zero post-486, unknown or exempt instructions.

The three staged DOSBox game-data directories were removed after validation;
the JSON reports, checksums and framebuffer captures remain. These checks
promote this routine only and do not claim full renderer completion.
