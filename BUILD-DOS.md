# Building NitroQuake for MS-DOS

This standalone repository contains native C/assembly, game assets, the DJGPP
build and source-bound ISA verification. PowerShell 7, Python 3.9+ (standard
library), full Git history and the pinned compiler are required. DOSBox,
Matplotlib and a benchmark checkout are not build dependencies.

## Build

Run from this repository's root on Windows:

```powershell
pwsh -NoProfile -File tools/bootstrap-dos.ps1
pwsh -NoProfile -File tools/build-dos.ps1 -CpuTarget i486
pwsh -NoProfile -File tools/build-dos.ps1 -CpuTarget i486 -DumpFlags
```

The default bootstrap installs only DJGPP, with archive hashes pinned in
`tools/dos-toolchain.json`. `-ToolRoot` selects another installation cache;
`-NoBootstrap` requires that compiler to be installed already. The default cache
is `%LOCALAPPDATA%/486quake/tools`.

The builder prints the executable path and writes a build manifest, generated
identity, source inventory and ISA proofs beside it in `out/`. Use
`-LocalOutputDirectoryName <unique-name>` for an isolated i486 build; it refuses
an existing directory. Long selector suffixes use hashed output names. Inspect
`-DumpFlags` rather than guessing an output path.

### Compiler invocation

The supported builder owns flags, dependency selection, linking and blocking
source-bound ISA audits. Its `-DumpFlags` JSON is the integration API consumed
by external runners. `tools/selectors.ps1` and `tools/renderer-profiles/` describe
native code generation. Explicit selectors remain supported; benchmark-profile
JSON files in that directory are compiler configuration, not runtime tooling.

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
Build them with `tools/build-dos.ps1 -Benchmark` and optionally `-Instrumentation`.
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

## Automatic product version and build numbers

The console background, startup banner, `version`, status, server greeting, and
DOS exit screen display `NitroQuake v0.999` and `Build <number>` on separate
lines. `tools/build-dos.ps1` derives the number from the total accepted plus
rejected optimization attempts. Rebuilding, failed builds, unrelated commits,
independent clones, and worktrees with the same recorded attempts keep the same
number. This identifies optimization progress, not individual binary builds.

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
its executable. The manifest records the count, accepted/rejected breakdown,
inventory digest, Git revision, and header hash. Runner freshness includes the
inventory digest, so a newly recorded attempt invalidates an existing build.
The builder records the inventory it embedded at build start; a report added
during compilation leaves that executable stale for the next runner.
Full Git history and Python 3.9+ are required; shallow clones and source archives
fail explicitly rather than inventing a number. The former local reservation
counter is unused and left intact. Legacy compiles bypassing the supported
builder remain explicitly build zero. Protocol/save versions remain independent.

Run `pwsh -NoProfile -File tools/test-build-number.ps1` for deterministic history,
duplicate/variant, deletion, rename, clone, and generated-header checks.
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
