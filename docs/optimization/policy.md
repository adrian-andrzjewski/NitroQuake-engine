# Optimization and build-number policy

This page is the current policy for optimization experiments and their
automatic build number. The complete experiment history remains in the
[ledger](../ledger/INDEX.md).

## Performance acceptance

Promote a performance candidate only when its pooled mean FPS is positive over
at least three matched, uninstrumented runs per variant. Pin the DOSBox-X
profile, executable settings, workload, frame count, and game data; retain all
samples and the spread. Require exact full per-frame color/Z streams or exact
framebuffer captures for affected workloads, plus a complete linked-image
strict i486 ISA audit. A non-positive mean, output mismatch, or ISA violation
rejects the candidate. There is no minimum percentage gain.

Optimize and qualify the renderer at 320x200. Instrumented profiles rank work
and help choose candidates; they are not release timing evidence. DOSBox-X
results are emulator measurements and do not qualify performance or reliability
on physical 486 hardware. See the benchmark suite's
[physical acceptance procedure](../../../benchmarks/docs/PHYSICAL-486-ACCEPTANCE.md).

## What counts as an attempt

An attempt is a separately documented implemented candidate or independent
variant that receives an accepted or rejected decision. Accepted C-to-assembly
ports count even when accepted for correctness rather than speed. Independent
follow-up and combined candidates count separately. Repeated samples,
verification of the same candidate, pure profiling, tests, bug repairs,
documentation, and unbuilt proposals do not count. Withdrawn candidates retain
their recorded outcome. Duplicate descriptions of one decision count once.

The inventory reads `docs/ledger/` and one preserved legacy source at
[`docs/history/ASM486-HANDOFF.md`](../history/ASM486-HANDOFF.md). Git history
supplies reachable deleted ledger records. The legacy map
[`tools/optimization-history-legacy.json`](../../tools/optimization-history-legacy.json)
resolves multi-attempt reports and duplicate write-ups by stable IDs and source
evidence; it does not contain a numeric offset. The retained early mip-0
specialization has a [stable ledger record](../ledger/2026-10-25-mip0-fully-flat-blocks-promoted.md).
Build numbering depends on
classified reports and ledger history, not commit hashes, so a clean
publication history does not change the count.

New `*-promoted.md`, `*-promotion.md`, `*-assembly-port.md`, and
`*-release-default.md` files contribute one accepted attempt; `*-rejected.md`
files contribute one rejected attempt. For reports containing multiple
decisions, add a stable marker for each candidate:

```markdown
<!-- optimization-attempt: 2026-11-18-example-a accepted -->
<!-- optimization-attempt: 2026-11-18-example-b rejected -->
```

Use `<!-- optimization-attempts: none -->` for evidence-only reports.
Repeated IDs count once; conflicting outcomes, missing classifications, or
missing source evidence fail inventory generation. Do not edit the generated
number by hand.

## Displayed number and reproducibility

The console displays two lines:

```text
NitroQuake v0.999
Build 888
```

The current inventory derives `Build 888` from 494 accepted and 394 rejected
attempts, including the early mip-0 specialization recorded
in the ledger. The builder recalculates this value from the current
checkout each time. The count can change only when a distinct attempt is
recorded or its reviewed classification changes. Unrelated commits, builds,
output paths, and worktree locations do not affect it.

The build fingerprint and product build ID identify source and resolved build
configuration separately. The manifest also records the Git revision, attempt
breakdown, and inventory digest. An inventory change invalidates build
freshness, so the next runner requires a rebuild.

The supported numbered builder requires Python 3.9+ and complete, non-shallow
Git history. It fails on a shallow clone or an unclassified report rather than
silently returning a partial number. Use:

```powershell
python tools/optimization-history.py
pwsh -NoProfile -File tools/test-build-number.ps1
```

The first command prints the derived inventory summary. The focused test checks
classification, deduplication, deleted and renamed records, clone behavior,
and the generated header.

## Historical policy

The old optimization plan and conversion survey are archived under
[`docs/history/`](../history/INDEX.md). Their dated thresholds, source counts,
and candidate claims do not override this policy or current profiles.
