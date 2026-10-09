# 76-selector combined assembly profile acceptance (2026-10-09)

## Strict i486 executable gate

The strict paired run compared `i486-c-reference` with
`i486-asm-selectable` at `CpuTarget=i486`, one run each across all six committed
render scenarios. The candidate profile selects assembly for 76 of its 77
selectors; `TransformFrustumImplementation` remains C. The reference and
candidate suites passed and their source-tree fingerprints matched
(`6FE9839E606AF326873711D4A104BBE4722FE787BA4C112B6B2C9A96944C4`).

The candidate executable SHA-256 was
`2E5AA47519B02E2848A4CDE06411778640489A16D6B77AC0D4D2049294593B49`. Its
complete gate checked 223,428 relocated instructions, 529 startup code rows and
9,207 maintained CWSDPMI instructions. The 358 project and runtime objects
passed exact source proofs (123 project objects and 235 installed runtime
objects). The linked executable mapped 345 source-bound contributions and
verified 1,742 relocated ranges. All gates reported zero post-i486 instructions,
unknown encodings, instruction exemptions or skipped bytes. The startup proof
bound 1,660 loaded bytes; the provider proof covered one runtime branch variant
with zero exemptions.

## Six-scene exact parity

All six deterministic scenarios passed: VESA, VGA, fullbright, reduced
viewport, entity workload and alternate world workload. After six warmup frames
per run, the pair compared 5,921 frame checksums with no mismatches. Each
frame-169 320x200 indexed capture and all 768 palette bytes matched exactly:
six captures, zero pixel-index differences and zero palette-byte differences.
The pair report is
`out/render-parity-selectable-strict-20261009/render-parity-result.json`.

The assembly candidate measured 0.6% to 2.1% slower across these workloads.
This is a regression observation, not a completion criterion; the result shows
no catastrophic slowdown in this suite.

## Remaining ownership and scope

The matching ownership inventory is
`out/renderer-ownership-selectable-strict-20261009.json`. Across 380 directly
reachable entries it still finds 63 renderer C functions, 40 reachable entries
containing 121 indirect call/jump instructions, and 26 unresolved direct
callees. This direct-call inventory is not a complete call graph; indirect
targets and renderer initialization/debug ownership need separate review.

This result validates the combined 76-selector profile, not a pure-assembly
renderer. The separately audited frustum assembly candidate has not yet been
combined with these 76 selectors. Extreme clipping/camera cases, broader
gameplay, long-run stability, corruption checks and complete indirect-target
closure remain open. See the
[renderer completion gaps](../RENDERER-COMPLETION-GAPS.md) and the
[frustum candidate acceptance](2026-10-09-frustum-transform-assembly-port.md).
