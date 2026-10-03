# The clamp fusion, and what the 1.0 cycle rate measures (2026-10-03)

Extracted verbatim from `ASM486-HANDOFF.md` lines 903-1065 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## The clamp fusion is measured at **0.0000%**, and the probe that explains it says **1.0 cycle per instruction measures added work, not removed work** (2026-10-03)

> **This supersedes the pricing rule everywhere it is used, in one direction only.**
> All eleven assembly rates in this file — 0.9740 to 0.9957, mean 0.9866 — were measured by
> **adding** a duplicated sequence and timing the whole-run delta. None of them measured what a
> **removed** instruction is worth. This pass built the one candidate in the ledger that the
> model said was worth 0.206%, removed it, and got **nothing**. A second probe then added
> instructions of the identical shape into the identical code and was charged **0.988 cycles each,
> 4,268x the run spread**. Both numbers come from the linked executables. The model is not wrong
> about what it measures; it has simply never been shown to predict the value of a removal.

### The candidate: one LEA per clamp, and the ledger had written it off for the wrong reason

`texture-spans` is the one pool the last pass left open — the span16 per-segment setup at 2.37% of
frame, 47x the gate, integer, admissible. Its second recorded candidate is the s/t clamp fusion, and
under "**Four candidates the pool suggests, and why all four are dead**" it is rejected with:

> the form needs a scratch register to hold `v - 4096` because subtracting in place destroys the
> running accumulator. `%eax` *is* free across lines 364–432, but the `movl %ebp,%eax` that gets
> it there costs exactly the instruction the fusion saves. **Four for four.**

**That arithmetic is the only thing wrong with it, and it is wrong by one instruction.** The value
does need a scratch register, and `%eax` and `%edx` really are free there — but the way to get the
biased value into the scratch register is `leal -4096(%ebp),%eax`, **one** instruction, not the
`movl`+`subl` pair the note priced. `leal` with a 32-bit displacement is a single 6-byte encoding
and gas accepts it; verified against the pinned toolchain before anything was built. So the clamp
is three instructions and one branch, not four and two:

```text
control   cmpl $4096,%ebp ; jl ; cmpl C(bbextents),%ebp ; ja       4 instructions, 2 branches
fuse      leal -4096(%ebp),%eax ; cmpl C(bbextentsm4096),%eax ; ja 3 instructions, 1 branch
```

`LClampHighOrLow2..5` discriminate low from high with `jg` on the same compare, which is the
`LClampHighOrLow0`/`LClampHighOrLow1` idiom the file already uses for the per-span clamps, so the
out-of-line side is not new machinery. The bound is prebiased once per face in `d_edge.c` and once
per sprite in `d_sprite.c`, alongside the two sites that already write `bbextents`/`bbextentt`.
The read is `4096 <= v <= bb` iff `(unsigned)(v - 4096) > (unsigned)(bb - 4096)`, which is exact
over the whole domain the clamps already assume, including `v == 4096` and `v == bb`; a negative
`v` wraps to a huge unsigned and takes the low clamp exactly as the signed `jl` did.

**Price, and it clears the gate on the model by 4x.** Two instructions per sixteen-wide segment at
2,059,018 segments — that site alone, and it is the one with a measured count:

```text
2 x 2,059,018 = 4,118,036 removed at 1.0 cy = 0.1231 s = 0.208% of 59.160558 s, gate 0.0296 s
```

The `LLastSegment` clamp pair removes two more per *span*, and the span count was never measured, so
**4,118,036 is a floor on the removal and 0.208% is a floor on the price.** Nothing later in this
entry depends on the exact figure.

### What it measured: 0.0000%

`control` was verified to reproduce the pre-change object **instruction for instruction** — 619
instructions, zero disassembly differences, the only two lines `Compare-Object` reports being
objdump's own filename header — because the twelve new `LClampHighOrLow*` instructions are cold
code that `control` must not carry. `bench486` PASS at end checksum `2378409472`; checksum
`1047377823` and 969 frames on every timedemo run.

```text
control : 59.169294 / 59.169259 / 59.169296 s, median 59.169294, spread 0.000037
fuse    : 59.169267 / 59.169329 / 59.169282 s, median 59.169282, spread 0.000062
delta   -0.000012 s = 0.0000%   trailing control 59.169284, drift -0.000010 s
```

**Not a near miss. The fuse median is 12 microseconds *slower*, at 0.3x the control spread, with no
drift.** And the binary is not the problem: `objdump` of the `...spancampfuse.../qbench.exe` the
timedemo actually ran shows all four fused clamps with their two distinct bound addresses, so the
change was compiled in and executed. At least 4,118,036 instructions removed bought 12 microseconds. This
is a rejection, not a closure-by-price, and the candidate is **not** to be rebuilt.

### The probe: the same shape, added, is charged 0.988

The obvious explanation was that the emulated core does not charge for a compare whose only
consumer is a not-taken branch, so the four removed compares were already free. **That is
falsifiable, and it is false.** A dead-scratch probe duplicating the *identical* instruction shape
— same `cmpl $4096` / not-taken `jl` / `cmpl C(bbextents)` / not-taken `ja` — was placed on the same
unconditional per-segment path, with no counter (the same convention as the `setup` probe: gas does
not dead-code-eliminate, and the count is that probe's already-measured 2,059,018 executions). It
added exactly four instructions and no padding:

```text
control : 59.629895 / 59.169340 / 59.169283 s   (first run the isolated outlier this file records)
probe   : 59.412649 / 59.412680 / 59.412652 s, spread 0.000031
delta   +0.243312 s = +0.4112%   trailing control 59.169278, drift -0.000062 s
```

Every probe run is 0.243 s above every clean control run, at **4,268x the clean spread of
0.000057 s** — the 0.460612 s block spread the driver prints is entirely that one outlier, which is
what its own warning is for. The divisor is 4 x 2,059,018 = 8,236,072:

```text
0.243312 s x 33.445 MHz = 8,137,271 cycles / 8,236,072 instructions = 0.9880 cycles each
```

**0.988.** The clamp shape is charged at the register-only rate. So the work is not free, the
removal is not being credited, and the two measurements sit in the same function, on the same
path, in the same workload, both checksum-clean. **Adding four of those instructions costs 0.243 s
and removing four of them saves 0.000012 s.**

### What that does and does not license

It licenses exactly one rule, and it is narrower than the one it replaces:

> **Price a candidate at 1.0 cycle per instruction only if the region is throughput-bound, and a
> region is throughput-bound only if an A/B has shown a removal paying there.** The 1.0 figure is a
> sound measure of the cost of *adding* work — that is what all eleven probes measured, and this
> pass's twelfth agrees. It is **not** a validated estimate of what a removal is worth, and the
> span16 setup is now a measured counter-example: a 4.1x-gate model prediction against a 0.0000%
> result.

The one removal ever checked against the model was the mip-1 flat-row index hoist, predicted 0.036%
and measured 0.0353% — a 2% agreement that is now the **only** evidence that the model predicts
removals at all, and it is one point in a region that happened to be throughput-bound. The
`unroll16` and fully-flat promotions were measured directly and are unaffected.

**The direction of the error is one-way, and that is what makes this actionable.** The model
over-priced this candidate by at least 4.1x, to the point of clearing a gate it does not clear. It
has never been shown to *under*-price. So **a model-priced rejection is not evidence that a
candidate is slow** — it is evidence that nobody has built it. The screened-out `surf8` candidates
(mip-2 0.0095%, mip-3 0.0006%, fully-flat per-block 0.0080%) and the four dead texture-span
reductions would all need a 600x overstatement to reach the gate, so they remain correctly closed on
price. The ones worth revisiting are the *large* model-priced pools whose regions have never had a
removal measured in them: the `renderface` C scaffolding at 15.8x, and the `edge-scan` map's biggest
blocks.

**The general consequence is that this project's screening method has one unvalidated half.** A
cycle model can tell you what a change *costs* to try, and after this pass it still can. It cannot
tell you what a change is *worth* without an A/B, and the "**Do not price a C candidate by
instruction count alone**" note under "**Priority-ordered next steps**" — which warned that the
rate is ±40% for C — understates the problem by orders of magnitude for removals in a
dependency-bound region. **Nothing in the texture-spans setup is reachable by instruction
removal.** The only way into that 2.37% is to shorten the loop-carried dependency chain — the
per-texel `addl %ebp,%ebx` / `adcl advancetable+4(,%ecx,4),%esi` carry pair is already two cycles,
which is minimal for a propagating accumulator — and that needs a source-level hypothesis this pass
did not produce. **Do not re-close `texture-spans` on instruction count again.**

Three small notes for whoever reopens it, each of which cost this pass a build-and-run cycle:

1. **`leal` is the instruction the note was missing**, and the general form of the lesson is that
   a scratch register does not have to be *moved* to and then modified — one addressing-mode
   instruction can compute into it. Re-read every "the register move costs what the fusion saves"
   closure in this file with that in mind; there are several.
2. **A `-D` selector whose helper blocks are not `#ifdef`-guarded breaks the `control` check
   silently.** Twelve cold instructions in an unguarded helper is the whole difference between a
   619-instruction control and a 631-instruction one, and the A/B would have measured that noise.
3. **Probes shift `.p2align` padding, and padding is executed.** A five-instruction probe inserted
   at the per-segment clamp cost 17 instructions, because the function's `.p2align 4,,15` blocks
   re-padded downstream; the same probe at four instructions cost exactly four, with none. Always
   take the added-instruction count from `objdump` and never from the source, and count any padding
   the insertion moved as part of the probe.

**Baseline unchanged and re-verified on the reverted tree.** The tree is back to HEAD, rebuilds clean, and
re-measures at **59.160549 s / 16.379158 FPS** against the recorded **59.160558 s / 16.379156 FPS** — a
0.000015% difference, i.e. noise — with 969 frames and checksum `1047377823`. (Mid-session the blocks
ran ~0.009 s high on *both* variants at once, which is why the A/B was run as matched pairs and not
against the recorded absolute; that offset cleared before this final run and is not a drift.) `bench486`
PASS at `2378409472` on the candidate; checksum `1047377823` and 969 frames on all sixteen timedemos.
The candidate, the probe, the two prebiased bounds and all four runners' plumbing are **removed from the
tree**; `d_draw16.s` reassembles to 619 instructions and both repositories are clean.


