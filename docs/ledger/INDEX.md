# Experiment ledger

Every dated measurement, rejection and correction from the 486 optimization work:
**89 headings**, all of which until 2026-10-03 sat under a single `## Current state`
heading in `ASM486-HANDOFF.md`. The prose was moved verbatim; nothing was reworded.

Read the entry by its heading, never by a line number - see the process rule in
`ASM486-HANDOFF.md` under "Process rules". Ten of twelve line-number citations in
this material were found wrong by an audit on 2026-10-03, each invalidated by a
later insertion above it.

## Files

| File | Entries | Region |
|---|---:|---|
| [`2026-09-26-reproducibility-baseline.md`](2026-09-26-reproducibility-baseline.md) | 1 | harness / method |
| [`2026-09-28-span-micro-experiments.md`](2026-09-28-span-micro-experiments.md) | 8 | alias |
| [`2026-09-29-alias-and-surface-block-experiments.md`](2026-09-29-alias-and-surface-block-experiments.md) | 7 | alias |
| [`2026-09-29-harness-and-cost-model.md`](2026-09-29-harness-and-cost-model.md) | 12 | world-bsp |
| [`2026-09-30-harness-fidelity-and-sourcing.md`](2026-09-30-harness-fidelity-and-sourcing.md) | 5 | harness / method |
| [`2026-10-01-attribution-corrections.md`](2026-10-01-attribution-corrections.md) | 5 | alias |
| [`2026-10-02-edge-scan-and-texture-spans.md`](2026-10-02-edge-scan-and-texture-spans.md) | 4 | harness / method |
| [`2026-10-02-surf8-bundle-and-promotion.md`](2026-10-02-surf8-bundle-and-promotion.md) | 5 | renderface |
| [`2026-10-03-alias-glue-closure.md`](2026-10-03-alias-glue-closure.md) | 3 | ISA / i386 |
| [`2026-10-03-clamp-fusion-and-the-1.0-rate.md`](2026-10-03-clamp-fusion-and-the-1.0-rate.md) | 1 | harness / method |
| [`2026-10-03-isa-audit-and-i386-codepath.md`](2026-10-03-isa-audit-and-i386-codepath.md) | 2 | ISA / i386 |
| [`2026-10-03-region-pricing-sweep.md`](2026-10-03-region-pricing-sweep.md) | 4 | z-spans |
| [`2026-10-04-toolchain-refactor.md`](2026-10-04-toolchain-refactor.md) | 10 | harness / method |
| [`2026-09-29-offline-precomputation-pass.md`](2026-09-29-offline-precomputation-pass.md) | 2 | harness / method |
| [`timedemo-baseline-history.md`](timedemo-baseline-history.md) | 6 | harness / method |
| [`microbenchmark-results.md`](microbenchmark-results.md) | 14 | harness / method |

## By region

The files are ordered by day, which is how the work happened. This table is the
other axis: one row per renderer region, newest entry first.

### alias

- `measured` [The alias-glue C block is **0.1703% of frame, 3.4x the gate** — the first price that region has ever had,...](2026-10-03-alias-glue-closure.md)
- `measured` [`alias-glue` reads 6.01% of frame and is **2.29%** — 62% of it is the profiler measuring itself (2026-10-...](2026-10-03-alias-glue-closure.md)
- `negative` [Aff8 AGI interlock investigation (2026-09-29) — null result, selector removed](2026-09-29-harness-and-cost-model.md)
- `superseded` [Alias-raster C-glue instrumentation (2026-09-29) — **SUPERSEDED 2026-10-01, the numbers below are instrum...](2026-09-29-harness-and-cost-model.md)
- `measured` [Alias attribution corrected (2026-10-01) — the profiler was measuring itself; C glue is 3.1x cheaper than...](2026-10-01-attribution-corrections.md)
- `measured` [Alias-raster child breakdown (2026-09-29) — C cost is 2.86%, not the predicted <1%](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Alias sub-node instrumentation and the alias cost breakdown (2026-09-29)](2026-09-29-alias-and-surface-block-experiments.md)
- `rejected` [Aff8 16-byte code-alignment experiment (2026-09-29) — rejected and reverted](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Monster gib trail zero-XY experiment (2026-09-29)](2026-09-28-span-micro-experiments.md)
- `measured` [Alias-span address-update experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Alias-model prepare source-cursor experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)

### edge-scan

- `closed` [The per-edge dispatch remainder, decomposed (2026-10-02, second pass) — `edge-scan` is now 78% mapped and...](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The complete `edge-scan` map — 78% of the bucket accounted for](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [A fifth probe trap, and it is a different failure from the other four](2026-10-02-edge-scan-and-texture-spans.md)
- `rejected` [What this does and does not license](2026-10-02-edge-scan-and-texture-spans.md)
- `rejected` [`edge-scan` cannot be decomposed (2026-10-01) — the arithmetic forbids it, do not retry](2026-10-01-attribution-corrections.md)

### harness / method

- `measured` [The duplication, measured](2026-10-04-toolchain-refactor.md)
- `measured` [Four defects that were producing a wrong...](2026-10-04-toolchain-refactor.md)
- `measured` [Two runners tested whatever binary was l...](2026-10-04-toolchain-refactor.md)
- `measured` [The generated DOSBox config was not repr...](2026-10-04-toolchain-refactor.md)
- `measured` [One selector, written five times](2026-10-04-toolchain-refactor.md)
- `measured` [Six latent defects in the source-level I...](2026-10-04-toolchain-refactor.md)
- `measured` [What is now a gate that was not](2026-10-04-toolchain-refactor.md)
- `measured` [A checklist moved out of a script's tail](2026-10-04-toolchain-refactor.md)
- `measured` [Result](2026-10-04-toolchain-refactor.md)
- `measured` [Dead code, and one that was not](2026-10-04-toolchain-refactor.md)
- `measured` [The clamp fusion is measured at **0.0000%**, and the probe that explains it says **1.0 cycle per instruct...](2026-10-03-clamp-fusion-and-the-1.0-rate.md)
- `measured` [`edge-scan` decomposed by dead-scratch probe — pass 1 of 2 (2026-10-02): six probes, and **the closure be...](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The census, and what it overturned](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The six probes](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Decision 3's 0.66 rate is wrong — the risk was prospective, not realised](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Four probe traps, each of which cost a build-and-run cycle](2026-10-02-edge-scan-and-texture-spans.md)
- `closed` [What is NOT closed, and what is inadmissible](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The Z-span integer probe, measured and retired (2026-10-02) — the harness charges 1.0 cycles per instruct...](2026-10-02-surf8-bundle-and-promotion.md)
- `measured` [Harness integrity and the measured fidelity result (2026-09-30) — the gate problem is now measured, not a...](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [Legal sources for a 486 machine ROM (not pursued here)](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [Sourcing research: the legal-BIOS question, answered (2026-09-30)](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [86Box, verified against source (2026-09-30) — the best ROM-free candidate, still disqualified](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [`Turbulent8` setup precompute (2026-09-30) — priced with a bit-exact dead-scratch probe; 0.034% addressab...](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [Static 486 cost model (2026-09-29) — built; it disqualifies all three blind axes and promotes nothing](2026-09-29-harness-and-cost-model.md)
- `measured` [E3 and E4 disposition (2026-09-29)](2026-09-29-harness-and-cost-model.md)
- `rejected` [Hot-code clustering (2026-09-29) — rejected, and object granularity is the blocker](2026-09-29-harness-and-cost-model.md)
- `measured` [What this harness can and cannot measure (2026-09-29)](2026-09-29-harness-and-cost-model.md)
- `measured` [Where this leaves the project](2026-09-29-harness-and-cost-model.md)
- `measured` [`renderface` priced by premise (2026-10-01) — large pool, but the x87 in it is essential work; no probe b...](2026-10-01-attribution-corrections.md)
- `measured` [Current parity-gated closure (2026-09-28)](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Current reproducibility note (2026-09-26)](2026-09-26-reproducibility-baseline.md)

### ISA / i386

- `measured` [The 161 `imul r32,r/m32` sites are **not** strength-reducible — three approaches refuted by measurement (...](2026-10-03-isa-audit-and-i386-codepath.md)
- `measured` [A separate i386 codepath exists, and the shipped "486" binary needs a Pentium — both from one root cause ...](2026-10-03-isa-audit-and-i386-codepath.md)
- `closed` [The alias-glue block is **63 instructions, minimal, and 5.5x the gate** — closed from its own disassembly...](2026-10-03-alias-glue-closure.md)

### lightmap

- `measured` [`R_BuildLightMap` is **0.06% of frame, not 7.5%** — and a real loop-invariant hoist in it is worth **0.04...](2026-10-03-region-pricing-sweep.md)

### renderface

- `negative` [Correction: the general block row is **minimal, and that is derivable** — the 31x gate is not reachable b...](2026-10-03-region-pricing-sweep.md)
- `closed` [`renderface` priced (2026-10-02) — **CLOSED with a price**, and the 1.0 cycle rate is not a constant](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The rate is a dependency property, not a constant — this is the important result](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [What the price does to `renderface`](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Two probe mechanics specific to C, both of which would have produced a silently wrong number](2026-10-02-edge-scan-and-texture-spans.md)
- `promoted` [`surf8` flat axis: three measured wins bundled and **PROMOTED, 0.0620%** (2026-10-02)](2026-10-02-surf8-bundle-and-promotion.md)
- `closed` [The `surf8` horizontal-flat axis, screened (2026-10-02) — four candidates, two closed by price](2026-10-02-surf8-bundle-and-promotion.md)
- `promoted` [mip-1 flat-row index hoist (2026-10-02) — **0.0353% alone; promoted at 0.0620% as part of a bundle**](2026-10-02-surf8-bundle-and-promotion.md)
- `measured` [Drawn-face ratio (2026-09-29) — measured at 0.9585, which closes the per-face precompute family](2026-09-29-harness-and-cost-model.md)
- `promoted` [mip-1 horizontal-flat surface blocks (2026-10-01) — **PROMOTED, 0.0513%**](2026-10-01-attribution-corrections.md)
- `measured` [Horizontal-flat mip-0 surface blocks (2026-09-29)](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Pre-surface-block-loop control and PROFILE486 baseline (2026-09-28)](2026-09-29-alias-and-surface-block-experiments.md)

### surface-cache

- `promoted` [The 1800 KB surface-cache wall does not exist (2026-09-29) — root-caused, and the latent win is promoted](2026-09-30-harness-fidelity-and-sourcing.md)
- `rejected` [E4, the surface-cache eviction churn (2026-09-29) — premise falsified before it was built, 0 of 8,886 reb...](2026-09-29-harness-and-cost-model.md)

### texture-spans

- `measured` [The general surface-block path is **6.85% of frame at 0.77 cycles per instruction**, and one instruction ...](2026-10-03-region-pricing-sweep.md)
- `measured` [The span16 per-segment setup is 2.37% of frame and contains no x87 at all — **`texture-spans` is re-opened**](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Four candidates the pool suggests, and why all four are dead](2026-10-02-edge-scan-and-texture-spans.md)
- `closed` [The unit-stride span premise is zero (2026-10-02) — `texture-spans` is closed, and the arithmetic says wh...](2026-10-02-surf8-bundle-and-promotion.md)
- `measured` [`d_mip_t16` as a constant table (2026-09-29) — landed; the promotion half was not attempted](2026-09-29-harness-and-cost-model.md)
- `measured` [Current texture-span follow-up (2026-09-29)](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Texture-span address-update experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Texture-span row-cross experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Texture-span load-order experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Texture-span tail-store experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)

### world-bsp

- `measured` [The bmodel frustum `FIXME` (2026-09-29) — premise measured, ceiling is two orders of magnitude short, do ...](2026-09-29-harness-and-cost-model.md)
- `measured` [`world-bsp` decomposed (2026-10-01) — it was never the BSP walk; 85% of it is per-face edge setup](2026-10-01-attribution-corrections.md)
- `measured` [World-BSP frame-count cache experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)

### z-spans

- `measured` [`z-spans` is the last unpriced region above 2%: **42,031,372 pixels, 3 instructions each, at 1.24 cycles ...](2026-10-03-region-pricing-sweep.md)
- `rejected` [Precomputed `izistep` for the Z-span prologue (2026-09-29) — rejected, and the estimate was wrong in the ...](2026-09-29-harness-and-cost-model.md)
- `rejected` [Z-span x87 prologue (2026-09-29) — measured, and the idea does not survive](2026-09-29-harness-and-cost-model.md)

## Sourced from `BUILD-DOS.md`

These three files were results sitting inside the operational build reference. Each
section below moved verbatim.

### [2026-09-29-offline-precomputation-pass.md](2026-09-29-offline-precomputation-pass.md)

- `Offline precomputation pass (2026-09-29) — one rejection, one cleanup, one closure`
- `Latest PROFILE486 and texture-span STOSW experiment (2026-09-29)`

### [timedemo-baseline-history.md](timedemo-baseline-history.md)

- `Lightmap style accumulation`
- `VGA full-frame copy experiment`
- `Surface-cache capacity and churn`
- `Surface-cache header locality experiment`
- `Lazy viewspantable rebuild`
- `Measured texture-span change`

### [microbenchmark-results.md](microbenchmark-results.md)

- `Memory helper experiment result`
- `Runtime memory-helper result`
- `Texture-axis cache probe result`
- `Surface-cache predicate result`
- `Mip-level selector result`
- `Turbulent-span inner-loop result`
- `Alias-project projection result`
- `Texture-animation frame-selection result`
- `Lightmap normalization result`
- `BSP plane-dot result`
- `BSP frustum-clipping result`
- `Alias bounding-box projection result`
- `Clipped alias vertex transform result`
- `Rejected negative-gradient Z-span unroll`

