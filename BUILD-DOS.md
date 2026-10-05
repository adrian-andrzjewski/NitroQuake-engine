# Building the NitroQuake MS-DOS software renderer on Windows

## Text-mode startup summary

Immediately before the first graphics mode, DOS Quake prints a compact ASCII
summary: DPMI-reported CPU class, successful FPU startup check, DOS/DPMI versions,
DPMI-reported physical RAM, and the separately allocated Quake heap. Unsupported
or failed diagnostic queries print `unknown` and do not stop startup. CPU reporting
does not require CPUID. Memory is shown in KiB (1024 bytes).

The video line describes the available automatic 320x200 candidate: VESA linear,
VESA banked (including BIOS mode and pitch), or VGA fallback. Discovery is reused;
saved configuration and explicit mode commands apply later, and a candidate can
still fail during activation. `-stdvid` reports forced VGA with VESA discovery
skipped.

Startup continues without input or delay by default. Add `-sysinfo-pause` to read
the text screen, then press and release Enter. The DOS interrupt input queue
consumes the dismissal and held-key releases before gameplay. Dedicated startup
prints the information once with video disabled. Dedicated and benchmark builds
ignore the pause switch.

Host-side focused checks include `python tools/test-sysinfo-dos.py`,
`python tools/test-video-dos.py`, and `python tools/test-rendering.py`. The
manifest-driven `tools/render-validation-dos.ps1` suite runs deterministic Quake
demos through VGA/VESA and lighting/viewport paths, compares captured PCX frames against
tolerant references, and checks per-frame output for temporal instability. See
`RENDERING-VALIDATION.md` for scenarios, thresholds, and result artifacts. These
checks do not replace physical-machine visual/input acceptance.

Run the full registered verification suite with `tools/run-tests.ps1`. Pass
`-SkipRendering -SkipSlow` to omit the multi-scene rendering suite and the final
promotion timedemo during a short source/build iteration.

This checkout builds the retained NitroQuake MS-DOS/software-renderer source
directly from Windows 10.  The compiler is a Windows-hosted DJGPP cross
toolchain; DOSBox-X is used only to run the resulting DOS executable.

The experimental status and next-agent continuation plan are maintained in
`ASM486-HANDOFF.md`.  This document is the operational reference for building,
running, benchmarking, and interpreting the results.

## The i386 target, and what it is and is not

`build-dos.ps1` has a `-CpuTarget i486|i386` switch.  `i486` is the default and
the retained release profile; `i386` is a separate codepath with its own output
tree, its own object directory, its own executable, and its own manifest.  The
two can never collide, and `build-dos.ps1` asserts that before it compiles or
deletes anything.

```powershell
.\tools\build-dos.ps1 -Clean -CpuTarget i386 -NoBootstrap
.\tools\smoke-dos.ps1   -CpuTarget i386 -SkipBuild -TimeoutSeconds 90
.\tools\bench-dos.ps1   -CpuTarget i386
.\tools\timedemo-dos.ps1 -CpuTarget i386 -Runs 3
```

The i386 build writes to `out\dos-i386-memasm-zneg4-...`, builds with
`-march=i386 -mtune=i386`, and additionally defines `TARGET_I386` for both the C
and the assembly compiler.  `TARGET_I386` is the only selector that differs, and
it is used in exactly three files.

### Read this before calling it a 386 binary

The i386 build is **i386 by construction and by audit of the project's own code,
and it will nevertheless not execute on a 386.**  That is a property of the
pinned toolchain, and it is worth stating precisely rather than in a footnote.

`-march=i386` on GCC 12.2 does not produce 386-safe code.  Measured on this
toolchain:

| construct | GCC emits | assembler emits | minimum ISA |
|---|---|---|---|
| `a * b`, two registers | `imull %ebx,%eax` | `0F AF` `imul r32,r/m32` | **Pentium** |
| `a > b` | `setg %al` | `0F 9F` | **i486** |

`0F AF` is the only two-operand `IMUL` encoding x86 has, so GNU `as` has nothing
to fall back on, and GCC emits that spelling regardless of `-march`.  There is no
command-line switch that changes it: `-march=386` is not a valid spelling,
`-Os` is worse (it adds `imull $imm`), and no `-mtune-ctrl` knob reaches
instruction selection for `IMUL`.  This was not assumed — GCC 4.8.2, the oldest
prebuilt in the `andrewwutw/build-djgpp` release series, was downloaded and
probed, and it behaves identically.  A toolchain swap buys nothing, so
`tools\dos-toolchain.json` is unchanged.

The same two constructs are present in the **i486** release build.  The shipped
`quake.exe` contains 161 `0F AF` instructions and would already fault on a real
486.  That predates this work; it is recorded here because it is the same root
cause, not a second problem.

### What the i386 build did fix

Every instruction above i486 **in this project's own assembly** is gone:

| construct | files | i486 build | i386 build |
|---|---|---:|---:|
| `SHLD` (`0F A4`) | `d_draw.s` | 18 | **0** |
| `BT`/`BTR` with a register bit offset (`0F A3`, `0F B3`) | `asm486_experiments.s` | 2 | **0** |
| `RDMSR`/`WRMSR` (`0F 32`, `0F 30`) | `dosasm.s` | 6 | **0** |

`dosasm.s`'s pair drives MSR `0x11` (CESR), which is a Pentium Pro / Cyrix-6x86
register and is unusable on an i486 as well as an i386.  Nothing in the tree
references `StartMSRInterval` or `EndMSRInterval`, so excluding them removes dead
code and changes no behaviour.  The other two have i386 spellings that are
bit-identical:

* `d_draw.s` packs a Z-span pixel pair with `shld`/`ror`; the i386 macro computes
  the same value as `(eax & 0xFFFF) | (edx & 0xFFFF0000)` in four instructions,
  using `%esi`, which is dead inside the span loop.
* `asm486_experiments.s` used a register-offset `BT`/`BTR` over a four-plane loop
  counter; a four-entry mask table expresses both exactly and needs no scratch
  register, which matters because all six are live there.

### Measured residual for the i386 target

`tools\isa-audit-source.py -CpuTarget i386` classifies the compiled instructions
only, with zero unclassified:

```text
instructions        115677
i386 115370  i486 131  i586 176  p6 0  unknown 0
above i386          307
  i586  imull (two-operand)  173      21 in our assembly, 152 from GCC
  i486  setcc                131      all from GCC
  i586  ud2                    3      GCC cold-block traps, unreachable
  i486  shrdl                  1      GCC
```

`tools\isa-audit.ps1` cross-checks that at the object level.  Note that this tool
is a **superset**: no object this toolchain produces has a `.rodata` section, so
DJGPP puts string literals inside `.text` and a linear disassembly decodes ASCII
as x86 (`63 6b 20` is `"ck "` and reads as `arpl`).  It is the right tool for
"which encodings exist in this binary"; it is not the right tool for a 386 gate.
Use `-Exempt 'crc.obj:_crctable'` and read the `unclassified` count, which is
required to be zero.

### Correctness

The i386 build is verified bit-identical to the i486 release:

```text
timedemo   969 frames  framebuffer-checksum 1047377823   (both targets)
benchmark  486 benchmark correctness PASS, end checksum 2378409472
smoke      DOS smoke test passed
```

### Guards on the i486 build

The i486 release is pinned three ways, and all three are checked by
`python tools\test-build-dos.py` and `python tools\guard-i486-release.py`:

* `tools\golden\build-flags-i486.json` — the resolved C, assembly and link flag
  lists, the output paths, and the source inventory.  `build-dos.ps1 -DumpFlags`
  produces them without needing a compiler, so the guard does not re-implement
  the profile-suffix arithmetic.
* `tools\golden\i486-release.sha256` — SHA-256 of all 103 objects and of
  `quake.exe`.  `host.c` and `host_cmd.c` print `__DATE__`/`__TIME__`, so those
  two objects and the executable are hashed with the timestamp replaced by a
  same-length literal; those three entries are marked `normalized` in the file so
  the weakening is visible.
* `tools\golden\isa-source-baseline.json` — the source-level ISA ratchet for
  `tools\isa-audit-source.py`, which is gate 5 of `tools\run-tests.ps1`.  Two
  absolute rules (unclassified must be zero, p6 must be zero) and per-ISA counts
  that may not rise.  It exists because that tool is the cross-check on the
  object-level gate above: the two count instructions by different means, and
  `tools\golden\isa-baseline.json` records that their agreement is the evidence
  its 62/63 string-data exclusion is sound rather than convenient.  Run the tool
  *without* `-FailOnViolation`, which is an absolute pass and stays red for as long
  as the multiply-elimination work is incomplete; the ratchet is what gates.
* The i386 codepath is entirely inside `#ifdef TARGET_I386`, so the i486 object
  bytes cannot move.  That is what the SHA-256 pin proves, and it is checked after
  every change to the assembly.
* `tools\dosbox-x-486-high.conf` is pinned by SHA-256 from `timedemo-dos.ps1`,
  with line endings normalised to LF before hashing.  Hashing the file as it sits
  on disk made that promotion gate depend on the machine's git configuration:
  there is no `.gitattributes` in this tree, the committed blob is LF, and
  `core.autocrlf=true` rewrites it to CRLF on checkout — so the pinned constant
  only ever matched a Windows clone configured this way.  A checkout with
  `core.autocrlf=false`, which includes Linux and any CI runner set up that way,
  failed the gate on a file that had not changed.

### Two pre-existing bugs found while adding the target

* `smoke-dos.ps1` defaulted `DynamicLightImplementation` to `c` while every other
  script defaulted to `asm`.  Because each runner computed the profile suffix
  itself, `smoke-dos.ps1 -SkipBuild` looked for
  `out\dos-memasm-...-fusedlightmapasm\quake.exe` while the release build lives
  in `out\dos-memasm-...-fusedlightmapasm-dlightasm\` — so it was not testing the
  release binary.  All three runners now ask `build-dos.ps1 -DumpFlags` where the
  output is instead of recomputing it, which is what made the divergence visible.
* `bench-dos.ps1` rebuilt only when `qbench.exe` was *missing*, with no source
  fingerprint, so an existing binary was benchmarked indefinitely regardless of
  source edits.  It now uses the same fingerprint as `timedemo-dos.ps1`.  This one
  cost real time: an i386 `bsp-clip` correctness failure survived a source fix and
  was re-observed three times against the same stale binary.

### The fingerprint, and who records it

All four runners hash the sources plus the builder's resolved configuration before
testing an executable, and `build-dos.ps1` records that hash after a successful
link.  Three details are load-bearing.

The hash covers the resolved configuration — the profile suffix, both flag lists,
`outputRoot` and the executable name — rather than a list of selector values.  That
is complete by construction, so no runner has to declare forty selectors to be
correct about them, and it cannot disagree with `tools\golden\build-flags-*.json`,
which compares exactly those fields.

The record is named after the executable (`quake.sources.sha256`,
`qbench.sources.sha256`, `qprof.sources.sha256`).  It used to be fixed at
`qbench.sources.sha256`, and since all four runners stage into the same output
directory for a given selector set, the release, bench and instrumented builds
overwrote each other's record and then rebuilt each other's binary on alternating
runs.

The builder records it, after the ISA gate.  It is the only component that knows
what it just produced, so a runner invoked with `-SkipBuild` after somebody else's
build has nothing else to check against — and "the file exists" is not evidence of
anything.  A build that fails the gate throws before reaching that line, so a
failed build never leaves a record claiming the tree matches.

### `smoke-dos.ps1` and `coverage-dos.ps1` had neither

Both asked only whether the executable existed, so once a release build was present
it was tested indefinitely however many sources had changed.  For `coverage-dos.ps1`
that is worse than a stale number: the claim the gate makes is that `world.c`,
`sv_*`, `pr_*` and the net layer were reached, and that claim is void if it was
reached in a different binary.  `coverage-dos.ps1` also hardcoded `dosbox-x.exe`
where the other three read `dosboxX.executable` from `tools\dos-toolchain.json`, and
had no bootstrap fallback — so `-NoBootstrap` meant one thing there and another
everywhere else.

## Profiling and probe tooling
### Premise-measurement counters (PROFILE486 only)

Three metric groups were added to answer candidate premises by measurement
rather than by argument. They compile only under `PROFILE486`, cost nothing in
release builds, and appear in the profile report and the `timedemo.txt` text
stream:

| group | counters | what it answered |
| --- | --- | --- |
| `profile-surface-cache` | `immutable_rebuilds` | 0 of 8,886 — closed the E4 surface-cache candidate |
| `profile-submodel` | `calls`, `faces`, `distinct-entities`, `entity-hits`, `table-overwrites` | 12,708 face tests over the run, so the bmodel frustum candidate sits ~5x under the gate |
| `profile-turbulent` | `rows`, `chunks`, `pixels` | 40,147 / 144,705 / 1,997,515, which priced the `Turbulent8` setup with a bit-exact dead-scratch probe |

`table-overwrites 0` is what makes `distinct-entities 26` trustworthy — a
collision would have inflated the reuse figure rather than deflating it, so
that counter is what licenses the conclusion drawn from the other.

The counters are evidence, not instrumentation overhead to be removed: each one
exists because a candidate died on a measured premise. See
`docs/ledger/2026-10-02-edge-scan-and-texture-spans.md` for the three write-ups.

**Added 2026-10-02 — `edge-iters`**, which decomposed the `edge-scan` bucket:

| counter | run total | what it answered |
| --- | ---: | --- |
| `insert`, `remove`, `step`, `pushback`, `sort` | 532,086 / 150,392 / 972,457 / 96,274 / 1,763,039 | loop iterations, where the existing counters only had *calls* — three of the four edge routines walk a list, so a probe priced per call is sized wrong by the walk length |
| `genspans` | 3,500,514 | per-edge entries, 3,612/frame. **This is what re-targeted the bucket**: the four micro-optimised loops are 52x the gate together against a 204x bucket |
| `emit` / `trailing` | 1,043,177 / 2,238,002 | span emits against `TrailingEdge` calls, i.e. **53% of calls emit nothing**, previously unmeasured |
| `bmodel-zsort` | 66,723 | bounds the ~50-instruction x87 bmodel 1/z sort, which is inadmissible on the blind axis and so is deliberately *not* probed |
| `edge-dispatch`: `leading`, `bmodel-leading`, `bmodel-trailing`, `insert-exit`, `newtop`, `xldone`, `lastspan`, `reset-iters` | 2,465,503 / 193,294 / 1,035,010 / 2,465,403 / 1,213,416 / 100 / 147,440 / 227,501 | which dispatch path each of the 3,500,514 edges takes. The accounting closes exactly: leading-only 1,262,511 + both 1,202,992 + trailing-only 1,035,010 = 3,500,513, and `LInsertAndExit`'s shortfall of 100 against `Lgs_leading` is exactly `xldone` |
| `renderface-general-edges` | 684,731 | edges handled by `R_RenderFace`'s **general** loop, of 1,077,059 total — the unrolled 3- and 4-edge blocks take the other 392,328. A per-edge price must be scaled by this, not by the total, and this counter is why that is checkable rather than assumed |

Reported on their own lines rather than appended to the big block, per the
`char text[1024]` rule below. Together these took `edge-scan` from "cannot be
decomposed" to **78% accounted, 159.2x the gate across sixteen named blocks**.

The measured breakdown (frame total 67.946126 s, attribution only — not a
release timing claim) is `alias-raster` 7.384299 s (10.87%), `alias-transform`
1.335922 s (1.97%), and `alias-setup` 0.181710 s (0.27%). The alias cost is
therefore raster-dominated. See `docs/ledger/2026-09-29-harness-and-cost-model.md` for the full record and its
consequences for the next optimization pass.

### Current promoted defaults

The promoted row-loop defaults use the mip-0 four-row and mip-1 eight-row
surface-block loops. That combined build completed three timedemo runs at
59.344208 seconds median (16.328468 FPS), each with 969 frames and framebuffer
checksum `1047377823`. The mip-1 change measured 0.0504% faster than the
five-run mip-0-only control and passed DOS smoke plus the full `bench486`
correctness suite (`2378409472`). Both loop controls remain selectable with
`-SurfaceBlockMip0Rows control` and `-SurfaceBlockMip1Rows control`.

`-SurfaceBlockMip0HorizontalFlat fast` uses one constant light-map row when a
mip-0 block has matching left/right light values and matching vertical steps.
It skips the per-texel horizontal light updates; `control` selects the original
drawer. Five alternating control/fast `demo1` runs measured medians of
59.344211 and 59.265486 seconds, respectively, a 78.725 ms (0.13266%) gain.
The control spread was 0.094 ms and the fast spread was 0.053 ms. All ten runs
completed 969 frames with checksum `1047377823`; candidate DOS smoke and full
`bench486` correctness passed (`2378409472`). `fast` is now the default.
Artifacts: `out\dos-bench-20260929-061426`, `out\dos-smoke`, and alternating
timedemos `out\dos-timedemo-20260929-062348` through
`out\dos-timedemo-20260929-063449`.

The fresh PROFILE486 control run is
`out\dos-timedemo-20260929-055543\timedemo-result.json`; its 67.797249-second
duration is attribution only. Self-time ranking: texture spans 27.89%, alias
models 13.28%, world BSP 11.41%, surface cache 10.72%, Z spans 9.29%, and edge
scanning 8.93%. The surface cache had 8,913 rebuilds, 6.481275 seconds of
rebuild time, and no thrash frames. Its mip-0 block drawer took 3.692177
seconds and PROFILE486 counted 26,861 horizontal-flat blocks across mip
levels. The world-BSP `local` frame-count candidate remains unpromoted because
its median was 0.046250% slower than control. This pass changes no visual
quality, resolution, presentation, scene, or timing behavior.

### `tools\probe-ab.ps1` — the A/B a probe needs, and the PowerShell traps around it (2026-10-02)

```powershell
.\tools\probe-ab.ps1 -Probe newtop
.\tools\probe-ab.ps1 -Probe prologue -Selector RenderFaceProbe
```

Runs three control runs, three probe runs and a trailing control, enforces
checksum `1047377823` on every one, and prints medians, the delta, the
within-block spread, the drift check and the signal ratio. Written because the
probe method above was otherwise prose with no executable form, and because
building the driver cost three cycles on PowerShell invocation bugs.

**Do not pass `-SkipBuild`.** Every probe selector is in the profile suffix and
the build fingerprint, so each variant rebuilds itself. That is deliberate: a
`-SkipBuild` probe run can measure the control binary, which is the single most
expensive mistake this project has made.

The trailing control is not decoration. It is the only thing that separates a
real delta from thermal drift, and this host produces **isolated ~0.36 s
outliers** — one of the nine probe control blocks had its *first* run be the
outlier, which made its raw three-run spread understate the signal ratio by
~14,000x. Medians handle the outlier; the drift check proves there was no
thermal component.

`-Runs 1` is a smoke test only and says so in its own output: a single run has
no spread and therefore no signal ratio.

**Five PowerShell traps, all of which produce a wrong answer rather than an
error.** They are in the script's comment block, repeated here because each one
cost a cycle:

| trap | symptom |
|---|---|
| `timedemo-dos.ps1` uses `Write-Host`, which writes to the information stream (6) | `2>&1` captures nothing; `*>&1` is required |
| the build writes warnings to stderr | under `$ErrorActionPreference='Stop'` they become terminating errors and truncate the captured output, which then reads as a parity failure |
| a function that `Write-Output`s progress *and* returns a value | returns both; the caller's `[double[]]` collects the strings and every median breaks. Use `Write-Host` |
| a quoted parameter name: `"-RenderFaceProbe"` | a literal string, bound positionally into `-DataRoot`, producing a nonsense DOSBox path |
| array splatting `@('-Runs','1',...)` | loses the parameter/value pairing, so `'1'` binds to `-OptimizationProfile`. Hashtable splatting works |

### `-SpanSetupProbe` — the span16 per-segment setup (2026-10-02)

```powershell
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -SpanSetupProbe setup
.\tools\timedemo-dos.ps1 -NoBootstrap -Runs 1 -NoFpsStats -SpanSetupProbe setup
```

Values `control`, `setup`. Six instructions duplicated at the head of the
per-segment setup in `d_draw16.s`, which every sixteen-wide segment passes
exactly once — 2,059,018 times over the run, so the count needs no counter.
Default `control`, which assembles `d_draw16.o` to 619 instructions, identical to
the pre-probe object.

Measured **+0.365979 s (0.6186% of frame)** at 9,891x the run spread, drift
−0.000009 s, 0.86% error against the 1.0 prediction. Six instructions of setup
cost 0.62% of frame; the full ~23-instruction integer setup scales to **2.37%,
47x the promotion gate**, and contains **no x87 at all** — which falsifies the
reason `texture-spans` was closed.

Unlike the C probes, no sink is needed: this is assembler, so `-O3` cannot elide
it. `%eax` and `%edx` are dead at the insertion point and the flags `sarl` sets
are dead too, which is the register discipline the `edge-scan` probes established.
See `docs/ledger/2026-10-02-edge-scan-and-texture-spans.md`, under "The span16 per-segment setup is 2.37% of frame".

### `-RenderFaceProbe` — the same switch for C, and two C-only traps (2026-10-02)

```powershell
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -RenderFaceProbe prologue
.\tools\timedemo-dos.ps1 -NoBootstrap -Runs 1 -NoFpsStats -RenderFaceProbe prologue
```

Same idea over `R_RenderFace`'s C scaffolding. Values `control`, `prologue`,
`edgeval`. Measurement only; `control` compiles `R_RenderFace` to 1,651
instructions, identical to the pre-probe object.

**Two traps that produce a silently wrong number rather than an error:**

- **`-O3` deletes a probe that writes to a dead local.** The store is provably
  dead, the "probe" compiles to nothing, and the timedemo reports a clean zero
  delta — which reads as "this code is free" when it means "this measurement
  measures nothing". The duplicated arithmetic must accumulate into an
  **external** global that something reports (`bench486_rf_probe_sink`); its
  value then doubles as the execution count, so an elided probe reports 0
  instead of lying.
- **Compare assembled probe against assembled `control`, and expect the compiler
  to fold part of your duplicate.** `prologue` attempted 12 instructions and
  added 11; `edgeval` attempted 14 and added **7**, because `-O3` CSE'd half the
  duplicate against the real code. That shortfall is not a broken probe — it is
  the compiler reporting that the block has no redundant work left, which is
  usually the answer. Take the instruction count from `objdump`, never from the
  source.

**And read the object before writing the probe at all.** The obvious candidate in
this function — the `edge_p - r_edges` computed twice per edge across 29 sites —
is already CSE'd by `-O3`; `objdump -dr` shows both loads hoisted and one
duplicated `sub`, so the entire prize is ~0.9x the gate. That was settled by one
disassembly instead of a build-and-run cycle.

**Measured rates here, which matter more than the closure:** `prologue` gives
**0.5439** cycles per instruction and `edgeval` gives **1.1917**, against nine
assembly loops measuring 0.9740–0.9957. The rate is a dependency property, not a
constant — independent instructions issue into idle slots and cost less than a
cycle, serialised ones cost more. See `docs/ledger/2026-10-02-edge-scan-and-texture-spans.md`, under "The rate is a dependency property
is not a constant".

**And a dead-scratch probe prices the cost of ADDING work, not the value of REMOVING
it (2026-10-03).** A twelfth probe settled this by direct contradiction: four
instructions of one shape added to the span16 per-segment setup cost +0.4112% at
**0.988 cycles each**, and four instructions of the *same* shape removed from the
*same* path — the clamp fusion, 0.206% predicted — measured **0.0000%**. So a region
can charge full price for work added and nothing for work removed, and every probe in
this file up to that point measured the addition. **A model-priced rejection is not
evidence that a candidate is slow, it is evidence that nobody built it**; the error
is one-way. **Take the added-instruction count from `objdump`, never from the source**,
and count any `.p2align` padding the insertion moved as part of the probe — a
five-instruction probe at the per-segment clamp cost 17, because the function's
`.p2align 4,,15` blocks re-padded downstream. See `docs/ledger/2026-10-03-clamp-fusion-and-the-1.0-rate.md`, under "The clamp
fusion is measured at 0.0000%".

### `-EdgeScanProbe` — dead-scratch measurement switch, never a candidate (2026-10-02)

```powershell
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -EdgeScanProbe entry
.\tools\timedemo-dos.ps1 -NoBootstrap -Runs 1 -NoFpsStats -EdgeScanProbe entry
```

One switch prices **one block** of `r_edgea.s`. It duplicates a fixed,
side-effect-free instruction sequence at that block's inner point and discards
the result, so the timedemo delta divided by the known probe instruction count
gives this harness's cycles-per-instruction for that mix. Default `control`.
Values: `control`, `entry`, `step`, `trailing`, `emit`, `insert`, `sort`,
`newtop`, `leadin`, `insertexit`.

**This is instrumentation, not a candidate.** A probe build is strictly slower by
construction; nothing here can ever be promoted. `control` was verified to
assemble **instruction-for-instruction identical** to the pre-probe tree (377
instructions, zero disassembly differences), so the release path is unchanged in
fact and not merely in intent.

Rules that are not obvious, each learned by faulting or mis-measuring a run:

- **Duplicate compute, never a store.** On mutating list code a duplicated store
  changes state and the run diverges. The `step` probe drops
  `movl %eax,et_u(%edx)` and keeps the load and the add.
- **A dead register is not a safe address.** `%esi` is dead in
  `R_InsertNewEdges`' search loop but *uninitialised* on the first pass — it is
  written only by the second probe — so the first `insert` probe faulted the
  timedemo. Probe a register that is both dead **and** initialised.
- **`mov mem,mem` does not assemble.** The `emit` block has no free register and
  a `.data` scratch long needs one anyway, so it borrows `%eax` across a
  `pushl`/`popl` pair, counted inside the seven probe instructions.
- **Put the probe before any instruction whose flags a later branch reads.** Both
  sort loops' back-edge and exit branch consume the flags of the real
  `cmpl st_key(%esi),%eax`.
- **A dead register is not enough — it must also be initialised, and already
  dereferenceable, at that exact instruction.** Three distinct failures here,
  none the same mistake: `%esi` in `R_InsertNewEdges`' search loop is dead but
  *uninitialised* on the first pass; `%edi` at `Lgs_leading` is dead but still a
  16-bit surface *index*, not a pointer, two instructions before it becomes one;
  and `mov mem,mem` is not encodable at all, which is how the `emit` block came
  to borrow `%eax` across a `pushl`/`popl`.
- **Price with a trailing control run.** This host throws isolated ~0.36 s
  outliers; every pair must be read on medians, and a trailing control catches
  drift. One of the nine control blocks had its *first* run be the outlier,
  which is why the raw three-run spread understates the signal ratio.

Results, the census they rest on, and the 0.98657 mean rate over nine mixes are
in `docs/ledger/2026-10-02-edge-scan-and-texture-spans.md`, under "`edge-scan` decomposed by dead-scratch probe". The
`PROFILE486` iteration and dispatch counters the probes are sized against are
retained and cost nothing in release builds.


### Sections moved out of this document

These were measurements, not build steps. Each is recorded verbatim in the
ledger, which is where a result belongs.

| Section | Now recorded in | Why it left |
|---|---|---|
| **Offline precomputation pass (2026-09-29) — one rejection, one cleanup, one closure** | [`docs/ledger/2026-09-29-offline-precomputation-pass.md`](docs/ledger/2026-09-29-offline-precomputation-pass.md) | a result, not a build step |
| **Hot-code clustering (2026-09-29) — rejected, selector removed** | [`docs/ledger/2026-09-29-harness-and-cost-model.md`](docs/ledger/2026-09-29-harness-and-cost-model.md) | duplicate of the ledger copy |
| **What this harness can and cannot measure (2026-09-29)** | [`docs/ledger/2026-09-29-harness-and-cost-model.md`](docs/ledger/2026-09-29-harness-and-cost-model.md) | duplicate of the ledger copy |
| **Z-span x87 prologue (2026-09-29) — measured at 0.71%, not worth porting** | [`docs/ledger/2026-09-29-harness-and-cost-model.md`](docs/ledger/2026-09-29-harness-and-cost-model.md) | duplicate of the ledger copy |
| **Aff8 AGI back-edge padding (2026-09-29) — measured null, selector removed** | [`docs/ledger/2026-09-29-harness-and-cost-model.md`](docs/ledger/2026-09-29-harness-and-cost-model.md) | duplicate of the ledger copy |
| **Alias-raster C-glue instrumentation (2026-09-29)** | [`docs/ledger/2026-09-29-harness-and-cost-model.md`](docs/ledger/2026-09-29-harness-and-cost-model.md) | duplicate of the ledger copy |
| **Alias-raster child instrumentation (2026-09-29)** | [`docs/ledger/2026-09-29-alias-and-surface-block-experiments.md`](docs/ledger/2026-09-29-alias-and-surface-block-experiments.md) | duplicate of the ledger copy |
| **Alias sub-node instrumentation (2026-09-29)** | [`docs/ledger/2026-09-29-alias-and-surface-block-experiments.md`](docs/ledger/2026-09-29-alias-and-surface-block-experiments.md) | duplicate of the ledger copy |
| **Static 486 cost model (read-only analysis)** | [`docs/ledger/2026-09-29-harness-and-cost-model.md`](docs/ledger/2026-09-29-harness-and-cost-model.md) | duplicate of the ledger copy |
| **Aff8 16-byte code-alignment experiment (2026-09-29) — rejected and reverted** | [`docs/ledger/2026-09-29-alias-and-surface-block-experiments.md`](docs/ledger/2026-09-29-alias-and-surface-block-experiments.md) | duplicate of the ledger copy |
| **Latest PROFILE486 and texture-span STOSW experiment (2026-09-29)** | [`docs/ledger/2026-09-29-offline-precomputation-pass.md`](docs/ledger/2026-09-29-offline-precomputation-pass.md) | a result, not a build step |
| **Monster gib trail zero-XY experiment (2026-09-29)** | [`docs/ledger/2026-09-28-span-micro-experiments.md`](docs/ledger/2026-09-28-span-micro-experiments.md) | duplicate of the ledger copy |

## Build

### DOS video startup

Mode index `0` remains VGA mode 13h. After the startup configuration has run,
an unset/zero `_vid_default_mode` automatically selects a BIOS-reported VBE 2.0
320x200 packed 8-bit mode. Linear framebuffer modes take priority over banked
modes. Banked modes must fit completely in one readable/writable window.
Saved nonzero defaults and explicit `+vid_mode N` choices take precedence over
automatic selection. `-stdvid` forces VGA startup and skips VESA discovery;
runtime `vid_mode N` changes and `vid_testmode` remain available.

320x200 VESA renders into tightly packed RAM and copies dirty rectangles to
one display page. Matching full-width pitches use a single transfer through
the existing i486 assembly copier. Padded hardware pitches retain row copies.
The default path has no retrace waits, display-start calls, or per-frame bank
switches. `_vid_wait_override 1` requests the legacy vsync override; explicit
`vid_wait 1` (vsync) and `vid_wait 2` (display enable) are honored where the VGA
status register supports them. Tearing is possible with waits disabled.

Discovery/allocation/mapping/BIOS initialization failures fall back to mode
13h. A failed requested mode gets one VGA recovery attempt, with no recursive
restoration or automatic retry. Backend, BIOS mode, pitch and failures are
logged to the console (`-condebug` also writes `id1/qconsole.log`). Active
linear mappings are released on mode changes and shutdown.

Run `python tools/test-video-dos.py` with native GCC for the mocked BIOS,
startup/recovery, direct-rectangle, padded-pitch and copy-boundary checks.
See [VIDEO-DOS-VALIDATION.md](VIDEO-DOS-VALIDATION.md) for DOSBox validation and
the distinction between framebuffer parity and displayed-output inspection.

### Compiler invocation

From the repository root in Windows PowerShell 5.1:

~~~powershell
Set-ExecutionPolicy -Scope Process Bypass
.\tools\bootstrap-dos.ps1
.\tools\build-dos.ps1 -Clean
~~~

The executable is written to:

~~~text
out\dos\quake.exe
~~~

The default normal build uses all 83 C files and 21 preprocessed x86 assembly
files in src.  Its `aggressive` profile is `-O3 -march=i486` with the
measured ASM paths enabled for alias projection, alias bounding-box projection,
clipped alias transform/lighting, texture animation, and lightmap
normalization; the turbulent loop uses the measured `stosb` variant. Renderer
entry selectors such as `-SkySpanImplementation`, `-WarpScreenImplementation`,
`-SolidSurfaceImplementation`, and `-TurbulentScanImplementation` let C and
assembly paths be built separately; the sky, solid-surface, and turbulent-scan
selectors remain on C by default. `-O2` remains
available as `-OptimizationProfile baseline` and writes to `out\dos-baseline`.  net_comx.c is
textually included by net_ser.c, so the build compiles 82 standalone C files
and obtains the remaining C implementation through that include.  Object files
and a generated build-manifest.json remain under out\dos, which is ignored by
Git.  The linker output is checked with the DJGPP objdump and must report
coff-go32.

The memory-helper experiment can route the real `Q_memset` and `Q_memcpy`
entry points through the hand-written 486 routines without changing the C
reference bodies.  Select it at build time:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -MemoryImplementation c
.\tools\build-dos.ps1 -Benchmark -MemoryImplementation asm
~~~

`asm` is now the 486-oriented default and writes to `out\dos-memasm`; `c`
remains the callable reference path and writes to `out\dos`. The ASM build
includes `asm486_experiments.s` and defines `ASM486_RUNTIME_MEMOPS`; all other
compiler flags and source inputs remain the same. Three current 486 timedemo
runs measured 62.556866 / 62.556847 / 62.556874 seconds with ASM versus a C
reference median near 62.568974 seconds, with checksum `4154140932` every run.

The texture-axis cache-key probe is independently selectable with
`-TextureAxisImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -TextureAxisImplementation c
.\tools\build-dos.ps1 -Benchmark -TextureAxisImplementation asm
~~~

`c` is the default and shares `out\dos`; `asm` writes to `out\dos-axisasm`.
This switch changes only the three-key cache hit/miss probe in `D_GetTextureAxes`;
hashing, cache misses, and axis-vector transforms remain in C.

The surface-cache miss-path and allocator assembly are selectable with
`-SurfaceCacheImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -SurfaceCacheImplementation c
.\tools\build-dos.ps1 -Benchmark -SurfaceCacheImplementation asm
~~~

`c` is the default and shares `out\dos`; `asm` writes to
`out\dos-surfaceasm`. This switch selects the fast cache-validity predicate,
texture/style key loads, miss-path extent setup, texture/style tag writes, and
the `D_SCAlloc` rover allocator, cache attachment, draw dispatch, and sticky
dynamic-light tag update. It also selects the public `D_CacheSurface` assembly
entry, which owns the hit/miss flow and animation call guard. The C entry is
retained as `D_CacheSurface_C` in benchmark builds. `R_TextureAnimation` uses
its own C/assembly selector, and PROFILE486 cache accounting uses
instrumentation-only C helpers. `R_DrawSurface` has its own selector below.

The complete `R_TextureAnimation` entry is selectable with
`-TextureAnimationImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -TextureAnimationImplementation c
.\tools\build-dos.ps1 -TextureAnimationImplementation asm
.\tools\bench-dos.ps1 -TextureAnimationImplementation asm -TextureAnimationOnly
.\tools\smoke-dos.ps1 -TextureAnimationImplementation asm
.\tools\timedemo-dos.ps1 -TextureAnimationImplementation asm -Runs 1
~~~

`asm` is the configured default. It selects alternate animation, the static
texture fast path, x87 time conversion with truncation toward zero, signed
phase remainder, and frame interval traversal. Benchmark builds retain
`R_TextureAnimation_C` and `R_TextureAnimationFrame_C`; the focused animation
harness compares 25 time values under all four x87 rounding modes and times the
complete entry. The single pinned timedemo sample confirms checksum parity; it
is not end-to-end performance evidence.

The mip-level threshold selector is independently selectable with
`-MipLevelImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -MipLevelImplementation c
.\tools\build-dos.ps1 -Benchmark -MipLevelImplementation asm
.\tools\bench-dos.ps1 -MipLevelImplementation asm -MipLevelOnly
.\tools\smoke-dos.ps1 -MipLevelImplementation asm
~~~

`c` is the default and shares `out\dos`; `asm` writes to `out\dos-mipasm`.
The assembly object exports the public `D_MipLevelForScale` symbol directly,
using 486 x87 comparisons for the three thresholds and the minimum-mip clamp.
The C selector remains complete, and benchmark builds retain
`D_MipLevelForScale_C` as the reference.

The turbulent-span store loop is independently selectable with
`-TurbulentImplementation c|asm|stosb`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -TurbulentImplementation c
.\tools\build-dos.ps1 -Benchmark -TurbulentImplementation asm
.\tools\build-dos.ps1 -Benchmark -TurbulentImplementation stosb
~~~

`stosb` is the measured target default, `asm` is the existing 486 assembly
control path, and `c` selects a callable C reference implementation.  The
variants use separate ignored output directories (`out\dos-turbc`,
`out\dos-turbasm`, and `out\dos`) and all keep the original portable C loop in
the source.

The `Turbulent8` scan setup and interpolation are independently selectable with
`-TurbulentScanImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -TurbulentScanImplementation c
.\tools\build-dos.ps1 -TurbulentScanImplementation asm
~~~

`c` is the default and retains the full C entry point. `asm` selects the
hand-written i486 scan setup and interpolation, keeps the C reference in
benchmark builds, and writes to the separate `out\dos-turbscan` directory.
`TurbulentImplementation` still independently selects the inner pixel-store
loop.

The surface-level `R_BuildLightMap` dispatcher is selectable with
`-LightMapBuildImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -LightMapBuildImplementation c
.\tools\build-dos.ps1 -LightMapBuildImplementation asm
.\tools\bench-dos.ps1 -LightMapBuildImplementation asm -LightMapBuildOnly
~~~

`c` is the release default. `asm` selects the hand-written i486 dispatcher and
uses a separate `lightmapbuildasm` output suffix. Benchmark builds retain
`R_BuildLightMap_C` as the parity reference; the existing lightmap style, fused,
dynamic-light, and normalization selectors still choose their helpers separately.
`-LightMapBuildOnly` runs the focused dispatcher parity harness.

The sparse dynamic-light orchestration is independently selectable with
`-DynamicLightOrchestrationImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -DynamicLightOrchestrationImplementation c
.\tools\build-dos.ps1 -DynamicLightOrchestrationImplementation asm
.\tools\bench-dos.ps1 -DynamicLightOrchestrationImplementation asm -LightMapBuildImplementation asm -LightMapBuildOnly
~~~

`c` is the release default. `asm` selects the hand-written sparse surface-light
bit traversal and per-light dispatch; `DynamicLightImplementation` still
independently chooses the texel sample loop. Assembly also owns the x87
projection, float-to-integer conversion, and surface cull; benchmark builds keep
the C projection and orchestration references. The focused lightmap-build harness
includes empty and active dynamic-light cases plus direct projection comparisons.

The surface-cache dynamic-light predicate is independently selectable with
`-DlightContributesImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -DlightContributesImplementation c
.\tools\build-dos.ps1 -DlightContributesImplementation asm
.\tools\bench-dos.ps1 -DlightContributesImplementation asm -LightMapBuildImplementation asm -LightMapBuildOnly
~~~

`c` is the release default. `asm` selects the `R_DlightContributes` i486
routine, which traverses sparse light bits and shares the assembly projection
helper with `R_AddDynamicLights`. Benchmark builds retain the C predicate for
the direct 36-case parity harness, including all four x87 rounding modes.

`-SurfaceCacheImplementation c|asm` independently selects the surface-cache
hit check, key loads, miss-path metadata, texture/style tags, allocator,
attachment, draw dispatch, and dynamic-light tag update:

~~~powershell
.\tools\build-dos.ps1 -SurfaceCacheImplementation c
.\tools\build-dos.ps1 -SurfaceCacheImplementation asm
.\tools\bench-dos.ps1 -SurfaceCacheImplementation asm -SurfaceCacheOnly
.\tools\smoke-dos.ps1 -SurfaceCacheImplementation asm
.\tools\timedemo-dos.ps1 -SurfaceCacheImplementation asm -Runs 1
.\tools\smoke-dos.ps1 -SurfaceCacheImplementation asm -SurfaceDrawImplementation asm
.\tools\timedemo-dos.ps1 -SurfaceCacheImplementation asm -SurfaceDrawImplementation asm -Runs 1
.\tools\timedemo-dos.ps1 -SurfaceCacheImplementation asm -SurfaceDrawImplementation asm -Instrumentation -Runs 1
~~~

`c` is the release default. The assembly entry stages the animated texture and
four style values, checks the cache, fills mip/extent fields on a miss, runs the
rover allocator when needed, attaches the block, writes tags, and dispatches
through the selected `R_DrawSurface` entry. It also updates the sticky
dynamic-light tag after drawing. `-SurfaceCacheOnly` checks four complete
public-entry hits across mips 0–3, eight extent/mip setup cases, cache-tag
parity, a seven-allocation sequence, four attachment cases, and four light-tag
states. The combined timedemo command above exercises the full cache-miss draw
path; its accepted result is recorded in the renderer-port ledger.

With `-Instrumentation`, `timedemo-dos.ps1` resolves and stages `qprof.exe`
before its freshness check. Combined benchmark/profile object files use the
compact `obj-bp` directory. For long selector profiles, the builder keeps the
descriptive output path while it fits; if an object or executable path would
exceed 259 characters, `-DumpFlags` resolves that cache or profile to a
deterministic hashed sibling under `out\`. `-Clean` resolves the same paths.

The full surface draw setup is selectable independently with
`-SurfaceDrawImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -SurfaceDrawImplementation c
.\tools\build-dos.ps1 -SurfaceDrawImplementation asm
.\tools\bench-dos.ps1 -SurfaceDrawImplementation asm -SurfaceDrawOnly
.\tools\smoke-dos.ps1 -SurfaceDrawImplementation asm
.\tools\timedemo-dos.ps1 -SurfaceDrawImplementation asm -Runs 1
~~~

`c` remains the release default and retains the original body as the benchmark
reference. The assembly entry calls the selected `R_BuildLightMap`, prepares
texture and surface state, handles both POT and NPOT wrapping, and dispatches
directly to the existing assembly mip-0 through mip-3 surface block drawers.
The focused harness compares complete scratch output, `blocklights`, and
renderer globals across 40 mip, texture-shape, and lightmap combinations. The
assembly path does not complete the render-time dependency closure; that work
remains tracked in the renderer-port ledger.

The per-face Z-gradient setup is selectable with
`-SurfaceZGradientImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -SurfaceZGradientImplementation c
.\tools\build-dos.ps1 -SurfaceZGradientImplementation asm
.\tools\bench-dos.ps1 -SurfaceZGradientImplementation asm -SurfaceZGradientOnly
.\tools\smoke-dos.ps1 -SurfaceZGradientImplementation asm
.\tools\timedemo-dos.ps1 -SurfaceZGradientImplementation asm -Runs 1
~~~

`c` is the release default. The assembly entry preserves the plane/entity/frame
cache, calls the existing assembly `TransformVector` routine on a miss, and
matches the C compiler's x87 operation order, including extended-precision
intermediates. Benchmark builds retain `R_SetSurfaceZGradients_C`; the focused
parity command checks cache hits and key changes across all four x87 rounding
modes. One pinned timedemo confirmed 969-frame framebuffer checksum parity; its
single timing is not a speed comparison.

`D_CalcGradients` and its texture-axis cache are selectable with
`-SurfaceGradientImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -SurfaceGradientImplementation c
.\tools\build-dos.ps1 -SurfaceGradientImplementation asm
.\tools\bench-dos.ps1 -SurfaceGradientImplementation asm -SurfaceGradientOnly
.\tools\smoke-dos.ps1 -SurfaceGradientImplementation asm
.\tools\timedemo-dos.ps1 -SurfaceGradientImplementation asm -Runs 1
~~~

`c` remains the release default. The assembly path owns the gradient math and
an independent texture-axis cache sized by `-TextureAxisCacheEntries`; misses
call the existing assembly `TransformVector`. Benchmark builds retain
`D_CalcGradients_C`. The focused parity command checked 20 combinations across
mip levels, cache hits and key
changes, and all four x87 rounding modes. The assembly release passed DOS smoke,
the i486 ISA gate with 168 enforced above-i486 instructions against the 170
baseline, and the pinned 969-frame checksum `1047377823`. Its 59.120912-second
timedemo is one output-parity sample, not a speed comparison.

The per-frame `D_DrawSurfaces` dispatcher is selectable with
`-SurfaceDispatcherImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -SurfaceDispatcherImplementation c
.\tools\build-dos.ps1 -SurfaceDispatcherImplementation asm
.\tools\smoke-dos.ps1 -SurfaceDispatcherImplementation asm
.\tools\timedemo-dos.ps1 -SurfaceDispatcherImplementation asm -Runs 1
~~~

`c` remains the release default and the benchmark reference. The assembly entry
owns surface traversal, mip-scale table setup, draw-flat handling, sky/background/
turbulent/textured selection, z-gradient loads, and brush-model/world-state
switches. Compile-time layout assertions protect its `surf_t`, `entity_t`,
`surfcache_t`, texture, and cvar offsets. Cache, gradient, mip, sky, solid,
turbulent, texture-span, and Z-span routines remain independently selectable;
this dispatcher stage does not close the world/BSP or render-time dependency
closure. The release assembly build passed the ISA gate with 168 enforced
above-i486 instructions against the 170 baseline, DOS smoke passed, and the
pinned timedemo completed 969 frames with checksum `1047377823` in 59.208935 s.
That single timing confirms output parity, not a speedup.

The 16-pixel texture-span store loop is independently selectable with
`-TextureSpanStores word|byte|dword|loop`:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -TextureSpanStores word
.\tools\build-dos.ps1 -Benchmark -TextureSpanStores byte
.\tools\build-dos.ps1 -Benchmark -TextureSpanStores dword
.\tools\build-dos.ps1 -Benchmark -TextureSpanStores loop
~~~

The negative-gradient Z-span loop is selectable with
`-ZSpanNegativeUnroll unroll8|control`. `control` is the production
default; `unroll8` retains the eight-pixel experiment for matched correctness
and timing comparisons. The experiment was rejected after three matched runs:
both variants completed 969 frames with checksum `1047377823`, while control
measured `59.408069` seconds median and `unroll8` measured `59.408076` seconds.

The follow-up `PROFILE486` run (`out\dos-timedemo-20260928-060116`) completed
969 frames with checksum `1047377823`. Its instrumented self-time ranking was
texture spans 28.11%, alias models 13.38%, world BSP 11.49%, surface cache
10.03%, Z spans 9.37%, and edge scanning 9.00%. The instrumented 67.271233
second duration is attribution evidence, not a release timing claim; texture
span work is the next optimization target.

~~~powershell
.\tools\build-dos.ps1 -Benchmark -ZSpanNegativeUnroll unroll8
.\tools\build-dos.ps1 -Benchmark -ZSpanNegativeUnroll control
~~~

`word` is now the production default.  It preserves the original texture/DDA
sampling order and packs adjacent destination pixels with 16-bit stores in the
full 16-pixel path.  The current seeded control recheck measured
59.408238, 59.408105, and 59.408106 seconds (median 59.408106), all with
969 frames and framebuffer checksum `1047377823`.  The earlier 59.497xxx /
4154140932 result is retained only as historical evidence.  The explicit `byte` control
uses the original unrolled stores and writes `out\dos-spanbyte`; `dword` packs
four destination pixels per `movl` and writes `out\dos-spandword`; `loop` uses
`stosb` in 7+8 pixel loops and writes `out\dos-spanloop`.  All variants retain
the exact checksum gate.


### Sections moved out of this document

Each of these was a restatement of an experiment the ledger already
records in full. The ledger copy is canonical; the copy that used to sit
here said the same thing in fewer words.

| Section | Now recorded in | Why it left |
|---|---|---|
| **Texture-span row-cross experiment (2026-09-28)** | [`docs/ledger/2026-09-28-span-micro-experiments.md`](docs/ledger/2026-09-28-span-micro-experiments.md) | duplicate of the ledger copy |
| **Texture-span address-update experiment (2026-09-28)** | [`docs/ledger/2026-09-28-span-micro-experiments.md`](docs/ledger/2026-09-28-span-micro-experiments.md) | duplicate of the ledger copy |
| **Texture-span load-order experiment (2026-09-28)** | [`docs/ledger/2026-09-28-span-micro-experiments.md`](docs/ledger/2026-09-28-span-micro-experiments.md) | duplicate of the ledger copy |
| **Alias-model prepare source-cursor experiment (2026-09-28)** | [`docs/ledger/2026-09-28-span-micro-experiments.md`](docs/ledger/2026-09-28-span-micro-experiments.md) | duplicate of the ledger copy |
| **Alias-span address-update experiment (2026-09-28)** | [`docs/ledger/2026-09-28-span-micro-experiments.md`](docs/ledger/2026-09-28-span-micro-experiments.md) | duplicate of the ledger copy |
| **World-BSP frame-count cache experiment (2026-09-28)** | [`docs/ledger/2026-09-28-span-micro-experiments.md`](docs/ledger/2026-09-28-span-micro-experiments.md) | duplicate of the ledger copy |
| **Texture-span tail-store experiment (2026-09-28)** | [`docs/ledger/2026-09-28-span-micro-experiments.md`](docs/ledger/2026-09-28-span-micro-experiments.md) | duplicate of the ledger copy |

## Runtime smoke test

Place legally obtained Quake data in the ignored directory:

~~~text
testdata\id1\pak0.pak
testdata\id1\pak1.pak
~~~

The data must live on the same volume as the repository, because the runners
hardlink the paks into each staging directory rather than copying them and NTFS
hardlinks cannot span volumes.  If you keep your game data on another volume,
copy the two paks to `testdata\id1` and drop `-DataRoot`.

Then run:

~~~powershell
.\tools\smoke-dos.ps1
~~~

The script stages a fresh DOS directory under out\dos-smoke, starts
DOSBox-X, initializes the DOS software renderer with sound/input/CD disabled,
and exits through the Quake command line.  It verifies both the DOSBox-X exit
code and a Quake exit marker.  The staged runtime uses the normal Quake layout:
`quake.exe`, `cwsdpmi.exe`, and the `id1` directory are siblings under the
mounted `quake` directory.  Use -DataRoot to point at another local data
directory, `-OptimizationProfile baseline` to smoke the `-O2` build, or
-SkipBuild when the executable is already available.
The runner stages only `pak*.pak` as hardlinks (not Steam configs, saves, or
autoexec files), writes a local `autoexec.cfg` containing `quit`, and launches
with
`-stdvid -forcquit +quit` so the attract demos and the Y/N quit menu cannot
hold the 486 cycle cap.  `-forcquit` also skips `Con_NotifyBox` key waits and
the VGA sell screen.  The generated smoke configuration is the pinned
`dosbox-x-486-high.conf` profile with a replaced `[autoexec]` section
(`cputype=486`, fixed 33445 cycles, 16 MB).  On this host, DOSBox-X opened
its folder chooser with the otherwise-valid 32 MB setting.  The memory choice
is a compatibility setting, not a performance claim.

For interactive play, use the same mounted directory and omit the timedemo
commands.  The following starts the current default build with sound, joystick,
mouse, and CD audio disabled:

~~~powershell
$dosbox = Join-Path $env:LOCALAPPDATA '486quake\tools\dosbox-x-2026.08.31\dosbox-x.exe'
$profile = (Resolve-Path '.\tools\dosbox-x-486-high.conf').Path
$mount = (Resolve-Path '.\out\dos-smoke').Path.Replace('\', '/')
& $dosbox -conf $profile `
  -c ('mount c "' + $mount + '"') `
  -c 'c:' `
  -c 'cd \quake' `
  -c 'quake.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio'
~~~

## 486-class timedemo

### Current seeded A/B reference

For current PROFILE486 work, src/cl_demo.c seeds srand(1) when a timedemo
begins. This stabilizes random entity animation phases for performance
comparisons. The resulting current-worktree framebuffer checksum is
1047377823; the older 4154140932 value in historical experiment records is not
interchangeable with this seeded reference.

The current raw VGA reference is 969 frames in a median 59.408106 seconds
(16.310905 FPS) across three runs, with checksum 1047377823 on every run.
When comparing optional implementations, rebuild each selector separately and
hold the DOSBox-X profile, DPMI host, data directory, command line, and random
seed constant. Keep an implementation only when its complete timedemo improves
repeatably and preserves the current checksum.

### Cross-version comparison (2026-09-28)

The current project build was also compared with the supplied `NitroQuake.exe`
optimization project and original `QUAKE.EXE` under the same DOSBox-X profile,
data set, `demo1` workload, and 969-frame timedemo. The current build measured
**16.310912 FPS** (59.408082 seconds median across three runs), compared with
approximately **14.2 FPS** for `NitroQuake.exe` and **13.4 FPS** for the original.
The current build was approximately 21.9% faster than the original and 14.8%
faster than `NitroQuake.exe`.

The detailed comparison, executable hashes, and evidence limitations are in
[`BENCHMARK-COMPARISON.md`](BENCHMARK-COMPARISON.md). The two supplied
executables report their result on-screen rather than producing the repository
runner's machine-readable timing and checksum files, so their values are
rounded single-run observations.

### Latest validation notes

### Historical pre-experiment reference

The earlier reported **14 FPS** (rounded) is reproducible on the pinned
profile.  A three-run raw `demo1` reference measurement on 2026-09-09, before
the currently selected ASM paths were promoted,
produced 969 frames per run and a median of **13.995834 FPS** (`69.234885`
seconds for the median run).
The runs used `qbench.exe`, the default `baseline` optimization profile,
DOSBox-X 2026.08.31, `cputype=486`, and fixed 33445 cycles.  The result is
recorded under `out\dos-timedemo-*\timedemo-result.json` and is emulator
evidence, not a native Windows performance measurement.

Use the repository runner for repeatable measurements instead of manually
copying executables:

~~~powershell
.\tools\timedemo-dos.ps1 -Runs 3
~~~

It stages a fresh DOS directory for every run, hardlinking `pak*.pak` from
`testdata\id1` instead of copying them, so `out\` stays small, writes six-decimal
timing data, and reports the median FPS.  The runner only compiles `qbench.exe` when that
file is missing; after source changes run `.\tools\build-dos.ps1 -Benchmark`
first, then `timedemo-dos.ps1 -SkipBuild`.  Keep the demo name, DOSBox-X
version, 486 profile, fixed cycle count, video mode, optimization profile, and
command-line options unchanged when comparing results.  By default it adds `-fpsstats`, preserving
the original average-FPS line while also measuring every timedemo frame.
Use `-NoFpsStats` for a raw comparison when measuring the cost of collecting
the extra statistics.  The raw result is the authority for small engine-speed
comparisons; the rich result is the authority for frame-time consistency.

### Alternate DPMI host (HDPMI32 experiment)

The default staging still copies `cwsdpmi.exe` beside the EXE.  For an isolated
DPMI-server A/B without rebuilding Quake:

~~~powershell
.\tools\timedemo-dos.ps1 -SkipBuild -DpmiHost hdpmi32 -Runs 5
.\tools\compare-dpmi-dos.ps1 -SkipBuild -Runs 5
~~~

`-DpmiHost hdpmi32` stages Japheth's `HDPMI32.EXE` from
`tools\thirdparty\hdpmi\`, omits `cwsdpmi.exe`, runs `HDPMI32 -r`, and records
a `DPMI.EXE` host probe.  A 2026-09-15 five-run matched comparison showed
HDPMI32 completes timedemos but fails the known-good framebuffer checksum
(`2955717646` vs `4154140932`) on every run, so **CWSDPMI remains the preferred
host**.  Full write-up: `DPMI-HDPMI32.md`.

For an odd number of runs, the runner selects the middle sorted sample.  Older
generated JSON records may contain the highest sample in `medianFps`; use the
individual `results` entries when auditing those records.

### Current committed default baseline

The current measured default after EmitEdge memory `subl C(surfaces)` on
LSide1/LSide0 is `62.580216 / 62.580291 / 62.580319` seconds, median
**15.484108 FPS** / **62.580291 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-211623\timedemo-result.json`).  That is about
8.0 ms faster than the prior EmitEdge u-clamp memory `cmpl` default at
**15.482121 FPS** / 62.588326 s (`out\dos-timedemo-20260915-210614`).

The prior EmitEdge u-clamp memory `cmpl` measured
`62.588579 / 62.588326 / 62.588325` seconds, median **15.482121 FPS** /
**62.588326 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-210614\timedemo-result.json`).  That is about
16.8 ms faster than the prior RecursiveTriangle-midpoint default at
**15.477961 FPS** / 62.605144 s (`out\dos-timedemo-20260915-205607`).

The prior RecursiveTriangle memory `addl` s/t/zi midpoints measured
`62.605330 / 62.605144 / 62.605103` seconds, median **15.477961 FPS** /
**62.605144 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-205607\timedemo-result.json`).  That is about
16.6 ms faster than the prior EmitEdge-`r_ceilv1` default at
**15.473853 FPS** / 62.621766 s (`out\dos-timedemo-20260915-204522`).

The prior EmitEdge defer `r_ceilv1` past horizontal EO measured
`62.621949 / 62.621766 / 62.621726` seconds, median **15.473853 FPS** /
**62.621766 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-204522\timedemo-result.json`).  That is about
2.0 ms faster than the prior leading `Lnewtop` memory `cmpl st_last_u`
default at **15.473368 FPS** / 62.623729 s
(`out\dos-timedemo-20260915-203108`).

The prior leading `Lnewtop` memory `cmpl st_last_u` measured
`62.623894 / 62.623729 / 62.623708` seconds, median **15.473368 FPS** /
**62.623729 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-203108\timedemo-result.json`).  That is about
25.9 ms faster than the prior StepActiveU-`et_u_step` default at
**15.466979 FPS** / 62.649598 s (`out\dos-timedemo-20260915-202546`).

The prior StepActiveU memory `addl et_u_step` measured
`62.651188 / 62.649598 / 62.649569` seconds, median **15.466979 FPS** /
**62.649598 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-202546\timedemo-result.json`).  That is about
104.3 ms faster than the prior ScanLeftEdge last-row Bresenham-skip default
at **15.441270 FPS** / 62.753905 s (`out\dos-timedemo-20260915-200539`).

The prior ScanLeftEdge skip dead last-row Bresenham measured
`62.810895 / 62.753822 / 62.753905` seconds, median **15.441270 FPS** /
**62.753905 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-200539\timedemo-result.json`).  That is about
28.7 ms faster than the prior TrailingEdge memory `cmpl st_last_u` default
at **15.434201 FPS** / 62.782647 s (`out\dos-timedemo-20260915-190100`).

The prior TrailingEdge memory `cmpl st_last_u` measured
`62.782709 / 62.782647 / 62.782532` seconds, median **15.434201 FPS** /
**62.782647 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-190100\timedemo-result.json`).  That is about
0.9 ms faster than the prior `LPushBackLoop` memory `cmpl et_u` default at
**15.433983 FPS** / 62.783533 s (`out\dos-timedemo-20260915-184357`).

The prior `LPushBackLoop` memory `cmpl et_u` measured
`62.783709 / 62.783486 / 62.783533` seconds, median **15.433983 FPS** /
**62.783533 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-184357\timedemo-result.json`).  That is about
3.7 ms faster than the prior InsertNewEdges memory `cmpl et_u` default at
**15.433068 FPS** / 62.787258 s (`out\dos-timedemo-20260915-183750`).

The prior InsertNewEdges memory `cmpl et_u` measured
`62.787043 / 62.787258 / 62.787362` seconds, median **15.433068 FPS** /
**62.787258 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-183750\timedemo-result.json`).  That is about
43.3 ms faster than the prior Aff8 multi last-group-skip default at
**15.422436 FPS** / 62.830543 s (`out\dos-timedemo-20260915-182515`).

The prior Aff8 multi skip dead last-group stepper measured
`62.830458 / 62.830543 / 62.830579` seconds, median **15.422436 FPS** /
**62.830543 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-182515\timedemo-result.json`).  That is about
123.2 ms faster than the prior leading sort-loop memory `cmpl st_key`
default at **15.392244 FPS** / 62.953783 s
(`out\dos-timedemo-20260915-180350`).

The prior leading sort-loop memory `cmpl st_key` measured
`62.953648 / 62.953783 / 62.953854` seconds, median **15.392244 FPS** /
**62.953783 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-180350\timedemo-result.json`).  That is about
52.8 ms faster than the prior RecursiveTriangle live-new-into-LDraw default
at **15.379351 FPS** / 63.006559 s (`out\dos-timedemo-20260915-174638`).

The prior RecursiveTriangle live `new[]` into LDraw measured
`63.006416 / 63.006581 / 63.006559` seconds, median **15.379351 FPS** /
**63.006559 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-174638\timedemo-result.json`).  That is about
5.5 ms faster than the prior leading memory `cmpl` first-`st_key` default at
**15.378020 FPS** / 63.012013 s (`out\dos-timedemo-20260915-173942`).

The prior leading memory `cmpl` first `st_key` measured
`63.011902 / 63.012013 / 63.012104` seconds, median **15.378020 FPS** /
**63.012013 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-173942\timedemo-result.json`).  That is about
72.4 ms faster than the prior FinalVerts light<<8 default at
**15.360381 FPS** / 63.084374 s (`out\dos-timedemo-20260915-172059`).

The prior FinalVerts Aff8-style light<<8 index measured
`63.084563 / 63.084374 / 63.084351` seconds, median **15.360381 FPS** /
**63.084374 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-172059\timedemo-result.json`).  That is about
2.9 ms faster than the prior RemoveEdges both-stores-then-advance default at
**15.359677 FPS** / 63.087263 s (`out\dos-timedemo-20260915-171204`).

The prior RemoveEdges both-stores-then-advance measured
`63.087380 / 63.087263 / 63.087206` seconds, median **15.359677 FPS** /
**63.087263 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-171204\timedemo-result.json`).  That is about
4.2 ms faster than the prior StepActiveU deferred step-loop `et_next`
default at **15.358664 FPS** / 63.091427 s
(`out\dos-timedemo-20260915-165144`).

The prior StepActiveU deferred step-loop `et_next` measured
`63.091567 / 63.091379 / 63.091427` seconds, median **15.358664 FPS** /
**63.091427 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-165144\timedemo-result.json`).  That is about
11.3 ms faster than the prior EmitEdge deferred `r_framecount` default at
**15.355923 FPS** / 63.102686 s (`out\dos-timedemo-20260915-163753`).

The prior EmitEdge defer `r_framecount` past cacheoffset EO measured
`63.102870 / 63.102606 / 63.102686` seconds, median **15.355923 FPS** /
**63.102686 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-163753\timedemo-result.json`).  That is about
0.5 ms faster than the prior `LPushBackLoop` deferred `et_prev` default at
**15.355803 FPS** / 63.103178 s (`out\dos-timedemo-20260915-160134`).

The prior StepActiveU `LPushBackLoop` deferred `et_prev` measured
`63.103349 / 63.103178 / 63.103124` seconds, median **15.355803 FPS** /
**63.103178 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-160134\timedemo-result.json`).  That is about
2.1 ms faster than the prior InsertNewEdges deferred `et_next` default at
**15.355295 FPS** / 63.105267 s (`out\dos-timedemo-20260915-154958`).

The prior InsertNewEdges defer `et_next` (probes 1–3) measured
`63.105419 / 63.105230 / 63.105267` seconds, median **15.355295 FPS** /
**63.105267 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-154958\timedemo-result.json`).  That is about
7.4 ms faster than the prior StepActiveU aftertail deferred-unlink default
at **15.353497 FPS** / 63.112658 s (`out\dos-timedemo-20260915-153501`).

The prior StepActiveU defer `et_prev`/`et_next` past `edge_aftertail`
measured `63.113353 / 63.112658 / 63.112628` seconds, median
**15.353497 FPS** / **63.112658 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-153501\timedemo-result.json`).  That is about
9.1 ms faster than the prior RecursiveTriangle deferred-`|dy|`-y-loads
default at **15.351272 FPS** / 63.121804 s
(`out\dos-timedemo-20260915-150014`).

The prior RecursiveTriangle defer same-edge y loads past `|dx|` early-out
measured `63.121965 / 63.121804 / 63.121646` seconds, median
**15.351272 FPS** / **63.121804 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-150014\timedemo-result.json`).  That is about
17.6 ms faster than the prior split-prefetch defer default at
**15.346986 FPS** / 63.139434 s (`out\dos-timedemo-20260915-144910`).

The prior RecursiveTriangle defer next-edge prefetches past `|dy|` split
measured `63.139641 / 63.139434 / 63.139417` seconds, median
**15.346986 FPS** / **63.139434 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-144910\timedemo-result.json`).  That is about
1.7 ms faster than the prior `lp2[0]`-defer default at **15.346585 FPS** /
63.141084 s (`out\dos-timedemo-20260915-140237`).

The prior RecursiveTriangle defer `lp2[0]` until equal-`y` measured
`63.141181 / 63.141050 / 63.141084` seconds, median **15.346585 FPS** /
**63.141084 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-140237\timedemo-result.json`).  That is about
2.2 ms faster than the prior Aff8-one-long deferred-`ptex` default at
**15.346044 FPS** / 63.143310 s (`out\dos-timedemo-20260915-133615`).

The prior Aff8 one-long defer `ptex` past Z measured
`63.143406 / 63.143310 / 63.143203` seconds, median **15.346044 FPS** /
**63.143310 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-133615\timedemo-result.json`).  That is about
2.5 ms faster than the prior DrawSubdiv deferred-colormap default at
**15.345430 FPS** / 63.145837 s (`out\dos-timedemo-20260915-132507`).

The prior DrawSubdiv defer `d_pcolormap` past backface cull measured
`63.146060 / 63.145728 / 63.145837` seconds, median **15.345430 FPS** /
**63.145837 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-132507\timedemo-result.json`).  That is about
32.3 ms faster than the prior FinalVerts `movzbl` skin-texel default at
**15.337574 FPS** / 63.178180 s (`out\dos-timedemo-20260915-131025`).

The prior FinalVerts `movzbl` skin texel measured
`63.178491 / 63.178164 / 63.178180` seconds, median **15.337574 FPS** /
**63.178180 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-131025\timedemo-result.json`).  That is about
1.4 ms faster than the prior Aff8 pixel `movzbl` default at
**15.337229 FPS** / 63.179599 s (`out\dos-timedemo-20260915-125058`).

The prior Aff8 pixel `movzbl` colormap index measured
`63.179791 / 63.179533 / 63.179599` seconds, median **15.337229 FPS** /
**63.179599 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-125058\timedemo-result.json`).  That is about
85.9 ms faster than the prior RecursiveTriangle live-`new[]` default at
**15.316416 FPS** / 63.265453 s (`out\dos-timedemo-20260915-124237`).

The prior RecursiveTriangle live `new[0]`/`new[1]` into LDraw measured
`63.265572 / 63.265453 / 63.265414` seconds, median **15.316416 FPS** /
**63.265453 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-124237\timedemo-result.json`).  That is about
1.8 ms faster than the prior EmitEdge deferred-`edge_p` default at
**15.315969 FPS** / 63.267301 s (`out\dos-timedemo-20260915-122259`).

The prior EmitEdge defer `edge_p` past horizontal EO measured
`63.267487 / 63.267234 / 63.267301` seconds, median **15.315969 FPS** /
**63.267301 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-122259\timedemo-result.json`).  That is about
14.2 ms faster than the prior leading spanstate `movl $1` default at
**15.312538 FPS** / 63.281476 s (`out\dos-timedemo-20260915-120825`).

The prior leading spanstate `movl $1` measured
`63.281763 / 63.281476 / 63.281405` seconds, median **15.312538 FPS** /
**63.281476 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-120825\timedemo-result.json`).  That is about
73.6 ms faster than the prior TrailingEdge memory-`decl`-spanstate default
at **15.294737 FPS** / 63.355125 s (`out\dos-timedemo-20260915-115111`).

The prior TrailingEdge memory `decl` of `spanstate` measured
`63.355242 / 63.355064 / 63.355125` seconds, median **15.294737 FPS** /
**63.355125 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-115111\timedemo-result.json`).  That is about
133.0 ms faster than the prior clipped-`r_pedge`-load-drop default at
**15.262705 FPS** / 63.488089 s (`out\dos-timedemo-20260915-113652`).

The prior drop unused clipped `r_pedge` load measured
`63.488166 / 63.488089 / 63.488004` seconds, median **15.262705 FPS** /
**63.488089 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-113652\timedemo-result.json`).  That is about
12.9 ms faster than the prior bmodel `incl`/`decl` default at
**15.259612 FPS** / 63.500960 s (`out\dos-timedemo-20260915-111815`).

The prior bmodel `incl`/`decl` of `r_bmodelactive` measured
`63.501194 / 63.500915 / 63.500960` seconds, median **15.259612 FPS** /
**63.500960 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-111815\timedemo-result.json`).  That is about
22.8 ms faster than the prior TrailingEdge world-skip default at
**15.254125 FPS** / 63.523798 s (`out\dos-timedemo-20260915-110651`).

The prior TrailingEdge skip of `r_bmodelactive` RMW measured
`63.523808 / 63.523798 / 63.523763` seconds, median **15.254125 FPS** /
**63.523798 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-110651\timedemo-result.json`).  That is about
49.4 ms faster than the prior EmitEdge-`r_pedge` single-load default at
**15.242273 FPS** / 63.573196 s (`out\dos-timedemo-20260915-104810`).

The prior EmitEdge single `r_pedge` load measured
`63.573476 / 63.573196 / 63.573176` seconds, median **15.242273 FPS** /
**63.573196 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-104810\timedemo-result.json`).  That is about
10.4 ms faster than the prior TrailingEdge-unlink default at
**15.239772 FPS** / 63.583628 s (`out\dos-timedemo-20260915-103948`).

The prior TrailingEdge unlink via live `%ecx` measured
`63.583853 / 63.583607 / 63.583628` seconds, median **15.239772 FPS** /
**63.583628 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-103948\timedemo-result.json`).  That is about
31.1 ms faster than the prior EmitEdge-pretouch-removal default at
**15.232323 FPS** / 63.614724 s (`out\dos-timedemo-20260915-102159`).

The prior EmitEdge next-edge pretouch removal measured
`63.615049 / 63.614724 / 63.614690` seconds, median **15.232323 FPS** /
**63.614724 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-102159\timedemo-result.json`).  That is about
8.5 ms faster than the prior ScanLeftEdge-pretouch default at
**15.230283 FPS** / 63.623244 s (`out\dos-timedemo-20260915-101018`).

The prior ScanLeftEdge pretouch removal measured
`63.623427 / 63.623209 / 63.623244` seconds, median **15.230283 FPS** /
**63.623244 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-101018\timedemo-result.json`).  That is about
29.0 ms faster than the prior dead-`st_key` default at **15.223339 FPS** /
63.652266 s (`out\dos-timedemo-20260915-094804`).

The prior dead `st_key` reload removal measured
`63.652309 / 63.652161 / 63.652266` seconds, median **15.223339 FPS** /
**63.652266 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-094804\timedemo-result.json`).  That is about
0.58 ms faster than the prior surfaces-CSE default at **15.223200 FPS** /
63.652849 s (`out\dos-timedemo-20260915-092321`).

The prior edge-scan `surfaces` CSE measured
`63.652962 / 63.652822 / 63.652849` seconds, median **15.223200 FPS** /
**63.652849 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-092321\timedemo-result.json`).  That is about
73.2 ms faster than the prior aspancount-spill default at **15.205710 FPS** /
63.726061 s (`out\dos-timedemo-20260915-080929`).

The prior ScanLeftEdge `%esi` package cursor measured
`63.783098 / 63.783005 / 63.782908` seconds, median **15.192135 FPS** /
**63.783005 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-064521\timedemo-result.json`).  That is about
112.1 ms faster than the prior Z-span `%ebp` default at **15.165488 FPS** /
63.895076 s (`out\dos-timedemo-20260915-055029`).

The prior Z-span `%ebp` list cursor measured
`63.895311 / 63.895076 / 63.895065` seconds, median **15.165488 FPS** /
**63.895076 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-055029\timedemo-result.json`).  That is about
89.3 ms faster than the prior left-edge CSE default at **15.144318 FPS** /
63.984395 s (`out\dos-timedemo-20260915-051520`).

The prior left-edge s/t step CSE measured
`63.984653 / 63.984268 / 63.984395` seconds, median **15.144318 FPS** /
**63.984395 s**, checksum `4154140932`
(`out\dos-timedemo-20260915-051520\timedemo-result.json`).  That is about
18.9 ms faster than the prior advancetable default at **15.139851 FPS** /
64.003272 s (`out\dos-timedemo-20260914-182901`).  An earlier CSE set
(`out\dos-timedemo-20260915-051014`) matched the checksum with a run-2
hitch; the 051520 rebenchmark confirms the keep without the hitch.

The prior polyset span advancetable hoist measured
`64.003358 / 64.003148 / 64.003272` seconds, median **15.139851 FPS** /
**64.003272 s**, checksum `4154140932`
(`out\dos-timedemo-20260914-182901\timedemo-result.json`).  That is about
88.9 ms faster than the prior phantom-mark default at **15.118851 FPS** /
64.092171 s (`out\dos-timedemo-20260914-180707`).

The prior phantom-mark dlight probe measured
`64.092357 / 64.092171 / 64.092163` seconds, median **15.118851 FPS** /
**64.092171 s**, checksum `4154140932`
(`out\dos-timedemo-20260914-180707\timedemo-result.json`).  That is about
11.9 ms faster than the prior adivtab-64 default at **15.116037 FPS** /
64.104105 s (`out\dos-timedemo-20260914-164951`).

The prior alias `adivtab` 32→64 measured
`64.104105 / 64.103726 / 64.569991` seconds, median **15.116037 FPS** /
**64.104105 s**, checksum `4154140932`
(`out\dos-timedemo-20260914-164951\timedemo-result.json`).  That is about
9.7 ms faster than the prior sticky-dlight default at **15.113744 FPS** /
64.113828 s (`out\dos-timedemo-20260914-163457`).

The prior sticky `cache->dlight` flag measured
`64.114027 / 64.113796 / 64.113828` seconds, median **15.113744 FPS** /
**64.113828 s**, checksum `4154140932`
(`out\dos-timedemo-20260914-163457\timedemo-result.json`).  That is about
14.8 ms faster than the prior MarkLights idist-cull default at
**15.110264 FPS** / 64.128594 s (`out\dos-timedemo-20260914-143404`).

The prior MarkLights clamp-to-rect idist cull measured
`64.128632 / 64.128594 / 64.128523` seconds, median
**15.110264 FPS** / **64.128594 s**, checksum `4154140932`
(`out\dos-timedemo-20260914-143404\timedemo-result.json`).  That is about
125.4 ms faster than the prior AABB-expand default at **15.080783 FPS** /
64.253958 s (`out\dos-timedemo-20260914-142303`).  A follow-up 2x2 discrete
sample cull matched the checksum but was 112.5 ms slower
(`out\dos-timedemo-20260914-161209`) and was reverted.  An
`R_AddDynamicLights` s/t sample-window clamp failed checksum
`696680082` on run 2 (`out\dos-timedemo-20260914-162709`) and was
reverted.  An `R_AliasClip` aliasvrect hoist plus skip-Z-reflag matched
checksum `4154140932` but was 42.4 ms slower
(`out\dos-timedemo-20260914-181813`) and was reverted.  A polyset
`a_sstepxfrac`→BSS `sstep` hoist matched the checksum but was 9.1 ms
slower (`out\dos-timedemo-20260914-183707`) and was reverted.  Local
copies of polyset right-edge Bresenham constants matched the checksum
but were 36.7 ms slower (`out\dos-timedemo-20260914-184757`) and were
reverted.  A left-edge `d_ptexextrastep` rewrite via `a_ststepxwhole`
matched the checksum but was 76.5 ms slower
(`out\dos-timedemo-20260915-053730`) and was reverted.  Tagging the
Z-span `%ebp` cursor bit0 to drop the count push/pop matched the
checksum but was 64.6 ms slower (`out\dos-timedemo-20260915-060125`)
and was reverted.  A `D_PolysetScanLeftEdge` skinwidth stack hoist
matched the checksum but was 10.0 ms slower
(`out\dos-timedemo-20260915-061218`) and was reverted.  Stack-live
`d_aspancount`/`errorterm` in `D_PolysetDrawSpans8` matched the
checksum but was 36.7 ms slower (`out\dos-timedemo-20260915-065310`)
and was reverted.

A 2026-09-10 lock before this pass measured
`68.958977 / 68.958817 / 68.958799` seconds, median **14.051865 FPS**,
969 frames, checksum `4154140932`
(`out\dos-timedemo-20260910-221227\timedemo-result.json`).

An earlier checkpoint after skipping the unused `D_CacheSurface`
`surfscale` FDIV (plus inlined power-of-two surface wrap,
release-only skip of `D_CheckCacheGuard`, once-per-frame alias view
matrix, the `Mod_LoadTexinfo` nested-loop UB fix, `-O3`, cached bmodel
span rotations, fused lightmap writes, an integer dlight inner loop, a
per-plane Z-gradient cache, power-of-two column wrap, `zspantable`
Z-span addressing, `viewspantable` dest rows in texture spans,
polyset, sprites, and particles, `zspantable` Z addressing in
sprites and particles, a 1800 KB surface cache, `Turbulent8`
`viewspantable` dest rows, a static `D_CacheSurface` hit path, a
`D_PolysetDrawFinalVerts` clip-rect hoist, and unused extra light-style
skips on cache hits, `D_RasterizeAliasPolySmooth` dest/Z row tables,
`R_RenderFace` surfedges hoist plus clip unroll, the clipped-bmodel
surfedges hoist, `R_DrawSurface` 8-bit setup, and mipscale step tables)
completed
three `demo1` runs at
`67.085825 / 67.085569 / 67.085585` seconds, median **14.444235 FPS** /
**67.085585 s** (`out\dos-timedemo-20260911-191612\timedemo-result.json`).
That is about 6.3 ms faster than the mipscale-table default
(14.442880 FPS / 67.091882 s) with checksum `4154140932` on every run.
The `Turbulent8` dest-row default was about 1.3 ms faster than the 1800 KB default (14.409100 FPS /
67.249168 s).  1900 KB, 2000 KB, 2100 KB, and
2400 KB were faster but checksum `2955717646` (same hash as the
reverted texture-source row-lookup).  2x surface cache was **14.373452 FPS** / 67.415956 s
(`out\dos-timedemo-20260911-133815`).  Sprite/particle `zspantable`
was **14.252866 FPS** / 67.986326 s
(`out\dos-timedemo-20260911-065037`).  Extending `viewspantable` to polyset, sprites, and particles was
**14.251887 FPS** / 67.990997 s (`out\dos-timedemo-20260911-064221`).
Texture-span `viewspantable` dest addressing was **14.250078 FPS** /
67.999624 s (`out\dos-timedemo-20260911-063418`).  Z-span `zspantable`
addressing was **14.239663 FPS** / 68.049361 s
(`out\dos-timedemo-20260911-062059`).  Power-of-two column
wrap was **14.208790 FPS** / 68.197221 s
(`out\dos-timedemo-20260911-054347`).  The Z-gradient
cache was **14.208466 FPS** / 68.198777 s
(`out\dos-timedemo-20260911-053759`).  The integer dlight
inner loop was **14.206133 FPS** / 68.209972 s
(`out\dos-timedemo-20260911-052933`).  Extra-style fusion was **14.194657 FPS**
/ 68.265121 s (`out\dos-timedemo-20260911-051834`).  One-style-only
fusion was **14.194521 FPS** / 68.265779 s
(`out\dos-timedemo-20260911-051131`).  Both `-O2` and
`-O3` `quake.exe +quit` smokes now complete in about 12 seconds on the pinned
profile after `-forcquit` / local `autoexec.cfg`.  The older
14.185365 FPS / 68.309838 s figure is retained as the previous fused
first-style lightmap default.  14.170874 FPS / 68.379696 s is the previous
bmodel-cache default.  14.162237 FPS / 68.421397 s is the previous `-O3`
default.  The 14.054401 FPS / 68.946370 s figure is retained as the previous
`-O2` default.  The 14.051872 FPS / 68.958785 s figure is retained as the
previous ASM-default `-O2` baseline.

### Per-frame FPS statistics

When `-fpsstats` is enabled, the timedemo records one wall-clock sample at the
start and end of each measured frame.  The fixed 8192-sample buffer is suitable
for the built-in demos and reports an overflow count instead of allocating from
the DOS heap.  Sorting and statistical calculations happen after the timed
interval, so they do not enter the FPS measurement.

The first line remains the original average FPS result.  Additional lines in
`timedemo.txt` include minimum and maximum single-frame FPS, median FPS, the
arithmetic mean of the slowest 1% and 0.1% of frames, the arithmetic mean of
the fastest 1%, selected percentiles, FPS standard deviation and variance, and
the number of significant drops and spikes.  A drop is a frame below 75% of
the run's average FPS; a spike is above 125%.  The longest consecutive run of
each event is also reported.  `mean-frame` may be higher than the benchmark
average because the benchmark average is frames divided by total duration,
whereas `mean-frame` is the arithmetic mean of each frame's reciprocal time.

Example:

~~~text
969 frames 69.248328 seconds 13.993117 fps
fps-summary frames 969 measured 969 stored 969 overflow 0 timer-reads 1939 duration 69.248328 average 13.993118 min 6.222621 max 28.422380 median 15.235517 low1 6.717671 low0.1 6.222621 high1 27.658456 mean-frame 15.507868 stddev 4.755007 variance 22.610091
fps-percentiles p0.1 6.222621 p1 7.068009 p5 8.212089 p50 15.235517 p95 23.622576 p99 26.565144 p99.9 28.422380
fps-events drop-threshold 10.494838 drops 159 longest-drop 16 spike-threshold 17.491397 spikes 296 longest-spike 43 invalid 0
~~~

The same summary is written as DOS-safe `timedemo.jsn`.  The PowerShell
runner embeds it under each run's `fpsStats` property and adds a
multi-run `fpsSummary` containing median values for comparison.  The JSON
also records the number of stored/overflowed samples and the frame-statistics
timer-read count.

A matched one-run overhead check on the pinned profile measured 69.248276
seconds with frame statistics and 69.235233 seconds with `-NoFpsStats`, or
approximately **0.019%** collection overhead.  Both runs completed all 969
frames and produced framebuffer checksum `4154140932`.

The default pass keeps the z-buffer base in a register across each z-span list
and reuses a dead register for the second packed depth pair.  The turbulent
span routine also loads its invariant table pointer once per span call.  The
depth arithmetic, water sampling, and turbulent-span color results are unchanged.

The release surface-cache header keeps the variable pixel tail at a four-byte
boundary and omits the unused debug-only height field.  This moves the pixel
data from offset 48 to 44 and recovers 4 bytes per allocated cache block;
builds with `DEBUG` retain the height field and original layout.  The cache
manager also skips redundant LRU unlink/relink work for a block already at
the head and returns newly allocated blocks directly.  These are memory and
allocator-path improvements; the matched timedemo change is within run noise.

Sprite model loading no longer clears each sprite frame a second time after
Hunk_AllocName returns it.  Hunk_AllocName already zeroes the complete,
16-byte-rounded allocation; Mod_LoadSpriteFrame then assigns its metadata and
fully writes the pixel tail through either the 8-bit copy or 16-bit conversion
path.  The allocation size and model layout are unchanged.  The cleanup passed
the 486 correctness harness and three seeded demo1 timedemos: 969 frames and
checksum 1047377823 on every run, with times 59.408076, 59.408052, and
59.408186 seconds.  This is a load-time memory-traffic cleanup rather than
an observed frame-rate gain.

The particle record packs its palette index and type into one byte each while
keeping the assembly-used offsets stable.  This shrinks each record from 44
to 40 bytes and saves 8 KiB in the default 2048-particle pool.  The 486
assembly drawer loads the palette byte directly instead of converting it
through the FPU.  Particle expiry is handled in one pointer-to-link walk,
and empty particle frames return before projection setup.  Brightfield
particle initialization now uses an explicit one-shot flag and no longer
evaluates an unused third-axis sine/cosine pair.
The final matched release timedemo remained within normal run noise, so these
particle changes are footprint and hot-path cleanups rather than a claimed
end-to-end FPS gain.

The renderer's per-frame texture-axis cache can be screened at 64, 128, or
256 entries without editing source files.  Each value uses a separate ignored
build directory:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -TextureAxisCacheEntries 128
.\tools\timedemo-dos.ps1 -TextureAxisCacheEntries 128 -Runs 3
~~~

A one-run demo1 screen under the same pinned profile completed all 969 frames
at 13.917021 FPS (64 entries), 13.917025 FPS (128), and 13.917031 FPS (256).
Those differences are within run noise, so the fidelity-preserving default
remains 256 entries.  Use matched multi-run measurements before selecting a
different footprint for a specific target.

For an AMD 5x86/486DX5-133-class target, add this option to the DOSBox-X
command line:

~~~powershell
-set 'cpu cycles=fixed 47810'
~~~

Keep the DOSBox-X version, profile, demo, and cycle setting unchanged when
comparing results.  Timedemo FPS is emulator evidence, not a native Windows
performance measurement.


### Sections moved out of this document

These were measurements, not build steps. Each is recorded verbatim in the
ledger, which is where a result belongs.

| Section | Now recorded in | Why it left |
|---|---|---|
| **Lightmap style accumulation** | [`docs/ledger/timedemo-baseline-history.md`](docs/ledger/timedemo-baseline-history.md) | a result, not a build step |
| **VGA full-frame copy experiment** | [`docs/ledger/timedemo-baseline-history.md`](docs/ledger/timedemo-baseline-history.md) | a result, not a build step |
| **Surface-cache capacity and churn** | [`docs/ledger/timedemo-baseline-history.md`](docs/ledger/timedemo-baseline-history.md) | a result, not a build step |
| **Surface-cache header locality experiment** | [`docs/ledger/timedemo-baseline-history.md`](docs/ledger/timedemo-baseline-history.md) | a result, not a build step |
| **Lazy viewspantable rebuild** | [`docs/ledger/timedemo-baseline-history.md`](docs/ledger/timedemo-baseline-history.md) | a result, not a build step |
| **Measured texture-span change** | [`docs/ledger/timedemo-baseline-history.md`](docs/ledger/timedemo-baseline-history.md) | a result, not a build step |

## 486 microbenchmark build

Build an isolated, DOS 8.3-compatible benchmark executable so the normal
`quake.exe` is not overwritten:

~~~powershell
.\tools\build-dos.ps1 -Benchmark
~~~

With Quake data available, the repository runner can stage and execute the
benchmark under the pinned 486 DOSBox-X profile:

~~~powershell
.\tools\bench-dos.ps1
~~~

Stage `out\dos\qbench.exe` beside `cwsdpmi.exe` and the `id1` data
directory, then run it in DOSBox-X with the same 486 profile and this command:

~~~text
qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchexit
~~~

The `bench486` command compares the existing C `Q_memset`/`Q_memcpy`
implementations with separate hand-written 486 assembly functions, then also
measures the existing rectangle-fill and alias-edge setup paths.  It validates
the complete working region before timing, prints five alternating samples per
case, and writes `bench486.txt` in the Quake directory.  The matrix covers
small and large lengths, dword boundaries, aligned buffers, independently
unaligned buffers, and zero/negative counts.  The assembly experiment is
used directly by the benchmark and is also available to normal `quake.exe`
builds through the explicit `-MemoryImplementation asm` switch; the 486-oriented
default now uses the ASM helpers, while `-MemoryImplementation c` retains the
original C helpers for reference comparisons.

The focused benchmark can select each implementation independently:

~~~powershell
.\tools\bench-dos.ps1 -MemoryImplementation asm `
  -TextureAxisImplementation asm `
  -SurfaceCacheImplementation asm `
  -MipLevelImplementation asm `
  -TurbulentImplementation stosb `
  -LightMapNormalizeImplementation asm `
  -BspPlaneDotImplementation asm `
  -BspClipImplementation asm `
  -BspWalkImplementation asm `
  -AliasTransformFinalImplementation asm `
.\tools\bench-dos.ps1 -TextureAxisImplementation c `
  -SurfaceCacheImplementation c `
  -MipLevelImplementation c `
  -TurbulentImplementation asm `
  -AliasBBoxProjectImplementation c `
  -AliasTransformFinalImplementation c `
~~~

Individual implementation switches can be omitted. The defaults are C for
memory helpers, texture-axis, surface-cache, mip-level selection, BSP plane
dot, BSP clipping, BSP traversal, world-face and B-model face rendering, and the
`Turbulent8` scan setup; `stosb` for turbulent spans;
and ASM for alias
projection, alias bounding-box projection, clipped alias transform/lighting,
texture animation, and lightmap normalization; the lightmap-build dispatcher
defaults to C. Pass
`-TurbulentImplementation asm` for the existing ASM control. The runner
records selector values in `bench-result.json` and uses a matching output
directory suffix. Use `-TurbulentOnly`, `-AliasProjectOnly`,
`-AliasBBoxProjectOnly`, `-AliasTransformFinalOnly`, `-TextureAnimationOnly`,
`-LightMapNormalizeOnly`, `-LightMapBuildOnly`, `-BspPlaneDotOnly`, `-BspClipOnly`, or
`-TurbulentScanOnly` to run only the corresponding focused experiment instead
of the longer general matrix.

The `R_RenderWorld` orchestration can be selected independently with
`-RenderWorldImplementation asm`. The default `c` path retains the original
orchestration as the reference; the assembly entry sets up render state and a
frame-local polygon queue, dispatches the selected BSP walk, and replays queued
polygons when requested. Use the same selector for build, smoke, and timedemo:

~~~powershell
.\tools\build-dos.ps1 -RenderWorldImplementation asm
.\tools\smoke-dos.ps1 -RenderWorldImplementation asm
.\tools\timedemo-dos.ps1 -RenderWorldImplementation asm -Runs 1
~~~

The full world-BSP walk can be selected independently with
`-BspWalkImplementation asm`. The default `c` path retains the original C
traversal. The assembly walk calls the existing assembly plane-dot and frustum
clip helpers, then handles recursion, leaf marking, face ordering, and polygon
queueing in assembly. World-face, B-model face setup, and cached-edge insertion
have independent assembly selectors; `R_StoreEfrags` has its own selector.
`R_ClipEdge` and edge projection/emission are handwritten in legacy
`src/r_drawa.s` under `id386`. `R_RenderPoly` belongs to the optional
polygon-driver branch; normal DOS span rendering leaves `r_drawpolys=0` and
`D_DrawPoly()` is a no-op.
Validate this selector with DOS smoke and the pinned timedemo:

~~~powershell
.\tools\build-dos.ps1 -BspWalkImplementation asm
.\tools\smoke-dos.ps1 -BspWalkImplementation asm
.\tools\timedemo-dos.ps1 -BspWalkImplementation asm -Runs 1
~~~

The world `R_RenderFace` path is independently selectable with
`-RenderFaceImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -RenderFaceImplementation asm
.\tools\smoke-dos.ps1 -RenderFaceImplementation asm
.\tools\timedemo-dos.ps1 -RenderFaceImplementation asm -Runs 1
~~~

`c` is the default and retains `R_RenderFace_C` as the benchmark reference.
The assembly path owns face edge traversal and surface setup while calling
legacy `R_ClipEdge` assembly and the existing surface-gradient selector. It
passed smoke and
the pinned 969-frame framebuffer checksum; its current single timing sample was
slower than the preceding C median, so it remains opt-in. `R_RenderBmodelFace`
has an independent selector below.

Brush-model face setup is selectable with
`-RenderBmodelFaceImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -RenderBmodelFaceImplementation asm
.\tools\smoke-dos.ps1 -RenderBmodelFaceImplementation asm
.\tools\timedemo-dos.ps1 -RenderBmodelFaceImplementation asm -Runs 1
~~~

The default `c` path retains `R_RenderBmodelFace_C` as the benchmark
reference. The assembly entry handles capacity checks, clip-chain setup,
bedge-list clipping, synthetic side edges, and surface setup while sharing
`R_ClipEdge` and the existing surface-gradient selector. The B-model selector
uses the short `-bm` output token to keep benchmark object paths within the
Windows path limit when combined with other render selectors. It passed smoke
and the pinned framebuffer checksum; its single timing sample is not promotion
evidence. The BSP walk, world-face, and B-model-face assembly paths passed a
combined timedemo with exact framebuffer parity.

Cached-edge insertion is independently selectable with
`-EmitCachedEdgeImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -EmitCachedEdgeImplementation asm
.\tools\smoke-dos.ps1 -EmitCachedEdgeImplementation asm
.\tools\timedemo-dos.ps1 -EmitCachedEdgeImplementation asm -Runs 1
~~~

The default `c` path retains `R_EmitCachedEdge_C` in benchmark builds. The
assembly entry fills the first empty 16-bit edge surface slot, updates the
nearest-depth value, and marks the edge emitted. It passed the pinned
969-frame checksum (`1047377823`) in regular and instrumented timedemos; the
instrumented run counted 121,467 assembly calls. Its single `59.179677 s`
sample is not a C/assembly comparison, so C remains the release default.

Submodel surface traversal is independently selectable with
`-SubmodelPolygonsImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -SubmodelPolygonsImplementation asm
.\tools\smoke-dos.ps1 -SubmodelPolygonsImplementation asm
.\tools\timedemo-dos.ps1 -SubmodelPolygonsImplementation asm -Runs 1
~~~

The C implementation remains the default reference. The assembly path walks
the brush-model surface list, computes the plane-side test with x87, updates
`r_currentkey`, and calls the selected `R_RenderFace`. Both the C and ASM
combined renderer candidates passed the pinned checksum with only this selector
changed between builds. Their single timedemo samples are not a timing
comparison. Fixed-wait live captures landed at different demo moments, so they
do not establish visual frame parity; see the submodel assembly ledger.

Frame-level edge drawing is independently selectable with
`-EdgeDrawingImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -EdgeDrawingImplementation asm
.\tools\smoke-dos.ps1 -EdgeDrawingImplementation asm
.\tools\timedemo-dos.ps1 -EdgeDrawingImplementation asm -Runs 1
~~~

The assembly entry uses aligned stack buffers when no caller edge buffer is
provided, dispatches world rendering and edge scans, switches Z testing on for
brush entities, and preserves the `r_dspeeds` and update flow. C and ASM passed
smoke and the pinned framebuffer checksum. Their single timings showed no
measured gain, so C remains the default; fixed-wait captures show coherent
frames but do not establish exact-frame visual parity.

The scanline edge loop is independently selectable with
`-ScanEdgesImplementation c|asm`:

~~~powershell
.\tools\build-dos.ps1 -ScanEdgesImplementation asm
.\tools\smoke-dos.ps1 -ScanEdgesImplementation asm
.\tools\timedemo-dos.ps1 -ScanEdgesImplementation asm -Runs 1
~~~

The assembly entry owns aligned span-buffer setup, the scanline loop, edge
updates, span-capacity flushes, and the final draw. It calls the existing edge
insert/remove/step and span-draw routines. C and ASM passed smoke and the pinned
969-frame checksum. Their single timings showed no speed gain, so C remains the
default. A matched-frame visual comparison is still open.

Active-edge maintenance has three selectable choices with
`-EdgeListMaintenanceImplementation legacy|c|asm`:

~~~powershell
.\tools\build-dos.ps1 -EdgeListMaintenanceImplementation c
.\tools\smoke-dos.ps1 -EdgeListMaintenanceImplementation asm
.\tools\timedemo-dos.ps1 -EdgeListMaintenanceImplementation asm -Runs 1
~~~

`legacy` is the default and retains the existing `id386` routines in
`r_edgea.s`. `c` forces the C reference routines to compile in the DOS build;
`asm` selects the replacement assembly for edge insertion, removal, and U
stepping. The C and ASM candidates passed the pinned framebuffer checksum, but
single samples showed no speed gain, so keep `legacy` as the default.

Compare runs using the same DOSBox-X version, profile, cycle count, executable
mode, and data set.  The benchmark is diagnostic evidence for these routines;
timedemo FPS remains the end-to-end renderer check.

### Optimization profiles and instrumentation

The default build is the measured `aggressive` profile (`-O3`,
`-march=i486`, and no newer instruction-set requirement).  `-O2` remains
available for A/B comparison and writes beside the default build:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -OptimizationProfile baseline
.\tools\timedemo-dos.ps1 -OptimizationProfile baseline -Runs 3
~~~

A matched 2026-09-10 `-O3` rerun after the `Mod_LoadTexinfo` UB fix reached
**14.162237 FPS** (`68.421397` seconds median;
`out\dos-timedemo-20260910-232607`) versus **14.054401 FPS** for `-O2`,
about 0.76% faster, with checksum `4154140932` on every run.  `-O3`
`quake.exe +quit` smoke passed, so `aggressive` is now the default.
The subsequent bmodel span-rotation cache reached **14.170874 FPS**
(`68.379696` seconds median; `out\dos-timedemo-20260910-233942`).
Fusing ambient into the first lightmap style reached **14.185365 FPS**
(`68.309838` seconds median; `out\dos-timedemo-20260910-234742`).
Fusing invert/clamp into that one-style write reached **14.194521 FPS**
(`68.265779` seconds median; `out\dos-timedemo-20260911-051131`).
Extending that fusion to extra styles reached **14.194657 FPS**
(`68.265121` seconds median; `out\dos-timedemo-20260911-051834`).
The integer dlight inner loop reached **14.206133 FPS**
(`68.209972` seconds median; `out\dos-timedemo-20260911-052933`).
The face Z-gradient cache reached **14.208466 FPS**
(`68.198777` seconds median; `out\dos-timedemo-20260911-053759`).
Power-of-two column wrap reached **14.208790 FPS**
(`68.197221` seconds median; `out\dos-timedemo-20260911-054347`).
`D_DrawZSpans` `zspantable` addressing reached **14.239663 FPS**
(`68.049361` seconds median; `out\dos-timedemo-20260911-062059`).


### Sections moved out of this document

These were measurements, not build steps. Each is recorded verbatim in the
ledger, which is where a result belongs.

| Section | Now recorded in | Why it left |
|---|---|---|
| **Memory helper experiment result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Runtime memory-helper result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Texture-axis cache probe result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Surface-cache predicate result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Mip-level selector result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Turbulent-span inner-loop result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Alias-project projection result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Texture-animation frame-selection result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Lightmap normalization result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **BSP plane-dot result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **BSP frustum-clipping result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Alias bounding-box projection result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Clipped alias vertex transform result** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |
| **Rejected negative-gradient Z-span unroll** | [`docs/ledger/microbenchmark-results.md`](docs/ledger/microbenchmark-results.md) | a result, not a build step |

## Reprovisioning

The bootstrapper reuses an existing archive only after verifying its SHA-256.
To replace the user-local installations and cached archives:

~~~powershell
.\tools\bootstrap-dos.ps1 -Force
~~~

-Force affects only the exact installation and download directories under
the selected tool root.

## Scope and limitations

- No Quake data, DOSBox-X binaries, DJGPP binaries, or build output is tracked.
  The ignored `out\` tree is disposable; historical report paths in this file
  document prior evidence but may not exist after cleanup or on a fresh clone.
- The historical q.bat, qa.bat, qb.bat, and qt.bat launchers are kept;
  the new smoke runner supplies a deterministic local staging layout instead.
- A successful host build proves compilation and linking.  The DOSBox-X smoke
  test is required before claiming runtime functionality.
- Timedemo checksum equality covers the recorded framebuffer only; it does not
  establish full visual, audio, gameplay, or physical-486 parity.
