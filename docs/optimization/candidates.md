# Choosing optimization candidates

Start from measured work in the
[current-source engine profile](../../../benchmarks/docs/results/current-source-engine-profile-2026-11-17.md),
then check the [optimization ledger](../ledger/INDEX.md) for prior attempts and
the current [renderer status](../architecture/renderer-status.md). The profile
is a DOSBox-X attribution capture from game revision `ae559389c9d4`; it is useful for
ranking work, but its single uninstrumented sample per workload does not
establish repeatable performance.

The report measured texture spans, surface-cache work, and Z spans across the
tested scenes. It proposed those shared paths for investigation and accepted no
candidate. Refresh the profile when source, selectors, or representative
workloads change materially.

## Qualification sequence

1. Confirm the routine is active in the current release profile and appears in
   an appropriate current workload.
2. Search the ledger for earlier variants, combined changes, correctness
   failures, and measured regressions.
3. State one narrow hypothesis and keep the C implementation as the reference.
4. Require exact affected-output parity and the linked-image i486 ISA audit.
5. Compare at least three matched uninstrumented runs per variant at 320x200;
   retain samples, spread, executable identity, and workload provenance.
6. Record the outcome in the ledger with a stable attempt identity when the
   report contains multiple decisions.

Apply the full [optimization policy](policy.md). Do not infer assembly coverage
from ISA compliance, or physical 486 performance from DOSBox-X timings.

The [historical pure-assembler survey](../PURE-ASSEMBLER-CANDIDATES.md) is
preserved for its source notes. Its broad candidate list and dated conclusions
are not a current priority ranking.
