# NitroQuake

NitroQuake is a Quake software-renderer engine for Intel 486-class DOS systems.
Native C, i486/x87 assembly, game assets and strict source-bound ISA verification
live in this repository. See the [build guide](BUILD-DOS.md) for prerequisites,
commands, generated artifacts and automatic product/build identity.

```powershell
pwsh -NoProfile -File tools/bootstrap-dos.ps1
pwsh -NoProfile -File tools/build-dos.ps1 -Configuration i486-release
```

The default bootstrap installs DJGPP only. Python is used as standard-library
build infrastructure; DOSBox and Python analysis/plotting packages are optional
external benchmark dependencies.

The separately versioned workspace `benchmarks/` suite owns DOSBox automation,
profiling, deterministic scenarios, comparisons and charts. It selects a full
game checkout with `-GameRoot` or `NITROQUAKE_GAME_ROOT`. This game can be cloned,
built and developed without that suite.

Native BENCH486 fixtures, optional profiling hooks and renderer selector profiles
remain here because they compile against engine interfaces. The experiment
ledger and archived [ASM486 handoff](docs/history/ASM486-HANDOFF.md) preserve
optimization provenance and provide the accepted/rejected attempt inventory
used for the automatic console build number. The build identity and numbering
rules are documented in [BUILD-DOS.md](BUILD-DOS.md) and the
[optimization policy](docs/optimization/policy.md). Runtime measurements in
historical records describe their original environment and layout.

See the [documentation index](docs/INDEX.md) for maintained build, architecture,
renderer, and optimization guidance.

Game data is not distributed. Use legally obtained PAKs. Existing licenses are
preserved in [gnu.txt](gnu.txt) and [readme.txt](readme.txt).
