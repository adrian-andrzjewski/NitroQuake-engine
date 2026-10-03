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

Recorded in `../BENCHMARK-COMPARISON.md`. Re-measured 2026-10-02 at
**59.160513 s** median over three runs — a 0.00008% difference, i.e. noise, so
the baseline is unchanged and the 2026-10-02 work promoted nothing. The
offline-precompute axis is closed by measurement; `../ASM486-HANDOFF.md` holds
every number behind that, plus each candidate that was rejected and why.

## The two largest unmeasured pools, and one of them is now measured

The plan of record has consistently said the renderer is converged on every
promotable axis. That remains true of every axis that had been *probed* — but
two regions were closed for want of a measurement rather than on one, and on
2026-10-02 the first was measured:

| pool | cyc/frame | vs gate | closed because |
|---|---:|---:|---|
| `edge-scan` | 208,581 | 204x | *"unresolvable by this instrument, not as converged"* |
| `renderface` | 226,000 | 221x | *"no admissible hypothesis"*; probe declined |

**`edge-scan` is now decomposed, and the closure was half wrong.** Its
justification was that a per-call timer scope costs 387 cycles against 466
cycles of work per operation, giving 17% signal. That floor is real and still
forbids a scope — but it does not bind a **dead-scratch probe**, which has no
measurement overhead at all because it adds work and is read off the whole-run
timedemo delta. **Nine** probes gave the decomposition that was thought
unavailable:

```text
edge-scan, 78% accounted          159.2x the gate  (16 named blocks)
  measured by their own probe     136.4x    (9 blocks, 139,535 cyc/frame)
  statically priced at 0.98657     19.4x    (6 blocks,  19,853 cyc/frame)
  bmodel 1/z sort, inadmissible      3.3x    (66,644 calls, ~40 of 50 are x87)
  residual                        44.8x    (scope overhead, R_RecursiveTriangle,
                                            call entry/exit, per-block count error)
```

The census behind it overturned two beliefs at once: the four loops carrying
~20 logged micro-experiments are **52x the gate together, not most of the
bucket**, and `TrailingEdge` is called 2,238,002 times to emit 1,043,177 spans —
**53% of its calls emit nothing**, which nothing had measured.

**So `edge-scan` is no longer an unknown.** It is sixteen named blocks, largest
23.2x the gate, smallest 0.9x. That is a different object from "8% of frame,
cannot be decomposed", and it is what the twenty rejected micro-experiments
never had. It is **not** a licence to build: read against the prohibition list,
every block above 5x is hand-tuned assembly that has already absorbed the
recorded micro-optimisations, and the three largest per-edge blocks are
structurally minimal.

`renderface` is **priced and closed**. It was the second-largest pool at 221x the
gate, closed for *"no admissible hypothesis"*. Two C dead-scratch probes give
**~15.8x the gate** of priced C scaffolding — per-edge cache validation ~11.5x,
per-call prologue ~4.3x — against the **70-90x** the old entry estimated. **That
estimate was high by 4-5x**, and the remainder of the 221x is the
`R_ClipEdge`/`R_EmitCachedEdge` calls, which is essential x87 edge emit and
inadmissible under Decision 1.

Three things killed the candidates before a line was written:

- **Read the object first.** The obvious prize — the double `edge_p - r_edges`
  across 29 sites — is **already CSE'd by `-O3`**. `objdump -dr` shows both
  loads hoisted and a single duplicated `sub`, so the whole candidate is 0.9x
  the gate. One disassembly, no build.
- **The two hoists a reader would try next are logged as reverted**, with
  measurements.
- **`-O3` deletes a C probe that writes to a dead local.** It compiles to
  nothing and reports a clean zero. A C probe must accumulate into a reported
  external global.

The general lesson is recorded because this project has now made the mistake
twice: **an entry that says what would be needed is not a closure.** The
`edge-scan` entry named the dead-scratch probe as its own remedy and was filed as
closed anyway.

**Where the renderer actually stands.** The three unmeasured mega-pools are now
measured, and the third is the largest prize found so far:

| pool | before | after |
|---|---|---|
| `edge-scan` | "cannot be decomposed" | **78% mapped, 159.2x the gate**, sixteen named blocks |
| `renderface` | "no admissible hypothesis" | **priced at ~15.8x the gate** of C scaffolding |
| **`texture-spans` setup** | "dominated by x87 — a blind axis" | **2.37% of frame, 47x the gate, zero x87** |

`texture-spans` was the last closure resting on an unexamined premise, and the
premise was wrong. A dead-scratch probe at the head of the per-segment setup
priced **six instructions at 0.6186% of frame** — the full ~23-instruction integer
setup scales to **2.37%**, which is larger than anything `edge-scan` or
`renderface` offered. The 125 x87 instructions in `d_draw16.s` sit in the entry
divide, the `LNotLastSegment` advance and the tail path, **not in the setup**.

**And there is still no candidate for it.** Four reductions of that pool are
recorded with why each fails: the `advancetable` hoist is the wrong function's
kept win and cannot apply because the table changes with position-in-span; the
clamp fusion needs a scratch register and the copy costs what the fusion saves;
the `fistpl`/reload pair is architecturally forced because `FIST` has no register
destination; and segment widening is already amortised for the x87 half. The
setup is ~23 necessary DDA instructions.

**So the convergence claim is weaker than the previous three passes suggested, and
that is the honest state.** The largest addressable-looking pool in the renderer
has been located and quantified, and it has not yet yielded a change. `texture-spans`
is re-opened. Read the four dead candidates before proposing a fifth — and do not
re-close it on the x87 argument, which is now measured false.

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

> **Item 2 is superseded by Decision 5 below: there is no 0.66 rate. Price
> everything at 1.0.** The reasoning that produced it is sound and the
> conclusion is wrong; see Decision 5 for the six measurements that overturn it.

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

## Decision 5 — there is no 0.66 rate; price everything at 1.0

Added 2026-10-02, from the `edge-scan` probe pass. Decision 3's instruction is
**wrong in its conclusion and right in its reasoning**, which is the worst kind
of error to leave standing, so it is replaced here rather than merely annotated.

The 0.66 figure came from `0.030368 s x 33.445 MHz / 1,543,048 = 0.658`. But
1,543,048 is the instruction count of the *promoted mip-1 flat path*, not of any
set of instructions a candidate would **remove**. The hoist that actually got
promoted removed 712,176 instructions and measured `0.020884 s` — **0.9807**.
The divisor was the wrong quantity, so the rate was never measured.

Six fresh dead-scratch probes across the whole instruction-mix range say the
discount does not track memory operands at all:

| probe mix | rate |
|---|---:|
| half global loads (`entry`) | 0.9957 |
| straight-line arithmetic, `imull`/`shrl`/`addl` (prior, `:114`) | 0.9955 |
| register-only partial moves (prior, mip-1 hoist) | 0.9810 |
| both sort loops, loads and compares (`sort`) | 0.9883 |
| `addl` with a memory operand (prior, Z-span probe) | 0.9955 |
| load and step (`step`) | 0.9896 |
| **pure memory operand, nothing else** (`insert`) | **0.9740** |
| push/pop and five loads (`emit`) | 0.9842 |

Mean **0.9864**, range 0.9740–0.9957, spread **2.2%** across eight mixes. The
most memory-bound probe measured is 0.974, not 0.66.

**So: count removed instructions, multiply by 1.0, compare against 1,022.8
cycles/frame.** This is also the conservative direction — 1.0 is the *higher*
price, so it admits more candidates than 0.66 would, and the timedemo remains
the only thing that promotes anything.

> **Amended the same evening: 1.0 is right for assembly and carries roughly ±40%
> error for C, in both directions.** Eleven probes now exist, and they do not
> agree with each other across languages:

> | mix | measured rate |
> |---|---:|
> | nine assembly loops, serial dependency chains | 0.9740 – 0.9957 (mean 0.9866) |
> | straight-line C, instructions independent of surrounding work | **0.5439** |
> | C in a loop, probe sink a loop-carried dependency | **1.1917** |

> The rate is a **dependency property, not a constant**. Independent instructions
> issue into slots that were already idle and cost *less* than a cycle;
> serialised ones cost *more*. Since every candidate this project has screened
> is assembly, 1.0 remains the right screening number **for assembly** — but a
> static estimate on a *C* mix can overstate the prize by nearly half or
> understate it by a fifth, and must be measured before it is trusted. No price
> already recorded in this file was computed on a C mix, so nothing is wrong;
> what was wrong was assuming the error bar was zero.

**Two consequences that are not optional bookkeeping:**

1. **The re-screen came back clean — verify, don't assume.** Recomputing every
   "closed on price" candidate at 1.0 reproduces its recorded figure exactly
   (A 0.0095%, B 0.0006%, D 0.0080%). The 0.66 was applied to precisely one
   candidate, C, in the screening table's first draft, and was corrected inside
   that same pass. **No recorded candidate price is wrong, and the bundle path's
   exhaustion does not rest on the bad rate** — it rests on measured figures for
   `GibTrail` (0.0119%) and `Turbulent8` (0.0344%), and on A/B/D being 5-83x
   under the gate at the *correct* rate. An earlier revision of this entry
   claimed the bad rate "was costing real candidates"; that overstated it, and
   the ledger entry records the correction.
2. **Decision 3's general warning survives and is now better founded.** The
   error it describes was real; it diagnosed the symptom (wrong rate) while
   being applied to the wrong quantity. What 0.66 actually cost was *standing
   guidance* — any future screening taking Decision 3 at face value would
   under-price by up to 50%. Where a rate is derived, check what the denominator
   counts.

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
measured at **0.0353%** — real, bit-exact, reproducible, and below the gate *on
its own*, so it was rejected in isolation and then **promoted at 0.0620% as part
of the Decision 4 bundle**. An earlier revision of this paragraph still read
"so it is rejected" without the qualifier; that was stale. Together with the
unit-stride span premise (0 pixels of a 400,000-pixel requirement) that closes
`texture-spans` on the admissible axis by measurement as well.

### The re-openable closures

Decision 4 has no list in the ledger yet, which is a gap: the plan asserts one
exists and it did not. Here it is, as of 2026-10-02. Every entry is bit-exact,
independently priced, and below the gate — so none is dead, only ungated.

| closure | price | state |
|---|---:|---|
| `SurfaceBlockMip0Rows=unroll8` | 0.0094% | **obsolete** — a strictly worse variant of the promoted `unroll16`; nothing to bundle with |
| `GibTrailHorizontalIntegration=skipzero` | 0.0119% | **live.** Selector already plumbed into all four runners; a default flip, no code. Needs ~0.038% more to clear the gate alone |
| mip-2 horizontal-flat block | 0.0064% claimed | **blocked on a bug**, not on price — it rendered checksum `3278041384` and the cause was never found |
| mip-3 horizontal-flat block | 0.0006% | closed on price; would need a 80x partner |

Only `skipzero` is worth acting on, and on its own it does not clear. This is
the honest reason the bundle path is exhausted rather than merely untried.

Two probes measured the last two, and both are worth copying rather than
reinventing:

- **Price the code you intend to remove, by duplicating it into scratch
  variables and discarding the result.** Both probe builds render bit-identical
  to control, so the probe is a measurement rather than a guess. Do *not*
  neutralise the inputs to make the work disappear: forcing `z = 1.0f` to remove
  the divides removes what the divides produce, which broke the water and
  faulted the run.
  **Two refinements from the 2026-10-02 `edge-scan` pass, both learned by faulting
  a run first.** A dead register is not a safe address — it must also be
  *initialised*; `%esi` looked dead in `R_InsertNewEdges`' search loop but is not
  written until the second probe, and reading through it crashed the timedemo.
  And on mutating code, duplicate the compute and **never the store**.
- **After any source edit, force a rebuild — or rather, you no longer have to.**
  ~~`../tools/timedemo-dos.ps1:272` only builds when the benchmark executable is
  absent, and that path is keyed by selector profile alone, so an edit is
  silently ignored and the previous binary is measured.~~
  **(Corrected: the runner now fingerprints all 163 sources plus the resolved
  selectors and rebuilds on a mismatch, or throws under `-SkipBuild` —
  `timedemo-dos.ps1:319-405`. Verified twice in one session. Passing `-Clean` to
  `build-dos.ps1` remains sound advice but is no longer required for
  correctness.)**
