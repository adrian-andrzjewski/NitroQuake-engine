# Classic solo scoreboard assembly port

The default i486 renderer now selects assembly for `Sbar_SoloScoreboard` and
`Sbar_DrawScoreboard`. The C versions remain available as BENCH parity oracles.
The assembly formatter builds the monster, secret, and time rows, applies the
client clock's truncation and signed-division rules, centers the level title,
and delegates glyph rendering through the selected `Sbar_DrawString` path.

## Focused parity

The `asm-fixture` DOSBox-X run compares exact captured text hashes, lengths, and
final draw coordinates for four cases: wide centered counters, deathmatch with
negative time, counters wider than three digits, and negative fractional time.
Three cases exercise the scoreboard dispatcher; the deathmatch case exercises
the solo formatter directly because the deathmatch overlay has its own C/ASM
fixture.

```powershell
tools/bench-dos.ps1 -SkipIsaAudit -SbarDrawOnly `
  -SbarDrawImplementation asm-fixture -CpuTarget i486 -NoBootstrap `
  -TimeoutSeconds 180
```

All four new cases passed exact C/ASM formatting and position parity. The
existing status-bar dispatcher, face, mini-scoreboard, full deathmatch,
intermission, and finale fixtures also passed. This is a diagnostic BENCH run;
the strict release gate below supplies the ISA proof.

## Strict i486 release verification

```powershell
tools/build-dos.ps1 -SbarDrawImplementation asm `
  -SbarPrimitiveImplementation asm -CpuTarget i486 -NoBootstrap
```

The strict gate passed 124,803 project-object instructions and 163,100 linked
instructions, with zero above-i486, unknown, or exempt instructions. It verified
235 source-bound runtime inputs, 418 executable CODE ranges, and 1,460 final
CODE ranges. Startup proof covered 529 code rows and 1,660 loaded bytes; the
maintained CWSDPMI provider passed with 9,207 instructions and no exemptions.

The refreshed release ownership inventory contains 405 directly reachable
renderer entries, of which 30 remain C-owned: 375/405, or 92.6%, are assembly-
owned by reachable-symbol count. The call graph remains incomplete, with 38
unresolved direct callees and `completeCallGraph=false`. This percentage is a
profile-specific symbol-count estimate, not a weighted measure of effort.

## Remaining validation

The focused formatter parity and strict instruction gates pass. Full-scene
image parity and FPS were not measured in this slice. The broader renderer port
remains active, including the unresolved call graph and remaining C-owned
rendering and lifecycle procedures.
