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

## Active resolution target

Per the user's direction on 2026-10-29, optimize and qualify the renderer at
320x200 only. Higher resolutions are outside the active 486 performance scope
because they are too slow for the target class of hardware.

### BSP plane-dot caches and shared-surface stamp suppression rejected (2026-11-04)

The shared-surface stamp check preserved the instrumented color/Z stream but
lowered the three-run uninstrumented mean from 8.872651667 to 8.871082 FPS.
A per-plane dot cache reused the existing spare plane allocation, and a direct
two-bit per-plane classification cache reused padding bytes. Both passed the
full i486 audit but lowered mean FPS: 8.871216667 and 8.866939, respectively,
against the 8.872651667 control. A shared-surface stamp check also regressed
the mean to 8.871082 FPS. Their saved uninstrumented streams varied at frames
727-731, a window that also varied in repeated control color streams. All three
changes were removed. See the [BSP cache and stamp rejection ledger](ledger/2026-11-04-bsp-plane-dot-cache-and-surface-stamp-rejected.md).

### Active-edge screen buckets and PVS surface epoch cache rejected (2026-11-04)

A 16-pixel active-edge predecessor index still changed two color frames after
its search was narrowed to long crossings, and increased pushback-search work
from 96,243 to 120,219 iterations. Moving leaf surface marks into the PVS pass
changed four color frames because PVS membership does not include the
per-frame frustum filter used by the BSP walk; it also increased rendered-face
calls and BSP time. Both candidates passed the complete strict i486 audit but
failed exact color parity, so their source changes were removed. See the
[edge-bucket and PVS cache rejection ledger](ledger/2026-11-04-edge-bucket-and-pvs-surface-cache-rejected.md).

### Active-edge scanline predecessor finger rejected (2026-11-04)

A scanline-local predecessor finger selected only 467 hints across 95,759
pushback-search iterations, removing just 484 iterations against the 96,243
control count. Its uninstrumented checksum run differed from each control color
stream at 288 of 970 records (frames 32-948), despite retaining the final
checksum. The complete strict i486 audit passed, but no timing A/B was run.
See the [predecessor-finger rejection ledger](ledger/2026-11-04-edge-pushback-finger-rejected.md).

### World-span depth hierarchy for alias occlusion rejected (2026-11-04)

A coarse hierarchy built from existing world and brush surface spans rejected
some alias models but failed exact color parity in both tested tile layouts.
The 8x8 version changed 51 of 970 frame checksums; the refined 32x4 version
changed 27. All recorded Z checksums and both final framebuffer checksums
matched. The strict i486 audits passed, but the candidate is removed. See the
[world-span HZB rejection ledger](ledger/2026-11-04-world-span-hzb-alias-rejected.md).

### Lazy tile-min hierarchy for alias-span occlusion rejected (2026-11-05)

A screen-horizontal tile-min cache queried long alias spans against the existing
Z buffer, rejecting 103 of 39,990 eligible spans at 8-pixel tiles and 140 at
4-pixel tiles. Both profile candidates differed from the no-cache profile at
frame 83 in color and Z, despite matching final checksums; exact per-frame
parity is therefore unproven. The helper also increased instrumented alias-span
self time. With at most 0.35% of queries rejected and no parity-clean candidate,
no uninstrumented timing or release ISA gate was run. The code was removed. See
the [alias-span tile-min hierarchy ledger](ledger/2026-11-05-alias-span-tile-depth-hierarchy-rejected.md).

### D_DrawZSpans per-row depth-term cache rejected (2026-11-05)

A 200-row cache for the rounded `v*d_zistepv` term had a 29.1% hit rate across
1,413,428 Z spans, but added a row bound and tag lookup to each span. Three
matched uninstrumented DOSBox-X runs averaged 16.328563333 FPS versus
16.388064667 FPS for control (-0.363%). All recorded framebuffer and Z
checksum rows matched in the instrumented parity replay, and the complete strict
i486 audit passed. The cache and profiling counters were removed. See the
[Z-span row-term cache rejection ledger](ledger/2026-11-05-zspan-row-term-cache-rejected.md).

### R_RenderFace clip-plane order reorder rejected (2026-11-04)

An isolated `1,0,2,3` view-plane chain candidate differed from its matched
packed-BSP control at **591 of 970 fixed-step frame checksums**, beginning at
frame 0. Both runs ended at `1047377823`, but the frame-695 PCX captures also
differed. No timing A/B was run; the candidate fails exact parity. See the
[clip-plane order ledger](ledger/2026-11-04-renderface-clipplane-order-rejected.md).

### R_RenderFace prelinked all-mask clip chains rejected (2026-11-04)

A scratch candidate prebuilt linked clip-plane chains for all 15 nonempty masks
and selected a head pointer in `R_RenderFace_asm486`. Two fixed-step candidate
replays were identical to each other but differed from the matched control at
**436 of 970 frames**, starting at frame 2. Both ended at checksum
`1047377823`, while the captured frame 695 differed. The strict i486 audit
passed, but the candidate fails exact parity; its two uninstrumented timing
groups are invalid as performance evidence. See the
[all-mask chain rejection ledger]
(ledger/2026-11-04-renderface-prelinked-all-mask-chains-rejected.md).

### R_RenderFace clip-plane argument hoist promoted (2026-11-04)

`R_RenderFace_asm486` now stores the face's constant `R_ClipEdge` plane
argument once before entering the edge loops. Three matched uninstrumented
runs improved mean FPS from **16.378047** to **16.388068
(+0.010021 FPS, +0.0611856%)**. All samples favored the candidate; all 970
fixed-step checksums and the captured frame 695 PCX matched byte-for-byte. The
complete strict i486 audit passed. See the
[clip-argument hoist ledger]
(ledger/2026-11-04-renderface-cliparg-hoist-promoted.md).

### RenderFace outgoing argument frame promoted (2026-11-04)

`R_RenderFace_asm486` reserves 12 bytes for outgoing `R_ClipEdge` arguments,
replacing per-call stack pushes and cleanup. Three matched uninstrumented runs
improved mean FPS from **16.377704** to **16.378047
(+0.000343 FPS, +0.002094%)**. Fixed-step checksums and the captured frame 695
PCX were byte-identical; the complete strict i486 audit passed. See the
[outgoing-argument ledger]
(ledger/2026-11-04-renderface-outgoing-argument-frame-promoted.md).

### Span16 full-segment endpoint conversion order promoted (2026-11-04)

The full-segment endpoint path stores T before S, removing an x87 exchange
without changing operands or rounding. Three matched uninstrumented runs
improved mean FPS from **16.377703333** to **16.377710333
(+0.000007 FPS, +0.0000427%)**. Exact fixed-step and captured-frame parity and
the complete strict i486 audit passed. See the
[endpoint-order ledger]
(ledger/2026-11-04-span16-segment-endpoint-order-promoted.md).

### Span16 initial-span S/T product order promoted (2026-11-04)

The initial and same-row setup paths calculate T before S. Four uninstrumented
runs per variant, including the first low-rate pair, improved pooled mean FPS
from **15.48214725** to **15.4929885
(+0.01084125 FPS, +0.07002%)**. The recorded experiment reports exact fixed-step
parity and a passing strict i486 gate. Its separate replay paths and audit
counts were not recovered while reconciling the retained outputs. See the
[initial-span product-order ledger]
(ledger/2026-11-04-span16-initial-span-product-order-promoted.md).

### R_GenerateSpans trailing-to-leading continuation tail-jump promoted (2026-11-04)

The both-sides edge path now pushes `Lgs_leading_body` as `TrailingEdge`'s
return address and jumps into the helper, replacing `call TrailingEdge` plus a
separate jump. A matched three-run uninstrumented A/B produced a positive pooled
mean of **16.365686333 FPS** for the candidate against **16.323727 FPS** for
control (**+0.041959333 FPS, +0.2570%**). One control run at **16.239810 FPS**
was a clear hitch; excluding it leaves the candidate only **0.000000833 FPS**
ahead of the two clean control runs, so the causal effect is uncertain. The
candidate median is 0.000017 FPS below control. It qualifies under the current
any-positive pooled-mean rule, with the hitch retained in the recorded pool.
All six runs rendered 969 frames and ended at checksum `1047377823`. The
candidate's 970-frame fixed-step checksum stream and captured frame 695 were
byte-identical to control; the complete strict i486 audit passed. See the
[trailing-to-leading continuation ledger]
(ledger/2026-11-04-r-genspans-trailing-to-leading-tail-jump-promoted.md).

### Assembly BSP continuation-state packing promoted (2026-11-04)

The assembly BSP walk now packs each parent continuation's side and resume phase
into one state word, shrinking the record from 24 to 20 bytes. Three matched,
uninstrumented 320x200 DOSBox-X runs improved mean FPS from **16.365682333** to
**16.365693333 (+0.0000672%)**. The gain is smaller than either variant's
run-to-run spread, but the current acceptance rule admits every positive
matched mean. All six runs rendered 969 frames with checksum `1047377823` and
matching event traces. The 970-record fixed-step checksum streams were
byte-identical, and the complete strict i486 audit passed with zero exemptions.
See the [packed-continuation ledger]
(ledger/2026-11-04-bsp-walk-packed-continuation-state-promoted.md).

### R_RenderFace prelinked full-mask chain promoted (2026-11-03)

The assembly frustum transform now refreshes a private, already-linked copy of
the four clip planes once per frustum update. `R_RenderFace_asm486` reuses that
chain for mask 15; partial masks and C frustum-transform builds retain their
existing path. Three uninstrumented 320x200 DOSBox-X runs improved mean FPS
from **16.491695** to **16.495431667 (+0.0226579%)**. All six runs rendered 969
frames with checksum `1047377823`; a separate replay matched all 970 recorded
per-frame checksums and the frame-482 PCX byte-for-byte. The full strict i486
audit passed. See the [prelinked-chain ledger]
(ledger/2026-11-03-renderface-prelinked-fullmask-chain-promoted.md).

### Assembly BSP frame-count snapshot promoted (2026-11-03)

The assembly BSP walker now snapshots `r_framecount` once per traversal,
removing the per-node global reload and the frame-count word from each parent
continuation record. Three matched uninstrumented 320x200 DOSBox-X runs improved
mean FPS from **16.349283667** to **16.349305333 (+0.0001325%)**. All six runs
rendered 969 frames and ended at checksum `1047377823`. A separate fixed-step
replay using `host_framerate 0.0783` matched all 970 per-frame checksums
byte-for-byte. The complete strict i486 audit passed with zero above-i486,
unknown, or exempt instructions. See the [BSP frame-count ledger]
(ledger/2026-11-03-bsp-framecount-snapshot-promoted.md).

### Z-span monotone constant-depth runs promoted (2026-11-03)

When the guarded monotone start and end depths share an upper 16-bit word,
`D_DrawZSpans` now fills the span with that value using aligned dword stores.
The change passed 169 exact C/assembly cases, all 970 per-frame checksums with
notifications disabled, an exact captured-frame comparison, and the complete
strict i486 gate. Three uninstrumented 320x200 runs improved the control median
from **16.464303** to **16.484395 FPS (+0.1220%)**; aligned `rep stosl` also
improved the intermediate word-store variant by **0.0256%**. The exact samples
and the control hitch are recorded in the [Z-span constant-depth ledger]
(ledger/2026-11-03-zspan-constant-depth-runs-promoted.md).

### R_ClipEdge world vertex projection cache withdrawn (2026-11-03)

The cache's original **+0.0529% DOSBox-X result** used the explicit
`ZSpanStartSchedule=nofxch` path and does not qualify the restored `control`
default. During control-schedule requalification, two paired runs produced a
repeatable one-frame checksum difference at index 412 (candidate
`542392344`, no-cache `3788779729`). A later fixed-cadence rerun matched all 964
post-warmup checksums and the captured frame exactly, so the earlier divergence
remains unexplained. Because parity was inconsistent across invocations, the
projection cache has been removed from the active renderer. Its measured gain
is not accepted. See the [projection-cache withdrawal ledger]
(ledger/2026-11-03-r-clipedge-projection-cache-withdrawn.md).

### Z-span no-FXCH default restored to control (2026-11-03)

The faster no-FXCH start schedule previously became the omitted i486 default.
On the current source, a strict i486 comparison of default `control` with
explicit `nofxch` rendered 969 frames in each run and ended with the same
checksum, but 37 of 964 post-warmup frame checksums differed (frames 99–773).
The frame-99 captures differed at 25 of 64,000 pixels; the palette matched,
mean absolute channel error was 0.004193, and maximum channel error was 60.
After the user reported visible rendering artifacts, the default is restored
to pixel-exact `control`; the faster schedule is available only through
explicit `-ZSpanStartSchedule nofxch`. See the [historical Z-span schedule
ledger](ledger/2026-10-31-zspan-no-fxch-promoted-and-renderface-no-clip-rejected.md).

### Z-span row recurrence rejected (2026-11-03)

An instrumented census found that 97.67% of linked surface spans continue on
the previous row, suggesting that `v * d_zistepv` could be carried with one
x87 subtraction. The candidate changed 38 per-frame checksums in `demo1`
(first changed frame 99, last 733), despite matching the final checksum and
frame-50 capture. It was rejected; the exact-image condition is not met. See
the [row-recurrence ledger](ledger/2026-11-03-zspan-row-recurrence-rejected.md).

### Span16 same-texel endpoint test measured (2026-11-03)

A profile-only census found **0 of 2,059,043** full 16-pixel segments whose
starting and clamped endpoint coordinates selected the same texel in both
axes. This conservative repeated-texel fast-path condition has no hits in the
measured `demo1` workload, so no branch was added. The single instrumented run
kept the expected final checksum, but does not establish pixel-by-pixel parity
or performance. See the
[same-texel endpoint census ledger](ledger/2026-11-03-span16-same-texel-endpoint-census.md).

### Alias constant-depth full-occlusion rejection rejected (2026-11-02)

An exact Z scan can skip a long alias span only when its horizontal inverse-
depth step is zero and every existing Z value is strictly nearer. The
candidate preserved the frame-50 PCX exactly and all 970 per-frame Z hashes,
but repeated-control color hashes showed wall-clock-dependent output. In three
uninstrumented 320x200 DOSBox-X runs, the scan was **0.011920 FPS (0.0724%)
slower** than control, so it was removed. The full i486 audit passed. See the
[alias span occlusion ledger](ledger/2026-11-02-alias-span-constant-depth-reject-rejected.md).

### Client update bit-count loop removal promoted (2026-10-30)

`CL_ParseUpdate` no longer scans all 16 update bits to increment the unread
`bitcounts` array. Three matched 320x200 runs averaged **16.328159333 FPS**,
**+0.006439 FPS (+0.0394505%)** over control. All runs retained 969 frames,
checksum `1047377823`, and identical recorded event traces; the full linked
i486 gate passed. See the [client parser ledger](ledger/2026-10-30-cl-parseupdate-bitcounts-promoted.md).

### RenderWorld assembly selector rejected (2026-10-30)

The C and assembly `R_RenderWorld` selectors were the only build difference.
Three uninstrumented 320x200 pairs averaged **16.329198333 FPS** for C and
**16.329114333 FPS** for assembly (**-0.000084 FPS, -0.0005144%**). Assembly
lost all three pairs; all six runs rendered 969 frames with checksum
`1047377823`, and both builds passed the full i486 gate. The C selector remains
the default. See the [RenderWorld selector ledger](ledger/2026-10-30-render-world-asm-timing-rejected.md).

### RenderFace empty-clip fast branch rejected (2026-10-30)

Adding a `testl`/branch to skip four clip-plane checks when no low clip bits
were set preserved the 320x200 output and passed the strict i486 executable
gate, but five alternating uninstrumented pairs averaged **16.3196218 FPS**
against **16.3217274 FPS** control (**-0.0021056 FPS, -0.0129006%**). All runs
rendered 969 frames with checksum `1047377823`; two correctly configured
visual captures passed golden and repeated-frame checks. The added decision cost
more than it saved here, so the shortcut was reverted. See the [RenderFace
empty-clip ledger](ledger/2026-10-30-renderface-empty-clipflags-fastpath-rejected.md).

### Non-bmodel edge-sort 10-vs-12 unroll recheck (2026-10-30)

The ten-comparison candidate preserved comparison order and passed all five
969-frame checksum checks, but averaged **16.3217204 FPS** against **16.3217212
FPS** for the twelve-comparison control (**-0.0000008 FPS, -0.00000490%**).
The paired spread was -0.000030 to +0.000024 FPS. This is no measurable gain;
leave the twelve-comparison worktree path in place. The candidate's renderer
ISA audit was skipped after the non-positive mean. See the [edge-sort unroll
ledger](ledger/2026-10-30-edge-sort-unroll-10-vs-12-rejected.md).

### Non-bmodel edge-sort sixteen-continuation trial rejected (2026-10-30)

Adding two comparisons to the promoted fourteen-continuation `Lsortloopnb`
group averaged **16.321720 FPS** against **16.321713667 FPS** for a fresh
fourteen-continuation control (**+0.000006333 FPS, +0.00003880%**). The
candidate's 0.000064 FPS spread exceeded the mean delta. All six runs retained
969 frames and checksum `1047377823`; both complete i486 audits passed. The
candidate was restored because the result did not establish a measurable gain.
See the [sixteen-continuation trial ledger](ledger/2026-10-30-edge-sort-nonbmodel-sixteen-continuation-rejected.md).

### Non-bmodel edge-sort fifteen-continuation trial rejected (2026-10-30)

Adding one comparison to the promoted fourteen-continuation `Lsortloopnb`
group averaged **16.328151667 FPS** against **16.328159333 FPS** for its
matched control (**-0.000007667 FPS, -0.00004696%**). All six runs rendered
969 frames with checksum `1047377823` and identical recorded event traces; the
candidate passed the full i486 audit. The source was restored because the mean
was negative and below both sample spreads. See the [fifteen-continuation
trial ledger](ledger/2026-10-30-edge-sort-nonbmodel-fifteen-continuation-rejected.md).

### Non-bmodel edge-sort thirteen-continuation trial rejected (2026-10-30)

Reducing the retained fourteen-continuation `Lsortloopnb` body by one ordered
comparison averaged **16.328471 FPS** against **16.328474667 FPS** control
(**-0.000003667 FPS, -0.00002246%**). All six runs retained 969 frames, final
checksum `1047377823`, and matching event traces. The isolated timing build
skipped ISA audit; the candidate was restored after the negative mean. See the
[thirteen-continuation trial ledger](ledger/2026-10-30-edge-sort-nonbmodel-thirteen-continuation-rejected.md).

Adding two comparisons to the retained non-bmodel sort group was also rejected.
The three-run candidate averaged **16.321728333 FPS** against **16.321726000
FPS** for control (**+0.000002333 FPS, +0.0000143%**), below both sample
spreads. All six runs retained 969 frames and checksum `1047377823`; the
candidate passed the complete i486 gate. The source was restored without a
fixed-step frame-stream or PCX comparison because timing showed no measurable
gain. See the [current-source sixteen-comparison recheck ledger](ledger/2026-10-30-edge-sort-nonbmodel-sixteen-current-source-recheck-rejected.md).

### 320x200 framebuffer page-offset pad (2026-10-30)

`VGA_FreeAndAllocVidbuffer` reserves 16 extra bytes for a single-buffer
320x200 mode and moves the RAM framebuffer start by 16 bytes, changing its 4 KB
page offset from 1,024 to 1,040 while preserving 16-byte alignment. The
surface-cache base remains unchanged. The strict DOSBox-X candidate averaged
**16.329118 FPS** against **16.329114333 FPS** for control
(**+0.000003667 FPS, +0.00002246%**); both three-run sets retained 969 frames
and checksum `1047377823`. The delta is below the sample spreads but meets the
current positive-mean rule. All linked object, executable, startup, and DPMI
provider i486 gates passed. DOSBox-X does not model the page-conflict mechanism
that motivated the layout change, so its physical-486 benefit is unverified.
See the [framebuffer page-offset ledger](ledger/2026-10-30-vga-framebuffer-page-offset-pad-promoted.md).

### Static surface-cache hit leaf entry recheck promoted (2026-10-31)

Moving the common static-texture cache-hit probe ahead of `D_CacheSurface`'s
saved-register and 52-byte frame setup gained **0.003130 FPS (+0.019160%)** in
three matched uninstrumented 320x200 runs: **16.339184667 FPS** versus
**16.336054667 FPS** control. All runs rendered 969 frames, ended at checksum
`1047377823`, and recorded matching timedemo event traces. For exact frame
parity, the repository's `host_framerate 0.0783` autoexec was applied: the
control checksum stream matched two candidate streams across all 970 rendered
frames, and frame 169 PCX files were byte-identical. The complete linked i486
gate passed 314,334 executable instructions with zero above-i486, unknown, or
exempt instructions; startup and provider proofs also passed with zero
exemptions. See the [static-hit leaf entry ledger](ledger/2026-10-31-surface-cache-hit-leaf-entry-promoted.md).

The earlier Oct 30 leaf-path result below remains historical: its raw timedemo
frame stream lacked the deterministic render-validation autoexec used in this
recheck.

### Surface-cache leaf hit fast path rejected (2026-10-30)

A leaf return for static-texture surface-cache hits averaged **16.325488 FPS**
against **16.321713667 FPS** control (**+0.003774333 FPS, +0.0231%**) across
three uninstrumented 320x200 runs. The i486 ISA audit passed, and both builds
retained the final checksum `1047377823`. However, 34 of 970 per-frame
checksums differed in the matched capture runs. Frame 500 was byte-identical,
but that does not establish full parity; the source change was restored. See
the [surface-cache leaf fast-path ledger](ledger/2026-10-30-surface-cache-hit-fastpath-rejected.md).

### Surface-cache hit pointer in EBX, current-source recheck retained (2026-10-30)

Keeping the cache pointer in `%ebx` through the hit-key checks gained **0.000315333
FPS (+0.0019312%)** in three matched 320x200 runs on the current source tree.
All six timedemos retained the 969-frame final checksum and matching event
traces. A separate fixed-step comparison matched all 970 per-frame checksums;
the captured frame was byte-identical to control and passed the committed golden
comparison. The full linked i486 audit passed. This is a recheck of the
2026-10-29 register schedule against a changed current-source baseline; its older
negative result remains documented, while this current-source version is
retained. See the [EBX current-source recheck ledger](ledger/2026-10-30-surface-cache-hit-ebx-current-recheck-promoted.md).

### Surface-cache hit-key order rejected (2026-10-30)

Checking the cached texture pointer before `cache->dlight` averaged **16.328385333
FPS**, versus **16.328474667 FPS** for the retained order (**-0.000089333 FPS,
-0.000547102%**). All six 320x200 runs retained the 969-frame final checksum
and event traces, and the full i486 audit passed. The reorder was reverted. See
the [key-order ledger](ledger/2026-10-30-surface-cache-key-order-rejected.md).

### Surface-cache hit pointer register reuse (2026-10-29)

Keeping the cache pointer in `%edi` across `R_DlightContributes` passed the
320x200 checksum and complete i486 gates. Two parity screens pooled to a small
positive delta of **0.000006333 FPS (+0.0000388%)**, but the matched strict
three-run means were both **16.321711333 FPS**. The strict comparison has no
positive gain, so the stack save/restore remains. See the
[cache-pointer register ledger](ledger/2026-10-29-surface-cache-hit-edi-pointer-strict-rejected.md).

### Z-span row-index load interleave (2026-10-29)

In both `D_DrawZSpans` loops, the row-table index load now sits between the
coordinate `FILD` operations, without changing the x87 arithmetic sequence.
The strict 320x200 candidate averaged **16.321714333 FPS** against **16.321711333
FPS** control (**+0.000003 FPS, +0.00001838%**). All six strict runs retained
969 frames and checksum `1047377823`; the complete linked i486 ISA audit passed.
Two full visual runs passed the golden comparison, and both 970-entry frame
checksum streams exactly matched the control. See the
[Z-span row-index ledger](ledger/2026-10-29-zspan-row-index-load-interleave-promoted.md).

### Z-span row-table lookup before second FILD rejected (2026-10-30)

Moving the `zspantable[espan_t_v]` lookup before the second coordinate `FILD`
in both positive- and negative-gradient Z-span loops passed the complete i486
gate and retained all six 969-frame final checksums. The candidate mean was
**16.321718333 FPS**, **0.000016 FPS slower (-0.0000980%)** than the fresh
control mean of **16.321734333 FPS**. The lookup returned to its previous
position. See the [Z-row lookup ledger](ledger/2026-10-30-zspan-row-table-before-fild-rejected.md).

### Z-span pair add schedule, current-source recheck rejected (2026-10-30)

Moving the independent second inverse-depth add between `SHLD` and `ROR`
averaged **16.328468667 FPS**, versus **16.328474667 FPS** for the retained
current-source control (**-0.000006 FPS, -0.0000367%**). All six runs retained
the 969-frame final checksum and event traces; the complete i486 audit passed.
The change was reverted. This rechecks a similar 2026-10-21 schedule against
the current baseline; see the [current-source ledger](ledger/2026-10-30-zspan-pair-add-schedule-rejected.md).

### Z-span 64-pixel nonnegative group rejected (2026-10-30)

Doubling the nonnegative depth loop group from 32 to 64 pixels averaged
**16.326761 FPS** versus **16.328474667 FPS** control (**-0.001713667 FPS,
-0.01049496%**). Although all six runs ended at checksum `1047377823`, exact
per-frame comparison found 149/970 mismatches and frame 169 changed 18,825 of
64,000 pixels. The candidate fails visual parity and was reverted; its timing
is diagnostic only. The complete linked i486 gate passed. See the [64-pixel
Z-span ledger](ledger/2026-10-30-zspan-unroll-64-rejected.md).

### Span16 tfrac load between address store and cache-width add rejected (2026-10-30)

Moving the `tfracf` load between the `advancetable+4` store and `cachewidth`
add in both setup arms averaged **16.328472 FPS**, **0.000002667 FPS slower
(-0.00001633%)** than the retained control. All six runs ended at checksum
`1047377823` with matching event traces; the captured frame-169 images matched
pixel-for-pixel. Repeated control captures themselves differed at 18
intermediate frame checksums, so the 19 candidate/control checksum differences
do not isolate a candidate-caused rendering change. The candidate passed the
complete linked i486 gate and was reverted for its negative mean. See the
[Span16 setup-schedule ledger](ledger/2026-10-30-span16-tfrac-between-store-width-rejected.md).

### Span16 x87/integer load scheduling (2026-10-29)

In `D_DrawSpans16`, both coordinate `FILD` operations now precede the
independent row, destination, count, and continuation loads. These loads run
before the dependent x87 arithmetic while preserving its stack and operation
order. The strict candidate averaged **16.321723 FPS** against the original
schedule's **16.320915667 FPS** (**+0.000807333 FPS, +0.004947%**), and improved
the prior paired-`FILD` schedule by **0.000013667 FPS (+0.00008373%)**. All nine
runs rendered 969 frames with framebuffer checksum `1047377823`; the complete
linked i486 audit passed. See the [FILD-window setup ledger](ledger/2026-10-29-span16-fild-window-setup-promoted.md)
and the [paired-`FILD` predecessor ledger](ledger/2026-10-29-span16-x87-load-schedule-promoted.md).

A follow-up that placed `tadjust` between the two `FILD` loads passed checksum
and ISA gates but averaged **16.321708 FPS**, 0.000001333 FPS below the paired-`FILD`
schedule. It was rejected; see the [spaced-schedule ledger](ledger/2026-10-29-span16-x87-load-spaced-rejected.md).

A split schedule that moved the next-span push and `sadjust` load back after
the initial `FDIV` averaged **16.321720333 FPS**, 0.000002667 FPS below the
current schedule. It passed screen parity but was rejected without a strict
audit; see the [split-schedule ledger](ledger/2026-10-29-span16-split-fdiv-overlap-rejected.md).

Moving only the T-adjust load between the S- and T-endpoint FISTPs screened
**0.000003333 FPS faster** than a fresh control recheck, but the strict
candidate averaged **16.321712667 FPS**, **0.000001667 FPS below** that current
control and **0.000010333 FPS below** the original strict control. The complete
i486 audit and exact checksum gates passed; the negative strict mean rejects
the schedule. The original load placement remains active. See the
[T-adjust endpoint-window ledger](ledger/2026-10-29-span16-tadjust-between-endpoint-fistps-rejected.md).

Moving the `snext` reload to immediately after its FISTP, ahead of the T-endpoint
multiply/FISTP, averaged **16.321709667 FPS** against **16.321714333 FPS** for
the fresh control recheck (**−0.000004667 FPS, −0.00002859%**). All runs kept
969 frames and checksum `1047377823`; the strict audit was skipped after the
negative mean. The reload remains after both endpoint FISTPs. See the
[`snext` reload ledger](ledger/2026-10-29-span16-snext-reload-during-t-endpoint-rejected.md).

Two carry-table preload schedules also passed the 320x200 checksum screen but
lost to the current schedule: loading the selected base after the S fractional
add averaged **16.262853333 FPS** (**−0.360683%**), while moving the store and
load before the S add averaged **16.304894333 FPS** (**−0.103106%**). Both
preserved all 969 frames and checksum `1047377823`; neither received a strict
ISA audit after its timing regression. The indexed memory-operand ADC remains
active; see the [carry-table schedule ledger](ledger/2026-10-29-span16-carry-table-preload-schedules-rejected.md).

Moving the U-coordinate load before the row-table lookup also passed the
320x200 checksum screen but averaged **16.321715 FPS**, **0.000008 FPS
(-0.000049%)** below the strict control. It was reverted without a strict ISA
audit; see the [U-load schedule ledger](ledger/2026-10-29-span16-u-load-before-rowbase-rejected.md).

Moving the independent `tfracf` load ahead of the address-table store and
cache-width add also passed the 320x200 checksum screen but averaged
**16.321717 FPS**, **0.000013333 FPS (0.00008169%)** below the fresh parity
control. All runs retained 969 frames and checksum `1047377823`; the full
strict i486 audit was skipped after the negative mean. The original load order
was restored. See the
[`tfracf` load ledger](ledger/2026-10-29-span16-tfrac-load-hoist-rejected.md).

Moving the eight low-byte texture fetches into the gap between the S fractional
add and indexed ADC also passed the 320x200 checksum screen, but averaged
**16.321708667 FPS** against **16.321723000 FPS** control (**−0.000014333
FPS, −0.0000878%**). All runs retained 969 frames and checksum `1047377823`;
the strict ISA audit was skipped after the negative mean. The original fetch
placement was restored; see the [low-byte fetch schedule ledger](ledger/2026-10-29-span16-low-byte-fetch-in-sadd-adc-gap-rejected.md).

Rechecking `TextureSpanLoadOrder=loadfirst` against the promoted FILD-window
control averaged **16.321716667 FPS** against **16.321723000 FPS**
(**−0.000006333 FPS, −0.0000388%**). All six runs retained 969 frames and
checksum `1047377823`; the parity-only candidate skipped the strict ISA audit
after its negative mean. `control` remains the default; see the
[FILD-window loadfirst recheck ledger](ledger/2026-10-29-span16-loadfirst-fild-window-recheck-rejected.md).

The compact `TextureSpanStores=loop` variant replaced the unrolled packed-word
stores with per-byte `STOSB` loops. Its 320x200 parity screen averaged
**15.676116667 FPS**, **0.645606333 FPS (3.9555%)** below the strict word-store
control. All runs retained 969 frames and checksum `1047377823`; the strict
ISA audit was skipped after the large timing regression. The loop-store
selector remains rejected; see the [loop-store ledger](ledger/2026-10-29-span16-loop-stores-rejected.md).

The unrolled `TextureSpanStores=byte` variant also regressed, averaging
**16.203579333 FPS**, **0.118143667 FPS (0.7238%)** below the strict word-store
control. All runs retained 969 frames and checksum `1047377823`; the strict
ISA audit was skipped after the negative mean. The packed word-store schedule
remains active; see the [byte-store ledger](ledger/2026-10-29-span16-byte-stores-rejected.md).

Aligning `LNotLastSegment` to a 16-byte boundary tested the 486 instruction
fetch path for repeated full segments. Its 320x200 parity screen averaged
**16.255337667 FPS**, **0.066376666 FPS (0.406677%)** below the fresh parity
control, with a 0.164067 FPS spread caused by one slow sample. All runs retained
969 frames and checksum `1047377823`; the full strict i486 audit was skipped
after the negative mean. The directive was removed. See the
[Span16 alignment ledger](ledger/2026-10-29-span16-full-segment-entry-alignment-rejected.md).

Rechecking `TextureSpanRowPath=norowcross` against the current 320x200 source
averaged **16.233645667 FPS** versus **16.329116 FPS** for control
(-0.095470333 FPS, -0.584663%). Every run retained 969 frames and checksum
`1047377823`; the slowdown exceeded both run sets' spread. The default row
path remains `control`; see the
[current-source recheck ledger](ledger/2026-10-29-span16-norowcross-current-recheck-rejected.md).

The current-source instrumented 320x200 profile again ranked texture spans
first. It recorded 969 frames and checksum `1047377823`; the 80.266266-second
profile run included 2,011,784 `Sys_FloatTime` reads at 5.779 microseconds per
read, so its FPS is diagnostic only. After subtracting each node's direct timer
floor, the largest self times were texture spans **18.201 s**, surface cache
**7.115 s**, Z spans **6.848 s**, render-face **6.429 s**, and edge scan
**6.212 s**. This floor adjustment does not remove all profiler overhead from
the denominator; use these values to rank current regions, not to claim real
486 frame shares. The profile also counted 1,454,477 texture spans over
43,956,325 pixels and 3,513,513 perspective segments, 42,031,379 Z-span pixels,
375,707 BSP nodes, and 670,748 surface tests. Artifact:
`out/dos-timedemo-20261029-221148/quake/profile.jsn`; source fingerprint
`44509FBCD86F71677CB86F0C91A0596427353981E6A2EBE3D659C2C9ABE56693`.

In `D_PolysetDrawSpans8`, moving each passing pixel's Z-buffer store before
the texture fetch in both unrolled eight-pixel groups produced a 320x200 mean
of **16.321720 FPS**, **0.000003 FPS (0.00001838%)** below the strict control.
All runs retained 969 frames and checksum `1047377823`; the strict ISA audit
was skipped after the negative mean. The original store schedule was restored;
see the [alias-span Z-store ledger](ledger/2026-10-29-alias-span-z-store-before-texel-load-screen-rejected.md).

Aligning `D_PolysetDrawSpans8`'s `LDrawLoop` entry to 16 bytes screened
**0.000002000 FPS faster**, but the strict candidate averaged **16.321711333
FPS** against **16.321723000 FPS** control (**−0.000011667 FPS,
−0.00007148%**). All runs retained 969 frames and checksum `1047377823`; the
complete executable, startup, and provider i486 audits passed. The strict loss
rejects the layout change, and the alignment directive was removed. See the
[alias-span alignment ledger](ledger/2026-10-29-alias-span-hotloop-alignment-rejected.md).

The alias span's runtime colormap patcher writes to `LPatchN-4`, so each
`LPatch` label must remain immediately after its five-byte lookup instruction.
An attempted Z-store move between that lookup and label redirected the patch
into the store and prevented the 320x200 timedemo from starting; the instruction
order was restored without recording timing. See the
[runtime-patch constraint ledger](ledger/2026-10-29-alias-span-z-store-after-colormap-invalid.md).

The patch-safe schedule that put the alias Z-store after the colormap lookup
kept the `LPatchN-4` displacement valid and rendered exact checksums, but its
three-run mean was **16.279602 FPS** against **16.321723 FPS** control
(**−0.042121 FPS, −0.2581%**). One sample was **16.195342 FPS**; a fresh control
recheck stayed within a 0.000021 FPS spread, but all candidate samples remain
in the mean. The store was restored and the strict ISA audit was skipped after
the loss. See the
[deferred-store ledger](ledger/2026-10-29-alias-span-deferred-z-store-after-colormap-screen-rejected.md).

Preloading the carry-selected alias-span address delta into `%eax` before the
S-fraction add, then using a register `ADC`, averaged **16.299054333 FPS**
against **16.321723000 FPS** control (**−0.022668667 FPS, −0.1389%**). All
runs retained exact 969-frame checksum parity; the strict ISA audit was skipped
after the negative screen mean. The added load did not pay for itself, so the
original indexed-memory `ADC` remains active. See the
[carry-delta preload ledger](ledger/2026-10-29-alias-span-carry-delta-preload-screen-rejected.md).

Moving that table read earlier, immediately after the T-carry mask and before
the independent Z and S-fraction updates, also lost: the 320x200 parity screen
averaged **16.299063667 FPS**, **0.022650666 FPS (0.138776%)** below the fresh
parity control. All runs retained 969 frames and checksum `1047377823`; the
provider ISA proof passed, while the full i486 audit was skipped after the
negative mean. The schedule was reverted, leaving the indexed-memory `ADC` in
place. See the
[early carry-delta preload ledger](ledger/2026-10-29-alias-span-early-carry-delta-preload-rejected.md).

Keeping the `D_CacheSurface` hit pointer in `%ebx` removed its unconditional
stack spill and hit-path reload, while misses saved the cache pointer and
reloaded the mip level. The 320x200 parity screen averaged **16.280218333
FPS**, **0.041504667 FPS (0.2543%)** below the strict control. The first two
samples were near control, but the third was **16.196545 FPS** and created a
0.125530 FPS spread; all runs retained exact checksum parity. The full pooled
mean was kept and the candidate was reverted without a strict audit. See the
[cache-register ledger](ledger/2026-10-29-surface-cache-hit-cache-register-rejected.md).

That paragraph records the older source baseline. The register schedule was
retested against the current surface-cache flow on 2026-10-30 and retained after
a positive three-run mean plus full frame-stream and image parity; see the
[current-source recheck ledger](ledger/2026-10-30-surface-cache-hit-ebx-current-recheck-promoted.md).

The branch-selected Span16 address update was rejected before timing. Its first
320x200 frame hash differed from the control, and the full-run framebuffer
checksum also failed exact parity. The current indexed carry-table path remains
active; see the [branch-address parity ledger](ledger/2026-10-29-span16-branch-address-parity-rejected.md).

A direct-`JC` follow-up to that opt-in path was interrupted after the user
reported visible horizontal-line artifacts. The candidate source was restored;
the default control path then completed 969 frames with checksum `1047377823`.
No timing was retained for the interrupted candidate. A later named
`demo1-vga-full` 320x200 validation captured frame 169 and passed the committed
golden comparison with 12 of 64,000 pixels changed (mean absolute channel error
0.0009375); checksum `1047377823` and all 969 frames matched. The visual build
skipped its separate ISA audit.

The rejected branch-address implementation and its selector have since been
removed from `src/d_draw16.s` and the DOS build, benchmark, smoke, and timedemo
wrappers. `TextureSpanAddressing` now accepts only `control`, preventing the
known bad path from being selected again. A current-source i486 build passed
the complete linked ISA audit (314,318 instructions; zero above-i486,
unclassified, or exempt instructions). The fresh 320x200 visual-only replay
passed twice: both 971-entry frame-checksum streams matched the prior control
with zero differences, and both golden comparisons retained the same 12-pixel
delta. Its report is
`out/render-validation-20261029-horizontal-line-fix-visual-rebuilt/render-validation-result.json`.

A current-source repeat on 2026-10-30 used source-tree fingerprint
`BFA0E1915D6AAB6A95DABA044EF27068093FEF9A5383F040B75B8B6A4CE78973`. Both
`demo1-vga-full` captures passed the 320x200 golden comparison with the same
12-pixel delta, and their 970-entry checksum streams matched across all 964
post-warmup frames. Their PCX files were byte-identical (SHA-256
`D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96`); visual
inspection of frame 169 showed no horizontal-line artifact. The report is
`out/render-validation-20261030-110945/render-validation-result.json`.

A guarded power-of-two cache-width shift was tested in the Span16 initial and
full-segment address setup, with the original `IMUL` retained for other widths.
The two candidate 320x200 parity-screen samples averaged **16.209385 FPS**
against **16.321706 FPS** for the fresh control (**−0.112321 FPS,
−0.688169%**). All runs retained 969 frames and checksum `1047377823`; the
candidate's two samples differed by only 0.000002 FPS. It was removed after
the repeated loss, before the strict ISA audit. See the
[power-of-two multiply ledger](ledger/2026-10-29-span16-pow2-cachewidth-multiply-screen-rejected.md).

### Surface-cache key preparation only on misses (2026-10-29)

The assembly cache path now compares the current texture and light-style keys
before writing `r_drawsurf.texture` and the four `lightadj` values. Hits return
without those miss-only stores; misses call the existing key-preparation helper.
The dynamic-light contribution check is unchanged. The candidate's three-run
320x200 mean was **16.321731 FPS** versus **16.321714 FPS** for a fresh matched
control (**+0.000017 FPS, +0.000104%**). All six runs rendered 969 frames with
checksum `1047377823`. The `demo1-vga-full` golden comparison passed at 320x200,
and the strict build/runtime ISA audits found zero above-i486, unknown, or
exempt instructions. The gain is smaller than the candidate spread, but remains
under the positive-mean rule. See the
[surface-cache miss-only key ledger](ledger/2026-10-29-surface-cache-prepare-keys-on-miss-promoted.md).

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

### RenderFace nearzi-only direct compare (2026-10-29)

`R_RenderFace` now compares `C(r_nearzionly)` directly with zero instead of
loading it into `%eax` and testing the register. The value only controlled the
near-z-only early return. The strict candidate averaged **16.304283 FPS**
against the fresh strict control's **16.301349 FPS**
(**+0.002934 FPS, +0.0180%**). All runs retained 969 frames and checksum
`1047377823`; the complete executable i486 gate passed. See the
[near-z-only compare ledger](ledger/2026-10-29-renderface-nearzionly-direct-compare-promoted.md).

### RenderFace cacheoffset sentinel direct compare (2026-10-29)

The `R_RenderFace` near-z-only return now compares `C(cacheoffset)` directly
with its fully-clipped sentinel, removing a load into `%eax` that was not used
after the branch. The strict candidate averaged **16.304901 FPS** against the
fresh strict control's **16.304283 FPS** (**+0.000618 FPS, +0.00379%**). All
runs retained 969 frames and checksum `1047377823`; the complete executable
i486 gate passed. See the
[cacheoffset compare ledger](ledger/2026-10-29-renderface-cacheoffset-sentinel-direct-compare-promoted.md).

### RenderFace shared signed-edge address calculation (2026-10-29)

Both regular and submodel edge loops retain the strict-positive branch and
negative-edge negation, then converge on one scaled address calculation. This
removes the nonpositive path's unconditional jump and duplicate `lea`. The
strict candidate averaged **16.309177 FPS** against the committed parent's
**16.304922 FPS** (**+0.004255 FPS, +0.02609641%**). All runs retained 969
frames and checksum `1047377823`; the complete executable i486 gate passed.
See the [shared edge-address ledger](ledger/2026-10-29-renderface-shared-edge-address-promoted.md).

### RenderFace cached-edge marker memory test (2026-10-29)

The regular edge loop tests the cached-offset high bit directly in memory and
loads the offset into `%eax` only on the marked path that needs its frame value.
The strict candidate averaged **16.312519333 FPS** against the committed
parent's **16.309177 FPS** (**+0.003342333 FPS, +0.02049357%**). All runs
retained 969 frames and checksum `1047377823`; the complete executable i486
gate passed. See the
[marker-test ledger](ledger/2026-10-29-renderface-edge-marker-memory-test-promoted.md).

Replacing the sign-test branch and conditional `NEG` with `CLTD/XOR/SUB`
branchless magnitude formation in both `R_RenderFace` edge loops averaged
**16.317098333 FPS**, **0.004624667 FPS (0.0283344%)** below the strict
control. All runs retained 969 frames and checksum `1047377823`; the strict
ISA audit was skipped after the negative mean, and the original branches were
restored. See the
[branchless-magnitude ledger](ledger/2026-10-29-renderface-branchless-edge-magnitude-rejected.md).

### `R_ClipEdge` left-clipped direct compare rejected (2026-10-29)

The `R_ClipEdge` both-clipped branch compared `r_leftclipped` directly in
memory instead of loading it into `%eax` and testing the register. Its
three-run parity screen averaged **16.274258333 FPS** against the committed
parent's **16.312519333 FPS** (**−0.038261 FPS, −0.23454991%**). The checksum
matched, but the pooled mean was negative, so the assembly was restored and no
strict audit was run. See the
[rejected compare ledger](ledger/2026-10-29-r-clipedge-leftclipped-direct-compare-rejected.md).

### Sprite clip-current direct compare (2026-10-29)

`R_ClipSpriteFace_asm486` now compares `clip_current` directly with zero,
removing the load into `%eax` and register test before the buffer-selection
branch. The strict candidate averaged **16.312544667 FPS** against the current
parent's **16.312519333 FPS** (**+0.000025333 FPS, +0.00015530%**). All runs
retained 969 frames and checksum `1047377823`; the complete executable i486
gate passed. See the
[sprite clip-current ledger](ledger/2026-10-29-r-clipsprite-clipcurrent-direct-compare-promoted.md).

### `R_GenerateSpans` edge-loop alignment rejected (2026-10-29)

Aligning `Lgs_edgeloop` to 16 bytes averaged **16.311311667 FPS** on the
three-run parity screen against the committed strict control's **16.312544667
FPS** (**−0.001233 FPS, −0.00755860%**). Every run retained 969 frames and
checksum `1047377823`; the strict i486 audit was skipped because the screen was
negative. The alignment directive was removed. See the
[edge-loop alignment ledger](ledger/2026-10-29-edge-genspans-loop-alignment-rejected.md).

### `R_GenerateSpans` edge-index/base load interleave rejected (2026-10-29)

Moving the independent `surfaces` base load between the two edge-index loads
averaged **16.321719667 FPS**, **0.000003333 FPS (-0.00002042%)** below the
strict control. All runs retained 969 frames and checksum `1047377823`; the
complete executable i486 audit passed. The original load order was restored.
See the [edge-load interleave ledger](ledger/2026-10-29-edge-surface-base-load-interleave-rejected.md).

### `R_GenerateSpans` edge base load before indices rejected (2026-10-29)

Moving the `surfaces` base load ahead of both edge-index loads produced a
positive **+0.000002333 FPS** parity screen, but the full strict three-run mean
was **16.321716 FPS**, **0.000007 FPS (-0.00004288%)** below the strict
control. All runs retained 969 frames and checksum `1047377823`; the complete
executable i486 audit passed. The original load order was restored. See the
[base-load schedule ledger](ledger/2026-10-29-edge-surface-base-before-indices-rejected.md).

### `R_GenerateSpans` non-bmodel sort exit branch (2026-10-29)

`Lsortloopnb` now branches directly to insertion when the key comparison ends
the search and takes the unconditional backward branch only when it continues.
The strict candidate averaged **16.318158667 FPS** against the committed
strict control's **16.312544667 FPS** (**+0.005614 FPS, +0.03441523%**). All
runs retained 969 frames and checksum `1047377823`; the complete executable
i486 gate passed. See the
[sort-exit ledger](ledger/2026-10-29-edge-sort-nonbmodel-exit-branch-promoted.md).

### `R_GenerateSpans` non-bmodel sort pair unroll (2026-10-29)

`Lsortloopnb` checks two active-surface nodes per back-edge, branching to
insertion as soon as either comparison ends the search. The strict candidate
averaged **16.321015333 FPS** against the committed strict control's
**16.318158667 FPS** (**+0.002856667 FPS, +0.01750606%**). All runs retained
969 frames and checksum `1047377823`; the complete executable i486 gate passed.
See the [sort-pair unroll ledger](ledger/2026-10-29-edge-sort-nonbmodel-pair-unroll-promoted.md).

### `R_GenerateSpans` non-bmodel sort four-way unroll (2026-10-29)

`Lsortloopnb` checks four active-surface nodes per back-edge, branching to
insertion as soon as any comparison ends the search. The strict candidate
averaged **16.321664 FPS** against the committed strict control's
**16.321015333 FPS** (**+0.000648667 FPS, +0.00397443%**). All runs retained
969 frames and checksum `1047377823`; the complete executable i486 gate passed.
See the [sort-four unroll ledger](ledger/2026-10-29-edge-sort-nonbmodel-four-unroll-promoted.md).

### `R_GenerateSpans` non-bmodel sort eight-way unroll (2026-10-29)

`Lsortloopnb` checks eight active-surface nodes per back-edge, branching to
insertion as soon as any comparison ends the search. The strict candidate
averaged **16.321705667 FPS** against the committed strict control's
**16.321664 FPS** (**+0.000041667 FPS, +0.0002553%**). All runs retained 969
frames and checksum `1047377823`; the complete executable i486 gate passed.
See the [sort-eight unroll ledger](ledger/2026-10-29-edge-sort-nonbmodel-eight-unroll-promoted.md).

### `R_GenerateSpans` non-bmodel sort sixteen-way unroll (2026-10-29)

`Lsortloopnb` now checks sixteen active-surface nodes per back-edge, exiting to
insertion as soon as a signed comparison ends the search. `PROFILE486` counts
and `EDGE_SCAN_PROBE_SORT` probes remain at each comparison. The strict
candidate averaged **16.321711667 FPS** against the eight-way strict control's
**16.321705667 FPS** (**+0.000006 FPS, +0.00003676%**). All runs retained 969
frames and checksum `1047377823`; the complete executable i486 gate passed.
See the [sort-sixteen unroll ledger](ledger/2026-10-29-edge-sort-nonbmodel-sixteen-unroll-promoted.md).

### `R_GenerateSpans` non-bmodel sort twelve-way unroll (2026-10-29)

The active unroll is now twelve comparisons per back-edge. Against a fresh
sixteen-way control, the 320x200 parity-screen mean improved by
**0.000006667 FPS (+0.00004083%)**. This is below both three-run sample
spreads, so the gain is tiny and noisy; it is retained under the positive
pooled-mean policy. All six runs completed 969 frames with checksum
`1047377823`. The candidate's 971-entry frame-checksum stream and captured PCX
exactly matched the control, and the exact changed `r_edgea.obj` passed the
strict linked i486 audit (314,306 instructions, no above-target, unknown, or
exempt instructions). See the
[sort-twelve unroll ledger](ledger/2026-10-29-edge-sort-nonbmodel-twelve-unroll-promoted.md).

### `R_GenerateSpans` non-bmodel sort thirty-two-way unroll rejected (2026-10-29)

Extending the non-bmodel sort loop from sixteen to thirty-two comparisons per
backedge averaged **16.321723 FPS**, exactly matching the strict control.
Every run retained 969 frames and checksum `1047377823`; the screen build
skipped the strict ISA audit. The extra unroll was removed because it produced
no measurable gain. See the
[sort-thirty-two ledger](ledger/2026-10-29-edge-sort-nonbmodel-thirtytwo-unroll-rejected.md).

The intermediate twenty-four-way unroll was screened twice against a fresh
sixteen-way control. Its two three-run means moved in opposite directions; the
six-run pooled mean was only **+0.000002333 FPS (+0.0000143%)**, while the
repeated screen was slower and the candidate median remained below control.
The gain was not repeatable, so the eight added comparisons were removed. All
six candidate runs retained 969 frames and checksum `1047377823`; both screens
used `VisualParityOnly`, with no strict ISA audit after the timing result. See
the [sort-twenty-four ledger](ledger/2026-10-29-edge-sort-nonbmodel-twentyfour-unroll-rejected.md).

### `R_GenerateSpans` trailing-edge direct-call layout rejected for parity (2026-10-29)

Moving `Lgs_nextedge` immediately after a direct `call TrailingEdge` broke the
fall-through from `LInsertAndExit`: ordinary leading edges entered `Lxl_done`
and incremented `st_spanstate`. The first 320x200 run rendered 969 frames but
failed checksum (`3586745294` versus `1047377823`); its 18.693908 FPS is invalid.
The original `pushl $Lgs_nextedge; jmp TrailingEdge` sequence and continuation
placement were restored. See the
[trailing-edge layout ledger](ledger/2026-10-29-edge-trailing-return-call-parity-rejected.md).

### Surface mip-0 lightdelta stack spill (2026-10-29)

`SURF8_MIP0_ROW` now preserves the unshifted `%ebp` delta with a balanced
`pushl`/`popl` pair instead of storing and reloading it through the absolute
`C(lightdelta)` global. The strict candidate averaged **16.304922 FPS** against
the fresh strict control's **16.304901 FPS** (**+0.000021 FPS, +0.0001288%**).
All runs retained 969 frames and checksum `1047377823`; the complete executable
i486 gate passed. See the
[mip-0 stack-spill ledger](ledger/2026-10-29-surf8-mip0-lightdelta-stack-spill-promoted.md).

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
neither fetch boundaries, write-buffer occupancy, nor 486 L1 set pressure. A
measured win is evidence for this emulated workload; a measured null cannot
settle effects the emulator does not model.

DOSBox-X does not model x87 latency, fetch boundaries, write-buffer occupancy,
or 486 L1 cache occupancy and replacement accurately. Equal 4 KB offsets imply
that corresponding 16-byte lines map to the same L1 set; they do not prove a
conflict or a stall in the 486's four-way cache. The 2026-10-30 cost-model
correction records the current allocation offsets and limits of that inference.
These effects cannot be validated by a DOSBox-X timedemo alone. The cost model's
80-cycle Z-span figure sums published x87 latencies without modeling overlap
with integer work. It is a gross no-overlap projection, not net elapsed time or
an attainable 4.46% speedup; see the
[x87 overlap correction](ledger/2026-10-30-zspan-x87-overlap-model-correction.md).
The Z-span prologue remains an unmeasured real-486 hypothesis, distinct from
improvements the pinned timedemo can verify.

`tools/486-cost-model.ps1` estimates x87 costs and reports cache footprint and
set mapping. Its cache-layout output is not a conflict or speed prediction; the
whole report is a ranking aid, never a result or a reason to reject a small
candidate.

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
