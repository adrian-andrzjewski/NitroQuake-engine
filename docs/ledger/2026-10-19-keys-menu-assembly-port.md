# Key binding menu drawing moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_Keys_Draw` and `M_FindKeysForCommand` now use explicit i486 assembly in the
screen-overlay assembly profile. Their C implementations remain available as
the reference for BENCH parity and the C-reference profile. The page still
renders the custom title, mode-specific prompt, all 18 action labels, up to two
key names per action, and the selected-row cursor.

The assembly lookup scans the 256 key slots in order, compares command prefixes
directly, returns the first two matches, and stops once both are found. The page
keeps the original centering and row positions, key-name strings, x87 truncation
semantics for the blinking cursor, and control-word preservation.

## Direct C/assembly parity

The focused DOSBox-X overlay run passed eight direct lookup cases covering no
match, late and final-slot matches, one and two prefix matches, empty and short
strings, and a full-table scan. The page fixture passed 288 cases across four
viewport widths, three x87 precision settings, four rounding modes, three
binding patterns over all 18 commands, both key-grab states, rotating cursor
rows, and animated times. It compares complete emitted text and picture traces,
guard regions, ABI state, and the x87 control word. The remaining focused
overlay fixtures passed in the same `486 benchmark correctness` run at
`out/dos-bench-20261019-031534/bench-result.json`.

## Strict i486 release verification and ownership

The strict `ScreenOverlaysImplementation=asm`, `CpuTarget=i486` release build
passed. It verified 165 project objects and 235 runtime sources, for 400 exact
native/annotated object proofs. The complete executable gate checked 161,956
relocated instructions, 529 startup CODE rows, and 9,207 provider instructions,
with no above-i486, unknown, or exempt instructions.

The refreshed non-BENCH renderer inventory contains 412 directly reachable
entries, with 17 still C-owned: 395/412, or 95.9%, are assembly-owned by
reachable-symbol count. The inventory still has 38 unresolved direct callees
and `completeCallGraph=false`; this is a profile-specific estimate, not a
complete call-graph or size-weighted measure.

## Scope and remaining work

This slice ports the key binding page and its 256-slot lookup helper. Other menu
draw pages, console printing/debug paths, the status-bar change notifier, and
DOS/VESA video lifecycle and palette routines remain among the direct C-owned
renderer dependencies. The parity run is correctness evidence; it does not
record a standalone speedup or FPS result.
