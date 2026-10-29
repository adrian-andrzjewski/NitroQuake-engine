# 486 optimization plan of record

The plan this renderer follows is `1790698732780-proud-rocket.md` in the
`.mimocode/plans/` directory of the **wrapper repository one level above this
subproject** — that is, `../../.mimocode/plans/1790698732780-proud-rocket.md`
from this file, or `../.mimocode/plans/` from the renderer root. It is not
inside this repository, so a clone of `quake/` alone will not contain it. This
page is the renderer-side index to it, so that anyone arriving at `quake/` can
find it and the rules it imposes even when the wrapper is not present.

**The authoritative document is the plan file, not this page.** This is a
pointer plus the two decisions that are easy to get backwards. Where the two
disagree, the plan file wins.

## Current performance acceptance (2026-10-21)

Promote any positive pooled mean FPS from at least three matched, uninstrumented
runs per variant, regardless of the gain size or whether it is smaller than the
observed run-to-run spread. Use the same pinned DOSBox-X profile, executable
settings, workload, frame count, and framebuffer checksum. Record all samples
and their spread with the result. Keep the strict i486 ISA audit and exact output
parity as required gates. A non-positive matched mean, parity failure, or ISA
violation still rejects a candidate.

The 0.05% threshold and its 1,022.8-cycles/frame equivalent below are historical
policy. They no longer exclude small candidates. Static cycle pricing is only a
way to rank experiments; price-only closures can be reopened for a timed A/B.
Entries that were rejected for measured slowdown, incorrect output, an
inapplicable workload, or an obsolete implementation remain closed for those
reasons.

### Edge-scan leading-edge bmodel dispatch (2026-10-28)

In `R_GenerateSpans`, the leading-edge bmodel test now compares
`st_insubmodel(%edi)` directly with zero, replacing the separate load to `%eax`
and register `test`. The strict candidate averaged **16.261895667 FPS** against
the current strict control's **16.241887 FPS** (**+0.020008667 FPS,
+0.1232%**). All runs retained 969 frames and checksum `1047377823`; the full
executable i486 audit passed with zero above-i486, unknown, or exempt
instructions. See the [leading-edge compare ledger](ledger/2026-10-28-edge-leading-insubmodel-compare-promoted.md).

### Edge-scan leading-edge spanstate check (2026-10-28)

The leading-edge path no longer stages `st_spanstate` in `%edx`. After the
bmodel dispatch, each path compares the field directly; the rare inverted-span
exit increments it in memory. The strict candidate averaged **16.281853333
FPS** against the current strict control's **16.261895667 FPS**
(**+0.019957666 FPS, +0.1227%**). All runs retained 969 frames and checksum
`1047377823`; the complete executable i486 gate passed. See the
[spanstate compare ledger](ledger/2026-10-28-edge-leading-spanstate-direct-compare-promoted.md).

### Edge-scan trailing-edge bmodel dispatch (2026-10-29)

`TrailingEdge` now compares `st_insubmodel(%esi)` directly with zero. The
independent patched `surfaces[1].st_next` load remains between the compare and
branch and preserves the flags, removing the register load and `testl` while
keeping `LPatch0` immediately after its patched load. The strict candidate
averaged **16.301349 FPS** against a fresh strict control's **16.281853 FPS**
(**+0.019496 FPS, +0.1197%**). All runs retained 969 frames and checksum
`1047377823`; the complete executable i486 gate passed. See the
[trailing-edge compare ledger](ledger/2026-10-29-edge-trailing-insubmodel-direct-compare-promoted.md).

Moving the Z-span U-coordinate load before the x87 origin add measured
**15.601291333 FPS** against the control's **15.601303 FPS**
(**−0.000011667 FPS, −0.00007478%**). All runs retained 969 frames and checksum
`1047377823`; the complete strict i486 audit passed. The negative pooled mean
rejects the move, and the load has been restored after the add. See the
[Z-span U-load ledger](ledger/2026-10-22-zspan-u-load-before-origin-add-rejected.md).

Delaying the Span16 endpoint `snext` and `tnext` reloads past the first texel
fetch and setup loads measured **15.601293333 FPS** against the control's
**15.601303 FPS** (**−0.000009667 FPS, −0.00006196%**). All runs retained 969
frames and checksum `1047377823`; the complete strict i486 audit passed. The
negative pooled mean rejects the schedule, and both reloads have been restored
after their `FISTP` stores. See the
[Span16 reload-interleave ledger](ledger/2026-10-22-span16-fistp-reload-interleave-rejected.md).

Moving the Span16 count decrement and `counttemp` save between the endpoint
`fmul` and `fxch` measured **15.601281333 FPS** against the control's
**15.601303 FPS** (**−0.000021667 FPS, −0.00013888%**). All runs retained 969
frames and checksum `1047377823`; the complete strict i486 audit passed. The
negative pooled mean rejects the schedule, which has been restored. See the
[Span16 count-update overlap ledger](ledger/2026-10-22-span16-counttemp-x87-overlap-rejected.md).

Moving the Span16 `sadjust` load between the endpoint `fmul` and `fxch` measured
**15.601299 FPS** against the same control (**−0.000004 FPS, −0.00002564%**).
All runs retained 969 frames and checksum `1047377823`; the complete strict
i486 audit passed. The negative pooled mean rejects the move, which has been
restored. See the
[Span16 S-adjust overlap ledger](ledger/2026-10-22-span16-sadjust-x87-overlap-rejected.md).

Moving the first Span16 texel load into that x87 window measured **15.601298
FPS** against the same control (**−0.000005 FPS, −0.00003205%**). All runs
retained 969 frames and checksum `1047377823`; the complete strict i486 audit
passed. The negative pooled mean rejects the move, which has been restored. See
the [first-texel overlap ledger](ledger/2026-10-22-span16-first-texel-x87-overlap-rejected.md).

In the A half of the default `D_DrawSpans16` word-store path, the first
high-byte fetch now follows the S-fraction add. The intervening byte load
preserves carry for the following `ADC`, so the add overlaps the source fetch.
The strict candidate averaged **15.564258 FPS** against the active strict
control's **15.564256667 FPS** (**+0.000001333 FPS, +0.00000857%**). Its
parity screen was **−0.000002333 FPS** against control; the strict positive
mean qualifies under the any-positive rule. All strict runs retained 969
frames and checksum `1047377823`, and the complete strict i486 gate passed. See
the [Span16 S-add ledger](ledger/2026-10-21-span16-s-add-before-first-high-fetch-promoted.md).

In the default `D_DrawSpans16` word-store path, the next T-step addition now
runs immediately before the current word store; the store and source-byte
load preserve its carry for the later `SBB`. The strict candidate averaged
**15.564260333 FPS** against the active strict control's **15.564258 FPS**
(**+0.000002333 FPS, +0.00001499%**). Its parity screen was **−0.000004667
FPS** against control, while the strict mean is positive. Every strict run
retained 969 frames and checksum `1047377823`, and the complete strict i486
gate passed. See the
[Span16 T-step/store ledger](ledger/2026-10-21-span16-tstep-before-word-store-promoted.md).

Extending that T-step/store overlap to five more interior stores averaged
**15.564255333 FPS** on the parity screen against **15.564251667 FPS** for
control (**+0.000003667 FPS**), but the audited strict candidate averaged
**15.564256333 FPS** against **15.564260333 FPS** (**−0.000004 FPS,
−0.00002570%**). All runs retained 969 frames and checksum `1047377823`; the
complete strict i486 gate passed. The negative strict mean rejects the five
additional moves, leaving the first-store overlap active. See the
[Span16 T-step overlap extension ledger](ledger/2026-10-21-span16-tstep-overlap-extension-rejected.md).

Moving the next T-step addition ahead of A-half stores 3 and 5 averaged
**15.564256667 FPS** on the parity screen against **15.564251667 FPS** for
control (**+0.000005 FPS**), but the strict candidate averaged
**15.564259333 FPS** against **15.564260333 FPS** (**−0.000001 FPS,
−0.00000643%**). All runs retained exact 969-frame checksum parity, and the
complete strict i486 gate passed. The negative strict mean rejects these two
moves; the first-store overlap remains active. See the
[Span16 A-half overlap ledger](ledger/2026-10-21-span16-tstep-a-half-overlap-rejected.md).

Moving the next T-step addition ahead of B-half stores 9, 11, and 13 averaged
**15.564256333 FPS** on the parity screen against **15.564251667 FPS** for
control (**+0.000004667 FPS**), but the strict candidate averaged
**15.564257 FPS** against **15.564260333 FPS** (**−0.000003333 FPS,
−0.00002142%**). All runs retained exact 969-frame checksum parity, and the
complete strict i486 gate passed. The negative strict mean rejects these three
moves; the first-store overlap remains active. See the
[Span16 B-half overlap ledger](ledger/2026-10-22-span16-tstep-b-half-overlap-rejected.md).

Moving only the next T-step addition before B-half store 11 averaged
**15.564253667 FPS** against the strict control's **15.564258 FPS**
(**−0.000004333 FPS, −0.00002784%**). All runs retained exact 969-frame
checksum parity, and the complete linked i486 audit passed. The negative strict
mean rejects the isolated store 11 move. See the
[Span16 store 11 ledger](ledger/2026-10-22-span16-tstep-store11-overlap-rejected.md).

Moving only the next T-step addition before A-half store 3 averaged
**15.564251 FPS** on the parity screen against **15.564251667 FPS** for control
(**−0.000000667 FPS**). Its strict mean was **15.564254667 FPS** against
**15.564260333 FPS** (**−0.000005667 FPS, −0.00003641%**). All runs retained
exact 969-frame checksum parity, and the complete strict i486 gate passed. The
negative strict mean rejects the store 3 move; the first-store overlap remains
active. See the
[Span16 store 3 ledger](ledger/2026-10-22-span16-tstep-store3-overlap-rejected.md).

Moving only the next T-step addition before A-half store 5 averaged
**15.564255 FPS** on the parity screen against **15.564251667 FPS** for control
(**+0.000003333 FPS**). Its strict mean was **15.564259 FPS** against
**15.564260333 FPS** (**−0.000001333 FPS, −0.00000857%**). All runs retained
exact 969-frame checksum parity, and the complete strict i486 gate passed. The
negative strict mean rejects the store 5 move; the first-store overlap remains
active. See the
[Span16 store 5 ledger](ledger/2026-10-22-span16-tstep-store5-overlap-rejected.md).

Moving only the next T-step addition before B-half store 9 averaged
**15.564258667 FPS** on the parity screen against **15.564251667 FPS** for
control (**+0.000007 FPS**). Its strict mean was **15.564255333 FPS** against
**15.564260333 FPS** (**−0.000005 FPS, −0.00003212%**). All runs retained exact
969-frame checksum parity, and the complete strict i486 gate passed. The
negative strict mean rejects the store 9 move; the first-store overlap remains
active. See the
[Span16 store 9 ledger](ledger/2026-10-22-span16-tstep-store9-overlap-rejected.md).

In the both-edge path of `R_GenerateSpans`, the leading-surface pointer is now
formed before `TrailingEdge` and carried in `%edi` across the helper. This
replaces the post-call `surfaces` reload with a direct jump to the shared
leading-edge body. The strict candidate averaged **15.564256667 FPS** against
the active strict control's **15.564254 FPS** (**+0.000002667 FPS,
+0.0000171354%**); the parity screen was also positive by **+0.000001667
FPS**. The gain is smaller than the run spread, but qualifies under the
any-positive rule. All runs retained 969 frames and checksum `1047377823`;
the complete strict i486 gate passed. See the
[edge leading-pointer ledger](ledger/2026-10-21-edge-scan-leading-pointer-retained-promoted.md).

`R_GenerateSpans` in `src/r_edgea.s` now reads the packed edge surface pair as
two unsigned 16-bit indices, removing the register copy and masks from each
edge iteration. The strict candidate averaged **15.564254 FPS** against the
active strict control's **15.538384 FPS** (**+0.025870 FPS, +0.16649093%**);
the parity screen averaged **15.564257 FPS** and was also positive. Every run
kept 969 frames and checksum `1047377823`. The complete strict i486 gate passed
with zero above-i486, unknown, or exempt instructions. See the
[edge surface-index decode ledger](ledger/2026-10-21-edge-scan-surface-index-decode-promoted.md).

Moving the first Z-span accumulator add/subtract ahead of its sign branch
averaged **15.601289 FPS** against the strict control's **15.601303 FPS**
(**−0.000014 FPS, −0.00008974%**). The trailing control was **15.601297 FPS**;
the candidate was still **−0.000008 FPS** below it. All seven runs retained
969 frames and checksum `1047377823`, and the complete strict i486 audit passed.
The negative mean rejects this schedule, leaving the original branch order
active. See the
[Z-span step-before-branch ledger](ledger/2026-10-22-zspan-step-before-sign-branch-rejected.md).

Moving the Z-span pair sign test ahead of its accumulator copy averaged
**15.537287333 FPS** against **15.537292000 FPS** for strict control
(**−0.000004667 FPS, −0.00003004%**). All six runs retained 969 frames and
checksum `1047377823`; the complete strict i486 audit passed. The negative
pooled mean rejects this order, leaving the original `MOV` then `TEST` schedule
active. See the
[Z-span sign-check screen ledger](ledger/2026-10-21-zspan-sign-check-before-copy-screen-rejected.md).

Moving the second Z-accumulator add/subtract between `SHLD` and `ROR` averaged
**15.537290333 FPS** on the three-run parity screen against a fresh control at
**15.537285333 FPS** (**+0.000005000 FPS**). The strict candidate averaged
**15.537294333 FPS**, below the latest strict control mean of **15.537297000
FPS** (**−0.000002667 FPS**). Exact parity and the complete i486 audit passed,
but the negative strict mean rejects the schedule. See the
[Z-span SHLD/ROR screen ledger](ledger/2026-10-21-zspan-step-between-shld-ror-screen-rejected.md).

The default `ASM486_SPAN16_WORD_STORES` path keeps each packed word store after
its final source-address `adcl` in the A and B halves. Its strict three-run mean
was **15.537289000 FPS**, above the pooled six-run strict control mean of
**15.518328500 FPS** (**+0.018960500 FPS, +0.12218%**). The control pool retains
one 15.423568 FPS outlier; against the earlier clean three-run block alone, the
candidate mean was **−0.000008 FPS**. A separate parity screen was positive by
**+0.000001000 FPS**. All runs retained exact 969-frame checksum parity and the
complete linked i486 audit passed. The positive pooled mean qualifies under the
user's any-positive rule; the timing remains noisy. See the
[Span16 after-ADC store ledger](ledger/2026-10-21-span16-store-after-adc-promoted.md).

Moving the default word-store loop's S-fraction add before the following
source-byte load averaged **15.537289333 FPS** against **15.537294667 FPS** for
control (**−0.000005333 FPS, −0.00003433%**). The parity-only screen retained
the exact frame count and checksum but skipped the strict i486 audit. The
negative mean rejects the reorder, and the prior instruction order is restored.
See the
[Span16 S-add screen ledger](ledger/2026-10-21-span16-s-add-before-fetch-screen-rejected.md).

Delaying the default word-store loop's T-carry extraction until after each
low-byte source fetch averaged **15.537292000 FPS** against **15.537289000 FPS**
for the matched strict control (**+0.000003000 FPS, +0.00001931%**). The
parity-only screen was also positive by **+0.000007333 FPS**. All strict runs
retained exact 969-frame checksum parity, and the complete linked i486 audit
passed. The positive strict mean qualifies even though it is below the spread.
See the
[Span16 T-carry ledger](ledger/2026-10-21-span16-tcarry-after-fetch-promoted.md).

Moving the `LSetUpCommon` `tstep` store just after the T-fraction add averaged
**15.537295000 FPS** against **15.537292000 FPS** for strict control
(**+0.000003000 FPS, +0.00001931%**). The three-run parity-only screen was also
positive by **+0.000000667 FPS**. All nine runs retained 969 frames and checksum
`1047377823`; the complete strict i486 audit passed. The positive mean qualifies
below the observed spread. See the
[Span16 `tstep` store ledger](ledger/2026-10-21-span16-tstep-store-after-add-promoted.md).

Moving the `LSetUpCommon` `advancetable` store from before the T-fraction add
to just after it averaged **15.537293000 FPS** against **15.537295000 FPS** for
the strict control (**−0.000002000 FPS, −0.00001287%**). All six runs retained
969 frames and checksum `1047377823`; the parity-only candidate skipped the ISA
audit. The negative mean rejects the ordering, and the original store position
is restored. See the
[Span16 `advancetable` screen ledger](ledger/2026-10-21-span16-advancetable-store-after-tfrac-add-screen-rejected.md).

Deferring the `LSetUpCommon` S-step fractional shift until after T-carry
extraction screened positive at **15.537301333 FPS** versus **15.537295000 FPS**
for strict control, but the strict candidate averaged **15.537289333 FPS**
(**−0.000005667 FPS, −0.00003647%**). All nine runs retained 969 frames and
checksum `1047377823`; the complete strict i486 audit passed. The negative strict
mean rejects the change, leaving the original shift position active. See the
[Span16 S-step shift ledger](ledger/2026-10-21-span16-sstep-shift-after-tcarry-rejected.md).

Moving the `LSetUpCommon` S-step shift after the T-step shift and
`advancetable` store averaged **15.537293667 FPS** against **15.537295000 FPS**
for strict control (**−0.000001333 FPS, −0.00000858%**). All six runs retained
969 frames and checksum `1047377823`; the parity-only candidate skipped the
strict ISA audit. The negative mean rejects the order, and the original shift
position remains active. See the
[Span16 S-step scheduling ledger](ledger/2026-10-21-span16-sstep-shift-after-advancetable-screen-rejected.md).

Moving the `LSetUpCommon` S-step shift after the T-step shift and before the
`advancetable` store averaged **15.537297000 FPS** against **15.537295000 FPS**
for strict control (**+0.000002000 FPS, +0.00001287%**). The three-run
parity-only screen was also positive by **+0.000003667 FPS**. All nine runs
retained 969 frames and checksum `1047377823`; the complete strict i486 audit
passed. The positive mean qualifies below the observed spread. See the
[Span16 S-step shift promotion ledger](ledger/2026-10-21-span16-sstep-shift-after-tstep-shift-promoted.md).

Moving the `LSetUpCommon` `sfracf` reload after the T-step shift averaged
**15.537292000 FPS** against **15.537297000 FPS** for the promoted strict
control (**−0.000005000 FPS, −0.00003218%**). All six runs retained 969 frames
and checksum `1047377823`; the parity-only candidate skipped the strict ISA
audit. The negative mean rejects the load order, leaving the promoted ordering
active. See the
[`sfracf` load-order screen ledger](ledger/2026-10-21-span16-sfracf-after-tstep-shift-screen-rejected.md).

Moving the `LSetUpCommon` `sfracf` reload after both fractional shifts averaged
**15.537290667 FPS** against **15.537297000 FPS** for the promoted strict
control (**−0.000006333 FPS, −0.00004076%**). All six runs retained 969 frames
and checksum `1047377823`; the parity-only candidate skipped the strict ISA
audit. The negative mean rejects the load order, leaving the promoted sequence
active. See the
[`sfracf` after-shifts screen ledger](ledger/2026-10-21-span16-sfracf-after-both-shifts-screen-rejected.md).

Shifting S first, storing `advancetable`, and then shifting T averaged
**15.537292333 FPS** against **15.537297000 FPS** for the promoted strict
control (**−0.000004667 FPS, −0.00003004%**). All six runs retained 969 frames
and checksum `1047377823`; the parity-only candidate skipped the strict ISA
audit. The negative mean rejects the permutation, leaving the promoted order
active. See the
[Span16 setup permutation ledger](ledger/2026-10-21-span16-s-first-store-t-shift-screen-rejected.md).

Extending the T-carry deferral to the high-byte loads averaged **15.537297000
FPS** against **15.537302000 FPS** for the promoted low-byte-only control
(**−0.000005000 FPS, −0.00003219%**). The parity-only screen retained exact
frame/checksum parity and skipped the strict audit. The negative mean rejects
the extension; the low-byte-only schedule remains active. See the
[high-byte extension screen ledger](ledger/2026-10-21-span16-tcarry-after-all-fetches-screen-rejected.md).

Rechecking `TextureSpanLoadOrder=loadfirst` against the currently promoted
low-byte T-carry schedule averaged **15.537290000 FPS** against
**15.537302000 FPS** for control (**−0.000012000 FPS, −0.00007724%**). The
parity-only screen retained exact frame/checksum parity and skipped the strict
audit. The negative mean leaves the control order active and `loadfirst`
opt-in. See the
[current-control loadfirst ledger](ledger/2026-10-21-span16-loadfirst-current-control-rejected.md).

After promoting the S-step shift after the T-step shift, `loadfirst` was
rechecked against the new strict control. It averaged **15.537296000 FPS**
against **15.537297000 FPS** (**−0.000001000 FPS, −0.00000644%**). All six runs
retained 969 frames and checksum `1047377823`; the parity-only run skipped the
strict audit. The negative mean leaves `control` active. See the
[current-control loadfirst ledger](ledger/2026-10-21-span16-loadfirst-current-control-rejected.md).

Moving the `LSetUpCommon` `advancetable` store immediately after the `sfracf`
reload averaged **15.537296333 FPS** against **15.537297000 FPS** for strict
control (**−0.000000667 FPS, −0.00000429%**). All six runs retained 969 frames
and checksum `1047377823`; the parity-only candidate skipped the strict ISA
audit. The negative mean rejects the earlier store placement. See the
[Span16 store-order screen ledger](ledger/2026-10-21-span16-advancetable-store-after-sfracf-screen-rejected.md).

The current `D_DrawSpans16` `LSetUpCommon` schedule moves the independent
`advancetable` store after the S- and T-step fractional shifts. Its strict
three-run mean was **15.537297000 FPS**, up from the pooled six-run strict
control mean of **15.537295333 FPS** (**+0.000001667 FPS, +0.00001072%**). A
separate three-run parity screen was also positive by **+0.000000333 FPS**.
Both gains are below the observed spread but positive. All strict runs retained
969 frames and checksum `1047377823`, and the complete linked i486 audit passed.
See the
[Span16 post-shift store ledger](ledger/2026-10-21-span16-store-after-tstep-shift-promoted.md).

The earlier `LSetUpCommon` store placement, after the `sfracf` reload and before
the T-step fractional shift, was promoted first and is now superseded in source
by the post-shift schedule. Its original measurement remains in the
[initial Span16 store ledger](ledger/2026-10-21-span16-advancetable-store-hoist-promoted.md).

Deferring the `tfracf` reload until after the `advancetable+4` store and
cachewidth addition in both `D_DrawSpans16` setup arms is also promoted. Its
strict three-run mean was **15.537299333 FPS**, up from the matched control's
**15.537290667 FPS** (**+0.000008667 FPS, +0.00005580%**). All runs retained
969 frames and checksum `1047377823`; the complete linked i486 audit passed.
See the
[deferred-reload promotion ledger](ledger/2026-10-21-span16-deferred-tfracf-reload-promoted.md).

Six assembly schedules were screened on 2026-10-21. Hoisting the
`D_DrawSpans16` cachewidth load averaged **15.537291667 FPS** against
**15.537300000 FPS** for control (**−0.000008333 FPS**); moving the `D_DrawZSpans`
high-word extraction ahead of the accumulator step averaged **15.537290333 FPS**
(**−0.000009667 FPS**); and preincrementing the Z-span destination pointer
before each packed store averaged **15.537293000 FPS** (**−0.000007000 FPS**).
The RenderFace nonnegative-edge branch averaged **15.537292333 FPS**
(**−0.000007667 FPS**). Moving the edge-scan span reset ahead of x87 row setup
averaged **15.537295333 FPS** (**−0.000004667 FPS**); preloading the row's
`newedges` pointer averaged **15.537292667 FPS** (**−0.000007333 FPS**). All six
three-run screens retained the exact frame count and checksum; their negative
pooled means were rejected. The parity-only screens skipped the ISA audit. See
the [span16 screen ledger](ledger/2026-10-21-span16-cachewidth-load-screen-rejected.md),
[extraction screen ledger](ledger/2026-10-21-zspan-extract-before-step-screen-rejected.md),
[pointer screen ledger](ledger/2026-10-21-zspan-store-pointer-preincrement-screen-rejected.md),
[RenderFace branch screen ledger](ledger/2026-10-21-renderface-nonnegative-edge-branch-screen-rejected.md),
the [edge-scan screen ledger](ledger/2026-10-21-edge-scan-span-reset-before-x87-screen-rejected.md),
and the [newedges screen ledger](ledger/2026-10-21-edge-scan-newedges-load-hoist-screen-rejected.md).

Keeping the edge-scan `surfaces` base in callee-saved `%edi` produced a
positive parity screen at **15.538371667 FPS** against **15.537290333 FPS** for
control (**+0.001081333 FPS**). The strict candidate averaged **15.500427 FPS**
because its third run measured 15.424542 FPS; that sample remains in the
pooled mean. Exact parity and the complete i486 audit passed, but the strict
mean was **−0.036870 FPS** against the latest strict control at **15.537297
FPS**, so the change is rejected and reverted. See the
[edge-scan surface-base ledger](ledger/2026-10-21-edge-scan-surface-base-cache-screen-rejected.md).

Replacing the per-row unconditional jump in `R_ScanEdges` with a bottom-tested
loop averaged **15.538384 FPS** in the strict candidate against **15.537297
FPS** for control (**+0.001087 FPS, +0.00699607%**). The parity-only screen
was also positive by **+0.001092333 FPS**. All runs retained 969 frames and
checksum `1047377823`; the full strict i486 audit passed. The positive pooled
mean qualifies under the any-positive rule. See the
[edge-scan row-loop promotion ledger](ledger/2026-10-21-edge-scan-bottom-tested-row-loop-promoted.md).

Moving the `D_DrawSpans16` base-address store ahead of the `tfracf` reload in
both setup arms averaged **15.537288333 FPS** against **15.537290667 FPS** for
control across three alternating pairs (**−0.000002333 FPS, −0.0000150%**).
All six parity-only runs retained 969 frames and checksum `1047377823`; the
negative pooled mean was rejected and the original order restored. The visual
screen skipped the ISA audit. See the
[Span16 store-order screen ledger](ledger/2026-10-21-span16-base-store-before-tfracf-screen-rejected.md).

Moving the alias raster Z-buffer store before the passing pixel's texture load
averaged **15.537286333 FPS** against **15.537299333 FPS** for the promoted
control (**−0.000013000 FPS, −0.00008367%**). All six parity-screen runs
retained 969 frames and checksum `1047377823`; the negative mean was rejected
without a strict audit, and the promoted store order was restored. See the
[alias depth-store screen ledger](ledger/2026-10-21-alias-depth-store-before-texel-screen-rejected.md).

Moving the alias raster Z-buffer store after the light-byte load but before the
colormap lookup averaged **15.537288667 FPS** against **15.537299333 FPS** for
the promoted control (**−0.000010667 FPS, −0.00006865%**). All six parity-screen
runs retained 969 frames and checksum `1047377823`; the negative mean was
rejected without strict validation, and the promoted store order was restored.
See the
[alias light-store screen ledger](ledger/2026-10-21-alias-depth-store-after-light-screen-rejected.md).

Moving the `LSetUpCommon` `advancetable` store before the `sfracf` reload
averaged **15.537288333 FPS** against **15.537299333 FPS** for the promoted
control (**−0.000011000 FPS, −0.00007080%**). All six parity-screen runs
retained 969 frames and checksum `1047377823`; the candidate's negative mean
was rejected without a strict audit, and the promoted order was restored. See
the [Span16 store-order ledger](ledger/2026-10-21-span16-store-before-sfracf-screen-rejected.md).

Moving the `LSetUpCommon` `sfracf` reload before the S-step shift averaged
**15.537286333 FPS** against **15.537299333 FPS** for the promoted control
(**−0.000013000 FPS, −0.00008367%**). All six parity-screen runs retained 969
frames and checksum `1047377823`; the negative mean was rejected without a
strict audit, and the promoted order was restored. See the
[Span16 reload-order ledger](ledger/2026-10-21-span16-sfracf-before-sstep-shift-screen-rejected.md).

## Latest matched selector result (2026-10-22)

The matched `R_RenderFace` selector comparison in
[`ledger/2026-10-22-renderface-assembly-promoted.md`](ledger/2026-10-22-renderface-assembly-promoted.md)
averaged **15.564252667 FPS** for assembly versus **15.502609667 FPS** for C
(**+0.061643 FPS, +0.39763%**). Each variant ran three uninstrumented samples
at 969 frames with checksum `1047377823`; both used the same source tree,
pinned DOSBox-X profile, and edge-list selector. The assembly candidate passed
the full linked strict i486 audit. `RenderFaceImplementation=asm` is confirmed
as the i486 default; C remains selectable and i386 remains C.

The follow-up x87 nearzi condition substitution (`testb`/`jnz` to
`sahf`/`jna`) averaged **15.563349333 FPS** against the current assembly
control's **15.564253333 FPS** (**−0.000904 FPS, −0.00580818%**). All six runs
matched 969 frames and checksum `1047377823`; the candidate passed the full
linked strict i486 audit. The negative mean rejected the substitution, and the
original condition check was restored. See the
[`SAHF/JNA rejection ledger`](ledger/2026-10-22-renderface-sahf-nearzi-rejected.md).

The current i486 default had also selected the replacement edge-list assembly,
although its matched result was slower than the original handwritten path. A
fresh strict three-run legacy mean of **15.598464333 FPS** versus
**15.564258 FPS** for replacement assembly gives **+0.034206333 FPS
(+0.21977491%)**. Both variants used the same source tree and checksum, and both
passed the full linked i486 audit. The i486 profile now selects legacy assembly
by default; replacement `asm` and C remain explicitly selectable. See the
[legacy-default ledger](ledger/2026-10-22-edge-list-legacy-default-promoted.md).

The legacy `R_InsertNewEdges` fourth-probe early-out layout passed exact
parity and the full linked i486 audit, but its strict three-run mean was
**15.562291667 FPS** against **15.600943 FPS** for control
(**−0.038651333 FPS, −0.24774998%**). All three samples were slower than
control; the slow third sample is included because no separate cause was
established. The original `JG` fallthrough remains active. See the
[fourth-probe rejection ledger](ledger/2026-10-22-edge-insert-probe4-earlyout-rejected.md).

Preloading the first `R_StepActiveU` successor before its order check passed
exact parity and the complete i486 audit, but averaged **15.600363667 FPS**
against **15.600943 FPS** for control (**−0.000579333 FPS, −0.00371345%**).
Every candidate sample was slower, so the original post-branch load remains.
See the
[edge-step prefetch rejection ledger](ledger/2026-10-22-edge-step-successor-prefetch-rejected.md).

Preloading the second `R_StepActiveU` successor before its order check also
passed exact parity and the complete i486 audit, but averaged **15.600565 FPS**
against **15.600943 FPS** for control (**−0.000378 FPS, −0.00242293%**). Every
candidate sample was slower, so the original post-branch load remains. See the
[second edge-step prefetch rejection ledger](ledger/2026-10-22-edge-step-second-successor-prefetch-rejected.md).

Preloading the third `R_StepActiveU` successor before its order check also
passed exact parity and the complete i486 audit, but averaged **15.600524 FPS**
against **15.600943 FPS** for control (**−0.000419 FPS, −0.00268574%**). Every
candidate sample was slower, so the original post-branch load remains. See the
[third edge-step prefetch rejection ledger](ledger/2026-10-22-edge-step-third-successor-prefetch-rejected.md).

Moving the fourth `R_StepActiveU` successor load ahead of the U fetch and add
passed exact parity and the complete i486 audit, but averaged **15.600934333
FPS** against **15.600943 FPS** for control (**−0.000008667 FPS,
−0.00005555%**). The negative mean restores the original load placement. See
the [fourth edge-step load ledger](ledger/2026-10-22-edge-step-fourth-successor-load-early-rejected.md).

Moving that load between the U fetch and addition also passed exact parity and
the complete i486 audit, but averaged **15.600929 FPS** against **15.600943
FPS** for control (**−0.000014 FPS, −0.00008974%**). The original placement
remains active. See the
[fourth edge-step load-position ledger](ledger/2026-10-22-edge-step-fourth-successor-load-between-u-add-rejected.md).

Moving the same load after the U store averaged **15.600926667 FPS** against
**15.600943 FPS** for control (**−0.000016333 FPS, −0.00010469%**), with exact
parity and the complete i486 audit passing. The original load slot remains.
See the
[after-store rejection ledger](ledger/2026-10-22-edge-step-fourth-successor-load-after-store-rejected.md).

Moving the load between the order compare and `jnl LNextEdge` also passed exact
parity and the complete i486 audit, but averaged **15.600940667 FPS** against
**15.600943 FPS** for control (**−0.000002333 FPS, −0.00001496%**). One sample
was faster than every control sample, but the pooled mean is negative. The
original load slot remains; see the
[after-compare rejection ledger](ledger/2026-10-22-edge-step-fourth-successor-load-after-compare-rejected.md).

The active `R_EdgeDrawing_asm486` helper's x87 float-truth sequence was replaced
with an integer check of the `r_dspeeds` bit pattern. Its strict three-run mean
is **15.598633 FPS** against **15.598464333 FPS** for control
(**+0.000168667 FPS, +0.00108130%**); all six runs retained 969 frames and
checksum `1047377823`. The full linked i486 audit passed with zero above-i486
instructions, unknown opcodes, or exemptions. This small positive mean
qualifies under the any-positive rule. The i486 profile already selects edge
drawing assembly, so this promotes the helper change without changing routing.
See the
[edge-drawing truth-test ledger](ledger/2026-10-22-edge-drawing-dspeeds-integer-truth-promoted.md).

Caching that truth value in `EBX` across the synchronous edge-drawing pass
removed three additional helper calls. Its strict three-run mean is
**15.598738667 FPS** against **15.598633 FPS** for the integer-helper control
(**+0.000105667 FPS, +0.00067741%**); all six runs retained exact checksum
parity. The full linked i486 audit passed. The any-positive mean qualifies, and
the existing assembly selector remains unchanged. See the
[edge-drawing cache ledger](ledger/2026-10-22-edge-drawing-dspeeds-cache-promoted.md).

Removing the final-scan branch's `TEST` after `OR` had exact checksum parity
and passed the full linked ISA gate, but its strict three-run mean was
**15.560257 FPS** against **15.598738667 FPS** for control
(**−0.038481667 FPS, −0.24669730%**). The third candidate run was an isolated
slow sample; it remains included because no separate cause was established.
The negative mean rejects the change, and `TEST` is restored. See the
[final-scan rejection ledger](ledger/2026-10-22-edge-drawing-final-scan-test-rejected.md).

The scan-edge assembly now caches `pdrawfunc` in `ESI`, removing its per-row
global load while retaining the span-base reset on flush. Its strict three-run
mean is **15.599823 FPS** against **15.598738667 FPS** for control
(**+0.001084333 FPS, +0.00695142%**); all six runs retained exact checksum
parity. The full linked i486 audit passed with zero exemptions. The any-positive
mean qualifies, and `ScanEdgesImplementation=asm` routing remains unchanged.
See the
[scan-edge callback ledger](ledger/2026-10-22-scan-edges-callback-cache-promoted.md).

The scan-edge loop now caches `surfaces` in `EDI` and keeps the exclusive row
limit in `-32(%ebp)`, removing the per-row global surface-pointer load and the
reload during span clearing. Its strict three-run mean is **15.600943 FPS**
against **15.599823 FPS** for the cached-callback control
(**+0.001120 FPS, +0.00717957%**); every candidate sample beat every control
sample. All six runs retained exact checksum parity, and the complete linked
i486 audit passed. The any-positive mean qualifies, with
`ScanEdgesImplementation=asm` routing unchanged. See the
[scan-edge surface-base ledger](ledger/2026-10-22-scan-edges-surface-base-cache-promoted.md).

Caching the per-row `max_span_p` comparison in a stack local passed the full
parity and i486 audit gates, but averaged **15.600933 FPS** against
**15.600943 FPS** for control (**−0.000010 FPS, −0.00006410%**). The negative
mean rejects it, so the global comparison remains active. See the
[max-span rejection ledger](ledger/2026-10-22-scan-edges-maxspan-local-cache-rejected.md).

The scan-edge span-clear loop now checks for an empty range once and then uses
a bottom-tested conditional back-edge, removing the per-surface unconditional
jump. Its strict three-run mean is **15.601030667 FPS** against **15.600943
FPS** for control (**+0.000087667 FPS, +0.00056193%**); every candidate sample
beat every control sample. Exact 969-frame checksum parity and the complete
linked i486 audit passed. This positive mean qualifies under the any-positive
rule. See the
[span-clear loop ledger](ledger/2026-10-22-scan-edges-clear-span-bottom-tested-promoted.md).

The span-clear loop now clears two adjacent surfaces per iteration, with a
single-surface tail when needed. Its strict three-run mean is **15.601132333
FPS** against **15.601030667 FPS** for the one-span control
(**+0.000101667 FPS, +0.00065167%**); every candidate sample beat every control
sample. Exact 969-frame checksum parity and the complete strict i486 audit
passed. This positive mean qualifies under the any-positive rule. See the
[two-span unroll ledger](ledger/2026-10-22-scan-edges-clear-span-unroll2-promoted.md).

The span-clear loop now clears four adjacent surfaces per iteration, then
handles up to three remaining surfaces in its tail path. Its strict three-run
mean is **15.601231333 FPS** against **15.601132333 FPS** for the two-span
control (**+0.000099 FPS, +0.00063457%**); every candidate sample beat every
control sample. Exact 969-frame checksum parity and the complete strict i486
audit passed. This positive mean qualifies under the any-positive rule. See the
[four-span unroll ledger](ledger/2026-10-22-scan-edges-clear-span-unroll4-promoted.md).

The span-clear loop now clears eight adjacent surfaces per iteration, then
handles up to seven remaining surfaces in its tail path. Its strict three-run
mean is **15.601264333 FPS** against **15.601231333 FPS** for the four-span
control (**+0.000033 FPS, +0.00021152%**); every candidate sample beat every
control sample. Exact 969-frame checksum parity and the complete strict i486
audit passed. This positive mean qualifies under the any-positive rule. See the
[eight-span unroll ledger](ledger/2026-10-22-scan-edges-clear-span-unroll8-promoted.md).

The eight-span loop now handles its tail in 4-, 2-, and 1-span groups. Its
strict three-run mean is **15.601271333 FPS** against **15.601264333 FPS** for
the sequential-tail control (**+0.000007 FPS, +0.00004487%**). The gain is
smaller than the run spread, but the positive mean qualifies under the
any-positive rule. Exact 969-frame checksum parity and the complete strict
i486 audit passed. See the
[grouped-tail ledger](ledger/2026-10-22-scan-edges-clear-span-unroll8-group-tail-promoted.md).

The scan-edge clear loop now clears twelve adjacent surfaces per iteration,
then uses an 8/4/2/1 grouped tail. Its strict three-run mean is **15.601279667
FPS** against **15.601271333 FPS** for the eight-span grouped-tail control
(**+0.000008333 FPS, +0.00005341%**). The positive mean qualifies under the
any-positive rule despite overlapping samples and a gain below the run spread.
Exact 969-frame checksum parity and the complete strict i486 audit passed. See
the [twelve-span grouped-tail ledger](ledger/2026-10-22-scan-edges-clear-span-unroll12-group-tail-promoted.md).

The scan-edge clear loop now clears fourteen adjacent surfaces per iteration,
then uses an 8/4/2/1 grouped tail. Its strict three-run mean is **15.601294667
FPS** against **15.601279667 FPS** for the twelve-span grouped-tail control
(**+0.000015 FPS, +0.00009615%**). The sample ranges overlap, but the positive
mean qualifies under the any-positive rule even though the gain is smaller
than the control's run spread. Exact 969-frame checksum parity and the complete
strict i486 audit passed. See the
[fourteen-span grouped-tail ledger](ledger/2026-10-22-scan-edges-clear-span-unroll14-group-tail-promoted.md).

The thirteen-span variant used the same 8/4/2/1 grouped tail and averaged
**15.601294333 FPS**, **−0.000000333 FPS (−0.00000214%)** against the
fourteen-span control. All runs retained exact 969-frame checksum parity and
the complete strict i486 audit passed. Under the any-positive mean rule, the
negative mean rejects this candidate; fourteen spans remains active. See the
[thirteen-span rejection ledger](ledger/2026-10-22-scan-edges-clear-span-unroll13-group-tail-rejected.md).

The active fourteen-span loop was also tested with one zeroed `ECX` register
reused for its fourteen stores. It averaged **15.601281 FPS** against
**15.601294667 FPS** for the immediate-store control (**−0.000013667 FPS,
−0.00008759%**). Exact 969-frame checksum parity and the complete strict i486
audit passed. The negative mean rejects register reuse; the immediate stores
remain active. See the
[zero-register rejection ledger](ledger/2026-10-22-scan-edges-clear-span14-zero-register-rejected.md).

Adding 16-byte code alignment at the active fourteen-span loop entry averaged
**15.601279 FPS** against the strict control's **15.601303 FPS**
(**−0.000024 FPS, −0.00015383%**). The trailing control was **15.601291 FPS**;
the candidate remained **−0.000012 FPS** below it. All seven runs retained 969
frames and checksum `1047377823`, and the complete strict i486 audit passed.
The negative mean rejects the alignment, leaving the original unaligned loop
active. See the
[scan-edge alignment ledger](ledger/2026-10-22-scan-edges-clear-span14-alignment-rejected.md).

The fifteen-span variant used the same 8/4/2/1 grouped tail but averaged
**15.601293667 FPS**, **−0.000001 FPS (−0.00000641%)** against the fourteen-span
control. Exact 969-frame checksum parity and the complete strict i486 audit
passed, but the negative mean rejects the candidate. The fourteen-span loop
remains active. See the
[fifteen-span rejection ledger](ledger/2026-10-22-scan-edges-clear-span-unroll15-rejected.md).

The sixteen-span variant passed parity and the complete strict i486 audit, but
its mean was **15.585453 FPS**, **−0.015811333 FPS (−0.10134649%)** against the
eight-span control. One sample measured **15.553785 FPS** over 62.299951 seconds
while the other two were near 15.6013 FPS. The slow sample stays in the pooled
mean, so the negative result rejects sixteen-span unrolling. The fourteen-span
loop with its grouped tail remains active. See the
[sixteen-span rejection ledger](ledger/2026-10-22-scan-edges-clear-span-unroll16-rejected.md).

## Recent assembly timing and hotspot profile (2026-10-21)

The `R_RenderFace` positive-edge branch layout in
[`ledger/2026-10-21-renderface-positive-edge-branch-layout.md`](ledger/2026-10-21-renderface-positive-edge-branch-layout.md)
is promoted in the working assembly source. Against the immediately preceding
promoted source, the strict three-run mean rose from **15.536974667 FPS** to
**15.537297333 FPS** (**+0.0020768%**); every candidate sample beat every
baseline sample. Exact 969-frame checksum parity and the full linked i486 audit
passed. This small repeatable gain qualifies under the no-minimum-gain policy.

The `TextureSpanStores=stosw` assembly variant in
[`ledger/2026-10-21-texture-span-stosw-rejected.md`](ledger/2026-10-21-texture-span-stosw-rejected.md)
averaged **15.522019667 FPS** against the promoted word-store control's
**15.537297333 FPS** (**−0.0983%**) with exact frame/checksum parity. Every
candidate sample was slower, so it remains opt-in and the indexed word stores
remain the default.

The early packed-store schedule in
[`ledger/2026-10-21-texture-span-early-store-promoted.md`](ledger/2026-10-21-texture-span-early-store-promoted.md)
was re-evaluated under the positive-mean promotion rule. Its twelve-run pooled
mean was **15.537298083 FPS** against **15.537297833 FPS** for control
(**+0.0000016%**). The delta is smaller than the run-to-run spread, but it is
positive and now qualifies. The candidate source passes the complete linked
i486 audit and its earlier twelve parity-screen runs retained the exact frame
count and checksum.

The alias-raster depth-store schedule in
[`ledger/2026-10-21-alias-raster-depth-store-reorder.md`](ledger/2026-10-21-alias-raster-depth-store-reorder.md)
is also promoted. Three alternating pairs averaged **15.537301333 FPS** for the
candidate and **15.537289333 FPS** for control (**+0.000012 FPS, +0.0000772%**).
All six runs matched 969 frames and checksum `1047377823`. The strict candidate
passed the complete linked i486 audit and a direct strict-binary parity run at
**15.537300 FPS**.

The follow-up alias-raster schedule in
[`ledger/2026-10-21-alias-raster-prelookup-depth-store-promoted.md`](ledger/2026-10-21-alias-raster-prelookup-depth-store-promoted.md)
is promoted under the positive-mean rule. Moving each passing pixel's Z-buffer
store after its texel load and before light/colormap work averaged
**15.537295667 FPS** against **15.537289667 FPS** for the prior schedule
(**+0.000006 FPS, +0.0000386%**) over three alternating pairs. The gain is
smaller than the paired spread, but the pooled mean is positive. All six runs
matched 969 frames and checksum `1047377823`; the strict linked i486 audit and
a direct strict-binary parity run passed.

The `D_DrawZSpans` accumulator schedule in
[`ledger/2026-10-21-zspan-step-before-store-promoted.md`](ledger/2026-10-21-zspan-step-before-store-promoted.md)
is promoted under the positive pooled-mean rule. Three alternating pairs
averaged **15.537298667 FPS** for the candidate and **15.499629667 FPS** for
control (**+0.2430%**); every run retained 969 frames and checksum
`1047377823`. One control sample at **15.424306 FPS** is a clear outlier and
drives most of the pooled delta: the other two pairs alone average
**15.537302 FPS** for the candidate and **15.5372915 FPS** for control. The
strict linked i486 audit and a direct strict-binary parity run passed; this
change promotes, while the causal gain size remains uncertain.

The surface-cache hit key-pointer retention in
[`ledger/2026-10-21-surface-cache-hit-key-pointer-retained-promoted.md`](ledger/2026-10-21-surface-cache-hit-key-pointer-retained-promoted.md)
is promoted under the positive-mean rule. Its strict three-run mean was
15.537292667 FPS against 15.537291333 FPS for control (**+0.00000858%**). All
six runs retained 969 frames and checksum `1047377823`; the complete linked
i486 audit passed. The gain is smaller than the observed spread, but its pooled
mean is positive. An intermediate load-gap schedule tied and was rejected; see
[`ledger/2026-10-21-surface-cache-hit-load-gap-rejected.md`](ledger/2026-10-21-surface-cache-hit-load-gap-rejected.md).
The single-style fall-through follow-up averaged 15.499113 FPS after one slow
sample, against the promoted control's 15.537292667 FPS (**−0.245729%**). It
passed parity and the strict i486 audit but was rejected on its negative pooled
mean; see
[`ledger/2026-10-21-surface-cache-hit-single-style-fallthrough-rejected.md`](ledger/2026-10-21-surface-cache-hit-single-style-fallthrough-rejected.md).
Preloading the texture pointer before the cache dlight check averaged
15.537290667 FPS against 15.537292667 FPS for control (**−0.000002 FPS,
−0.00001287%**). It passed parity and the strict i486 audit, but its negative
pooled mean was rejected; see
[`ledger/2026-10-21-surface-cache-hit-texture-preload-rejected.md`](ledger/2026-10-21-surface-cache-hit-texture-preload-rejected.md).
Moving the texture comparison itself ahead of the cache dlight check averaged
15.537286667 FPS against 15.537292667 FPS for control (**−0.000006 FPS,
−0.00003862%**). It also passed parity and the strict i486 audit, but was
rejected on the negative pooled mean; see
[`ledger/2026-10-21-surface-cache-hit-texture-check-first-rejected.md`](ledger/2026-10-21-surface-cache-hit-texture-check-first-rejected.md).

The mip-2 horizontal-flat block was reimplemented in assembly after its older
attempt failed checksum parity. The new four-row path passed exact parity and
the complete strict i486 audit, but averaged **15.537008 FPS** against
**15.537292667 FPS** for control (**−0.000284667 FPS, −0.00183215%**), so it was
removed on its negative mean. See
[`ledger/2026-10-21-surf8-mip2-horizontal-flat-rejected.md`](ledger/2026-10-21-surf8-mip2-horizontal-flat-rejected.md).

The general mip-2 block's source texel loads were moved ahead of light-delta
setup in assembly. The strict three-run mean rose to **15.537300 FPS** from
**15.537292667 FPS** (**+0.000007333 FPS, +0.00004720%**). This positive mean
qualifies under the no-floor rule even though it is smaller than the run spread.
All six runs matched 969 frames and checksum `1047377823`; the full linked i486
audit passed. See
[`ledger/2026-10-21-surf8-mip2-texel-loads-promoted.md`](ledger/2026-10-21-surf8-mip2-texel-loads-promoted.md).

Moving the mip-2 `lightright` and `lightdelta` reloads ahead of the final two
colormap reads averaged **15.537290667 FPS** against the promoted texel-load
source's **15.537300000 FPS** (**−0.000009333 FPS, −0.00006007%**). All six
runs matched 969 frames and checksum `1047377823`; the strict linked i486 audit
passed. The negative pooled mean rejects this reload schedule, while the
separate texel-load schedule remains active. See
[`ledger/2026-10-21-surf8-mip2-rowstate-reload-rejected.md`](ledger/2026-10-21-surf8-mip2-rowstate-reload-rejected.md).

Moving only the mip-2 `lightdelta` reload between the final two colormap reads
averaged **15.537292 FPS** against the promoted texel-load source's
**15.537300 FPS** (**−0.000008 FPS, −0.00005149%**). All six strict runs
matched 969 frames and checksum `1047377823`; the linked i486 audit passed.
The negative pooled mean rejects this isolated reload move. See
[`ledger/2026-10-21-surf8-mip2-lightdelta-prefetch-rejected.md`](ledger/2026-10-21-surf8-mip2-lightdelta-prefetch-rejected.md).

Swapping the initial mip-2 texel 2 and texel 3 loads averaged
**15.537293667 FPS** against **15.537300000 FPS** for the promoted order
(**−0.000006333 FPS, −0.00004076%**). All six runs retained 969 frames and
checksum `1047377823`. The three-run screen was parity-only, skipped the ISA
audit, and returned a negative mean, so the original load order remains active.
See
[`ledger/2026-10-21-surf8-mip2-texel-read-order-screen-rejected.md`](ledger/2026-10-21-surf8-mip2-texel-read-order-screen-rejected.md).

The `D_DrawSpans16` common nonzero-step setup's cachewidth-load hoist averaged
**15.537291667 FPS** against the active control's **15.537300000 FPS**
(**−0.000008333 FPS, −0.00005363%**). All runs retained 969 frames and
checksum `1047377823`; the parity-only screen skipped the ISA audit. The
negative pooled mean rejects the hoist, and the original setup order is
restored. See
[`ledger/2026-10-21-span16-cachewidth-load-screen-rejected.md`](ledger/2026-10-21-span16-cachewidth-load-screen-rejected.md).

The surface-cache hit key-store deferral in
[`ledger/2026-10-20-cache-hit-key-store-deferral.md`](ledger/2026-10-20-cache-hit-key-store-deferral.md)
is promoted in the working source. Against the matched control, three-run mean
FPS rose from **15.501913667** to **15.506285333** (**+0.0282%**). All six runs
rendered 969 frames with checksum `1047377823`; every candidate run was faster
than every control run, and the candidate passed the full linked i486 audit.

The surface-cache key-preparation fusion in
[`ledger/2026-10-20-cache-key-fusion.md`](ledger/2026-10-20-cache-key-fusion.md)
is promoted in the working source. Against the same pinned 32 MB profile, the
three-run mean rose from **15.495709 FPS** to **15.501904 FPS** (**+0.039975%**).
All six runs rendered 969 frames with checksum `1047377823`; the candidate
passed the strict linked i486 audit.

The `R_RenderFace` cache-offset reuse in
[`ledger/2026-10-20-renderface-cacheoffset-reuse.md`](ledger/2026-10-20-renderface-cacheoffset-reuse.md)
is promoted in the working assembly source. The strict three-run mean was
**15.534454 FPS** against the six-run control mean of **15.531288 FPS**
(**+0.02038%**); every candidate sample beat every control sample. Exact
969-frame checksum parity and the complete linked i486 audit passed.

The follow-up `R_RenderFace` owner-compare fusion in
[`ledger/2026-10-20-renderface-owner-compare-fusion.md`](ledger/2026-10-20-renderface-owner-compare-fusion.md)
is also promoted. Against the preceding promoted source, the strict three-run
mean rose from **15.534454 FPS** to **15.536975 FPS** (**+0.0162284%**); every
candidate sample beat every baseline sample. Exact 969-frame checksum parity
and the complete linked i486 audit passed.

The cached-offset load hoist in
[`ledger/2026-10-20-renderface-offset-load-hoist-rejected.md`](ledger/2026-10-20-renderface-offset-load-hoist-rejected.md)
was removed after its parity-screen mean came in at **15.535376 FPS**
(**−0.0102894%**) against the promoted source. All samples were slower and
parity matched, so the existing load/compare order remains.

The branchless surfedge-magnitude candidate in
[`ledger/2026-10-20-renderface-branchless-surfedge-rejected.md`](ledger/2026-10-20-renderface-branchless-surfedge-rejected.md)
averaged **15.530492 FPS** over six parity-screen samples against a fresh
control at **15.536974 FPS** (**−0.041722%**). Five of six samples were below
control and parity matched, so the signed-edge branch was restored.

The `R_RenderFace` triangle/quad edge unroll in
[`ledger/2026-10-20-renderface-triangle-quad-unroll-rejected.md`](ledger/2026-10-20-renderface-triangle-quad-unroll-rejected.md)
was rejected after its strict three-run mean measured **15.530795 FPS**
(**−0.00317%**) against the same control. All candidate samples were slower;
the temporary unrolled code has been removed.

The `D_DrawZSpans` 16-pixel middle-loop unroll in
[`ledger/2026-10-20-zspan-middle-unroll16.md`](ledger/2026-10-20-zspan-middle-unroll16.md)
is also promoted. The six added strict samples averaged **15.531288 FPS**; all
nine candidate samples, including the earlier outlier, averaged
**15.518568667 FPS** against the immediate control's **15.506285333 FPS**
(**+0.0792%**). All runs retained the 969-frame checksum `1047377823`, and the
strict linked i486 audit passed.

The 32-pixel middle-loop follow-up in
[`ledger/2026-10-20-zspan-middle-unroll32-rejected.md`](ledger/2026-10-20-zspan-middle-unroll32-rejected.md)
averaged **15.534157 FPS** against the 16-pixel control's **15.536974 FPS**
(**−0.0181331%**). All samples were slower with exact parity, so the promoted
16-pixel grouping remains.

A fresh instrumented profile after the Z-span promotion ranked texture spans
first at 22.80% corrected self time, followed by Z spans at 10.47%, render-face
work at 9.30%, surface-cache work at 9.06%, and edge scanning at 8.02%. It
completed at 11.634824 FPS with the expected checksum; that rate is diagnostic
only because profiling hooks add overhead. The captured profile is
`out/dos-timedemo-20261020-193534/quake/PROFILE.JSN`.

The `TextureSpanLoadOrder=loadfirst` recheck in
[`ledger/2026-10-20-texture-span-loadfirst-recheck.md`](ledger/2026-10-20-texture-span-loadfirst-recheck.md)
did not produce a repeatable gain. Nine candidate runs averaged 15.531283889
FPS against ten control runs at 15.531284 FPS; the follow-up three-run means
were identical, so `control` remains the default.

The load-first plus early-store combination in
[`ledger/2026-10-21-texture-span-loadfirst-early-store-rejected.md`](ledger/2026-10-21-texture-span-loadfirst-early-store-rejected.md)
was also rejected under the positive-mean rule: its strict three-run mean was
15.537288333 FPS against 15.537291333 FPS for control (**−0.0000193%**).
All six runs retained the expected 969-frame checksum and the candidate passed
the complete linked i486 audit; the promoted early-store schedule remains in
the control load order.

The `TextureSpanStores=dword` recheck in
[`ledger/2026-10-20-texture-span-dword-recheck.md`](ledger/2026-10-20-texture-span-dword-recheck.md)
averaged 15.425266 FPS against the current six-run word-store control at
15.531288 FPS (**−0.6826%**). All runs retained exact frame parity; the
candidate timing screen skipped the strict ISA audit. The measured slowdown
leaves word stores as the default.

The `TextureSpanTailStores=word` screen in
[`ledger/2026-10-20-texture-span-tail-word-rejected.md`](ledger/2026-10-20-texture-span-tail-word-rejected.md)
averaged **15.358172 FPS** against the current **15.536975 FPS** build
(**−1.1508%**). It retained exact frame parity but was clearly slower, so the
candidate was rejected without a full ISA audit and `control` remains the
default.

## Historical baseline snapshot (2026-10-02)

```text
demo1 timedemo   59.160558 s   16.379156 FPS   969 frames
framebuffer checksum 1047377823    bench486 end checksum 2378409472
```

Recorded in `../BENCHMARK-COMPARISON.md`. Re-measured 2026-10-02 at
**59.160513 s** median over three runs — a 0.00008% difference, i.e. noise, so
the baseline is unchanged and the 2026-10-02 work promoted nothing. The
offline-precompute axis is closed by measurement; `ledger/INDEX.md` holds
every number behind that, plus each candidate that was rejected and why.

## Historical hotspot census (2026-10-02): the two largest unmeasured pools

The plan of record has consistently said the renderer is converged on every
promotable axis. That remains true of every axis that had been *probed* — but
two regions were closed for want of a measurement rather than on one, and on
2026-10-02 the first was measured:

| pool | cyc/frame | vs gate | closed because |
|---|---:|---:|---|
| `edge-scan` | 208,581 | 204x | *"unresolvable by this instrument, not as converged"* |
| `renderface` | 226,000 | 221x | *"no admissible hypothesis"*; probe declined |

**`edge-scan` is now decomposed, and the closure was half wrong.** Its
justification was that a per-call timer scope costs 387 cycles against 466
cycles of work per operation, giving 17% signal. That floor is real and still
forbids a scope — but it does not bind a **dead-scratch probe**, which has no
measurement overhead at all because it adds work and is read off the whole-run
timedemo delta. **Nine** probes gave the decomposition that was thought
unavailable:

```text
edge-scan, 78% accounted          159.2x the gate  (16 named blocks)
  measured by their own probe     136.4x    (9 blocks, 139,535 cyc/frame)
  statically priced at 0.98657     19.4x    (6 blocks,  19,853 cyc/frame)
  bmodel 1/z sort, inadmissible      3.3x    (66,644 calls, ~40 of 50 are x87)
  residual                        44.8x    (scope overhead, R_RecursiveTriangle,
                                            call entry/exit, per-block count error)
```

The census behind it overturned two beliefs at once: the four loops carrying
~20 logged micro-experiments are **52x the gate together, not most of the
bucket**, and `TrailingEdge` is called 2,238,002 times to emit 1,043,177 spans —
**53% of its calls emit nothing**, which nothing had measured.

**So `edge-scan` is no longer an unknown.** It is sixteen named blocks, largest
23.2x the gate, smallest 0.9x. That is a different object from "8% of frame,
cannot be decomposed", and it is what the twenty rejected micro-experiments
never had. It is **not** a licence to build: read against the prohibition list,
every block above 5x is hand-tuned assembly that has already absorbed the
recorded micro-optimisations, and the three largest per-edge blocks are
structurally minimal.

`renderface` is **priced and closed**. It was the second-largest pool at 221x the
gate, closed for *"no admissible hypothesis"*. Two C dead-scratch probes give
**~15.8x the gate** of priced C scaffolding — per-edge cache validation ~11.5x,
per-call prologue ~4.3x — against the **70-90x** the old entry estimated. **That
estimate was high by 4-5x**, and the remainder of the 221x is the
`R_ClipEdge`/`R_EmitCachedEdge` calls, which is essential x87 edge emit and
inadmissible under Decision 1.

Three things killed the candidates before a line was written:

- **Read the object first.** The obvious prize — the double `edge_p - r_edges`
  across 29 sites — is **already CSE'd by `-O3`**. `objdump -dr` shows both
  loads hoisted and a single duplicated `sub`, so the whole candidate is 0.9x
  the gate. One disassembly, no build.
- **The two hoists a reader would try next are logged as reverted**, with
  measurements.
- **`-O3` deletes a C probe that writes to a dead local.** It compiles to
  nothing and reports a clean zero. A C probe must accumulate into a reported
  external global.

The general lesson is recorded because this project has now made the mistake
twice: **an entry that says what would be needed is not a closure.** The
`edge-scan` entry named the dead-scratch probe as its own remedy and was filed as
closed anyway.

**Where the renderer actually stands.** The three unmeasured mega-pools are now
measured, and the third is the largest prize found so far:

| pool | before | after |
|---|---|---|
| `edge-scan` | "cannot be decomposed" | **78% mapped, 159.2x the gate**, sixteen named blocks |
| `renderface` | "no admissible hypothesis" | **priced at ~15.8x the gate** of C scaffolding |
| **`texture-spans` setup** | "dominated by x87 — a blind axis" | **2.37% of frame, 47x the gate, zero x87** |

`texture-spans` was the last closure resting on an unexamined premise, and the
premise was wrong. A dead-scratch probe at the head of the per-segment setup
priced **six instructions at 0.6186% of frame** — the full ~23-instruction integer
setup scales to **2.37%**, which is larger than anything `edge-scan` or
`renderface` offered. The 125 x87 instructions in `d_draw16.s` sit in the entry
divide, the `LNotLastSegment` advance and the tail path, **not in the setup**.

**And there is still no candidate for it.** Four reductions of that pool are
recorded with why each fails: the `advancetable` hoist is the wrong function's
kept win and cannot apply because the table changes with position-in-span; the
clamp fusion needs a scratch register and the copy costs what the fusion saves;
the `fistpl`/reload pair is architecturally forced because `FIST` has no register
destination; and segment widening is already amortised for the x87 half. The
setup is ~23 necessary DDA instructions.

**So the convergence claim is weaker than the previous three passes suggested, and
that is the honest state.** The largest addressable-looking pool in the renderer
has been located and quantified, and it has not yet yielded a change. `texture-spans`
is re-opened. Read the four dead candidates before proposing a fifth — and do not
re-close it on the x87 argument, which is now measured false.

## Decision 3 — price at the rate that matches the instruction mix

Added 2026-10-02, after a screening error produced a wrong answer in the right
direction. DOSBox-X's dynamic core charges **1.0 cycle per removed
instruction**, measured two independent ways that agree to 1.5%: a dead-scratch
probe of 24 straight-line integer ops (`imull`/`shrl`/`addl`) at 0.9956, and a
promoted hoist of register-only partial moves at 0.981. Both are recorded in
`ledger/INDEX.md`.

The mip-1 flat-path promotion implies a *different* rate, 0.66 cycles per
instruction, because its 13 instructions per row include two global loads and a
global store. **Screening a candidate at the wrong one of these is a 50% error,
and in this project it was:** the mip-1 flat-row index hoist was first priced at
0.029% and written off as under the gate, and actually measured **0.0353%** —
a clean bit-exact win that would have been declined. So:

1. Count the operations the change would **remove**.
2. Price them at **1.0 cycle per instruction** unless the removed instructions
   include memory operands, in which case 0.66 is the measured rate for that mix.
3. Use the result to rank likely experiments; 1,022.8 cycles/frame was the
   former 0.05% cutoff and is no longer a rejection threshold.

> **Item 2 is superseded by Decision 5 below: there is no 0.66 rate. Price
> everything at 1.0.** The reasoning that produced it is sound and the
> conclusion is wrong; see Decision 5 for the six measurements that overturn it.

The instruction-pricing results remain useful for ranking. Decisions 1 and 2
below now follow the no-floor acceptance policy above.

## Decision 4 — historical bundle example for sub-gate wins

Added 2026-10-02, the same day as Decision 3 and the reason the previous pass
found nothing. Under the policy at that time, the promotion gate applied to the
total baseline delta, so a 0.035% change could not be promoted on its own. That
magnitude floor was removed on 2026-10-20; any positive pooled mean from at
least three matched, uninstrumented runs per variant qualifies on its own,
however small or below the run spread. The three-change `surf8` bundle remains a useful
historical example of validating interacting changes together.

The `surf8` promotion is the historical worked example: `SurfaceBlockMip0Rows=unroll16`
(0.0132%), `SurfaceBlockMip1IndexHoist=hoist` (0.0353%), and a fully-flat
variant of the same path (0.0126%). Predicted 0.036716 s from the instruction
model, measured 0.036689 s — 0.07% error, with all three components validated
bit-exact against the framebuffer checksum.

What this does **not** license:

- Treating an estimated price as a measured speedup. The bundle cleared by 24%
  under the old floor, and each component is a genuine instruction removal
  rather than a scheduling accident.
- Bundling changes whose *interaction* is unverified. The three here touch
  disjoint code (mip-0 general loop, mip-1 flat row, mip-1 flat block entry), and
  the matched A/B is run on the whole bundle, not on the pieces.

## Decision 5 — there is no 0.66 rate; price everything at 1.0

Added 2026-10-02, from the `edge-scan` probe pass. Decision 3's instruction is
**wrong in its conclusion and right in its reasoning**, which is the worst kind
of error to leave standing, so it is replaced here rather than merely annotated.

The 0.66 figure came from `0.030368 s x 33.445 MHz / 1,543,048 = 0.658`. But
1,543,048 is the instruction count of the *promoted mip-1 flat path*, not of any
set of instructions a candidate would **remove**. The hoist that actually got
promoted removed 712,176 instructions and measured `0.020884 s` — **0.9807**.
The divisor was the wrong quantity, so the rate was never measured.

Six fresh dead-scratch probes across the whole instruction-mix range say the
discount does not track memory operands at all:

| probe mix | rate |
|---|---:|
| half global loads (`entry`) | 0.9957 |
| straight-line arithmetic, `imull`/`shrl`/`addl` (prior, ledger "**The Z-span integer probe**") | 0.9955 |
| register-only partial moves (prior, mip-1 hoist) | 0.9810 |
| both sort loops, loads and compares (`sort`) | 0.9883 |
| `addl` with a memory operand (prior, Z-span probe) | 0.9955 |
| load and step (`step`) | 0.9896 |
| **pure memory operand, nothing else** (`insert`) | **0.9740** |
| push/pop and five loads (`emit`) | 0.9842 |

Mean **0.9864**, range 0.9740–0.9957, spread **2.2%** across eight mixes. The
most memory-bound probe measured is 0.974, not 0.66.

**So: count removed instructions, multiply by 1.0, compare against 1,022.8
cycles/frame.** This is also the conservative direction — 1.0 is the *higher*
price, so it admits more candidates than 0.66 would, and the timedemo remains
the only thing that promotes anything.

> **Amended the same evening: 1.0 is right for assembly and carries roughly ±40%
> error for C, in both directions.** Eleven probes now exist, and they do not
> agree with each other across languages:

> | mix | measured rate |
> |---|---:|
> | nine assembly loops, serial dependency chains | 0.9740 – 0.9957 (mean 0.9866) |
> | straight-line C, instructions independent of surrounding work | **0.5439** |
> | C in a loop, probe sink a loop-carried dependency | **1.1917** |

> The rate is a **dependency property, not a constant**. Independent instructions
> issue into slots that were already idle and cost *less* than a cycle;
> serialised ones cost *more*. Since every candidate this project has screened
> is assembly, 1.0 remains the right screening number **for assembly** — but a
> static estimate on a *C* mix can overstate the prize by nearly half or
> understate it by a fifth, and must be measured before it is trusted. No price
> already recorded in this file was computed on a C mix, so nothing is wrong;
> what was wrong was assuming the error bar was zero.

> **Amended 2026-10-03, and this one is not a ±40% error bar — it breaks the rule for removals.**
> A twelfth probe was run against the `texture-spans` clamp-fusion candidate, and it separates two
> things this entry had merged:
>
> | what was measured | measured rate |
> |---|---:|
> | **cost of ADDING** instructions, eleven assembly loops | 0.9740 – 0.9957 (mean 0.9866) |
> | **cost of ADDING**, the clamp shape, a twelfth probe | **0.9880** |
> | **value of REMOVING** them, same shape, same path, same run | **0.0000** |
> | straight-line C, instructions independent of surrounding work | 0.5439 |
> | C in a loop, probe sink a loop-carried dependency | 1.1917 |
>
> The candidate removed at least 4,118,036 instructions — 4.1x the gate, 0.206% predicted — from the span16
> per-segment setup and measured **−0.000012 s**, i.e. nothing, at 0.3x the run spread, checksum-clean
> and verified compiled into the linked executable. A probe adding four instructions of the *identical*
> shape into the *identical* path was charged **0.988 cycles each** at 4,268x the clean spread. **All
> eleven prior probes, and this one, measured the cost of adding work. Not one measured what a removal
> is worth.**
>
> **Decision 5 is therefore narrowed, not overturned.** 1.0 remains the right number for
> *screening* a candidate against — it is the higher price, it admits more candidates, and the
> timedemo is still the only thing that promotes. But it is a validated statement about **added**
> work, and **the span16 setup is now a measured counter-example for removals**: a region can charge
> 0.988 per instruction added and 0.000 per instruction removed, because it is dependency-bound
> rather than throughput-bound.
>
> **The error is one-way, which is the actionable part.** It has only ever been shown to
> *over*-price, by at least 4.1x here. So **a model-priced rejection is not evidence that a candidate
> is slow — it is evidence that nobody has built it.** The single validated removal prediction in the
> repository is the mip-1 flat-row index hoist (0.036% predicted, 0.0353% measured, 2% error), in a
> region that happened to be throughput-bound. The `unroll16` and fully-flat promotions were measured
> directly and are unaffected.
>
> **Operationally: do not close a pool on an instruction count.** Closing requires an A/B, or a
> structural argument that does not rest on the count. Candidates that a model rejected on price are
> only correctly closed if the model cannot plausibly be wrong by the needed factor — the `surf8`
> screen (0.0006%–0.0126%) and the four dead texture-span reductions need a ~600x overstatement to
> reach the gate and remain closed. The large model-priced pools whose regions have never had a
> removal measured in them — `renderface`'s C scaffolding at 15.8x, the `edge-scan` map's biggest
> blocks — are the ones worth an A/B.

**Two consequences that are not optional bookkeeping:**

1. **The re-screen came back clean — verify, don't assume.** Recomputing every
   "closed on price" candidate at 1.0 reproduces its recorded figure exactly
   (A 0.0095%, B 0.0006%, D 0.0080%). The 0.66 was applied to precisely one
   candidate, C, in the screening table's first draft, and was corrected inside
   that same pass. **No recorded candidate price is wrong, and the bundle path's
   exhaustion does not rest on the bad rate** — it rests on measured figures for
   `GibTrail` (0.0119%) and `Turbulent8` (0.0344%), and on A/B/D being 5-83x
   under the gate at the *correct* rate. An earlier revision of this entry
   claimed the bad rate "was costing real candidates"; that overstated it, and
   the ledger entry records the correction.
2. **Decision 3's general warning survives and is now better founded.** The
   error it describes was real; it diagnosed the symptom (wrong rate) while
   being applied to the wrong quantity. What 0.66 actually cost was *standing
   guidance* — any future screening taking Decision 3 at face value would
   under-price by up to 50%. Where a rate is derived, check what the denominator
   counts.

## Decision 1 — the timedemo remains the performance authority, with no magnitude floor

The 0.05% DOSBox-X timedemo delta was the performance floor when this plan was
written. It was removed on 2026-10-20: any positive pooled mean from at least
three matched, uninstrumented timedemo runs per variant qualifies, even when
the gain is below run-to-run spread. The timedemo remains the performance
authority; a static 486 cycle model is not a performance result and cannot
promote a change.

The reasoning is the harness's own, recorded in `ledger/2026-09-29-harness-and-cost-model.md` under
"**What this harness can and cannot measure**" ("**Applying the rule.**" inside it):
DOSBox-X prices x87 at ~1.04 cy/op where a 486DX spends roughly 12, and models
neither fetch boundaries, write-buffer occupancy, nor 4 KB page aliasing. A
measured win is therefore sound, but a measured null only proves the emulator
could not see the cost.

DOSBox-X does not model x87 latency, fetch boundaries, write-buffer occupancy,
or 4 KB aliasing accurately. Those costs cannot be validated by a DOSBox-X
timedemo alone. The Z-span x87 prologue remains an unmeasured real-486
hypothesis, not a measured speedup; keep it distinct from improvements that
the pinned timedemo can verify.

`tools/486-cost-model.ps1` can help rank experiments across those axes. Its
output is a report, never a result or a reason to reject a small candidate.

## Decision 2 — price the prize before asking about the hit rate

Before proposing a cached or precomputed value:

1. Count the operations the change would **remove**, not the cache hits it
   would earn.
2. Divide by frames and use the estimated cycles as a ranking aid. The former
   **1,022.8 cycles/frame** cutoff was only the historical 0.05% floor; it is
   no longer a rejection threshold.
3. Check whether a cache hits, then measure any viable candidate with at least
   three matched, uninstrumented timedemo runs per variant. Promote any
   positive pooled mean, even when it is smaller than the run spread; no extra
   positive pair or minimum gain is required.

Four candidates died on this, and all four had quoted a ceiling from a bucket
share or a cost of churn:

| Candidate | Quoted | Measured | Why it died |
| --- | --- | --- | --- |
| E0, per-face precompute | ~0.10–0.14% | 3.4% hit rate | ceiling assumed 100% reuse |
| E4, surface-cache churn | 2.61% | 0 of 8,886 | no such surfaces exist in the workload |
| bmodel frustum `FIXME` | 1.5–2.5% | ~5x under gate | 13.1 face tests per frame |
| `Turbulent8` setup | 2.27% | 0.0344% addressable | chunk setup is a running accumulation |

Two more were closed on the old price rule in 2026-10-02, from counters rather
than estimates: the **mip-2** and **mip-3** horizontal-flat surface blocks at
0.0095% and 0.0006%, and the **fully-flat per-block index hoist** at 0.0080%.
Those prices no longer exclude a viable candidate; use a matched A/B before
calling any of them faster or slower. The
remaining item on that axis, the **mip-1 flat-row index hoist**, was built and
measured at **0.0353%** — real, bit-exact, reproducible, and below the gate *on
its own*. Under the old policy it was rejected in isolation, then **promoted at
0.0620% as part of the Decision 4 bundle**. The earlier standalone measurement
also qualifies under today's no-floor policy, and the optimized path is already
active in the working source. An earlier revision of this paragraph still read
"so it is rejected" without the qualifier; that was stale. Together with the
unit-stride span premise (0 pixels of a 400,000-pixel requirement) that closes
`texture-spans` on the admissible axis by measurement as well.

### Historical price-only closures (2026-10-02)

Decision 4 has no list in the ledger yet, which is a gap: the plan asserts one
exists and it did not. Here it is, as of 2026-10-02. Every entry is bit-exact,
independently priced, and below the old gate. Price alone no longer closes a
viable candidate; use a matched timedemo to learn whether it improves FPS.

| closure | price | state |
|---|---:|---|
| `SurfaceBlockMip0Rows=unroll8` | 0.0094% | **obsolete** — a strictly worse variant of the promoted `unroll16`; nothing to bundle with |
| `GibTrailHorizontalIntegration=skipzero` | 0.0119% | **live, but outside the assembly-only scope:** the selector changes a C routine |
| mip-2 horizontal-flat block | 0.0064% initially claimed | **reopened 2026-10-21; parity-clean assembly reimplementation measured 0.00183215% slower** in a strict three-run A/B; see [`ledger/2026-10-21-surf8-mip2-horizontal-flat-rejected.md`](ledger/2026-10-21-surf8-mip2-horizontal-flat-rejected.md) |
| mip-3 horizontal-flat block | 0.0006% estimated | **measured and rejected:** matched 3-run diagnostic A/B was 0.0004516% slower; see [`ledger/2026-10-20-mip3-flat-block-rejected.md`](ledger/2026-10-20-mip3-flat-block-rejected.md) |

`skipzero` was the only live selector in this old bundle list, but it changes a
C routine and is outside the current assembly-only optimization scope.

Two probes measured the last two, and both are worth copying rather than
reinventing:

- **Price the code you intend to remove, by duplicating it into scratch
  variables and discarding the result.** Both probe builds render bit-identical
  to control, so the probe is a measurement rather than a guess. Do *not*
  neutralise the inputs to make the work disappear: forcing `z = 1.0f` to remove
  the divides removes what the divides produce, which broke the water and
  faulted the run.
  **Two refinements from the 2026-10-02 `edge-scan` pass, both learned by faulting
  a run first.** A dead register is not a safe address — it must also be
  *initialised*; `%esi` looked dead in `R_InsertNewEdges`' search loop but is not
  written until the second probe, and reading through it crashed the timedemo.
  And on mutating code, duplicate the compute and **never the store**.
- **After any source edit, force a rebuild — or rather, you no longer have to.**
  ~~`../tools/timedemo-dos.ps1:272` only builds when the benchmark executable is
  absent, and that path is keyed by selector profile alone, so an edit is
  silently ignored and the previous binary is measured.~~
  **(Corrected: the runner now fingerprints all 163 sources plus the resolved
  selectors and rebuilds on a mismatch, or throws under `-SkipBuild` —
  `timedemo-dos.ps1:319-405`. Verified twice in one session. Passing `-Clean` to
  `build-dos.ps1` remains sound advice but is no longer required for
  correctness.)**
