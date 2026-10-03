# `edge-scan`, `renderface` and `texture-spans` (2026-10-02)

Extracted verbatim from `ASM486-HANDOFF.md` lines 1066-1358 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## `edge-scan` decomposed by dead-scratch probe — pass 1 of 2 (2026-10-02): six probes, and **the closure below was half wrong**

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

Decision 3 (`docs/OPTIMIZATION-PLAN.md`, under "Decision 5") says to price at 1.0 unless the removed instructions include memory operands, "in which case **0.66 is the measured rate for that mix**". **Six fresh measurements do not support any rate
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

## The per-edge dispatch remainder, decomposed (2026-10-02, second pass) — `edge-scan` is now 78% mapped and the "115x unmeasured" is closed

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

## `renderface` priced (2026-10-02) — **CLOSED with a price**, and the 1.0 cycle rate is not a constant

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

## The span16 per-segment setup is 2.37% of frame and contains no x87 at all — **`texture-spans` is re-opened**

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
   > **CORRECTED and then MEASURED, 2026-10-03 — see ``2026-10-03-clamp-fusion-and-the-1.0-rate.md``, under "The clamp fusion is measured at **0.0000%**". Two separate errors, in this order.** (a) The "Four for four" arithmetic is wrong: `leal -4096(%ebp),%eax` puts the biased value in the scratch register in **one** instruction, so the clamp really is 3-for-4, and no register needs freeing anywhere else. The candidate was therefore buildable, and was built. (b) It then **measured 0.0000%** against a 0.206% model prediction — 4,118,036 instructions removed bought 12 microseconds — while a probe adding four instructions of the identical shape into the identical path was charged **0.988 cycles each**. **The candidate is dead, but not for the reason recorded here, and the "worth re-attempting if a register can be freed" advice is dead with it. Do not rebuild it.** What survives from this item is the general form of the mistake: a scratch register does not have to be *moved* to and then modified. Re-read every closure in this file resting on a register move costing what a transformation saves.
3. **Drop the `fistpl snext` / `fistpl tnext` / `movl snext,%eax` / `movl tnext,%edx` sequence in `LSpan16`/`LSpanLoop`.** Architecturally impossible: `FIST` has no register destination on a 486, it only writes memory, so the store-then-reload is forced.
4. **Widen the segments to amortise the setup.** The A/B halves already amortise the expensive x87 advance — `LSpan16AfterStoresA` does `LSetupNotLast2` (x87 only) and falls straight into the B stores with **no integer setup between them**. The measured 2,059,018 setup executions are the ground truth and nothing in this structure reduces them.

**So: a 47x-gate pool, and no candidate.** The honest position is that the setup is ~23 necessary instructions of DDA — advance s/t, derive the two advance-table entries from the position within the span, left-justify the fractions, accumulate, and select the T carry. That is not the same as saying no candidate exists, and it is a much better place to look than anywhere else in the renderer.

**Do not close `texture-spans` again on the x87 argument.** If it is re-closed, re-close it on a measurement.

> **And do not close it on instruction count either — that is what the 2026-10-03 pass measured.** Candidate 2 above was built, correctly and bit-exactly, and returned **0.0000%** while a probe proved the region charges 0.988 cycles per instruction *added*. The region is not reachable by removing instructions at all; it is dependency-bound. The only door is shortening the loop-carried chain, and no one has yet produced a hypothesis for that. See ``2026-10-03-clamp-fusion-and-the-1.0-rate.md``, under "The clamp fusion is measured at **0.0000%**".

Verification: `-SpanSetupProbe control` assembles `d_draw16.o` to **619 instructions, zero disassembly differences** from the pre-probe object. Baseline **59.160569 s** median over three runs against the recorded 59.160558 s — 0.00002%, noise. Checksum `1047377823` on every run, `bench486` PASS with end checksum `2378409472`, DOS smoke clean, 969 frames. Probe plumbing added to all four runners; default `control`.

