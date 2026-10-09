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

## Paired scene parity (visual-only diagnostic)

On 2026-10-09, the isolated `-VisualParityOnly` runner compared
`i486-c-reference` with `i486-asm-frustum-transform` in DOSBox-X 2026.08.31
using the pinned i486 profile. The shared source-tree fingerprint matched
(`1FCFC8080DC88945BD660E9A330538015A4AFD9FBE3B03F73BF5B16B7CD22736`).
Both build manifests explicitly say `isaAuditStatus: SKIPPED`; these renderer
binaries are separate from the earlier strictly audited executable and this
pair is not 486 instruction-set evidence.

The six runs (two each for `demo1-vga-full`, `demo2-entity-workload` and
`demo3-world-workload`) passed 6,058 post-warmup frame-checksum comparisons.
All six 320x200 indexed captures and their 768-byte palettes matched exactly:
zero differing pixel indices, zero palette-byte mismatches and no unexplained
frame differences. Six startup frames per run were excluded by the existing
pair gate. The independent CWSDPMI provider proof also passed: 9,207
instructions, one reviewed runtime branch variant and zero exemptions.

The visual-only executables were recorded separately from the strict candidate:

| Profile | Executable SHA-256 | ISA status |
|---|---|---|
| `i486-c-reference` | `023557407AD2406D83CCF37610753DA936D1303D9C56E6A2AA1F92349765C60C` | `SKIPPED` |
| `i486-asm-frustum-transform` | `9D883BD296405FE7D0A8713CBDC0DE2F41753EA82EF26CC17AB6F23E95F028E3` | `SKIPPED` |

The pair report is `out/render-parity-frustum-visual-20261009/render-parity-result.json`.
Median FPS differed by less than 0.013% in each scene (candidate versus C):
12.680860 versus 12.681964, 12.780727 versus 12.781459, and 12.173252 versus
12.174717. These are regression observations, not a promotion criterion.

**Promotion status and remaining checks.**

This candidate is not promoted. The C implementation remains the default and
the assembly profile remains isolated. The normal i486 build reached and passed
the project, runtime, linked-object and relocated-executable audits, then
stopped at the separate startup-source reproduction gate:
`tools/djgpp-assembler-tool.py` could not find a Windows MinGW GCC. The earlier
strictly audited executable therefore has no complete startup-source manifest,
and the visual-only executables above have no renderer ISA audit. Complete the
startup-source proof and run the strict linked and executable gates on the exact
renderer binary before considering promotion. No performance claim is made for
this setup routine.
