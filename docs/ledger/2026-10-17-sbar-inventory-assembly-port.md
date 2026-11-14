# Status-bar inventory i486 assembly port (2026-10-17)

## Behavior and selector

`src/client/sbar_inventory_asm.inc` now contains the optimized i486 implementation of
`Sbar_DrawInventory`, selected by `SbarInventoryImplementation=asm` in the
current assembly profile. It preserves the standard, Hipnotic, Rogue and
combined-expansion branches, weapon flash timing, ammo formatting, item and
sigil drawing order, and the `sb_updates` side effect. `sbar_draw_asm.inc`
routes the production dispatcher to the new entry.

`SbarInventoryImplementation=c` retains the original C path for the reference
profile. BENCH builds also retain it as `Sbar_DrawInventory_C` for direct
differential checks; the assembly profile omits the C body from production
builds. `asm_sbar.h` asserts the client-state offsets and game constants used by
the assembly.

## Direct C/assembly parity

`Bench486SbarInventoryCases` exercises five states (empty, standard, Hipnotic,
Rogue, and combined expansion inventory) under all four x87 rounding modes. It
compares the ordered draw events and status-bar update state for 20 cases. The
isolated DOSBox-X run passed all 20 with zero failures:

```text
out/dos-bench-20261017-033155/bench-result.json
```

The inventory-only host command closes its report and exits after this fixture,
so it does not fall through into the unrelated general memory benchmark.

## Strict i486 build and Demo 1 run

The BENCH build passed the strict project-object, linked-object, relocated
executable, startup and CWSDPMI gates. It decoded 243,202 project-object
instructions and 281,499 linked instructions, with zero above-i486 or unknown
instructions, exemptions, skipped bytes, or mismatches. The startup proof
covered 529 instruction rows and the DPMI provider proof covered 9,207
instructions.

Three Demo 1 runs on the same all-assembly profile each completed 969 frames
with the enforced framebuffer checksum `1047377823`. The median was
`15.141444 FPS` (`63.996537`, `63.996543`, and `63.996520` seconds):

```text
out/dos-timedemo-20261017-033417/timedemo-result.json
```

The supplied older QBENCH page-fault screenshot was not reproduced by this
build. Its executable did not have a matching map, so this run does not
establish the cause of that older fault.

## Traceability and remaining scope

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/client/sbar.c:Sbar_DrawInventory` | `src/client/sbar_inventory_asm.inc:_Sbar_DrawInventory_asm486` | 20 cases across five inventory states and four x87 modes | Strict i486 gates pass; three Demo 1 runs preserve 969 frames and checksum `1047377823` |

This is status-bar composition support. The ownership report still lists 73
directly reachable C renderer entries, primarily screen, menu, console and
diagnostic support; the overall renderer port remains active.
