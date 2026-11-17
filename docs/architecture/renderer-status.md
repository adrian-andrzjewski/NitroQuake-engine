# Renderer implementation status

NitroQuake retains C reference implementations alongside selectable assembly
paths. This supports correctness comparisons and focused measurement while the
DOS release remains constrained to the i486 instruction set.

## Current source and verification

The supported profiles are maintained under
[`tools/renderer-profiles/`](../../tools/renderer-profiles/), and the ordered
selector table is maintained by the game build tooling. The host verification
suite checks selector resolution, release inventories, and C-reference build
contracts. At the 2026-11-17 selector-matrix checkpoint, all 138
assembly-capable release selector values were validated.

The `i486-release` build performs source-bound checks and a complete linked
image audit. These checks prove the audited image stays within the supported
instruction policy. They do not measure how much code is handwritten assembly,
prove the whole renderer call graph is assembly-owned, or prove visual parity.

## Evidence status

| Question | Current evidence | Limit |
|---|---|---|
| Does the supported i486 build pass its compiler and ISA gates? | Build and linked-image audits in the game build workflow | Does not establish runtime behavior on every DOS or DPMI host |
| Are selectable implementations covered by host checks? | Selector/profile and inventory tests | Coverage of a setting does not prove end-to-end scene parity |
| Is C/assembly output identical? | Deterministic fixture and emulator replay records | Each result applies to its stated source revision and workloads |
| Which work is worth investigating? | [Current-source profile](../../../benchmarks/docs/results/current-source-engine-profile-2026-11-17.md) | Single uninstrumented sample per group; attribution is instrumented and emulator-specific |
| Is release performance accepted on a physical 486? | [Acceptance procedure](../../../benchmarks/docs/PHYSICAL-486-ACCEPTANCE.md) | Physical target qualification remains open |

The profile report identifies texture-span, surface-cache, and Z work as
measurable areas for further investigation. It records no accepted change.
Use the [candidate workflow](../optimization/candidates.md) and
[optimization policy](../optimization/policy.md) before proposing a port or
performance change.

## Scope of the archived gap survey

The former [renderer completion gaps](../RENDERER-COMPLETION-GAPS.md) page is a
dated snapshot. Its selector counts and ownership scans describe older source
revisions and must not be used as the current inventory. The full record is
preserved in [history](../history/RENDERER-COMPLETION-GAPS.md).
