# 486 ASM experiment handoff

This checkout is a DOS WinQuake/software-renderer preservation project.  The
purpose of the ASM work is experimental: compare small hand-written 486 paths
with the original C under the same DJGPP build and DOSBox-X workload, then
promote only changes that preserve the exact framebuffer and win the complete
timedemo.  This is a continuation note for the next agent; operational build
and run details remain in `BUILD-DOS.md`.

## Current state

### Correction: the general block row is **minimal, and that is derivable** — the 31x gate is not reachable by removal (2026-10-03, third pass of the day)

> **This closes the lead the previous entry ends on.** That entry priced the general surface-block
> path at 6.85% of frame and pointed the next pass at its row prologue. Both of its suggestions are
> now closed, and not by a failed search — by a derivation that accounts for every instruction in the
> row. Read this before spending anything on `SURF8_MIP0_ROW`/`SURF8_MIP1_ROW` again.

**The candidate was the two index-byte writes.** `movb %dh,%bh` and `movb %dh,%ch` appear once per
texel in both general rows, they write the *same* byte into two *different* index registers, and a
single-index-register rewrite removes exactly one instruction per texel — **8.3x the gate on mip-1,
22x on mip-0.** That was the plan. It is impossible, and the flat row says why.

**The general row's six instructions per texel are:** one texel load, one colormap load, **two**
`addl %ebp,%edx`, and **two** `movb %dh,%Xh`. The two adds advance the interpolated light twice per
texel while the light *byte* is consumed once per output, so `%dh` takes **two distinct values per
texel** — and each index register needs the byte for the state at which its own lookup happens. The
rewrite fails in both directions:

- **Keep two light bytes** (sample `%dh` after each add, as the code does) and one register cannot
  hold both, because r7's lookup needs the byte from before the first add and r6's from between the
  two adds.
- **Keep the add count** (two per texel, which the row's fixed-point ramp requires) and both lookups
  then see the *same* `%dh`, which is not what the current code computes. That is a different
  rendering, not a faster one.

**`SURF8_MIP1_FLAT_ROW` is the proof, and it is already in the tree.** It contains **no
`addl %ebp,%edx` at all** — the light is constant across a flat row — and it *still* carries both
`movb %dh,%bh` and `movb %dh,%ch` (once per row, under the promoted hoist). So the pair is not a
redundancy artefact of the general path: **one byte-write per index register is invariant**, because
`%ebx` and `%ecx` remain two distinct registers holding two distinct texel bytes. In the flat row
`%dh` never changes, so one write each per row suffices; in the general row `%dh` changes once per
add, so each register needs one write per add, and there are two adds per texel. `SURF8_MIP0_
HORIZONTAL_FLAT_ROW` agrees exactly: its entire per-row light cost is the same two writes.

**So the general row is 6-for-6 minimal**, and so is the flat row at 3-for-3. The earlier statement
that the flat specialisations are *complete* extends to the general path itself: there is no
instruction in either row that is not carrying a distinct value to a distinct consumer. That is a
much stronger position than "no candidate was found", and it is the second time in two days that a
promising pool has turned out to be closed by structure rather than by price — the first being the
span16 per-segment setup, which is latency-bound, and this one, which is minimal.

**The row prologue is closed for a second, independent reason.** `movl %ebp,C(lightdelta)` /
`sarl $4,%ebp` at the head and `movl C(lightdelta),%ebp` / `addl C(lightdeltastep),%ebp` at the tail
(2,778,592 instructions on mip-0, 0.14% of frame, 2.8x the gate) is a matched round trip whose sole
purpose is to let the tail's add happen in the block domain while the body consumes the shifted
value. It cannot be elided by keeping `%ebp` in one domain, because the shift is destructive and
**all seven general registers are live across the body** — `%eax` accumulates results, `%ebx`/`%ecx`
are the two index registers, `%edx` the interpolated light, `%ebp` the step, `%esi`/`%edi` the
source and destination cursors. Removing it needs a register this row does not have, which is the
same wall the ledger records for the span16 `emit` block ("the block has no free register").

**What survives, and it is the useful part.** The 31.4x figure was never wrong as an *opportunity
size*; it is wrong as a *reachability*. The honest summary of this renderer is now two-part and both
halves are measured:

| region | share | why it is closed |
|---|---:|---|
| span16 per-segment setup | 2.37% | latency-bound: charges 0.988/instr added, ~0.0 removed (4.1x-gate candidate measured 0.0000%) |
| general + flat block rows | 6.85% | **minimal**: 6-for-6 and 3-for-3, every instruction has a distinct consumer |
| `renderface`, `edge-scan`, alias | ~25% | priced and mapped; x87 remainder inadmissible |

And the standing methodological correction is unchanged and now has a second illustration: **a
large instruction budget is not an opportunity unless the instructions are removable.** This region
has 31.1M texels' worth of budget and zero removable instructions in it, and it took a derivation
rather than 150 experiments to establish that. The gate was never the binding constraint anywhere in
this renderer; **instruction-level structure was, and it has now been shown minimal in the last two
places anyone had a hypothesis for.**

Verification: no code was built, no timedemo was run, no probe was added. Both repositories are
code-clean, `d_draw16.s` remains 619 instructions, and the baseline is unchanged at **59.160558 s /
16.379156 FPS**.
### The general surface-block path is **6.85% of frame at 0.77 cycles per instruction**, and one instruction per texel is worth **31x the gate** (2026-10-03, second pass of the day)

> **This is a price, not a candidate.** Nothing was built. It is the first region found this
> project-wide whose *instruction* budget is large, whose per-instruction charge is **below** the
> nominal 1.0, and where the prize calculation clears the gate by a factor that makes instruction
> arithmetic — not the 0.05% gate — the binding constraint. Read it as the map that says where to
> spend the next pass, not as a closure and not as a win.

#### The measurement, and it is counters rather than arithmetic

Everything below comes from `surface_cache.mip_seconds` and `surface_cache.blocks_per_mip` in
`PROFILE.JSN`, both of which are measured counters, against `blocks_per_mip` minus
`horizontal_flat_per_mip` to isolate the general path and the real block footprint per mip
(16x16, 8x8, 4x4, 2x2):

| mip | blocks | horizontal-flat | general | general texels | cycles/texel |
|---|---:|---:|---:|---:|---:|
| 0 | 93,991 | 7,160 | 86,831 | 22,228,736 | **5.46** |
| 1 | 142,928 | 14,857 | 128,071 | 8,196,544 | **6.65** |
| 2 | 44,445 | 3,930 | 40,515 | 648,240 | **10.06** |
| 3 | 7,364 | 591 | 6,773 | 27,092 | **19.71** |
| **total** | 288,728 | 26,538 | **262,190** | **31,100,612** | — |

`mip_seconds` sums to 5.471 s of the 79.839 s instrumented run; rescaled to the release baseline
that is **4.055 s, 6.85% of frame**. So this is a **larger** admissible pool than the span16
per-segment setup the previous entry closed.

**The per-instruction charge is the interesting number.** Counting the mip-0 general row
(`SURF8_MIP0_ROW`) gives 12 instructions per two texels — two texel loads, two colormap lookups,
`movb %dh,%bh` and `movb %dh,%ch`, and four `addl %ebp,%edx` — plus a 17-instruction row prologue
and epilogue over 16 texels, i.e. **~7.06 instructions per texel** against a measured **5.46
cycles: 0.77 cycles per instruction.** The region is executing its instructions *below* the
nominal charge, which is the signature of instruction-level slack rather than a saturated
dependency chain.

#### What that makes one instruction worth

```text
31,100,612 instructions  /  33.445 MHz  =  0.9299 s  =  1.572% of frame  =  31.4x the 0.05% gate
```

**One instruction removed per general texel is 31x the gate.** mip-0 alone — 22,228,736 general
texels — is **1.12% of frame, 22x the gate.** For comparison, the entire span16 per-segment setup
was 47x the gate on paper and delivered 0.0000%, and the clamp fusion needed 4 instructions per
texel to reach 4.1x. Here the barrier is not the gate at all; it is finding an instruction that is
provably removable without disturbing a dependency. **That inverts the economics of this region
relative to everything else in the renderer.**

#### The flat specialisations are complete — this is new, and it closes the last idea here

`r_surf.c` already counts the two flatness predicates, and reading them settles whether a third
case exists. `horizontal_flat_blocks` counts `light_tl == light_tr && light_bl == light_br`; the
fully-flat subset additionally requires `light_tl == light_bl`. In `SURF8_MIP1_ROW` the per-texel
light work is `%edx += %ebp` twice, where `%edx` is the interpolated light and `%ebp` is
`lightdelta = (lightleft - lightright) & 0xFFFFF`, so:

- **horizontal flat** means `lightleft == lightright` with matching vertical steps, so `lightdelta`
  is 0 and both `addl %ebp,%edx` per texel are no-ops. **Implemented** (mip-0 and mip-1, promoted).
- **fully flat** additionally makes the light constant across rows, so the index bytes can be
  formed once per *block*. **Implemented** (promoted, bundled).
- **a vertical-flat-only block** — `light_tl == light_bl && light_tr == light_br` with
  `light_tl != light_tr`, i.e. `lightleftstep == lightrightstep == 0` but `lightdelta != 0` — was
  the one candidate this pass generated, and **it is not a zero-work case.** Both vertical steps
  being zero leaves the left-to-right ramp across the row intact, so `%ebp != 0` and the per-texel
  light update is *real work*. The `vertical_flat_blocks` counter reads 24,130, and there is
  nothing to remove for it.

**So the two flat paths are the only zero-work cases that exist, and both are shipped.** That is
why candidates A/B/D and the vertical-flat idea all fail, and it is a stronger statement than the
ledger's previous "no candidate found": the specialisations are *complete*, not merely exhausted.

#### Where the fat actually is, and the barrier

mip-2 and mip-3 run at **10.06 and 19.71 cycles per texel** against mip-0's 5.46 — because their
rows are 4 and 2 texels wide against a ~17-instruction row prologue, so a third of the mip-2 body
and two thirds of the mip-3 body is per-row overhead. They are also only 0.26% of frame combined,
so the *relative* fat is there and the *absolute* prize is in mip-0 and mip-1.

The candidate this pass identified and did **not** build: `movb %dh,%bh` and `movb %dh,%ch` write
the same byte of the two index registers `%ebx` and `%ecx` on every texel. One index register
instead of two removes exactly one instruction per texel — **11x the gate on mip-1, 22x on mip-0** —
but it serialises the texel load and the colormap load onto one register, replacing four
independent load pairs per two texels with two dependent pairs. That trades instruction count for
memory-level parallelism, which is exactly the axis this project cannot adjudicate: DOSBox-X does
not model load latency, so a harness win there would be uninterpretable as a 486 win. **On this
project's own admission rule, a candidate whose payoff is partly load-latency is inadmissible**,
and it is not built on that basis.

The mip-0/mip-1 row prologues carry a second, safer candidate: `movl %ebp,C(lightdelta)` /
`sarl $4,%ebp` at the row head and `movl C(lightdelta),%ebp` / `addl C(lightdeltastep),%ebp` at
the tail are a matched round trip through memory whose only purpose is to let the tail's add
happen in the block domain while the body consumes the shifted value. Over 86,831 mip-0 general
blocks x 16 rows that pair is 2,778,592 instructions = **0.14% of frame, 2.8x the gate** on its
own, and it needs no dependency change at all — only a second register to hold the unshifted step,
or the elimination of the round trip. **This is the first candidate in a long while whose barrier
is register allocation rather than a blind axis, and it is where the next pass should start.**

#### What is not claimed

The 0.77 figure is a region rate, and **the previous entry is the standing warning against
over-reading it**: the span16 setup charges ~1.0 per instruction *added* and ~0.0 *removed*, so a
sub-1.0 region rate is not by itself evidence that a removal pays. The removal probes above have
been additions probes; **no probe in this repository has yet measured what a removal is worth in
this region**, and that is the one measurement that would convert this entry from a price into a
candidate. Until it exists, treat 31x the gate as the size of the opportunity and the removal
question as unanswered.

Verification: no code was built and no timedemo was run for this entry. `d_draw16.s` remains 619
instructions, both repositories are code-clean, and the baseline is unchanged at **59.160558 s /
16.379156 FPS**.
### The clamp fusion is measured at **0.0000%**, and the probe that explains it says **1.0 cycle per instruction measures added work, not removed work** (2026-10-03)

> **This supersedes the pricing rule everywhere it is used, in one direction only.**
> All eleven assembly rates in this file — 0.9740 to 0.9957, mean 0.9866 — were measured by
> **adding** a duplicated sequence and timing the whole-run delta. None of them measured what a
> **removed** instruction is worth. This pass built the one candidate in the ledger that the
> model said was worth 0.206%, removed it, and got **nothing**. A second probe then added
> instructions of the identical shape into the identical code and was charged **0.988 cycles each,
> 4,268x the run spread**. Both numbers come from the linked executables. The model is not wrong
> about what it measures; it has simply never been shown to predict the value of a removal.

#### The candidate: one LEA per clamp, and the ledger had written it off for the wrong reason

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

#### What it measured: 0.0000%

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

#### The probe: the same shape, added, is charged 0.988

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

#### What that does and does not license

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


### `edge-scan` decomposed by dead-scratch probe — pass 1 of 2 (2026-10-02): six probes, and **the closure below was half wrong**

> **This is the first of three passes on 2026-10-02 and the numbers grow under
> it.** Pass 1 (here) decomposed the six loop/prelude blocks at 88.8x the gate
> and left 115x unmeasured. Pass 2, "The per-edge dispatch remainder" below,
> measured that remainder and brought `edge-scan` to 78% mapped. A third pass
> priced `renderface` and produced the correction that **1.0 cycles per
> instruction is a dependency property, not a constant**. Eleven probes exist in
> total; the "fifth and sixth rate calibration" in this entry's original heading
> counted only the ones that existed when it was written, and is superseded by
> the eleven-mix picture in the third pass.

`edge-scan` was closed under the heading "**`edge-scan` cannot be decomposed**" as *"unresolvable by this instrument, not as converged"*, on the floor arithmetic that a per-call scope costs 387 cycles against 466 cycles of real work per operation. **That floor does not bind a dead-scratch probe.** A probe costs
zero measurement overhead — it *adds* work and is read off the whole-run timedemo delta against a 0.000049 s spread — so the per-routine decomposition the floor forbade is available by a different route. The ledger
named this remedy itself, in the same entry ("*need the dead-scratch probe or real hardware*") and never ran it. It has now been run, and the result re-opens the bucket.

**Method.** A loop-iteration census first (`-Instrumentation`, one run), because the existing counters count *calls* and three of the four edge routines walk a list, so a probe priced per call would be sized wrong by
the walk length. Then one dead-scratch probe per block, duplicating a fixed side-effect-free sequence and discarding the result. Three runs per variant plus a trailing control for drift; checksum `1047377823`
enforced on all seven runs of every pair by the runner.

### The census, and what it overturned

```
edge-iters insert 532086 remove 150392 step 972457 pushback 96274 sort 1763039
            emit 1043177 genspans 3500514 bmodel-zsort 66723 trailing 2238002
```

**`genspans` is 3,500,514 edges — 3,612 per frame, 23.75 per scanline.** The four loops this file has spent twenty micro-experiments on (`LNextEdge`, `LContinueSearch`, `Lre_loop`, `Lsortloop*`) are **52x the gate
together. The whole bucket is 204x.** So roughly three-quarters of `edge-scan` was never in the routines under test.

**`TrailingEdge` is called 2,238,002 times and emits 1,043,177 spans: 53% of its calls emit nothing**, falling through to `LNoEmit2`/`LNoEmit`/`LInverted`. Nothing had measured that ratio.

### The six probes

Each delta is the probe run's median minus the control block's median; the instruction count is exact and is what the rate divides. Rates at 33.445 MHz:

| probe | block | probe instrs | delta | **rate** | vs 1.0 prediction | delta/spread |
|---|---|---:|---:|---:|---:|---:|
| `entry` | `Lgs_edgeloop` prelude | 21,003,084 | +0.625280 s | **0.9957** | 0.43% | 5,299x |
| `step` | `LNextEdge` | 7,779,656 | +0.230202 s | **0.9896** | 1.05% | 32,886x |
| `trailing` | `TrailingEdge` dispatch | 13,428,012 | +0.396177 s | **0.9868** | 1.34% | 12,780x |
| `emit` | span emit block | 7,302,239 | +0.214890 s | **0.9842** | 1.60% | 1,257x |
| `insert` | `LContinueSearch` | 2,128,344 | +0.061982 s | **0.9740** | 2.67% | 408x |
| `sort` | `Lsortloop*` (both) | 10,578,234 | +0.312596 s | **0.9883** | 1.18% | 2,442x |

**Mean 0.9864, min 0.9740, max 0.9957, spread 2.2%.** Every delta is 408x or better over its control block's spread; trailing-control drift was +0.0000% to +0.0002% in all six pairs, so none of these is
thermal. *(Six probes here; the second pass below takes it to nine and the mean to 0.98657 over a 2.20% spread.)*

**Applying the mean rate to each block's real instruction count** gives the priced pools:

| block | instr/run | cyc/frame | x gate |
|---|---:|---:|---:|
| `step` `LNextEdge` | 23,338,968 | 23,759 | **23.2** |
| `entry` `Lgs_edgeloop` prelude | 21,003,084 | 21,381 | **20.9** |
| `emit` span emit block | 19,820,363 | 20,177 | **19.7** |
| `trailing` `TrailingEdge` dispatch | 13,428,012 | 13,670 | **13.4** |
| `insert` `LContinueSearch` | 6,385,032 | 6,500 | 6.4 |
| `sort` `Lsortloop*` | 5,289,117 | 5,384 | 5.3 |
| **measured total** | 89,264,576 | **90,871** | **88.8** |
| profiler `edge-scan` | | 208,581 | 203.9 |
| **unmeasured remainder** | | **117,710** | **115.1** |

**The single largest unmeasured pool in this renderer is 115x the gate**, and the census says what it is: **~34 instructions per edge of per-edge dispatch work in `R_GenerateSpans`** — the leading/trailing
dispatch, `LInsertAndExit`, `Lnewtop`, `Lxl_done` — spread over 3,500,514 edges. It is now a bounded target rather than a residue.

> **Resolved later the same day by the second pass below.** That remainder is measured, not merely bounded: `Lnewtop` 18.1x, `Lgs_leading` 17.2x, `LInsertAndExit` 12.3x, and the rest smaller. The
> `edge-scan` bucket is now **78% accounted for at 159.2x of the profiler's 203.9x**. Read the map there, not the estimate here.

### Decision 3's 0.66 rate is wrong — the risk was prospective, not realised

Decision 3 (`docs/OPTIMIZATION-PLAN.md:26-45`) says to price at 1.0 unless the removed instructions include memory operands, "in which case **0.66 is the measured rate for that mix**". **Six fresh measurements do not support any rate
below 1.0.** The mixes span the whole range:

- `entry` is half global loads (`movl C(surfaces),%ecx` x3 in six) and measured **0.9957** — the *register-only* rate.
- `insert` is **pure memory operand**, four `et_u` loads and compares, nothing else, and measured **0.9740** — the lowest of the six, and still nowhere near 0.66.

So the discount does not track "has memory operands". Re-deriving the ledger's own source figure shows where 0.66 came from: `0.030368 s x 33.445 MHz / 1,543,048 = 0.658`, but 1,543,048 is the instruction count of
the *promoted mip-1 flat path*, not of any removed instruction set. The hoist that actually got promoted removed 712,176 instructions and measured `0.020884 s` = **0.9807**. **Actionable rule: price
everything at 1.0.** It is the conservative direction (a higher price admits more candidates, and the timedemo is still the only thing that promotes), and six measured mixes now say 1.0 is also the *correct*
one.

**Correction to this entry's own first claim, made after checking rather than assuming. It was not costing past candidates.** The re-screen is pure arithmetic and it comes back clean:

| candidate | instr | at 1.0 | at 0.66 | ledger recorded |
|---|---:|---:|---:|---:|
| A mip-2 h-flat block | 188,640 | **0.0095%** | 0.0063% | 0.0095% |
| B mip-3 h-flat block | 11,820 | **0.0006%** | 0.0004% | 0.0006% |
| D fully-flat `%dh` hoist | 158,578 | **0.0080%** | 0.0053% | 0.0080% |

Every recorded figure is the **1.0** column. The 0.66 was applied to exactly one candidate — C, in the screening table's first draft — and was caught and corrected inside that same pass, which is why C reads 0.0360% there rather
than 0.029%. So no recorded candidate price is wrong, and the bundle path's exhaustion does **not** rest on the bad rate: it rests on measured figures for `GibTrail` (0.0119%) and `Turbulent8` (0.0344%) and on
A/B/D being 5-83x under the gate at the correct rate.

**What the error actually cost is standing guidance.** Decision 3 told the next pass to price memory-operand mixes at 0.66, and six measurements now say that is wrong by up to 50%. Any *future* screening that took
the prose at face value would under-price by that factor. That is the whole damage, and it is why Decision 3 was replaced rather than merely annotated.

### Four probe traps, each of which cost a build-and-run cycle

1. **A dead register is not a safe address — it must also be initialised.** The `insert` probe first read `et_u(%esi)` because `%esi` looked dead in the search loop. It **faulted the run**: `%esi` is dead but
   *uninitialised* on the first pass through `LContinueSearch`, not written until the second probe's `movl et_next(%ecx),%esi`. The probe now reads `%ecx` only.
2. **`mov mem,mem` is not encodable on x86.** The `emit` probe was first written against a `.data` scratch long; gas rejects all six lines with `too many memory references`. The block has no free register, so it
   now borrows `%eax` across a `pushl`/`popl` pair, which is counted inside the seven.
3. **Place a probe *before* any instruction whose flags a later branch reads.** In both sort loops `jge`/`jg` and `jne LInsertAndExit` consume the flags of the real `cmpl st_key(%esi),%eax`. The probe goes above it.
   In the `step` loop, **drop the store**: duplicating `movl %eax,et_u(%edx)` would advance `et_u` twice and diverge the run. That is the whole reason a probe on mutating list code copies compute and never stores.
4. **Confirm `control` against the object, not the source.** Both revisions of `r_edgea.s` were assembled with the pinned toolchain and the disassembly diffed: **377 instructions each, zero differences.** The only two
   lines `Compare-Object` reports are objdump's own filename header. A `#ifdef` probe that leaks into `control` would be caught here and nowhere else.

Also recorded: this host produces **isolated ~0.36 s timedemo outliers** (seen in four separate control blocks here and in the baseline re-measure). Every pair was analysed on medians, and each probe block's two
non-outlying runs agree to <=0.00006 s. Any future single-run timedemo on this machine should be treated as suspect.

### What is NOT closed, and what is inadmissible

`edge-scan` is **re-opened**, not converged: 88.8x the gate is measured and the remaining 115x is bounded and named. `R_GenerateSpans` and `TrailingEdge` are the targets — they are now known to be worth 20.9x, 19.7x
and 13.4x on their own, and the 53%-of-calls-emit-nothing ratio is a structural fact no previous entry had. The **bmodel 1/z sort is excluded on principle, not on price**: 66,723 calls of a ~50-instruction
block that is ~40 x87, which is the blind axis (Decision 1). Pricing it with an integer probe would measure the integer subset and silently ignore the FP majority, so it is not probed.

`renderface` (under "**`renderface` priced by premise**", 226,000 cy/frame = 221x the gate) is untouched and still closed for lack of a named hypothesis. Unlike `edge-scan`, a C probe prices *named statements*, so it needs the hypothesis first;
that closure is correct and stands.

**Baseline unchanged: 59.160513 s median** over three runs (59.160645 / 59.160513 / 59.523401, the third an outlier), against the recorded 59.160558 s — a 0.00008% difference, i.e. noise. Checksum `1047377823`
on every run, `bench486` PASS with end checksum `2378409472`, DOS smoke clean, 969 frames throughout. Release is unchanged in fact, not only in intent: `-EdgeScanProbe control` assembles
instruction-for-instruction identical to the pre-probe tree.

### The per-edge dispatch remainder, decomposed (2026-10-02, second pass) — `edge-scan` is now 78% mapped and the "115x unmeasured" is closed

The entry above left **115.1x the gate unmeasured**, identified only as "~34 instructions per edge of per-edge dispatch in `R_GenerateSpans`". That is now measured. Eight more counters name which path each of the
3,500,514 edges takes, and the dispatch accounting **closes exactly**:

```text
leading-only 1,262,511 + both 1,202,992 + trailing-only 1,035,010 = 3,500,513 = genspans
```

`Lgs_leading` (2,465,503) minus the 1,202,992 "both" cases accounts for every leading edge, and `LInsertAndExit` (2,465,403) is reached once per leading edge — the shortfall of 100 is exactly
`xldone`, the inverted-bmodel exit. Three more probes priced the largest blocks:

| probe | block | probe instrs | delta | **rate** | vs 1.0 pred | delta/spread |
|---|---|---:|---:|---:|---:|---:|
| `newtop` | `Lnewtop` span fill | 7,280,496 | +0.214485 s | **0.9856** | 1.3% | 4,663x |
| `leadin` | `Lgs_leading` dispatch | 14,793,018 | +0.436852 s | **0.9878** | 1.2% | 9,928x |
| `insertexit` | `LInsertAndExit` | 14,792,418 | +0.436770 s | **0.9876** | 1.2% | ~29,000x |

The `insertexit` control block's **first run was the isolated outlier** this file records elsewhere (59.430366 against 59.160562 / 59.160577); the other two agree to 0.000015 s, so the ratio is
~29,000x against the clean spread, not the 2x the raw three-run spread prints. Median, never mean.

**Nine probes, nine mixes, mean rate 0.98657, range 0.9740–0.9957, spread 2.20%.**

### The complete `edge-scan` map — 78% of the bucket accounted for

| block | src | instr/run | cyc/frame | x gate |
|---|---|---:|---:|---:|
| `step` `LNextEdge` loop | M | 23,338,968 | 23,762 | **23.2** |
| `entry` `Lgs_edgeloop` prelude | M | 21,003,084 | 21,384 | **20.9** |
| `emit` span emit block | M | 19,820,363 | 20,180 | **19.7** |
| `newtop` `Lnewtop` span fill | M | 18,201,240 | 18,531 | **18.1** |
| `leadin` `Lgs_leading` dispatch | M | 17,258,521 | 17,571 | **17.2** |
| `trailing` `TrailingEdge` dispatch | M | 13,428,012 | 13,671 | **13.4** |
| `insertexit` `LInsertAndExit` | M | 12,327,015 | 12,550 | **12.3** |
| `nextedge` `Lgs_nextedge` advance | S | 10,501,539 | 10,692 | 10.5 |
| `insert` `LContinueSearch` | M | 6,385,032 | 6,501 | 6.4 |
| `sort` `Lsortloop*` | M | 5,289,117 | 5,385 | 5.3 |
| `"both"` `call TrailingEdge` | S | 2,405,984 | 2,450 | 2.4 |
| `trailpush` `Lgs_trailing` | S | 2,070,020 | 2,108 | 2.1 |
| `lastspan` `Lgs_lastspan` | S | 2,064,160 | 2,102 | 2.1 |
| `bmodellead` `Lbmodel_leading` | S | 1,546,352 | 1,574 | 1.5 |
| `resetspan` `Lgs_resetspanstate` | S | 910,004 | 927 | 0.9 |
| bmodel 1/z sort (40 of 50 are x87) | S | 3,332,200 | 3,393 | 3.3 *(inadmissible)* |
| **total accounted** | | | **162,780** | **159.2** |
| profiler `edge-scan` | | | 208,581 | 203.9 |
| **residual** | | | **45,801** | **44.8** |

`M` = measured by its own probe. `S` = priced with the measured 0.98657 mean rate against a static instruction count, which is weaker evidence and labelled as such. The 44.8x residual is
`edge-scan` scope overhead, `R_RecursiveTriangle`, call entry/exit, and the error in the per-block instruction estimates.

**So `edge-scan` is no longer an unknown at all.** It is sixteen named blocks, the largest 23.2x the gate and the smallest 0.9x, with 78% of it measured and the rest statically priced. That is a
different object from "8% of frame, cannot be decomposed", and it is what the twenty rejected micro-experiments never had.

### A fifth probe trap, and it is a different failure from the other four

The `leadin` probe first sat at the `Lgs_leading` label and **faulted the run**. `%edi` is a 16-bit surface *index* there, not a pointer — `shrl $16-SURF_T_SHIFT,%edi` and `addl %eax,%edi` two instructions later are
what make it one — so `st_spanstate(%edi)` was a wild read. The probe moved to `LPatch2`.

That makes three distinct "the register looked free" failures, and they are not the same mistake: **dead but uninitialised** (`%esi` in `LContinueSearch`), **dead but not yet a pointer** (`%edi` at
`Lgs_leading`), and **`mov mem,mem` is not encodable** (the `emit` block). The general rule they share: a probe may only read through a register that is dead **and** initialised **and** already
dereferenceable at that exact instruction. The full list is now five, and it is at the top of this file because every one cost a build-and-run cycle.

### What this does and does not license

It licenses saying where the time is. It does **not** license a candidate. Read the map against the prohibition list and the honest reading is discouraging: every block above 5x the gate is hand-tuned
assembly that has already absorbed the micro-optimisations this file records, and the three largest per-edge blocks are structurally minimal — `Lgs_nextedge` is three instructions (advance, compare
sentinel, branch) and nothing can come out of it; `LInsertAndExit` is four stores and one load and all five are load-bearing for a doubly-linked list; `Lgs_leading`'s `st_insubmodel` load and test is
the bmodel dispatch and 92% of edges take the not-bmodel side of it.

The one structural observation the map makes available, offered as a lead and **not** as a candidate: **`Lnewtop` and `TrailingEdge`'s emit block are two copies of the same six-field span fill**,
running 1,213,416 and 1,043,177 times respectively for 37.8x the gate between them. Unifying them is a code-size argument, not an instruction-removal one, so under Decision 2 it has no price yet. It would
need a source-level hypothesis before a probe could be aimed at it — the same discipline that keeps `renderface` correctly closed.

**Baseline unchanged: 59.160594 s median** over three runs (59.160642 / 59.160538 / 59.160594, spread 0.000104 s, no outlier this time), against the recorded 59.160558 s — a 0.00006% difference.
Checksum `1047377823` on every run, `bench486` PASS with end checksum `2378409472`, DOS smoke clean, 969 frames throughout. `-EdgeScanProbe control` assembles instruction-for-instruction
identical to the pre-probe tree: 377 instructions, zero disassembly differences, and each probe value adds exactly the 6 instructions it claims.

### `renderface` priced (2026-10-02) — **CLOSED with a price**, and the 1.0 cycle rate is not a constant

The second-largest pool at 226,000 cy/frame (221x the gate) was closed under "**`renderface` priced by premise**" for *"large pool, but the x87 in it is essential work; no probe built"*, with the honest note *"a price was notobtained and none is claimed."* It has now been priced, and two results came out of it — one expected, one that corrects this project's screening method.

**First, the free kill.** The obvious hypothesis was the double `edge_p - r_edges`: the cache-validation test computes it, and the clip branch then recomputes it into `cacheoffset`, 29 times over. Reading `r_draw.o` with relocations settles it without a build:

```text
2ae: mov    _edge_p,%edx      <- loaded ONCE
2b4: mov    _r_edges,%esi     <- loaded ONCE
2ba: mov    %edx,%edi
2bc: sub    %esi,%edi         <- validation
2c0: jae    2d0
2d0: sub    %esi,%edx         <- store: the ONLY duplication
```

GCC has already hoisted both loads. The entire prize is **one `sub`** per clipped edge, about 0.9x the gate. **Read the object before writing the probe** — this cost one `objdump -dr` instead of a build-and-run cycle. The two hoists one would try next, `currententity->model` and `r_pcurrentvertbase`, are already recorded as tried and reverted -- see the two "Do not retry hoisting" bullets under "**Priority-ordered next steps**".

**Then the probes.** `-RenderFaceProbe control|prologue|edgeval`, three runs per variant plus trailing control, checksum on every run:

| probe | block | count | added instrs | delta | rate |
|---|---|---:|---:|---:|---:|
| `prologue` | per-call clip chain + state init | 215,720 | 11 | +0.038590 s (0.0652%) | **0.5439** |
| `edgeval` | per-edge cache validation, general loop | 684,731 | 7 | +0.170782 s (0.2887%) | **1.1917** |

`renderface-general-edges` is 684,731 of 1,077,059 — the general loop covers 63.6% of edges, the unrolled 3- and 4-edge blocks take the rest, which is why the probe is priced per general-loop edge and not scaled.

### The rate is a dependency property, not a constant — this is the important result

Nine assembly probes (the `edge-scan` pass) spanned nine mixes and landed **0.9740-0.9957, mean 0.9866**. Two C probes, same harness, same timedemo, give **0.5439** and **1.1917** — a factor of 2.2 between them.

The three groups are not the same measurement:

- **0.9866 (nine assembly probes): tight loops whose every instruction depends on the previous one.** Each removed instruction removes a cycle of latency. This is the rate the project's candidates are screened at, and it is the right number for assembly.
- **0.5439 (`prologue`): straight-line C whose instructions are independent of the surrounding work.** They issue into slots that were already idle, so removing one costs *less* than a cycle.
- **1.1917 (`edgeval`): a loop whose sink increment is a loop-carried dependency on one global.** Serialised across iterations, so each costs *more* than a cycle.

**So Decision 5's "price everything at 1.0" is right for assembly and carries roughly ±40% error for C — in both directions.** A static C estimate at 1.0 can overstate the prize by nearly half, or understate it by a fifth, depending on whether the candidate sits in independent straight-line code or a serialised loop. Nothing in this file's static estimates was computed on a C mix, so no recorded price is wrong, but the method's error bar for C is now known and was previously assumed to be zero.

### What the price does to `renderface`

Priced with the rate that matches each mix:

| block | instructions | rate | cyc/frame | x gate |
|---|---:|---:|---:|---:|
| per-edge cache validation, general loop | ~14 x 684,731 | 1.1917 | ~11,800 | **11.5** |
| per-call prologue | ~36 x 215,720 | 0.5439 | ~4,360 | **4.3** |
| **priced C scaffolding** | | | **~16,200** | **~15.8** |
| the entry estimated at 70-90x | | | 70,000-90,000 | 70-90 |
| `renderface` total | | | 226,000 | 221 |

**The "30-40% of the bucket, 70,000-90,000 cycles/frame" estimate was high by 4-5x.** Two reasons, both checkable: `probe: only 7 of the 14 instructions survived, because GCC CSE'd half my duplicate against the real code — which is direct evidence that the block has little redundant work left, and the remainder of the 221x is the `R_ClipEdge` / `R_EmitCachedEdge` calls, which is the essential x87 edge emit and inadmissible under Decision 1.

**`renderface` is therefore closed by price, not by argument.** Do not re-open it. The per-call prologue is 4.3x and the per-edge validation 11.5x; both are ordinary C state setup and cache-validity tests that the code genuinely needs, `-O3` has already taken the available common-subexpression wins, and the two hoists a reader would reach for first are logged as reverted.

### Two probe mechanics specific to C, both of which would have produced a silently wrong number

1. **`-O3` deletes a probe that writes to a dead local.** The store is provably dead, so the "probe" compiles to nothing and measures zero while appearing to run. A C probe must accumulate into an **external** global that something reports — `bench486_rf_probe_sink`. The sink's value doubles as the execution count, so a probe that got elided reports 0 instead of lying.
2. **Compare the assembled probe against assembled `control`, and expect the compiler to fold part of your duplicate.** `prologue` attempted 12 and added 11; `edgeval` attempted 14 and added 7. The shortfall is not a bug in the probe, it is the compiler telling you the block was already shared — which is itself the answer, and is why the count must come from `objdump` and not from the source.

**Baseline unchanged: 59.160535 s median** over three runs (59.160577 / 59.160535 / 59.160503, spread 0.000074 s), against the recorded 59.160558 s — 0.00004%, noise. Checksum `1047377823` on every run, `bench486` PASS with end checksum `2378409472`, DOS smoke clean. `-RenderFaceProbe control` compiles to **1,651 instructions in `R_RenderFace`, identical to the pre-probe object**.

### The span16 per-segment setup is 2.37% of frame and contains no x87 at all — **`texture-spans` is re-opened**

`texture-spans` is the largest bucket in the renderer at ~24% of frame, and it was closed on the argument that *"the time is in the setup, not the loop"* and the setup is *"dominated by two x87 stores per segment — a blind axis"*. That is the one remaining closure resting on an unexamined premise rather than a measurement, so it got probed.

**The x87 claim is false for the setup path.** `d_draw16.s` carries 125 x87 instructions out of 619 (**20.2%**), and they are spread across the whole function — the entry divide, the `LNotLastSegment` advance, the tail path. The per-segment integer setup from `LSpan16RowCrossFallback` through `LSetUpCommon` contains **zero** of them.

| probe | block | count | added instrs | delta | rate |
|---|---|---:|---:|---:|---:|
| `setup` | head of the per-segment setup | 2,059,018 | 6 | **+0.365979 s (0.6186%)** | **0.9908** |

9,891x the run spread, trailing-control drift −0.000009 s, predicted 0.36917 s against 0.365979 s measured — **0.86% error**. The rate is the tenth consecutive assembly measurement inside 0.974–0.996, so Decision 5's 1.0 is confirmed on a twelfth probe.

**Six instructions of setup cost 0.62% of frame.** The whole integer setup path is ~23 instructions, which scales to **2.37% of frame — 47x the promotion gate.** That is a larger pool than anything `edge-scan` or `renderface` offered, and it is integer, measurable, and admissible.

### Four candidates the pool suggests, and why all four are dead

Recorded so the next pass does not re-derive them:

1. **Hoist `advancetable`/`tstep` out of the segment loop.** This is the *kept* 88.9 ms win in `D_PolysetDrawSpans8` (row "Polyset span advancetable hoist" under "**Completed experiments and decisions**"), applied to the wrong function. Here `advancetable[0]` and `[1]` are computed from `(t - t_start)` and `(s - s_start)`, so **they change every segment by construction** and cannot be hoisted. The parallel is misleading and should not be re-tried on the strength of the other function's result.
2. **Fuse the `s` and `t` clamps into one unsigned range check.** `(unsigned)(v - 4096) > (bb - 4096)` is 3 instructions against the current 4, and there are two clamps — nominally 2 instructions per segment, **0.206% of frame, 4.1x the gate, which would clear on its own.** It does not work: the form needs a scratch register to hold `v - 4096` because subtracting in place destroys the running accumulator. `%eax` *is* free across lines 364–432, but the `movl %ebp,%eax` that gets it there costs exactly the instruction the fusion saves. Four for four. This one is worth re-attempting only if a register can be freed elsewhere first.
   > **CORRECTED and then MEASURED, 2026-10-03 — see the clamp-fusion entry at the top of this file. Two separate errors, in this order.** (a) The "Four for four" arithmetic is wrong: `leal -4096(%ebp),%eax` puts the biased value in the scratch register in **one** instruction, so the clamp really is 3-for-4, and no register needs freeing anywhere else. The candidate was therefore buildable, and was built. (b) It then **measured 0.0000%** against a 0.206% model prediction — 4,118,036 instructions removed bought 12 microseconds — while a probe adding four instructions of the identical shape into the identical path was charged **0.988 cycles each**. **The candidate is dead, but not for the reason recorded here, and the "worth re-attempting if a register can be freed" advice is dead with it. Do not rebuild it.** What survives from this item is the general form of the mistake: a scratch register does not have to be *moved* to and then modified. Re-read every closure in this file resting on a register move costing what a transformation saves.
3. **Drop the `fistpl snext` / `fistpl tnext` / `movl snext,%eax` / `movl tnext,%edx` sequence in `LSpan16`/`LSpanLoop`.** Architecturally impossible: `FIST` has no register destination on a 486, it only writes memory, so the store-then-reload is forced.
4. **Widen the segments to amortise the setup.** The A/B halves already amortise the expensive x87 advance — `LSpan16AfterStoresA` does `LSetupNotLast2` (x87 only) and falls straight into the B stores with **no integer setup between them**. The measured 2,059,018 setup executions are the ground truth and nothing in this structure reduces them.

**So: a 47x-gate pool, and no candidate.** The honest position is that the setup is ~23 necessary instructions of DDA — advance s/t, derive the two advance-table entries from the position within the span, left-justify the fractions, accumulate, and select the T carry. That is not the same as saying no candidate exists, and it is a much better place to look than anywhere else in the renderer.

**Do not close `texture-spans` again on the x87 argument.** If it is re-closed, re-close it on a measurement.

> **And do not close it on instruction count either — that is what the 2026-10-03 pass measured.** Candidate 2 above was built, correctly and bit-exactly, and returned **0.0000%** while a probe proved the region charges 0.988 cycles per instruction *added*. The region is not reachable by removing instructions at all; it is dependency-bound. The only door is shortening the loop-carried chain, and no one has yet produced a hypothesis for that. See the clamp-fusion entry at the top of this file.

Verification: `-SpanSetupProbe control` assembles `d_draw16.o` to **619 instructions, zero disassembly differences** from the pre-probe object. Baseline **59.160569 s** median over three runs against the recorded 59.160558 s — 0.00002%, noise. Checksum `1047377823` on every run, `bench486` PASS with end checksum `2378409472`, DOS smoke clean, 969 frames. Probe plumbing added to all four runners; default `control`.

### Process rule (2026-10-03): **cite this file by heading, never by line number**

An audit of every line-number citation in the entries added on 2026-10-02/03 found **ten of twelve wrong.** Each had been verified when written, and each was invalidated by a *later* insertion above it in this same file. This is not carelessness; it is arithmetic that cannot stay correct in a document that grows every time it is edited, and this project has now paid for it three separate ways — `8da4eb1` "re-anchor the plan of record's ledger citations", this pass, and the stale `2491-2759` range in the plan of record.

**Rule: reference this file by heading text or a distinctive quoted phrase, never by `:NNNN`.** When pointing at a section, name it:

> good: under "**`edge-scan` cannot be decomposed**", in the row "Polyset span
> advancetable hoist" under "**Completed experiments and decisions**"
>
> bad: `ASM486-HANDOFF.md:1851`, `:3025`, `:3744`

The same applies across files. `BUILD-DOS.md` and `docs/OPTIMIZATION-PLAN.md` had bare `:NNN` pointing into this ledger without even naming it, which is how a reader ends up reading a probe table when the text meant a different entry entirely. **Cross-file references must name the file and the heading.**

Two further anchors that were wrong and are now right, worth recording because they are *load-bearing* rather than decorative:

- **`timedemo-dos.ps1` enforces the profile-hash gate at `:576`, against `-ExpectedProfileSha256` at `:117`** — not `:548-556`/`:104` as three places claimed. The *claim* (it is enforced) was always true; only the anchors rotted. Verified by grep, not by counting.
- **`BUILD-DOS.md` is the place to look for which scripts exist and what they enforce**, not the reverse; its own instructions now say to grep `ExpectedProfileSha256` rather than trust a line number.

If a line number genuinely must appear, it is a comment in the *target file*, not in prose about it — a comment next to the code moves with the code.

### Standing hazard found on the way: the profile reporter's JSON buffer is also over its limit

The known `char text[1024]` overflow (under "**`char text[1024]` in the profile reporter**") has a twin. The `metrics` object in `Bench486WriteProfileJson` is one `Bench486ProfileJsonPrintf` call whose format literal is **1,671 bytes with 88 `%lu`
conversions — a worst case of 2,551 bytes against `char text[2048]`**. It survives on every value being shorter than ten digits (longest observed line 898). Less urgent than the 1024 case, which has only 24 bytes
of headroom, but the same class. Both new counters were added as **their own report call**, per that entry's own rule.

### `surf8` flat axis: three measured wins bundled and **PROMOTED, 0.0620%** (2026-10-02)

The first promotion since the profiler was corrected. Three independently
priced, individually sub-gate changes were bundled, because **the gate is on the
total delta, not on any one change** — three changes worth 0.035%, 0.014% and
0.013% cannot be promoted one at a time and are worth 0.062% together.

| component | what it removes | instructions/run | predicted |
|---|---|---:|---:|
| `SurfaceBlockMip0Rows=unroll16` | the mip-0 row-loop branch, 16 rows per iteration instead of 4 | — | 0.0132% (measured on its own today) |
| `SurfaceBlockMip1IndexHoist=hoist` | 6 of the 8 per-texel `%dh` byte moves in the mip-1 flat row | 712,176 | 0.0353% (measured on its own) |
| ...and its fully-flat body | a second mip-1 flat body for blocks with all four corners equal: the index bytes are formed once per **block** instead of once per row, and the eight no-op `addl %ebp,%edx` steps go | 11,327 × 22 = 249,194 | 0.0126% |
| **total** | | | **0.0611%** |

Three alternating pairs, control first, both from one tree, release defaults
against `-SurfaceBlockMip0Rows unroll16 -SurfaceBlockMip1IndexHoist hoist`:

```text
control: 59.656695 / 59.197208 / 59.197235 s, median 59.197235
bundle:  59.160588 / 59.160522 / 59.160546 s, median 59.160546
delta   -0.036689 s = 0.06198% faster;  969 frames and checksum 1047377823 on all six
```

The first control run is the isolated-outlier pattern recorded elsewhere in this
file; the other two controls spread 0.000027 s, so the delta is 1,359x the clean
spread, and every bundle run beat every control run including the outlier.
`bench486` correctness PASS with end checksum `2378409472`, DOS smoke clean.

**Predicted 0.036716 s from the instruction model against 0.036689 s measured —
0.07% error.** The prediction summed the two previously measured components at
their measured rates and the new one at the 1.0 cycle rate, so
`docs/OPTIMIZATION-PLAN.md` Decision 3 now has three agreeing data points.

**Promoted default re-measures at 59.160558 s median** (59.160558 / 59.160577 /
59.160502), 16.379156 FPS, checksum `1047377823` on all three, with `bench486`
PASS and smoke clean. **New baseline 59.160558 s / 16.379156 FPS**, from
59.197264 s / 16.369000.

**Three traps, each of which cost a build-and-run cycle. All three are
generalisable, and two of them are the reason this entry is long.**

1. *The fully-flat test must come **before** `xorl %ecx,%ecx`.* It was written
   after, next to the call it selects, so `cmpl $0,%ecx` tested a register that
   had just been zeroed, was **always true**, and every horizontal-flat block
   took the fully-flat body. That renders **checksum `3165952421`** — the same
   value, and the same class of error, as hoisting the index bytes to block
   granularity. `lightrightstep` is the value the test needs, so the test belongs
   with the other two that read the pre-clobber register state.
2. *gas does not substitute macro parameters through a nested expansion.* The
   first attempt factored the eight texels into a shared `SURF8_MIP1_FLAT_TEXELS`
   macro called from two wrappers; gas emitted the literal label
   `.LLBPatchm1fsuffix_0` eight times and the assembler rejected it as already
   defined. Two independent single-level macros with disjoint label suffixes
   (lower case for the horizontal-flat body, upper case for fully-flat) is the
   working shape. **Share assembly by copying it; gas macros are not C macros.**
3. *Do not "fix" the `unroll16` patch ladder.* Counting `.long` lines in the
   preprocessed source reads 296 for the `unroll16` configuration against a
   ladder of 408, which looks exactly like a 112-entry overflow and was changed
   to 216 — **and 216 faults.** The ladder was right and the counting method was
   wrong: it agrees with the committed ladder for `unroll4` (216) and `unroll8`
   (280) and disagrees only for `unroll16`. **Count the `0x12345678` immediates
   in the assembled object instead** — 216 / 280 / 408 — which is the number
   `R_Surf8Patch` actually walks. That is also the check that validated the
   fully-flat body's own `+64`, at 472 immediates against 328+16+64+64.

**Verification before any timedemo, both of which earned their keep.** `control`
was confirmed to reproduce the previous release path **instruction for
instruction** — 1,273 instructions, zero differences, 216 colormap immediates —
by assembling both revisions with the real toolchain and diffing the objects,
not by preprocessing (which reports the new macro's definition text as 32
"differences"). And the ladder was checked against the object before building.

**One candidate was built and abandoned in the same pass.** The mip-2
horizontal-flat block (worth 0.0064%, five instructions per row over 3,930
blocks) was written, verified to add exactly four colormap immediates to the
object, and then removed: it rendered checksum `3278041384` and the cause was not
found. It is the same shape as mip-0's and mip-1's flat rows, which are both
promoted, so the bug is in the mip-2 block's own setup rather than in the idea —
but an unresolved regression is not a candidate, and 0.0064% does not justify
shipping one. `R_DrawSurfaceBlock8_mip2` still uses its general loop.

### The Z-span integer probe, measured and retired (2026-10-02) — the harness charges 1.0 cycles per instruction, and the x87 axis stays inadmissible

An uncommitted `-ZSpanIntProbe` switch was in the tree at the start of this
pass: 22 dead integer operations per Z-span in `d_draw.s`, wired into
`build-dos.ps1` and `timedemo-dos.ps1`, never actually run. It prices a bit-exact
integer replacement of the 1/z prologue. Three alternating pairs, control first,
both variants from one tree, no `-SkipBuild` (the switch is in the profile suffix
and the build fingerprint, so each variant rebuilds itself and a probe run cannot
measure a control binary):

```text
control: 59.197254 / 59.197244 / 59.197260 s, median 59.197254   zspan-int-probe 0
probe:   60.208521 / 60.208489 / 60.208529 s, median 60.208521   zspan-int-probe 1415815
delta    1.011267 s = 1.7086% SLOWER;  969 frames and checksum 1047377823 on all six
```

**The number worth keeping is the divisor, not the delta.** The probe body is 24
instructions and ran 1,415,815 times — 33,979,560 instructions for 1.011267 s, at
33.445 MHz:

```text
1.011267 s / 33,979,560 instructions = 2.9765e-8 s  =  0.9955 cycles per instruction
```

**DOSBox-X's dynamic core prices straight-line integer work at essentially exactly
one cycle per instruction**, regardless of the operation: that chain is seven
`imull r,r` (three cycles each on a 486DX), seven `shrl`, seven `addl` with a
memory operand, two loads and one `incl`, and it still averages 0.9955. Set that
against the Z-span prologue's own measured 9.4 cycles for nine serialized x87
operations (`:819`) — 1.04 cycles per x87 op. **An integer replacement of the
prologue therefore has a break-even of fewer than 9.4 instructions**, and a
bit-exact reciprocal needs more than that: the prologue rounds to single precision
after each of three float operations, so an integer version has to reproduce that
rounding. The axis is closed by measurement. Do not resurrect it.

This also gives the project a calibration constant it did not have, and it is the
same currency every later entry prices in: **~1.0 cycle per removed instruction**,
against the 0.66 that the promoted mip-1 flat path implies for its own mix (13
instructions per row including two global loads and a store, 1,543,048 instructions
for 0.030368 s). Quote the rate that matches the instruction mix under
consideration; 1.0 is the conservative one.

The probe, its switch and its plumbing have been **removed from all four files**,
and the tree is back to a clean two-state-plus-instrumentation configuration.
Release re-measured on the final tree at **59.197237 s** median (59.197237 /
59.197223 / 59.197255), checksum `1047377823` on all three, against the promoted
59.197264 s — a 0.00005% difference, i.e. noise. New baseline unchanged:
**59.197264 s / 16.369000 FPS**.

**Two tooling traps this probe walked into, both worth not walking into again.**

1. *A dead-scratch probe must report its execution count, not its scratch value.*
   The first revision did `addl %eax,bench486_zspan_probe`, which reports the sum
   of the accumulated scratch and read `191,564,989` — a number with no
   denominator. There is no compiler in a `.s` file that could eliminate the dead
   chain, so a plain `incl` is both sufficient and the only reportable quantity.
   The comment in that block also claimed 32 operations where there are 24.
2. *`Bench486Printf` is the wrong helper inside `Bench486WriteTimedemoCounters`.*
   It writes to `bench486_report_handle` (`bench486.txt`), which a timedemo run
   never opens; the function's argument is `report_handle`, the `timedemo.txt`
   handle opened at `cl_demo.c:380`. The probe count reached the console and not
   the report, and was invisible to the run JSON. Anything reported from that
   function must go through `report_handle`.

### The `surf8` horizontal-flat axis, screened (2026-10-02) — four candidates, two closed by price

The mip-1 promotion was the mip-0 specialisation applied one level down. The
obvious continuation is to apply it to the remaining levels, and then to tighten
the mip-1 path itself. Both are priced here from counters already in the tree
(`r_surf.c:845-882`) and the calibration above. **No code was built**; this is the
screening rule at `docs/OPTIMIZATION-PLAN.md` Decision 2 applied before building.

The structural asymmetry that motivated candidates C and D: **mip-0's flat row
already hoists its colormap-index bytes and uses byte stores**
(`surf8.s:457-458` puts `movb %dh,%bh` / `movb %dh,%ch` once per row, ahead of the
16 texels), while **mip-1's flat row does neither** — `SURF8_MIP1_FLAT_ROW`
(`surf8.s:822-860`) is the general row with the light updates deleted, so it still
issues 4 + 4 of those byte moves per eight-texel row and packs through `%eax` and
`rorl $16`. Both were written after the fact; only one of them was finished.

| candidate | mechanism | removed instr/run | price at 1.0 cy | vs the 0.05% gate |
|---|---|---:|---:|---:|
| A | mip-2 horizontal-flat block, 4×4 | 3,930 × 4 rows × 12 = 188,640 | 0.00564 s = **0.0095%** | 5.2× under |
| B | mip-3 horizontal-flat block, 2×2 | 591 × 2 × 10 = 11,820 | 0.00035 s = **0.0006%** | 83× under |
| C | hoist the two `%dh` byte moves out of `SURF8_MIP1_FLAT_ROW`, 31 → 25 instructions per row | 118,696 × 6 = 712,176 | 0.02129 s = **0.0360%** | **built and measured below** |
| D | fully-flat blocks hoist `%dh` once per block instead of once per row (`fully_flat_per_mip[1] = 11,327`) | 11,327 × 14 = 158,578 | 0.00474 s = **0.0080%** | 6.2× under |

**A and B close. C was built and measured: 0.0353%, real, reproducible, and
below the gate, so it is rejected — see the entry below. D closes at 6.2× under.**

One correction this screening produced, which matters more than any of the four:
the first draft priced C and D at 0.66 cycles per instruction and concluded
0.029% — a refusal. **The 0.66 is the rate implied by the promoted mip-1 mix** (13
instructions per row including two global loads and a global store). C removes
**register-only partial moves**, which is much closer to the probe's straight-line
mix, and the probe measured that at 0.9955. At the measured rate C is 0.036%, and
building it confirmed the model to 2%. **Price a candidate at the rate that
matches its own instruction mix, or the screening is wrong by 50%** — and at
0.029% the decision would have been to not build something that turned out to be
a clean, bit-exact, reproducible win.

### mip-1 flat-row index hoist (2026-10-02) — **0.0353% alone; promoted at 0.0620% as part of a bundle**

> **Superseded by the entry above.** This change was measured on its own first,
> at 0.0353% — real, bit-exact, reproducible, and **below the 0.05% gate, so on
> its own it is not promotable.** It was later bundled with `unroll16` and a
> fully-flat variant of the same path, and the bundle cleared the gate at
> **0.0620%** and is now the release default. The measurements below stand; the
> conclusion "rejected" applies only to the isolated change.

Candidate C from the entry above: `SURF8_MIP1_FLAT_ROW` re-forms the two
colormap index registers with four `movb %dh,%bh` / `movb %dh,%ch` pairs per
eight-texel row, and `%dh` is invariant across the row, so two instructions at
the top of the row replace eight. mip-0's flat row has had this shape since it
was written (`:457-458`); mip-1's was only ever the general row with the light
updates deleted.

An opt-in `-SurfaceBlockMip1IndexHoist control|hoist` selector was added to all
four runners for a matched A/B, with `control` reproducing the previous body
**byte-for-byte** — verified by preprocessing both revisions with the real
toolchain and diffing: 1,066 instruction lines, zero differences. Do not skip
that check on an ASM selector; see the two bugs below.

Three alternating pairs, control first, both from one tree:

```text
control: 59.197249 / 59.197235 / 59.197244 s, median 59.197244, spread 0.000014
hoist:   59.176362 / 59.176285 / 59.176354 s, median 59.176354, spread 0.000077
delta   -0.020890 s = 0.03529% faster;  969 frames and checksum 1047377823 on all six
```

Every candidate run beat every control run and the delta is 271x the control
spread, so the effect is real and not noise. **It is below the 0.05% gate on its
own, so it was not promotable on its own.** The selector was withdrawn, the
release path restored to byte-identical with `b99a7ea`, and the change re-applied
later as one component of a bundle that does clear the gate — see the entry at
the top of this section. The selector is back, and `-SurfaceBlockMip1IndexHoist
control` now reproduces exactly the body measured here.

**The calibration got a second, independent confirmation.** 712,176 instructions
for 0.020890 s is 2.9335e-8 s each, or **0.981 cycles per instruction** — against
the 0.9955 the Z-span probe measured on a completely different mix (seven
`imull`, seven `shrl`, seven `addl` with a memory operand). Two unrelated
instruction mixes, 1.5% apart. **1.0 cycle per removed instruction is a sound
screening rate for this harness**, which is the number most future screening
will need.

**Two bugs, both worth more than the win.**

1. *The hoist has to be per **row**, not per unrolled block.* The first version
   put `movb %dh,%bh; movb %dh,%ch` at the top of `LSurf8Mip1HorizontalFlatRow`,
   outside the eight unrolled `SURF8_MIP1_FLAT_ROW` invocations. That rendered
   **checksum `3165952421`**, deterministically and reproducibly. The cause is
   that each row's trailing `addl %ebp,%edx` advances the light to the next
   scanline: `%dh` is invariant *within* a row and varies *between* rows, so
   rows b..h were all indexing the colormap with row a's light byte. The
   instruction-level argument said the transform was equivalent and the
   instruction diff confirmed it removed only the 62 intended instructions — the
   mistake was one level of granularity up, in a place the diff could not see.
2. *`#error` is inert under `-x assembler-with-cpp`.* A sentinel of the form
   `#ifdef X` / `#error` / `#endif` was used to check that a selector's `-D` flag
   reached the preprocessor, and it reported "not reached" for a define that was
   demonstrably present. Use an `#ifdef`-guarded **literal** as the sentinel
   instead; that works.

**The premise was measured, not assumed.** `bench486_surf8_flat_dh_moved` reads
**0 of 118,712** flat rows, confirming `%dh` really does hold still across a
row's eight texels. Note that the counter must sample at the top and bottom of
**each row**: sampling once per unrolled block makes every row with a non-zero
vertical step look like a violation, and reported 12,819 false positives on the
first attempt. The counters are kept — they are free, and they are the evidence
for this entry and the guard against anyone retrying the block-granularity form.

Two readings from the same profile data that are worth not misreading again:

- **`surface-cache` has no prize in `D_CacheSurface`.** The report shows 472
  cycles per cache *hit* (`hit_seconds` 0.656079 s over 46,483 hits), which looks
  like a 0.86%-of-frame lookup cost. It is the profiler. `miss_check_seconds`
  measures 574 cycles for the *identical* code prefix, and 574 is three times the
  measured 193.3-cycle `Sys_FloatTime` read. The hit path simply takes fewer reads
  than the miss path. The lookup is `D_CacheSurfaceHit_asm486` and costs nothing.
- **`D_DrawSpans8` is dead in the timedemo.** `d_subdiv16` defaults to `"1"`
  (`d_init.c:27`) and nothing in the C tree sets it to 0, so `d_drawspans =
  D_DrawSpans16` at `d_init.c:164`. The proof is not the cvar: it is that
  `bench486_texture_full_tzero` reads 1,025,646 and that symbol is `.extern`'d
  only in `d_draw16.s`. `d_draw.s`'s `D_DrawSpans8` and its `Entry2_8..Entry8_8`
  table are unreachable in this workload — roughly 30 KB of `.text` that the cost
  model would count as cache displacement. That is a **blind axis**, so deleting
  it is inadmissible as a performance claim; it is code hygiene, and a separate
  change from anything in this pass.

### The unit-stride span premise is zero (2026-10-02) — `texture-spans` is closed, and the arithmetic says why every earlier attempt failed

`texture-spans` is the largest admissible pool in the renderer at **24.0% of
the profiled frame** (18.979 s of 79.169 s, 1,454,455 spans, 43,956,265 pixels)
and the only one never premise-measured. The hypothesis was the one structural
specialisation the inner loop still admits. Three counters were added to `d_draw16.s` — plain
increments, no timer reads, behind the existing `PROFILE486` guard and the
established `bench486_profile_frame_active` test (`:445`, `:472-473`, `:504`) —
and one instrumented run decided it.

The segment loop is 11 instructions per two pixels under the promoted word-store
build (`LSpan16ControlStoresA`, `d_draw16.s:674`): two texel loads, a store, and
per texel `addl tstep,%edx` / `sbbl %ecx,%ecx` / `addl %ebp,%ebx` /
`adcl advancetable+4(,%ecx,4),%esi`. A segment whose t step has no whole texel,
whose s step is exactly one texel, and whose s step has **no fractional part**,
would advance the source by one byte per sample with no carry, collapsing that
four-instruction pair into `addl $1,%esi`. The decision rule was fixed before the
run: at 1.0 cycle per instruction the gate is 1,022.8 × 969 ≈ 1.0 M instructions
per run, so at 1.5 instructions saved per pixel the candidate needed **400,000
pixels** to be worth building.

```text
span-strides segments 2059015 unit-stride-segments 0 unit-stride-pixels 0
full-tzero 1025646  full-sone 194183  full-sfrac-zero 2
```

**Zero.** Not small — zero. Whenever `(sstep>>16) == 1` the fractional part of
`sstep` is non-zero, so the s-fraction accumulator is live on every single one of
the 194,183 candidate segments and the carry chain cannot be removed. That is
structural, not incidental: the s fraction is what makes the texture wrap correctly
at a sub-texel rate, so an exactly-unit-stride span does not occur in this
workload. The premise is falsified before any code was written, which is the E4
and bmodel-`FIXME` pattern — and it cost one profile run rather than a timedemo.

**The arithmetic now explains all six earlier texture-span rejections, which is
the more useful half of this entry.** At 1.0 cycle per instruction the inner loop
accounts for 2,059,015 segments × 88 instructions = 181.2M of the 634.7M cycles
in the bucket. That leaves **220 cycles of per-segment setup for every sixteen
pixels** (308 cycles per segment in total), against 5.5 instructions per pixel of
loop — 14.4 cycles per texture pixel for the whole bucket. So:

- **The time is in the setup, not the loop.** The setup is the two `fistpl`, the
  four clamps and the `advancetable` build, and the `fistpl` half is the **blind
  axis**.
- The `norowcross` experiment at `:1821` is the direct confirmation, and its
  accounting is worth carrying forward. It was exercised on **209,338 segments**,
  removed 4 instructions per two pixels from them — 6,698,816 instructions, 36% of
  the loop on 7.6% of the pixels, worth 0.200293 s at the calibration above — and
  measured **0.580537% slower**, 0.344887 s. The candidate's per-segment
  eligibility test (`:375-386`, six instructions) adds 1,256,028 instructions.
  Net: **0.545180 s, 18.2 M cycles, added**, against 6.70 M instructions removed.
  10.3 M cycles of that are in the loop bodies themselves, not the test: the
  non-indexed `adcl advancetable+4,%esi` of the row-cross-free body costs more
  than the control body's indexed `adcl advancetable+4(,%ecx,4),%esi`, which an
  instruction count alone does not predict. **Removing four instructions per two
  pixels from 7.6% of the segments cost eighteen million cycles.**

**So the admissible integer work in `texture-spans` is not in the loop, and the
part that is in the setup is dominated by two x87 stores per segment that this
harness cannot price honestly.** ~~`texture-spans` is closed on the admissible axis
by measurement, not by exhaustion of ideas.~~ A candidate here would have to remove
per-*segment* integer work, which is a narrower description than this file has
given the bucket in any previous entry - and note that the one structural loop
specialisation anyone had proposed is now measured at zero population.

> **The second half of that sentence is now measured FALSE, and the closure does not
> stand.** A dead-scratch probe at the head of the per-segment setup measured the
> setup's integer part at **2.37% of frame, 47x the gate, containing zero x87** — see
> "the span16 per-segment setup is 2.37% of frame" at the top of this file. The 125
> x87 instructions in `d_draw16.s` sit in the entry divide, the `LNotLastSegment`
> advance and the tail path, **not in the setup**, so the setup was never the blind
> axis it was closed as being. `texture-spans` is **re-opened**, and four candidate
> reductions of that pool are recorded there with why each fails. The narrower
> description above — remove per-*segment* integer work — was right; the closure built
> on it was not.

The counters are kept. They are free in release, they are the denominator any
future segment-level idea needs, and `unit-stride-pixels` is a permanent guard
against re-proposing the loop specialisation.

### `char text[1024]` in the profile reporter is at its limit (2026-10-02) — three counters aborted an instrumented run with no error

Adding three fields to the big counter block in `Bench486WriteTimedemoCounters`
(`host_cmd.c:1379`) produced an instrumented timedemo that ran all 969 frames,
wrote its frame line, and then **died silently**: no `profile.jsn`, no
`framebuffer-checksum`, and the runner's only complaint was
`Instrumented Quake did not produce 'profile.jsn'`. The format has 60 `%lu` and
13 `%.6f` conversions in a `char text[1024]`, so its worst case is about **1,350
bytes** — it had been living ~30% over the buffer on paper and surviving only
because every real value is shorter than ten digits.

Three counters were enough to tip it. They now have their own report call
(`host_cmd.c:1470-1477`), and the lesson is the general one: **in this file, add a
field by adding a report call, never by growing an existing format string.** A
stack-smashing `sprintf` in the reporter fails *after* the timedemo has completed,
so it destroys the profile without touching the timing, and it looks like a
harness bug rather than a source bug.

**2026-10-02: the same defect exists a second time, in JSON, and is not yet
recorded here.** The `metrics` object is one `Bench486ProfileJsonPrintf` call with a
1,671-byte format literal and 88 `%lu` conversions — a 2,551-byte worst case against
`char text[2048]` (`host_cmd.c:865`). Longest observed line is 898, so it is not
close, but it is the same class and the same rule applies. Fix when a field is
next added there.

### Harness integrity and the measured fidelity result (2026-09-30) — the gate problem is now measured, not asserted

The conclusion at `:775` — stop optimizing against this harness, because it
cannot see what a 486 pays — is now backed by an executable measurement rather
than an argument. This entry records the tooling that establishes it, because
the next passes depend on it.

**Three harness defects fixed first**, since every other number in this ledger
depends on them:

1. **The stale-binary hazard is closed.** `timedemo-dos.ps1` built only
   `if (-not (Test-Path $benchmarkExe))`, keyed on the selector profile alone,
   so a source edit was silently ignored and the previous binary measured (see
   the warning under "**THE TIMEDEMO RUNNER WILL NOT REBUILD AFTER A SOURCE EDIT**"). It now hashes all 163 `.c`/`.s`/`.h` files plus the
   resolved selectors into a fingerprint stored beside the executable, and
   rebuilds on mismatch. **Note there is no `-Clean` switch** — verified; the
   documented remedy did not exist, and that warning and `BUILD-DOS.md` should be
   read with that in mind.
2. **The recorded-but-unenforced constants now fail the run** (`timedemo-dos.ps1`, grep `ExpectedProfileSha256`).
   `timedemo-dos.ps1` compares the profile SHA-256 against
   `F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45` and gates
   every run on 969 frames and framebuffer checksum `1047377823`. A wrong value
   fails the run rather than reporting a time; `-AllowGateOverride` records a
   deliberate exception and warns.
3. **Per-function attribution is available.** The link strips with `-s`
   (grep `-s` in `build-dos.ps1` for the line), so the header of `486-cost-model.ps1` could only report
   image totals. The build already retains 103 objects under
   `out\dos<profile>\obj-bench`, so the cost model now disassembles those and
   reports per-symbol x87 cost (new section 1b). `-s` is kept; dropping it would
   perturb an already non-reproducible image.

**Four in-engine probes** (`WinQuake\host_cmd.c`, `-benchfidelity`, dispatched
via `+bench486`) whose 486 costs are known, used to judge whether an emulator
prices them at all:

| probe | measures |
|---|---|
| `x87chain` | a serialized x87 chain with a real FDIV, the `d_draw16.s:145-198` shape |
| `fpu fistp32` vs `fist16` | 32-bit against 16-bit float-to-int store; the model prices `fistp` at 39 cy |
| `l1-4096` vs `l1-24576` | 4 KB working set (fits the 8 KB L1) against one that cannot |
| `alias-0` vs `alias-64` | two buffers sharing an L1 set against two that do not; the `vid_vga.c:299-304` shape |

**DOSBox-X scores 0 of 4** (`out\fidelity-dosbox-x.json`):

```text
fidelity x87chain   748.1 ns/op
fidelity fpu fistp32 329.2 ns/op
fidelity fpu fist16  329.2 ns/op     -> 1.000x separation
fidelity l1-4096    179.7 ns/op
fidelity l1-24576   179.7 ns/op      -> 1.000x separation
fidelity alias-0    239.5 ns/op
fidelity alias-64   239.5 ns/op      -> 1.000x separation
```

The three 1.000x results are exact ties, not noise: **DOSBox-X has no cache
model whatsoever**, so neither L1 capacity nor set aliasing can move its clock.
`fistp32` and `fist16` tying at 329.2 ns is the flat-FPU model stated directly.
Only the x87 chain separates, at 2.272x, which is closer to the op-count ratio
than to the latency ratio a 486DX charges.

**This is the correct and expected result.** DOSBox-X remains the **parity gate**
— checksum, frame count, functional correctness — where its flat FPU does not
make it *wrong*, only insensitive. It cannot also price 486 costs, and no
lawful automated harness here can supply that measurement instead, as the
sourcing research below establishes.

**The probes were validated on real x86 silicon, and they are sound.**
`tools\fidelity-probe-host.c` is a host-native build of the same four probes,
runnable with `gcc -O2 -march=native -o out\fidelity-probe-host.exe
tools\fidelity-probe-host.c`. Run on this machine (AMD Ryzen 5 3600, Zen 3):

```text
fidelity x87chain  4.66 ns/op
fidelity fpu fistp32  10.89 ns/op
fidelity fpu fist16    9.58 ns/op   -> fistp32/fist16 = 1.136x   PASS
fidelity l1-4096     0.35 ns/op
fidelity l1-24576    0.46 ns/op   -> 1.342x                    PASS
fidelity alias-0     0.55 ns/op
fidelity alias-64    0.53 ns/op   -> 1.034x                    (below the 1.05 gate)
```

**This is the control the DOSBox-X 0/4 result needed.** The probes do detect a
real FISTPL/FIST latency gap and a real L1 capacity cliff when the hardware has
one, so the ties under DOSBox-X are the *emulator's* blind spots rather than
broken probes. The two that do not separate here fail for an instructive reason:
a Zen 3 has a 32 KB L1d and a hardware prefetcher, so a 4 KB versus 24 KB
working set and a 2048-byte set conflict both sit far below its thresholds.
**The probes are calibrated to 486 geometry; this host is not a 486.** That is
precisely the class of difference DOSBox-X cannot express either.

It also bounds what a modern host can be used for: it can validate probe design,
and it cannot stand in for a 486 reference.

### Legal sources for a 486 machine ROM (not pursued here)

Asked to source a 486 machine BIOS, the answer is that the copyrighted-vendor
images are not something to fetch: every machine profile wants a specific
third-party firmware image (AMI, Award, Phoenix, ALi, IBM, SiS, VIA), and the
sites that host them distribute them without permission. Emulators in this
class state that they will never bundle them, and that position is the correct
one.

What is legitimate, if 486 pricing is wanted:

- **A physical 486 machine**, dumping its own ROM. This is the best option: it
  settles every axis, including the ones no emulator models, and the project's
  ledger already recommends a real 486DX2/DX4 as the honest arbiter.
- **A ROM the user already owns**, from a machine in their possession.
- **A freely-licensed BIOS** where an emulator supports one. 86Box is
  ROM-dependent by design, so this is not a general escape.

None of these is available to an automated pass, which is why the pricing gap is
recorded as measured-and-unclosable rather than forced.

### Sourcing research: the legal-BIOS question, answered (2026-09-30)

Because the ROM route is closed, the obvious hope is a ROM-free emulator that is
still cycle-accurate. Researched and **eliminated**, with the decisive evidence
rather than a summary:

**Bochs ships a GPL BIOS and needs no third-party ROM — and is disqualified by
its CPU model.** Its `bochs/cpu/cpu.h` (6151 lines) has **no data cache
whatsoever**: no `bxDCache`, no `bxCache_c`, no set index, no tag array, no
associativity. The only cache class is `bxICache_c` (`:428-429`, `:1442`), and
that is a fetch-unit trace cache, not a set-associative L1. `CACHE_LINE_SIZE` is
a hardcoded `const 64` (`:421`) used only for UMONITOR alignment (`:879`) — and
64 bytes is wrong for a 486 regardless, which has 32-byte lines. There is no
cache configuration option of any kind. The x87 is softfloat (`i387_t` at
`:1100-1101`, `softfloat_status_t` at `:837`) for correctness only, with no
latency model, and `icount` (`:1002`) is incremented by 1 per instruction
(`:6105-6109`) with **no cycle concept anywhere** — grepping
`cycle|latency|stall|ips` over the whole file returns one hit, an unrelated
comment.

So Bochs would score 0/4 on the fidelity suite, for the same reason DOSBox-X
does: it has no data cache and a free FPU. It also has the wrong line size and
the wrong associativity even if a cache existed. **Do not install Bochs as a
486-cost reference.**

**SeaBIOS is GPL and is QEMU's default, but it does not help.** It targets
QEMU's own virtual hardware (i440fx/q35, `fw_cfg`, virtio) and is used by no
period-ISA emulator, so it is not a general escape. QEMU's TCG is, like DOSBox-X,
an instruction-count model with a flat FPU and no cache — it would fail the
same probes. Booting DOS under it is possible but buys nothing for this
project.

**Net conclusion, and it is the honest one:** there is **no legally-obtainable,
ROM-free, cycle-accurate 486 emulator** available. Emulators that model 486
cache and FPU latency (86Box) are ROM-dependent by design, because that
hardware's behaviour is defined by the firmware. Emulators that are ROM-free
(Bochs, QEMU) are not cycle-accurate. The two properties are not separable
without either a BIOS the user owns or real hardware.

That is a stronger result than "we did not find one", and it should end the
search rather than license a repeat of it. The measurement gap is real, it is
now measured (0/4), and it is **not closable within this project's constraints**.

**What this means for the plan.** The Phase 3/Phase 4 candidates stay
unimplemented, and the reason is now stronger than "we lack a measurement":
the available legal harnesses cannot supply the measurement at all, so any
candidate built now would rest on published latencies alone. That is
precisely the reasoning error the ledger documents for the Z-span prologue
(`:799-800`), where an instruction-count estimate said 7.8% and the truth was
0.71%. **The honest position is that the renderer is converged, the reason is
now proven rather than asserted, and the remaining 486-specific wins are real but
unclaimable without hardware the project does not have.**

### 86Box, verified against source (2026-09-30) — the best ROM-free candidate, still disqualified

86Box was the strongest remaining hope, and it was checked properly rather than
dismissed. It is GPL and its emulator is freely installable; the problem is the
same ROM dependency plus a cache model that does not exist.

**The `_cache[2048]` array is not a cache.** This is the load-bearing fact and it
is easy to get wrong from a name. Declared `src/cpu/cpu.c:289-290` (externs at
`cpu.h:640-641`). Its only uses repo-wide are in Pentium-era test-register
emulation, `src/cpu/x86_ops_mov_ctrl.h:424-425`:

```c
_tr[3]      = *(uint32_t *) &(_cache[cache_index]);
cache_index = (cache_index + 4) & 0xf;
```

`cache_index` is a **rotating cursor, not derived from any address** — there is
no shift-mask, no tag array, no replacement policy, and only bytes 0-15 of the
2048-byte array are ever touched. The other 2032 bytes are dead space, and the
symbol is a leftover from an earlier emulator's test-register path. Our own grep
of `cpu.c` independently found zero uses there, which agrees.

**Cache cost is a flat per-model constant**, not a structure. `cpu_update_waitstates()`
(`cpu.c:4543-4588`) assigns one pair of numbers to every read and write
regardless of address:

```c
cpu_cycles_read  = cpu_s->cache_read_cycles;
cpu_cycles_write = cpu_s->cache_write_cycles;
```

There is no cache-size configuration anywhere; `src/config.c` mentions "cache"
only for a host-side disk cache. **86Box therefore cannot answer any capacity,
associativity, geometry, or set-conflict question at all** — a 4 KB and a 24 KB
working set cost it identically because it has no notion of capacity.

**x87 latency is genuine, and is 86Box's one real strength.** `x87_timings_486`
at `src/cpu/x87_timings.c:314` carries Intel-derived per-instruction latencies
(`.fdiv = 73`, `.fild_16 = 14`, `.fild_32 = 10`, `.fmul_32 = 11`) with a separate
`x87_concurrency_486` table for dependency busy-wait. So 86Box is markedly better
than Bochs or DOSBox-X on the x87 axis.

**But the one candidate that matters most is exactly the one 86Box cannot
distinguish.** `.fist_16` and `.fist_32` are **both 31 cycles**
(`x87_timings.c:346-347`) — there is no FIST-versus-FISTPL distinction, because
the 486 penalty is for a 16-bit *integer store destination*, not the opcode.
**Candidate C1 is precisely a 16-bit FIST substitution.** So 86Box would tie on
the exact axis the leading candidate pays for, and would also tie on all three
cache probes. It could not promote C1, and it could not promote C3 or C4 either.

**No cycle-count output and no script interface.** `-S` is `--settings`, not a
script. Automation is `--config` + `--image` + `--logfile` only, and there is no
user-facing emulated-cycle counter (`instr_counts` is a JIT block counter). So
even a legal ROM would leave the promotion signal resting on wall-clock timing,
which is unreliable for a ~31-cycle difference.

The 486 machines want the same vendor firmware as everything else —
`roms/machines/ami495/opt495sx.ami`, `roms/machines/c747/486-C747 Tandon.BIN`,
`roms/machines/pred1plus/PRED1PLUS.BIN` (`src/machine/m_at_386dx_486.c`,
`src/machine/m_at_socket3.c`). The `86box/roms` repository is exactly the
unlicensed vendor-firmware redistribution already ruled out, and its own README
carries no licensing grant at all — only contribution guidelines.

**A DOS image does not help, and this is worth stating because it looks like it
should.** A Windows-hosted DOS install is the *guest OS*, not the *BIOS*; the
firmware that defines the emulated hardware's behaviour is the thing in question,
and DOSBox-X already supplies a perfectly good guest DOS. WinWorldPC's MS-DOS
6.0/6.22 are abandonware and reasonable to use for exactly that purpose, but they
resolve nothing about the ROM. (Its 7.1 page is the China DOS Union custom
build, which the site itself notes it does not normally approve of.)

**So the three suggested routes resolve as:** 86Box's *emulator* is fine to
install but is disqualified on fidelity (no cache model; ties on C1's own axis);
the 86Box *ROMs* repo is the same copyright problem and is not a workaround; a
*DOS image* was never the missing piece. The search is closed.

### The 1800 KB surface-cache wall does not exist (2026-09-29) — root-caused, and the latent win is promoted

Four experiments in this ledger record that growing `SURFCACHE_SIZE_AT_320X200`
past 1800 KB produced checksum `2955717646` and was reverted, throwing away a
claimed 0.4-0.8% win each time. **There is no such defect.** A larger cache
renders correctly and is faster.

`D_SurfaceCacheForRes` (`d_surf.c:58-76`) already honours a runtime
`-surfcachesize <KB>` parameter, so the size can be swept with no rebuild. The
knob is provably live: `-surfcachesize 30000` fails with Quake refusing the
video mode, exactly as the memory guard at `vid_vga.c:269-276` predicts.

| cache | median time | FPS | checksum |
| ---: | ---: | ---: | --- |
| 1800 KB (previous default) | 59.264965 s | 16.350301 | `1047377823` |
| 1900 KB | 59.252435 s | 16.353759 | `1047377823` |
| **2400 KB (new default)** | **59.227329 s** | **16.360690** | `1047377823` |
| 6000 KB | 59.218547 s | 16.363117 | `1047377823` |

**Promoted: 2400 KB, 0.0635% faster, above the 0.05% gate.** Delta 0.037636 s
against a 0.000049 s run spread — roughly 770x the spread, and the checksum was
`1047377823` on all six A/B runs. 6000 KB adds only a further 0.015% for 2.5x
the memory, so 2400 KB is the knee. Instrumented, evictions fall from 2,151 to
2,122 invalidations and surface-cache self time from 7.260873 s to 7.240347 s.

**Why the historical rows were wrong.** They all report the *same* wrong
checksum `2955717646`, and this ledger already notes at `:2127` that it is
"the same hash as the reverted texture-source row-lookup" — an unrelated bug's
signature. A genuine cache-size-dependent defect would not reproduce one
unrelated bug's exact checksum at four different sizes. Those runs were
confounded by an experimental build that was itself rendering incorrectly; the
cache size was an incidental variable. **Do not re-investigate a cache-size
correctness bug; there is none.**

**Raising the default does not weaken the low-memory guard.** The guard at
`vid_vga.c:334-335` is
`memsize - tbuffersize + SURFCACHE_SIZE_AT_320X200 + 0x10000*3 < minimum_memory`,
and at 320x200 `tbuffersize` already contains that same constant, so the two
terms cancel and the guard reduces to `memsize - framebuffer + 192K` whatever
the cache size is. A small machine is exactly as protected as before.

**⚠⚠ THE TIMEDEMO RUNNER WILL NOT REBUILD AFTER A SOURCE EDIT — THIS ALMOST
PRODUCED A FALSE FINDING HERE.** `timedemo-dos.ps1:272` gates the entire build
on `if (-not (Test-Path $benchmarkExe))`, and `$benchmarkExe` is
`out\dos<profile-suffix>\qbench.exe` — keyed only by the *selector profile*, not
by source content. **If that executable exists, a source or header edit is
silently ignored and the previous binary is measured.** Editing
`d_local.h` appeared to do nothing for three timedemos; the binary still
carried `mov $0x1c2000,%eax` (1800 KB) while a direct compile of the same
file emitted `mov $0x258000,%eax` (2400 KB). **Pass `-Clean` to
`build-dos.ps1`, or verify the constant in the linked image, after any source
edit before trusting a timedemo.** This is a live hazard for every source-level
experiment in this project, not just this one.

**RESOLVED 2026-09-30.** The runner now hashes all 163 source files plus the
resolved selectors and rebuilds on mismatch, so neither flag is required and the
false negative can no longer occur. Two corrections to the note above: the
documented `-Clean` switch belongs to `build-dos.ps1`, **not**
`timedemo-dos.ps1`, which never had one; and the anchor `timedemo-dos.ps1:272`
has moved as the file has been edited.

### `Turbulent8` setup precompute (2026-09-30) — priced with a bit-exact dead-scratch probe; 0.034% addressable, below the gate

The last open candidate on the admissible list, quoted at **2.27% of frame**
(the whole `turbulent-spans` bucket). Unlike the previous three this ceiling
was a real bucket share rather than a mis-attribution, so it was measured
properly rather than dismissed arithmetically.

**Structure (PROFILE486 counters in `Turbulent8`):**

```text
profile-turbulent rows 40147 chunks 144705 pixels 1997515
turbulent-spans self 1.927013 s = 2.28% of the profiled frame
```

1,997,515 pixels are blitted and that blit is irreducible, so the only prize is
the s/t setup: one x87 divide plus a dozen flops per row **and** per 16-pixel
chunk.

**The probe.** The setup arithmetic was duplicated into scratch variables inside
the same loops, accumulated into a file-scope global so the compiler could not
eliminate it, and never fed to the blitter. Both probe builds rendered
**checksum `1047377823`, bit-identical to control** — which is what makes this
a sound measurement rather than the failed `z = 1.0f` attempt, which destroyed
the texture coordinates and faulted.

| build | median | delta vs control | % of frame |
|---|---:|---:|---:|
| control | 59.227346 s | — | — |
| row setup duplicated only | 59.247732 s | +0.020386 s | **0.0344%** |
| row + chunk setup duplicated | 59.296962 s | +0.069616 s | **0.1176%** |
| so the chunk share alone | — | +0.049230 s | 0.0831% |

**Dead, and the reason is structural.** The chunk-level setup
(`sdivz += sdivz16stepu; ... z = 0x10000 / zi;`) is a **running accumulation**:
each chunk depends on the previous one's state, so no per-`(surface, row)`
memo can cover it. That is 0.0831% of frame, permanently unaddressable. The
only work a memo could remove is the 40,147 row-level setups, worth
**0.0344% — below the 0.05% gate** — and that is an upper bound assuming a
100% hit rate and a free lookup, before accounting for the fact that the
inputs (`d_sdivzorigin`, `d_sdivzstepu`, ...) are recomputed per surface per
frame from the current view and so change every frame of a moving demo.

**The quoted 2.27% was ~66x the addressable work.** The whole duplicated setup
is 0.1176% of frame against a 2.28% bucket, so ~95% of the bucket is the
1,997,515-pixel blit and its surrounding call overhead, and the rest is
arithmetic no memo can reach.

Two process notes, both learned the hard way here:

- **A dead-scratch probe must not perturb the code it is pricing.** Forcing
  `z = 1.0f` to remove the divides *is* removing the thing the divides produce,
  so it broke water and faulted the run. Duplicate the work, discard the
  result, never change an input.
- **When inserting code by anchor, bound the search to the target function.**
  Two of the five probe blocks were placed by a whole-file pattern match and
  landed in `D_DrawSpans8`, which shares the same statement shapes. The compile
  caught it; a narrower anchor would not have.

Instrumentation retained: the three `PROFILE486` counters
(`bench486_turbulent_rows/_chunks/_pixels`). Inert in release builds.

### The bmodel frustum `FIXME` (2026-09-29) — premise measured, ceiling is two orders of magnitude short, do not build

The last sizeable candidate on the admissible list was the pair of in-code
precompute TODOs in `R_DrawSubmodelPolygons` (`r_bsp.c:462` and `:480`,
`/* FIXME: use bounding-box-based frustum clipping info? */`). The loop runs a
per-surface `DotProduct(modelorg, pplane->normal) - pplane->dist` backface test
(`:472`) for every face of every visible bmodel, and the proposal was a
per-`(face, entity)` precompute. It was quoted at **1.5-2.5% of frame**.

**Measured, and both halves of the premise are now known:**

```text
profile-submodel calls 2118 faces 12708 distinct-entities 26 \
  entity-hits 2092 table-overwrites 0
```

- **The reuse premise is TRUE, and unusually good.** 2,092 of 2,118 calls
  re-draw an entity already seen, across only **26 distinct entities** — a
  98.8% hit rate, nothing like E0's 3.4% or E4's zero. Structurally this is
  expected: the loop already visits every face of a submodel exactly once per
  call, so reuse can only come from repeated entity draws, and demo1 redraws
  26 entities 2,118 times. The `(face, entity, miplevel)` key would have hit
  almost every time.
- **The ceiling kills it anyway.** 12,708 face tests in the entire 969-frame
  run is **13.1 per frame**. The backface test is three multiplies, two adds
  and a subtract on data already in cache, so the whole loop is worth on the
  order of **200 cycles/frame** — against a promotion gate of **1,022.8
  cycles/frame**. Even deleting every dot product outright lands near
  **0.01% of frame, roughly 5x below the 0.05% gate.**

**The 1.5-2.5% figure was wrong by about two orders of magnitude**, most
likely by attributing the bmodel path's 13.60% `alias-raster` share to this
loop. Note the loop is a small part of the alias path even in absolute terms:
12,708 faces here against 417,090 alias-vertices. **Do not build this, and do
not re-quote its ceiling.**

The instrumentation is `PROFILE486`-only and inert in release builds (release
re-measured at 59.227374 s median, checksum unchanged). It is kept because it
is the evidence for the ceiling and because `table-overwrites 0` is what makes
`distinct-entities 26` trustworthy; a future reader can delete it with the rest
of the counters without loss.

**This is now the third candidate on the offline-precompute axis to die on a
measured premise** (E0 3.4% hit rate, E4 zero immutable rebuilds, bmodel
frustum 5x under gate). All three quoted their ceiling from a *bucket share* or
a *cost of churn* rather than from the addressable work. The screening rule that
would have caught all three: **price the prize, not the hit rate** — count the
operations the optimisation would remove, divide by frames, and compare to
1,022.8 cycles/frame before asking whether the cache hits.

### E4, the surface-cache eviction churn (2026-09-29) — premise falsified before it was built, 0 of 8,886 rebuilds

E4 was the largest candidate left on the offline-precompute axis at a quoted
**2.61% of frame**: 2,151 of 9,009 surface-cache rebuilds per run are
eviction-caused (1.547 s at 0.719 ms/rebuild), and the claim was that those
re-light surfaces whose lightstyle is permanently `256`
(`d_lightstylevalue[j] = 256` for any zero-length style, `r_light.c:68`) and
whose lit pixels therefore can never change, so the re-light is pure waste.

**That population does not exist in this workload.** A PROFILE486 counter was
added at the miss site in `D_CacheSurface` (`d_surf.c:410`) counting rebuilds
whose four `d_lightstylevalue[surface->styles[k]]` are all `256`:

```text
profile-surface-cache hits 46414 rebuilds 8886 immutable-rebuilds 0 \
  allocations 2710 wraps 3 invalidated-blocks 1893 thrash-frames 0
```

**Zero**, out of 8,886 rebuilds. Every surface that gets re-lit carries at least
one lightstyle that is not statically fullbright, so its lit pixels genuinely
depend on the current style value and the rebuild is necessary work. **Do not
build E4. The 2.61% ceiling was an upper bound on the *cost of eviction*, never
on the *addressable* part of it, and the addressable part is nil.**

Two secondary readings from the same run, at the new 2400 KB default:

- raising the cache 1800 -> 2400 KB cut invalidated blocks 2,151 -> **1,893**
  (12%) and wraps 4 -> 3, but rebuilds only 9,009 -> 8,886 (1.4%). Eviction
  churn is therefore **not** capacity-bound, which is the second reason a
  cache-policy fix could not have recovered 2.61%.
- `immutable_rebuilds` is a permanent PROFILE486-only metric; it costs nothing
  in release builds (median re-measured at 59.227332 s, unchanged). It is kept
  because it is the evidence for this null. Remove it if the tree is ever
  pruned of counters.

Admissible work after this null: `turbulent-spans` (~2.27%) and the bmodel
frustum `FIXME` (1.5-2.5%, keyed on `(face, entity, miplevel)`). E2 remains
below the run spread and should not be attempted.

### Static 486 cost model (2026-09-29) — built; it disqualifies all three blind axes and promotes nothing

`tools\486-cost-model.ps1` prices the three axes this harness cannot see, using
the pinned toolchain's objdump plus the Intel 486 published FP latencies. It is
a **disqualifier and a ranking aid, never a promotion criterion**: the 0.05%
DOSBox-X timedemo delta remains the sole gate, and a cycle figure from this
tool is a published-latency estimate, not a measurement taken here.

```powershell
.\tools\486-cost-model.ps1 `
    -ProfileJson 'out\dos-timedemo-<timestamp>\timedemo-result.json' `
    -Json 'out\486-cost-model.json'
```

**Measured against the promoted build:**

| quantity | value |
|---|---:|
| `.text` | 738,648 B = **91** unified-cache windows (90.2x the 8 KB L1) |
| x87 instructions in `.text` | 23,020 |
| Z-span prologue x87 cost | **74 cy/span** vs **9.4 cy** measured in DOSBox-X |
| spans / pixels per span | 1,494,649 / **30.75** (ledger records 30.7) |
| `z-spans` node calls | **58,051** (matches the ledger anchor exactly) |
| projected prologue share of frame | **3.91%** at 33.445 MHz, 1.95% at 66.9 MHz |

**The three disqualifications, all now quantified rather than asserted:**

1. **x87 latency — disqualified.** 74 cy/span against a measured 9.4 is a
   **7.9x** gap, and 3.91% of frame on a 486 against 0.71% measured here. The
   percentage scales linearly with clock; the ledger's historical **7.8%**
   estimate is consistent with this model at roughly 25 MHz, so the two agree
   in order of magnitude. Under a retained timedemo gate this axis cannot be
   promoted at any clock, which is why the Z-span prologue is a *rejected
   target* rather than a deferred one.
2. **L1 footprint — disqualified.** `.text` spans 91 windows of an 8 KB
   unified cache, and DOSBox-X does not model displacement.
3. **4 KB aliasing — disqualified, precondition confirmed by computation.**
   From `vid_vga.c:299-304`: zbuffer 128,000 B, then `vid_surfcache` at
   +128,000, then `lvid->buffer` at +1,971,200. Both land at page offset
   **1,024**, so they alias. This is now a computed fact, not a hypothesis —
   but the stall itself is unmodelled, so a null result would be uninformative.

**Two corrections this pass produced.**

- **The prologue is twelve x87 instructions, not nine.** `d_draw.s:812-835`
  contains `fildl fildl fmuls fxch fmuls fxch fadds faddp fcoms fnstsw fmuls
  fistpl`. The ledger's "nine" appears to count a latency-carrying subset
  (the two `fxch` register swaps and the `fnstsw` status read carry no
  dependency). Both figures are reported by the tool; the twelve are priced.
- **The linked executable is stripped by the build**, not by accident:
  `build-dos.ps1` links with `-s` (grep it for the line), so `objdump -t` reports *no symbols*.
  Per-function attribution is therefore impossible from the image, and the
  tool splits its work accordingly — exact image totals from the binary,
  per-path x87 accounting from the assembler sources where labels and line
  numbers exist. The object-granularity clustering experiment's lesson
  applies here too: this tool says nothing about *placement*.

**A counting trap worth recording.** objdump prints segment prefixes as
separate tokens and disassembles some data regions linearly, so a naive
"mnemonic begins with `f`" rule counted 336 `fs` prefixes, 68 bare `ff` grp5
opcodes and 3 AMD 3DNow `femms`/`fcmovnu` as x87 — 407 false positives, 1.7% of
the total. The tool carries an explicit exclusion list and **reports any x87
opcode it has no published latency for**, so a table gap is visible rather than
silently priced at the 3-cycle default.

Admissible work is unchanged: payoff in instruction count, memory traffic, or
arithmetic. That is E4 (surface-cache eviction churn), `turbulent-spans`, and
the bmodel frustum `FIXME`.

### `d_mip_t16` as a constant table (2026-09-29) — landed; the promotion half was not attempted

`D_DrawSurfaces` rebuilt three 4-entry float tables on every span flush
(1,052/run) under a `// TODO: could preset a lot of this at mode set time`.
One of the three is not runtime data at all: `d_mip_t16[mip] = 0x10000 *
d_mipscale_values[mip]` is exactly `{0x10000, 0x8000, 0x4000, 0x2000}` for
`d_mipscale_values = {1.0, 0.5, 0.25, 0.125}`, and all four are exactly
representable in single precision. It is now a `static const` table and the
store is gone.

```text
closure before E2:    59.265368 s  16.350189 FPS  checksum 1047377823
with d_mip_t16 const: 59.265007 s  16.350289 FPS  checksum 1047377823
delta: -0.000361 s = 0.0006% faster
```

**This is a cleanup, not a win, and it is kept on that basis.** The predicted
ceiling was ~0.005% and the measurement is ~0.0006%; both are an order of
magnitude below the 0.05% gate and near the 0.000049 s run spread, so no
timedemo beyond this single confirmation run is justified. What it buys is the
deletion of a redundant recomputation of a compile-time constant.

**The planned hoist of `d_mip_xscale` / `d_mip_yscale` into `D_ViewChanged` was
deliberately not done.** `xscaleinv` and `yscaleinv` have exactly one writer each
(`r_main.c:418`, `:421`), both inside `R_ViewChanged`, which calls
`D_ViewChanged()` last (`:482`) — so the ordering looks safe. But `R_ViewChanged`
itself is only reached from `R_SetupFrame` (`r_misc.c:454`, `:478`, `:491`) under
the condition `(r_dowarp != r_dowarpold) || r_viewchanged || lcd_x.value`, and
from `SCR_UpdateScreen` (`screen.c:276`). The current code self-heals because
`D_DrawSurfaces` fills the tables on its first call regardless. Hoisting trades
that unconditional fill for a dependency on a conditional call having happened
before the first `D_CalcGradients`; a missed first frame would leave the tables
zero and silently break texture mapping. The remaining upside is ~0.003% and
unmeasurable, which does not justify introducing a startup-ordering assumption
that the checksum gate would only catch after the fact. Revisit only with a
measurement that could resolve it.

### E3 and E4 disposition (2026-09-29)

Neither was built, for reasons that are now measurements rather than estimates.

- **E3** (per-`(face, miplevel)` constants computed at map load) is **closed** by
  the drawn-face ratio of 0.9585 measured above. A ~3.4% hit rate scales its
  ~0.10-0.14% ceiling down to ~0.004% of frame.
- **E4** (surface-cache span geometry split from lighting) was gated on E1-E3
  landing. E1 was rejected and E3 is closed, so its precondition is not met and
  it was not attempted. Its own stated ceiling was ~0.5%, which remains the
  largest unclaimed item on the offline-precompute list, but it is a cache-policy
  change rather than a precompute and does not belong to this pass.

### Precomputed `izistep` for the Z-span prologue (2026-09-29) — rejected, and the estimate was wrong in the wrong direction

`D_DrawZSpans` recomputed `d_zistepu * 2^31` once per call (58,051/run) via
`flds` / `fmuls Float2ToThe31nd` / `fistpl`, even though `d_zistepu` was already
cached per face by `R_SetSurfaceZGradients` (`r_draw.c:390-425`, a promoted win).
An opt-in `-IzistepImplementation control|precomputed` selector stored the scaled
value into the 8 free pad bytes at `surf_t` offset 56 and had the asm load it.

It was bit-exact by construction — `* 2^31` is a pure exponent bump, and the
C spelling `(int)(x * 0x8000 * 0x10000)` is the reference already in use at
`d_scan.c:459` — and every gate passed: `486 benchmark correctness PASS` with
end checksum `2378409472`, clean DOS smoke, and 969 frames with framebuffer
checksum `1047377823` on all six timedemos.

```text
control:    59.265374 / 59.265325 s   (median 59.265374, 16.350188 FPS)
precomputed: 59.285937 / 59.285888 / 59.285910 s  (median 59.285910, 16.344524 FPS)
delta        0.020536 s = 0.0347% SLOWER
```

The control median is from its two clean samples; its third run was 59.660367 s,
the isolated-outlier pattern already recorded elsewhere in this file. Every clean
control sample beats every candidate sample, and the 0.020536 s delta is roughly
420x the 0.000049 s run spread, so this is a real regression and not noise.
The candidate spread was itself only 0.000049 s.

**Why the estimate failed, which is the part worth keeping.** The prior plan
predicted 0.044-0.054%, sitting right on the 0.05% gate. The direction was wrong:
the change is not merely "saving" x87 work, it *adds* a store. `R_SetSurfaceZGradients`
now writes a fourth field per face, and it runs on both the miss and the cache-hit
path, so the cost is paid 58,051 times per run. What it removes is `flds` + `fmuls`
+ `fistpl`, which DOSBox-X prices at roughly a cycle each (the documented 1.04
cy/x87-op figure). Trading a real memory write for three emulator-cheap
instructions loses. This is **not** one of the axes the harness cannot see: it is
a genuine instruction-count and memory-traffic result, measured correctly, and the
answer is no.

A structural finding did survive and is recorded here because it is true and
cheap: **`LFNegSpan` in `d_draw.s` was dead code.** It was entered only from
`jz LFNegSpan` when `d_zistepu == 0`, where `-0.0 * -2^31` truncates to 0, so it
always fell through to `LZeroStepSpanLoop` regardless. Deleting it let the
candidate drop the `flds` entirely rather than keep a fragile x87-stack
dependency, but the net was still negative. `LFNegSpan` is live again.

The selector, the `izistep` field, `d_izistep`, the asm symbol and the plumbing in
all four runner scripts have been removed. The tree is back to control; the closure
timedemo is 59.265368 s / 16.350189 FPS at 969 frames and checksum `1047377823`.
Do not retry this as written. If anyone revisits removing x87 from the Z-span
prologue, the cost is on the producer side, and it has to come down by removing
the per-face store rather than by adding one.

### Drawn-face ratio (2026-09-29) — measured at 0.9585, which closes the per-face precompute family

The prior plan assumed a world `msurface_t` is drawn at most once per frame, and
cited `gradients 58051 == surfaces work_items 58051` as support. That pair of
counters cannot distinguish the claim from a tautology: both count *draws*.
A per-face cache keyed on `(face, miplevel)` therefore has an unmeasured hit rate,
and the whole E3 experiment was gated on that number.

So the counter was changed to count **distinct** faces per frame, not draws, via a
4096-slot direct-mapped table keyed on the face pointer and tagged with
`r_framecount` (`D_NoteFaceDrawn`, `d_edge.c:46-68`). It is `#ifdef PROFILE486`
only, costs nothing in release, and deliberately does not add a field to
`msurface_t`, which is exactly 64 bytes and must stay so. A collision merges two
faces, so the reported distinct count is a slight undercount and the true hit rate
is a slight overstatement of the repeats — the safe direction.

```text
gradients calls      58051
faces drawn (distinct) 55642
ratio                 0.9585    (repeats 2409, 4.15% of draws)
est. true ratio       ~0.966    (allowing ~426 expected collisions)
```

**The family is closed.** Faces do repeat, but only ~3.4% of the time — these are
bmodel faces, redrawn once per visible leaf. A per-face table could serve at most
that fraction of calls, so the E3 ceiling of ~0.10-0.14% of frame scales down to
**~0.004%**, an order of magnitude below the 0.05% gate. E3 should not be built.
This also retires the "memoization with a last-used compare loses" rule for this
particular family: it was never the comparison that failed, it was the hit rate.

The counter is kept, so the ratio can be re-measured rather than re-argued. It is
instrumentation only and does not appear in release builds.

### Hot-code clustering (2026-09-29) — rejected, and object granularity is the blocker

The measured facts made this look like the strongest remaining idea: `.text` is
738,392 bytes — **90x the 486's 8 KB unified L1** — and the two dominant
self-time buckets, texture spans (22.34%) and alias raster (10.87%), live in
separate objects. An opt-in `-HotCodeClustering control|cluster` selector
reordered the link line to place `d_draw16.obj`, `d_polysa.obj` and
`d_draw.obj` first. No code or data changed, so the checksum could not move —
and it did not: both variants returned `1047377823`.

```text
control  59.265504 s   checksum 1047377823
cluster  59.728678 s   checksum 1047377823   0.7815% SLOWER
```

**Rejected, and the failure is diagnostic.** Disassembly of the clustered
binary shows why. The Aff8 leaf's 16 sites moved from `0x90964` to `0x3524` —
to the very front of `.text` — while the 8-site group stayed at `0x92c15`. The
gap between the two hot halves therefore grew from **8,062 bytes to 586,686
bytes**, 73x worse. Reordering whole objects cannot cluster two functions when
the objects holding them are each far larger than the cache; it only relocates
one of them and displaces everything else.

A real attempt needs function-level placement — a linker `-T` script naming
`D_DrawSpans16` and `D_PolysetDrawSpans8` explicitly, or `.text.*` subsections.
That is a materially larger change than an object reordering, and given the
harness cannot model unified-cache displacement (see "What this harness can and
cannot measure" above) the result would be uninterpretable either way. Not
pursued.

The selector and its output directory have been removed; the tree is back to
`43ebcab` with the release build re-verified.

### What this harness can and cannot measure (2026-09-29)

The project has reached the point where the binding constraint is the emulator,
not the code. This section states the limit so later passes do not spend
timedemos on ideas the harness cannot see.

**The measurement.** Duplicating the Z-span x87 prologue into dead scratch cost
9.4 cycles for nine serialized x87 operations — about 1.04 cycles per op. A
physical 486DX spends roughly 12 cycles per x87 op and 30-90 on `FISTP` alone.
That is a 30-90x gap.

**No DOSBox-X option closes it.** The `[cpu]` section
(`tools\dosbox-x-486-high.conf:490-537`) sets `core = dynamic`, `fpu = true`,
`cputype = 486`, `cycles = fixed 33445`. DOSBox-X 2026.08.31 exposes 44 CPU
options and none controls x87 latency or fidelity; the `core` values differ in
which opcodes decode, not in per-instruction x87 timing. `fpu = true` decides
whether an FPU exists, not how it is timed — the FPU is present, functionally
correct (checksum `1047377823` is bit-exact), and temporally free.

**The consequence, and it is the thing to remember:**

> A **positive** result in this harness is sound — a measured win is a real
> win, and the checksum gate makes the semantics exact. A **negative** result is
> weak evidence. A measured null proves only that the emulator could not see the
> cost.

So the harness is reliable for finding wins and unreliable for rejecting
486-specific ideas. Every axis where a real 486 pays and DOSBox-X does not:

| axis | real 486DX | this harness | consequence |
|---|---|---|---|
| x87 latency | ~12 cy/op, `FISTP` 30-90 | ~1.04 cy/op | any win priced by FP-op count reads 10-30x small |
| instruction cache | none — 8 KB unified data cache only | n/a | "I-cache" explanations are wrong by construction |
| fetch boundary / write buffer | 16-byte bursts, 4-entry WB | not modelled | the two most 486-specific mechanisms are invisible |
| 4 KB paging aliasing | real stall | not modelled | never tried, and unmeasurable here |

**Two corrections this forced.**

1. `ASM486-HANDOFF.md:1124-1130` attributes the Aff8 padding regression to *"slightly
   worse I-cache placement."* **The 486 has no instruction cache** — only an
   8 KB unified data cache. What the sentence describes is 16-byte fetch
   boundaries and unified-cache displacement. That is the only I-cache
   reference in the repository, and it has been shaping the recorded reasoning
   about why the alignment experiment failed.
2. ~~The pinned profile SHA-256 is **recorded, not enforced**.
   `tools\timedemo-dos.ps1:439-446` computes it and `:653` writes it into the
   report, but nothing compares it to a constant — `F3948708` appears only in
   prose (`BENCHMARK-COMPARISON.md:22`, `VIDEO-DOS-VALIDATION.md:71`,
   `docs\PURE-ASSEMBLER-CANDIDATES.md`). A future change to the DOSBox-X core
   would therefore not be caught; it would silently re-baseline every entry in
   the ledger, because the hash protects the file, not the numbers.~~
   **(Closed 2026-09-30, and the line numbers above had moved even then. The hash
   is enforced: `timedemo-dos.ps1:548-556` compares it to `-ExpectedProfileSha256`
   (constant at `:104`) and throws unless `-AllowGateOverride` is passed. Grep for
   `ExpectedProfileSha256` rather than trusting any anchor in this file — several
   have drifted.)**

**Applying the rule.** Before spending a timedemo on an idea whose payoff comes
from FPU latency, fetch boundaries, write-buffer occupancy, or 4 KB aliasing,
recognise that a null is uninformative. Those ideas can only be settled on
hardware. Ideas whose payoff is instruction count, memory traffic, or
arithmetic are still fully measurable here, and that is where any further
optimization effort belongs.

### Where this leaves the project

> **Amended 2026-10-01.** The first two bullets below were not "closed by
> evidence". `alias raster` was closed by a measurement that was measuring its
> own timer, and it is now 4.0% of frame rather than 13.6% — small, but
> un-decomposed rather than converged. The claim that "every remaining mechanism
> is closed" rested partly on that. The recommendation to stop stands for the
> 486-specific axes, which really are invisible here; it did not cover the
> instruction-count axes, and the corrected profile identifies two of them
> (`world-bsp` 10.2%, `edge-scan` 8.0%) that were never structurally priced.
> See "Alias attribution corrected".

The renderer is converged at the source level. Every remaining mechanism I can
identify is either closed by measurement or closed by the harness's own
limits:

- texture spans, alias raster, the Z-span prologue, the video path, and the
  surface-cache size/layout are all closed by evidence, with the numbers
  recorded above;
- x87 latency, fetch boundaries, write-buffer occupancy, and 4 KB aliasing are
  unmeasurable here and no DOSBox-X option changes that;
- code layout is measurable only at object granularity, which the
  clustering experiment just showed is too coarse to be useful.

**The honest recommendation is to stop optimizing against this harness.** Not
because the renderer cannot be improved, but because the remaining ideas target
costs the measurement cannot see, and the project has no way to tell a real win
from an invisible one.

If the goal is real 486 hardware rather than the DOSBox-X benchmark, the next
step is not more assembly — it is a machine that can see what a 486 actually
pays. A physical 486DX2/DX4, or a cycle-accurate alternative emulator, would
immediately make the write-buffer, aliasing, and code-layout questions
answerable, and would let the alignment and prologue results be re-examined
without the emulator's flat FPU model distorting them.

Until then, the work stands as a complete, parity-gated optimization pass:
59.265 s / 16.35 FPS for `demo1`, roughly 22% faster than original Quake, with
969 frames and framebuffer checksum `1047377823` reproduced on every run.

### Z-span x87 prologue (2026-09-29) — measured, and the idea does not survive

`d_draw.s:812-838` runs nine serialized x87 instructions per span to compute
the initial 1/z, amortized over only 30.7 pixels on average (1,494,650 spans
for 45,953,856 pixels). It was the largest identified win in a bucket that no
logged Z-span experiment touches — all six ledger entries target addressing
(`zspantable`), packing (`shldl`/`rorl`), unrolling, or stack traffic.

**An instruction count suggested ~4.6 s, about 7.8% of frame. Measurement says
0.419 s, about 0.71%. The estimate was 11x too high.**

Measured with a probe that recomputes the identical prologue into the same
scratch slot, discarding the result. Because it reproduces the same value, the
framebuffer is bit-identical — both runs returned checksum `1047377823`, which
is what makes this probe safe to run, unlike the earlier attempt that
overwrote the Z buffer with a constant and produced visibly broken textures.

```text
control  59.265481 s   checksum 1047377823
probe    59.684261 s   checksum 1047377823   (prologue done twice)
delta     0.418780 s = one prologue = 9.4 cycles/span = 0.71% of frame
```

The estimate was wrong because it priced x87 ops at real 486 silicon speeds
(~12 cycles each, with `FISTP` at 30-90). DOSBox-X emulates them far more
cheaply; nine of them cost 9.4 cycles. A real 486DX would show a much larger
number, which is precisely the gap the project's standing caveat about
emulator results not predicting physical hardware applies to — in the opposite
direction from the usual one, where emulation flatters a change.

**The idea is not worth pursuing.** Even a perfect fix caps at 0.71% of frame,
and the bit-exact rewrite is blocked: the prologue computes in *single*
precision, rounding after each of the three float operations, so an integer
replacement would have to reproduce that rounding exactly. A naive integer
version fails the checksum. Reaching even half the ceiling would mean
emulating x87 rounding in integer arithmetic — far more expensive than the
0.419 s being removed.

Recorded so the 7.8% figure is not resurrected. The probe, its
`-ZSpanArithmetic` selector, and its `out\` directory have all been removed; the
tree is back to `1f01959` and the release build re-verified at 969 frames and
checksum `1047377823`, 59.265510 s.

**Method note worth keeping:** the safe way to price a hot sequence is to
duplicate it into dead scratch and time the delta. It is bit-exact, needs no
correctness argument, and cannot render anything wrong. The unsafe version —
overwriting live output — produces a faster but meaningless number *and* a
broken binary.

### Aff8 AGI interlock investigation (2026-09-29) — null result, selector removed

The Aff8 pixel leaf was the last untested 486 mechanism from the optimization
brief. It was investigated two ways, both recorded here because the process is
more useful than the outcome.

**1. The per-pixel hypothesis was false.** The claim was that `movb %dh,%ah`
followed by `movb 0x12345678(%eax),%al` creates a per-pixel interlock. The
assembled leaf is:

```text
  cmpw  (%ecx),%bp                 base=%ecx
  jl    Lp1
  movzbl (%esi),%eax              base=%esi, writes %eax
  movb  %dh,%ah                   writes %eax, NO memory operand
  movw  %bp,(%ecx)                base=%ecx
  movb  0x12345678(%eax),%al      base=%eax
  movb  %al,(%edi)                base=%edi
```

An interlock requires instruction N to write a register that instruction N+1
uses as a memory base or index. Checking each adjacent pair: `movb %dh,%ah`
writes `%eax` but has **no** memory operand, so it cannot be the N in a hazard,
and the `%eax` base use two instructions later is already separated by the Z
store. The `movzbl (%esi),%eax` → `movb %dh,%ah` pair looks like a hazard, but
the second instruction is register-to-register with no address generation.
`ALIAS_SPAN_ADVANCE` ends by writing `%esi` and the following
`cmpw (%ecx),%bp` uses `%ecx`, leaving two instructions of separation. The
original id Software schedule is already correct here.

**2. The one real interlock was measured, and is worth nothing.** Exactly one
genuine AGI remains: `addl $16,%ecx` immediately precedes `cmpw (%ecx),%bp` at
the two `LDrawLoop` group back-edges (`d_polysa.s:988` and `:1124`). Rather than
arguing from the disassembly, an opt-in `-Aff8AgiPadding control|pad` selector
was added, emitting one NOP at each back-edge, and the padding was confirmed in
the linked binary (control runs `add $0x10,%ecx` straight into
`cmpw (%ecx),%bp` at `0x90b14`; `pad` inserts `0x90b17: nop` between them).

The candidate passed every parity gate — `486 benchmark correctness PASS` with
end checksum `2378409472` (`out\dos-bench-20260929-102523`), a clean DOS smoke
test, and six timedemo runs at 969 frames with framebuffer checksum
`1047377823`. Three alternating pinned `demo1` pairs:

```text
control: 59.265427 / 59.265498 / 59.265442 s; median 59.265498 s, 16.350153 FPS
pad:     59.265453 / 59.265466 / 59.265480 s; median 59.265466 s, 16.350159 FPS
```

The delta is **-0.000032 s (-0.000054%)**, roughly 1,000x smaller than the
0.05% promotion gate and inside the run-to-run spread (control 0.000071 s, pad
0.000024 s). A clean null, not a regression: the NOP costs nothing in this
workload and saves nothing either.

**The selector and its `ASM486_AFF8_AGI_PAD` define have been removed from the
tree.** The measurement stands as the record; the code does not, because there
is nothing left to keep. Artifacts remain in `out\dos-timedemo-20260929-103519`
through `out\dos-timedemo-20260929-104051`.

Two conclusions. The Aff8 leaf is finished: the alignment experiment lost 0.806%
by growing this loop, and this padding is measurably free but worthless, so both
directions are closed. And the reasoning error in step 1 is the part worth
keeping — the interlock is easy to *see* in a disassembly and easy to believe,
and it was wrong. Verify adjacency **and operand types** before spending a
timedemo A/B on any 486 interlock claim.

### Alias-raster C-glue instrumentation (2026-09-29) — **SUPERSEDED 2026-10-01, the numbers below are instrumentation-limited**

> **The table in this section does not support the conclusion drawn from it, and
> the conclusion is withdrawn.** The four per-call C regions were measured at
> 253-304 cycles/call, but each scope's measured window physically contains its
> own timer read, and one read costs ~193 cycles. Between **62% and 76%** of
> every figure in the table is the clock, not the code. Re-measured with the
> scope amortized to one per triangle, the C glue is **1.83 s, not the ~5.97 s
> these numbers implied — a 3.1x overstatement.** See "Alias attribution
> corrected" below. The text is kept as written on 2026-09-29 so the reasoning
> error stays visible; do not cite the table as evidence of convergence.

The unattributed `alias-raster` self time is split into `alias-edge-setup`,
`alias-span-package`, and `alias-step-math`, wrapping the cursor-init blocks,
the single-row span-package emits, and the two duplicated base/extra step
blocks in `WinQuake\d_polyse.c`. From
`out\dos-timedemo-20260929-100501\timedemo-result.json` (frame total
84.627456 s, attribution only), in total cycles per call:

```text
node                       impl   calls    cycles/call
alias-draw-spans            ASM  153853       715.6
alias-scan-left-edge        ASM  109941       544.9
alias-calcgradients         ASM  124769       381.8
alias-step-math              C   109941       303.8
alias-linescan-setup         C   263794       283.1
alias-edge-setup             C   183042       267.9
alias-span-package           C   168786       252.9
```

**The remaining C is uniformly cheap.** The three glue regions are
36.8% / 32.5% / 30.7% of the measured glue, 253-304 cycles per call, and none
is an outlier. There is no single hot C block left to port; the C is thin,
evenly spread setup code interleaved with three already-optimized ASM routines.
Combined with the four pre-existing ASM children, this is the evidence that the
alias raster path is converged at the source level.

> **Withdrawn 2026-10-01.** The uniformity observation may well be true, but it
> was not established by this table: every per-call value here is at or below
> the instrumentation that produced it. "No outlier" is what a clock-dominated
> measurement looks like regardless of the code. The *conclusion* (do not port
> this C) still happens to be the right call, and for a better reason — see
> "Alias attribution corrected" — but it is not supported by this evidence.

**Methodology note, because it changes how these numbers may be used.** Each
added ENTER/LEAVE pair costs two `Sys_FloatTime` reads, and this level added
16 reads per rasterized triangle: 923,482 extra reads and 6.98 s across the
frame. That is **~253 cycles per timer read**, which is the same order as the
regions being measured. Consequences:

- Absolute seconds for the three new nodes are inflated by their own
  instrumentation and must not be quoted as real work.
- Per-call cycles are also inflated, but by a near-constant addend, so the
  *ranking* and the *relative* split within the glue are sound. That is what
  the table above is for. **(2026-10-01: this second bullet is also withdrawn.
  When the signal is smaller than the addend, the ranking is an artifact of call
  counts, not of cost. The measured per-call figures are 253-304 cycles against
  a ~193-cycle read, leaving 25-38% signal, so the split is not sound.)**
- The four pre-existing nodes are directly comparable across runs: they moved
  by at most 11 ms between the previous level and this one.

### Alias attribution corrected (2026-10-01) — the profiler was measuring itself; C glue is 3.1x cheaper than recorded

The self-time ranking this project has been steering by is distorted by the
profiler, and the distortion is large enough to have produced a false
convergence verdict. This entry records the correction, the tool that makes it
automatic, and the amended cost distribution.

**The mechanism.** `Bench486ProfileEnter` reads `Sys_FloatTime` *before*
recording the scope start, and `Bench486ProfileLeave` reads it again at the
top. So a scope's measured self window physically contains one `Sys_FloatTime`
call of its own, plus one for every child scope it enters. The profiler now
calibrates the real cost of a read at startup (`Bench486ProfileCalibrateTimer`,
256 back-to-back reads) and reports it in `profile.jsn` as
`instrumentation.read_seconds`, and emits a per-node `instr_reads` count. The
measured cost is **193.3 cycles per read** on the pinned profile — close to,
and slightly below, the 253 cycles independently estimated at `:952`.

**What that does to the recorded table.** The four C-glue regions, re-priced
against their own instrumentation:

```text
node                    calls    raw cyc/call -> signal cyc/call   signal
alias-span-package    168,782           252.9  ->          59.8      23.6%
alias-edge-setup      183,040           268.0  ->          74.8      27.9%
alias-linescan-setup  263,792           283.2  ->          90.0      31.8%
alias-step-math       109,941           303.8  ->         110.6      36.4%
```

**Between 62% and 76% of every number in that table was the clock.** The raw
figures reproduce the 2026-09-29 values exactly, which confirms the correction is
calibrated rather than fitted. Summed, the four regions cost
`(168782*252.9 + 183040*268.0 + 263792*283.2 + 109941*303.8)` = **5.97 s** on
the raw readings.

**Measured properly, they cost 1.83 s** — a **3.1x overstatement**.

**The fix, and why it was the right one anyway.** The four per-call C scopes are
gone. `D_RasterizeAliasPolySmooth` now opens **one** `alias-glue` scope per
triangle, and the three ASM helpers keep their own scopes, so `alias-glue`'s
self time is the C and nothing else. Timer reads fell **2,781,830 ->
1,580,280 (-43%)** and the profiled frame from 84.59 s to 75.68 s, with
checksum `1047377823` unchanged on every run. The ledger's own advice at `:946-948`
("amortize: time a whole span or a whole triangle rather than each sub-block")
was right and had simply not been carried out.

**The amended distribution** (corrected self time, `out\dos-timedemo-20261001-154726`):

```text
node                corrected   % of profiled frame   signal
texture-spans         18.587 s            24.6%         98.3%
world-bsp              7.724 s            10.2%         99.9%
surface-cache          6.832 s             9.0%         95.5%
edge-scan              6.043 s             8.0%         99.8%
z-spans                5.968 s             7.9%         94.7%
alias-raster           2.999 s             4.0%         79.9%
surfaces               2.805 s             3.7%         67.8%
alias-draw-spans       2.408 s             3.2%         73.0%
turbulent-spans        1.911 s             2.5%         99.2%
alias-glue (the C)     1.827 s             2.4%         38.1%
alias-transform        1.305 s             1.7%         97.6%
brush-entities         1.228 s             1.6%         99.5%
```

`alias-raster` is no longer 13.6% of frame; it is 4.0%, and the C glue inside it
is 2.4%. **The alias raster path is still not worth porting** — the C is thin —
but that is now a conclusion from a measurement that can see it, not from one
that could not. Do not cite the old table again.

**Two corrections to the project's standing numbers.**

1. **`frameFpsStats` was silently costing 0.020% of frame.** The recorded
   baseline 59.227329 s was measured with it **off**, but the runner defaulted
   it **on**, so a default `timedemo-dos.ps1` invocation produced 59.239011 s —
   **0.0117 s, which is 39% of the entire 0.05% promotion gate**, before any
   code change. The flag is now opt-in (`-FpsStats`), a run with it enabled
   prints a warning that the result is a diagnostic and not a promotion
   measurement, and the resolved value is written to the report JSON. With it
   off, the tree reproduces the baseline at **59.227628 s median**
   (59.227596 / 59.227628 / 59.227631), a 0.0005% difference.
2. **`tools\profile-report.ps1` now refuses to mislead.** It prints corrected
   self time, the per-read floor, a per-call figure with the signal fraction, and
   an explicit `LOW SIGNAL` list naming the regions whose measured window is
   mostly clock, with the instruction not to port or close them on that
   evidence. Any future pass that adds a per-call scope will see its own floor
   immediately.

**What this does not change.** The promotion gate, the parity gates, the
inadmissibility of the x87/fetch/write-buffer/aliasing axes, and the closure of
E0, E4, the bmodel `FIXME`, and `Turbulent8` all stand. The two buckets this
re-opens as unmeasured rather than closed are `world-bsp` (10.2%) and
`edge-scan` (8.0%) — both high signal, both never structurally decomposed.
They are resolved immediately below.

### `world-bsp` decomposed (2026-10-01) — it was never the BSP walk; 85% of it is per-face edge setup

`world-bsp` sat at 10.2% of frame as a single opaque bucket covering
`R_RecursiveWorldNode`, the ~800-line `R_RenderFace`, `R_ClipEdge` and
`R_EmitCachedEdge`, with no split. Four PROFILE486 counters were added first
(plain increments, no timer reads) to size the callees before committing to a
scope, because sizing the scope by guesswork is how the alias table went wrong.

```text
renderface-calls    215,720   (222.6 per frame)
renderface-emitted  104,642   (107.9 per frame; 48.5% of calls emit a surface)
clipedge-calls            0   <-- the C R_ClipEdge is not the one that runs
emitcached-calls   121,467   (125.3 per frame; 56% of calls hit the edge cache)
```

`clipedge-calls 0` is itself a result: `R_ClipEdge` is `r_drawa.s` assembly in
every promoted build, so the C reference in `r_draw.c` is dead code on this
path. The 486,253 calls per run that do **not** hit `R_EmitCachedEdge` go
through the assembly clipper.

222 calls/frame is low enough to scope. One `renderface` scope around the three
`R_RenderFace` call sites in `r_bsp.c` splits the bucket cleanly
(`out\dos-timedemo-20261001-171323`, checksum `1047377823`):

```text
region        corrected   % of frame   signal   per call
renderface      6.549 s       8.29%     84.0%   1015 cyc/call
world-bsp       2.157 s       2.73%     63.9%   (the walk, after subtraction)
```

**The BSP traversal is not the cost.** It is 2.7% of frame, and `R_RenderFace`
is 8.3% — **85% of what was filed as "world BSP" is per-face edge setup.** The
profile has been steering by "world-bsp 9-11%" for several passes, and that
number was really the face-setup bucket wearing the wrong label.

**Price, and the admissibility split.** `renderface` is 226,000 cycles/frame,
**221x the 1,022-cycle gate**, so this is the largest admissible-axis pool found
so far. But most of it is the assembly `R_ClipEdge`, and its 12 serialized x87
instructions per clip plane are the **blind axis** — a change there pays in x87
latency, which DOSBox-X cannot register, so it is inadmissible however large
the prize. Only the instruction-count part of `R_RenderFace` — the unrolled
per-edge dispatch scaffolding, the clip-plane link setup, and the cache
validation in front of `R_EmitCachedEdge` — is admissible, and it has never
been separated from the clipper. That separation is the next task, and it needs
a probe rather than a timer, for the reason in the next section.

### `renderface` priced by premise (2026-10-01) — large pool, but the x87 in it is essential work; no probe built

The obvious next step after the split above was a dead-scratch probe to price
`R_RenderFace`'s C scaffolding against the assembly clipper. Before building
it, the population was measured with plain counters (no timer reads), which is
what the mip-1 result taught to do first.

```text
renderface-calls    215,720   (222.6 per frame, 4.99 edges per call)
renderface-emitted  104,640   (48.5% of calls emit a surface)
edge setups       1,077,059
  of which cache-hit 121,466  (11.3%) -> R_EmitCachedEdge, no clipping at all
  of which clipped    955,593  (88.7%) -> the assembly R_ClipEdge
clip planes          637,693   (2.96 per face, but only 0.667 per clipper call)
early returns              0   (no surface_p / edge_p exhaustion at all)
```

**This reframes the bucket, and it is why the probe was not built.**

The 88.7% figure looks alarming, but it is the wrong number to fear. The
clipper's *plane-dot* loop — the obviously inadmissible part, ~20 x87
instructions per plane — runs **637,693** times in total, not 955,593, because
two thirds of clipper calls arrive with `pclip == NULL` and fall straight
through to `Lemit`. 637,693 x 20 is 12.8 M x87 instructions, about 13 M
cycles: **~6% of `renderface`'s 219 M cycles.**

So the bucket is not mostly "clipping x87 that could go away". It is mostly the
per-edge **emit** path — `fldcw`, `LTransformAndProject` (project, 1/z divide,
scale), edge store and stack clear — at 955,593 edges. That is essential edge
work, not an optimisation target, and it is inadmissible in any case.

What remains admissible is the C scaffolding around it, plausibly 30-40% of the
bucket, i.e. 70,000-90,000 cycles/frame, still 70-90x the gate. **A price was
not obtained and none is claimed.** The obstacle is not measurement: it is that
no candidate transformation exists to price. The mip-1 win came from a *known*
specialisation applied one level down, and the premise counters said where to
apply it. Here there is no equivalent — the ledger already records the hoist
and unroll attempts in `R_RenderFace`, and most were reverted.

**Decision: `renderface` is closed as "large, correctly attributed, and without
an admissible hypothesis". Do not build the probe.** Instrumenting 800 lines of
unrolled C across ~24 edge sites to price a pool with no candidate is exactly
the "another C-to-ASM port without a new source-level hypothesis" that
`:2985-2992` warns against. If a hypothesis for the clip-plane link chain or
the cache-validation sequence appears later, the counters above are already in
the tree to test its premise for free.

> **Superseded 2026-10-02 — the probe was built and the pool is now priced. The closure
> still stands, but it rests on a measurement rather than on "no hypothesis".** Two C
> dead-scratch probes over the prologue and the per-edge cache validation give **~15.8x
> the gate** of priced C scaffolding, against the 70-90x estimated above — **the estimate
> was high by 4-5x**. Read the new `renderface` priced entry at the top of this file. Two
> findings from it are worth more than the closure: the redundant `edge_p - r_edges` was
> already CSE'd by `-O3` (the whole prize is one `sub`, 0.9x, and reading `objdump -dr`
> found that before any build), and **the 1.0 cycle rate is a dependency property, not a
> constant** — nine assembly loops measure 0.974-0.996, one straight-line C mix 0.5439,
> one serialised C mix 1.1917. Do not re-open `renderface`.

### `edge-scan` cannot be decomposed (2026-10-01) — the arithmetic forbids it, do not retry

`edge-scan` is 7.65% of frame and was the other undecomposed bucket. The
counters give 73 inserts, 72 removes, 151 steps and 152 span generations per
frame, so the whole bucket is 448 operations:

```text
edge-scan corrected budget   208,581 cycles/frame
operations per frame                448
cost per operation                  466 cycles
timer floor per scope               387 cycles   (2 reads x 193.3)
best achievable signal              17.0%
```

**Any per-call scope over these routines would report at most 17% signal.** At
466 cycles of real work per operation against a 387-cycle floor, a decomposition
would be measuring `Sys_FloatTime`, which is precisely the error that produced
the withdrawn alias table. Adding one anyway would also cost 868k reads and put
the build back above its previous 2.78M.

**So `edge-scan` is closed as unresolvable by this instrument, not as converged.**
Its components (`R_InsertNewEdges`, `R_RemoveEdges`, `R_StepActiveU`,
`R_GenerateSpans` in `r_edgea.s`) are hand-tuned assembly with roughly twenty
logged micro-experiments already rejected, so there is no strong reason to
expect an unmeasured win. The honest statement is that a real win there would
need the dead-scratch probe or real hardware, not another scope. **Do not add a
scope to `edge-scan`; the floor arithmetic above is the reason, and it will not
improve with more runs.**

> **Superseded 2026-10-02 by the `edge-scan` dead-scratch decomposition at the top
> of this file. The scope prohibition STANDS and the arithmetic above is still
> correct — but it was read as licensing a permanent closure, and that reading
> was wrong.** The floor binds a *timer scope*, and a dead-scratch probe is not
> one: it has no measurement overhead, because it adds work and is read off the
> whole-run timedemo delta against a 0.000049 s spread. Six probes then gave the
> decomposition this entry says was unavailable, and it re-opened the bucket at
> 88.8x the gate measured plus **115.1x now bounded and named**. Two of its own
> predictions were wrong: the four micro-optimised loops are 52x the gate, not
> most of it, and the conclusion "no strong reason to expect an unmeasured win"
> was reasoned rather than measured. **The remedy named in the last paragraph was
> correct and simply was not run — that is the actual failure here.** Do not
> repeat it: an entry that says what would be needed is not a closure.

### mip-1 horizontal-flat surface blocks (2026-10-01) — **PROMOTED, 0.0513%**

The first admissible win since the profiler was corrected, and the first
candidate to clear the gate on a *measured* premise rather than an extrapolated
one. It is the mip-0 specialisation applied one mip level down.

**Premise, measured before anything was built.** The flat-block counters were
split by mip level (they had only been summed, which is what hid the
opportunity). mip-1 has more blocks than mip-0, and a higher flat fraction:

```text
mip     blocks  horizontal-flat   share
0      93,602           7,158      7.65%
1     142,258          14,837     10.43%
2      44,445           3,930      8.84%
3       7,364             591      8.03%
```

**The price, and why modelling was not enough.** Calibrating against the
measured mip-0 promotion (78.725 ms net) gave 0.839 cycles per removed
`addl %ebp,%edx`, which put mip-1 at **1,015 cycles/frame against the
1,022-cycle gate — 0.99x.** The entire verdict hinged on one assumption: that
the four-instruction eligibility test would cost 4 cycles on the 127,421
non-flat mip-1 blocks.

**That assumption was wrong, and only a measurement could say so.** A temporary
probe duplicated the mip-0 flat test (both outcomes falling through, so it is
bit-exact) behind a `-FlatTestProbe` switch that was part of the build
fingerprint and the profile suffix, so a probe run could never measure a control
binary. Three alternating pairs:

```text
control   59.228381 / 59.228440 / 59.228389 s
probe     59.228407 / 59.228396 / 59.228387 s
delta    -0.000033 s  = -1.1 cycles/frame
```

**The eligibility test is free** — the branch is perfectly predicted and the
four instructions overlap with surrounding work. So the mip-1 prize is the
gross figure, **1,542 cycles/frame = 1.51x the gate**, not the net figure the
model produced. The probe, its switch and its plumbing were then removed
completely; the tree is back to a clean two-state selector.

**This is the general lesson worth keeping.** A model calibrated on real data
still got the sign of the answer wrong, by 0.01x, because one of its two
parameters was an assumption rather than a measurement. The 0.99x looked like a
refusal to build; it was actually an invitation to measure the one number that
decided it.

**Implementation.** `surf8.s` gains `LSurf8Mip1HorizontalFlat`, the general
`SURF8_MIP1_ROW` with every per-texel light update removed. Source byte order,
the `%eax` packing, both `rorl $16` word swaps and both colormap lookups per
texel are byte-for-byte the general path, so the output is identical; only the
light updates go, replaced by one `addl %ebp,%edx` per row. 64 new colormap
patch sites, so `R_Surf8Patch`'s `%ecx` ladder gains `addl $64,%ecx` — the
documented footgun, verified by preprocessing the table with the real toolchain
and counting (216 entries against a computed 216) before building.

**Two bugs worth recording, because both produced a hard fault rather than wrong
pixels, and neither was findable by reading the code.**

1. The eligibility test has to sit **before** the `subl %ecx,%ecx` /
   `subl %ebx,%ebx` that clear those registers for loop addressing. mip-0 has no
   such zeroing, so copying mip-0's *position* verbatim on mip-1 put the test
   after them, where it compared 0 to 0, always passed, and set the per-row step
   to 0.
2. The eight rows are unrolled inside the subroutine, so the loop counter is the
   number of **row bodies** (1), not the block height (8). Copying mip-0's
   `pushl $16` shape and unrolling eight rows gave 8x8 = 64 rows, which ran off
   the end of the surface cache. Quake faulted with no output at all, which is
   how a surface-cache overrun presents.

**Result.** Three alternating pairs, control first, both from the same tree:

| build | runs (s) | median | frames / checksum |
|---|---|---:|---|
| `SurfaceBlockMip1HorizontalFlat=control` | 59.227632 / 59.227598 / 59.227546 | 59.227632 | 969 / `1047377823` |
| `SurfaceBlockMip1HorizontalFlat=fast` | 59.197250 / 59.197203 / 59.197264 | **59.197264** | 969 / `1047377823` |

**0.030368 s, 0.0513% faster** — above the 0.05% gate, and about 353x the
0.000086 s control spread. Every candidate run beat every control run. The
candidate passed the DOS smoke test and the full `bench486` correctness suite
(`486 benchmark correctness PASS`, end checksum `2378409472`).

**Promoted to the default** in `build-dos.ps1`, `bench-dos.ps1`,
`timedemo-dos.ps1` and `smoke-dos.ps1`; `control` remains selectable for A/B.
The promoted default re-measures at **59.197264 s** median
(59.197260 / 59.197266 / 59.197264), checksum `1047377823` on all three, with
`bench486` PASS and smoke clean.

**New baseline: 59.197264 s / 16.369000 FPS**, from 59.227329 s / 16.360690.

Because this win is a straight removal of arithmetic, it is squarely on the
admissible side of the gate. Note the two facts that made it possible and that
were both unavailable before 2026-10-01: the per-mip flat counts, which the
summed counter hid, and a profile whose self-times can be trusted.

- Do not add a fourth level of per-call instrumentation here. The measurement
  cost now rivals the signal, and no further decision hinges on it. If more
  resolution is ever needed, amortize: time a whole span or a whole triangle
  rather than each sub-block.

Release parity is unchanged at 969 frames and checksum `1047377823`, confirmed
after this level. Workload counters held: `alias-models` 5470,
`alias-vertices` 417090, `line-setups` 263794, `max-depth` 8,
`stack-overflows` 0, `bad-leaves` 0.

### Alias-raster child breakdown (2026-09-29) — C cost is 2.86%, not the predicted <1%

`alias-raster` is now split into its four children:
`alias-calcgradients`, `alias-linescan-setup`, `alias-scan-left-edge`, and
`alias-draw-spans`. The enum entries go after `BENCH486_PROFILE_ALIAS_RASTER`
in `WinQuake\quakedef.h`, the matching names after `"alias-raster"` in
`WinQuake\host_cmd.c` (the two lists must stay in identical order), and the
ENTER/LEAVE pairs are in `WinQuake\d_polyse.c` inside
`D_RasterizeAliasPolySmooth`, wrapping each call individually. The two
right-edge `linescan-setup` calls have no matching `ScanLeftEdge`; they exist
only to set `ubastep`/`erroradjust*` for the `D_PolysetDrawSpans8` right-edge
loop.

Measured from `out\dos-timedemo-20260929-095627\timedemo-result.json`
(frame total 77.643930 s, attribution only):

```text
alias-raster self   8.339431 s  10.74%   unattributed C glue
alias-draw-spans    3.287665 s   4.23%   ASM  153852 calls
alias-linescan-setup 2.222018 s  2.86%   C    263814 calls
alias-scan-left-edge 1.788217 s  2.30%   ASM  109962 calls
alias-calcgradients  1.420764 s   1.83%   ASM  124767 calls
```

Call multiplicities confirm the model: 124,767 triangles at ~22.8 per model,
2.11 line-scan setups and 1.23 draw-spans per triangle, 0.88 left-edge scans.

**A prior estimate in this session was wrong by 3.5x and is corrected here.**
The pre-measurement estimate put `D_PolysetSetUpForLineScan` at 0.32-0.63 s
(0.46-0.93% of frame), reasoning from a ~40-80 cycle `adivtab` lookup. It
actually costs **281.7 cycles per call**, because 263,814 non-inlined calls each
pay argument setup and the global write-back, and the estimate counted only the
fast-path body. It is 2.86% of frame, not under 1%. Recording the miss because
the ledger's value is precisely in not repeating wrong estimates.

Consequences for the next pass. The raster subtree is 51.1% identifiable C
(`alias-linescan-setup` at 2.86% of frame) and 48.9% ASM, and the largest single
item remains the **8.339 s of unattributed `alias-raster` self time (10.74% of
frame)** — larger than any named child. That residual is the C glue in
`D_RasterizeAliasPolySmooth`: the duplicated base/extra step precomputation at
`d_polyse.c:828-873` and `925-967`, the span-package setup blocks, and
`D_PolysetSetEdgeTable`. It has not yet been split. That residual, not the
line-scan helper, is the next thing worth instrumenting or porting.

Instrumentation integrity: `alias-models` 5470, `alias-vertices` 417090,
`line-setups` 263814, `stack-overflows` 0, `bad-leaves` 0, `max-depth` 8.
The release build is unchanged at 969 frames and checksum `1047377823`. Note the
instrumented run costs 77.6 s against 67.96 s for the previous level, so
timer reads rose from 553,450 to 1,858,372; instrumented durations are
attribution evidence only and must not be compared to release timings.

### Alias sub-node instrumentation and the alias cost breakdown (2026-09-29)

The alias-model bucket is no longer a single flat bracket. `BENCH486_PROFILE_ALIAS_SETUP`,
`BENCH486_PROFILE_ALIAS_TRANSFORM`, and `BENCH486_PROFILE_ALIAS_RASTER` were added to
`WinQuake\quakedef.h` (immediately after `ALIAS_MODEL`) and to the name table in
`WinQuake\host_cmd.c`. `WinQuake\r_alias.c` wraps three sub-regions of
`R_AliasDrawModel` and its two prepare helpers: the once-per-model setup
(`R_AliasSetupSkin` through `ziscale`, `r_alias.c:917-949`), the per-vertex
transform/project loop (in both `R_AliasPrepareUnclippedPoints` and
`R_AliasPreparePoints`), and the rasterizer call (the per-triangle
`D_PolysetDraw`/`R_AliasClipTriangle` loop in `R_AliasPreparePoints`, and
`D_PolysetDraw` in `R_AliasPrepareUnclippedPoints`). This is measurement only:
the `PROFILE486` macros compile to `((void)0)` in release builds, and the
release timedemo is unchanged at 969 frames and checksum `1047377823`.

The breakdown from `out\dos-timedemo-20260929-093012\timedemo-result.json`
(frame total 67.946126 s, attribution only):

```text
alias-raster      7.384299 s  10.87%   82.95% of the alias bucket
alias-transform   1.335922 s   1.97%   15.01%
alias-setup       0.181710 s   0.27%    2.04%
alias-model self  0.298821 s   0.44%   (unattributed remainder)
```

**This settles the question the previous pass could not.** The earlier
arithmetic showed the bucket cost ~716 cycles per vertex when an x87 transform
is only ~40-60, so it could not be transform-bound; the instrumentation
confirms that directly. The alias cost is overwhelmingly **rasterization**,
not setup and not the per-vertex transform. The three setup helpers
(`R_AliasSetupSkin`, `R_AliasSetUpTransform`, `R_AliasSetupLighting`,
`R_AliasSetupFrame`) together cost only 0.27%, and the per-vertex transform and
clip loop is 1.97%. Optimizing the setup prologue or the transform helper —
both of which had prior rejected experiments in the ledger — could not have
moved the needle.

The remaining alias cost is the pixel work itself: `D_PolysetDrawSpans8` and
`D_PolysetScanLeftEdge` in `WinQuake\d_polysa.s`, plus the three still-C helpers
they call, `D_PolysetSetEdgeTable`, `D_RasterizeAliasPolySmooth`, and
`D_PolysetSetUpForLineScan` in `WinQuake\d_polyse.c`. Because the pixel loops
in `d_polysa.s` are already heavily mined and the alignment experiment showed
the loop body resists rearrangement, the remaining C-to-ASM surface in the
alias raster path is the only unexhausted avenue, and it is now the
highest-value remaining target in the renderer.

Instrumentation integrity: `alias-models` is still 5470 and `alias-vertices`
still 417090, `max-depth` is 8 (was 6), and `stack-overflows` and `bad-leaves`
are both 0. The added sub-nodes cost 0.243 s (`0.36%`) against the prior
profile run. Note the three sub-nodes aggregate across both the `entities` and
`viewmodel` call sites, so their sum exceeds either single parent's inclusive
time; that is expected, not an accounting error. Because `alias-raster` now
appears directly in the ranked self-time list at 10.87%, it displaces
`world-bsp` (11.38%) and ranks third overall behind `texture-spans` (27.82%).

### Aff8 16-byte code-alignment experiment (2026-09-29) — rejected and reverted

This was the first attempt in the checkout to use the 486 code-layout axis.
Exploration had confirmed that register allocation, load scheduling, and CSE
were already mined, while **alignment padding was entirely untouched**: no NOP
filler, no `Bochs D4`-style macro, and no `.rept` filler exists in any of the
21 `.s` files, and `d_polysa.s` had exactly one `.p2align` (a `.data` label).
The Aff8 pixel loop had no alignment directives at all.

**The experiment code has since been reverted.** The temporary
`-Aff8LoopAlignment control|aligned` selector, its `ASM486_AFF8_ALIGN` define
in `WinQuake\d_polysa.s`, and the `AFF8_ALIGN` macro sites have all been
removed, along with the selector plumbing in `build-dos.ps1`, `bench-dos.ps1`,
`timedemo-dos.ps1`, and `smoke-dos.ps1`. The tree is back to its pre-experiment
state and this section is preserved as a record of the measurement. The
candidate had been defined as an `AFF8_ALIGN` macro (`.p2align 4,,15`) before
five hot labels: `LDrawLoop`, `LDraw16`, `LAff8LastGroup`, `LNextSpan`, and
`LExactlyOneLong`, with store counts, sampling order, and the fixed-point DDA
unchanged so that only instruction addresses moved.

Both variants used DJGPP GCC 12.2.0, target i586-pc-msdosdjgpp, `-O3
-march=i486`, 83 C sources, and 21 assembly sources, with the pinned
`tools\dosbox-x-486-high.conf` profile, CWSDPMI, and the seeded `demo1`
workload. Note that `qbench.exe` is **not byte-reproducible**: `host.c:912`
and `host_cmd.c:4643` embed `__TIME__`/`__DATE__` in a startup banner, so six
stamp bytes differ between any two builds of identical source. Hashes recorded
in this file identify a build, not the source; compare selectors and
framebuffer checksums instead. The control `qbench.exe` SHA-256 for this pass
was `96FC0BE537B01CA74CBC60D10D20F1610101792DCEA81D14F97396409543230B`.

The alignment was verified in the linked binaries before timing. The candidate
places `LDrawLoop` at `0x90960`, `LAff8LastGroup` at `0x90ce0`, `LNextSpan` at
`0x90cf0`, and `LExactlyOneLong` at `0x90d10`, all on 16-byte boundaries, with
13 NOP bytes of padding at `0x90ce3`-`0x90cef`. The `0x12345678` colormap
placeholder count is **189 in both binaries**, which confirms `D_Aff8Patch`
still covers all 18 patch slots and that `d_modech.c`'s
`D_PolysetAff8Start`..`End` writable range still spans every patched byte
after padding. The loop back-edge `jmp 0x90960` at `0x90cd7` confirms the
target.

Correctness and startup both passed. The candidate reported
`486 benchmark correctness PASS` with end checksum `2378409472`
(`out\dos-bench-20260929-084221\bench-result.json`) and a clean smoke test
with DOSBox-X and Quake exit codes both `0`.

Three alternating pinned `demo1` timedemo pairs followed. Every run completed
969 frames with framebuffer checksum `1047377823`:

```text
control: 59.265452 / 59.265481 / 59.265442 s; median 59.265481 s, 16.350159 FPS
aligned: 59.287251 / 59.287243 / 59.743230 s; median 59.743230 s, 16.219411 FPS
```

The aligned median is `0.477749` seconds (`0.806117%`) **slower** than
control, against a required 0.05% improvement, so the candidate was rejected
and is now fully removed. Artifacts remain in `out\dos-timedemo-20260929-085326`
through `out\dos-timedemo-20260929-085922`.

Two observations matter for interpreting this. First, the aligned spread is
`0.455987` s because the third sample (`59.743230`) is a clear outlier, while
its first two samples are only ~22 ms behind control; the project has seen
this same isolated-outlier pattern in earlier `stosw` runs. Second, and more
importantly, the direction is consistently wrong rather than noisy: even the
two clean aligned samples are slower than every control sample. The likely
cause is that the padding pushes already-large unrolled bodies across an extra
16-byte fetch boundary and displaces other lines from the 8 KB unified cache,
while the write-buffer and fetch-boundary costs this was meant to relieve turn
out not to dominate. *(Corrected: an earlier revision of this paragraph said
"I-cache placement." The 486 has no instruction cache — only an 8 KB unified
data cache — so the mechanism is fetch boundaries and unified-cache
displacement, not an I-cache.)* Because the measured effect is negative rather
than indistinguishable, this is a rejected result and not a null result. Note
also that a genuine physical-486 alignment benefit would not be expected to be
faithfully reproduced by DOSBox-X anyway (`BENCHMARK-COMPARISON.md:49`, and see
"What this harness can and cannot measure" above).

### Current texture-span follow-up (2026-09-29)

A PROFILE486 control run is recorded in
`out\dos-timedemo-20260929-071039\timedemo-result.json`: 969 frames,
framebuffer checksum `1047377823`, with texture spans first at 27.92% self
time and alias models next at 13.29%. The instrumented duration is attribution
only. **This is no longer the most recent profile** — the alias subtree has
since been split into seven sub-nodes (see the sections above), which
re-attributes the alias bucket as 82.95% raster / 15.01% transform / 2.04%
setup, and reports `alias-raster` self time directly. The texture-span
percentage is unchanged; only the alias attribution is refined.

The new opt-in `-TextureSpanStores stosw` path uses unrolled `STOSW` stores
for full 16-pixel segments; `word` remains the default. Candidate smoke and
full `bench486` correctness passed (`2378409472`). Three alternating pinned
timedemo pairs retained 969 frames and checksum `1047377823`; medians were
59.265502 seconds for `word` and 59.325327 seconds for `stosw` (0.10094%
slower). Keep `stosw` only for reproducible A/B work. Full profile, timing,
spread, and artifact details are in `BUILD-DOS.md` under “Latest PROFILE486
and texture-span STOSW experiment.” Alias-model rendering is the next hotspot.

### Current parity-gated closure (2026-09-28)

The release defaults now use the mip-0 four-row and mip-1 eight-row
surface-block loops (`SurfaceBlockMip0Rows=unroll4`,
`SurfaceBlockMip1Rows=unroll8`). The mip-1 loop was promoted after a five-run
mip-0-only control median of 59.374140 seconds and a three-run combined median
of 59.344208 seconds, a 0.0504% improvement. The earlier mip-0 promotion
measured a 0.0573% gain against its control. Every timedemo completed 969
frames with framebuffer checksum `1047377823`; the candidate also passed DOS
smoke and full `bench486` correctness (`2378409472`). Both control paths remain
selectable for matched A/B comparisons.

The fresh PROFILE486 control run is
`out\dos-timedemo-20260929-055543\timedemo-result.json`. Its 67.797249-second
duration is attribution evidence, not release timing. Self-time ranking is
texture spans 27.89%, alias models 13.28%, world BSP 11.41%, surface cache
10.72%, Z spans 9.29%, and edge scanning 8.93%. The surface cache recorded
8,913 rebuilds, 6.481275 seconds of rebuild time, 5.616218 seconds in block
drawing, and no thrash frames. Mip-0 block drawing took 3.692177 seconds; the
profile counted 26,861 horizontal-flat blocks across mip levels. The release
gate remains 969 frames with checksum `1047377823`. Previously tested
texture-span addressing, load-order, and tail-store alternatives remain
rejected or below threshold. No visual-quality, resolution, presentation,
scene, or timing changes are part of this pass.

The BSP frame-count experiment remains unpromoted. Its `local` selector
preserved correctness, smoke, and release framebuffer parity, but its
three-run median was 59.435670 seconds versus 59.408194 seconds for its
control, so it did not clear the 0.05% improvement gate.

### Horizontal-flat mip-0 surface blocks (2026-09-29)

The opt-in `-SurfaceBlockMip0HorizontalFlat fast` path specializes blocks
whose top-left and top-right light values match and whose left/right vertical
steps also match. Each scanline then uses one constant light-map row, so the
drawer skips its per-texel horizontal light updates. The `control` selector
retains the original path. PROFILE486 counted 26,861 horizontal-flat blocks
across the mip levels, motivating a mip-0 specialization.

Five alternating pinned `demo1` runs measured control at
`59.344206 / 59.344204 / 59.344211 / 59.344238 / 59.344298` seconds and fast
at `59.265472 / 59.265448 / 59.265501 / 59.265486 / 59.265487` seconds. The
medians are `59.344211` and `59.265486` seconds, a 78.725 ms (0.13266%) gain;
the full timing ranges are 0.094 ms and 0.053 ms. Every run completed 969
frames with framebuffer checksum `1047377823`. Candidate smoke passed and the
full `bench486` correctness suite passed with checksum `2378409472`. Promote
`fast` as the build, smoke, benchmark, and timedemo default; `control` remains
available for A/B checks. Artifacts are in `out\dos-bench-20260929-061426`,
`out\dos-smoke`, and timedemo directories
`out\dos-timedemo-20260929-062348` through
`out\dos-timedemo-20260929-063449`.

### Monster gib trail zero-XY experiment (2026-09-29)

`R_RocketTrail` creates `pt_grav` only for the `EF_GIB` and `EF_ZOMGIB` blood
trail variants. Those particles start with zero velocity on all axes and only
their vertical velocity changes. The opt-in
`-GibTrailHorizontalIntegration skipzero` path skips the two horizontal
zero-velocity position updates in `R_DrawParticles`; the default `control`
path retains the original C behavior. The selector is supported by the build,
timedemo, smoke, and `bench486` runners. PROFILE486 reports
`metrics.gib_trail_particles` so a replay can confirm it exercises this path.

The pinned `demo1` profile processed 8,162 gib trail particles out of 134,544
total particle updates over 969 frames. The three-run control median was
59.344081 seconds; `skipzero` measured 59.337036 seconds, a repeatable
0.0119% improvement. All six timedemo runs retained framebuffer checksum
`1047377823`. Candidate smoke passed and `bench486` reported correctness PASS
with checksum `2378409472`. Keep `control` as the default: the measured gain is
below the 0.05% promotion gate. Artifacts are in
`out\dos-timedemo-20260928-224352`,
`out\dos-timedemo-20260928-224550`,
`out\dos-timedemo-20260928-224937`,
`out\dos-bench-20260928-225518`, and `out\dos-smoke`.

The mip-0 eight-row extension also remains opt-in. Five fresh alternating
runs, with both executables rebuilt from the same source, measured 59.344242
seconds median for the four-row control and 59.338650 seconds for unroll8, a
0.0094% gain below the gate. All ten runs completed 969 frames with checksum
`1047377823`; smoke and full correctness passed. Keep
`SurfaceBlockMip0Rows=unroll4` as the release value.

> **Superseded 2026-10-02: the release value is `unroll16`, not `unroll4`.** These
> two sub-gate closures were bundled with `SurfaceBlockMip1IndexHoist=hoist` and a
> fully-flat mip-1 body and cleared the gate at 0.0620%; see the `surf8` promotion
> at the top of this file. `build-dos.ps1` is the authority for the current default.
> The measurements below stand.

The mip-0 sixteen-row extension also remains opt-in. Five fresh alternating
runs measured 59.344220 seconds median for the four-row control and 59.335845
seconds for unroll16, a 0.0141% gain below the gate. All ten runs completed
969 frames with checksum `1047377823`; smoke and full correctness passed. Keep
`SurfaceBlockMip0Rows=unroll4` as the release value.

> **Superseded 2026-10-02: the release value is `unroll16`.** As above. Note this
> makes the `unroll8` entry immediately above obsolete as a *candidate* — it is a
> strictly worse variant of a change that is already promoted, so there is nothing
> left to bundle it with.

### Pre-surface-block-loop control and PROFILE486 baseline (2026-09-28)

The exact-parity pass was re-established from the current source before the
new experiment.  The aggressive DJGPP i486 control build used the pinned
`tools\dosbox-x-486-high.conf` profile, CWSDPMI, the Steam `id1` data root,
and the current default selectors (`TextureSpanAddressing=control`).  The
benchmark executable is
`out\dos-memasm-zneg4-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm\qbench.exe`
with SHA-256
`0A9E78074153380228072A257D979E968887C7AD2311EC2DCCAAA162DC2C9EE1`.

The fresh gate artifacts are:

```text
correctness: out\dos-bench-20260928-122205\bench-result.json
smoke:       out\dos-smoke\smoke-result.json
timedemo:    out\dos-timedemo-20260928-123125\timedemo-result.json
PROFILE486:  out\dos-timedemo-20260928-123502\timedemo-result.json
```

Correctness reported `486 benchmark correctness PASS` with end checksum
`2378409472`; smoke exited cleanly with DOSBox-X and Quake exit codes `0`.
The three release timedemo runs all completed 969 frames with framebuffer
checksum `1047377823`:

```text
59.408238 / 59.408105 / 59.408106 seconds
median 59.408106 seconds, 16.310905 FPS
```

The fresh PROFILE486 run took 67.271354 seconds for attribution only.  Its
self-time ranking was texture spans 28.11%, alias models 13.38%, world BSP
11.49%, surface cache 10.03%, Z spans 9.37%, and edge scanning 9.00%.
Texture spans remain the largest renderer hotspot; after the measured
alias-span and world-BSP passes, the next eligible hotspot is the
surface-cache rebuild path.

After leaving the candidate opt-in, the default selectors were rebuilt again.
The final control `qbench.exe` SHA-256 is
`90AF568DE3DC9B8862EF7BB40D2477FB74A75E406CFD70E0A8E044A1064CFA11`; the
normal `quake.exe` SHA-256 is
`C4FD4C4DB5D303479CF02368DFF3100CD96811EB6B1AA9AF8AEAC1C5EE1A254B`.
The post-change control timedemo
`out\dos-timedemo-20260928-130729\timedemo-result.json` again completed 969
frames in 59.408233 seconds at 16.310870 FPS with checksum `1047377823`.
The final control smoke result in `out\dos-smoke\smoke-result.json` reports
DOSBox-X and Quake exit codes both `0`.

### Alias-span address-update experiment (2026-09-28)

The next alias-rasterizer experiment adds an opt-in
-AliasSpanAddressing control|branch selector.  branch defines
ASM486_ALIAS_SPAN_BRANCH_ADDRESS in D_PolysetAff8Start, replacing the
indexed two-entry advancetable lookup with direct base/extra address updates
selected by the T-carry mask.  The candidate tests that mask before the
S-carry-producing update, then uses a fixed ADC displacement; sample order,
depth tests, light/colormap lookup, destination writes, span tails, and the
control path remain unchanged.  control is still the production default.

Both variants used the aggressive DJGPP GCC 12.2.0 i486 profile
(-O3 -march=i486), 83 retained C sources, 21 assembly sources, the pinned
DOSBox-X 486 profile, CWSDPMI, and the legal Steam id1 data root.  The
isolated executable hashes are:

| artifact | control | branch candidate |
| --- | --- | --- |
| qbench.exe | F93123A52971DDD57C4B070DBC9E88C4DE2AD36B270C4203B0A141AE4749E749 | C2430CC7A4DB3D7983B5F35E8B5081925D5C44E0FC29FF777D45693CC64898A8 |
| quake.exe | C7989BEEBA18D22DCB1D1D467124F2B5E04A8D06DE6DF96BD083B8F21E6D5FD1 | 0CBE9F2B4F01EDF05BDDD80F7CD670A9F3C258589033009DB626EA2BFBAE0F8D |

The correctness results are
out\dos-bench-20260928-134700\bench-result.json for control and
out\dos-bench-20260928-133843\bench-result.json for the candidate.  Both
reported DOSBox-X exit 0, 486 benchmark correctness PASS, and end checksum
2378409472.  The candidate smoke evidence is
out\dos-smoke-aliasspanaddrbranch-result.json with clean DOSBox-X/Quake
exits; the final default-control smoke result is
out\dos-smoke\smoke-result.json.

The independent alternating release samples were:

| variant | samples (seconds) | median | median FPS | spread |
| --- | --- | ---: | ---: | ---: |
| control | 59.408173 / 59.408253 / 59.408238 | 59.408238 | 16.310869 | 0.000080 |
| branch | 60.056674 / 59.593444 / 59.593426 | 59.593444 | 16.260178 | 0.463248 |

Every run completed 969 frames with framebuffer checksum 1047377823.  The
branch median is 0.185206 seconds (0.311751%) slower than control, so it
fails the required 0.05% promotion threshold and remains opt-in only.  No
visual-quality, resolution, presentation, scene, or timing changes were made.
The final default-control closure timedemo is
out\dos-timedemo-20260928-140755\timedemo-result.json: 969 frames,
59.408222 seconds, and checksum 1047377823.

The current PROFILE486 attribution remains texture spans at 28.11%, alias
models at 13.38%, and world BSP at 11.49%; after rejecting this alias-span
address path, world BSP traversal was the next hotspot investigated.

### World-BSP frame-count cache experiment (2026-09-28)

The world BSP walk has an opt-in
-BspFrameCountImplementation control|local selector.  local snapshots the
immutable per-frame r_framecount once after node visibility/frustum culling
and reuses it for leaf surface marking and both node-surface visibility
loops.  The control path retains the original global reads and remains the
production default.  No traversal order, surface order, comparison, or
rendering operation changes.

The reproducible commands are:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -Clean -NoBootstrap -BspFrameCountImplementation control
.\tools\build-dos.ps1 -Benchmark -Clean -NoBootstrap -BspFrameCountImplementation local
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -BspFrameCountImplementation control -TimeoutSeconds 600
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -BspFrameCountImplementation local -TimeoutSeconds 600
.\tools\smoke-dos.ps1 -SkipBuild -NoBootstrap -BspFrameCountImplementation local -DynamicLightImplementation asm -TimeoutSeconds 180
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -BspFrameCountImplementation control
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -BspFrameCountImplementation local
~~~

Both variants used DJGPP GCC 12.2.0, target i586-pc-msdosdjgpp,
-O3 -march=i486, 83 retained C sources, 21 assembly sources, the pinned
DOSBox-X 486 profile, CWSDPMI, and the same legal Steam id1 data root.  The
final executable hashes are:

| artifact | control | local candidate |
| --- | --- | --- |
| qbench.exe | D8CC026621C603512028138E546BEBF806F540CA74918AE344D16FF0DD843D46 | BBD6BC2468382872730AA8978552C4C1931EE12D1BAD11BBCA9996571F086FD6 |
| quake.exe | 866EBCE2072AA6F7E954A79A802E3199D6CAABCFC5C0E995246B226AF1FBBDEF | 2CB2B5F1DF06B3F28BB9490BE8FDFA2069CBBAB0713828AD747D3FCA0213D121 |

The correctness results are
out\dos-bench-20260928-163429\bench-result.json for control and
out\dos-bench-20260928-162612\bench-result.json for local.  Both reported
DOSBox-X exit 0, 486 benchmark correctness PASS, and end checksum 2378409472.
The candidate smoke evidence is out\dos-smoke-bspframecache-result.json with
DOSBox-X and Quake exit codes 0; the final control smoke evidence is
out\dos-smoke\smoke-result.json, also with both exit codes 0.

The independent alternating release samples were:

| variant | samples (seconds) | median | median FPS | spread |
| --- | --- | ---: | ---: | ---: |
| control | 59.408213 / 59.408180 / 59.408194 | 59.408194 | 16.310881 | 0.000033 |
| local | 59.435670 / 59.435661 / 59.435771 | 59.435670 | 16.303341 | 0.000110 |

Every run completed 969 frames with framebuffer checksum 1047377823.  The
local median is 0.027476 seconds slower, or 0.046250%, so it does not clear
the required 0.05% promotion threshold.  The candidate is rejected for
promotion but retained as an explicit opt-in experiment; control remains the
production default.  Release evidence is in
out\dos-timedemo-20260928-164250, out\dos-timedemo-20260928-164441,
out\dos-timedemo-20260928-164556, out\dos-timedemo-20260928-164708,
out\dos-timedemo-20260928-164832, and out\dos-timedemo-20260928-164945.
The final rebuilt control closure is
out\dos-timedemo-20260928-165256\timedemo-result.json: 969 frames,
59.408217 seconds, and checksum 1047377823.

The profile ranking remains texture spans at 28.11%, alias models at 13.38%,
world BSP at 11.49%, and surface cache at 10.03%; the surface-cache rebuild
path is the next hotspot to investigate.  No visual-quality, resolution,
presentation, scene, or timing changes were made.

### Texture-span address-update experiment (2026-09-28)

The full 16-pixel word-store texture loop has an opt-in
`-TextureSpanAddressing control|branch` selector.  `branch` replaces the
indexed two-entry `advancetable` lookup with direct base/extra address adds
selected by the T carry, while retaining the S carry and the original sample
and store sequence.  It is restricted to `TextureSpanStores=word`,
`TextureSpanLoadOrder=control`, and `TextureSpanRowPath=control`.
`control` remains the production default.

The candidate build was isolated under
`out\dos-memasm-spanaddrbranch-zneg4-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm`.
Its benchmark `qbench.exe` SHA-256 is
`8D44EA9AC5E3002B05E7E0C25B8697166AA8BF6D7DD4FE85A080A4173334694E`; the
normal smoke executable SHA-256 is
`B14F6732726AB59DF860D4AC97D81C9314FC1481705872B95E1310750BB96FA2`.
The selector and build metadata are recorded in the result JSON files.

The candidate correctness result
`out\dos-bench-20260928-124646\bench-result.json` reported
`486 benchmark correctness PASS` and end checksum `2378409472`.  The
candidate smoke result was also a clean DOSBox-X/Quake exit.  However, the
release timedemo result
`out\dos-timedemo-20260928-125539\timedemo-result.json` exposed a parity
failure: all three 969-frame runs produced framebuffer checksum `2110466403`
instead of the required `1047377823`.

```text
branch: 60.664292 / 60.664491 / 60.664483 seconds
median 60.664483 seconds, 15.973103 FPS
```

The candidate was `1.256377` seconds (`2.114824%`) slower than the fresh
control median and failed the release checksum gate, so it is rejected for
promotion.  It remains an explicit opt-in only to reproduce the rejection;
the default control path is unchanged.  The next pass should move to the
alias-model rasterizer hotspot, then world BSP if no exact-parity win appears.

### Current reproducibility note (2026-09-26)

ASM/setup: D_SetupFrame now lazily rebuilds viewspantable only when the active
view buffer or effective row stride changes. Full correctness and video tests
pass. Three raw demo1 runs measured 59.422468 / 59.422417 / 59.422374
seconds (median 16.306977 FPS), checksum 1047377823 on every run, versus the
16.297855 FPS clean baseline.

The benchmark worktree seeds srand(1) at the start of PROFILE486 timedemos and
uses -falign-jumps=16 in the aggressive DOS build. These changes make the
current profiling/timedemo workload deterministic enough for A/B comparison,
but they change the framebuffer reference from older handoff runs. The current
worktree authority is 969 frames with checksum 1047377823; older reports using
4154140932 remain historical results and must not be mixed into current A/B
comparisons.

The optional ASM surface-cache predicate was rechecked with guarded dispatch
and then rejected: C median 59.506742 seconds (16.283870 FPS) versus ASM median
59.512084 seconds (16.282407 FPS) across three raw runs. All runs completed
969 frames with checksum 1047377823, and both variants passed the full 486
benchmark correctness PASS harness. Keep the C surface-cache predicate as the
default; a focused helper win is insufficient when the complete timedemo loses.

The negative-gradient Z-span eight-pixel packing schedule was rechecked with
the current seeded workload. It is available only through the explicit
`-ZSpanNegativeUnroll unroll8` build/timedemo option; `control` remains the
production default. Three matched runs completed 969 frames with checksum
1047377823: control measured 59.408069 seconds median and `unroll8` measured
59.408076 seconds. The candidate is rejected as a marginal regression, but the
selector remains for reproducible A/B work. The accompanying PROFILE486 run
puts texture spans first at 28.11% of instrumented self time, making them the
next optimization target; the instrumented duration is attribution evidence,
not a release timing claim.

### Texture-span row-cross experiment (2026-09-28)

`D_DrawSpans16` now has an opt-in `-TextureSpanRowPath norowcross` selector,
implemented by `ASM486_SPAN16_NO_ROW_CROSS`; `control` remains the default.
For full 16-pixel segments, the candidate uses an S-only texture-address loop
only when the clamped T endpoint is non-negative relative to the start and both
endpoints are in the same texture row.  Negative gradients and row crossings
use the unchanged control DDA.  The 8-bit span path is outside this slice.

The matched aggressive i486 builds were made with:

```powershell
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -TextureSpanRowPath control
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -TextureSpanRowPath norowcross
```

Both `bench-dos.ps1 -SkipBuild` runs passed `486 benchmark correctness PASS`
with end checksum `2378409472`.  Three alternating release timedemo pairs were
run with `tools\dosbox-x-486-high.conf`, CWSDPMI, the seeded `demo1` workload,
and the same `id1` data.  Every run completed 969 frames with framebuffer
checksum `1047377823`:

```text
control:    59.408221 / 59.408218 / 59.408243 s, median 59.408221 s, 16.310874 FPS
norowcross: 59.753011 / 59.753108 / 60.217335 s, median 59.753108 s, 16.216730 FPS
```

`norowcross` is `0.344887` seconds (`0.580537%`) slower than control.  The
median delta is above the `0.05%` escalation threshold, so no five-sample repeat
was required.  The candidate is rejected for promotion and retained as an
explicit opt-in experiment; `control` stays the release default.  Build,
benchmark, and timedemo JSON metadata record `textureSpanRowPath`, and the
candidate output is isolated under the ignored `...-spannorow` directory.

PROFILE486 evidence is in `out\dos-timedemo-20260928-070210` (control) and
`out\dos-timedemo-20260928-070331` (candidate).  The new profile counters are
`row_eligible=0,row_fast=0` for control and
`row_eligible=209338,row_fast=209338` for the candidate.  This proves the
candidate path was exercised, but the instrumented timing remains attribution
evidence rather than a release performance claim.

### Texture-span load-order experiment (2026-09-28)

The full 16-pixel texture-span word-store loop now has an opt-in
`-TextureSpanLoadOrder control|loadfirst` selector. `loadfirst` starts each
current texel load before the independent fixed-point S/T accumulator updates;
the carry-producing updates, sample order, and packed destination stores are
unchanged. It requires `-TextureSpanStores word`; `control` remains the
production default.

The candidate passed the existing correctness harness with end checksum
`2378409472`. Initial three-run timedemos under the pinned DOSBox-X 486
profile completed 969 frames with framebuffer checksum `1047377823` on every
run:

```text
control:    59.408224 / 59.408166 / 59.408042 s, median 59.408166 s
loadfirst:  59.408243 / 59.408113 / 59.408102 s, median 59.408113 s
```

Three additional alternating control/candidate pairs were:

```text
control:    59.408221 / 59.408177 / 59.408211 s, median 59.408211 s
loadfirst:  59.408215 / 59.408193 / 59.408237 s, median 59.408215 s
```

The alternating median difference is `0.000004` seconds, inside the observed
run spread. This is a noise-level result, so `loadfirst` remains an explicit
opt-in experiment and `control` remains the release default.

The matched benchmark executables were built with the pinned
`i586-pc-msdosdjgpp-gcc 12.2.0` aggressive profile (`-O3 -march=i486`), 83 C
sources, and 21 assembly sources. The control `qbench.exe` SHA-256 is
`8D2623E045ED5DB4133D47B35B69335F8995422A815A8347158F27ACE123958F`; the
`loadfirst` candidate is
`9A5DFCDDFD35235C9BA72FDE1CEDC8429E70B59D5FB1E25B2CA0DE0C883C6D05`.
The candidate profile executable SHA-256 is
`EFBF1ECB4684C2D97AAFA89FA06B1AF8E7F65F0D4ACC415467FE0EDF00602428`.
The instrumented candidate run (`out\dos-timedemo-20260928-093436`) took
67.271309 seconds for 969 frames and ranked texture spans 28.11%, alias models
13.38%, world BSP 11.49%, surface cache 10.03%, Z spans 9.37%, and edge
scanning 9.00% by self-time. Input, game, audio, and present accounted for
0.03%, 0.88%, 0.03%, and 0.64%, respectively. These timings are profiling
attribution, not a release claim.

Final closure validation after the control rebuild passed as well:
`out\dos-bench-20260928-094143\bench-result.json` records DOSBox-X exit code
`0`, `486 benchmark correctness PASS`, and end checksum `2378409472`; the
candidate `out\dos-smoke\smoke-result.json` records DOSBox-X and Quake exit
codes both `0`.

### Alias-model prepare source-cursor experiment (2026-09-28)

The final PROFILE486 control ranked texture spans at `28.11%` self time, alias
models at `13.38%`, world BSP at `11.49%`, surface cache at `10.03%`, Z spans
at `9.37%`, and edge-scan self at `9.00%`; alias work was 5,470 models and
417,090 vertices. The new build-time selector is
`-AliasPrepareImplementation control|local`, with `control` unchanged as the
production default. The `local` candidate only carries `r_apverts` through
`R_AliasPreparePoints` in a local pointer, then publishes the same final
post-incremented cursor. Clip-bound loads, helper/comparison order, fixed-point
and x87 behavior, flags, simulation, audio, and framebuffer writes remain
unchanged. The previously rejected `aliasvrect`-local hoist was not retried.

Both final builds used DJGPP GCC 12.2.0, target `i586-pc-msdosdjgpp`,
`-O3 -march=i486`, 83 C sources, and 21 assembly sources. The control and
candidate `qbench.exe` hashes are respectively
`18C5A92B2F6CB0DF6BB10BADDDA1491BB0BCFC11738BB80A80B56A939FBCCA33` and
`876B1AD6C22BFEC9B1CC6048F5E97A01A8F34B45D64E55522D30BE81D6A1580A`; the
instrumented `qprof.exe` hashes are
`CFEA0ED0F24DC7F85F99CD57C6B8BDCA27B36460317699D453564F61BEEB151B` and
`3729E13DECDB7F203E0F939E1ABE5193882976AEB3A5C7792F0D3A255CBEBEDE`.
The build manifests record the selector and keep the candidate in the
`...-aliaslocal...` output family. Their `sourceCommit` is
`de1d41d12d3e54286291c59e35822e27182e2228`; the selector and source-cursor
change are the intentional working-tree patch under test.

The benchmark, timedemo, and smoke wrapper auto-build paths also use named
parameter forwarding, so a missing isolated executable cannot misbind a
selector or benchmark switch. Explicit build followed by `-SkipBuild` remains
the preferred measured workflow.

The control correctness result is
`out\dos-bench-20260928-111615\bench-result.json`; the candidate result is
`out\dos-bench-20260928-104656\bench-result.json`. Both passed
`486 benchmark correctness PASS` with end checksum `2378409472` and DOSBox-X
exit code `0`. The candidate smoke result reports DOSBox-X and Quake exit code
`0`.

The fresh alternating release set was:

```text
control: 59.408180 / 59.408212 / 59.408172 s, median 59.408180 s, 16.310885 FPS
local:   59.404173 / 59.404192 / 59.404109 s, median 59.404173 s, 16.311986 FPS
```

Every run completed 969 frames with framebuffer checksum `1047377823`. The
candidate median is `0.004007` seconds faster (`0.006745%`), with maximum
within-variant spread `0.000083` seconds. It still fails the required `0.05%`
promotion threshold, so it is rejected and retained only as an opt-in
experiment; `control` remains the default. Release results are in
`out\dos-timedemo-20260928-110615`, `...-110752`, `...-110904`,
`...-111017`, `...-111130`, and `...-111242`. The control and candidate
PROFILE486 runs are `out\dos-timedemo-20260928-111433` and
`out\dos-timedemo-20260928-110347`; their instrumented timings are attribution
evidence only.

### Texture-span tail-store experiment (2026-09-28)

The variable-length final segment of `D_DrawSpans16` has an opt-in
`-TextureSpanTailStores control|word` selector.  The `word` candidate defines
`ASM486_SPAN16_TAIL_WORD_STORES`, packs adjacent pre-final samples with `movw`,
and preserves the existing fixed-point DDA order and final-sample behavior.
Full 16-pixel segments and `D_DrawSpans8` are unchanged; `control` remains the
default.

Both matched aggressive i486 builds passed `486 benchmark correctness PASS` with
end checksum `2378409472`.  Three alternating release timedemo pairs used the
pinned DOSBox-X 486 profile, CWSDPMI, seeded `demo1`, and the same `id1` data.
Every run completed 969 frames with framebuffer checksum `1047377823`:

```text
control: 59.408215 / 59.868491 / 59.408242 s, median 59.408242 s, 16.310868 FPS
word:    60.135289 / 60.135318 / 60.135324 s, median 60.135318 s, 16.113659 FPS
```

`word` is `0.727076` seconds (`1.223864%`) slower than control.  The median
delta is above the `0.05%` escalation threshold, so no five-sample repeat was
required.  The candidate is rejected for promotion but retained as an explicit
opt-in experiment; `control` stays the release default.  Build, benchmark, and
timedemo JSON metadata record `textureSpanTailStores`, and the candidate output
is isolated under the ignored `...-spantailword` directory.

The next sequential pass also rejected two leads. The proposed surf8.s
lightright-store removal was invalid: the stores at the end of the mip0, mip1,
and mip2 blocks feed the next loop iteration through C(lightright), so they are
live lighting state and must remain. A scoped zero-vector early-out before
VectorNormalize in DropPunchAngle passed the correctness harness and retained
969 frames/checksum 1047377823, but its three-run median was 16.283890 FPS
versus the 16.283870 FPS baseline, an insignificant 0.000020 FPS difference.
It was reverted as measurement noise. Do not promote either experiment.

The nested repository is the Git boundary: `D:\Project\486quake\quake`.
The current source uses the `aggressive` profile (`-O3 -march=i486`) and the
repository-owned `tools\dosbox-x-486-high.conf` profile (`cputype=486`, fixed
33445 cycles, DOSBox-X 2026.08.31, 16 MB).  The current default selections are:

- ASM: alias projection, alias bounding-box projection, clipped alias
  transform/lighting, texture-animation selection, and lightmap normalization.
- `stosb`: turbulent-span stores.
- `word`: 16-pixel texture-span stores are the production default.  The full
  segment path packs adjacent destination pixels with `movw` while preserving
  the original sampling/DDA order.  Three matched runs measured
  `59.408238 / 59.408105 / 59.408106` seconds (median `59.408106`), with
  checksum `1047377823` on every run.  `byte` remains the original unrolled
  control path; dword packing and the stosb loop remain explicit alternatives.
  The earlier `59.497xxx` / `4154140932` measurements are historical and are
  not comparable with the current seeded workload.
- C: memory helpers, texture-axis cache predicate, surface-cache predicate,
  mip-level selection, BSP plane-dot, and BSP frustum clipping.
- ASM: generic lightmap style accumulation is now the production default via
  LightMapStylesImplementation=asm. The C reference remains selectable.
  The focused maps-1..4 cases all matched, and matched demo1 runs measured
  C at 59.512120 / 59.512084 / 59.512013 seconds versus ASM at
  59.503904 / 59.503792 / 59.503771 seconds, with checksum 1047377823 on
  every run. The full correctness harness passed for both variants.
- ASM: fused no-dynamic-light 2/3/4-style lightmap accumulation is also now
  the production default via FusedLightMapImplementation=asm. Focused boundary
  cases and full correctness passed. Matched demo1 runs measured C at
  59.504490 / 59.504450 / 59.504481 seconds versus ASM at
  59.502617 / 59.502563 / 59.502535 seconds; all runs kept checksum
  1047377823.
- ASM: the first alias transform composition now uses the specialized diagonal
  matrix path by default via AliasMatrixCompositionImplementation=special.
  AngleVectors and the second composition remain unchanged. Three matched
  demo1 runs measured C at 59.502611 / 59.502548 / 59.502529 seconds versus
  special at 59.455982 / 59.455677 / 59.455756 seconds; every run kept
  checksum 1047377823 and the full correctness harness passed.
- ASM: the existing dynamic-light sample loop is now the production default via
  DynamicLightImplementation=asm. Matched demo1 runs measured C at
  59.422461 / 59.422365 / 59.422373 seconds versus ASM at
  59.410915 / 59.410949 / 59.410930 seconds; all runs kept checksum
  1047377823 and the full ASM correctness harness passed.
- VGA full-frame linear-copy fast path was tested and rejected. Direct VGA
  parity tests passed, and forced -stdvid timedemos kept checksum 1047377823,
  but the guarded candidate measured 16.302751 FPS versus the matched control
  at 16.303103 FPS. The candidate was reverted; retain the expanded VGA
  coverage, but do not promote the copy shortcut.
- Inlined 486 setup: power-of-two surface wrap in `R_DrawSurface`, release
  builds skip `D_CheckCacheGuard`, and `R_AliasSetViewMatrix` fills the alias
  view matrix once per frame.
- `Mod_LoadTexinfo` copies `vecs[2][4]` with nested `j<2`/`k<4` loops so
  `-O3` `-Waggressive-loop-optimizations` cannot walk off the array.
- Bmodel span drawing: consecutive surfaces from the same brush entity keep
  the rotated axes; later revisits reuse `R_RotateBmodelCached` instead of
  rebuilding the matrix with `sin`/`cos`.  `R_RotateBmodel` remains the
  reference.
- Face Z gradients: `R_SetSurfaceZGradients` reuses one plane's finished
  `d_zistep` values while the drawing `currententity` is unchanged this
  frame.  The entity pointer replaces three `modelorg` float comparisons;
  the miss path remains the original `TransformVector` / `1/z` arithmetic.
- Z spans: `D_DrawZSpans` ASM uses `zspantable` row bases instead of
  IMUL `d_zrowbytes`.  The span list cursor lives in `%ebp` so the pack
  loop can scratch `%esi` without push/pop per span.  The first packed pair
  in both positive- and negative-gradient loops uses 486 `shldl`/`rorl`
  packing instead of a masked `%esi` high-word merge; the C multiply path
  remains the reference.
- Edge scan: `R_GenerateSpans` / `Lgs_leading` reuses the live
  `surfaces` pointer in `%eax` instead of reloading it before the leading
  surface add.  `Lnewtop_fpop2` no longer loads a dead `st_key` into
  `%eax` before `Lnewtop` overwrites it.  `R_EmitEdge` omits the
  discarded next-edge pretouch loads on both leading and trailing sides,
  loads `edge_p` and `r_pedge` only after the horizontal early-out
  (`leal` for `edge_p+et_size` so CF from the ceil compare feeds the side
  test; no preload into `%esi`), and drops an unused `r_pedge` load on the
  fully-clipped both-points-out path (cacheoffset only).
  `LPop5AndDone` loads `r_framecount` only when `cacheoffset != 0x7FFFFFFF`
  (matches C; partially-clipped exits skip the dead dword).
  `TrailingEdge`
  uses memory `decl` for `--surf->spanstate` (ZF test; inverted path
  needs no extra store), emit / `LNoEmit2` unlink with the already-loaded
  `st_next` in `%ecx` instead of reloading into `%edx`, skips the
  `r_bmodelactive` update when `insubmodel` is 0, and uses `decl`/`incl`
  memory forms for bmodel enter/leave (matching C's `++`/`--`).
  Emit compares `iu` to `st_last_u` via memory `cmpl` (load `last_u` into
  `%edx` only when emitting).
  Leading
  non-inverted paths store `movl $1` into `spanstate` (was 0) instead of
  `incl`+store; inverted `Lxl_done` still uses `incl`.
  Leading first key test uses memory `cmpl st_key(%esi),%eax` (drops
  preload into `%ecx`; dead on `Lnewtop` / `Lzcheck_for_newtop`).
  Sort walks `Lsortloopnb` / `Lsortloop` use the same memory `cmpl`
  (drop per-probe key preload into `%ecx`).
  `R_StepActiveU` `LPushBack` checks `edge_aftertail` before loading
  `et_prev`/`et_next` (matches C; every scanline's finish early-out
  skips two dead dword loads).
  `R_StepActiveU` step probes 1–3 defer `et_next` past the order
  early-out; `LPushBack` / `LPushBack2` load continuation `et_next` only
  after aftertail (matches C; drops the duplicate unlink load).
  Probe 4 keeps its preload for `jnl LNextEdge`.
  `R_RemoveEdges` finishes both unlink stores before testing
  `nextremove` (matches C; drops `%ebx` push/pop and the odd-tail
  `Lre_done` second-store path).
  `R_InsertNewEdges` defers `et_next` past the `et_u` early-out on the
  first three search probes (dead on `LAddedge` / `LAddedge2`); the
  fourth probe keeps the original `jg` fallthrough so long walks do
  not pay an extra `jmp`.  Search probes use memory `cmpl et_u(...)`
  (drop preload into `%ebx`).
  `R_StepActiveU` `LPushBackLoop` defers `et_prev` past the first
  `et_u` early-out (dead on `LPushBackFound`); second probe unchanged.
  Pushback search uses memory `cmpl et_u(...)` (drop preload into `%ebx`).
  Step probes use memory `addl et_u_step(...)` (drop preload into `%ebx`).
  Leading `Lnewtop` compares `iu` to `st_last_u` via memory `cmpl` (load
  `last_u` into `%edx` only when emitting), matching TrailingEdge.
  `R_EmitEdge` compares `ceilv0` to `r_ceilv1` via memory `cmpl` and loads
  `r_ceilv1` into `%ecx` only when the edge is non-horizontal (CF still
  feeds the side `jc` after `leal`).
  `D_PolysetRecursiveTriangle` midpoint s/t/zi uses memory `addl` of
  `lp2` fields (drop `%edx` preloads); x/y still keep `lp1` live for
  nodraw compares and `new[0]`/`new[1]` into LDraw.
  `R_EmitEdge` u-clamp uses memory `cmpl` against vrect left/right
  (load the clamp bound into `%edx` only on the taken clamp paths).
  EmitEdge `LSide1`/`LSide0` use memory `subl C(surfaces)` for the
  `surface_p - surfaces` index instead of preloading `surfaces` into
  `%esi`; `%esi` is then set with `movl %edx,%esi` (0) or
  `movl $1,%esi` for the sort side.
- Texture spans: `D_DrawSpans16` / `D_DrawSpans8` ASM load dest rows from
  `viewspantable` (`d_viewbuffer + d_scantable[v]`, filled in
  `D_SetupFrame`).  Alias polyset, sprites, particles, and live
  `Turbulent8` dest rows use the same table.  Live
  `D_RasterizeAliasPolySmooth` dest and Z rows also use
  `viewspantable` / `zspantable`; the multiply form stays in a comment.
  C `D_DrawSpans8` still
  multiplies `screenwidth`.  `D_PolysetDrawFinalVerts` hoists the
  viewmodel clip edges into registers/locals; C matches the live ASM.
  `D_PolysetSetUpForLineScan` uses a 64x64 `adivtab` for `tm,tn` in
  `[-31,32]` (was 32x32 / `[-15,16]`); longer edges still use IDIV /
  `FloorDivMod`.  Live ASM `D_PolysetDrawSpans8` builds `advancetable` /
  `tstep` once per call (same pattern as `lzistepx`).
  Aff8 pixel leaves use `movzbl` for the texel/`(light<<8)|texel`
  colormap index instead of `xorl`+`movb`.
  Aff8 `LExactlyOneLong` loads `ptex` only after the Z test passes.
  Aff8 multi `Lp8` skips the post-group s/t/z/ptex step when the last
  group finishes (`decw`/`jz` before the dead advance).
  `D_PolysetDrawFinalVerts` uses `movzbl` for the skin texel (drops
  `andl $0x00FF` before the light-shifted colormap add) and forms
  `(light<<8)|texel` via `movb` of `v[4]`'s high byte into `%dh` (Aff8-style;
  drops dword light load/`andl $0xFF00`/`addl`).
  `D_DrawSubdiv` sets `d_pcolormap` only after the backface cull (matches
  C; skips the store on culled triangles).
  `D_RasterizeAliasPolySmooth` reuses left-edge s/t base products for the
  extra-step path (`d_countextrastep = ubasestep + 1`).
  Live ASM `D_PolysetScanLeftEdge` keeps the package cursor in `%esi`,
  live `d_pdest`/`d_pz` in `%edi`/`%ebp`, and spills light/zi/aspancount
  on the stack (aspancount written back once on exit).  The discarded
  next-package cache pretouch `movb` is omitted; the first store after
  advancing `%esi` still touches the line.  After packaging the last
  row, the Bresenham step is skipped (`decl`/`jz` before the step;
  matches Aff8 last-group).  `D_PolysetRecursiveTriangle`
  pixel leaf reuses live `new[1]`/`new[0]` in `%ecx`/`%ebp` from the Z
  setup (`movzbl` colormap index; no stack reloads).  Leading-edge nodraw
  loads `lp2[0]` only on the equal-`y` path (into `%eax` so live
  `new[0]`/`new[1]` in `%edx`/`%ebp` survive into `LDraw`, skipping the
  stack reloads at draw entry).  Near-edge `|dy|` split checks
  defer the next-edge `lp3[0]`/`lp1[0]` prefetches until after the
  `ja LSplit`/`LSplit2` early-outs.  Same-edge `|dx|` early-outs skip the
  y loads until `|dy|` is actually tested (`LSplit3` saves `lp1` locally).
- Sprite and particle Z: ASM uses `zspantable` instead of IMUL
  `d_zrowbytes`.  The C multiply paths remain the reference.
- `R_DrawSurface` wraps the per-column source offset with AND when the
  mip width is a power of two; the compare/branch loop remains the
  non-POT reference.
- Surface cache: `SURFCACHE_SIZE_AT_320X200` is `2400*1024` (was `1800*1024`;
  **raised 2026-09-29 — 0.0635% faster, checksum `1047377823`, and the
  "1900 KB and larger failed checksum `2955717646`" claim below is a
  confounded build, not a cache-size defect**).
  `D_CacheSurface` skips `R_TextureAnimation` for static textures and
  fills `r_drawsurf` only on a miss; unused extra light styles are skipped
  when `styles[1] == 255`.  `R_TextureAnimation` remains the
  animated/alternate reference.  `R_BuildLightMap` folds ambient into the first
  lightmap style so the common one-style case writes `blocklights` once.
  When there are no dynamic lights, invert/clamp is fused into that write
  for one to four styles; dlights still accumulate then call
  `R_BuildLightMapNormalize_*`.  `R_AddDynamicLights` keeps the per-texel
  distance in an integer and walks `blocklights` by row;
  `R_AddDynamicLights_C` remains the float-`dist` reference.
  Rebuilds no longer compute unused `surfscale` or store
  `cache->mipscale`; the header field remains for layout.
  `R_MarkLights` skips faces whose plane distance already fails the
  same `radius - fabs(planedist) < minlight` reject used by
  `R_AddDynamicLights`, and also skips faces whose projected impact
  is farther than `fmin` from the lightmap rect under the same integer
  idist metric, so impossible dlight marks no longer force
  surface-cache rebuilds.  `cache->dlight` is set only when
  `R_AddDynamicLights` actually increments a sample (`r_dlight_contributed`),
  so zero-contribution marked rebuilds do not sticky-miss the next frame.
  `D_CacheSurface` also probes `R_DlightContributes` on marked frames with a
  clean cache hit so phantom marks skip the rebuild on the marked frame itself.

Every ASM candidate retains its C implementation.  `build-dos.ps1`,
`bench-dos.ps1`, and `timedemo-dos.ps1` expose independent `c|asm` selectors
and write separate ignored output directories when needed.  `out\` contains
generated executables, staged data, logs, JSON reports, and object files; it is
not source and must not be committed.

## Completed experiments and decisions

This ledger contains historical measurements from multiple benchmark
generations.  Entries using framebuffer checksum `4154140932` predate the
current `srand(1)` seeded workload; the current release authority is 969
frames with checksum `1047377823`, as recorded in the fresh control section
above.  Do not compare timings across those checksum generations.

The entries below preserve their original alternating C/ASM evidence and
checksums; newer exact-parity results are recorded in the current sections
above.  The percentages below are DOSBox-X evidence, not a claim about all
physical 486 variants.

| Experiment | Focused result | Timedemo result | Decision |
| --- | --- | --- | --- |
| Texture-span setup (`d_draw16.s`) | Narrow address-arithmetic change | About 0.10% faster | Kept |
| Turbulent stores | Existing ASM 20.6--28.8% faster than C; `stosb` tied it in isolation | `stosb` 0.086207% faster than existing ASM | `stosb` default |
| Alias projection (`R_AliasProjectFinalVert`) | 7.316--7.317% faster | 0.017696% faster | ASM default |
| Texture animation (`R_TextureAnimationFrame`) | 1.052--31.999% faster | 0.009406% faster | ASM default |
| Lightmap normalization (`R_BuildLightMap`) | 9.447--9.969% faster | 0.0275% faster | ASM default |
| Alias bbox projection (`R_AliasCheckBBox`) | 16.667--20.120% faster | 0.0264% faster | ASM default |
| Clipped alias transform (`R_AliasTransformFinalVert`) | 20.000--25.218% faster | 0.150883% faster | ASM default |
| Memory helpers (`Q_memset`/`Q_memcpy`) | About 4.6--64.4% faster by case | ~0.019% faster end-to-end on current 486 timedemo; checksum pass | **ASM default**; C reference |
| Texture-axis predicate (`D_GetTextureAxes`) | 0.000% to -0.002% | Not promoted | C default |
| Surface-cache predicate (`D_CacheSurface`) | 3.846--5.000% faster | 0.030% slower | C default |
| Mip selector (`D_MipLevelForScale`) | Mixed: -8.697% to +7.143% | 0.0092% slower | C default |
| BSP plane dot (`R_RecursiveWorldNode`) | Mixed: -13.334% to +21.052% | 0.0367% slower | C default |
| BSP clipping (`R_RecursiveWorldNode`) | Mixed: -4.651% to +55.931% | 0.2749% slower | C default |
| Span16 dword stores (`d_draw16.s`) | Checksum pass | Median 68.958760 s vs 68.958817 s (noise) | `byte` default; `dword` opt-in |
| Span16 dword stores recheck (current source, 486 profile) | Three no-FPS-stat runs: 62.568941 / 62.568978 / 62.568999 s; checksum pass | Matching byte runs: 62.569014 / 62.568957 / 62.568953 s; medians differ by ~1 microsecond | `byte` remains default |
| Aff8 Z-store scheduling probe (`d_polysa.s`) | Moved Z store ahead of skin load in all eight pixels | 62.568983 / 62.569006 / 62.569015 s; ~27 microseconds slower than matched byte baseline; checksum pass | Reverted |
| Span16 loop+stosb (`d_draw16.s`) | Checksum pass | 70.980641 s / 13.651610 FPS, ~2.8% slower | `byte` default; `loop` opt-in |
| Surface block `movw` (`block8.h`) | Checksum pass | Noise vs byte stores | Reverted |
| Surface wrap + cache guard + alias view matrix | Inlined, no new helper | 68.946370 s / 14.054401 FPS, 12.4 ms faster | Kept |
| Aggressive `-O3` vs `-O2` | Checksum pass; `+quit` smoke pass | 68.421397 s / 14.162237 FPS | **Default**; `-O2` is `-OptimizationProfile baseline` |
| Bmodel span rotation cache (`d_edge.c` / `R_RotateBmodelCached`) | Id per-polygon `sin`/`cos` FIXME | 68.379696 s / 14.170874 FPS, 41.7 ms faster | Kept |
| Fused first-style lightmap (`R_BuildLightMap`) | Ambient+style0 in one write pass | 68.309838 s / 14.185365 FPS, 69.9 ms faster | Kept |
| Fused one-style normalize (`R_BuildLightMap`) | Invert/clamp in the first write when there are no extra styles or dlights | 68.265779 s / 14.194521 FPS, 44.1 ms faster | Kept |
| One-style lightmap inverse-base hoist (`R_BuildLightMap`) | Hoist `255*256 - ambient` out of the common no-dlight texel loop | 62.052978 s / 15.615689 FPS median vs 62.057653 s / 15.614513 FPS baseline; 0.0075% faster, checksum pass | Kept |
| Dynamic-light S-axis accumulator (`R_AddDynamicLights`, `R_DlightContributes`) | Replace repeated `local[0] - s*16` calculation with an integer scanline accumulator; preserve sample order | 62.018356 s / 15.624406 FPS median; 34.6 ms faster than the prior default, checksum pass | Kept |
| Z-gradient cache key (`R_SetSurfaceZGradients`) | Use the stable drawing entity pointer instead of three `modelorg` float comparisons | 61.989240 s / 15.631745 FPS median across five runs; checksum pass | Kept |
| BSP visibility predicate order (`R_RecursiveWorldNode`) | Check `visframe` before the surface backface flag in both node surface loops | 61.976925 s / 15.634851 FPS median across five runs; 12.3 ms faster, checksum pass | Kept |
| Zero-step Z-span stores (`D_DrawZSpans`) | When fixed-point `izistep` is zero, reuse the initial-Z result with `rep stosw` instead of per-pixel gradient updates | 61.559877 s / 15.740772 FPS median across five runs; checksum pass | Kept |
| BSP node visibility predicate order (`R_RecursiveWorldNode`) | Reject stale node `visframe` before checking `CONTENTS_SOLID` | 61.556783 s / 15.741564 FPS median across five runs; 3.1 ms faster, checksum pass | Kept |
| Integer subdivided alias cull determinant (`D_PolysetDraw`) | Replace the six-load x87 determinant with the matching 32-bit integer expression used by the non-subdivided path | 61.496717 s / 15.756939 FPS median across three runs; 60.1 ms faster, checksum pass | Kept |
| Integer determinant base restore (`D_PolysetDraw`) | Restore `%edi` from stable `r_affinetridesc.pfinalverts` instead of stack push/pop around the scratch determinant | 61.487373 s / 15.759333 FPS median across five runs; 9.3 ms faster, checksum pass | Kept |
| Z-span first-pair packing (`D_DrawZSpans`) | Pack the first aligned depth pair with 486 `shldl`/`rorl` in both gradient signs; fixed-point stepping and later pair schedule unchanged | 60.901914 / 60.901634 / 60.901646 s; median 60.901646 s / 15.910900 FPS; framebuffer checksum `4154140932` on every run | Kept |
| Fused extra-style normalize (`R_BuildLightMap`) | Same one-pass invert/clamp for 2--4 styles when there are no dlights | 68.265121 s / 14.194657 FPS, 0.66 ms faster | Kept |
| Integer dlight inner loop (`R_AddDynamicLights`) | Integer distance + row pointer; `R_AddDynamicLights_C` kept | 68.209972 s / 14.206133 FPS, 55.1 ms faster | Kept |
| Face Z-gradient cache (`R_SetSurfaceZGradients`) | Reuse one plane's `d_zistep` while `modelorg` is stable; original math on miss | 68.198777 s / 14.208466 FPS, 11.2 ms faster | Kept |
| POT column wrap (`R_DrawSurface`) | AND wrap on power-of-two mip widths; compare/branch remains the non-POT path | 68.197221 s / 14.208790 FPS, 1.6 ms faster | Kept |
| Alias `AngleVectors` cache (`R_AliasSetUpTransform`) | 16-slot per-frame basis reuse; `AngleVectors` miss path | 68.212837 s / 14.205537 FPS, 15.6 ms slower | Reverted |
| Direct mip0 drawer (`R_DrawSurface`) | Direct `R_DrawSurfaceBlock8_mip0` in the POT column loop | 68.198298 s / 14.208566 FPS, 1.1 ms slower | Reverted |
| Z-span row table (`D_DrawZSpans`) | Use existing `zspantable` instead of IMUL `d_zrowbytes`; C multiply kept | 68.049361 s / 14.239663 FPS, 147.9 ms faster | Kept |
| Texture-span row table (`D_DrawSpans16`) | `viewspantable` dest rows instead of `d_scantable` plus `d_viewbuffer`; C multiply kept | 67.999624 s / 14.250078 FPS, 49.7 ms faster | Kept |
| Extra `viewspantable` dest sites | Same table in polyset, sprites, and particles | 67.990997 s / 14.251887 FPS, 8.6 ms faster | Kept |
| Sprite/particle Z row table | `zspantable` instead of IMUL `d_zrowbytes` in `d_spr8.s` / `d_parta.s` | 67.986326 s / 14.252866 FPS, 4.7 ms faster | Kept |
| Remainder t-zero cachewidth skip (`D_DrawSpans16`) | Skip remainder IMUL when integer t-step is 0 | 68.007120 s / 14.248508 FPS, 20.8 ms slower | Reverted |
| Texture-source row table (`cachespantable`) | Per-surface `cacheblock+t*cachewidth` table for span starts | 68.333304 s / 14.180494 FPS, 347 ms slower | Reverted |
| 2x surface cache (`SURFCACHE_SIZE_AT_320X200`) | 1200 KB instead of 600 KB | 67.415956 s / 14.373452 FPS, 570.4 ms faster | Ladder; 3x kept |
| 3x surface cache (`SURFCACHE_SIZE_AT_320X200`) | 1800 KB instead of 600 KB | 67.249168 s / 14.409100 FPS, 166.8 ms faster than 2x | Kept |
| Turbulent dest rows (`Turbulent8`) | `viewspantable[v] + u` instead of `screenwidth * v` | 67.247873 s / 14.409378 FPS, 1.3 ms faster | Kept |
| Static surface-cache hit path (`D_CacheSurface`) | Skip `R_TextureAnimation` and `r_drawsurf` stores on static hits | 67.229543 s / 14.413306 FPS, 18.3 ms faster | Kept |
| FinalVerts clip hoist (`D_PolysetDrawFinalVerts`) | Hoist `vrectright`/`vrectbottom` out of the vertex loop | 67.218606 s / 14.415652 FPS, 10.9 ms faster | Kept |
| Unused extra-style skip (`D_CacheSurface`) | Skip lightadj[1-3] compares when `styles[1]==255` | 67.200437 s / 14.419549 FPS, 18.2 ms faster | Kept |
| Alias raster dest/Z tables (`D_RasterizeAliasPolySmooth`) | `viewspantable`/`zspantable` instead of `ystart` IMUL | 67.185736 s / 14.422704 FPS, 14.7 ms faster | Kept |
| Face edge setup (`R_RenderFace`) | Hoist `surfedges + firstedge`; unroll 4 clip-plane links | 67.097222 s / 14.441731 FPS, 88.5 ms faster | Kept |
| Bmodel clip unroll (`R_RenderBmodelFace`) | Same 4 clip-plane links as world faces | 67.097295 s / 14.441715 FPS, 0.07 ms, overlapping ranges | Reverted |
| Bmodel surfedges hoist (`R_DrawSolidClippedSubmodelPolygons`) | `pmodel->surfedges + firstedge` like world faces | 67.096341 s / 14.441920 FPS, 0.88 ms faster | Kept |
| Surface draw 8-bit setup (`R_DrawSurface`) | Skip `r_pixbytes` 16-bit path; reuse `r_stepback` for `r_sourcemax` | 67.093880 s / 14.442450 FPS, 2.46 ms faster | Kept |
| Mipscale step tables (`D_CalcGradients`) | Precompute `xscaleinv`/`yscaleinv`/`0x10000` × mip once per frame | 67.091882 s / 14.442880 FPS, 2.0 ms faster | Kept |
| Unused surfscale FDIV (`D_CacheSurface`) | Skip `1.0/(1<<mip)` and unread `cache->mipscale` store | 67.085585 s / 14.444235 FPS, 6.3 ms faster | Kept |
| Skip live `blocksize` (`R_DrawSurface`) | Stop storing 16-bit block globals; dest used local step only | checksum `2281919689` | Reverted |
| `R_DrawSurface` surfmip hoist | Local `mip` for rebuild setup shifts | 67.085593 s / 14.444234 FPS, noise | Reverted |
| Mip-scaled modelorg (`D_CalcGradients`) | Precompute `transformed_modelorg × mip` on world/bmodel switch | 67.096034 s / 14.441986 FPS, 4.2 ms slower | Reverted |
| DrawSurfaces Restore/Set CALL skip | Skip no-op `D_RestoreWorldDrawingState` / same-entity `D_SetBmodelDrawingState` | 67.093276 s / 14.442580 FPS, 1.4 ms slower | Reverted |
| Direct `D_DrawSpans16` | Compare `d_drawspans` and call 16-pixel drawer directly | 67.101141 s / 14.440887 FPS, 9.3 ms slower | Reverted |
| World `r_drawpolys` hoist | Duplicate surface loops so span path skips poly dispatch | hitch min 1.89 FPS | Reverted |
| Alias `skintable` start addr | Always `D_PolysetUpdateTables`; row lookup instead of `t*skinwidth` | 67.270496 s / 14.404533 FPS, 178.6 ms slower | Reverted |
| Face vert-base hoist (`R_RenderFace`) | Local `r_pcurrentvertbase` for `R_ClipEdge` | 67.123877 s / 14.435996 FPS, 32.0 ms slower | Reverted |
| Fused smax POT wrap (`R_DrawSurface`) | One POT test for soffset wrap and column loop | hitch min 1.91 FPS | Reverted |
| Face model hoist (`R_RenderFace`) | Local `currententity->model` for edges/surfedges | 67.093926 s / 14.442440 FPS, 0.05 ms, run-1 outlier | Reverted |
| AnimateLight length-1 skip (`R_AnimateLight`) | Skip `i % len` when `len==1` | 67.095987 s / 14.441996 FPS, 2.1 ms slower | Reverted |
| Gradient step cache (`D_CalcGradients`) | Reuse s/t step-origin while texinfo/mip/modelorg match | 67.220030 s / 14.415346 FPS, 34.3 ms slower | Reverted |
| Unclipped alias `movzbl` expand (`r_aliasa.s`) | Full-dword vertex expand like the clipped helper | 67.200278 s / 14.419583 FPS, 0.16 ms, overlapping ranges | Reverted |
| Inlined fused frustum (`R_RecursiveWorldNode`) | Multiply `minmaxs` into the plane; no `rejectpt` stores | 67.200552 s / 14.419524 FPS, hitch min 1.87 FPS | Reverted |
| FinalVerts colormap hoist (`D_PolysetDrawFinalVerts`) | Stack-cache `acolormap` next to clip edges | 67.200621 s / 14.419510 FPS, 0.18 ms slower | Reverted |
| Turbulent last-segment divisor switch | Constant `/1`..`/15` so GCC emits IMUL magic | 67.275508 s / 14.403459 FPS, 27.6 ms slower | Reverted |
| Alias POT skinwidth shift (`D_PolysetCalcGradients`) | `shll %cl` when skinwidth is POT, IMUL fallback | 67.260820 s / 14.406604 FPS, 11.7 ms slower | Reverted |
| PreparePoints clip hoist (`R_AliasPreparePoints`) | Locals for `aliasvrect` clip edges | 67.234277 s / 14.412292 FPS, 15.7 ms slower | Reverted |
| 1900 KB surface cache | between 1800 and 2100 | checksum `2955717646` | Reverted — **superseded 2026-09-29, the checksum was a confounded build; 1900 KB is correct and faster** |
| 2000 KB surface cache | between 1800 and 2100 | checksum `2955717646` | Reverted — **superseded 2026-09-29, as above** |
| 2100 KB surface cache | between 1800 and 2400 | checksum `2955717646`; run 1 hitch min 1.72 FPS | Reverted — **superseded 2026-09-29, as above** |
| 4x surface cache (`SURFCACHE_SIZE_AT_320X200`) | 2400 KB | checksum `2955717646` | Reverted — **superseded 2026-09-29; 2400 KB is now the default, 0.0635% faster at checksum `1047377823`** |
| Aggressive `-funroll-loops` (`build-dos.ps1`) | Faster but wrong FB | 66.801015 s / 14.505767 FPS; checksum `2623602099` | Reverted |
| MarkLights plane cull (`R_MarkLights`) | Same reject as `R_AddDynamicLights` | 66.776824 s / 14.511022 FPS, 185.8 ms faster | Kept |
| MarkLights S/T extent cull (`R_MarkLights`) | AABB expand by `fmin` after plane reject | 64.253958 s / 15.080783 FPS, 2522.9 ms faster | Kept |
| MarkLights idist cull (`R_MarkLights`) | Clamp-to-rect idist replaces AABB expand | 64.128594 s / 15.110264 FPS, 125.4 ms faster | Kept |
| MarkLights 2x2 sample cull (`R_MarkLights`) | Exact 2x2 discrete idist vs continuous clamp | 64.241100 s / 15.083802 FPS, 112.5 ms slower | Reverted |
| Dlight sample window (`R_AddDynamicLights`) | Clamp s/t loops to idist-feasible indices | run 2 checksum `696680082` | Reverted |
| Sticky dlight cache flag (`D_CacheSurface`) | `cache->dlight` only if a sample was lit | 64.113828 s / 15.113744 FPS, 14.8 ms faster | Kept |
| Alias adivtab 32→64 (`D_PolysetSetUpForLineScan`) | Wider table hit, same FloorDivMod values | 64.104105 s / 15.116037 FPS, 9.7 ms faster | Kept |
| Phantom-mark dlight probe (`D_CacheSurface`) | `R_DlightContributes` skip on marked clean cache | 64.092171 s / 15.118851 FPS, 11.9 ms faster | Kept |
| Alias clip hoist + skip Z reflag (`R_AliasClip`) | Hoist vrect; Z writes final flags | 64.134559 s / 15.108859 FPS, 42.4 ms slower | Reverted |
| Polyset span advancetable hoist (`D_PolysetDrawSpans8`) | Once-per-call `advancetable`/`tstep` | 64.003272 s / 15.139851 FPS, 88.9 ms faster | Kept |
| Polyset sstep hoist (`D_PolysetDrawSpans8`) | BSS `sstep` for `a_sstepxfrac` in pixel loop | 64.012388 s / 15.137695 FPS, 9.1 ms slower | Reverted |
| Polyset Bresenham const hoist (`D_PolysetDrawSpans8`) | Local copies of erroradjust*/ubasestep/countextra | 64.039951 s / 15.131180 FPS, 36.7 ms slower | Reverted |
| Left-edge s/t step CSE (`D_RasterizeAliasPolySmooth`) | Reuse base products for extra steps | 63.984395 s / 15.144318 FPS, 18.9 ms faster | Kept |
| Left-edge ptexextrastep via `a_ststepxwhole` | Carry-adjust + branch instead of skinwidth IMUL | 64.060863 s / 15.126241 FPS, 76.5 ms slower | Reverted |
| Z-span list cursor in `%ebp` (`D_DrawZSpans`) | Drop per-span push/pop of span pointer | 63.895076 s / 15.165488 FPS, 89.3 ms faster | Kept |
| Z-span odd-pixel tag in `%ebp` bit0 (`D_DrawZSpans`) | Drop count push/pop via pointer tag | 63.959669 s / 15.150173 FPS, 64.6 ms slower | Reverted |
| ScanLeftEdge skinwidth stack hoist (`D_PolysetScanLeftEdge`) | Push skinwidth once; `addl (%esp)` on tfrac carry | 63.905049 s / 15.163121 FPS, 10.0 ms slower | Reverted |
| ScanLeftEdge package cursor in `%esi` (`D_PolysetScanLeftEdge`) | Keep `d_pedgespanpackage` live; publish once on exit | 63.783005 s / 15.192135 FPS, 112.1 ms faster | Kept |
| DrawSpans8 stack-live aspancount/errorterm (`D_PolysetDrawSpans8`) | Stack copies for outer right-edge loop | 63.819708 s / 15.183397 FPS, 36.7 ms slower | Reverted |
| ScanLeftEdge pdest/pz cursors (`D_PolysetScanLeftEdge`) | `%edi`/`%ebp` live; light/zi on stack | 63.741911 s / 15.201929 FPS, 41.1 ms faster | Kept |
| ScanLeftEdge aspancount stack (`D_PolysetScanLeftEdge`) | Spill `d_aspancount` beside light/zi; write back once | 63.726061 s / 15.205710 FPS, 15.7 ms faster | Kept |
| Sky `viewspantable` dest (`D_DrawSkyScans8`) | Same table as texture spans | Noise vs aspancount default (~0.01 ms) | Reverted |
| Span16 s/t integer CSE (`d_draw16.s`) | Keep clamped s/t in regs across sfrac/tfrac shifts | 63.784645 s / 15.191744 FPS, ~43 ms slower | Reverted |
| Span16 early `pnext` preload (`d_draw16.s`) | Store next span in `pspantemp` during FDIV setup | Noise / slight loss vs aspancount default | Reverted |
| ScanLeftEdge erroradjust stack (`D_PolysetScanLeftEdge`) | Spill `erroradjustup`/`down` beside aspancount | Hitch min 1.93 FPS; ~13 ms slower median | Reverted |
| ScanLeftEdge errorterm stack (`D_PolysetScanLeftEdge`) | Spill `errorterm` beside aspancount | ~13 ms slower than aspancount-only | Reverted |
| Turbulent sstep/tstep/pbase stack hoist (`D_DrawTurbulent8Span_asm486`) | Snapshot three span-invariant globals once | 63.743347 s / 15.201586 FPS, ~17 ms slower | Reverted |
| Edge-scan surfaces CSE (`R_GenerateSpans` / `Lgs_leading`) | Drop dead `movl C(surfaces),%eax` before leading add | 63.652849 s / 15.223200 FPS, 73.2 ms faster | Kept |
| Edge-scan both-edges leading precompute (`R_GenerateSpans`) | Finish leading surf* before `TrailingEdge`; drop post-call reload | 63.654537 s / 15.222796 FPS, ~1.7 ms slower | Reverted |
| Edge-scan dead `st_key` reload (`Lnewtop_fpop2`) | Remove load overwritten by `Lnewtop` | 63.652266 s / 15.223339 FPS, 0.58 ms faster | Kept |
| TrailingEdge `st_next` CSE (`TrailingEdge`) | Reuse `%ecx` instead of reloading `st_next` | ~63.652240 s, ~0.03 ms (noise) | Reverted |
| DrawSpans8 aspancount register CSE (`D_PolysetDrawSpans8`) | Keep original aspancount in `%ebp` for += | ~63.652379 s, ~0.11 ms slower | Reverted |
| ScanLeftEdge pretouch removal (`D_PolysetScanLeftEdge`) | Drop discarded `movb` cache pretouch | 63.623244 s / 15.230283 FPS, 29.0 ms faster | Kept |
| EmitEdge pretouch removal (`R_EmitEdge`) | Drop discarded next-edge `movl (%edx),%eax` on both sides | 63.614724 s / 15.232323 FPS, 8.5 ms faster | Kept |
| TrailingEdge unlink via live `%ecx` (`TrailingEdge`) | Use preloaded `st_next` directly on emit/LNoEmit2; no reload or `movl %ecx,%edx` | 63.583628 s / 15.239772 FPS, 31.1 ms faster | Kept |
| EmitEdge single `r_pedge` load (`R_EmitEdge`) | Drop preload into `%esi`; load once after horizontal early-out for `et_owner` | 63.573196 s / 15.242273 FPS, 10.4 ms faster | Kept |
| TrailingEdge skip `r_bmodelactive` RMW (`TrailingEdge`) | Skip load/sub/store when `insubmodel==0` | 63.523798 s / 15.254125 FPS, 49.4 ms faster | Kept |
| Bmodel `incl`/`decl` `r_bmodelactive` (`TrailingEdge` / `Lbmodel_leading`) | Memory inc/dec instead of load/add/store; world skip kept | 63.500960 s / 15.259612 FPS, 22.8 ms faster | Kept |
| EmitEdge drop unused clipped `r_pedge` load (`R_EmitEdge`) | Fully-clipped path wrote only `cacheoffset`; `%ecx` load was dead | 63.488089 s / 15.262705 FPS, 12.9 ms faster | Kept |
| TrailingEdge memory `decl` spanstate (`TrailingEdge`) | `--surf->spanstate` via `decl mem`; drop inverted-path store | 63.355125 s / 15.294737 FPS, 133.0 ms faster | Kept |
| Leading spanstate `movl $1` (`Lgs_leading` / `Lbmodel_leading`) | Known-zero fall-through stores 1; skip `incl`/%edx | 63.281476 s / 15.312538 FPS, 73.6 ms faster | Kept |
| EmitEdge defer `edge_p` past horizontal early-out (`R_EmitEdge`) | Load `edge_p`+`leal` next only when emitting; CF preserved | 63.267301 s / 15.315969 FPS, 14.2 ms faster | Kept |
| RecursiveTriangle live new[0]/new[1] (`D_PolysetRecursiveTriangle`) | Reuse Z-setup `%ecx`/`%ebp`; `movzbl` colormap; drop stack reloads | 63.265453 s / 15.316416 FPS, 1.8 ms faster | Kept |
| Aff8 pixel `movzbl` colormap index (`D_PolysetDrawSpans8`) | Replace `xorl`+`movb` with `movzbl` in LDraw8–1 / one-long | 63.179599 s / 15.337229 FPS, 85.9 ms faster | Kept |
| FinalVerts `movzbl` skin texel (`D_PolysetDrawFinalVerts`) | Drop `movb`+`andl $0x00FF`; zero-extend into colormap add | 63.178180 s / 15.337574 FPS, 1.4 ms faster | Kept |
| DrawSubdiv defer `d_pcolormap` past cull (`D_DrawSubdiv`) | Set colormap only when triangle will draw; match C order | 63.145837 s / 15.345430 FPS, 32.3 ms faster | Kept |
| Aff8 one-long defer `ptex` past Z (`LExactlyOneLong`) | Skip skin load on occluded one-pixel Aff8 spans | 63.143310 s / 15.346044 FPS, 2.5 ms faster | Kept |
| RecursiveTriangle defer `lp2[0]` (`D_PolysetRecursiveTriangle`) | Load `lp2[0]` only on equal-`y` nodraw test; flags preserved | 63.141084 s / 15.346585 FPS, 2.2 ms faster | Kept |
| RecursiveTriangle defer split-path prefetches (`D_PolysetRecursiveTriangle`) | Load next-edge `lp3[0]`/`lp1[0]` only after `|dy|` fails to split | 63.139434 s / 15.346986 FPS, 1.7 ms faster | Kept |
| RecursiveTriangle defer `|dy|` y-loads past `|dx|` (`D_PolysetRecursiveTriangle`) | Skip same-edge y loads on `|dx|` early-out; fix `LSplit3` rotate | 63.121804 s / 15.351272 FPS, 17.6 ms faster | Kept |
| StepActiveU defer `et_prev`/`et_next` past aftertail (`R_StepActiveU`) | Match C: early-out before unlink loads on every scanline finish | 63.112658 s / 15.353497 FPS, 9.1 ms faster | Kept |
| InsertNewEdges defer `et_next` past `et_u` (probes 1–3) (`R_InsertNewEdges`) | Skip next-edge load on taken early-out; keep probe-4 `jg` fallthrough | 63.105267 s / 15.355295 FPS, 7.4 ms faster | Kept |
| StepActiveU defer `et_prev` past first `et_u` (`LPushBackLoop`) | Skip prev load on taken pushback early-out; probe 2 unchanged | 63.103178 s / 15.355803 FPS, 2.1 ms faster | Kept |
| EmitEdge defer `r_framecount` past cacheoffset EO (`LPop5AndDone`) | Match C: load framecount only when tagging fully-clipped cache | 63.102686 s / 15.355923 FPS, 0.5 ms faster | Kept |
| StepActiveU defer step-loop `et_next` past order EO (`R_StepActiveU`) | Probes 1–3; load continuation only after aftertail; drop dup unlink load | 63.091427 s / 15.358664 FPS, 11.3 ms faster | Kept |
| RemoveEdges both-stores-then-advance (`R_RemoveEdges`) | Match C unlink; drop `%ebx` push/pop and odd-tail `Lre_done` store | 63.087263 s / 15.359677 FPS, 4.2 ms faster | Kept |
| FinalVerts Aff8-style light<<8 colormap index (`D_PolysetDrawFinalVerts`) | `movb` high byte of `v[4]` into `%dh`; drop dword/`andl`/`addl` | 63.084374 s / 15.360381 FPS, 2.9 ms faster | Kept |
| Leading memory `cmpl` first `st_key` (`Lgs_leading` / `Lbmodel_leading`) | Drop `surf2->key` preload; dead on newtop / 1/z-check | 63.012013 s / 15.378020 FPS, 72.4 ms faster | Kept |
| RecursiveTriangle keep live new[0]/new[1] into LDraw (`D_PolysetRecursiveTriangle`) | Equal-y uses `%eax` for `lp2[0]`; skip stack reloads at draw entry | 63.006559 s / 15.379351 FPS, 5.5 ms faster | Kept |
| Leading sort-loop memory `cmpl` `st_key` (`Lsortloopnb` / `Lsortloop`) | Drop per-probe key preload; same pattern as first-key keep | 62.953783 s / 15.392244 FPS, 52.8 ms faster | Kept |
| Aff8 multi skip dead last-group stepper (`Lp8`) | `decw`/`jz` before s/t/z/ptex advance on final group | 62.830543 s / 15.422436 FPS, 123.2 ms faster | Kept |
| InsertNewEdges memory `cmpl et_u` (`R_InsertNewEdges`) | Drop `%ebx` key preload per probe; keep probe-4 `jg` fallthrough | 62.787258 s / 15.433068 FPS, 43.3 ms faster | Kept |
| StepActiveU `LPushBackLoop` memory `cmpl et_u` (`R_StepActiveU`) | Drop `%ebx` key preload on pushback walk probes | 62.783533 s / 15.433983 FPS, 3.7 ms faster | Kept |
| TrailingEdge memory `cmpl st_last_u` (`TrailingEdge`) | Load `last_u` into `%edx` only on emit; dead on `LNoEmit2` | 62.782647 s / 15.434201 FPS, 0.9 ms faster | Kept |
| ScanLeftEdge skip dead last-row Bresenham (`D_PolysetScanLeftEdge`) | `decl`/`jz` before step after last package; shared epilogue | 62.753905 s / 15.441270 FPS, 28.7 ms faster | Kept |
| StepActiveU memory `addl et_u_step` (`R_StepActiveU`) | Drop `%ebx` u_step preload on all four step probes | 62.649598 s / 15.466979 FPS, 104.3 ms faster | Kept |
| Leading `Lnewtop` memory `cmpl st_last_u` (`R_GenerateSpans`) | Load `last_u` into `%edx` only on emit; same as TrailingEdge | 62.623729 s / 15.473368 FPS, 25.9 ms faster | Kept |
| EmitEdge defer `r_ceilv1` past horizontal EO (`R_EmitEdge`) | Memory `cmpl`; load `%ecx` only when emitting; CF kept for side | 62.621766 s / 15.473853 FPS, 2.0 ms faster | Kept |
| RecursiveTriangle memory `addl` s/t/zi midpoints (`D_PolysetRecursiveTriangle`) | Drop lp2 preloads for new[2]/[3]/[5]; keep lp1 x/y live for nodraw | 62.605144 s / 15.477961 FPS, 16.6 ms faster | Kept |
| EmitEdge memory `cmpl` u-clamp (`R_EmitEdge`) | Load vrect clamp bounds into `%edx` only when clamping | 62.588326 s / 15.482121 FPS, 16.8 ms faster | Kept |
| EmitEdge memory `subl surfaces` (`R_EmitEdge`) | Drop `surfaces` preload into `%esi`; set sort side from `%edx`/immediate | 62.580291 s / 15.484108 FPS, 8.0 ms faster | Kept |

The last accepted clipped-transform comparison used three runs per variant:

```text
C:   69.063022 / 69.062948 / 69.062989 s, median 69.062989 s, 14.030670 FPS
ASM: 68.958781 / 68.958804 / 68.958785 s, median 68.958785 s, 14.051872 FPS
```

The gain is 104.204 ms per timedemo.  Disassembly showed the useful 486-level
difference: the C helper reloads packed vertex bytes through compiler-generated
temporaries for each dot product, while ASM expands them once into scratch
storage and reuses them with x87 arithmetic.  The call boundary is shared.
The helper is intentionally small; it does not rewrite the larger alias path.

## Current baseline and evidence

- Historical pre-experiment reference: 69.234885 s / 13.995834 FPS median.
- Pre-change lock on this pass (`out\dos-timedemo-20260910-221227`):
  `68.958977 / 68.958817 / 68.958799` s, median **68.958817 s / 14.051865 FPS**,
  969 frames, checksum `4154140932`.  Alias-transform focused bench PASS
  (`out\dos-bench-20260910-221009`).  One instrumented profile
  (`out\dos-timedemo-20260910-222107`) ranked self time as texture spans
  25.67%, surface cache 14.55%, alias model 12.83%, Z spans 10.87%, world BSP
  10.83%, edge-scan self 8.83%.  Full-16 `tzero` segments were 1,026,030;
  `tfrac-zero` was 28, so a pure horizontal inner loop is not the common case.
- Current `-O2` after inlined surface/alias setup
  (`out\dos-timedemo-20260910-224722`): `68.946589 / 68.946370 / 68.946351` s,
  median **68.946370 s / 14.054401 FPS**.  Gain is 12.447 ms (0.018%) with the
  same 969-frame checksum.  Kept as `-OptimizationProfile baseline`.
- Previous `-O3` default after the texinfo UB fix and passing `+quit` smoke
  (`out\dos-timedemo-20260910-232607`): `68.421643 / 68.421316 / 68.421397` s,
  median **68.421397 s / 14.162237 FPS**.
- Previous default after the bmodel span-rotation cache
  (`out\dos-timedemo-20260910-233942`): `68.379915 / 68.379696 / 68.379627` s,
  median **68.379696 s / 14.170874 FPS**, checksum `4154140932`.  About
  41.7 ms faster than the previous `-O3` default.  `R_RotateBmodel` still
  rebuilds the matrix; span drawing uses `R_RotateBmodelCached` plus
  consecutive-entity skip.
- Previous default after fusing ambient into the first lightmap style
  (`out\dos-timedemo-20260910-234742`): `68.309988 / 68.309789 / 68.309838` s,
  median **68.309838 s / 14.185365 FPS**, checksum `4154140932`.  About
  69.9 ms faster than the bmodel-cache default.
- Previous default after fusing invert/clamp into the one-style write
  (`out\dos-timedemo-20260911-051131`): `68.265960 / 68.265718 / 68.265779` s,
  median **68.265779 s / 14.194521 FPS**, checksum `4154140932`.  About
  44.1 ms faster than the fused first-style write.
- Previous default after fusing invert/clamp for extra styles as well
  (`out\dos-timedemo-20260911-051834`): `68.265281 / 68.265038 / 68.265121` s,
  median **68.265121 s / 14.194657 FPS**, checksum `4154140932`.  About
  0.66 ms faster than one-style-only fusion; every extra-style run was
  faster than every one-style-only run.
- Previous default after the integer dlight inner loop
  (`out\dos-timedemo-20260911-052933`): `68.210077 / 68.209972 / 68.209845` s,
  median **68.209972 s / 14.206133 FPS**, checksum `4154140932`.  About
  55.1 ms faster than extra-style fusion.  Worst-frame FPS rose from
  6.279967 to 6.299928; low-1% from 6.802995 to 6.837195.  Dlights still
  feed the two-pass accumulate-then-normalize path.
- Previous default after the face Z-gradient cache
  (`out\dos-timedemo-20260911-053759`): `68.198978 / 68.198777 / 68.198746` s,
  median **68.198777 s / 14.208466 FPS**, checksum `4154140932`.  About
  11.2 ms faster than the integer-dlight default; every run was faster than
  every previous-default run.  `out\dos-timedemo-20260911-050318` was a
  stale-`qbench` rerun and is not evidence for this change.
- Previous default after power-of-two column wrap in `R_DrawSurface`
  (`out\dos-timedemo-20260911-054347`): `68.197434 / 68.197202 / 68.197221` s,
  median **68.197221 s / 14.208790 FPS**, checksum `4154140932`.  About
  1.6 ms faster than the Z-gradient cache; every run was faster than every
  Z-cache run.
- Previous default after `D_DrawZSpans` used `zspantable`
  (`out\dos-timedemo-20260911-062059`): `68.049783 / 68.049361 / 68.049299` s,
  median **68.049361 s / 14.239663 FPS**, checksum `4154140932`.  About
  147.9 ms faster than the POT-wrap default.  Worst-frame FPS rose from
  6.300360 to 6.311090.  C `D_DrawZSpans` still multiplies `d_zwidth`.
- Previous default after texture-span `viewspantable` dest addressing
  (`out\dos-timedemo-20260911-063418`): `67.999833 / 67.999624 / 67.999594` s,
  median **67.999624 s / 14.250078 FPS**, checksum `4154140932`.  About
  49.7 ms faster than the Z-span-table default.  Worst-frame FPS rose from
  6.311090 to 6.316737.  C `D_DrawSpans8` still multiplies `screenwidth`.
- Previous default after polyset/sprite/particle `viewspantable` dest
  addressing (`out\dos-timedemo-20260911-064221`):
  `67.991123 / 67.990960 / 67.990997` s, median
  **67.990997 s / 14.251887 FPS**, checksum `4154140932`.  About 8.6 ms
  faster than texture-span-only `viewspantable`.  Worst-frame FPS rose from
  6.316737 to 6.318577.
- Previous default after sprite/particle `zspantable` Z addressing
  (`out\dos-timedemo-20260911-065037`): `67.986523 / 67.986326 / 67.986315` s,
  median **67.986326 s / 14.252866 FPS**, checksum `4154140932`.  About
  4.7 ms faster than extra-`viewspantable`.  Worst-frame FPS rose from
  6.318577 to 6.320384.
- Previous default after 2x surface cache (1200 KB)
  (`out\dos-timedemo-20260911-133815`): `67.416141 / 67.415956 / 67.415942` s,
  median **67.415956 s / 14.373452 FPS**, checksum `4154140932`.  About
  570.4 ms faster than the 600 KB default.
- Previous default after 3x surface cache (1800 KB)
  (`out\dos-timedemo-20260911-134300`): `67.249266 / 67.249142 / 67.249168` s,
  median **67.249168 s / 14.409100 FPS**, checksum `4154140932`.  About
  166.8 ms faster than 2x.  1900 KB, 2000 KB, 2100 KB, and 2400 KB
  were all faster but checksum `2955717646` (same hash as the
  reverted texture-source row-lookup).  **Do not grow the cache past
  1800 KB without a new checksum-identical size. — SUPERSEDED
  2026-09-29: this was a confounded build, not a cache-size defect.
  2400 KB is now the default at checksum `1047377823`, 0.0635%
  faster; see "The 1800 KB surface-cache wall does not exist".**
- Previous default after `Turbulent8` `viewspantable` dest rows
  (`out\dos-timedemo-20260911-143822`): `67.248071 / 67.247843 / 67.247873` s,
  median **67.247873 s / 14.409378 FPS**, checksum `4154140932`.  About
  1.3 ms faster than the 1800 KB default.  Worst-frame min FPS is
  6.320384.
- Previous default after the static surface-cache hit path
  (`out\dos-timedemo-20260911-152128`): `67.229687 / 67.229543 / 67.229518` s,
  median **67.229543 s / 14.413306 FPS**, checksum `4154140932`.  About
  18.3 ms faster than the `Turbulent8` dest-row default.  Worst-frame
  min FPS rose from 6.320384 to 6.321120.  Every run was faster than
  every previous-default run.
- Previous default after the FinalVerts clip-rect hoist
  (`out\dos-timedemo-20260911-152839`): `67.218821 / 67.218606 / 67.218548` s,
  median **67.218606 s / 14.415652 FPS**, checksum `4154140932`.  About
  10.9 ms faster than the static cache-hit default.  Worst-frame min
  FPS rose from 6.321120 to 6.321254.  Every run was faster than every
  previous-default run.
- Previous default after skipping unused extra light styles
  (`out\dos-timedemo-20260911-154031`): `67.200635 / 67.200347 / 67.200437` s,
  median **67.200437 s / 14.419549 FPS**, checksum `4154140932`.  About
  18.2 ms faster than the FinalVerts hoist.  Worst-frame min FPS is
  6.321254.  Every run was faster than every previous-default run.
- Previous default after alias raster dest/Z row tables
  (`out\dos-timedemo-20260911-161154`): `67.185888 / 67.185693 / 67.185736` s,
  median **67.185736 s / 14.422704 FPS**, checksum `4154140932`.  About
  14.7 ms faster than the extra-style skip.  Worst-frame min FPS rose
  from 6.321254 to 6.322259.  Every run was faster than every
  previous-default run.
- Previous default after `R_RenderFace` surfedges hoist and clip unroll
  (`out\dos-timedemo-20260911-173034`): `67.097430 / 67.097210 / 67.097222` s,
  median **67.097222 s / 14.441731 FPS**, checksum `4154140932`.  About
  88.5 ms faster than the alias raster dest/Z default.  Worst-frame min
  FPS rose from 6.322259 to 6.325209.  Every run was faster than every
  previous-default run.
- Previous default after the clipped-bmodel surfedges hoist
  (`out\dos-timedemo-20260911-174206`): `67.096456 / 67.096339 / 67.096341` s,
  median **67.096341 s / 14.441920 FPS**, checksum `4154140932`.  About
  0.88 ms faster than the `R_RenderFace` default.  Worst-frame min FPS
  rose from 6.325209 to 6.325275.  Every run was faster than every
  previous-default run.
- Previous default after `R_DrawSurface` 8-bit setup
  (`out\dos-timedemo-20260911-174904`): `67.093796 / 67.093948 / 67.093880` s,
  median **67.093880 s / 14.442450 FPS**, checksum `4154140932`.  About
  2.46 ms faster than the clipped-bmodel hoist.  Worst-frame min FPS
  rose from 6.325275 to 6.325880.  Every run was faster than every
  previous-default run.
- Previous default after mipscale step tables
  (`out\dos-timedemo-20260911-182120`): `67.091435 / 67.091882 / 67.091930` s,
  median **67.091882 s / 14.442880 FPS**, checksum `4154140932`.  About
  2.0 ms faster than the 8-bit surface-setup default.  Worst-frame min
  FPS rose from 6.325880 to 6.325980.  Every run was faster than every
  previous-default run.
- Previous default after skipping the unused `surfscale` FDIV
  (`out\dos-timedemo-20260911-191612`): `67.085825 / 67.085569 / 67.085585` s,
  median **67.085585 s / 14.444235 FPS**, checksum `4154140932`.  About
  6.3 ms faster than the mipscale-table default.  Worst-frame min FPS
  rose from 6.325980 to 6.326751.  Every run was faster than every
  previous-default run.
- Previous default through commit `f6ea9c6` (`out\dos-timedemo-20260914-121838`):
  `66.962797 / 66.962567 / 66.962657` s, median
  **66.962567 s / 14.470771 FPS**, checksum `4154140932` on all three runs.
  About 123 ms (0.18%) faster than the pre-unroll default above.  Eight
  further commits landed after this doc's 67.085585 s snapshot: solid-surface
  `viewspantable` spans (`e869b7d`), integer dlight contribution and test
  (`03bb815`, `06ab02b`), 4x fused lightmap loops (`41757fc`), hoisted
  `R_DrawSurface` mip dispatch (`53a7d7f`), lightstyle counter + `rep` tails +
  16B align (`41aa622`, `3cc85f5`), and `R_RenderFace` / `R_BuildLightMap`
  unrolling (`33c0ebf`, `f6ea9c6`).
  Matching instrumented diagnostic (`out\dos-timedemo-20260914-122314`,
  12.950385 FPS) ranks self time as texture spans 26.24%, surface cache
  13.56%, alias model 13.16%, Z spans 10.98%, world BSP 10.48%, edge-scan
  self 9.07%, surfaces self 5.50%, turbulent 2.57%.  Of 3,513,435 full
  16-pixel texture segments, 1,027,061 (29.2%) have a zero integer t-step;
  `full-tdelta-zero` is only 28, so the fractional t accumulator still
  carries.
- Previous default re-lock without `-funroll-loops`
  (`out\dos-timedemo-20260914-134340`): `66.962837 / 66.962633 / 66.962597` s,
  median **66.962633 s / 14.470758 FPS**, checksum `4154140932` on all three
  runs.  Matches the `f6ea9c6` reference within run noise.
- Previous default after `R_MarkLights` plane cull
  (`out\dos-timedemo-20260914-140045`): `66.776961 / 66.776735 / 66.776824` s,
  median **66.776824 s / 14.511022 FPS**, checksum `4154140932` on all three
  runs.  About 185.8 ms faster than the re-lock; every run was faster than
  every re-lock run.  Faces that cannot receive a dlight sample are no
  longer marked, so `D_CacheSurface` keeps hits instead of rebuilding with
  an empty dlight pass.
- Previous default after `R_MarkLights` S/T extent cull
  (`out\dos-timedemo-20260914-142303`): `64.253958 / 64.253841 / 65.839411` s,
  median **64.253958 s / 15.080783 FPS**, checksum `4154140932` on all three
  runs.  About 2522.9 ms faster than the plane-cull default; every run was
  faster than the plane-cull median.  Run 3 was slower than runs 1/2 but
  still clear of the prior median.  Projected impact outside the lightmap
  rect expanded by `fmin` is no longer marked.
- Previous default after `R_MarkLights` clamp-to-rect idist cull
  (`out\dos-timedemo-20260914-143404`): `64.128632 / 64.128594 / 64.128523` s,
  median **64.128594 s / 15.110264 FPS**, checksum `4154140932` on all three
  runs.  About 125.4 ms faster than the AABB-expand default; every run was
  faster than every AABB-expand run.  Uses the same integer idist metric as
  `R_AddDynamicLights` against the clamped lightmap rect.
- Previous default after sticky `cache->dlight` flag
  (`out\dos-timedemo-20260914-163457`): `64.114027 / 64.113796 / 64.113828` s,
  median **64.113828 s / 15.113744 FPS**, checksum `4154140932` on all three
  runs.  About 14.8 ms faster than the idist-cull default; every run was
  faster than the idist-cull median.  `D_CacheSurface` sets `cache->dlight`
  from `r_dlight_contributed` after `R_DrawSurface`.
- Previous default after alias `adivtab` 32→64
  (`out\dos-timedemo-20260914-164951`): `64.104105 / 64.103726 / 64.569991` s,
  median **64.104105 s / 15.116037 FPS**, checksum `4154140932` on all three
  runs.  About 9.7 ms faster than the sticky-dlight default.  Run 3 was
  slower than the prior median; runs 1/2 were faster.  `D_PolysetSetUpForLineScan`
  tables `tm,tn` in `[-31,32]`.
- Previous default after phantom-mark dlight probe
  (`out\dos-timedemo-20260914-180707`): `64.092357 / 64.092171 / 64.092163` s,
  median **64.092171 s / 15.118851 FPS**, checksum `4154140932` on all three
  runs.  About 11.9 ms faster than the adivtab-64 default; every run was
  faster than the prior median.  `D_CacheSurface` calls `R_DlightContributes`
  when a clean cache is marked this frame and skips the rebuild on a miss.
- Previous default after polyset span advancetable hoist
  (`out\dos-timedemo-20260914-182901`): `64.003358 / 64.003148 / 64.003272` s,
  median **64.003272 s / 15.139851 FPS**, checksum `4154140932` on all three
  runs.  About 88.9 ms faster than the phantom-mark default; every run was
  faster than the prior median.  ASM `D_PolysetDrawSpans8` builds
  `advancetable`/`tstep` once per call.
- Previous default after left-edge s/t step CSE
  (`out\dos-timedemo-20260915-051520`): `63.984653 / 63.984268 / 63.984395` s,
  median **63.984395 s / 15.144318 FPS**, checksum `4154140932` on all three
  runs.  About 18.9 ms faster than the advancetable default; every run was
  faster than the prior median.  Confirms the earlier
  `out\dos-timedemo-20260915-051014` keep (that set had a run-2 hitch).
  `D_RasterizeAliasPolySmooth` reuses s/t base products for extra steps.
- Previous default after Z-span `%ebp` list cursor
  (`out\dos-timedemo-20260915-055029`): `63.895311 / 63.895076 / 63.895065` s,
  median **63.895076 s / 15.165488 FPS**, checksum `4154140932` on all three
  runs.  About 89.3 ms faster than the left-edge CSE default; every run was
  faster than the prior median.  ASM `D_DrawZSpans` keeps the span list in
  `%ebp` and drops the per-span push/pop.
- Previous default after ScanLeftEdge `%esi` package cursor
  (`out\dos-timedemo-20260915-064521`): `63.783098 / 63.783005 / 63.782908` s,
  median **63.783005 s / 15.192135 FPS**, checksum `4154140932` on all three
  runs.  About 112.1 ms faster than the Z-span default; every run was
  faster than the prior median.  ASM `D_PolysetScanLeftEdge` keeps
  `d_pedgespanpackage` in `%esi` for the whole scan and publishes once on
  both exit paths; `errorterm` / `d_aspancount` use `%eax`.
- Previous default after ScanLeftEdge pdest/pz cursors
  (`out\dos-timedemo-20260915-070155`): `63.741911 / 63.741666 / 63.742057` s,
  median **63.741911 s / 15.201929 FPS**, checksum `4154140932` on all three
  runs.  About 41.1 ms faster than the package-cursor default; every run was
  faster than the prior median.  `%edi`/`%ebp` hold live `d_pdest`/`d_pz`;
  light/zi sit on the stack for the scan.
- Re-lock before this pass (`out\dos-timedemo-20260915-073048`):
  `63.741869 / 63.741679 / 63.741717` s, median
  **63.741717 s / 15.201975 FPS**, checksum `4154140932` on all three runs.
  Matches the pdest/pz default within run noise.
- Current default after ScanLeftEdge aspancount stack spill
  (`out\dos-timedemo-20260915-080929`): `63.726312 / 63.726047 / 63.726061` s,
  median **63.726061 s / 15.205710 FPS**, checksum `4154140932` on all three
  runs.  About 15.7 ms faster than the re-lock; every run was faster than
  every re-lock run.  `d_aspancount` lives at `0(%esp)` beside light/zi;
  both exit paths write it back once.
- Current default after edge-scan `surfaces` CSE
  (`out\dos-timedemo-20260915-092321`): `63.652962 / 63.652822 / 63.652849` s,
  median **63.652849 s / 15.223200 FPS**, checksum `4154140932` on all three
  runs.  About 73.2 ms faster than the aspancount default; every run was
  faster than the prior median.  `Lgs_leading` reuses `%eax` already loaded
  with `surfaces` instead of reloading it.
- Current default after edge-scan dead `st_key` reload removal
  (`out\dos-timedemo-20260915-094804`): `63.652309 / 63.652161 / 63.652266` s,
  median **63.652266 s / 15.223339 FPS**, checksum `4154140932` on all three
  runs.  About 0.58 ms faster than the surfaces-CSE default; every run was
  faster than the prior median.  `Lnewtop_fpop2` no longer loads `st_key`
  into `%eax` before `Lnewtop` overwrites it.
- Current default after ScanLeftEdge pretouch removal
  (`out\dos-timedemo-20260915-101018`): `63.623427 / 63.623209 / 63.623244` s,
  median **63.623244 s / 15.230283 FPS**, checksum `4154140932` on all three
  runs.  About 29.0 ms faster than the st_key default; every run was faster
  than the prior median.  The discarded `movb spanpackage_t_size(%esi),%al`
  pretouch is gone; the next package write after `addl` still warms the line.
- Current default after EmitEdge pretouch removal
  (`out\dos-timedemo-20260915-102159`): `63.615049 / 63.614724 / 63.614690` s,
  median **63.614724 s / 15.232323 FPS**, checksum `4154140932` on all three
  runs.  About 8.5 ms faster than the ScanLeftEdge-pretouch default; every
  run was faster than the prior median.  Both leading/trailing
  `movl (%edx),%eax` next-edge pretouches in `R_EmitEdge` are gone.
- Current default after TrailingEdge unlink via live `%ecx`
  (`out\dos-timedemo-20260915-103948`): `63.583853 / 63.583607 / 63.583628` s,
  median **63.583628 s / 15.239772 FPS**, checksum `4154140932` on all three
  runs.  About 31.1 ms faster than the EmitEdge-pretouch default; every run
  was faster than every prior-default run.  Emit and `LNoEmit2` unlink with
  the already-loaded `st_next` in `%ecx` instead of reloading into `%edx`.
- Current default after EmitEdge single `r_pedge` load
  (`out\dos-timedemo-20260915-104810`): `63.573476 / 63.573196 / 63.573176` s,
  median **63.573196 s / 15.242273 FPS**, checksum `4154140932` on all three
  runs.  About 10.4 ms faster than the TrailingEdge-unlink default; every
  run was faster than every prior-default run.  Horizontal edges skip
  `r_pedge` entirely; non-horizontal edges load it once for `et_owner`.
- Current default after TrailingEdge skip of `r_bmodelactive` RMW
  (`out\dos-timedemo-20260915-110651`): `63.523808 / 63.523798 / 63.523763` s,
  median **63.523798 s / 15.254125 FPS**, checksum `4154140932` on all three
  runs.  About 49.4 ms faster than the EmitEdge-`r_pedge` default; every
  run was faster than every prior-default run.  World surfaces
  (`insubmodel==0`) skip the `r_bmodelactive` load/sub/store.
- Current default after bmodel `incl`/`decl` of `r_bmodelactive`
  (`out\dos-timedemo-20260915-111815`): `63.501194 / 63.500915 / 63.500960` s,
  median **63.500960 s / 15.259612 FPS**, checksum `4154140932` on all three
  runs.  About 22.8 ms faster than the world-skip default; every run was
  faster than every prior-default run.  `Lbmodel_leading` uses
  `incl C(r_bmodelactive)`; TrailingEdge bmodels use `decl`.
- Current default after dropping unused clipped `r_pedge` load
  (`out\dos-timedemo-20260915-113652`): `63.488166 / 63.488089 / 63.488004` s,
  median **63.488089 s / 15.262705 FPS**, checksum `4154140932` on all three
  runs.  About 12.9 ms faster than the bmodel-incl/decl default; every run
  was faster than every prior-default run.  Fully-clipped edges only update
  `cacheoffset`.
- Current default after TrailingEdge memory `decl` of `spanstate`
  (`out\dos-timedemo-20260915-115111`, rebench of `114708`):
  `63.355242 / 63.355064 / 63.355125` s, median **63.355125 s / 15.294737 FPS**,
  checksum `4154140932` on all three runs.  About 133.0 ms faster than the
  clipped-`r_pedge` default; every run was faster than every prior-default
  run.  First bench (`114708`) was `63.355247 / 63.355017 / 63.355112` s.
- Current default after leading spanstate `movl $1`
  (`out\dos-timedemo-20260915-120825`): `63.281763 / 63.281476 / 63.281405` s,
  median **63.281476 s / 15.312538 FPS**, checksum `4154140932` on all three
  runs.  About 73.6 ms faster than the TrailingEdge-spanstate-decl default;
  every run was faster than every prior-default run.  Non-inverted leading
  paths store immediate 1; `Lxl_done` keeps `incl`.
- Current default after EmitEdge deferred `edge_p`
  (`out\dos-timedemo-20260915-122259`): `63.267487 / 63.267234 / 63.267301` s,
  median **63.267301 s / 15.315969 FPS**, checksum `4154140932` on all three
  runs.  About 14.2 ms faster than the leading-`movl $1` default; every run
  was faster than every prior-default run.  Horizontal edges skip
  `edge_p`/`leal`; CF from the ceil `cmpl` still feeds the side `jc`.
- Current default after RecursiveTriangle live `new[0]`/`new[1]`
  (`out\dos-timedemo-20260915-124237`): `63.265572 / 63.265453 / 63.265414` s,
  median **63.265453 s / 15.316416 FPS**, checksum `4154140932` on all three
  runs.  About 1.8 ms faster than the deferred-`edge_p` default; every run
  was faster than every prior-default run.
- Current default after Aff8 pixel `movzbl`
  (`out\dos-timedemo-20260915-125058`): `63.179791 / 63.179533 / 63.179599` s,
  median **63.179599 s / 15.337229 FPS**, checksum `4154140932` on all three
  runs.  About 85.9 ms faster than the RecursiveTriangle default; every run
  was faster than every prior-default run.  LDraw8–1 and `LExactlyOneLong`
  use `movzbl` for the texel half of the colormap index.
- Current default after FinalVerts `movzbl` skin texel
  (`out\dos-timedemo-20260915-131025`): `63.178491 / 63.178164 / 63.178180` s,
  median **63.178180 s / 15.337574 FPS**, checksum `4154140932` on all three
  runs.  About 1.4 ms faster than the Aff8-`movzbl` default; every run was
  faster than every prior-default run.
- Current default after DrawSubdiv deferred `d_pcolormap`
  (`out\dos-timedemo-20260915-132507`): `63.146060 / 63.145728 / 63.145837` s,
  median **63.145837 s / 15.345430 FPS**, checksum `4154140932` on all three
  runs.  About 32.3 ms faster than the FinalVerts-`movzbl` default; every
  run was faster than every prior-default run.  Culled triangles skip the
  colormap store.
- Current default after Aff8 one-long deferred `ptex`
  (`out\dos-timedemo-20260915-133615`): `63.143406 / 63.143310 / 63.143203` s,
  median **63.143310 s / 15.346044 FPS**, checksum `4154140932` on all three
  runs.  About 2.5 ms faster than the DrawSubdiv-colormap default; every
  run was faster than every prior-default run.  Occluded one-pixel spans
  skip the skin pointer load.
- Current default after RecursiveTriangle deferred `lp2[0]`
  (`out\dos-timedemo-20260915-140237`): `63.141181 / 63.141050 / 63.141084` s,
  median **63.141084 s / 15.346585 FPS**, checksum `4154140932` on all three
  runs.  About 2.2 ms faster than the Aff8-one-long-`ptex` default; every
  run was faster than every prior-default run.  Unequal-`y` leading edges
  skip the `lp2[0]` load.
- Current default after RecursiveTriangle deferred split-path prefetches
  (`out\dos-timedemo-20260915-144910`): `63.139641 / 63.139434 / 63.139417` s,
  median **63.139434 s / 15.346986 FPS**, checksum `4154140932` on all three
  runs.  About 1.7 ms faster than the `lp2[0]`-defer default; every run was
  faster than every prior-default run.  `LSplit`/`LSplit2` skip the next-edge
  `lp3[0]`/`lp1[0]` loads.
- Current default after RecursiveTriangle deferred `|dy|` y-loads
  (`out\dos-timedemo-20260915-150014`): `63.121965 / 63.121804 / 63.121646` s,
  median **63.121804 s / 15.351272 FPS**, checksum `4154140932` on all three
  runs.  About 17.6 ms faster than the split-prefetch default; every run was
  faster than every prior-default run.  `|dx|` early-outs skip both y loads;
  `LSplit3` does `movl %ebx,%edx` locally.
- Current default after StepActiveU deferred aftertail unlink loads
  (`out\dos-timedemo-20260915-153501`): `63.113353 / 63.112658 / 63.112628` s,
  median **63.112658 s / 15.353497 FPS**, checksum `4154140932` on all three
  runs.  About 9.1 ms faster than the `|dx|` y-load default; every run was
  faster than every prior-default run.  Scanline finish via `edge_aftertail`
  no longer loads `et_prev`/`et_next`.
- Current default after InsertNewEdges deferred `et_next` (probes 1–3)
  (`out\dos-timedemo-20260915-154958`): `63.105419 / 63.105230 / 63.105267` s,
  median **63.105267 s / 15.355295 FPS**, checksum `4154140932` on all three
  runs.  About 7.4 ms faster than the StepActiveU-aftertail default; every
  run was faster than every prior-default run.  Taken `et_u` early-outs
  skip the next-edge load; probe 4 keeps `jg` fallthrough.
- Current default after StepActiveU `LPushBackLoop` deferred `et_prev`
  (`out\dos-timedemo-20260915-160134`): `63.103349 / 63.103178 / 63.103124` s,
  median **63.103178 s / 15.355803 FPS**, checksum `4154140932` on all three
  runs.  About 2.1 ms faster than the InsertNewEdges-`et_next` default;
  every run was faster than every prior-default run.  First-probe
  `LPushBackFound` skips the `et_prev` load.  (An earlier measurement
  `out\dos-timedemo-20260915-155745` had a hitch min 1.88 FPS on run 2;
  the clean re-run is the accepted evidence.)
- Current default after EmitEdge deferred `r_framecount` on `LPop5AndDone`
  (`out\dos-timedemo-20260915-163753`): `63.102870 / 63.102606 / 63.102686` s,
  median **63.102686 s / 15.355923 FPS**, checksum `4154140932` on all three
  runs.  About 0.5 ms faster than the `LPushBackLoop`-`et_prev` default;
  every run was faster than every prior-default run.  Partially-clipped
  exits (`cacheoffset == 0x7FFFFFFF`) skip the `r_framecount` load.
- Current default after StepActiveU deferred step-loop `et_next`
  (`out\dos-timedemo-20260915-165144`): `63.091567 / 63.091379 / 63.091427` s,
  median **63.091427 s / 15.358664 FPS**, checksum `4154140932` on all three
  runs.  About 11.3 ms faster than the `r_framecount`-defer default; every
  run was faster than every prior-default run.  Aftertail / pushback no
  longer pay a probe preload; unlink uses one `et_next` load.
- Current default after RemoveEdges both-stores-then-advance
  (`out\dos-timedemo-20260915-171204`): `63.087380 / 63.087263 / 63.087206` s,
  median **63.087263 s / 15.359677 FPS**, checksum `4154140932` on all three
  runs.  About 4.2 ms faster than the StepActiveU-`et_next` default; every
  run was faster than every prior-default run.  Odd-length remove lists
  no longer take a special path to finish `prev->next`.
- Current default after FinalVerts Aff8-style light<<8 index
  (`out\dos-timedemo-20260915-172059`): `63.084563 / 63.084374 / 63.084351` s,
  median **63.084374 s / 15.360381 FPS**, checksum `4154140932` on all three
  runs.  About 2.9 ms faster than the RemoveEdges default; every run was
  faster than every prior-default run.
- Current default after leading memory `cmpl` first `st_key`
  (`out\dos-timedemo-20260915-173942`): `63.011902 / 63.012013 / 63.012104` s,
  median **63.012013 s / 15.378020 FPS**, checksum `4154140932` on all three
  runs.  About 72.4 ms faster than the FinalVerts-light<<8 default; every
  run was faster than every prior-default run.  `Lnewtop` /
  `Lzcheck_for_newtop` skip the `surf2->key` register preload.
- Current default after RecursiveTriangle live new[] into LDraw
  (`out\dos-timedemo-20260915-174638`): `63.006416 / 63.006581 / 63.006559` s,
  median **63.006559 s / 15.379351 FPS**, checksum `4154140932` on all three
  runs.  About 5.5 ms faster than the leading-`st_key`-`cmpl` default; every
  run was faster than every prior-default run.  Unequal-`y` draws skip
  stack reloads of `new[0]`/`new[1]`.
- Current default after leading sort-loop memory `cmpl` `st_key`
  (`out\dos-timedemo-20260915-180350`): `62.953648 / 62.953783 / 62.953854` s,
  median **62.953783 s / 15.392244 FPS**, checksum `4154140932` on all three
  runs.  About 52.8 ms faster than the live-new-into-LDraw default; every
  run was faster than every prior-default run.
- Current default after Aff8 multi skip dead last-group stepper
  (`out\dos-timedemo-20260915-182515`): `62.830458 / 62.830543 / 62.830579` s,
  median **62.830543 s / 15.422436 FPS**, checksum `4154140932` on all three
  runs.  About 123.2 ms faster than the sort-loop-`st_key` default; every
  run was faster than every prior-default run.
- Current default after InsertNewEdges memory `cmpl et_u`
  (`out\dos-timedemo-20260915-183750`): `62.787043 / 62.787258 / 62.787362` s,
  median **62.787258 s / 15.433068 FPS**, checksum `4154140932` on all three
  runs.  About 43.3 ms faster than the Aff8-last-group default; every run
  was faster than every prior-default run.
- Current default after `LPushBackLoop` memory `cmpl et_u`
  (`out\dos-timedemo-20260915-184357`): `62.783709 / 62.783486 / 62.783533` s,
  median **62.783533 s / 15.433983 FPS**, checksum `4154140932` on all three
  runs.  About 3.7 ms faster than the InsertNewEdges-`et_u`-`cmpl` default;
  every run was faster than every prior-default run.
- Current default after TrailingEdge memory `cmpl st_last_u`
  (`out\dos-timedemo-20260915-190100`): `62.782709 / 62.782647 / 62.782532` s,
  median **62.782647 s / 15.434201 FPS**, checksum `4154140932` on all three
  runs.  About 0.9 ms faster than the `LPushBackLoop`-`et_u`-`cmpl` default;
  every run was faster than every prior-default run.
- Current default after ScanLeftEdge skip dead last-row Bresenham
  (`out\dos-timedemo-20260915-200539`): `62.810895 / 62.753822 / 62.753905` s,
  median **62.753905 s / 15.441270 FPS**, checksum `4154140932` on all three
  runs.  About 28.7 ms faster than the TrailingEdge-`last_u` default; every
  run was faster than every prior-default run.  (Earlier measurement
  `out\dos-timedemo-20260915-200144` had a 62.856 s middle-run outlier;
  the clean re-run is the accepted evidence.)
- Current default after StepActiveU memory `addl et_u_step`
  (`out\dos-timedemo-20260915-202546`): `62.651188 / 62.649598 / 62.649569` s,
  median **62.649598 s / 15.466979 FPS**, checksum `4154140932` on all three
  runs.  About 104.3 ms faster than the ScanLeftEdge default; every run
  was faster than every prior-default run.
- Current default after leading `Lnewtop` memory `cmpl st_last_u`
  (`out\dos-timedemo-20260915-203108`): `62.623894 / 62.623729 / 62.623708` s,
  median **62.623729 s / 15.473368 FPS**, checksum `4154140932` on all three
  runs.  About 25.9 ms faster than the StepActiveU-`et_u_step` default; every
  run was faster than every prior-default run.
- Current default after EmitEdge defer `r_ceilv1` past horizontal EO
  (`out\dos-timedemo-20260915-204522`): `62.621949 / 62.621766 / 62.621726` s,
  median **62.621766 s / 15.473853 FPS**, checksum `4154140932` on all three
  runs.  About 2.0 ms faster than the `Lnewtop`-`last_u` default; every run
  was faster than every prior-default run.
- Current default after RecursiveTriangle memory `addl` s/t/zi midpoints
  (`out\dos-timedemo-20260915-205607`): `62.605330 / 62.605144 / 62.605103` s,
  median **62.605144 s / 15.477961 FPS**, checksum `4154140932` on all three
  runs.  About 16.6 ms faster than the EmitEdge-`r_ceilv1` default; every
  run was faster than every prior-default run.
- Previous default after EmitEdge memory `cmpl` u-clamp
  (`out\dos-timedemo-20260915-210614`): `62.588579 / 62.588326 / 62.588325` s,
  median **62.588326 s / 15.482121 FPS**, checksum `4154140932` on all three
  runs.  About 16.8 ms faster than the RecursiveTriangle-midpoint default;
  every run was faster than every prior-default run.
- Current default after EmitEdge memory `subl surfaces`
  (`out\dos-timedemo-20260915-211623`): `62.580216 / 62.580291 / 62.580319` s,
  median **62.580291 s / 15.484108 FPS**, checksum `4154140932` on all three
  runs.  About 8.0 ms faster than the u-clamp default; every run was faster
  than every prior-default run.  `LSide1`/`LSide0` compute
  `surface_p - surfaces` with memory `subl C(surfaces)` and set the sort
  side register from zeroed `%edx` or immediate 1.

## Important decisions and assumptions

- Original C bodies stay intact as references; do not delete them to make ASM
  the only implementation.
- A focused microbenchmark win is not sufficient.  Require correctness,
  matched release timedemos, and a measured end-to-end gain before changing a
  default.
- Keep `-O3 -march=i486` as the measured default, the same DOSBox-X
  version/profile/cycles, demo, data, and command-line options for A/B
  comparisons.  Use `-OptimizationProfile baseline` for `-O2`.  Do not
  enable newer ISA requirements.  Do not add `-funroll-loops` to the
  aggressive C flags; it failed the framebuffer checksum gate.
- Exact framebuffer checksum is the automated parity gate.  It does not prove
  complete visual or gameplay parity outside the timedemo.
- `R_AliasTransformFinalVert_asm486` uses static scratch labels in
  `asm486_experiments.s`; this is acceptable for the current single-threaded
  DOS renderer, but the helper is not reentrant.
- DOSBox-X timing is an emulated 486-class model.  No physical 486 measurement
  has been made, and only `demo1` has been used for the documented matched
  end-to-end comparisons.
- **The 1.0 cycle per instruction figure prices added work, not removed work**
  (2026-10-03).  Eleven assembly probes measured the cost of *adding* a duplicated
  sequence and span nine mixes at 0.9740–0.9957; a twelfth put four instructions of
  the span16 clamp shape into that path at 0.988, while four instructions of that
  same shape *removed* from it returned 0.0000% against a 4.1x-gate prediction.  Use
  1.0 to **screen** — it is the higher price, so it admits more candidates, and the
  timedemo still promotes nothing on its own.  **Never close a pool on an
  instruction count.**  The error is one-way and always over-pricing, so a
  model-priced rejection means "nobody built it", not "it is slow".  See the
  clamp-fusion entry at the top of this file.

## Failed or inconclusive work

- `Lgs_lastspan` memory `cmpl st_last_u`
  (`out\dos-timedemo-20260915-204034`) matched checksum `4154140932` but
  was ~4.3 ms slower than the `Lnewtop`-`last_u` default (median 62.628042 s).
  Once-per-scanline right-edge emit; do not retry.
- Aff8 DrawSpans8 skip last-span right-edge Bresenham
  (`out\dos-timedemo-20260915-201944`) matched checksum `4154140932` but
  was ~19.5 ms slower than the ScanLeftEdge default (median 62.773405 s).
  Peeking the `-999999` sentinel before the step hurt the common path;
  do not retry.
- Particle NxN drop `%esi` push; use dead `%eax` for `d_zrowbytes`
  (`out\dos-timedemo-20260915-195244`) matched checksum `4154140932` but
  was noise (~0.3 ms vs the TrailingEdge-`last_u` default).  Do not retry.
- Leading inverted `Lxl_done` memory `incl` spanstate
  (`out\dos-timedemo-20260915-185246`) matched checksum `4154140932` but
  was noise (~0.1 ms vs the `LPushBackLoop`-`et_u`-`cmpl` default).
  Do not retry.
- EmitEdge defer `r_ceilv1` fistl past `r_nearzionly` (`out\dos-timedemo-20260915-181715`)
  matched checksum `4154140932` but was ~20.4 ms slower than the sort-loop
  `st_key` default (median 62.974149 s).  Extra `fxch` around deferred
  `fistl` on the common emit path hurt more than skipping ceil on
  nearzionly; do not retry.
- Sprite `D_SpriteDrawSpans` v/u CSE across Z and dest setup
  (`out\dos-timedemo-20260915-172816`) matched checksum `4154140932` but
  was noise (~0.14 ms vs the FinalVerts-light<<8 default).  Keeping
  `sspan_t_v`/`u` live did not move end-to-end time; do not retry.
- Particle defer rect-edge loads past clip early-outs (`D_DrawParticle`)
  (`out\dos-timedemo-20260915-170311`) matched checksum `4154140932` but
  was noise (~0.4 ms vs the StepActiveU-`et_next` default).  Short-circuit
  loads for `d_vrectright_particle` / `d_vrectx` did not move end-to-end
  time; do not retry.
- RecursiveTriangle keep `lp2[1]` live via `leal` for nodraw compare
  (`out\dos-timedemo-20260915-161932`) matched checksum `4154140932` but
  was noise/tied vs the `LPushBackLoop`-`et_prev` default (median
  63.103192 s; run 1 outlier 63.699628 s).  Avoiding the `4(%esi)` reload
  did not move end-to-end time; do not retry.
- InsertNewEdges defer `et_next` on all four probes with `jle`+`jmp`
  (`out\dos-timedemo-20260915-154519`) matched checksum `4154140932` but
  was noise (~0.4 ms vs the StepActiveU-aftertail default).  The extra
  unconditional `jmp` on long walks cancelled the load savings; keep
  probes 1–3 only with probe-4 `jg` fallthrough.  Do not retry the
  four-probe+`jmp` form.
- InsertNewEdges unify `LAddedge2` into `LAddedge` (`out\dos-timedemo-20260915-152701`)
  matched checksum `4154140932` but was ~4.2 ms slower than the `|dx|` y-load
  default (median 63.125989 s).  Falling through with `movl %esi,%ecx` hurt;
  do not retry.
- Sprite `Spr8Entry2_8` drop dead texel preload (`out\dos-timedemo-20260915-152226`)
  matched checksum `4154140932` but was noise (~0.1 ms).  `LLEntry2_8` already
  reloads after Z; removing the entry stub `movb` did not move end-to-end time;
  do not retry.
- Aff8 hoist `pz`/`zi` before one-long vs multi (`out\dos-timedemo-20260915-151700`)
  matched checksum `4154140932` but was noise (~0.1 ms).  Sharing loads across
  the `cmpl $1` split (flags preserved by `movl`) did not help; do not retry.
- Particle defer `pt_color` past Z (`out\dos-timedemo-20260915-135449`)
  matched checksum `4154140932` but was noise (~0.4 ms vs the Aff8-one-long
  default).  Per-leaf color loads for 1x1 after Z / NxN at entry did not
  move end-to-end time enough to keep; do not retry.
- Leading defer `surfaces[1].next` past inverted early-out
  (`out\dos-timedemo-20260915-123249`) matched checksum `4154140932` but was
  noise/~tied vs the deferred-`edge_p` default (median 63.267303 s).
  Splitting `LPatch2`/`LPatch2b` after the spanstate tests did not move
  end-to-end time; do not retry.
- TrailingEdge hoist `st_next` into `%ecx` for `LNoEmit`
  (`out\dos-timedemo-20260915-120218`) matched checksum `4154140932` but was
  noise (~0.08 ms vs the spanstate-decl default).  Preloading before the
  top-of-stack compare and sharing the emit unlink form for `LNoEmit` did
  not move end-to-end time; do not retry.
- EmitEdge `r_pedge`/`et_owner` into FDIV shadow (`out\dos-timedemo-20260915-112708`)
  matched checksum `4154140932` but was noise (~0.03 ms vs the bmodel
  incl/decl default).  Starting u-step FDIV before the owner store did not
  help; keep owner store before the side branch.  Do not retry.
- PolysetCalcGradients s/t step CSE (`out\dos-timedemo-20260915-113155`)
  matched checksum `4154140932` but median tied the prior default
  (63.500960 s).  Copying `r_sstepx`/`r_tstepx` before `shll` to avoid a
  second pair of loads did not move end-to-end time; do not retry.
- Leading spanstate-before-insubmodel reorder (`out\dos-timedemo-20260915-110203`)
  matched checksum `4154140932` but was noise (~0.01 ms vs the EmitEdge
  `r_pedge` default).  Testing inversion before loading `insubmodel` and
  dropping the redundant `Lbmodel_leading` spanstate retest did not move
  end-to-end time; do not retry.
- Span16 FILD-overlapped v/u loads (`out\dos-timedemo-20260915-103436`)
  matched checksum `4154140932` but was noise/~0.14 ms slower than the
  EmitEdge-pretouch default (median 63.614868 s vs 63.614724 s).  Loading
  `espan_t_v`/`espan_t_u` into `%eax`/`%ecx` under FILD and skipping the
  FDIV-shadow reloads did not help under DOSBox-X's 486 model; do not retry
  moving those dest-setup loads earlier in `D_DrawSpans16`.
- DrawSpans8 aspancount register CSE (`out\dos-timedemo-20260915-100552`)
  matched checksum `4154140932` but was noise/~0.11 ms slower than the
  st_key default.  Do not retry keeping a second copy of `d_aspancount` in
  `%ebp` for the right-edge `+=` update.
- TrailingEdge `st_next` CSE via `movl %ecx,%edx` (`out\dos-timedemo-20260915-095842`)
  matched checksum `4154140932` but was noise (~0.03 ms).  Replaced by the
  kept direct-`%ecx` unlink (`out\dos-timedemo-20260915-103948`); do not
  retry the intermediate `movl %ecx,%edx` form.
- Edge-scan both-edges leading precompute (`out\dos-timedemo-20260915-094223`)
  matched checksum `4154140932` but was ~1.7 ms slower than the surfaces-CSE
  default (63.654537 s vs 63.652849 s).  Finishing `surf*` before
  `TrailingEdge` avoided a reload but the leading-only join cost more;
  do not retry.
- Turbulent sstep/tstep/pbase stack hoist (`out\dos-timedemo-20260915-091357`)
  matched checksum `4154140932` but was ~17 ms slower than the aspancount
  default (63.743347 s vs 63.726061 s).  Absolute C-global loads beat
  stack-relative copies for those three invariants; do not retry.
- HDPMI32 as an alternate DPMI server (`DPMI-HDPMI32.md`,
  `out\dos-dpmi-compare-20260915-084120`): resident `HDPMI32 -r` is
  detected and Quake completes `demo1`, but every run failed checksum
  `2955717646` vs `4154140932`.  Median FPS looked ~0.05% higher while
  measuring different pixels, and one of five HDPMI runs hitching widened
  its FPS range to 0.325.  Keep CWSDPMI; do not promote HDPMI32.
- A texture row-lookup experiment was reverted after a faster run produced
  checksum `2955717646` instead of `4154140932`.
- The isolated surface-cache, mip, BSP-dot, and BSP-clip wins did not survive
  the real call boundary and workload; their C paths remain defaults.
- The broad mixed benchmark matrix in
  `out\dos-bench-20260910-204331` exceeded its 300-second diagnostic bound
  before producing a result JSON.  It is not a passing benchmark and should
  not be used as evidence.
- Alias `AngleVectors` caching (`out\dos-timedemo-20260911-055546`) matched
  checksum `4154140932` but was 15.6 ms slower than the current default.
  Hit rate did not cover the probe/copy cost; do not retry a per-frame
  angle-basis cache.
- Direct mip0 column calls (`out\dos-timedemo-20260911-060235`) matched
  checksum `4154140932` but were 1.1 ms slower than the indirect
  `(*pblockdrawer)()` POT loop.  Do not retry direct mip drawers.
- Remainder `EntryN_16` t-zero cachewidth skip
  (`out\dos-timedemo-20260911-132341`) matched checksum `4154140932` but
  was 20.8 ms slower (68.007120 s vs 67.986326 s).  The extra remainder
  branch cost more than the skipped IMUL; do not retry.
- Texture-source `cachespantable` (`out\dos-timedemo-20260911-133154`)
  matched checksum `4154140932` but was 347 ms slower.  Filling source
  rows per surface cost more than the per-span cachewidth IMUL; do not
  retry a per-surface source-row table.
- Alias POT skinwidth shift (`out\dos-timedemo-20260911-140630`)
  matched checksum `4154140932` but was 11.7 ms slower (67.260820 s
  vs 67.249168 s).  The extra `test`/`js`/`jmp` around one per-triangle
  IMUL cost more than the shift; do not retry a branched skinwidth
  shift.
- PreparePoints clip-rect hoist (`out\dos-timedemo-20260911-153350`)
  matched checksum `4154140932` but was 15.7 ms slower (67.234277 s
  vs 67.218606 s).  Extra locals around the transform/project calls
  spilled; do not retry hoisting `aliasvrect` in `R_AliasPreparePoints`.
- Alias clip hoist + skip Z reflag (`out\dos-timedemo-20260914-181813`)
  matched checksum `4154140932` but was 42.4 ms slower (64.134559 s
  vs 64.092171 s).  Extra locals / `clip != R_Alias_clip_z` branch in
  `R_AliasClip` cost more than the skipped retest; do not retry.
- Polyset sstep hoist (`out\dos-timedemo-20260914-183707`)
  matched checksum `4154140932` but was 9.1 ms slower (64.012388 s
  vs 64.003272 s).  Routing `a_sstepxfrac` through BSS `sstep` in the
  pixel loop did not beat the direct C global; keep `addl C(a_sstepxfrac)`.
- Polyset Bresenham const hoist (`out\dos-timedemo-20260914-184757`)
  matched checksum `4154140932` but was 36.7 ms slower (64.039951 s
  vs 64.003272 s).  Local copies of `erroradjustup`/`down`, `ubasestep`,
  and `d_countextrastep` for the span prologue cost more than the C
  global loads; do not retry.
- Left-edge `d_ptexextrastep` via `a_ststepxwhole`
  (`out\dos-timedemo-20260915-053730`) matched checksum `4154140932`
  but was 76.5 ms slower (64.060863 s vs 63.984395 s).  Carry adjust
  plus ±1/`t_adj` branches cost more than `(textra>>16)*skinwidth`; keep
  the direct IMUL form from the left-edge s/t CSE keep.
- Z-span odd-pixel `%ebp` bit0 tag (`out\dos-timedemo-20260915-060125`)
  matched checksum `4154140932` but was 64.6 ms slower (63.959669 s
  vs 63.895076 s).  Tagging the span cursor to drop the count push/pop
  cost more than the stack traffic; keep `pushl %ecx` / `popl %ecx`.
- ScanLeftEdge skinwidth stack hoist (`out\dos-timedemo-20260915-061218`)
  matched checksum `4154140932` but was 10.0 ms slower (63.905049 s
  vs 63.895076 s).  Pushing `skinwidth` once and `addl (%esp)` on tfrac
  carry did not beat the direct `r_affinetridesc` load; do not retry.
- DrawSpans8 stack-live aspancount/errorterm
  (`out\dos-timedemo-20260915-065310`) matched checksum `4154140932`
  but was 36.7 ms slower (63.819708 s vs 63.783005 s).  Routing the
  outer right-edge mutables through stack slots cost more than the C
  globals; keep direct `C(d_aspancount)` / `C(errorterm)` traffic.
  (ScanLeftEdge aspancount stack spill is a different site and was kept.)
- ScanLeftEdge erroradjust stack (`out\dos-timedemo-20260915-075950`)
  matched checksum `4154140932` but hitch min 1.93 FPS and ~13 ms slower
  median than the aspancount-only default.  Do not retry spilling
  `erroradjustup`/`down` beside the kept ScanLeftEdge stack locals.
- ScanLeftEdge errorterm stack (`out\dos-timedemo-20260915-080441`)
  matched checksum `4154140932` but was ~13 ms slower than aspancount-only.
  Do not retry spilling `errorterm` beside aspancount in ScanLeftEdge.
- Span16 s/t integer CSE (`out\dos-timedemo-20260915-074041`) matched
  checksum `4154140932` but was ~43 ms slower.  Do not retry keeping
  clamped s/t in registers across the sfrac/tfrac shifts in
  `D_DrawSpans16`.
- Span16 early `pnext` preload (`out\dos-timedemo-20260915-075512`)
  matched checksum `4154140932` but was noise/slightly slower.  Do not
  retry storing the next span in `pspantemp` during FDIV setup.
- Sky `viewspantable` dest (`out\dos-timedemo-20260915-075043`) matched
  checksum `4154140932` but was noise (~0.01 ms).  Do not retry
  `D_DrawSkyScans8` row-table addressing for timedemo gain; multiply
  form remains.
- Unclipped alias `movzbl` expand (`out\dos-timedemo-20260911-155009`)
  matched checksum `4154140932` but the 0.16 ms median delta sat
  inside the previous run spread; do not retry byte-store vs
  `movzbl` expansion in `R_AliasTransformAndProjectFinalVerts`.
- Inlined fused frustum (`out\dos-timedemo-20260911-155650`)
  matched checksum `4154140932` but run 3 hitched to 1.87 FPS and
  the median was 0.12 ms slower.  Do not retry fused `minmaxs`
  multiplies in `R_RecursiveWorldNode`; the extra CALL helper already
  lost, and this inlined form did not beat the original stores.
- FinalVerts colormap hoist (`out\dos-timedemo-20260911-160304`)
  matched checksum `4154140932` but was 0.18 ms slower (67.200621 s
  vs 67.200437 s).  Do not retry stacking `acolormap` in
  `D_PolysetDrawFinalVerts`; the clip-edge hoist is enough.
- Gradient step cache (`out\dos-timedemo-20260911-161755`)
  matched checksum `4154140932` but was 34.3 ms slower (67.220030 s
  vs 67.185736 s).  The texinfo/mip/modelorg compares cost more than
  the skipped step muls; do not retry a last-used `D_CalcGradients`
  step-origin cache.
- Mip-scaled modelorg (`D_CalcGradients`,
  `out\dos-timedemo-20260911-183436`) matched checksum `4154140932`
  but was 4.2 ms slower (67.096034 s vs 67.091882 s) with an 846 ms
  first-run outlier.  Do not retry precomputing
  `transformed_modelorg × mipscale`; the per-frame `xscaleinv` tables
  are enough.
- DrawSurfaces Restore/Set CALL skip
  (`out\dos-timedemo-20260911-184541`) matched checksum `4154140932`
  but was 1.4 ms slower (67.093276 s vs 67.091882 s).  Extra
  per-surface `span_bmodel` tests cost more than the no-op CALL on
  the 486; do not retry skipping `D_RestoreWorldDrawingState` /
  `D_SetBmodelDrawingState` with caller-side ifs.
- Direct `D_DrawSpans16` (`out\dos-timedemo-20260911-185331`)
  matched checksum `4154140932` but was 9.3 ms slower (67.101141 s
  vs 67.091882 s).  Do not retry a per-surface compare against
  `d_drawspans` to turn the indirect CALL into a direct one.
- World `r_drawpolys` hoist (`out\dos-timedemo-20260911-185857`)
  matched checksum `4154140932` but run 1 hitched to **1.89 FPS**
  (67.545301 s).  Runs 2/3 were ~3 ms faster and are not a promote.
  Do not retry duplicating `R_RecursiveWorldNode` surface loops to
  hoist `r_drawpolys`; growing that function hitches like fused
  frustum.
- Alias `skintable` start addressing
  (`out\dos-timedemo-20260911-190512`) matched checksum `4154140932`
  but was 178.6 ms slower (67.270496 s vs 67.091882 s).  Do not
  retry `skintable` in `D_RasterizeAliasPolySmooth` or calling
  `D_PolysetUpdateTables` on the clipped path; keep the
  `t*skinwidth` start IMUL and the drawtype-only table fill.
- Skip live `blocksize` (`R_DrawSurface`,
  `out\dos-timedemo-20260911-192431`) was faster but checksum
  `2281919689`.  The 8-bit column loop still advances `soffset` with
  the `blocksize` global.  Do not skip storing `blocksize`; dest
  `horzblockstep` is not enough.
- `R_DrawSurface` surfmip hoist (`out\dos-timedemo-20260911-193158`)
  matched checksum `4154140932` but the 0.008 ms median delta sat
  inside the previous run spread (67.085593 s vs 67.085585 s).  Do
  not retry a local `mip` for rebuild setup; `-O3` already CSEs
  `r_drawsurf.surfmip`.
- Face vert-base hoist (`R_RenderFace`,
  `out\dos-timedemo-20260911-182623`) matched checksum `4154140932`
  but was 32.0 ms slower (67.123877 s vs 67.091882 s).  The extra
  local spilled the edge loop; do not retry hoisting
  `r_pcurrentvertbase` in `R_RenderFace`.
- AnimateLight length-1 skip (`out\dos-timedemo-20260911-180922`)
  matched checksum `4154140932` but was 2.1 ms slower (67.095987 s
  vs 67.093880 s).  The extra `len==1` branch cost more than the
  skipped IDIV; do not retry length-1 or POT remainder in
  `R_AnimateLight`.
- Face model hoist (`R_RenderFace`,
  `out\dos-timedemo-20260911-180409`) matched checksum `4154140932`
  but the median was 0.05 ms slower (67.093926 s vs 67.093880 s)
  with a 500 ms first-run outlier.  Do not retry hoisting
  `currententity->model` in `R_RenderFace`; the surfedges pointer is
  enough.
- Fused smax POT wrap (`R_DrawSurface`,
  `out\dos-timedemo-20260911-175426` and confirmation
  `out\dos-timedemo-20260911-175849`) matched checksum `4154140932`
  but hitched: first confirmation run min **1.91 FPS**, and the first
  measurement run was 700 ms slower.  Do not retry folding the soffset
  wrap into the column-loop POT test.
- Bmodel clip unroll (`R_RenderBmodelFace`,
  `out\dos-timedemo-20260911-173554`) matched checksum `4154140932` but
  the median was 0.07 ms slower than the `R_RenderFace` default
  (67.097295 s vs 67.097222 s) with fully overlapping run ranges.
  Do not retry unrolling the bmodel clip-plane list; world-face
  surfedges addressing was the real win.
- Turbulent last-segment divisor switch
  (`out\dos-timedemo-20260911-150819`) matched checksum `4154140932`
  but was 27.6 ms slower (67.275508 s vs 67.247873 s).  GCC did emit
  IMUL magic, but the 15-way jump table cost more than two IDIVs; do
  not retry a switch or jump table around the last-segment divide.
- 1900 KB (`out\dos-timedemo-20260911-142256`), 2000 KB
  (`out\dos-timedemo-20260911-141744`), 2100 KB
  (`out\dos-timedemo-20260911-135941`), and 2400 KB
  (`out\dos-timedemo-20260911-135043`) were all faster (about
  14.43 FPS) but checksum `2955717646`.  2100 KB run 1 also hitched
  to 1.72 FPS.  1800 KB is the largest checksum-identical size
  measured.  Do not retry 1900 KB or larger without a new
  checksum-identical size.  **— SUPERSEDED 2026-09-29: there is no
  cache-size correctness bug. 1900/2400/6000 KB all render checksum
  `1047377823`; 2400 KB is promoted.**
- Aggressive `-funroll-loops` in `tools\build-dos.ps1`
  (`out\dos-timedemo-20260914-134806`) was about 161.6 ms faster than the
  matched control (`out\dos-timedemo-20260914-134340`: median
  66.962633 s / 14.470758 FPS) at median **66.801015 s / 14.505767 FPS**,
  but every run produced framebuffer checksum `2623602099` instead of
  `4154140932`.  Do not retry global `-funroll-loops` under `-ffast-math`;
  targeted source unrolls that keep the checksum remain allowed.
- MarkLights 2x2 sample cull (`out\dos-timedemo-20260914-161209`) matched
  checksum `4154140932` but was 112.5 ms slower than the continuous
  clamp-to-rect idist default (64.241100 s / 15.083802 FPS vs
  64.128594 s / 15.110264 FPS).  Extra per-face sample work cost more than
  the few additional culls; do not retry a 2x2 or fuller discrete sample
  scan in `R_MarkLights`.
- Dlight sample-window clamp in `R_AddDynamicLights`
  (`out\dos-timedemo-20260914-162709`) produced checksum `696680082` on
  run 2 (runs 1/3 kept `4154140932`).  Do not retry clamping the live
  s/t loops by a float floor window derived from `fmin_scaled`; keep the
  full-grid walk.  `R_AddDynamicLights_C` remains the reference.

## Priority-ordered next steps

1. Reproduce the current `-O3` default three-run `demo1` timedemo
   (15.484108 FPS median, checksum `4154140932`,
   `out\dos-timedemo-20260915-211623`) before further edits.
   ~~`timedemo-dos.ps1` does **not** rebuild an existing `qbench.exe`; run
   `build-dos.ps1 -Benchmark` first after source changes, then
   `-SkipBuild` for the timedemo.~~
   **(2026-10-02: stale, struck through. The runner now fingerprints all 163
   sources plus the resolved selectors and rebuilds on a mismatch, or throws
   under `-SkipBuild` — `timedemo-dos.ps1:319-405`. Verified twice in one session
   this pass. See `:489`. `-Clean` on `build-dos.ps1` remains sound advice but is
   no longer required for correctness.)**
   **DPMI note (2026-09-15):** HDPMI32 as a CWSDPMI alternative was tested
   with engine unchanged (`DPMI-HDPMI32.md`).  It runs and probes as vendor
   `HDPMI` 3.20, but every timedemo failed checksum `2955717646` vs
   known-good `4154140932`.  Keep CWSDPMI; do not promote HDPMI32.
   Do not retry turbulent sstep/tstep/pbase stack hoisting
   (`out\dos-timedemo-20260915-091357`; ~17 ms slower).
   Do not retry both-edges leading precompute before `TrailingEdge`
   (`out\dos-timedemo-20260915-094223`; ~1.7 ms slower).
   Do not retry TrailingEdge `movl %ecx,%edx` CSE (noise); the direct-`%ecx`
   unlink is kept.  Do not retry DrawSpans8 aspancount register CSE.
   Do not restore ScanLeftEdge or EmitEdge discarded pretouch loads.
   Do not restore the EmitEdge `r_pedge` preload into `%esi`.
   Do not retry Span16 FILD-overlapped v/u dest loads
   (`out\dos-timedemo-20260915-103436`; noise).
   Do not retry leading spanstate-before-insubmodel reorder
   (`out\dos-timedemo-20260915-110203`; noise).
   Do not restore load/add/store for `r_bmodelactive` on the bmodel path.
   Do not retry EmitEdge owner-store into FDIV shadow
   (`out\dos-timedemo-20260915-112708`; noise).
   Do not retry PolysetCalcGradients s/t step CSE
   (`out\dos-timedemo-20260915-113155`; tied).
   Do not restore the unused clipped-path `r_pedge` load.
   Do not restore load/decl/store for TrailingEdge `spanstate`.
   Do not retry TrailingEdge `st_next` hoist for `LNoEmit`
   (`out\dos-timedemo-20260915-120218`; noise).
   Do not restore leading `incl`+%edx store for known-zero spanstate.
   Do not restore EmitEdge `edge_p` load before the horizontal early-out.
   Do not retry leading `surfaces[1].next` defer past inverted early-out
   (`out\dos-timedemo-20260915-123249`; noise).
   Do not restore RecursiveTriangle stack reloads of `new[0]`/`new[1]`.
   Do not restore Aff8 `xorl`+`movb` colormap index formation.
   Do not restore FinalVerts `movb`+`andl $0x00FF` skin texel load.
   Do not restore DrawSubdiv `d_pcolormap` setup under the FPU cull.
   Do not restore Aff8 one-long `ptex` load before the Z test.
   Do not retry particle `pt_color` defer past Z
   (`out\dos-timedemo-20260915-135449`; noise).
   Do not restore RecursiveTriangle `lp2[0]` load before the equal-`y` test.
   Do not restore RecursiveTriangle next-edge prefetches before `|dy|` split.
   Do not restore RecursiveTriangle y loads before `|dx|` early-out.
   Do not retry Aff8 `pz`/`zi` hoist before one-long vs multi
   (`out\dos-timedemo-20260915-151700`; noise).
   Do not retry `Spr8Entry2_8` dead texel preload removal
   (`out\dos-timedemo-20260915-152226`; noise).
   Do not retry InsertNewEdges `LAddedge2` fallthrough unify
   (`out\dos-timedemo-20260915-152701`; ~4.2 ms slower).
   Do not restore StepActiveU `et_prev`/`et_next` loads before the
   `edge_aftertail` early-out.
   Do not retry InsertNewEdges four-probe `et_next` defer with `jle`+`jmp`
   (`out\dos-timedemo-20260915-154519`; noise); keep probes 1–3 only.
   Do not restore InsertNewEdges `et_next` before the first three
   `et_u` early-outs.
   Do not restore StepActiveU `LPushBackLoop` `et_prev` before the first
   `et_u` early-out.  Do not extend that deferral to probe 2 with
   `jnl`+`jmp` (same trap as the four-probe InsertNewEdges form).
   Do not retry RecursiveTriangle `lp2[1]` live-keep via `leal` for nodraw
   (`out\dos-timedemo-20260915-161932`; noise).
   Do not restore EmitEdge `r_framecount` load before the `cacheoffset`
   `0x7FFFFFFF` early-out on `LPop5AndDone`.
   Do not restore StepActiveU step-loop `et_next` before order early-outs
   on probes 1–3.  Do not add a probe-4 `jl`+`jmp` form.
   Do not retry particle rect-edge load defer past clip early-outs
   (`out\dos-timedemo-20260915-170311`; noise).
   Do not restore RemoveEdges `%ebx` push or the odd-tail `Lre_done`
   second-store path.
   Do not restore FinalVerts dword light load/`andl $0xFF00`/`addl` for
   the colormap index.
   Do not retry sprite `D_SpriteDrawSpans` v/u CSE across Z/dest setup
   (`out\dos-timedemo-20260915-172816`; noise).
   Do not restore leading first-key `movl st_key(%esi),%ecx` before
   `cmpl` (`Lgs_leading` / `Lbmodel_leading`).
   Do not restore RecursiveTriangle `LDraw` stack reloads of `new[0]`/
   `new[1]` (keep live `%edx`/`%ebp` from midpoint; equal-y uses `%eax`
   for `lp2[0]`).
   Do not restore sort-loop `movl st_key(%esi),%ecx` before `cmpl`
   (`Lsortloopnb` / `Lsortloop`).
   Do not retry EmitEdge defer `r_ceilv1` past `r_nearzionly`
   (`out\dos-timedemo-20260915-181715`; ~20 ms slower).
   Do not restore Aff8 multi last-group stepper before `decw` exit
   (`Lp8`).
   Do not restore InsertNewEdges `movl et_u→%ebx` before `cmpl`.
   Do not restore `LPushBackLoop` `movl et_u→%ebx` before `cmpl`.
   Do not retry leading inverted `Lxl_done` memory `incl` spanstate
   (`out\dos-timedemo-20260915-185246`; noise).
   Do not restore TrailingEdge `st_last_u` preload before the `LNoEmit2`
   early-out.
   Do not retry particle NxN `%esi` push removal / `%eax` z-stride
   (`out\dos-timedemo-20260915-195244`; noise).
   Do not restore ScanLeftEdge last-row Bresenham step after the final
   package (`decl`/`jz` before step is kept).
   Do not retry Aff8 DrawSpans8 last-span right-edge Bresenham skip
   (`out\dos-timedemo-20260915-201944`; ~19.5 ms slower).
   Do not restore StepActiveU `movl et_u_step→%ebx` before `addl`.
   Do not restore leading `Lnewtop` `st_last_u` preload before the
   `LInsertAndExit` early-out.
   Do not retry `Lgs_lastspan` memory `cmpl st_last_u`
   (`out\dos-timedemo-20260915-204034`; ~4.3 ms slower).
   Do not restore EmitEdge `movl r_ceilv1→%ecx` before the horizontal
   `cmpl`/`jz`.
   Do not restore RecursiveTriangle `movl lp2→%edx` before midpoint
   `addl` for new[2]/new[3]/new[5].
   Do not restore EmitEdge u-clamp `movl` of vrect bounds before `cmpl`.
   Do not restore EmitEdge `movl C(surfaces),%esi` before the LSide1/LSide0
   `surface_p - surfaces` sub; the memory form and explicit sort-side
   `movl` are kept.
   Do not retry 16-byte `.p2align` padding of the Aff8 hot labels
   (reverted; 0.806117% slower median, checksum-clean).  The 486 code-layout
   axis remains untried in every other loop family, but padding these
   already-large unrolled bodies measurably hurt; prefer layout experiments
   that do not grow the bodies.  The experiment code and its
   `-Aff8LoopAlignment` selector have been removed from the tree.
   Do not port `D_PolysetSetEdgeTable` to assembler on principle.  It is a
   short branch tree that only assigns `pedgetable`; the remaining C cost in
   the alias raster path is concentrated in the step-precomputation blocks
   and the span-package setup of `D_RasterizeAliasPolySmooth`, not in this
   predicate.  Instrument that residual (10.74% of frame) before choosing a
   port target.
    The alias raster path is now instrumented to the source level and is
    converged: `D_PolysetCalcGradients`, `D_PolysetScanLeftEdge`, and
    `D_PolysetDrawSpans8` are assembly; the remaining C (`linescan-setup`,
    `edge-setup`, `span-package`, `step-math`, `SetEdgeTable`) measures
    253-304 cycles per call with no outlier, and the two prior `SetUpForLineScan`
    improvements are already kept.  Do not open another C-to-ASM port here
    without a new source-level hypothesis, and note that per-call profiling now
    costs about as much as it measures.
    **(2026-10-01: the 253-304 cycles/call figure is withdrawn — it was 62-76%
    profiler overhead. The C glue measures 1.83 s of frame, a 3.1x overstatement,
    so "converged" is now a conclusion from a measurement that can see it. The
    guidance not to port it still holds, and now rests on the corrected number
    rather than on a clock artifact. See "Alias attribution corrected".)**
   Do not add AGI-interlock padding to the Aff8 pixel leaf.  The per-pixel
   hypothesis (`movb %dh,%ah` beside a `(%eax)`-based colormap load) is not a
   real interlock: the partial write has no memory operand and the `%eax` base
   use is already separated by the Z store.  The one genuine interlock,
   `addl $16,%ecx` -> `cmpw (%ecx),%bp` at the `LDrawLoop` back-edge, was
   measured at -0.000054% — a null result, not a regression — with checksum
   parity intact, and the `-Aff8AgiPadding` selector has since been removed
   from the tree.  Do not re-run it.  Check adjacency and operand types before
   believing any 486 interlock claim.
   Hot-code clustering via object reordering was measured at 0.7815% SLOWER
   and removed.  Reordering whole objects cannot cluster the two dominant
   drawers when each object is far larger than the 8 KB L1: it moved one
   leaf to the front of .text and grew the gap to the other from 8,062 to
   586,686 bytes.  Do not retry object reordering.  Function-level placement
   via a linker -T script remains untried but would be uninterpretable in
   this harness, which does not model unified-cache displacement.
   The Z-span x87 prologue (`d_draw.s:812-846`) is NOT worth porting.  An
   instruction count suggested 7.8% of frame; measured by duplicating the
   prologue into dead scratch it is 0.419 s, 0.71% of frame, 9.4 cycles/span.
   Do not resurrect the 7.8% figure.  The rewrite is also blocked: the
   prologue rounds to single precision after each of three float ops, so an
   integer replacement fails the checksum.  If pricing any hot sequence again,
   duplicate it into dead scratch and time the delta — that is bit-exact and
   cannot render anything wrong, unlike overwriting live output.
2. Texture spans remain ~26.2% self time (`out\dos-timedemo-20260911-184157`,
   diagnostic).  Dest rows now come from
   `viewspantable` in the 16/8-pixel drawers, polyset, sprites,
   particles, and live `Turbulent8`.  Live `D_RasterizeAliasPolySmooth`
   dest and Z rows use the same tables.  Keep the unrolled 16-pixel leaf; dword coalescing was
   noise and a compact stosb loop was ~2.8% slower.  Remainder t-zero
   IMUL skip and a per-surface source-row table both matched the
   checksum but lost end-to-end; do not retry those.  Do not revive
   the earlier checksum-failing texture-source row-lookup.  Do not
   retry a jump table around the turbulent last-segment divide.
   Do not retry a per-surface `d_drawspans == D_DrawSpans16`
   compare/direct CALL.  The start-address `cachewidth` IMUL sits in
   the FDIV shadow; do not add per-span branches to skip it.
   Do not retry `D_DrawSpans16` s/t integer CSE across the sfrac/tfrac
   shifts (`out\dos-timedemo-20260915-074041`; ~43 ms slower) or early
   `pnext` preload into `pspantemp` (`out\dos-timedemo-20260915-075512`;
   noise).  Do not retry `D_DrawSkyScans8` `viewspantable` dest rows
   (noise vs the aspancount default).  Do not retry FILD-overlapped
   v/u loads for dest setup.
3. Surface-cache rebuilds were ~14.5% at 600 KB.  The default cache is
   now 1800 KB; 1200 KB also matched the checksum.  1900 KB, 2000 KB,
   2100 KB, and 2400 KB all failed checksum `2955717646`.  Do not
   retry those sizes.  Do not add another predicate helper.  Static
   **(superseded 2026-09-29: those four sizes are correct — the failures
   were a confounded build. The default is now 2400 KB. Do not add
   another predicate helper still.)**
   textures now skip `R_TextureAnimation` and `r_drawsurf` stores on
   a hit, and unused extra light styles are skipped when
   `styles[1] == 255`.  No-dlight invert/clamp is fused
   into the lightmap write for 1--4 styles, and `R_AddDynamicLights` now
   uses an integer distance.  Per-column wrap uses AND on power-of-two
   widths.  Direct mip drawers were 1.1 ms slower end-to-end; leave
   `(*pblockdrawer)()`.  Live `surf8.s` mip0 already uses `movl` dest
   packs; `block8.h` is unused.    Rebuild setup now skips the 16-bit
  `r_pixbytes` path and reuses `r_stepback` for `r_sourcemax`.
  Do not retry folding the soffset wrap into the column-loop POT test.
  Rebuilds no longer compute unused `surfscale` / `cache->mipscale`.
  Do not skip storing `blocksize`; the 8-bit column loop uses it for
  `soffset`.  Do not retry a local `mip` for `R_DrawSurface` setup.
  `R_MarkLights` now applies the `R_AddDynamicLights` plane reject and an
  O(1) clamp-to-rect idist cull (replacing the earlier `fmin` AABB expand).
  Do not retry a full per-sample MarkLights scan; phantom faces would pay
  the nested loop.  Do not retry a 2x2 discrete sample scan in
  `R_MarkLights`; it matched the checksum but was 112.5 ms slower.
  Do not retry an `R_AddDynamicLights` s/t sample-window clamp; it failed
  checksum `696680082`.  `cache->dlight` now tracks real sample adds via
  `r_dlight_contributed`.  Marked frames with a clean cache also probe
  `R_DlightContributes` before rebuilding.  Surface rebuild skips from the
  continuous-vs-discrete MarkLights gap are largely exhausted; do not add
  another surface-cache predicate helper or revive MarkLights sample scans /
  dlight loop windowing.
4. Alias leftover is now narrower polyset raster guts after the
   once-per-call `advancetable`/`tstep` hoist and left-edge s/t step CSE
   in `D_RasterizeAliasPolySmooth`.  RecursiveTriangle keeps live
   `new[0]`/`new[1]` through the pixel leaf, defers `lp2[0]` until
   equal-`y`, defers next-edge prefetches past `|dy|` split tests, and
   defers same-edge y loads past `|dx|` early-outs.  Aff8 leaves and
   FinalVerts use `movzbl` for the colormap index / skin texel.
   DrawSubdiv defers `d_pcolormap` until after the backface cull.
   Aff8 one-long defers `ptex` until after Z.
   Keep direct `addl C(a_sstepxfrac)` in the pixel loop; do not retry
   BSS `sstep` for that constant (`out\dos-timedemo-20260914-183707`;
   matched checksum but ~9 ms slower).  Do not retry local copies of
   right-edge Bresenham constants (`erroradjustup`/`down`, `ubasestep`,
   `d_countextrastep`) in the span prologue
   (`out\dos-timedemo-20260914-184757`; ~37 ms slower).
   Do not retry stack-live `d_aspancount`/`errorterm` for the outer
   `D_PolysetDrawSpans8` right-edge loop
   (`out\dos-timedemo-20260915-065310`; ~37 ms slower).
   Do not retry `d_ptexextrastep` via `a_ststepxwhole` with carry
   adjust/branches (`out\dos-timedemo-20260915-053730`; ~76 ms slower);
   keep `(sextra>>16)+(textra>>16)*skinwidth`.
   `D_PolysetDrawFinalVerts`
   hoists the viewmodel clip edges; C keeps the same locals as the live ASM.
   `D_RasterizeAliasPolySmooth` uses `viewspantable`/`zspantable`.
   `D_PolysetSetUpForLineScan` uses a 64x64 `adivtab` (`[-31,32]`); do not
   grow further without a timedemo win (D-cache cost).
   Do not retry an `AngleVectors` cache.
   Do not retry a branched POT skinwidth shift in `D_PolysetCalcGradients`.
   Do not retry hoisting `aliasvrect` locals in `R_AliasPreparePoints`.
   Do not retry hoisting `aliasvrect` / skipping Z reflag in `R_AliasClip`
   (`out\dos-timedemo-20260914-181813`; matched checksum but ~42 ms slower).
   Do not retry `movzbl` expansion in `R_AliasTransformAndProjectFinalVerts`.
   Do not retry fused `minmaxs` multiplies in `R_RecursiveWorldNode`.
   Do not retry stacking `acolormap` in `D_PolysetDrawFinalVerts`.
   Do not retry a last-used `D_CalcGradients` step-origin cache.
   Per-frame mipscale × `xscaleinv`/`yscaleinv`/`0x10000` tables are
   the kept substitute.  Do not retry precomputing
   `transformed_modelorg × mipscale` on world/bmodel switch.
   World faces now hoist `surfedges` and unroll the four clip-plane
   links in `R_RenderFace`.  Clipped bmodels hoist the same `surfedges`
   pointer.  Do not retry unrolling `R_RenderBmodelFace` clip planes.
   Do not retry hoisting `currententity->model` in `R_RenderFace`.
   Do not retry hoisting `r_pcurrentvertbase` in `R_RenderFace`.
   2026-10-02, added after pricing the pool rather than assuming it: **do not
   retry hoisting the duplicated `edge_p - r_edges` in `R_RenderFace`.** `-O3`
   already CSEs both loads and leaves exactly one duplicated `sub`, so the
   whole candidate is ~0.9x the gate -- confirmed by `objdump -dr`, no build
   needed. **And do not re-open `renderface` as a large pool**: two C
   dead-scratch probes price its C scaffolding at **~15.8x the gate**
   (per-edge validation ~11.5x, per-call prologue ~4.3x) against the 70-90x the
   entry at `:1743` estimated. The remainder of its 221x is the `R_ClipEdge` /
   `R_EmitCachedEdge` calls, which is essential x87 edge emit and inadmissible
   under Decision 1. See "renderface priced" at the top of this file.
   Related and general: **do not price a C candidate by instruction count alone.**
   The 1.0 cycle rate is a dependency property -- nine assembly loops measure
   0.974-0.996, one straight-line C mix 0.5439 and one serialised C mix 1.1917.
   Screen C at 1.0 if you must, then measure before believing it.
   **(2026-10-03, and this is much bigger than the ±40% for C. A twelfth probe
   now shows the 1.0 rate measures the cost of ADDING work, not the value of
   REMOVING it: 4 instructions of the same shape added to the span16 setup cost
   +0.4112% at 0.988 cycles each, and 4 instructions of that same shape removed
   from the identical path returned 0.0000% against a 4.1x-gate prediction. See
   the clamp-fusion entry at the top of this file. So: **a model-priced rejection
   is not evidence that a candidate is slow, it is evidence that nobody built
   it** — the error is one-way and always in the direction of over-pricing, and
   the only validated removal prediction in the repo is the mip-1 index hoist's
   2% agreement. Do not re-close a pool on an instruction count.)**
   Do not retry length-1 or POT remainder in `R_AnimateLight`.
   Do not retry skipping no-op bmodel Restore/Set CALLs with extra
   per-surface ifs.  Do not retry duplicating world surface loops to
   hoist `r_drawpolys`.  Do not retry `skintable` start addressing in
   `D_RasterizeAliasPolySmooth`.     Do not retry a `D_PolysetScanLeftEdge`
   skinwidth stack hoist (`out\dos-timedemo-20260915-061218`; ~10 ms
   slower).  `D_PolysetScanLeftEdge` keeps `d_pedgespanpackage` in `%esi`
   and live `d_pdest`/`d_pz` in `%edi`/`%ebp` (light/zi/aspancount on
   stack), publishing the package pointer and writing back
   `d_aspancount` once on exit.  Do not restore the discarded package
   pretouch `movb`.  Z spans use `zspantable`
   and keep the span list in `%ebp` (no per-span push/pop of the list
   pointer); keep the count `pushl`/`popl` for the odd pixel.  Do not
   retry tagging `%ebp` bit0 to drop that count stack traffic
   (`out\dos-timedemo-20260915-060125`; ~65 ms slower).  Do not retry
   stack-hoisting `erroradjustup`/`down` or `errorterm` beside the
   kept aspancount spill in `D_PolysetScanLeftEdge`.  Do not retry
   `D_DrawSpans16` s/t integer CSE across the sfrac/tfrac shifts, early
   `pnext` preload into `pspantemp`, or `D_DrawSkyScans8`
   `viewspantable` dest rows (noise or slower).  Edge scan keeps the
   `Lgs_leading` `surfaces` CSE and TrailingEdge direct-`%ecx` unlink;
   `R_EmitEdge` loads `edge_p`/`r_pedge` only after the horizontal early-out
   (`leal` next pointer) and omits the unused fully-clipped `r_pedge` load;
   TrailingEdge uses memory `decl` for `spanstate`, skips `r_bmodelactive`
   when `insubmodel==0`, and uses `decl`/`incl` memory forms for bmodel
   enter/leave.  Leading non-inverted paths store `movl $1` for spanstate.
   Look for other dead reloads carefully before adding stack traffic.
   Do not revive BSP plane-dot/clip helpers.
   Face Z gradients are cached.

## Current implementation result

The current pass keeps the dynamic-light S-axis accumulator, the
`currententity`-keyed face Z-gradient cache, and changes `WinQuake/r_bsp.c`
to test a node's `visframe` before `CONTENTS_SOLID`, while both world-node
surface loops test `visframe` before the backface flag.  Predicate semantics
and recursion are unchanged.  In
`WinQuake/d_draw.s`, spans whose fixed-point `izistep` is zero now reuse the
same initial-Z/clamp calculation and fill the 16-bit depth words with
`rep stosw`; the normal positive/negative gradient paths are unchanged.  The
five-run node-order-plus-zero-step sample was `61.556987`, `61.556783`,
`61.556720`, `61.556934`, and `61.556789` seconds (969 frames and framebuffer
checksum `4154140932` each run), for a median `61.556783 s / 15.741564 FPS`
versus the committed zero-step baseline `61.559877 s / 15.740772 FPS`.  The full
`bench-dos.ps1` run reported `486 benchmark correctness PASS` with harness
checksum `2378409472`, and the smoke test passed.  In `WinQuake/d_polysa.s`,
the subdivided alias backface cull now uses the same 32-bit integer determinant
as `D_DrawNonSubdiv`, avoiding the x87 round trip for integer screen
coordinates.  The three-run candidate sample was `61.878873`, `61.496626`,
and `61.496717` seconds (969 frames and framebuffer checksum `4154140932` on
each run), for a median `61.496717 s / 15.756939 FPS`; the full correctness
harness also retained checksum `2378409472`.  The follow-up five-run sample
restoring `%edi` from the stable `r_affinetridesc.pfinalverts` field instead of
using a per-triangle stack pair was `61.487631`, `61.487324`, `61.487423`,
`61.487373`, and `61.487350` seconds, again with framebuffer checksum
`4154140932` on every run, for a median `61.487373 s / 15.759333 FPS`.
The follow-up Z-span first-pair `shldl`/`rorl` packing in both gradient signs
measured `60.901914`, `60.901634`, and `60.901646` seconds, with the same
969-frame framebuffer checksum on every run, for a median
`60.901646 s / 15.910900 FPS`.  The full correctness harness retained
checksum `2378409472`, and the rebuilt normal binary passed the DOS smoke test.

## Starting commands

Use a local, legally obtained `id1` directory containing `pak0.pak`:

```powershell
.\tools\build-dos.ps1 -Clean -Benchmark -NoBootstrap
.\tools\bench-dos.ps1 -SkipBuild -AliasTransformFinalOnly
.\tools\smoke-dos.ps1 -SkipBuild `
  -TimeoutSeconds 90
.\tools\timedemo-dos.ps1 -Runs 3
```

For the direct C/ASM transform A/B, build each selected benchmark executable
and run the focused command with the matching selector:

```powershell
.\tools\build-dos.ps1 -Clean -Benchmark `
  -AliasTransformFinalImplementation c -NoBootstrap
.\tools\bench-dos.ps1 -SkipBuild -AliasTransformFinalOnly `
  -AliasTransformFinalImplementation c
.\tools\build-dos.ps1 -Clean -Benchmark `
  -AliasTransformFinalImplementation asm -NoBootstrap
.\tools\bench-dos.ps1 -SkipBuild -AliasTransformFinalOnly `
  -AliasTransformFinalImplementation asm
```

The relevant source entry points are
`R_AliasTransformFinalVert` and
`R_AliasTransformFinalVert_asm486` in `WinQuake\r_alias.c` and
`WinQuake\asm486_experiments.s`.  Use `WinQuake\host_cmd.c` for the focused
benchmark harness and `tools\profile-report.ps1` for profile JSON.