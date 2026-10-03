# ISA audit and the i386 codepath (2026-10-03)

Extracted verbatim from `ASM486-HANDOFF.md` lines 12-236 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## The 161 `imul r32,r/m32` sites are **not** strength-reducible — three approaches refuted by measurement (2026-10-03)

This supersedes the arithmetic-reduction half of the entry above. That entry correctly
established that the shipped executable carries **161 `0F AF`** instructions and that
`0F AF` is a Pentium encoding, and that it "can only be removed by strength reduction".
**The second half is wrong, and three separate attempts to apply it all failed.** Do not
re-derive any of them.

**The measurement that settles it.** Classifying all 161 sites by the *multiplier* operand,
using `tools\isa-audit.ps1` (which anchors on instruction boundaries rather than grepping,
so it does not misread a displacement as a literal):

| multiplier form | sites |
|---|---:|
| register x register | ~112 |
| memory / relocated global | ~49 |
| **immediate — the safe one-operand `F7 /5` encoding** | **0** |

There is also no cheap case hiding elsewhere: the same object set already contains **814**
`imul $imm,%reg` forms, which GCC emits whenever the multiplier is a compile-time constant.
It has no such option when both operands are live. `0F AF` is the only two-register 32-bit
`IMUL` encoding x86 has, so a product of two runtime values has no shorter 486-legal form.

**Refuted approach 1 — `cachewidth` as a power of two.** `d_draw.s:343`,
`d_draw16.s:323`, `d_spr8.s:323` and five siblings compute `(tfrac >> 16) * cachewidth`,
which looks like a shift if `cachewidth` is a power of two. It is not:
`cachewidth = surface->extents[0] >> miplevel` (`d_surf.c:431`) and
`cachewidth = pspriteframe->width` (`d_sprite.c:427`), both arbitrary. The tree's own
instrumentation counter gates on `!(cachewidth & 15)` (`d_edge.c:636`), i.e. **multiples of
16**, which is the opposite of a power of two. No power-of-two assumption exists anywhere.

**Refuted approach 2 — pre-scaling `reciprocal_table`.** `d_draw.s:612,616` and four
siblings compute `sstep = (snext - s) * reciprocal_table[spancount]`. Multiplying by a
16.16 reciprocal *is* the division; the multiplier is a function of a runtime span length,
so it cannot become a shift. Pre-scaling the table by the axis scale removes the separate
scale multiply but leaves this one.

**Refuted approach 3 — `* sizeof` sites as free shift conversions.** An objdump sweep
appears to find 23 sites with a literal multiplier, which reads as `x * 16` and therefore
as `x << 4`. Those are **unrelocated COFF displacements**: `0f af 0d 10 00 00 00` is an
**eight**-byte instruction multiplying by a global whose link-time address is `0x10`, and
objdump prints the unrelocated value, so the displacement reads as the literal `0x10`.
Count only sites the audit reports, and check the instruction length before believing an
operand is a constant. After that correction the count of genuinely constant multipliers
is **zero**.

**What the largest cluster actually is.** `_D_RasterizeAliasPolySmooth` carries 14 of the
161 — the single largest concentration, in a function the convergence statement already
records as *minimal* at 63 instructions. The shape is
`sar $0x10,%edi` / `imul %edi,%eax`, i.e. `(vtemp >> 16) * alias_scale`: a per-vertex scale
where both operands are runtime. The block appears twice because GCC inlined it twice.

**The only remaining path, and its price.** A hand-written shift-add expansion, ~11
instructions for a 32-bit low product, or an `__asm__` equivalent. GCC will not emit it
and `-march=i486` does not suppress `0F AF` (verified above against two GCC versions).
Split by cost:

- **~130 in init, asset-load and per-frame-trivial code** — free in *performance* terms,
  since they execute a handful of times per run, but a large diff across ~50 files in
  which every sequence must be an exactly-correct 32-bit low product, and in which
  surrounding register pressure may get worse.
- **~30 in the inner loop** — prohibitive. The three `texture_segments` multiply sites
  execute **3,513,485 times per run**; naive shift-add there prices at roughly **+10 s**
  on a 59.16 s baseline. The span-length histogram is spread near-uniformly over 1..16, so
  a dispatch onto compile-time constants — which *would* be free, since `imul $imm` is
  `F7 /5` — would need ~16 specialisations and cost more than it saves.

**Recommendation: do not attempt it.** The state is now *enforced and visible* rather than
open: `build-dos.ps1` runs the audit on its own objects after every link and throws on a
regression against `tools/golden/isa-baseline.json`, so no new above-target instruction can
enter the tree unnoticed. That is a durable outcome. Spending a large unverifiable diff to
convert a pinned 161 to zero buys a property the harness cannot measure, and risks the
8 KB unified cache, which is the one axis that is real on a 486 and invisible here.

Per-enforcement figures, all four verified deterministic across repeated builds:

| variant | enforced above-target | string-data decode (not enforced) |
|---|---:|---:|
| `i486/quake.exe` | 170 (`0f af` 161, `0f 30` 4, `0f 32` 2, `0f 0b` 3) | 0 |
| `i486/qbench.exe` | 173 (`0f af` 164) | 0 |
| `i486/qprof.exe` | 177 (`0f af` 168) | 0 |
| `i386/quake.exe` | 305 | 722 |

Three implementation notes that cost real time and will recur:

1. **Baseline per variant, not per target.** `-Benchmark` compiles the ~4335-line bench
   harness and `-Instrumentation` the PROFILE486 counters, so those are strictly larger
   code sets. One figure per target made every `bench-dos` run fail the gate.
2. **Audit a named object list, not a directory.** A build recompiles in place, so an
   object directory accumulates objects from selector sets that are no longer active
   (`asm486_experiments.s` when every implementation selector is `c`; `net_comx.c`, which is
   `#include`d rather than compiled). Sweeping the directory audits those too, and sweeping
   every `obj*` subdirectory counted **206** objects instead of 103 by double-counting
   `obj/` and `obj-bench/`.
3. **`62` and `63` are string literals, not instructions.** DJGPP emits string data into
   `.text`; `62 61 64` is `"ad"`, `63 6b 20` is `"ck "`, `65 63 74 00` is `"ect\0"`. They
   appear across ~50 objects, so `crc.obj:_crctable`-style symbol exemption cannot reach
   them. After excluding them the object-level gate reports **305** above-i386 against the
   **307** that `isa-audit-source.py` reports at source level — two independent methods
   agreeing within 2, which is the evidence the exclusion is sound rather than convenient.

New tooling: `tools\run-tests.ps1` runs all eight gates in one command, ordered
cheapest-first, and includes `test-sysinfo-dos.py` and `test-video-dos.py`, which the
checklist in "Starting commands" had omitted. `tools\compare-dpmi-dos.ps1` was
non-functional and now runs: it forced `SkipBuild` (which throws when no fingerprint file
exists), compared against the superseded checksum `4154140932`, and splatted
`@('-Benchmark')` — array splatting binds *positionally* for a PowerShell script, so
`-Benchmark` was taken as a positional value and failed the `CpuTarget` ValidateSet.

## A separate i386 codepath exists, and the shipped "486" binary needs a Pentium — both from one root cause (2026-10-03)

> **Do not re-open this as an optimization question. It is an ISA-level fact about the pinned
> toolchain, measured in three independent ways.** The i486 release profile is unchanged and
> byte-pinned; the i386 target is a separate build, a separate output tree and a separate
> manifest. Full detail and the commands are in `BUILD-DOS.md`, "The i386 target".

### The finding that reframes the name of this tree

The retained `quake.exe` contains **161 `0F AF` instructions**, and `0F AF` is
`IMUL r32, r/m32` — a **Pentium** instruction. So the "486" build has never
actually been runnable on a 486. The cause is not our code:

```text
C source          a * b        →   GCC   imull  %ebx,%eax
assembler         imull %ebx,%eax  →  0f af c3
```

`0F AF` is the *only* two-operand `IMUL` encoding x86 has; there is no 386-safe
spelling for GNU `as` to fall back on. GCC emits that AT&T spelling
independently of `-march`, which is why the earlier `-march=i386` experiment in
this tree produced a binary that would have faulted on a 386 at its very first
`Q_atoi`.

Two claims were checked rather than assumed:

- **`-march=i386` does restrict something.** At `-march=i386` GCC drops `bswap`;
  it does not drop `imul` or `setcc`.
- **No available toolchain fixes it.** `djgpp-mingw-gcc482-standalone.zip` (GCC
  4.8.2, the oldest prebuilt in the `andrewwutw/build-djgpp` series) was
  downloaded to a scratch directory and probed: identical `0f af` and `0f 9x`
  output at `-march=i386`. `dos-toolchain.json` is therefore unchanged, because
  swapping to a 2013 compiler would buy nothing and cost a hash pin.

### What the i386 build does fix

Every instruction above i486 **in this project's own assembly**, all three of
which were measured present in the i486 build and are now zero:

| construct | file | i486 | i386 | replacement |
|---|---|---:|---:|---|
| `SHLD` `0F A4` | `d_draw.s` | 18 | 0 | `mov`/`and`/`and`/`or`, bit-identical, `%esi` scratch |
| `BT`/`BTR` register form | `asm486_experiments.s` | 2 | 0 | four-entry mask table, no scratch register needed |
| `RDMSR`/`WRMSR` | `dosasm.s` | 6 | 0 | excluded; zero callers tree-wide |

`dosasm.s`'s `StartMSRInterval`/`EndMSRInterval` drive MSR `0x11` (CESR), which
is Pentium Pro / Cyrix-6x86 — unusable on an i486 too, and dead code besides.

### Residual, measured not estimated

```text
i386 target, code-only scan (tools/isa-audit-source.py), 0 unclassified:
  above i386   307   =  173 two-operand imul  (21 ours, 152 GCC)
                     +  131 setcc             (all GCC)
                     +    3 ud2               (GCC cold traps)
                     +    1 shrdl             (GCC)
```

**The remaining 21 `imul` sites in our own assembly are the one open item**, and
they are recorded rather than attempted, because fixing them cannot make the
binary 386-runnable while GCC contributes 152 more:

```text
d_draw.s     L343 L417 L612 L616 L629
d_draw16.s   L323 L526 L1604 L1609 L1622
d_polysa.s   L1284 L1290 L1715 L1720
d_spr8.s     L323 L393 L651 L655 L669
snd_mixa.s   L168 L188
```

Each needs a free scratch register, and these are hand-tuned loops with no spare
one. Per the standing rule in this file, the move is to read the object before
writing code — and to price it first, which has not been done.

### Two bugs found on the way, both pre-existing

- **`smoke-dos.ps1` was not testing the release binary.** It defaulted
  `DynamicLightImplementation` to `c` while `build-dos.ps1`, `bench-dos.ps1` and
  `timedemo-dos.ps1` all default to `asm`, and because each runner computed the
  profile suffix itself, `smoke-dos.ps1 -SkipBuild` resolved to a directory the
  builder never wrote. Every pass ever reported by the documented smoke command
  was for a different binary. All three runners now ask `build-dos.ps1
  -DumpFlags` for the output path.
- **`bench-dos.ps1` could benchmark a stale binary indefinitely.** It rebuilt only
  when `qbench.exe` was missing, with no source fingerprint, unlike
  `timedemo-dos.ps1`. It now carries the same `qbench.sources.sha256` fingerprint.
  This cost real time: an i386 `bsp-clip` correctness failure survived its source
  fix and was re-observed three times against the same stale `qbench.exe`.

The `bsp-clip` failure itself was genuine and is worth keeping: the first i386
spelling of the `BT` replacement branched on CF after `TEST`, which always
clears CF, so every plane was skipped and the clip mask came back `15`. The
correct form tests the mask against the flags and branches on ZF.

### Verification

i486 (unchanged, and now pinned):

```text
timedemo   3 runs, 969 frames each, checksum 1047377823
           59.160560 / 59.160541 / 59.160535 s   (baseline 59.160558)
benchmark  486 benchmark correctness PASS, end checksum 2378409472
smoke      passed
SHA-256    tools/guard-i486-release.py PASS over 103 objects + quake.exe
flags      tools/test-build-dos.py PASS
```

i386:

```text
timedemo   969 frames, checksum 1047377823      (bit-identical to i486)
benchmark  486 benchmark correctness PASS, end checksum 2378409472
smoke      passed, with the emulated CPU forced to cputype = 386
audits     0 unclassified; 0 instructions above i486 in our own assembly
```

