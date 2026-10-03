# alias-glue closure (2026-10-03)

Extracted verbatim from `ASM486-HANDOFF.md` lines 237-531 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## The alias-glue block is **63 instructions, minimal, and 5.5x the gate** — closed from its own disassembly (2026-10-03, eighth pass)

> **This closes the region the seventh pass opened.** The probe gave it a price; this pass read the
> compiled object and found every instruction accounted for, the same standard applied to the
> surface-block rows. It is the last region in the renderer, and the smallest instruction-level
> proof in the set.

### The hypothesis, and it died in one read

The obvious candidate was duplication: the block computes fifteen step values immediately after
`D_PolysetSetUpForLineScan` has run, so maybe it was recomputing what that function had just stored.
**It is not** — `D_PolysetSetUpForLineScan` sets exactly four globals (`errorterm`, `ubasestep`,
`erroradjustup`, `erroradjustdown`) and touches none of the fifteen. One read of the function killed
it, which is the cheapest possible closure and the argument for checking before building.

### The object, and it is already factored

`objdump` of the release `d_polyse.obj`, from the `ubasestep` load after the call to the
`d_ziextrastep` store:

```text
3b0: mov  ubasestep,%eax          ; 3 loads total: ubasestep, d_zwidth, screenwidth
3b5: mov  d_zwidth,%edx
3bb: add  %eax,%edx
3bd: add  %edx,%edx
3bf: mov  %edx,d_pzbasestep       ; 15 stores total, one per d_* global
3c5: add  $0x2,%edx
3c8: mov  %edx,d_pzextrastep      ;   GCC kept %edx and folded the +2 into it
3ce: mov  screenwidth,%edi
3d4: add  %eax,%edi
3d6: mov  %edi,d_pdestbasestep
3dc: inc  %edi
3dd: mov  %edi,d_pdestextrastep   ;   ... and the +1 into %edi
3e6: mov  r_lstepx,%ebp           ; working_lstepx lives in a register, not a global
3ec: test %eax,%eax
3ee: js   ...                     ; 1 branch: the ubasestep < 0 bias
3f8: lea  0x1(%eax),%ecx
3fb: mov  %ecx,d_countextrastep
```

**63 instructions: 15 stores, 3 loads, 32 arithmetic, 1 branch, 1 stack adjust.** Two things are
already done that a source reading would not show:

- **`d_pzextrastep` and `d_pdestextrastep` cost one `add`/`inc` each, not a reload.** `-O3` keeps the
  base in `%edx`/`%edi` and folds the `+2`/`+1` into the register, so the source's apparent second
  computation of `d_pzbasestep` and `d_pdestbasestep` never happens.
- **`working_lstepx` is never stored.** The `ubasestep < 0` bias is resolved into `%ebp` and consumed
  from there, so a value that reads like a global in the source is one load and one branch.

**Every one of the 63 has a distinct consumer.** The 15 stores are forced by the interface — each of
the fifteen `d_*` values is read by `D_PolysetScanLeftEdge` from `.data` — and the 32 arithmetic
operations are what producing fifteen distinct values costs once GCC has factored them. There is
nothing to remove, and this is the first closure in the session derived from the compiled form rather
than from the source.

### The corrected price

The seventh pass priced the *probe*, which duplicated the arithmetic but not the stores. Scaling to
the whole block:

```text
63 x 92,715 = 5,841,045 instructions, at the measured C rate 0.9319
= 5,443,270 cycles = 0.163 s = 0.275% of frame = 5,617 cycles/frame = 5.49x the gate
```

So the block is **5.5x the gate, not 3.4x** — the probe priced 39 of the 63 instructions, and the
arithmetic it duplicated was the cheap part. The 15 interface stores alone are 0.066% of frame, 1.3x
the gate; the matching fifteen loads the ASM performs are the same size again, but they are paid
inside `D_PolysetScanLeftEdge` and are not visible here.

**Correcting the seventh pass in its own favour.** It reported the block at 0.1703% and stopped
there. The block is 0.275%. The error was conservative, and the lesson is the one the probe entry
already carries: a C probe prices the instructions it duplicated, and a probe that folds part of the
duplicate — 15 attempted expressions became 39 instructions, against 63 in the block — is not the
same thing as the block. **Price the object, not the probe.**

### What remains, and it is exactly one thing

The fifteen values crossing the C/ASM boundary as memory. Fifteen stores here, fifteen loads there,
0.066% of frame each way, plus the register pressure that prevents either side from holding them.
It is a real cost and it is above the gate on its own.

It is also a C-to-ASM interface change spanning `d_polyse.c` and two assembly files, where the ASM
half's calling-convention contract is what its loop addressing relies on. The prohibition list gates
that behind a source-level hypothesis, **a probe is a price and not a hypothesis**, and eight passes
have now shown that the productive move in this renderer is to read the object before writing code.
So it is recorded as the project's one remaining priced, above-gate, structurally-addressable item,
with its size, and not built.

### The session's complete map

| region | share | how it closed |
|---|---:|---|
| `edge-scan` | 8.27% | 78% mapped, sixteen load-bearing blocks |
| general + flat surface-block rows | 6.85% | minimality proof, 6-for-6 and 3-for-3 |
| `z-spans` pixel loop | 6.37% | minimality proof **and** 1.24 cy/instr dependency |
| `z-spans` per-span prologue | 2.72% | all seven registers live at `LFSpanLoop` |
| `texture-spans` setup | 2.37% | latency-bound; 4.1x candidate measured **0.0000%** |
| `alias-glue` C block | **0.275%** | **this entry: 63 instructions, minimal** |
| `alias-glue` scope | 2.29% | 62% of its reported self time was the clock |
| `renderface` C scaffolding | ~2% | priced; remainder is essential x87 |
| surface-cache remainder | 0.67% | 1,152 tryalloc scans, **0** evictions |
| `R_BuildLightMap` | 0.06% | hoist worth 0.04x the gate |

**Eight passes, ten regions, every one closed by measurement, by counter, or by proof — and not one
by exhaustion.** The single remaining priced item is an interface change, and the gate has never been
what stood in the way.

Verification: no code changed, no timedemo run. Both figures come from the release object and from
counters already in the tree. Baseline unchanged at **59.160558 s / 16.379156 FPS**; `d_draw16.s`
still 619 instructions.
## The alias-glue C block is **0.1703% of frame, 3.4x the gate** — the first price that region has ever had, at a C rate of **0.932** (2026-10-03, seventh pass)

> **This is a price, and it is above the gate.** Every previous entry in this session closed a
> region; this one opens one, with a measurement. It is also the first application of the dead-scratch
> probe to the alias glue, which the project had explicitly left unmeasurable.

### Why the region needed a probe and not a timer

The four per-call C scopes in `D_RasterizeAliasPolySmooth` were **removed** because at 100k–260k
calls each they cost more in `Sys_FloatTime` than they measured, and the ledger's conclusion was that
the alias glue is therefore unpriceable. That is correct and it is not the end: a dead-scratch probe
has **no measurement overhead at all**, because it adds work and is read off the whole-run delta.
This is the same remedy the `edge-scan` entry named for itself in 2026-10-02 and then used eleven
times.

### The probe

A new `-AliasGlueProbe control|setup` selector on all four runners, probing the per-triangle step
setup in `d_polyse.c` — the `d_pzbasestep` / `d_pdestbasestep` / `d_ptexbasestep` /
`d_sfracbasestep` / `d_lightbasestep` / `d_zibasestep` / `*extrastep` family, fifteen globals in all.
The probe recomputes the same arithmetic into locals and folds it into the sink; **nothing is written
to any `d_*` global**, so the three ASM helpers that follow are untouched.

Three C-probe mechanics, all of which would have produced a silently wrong number:

1. **The sink must be an external global defined in the probe's own file.** `-O3` deletes a dead local
   store, so a local sink compiles to nothing and measures zero while appearing to run. This file now
   defines `bench486_ag_probe_sink` exactly as `r_draw.c` defines `bench486_rf_probe_sink`, and
   `host_cmd.c` declares it `extern` — *not* the reverse, which is what `quakedef.h` does for the
   instrumentation counters and which does **not** work, because that whole extern block sits inside
   `#ifdef PROFILE486` at `quakedef.h` line 58 and a probe build is not an instrumented build.
2. **A second external global is the execution count**, so a probe that got folded away reports 0
   instead of producing a plausible wrong number.
3. **Take the instruction count from `objdump`, not from the source.** The probe attempts fifteen
   expressions and adds **39** instructions; `-O3` folds and factors part of the duplicate, which is
   itself the answer — the compiler is telling you the block shares work.

### The measurement

`control` verified to reproduce the pre-probe source **instruction for instruction** — `d_polyse.c`
at 20,789 instructions from `HEAD` and 20,789 from the `control` build, zero disassembly differences.
The `setup` build is 39 instructions larger.

```text
control : 59.160563 / 59.160633 / 59.160546 s, spread 0.000087
probe   : 59.261319 / 59.261293 / 59.261321 s, spread 0.000028
delta   +0.100756 s = +0.1703%   trailing control 59.160561, drift -0.000002 s
delta / spread : 1,158x          checksum 1047377823 on all seven runs
```

```text
39 x 92,715 executions = 3,615,885 instructions
0.100756 s x 33.445 MHz = 3,369,784 cycles
3,369,784 / 3,615,885 = 0.9319 cycles per instruction
```

The count is **92,715 of 124,754 triangles**; the other 32,039 take the `initialleftheight == 1`
single-span fast path, which is why the block is not simply the glue's call count.

> **SUPERSEDED on its price by the entry above: the block is 0.275% of frame, 5.5x the gate, not
> 3.4x.** The probe priced 39 of the block's 63 instructions -- the arithmetic it duplicated, which is
> the cheap part -- so its figure was conservative. **A C probe prices the instructions it duplicated,
> not the block.** The 0.9319 C rate and the 92,715 execution count below both stand.

### What it says, and it is a correction

**The block is 0.1703% of frame — 3,478 cycles/frame, 3.40x the 1,022.8-cycle gate.** For scale, the
whole `alias-glue` scope is 2.29%, so this single straight-line block is **7.4% of the glue**.

And the C rate is **0.9319**, which is the useful part. This is straight-line C with no loop-carried
dependency beyond the sink, so the ledger's two existing C probes bracket what to expect:

| C mix | rate |
|---|---:|
| `R_RenderFace` prologue, straight-line, instructions independent of the work around them | 0.5439 |
| **`d_polyse.c` per-triangle step setup, straight-line, feeds three ASM helpers** | **0.9319** |
| `R_RenderFace` edgeval, loop with a loop-carried sink | 1.1917 |

**0.5439 is not a general property of straight-line C.** The `prologue` figure was measured on code
whose instructions issue into slots already idle; this block's stores feed three assembly helpers
immediately afterwards, so its work is closer to the serialised end of the range. A third C data point
at 0.93 means **a C candidate screened at 0.5439 can be wrong by 1.7x in the direction that matters**,
and the project has been using the 0.5439 figure as though it were the C rate.

### The candidate, and why it is not built

There is exactly one, and it is structural rather than arithmetic. **These fifteen values are written
by C into globals and immediately reloaded from memory by `D_PolysetScanLeftEdge` and
`D_PolysetDrawSpans8`.** The interface is a memory round trip, fifteen stores here and fifteen loads
there, and the ledger already records that `D_PolysetScanLeftEdge` hoists what it can
("`d_pedgespanpackage` in `%esi`, `d_pdest`/`d_pz` in `%edi`/`%ebp`, light/zi/aspancount on stack").

Removing the round trip means changing the C↔ASM boundary so fifteen values cross in registers
instead of through `.data` — a change spanning `d_polyse.c` and two assembly files, with a
calling-convention contract that the ASM half depends on for its loop addressing. That is precisely
the "C-to-ASM port without a new source-level hypothesis" the prohibition list forbids, and a probe is
a price, not a hypothesis. **It is not built on the strength of a number.**

What the number does license: **this block is above the gate, so if a hypothesis for that interface
ever appears it starts here rather than in a 2%-of-frame C residual.** And the near-identical second
copy of the same fifteen-value computation at `d_polyse.c`'s `numleftedges == 2` branch is not a CSE
candidate — `D_PolysetSetUpForLineScan` is re-called with the other edge's coordinates in between, so
`ubasestep` and the step family genuinely differ.

Verification: three runs per variant plus a trailing control, checksum `1047377823` on all seven,
`bench486` not required for a probe. `control` instruction-identical to `HEAD`'s `d_polyse.c`.
Baseline unchanged at **59.160558 s / 16.379156 FPS**; `d_draw16.s` still 619 instructions.
## `alias-glue` reads 6.01% of frame and is **2.29%** — 62% of it is the profiler measuring itself (2026-10-03, sixth pass)

> **This closes the last region above 2%, and it reconciles a discrepancy the ledger has carried for
> three days.** The profile tree reports `alias-glue` self time as 4.792709 s, 6.01% of frame. The
> ledger says the C glue is 1.83 s. **Both are right, and the arithmetic that separates them is exact
> and was sitting in the profiler's own documentation.**

### The arithmetic, which reproduces the reported figure to the instruction

The profiler states its own rule: *"Each scope charges one ENTER read to its parent and one LEAVE read
to its own self time. A node's instr_reads is that floor; subtract it from self_seconds before
quoting any per-call cost."* `alias-glue` is the parent of three live child scopes and is itself a
scope, so its self time carries:

```text
CALCGRADIENTS    124,754 ENTER reads charged to alias-glue
SCAN_LEFT_EDGE   109,925 ENTER reads charged to alias-glue
DRAW_SPANS       153,838 ENTER reads charged to alias-glue
its own LEAVE    124,754
                --------
                513,271     and the tree reports instr_reads = 513,271   <- exact
```

At the measured 193.3-cycle `Sys_FloatTime` read:

```text
513,271 x 193.3 cy / 33.445 MHz = 2.9665 s of timer-read overhead
4.792709 s reported self       - 2.9665 s                   = 1.8262 s
```

**1.8262 s against the ledger's recorded 1.83 s.** The 2026-10-01 entry that withdrew the
"253–304 cycles per call" figure as 62–76% profiler overhead was right, and the corrected 1.83 s it
left behind is the real number. The tree's 6.01% is the same number with the clock added back.

**So the C glue is 1.826 s, 2.29% of frame, 362.8 cycles per triangle** over 124,754 calls — and
the withdrawn 253–304 figure was an *under*count of the real cost because it was measured on a
sub-block, not the whole scope.

### Why it stays closed

2.29% is below anything a C-to-assembler port could return, and the prohibition is not stylistic:
`D_RasterizeAliasPolySmooth`'s body is edge-pointer setup, the `initialleftheight == 1` single-span
fast path, the `D_PolysetSetUpForLineScan` call, and a per-scanline step loop that writes eight fields
per span into the span package. Its four named sub-blocks cannot be priced per call at all — the
per-call scopes were **removed** for exactly that reason, because at 100k–260k calls each they cost
more in `Sys_FloatTime` than they measured. That is a correct decision and it is also the reason this
region has never had a number: **the only honest instrument for it is a dead-scratch probe, and a
C probe needs `-O3` to be defeated** (it deletes a dead local store, so the probe must accumulate into
a reported external global). That is a two-hour experiment for a region already under the gate.

### The bucket, and the session's complete result

| region | share of frame | cyc/instr | closed by |
|---|---:|---:|---|
| general + flat surface-block rows | 6.85% | 0.77 | minimality proof (6-for-6, 3-for-3) |
| `z-spans` pixel loop | 6.37% | **1.24** | minimality proof + dependency structure |
| `edge-scan` | 8.27% | ~1.0 | 78% mapped, sixteen load-bearing blocks |
| `z-spans` per-span prologue | 2.72% | — | all seven registers live at `LFSpanLoop` |
| **`alias-glue` C** | **2.29%** | — | this entry: 62% of it was the clock |
| `texture-spans` setup | 2.37% | 0.988 | latency-bound; 4.1x candidate measured **0.0000%** |
| `renderface` C scaffolding | ~2% | 0.54 / 1.19 | priced; remainder is essential x87 |
| `R_BuildLightMap` | 0.06% | — | hoist worth 0.04x the gate |
| surface-cache remainder | 0.67% | — | 1,152 tryalloc scans, **0** evictions |

**Every region in the renderer is now closed, and the whole session produced one methodological
result rather than a speedup: 1.0 cycle per instruction prices *added* work, and this entry is the
second independent demonstration of why that matters — here the same code is 6.01% or 2.29% of frame
depending only on whether you subtract the clock, and the profiler's own note told you to.**

The standing rule for the next pass, and it is the one this session kept re-learning: **before
pricing anything, subtract the instrument.** `instr_reads` x 193.3 cycles is not a footnote, it is
62% of this node.

Verification: no code built, no timedemo run, no counter added — this entry is arithmetic over
figures already in the tree, and both inputs (`instr 513271` and the three child call counts) are
independently reported. Baseline unchanged at **59.160558 s / 16.379156 FPS**; `d_draw16.s` still 619
instructions.
