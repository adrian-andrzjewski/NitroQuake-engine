# Clipped alias transform evaluation-order parity

Status: the alias vertex transforms match the current C reference on the
representative exact-render suite. The complete renderer port and its long-run
stability gates remain in progress.

## `R_AliasTransformFinalVert` (2026-10-06)

The exact paired render suite found isolated framebuffer differences in
reduced-viewsize Demo 1 (frame 600), Demo 2 (frame 42), and Demo 3 (frame 643).
Selector isolation traced them to `R_AliasTransformFinalVert`.

Disassembly of the reference build's `_R_AliasTransformFinalVert_C` showed the
actual x87 sequence for each transformed row: multiply and accumulate the first
two vertex coordinates, add the row translation, then add the third coordinate
product. `R_AliasTransformFinalVert_asm486` had added the translation after all
three products. The alternate grouping can round differently in the x87
register format. The assembly now follows the reference sequence explicitly.
The lighting calculation keeps the reference's live x87 dot product through
the sign check and shaded multiply; it does not round-trip `lightcos` through a
single-precision temporary.

The `bench486` fixture now includes `x87-row-order`, with exact power-of-two
terms chosen so the reference sequence produces `1.0` while the old
translation-last sequence rounds to `0.0`. The host source test checks the
assembly row order, and the DOS fixture compares all output fields against the
C helper.

Evidence:

- `tools/test-rendering.py`: 16 tests passed, including the assembly-order
  assertion. `tools/test-rendering-reports.py`: 4 exact-report tests passed.
- `tools/bench-dos.ps1 -AliasTransformFinalOnly
  -AliasTransformFinalImplementation asm -NoBootstrap` passed in DOSBox-X
  configured as an i486. All five C/assembly fixtures matched, including
  `x87-row-order`. For that fixture, 200,000 calls measured 0.681809 s in C
  and 0.556209 s in assembly across the five-sample median.
- The post-link object audit inspected 103 objects and decoded 206,351
  instructions: zero enforced post-i486 instructions and zero unknown
  instructions. The one exempt MMX-pattern match remains the data-only CRC
  table. This report covered objects, not the linked executable.
- The exact six-scene paired run passed all six C and assembly scenarios on
  the same source-tree fingerprint. It compared 5,921 post-warmup frame
  checksums in total (964 each for four Demo 1 scenes, 980 for Demo 2, and
  1,085 for Demo 3); every stream matched. Each captured 320x200 PCX also
  matched all 64,000 palette indices and all 768 palette bytes.
- The formerly divergent captures were additionally checked at frames 600,
  42, and 643; each is exact. The shared source-tree fingerprint is
  `3146FF96C73326D007C11A726E8647724B2159AF17EEB1134FA80B35CF5AF1E9`.

The full paired report is
`out/render-parity-sixscene-x87-final-20261006/render-parity-result.json`;
the focused three-frame report is
`out/render-parity-alias-order-final-20261006/render-parity-result.json`.
The object audit is retained at
`out/profile-30cd6d87d1e638e4/isa-audit.json`.

## `R_AliasTransformVector` (2026-10-06)

The selectable bbox-projection path transforms all eight model-space bounding
box corners before clipping and projection. `R_AliasTransformVector` now
dispatches to `R_AliasTransformVector_asm486` when
`AliasBBoxProjectImplementation=asm`; the C function remains the reference and
the benchmark's explicit C side. The assembly uses the same x87 row operation
order established above: first two coordinate products, translation, then the
third product, with each result rounded when stored to the output vector.

The direct `bench486` coverage compares both three-float output vectors. The
fractional case produced exact result `1358244996`, and the adversarial
`x87-row-order` case produced `3492024607` in both implementations. The
source-level suite now has 17 passing tests, including checks for selector
dispatch, stack arguments, operation order, and the adversarial fixture.
`tools/test-build-dos.py` and `tools/test-isa-audit.py` also passed.

After this helper was added, the paired six-scene C/assembly run passed all
5,921 post-warmup frame checksums and six captured frames. All 320x200 captures
matched each of their 64,000 palette indices and 768 palette bytes. The source
fingerprint was
`58C74D852DC032ED2188CD58EB23FCCB10BA228AD7F7638FB7D5918DD6511DA0`.
The object audit inspected 103 objects and decoded 206,232 instructions, with
zero enforced above-i486 and zero unknown instructions; the known data-only
CRC-table exemption remains. This is object-level evidence, not a linked
executable instruction/dependency audit.

The paired report is
`out/render-parity-sixscene-aliasbbox-final-20261006/render-parity-result.json`;
the focused DOS benchmark and audit are in
`out/dos-bench-20261006-143404/bench-result.json`.

## `R_ConcatTransforms` (2026-10-06)

The alias setup path uses `R_ConcatTransforms` twice to build the model-to-view
matrix. `AliasMatrixCompositionImplementation=c|special|asm` now exposes a
selectable assembly replacement while preserving both the generic C reference
and the existing specialized C path. In `asm` mode, both concatenations call
`R_ConcatTransforms_asm486`.

The DJGPP reference object disassembly was used to set the x87 order. For each
matrix element it accumulates products zero and one, then product two; for the
translation column it adds the source-row translation between those operations
before adding product two. Each element is stored as a 32-bit float. The
assembly uses caller-saved integer registers and balances the x87 stack at each
return. The direct `bench486` cases compare all 12 outputs for fractional
matrices and a cancellation fixture that requires the reference translation
order and yields exactly `1.0`.

Evidence:

- `tools/bench-dos.ps1 -AliasBBoxProjectOnly -AliasBBoxProjectImplementation asm
  -AliasMatrixCompositionImplementation asm -NoBootstrap` passed in DOSBox-X
  configured as an i486. Matrix results were exact: fractional checksum
  `1689432555`; translation-order checksum `1423658175`. The four existing bbox
  projection cases and both bbox-vector transform cases also passed.
- The selected build audit inspected 103 objects and decoded 192,737
  instructions: zero enforced above-i486 instructions and zero unknown
  instructions. The one data-only CRC-table exemption remains.
- `tools/test-build-dos.py` passed with the new selector pinned; the rendering
  source suite has 18 passing checks, and the report comparator has 4 passing
  checks.
- The final six-scenario C/assembly paired run passed on the same source-tree
  fingerprint, `9C7D0D9B18A7BEA717254B9161FA5F51F2BD9BA9DC4434BE4D33E597B6051B44`.
  All six per-frame streams matched exactly across 5,921 post-warmup frames, and
  each captured 320x200 framebuffer matched all 64,000 palette indices and all
  768 palette bytes. The scenarios covered both Demo 1 display paths, fullbright,
  reduced viewsize, the Demo 2 entity workload, and the Demo 3 world workload.
- The candidate-profile object audit inspected 103 objects and decoded 206,520
  instructions, with zero enforced above-i486 and zero unknown instructions;
  that result was object-level evidence at the time; the linked-closure check
  below supersedes it for the current release.

The focused benchmark report is
`out/dos-bench-20261006-151117/bench-result.json`. The exact paired report is
`out/render-parity-sixscene-aliasmatrix-final-20261006/render-parity-result.json`.

Linked-closure follow-up (2026-10-06): the default i486 build now emits a GNU
linker map and runs `tools/isa-audit-linked.ps1` as a blocking post-link gate.
The normal release build passed with 338 source, CRT, and runtime objects,
209,707 mapped `.text` disassembly records, and zero enforced post-i486 or
non-exempt unknown instructions. The wrapper matched 207,062 instruction
opcode/ModRM sites against the final executable with zero mismatches. It also
reported 557 sites in four bounded data ranges, 139 standalone data-byte or
prefix sites, and 1,949 relocation-covered `.text` sites; all 209,707 records
are accounted for. The closure included 235 static runtime inputs across 331
mapped code contributions. Relocation listings, exact runtime member hashes,
the full executable disassembly, and per-site linked opcodes are retained beside
the executable in `out/dos-memasm-fillrectasm-zpointasm-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm/`.

The deliberate `asm486_experiments.obj` and `quake.exe` changes were then added
to the 104-entry i486 release pin. `tools/guard-i486-release.py` passed on the
recorded 103 objects plus executable.

This verifies the linked instruction stream and static runtime code for that
build configuration. It does not close the renderer conversion. Remaining
work includes the unported renderer paths, repeated full-suite and extended
temporal-soak runs on the final source, representative gameplay scenarios, and
execution in a genuine 486-compatible environment or a properly configured
486 emulator.
