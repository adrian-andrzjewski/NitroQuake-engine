# Building NitroQuake for MS-DOS

This standalone repository contains native C/assembly, game assets, the DJGPP
build and source-bound ISA verification. PowerShell 7, Python 3.9+ (standard
library), a complete non-shallow Git checkout, and the pinned compiler are
required by the supported numbered builder. DOSBox, Matplotlib and a benchmark
checkout are not build dependencies.

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

Before adding, changing, or removing a selector, follow the
[selector change review](docs/SELECTOR-CHANGE-CHECKLIST.md). In particular,
record the parity, measurement, or historical-reproduction need; keep the
ordered selector table, profiles, golden flag schedules and source inventories
in sync; and verify that effective selector settings are represented in the
resolved inputs used for build identity. The selector matrix and profile tests
pin those contracts, while `test-build-fingerprints.ps1` verifies that a changed
profile suffix changes the artifact identity.

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
of product build identity. Historical optimization decisions stay in
`docs/ledger/` and `docs/history/ASM486-HANDOFF.md`; current rules are in
`docs/optimization/policy.md`.

## Product build identity and optimization history

The console background, startup banner, `version`, status, server greeting, and
DOS exit screen display `NitroQuake v0.999` and `Build <number>` on separate
lines. The build number is the total number of distinct accepted and rejected
optimization attempts in the complete inventory. The product build ID remains a
separate 12-character source-revision and 12-character configuration prefix in
the manifest; its SHA-256 fingerprint covers source files, resolved
target/compiler/linker settings, compatibility policy, and the optimization
inventory. Checkout and output paths are normalized out of that fingerprint.
Rebuilding identical inputs in another checkout or output directory keeps the
same build number and product build ID.

The manifest records the full source commit, full build fingerprint, source tree
fingerprint, product build ID, and accepted/rejected attempt inventory. The
standalone history inventory reports incomplete history or unclassified ledger
entries as errors. The supported numbered builder requires complete Git history
and fails rather than emitting a partial or missing count. Python 3.9+ remains a
build-tool prerequisite.

`tools/optimization-history.py` inventories `docs/ledger/` and the early
`docs/history/ASM486-HANDOFF.md` decisions. Git supplies reachable historical documents,
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
its executable. Runner freshness uses the same fingerprint as the product build
ID, including the inventory digest, so adding, removing, or reclassifying an
attempt regenerates the header, executable, and manifest. The former local
reservation counter is unused and left intact. Legacy compiles bypassing the
supported builder remain explicitly build zero. Protocol/save versions remain
independent.

Run `pwsh -NoProfile -File tools/test-build-number.ps1` for deterministic product
identity, full-history requirements, history provenance, and generated-header checks.
Inspect the full inventory with `python tools/optimization-history.py --output
out/optimization-inventory.json`.
## Runtime and historical workflows

Runtime smoke tests, deterministic replay, timing, profiling, selector
comparisons, and physical-machine acceptance are owned by the sibling
benchmarks/ repository. Start with its [documentation index](../benchmarks/docs/INDEX.md)
and [operations guide](../benchmarks/docs/OPERATIONS.md). The full dated
operations notebook is preserved at
[benchmarks/docs/history/OPERATIONS.md](../benchmarks/docs/history/OPERATIONS.md).

The current i486 release selector profile is maintained under
tools/renderer-profiles/; C-reference comparisons and selector changes
are covered by the [selector review checklist](docs/SELECTOR-CHANGE-CHECKLIST.md).
The i386 C-reference build is a diagnostic target, not a shipping product
configuration. Historical startup, profiling, and target notes remain in
the archived operations notebook.
