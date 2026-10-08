# Accepted renderer checkpoint

## Combined assembly selection passes the complete guest suite

`i486-asm-world-alias.json` combines all 38 accepted assembly modules and
83 implementation selectors. The fixed-speed 486 guest run
`out/dos-bench-20261008-083434` passes the complete exact reference suite,
including frame control, palette, math, visibility, public bindings, sky,
dispatch, drawing driver, view, framebuffer drawing, chase camera, alias
pipeline and world control. Preserved registers, stack and x87 control-word
contracts pass alongside state, immutable input, pixels and guard comparisons.
The final correctness result is PASS with checksum `3755475462`.

The executed source tree is
`DD47AA8537AF60FE5801F1B69B1E79753B5F2A7ECC171144AF280F6ABAA8B456`.
The guest binary and provider match the retained ISA artifacts exactly.
The complete report, staging configuration and proof bindings are retained in
`out/main-world-combined-guest-accepted-20261008`. A queue wrapper initially
matched `FAIL` inside `0 failures`; the actual guest result was successful.
Word-boundary matching corrected the wrapper without changing the renderer.

The ownership inventory recognizes compiler clones as their original C
functions, including visibility support in `model.c`. Adversarial host checks
cover clone attribution, direct root traces, indirect transfer reporting and
rejection of text-resident constants as functions. The accepted combined
release still has eight directly reachable C support entries. Further
initialization, effects, cache/tile and indirect-target closure also remain
required. This checkpoint does not claim a complete assembly renderer.

## Whitespace cleanup and release pins preserve all allocated behavior

Before committing the accumulated accepted ports, 79 whitespace findings in
added C oracle lines were cleaned in eight files. Original bytes, hashes and
the exact changed lines are retained. All 480 project objects from default,
combined release, benchmark and profiling builds were frozen beforehand.
Rebuilding proves identical allocated section bytes and normalized relocations,
apart from the existing `__TIME__` text in `host.c` and `host_cmd.c`. Every
changed clock byte is independently proved literal data, and all other bytes
remain identical. The resulting source tree is
`629631B6920ACE55D3F33161D40A3EA64983F5C1B173A2F2333AEC8E11EB016A`.

The default release passes 171,204 actual relocated instruction sites. The
combined release, benchmark and profiling builds pass 169,110, 241,717 and
247,875 respectively. Each includes 120 project objects, all 235 required
runtime inputs, 529 startup instructions, and 9,207 provider instructions plus
its one proved runtime variant. There are zero post-486 instructions, unknowns
or instruction exemptions. Before/after objects and complete proofs are retained
in `out/renderer-pre-whitespace-snapshot-20261008` and
`out/renderer-post-whitespace-snapshot-20261008`.

The cached whitespace review also found 437 trailing spaces or tabs in 26
new maintained assembly sources/includes. Removing only those characters and
reassembling all seven affected modules in four build variants proves all 28
objects have identical allocated bytes and normalized relocations. This binds
the cleaned assembly to the same strictly audited executable instructions;
no executable changes. The proof is retained in
`out/renderer-asm-whitespace-proof-20261008`. The final checkpoint source tree is
`B3415FAA6C38B2D5A5AC09C42CD1D0F703E57493E95A04C073C18167EF867102`.

The deliberate release-pin refresh records 120 objects and the executable in
`tools/golden/i486-release.sha256`; immediate verification passes. Build flag
goldens, selector forwarding and the documentation structure also pass. Local
checkpoint commits preserve unfinished work and are not pushed. Full-frame
soak acceptance and the remaining conversions are separate subsequent gates.
