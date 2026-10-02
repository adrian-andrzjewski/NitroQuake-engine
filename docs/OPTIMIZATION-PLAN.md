# 486 optimization plan of record

The plan this renderer follows is `1790698732780-proud-rocket.md` in the
`.mimocode/plans/` directory of the **wrapper repository one level above this
subproject** — that is, `../../.mimocode/plans/1790698732780-proud-rocket.md`
from this file, or `../.mimocode/plans/` from the renderer root. It is not
inside this repository, so a clone of `quake/` alone will not contain it. This
page is the renderer-side index to it, so that anyone arriving at `quake/` can
find it and the rules it imposes even when the wrapper is not present.

**The authoritative document is the plan file, not this page.** This is a
pointer plus the two decisions that are easy to get backwards. Where the two
disagree, the plan file wins.

## Current state

```text
demo1 timedemo   59.160558 s   16.379156 FPS   969 frames
framebuffer checksum 1047377823    bench486 end checksum 2378409472
```

Recorded in `../BENCHMARK-COMPARISON.md`. The offline-precompute axis is closed
by measurement; `../ASM486-HANDOFF.md` holds every number behind that, plus
each candidate that was rejected and why.

## Decision 3 — price at the rate that matches the instruction mix

Added 2026-10-02, after a screening error produced a wrong answer in the right
direction. DOSBox-X's dynamic core charges **1.0 cycle per removed
instruction**, measured two independent ways that agree to 1.5%: a dead-scratch
probe of 24 straight-line integer ops (`imull`/`shrl`/`addl`) at 0.9956, and a
promoted hoist of register-only partial moves at 0.981. Both are recorded in
`../ASM486-HANDOFF.md`.

The mip-1 flat-path promotion implies a *different* rate, 0.66 cycles per
instruction, because its 13 instructions per row include two global loads and a
global store. **Screening a candidate at the wrong one of these is a 50% error,
and in this project it was:** the mip-1 flat-row index hoist was first priced at
0.029% and written off as under the gate, and actually measured **0.0353%** —
a clean bit-exact win that would have been declined. So:

1. Count the operations the change would **remove**.
2. Price them at **1.0 cycle per instruction** unless the removed instructions
   include memory operands, in which case 0.66 is the measured rate for that mix.
3. Compare against 1,022.8 cycles/frame.

Decisions 1 and 2 below are unchanged.

## Decision 4 — bundle sub-gate wins, because the gate is on the total

Added 2026-10-02, the same day as Decision 3 and the reason the previous pass
found nothing. The promotion gate is a delta from the current baseline, so a
change worth 0.035% can never be promoted **on its own** no matter how clean it
is. Three such changes, each independently priced and each bit-exact, are worth
0.062% together and clear the gate.

The `surf8` promotion is the worked example: `SurfaceBlockMip0Rows=unroll16`
(0.0132%), `SurfaceBlockMip1IndexHoist=hoist` (0.0353%), and a fully-flat
variant of the same path (0.0126%). Predicted 0.036716 s from the instruction
model, measured 0.036689 s — 0.07% error, with all three components validated
bit-exact against the framebuffer checksum.

What this does **not** license:

- Bundling anything that is not independently priced. The rule is still
  Decision 2: every component must survive the prize screen on its own.
- Bundling to hide a marginal win. The bundle cleared by 24%, and each component
  is a genuine instruction removal rather than a scheduling accident.
- Bundling changes whose *interaction* is unverified. The three here touch
  disjoint code (mip-0 general loop, mip-1 flat row, mip-1 flat block entry), and
  the matched A/B is run on the whole bundle, not on the pieces.

## Decision 1 — the acceptance gate is the timedemo, not a cost model

The 0.05% DOSBox-X timedemo delta is the **sole promotion criterion**, and it
is unchanged. An earlier draft of the plan proposed replacing it with a static
486 cycle model; that was wrong and was reverted.

The reasoning is the harness's own, recorded at `../ASM486-HANDOFF.md:728-736`
("Applying the rule" is at `:754`):
DOSBox-X prices x87 at ~1.04 cy/op where a 486DX spends roughly 12, and models
neither fetch boundaries, write-buffer occupancy, nor 4 KB page aliasing. A
measured win is therefore sound, but a measured null only proves the emulator
could not see the cost.

The consequence is stronger than "a null is weak evidence" and is worth stating
plainly, because it removes targets rather than merely demoting them: **a
candidate whose entire payoff is x87 latency, fetch boundaries, write-buffer
occupancy or 4 KB aliasing cannot be selected at all**, because nothing that
registers only there can ever be promoted. The Z-span x87 prologue — the
largest known real-486 prize in this renderer at 3.91% of frame, measured by
`tools/486-cost-model.ps1` — is inadmissible for that reason alone. It was not
closed by a measurement, and should not be re-proposed as though it were.

`tools/486-cost-model.ps1` exists to enforce this. It quantifies the three
blind axes so that a timedemo is never spent on an idea whose payoff the
harness cannot register. Its output is a report, never a result.

## Decision 2 — price the prize before asking about the hit rate

Before proposing a cached or precomputed value:

1. Count the operations the change would **remove**, not the cache hits it
   would earn.
2. Divide by frames and compare against **1,022.8 cycles/frame** (the 0.05%
   gate; roughly 22 cycles per texture pixel).
3. Only then ask whether a cache hits, and only if step 2 clears the gate.

Four candidates died on this, and all four had quoted a ceiling from a bucket
share or a cost of churn:

| Candidate | Quoted | Measured | Why it died |
| --- | --- | --- | --- |
| E0, per-face precompute | ~0.10–0.14% | 3.4% hit rate | ceiling assumed 100% reuse |
| E4, surface-cache churn | 2.61% | 0 of 8,886 | no such surfaces exist in the workload |
| bmodel frustum `FIXME` | 1.5–2.5% | ~5x under gate | 13.1 face tests per frame |
| `Turbulent8` setup | 2.27% | 0.0344% addressable | chunk setup is a running accumulation |

Two more closed on the same rule in 2026-10-02, from counters rather than
estimates: the **mip-2** and **mip-3** horizontal-flat surface blocks at 0.0095%
and 0.0006%, and the **fully-flat per-block index hoist** at 0.0080%. The
remaining item on that axis, the **mip-1 flat-row index hoist**, was built and
measured at **0.0353%** — real, bit-exact, reproducible, and **below the gate**,
so it is rejected. Together with the unit-stride span premise (0 pixels of a
400,000-pixel requirement) that closes `texture-spans` on the admissible axis
by measurement as well.

Two probes measured the last two, and both are worth copying rather than
reinventing:

- **Price the code you intend to remove, by duplicating it into scratch
  variables and discarding the result.** Both probe builds render bit-identical
  to control, so the probe is a measurement rather than a guess. Do *not*
  neutralise the inputs to make the work disappear: forcing `z = 1.0f` to remove
  the divides removes what the divides produce, which broke the water and
  faulted the run.
- **After any source edit, force a rebuild.** `../tools/timedemo-dos.ps1:272`
  only builds when the benchmark executable is absent, and that path is keyed
  by selector profile alone, so an edit is silently ignored and the previous
  binary is measured. This produced a false negative here. See the warning in
  `../BUILD-DOS.md`.
