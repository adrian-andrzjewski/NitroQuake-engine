# Multiplayer game-options menu moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_GameOptions_Draw` now has an explicit i486 assembly implementation in
`screen_overlaysasm.s`. The C implementation remains available as
`M_GameOptions_Draw_C` in the BENCH parity build and remains the selected path
when the screen-overlay assembly profile is disabled. No selector was added;
the routine follows `ScreenOverlaysImplementation=asm`.

The assembly draws the plaque and centered multiplayer title, the begin-game
box, player/game/team/skill/limit labels, expansion-specific episode and level
descriptions, the animated cursor, and the timed server-info message. The
header asserts the `cvar_t.value` offset used by the assembly. Float-to-int
casts truncate toward zero. Cursor timing computes `realtime * 4` under the
incoming x87 precision and rounding mode, then switches only the integer cast
to truncation and restores the control word.

## Direct C/assembly parity

The focused screen-overlay run passed 96 exact C/ASM game-options cases. Eight
input sets were crossed with three x87 precision settings and all four rounding
modes. Coverage includes base, Hipnotic, and Rogue episode tables, Rogue team
rules, zero and fractional limits, title widths from zero through 401 pixels,
four viewport widths, cursor timing near frame boundaries, and visible/expired
server-info messages. The fixture compares each glyph, cache/picture event,
ABI result, x87 control word, and timeout state.

The first run exposed a cursor mismatch when the incoming x87 mode rounded
`realtime * 4` to a single-precision integer boundary. The assembly had changed
the control word before multiplication. It now preserves the C intermediate
rounding and applies truncation only for the final integer conversion.

Reproduce the focused runtime matrix with:

```powershell
tools/bench-dos.ps1 -ScreenOverlaysImplementation asm -ScreenOverlaysOnly `
  -CpuTarget i486 -SkipIsaAudit -NoBootstrap -TimeoutSeconds 180
```

This is a diagnostic BENCH run because it skips the BENCH ISA audit. The strict
non-BENCH release audit below verifies the production assembly source.

## Strict i486 release verification and ownership

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict release gate passed source proofs for 167 project objects and 235
installed objects, verifying 402 exact native/annotated object proofs. It
verified 161,517 linked opcodes, 529 startup rows, and 9,207 provider
instructions, with zero instructions above i486, unclassified, exempt, or
unenforced.

The refreshed non-BENCH ownership inventory contains 605 renderer entries and
415 directly reachable entries. Eight remain directly C-owned, so 407/415, or
98.1%, are assembly-owned by reachable-symbol count. The report has 38
unresolved direct callees and `completeCallGraph=false`; this is a
profile-specific symbol-count estimate, not a weighted completion figure.
There are no directly reachable cache, zone-heap, or DOS/VESA video-lifecycle
C owners.

## Scope and remaining work

The eight directly reachable C owners are `_Con_DPrintf`, `_Con_DebugLog`,
`_Con_Printf`, `_M_LanConfig_Draw`, `_M_Search_Draw`,
`_M_SerialConfig_Draw`, `_M_ServerList_Draw`, and `_M_Video_Draw`.
`M_GameOptions_Draw` is now assembly-owned in the release profile. Full-scene
parity and FPS measurement remain open; this menu correctness run does not
measure either.
