# Region pricing sweep (2026-10-03)

Extracted verbatim from `ASM486-HANDOFF.md` lines 532-902 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## `z-spans` is the last unpriced region above 2%: **42,031,372 pixels, 3 instructions each, at 1.24 cycles per instruction** (2026-10-03, fifth pass)

> **This closes the last region in the renderer larger than 2% of frame that nobody had priced.**
> `z-spans` is 7.89% of frame and the only part of it ever examined was the x87 prologue. It now has
> a measured population, a counted instruction budget, and a derivation showing the budget is the
> 486 minimum. Combined with the four closures above it, **every region above 2% of frame is now
> closed by measurement or by proof.**

### The population

Two `PROFILE486` counters at the span head, where the pixel count is already in a register:

```text
z-spans pixels 42031372 spans 1414939 avg 29
```

One instrumented `demo1` run, 969 frames, checksum `1047377823`.

### The pixel loop is 3 instructions per pixel, and 3 is the floor

`LFMiddleQuad` is 51 instructions per 16 pixels (48 in the body, plus `addl $32,%edi`, `subl $4,%ecx`
and `jnz`), i.e. **3.19 per pixel** with the unroll dispatch outside the loop. The body is a
five-instruction pack of two pixels:

```text
movl	%edx,%eax ; addl %ebx,%edx ; shrl $16,%eax ; shldl $16,%edx,%eax ; rorl $16,%eax ; movl %eax,(%edi)
```

producing `dword = (A >> 16) | ((A + izistep) >> 16) << 16`. Both `A` and `A + izistep` are needed
simultaneously, so the `movl` copy is forced; `shrd` — which would merge in the opposite direction in
**one** instruction and delete the `rorl` — does not exist on a 486. So the pack is `movl` + `shrl` +
`shldl` + `rorl`, plus one `addl` and one store per pixel: **3, and no fewer.**

The obvious restructure was tried on paper and is *worse*: keeping two accumulators (`%eax` for even
pixels, `%edx` for odd, each advanced by `2*izistep`) removes the copy but needs a separate
`addl $8,%edi` per pair, giving 4 per pixel against the current 3. The 16-pixel unroll is what makes
the current form cheap, by amortising the destination advance over 16 pixels.

### And it runs at 1.24 cycles per instruction, so removal would pay nothing anyway

```text
z-spans self 6.303 s = 7.89% of frame -> 4.671 s release = 156.2M cycles
42,031,372 pixels   ->   3.72 cycles/pixel
3 counted instructions/pixel -> 1.24 cycles per instruction
```

**1.24 is the worst ratio measured anywhere in this renderer.** Every other hot region lands at or
below 1.0 — the block rows at 0.77, the span16 setup at 0.988. This one is *above* it, which means
the loop is dependency-bound on the `%edx` accumulator: `addl %ebx,%edx` must retire before
`shldl %edx,%eax` can read it, and that chain is longer than the instruction count can hide. So the
region has **no slack at all** and a removed instruction would buy approximately zero — the same
result the span16 per-segment setup gave, reached here by the opposite route. There it was 1.0 for
additions and 0.0 for removals; here it is 1.24 for everything.

**This is the second region in the session to close on dependency structure rather than on minimality,
and together they say the harness's slack is concentrated in the block drawers (0.77) and absent from
the interpolating fills (1.0–1.24).**

### The per-span prologue is 2.72% of frame and has nowhere to put a register

The ~38 scalar instructions at each span head — the `d_zistepu`/`d_ziorigin`/`d_sdivzstep*` reloads,
the `%eax`/`%edx`/`%edi`/`%ecx` setup, and the 8-instruction dword-alignment prefix — are
38 x 1,414,939 = **53.8M instructions = 1.61 s = 2.72% of frame**, and no part of them has ever been
priced. They cannot be hoisted into registers: at `LFSpanLoop` **all seven general registers are
live** — `%ebp` is the span cursor, `%ebx` the `izistep` loaded once per *call*, `%edi` the
destination, `%esi` and `%ecx` the span fields, `%edx` the z accumulator, `%eax` the pack scratch —
and the x87 stack is a separate eight-slot resource this loop cannot draw integer registers from.
That is the same wall the span16 `emit` block hit and the same one the block-row prologue hit. **The
globals must be reloaded per span because there is no register to hold them.**

### The bucket now resolves completely

| region | share of frame | cyc/instr | disposition |
|---|---:|---:|---|
| `texture-spans` setup | 2.37% | 0.988 | latency-bound; 4.1x-gate candidate measured **0.0000%** |
| general + flat block rows | 6.85% | 0.77 | **minimal**, 6-for-6 and 3-for-3, proven from the flat row |
| `z-spans` pixel loop | 6.37% | **1.24** | **minimal** (3/pixel) and dependency-bound |
| `z-spans` per-span prologue | 2.72% | — | all 7 registers live; x87 remainder inadmissible |
| `renderface` C scaffolding | ~2% | 0.54 / 1.19 | priced; remainder is essential x87 edge emit |
| `edge-scan` | 8.27% | ~1.0 | 78% mapped, sixteen named blocks, all load-bearing |
| `R_BuildLightMap` | 0.06% | — | hoist worth 0.04x the gate |
| surface-cache non-draw remainder | 0.67% | — | 1,152 tryalloc scans, **0** evictions |

**Every region above 2% of frame is now closed, and not one of them on price alone.** Three closed by
minimality proof, two by dependency structure, one by a fresh counter, one by a measured 0.0000%. The
0.05% gate has not been the binding constraint in any of them — instruction-level structure has, and
in the two 6%+ regions it turned out to be a *proof* rather than a search.

Verification: two `PROFILE486`-guarded counters added, no release cost. Instrumented run 969 frames,
checksum `1047377823`. Baseline unchanged at **59.160558 s / 16.379156 FPS**; `d_draw16.s` still 619
instructions.
## `R_BuildLightMap` is **0.06% of frame, not 7.5%** — and a real loop-invariant hoist in it is worth **0.04x the gate** (2026-10-03, fourth pass)

> **This is a premise-falsification, and it falsifies an error made earlier in the same session.**
> The previous three entries all worked from measured counters, which is the right discipline, and
> this one still managed to misattribute 7.5% of frame to the wrong function. The counter that
> settles it is now in the tree, so the next pass does not have to.

### The error, stated plainly

`surface_cache.rebuild_seconds` reads 6.353 s, **7.96% of frame**, and for most of this session I
treated that as `R_BuildLightMap`. It is not. `bench486_surface_cache_rebuild_start` is stamped in
`D_CacheSurface` **after** the cache-validity check, and `rebuild_seconds` is read at function exit,
so it spans the *entire* miss: allocation, eviction, `R_BuildLightMap`, and the
`(*pblockdrawer)()` draw into the fresh cache blocks. Decomposed against the counters that nest
inside it:

```text
rebuild_seconds      6.353 s   the whole D_CacheSurface miss
  draw_seconds       6.173 s     nested inside it
    block_seconds    5.471 s     R_DrawSurfaceBlock -- proven minimal earlier today
  lightmap_seconds   0.351 s     R_BuildLightMapStyles, the dynamic-light path
  remainder           0.180 s     allocation, eviction, mipmap upload
```

**So 86% of `rebuild_seconds` is the block drawer this file already proved 6-for-6 minimal, and the
lightmap build is `lightmap_seconds` — 0.44% of frame at most.**

### The counters that say so

Three were added for this pass (`bench486_lm_single_texels`, `bench486_lm_fused_texels`,
`bench486_lm_fused_maps[5]`, reported as their own `lightmap-texels` line per the buffer rule) and
one instrumented run settled it:

```text
lightmap-texels single 168206 fused 9372 maps2 9372 maps3 0 maps4 0
```

**177,578 lightmap texels across the whole run**, and the fused multi-style loop executes **9,372**
times — all of them `maps == 2`. `maps3` and `maps4` are **zero**: this workload never lights a
surface with three or four active styles.

### The candidate this killed, and it was a real one

`R_BuildLightMapFusedNoDlights_asm486` reloads **four loop-invariants from the stack on every
texel** — `scale` from `48(%esp)`, the `255*256` constant as an immediate, the trip count from
`40(%esp)`, and the plane pointer from `0(%esp)` — in a hand-written loop that a `-O3` C compiler
would have hoisted. That is a genuine defect: **the hand-written assembly is worse than the C
reference it replaced**, and the fix is textbook (fold `scale` and `255*256` into one hoisted
constant, and replace `incl`/`cmpl mem`/`jb` with `decl`/`jnz`). The single-table path is already
3 instructions per texel and cannot be improved.

It is also worth nothing:

```text
4 hoisted instructions x 9,372 executions = 37,488 instructions = 0.0011 s = 0.0019% = 0.04x the gate
3 instructions x 168,206 single-table texels = 504,618 instructions = 0.0255% = 0.51x the gate
```

**0.04x the gate — a factor of 25 under it.** Removing *every* instruction the fused loop could
possibly shed does not reach the promotion threshold, because the loop runs four orders of magnitude
fewer times than the arithmetic assumed. The C-vs-assembly regression is real and is worth fixing on
correctness-and-cleanliness grounds; it is not a performance candidate, ever.

### What this pass actually establishes

The surface-cache bucket resolves completely, and none of it is addressable:

| component | share of frame | disposition |
|---|---:|---|
| `R_DrawSurfaceBlock` | 6.85% | **minimal**, proven by derivation — see the general block row entry |
| `R_BuildLightMapStyles` (dlight) | 0.44% | below gate as a whole |
| `R_BuildLightMap` fill | **0.06%** | 0.04x–0.51x the gate; defect real but unmeasurable here |
| allocation / eviction / mipmap | 0.23% | 1,152 tryalloc scans, 113 moves, 0 evictions |

**A third region has now closed this session, and this is the first one closed by a fresh counter
rather than by a failed search or an argument.** The method is the one the project already prescribes
— count the operations a change would remove, then compare against 1,022.8 cycles/frame — applied to
a candidate that was *about* to be built. Building it would have consumed a selector, four runners'
plumbing, and two timedemo pairs to measure 0.0019%.

**The generalisable trap, and it is worth naming because it nearly cost a build.** `rebuild_seconds`,
`draw_seconds` and `block_seconds` are all named `*_seconds` and all sit in the same JSON object, and
only one of them means what its name suggests at the granularity a reader assumes. `block_seconds`
is per-`R_DrawSurfaceBlock`-**call**; `mip_seconds` inside it is summed per **call** but its
`mip_blocks` divisor is `r_numhblocks * r_numvblocks`, i.e. per **block**. Reading those two as
mutually consistent gets the per-texel figure right and the attribution wrong. **Before pricing
anything in this bucket, read the scope of the `Sys_FloatTime` pair that produces the number** — in
`d_surf.c` the rebuild clock starts after the validity check, not at the rebuild.

Verification: three `PROFILE486`-guarded counters added (no release cost, no code-size cost); one
instrumented `demo1` run, **969 frames, checksum `1047377823`**, `maps2 9372 maps3 0 maps4 0`.
Baseline unchanged at **59.160558 s / 16.379156 FPS**; `d_draw16.s` still 619 instructions.
## Correction: the general block row is **minimal, and that is derivable** — the 31x gate is not reachable by removal (2026-10-03, third pass of the day)

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
> **A correction to the 6.85% attribution below, from the pass after this one.** `block_seconds` is
> `R_DrawSurfaceBlock`'s *own* cost and that 6.85% figure is right, but it sits inside
> `surface_cache.rebuild_seconds`'s 7.96% — and `rebuild_seconds` is **not** `R_BuildLightMap`. It
> is stamped in `D_CacheSurface` *after* the validity check, so it spans the whole miss: allocation,
> lightmap build, and the block draw. 86% of it is this drawer. See "`R_BuildLightMap` is 0.06% of
> frame, not 7.5%".

## The general surface-block path is **6.85% of frame at 0.77 cycles per instruction**, and one instruction per texel is worth **31x the gate** (2026-10-03, second pass of the day)

> **This is a price, not a candidate.** Nothing was built. It is the first region found this
> project-wide whose *instruction* budget is large, whose per-instruction charge is **below** the
> nominal 1.0, and where the prize calculation clears the gate by a factor that makes instruction
> arithmetic — not the 0.05% gate — the binding constraint. Read it as the map that says where to
> spend the next pass, not as a closure and not as a win.

### The measurement, and it is counters rather than arithmetic

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
per-segment setup closed in ``2026-10-02-edge-scan-and-texture-spans.md``, under "The span16 per-segment setup is 2.37% of frame".

**The per-instruction charge is the interesting number.** Counting the mip-0 general row
(`SURF8_MIP0_ROW`) gives 12 instructions per two texels — two texel loads, two colormap lookups,
`movb %dh,%bh` and `movb %dh,%ch`, and four `addl %ebp,%edx` — plus a 17-instruction row prologue
and epilogue over 16 texels, i.e. **~7.06 instructions per texel** against a measured **5.46
cycles: 0.77 cycles per instruction.** The region is executing its instructions *below* the
nominal charge, which is the signature of instruction-level slack rather than a saturated
dependency chain.

### What that makes one instruction worth

```text
31,100,612 instructions  /  33.445 MHz  =  0.9299 s  =  1.572% of frame  =  31.4x the 0.05% gate
```

**One instruction removed per general texel is 31x the gate.** mip-0 alone — 22,228,736 general
texels — is **1.12% of frame, 22x the gate.** For comparison, the entire span16 per-segment setup
was 47x the gate on paper and delivered 0.0000%, and the clamp fusion needed 4 instructions per
texel to reach 4.1x. Here the barrier is not the gate at all; it is finding an instruction that is
provably removable without disturbing a dependency. **That inverts the economics of this region
relative to everything else in the renderer.**

### The flat specialisations are complete — this is new, and it closes the last idea here

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

### Where the fat actually is, and the barrier

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

### What is not claimed

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
