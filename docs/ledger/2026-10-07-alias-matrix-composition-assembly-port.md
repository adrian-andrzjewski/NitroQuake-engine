# Alias transform matrix composition assembly path

## `R_ConcatTransforms` call sites

`AliasMatrixCompositionImplementation=c|special|asm` selects the C reference,
the existing diagonal-matrix C specialization, or the assembly matrix path.
Under `asm`, `R_AliasSetViewMatrix_asm486` copies the right/up/forward basis
vectors and flips the up-vector sign bits, then both matrix products in
`R_AliasSetUpTransform` call `R_ConcatTransforms_asm486`. The C function keeps
its original calls and remains the reference. `R_ConcatTransforms_asm486`
preserves the reference x87 operation order for each output element. Both C
choices remain available; assembly is the i486 default after exact comparison.

## Direct fixtures and i486 audit

The DOSBox-X `cputype=486` fixture suite compared the fractional and
translation-order matrices exactly. Their checksums were `1689432555` and
`1423658175`. Three view-matrix fixtures also matched exactly: fractional
(`3542091135`), wide range (`840907921`), and signed zero (`1389475662`). The
fourth matrix value in each row retained its sentinel, matching the C
`VectorCopy` stores.

The selected object audit examined 103 objects and 181,298 instruction sites;
the full object closure examined 338 objects and 222,810 sites. The linked
audit verified 220,094 opcodes across 235 runtime inputs and 333 executable
`.text` ranges. No enforced instruction above i486 was found. The known
third-party runtime/data exemptions remain listed in the audit.

The direct fixture report is
`out/dos-bench-20261007-044723/bench-result.json`; object and linked reports are
under `out/profile-d4c88cfb82779d9c/`.

## Two-repeat Demo 2 parity

The focused `i486-asm-alias-matrix` profile changes only
`AliasMatrixCompositionImplementation` from the C-reference profile. Both
profiles used source-tree fingerprint
`B53D92990A02A8DD4F47A2EAF7A0345746A69F2C8D2662677DE658EA3D029C94` and
completed two 985-frame Demo 2 runs. All 980 post-warmup frame checksums matched
on both repeats. Each captured 320x200 frame matched all 64,000 palette indices
and all 768 palette bytes. The result is
`out/render-parity-20261007-044916/render-parity-result.json`.

The diagnostic medians were 12.784987 fps for the C reference and 12.746767 fps
for assembly, about 0.30% lower in this pair. This timing is not a performance
claim; exact parity and the i486 opcode gate are the promotion criteria for
this stage.
