# Renderer completion gaps

The objective is the complete software renderer and its rendering-time
dependencies, with explicitly owned i486 instructions and equivalent output.
Passing the ISA audit on a C function does not convert that function to assembly.
Selecting every existing assembly switch does not establish complete ownership.

## Accepted incremental work

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
91-selector candidate profile exists, but it has not had a new full-profile
ownership inventory or complete-profile acceptance run; the 61-C-entry figure
above remains the preceding 77-selector inventory, not a current count.

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
viewport and an alternate world. Waterwarp sizing, debug-stat and multiplayer
branches, extreme dimensions and long-run behavior remain open; the default
release selector is still C. See the
[`R_SetupFrame` port record](ledger/2026-10-09-r-setupframe-assembly-port.md).

The current 2026-10-09 `i486-asm-selectable` inventory in
`out/renderer-ownership-selectable-77-strict-20261009.json` uses all four
rendering roots and finds 61 directly reachable C renderer entries, 40
reachable entries containing 121 indirect call/jump sites, and 26 unresolved
direct callees. This inventory includes the broader screen/update path and does
not claim a complete call graph. The earlier 76-selector snapshot is retained
in `out/renderer-ownership-selectable-strict-20261009.json` as historical
evidence.

The inventory stops traversal at explicitly named `Sys_Error` and `Host_Error`
abort boundaries. Those functions and the linked runtime are still ISA-audited.
Indirect transfers require separate target review, so this tool does not claim
to prove a complete call graph.

| Area | Remaining behavior or ownership to verify |
|---|---|
| BSP/world | Other optional polygon/debug passes, remaining frustum initialization and explicit indirect-target closure. `R_ZDrawSubmodelPolys` has an assembly selector and direct cull/call-order fixture, which does not test the downstream `R_RenderPoly` rasterizer. |
| Edge processing | Frame initialization, culled polygons and remaining C list/span forwarding entries |
| Alias models | Combined complete-profile verification, indirect targets and removal of inactive C oracle code from release |
| Sky and particles | Combined complete-profile verification, broader particle-effect stress/sequence scenarios, and sky scenes. The focused `D_DrawParticle` event-scene parity is accepted; it does not close these wider gates. |
| Renderer mathematics | Verify selected release ownership after accepted math-support integration and close any newly discovered helpers |
| Visibility support | Verify complete selected release ownership after accepted integration |
| View and drawing support | `V_ParseDamage`, `V_BonusFlash_f`, `V_cshift_f` and `V_Init` have accepted focused assembly slices; combined-profile verification and initialization/indirect dependencies remain |
| Screen and overlays | `Con_DrawInput` and `SCR_DrawNotifyString` now have selectable i486 assembly entries with exact direct C/ASM/public state and indexed-framebuffer fixtures; both selected executables and their linked support/runtime objects, startup code and CWSDPMI provider passed strict i486 audits with zero violations or exemptions. `Con_DrawInput` still calls the separately owned `Draw_Character` backend. Combined-profile/full-scene parity, other console drawing paths, status-bar/menu overlays, and `screen.c` including `_SCR_UpdateScreen` remain open for ownership review. See the [notify-string port record](ledger/2026-10-10-scr-drawnotifystring-assembly-port.md). |
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
