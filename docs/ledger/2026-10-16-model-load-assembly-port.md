# `Mod_LoadModel` i486 assembly port (2026-10-16)

## Scope

`Mod_LoadModel`, reached by `Mod_Extradata` when an alias model is absent from
the cache, now uses an i486 assembly dispatcher in the existing
`AliasControlImplementation=asm` profile. The C implementation remains
available in the C reference profile. `asm-fixture` builds also retain it as
the direct parity oracle. Compile-time ABI assertions pin the 32-bit `model_t`
layout and the fields read or written by assembly.

The dispatcher handles alias cache hits, already-loaded non-alias models,
missing optional and required files, file-base setup, alias and sprite header
dispatch, and the brush fallback. The direct C/ASM fixture passes all seven
cases: alias cache hit, alias cache miss, sprite dispatch, brush fallback,
loaded brush fast path, missing optional model and missing required model.
Result fields, helper calls, cache state and error arguments match exactly.
Run it with:

```powershell
.\tools\bench-dos.ps1 `
  -AliasModelLoadOnly -AliasControlImplementation asm-fixture `
  -SkipIsaAudit -NoBootstrap -TimeoutSeconds 180
```

## Strict i486 build

The production all-assembly selector build used:

```powershell
.\tools\build-dos.ps1 -Benchmark -AliasControlImplementation asm -NoBootstrap
```

The complete executable gate passed for build root
`out/profile-907251d478dae3d7`: 278,242 relocated instructions, 409
source-bound code contributions, 2,169 CODE ranges, 26 DATA ranges, 529
startup CODE rows and 9,207 CWSDPMI provider instructions. There were zero
above-i486 instructions, unknown instructions or exemptions. Exact source
proofs covered 151 project objects and 235 installed runtime objects; all 386
native or annotated object proofs passed. The linked report is
`out/profile-907251d478dae3d7/isa-qbench/isa-audit-linked.json`.

## Renderer parity

The final source-tree fingerprint was
`55DA567ED18E093DA1F019F7496601FA7B773E366A1B2E7BA1C3D869A0E01D2C` for both
profiles. In `demo2-entity-workload`, the C reference and all-assembly
candidate matched all 980 checksums after six warmup frames. Their frame-169
320x200 indexed captures and palettes matched exactly: zero pixel-index or
palette-byte differences. Both final checksums were `1887495667`.

This one run measured 12.241803 FPS for C and 12.205261 FPS for assembly.
Treat these as run-specific measurements, not a performance conclusion. The
parity runner used `-VisualParityOnly`, so it skipped its own ISA audit; the
separate strict production build above passed the complete executable gate.
The pair report is
`out/render-parity-alias-model-final-20261016/render-parity-result.json`.

## Remaining limits

An earlier standalone `-AliasControlOnly` DOSBox-X run timed out without
writing a benchmark report. The new isolated model-load fixture and the actual
renderer parity pair both pass, but that broader standalone benchmark has no
new accepted result. This is one model-loading dispatcher slice; additional
3D procedures, remaining renderer C paths, broader scene coverage, long-run
stability and human visual/gameplay acceptance remain open. DOSBox-X results
are emulator evidence, not a physical 486 test.
