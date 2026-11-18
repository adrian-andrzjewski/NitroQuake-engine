# NitroQuake engine

NitroQuake is an independent DOS and 486-focused derivative of id Software's
Quake software renderer. It preserves the original gameplay and rendering
behavior while measuring and optimizing renderer and engine hot paths.

This repository contains the engine source, build system, and source-bound ISA
verification tools. Runtime profiling and comparison automation live in the
[NitroQuake workspace repository](https://github.com/adrian-andrzjewski/NitroQuake).

## Build

On Windows with PowerShell 7 and Python 3:

```powershell
pwsh -NoProfile -File tools/bootstrap-dos.ps1
pwsh -NoProfile -File tools/build-dos.ps1 -Configuration i486-release
```

The bootstrap downloads the pinned DJGPP build components. A native Windows GCC
is also required for the host-side source verification tools. See
[BUILD-DOS.md](BUILD-DOS.md) for prerequisites, output locations, and tests.

## Game data

This repository does not contain Quake PAK files or other commercial game data.
To run the engine, place legally obtained registered Quake data in the standard
`id1/` directory on the runtime search path. The root `.gitignore` excludes
common game-data formats and the `id1/` directory; keep personal game files
outside version control.

## Licensing

The Quake-derived engine source is licensed under GNU GPL version 2 or, at your
option, any later version. Original copyright notices are retained. Modified
Quake-derived source files carry a NitroQuake change notice; Git history records
the individual changes. Some build-verification references have separate
licenses, documented in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

Quake is a trademark of id Software. NitroQuake is independent and is not
affiliated with or endorsed by id Software. Game data and game branding are not
included.
