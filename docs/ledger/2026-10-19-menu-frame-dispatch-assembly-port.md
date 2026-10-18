# Menu frame dispatcher moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_Draw` now selects the assembly implementation in the default i486 profile.
The C implementation remains available as the BENCH oracle and in the
C-reference profile. The assembly routine preserves the early returns,
recursive-draw behavior, screen-copy flags, console/fade selection, all 18 menu
states, enter-sound handling, and the final audio update.

The console-height branch matches the compiled DJGPP C oracle for the tested
positive zero, negative zero, positive subnormal, and NaN values. The C build's
unordered NaN comparison follows the fade path; the assembly test uses the same
branch result.

## Direct C/assembly parity

The DOSBox-X fixture passes 27 exact C/assembly cases: early returns, every
menu state, recursive drawing, invalid states, console/fade paths, zero and
subnormal values, NaN, and enter sound. It compares ordered draw/update/sound
events, mutable state, ABI preservation, and the x87 control word. The existing
overlay dispatch, pause/loading, menu text, centered picture, text-box, and
console draw fixtures pass in the same run.

Run the focused parity fixture with:

```powershell
tools/bench-dos.ps1 -ScreenOverlaysImplementation asm -ScreenOverlaysOnly `
  -CpuTarget i486 -NoBootstrap -SkipIsaAudit -TimeoutSeconds 180
```

`-SkipIsaAudit` makes this a diagnostic runtime run; the release gate below
provides the i486 instruction proof.

## Strict i486 release verification

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict build passed project and runtime proofs for 165 and 235 exact
objects. The complete executable gate verified 162,510 relocated instructions,
529 startup code rows, and the 9,207-instruction CWSDPMI provider. It found no
above-i486, unknown, exempt, or unclassified instructions or bytes.

The refreshed non-BENCH release ownership inventory contains 409 directly
reachable renderer entries, of which 29 remain C-owned: 380/409, or 92.9%, are
assembly-owned by reachable-symbol count. The call graph remains incomplete,
with 38 unresolved direct callees. This is a profile-specific symbol-count
estimate, not a weighted measure of implementation effort.

## Scope and remaining work

This slice owns menu frame setup and state dispatch. Individual menu screens,
sound playback, console drawing, and other rendering calls remain delegated to
their existing implementations. It does not measure FPS or establish
complete-scene image parity. The broader renderer port and full call-graph
review remain open.
