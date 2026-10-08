# Toolchain refactor: eight defects, and one duplication that measured twice

**2026-10-04.** No source under `src\` changed. Every figure in every other ledger
entry is unaffected, and `tools\guard-i486-release.py` passes, which is the proof:
the 103 i486 release objects and `quake.exe` hash exactly as they did before this
work. What follows is a record of the tooling, and of eight defects found in it —
seven of which had been silently producing a wrong answer.

## The duplication, measured

The four DOS runners were compared line-by-line, comments and whitespace normalised.
`bench-dos.ps1` and `timedemo-dos.ps1` — both 300-to-800-line scripts — shared
**312 identical lines across 19 maximal blocks**. `smoke-dos.ps1` shared 120 with
bench and 118 with timedemo. Across all thirteen PowerShell tools, 973 identical
line-pairs.

The blocks were: tool-root and data-root resolution, the toolchain-manifest read,
the DOSBox-X path plus bootstrap-or-throw, the `[autoexec]` rewrite with `cputype`
forcing, the pak hardlink staging, the argument quoting, the `ProcessStartInfo`
launch, and the source fingerprint.

## Four defects that were producing a wrong answer

### The release guard was never date-blind

`tools\guard-i486-release.py` normalises `__TIME__` and `__DATE__` out of three
artefacts before hashing, so they can hash the same twice. Its date pattern was
`\d{2}-[A-Za-z]{3}-\d{4}`. C spells `__DATE__` as `Mmm dd yyyy` with a space-padded
day, so DJGPP writes `Oct  4 2026` — and the pattern matched nothing, ever. The
calendar date stayed in the digest of `host.obj`, `host_cmd.obj` and `quake.exe`,
and **the guard failed on any rebuild on a different day.**

Replaced with one anchored pattern, because the two halves are one literal in the
artefacts: the two `__TIME__`/`__DATE__` users print them from a single
`Exe: %s %s\n`, so the pair is always adjacent. Measured across all 104 pinned
artefacts: the new pattern matches exactly those three and no others, so none of the
other 101 pins is weakened.

Verified by rewriting an embedded stamp to `23:59:59 Dec 31 2026`: the old patterns
change the digest, the new ones do not, and one appended byte still does.

### Omitting `-ObjectNames` aborted the ISA audit instead of widening it

`tools\isa-audit.ps1` used `$null` as the off state for its object-name filter, then
read `$objectNameFilter.Count`. Under `Set-StrictMode -Version Latest` a property
read on `$null` is a terminating error, so the invocations in that file's own
`.EXAMPLE` block — neither of which passes `-ObjectNames` — died before auditing
anything.

| `-ObjectNames` | before | after |
|---|---|---|
| omitted | fatal error | 103 objects, 168461 instructions |
| `math.obj`, `view.obj` | fatal error | 2 objects, 2417 instructions |
| `math.obj`, `nosuch.obj` | silent | throws, naming `nosuch.obj` |

The third row was a second defect in the same six lines: `$missingObjects` started
empty and only ever had entries removed from it, so the "named objects not found"
throw could not fire and a typo audited fewer objects than asked for.

### The promotion gate's profile pin only passed on machines like this one

`timedemo-dos.ps1` pinned the SHA-256 of `tools\dosbox-x-486-high.conf` **as it sat
on disk**. There is no `.gitattributes` in this tree. The committed blob is LF
(116757 bytes); this checkout is CRLF (118213) because `core.autocrlf=true`. The
pinned constant was the hash of the CRLF form.

So the gate that exists to stop the ledger being silently re-baselined was itself
valid only on the machine that recorded it. A checkout with `core.autocrlf=false` —
Linux, any CI runner configured that way — would fail it on a file that had not
changed.

The pin is now taken over the file with line endings normalised to LF, via
`Get-TextFileHash`. It pins what the file says rather than which platform checked it
out, and `tools\guard-i486-release.py` already normalised for the same reason: the
thing being pinned is not the clock.

| input | bytes | verdict |
|---|---:|---|
| this working tree, CRLF | 118213 | matches |
| the committed blob, LF | 116757 | matches |
| the same content as CRLF | 118216 | matches |
| `fixed 33445` → `fixed 33446` | 116757 | differs |

The first two previously disagreed, which is the whole defect.

### CMPXCHG8B was classified i486

`tools\isa-audit.ps1` mapped `0fc6` and `0fc7` to `i486`, and `0fc7` carried the
comment `RDRAND-ish` — a third ISA level, two generations later again — so one table
row was standing in for three answers. CMPXCHG8B is a Pentium instruction.
`tools\isa-audit-source.py` already had `cmpxchg8b` in its i586 list; the two tools
disagreed, and this is the one wired into the blocking build gate.

Measured before changing the table, because a misclassification that turns a green
gate red is worse than the misclassification: objdump reports **zero** `cmpxchg8b`
and zero `cmpxchg16b` across all 103 objects of both the i486 and the i386 set, and
`tools\golden\isa-baseline.json` records no `0f c6` or `0f c7` for any variant. The
correction moves no figure. It matters the moment the compiler emits either, which
is exactly when the gate has to be right.

## Two runners tested whatever binary was lying around

`smoke-dos.ps1` and `coverage-dos.ps1` asked only whether the executable *existed*.
Once a release build was present it was tested indefinitely however many sources had
changed — the same defect `bench-dos.ps1` had already fixed for itself, and the
reason a correctness failure there could be reported against a stale binary.

For `coverage-dos.ps1` it is worse than a stale number. The claim the gate makes is
that `world.c`, `sv_*`, `pr_*` and the net layer were *reached*; that claim is void
if it was reached in a different binary.

Unifying the fingerprint surfaced two further defects:

- The record was fixed at `qbench.sources.sha256`, and all four runners stage into
  the same output directory for a given selector set — so the release, bench and
  instrumented builds overwrote each other's record and rebuilt each other's binary
  on alternating runs. It is now named after the executable.
- `bench-dos.ps1` and `timedemo-dos.ps1` each spelled out the same forty selectors
  by hand, and the two lists had **drifted in order** — `TurbulentImplementation` and
  `MemoryImplementation` are transposed — so they could never have agreed on a
  digest. The configuration half is now derived from the builder's own resolved
  output, which is complete by construction and cannot disagree with the golden
  manifest that compares those exact fields.

`build-dos.ps1` records the hash after the ISA gate, because it is the only component
that knows what it just produced. A build that fails the gate throws before reaching
that line, so a failed build never leaves a record claiming the tree matches.

## The generated DOSBox config was not reproducible

Each runner built its `[autoexec]` block with a here-string, and a here-string takes
its line endings from the `.ps1` file it is written in. Git stores these files as LF
and `core.autocrlf=true` rewrites them to CRLF on checkout, so **the same commit
produced different generated bytes on different machines.** HEAD's version appended
`[Environment]::NewLine` after a `TrimEnd`, which put CRLF at the end of a block
whose interior was LF.

The block now takes the template's own line ending, so it matches whatever it is
inserted into under any git configuration.

Verified byte-for-byte: HEAD's `smoke-dos.ps1` and the refactored one, both given the
CRLF working-tree form they have on this machine, both reading the same template
bytes and the same executable, produce identical configs — 118216 bytes, and the LF
count equals the template's own 3, so the injected block contributes none.

An earlier attempt at that comparison reported a **false pass**: a bad path had
truncated HEAD's runner to zero bytes, and the harness compared a leftover file with
itself. The harness now refuses to compare when a side produced no config.

## One selector, written five times

Every build selector's effect appeared five times in `build-dos.ps1`: the suffix
token, the C `-D`, the assembly `-D`, whether the `.s` files are compiled, and the
manifest echo — plus a fourth copy of the implementation-selector list feeding the
expected active-assembly count.

They had drifted. `asm486_experiments.s` was excluded by name in one place and
folded into a thirteen-way boolean `-or` in two others.

### The `-or` that reads as an exclusion and is not

That filter was a chain of `-or`, and `-eq` binds tighter, so it parsed as *"any
implementation selector is `asm`, **OR** this file is not `asm486_experiments.s`"*.
The name test is therefore an extra way for a file to be **included**.

In the default release build all 21 `.s` files are compiled, `asm486_experiments.s`
among them, and the inventory pin expects 21. The first table-driven version read it
as an exclusion, compiled 20, and **the inventory pin failed the build** — which is
the pin doing exactly its job.

### Three orders, none derivable from another

The suffix reads in output-directory order; the C defines follow the shape of the
source tree; the assembly defines start with `TARGET_I386` because it selects the
file-level variants and must be visible before the feature macros. The manifest echo
turned out to be the suffix order minus the three selectors it emits explicitly, so
it is derived and checked rather than declared a fourth time.

`Assert-SelectorOrdersIsConsistent` and `Assert-SelectorManifestOrderIsConsistent`
run before anything is emitted. Verified against four deliberate defects:

| injected defect | diagnosis |
|---|---|
| `BspClipImplementation` dropped from `CDefineOrder` | `BspClipImplementation has C defines but is missing from CDefineOrder.` |
| an order naming a selector that does not exist | names both the phantom and the selector it displaced |
| a selector listed twice in one order | `SuffixOrder lists 'GibTrailHorizontalIntegration' twice.` |
| a table entry with its `C` key deleted | `table entry 'OptimizationProfile' has no 'C' key.` |

The first version of that last check did not fire: the verification loop read
`$selector.C.Count` directly, so under StrictMode the missing key aborted the
function before the collected problem was printed, and the diagnosis the guard exists
to give was replaced by `The property 'C' cannot be found on this object`.

Verified byte-for-byte against HEAD: `-DumpFlags` output identical for both targets,
including the 26/16 and 27/17 flag arrays and the exact suffix token order; and a
real build's manifest identical field for field, same 54 keys in the same order.

## Six latent defects in the source-level ISA tool

`tools\isa-audit-source.py` had never gated a build, which is why these survived.

`movq` was in both `I386_SAFE` and `P6_SUBSTRINGS`, and the P6 substring test runs
first, so every `movq` classified as `p6`. It is the ordinary 386 quadword move.
Latent rather than active: GCC at `-march=i386` emits `movl` and never `movq`, so the
scan reports `p6 0` today — verified, not assumed.

`verr` and `verw` sat in `I486_MNEMONICS` under the comment *"386; kept here only so
it is never silently 486+ below"*, which describes the opposite of what the entry
does. `movzbq`/`movzwq`/`movswq` were whitelisted as i386 though they are long-mode
forms. `movnti` was added to the whitelist and discarded on the next line. `lodb` was
a typo for `lodsb`, which was already present. `toolchain_env()` was annotated
`-> dict` and returned a 2-tuple.

`_assert_no_shadowed_mnemonics` now runs at import and fails if a mnemonic is in both
`I386_SAFE` and `P6_SUBSTRINGS`, or in two exact-match tables. Verified against both
shapes.

The report's `line` was ambiguous in a way that matters here: for a `.c` row it is a
line of the compiler's generated assembly, for a `.s` row a line of the preprocessed
text. Both were filed under a source file name and neither is a line of it — so a
reader could cite one as a location in the C file, which is the mistake this ledger's
own citation rule exists to prevent, committed by a tool. The report now carries a
`lineNumberKind` field saying which is which.

Numbers unchanged, which is the point: 115677 instructions, 307 above i386, `p6 0`,
`unknown 0`.

## Toolchain-audit ISA correction (2026-10-06)

The source-level counts and release-ISA conclusion recorded later in this entry
used a wrong Pentium classification for `IMUL 0F AF`. The corrected source scan
reports zero above-i486 instructions and 131 i486 instructions for the i386
target. See the [ISA correction](2026-10-03-isa-audit-and-i386-codepath.md) for
the primary manual reference and the refreshed object/source baselines.

## What is now a gate that was not

`isa-audit-source.py` is gate 5. It counts instructions in compiler output where the
existing gate counts them in disassembled objects — a genuinely different
measurement, since the object tool sees every inlined copy and this one sees one hit
per source construct. `tools\golden\isa-baseline.json` records that their agreement
is the evidence the 62/63 string-data exclusion is sound; an unregistered
cross-check is not a cross-check.

It runs **without** `-FailOnViolation`. That flag is an absolute pass and stays red
for as long as the multiply-elimination work is incomplete, which is the documented
state of this tree; a gate that is always red is a gate that gets switched off. So
it gained the same ratchet shape as the object-level gate, against a new
`tools\golden\isa-source-baseline.json`: two absolute rules and per-ISA counts that
may not rise. It fails closed with no baseline recorded.

Recorded: i486 176 above target, i386 307 above target, both 0 unclassified and
0 p6. The i386 figure is the one `ASM486-HANDOFF.md` already cites from this tool,
and it sits against the object-level gate's 305.

Verified it can fail: with the recorded i586 count lowered to 1, it reports
`i586: 176 above baseline 1` and `above-target total: 176 above baseline 1`, exit 1.

It also failed its first full-suite run, on `-NoBootstrap`: the runner passed the
flag and this tool has no such switch, because it never installs the toolchain, it
only needs it present. Argparse exited 2. That is what a gate does.

## A checklist moved out of a script's tail

The list of coverage gaps was printed at the end of `run-tests.ps1`. It is now under
`ASM486-HANDOFF.md`, "Coverage gates still missing", and the runner prints a pointer.

Wrong twice over, and the old copy demonstrated both: a checklist kept in a script's
tail drifts from the code it describes — that one was dated — and it cited the source
by line number (`menu.c:2944`, `snd_dma.c:167`, `host_cmd.c:178`), the exact form
`docs\INDEX.md`'s citation rule forbids. It could not be enforced over a `.ps1`,
which is the other half of why it was in the wrong file.

## Result

Full suite: **11 passed, 0 failed, 0 skipped**, 763.3 s. ISA gates unchanged at
170/170 (i486 release), 173/173 (bench) and 305/305 (i386), 0 unclassified. Timedemo
59.160577 / 59.160497 / 59.160536 s over 969 frames with checksum `1047377823`
enforced, against a recorded baseline of 59.227329 s. The new gate costs 18.4 s.

Line counts: `bench-dos.ps1` 494 → 344, `coverage-dos.ps1` 293 → 221,
`smoke-dos.ps1` 310 → 209, `timedemo-dos.ps1` 845 → 633, `build-dos.ps1` 958 → 684.

## Dead code, and one that was not

Three unused assignments (`$buildRoot` in three runners, `$reg` in the ISA audit's
`0f 01` branch), a median computed twice by two separately-edited copies of the same
rule, and `-frames` as the only parameter in the tree not in PascalCase.

One of these was subtler: `timedemo-dos.ps1` defines `Get-MedianNumber` and then
re-implements the median inline for the one figure a reader acts on, while the
helper computed the same statistic for thirty-odd fields in the summary block
beside it. The headline number and the same number next to it were two copies of one
rule.
