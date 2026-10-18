# Intermission status overlay moves to i486 assembly (2026-10-18)

## Behavior and selector

`Sbar_IntermissionOverlay` now composes the normal intermission screen in i486
assembly under the existing `ASM486_SBAR_DRAW` selector and default i486
profile. Its `Sbar_IntermissionNumber` helper is also assembly-owned. The normal
path draws the completion/intermission pictures, elapsed-time digits, and
secret/monster counts. Deathmatch mode delegates to the assembly
`Sbar_DeathmatchOverlay` path. C versions remain available as BENCH oracles.
The finale overlay remains C.

## Exact C/ASM parity

The focused fixture compares C and assembly event order, state, scoreboard
sorting, cache paths, and ABI behavior in four cases:

- `cooperative-time-and-counts`
- `minute-rollover-and-long-minutes`
- `deathmatch-full-roster-dispatch`
- `deathmatch-empty-roster-dispatch`

All four pass exactly. The existing status-bar drawing, face, mini-deathmatch,
and full-deathmatch fixtures also pass in the same run.

## Strict i486 verification

Reproduction command:

```powershell
tools/bench-dos.ps1 -SbarDrawOnly -SbarDrawImplementation asm-fixture -CpuTarget i486 -NoBootstrap -TimeoutSeconds 180
```

The strict focused run passed the complete executable ISA gate: 289,402
relocated instructions, with zero above-i486, unknown, or exempted
instructions. The object audit also passed with zero such instructions. The
four intermission parity cases and all existing focused status-bar fixtures
passed. This fixture run did not measure FPS.

## Scope and remaining work

The default i486 path now owns both ordinary and deathmatch intermission
composition. The finale overlay and other reachable renderer C routines still
need review and migration. The same profile's rough reachable-symbol estimate
is 318/366 (86.9%) assembly-owned, with 48 directly reachable renderer C
dependencies and 82 unresolved direct callees; `completeCallGraph=false`.
This is not a code-size or effort percentage and does not establish complete
renderer ownership or full-scene parity.
