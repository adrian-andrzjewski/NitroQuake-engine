# Load and Save menu pages move to i486 assembly (2026-10-19)

## Behavior and selector

`M_Load_Draw` and `M_Save_Draw` now select a shared renderer in the default
i486 screen-overlay assembly profile. The two entry points choose their
respective title pictures; the shared routine preserves picture caching and
centering, all twelve save-name rows, and the animated cursor calculation.
The C implementation remains available in BENCH as the parity oracle.

The cursor's `(int)(realtime * 4) & 1` conversion uses a temporary
round-toward-zero x87 control word and restores the caller's control word,
matching the C behavior independently of the incoming rounding mode.

## Direct C/assembly parity

The focused DOSBox-X screen-overlay run passes 768 exact C/assembly cases: both
pages, both cursor endpoints, four time values, four viewport widths, three
x87 precisions, and all four rounding modes. The fixture checks cached picture
paths and pointers, draw order and placement, all twelve filename rows
(including an empty row, a maximum-length row, and a high-bit byte), cursor
glyph and placement, preserved state, ABI sentinels, and x87 control-word
preservation. The existing overlay, menu, text-box, dispatch, and console-draw
fixtures pass in the same run.

Run the focused parity fixture with:

```powershell
tools/bench-dos.ps1 -ScreenOverlaysImplementation asm -ScreenOverlaysOnly `
  -CpuTarget i486 -NoBootstrap -SkipIsaAudit -TimeoutSeconds 180
```

`-SkipIsaAudit` makes this a diagnostic runtime run; the release gate below
provides the i486 instruction proof.

## Strict i486 release verification and ownership

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict build passed project proofs for 165 objects, runtime proofs for 235
sources and 400 exact native/annotated object proofs, plus the complete linked
executable ISA gate. It verified 162,428 relocated instructions, 529 startup
rows, and 9,207 CWSDPMI provider instructions with no above-i486, unknown,
exempt, or unclassified instructions or bytes. The refreshed release inventory
confirms `_M_Load_Draw` and `_M_Save_Draw` are owned by `screen_overlaysasm.s`
as assembly.

The report contains 409 directly reachable renderer entries, of which 23
remain C-owned: 386/409, or 94.4%, are assembly-owned by reachable-symbol
count. The call graph remains incomplete, with 38 unresolved direct callees.
This is a profile-specific symbol-count estimate, not a weighted measure of
implementation effort.

## Scope and remaining work

This slice ports the paired Load/Save page drawing path and keeps the shared
picture cache and drawing primitives as dependencies. It does not measure FPS
or establish complete-scene image parity; the broader renderer port and
call-graph review remain open.
