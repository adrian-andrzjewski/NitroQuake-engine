# Options menu drawing moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_Options_Draw`, `M_DrawSlider`, and `M_DrawCheckbox` now use explicit i486
assembly in the screen-overlay assembly profile. The C bodies remain available
only in the BENCH parity configuration as reference implementations. The page
draws the plaque/title, all option labels, five clamped sliders, four
checkboxes, the conditional video-options label, and the animated selection
cursor.

The assembly preserves the C page's cache and draw order, centered picture
placement, glyph sequence, floating-point expressions, float-to-integer
truncation, and x87 control-word behavior. Slider range math is rounded through
the same single-precision C local before drawing; the helper keeps the x87 stack
balanced across calls.

## Direct C/assembly parity

The focused DOSBox-X overlay run passed 384 exact C/assembly options-page cases.
The matrix covers four viewport widths, eight sets of ordinary/out-of-range and
special float values, three x87 precision settings, all four rounding modes,
four cursor positions, optional video-menu text, and eight animation times.
It checks every emitted glyph coordinate/value, cache and picture events,
buffer guards, ABI state, and x87 control-word preservation. The other focused
screen-overlay, menu, textbox, dispatch, and console-draw fixtures passed in the
same run.

Run the focused parity fixture with:

```powershell
tools/bench-dos.ps1 -ScreenOverlaysImplementation asm -ScreenOverlaysOnly `
  -CpuTarget i486 -NoBootstrap -SkipIsaAudit -TimeoutSeconds 180
```

`-SkipIsaAudit` makes this a diagnostic runtime run; the release gate below
provides the strict i486 instruction proof.

## Strict i486 release verification and ownership

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict release build passed project proofs for 165 objects and runtime
proofs for 235 installed sources, verifying 400 exact native/annotated object
proofs. The linked executable audit checked 162,032 relocated instructions,
529 startup CODE rows, and 9,207 provider instructions. No above-i486,
unclassified, or exempt instructions were found.

The refreshed non-BENCH renderer inventory contains 411 directly reachable
entries, with 19 still C-owned: 392/411, or 95.4%, are assembly-owned by
reachable-symbol count. The call graph has 38 unresolved direct callees and
`completeCallGraph=false`, so this remains a profile-specific estimate rather
than a complete or size-weighted measure. No directly reachable cache or
zone-heap C owners appear in this profile.

## Scope and remaining work

This slice ports the options page and the slider/checkbox rendering helpers.
Nine other menu draw pages, console printing/debug paths, the status-bar change
notifier, and DOS/VESA video lifecycle and palette routines remain among the
direct C-owned renderer dependencies. Full-scene parity and FPS measurement
remain open.
