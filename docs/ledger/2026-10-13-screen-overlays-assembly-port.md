# `SCR_UpdateScreen` overlay dispatch i486 assembly slice (2026-10-13)

## Original branch block and selector

| Reference behavior | Assembly implementation | Reference boundary |
| --- | --- | --- |
| `src/client/screen.c:SCR_UpdateScreen` inline overlay decision tree | `src/client/screen_overlaysasm.s:SCR_DrawScreenOverlays_asm486`, selected by `ScreenOverlaysImplementation=asm` | `SCR_DrawScreenOverlays_Screen_C` retains the C branch tree for the BENCH486 oracle; `ScreenOverlaysImplementation=c` uses it directly |

The helper preserves the original branch precedence and visible call order:
dialog, loading, intermission 1, intermission 2/finale, intermission 3, then
normal overlays. In the normal path it calls the RAM indicator, network marker,
turtle marker, pause marker, center-string check, status bar, console, and menu
in that order. The dialog path still sets `scr_copyeverything`; intermission
branches still require `key_dest == key_game`.

`src/client/asm_screenoverlays.h` pins `client_state_t.intermission` at byte offset
548 and `key_game` at zero with compile-time checks. The assembly is `.arch
i486`, follows cdecl, and reads its two trace parameters from the stack. The
C and assembly profiles contain the same 108 selectors and differ only in
`ScreenOverlaysImplementation`; the C profile selects C for this helper and
assembly for the other 107 selectors.

## Direct C/assembly branch fixture

The guarded fixture in `src/tests/bench486/bench486_screenoverlays.h` compares eight branch
and state cases, including dialog/loading precedence, all three intermission
branches, menu destinations, and default-path state preservation. It checks
the recorded callback sequence, `scr_copyeverything`, stack/register state,
and x87 state. The DOSBox-X run reported:

```text
screen overlay dispatch 8 exact C/assembly branch cases; event and state parity PASS
486 benchmark correctness PASS
```

The draw routines called by these branches retain their own owners and tests;
this slice ports dispatch and ordering, not their implementations. The full
`SCR_UpdateScreen` orchestration was ported in a separate later slice; the
called console, status-bar, menu, fade and other drawing routines remain
separately owned. See the [full `SCR_UpdateScreen` port
record](2026-10-13-screen-update-assembly-port.md).

## Exact paired scene and i486 audit

The strict pair used the configured DOSBox-X 486 profile and
`demo1-vesa-full`. Both builds passed the complete ISA gate. The C build had
274,520 linked instructions; the assembly candidate had 275,665. Both had zero
above-i486 instructions, unknown instructions, or exemptions. The audit also
source-proved 147 project objects and 235 installed runtime objects, verified
all relocated opcodes, audited the 529 startup code rows, and checked 9,207
CWSDPMI provider instructions with zero exemptions.

Each profile ran the scene twice. Each run produced 970 checksum records, of
which all 964 post-warmup frames matched between C and assembly. Both profiles
were repeat-stable. The captured 320x200 indexed frame matched exactly in both
runs: zero differing pixel indices and zero palette-byte differences. The
paired report records `pass: true`, strict ISA status `PASS`, and a matching
source-tree fingerprint. Median timedemo rates were 12.024 FPS for C and
12.024 FPS for assembly; this is regression evidence, not an optimization
claim.

## Ownership snapshot

The strict candidate's four-root BENCH486 ownership report lists 639 renderer
entries, of which 367 are directly reachable (345 assembly and 22 C). It also
reports 59 unresolved direct callees. The trace includes fixture hooks and is
not a complete call graph; indirect targets and the remaining C owners still
need review. The report is
`out/render-parity-screen-overlays-20261013/renderer-ownership-candidate.json`.

## Reproduction and remaining scope

Choose fresh output and local-output names for every run. Keep temporary files
on D: by setting `TEMP`, `TMP`, and `TMPDIR` to a directory under `out`:

```powershell
$env:TEMP = 'workspace\quake\out\tmp-screen-overlays-repro'
$env:TMP = $env:TEMP
$env:TMPDIR = $env:TEMP
pwsh -NoProfile -File tools/render-parity-dos.ps1 `
  -ReferenceProfile tools/renderer-profiles/i486-screen-overlays-c.json `
  -CandidateProfile tools/renderer-profiles/i486-screen-overlays-asm.json `
  -Scenario demo1-vesa-full -CpuTarget i486 -NoBootstrap `
  -ToolRoot out/tools -DataRoot testdata/id1 `
  -OutputRoot out/render-parity-screen-overlays-repro `
  -LocalOutputDirectoryPrefix overlay-repro
```

The run reports are under `out/render-parity-screen-overlays-20261013/`; the
strict build trees are `out/local-overlay13-r-demo1-vesa-full/` and
`out/local-overlay13-a-demo1-vesa-full/`. This single-scene result closes only
the overlay-dispatch slice; the full-routine port has separate exact paired
evidence. The called screen, status-bar and menu drawing routines remain
separately owned, and full-renderer coverage remains open. This evidence uses
the configured DOSBox-X 486 profile; it does not claim a run on genuine 486
hardware.
