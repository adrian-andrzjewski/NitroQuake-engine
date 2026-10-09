# 84-selector alias-control integration checkpoint (2026-10-09)

## Candidate identity and strict ISA gate

The opt-in `i486-asm-selectable-84` profile extends the strict 83-selector
profile with the already reviewed `AliasControlImplementation=asm` pipeline.
All 84 declared selectors are set to assembly. The candidate executable
SHA-256 is `6C4ABD5A2F902C2F6853C369BB4D08C9A21F0BCAD4021BB957681529FD15E609`.

The C reference and candidate were built from source-tree fingerprint
`7C94D1854C15A26AFE15725E2FE799596C02D2D848978247A5692BCDB964C8EB` and ran
under DOSBox-X's i486 profile. Exact source proofs covered 123 project objects
and 235 installed runtime objects. The complete executable gate passed 244,632
relocated instructions, 529 startup code rows and 9,207 CWSDPMI instructions,
with zero post-i486 instructions, unknowns, exemptions or opcode mismatches.

## Exact entity-scene parity

The reference and candidate each completed one `demo2-entity-workload` run.
Both produced 986 frame checksums. After six warmup frames, all 980 compared
checksums matched exactly. The selected frame-169 320x200 indexed framebuffer
and palette also matched exactly: zero of 64,000 pixel indices and zero
palette bytes differed.

The reference ran at 12.781 FPS and the candidate at 12.702 FPS in this one
measurement, about 0.6% slower. This is not a material regression, and
performance is not the completion criterion. The paired report is
`out/render-parity-selectable-84-entity-strict-20261009/render-parity-result.json`.

## Ownership impact and remaining C paths

The candidate's ownership inventory reports 613 renderer entries, 370 directly
reachable entries and 20 directly reachable renderer C functions. It no longer
reports the five alias-control C functions present in the 83-selector scan.
Directly reachable indirect transfers fell from 148 sites in 63 entries to 54
sites in 42 entries. The current inventory also lists 40 unresolved direct
callees; this includes runtime imports and is not a count of 40 renderer C
functions. The report explicitly is not a complete call graph.

The remaining direct C inventory includes `R_SetupFrame`, the optional
`R_ZDrawSubmodelPolys` C dispatch wrapper, renderer debug/stat paths, and
BENCH486 instrumentation hooks. Initialization/support ownership, indirect
targets and these remaining C paths still need review. See
`out/renderer-ownership-selectable-84-strict-20261009.json`.

## Validation boundary

The 54-test rendering suite and two ownership-scanner tests pass. The exact
paired run covers the alias-heavy entity workload, not every renderer scenario.
Broader scene coverage, long-running stability/corruption checks, full
renderer ownership, and human visual/gameplay acceptance remain open. DOSBox-X
with `CpuTarget=i486` is representative emulator evidence, not a genuine
486-hardware run. The normal C selection remains available as the reference.

## Run the combined alias-control profile

From the `quake` directory, use a fresh output root for each rerun:

```powershell
.\tools\render-parity-dos.ps1 `
  -ReferenceProfile 'tools/renderer-profiles/i486-c-reference.json' `
  -CandidateProfile 'tools/renderer-profiles/i486-asm-selectable-84.json' `
  -Scenario demo2-entity-workload -RunsOverride 1 `
  -OutputRoot 'out/render-parity-selectable-84-entity-strict-20261009' `
  -CpuTarget i486 -TimeoutSeconds 600 -NoBootstrap
```
