# Player setup menu drawing moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_Setup_Draw` now selects the i486 assembly implementation in the screen
overlay assembly profile. The C body remains available as `M_Setup_Draw_C` in
BENCH builds as the parity oracle. The page preserves the plaque and title,
hostname and player-name boxes, shirt and pants labels, accept box, translated
player preview, and blinking cursors.

The assembly entry keeps the original centered-title arithmetic and x87
truncation behavior. Its translation-table call pushes the `top` and `bottom`
arguments in the C calling-convention order. The strict release uses the
existing assembly menu and player-translation helpers selected by the build.

## Direct C/assembly parity

The focused DOSBox-X screen-overlay run passed 240 setup-page cases. It covers
all five cursor states, four viewport widths, six shirt and pants colors,
three x87 precision modes, four rounding modes, four hostname/player-name
length patterns, and multiple animation times. The fixture compares complete
text and picture traces, guard regions, identity and translated color tables,
ABI state, and the x87 control word.

The same run passed all screen-overlay fixtures, including 288 key-page cases
and eight key-lookup cases, and ended with `486 benchmark correctness PASS` at
`out/dos-bench-20261019-034315/bench-result.json`. This focused diagnostic
skipped the ISA audit; the separate release build below supplies that proof.

## Strict i486 release verification and ownership

The strict release build with `ScreenOverlaysImplementation=asm` and
`CpuTarget=i486` passed. Source and runtime proofs covered 165 project objects
and 235 installed runtime objects, for 400 exact object proofs. The source
object audit checked 123,636 instructions; the linked object and executable
audits checked 161,933 instructions/opcodes. No above-i486, unknown, exempt, or
non-instruction bytes were reported. The final-byte startup audit covered 529
CODE rows, and the DPMI provider audit covered 9,207 instructions with zero
exemptions.

The refreshed non-BENCH renderer inventory contains 412 directly reachable
entries, with 16 still C-owned: 396/412, or 96.1%, are assembly-owned by
reachable-symbol count. The inventory has 38 unresolved direct callees and
`completeCallGraph=false`; this is a profile-specific symbol-count estimate,
not a complete or size-weighted measure.

## Scope and remaining work

This slice ports the player setup drawing procedure. Cache loading, picture and
text drawing, translation-table construction, and player translation remain
calls into existing engine helpers. Other menu pages and broader renderer,
video, and lifecycle procedures still need ownership work. The parity and ISA
results do not measure standalone FPS or speedup.
