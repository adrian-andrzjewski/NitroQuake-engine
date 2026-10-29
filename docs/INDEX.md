# NitroQuake documentation

Use this page to find the maintained workflow guides, implementation rules, and
historical evidence. Each document below has one clear subject; dated reports
remain available as evidence and are not the current source of policy.

## Current workflow

| Need | Start here |
|---|---|
| Build, run, and inspect the DOS renderer; use probes and timedemos | [`../BUILD-DOS.md`](../BUILD-DOS.md) |
| Run deterministic rendering checks and review image differences | [`../RENDERING-VALIDATION.md`](../RENDERING-VALIDATION.md) |
| Verify selector ownership, object code, linked binaries, and allowed ISA | [`ISA-VERIFICATION.md`](ISA-VERIFICATION.md) |
| Read the current i486 status, accepted and reverted work, baseline, and open work | [`../ASM486-HANDOFF.md`](../ASM486-HANDOFF.md) |
| Read optimization policy, performance acceptance, and current decisions | [`OPTIMIZATION-PLAN.md`](OPTIMIZATION-PLAN.md) |
| Find a dated experiment and its recorded result | [`ledger/INDEX.md`](ledger/INDEX.md) |

## Implementation references

| Subject | Document |
|---|---|
| Assembly module ownership, ABI, register use, and arithmetic conventions | [`RENDERER-ASSEMBLY-CONVENTIONS.md`](RENDERER-ASSEMBLY-CONVENTIONS.md) |
| Remaining assembly ownership and validation gates | [`RENDERER-COMPLETION-GAPS.md`](RENDERER-COMPLETION-GAPS.md) |
| Functions considered for full assembler conversion | [`PURE-ASSEMBLER-CANDIDATES.md`](PURE-ASSEMBLER-CANDIDATES.md) |
| VESA 320x200 performance proposal and its acceptance gates | [`VESA-320X200-PERFORMANCE-PLAN.md`](VESA-320X200-PERFORMANCE-PLAN.md) |

## Benchmark and historical references

These documents record a specific comparison, experiment, or checkpoint. Use
the current workflow guides above for present-day instructions and defaults.

| Record | Scope |
|---|---|
| [`../BENCHMARK-COMPARISON.md`](../BENCHMARK-COMPARISON.md) | Comparison with the supplied DOS executables |
| [`../VIDEO-DOS-VALIDATION.md`](../VIDEO-DOS-VALIDATION.md) | Dated DOS VESA validation from 2026-09-26 |
| [`../DPMI-HDPMI32.md`](../DPMI-HDPMI32.md) | CWSDPMI and HDPMI32 host experiment |
| [`../RESTART-HANDOFF-20261007.md`](../RESTART-HANDOFF-20261007.md) | Restart checkpoint from 2026-10-07 |

The root [`../readme.txt`](../readme.txt) and [`../gnu.txt`](../gnu.txt) are
upstream project documentation and licensing material.

## Evidence and citations

**Cite by heading, never by line number.** An audit on 2026-10-03 found ten of
twelve line-number citations in this material wrong. Later insertions had
invalidated each citation. The recorded rule and its rationale are in
[`../ASM486-HANDOFF.md`](../ASM486-HANDOFF.md) under “Process rules”.

For a historical result, cite both the file and its heading. The ledger index
links each record file and reports its subsection count; the file itself holds
the full evidence. Its date and measured result do not make it a current
baseline. The [`ledger/INDEX.md`](ledger/INDEX.md) also contains a curated
cross-reference by renderer region.

> good: `docs/ledger/2026-10-03-clamp-fusion-and-the-1.0-rate.md`, under
> “The clamp fusion is measured at **0.0000%**”.
>
> bad: `ASM486-HANDOFF.md:1851`.

`tools/doc-structure-check.ps1` checks citations, relative Markdown links,
heading levels, and the ledger file inventory with its per-file subsection
counts. It is the first gate in `tools/run-tests.ps1`.
