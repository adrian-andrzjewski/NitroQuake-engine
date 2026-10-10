# NitroQuake documentation

Operational documents, one experiment ledger, and a rule about how to cite them.

## Read in this order

1. **[`../BUILD-DOS.md`](../BUILD-DOS.md)** - operational reference. Building the
   DOS renderer from Windows, the probe switches, the timedemo gate, what each
   script enforces, and the committed default baseline. Start here to *run*
   anything.
2. **[`../RENDERING-VALIDATION.md`](../RENDERING-VALIDATION.md)** - deterministic
   rendering scenarios, image comparison tolerances, and failure artifacts.
3. **[`../ASM486-HANDOFF.md`](../ASM486-HANDOFF.md)** - the state of record. The
   convergence statement, the current baseline and evidence, the promoted and
   reverted change tables, the standing decisions, and the open work. Start
   here to *know* something.
4. **[`ledger/INDEX.md`](ledger/INDEX.md)** - all the dated experiments, indexed
   by day and by renderer region. Start here to find out *whether something was
   tried*.
5. **[`OPTIMIZATION-PLAN.md`](OPTIMIZATION-PLAN.md)** - the five decisions that
   govern the work, and why each was corrected. Read before proposing an
   optimisation.

## The documents

| Document | What it is | Size |
|---|---|---:|
| [`../BUILD-DOS.md`](../BUILD-DOS.md) | Operational build, run, probe and tooling reference | ~1,460 lines |
| [`../ASM486-HANDOFF.md`](../ASM486-HANDOFF.md) | State of record: convergence, baseline, decisions, next steps | ~1,580 lines |
| [`../BENCHMARK-COMPARISON.md`](../BENCHMARK-COMPARISON.md) | Current build against the supplied executables | 139 lines |
| [`../VIDEO-DOS-VALIDATION.md`](../VIDEO-DOS-VALIDATION.md) | DOS VESA default validation, 2026-09-26 | 127 lines |
| [`../RENDERING-VALIDATION.md`](../RENDERING-VALIDATION.md) | Deterministic render scenarios, PCX comparison and temporal checks | New |
| [`ISA-VERIFICATION.md`](ISA-VERIFICATION.md) | Source-bound object, executable, startup and provider verification | New |
| [`RENDERER-ASSEMBLY-CONVENTIONS.md`](RENDERER-ASSEMBLY-CONVENTIONS.md) | Assembly ownership, ABI, arithmetic, modules and acceptance rules | New |
| [`RENDERER-COMPLETION-GAPS.md`](RENDERER-COMPLETION-GAPS.md) | Accepted conversions and remaining ownership/scenario gates | New |
| [`ledger/2026-10-10-d-drawzspans-assembly-parity.md`](ledger/2026-10-10-d-drawzspans-assembly-parity.md) | `D_DrawZSpans` exact C/assembly depth-buffer parity and i486 audit | New |
| [`ledger/2026-10-10-screen-center-string-assembly-parity.md`](ledger/2026-10-10-screen-center-string-assembly-parity.md) | `SCR_DrawCenterString` C/assembly parity and i486 audit | New |
| [`ledger/2026-10-10-d-drawparticle-assembly-port.md`](ledger/2026-10-10-d-drawparticle-assembly-port.md) | Existing `D_DrawParticle` assembly path, C oracle and exact parity evidence | New |
| [`ledger/2026-10-09-r-blobexplosion-assembly-port.md`](ledger/2026-10-09-r-blobexplosion-assembly-port.md) | `R_BlobExplosion` traceability and pending acceptance gates | New |
| [`../DPMI-HDPMI32.md`](../DPMI-HDPMI32.md) | CWSDPMI vs HDPMI32 host experiment | 111 lines |
| [`OPTIMIZATION-PLAN.md`](OPTIMIZATION-PLAN.md) | The five governing decisions | 384 lines |
| [`PURE-ASSEMBLER-CANDIDATES.md`](PURE-ASSEMBLER-CANDIDATES.md) | Which functions are worth hand-writing, and which are not | 359 lines |
| [`VESA-320X200-PERFORMANCE-PLAN.md`](VESA-320X200-PERFORMANCE-PLAN.md) | VESA mode-set performance plan | 124 lines |
| [`ledger/`](ledger/INDEX.md) | 550 ledger headings across 108 files | 12,581 lines |

The two documents that grew past 5,000 and 3,000 lines were split on
2026-10-03. Nothing was reworded: the experiment log that sat under a single
`## Current state` heading in `ASM486-HANDOFF.md`, and the result write-ups that
sat inside `BUILD-DOS.md`, moved verbatim into `ledger/`. Sections that existed
in both documents were recorded once, in the ledger, and the copy in
`BUILD-DOS.md` became a pointer.

## The citation rule

**Cite by heading, never by line number.** This is not a style preference; it is
a recorded failure. An audit on 2026-10-03 found ten of twelve line-number
citations in this material wrong. Each had been verified when written, and each
was invalidated by a later insertion above it in the same file - the project has
now paid for it three separate ways. The rule, its evidence and its two
load-bearing anchors are in `../ASM486-HANDOFF.md` under "Process rules".

In practice:

> good: `docs/ledger/2026-10-03-clamp-fusion-and-the-1.0-rate.md`, under
> "The clamp fusion is measured at **0.0000%**".
>
> bad: `ASM486-HANDOFF.md:1851`.

Across files, name the file *and* the heading. A bare `ASM486-HANDOFF.md`
citation is how a reader ends up reading a probe table when the text meant a
different entry entirely.

`tools/doc-structure-check.ps1` enforces this, and it is the first gate in
`tools/run-tests.ps1`. It reports a line-number citation even inside a code
span; the only exemption is a "> bad:" line quoting the examples above.

