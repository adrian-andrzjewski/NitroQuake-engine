# `R_TransformFrustum` assembly candidate (2026-10-09)

## Opt-in frustum transform candidate

**Traceability.**

The original implementations are `R_TransformFrustum` and
`R_SetUpFrustumIndexes` in `src/r_misc.c`. Their C calculations remain
available as benchmark oracles. The selectable replacements are in
`src/r_frustumasm.s`; layout contracts are in `src/asm_frustum.h`, and guarded
direct fixtures are in `src/bench486_frustum.h`.

The assembly uses an unrolled `.arch i486`/`.arch .387` x87 schedule. It follows
the target compiler's expression order and retains the extended intermediates
through the same float-store and distance-dot-product boundaries as the C
reference. The `i486-asm-frustum-transform` renderer profile changes only
`TransformFrustumImplementation`; that selector covers both routines. C
remains the default.

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

## Frustum AABB-index setup extension (2026-10-09)

`R_SetUpFrustumIndexes` runs from `R_SetupFrame` after the clip planes are
transformed. It selects the positive and negative AABB corners for each of the
four clip planes. Under the existing `TransformFrustumImplementation` selector,
the C oracle is `R_SetUpFrustumIndexes_C` and the assembly replacement writes
the same six indices and pointer per plane. Static assertions bind the assembly
offsets and table sizes to the C structures.

The C compiler compares each normal by loading zero and executing
`fcomps normal`. The assembly follows that operand order and checks the
unordered flag before branching, matching both the ordered `< 0` decision and
the resulting x87 status for negative zero and NaN inputs. This detail was
verified against generated C assembly; an earlier `FTST` version produced the
same tables but left the opposite C0 condition bit and was rejected by the
direct oracle.

The diagnostic DOSBox-X i486 run passed 5,632 index cases across 12 x87 control
words and 4,096 continuous calls, with exact index tables, pointer tables,
input preservation, x87 status and ABI state. The existing transform fixture
also passed all 5,760 cases. Both reported zero failures. The active
`r_frustumasm.obj` was independently disassembled and classified: 235
instructions, all i386/i486-compatible, zero post-i486 or unknown instructions,
and zero exemptions. Its report and instruction stream are retained under
`out/diagnostic-bench-profile-ee3cdf2774ad7b09/isa-qbench/`.

The full candidate builds for these diagnostics explicitly report
`isaAuditStatus: SKIPPED`; the object result proves only this assembly object,
not the renderer executable or its runtime. The independent CWSDPMI proof
passed with 9,207 instructions, one reviewed runtime branch variant and zero
exemptions.

The paired visual-only run compared one run each of `demo1-vesa-full`,
`demo2-entity-workload` and `demo3-world-workload`. All six C and assembly
timedemos passed. After the six configured warmup frames, all 964, 980 and
1,085 frame checksums matched exactly. The three 320x200 indexed captures and
their 768-byte palettes also matched exactly: zero pixel-index and palette
mismatches. The shared source-tree fingerprint matched. The pair report is
`out/render-parity-frustum-index-visual-20261009/render-parity-result.json`;
both build manifests still say `SKIPPED`, so this is visual evidence only.

**Promotion status and remaining checks.**

This candidate is not promoted. The C implementation remains the default and
the assembly profile remains isolated. The earlier strict audit and executable
hash above predate the `R_SetUpFrustumIndexes` extension. The new diagnostic
candidate's full renderer audit remains incomplete at the separate
startup-source reproduction gate:
`tools/djgpp-assembler-tool.py` could not find a Windows MinGW GCC. The earlier
strictly audited executable therefore has no complete startup-source manifest,
and the new visual-only executables have no renderer ISA audit. Complete the
startup-source proof and run the strict linked and executable gates on the exact
extended renderer binary before considering promotion. No performance claim is
made for these setup routines.
