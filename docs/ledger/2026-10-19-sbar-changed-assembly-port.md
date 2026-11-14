# Status-bar refresh state setter i486 assembly port (2026-10-19)

## Selection and behavior

The existing `SbarPrimitiveImplementation=asm` selector now owns
`Sbar_Changed` in `src/client/sbarasm.s`. It stores zero to `sb_updates`, matching the
C routine's request to refresh the status bar next frame. The C-reference
profile still selects the original C function. BENCH retains the C oracle as
`Sbar_Changed_C` while the public `Sbar_Changed` symbol resolves to assembly.

## Direct C/assembly parity

The status-bar primitive fixture compares the resulting `sb_updates` value for
six initial states: signed minimum, -1, 0, 1, 3, and signed maximum. DOSBox-X
reported:

```text
sbar changed state C/ASM PASS (6 cases, 0 failures)
sbar number and coordinate primitives C/ASM PASS (0 failures; 18 formatter and 544 scene-state cases)
486 benchmark correctness PASS
```

Reproduce the fixture from `quake/` with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -SbarPrimitivesOnly
```

The hash-bound report is `out/dos-bench-20261019-061323/bench-result.json`.

## Strict i486 verification

The BENCH build's object and linked-object audits passed 261,097 and 299,394
instructions. Its relocated executable proof verified all 299,394 opcodes in
434 code ranges; source mapping bound 434 contributions across 2,324 CODE and
35 DATA ranges. The startup proof audited 529 code rows and the provider proof
audited 9,207 instructions. There were no above-i486, unknown, exempted,
undecoded, or unclassified sites.

The non-BENCH release build's object and linked-object audits passed 123,617
and 161,914 instructions. Its relocated executable proof verified all 161,914
opcodes in 420 code ranges; source mapping bound 420 contributions across
1,445 CODE and 35 DATA ranges. Startup and provider proofs passed for 529 and
9,207 instructions, with zero exemptions. The build manifest selects
`SbarPrimitiveImplementation=asm`; the release map resolves `Sbar_Changed` to
`obj/sbarasm.obj` and omits the C symbol. The BENCH map contains both
`Sbar_Changed_C` and assembly `Sbar_Changed`.

The regenerated release ownership inventory reports 412 directly reachable
renderer entries, 12 directly reachable C dependencies, and 38 unresolved
direct callees. This port moves the count-based estimate to 400/412 (97.1%);
the inventory remains incomplete and does not weight functions by size or
complexity. Full renderer parity and capture gates remain open.
