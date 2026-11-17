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
remain here because they compile against engine interfaces. Historical decisions
in `docs/ledger/` and `ASM486-HANDOFF.md` preserve optimization provenance and
provide the accepted/rejected attempt inventory recorded in build manifests when
the history is complete. Product build identity comes from the source revision
and resolved build configuration, as described in [BUILD-DOS.md](BUILD-DOS.md).
Runtime measurements in those historical records describe their original
environment and layout.

Game data is not distributed. Use legally obtained PAKs. Existing licenses are
preserved in [gnu.txt](gnu.txt) and [readme.txt](readme.txt).
