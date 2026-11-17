# NitroQuake documentation

This index separates maintained guidance from dated evidence. Build and
verification rules live with the game checkout; emulator workflows and
performance reports live in the sibling benchmark repository.

## Start here

| Need | Read |
|---|---|
| Build the DOS game and run game-side checks | [Build guide](../BUILD-DOS.md) |
| Understand the current engine and repository boundaries | [Current architecture](architecture/current-state.md) |
| Review renderer implementation and evidence status | [Renderer status](architecture/renderer-status.md) |
| Verify source and linked-image i486 compatibility | [ISA verification](ISA-VERIFICATION.md) |
| Change or add renderer selectors | [Selector change checklist](SELECTOR-CHANGE-CHECKLIST.md) |
| Review C/assembly conventions and ABI rules | [Renderer assembly conventions](RENDERER-ASSEMBLY-CONVENTIONS.md) |
| Understand memory and stack limits | [Memory budget](memory-budget.md) |

## Optimization work

| Need | Read |
|---|---|
| Performance acceptance, attempt definitions, and build numbering | [Optimization policy](optimization/policy.md) |
| Select and qualify a new renderer candidate | [Candidate workflow](optimization/candidates.md) |
| Find an accepted or rejected experiment | [Optimization ledger index](ledger/INDEX.md) |

The build number is calculated from the distinct accepted and rejected
optimization attempts in the ledger and its documented legacy source. It is
not a commit count or a manually maintained release counter. The policy page
documents the current inventory and the deterministic classification rules.

## Benchmarking and dated results

The [benchmark suite guide](../../benchmarks/README.md) documents DOSBox-X setup,
runtime commands, and input data. Use its [documentation index](../../benchmarks/docs/INDEX.md)
to find validation procedures and reports. The
[2026-11-17 current-source profile](../../benchmarks/docs/results/current-source-engine-profile-2026-11-17.md)
is a dated attribution capture; it ranks work but is not repeated timing or
physical-486 evidence.

## Historical records

[History index](history/INDEX.md) lists preserved planning documents,
assessments, and handoffs. Historical records retain the decisions and evidence
available when written; they do not override current policy or current source.
The complete experiment records remain in the [optimization ledger](ledger/INDEX.md).

The upstream [Quake readme](../readme.txt) and [GNU license](../gnu.txt) remain
at the game repository root.

## Evidence and citations

Cite a document by its heading, never by line number. The
[`doc-structure-check.ps1`](../tools/doc-structure-check.ps1) gate checks
Markdown links, heading structure, citations, and the exact ledger inventory.
The ledger index links each experiment and includes a renderer-region
cross-reference.
