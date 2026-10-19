# Quit dialog drawing moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_Quit_Draw` now uses explicit i486 assembly in the screen-overlay assembly
profile. Its C body remains available to the BENCH parity build as a reference.
The assembly preserves the recursive previous-page redraw when the quit dialog
is entered from another menu, then draws the same quit plaque and one of the
eight four-line messages.

## Direct C/assembly parity

The focused DOSBox-X overlay run passed 624 exact C/assembly cases: 384 message
cases across eight messages, four viewport widths, three x87 precision modes,
and four rounding modes, plus 240 recursive redraw cases across five previous
menu states and the same width/precision/rounding matrix. The fixture compares
the complete text and picture traces, relevant menu state, ABI state, and x87
control word. The other focused overlay fixtures and `486 benchmark correctness`
also passed in the run at `out/dos-bench-20261019-024941/bench-result.json`.

## Strict i486 release verification and ownership

The strict `ScreenOverlaysImplementation=asm`, `CpuTarget=i486` release build
passed. It verified 165 project objects and 235 runtime sources, for 400 exact
native/annotated object proofs. The complete executable ISA gate checked
162,016 relocated instructions, 529 startup CODE rows, and 9,207 provider
instructions, with no above-i486, unknown, or exempt instructions.

The refreshed non-BENCH renderer inventory contains 411 directly reachable
entries, with 18 still C-owned: 393/411, or 95.6%, are assembly-owned by
reachable-symbol count. The inventory still has 38 unresolved direct callees and
`completeCallGraph=false`; this is a profile-specific estimate, not a complete
call-graph or size-weighted measure. No directly reachable cache or zone-heap C
owners appear in this profile.

## Scope and remaining work

This slice ports the quit dialog renderer. Other menu draw pages, console
printing/debug paths, the status-bar change notifier, and DOS/VESA video
lifecycle and palette routines remain among the direct C-owned renderer
dependencies. Full-scene parity and FPS measurement remain open.
