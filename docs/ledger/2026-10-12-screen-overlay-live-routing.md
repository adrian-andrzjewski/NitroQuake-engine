# Screen overlay live-call routing and parity (2026-10-12)

## Fixture hooks and production calls

The notify string, centered string, and centered-string erase assembly paths
need test hooks to compare C and assembly calls. In BENCH486 builds, those
hooks are now used only while the direct differential fixture is active. Normal
benchmark frames take the same `Draw_Character` and `Draw_TileClear` calls as
the selected renderer. This prevents test instrumentation from replacing live
drawing during integration runs.

| Original entry | Assembly path | Live backend | Direct evidence |
|---|---|---|---|
| `SCR_DrawNotifyString` | `screen_notifyasm.s` | `Draw_Character` | 19 cases, four rounding modes, high-bit dimensions at three precisions, plus exact live framebuffer route |
| `SCR_DrawCenterString` | `screen_centerasm.s` | `Draw_Character` | 18 cases across 12 x87 control words, plus exact 8-bit and 16-bit live framebuffer routes |
| `SCR_EraseCenterString` | `screen_eraseasm.s` | `Draw_TileClear` | 252 direct C/assembly/public cases across 12 x87 control words |

The C implementations remain the selectable reference. `Draw_Character` and
`Draw_TileClear` remain C-owned backend routines; this slice verifies the screen
entries and their actual backend calls.

## 486 fixture and ISA evidence

Each focused `bench-dos.ps1` run used `CpuTarget=i486` and DOSBox-X's 486DX+x87
profile. All three direct fixtures passed with zero mismatches. Each selected
binary passed project-object, linked-object, relocated-executable, startup,
and CWSDPMI provider audits. The linked instruction totals were 210,817 for
erase, 211,250 for centered string, and 211,696 for notify string; the audits
reported zero above-i486 instructions, unknown encodings, or exemptions. The
startup proof covered all 1,660 loaded bytes and 529 code rows; the provider
proof covered 9,207 instructions.

The fixture-scoped routing static checks and the focused screen selector tests
also passed (6 tests).

## Exact scene pair

`render-parity-dos.ps1` ran `demo1-vga-full` using a C-reference profile and a
profile selecting only the three screen assembly entries. The paired scene
used the same 969-frame script and source-tree fingerprint. All 964
post-warmup checksums matched exactly. The 320x200 indexed capture matched all
64,000 pixel indices and every palette byte.

This scene pair used `-VisualParityOnly`, so it is parity evidence rather than
an ISA certification. The three separate focused runs above provide the strict
instruction and runtime-provider evidence. The scene pair does not close the
remaining renderer ownership or broader gameplay coverage.

## Reproduction

Focused strict fixtures:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -ScreenEraseCenterStringImplementation asm -ScreenEraseCenterStringOnly -NoBootstrap -TimeoutSeconds 180
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -ScreenCenterStringImplementation asm -ScreenCenterStringOnly -NoBootstrap -TimeoutSeconds 180
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -ScreenNotifyImplementation asm -ScreenNotifyOnly -NoBootstrap -TimeoutSeconds 180
```

Scene parity report: `out/screen-overlays-live-parity-20261012/render-parity-result.json`.
