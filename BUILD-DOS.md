# Building NitroQuake for MS-DOS

This standalone repository contains native C/assembly, game assets, the DJGPP
build and source-bound ISA verification. PowerShell 7, Python 3.9+ (standard
library), a Git checkout with `HEAD`, and the pinned compiler are required. Full
Git history is needed only for a complete optimization-attempt inventory. DOSBox,
Matplotlib and a benchmark checkout are not build dependencies.

## Build

Run from this repository's root on Windows:

```powershell
pwsh -NoProfile -File tools/bootstrap-dos.ps1
pwsh -NoProfile -File tools/build-dos.ps1 -Configuration i486-release
pwsh -NoProfile -File tools/build-dos.ps1 -Configuration c-reference -DumpFlags
```

The default bootstrap installs only DJGPP, with archive hashes pinned in
`tools/dos-toolchain.json`. `-ToolRoot` selects another installation cache;
`-NoBootstrap` requires that compiler to be installed already. The default cache
is `%LOCALAPPDATA%/486quake/tools`.

The builder prints the executable path and writes a build manifest, generated
identity, source inventory and ISA proofs beside it in `out/`. It supports two
named configurations: `i486-release` (the default) and `c-reference`. The
C-reference configuration can also be built for i386 with
`-Configuration c-reference -CpuTarget i386`. Use
`-LocalOutputDirectoryName <unique-name>` for an isolated build; it refuses an
existing directory. Inspect `-DumpFlags` rather than guessing an output path.

### Compiler invocation

The supported builder owns flags, dependency selection, linking and blocking
source-bound ISA audits. Its `-DumpFlags` JSON is the integration API consumed
by external runners. `i486-asm-selectable-current.json` and
`i486-c-reference.json` define the two supported configurations. Other selector
profiles support benchmark comparisons. Per-routine selectors, experimental
assembly variants and dead-scratch probes are available through the benchmark
suite; the internal `tools/build-dos-experimental.ps1` backend is not a shipping
build interface.

### DOS video startup

The game automatically selects available 320x200 VESA/VGA presentation.
`-stdvid` forces VGA discovery/selection. BIOS discovery and activation failures
are handled by the engine; a successful build alone is not hardware validation.

## Verification

```powershell
pwsh -NoProfile -File tools/run-tests.ps1 -HostOnly
pwsh -NoProfile -File tools/run-tests.ps1 -NoBootstrap -SkipReleaseGuard
python tools/test-bootstrap-dos.py
```

Host verification includes documentation, build configuration, optimization
history, source contracts and installer checks. The full game runner additionally
builds and exercises compiler-dependent ISA checks without launching an emulator.
The sysinfo/video fault harnesses also require a native host GCC. Test debt
predating this separation is recorded in
`docs/ledger/2026-11-08-commit-validation-and-test-debt.md`.
The release guard pins a particular accepted artifact, so use it for that
artifact's acceptance rather than assuming every newly built binary matches it.

Runtime smoke, server coverage, deterministic replays, C/assembly comparisons,
profiling, timing and graph generation belong to the separately versioned
workspace `benchmarks/` suite. Its README documents `-GameRoot` and
`NITROQUAKE_GAME_ROOT` for selecting this checkout. The game never imports it.
Keep successful compile/ISA results separate from gameplay, visual, sound and
physical 486 acceptance.

## 486 microbenchmark build

Native BENCH486 correctness fixtures and optional PROFILE486 instrumentation
remain with the game because they compile against private engine interfaces.
Build them with `tools/build-dos-experimental.ps1 -Benchmark` and optionally
`-Instrumentation`; ordinary release builds do not expose benchmark controls.
With a BENCH486 executable, `-fpsstats -timedemoexit` also exports ordered
`FRAMTIME.CSV` samples after playback. The native summary records the capture
schema and actual video dimensions. The external suite's frame-timeline runner
owns orchestration, host statistics and graph generation; normal game builds
contain no timing buffers or export code.
BENCH486 also provides `benchprofile N` for a bounded, fully signed-on local
server capture. `-gamebench` fixes simulation delta from the first host frame
while preserving the real DOS timer. PROFILE486 `-profilecoarse` and
`-profileparts` disable dense premise counters and select broad or component
scopes; default instrumentation retains the detailed counter inventory.
The external suite documents collection and interpretation in
`benchmarks/docs/ENGINE-PROFILING.md`.
The suite owns their orchestration, parsing, scenarios and reporting. Instrumented
profiles rank hotspots; matched uninstrumented runs establish timing evidence.

## Reprovisioning

`tools/bootstrap-dos.ps1 -Force` replaces the pinned compiler installation and
cached archive under the selected tool root. The benchmark suite bootstraps its
own pinned emulator using a separate manifest and the same installer code.

## Scope and limitations

Licensed PAK files and local output are not committed. Existing output archives,
accepted artifacts and worktrees retain their original locations; preserve
evidence before removing generated files. Protocol/save versions are independent
of product build identity. Historical optimization decisions stay in `docs/ledger/`
and `ASM486-HANDOFF.md` as reproducible version provenance.

## Product build identity and optimization history

The console background, startup banner, `version`, status, server greeting, and
DOS exit screen display `NitroQuake v0.999` and `Build <revision>-<configuration>`
on separate lines. The 12-character revision prefix identifies `HEAD`; the
12-character configuration prefix comes from a SHA-256 fingerprint of the
source files and resolved target, compiler/linker settings, and compatibility
policy. Checkout and output paths are normalized out of that fingerprint.
Changes to the revision, source inputs, or effective build configuration produce
a different identifier. Rebuilding identical inputs in another checkout or
output directory keeps the same identifier.

The manifest records the full source commit, full build fingerprint, source tree
fingerprint, and product build ID. Optimization history is separate provenance:
the manifest retains the accepted/rejected attempt count and inventory digest
when they can be derived. Shallow clones still build from their available HEAD;
if their history is incomplete, the manifest records null counts with an
unavailable status instead of presenting a partial count as complete. The
standalone history inventory remains strict and reports incomplete history or
unclassified ledger entries as errors. Git with a resolvable `HEAD` is required
for product identity. Full Git history is needed only for a complete
optimization inventory; Python 3.9+ remains a build-tool prerequisite.

`tools/optimization-history.py` inventories `docs/ledger/` and the early
`ASM486-HANDOFF.md` decisions. Git supplies reachable historical documents,
including deleted reports. Only HEAD ancestry participates; unrelated branches
do not contribute. Working-tree reports participate so an optimization can be
built before its report is committed. The reviewed legacy classifications in
`tools/optimization-history-legacy.json` resolve aggregate reports and duplicate
write-ups; they contain source references and decisions, never a numeric offset.
One retained early mip-0 specialization has no standalone report; its exact Git
revision is classified in the same map and counted only when reachable from HEAD.
The later dword-packing optimization to its helper is a separate attempt.

An attempt is a separately documented implemented candidate or independent
variant with an acceptance or rejection decision. Accepted C-to-assembly ports
count even when accepted on correctness alone. Distinct later investigations
and combined candidates count separately; repeated samples and verification of
the same investigation do not. Withdrawn candidates retain one attempt. Pure
profiling, tests, bug repairs, documentation, and unbuilt proposals do not count.
Early summary-table rows take precedence over their repeated narrative lists.

New `*-promoted.md`, `*-promotion.md`, `*-assembly-port.md`, and
`*-release-default.md` reports automatically contribute one accepted attempt;
`*-rejected.md` reports contribute one rejected attempt. For multi-candidate
reports, duplicates, or outcomes that filenames cannot express, put stable IDs
in the report (one comment per candidate):

```markdown
<!-- optimization-attempt: 2026-11-09-example-variant-a accepted -->
<!-- optimization-attempt: 2026-11-09-example-variant-b rejected -->
```

Repeated IDs count once and conflicting outcomes fail the build. Mark pure
evidence/meta reports with `<!-- optimization-attempts: none -->`. Unknown
report types fail explicitly instead of silently changing the total. No build
counter or source version needs updating. Accepted and rejected are historical
decisions, not promises about present performance or physical 486 hardware.

Every build writes `nitroquake-build.h` and `optimization-inventory.json` beside
its executable. Runner freshness uses the same source/configuration fingerprint
as the build ID; ledger edits alone do not invalidate an executable. The
optimization inventory is captured as manifest provenance at build start and
does not participate in that fingerprint. The former local reservation counter
is unused and left intact. Legacy compiles bypassing the supported builder
remain explicitly build zero. Protocol/save versions remain independent.

Run `pwsh -NoProfile -File tools/test-build-number.ps1` for deterministic product
identity, shallow-clone behavior, history provenance, and generated-header checks.
Inspect the full inventory with `python tools/optimization-history.py --output
out/optimization-inventory.json`.

## Text-mode startup summary

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Deterministic full-frame correctness replays

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Current i486 renderer selector defaults

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## The i386 target, and what it is and is not

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Read this before calling it a 386 binary

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## What the i386 build did fix

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Measured residual for the i386 target

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Correctness

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Guards on the i486 build

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Two pre-existing bugs found while adding the target

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## The fingerprint, and who records it

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## `smoke-dos.ps1` and `coverage-dos.ps1` had neither

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Profiling and probe tooling

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Premise-measurement counters (PROFILE486 only)

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Current promoted defaults

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## `tools\probe-ab.ps1` — the A/B a probe needs, and the PowerShell traps around it (2026-10-02)

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## `-SpanSetupProbe` — the span16 per-segment setup (2026-10-02)

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## `-RenderFaceProbe` — the same switch for C, and two C-only traps (2026-10-02)

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## `-EdgeScanProbe` — dead-scratch measurement switch, never a candidate (2026-10-02)

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Sections moved out of this document

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Alias triangle rasterization

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Runtime smoke test

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## 486-class timedemo

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Current seeded A/B reference

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Cross-version comparison (2026-09-28)

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Latest validation notes

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Historical pre-experiment reference

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Alternate DPMI host (HDPMI32 experiment)

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Current committed default baseline

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Per-frame FPS statistics

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.

## Optimization profiles and instrumentation

The historical instructions and measurements for this topic are preserved in
the benchmark suite's `docs/OPERATIONS.md`, under this heading. Native build
options are described above; runtime tools execute from the suite checkout.
