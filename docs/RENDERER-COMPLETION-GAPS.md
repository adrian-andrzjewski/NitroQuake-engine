# Renderer completion gaps

The objective is the complete software renderer and its rendering-time
dependencies, with explicitly owned i486 instructions and equivalent output.
Passing the ISA audit on a C function does not convert that function to assembly.
Selecting every existing assembly switch does not establish complete ownership.

As of 2026-10-17, the i486 build defaults to the complete 129-entry assembly
selector profile in
[`i486-asm-selectable-current.json`](../tools/renderer-profiles/i486-asm-selectable-current.json).
[`i486-c-reference.json`](../tools/renderer-profiles/i486-c-reference.json)
is the complete C parity profile. The dated entries below preserve the status
reported when each comparison was recorded. The 2026-10-16 entity-trace,
area-link clipper, and touched-leaf ports add exact C/ASM correctness and
strict instruction evidence, but no FPS or complete renderer-ownership claim.

The 2026-10-18 focused BENCH ownership report contains 381 directly reachable
renderer entries and 69 directly reachable C dependencies, or roughly 82%
assembly-owned by reachable-symbol count. This is only a rough progress
estimate: the inventory reports 64 unresolved direct callees, one selected
indirect-target set, and `completeCallGraph=false`; it does not weight routines
by size or complexity. The surface-cache sizing and lifecycle entries added
below pass their direct fixtures and the complete focused i486 executable gate.

The default i486 surface-cache assembly selection now owns
`D_SurfaceCacheForRes`, `D_InitCaches`, and `D_FlushCaches` for the cache-only
drawing profile. The full drawing-driver assembly profile continues to use its
own `D_FlushCaches` entry. `COM_CheckParm`, `Q_atoi`, and `Con_Printf` remain
shared C helpers, and the C reference routines remain available in C-reference
and BENCH builds. Direct parity passes six default-size cases plus the
`-surfcachesize` override, init state/guard/canaries, and flush owner/sentinel
cases. The focused executable passed the strict i486 audit. Its fast-path
microbenchmark does not measure the newly ported sizing or lifecycle routines;
see the [surface-cache lifecycle port](ledger/2026-10-18-surface-cache-lifecycle-assembly-port.md).

## Accepted incremental work

The cold model-load path used by alias rendering now dispatches through i486
assembly in the `AliasControlImplementation=asm` profile; the C implementation
remains the reference path. A seven-case direct fixture and the exact Demo 2
C/ASM pair pass, and the production assembly profile passes the complete i486
executable gate. This closes the `Mod_LoadModel` dispatch slice only; remaining
renderer C ownership and broader acceptance are still open. See the
[model-load assembly port](ledger/2026-10-16-model-load-assembly-port.md).

Sprite orientation/dispatch, the public sprite-frame entry, `VectorNormalize`
and `AngleVectors` have independent assembly entries and direct fixtures. The
corrected sprite/math integration pair verified actual assembly selection and
matched 1,960 post-warmup frame checksums and two indexed frame/palette captures.
See [sprite and math port](ledger/2026-10-07-sprite-orientation-and-render-math-port.md).

Animated light styles and recursive/public point lighting have now passed
14,336 style frames and 1,600 point-light cases, plus three demo scenes twice per
profile: 6,058 post-warmup checksum comparisons and six exact captures. Their
reviewed files are integrated; the two new switches still default to C. See
[light-control port](ledger/2026-10-07-light-control-port.md).

Palette generation and updates passed 480 direct cases and 9,728 update frames,
including uninterrupted state, ABI and guard checks. The actual-selector pair
matched 6,058 post-warmup checksums and six exact indexed/palette captures. The
reviewed files are integrated and the direct fixture also passed in the main
checkout. See [palette port](ledger/2026-10-07-palette-assembly-port.md).

The fourteen frame-control entries passed 22,528 direct comparisons and the
three-scene, two-repeat pair: 6,058 post-warmup checksum comparisons and six
exact indexed/palette captures. ABI, guards and uninterrupted visibility/bounds
state pass, including the frame-counter wrap. See
[frame-control port](ledger/2026-10-07-frame-control-assembly-port.md).

The 2026-10-17 frame-control follow-up moves the render-time `Hunk_LowMark`
getter into `r_framecontrolasm.s`; the release `zone.obj` no longer defines the
symbol, while BENCH retains `Hunk_LowMark_C` for parity. Its eleven-state ABI
fixture passed, and the paired three-scene run matched all 6,058 post-warmup
checksums plus six indexed/palette captures exactly. The all-selector i486
release gate also passed. This closes that shared support dependency only;
remaining screen, menu, console and status-bar C ownership and visual acceptance
gates remain open. See the
[frame-control follow-up](ledger/2026-10-07-frame-control-assembly-port.md).

The twenty remaining math-support entries passed their focused scene pair:
6,058 exact post-warmup checksums and six exact indexed/palette captures.
Nineteen returning routines also passed 29,184 direct cases under twelve x87
settings and 8,192 uninterrupted matrix frames. The terminating error boundary
is inspected separately. Reviewed files are integrated; see the
[math support port](ledger/2026-10-07-math-closure-assembly-port.md).

Point-to-leaf traversal, visibility decompression and PVS selection passed
9,216 direct cases and an 8,192-step continuous sequence, followed by 6,058
exact frame checksums and six indexed/palette captures. Reviewed visibility
files are integrated. See the
[visibility port](ledger/2026-10-07-visibility-assembly-port.md).

The frozen combined snapshot after math support integration passed all six
committed scenes twice: 11,842 exact post-warmup checksums and twelve exact
indexed/palette captures. Executables and hash-bound verification records are
retained with the pair. This snapshot precedes visibility integration. See the
[combined comparison](ledger/2026-10-07-all-selectable-combined-parity.md).

After visibility integration, the main aggregate direct suite also passed with
every requested selector verified, zero exact-result or ABI failures and
completed continuous state sequences. That release inventory found 69 reachable
C renderer dependencies before public-entry integration. See the
[combined direct acceptance](ledger/2026-10-07-combined-direct-acceptance.md).

Thirty-two public forwarding entries are now assembly-owned. Their focused
pair matched 6,058 frame checksums and six indexed/palette captures exactly.
The full and mixed direct selections passed exact transfer targets, the sprite
hook, ABI and guard checks. Earlier assembly modules retain identical allocated
bytes and normalized relocations. The subsequent main aggregate suite also
passes in `out/dos-bench-20261007-210151`. See the
[public-entry port](ledger/2026-10-07-public-entry-assembly-port.md).

The five sky entries passed 3,072 scalar and 1,440 compositor cases, an
8,192-frame time sequence and 2,048 continuous composited frames. Their focused
pair matched 6,058 frame checksums and six indexed/palette captures exactly.
All thirty preceding assembly modules retain identical allocated bytes and
normalized relocations. The reviewed sky files are integrated; see the
[sky port](ledger/2026-10-07-sky-assembly-port.md).

Twelve renderer dispatch/control entries passed normal and profiling fixtures,
mixed selection and the focused three-scene pair: 6,058 exact post-warmup
checksums and six indexed/palette captures. Reviewed files are integrated;
see the [dispatch port](ledger/2026-10-08-render-dispatch-assembly-port.md).

Thirteen drawing-driver entries passed 18,176 direct comparisons in both normal
and profiling builds, plus the three-scene pair: 6,058 exact post-warmup checksums
and six indexed/palette captures. Reviewed files are integrated; see the
[drawing driver port](ledger/2026-10-08-drawing-driver-assembly-port.md).

Thirteen view/camera control entries passed 18,176 exact comparisons in each
normal and profiling fixture, plus 6,058 exact scene checksums and six complete
indexed/palette captures. Reviewed files are integrated; see the
[view control port](ledger/2026-10-08-view-control-assembly-port.md).

All eighteen framebuffer drawing entries passed 11,648 exact cases in each
normal and profiling fixture, plus 6,058 exact scene checksums and six complete
indexed/palette captures. Reviewed files are integrated; see the
[framebuffer drawing port](ledger/2026-10-08-framebuffer-drawing-assembly-port.md).

Four chase-camera entries passed 14,336 exact cases in each normal and profiling
fixture, twelve x87 settings, 8,192 continuous calls and 48 guard checks. Their
active-camera scene pair passes 6,058 checksums and six indexed/palette captures.
Reviewed files are integrated; the original collision fraction bits are
preserved. See the [chase camera port](ledger/2026-10-08-chase-camera-assembly-port.md).

The assembly chase path now also owns its recursive BSP hull collision trace
through `SV_RecursiveHullCheck_asm486`, with the C routine retained as its
parity oracle and for non-assembly callers. The focused fixture passed 14,336
exact cases, twelve x87 settings, 8,192 sequence calls, and 48 guard checks;
the complete candidate executable gate passed. The `ChaseOnly` fixture does
not measure FPS. See the
[chase hull-check port](ledger/2026-10-16-chase-hull-check-assembly-port.md).

Nine alias-pipeline entries passed 11,648 exact cases in each normal and profiling
fixture, twelve x87 settings, 8,192 continuous calls and 128 guard checks. Their
three-scene pair passes 6,058 checksums and six indexed/palette captures.
Reviewed files are integrated, including original private skin-descriptor state.
See the [alias pipeline port](ledger/2026-10-08-alias-pipeline-assembly-port.md).

Nine world-control entries pass 11,648 exact cases in each normal and profiling
fixture, twelve x87 settings, 8,192 cache/state calls and 144 guard checks.
Three scenes and two runs pass 6,058 checksums and six indexed/palette captures.
Reviewed integration preserves the independently accepted alias pipeline;
`i486-asm-world-alias` selects both cohorts. See the
[world control port](ledger/2026-10-08-world-control-assembly-port.md).

Particle simulation and free-list initialization have an isolated i486 profile.
The C-reference and assembly profiles pass the six-scene pair twice each, with
11,842 exact post-warmup frame checksums and twelve exact indexed/palette
captures. The candidate binary passes the complete relocated, startup, and
provider ISA gate without exemptions. Per-scene timings differ by at most
0.021%; the broader all-assembly profile and broader particle-effect stress
scenarios remain open. See the
[particle port](ledger/2026-10-06-particle-update-assembly-port.md).

The pre-existing 32-bit `D_DrawParticle` assembly rasterizer now has a
selectable C oracle and a focused parity record. Its direct fixture passed 104
comparisons across four x87 rounding modes; the strict `demo2-wizspike-event`
pair matched seven post-warmup checksums and all indexed framebuffer and
palette bytes on both repeats. The strict i486 executable and support-code
audits passed. This verifies the existing rasterizer and does not count as a
new assembly conversion; see the
[`D_DrawParticle` verification ledger](ledger/2026-10-10-d-drawparticle-assembly-port.md).

The existing `D_DrawZSpans` assembly path now has a retained BENCH486 C oracle
and passed 117 exact guarded-buffer comparisons, including Quake's negative
`SURF_DRAWBACKGROUND` depth. Its selected executable, startup loader and
runtime-provider checks passed the strict i486 ISA gate with zero violations,
unknowns or exemptions. This is routine-level depth-buffer evidence; a full
scene pair remains outside this slice. See the
[z-span parity ledger](ledger/2026-10-10-d-drawzspans-assembly-parity.md).

`SCR_DrawCenterString` now has a retained C oracle and a selectable i486
assembly implementation. Eighteen deterministic cases passed across four x87
rounding modes and three precision settings, with exact guarded-framebuffer,
character-call, ABI and x87-state comparisons. The strict executable, startup
and CWSDPMI audits passed with zero violations or exemptions; the exact fixture
run used the selected 486DX+x87 DOSBox-X profile. This verifies one overlay
routine; complete-scene parity and broader screen/rendering ownership remain
open. See the
[center-string parity ledger](ledger/2026-10-10-screen-center-string-assembly-parity.md).

The opt-in frustum profile now selects assembly for both `R_TransformFrustum`
and `R_SetUpFrustumIndexes`. Its strict paired i486 run passed the complete
relocated executable, startup and CWSDPMI provider gates with zero instruction
violations, unknowns or exemptions. Three matched scenes produced 3,029 exact
post-warmup frame checksums and three exact indexed-framebuffer/palette
captures. C remains the default while broader renderer ownership work continues.
See the [frustum port](ledger/2026-10-09-frustum-transform-assembly-port.md).

The combined `i486-asm-selectable` profile now sets all 77 selectors to
assembly, including frustum transform. Its strict i486 paired run passed the
complete executable, startup and provider gates. Six scenes matched for 5,921
post-warmup checksums and six indexed-framebuffer/palette captures. This does
not mean every renderer entry point is assembly: the current ownership
inventory still finds 61 directly reachable C renderer functions. See the
[77-selector assembly-profile acceptance](ledger/2026-10-09-selectable-77-assembly-profile-acceptance.md).

`R_RocketTrail` now has a focused i486 assembly selector. Its strict candidate
passed the complete relocated-executable, startup and provider gates, the
16-case full-state/RNG fixture, and an exact Demo 2 pair with 980 matching
post-warmup frame checksums and no indexed-pixel or palette differences. The
focused profiles and traceability record are
[here](ledger/2026-10-09-r-rockettrail-assembly-port.md). A cumulative
The current cumulative candidate selects 108 assembly implementations. Its
fresh four-root BENCH486 ownership report lists 639 renderer
entries, of which 367 are directly reachable (345 assembly and 22 C), with 59
unresolved direct callees. This is a bounded trace, not a complete renderer
percentage: the report includes test hooks, and indirect transfers still need
explicit target review. It is retained at
`out/render-parity-screen-overlays-20261013/renderer-ownership-candidate.json`.

`R_BlobExplosion` now has an isolated assembly selector, a guarded direct
C-versus-assembly fixture and a focused Demo 2 manifest requiring the
`TE_TAREXPLOSION` event trace. Its seven-case DOSBox state/ABI/RNG fixture,
two-run C-versus-assembly scene pair, and strict candidate executable audit
pass. The pair matches all 64,000 indexed pixels and palette bytes, and all
seven post-warmup frame checksums; the event occurs once at frame 10 without
overflow. `R_BlobExplosion` is now the i486 release default while explicit C
and the separate i386 profile remain available. The normal non-BENCH release
executable also passes the full linked i486 ISA gate. This closes only the
BlobExplosion slice; the broader renderer conversion remains incomplete. See
the [BlobExplosion port ledger](ledger/2026-10-09-r-blobexplosion-assembly-port.md)
for report paths and exact scope.

Earlier sprite/math and light-control pair reports that failed to forward the
new selectors are invalid acceptance evidence. Their original results and
invalidation records are retained. Current runners forward declared selectors
from the shared table and compare requested selectors with the actual build
manifest before emulator execution.

`R_PrintDSpeeds` now uses the i486 assembly selected by
`PrintTimesImplementation=asm`; the same selector retains the original C
default and BENCH486 oracle. Six deterministic console cases under four x87
rounding modes passed all 24 exact C/assembly comparisons, including integer
truncation boundaries, ring wrap, canaries, ABI and x87 state. The selected
executable, startup and CWSDPMI provider all passed strict i486 audits with zero
violations or exemptions. This closes the stage-timing diagnostic only; screen
update, overlays, and the broader renderer ownership gaps below remain open.
See the [R_PrintDSpeeds port ledger](ledger/2026-10-13-r-printdspeeds-assembly-port.md).

`SCR_CalcRefdef` now has a selectable i486 assembly implementation in
`src/screen_refdefasm.s`; the original C routine remains the default and direct
oracle. Its 12 deterministic input cases passed under four x87 rounding modes
(48 exact state, event-order, ABI and x87-stack comparisons). The C-reference
and assembly profiles differ only in `ScreenRefdefImplementation`; seven
matched DOSBox-X scenes passed 6,885 post-warmup frame-checksum comparisons and
seven exact indexed-framebuffer/palette captures. The final cumulative i486
candidate also passed the full linked-object, relocated-executable, startup and
CWSDPMI ISA gates, then rendered the strict smoke scene successfully. The
diagnostic hooks are active only during the direct fixture; production calls
route to `Sbar_Changed`, `Cvar_Set` and `R_ViewChanged`. The non-semantic
uninitialized `vrect.pnext` field is normalized only in the fixture observer.
This closes `SCR_CalcRefdef` only; `_SCR_UpdateScreen`, console/status/menu
overlays and remaining renderer ownership are still open. See the
[`SCR_CalcRefdef` port ledger](ledger/2026-10-13-screen-calc-refdef-assembly-port.md).

`SCR_DrawRam` now has a selectable i486 assembly entry, a retained BENCH486 C
oracle, and an independent exact framebuffer fixture. Seven cases across four
x87 rounding modes and three precision settings passed 84 C/assembly checks;
the complete i486 executable, startup, and provider audits passed with zero
exemptions. The accepted record is routine-level; no paired gameplay-scene run
for this overlay has been recorded. An expanded quiet-NaN draw case did not
reach its fixture summary and remains unresolved, so it is excluded from the
accepted fixture. See the
[`SCR_DrawRam` port ledger](ledger/2026-10-13-screen-drawram-assembly-port.md).

The `SCR_UpdateScreen` overlay decision tree now has a selectable assembly
dispatcher. Its eight-case branch/state fixture passed, and the C and assembly
profiles matched two repeat-stable Demo 1 runs: 1,928 post-warmup frame
checksum comparisons, two exact 320x200 indexed captures, and zero palette
differences. Both selected builds passed strict i486 object, linked-executable,
startup, and CWSDPMI audits with zero violations or exemptions. This converts
dispatch only; see the separate full-routine port below. The status-bar
composition, console, menu, fade and other called drawing routines remain
separately owned. See the
[`SCR_UpdateScreen` overlay-dispatch ledger](ledger/2026-10-13-screen-overlays-assembly-port.md).

The full `SCR_UpdateScreen` orchestration now has a selectable i486 assembly
implementation. Fifteen direct C/assembly cases pass, and the focused profiles
match seven deterministic scenes across fourteen runs: 13,770 exact
post-warmup checksums and fourteen exact indexed framebuffer/palette captures.
The cumulative 110-selector release build passes the complete object, linked
executable, startup, CRT-helper and provider ISA gates with zero violations or
exemptions, then passes the DOSBox-X i486 smoke run. Its exact current-state
owner inventory still finds 69 reachable C renderer/support functions, 118
indirect transfer sites and 37 unresolved direct callees. See the
[`SCR_UpdateScreen` full port ledger](ledger/2026-10-13-screen-update-assembly-port.md).

Status-bar drawing primitives now have a selectable i486 assembly path. The
default profile selects it, while the C copies remain available in BENCH builds
for parity checks. The focused DOSBox-X fixture passes all 18 formatter checks
and 544 coordinate/number scene-state cases. `Sbar_Draw` now also has an
assembly dispatcher selected by the default i486 profile, with the C routine
retained in BENCH builds and the C-reference profile. Its 14-case DOSBox-X
fixture, strict i486 build, and paired Demo 1 capture passed. The assembly
dispatcher now routes to the separately ported inventory composition and frag
strip/sorter. The frag fixture passes six exact C/assembly cases under the
strict i486 build. Face, scoreboard, intermission and finale composition remain
separate work, and overall status-bar and renderer ownership is not complete.
See the
[`Sbar` primitive port ledger](ledger/2026-10-15-sbar-primitives-assembly-port.md)
and [`Sbar_Draw` dispatcher port ledger](ledger/2026-10-16-sbar-draw-assembly-port.md),
plus the [frag strip and sorter ledger](ledger/2026-10-17-sbar-frags-assembly-port.md).

## Remaining machine-code ownership

`tools/renderer-ownership.py` inventories built renderer entries, direct
callees, unresolved runtime calls and indirect transfers. The earlier
all-selectable release snapshot found 92 reachable C dependencies. The
post-math inventory in `out/renderer-ownership-after-math-closure-20261007.json`
found 71, including public C forwarding entries as well as algorithms. The
post-visibility inventory found 69. The accepted public-entry release inventory
in `out/public-bindings-worktree-20261007/out/renderer-ownership-public-bindings-accepted-20261007.json`
finds 49 reachable C renderer dependencies. The accepted sky release inventory
in `out/sky-worktree-20261007/out/renderer-ownership-sky-accepted-20261007.json`
finds 47. The accepted dispatch release inventory in
`out/dispatch-worktree-20261008/out/renderer-ownership-dispatch-release-20261008.json`
finds 36. The accepted drawing-driver release inventory in
`out/driver-worktree-20261008/out/renderer-ownership-driver-release-20261008.json`
finds 29. Re-run it against each new release manifest; historical counts are
not current completion claims.

The accepted view release's earlier three-root inventory finds 21 reachable C
routines. `out/renderer-ownership-expanded-view-20261008.json` broadens ownership
to view assembly, chase support, compiler clones and `_SCR_UpdateScreen`; it
finds 32 reachable C entries. The increased count reflects the wider reviewed
scope, including the character clone and framebuffer drawing operations.

The accepted drawing release's expanded four-root inventory,
`out/renderer-ownership-expanded-drawing-20261008.json`, finds nineteen
reachable C renderer entries. This is a direct-call inventory, not a claim that
all renderer initialization or indirect targets have been converted.

The accepted chase release's expanded inventory in
`out/chase-worktree-20261008/out/renderer-ownership-chase-release-20261008.json`
finds eighteen directly reachable C entries. The camera port removes
`Chase_Update` from the preceding direct-call remainder. Initialization, debug
and indirect paths still require separate ownership review.

The accepted alias-pipeline release inventory in
`out/alias-control-worktree-20261008/out/renderer-ownership-alias-control-release-20261008.json`
finds thirteen directly reachable C renderer entries. Initialization, debug and
indirect paths still require separate ownership review.

The combined world/alias release inventory in
`out/renderer-ownership-world-alias-release-20261008.json` finds eight directly
reachable C renderer entries. All 38 accepted assembly modules preserve their
allocated bytes and normalized relocations in normal, benchmark and profiling
builds. These builds pass the complete instruction, startup and provider gates;
the broader initialization, effects, debug and indirect paths remain open.

`R_SetupFrame` now has a selectable 486 assembly implementation in
`src/r_setupframe_asm.inc`. Its focused C/assembly profile passed the strict
linked executable gate and three exact scene comparisons, including a reduced
viewport and an alternate world. A four-case stress pair now also covers
waterwarp off/on, debug counters, negative ambient and reduced viewport, with
3,888 exact post-warmup checksums and exact indexed/palette captures. The
waterwarp-enabled demo2 path changes 210 checksums while C and assembly remain
identical. Multiplayer cvar enforcement, waterwarp sizing across modes,
extreme dimensions and long-run behavior remain open; the default i486 release
profile uses assembly, with the C profile retained for parity checks. See the
[`R_SetupFrame` port record](ledger/2026-10-09-r-setupframe-assembly-port.md).

The current 2026-10-09 `i486-asm-selectable` inventory in
`out/renderer-ownership-selectable-77-strict-20261009.json` uses all four
rendering roots and finds 61 directly reachable C renderer entries, 40
reachable entries containing 121 indirect call/jump sites, and 26 unresolved
direct callees. This inventory includes the broader screen/update path and does
not claim a complete call graph. The earlier 76-selector snapshot is retained
in `out/renderer-ownership-selectable-strict-20261009.json` as historical
evidence.

The refreshed 109-selector release inventory is
`out/renderer-ownership-screen-update-release-20261013.json`. Its wider source
classification includes `console.c`, `menu.c`, `sbar.c`, `zone.c` and the DOS
video drivers. It reports 640 renderer entries, 389 directly reachable
entries, 69 directly reachable C renderer/support functions, 118 indirect
call/jump sites across 36 functions, and 37 unresolved direct callees. The
scope differs from the earlier 77-selector inventory, so the counts are not a
like-for-like conversion percentage. The scan remains a partial call graph;
indirect targets and initialization/debug paths still require review.

The 2026-10-16 default i486 benchmark build's four-root ownership report
(`out/profile-47c681114048cac6/renderer-ownership-qbench.json`) finds no
directly reachable C-owned `r_` or `d_` rendering procedures other than the
`R_PrintDSpeeds` and `R_TimeGraph` benchmark clock probes. The 78 C entries in
the broader report are primarily screen, menu, console, status-bar, video and
cache support; the report still has 64 unresolved direct callees and is not a
complete call graph. The `r_`/`d_` name filter also misses rendering-time 3D
work named `SV_*`: `ClipMoveToEntityImplementation=asm` selects the
`SV_ClipMoveToEntity` wrapper, `ClipToLinksImplementation=asm` selects the
area-node/entity filter and recursive walk, `HullCheckImplementation=asm`
selects the recursive BSP checker, and `HullForEntityImplementation=asm`
selects `SV_HullForEntity` and `SV_HullForBox` assembly in the i486 profile;
`FindTouchedLeafsImplementation=asm` selects the entity-to-world-leaf BSP
traversal used for visibility/PVS linkage.
The C-reference profile and BENCH parity oracle retain their C implementations.
The entity/world fixture matched all 14 box and brush-hull traces and observed
14 assembly wrapper entries, 40 recursive entries, and 16 intact sentinels;
the six-case direct hull fixture compared the selected hull, six planes, and
offsets. The eight-case area-link fixture compared the full moveclip state,
including entity filters, monster bounds, trace merging, and area-node
recursion, and observed 10 assembly entries with intact guard sentinels.

The 2026-10-16 full i486 assembly-profile BENCH inventory at
`out/profile-35cc1e58e193f012/renderer-ownership-qbench.json` reports 903
renderer entries, 380 directly reachable entries, 61 directly reachable C
renderer/support entries, and 64 unresolved direct callees. This profile
selected `VideoUpdateImplementation=asm`; at that snapshot the separate
VID_Update parity fixture remained open. A newer focused BENCH run at
`out/profile-967ed633342227d7/renderer-ownership-qbench.json` selected
`HunkNamedAllocImplementation=asm-fixture` and `VideoUpdateImplementation=c`
and reports 908 renderer entries, 380 directly reachable entries, 62 directly
reachable C entries, and 64 unresolved direct callees. The directly reachable
count in the first snapshot gives a historical assembly-ownership proxy of
318/380 (83.7%); it is not a complete call-graph or production-only completion
percentage, and unresolved callees are outside that denominator. `Cache_Check`,
`Cache_Alloc`, `Cache_TryAlloc`, `Cache_Free`, `Cache_Move`, `Cache_FreeLow`,
`Cache_FreeHigh`, `Hunk_FreeToLowMark`, `Hunk_FreeToHighMark`, `Hunk_TempAlloc`,
`Hunk_HighMark`, `Hunk_Alloc`, `Z_Malloc`, and the VESA dirty-rectangle copy
loop and page-flip orchestration now use their selected assembly entries; each
has a direct C/ASM fixture. `Cache_Flush` now shares the assembly-backed cache-free selector and
has empty-cache and populated-cache parity cases. `Memory_Init` and `Cache_Init`
now use the zone-heap assembly selector, with direct checks for cache sentinel
setup, flush-command registration, default memory setup, and the `-zone 32`
override. `Z_Print` and `Cache_Print` now have assembly-owned list walks; their
C trace adapters retain formatted console output, and C references remain
available in BENCH and the C-reference profile. `Z_CheckHeap`, `Hunk_Check`,
and cache LRU maintenance also use the zone-heap assembly selector.
`Hunk_Print` now uses an assembly-owned hunk walk with C trace/error adapters;
its C reference remains available for parity. `Cache_Report` now uses an
assembly-owned calculation with a C formatting adapter; its C reference
remains available for parity. `Hunk_Alloc` now has an assembly wrapper that
routes through the selected named allocator; its C wrapper remains available
for parity. `Cache_Compact` is an empty no-op. See the
[`zone heap and cache diagnostics port ledger`](ledger/2026-10-17-zone-heap-assembly-port.md).
On 2026-10-18, `VID_Update` gained a selectable i486 assembly state machine;
the i486 assembly profile selects it by default, while the C-reference profile
and BENCH oracle retain C. Its 20-case DOSBox-X C/ASM fixture passed startup
mode selection, command-line precedence, testing-mode deadlines, float-to-int
truncation, and rectangle dispatch. The independent non-BENCH i486 release
build selected `videoUpdateImplementation=asm` and passed the complete strict
executable gate: 163,797 relocated instructions, 414 source-bound
contributions, 1,466 CODE ranges, 529 startup CODE rows, and 9,207 provider
instructions, with zero exemptions. The same day's `asm-fixture` BENCH
ownership scan at
`out/diagnostic-bench-profile-ed4037e28149b7b0/renderer-ownership-qbench.json`
reports 907 renderer entries, 379 directly reachable entries, 60 directly
reachable C entries, and 70 unresolved direct callees; its fixture selector and
scope differ from the historical inventories above, so it does not yield a
comparable completion percentage. This closes only the per-frame update state
machine, not the wider video or renderer ownership gaps.
On the same date, `PlayerTranslationImplementation=asm` became the i486 default
for `M_BuildTranslationTable` and the palette transformation loop in
`CL_NewTranslation`; C references remain available in the C profile and BENCH.
All 256 shirt/pants pairs passed for both routines in the DOSBox-X fixture, with
exact table/colormap bytes, canaries, and ABI checks. The strict BENCH gate
passed 282,340 relocated instructions and the non-BENCH release gate passed
163,666 relocated instructions, each with zero above-i486/unknown instructions
or exemptions. The fixture does not measure FPS or full-scene parity; see the
[player-color translation port ledger](ledger/2026-10-18-player-translation-assembly-port.md).
On 2026-10-18, `VesaPaletteImplementation=asm` became the i486 default for the
256-entry VESA palette byte-conversion loop; the C oracle remains available in
the C-reference and BENCH profiles. The `asm-fixture` BENCH passed four palette
patterns across all entries, exact byte/order checks, canaries, and callee-saved
register checks. The focused strict gate passed 282,789 relocated instructions,
and the non-BENCH release build passed the complete executable gate for 163,675
relocated instructions, 529 startup CODE rows, and 9,207 provider instructions,
with zero above-i486/unknown instructions or exemptions. This does not port the
BIOS call that programs the hardware palette and does not establish full-scene
parity or FPS; see the [VESA palette conversion port ledger](ledger/2026-10-18-vesa-palette-assembly-port.md).

On 2026-10-18, `VesaDefaultModeImplementation=asm` became the i486 default for
the linked-mode scan that chooses a 320x200 VESA mode. The assembly prefers the
first linear candidate and otherwise retains the first banked candidate; the C
oracle remains available in the C-reference and BENCH profiles. Six synthetic
mode lists passed exact selection, read-only guard, and ABI checks. The focused
BENCH gate passed 282,535 relocated instructions, and the non-BENCH release
build passed the complete executable gate for 163,627 relocated instructions,
529 startup CODE rows, and 9,207 provider instructions, with zero above-i486/
unknown instructions or exemptions. VESA mode-info decoding and BIOS mode
operations remain C-owned; this fixture establishes neither FPS nor full-scene
parity. See the [VESA default-mode selection port ledger](ledger/2026-10-18-vesa-default-mode-assembly-port.md).

The latest fixture ownership inventory at
`out/profile-c3de2a41110c2c69/renderer-ownership-qbench.json` reports 909
renderer entries, 382 directly reachable entries, 60 directly reachable C
entries, and 64 unresolved direct callees. Its 322/382 (84.3%) assembly
function-count proxy is specific to this BENCH inventory, includes fixture
helpers, and is not a complete-call-graph or production-weighted completion
percentage.

The VGA linear and planar pixel-copy routines already use assembly. The VESA
palette conversion loop now uses assembly; VESA discovery, wait probing, BIOS
palette programming, and mode changes remain C-owned. Page-flip assembly calls
C adapters for hardware-specific operations. See the
[`Cache_Check` port ledger](ledger/2026-10-17-cache-check-assembly-port.md),
[`Cache_Alloc` port ledger](ledger/2026-10-17-cache-alloc-assembly-port.md),
[`Cache_Move` port ledger](ledger/2026-10-17-cache-move-assembly-port.md),
[`Cache_TryAlloc` port ledger](ledger/2026-10-17-cache-allocation-search-assembly-port.md),
[`Cache_Free` port ledger](ledger/2026-10-17-cache-free-assembly-port.md),
[`Cache_FreeLow` port ledger](ledger/2026-10-17-cache-free-low-assembly-port.md),
[`Cache_FreeHigh` port ledger](ledger/2026-10-17-cache-free-high-assembly-port.md),
[`Hunk mark-release` port ledger](ledger/2026-10-17-hunk-mark-release-assembly-port.md),
[`Hunk temp-allocation` port ledger](ledger/2026-10-17-hunk-temp-alloc-assembly-port.md),
[`zone heap and cache diagnostics port ledger`](ledger/2026-10-17-zone-heap-assembly-port.md),
[`VESA copy` port ledger](ledger/2026-10-17-vesa-copy-rects-assembly-port.md),
and [`VESA swap` port ledger](ledger/2026-10-17-vesa-swap-buffers-assembly-port.md).

The focused `Cache_Move` strict BENCH gate passed with zero above-i486
instructions, unknown encodings, exemptions, or skipped bytes. It audited
243,861 project instructions across 154 objects and 282,158 linked
instructions across 389 objects; executable proof verified all 282,158
opcodes across 235 runtime inputs and 415 source-bound contributions. The
final mapping covered 2,199 CODE ranges and 29 DATA ranges. Startup proof
covered 1,660 loaded bytes and 529 CODE rows; the provider proof covered
9,207 instructions with zero exemptions. The prior full release audit
reported 129,467 project instructions and 167,764 linked instructions across
386 objects, then verified 394 source-bound contributions, 1,451 CODE ranges,
25 DATA ranges, and the same startup/provider totals. The
selected release omits the C bodies for `SV_ClipToLinks`,
`SV_ClipMoveToEntity`, `SV_RecursiveHullCheck`, `SV_HullForEntity`, and
`SV_HullForBox`. The current assembly profile is
`out/profile-b0b63996f725e26c`. These focused checks do not measure FPS or
establish full gameplay, visual, or complete renderer-ownership acceptance.
Continue 3D work through other shared call paths and unresolved indirect
targets, keeping C available for parity. See the [area-link clipper
ledger](ledger/2026-10-16-clip-to-links-assembly-port.md).

The touched-leaf traversal has its own ten-case C/ASM fixture, including
boundary-equality cases for axial and non-axial planes; it matched the full
edict and guard state and observed 31 assembly entries. Its strict BENCH gate
audited 243,476 project instructions and 281,773 linked instructions across
386 objects, then verified 408 source-bound contributions, 2,173 CODE ranges,
25 DATA ranges, 1,660 startup bytes, 529 startup CODE rows, and 9,207 provider
instructions. The strict Release gate audited 129,441 project instructions
and 167,738 linked instructions across 386 objects, then verified 394
source-bound contributions, 1,451 CODE ranges, 25 DATA ranges, and the same
startup/provider totals. Both gates reported zero above-i486 instructions,
unknown encodings, exemptions, or misclassified data.

The DOSBox-X early page fault was reproduced with BENCH builds that compiled
the WorldControl parity oracle, hooks and fixture data into the executable.
The three production assembly groups pass individually and in all pairs; all
three together pass the complete 985-frame Demo 2 when the optional fixture is
omitted. `WorldControlImplementation=asm` selects the production rotation,
efrag and edge-frame procedures; `asm-fixture` explicitly opts into the BENCH
oracle and hooks. The default all-assembly run passes Demo 2 with final
checksum `1887495667`, an exact 320x200 indexed framebuffer and palette, and a
measured 12.17 FPS in the one-run timedemo. Its strict executable gate decoded
278,233 relocated instructions and verified 386 exact object contributions,
409 source-bound contributions, 2,168 CODE ranges, 26 DATA ranges, 529 startup
CODE rows and 9,207 provider instructions, with zero above-i486 instructions,
unknown encodings or exemptions. The ownership inventory finds no direct
reachable `r_*.c` or `d_*.c` frame-path procedures outside BENCH print/time
probes; C support procedures remain, and unresolved callees and indirect
targets prevent a complete ownership claim. See the
[touched-leaf traversal ledger](ledger/2026-10-16-find-touched-leafs-assembly-port.md).

The inventory stops traversal at explicitly named `Sys_Error` and `Host_Error`
abort boundaries. Those functions and the linked runtime are still ISA-audited.
Indirect transfers require separate target review, so this tool does not claim
to prove a complete call graph.

| Area | Remaining behavior or ownership to verify |
|---|---|
| Camera collision / BSP hull trace | `ChaseImplementation=asm` uses `SV_RecursiveHullCheck_asm486`; `HullCheckImplementation=asm` selects the recursive checker; `ClipMoveToEntityImplementation=asm` selects the `SV_ClipMoveToEntity` wrapper; `ClipToLinksImplementation=asm` selects `SV_ClipToLinks` area-link filtering and recursion; `HullForEntityImplementation=asm` selects assembly for `SV_HullForEntity` and `SV_HullForBox`. The 14-case entity/world fixture matched exact traces with 14 wrapper entries, 40 recursive entries, and 16 intact sentinels; the six-case direct hull fixture compared hull selection, all six planes, offsets, and sentinels; the eight-case area-link fixture matched full moveclip state and recorded 10 assembly entries with guard sentinels intact. Strict BENCH and release i486 gates passed with zero above-i486 instructions, unknown encodings, exemptions, or misclassified data. The selected release omits all five C bodies. Broader gameplay scenes remain open. See the [area-link clipper ledger](ledger/2026-10-16-clip-to-links-assembly-port.md), [entity trace-wrapper ledger](ledger/2026-10-16-clip-move-to-entity-assembly-port.md), [hull-selection ledger](ledger/2026-10-16-entity-hull-selection-assembly-port.md), and [recursive hull-check ledger](ledger/2026-10-16-chase-hull-check-assembly-port.md). |
| Entity visibility / PVS leaves | `FindTouchedLeafsImplementation=asm` selects the BSP leaf traversal and passed ten exact direct C/ASM cases plus strict BENCH and Release i486 gates. The combined all-assembly profile now passes the 985-frame Demo 2 after excluding the opt-in WorldControl fixture; broader scene and visibility stress coverage remain open. See the [touched-leaf traversal ledger](ledger/2026-10-16-find-touched-leafs-assembly-port.md). |
| BSP/world | The i486 defaults now select assembly for `R_ZDrawSubmodelPolys`, `R_RenderPoly`, and `R_RecursiveWorldNodeClip`, with C retained as the parity reference. The world-node clip helper uses an unrolled x87 schedule and passed five exact C/ASM cases plus the full strict i486 ISA gate; its displayed medians match at DOSBox's 1 μs timing resolution. A full scene capture after this follow-up remains open. The direct cull/projection fixtures pass, and an opt-in Demo 1 `-drawpolys` pair matched 964 post-warmup checksums and its indexed capture. `D_DrawPoly` remains a no-op in the DOS span driver, so polygon rasterization is not covered. The standard span path keeps `r_drawpolys` false; the Demo 2 diagnostic still has an unstable C/C baseline. Remaining optional polygon/debug passes and indirect-target closure remain open. See the [Z-submodel polygon ledger](ledger/2026-10-09-zsubmodel-polygons-assembly-port.md) and [RenderPoly parity ledger](ledger/2026-10-10-render-poly-assembly-parity.md). |
| Edge processing | `R_ScanEdges` and `R_EdgeDrawing` have focused C/assembly pairs, each with 6,058 exact post-warmup checksums and six exact indexed/palette captures; the strict i486 audit for `R_EdgeDrawing` passed. `R_RecursiveClipBPoly` now has a focused C/assembly profile pair with the same exact frame coverage and a strict i486 audit. Frame initialization, other clipping boundaries, optional polygon/debug paths, and remaining C list/span forwarding entries remain open. See the [edge-drawing port record](ledger/2026-10-05-edge-drawing-assembly-port.md), [scan-edges port record](ledger/2026-10-05-scan-edges-assembly-port.md), and [brush-model polygon-clipping port record](ledger/2026-10-05-bmodel-polygon-clip-assembly-port.md). |
| Alias models | Combined complete-profile verification, indirect targets and removal of inactive C oracle code from release |
| Sky and particles | Combined complete-profile verification, broader particle-effect stress/sequence scenarios, and sky scenes. `R_ParseParticleEffect` now has exact parser-state parity across complete/truncated packets and x87 rounding modes, plus a paired `svc_particle` event-to-frame scene with exact framebuffer and checksum parity. The focused `D_DrawParticle` event-scene parity and parser scene do not close the wider stress/sequence and sky gates. |
| Renderer mathematics | Verify selected release ownership after accepted math-support integration and close any newly discovered helpers |
| Visibility support | Verify complete selected release ownership after accepted integration |
| View and drawing support | `V_ParseDamage`, `V_BonusFlash_f`, `V_cshift_f` and `V_Init` have accepted focused assembly slices; combined-profile verification and initialization/indirect dependencies remain |
| Screen and overlays | `SCR_UpdateScreen` orchestration, overlay dispatch, `Con_DrawInput`, `Con_DrawConsole`, `Con_DrawNotify`, `SCR_DrawNotifyString`, `SCR_DrawRam` and several other helpers have selectable i486 assembly paths with direct fixtures. `Con_DrawConsole` passes five exact C/assembly framebuffer and state cases; `Con_DrawNotify` passes eight cases across four x87 modes through direct C, assembly and selected public entries; `Con_DrawInput` passes 21 cases across four x87 modes. Status-bar coordinate, text and number primitives now select assembly; its higher-level composition remains C-owned. The full update routine passed seven exact paired scenes and a strict cumulative release smoke. Console printing, logging, menu, video/cache and screen marker/loading callees remain C-owned; indirect targets, full screen stress and long-run checks remain open. See the [console-notification](ledger/2026-10-17-con-drawnotify-assembly-port.md), [console-draw](ledger/2026-10-17-con-drawconsole-assembly-port.md), [notify-string](ledger/2026-10-10-scr-drawnotifystring-assembly-port.md), [RAM-indicator](ledger/2026-10-13-screen-drawram-assembly-port.md), [overlay-dispatch](ledger/2026-10-13-screen-overlays-assembly-port.md), [status-bar primitive](ledger/2026-10-15-sbar-primitives-assembly-port.md), and [full screen-update](ledger/2026-10-13-screen-update-assembly-port.md) ledgers. |
| Runtime providers | The maintained CWSDPMI provider, final startup and automatic strict gate pass; alternate provider and environment implementations require their own proof |

These groups include simple C wrappers as well as algorithms. Both must be
accounted for before declaring the renderer pure assembly. Profiling/test-only
C oracles must be distinguished from executable release renderer dependencies.

## Validation still required

The six committed demo scenarios cover VGA/VESA, lighting/viewport variants,
entities and alternate world workloads. They do not by themselves establish
dedicated coverage of every clipping boundary, extreme coordinate/camera case,
palette transition, long uninterrupted full-frame sequence or gameplay action.
Add explicit scenarios and observable checks for those requirements.

The paired acceptance gate compares indexed pixels, all palette bytes and
post-warmup checksum streams exactly. Historical golden-image RGB tolerances
cannot substitute for that gate. Every unexplained difference blocks acceptance.

The isolated stricter classifier reports 131,352 instruction sites across
110 frozen project objects without instruction exemptions or unknown encodings.
Compiler-emitted data is identified by reassembly with zero-byte boundary
labels, requiring identical allocated bytes and relocations for all 82 C
objects. Evidence is under
`out/isa-classifier-worktree-20261007/out/native-release-snapshot-20261007-4`
and `isa-release-snapshot-with-proved-data-20261008-8.json`. The first version
was superseded after stronger tests found DJGPP `/APP` markers and interior
instruction labels requiring stricter handling. The regenerated proof validates
all 82 C objects, source function entries, direct targets and fallthroughs.
Continuous raw-byte decoding passes 505 permitted and rejects 544 forbidden
encoding fixtures; 43 adversarial boundary-proof checks also pass. All 82 proofs
were regenerated under the current policy. This frozen snapshot precedes
visibility, public-entry and sky integration. The experiment does not replace
the normal build gate.

All 235 linked runtime objects now have exact primary-source boundary proofs.
Original GCC 4.7.4 and primary assembly reproduce 220 objects; the original alias
generator reproduces ten; primary GCC 12.2 sources reproduce the remaining five
libgcc objects. Allocated bytes, section properties and normalized relocations
must match. The portable source/listing bundle also re-proves all 235 installed
objects and rejects unknown or changed inputs. See the
[runtime audit](ledger/2026-10-08-runtime-source-audit.md).

The complete frozen 345-input audit and independent decoding of its actual
relocated executable both pass 169,617 instruction sites, with zero unknowns,
post-486 encodings, instruction exemptions or relocation-field skips. Fourteen
adversarial final-mapping checks and nine genuine linked-binary checks also pass.
The current automatic workflow is integrated into the main checkout. Its
accepted 352-input release and actual relocated executable both pass 169,312
instructions, followed by the complete startup and provider proofs. The real
cached runner and i486 smoke execution pass. See the
[automatic gate](ledger/2026-10-08-automatic-executable-isa-gate.md).

The MZ loader's 1,536 loaded bytes reproduce exactly from the original DJGPP
source. Its source-typed code ranges, including the deliberate overlapping
entry, decode to 489 instructions, all i386-compatible with zero unknowns or
instruction exemptions. The hash-bound proof passes 21 adversarial checks and
has been verified against the accepted sky benchmark. The two executable
16-bit helpers embedded in CRT `.data` also reproduce exactly from primary
sources: 108 and 16 bytes, covering 40 i386-compatible instructions with no
unknowns or exemptions. Their binding verifier passes 22 adversarial checks.
Final-binary mapping now binds all 1,660 loaded startup bytes and 529 instruction
rows to the exact executable and map. Nine adversarial final-startup checks pass.
These startup checks are now automatic. The maintained CWSDPMI provider adds
9,207 strictly decoded instructions and one runtime branch variant with zero
exemptions. Its paired emulator runs pass 6,058 exact checksums and six complete
indexed/palette captures. See the
[provider acceptance](ledger/2026-10-08-cwsdpmi-486-provider.md).

The 77-selector combined profile now passes all six committed scenes and the
complete i486 executable gate. Completion still requires closing direct C
dependencies and indirect targets, reviewing initialization/debug/support
paths, further ISA-classifier coverage, long full-renderer stability and
corruption checks, and broader gameplay scenarios. Human visual/gameplay
acceptance remains pending. A timing improvement is not a completion criterion,
and no current report claims the overall goal complete.

The instrumented dispatch gameplay check exposed a negative legacy turbulent
time scalar. The profiling-only subtraction is now corrected: the matched
rerun passes 980 exact checksums, the indexed capture and palette, and reports
positive elapsed time with no stack errors. All 34 normal assembly objects
remain byte/relocation-identical. See the
[timer correction](ledger/2026-10-08-turbulent-profile-timer.md).

The combined world/alias selection now passes the complete 38-module guest
correctness suite, checksum `3755475462`. Four rebuilt variants also prove all
480 allocated project objects equivalent after copied-oracle whitespace cleanup;
only proved build-clock literal data differs. The refreshed default release
guard verifies 120 objects and its executable. See the
[accepted checkpoint](ledger/2026-10-08-accepted-renderer-checkpoint.md).

## Opt-in frustum candidate

The frustum transform and AABB-index setup pair now has a complete strict
acceptance run. The assembly profile passed the linked and independently
relocated executable audit, startup checks and maintained CWSDPMI provider
proof. Its final executable contained 202,135 relocated instructions, with
zero post-i486 instructions, unknowns or exemptions. The C reference and
assembly candidate passed `demo1-vesa-full`, `demo2-entity-workload` and
`demo3-world-workload`: 3,029 post-warmup checksums and all three 320x200
indexed captures/palettes matched exactly. The C selector remains the default;
this isolated candidate does not close remaining renderer ownership or broader
stability requirements. See the
[frustum candidate and extension](ledger/2026-10-09-frustum-transform-assembly-port.md).

## Expanded 83-selector candidate

The opt-in 83-selector profile passes the complete i486 executable gate and
the `demo1-vesa-full` paired run: 964 post-warmup checksums and the frame-169
320x200 indexed capture/palette match exactly. Its ownership inventory reports
25 directly reachable renderer C functions, 148 indirect transfer sites and
33 unresolved direct callees; this is not a complete call graph. The result
does not establish broad scenario or full-renderer parity. See the
[83-selector VESA checkpoint](ledger/2026-10-09-selectable-83-vesa-checkpoint.md).

The 84-selector profile adds the accepted alias-control pipeline and passes
the complete executable gate plus `demo2-entity-workload`: all 980 post-warmup
checksums and the frame-169 indexed capture/palette match exactly. Its owner
scan no longer reports the five alias-control C functions; direct C entries
fall from 25 to 20 and indirect transfer sites from 148 to 54. The graph is
still incomplete, and the remaining C paths and broader renderer scenarios
remain open. See the
[84-selector alias-control checkpoint](ledger/2026-10-09-selectable-84-alias-control-checkpoint.md).

The `R_CheckVariables` frame-control slice is now implemented in
`src/r_checkvariables_asm.inc` and replaces `r_misc.c:R_CheckVariables` when
`ASM486_VIEW_CONTROL` is selected. Its C-vs-assembly fixture passes 180 cases
across twelve x87 control words; the combined all-84-selector aggressive BENCH
run passes the 18,176-case ViewControl fixture. The candidate executable and
runtime ISA gate passes 245,178 relocated renderer/runtime instructions, 353
source-bound executable contributions, 1,844 ranges, 529 startup CODE rows and
9,207 provider instructions, with zero above-i486 instructions and zero
exemptions. The paired C-reference versus 84-selector assembly run now passes
three DOSBox-X scenes with exact frame-checksum streams (3,029 compared frames)
and exact 320x200 indexed framebuffer and palette captures. The assembly path
remains selectable; this checkpoint completes only the `R_CheckVariables`
slice, not the renderer migration.
