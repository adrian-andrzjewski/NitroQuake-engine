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
demo1 timedemo   59.227329 s   16.360690 FPS   969 frames
framebuffer checksum 1047377823    bench486 end checksum 2378409472
```

Recorded in `../BENCHMARK-COMPARISON.md`. The offline-precompute axis is closed
by measurement; `../ASM486-HANDOFF.md` holds every number behind that, plus
each candidate that was rejected and why.

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
