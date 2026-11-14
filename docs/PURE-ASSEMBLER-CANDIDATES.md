# Pure-Assembler Conversion Candidates

Date: 2026-09-28, updated 2026-10-28
Scope: i486 DOS NitroQuake software renderer

> **Scope update (2026-10-04):** this document records the earlier performance
> survey and its recommendations about which conversions are likely to improve the
> timedemo. The current user-directed work is broader: port the full software
> renderer and render-time dependency closure to hand-written i486 assembler while
> retaining C references during migration. The survey is still useful for choosing
> order and measuring performance; its recommendation against a full conversion no
> longer limits the requested scope. Track implementation state in
> renderer-port ledgers under `docs/ledger/`.
> Current source and coverage gaps are recorded in
> [Renderer completion gaps](RENDERER-COMPLETION-GAPS.md).

> **Objective clarification (2026-10-06):** the requested move to assembly is
> primarily to establish i486 CPU compatibility while preserving the reference
> renderer's behavior. Timing remains useful diagnostic evidence, but a slower
> assembly path is not a reason to reject a correct i486 implementation.

> **Performance acceptance update (2026-10-21):** promotion accepts any positive
> pooled mean from at least three matched, uninstrumented samples per variant,
> regardless of the gain size or whether it is smaller than run-to-run variation.
> Record the samples and spread. Exact frame-count and framebuffer-checksum
> parity plus the strict i486 ISA audit remain required. Below-0.05% conclusions
> in historical entries describe the old policy; measured regressions remain
> closed for the implementation that lost.

> **Dynamic-light remaining-mask scan in EDI (2026-10-28):** keeping the
> sparse surface-light mask in callee-saved `EDI` removed the per-light stack
> reload and store. The strict candidate averaged **16.240113 FPS** against
> **16.240109333 FPS** for control (**+0.000003667 FPS, +0.00002258%**).
> Exact 969-frame checksum parity and the complete strict i486 audit passed.
> Both medians were **16.240111 FPS**; the candidate spread was 0.000008 FPS,
> and the trailing control drifted 0.000005 FPS above the control median. The
> positive mean qualifies under the current policy, while the near-noise-sized
> gain remains visible in the ledger. See
> `docs/ledger/2026-10-28-dlight-edi-mask-register-promoted.md`.

> **Dynamic-light mask clear with `BTR` (2026-10-28):** replacing the `LEA`
> and `AND` mask-clear sequence with `btrl %ebx,%edi` averaged **16.240115667
> FPS** against **16.240104667 FPS** for the EDI/`AND` control (**+0.000011
> FPS, +0.00006773%**). Exact 969-frame checksum parity and the complete strict
> i486 audit passed. The candidate median improved by 0.000006 FPS, while its
> spread was 0.000024 FPS and the trailing control drifted 0.000013 FPS above
> the control median. The positive mean qualifies under the current rule; see
> `docs/ledger/2026-10-28-dlight-btr-mask-clear-promoted.md` for the timing
> caveat and run artifacts.

> **Alias left-edge height folded into the counter (2026-10-28):** the scan
> prologue now uses `orw height(%esp),%cx`, removing two instructions per call.
> The strict candidate averaged **16.240123667 FPS** against **16.238273333
> FPS** for control (**+0.001850333 FPS, +0.01139489%**). All six runs matched
> 969 frames and checksum `1047377823`; the complete i486 audit passed. Six
> extra alignment NOPs after a rasterizer `ret` explain the object-wide static
> instruction count while remaining unreachable. See
> `docs/ledger/2026-10-28-d-polyset-scan-left-height-lowword-promoted.md`.

> **Z-span U-coordinate load before x87 origin add (2026-10-22):** the strict
> candidate averaged **15.601291333 FPS** against **15.601303 FPS** for control
> (**−0.000011667 FPS, −0.00007478%**). Exact 969-frame checksum parity and the
> complete strict i486 audit passed; the negative mean rejects the move, which
> has been restored. See
> `docs/ledger/2026-10-22-zspan-u-load-before-origin-add-rejected.md`.

> **Span16 endpoint reload interleave (2026-10-22):** delaying the `snext` and
> `tnext` reloads averaged **15.601293333 FPS** against **15.601303 FPS** for
> control (**−0.000009667 FPS, −0.00006196%**). Exact 969-frame checksum parity
> and the complete strict i486 audit passed; the negative mean rejects this
> schedule, which has been restored. See
> `docs/ledger/2026-10-22-span16-fistp-reload-interleave-rejected.md`.

> **Span16 count update overlapped with x87 endpoint math (2026-10-22):** the
> strict candidate averaged **15.601281333 FPS** against **15.601303 FPS** for
> control (**−0.000021667 FPS, −0.00013888%**). Exact 969-frame checksum parity
> and the complete strict i486 audit passed; the negative pooled mean rejects
> the schedule, which has been restored. See
> `docs/ledger/2026-10-22-span16-counttemp-x87-overlap-rejected.md`.

> **Span16 S-adjust load overlapped with x87 endpoint math (2026-10-22):** the
> strict candidate averaged **15.601299 FPS** against **15.601303 FPS** for
> control (**−0.000004 FPS, −0.00002564%**). Exact 969-frame checksum parity
> and the complete strict i486 audit passed; the negative pooled mean rejects
> the move, which has been restored. See
> `docs/ledger/2026-10-22-span16-sadjust-x87-overlap-rejected.md`.

> **Span16 first texel load overlapped with x87 endpoint math (2026-10-22):**
> the strict candidate averaged **15.601298 FPS** against **15.601303 FPS** for
> control (**−0.000005 FPS, −0.00003205%**). Exact 969-frame checksum parity
> and the complete strict i486 audit passed; the negative pooled mean rejects
> the move, which has been restored. See
> `docs/ledger/2026-10-22-span16-first-texel-x87-overlap-rejected.md`.

> **Span16 S-add before first A-half high-byte fetch (2026-10-21):** the strict
> candidate averaged **15.564258 FPS** against **15.564256667 FPS** for control
> (**+0.000001333 FPS, +0.00000857%**). The parity screen was **−0.000002333
> FPS** against control. Exact 969-frame checksum parity and the complete strict
> i486 audit passed; the positive strict mean qualifies under the current rule.
> See `docs/ledger/2026-10-21-span16-s-add-before-first-high-fetch-promoted.md`.

> **Span16 T-step addition before word store (2026-10-21):** the strict
> candidate averaged **15.564260333 FPS** against **15.564258 FPS** for control
> (**+0.000002333 FPS, +0.00001499%**). The parity screen was **−0.000004667
> FPS** against control. Exact 969-frame checksum parity and the complete strict
> i486 audit passed; the positive strict mean qualifies under the current rule.
> See `docs/ledger/2026-10-21-span16-tstep-before-word-store-promoted.md`.

> **Span16 T-step/store overlap extension (2026-10-21):** the parity screen
> averaged **15.564255333 FPS** against **15.564251667 FPS** for control
> (**+0.000003667 FPS**), but the strict candidate averaged **15.564256333 FPS**
> against **15.564260333 FPS** (**−0.000004 FPS, −0.00002570%**). Exact
> 969-frame checksum parity and the complete strict i486 audit passed. The
> negative strict mean rejects the five additional moves; the first-store
> overlap remains active. See
> `docs/ledger/2026-10-21-span16-tstep-overlap-extension-rejected.md`.

> **Span16 A-half T-step/store overlap (2026-10-21):** the parity screen
> averaged **15.564256667 FPS** against **15.564251667 FPS** for control
> (**+0.000005 FPS**), but the strict candidate averaged **15.564259333 FPS**
> against **15.564260333 FPS** (**−0.000001 FPS, −0.00000643%**). Exact
> 969-frame checksum parity and the complete strict i486 audit passed. The
> negative strict mean rejects moving the additions before stores 3 and 5; the
> first-store overlap remains active. See
> `docs/ledger/2026-10-21-span16-tstep-a-half-overlap-rejected.md`.

> **Span16 B-half T-step/store overlap (2026-10-22):** the parity screen
> averaged **15.564256333 FPS** against **15.564251667 FPS** for control
> (**+0.000004667 FPS**), but the strict candidate averaged **15.564257 FPS**
> against **15.564260333 FPS** (**−0.000003333 FPS, −0.00002142%**). Exact
> 969-frame checksum parity and the complete strict i486 audit passed. The
> negative strict mean rejects moving the additions before stores 9, 11, and
> 13; the first-store overlap remains active. See
> `docs/ledger/2026-10-22-span16-tstep-b-half-overlap-rejected.md`.

> **Span16 store 3 T-step overlap (2026-10-22):** the parity screen averaged
> **15.564251 FPS** against **15.564251667 FPS** for control (**−0.000000667
> FPS**), and the strict candidate averaged **15.564254667 FPS** against
> **15.564260333 FPS** (**−0.000005667 FPS, −0.00003641%**). Exact 969-frame
> checksum parity and the complete strict i486 audit passed. The negative
> strict mean rejects the store 3 move; the first-store overlap remains active.
> See `docs/ledger/2026-10-22-span16-tstep-store3-overlap-rejected.md`.

> **Span16 store 5 T-step overlap (2026-10-22):** the parity screen averaged
> **15.564255 FPS** against **15.564251667 FPS** for control (**+0.000003333
> FPS**), but the strict candidate averaged **15.564259 FPS** against
> **15.564260333 FPS** (**−0.000001333 FPS, −0.00000857%**). Exact 969-frame
> checksum parity and the complete strict i486 audit passed. The negative
> strict mean rejects the store 5 move; the first-store overlap remains active.
> See `docs/ledger/2026-10-22-span16-tstep-store5-overlap-rejected.md`.

> **Span16 store 9 T-step overlap (2026-10-22):** the parity screen averaged
> **15.564258667 FPS** against **15.564251667 FPS** for control (**+0.000007
> FPS**), but the strict candidate averaged **15.564255333 FPS** against
> **15.564260333 FPS** (**−0.000005 FPS, −0.00003212%**). Exact 969-frame
> checksum parity and the complete strict i486 audit passed. The negative
> strict mean rejects the store 9 move; the first-store overlap remains active.
> See `docs/ledger/2026-10-22-span16-tstep-store9-overlap-rejected.md`.

> **Span16 word stores after the final address ADC (2026-10-21):** the strict
> candidate averaged **15.537289000 FPS** against a pooled six-run control mean
> of **15.518328500 FPS** (**+0.018960500 FPS, +0.12218%**). The control retains
> one slow 15.423568 FPS run; the candidate was **−0.000008 FPS** against the
> earlier clean three-run block alone. A separate parity screen was positive by
> **+0.000001000 FPS**. Exact 969-frame checksum parity and the complete strict
> i486 audit passed. The pooled positive mean qualifies under the current rule;
> timing remains noisy. See
> `docs/ledger/2026-10-21-span16-store-after-adc-promoted.md`.

> **Span16 S-step add before source fetch (2026-10-21):** moving the S-fraction
> add before the paired low-byte load averaged **15.537289333 FPS** against
> **15.537294667 FPS** for control (**−0.000005333 FPS, −0.00003433%**). Exact
> 969-frame checksum parity held; the parity-only screen skipped the strict ISA
> audit. Its negative pooled mean rejects the reorder, which has been restored.
> See `docs/ledger/2026-10-21-span16-s-add-before-fetch-screen-rejected.md`.

> **Span16 T-carry extraction after low-byte fetch (2026-10-21):** moving
> `sbbl %ecx,%ecx` after each `movb (%esi),%al` averaged **15.537292000 FPS**
> against **15.537289000 FPS** for the matched strict control
> (**+0.000003000 FPS, +0.00001931%**). A separate parity screen was positive
> by **+0.000007333 FPS**. Exact frame/checksum parity and the full strict i486
> audit passed; the positive mean qualifies despite being below the spread. See
> `docs/ledger/2026-10-21-span16-tcarry-after-fetch-promoted.md`.

> **Span16 T-step store after fractional add (2026-10-21):** moving the
> `tstep` store immediately after the T-fraction addition averaged
> **15.537295000 FPS** against **15.537292000 FPS** for strict control
> (**+0.000003000 FPS, +0.00001931%**). The parity-only screen was also positive
> by **+0.000000667 FPS**. All nine runs retained 969 frames and checksum
> `1047377823`; the full strict i486 audit passed. The positive mean qualifies
> below the spread. See
> `docs/ledger/2026-10-21-span16-tstep-store-after-add-promoted.md`.

> **Span16 `advancetable` store after T-fraction add (2026-10-21):** moving
> the store from before `addl %ecx,%edx` to just after it averaged
> **15.537293000 FPS** against **15.537295000 FPS** for strict control
> (**−0.000002000 FPS**). All six runs retained 969 frames and checksum
> `1047377823`; the parity-only candidate skipped the ISA audit. Its negative
> mean rejects the order, and the original placement remains active. See
> `docs/ledger/2026-10-21-span16-advancetable-store-after-tfrac-add-screen-rejected.md`.

> **Span16 S-step shift after T-carry (2026-10-21):** the parity-only screen
> averaged **15.537301333 FPS**, above the strict control's **15.537295000 FPS**,
> but the strict candidate averaged **15.537289333 FPS** (**−0.000005667 FPS,
> −0.00003647%**). All nine runs retained 969 frames and checksum
> `1047377823`; the full strict i486 audit passed. The negative strict mean
> rejects the deferral, and the original shift position remains active. See
> `docs/ledger/2026-10-21-span16-sstep-shift-after-tcarry-rejected.md`.

> **Span16 S-step shift after `advancetable` store (2026-10-21):** the
> three-run parity-only screen averaged **15.537293667 FPS** against
> **15.537295000 FPS** control (**−0.000001333 FPS, −0.00000858%**). Exact
> 969-frame checksum parity held; the negative mean rejects the order, and the
> original shift position remains active. See
> `docs/ledger/2026-10-21-span16-sstep-shift-after-advancetable-screen-rejected.md`.

> **Span16 S-step shift after T-step shift (2026-10-21):** the strict candidate
> averaged **15.537297000 FPS** against **15.537295000 FPS** for strict control
> (**+0.000002000 FPS, +0.00001287%**). The parity-only screen was positive by
> **+0.000003667 FPS**. All nine runs retained 969 frames and checksum
> `1047377823`; the full strict i486 audit passed. The positive mean qualifies
> below the spread. See
> `docs/ledger/2026-10-21-span16-sstep-shift-after-tstep-shift-promoted.md`.

> **Span16 `sfracf` reload after T-step shift (2026-10-21):** the parity-only
> screen averaged **15.537292000 FPS** against **15.537297000 FPS** control
> (**−0.000005000 FPS, −0.00003218%**). All six runs retained exact 969-frame
> checksum parity. The negative mean rejects the load order; the promoted
> `sfracf`-before-T-shift sequence remains active. See
> `docs/ledger/2026-10-21-span16-sfracf-after-tstep-shift-screen-rejected.md`.

> **Span16 S-first/store/T-shift setup permutation (2026-10-21):** the
> parity-only screen averaged **15.537292333 FPS** against **15.537297000 FPS**
> control (**−0.000004667 FPS, −0.00003004%**). Exact 969-frame checksum parity
> held; the negative mean rejects the order and the promoted schedule remains
> active. See
> `docs/ledger/2026-10-21-span16-s-first-store-t-shift-screen-rejected.md`.

> **Span16 `sfracf` reload after both shifts (2026-10-21):** the parity-only
> screen averaged **15.537290667 FPS** against **15.537297000 FPS** control
> (**−0.000006333 FPS, −0.00004076%**). All six runs retained exact 969-frame
> checksum parity. The negative mean rejects the load order; the promoted
> `sfracf`-before-shifts sequence remains active. See
> `docs/ledger/2026-10-21-span16-sfracf-after-both-shifts-screen-rejected.md`.

> **Span16 T-carry deferral to high-byte loads (2026-10-21):** extending the
> low-byte-only promotion to high-byte fetches averaged **15.537297000 FPS**
> against **15.537302000 FPS** for control (**−0.000005000 FPS, −0.00003219%**).
> Exact 969-frame checksum parity held; the parity-only screen skipped the
> strict ISA audit. Its negative mean rejects the extension; the promoted
> low-byte-only schedule remains active. See
> `docs/ledger/2026-10-21-span16-tcarry-after-all-fetches-screen-rejected.md`.

> **Span16 `loadfirst` recheck (2026-10-21):** against the promoted low-byte
> T-carry schedule, `loadfirst` averaged **15.537290000 FPS** against
> **15.537302000 FPS** for control (**−0.000012000 FPS, −0.00007724%**). Exact
> 969-frame checksum parity held; the parity-only screen skipped the strict ISA
> audit. Its negative mean leaves `control` as default and `loadfirst` opt-in.
> See `docs/ledger/2026-10-21-span16-loadfirst-current-control-rejected.md`.

> **Span16 `loadfirst` recheck after S-step shift promotion (2026-10-21):**
> it averaged **15.537296000 FPS** against **15.537297000 FPS** for the new
> strict control (**−0.000001000 FPS, −0.00000644%**). All six runs retained
> exact 969-frame checksum parity. The negative mean keeps `control` as default;
> the recheck is appended to
> `docs/ledger/2026-10-21-span16-loadfirst-current-control-rejected.md`.

> **Span16 `advancetable` store after `sfracf` load (2026-10-21):** the
> parity-only screen averaged **15.537296333 FPS** against **15.537297000 FPS**
> control (**−0.000000667 FPS, −0.00000429%**). Exact 969-frame checksum parity
> held; the negative mean rejects the earlier store placement. See
> `docs/ledger/2026-10-21-span16-advancetable-store-after-sfracf-screen-rejected.md`.

> **Current Span16 setup-store schedule (2026-10-21):** moving the independent
> `advancetable` store after both fractional shifts averaged **15.537297000 FPS**
> against a pooled six-run strict control mean of **15.537295333 FPS**
> (**+0.000001667 FPS, +0.00001072%**). A separate three-run parity screen was
> positive by **+0.000000333 FPS**. These gains are below the spread but
> positive. Exact 969-frame checksum parity and the complete linked i486 audit
> passed. See
> `docs/ledger/2026-10-21-span16-store-after-tstep-shift-promoted.md`.
>
> **Earlier Span16 setup-store placement (2026-10-21):** placing the
> `advancetable` store after the `sfracf` reload but before the T-step shift
> averaged **15.537294000 FPS** against **15.537290333 FPS** control
> (**+0.000003667 FPS, +0.00002360%**). It was promoted then and is now
> superseded in source by the post-shift schedule. See
> `docs/ledger/2026-10-21-span16-advancetable-store-hoist-promoted.md`.

> **Span16 deferred `tfracf` reload (2026-10-21):** delaying the reload until
> after the `advancetable+4` store and cachewidth addition averaged
> **15.537299333 FPS** against **15.537290667 FPS** for control
> (**+0.000008667 FPS, +0.00005580%**). Exact frame/checksum parity held and the
> complete linked i486 audit passed. The positive mean qualifies regardless of
> spread; see
> `docs/ledger/2026-10-21-span16-deferred-tfracf-reload-promoted.md`.

> **Span16 base-store order screen (2026-10-21):** moving the `advancetable+4`
> store ahead of the `tfracf` reload in both setup arms averaged **15.537288333
> FPS** against **15.537290667 FPS** for control across three alternating
> pairs (**−0.000002333 FPS**). Exact frame/checksum parity held; the negative
> pooled mean was rejected and the original order restored. The visual screen
> skipped the ISA audit. See
> `docs/ledger/2026-10-21-span16-base-store-before-tfracf-screen-rejected.md`.

> **Z-span timing update (2026-10-20):** the i486 `D_DrawZSpans` middle loop now
> handles sixteen pixels per iteration for both gradient directions. The
> unroll is promoted: six added strict samples averaged 15.531288 FPS, and all
> nine candidate samples averaged 15.518568667 FPS (**+0.0792%** against the
> matched control mean), including one slow outlier. Exact framebuffer parity
> and the linked i486 audit passed; see
> `docs/ledger/2026-10-20-zspan-middle-unroll16.md`.
>
> **Z-span unroll follow-up (2026-10-20):** a 32-pixel main-loop group
> averaged **15.534157 FPS** against the current 16-pixel control's
> **15.536974 FPS** (**−0.01813%**) with exact framebuffer parity. All three
> samples were slower; the visual-only screen skipped the ISA audit, and the
> 16-pixel grouping remains active. See
> `docs/ledger/2026-10-20-zspan-middle-unroll32-rejected.md`.
>
> **Texture-span recheck (2026-10-20):** the prior `loadfirst` schedule was
> remeasured against the current build after removing the old gain floor. Its
> nine-run average matched the ten-run control to the displayed precision, and
> the follow-up control/candidate block means were identical. It remains an
> opt-in experiment; see
> `docs/ledger/2026-10-20-texture-span-loadfirst-recheck.md`.
>
> **Texture-span store recheck (2026-10-20):** six `dword`-store samples
> averaged 15.425266 FPS against the current word-store control's 15.531288
> FPS, with exact frame/checksum parity. The visual-only screen skipped the
> ISA audit; the measured slowdown rejects the candidate. See
> `docs/ledger/2026-10-20-texture-span-dword-recheck.md`.
>
> **Texture-span tail-store screen (2026-10-20):** `TextureSpanTailStores=word`
> averaged **15.358172 FPS** against the current **15.536975 FPS** build
> (**−1.1508%**) with exact frame/checksum parity. The visual-only screen
> skipped the ISA audit; the measured slowdown rejects the candidate and
> `control` remains the default. See
> `docs/ledger/2026-10-20-texture-span-tail-word-rejected.md`.
>
> **RenderFace timing update (2026-10-20):** the assembly-only cache-offset
> reuse in `R_RenderFace_asm486` and its owner-compare fusion are both promoted.
> The follow-up fusion gained **+0.01623%** over the prior promoted source, with
> exact checksum parity and a strict linked i486 audit. The cached-offset load
> hoist (**−0.01029%**), branchless surfedge magnitude (**−0.04172%** over six
> samples), and larger triangle/quad unroll (**−0.00317%**) were measured
> slower and removed. See the five
> `2026-10-20-renderface-*.md` ledger entries.

> **RenderFace branch-layout update (2026-10-21):** making positive surfedges
> the taken branch in both regular and submodel loops averaged **15.537297333
> FPS** in the strict three-run set, **+0.0020768%** over the preceding
> promoted source. All runs retained the 969-frame checksum and the linked
> i486 audit passed. The positive three-run pooled mean qualifies even though
> it is below the run-to-run spread; no minimum gain is required. See
> `docs/ledger/2026-10-21-renderface-positive-edge-branch-layout.md`.

> **Texture-span `stosw` screen (2026-10-21):** the `TextureSpanStores=stosw`
> assembly variant averaged **15.522019667 FPS**, **−0.0983%** against the
> promoted indexed word-store control. All samples retained the 969-frame
> checksum and were slower; the parity-only screen skipped the ISA audit. The
> indexed word-store path remains the default. See
> `docs/ledger/2026-10-21-texture-span-stosw-rejected.md`.

> **Texture-span early-store schedule (2026-10-21):** promoted under the
> positive-mean rule. The twelve-run pooled mean was **15.537298083 FPS** versus
> **15.537297833 FPS** for control (**+0.0000016%**). The delta is inside run
> variation; all 24 samples retained 969 frames and checksum `1047377823`. The
> candidate passes the strict linked i486 audit. See
> `docs/ledger/2026-10-21-texture-span-early-store-promoted.md`.

> **Texture-span load-first plus early-store combination (2026-10-21):** the
> strict candidate averaged **15.537288333 FPS** against **15.537291333 FPS**
> for control (**−0.0000193%**). All six runs retained 969 frames and checksum
> `1047377823`; the candidate's complete linked i486 audit passed. The negative
> mean rejects this combination, while the separately promoted early-store
> schedule remains active. See
> `docs/ledger/2026-10-21-texture-span-loadfirst-early-store-rejected.md`.

> **Alias-raster depth-store schedule (2026-10-21):** moving the Z-buffer word
> store after the colormap lookup averaged **15.537301333 FPS** against
> **15.537289333 FPS** for control (**+0.0000772%**) across three alternating
> pairs. All six runs retained 969 frames and checksum `1047377823`; the strict
> linked i486 audit and a direct strict-binary parity run passed. See
> `docs/ledger/2026-10-21-alias-raster-depth-store-reorder.md`.
>
> **Alias-raster pre-lookup depth store (2026-10-21):** moving the Z-buffer
> store after the texel load and before light/colormap work averaged
> **15.537295667 FPS** against **15.537289667 FPS** for the preceding schedule
> (**+0.0000386%**) over three alternating pairs. The positive pooled mean
> qualifies even though it is smaller than the paired spread. All six runs
> retained 969 frames and checksum `1047377823`; the complete linked i486 audit
> and a direct strict-binary parity run passed. See
> `docs/ledger/2026-10-21-alias-raster-prelookup-depth-store-promoted.md`.

> **Z-span accumulator schedule (2026-10-21):** moving the second Z-step
> arithmetic to immediately before each packed framebuffer store averaged
> **15.537298667 FPS** over three candidate samples, against a pooled control
> mean of **15.499629667 FPS** (**+0.2430%**). One control sample at
> **15.424306 FPS** drives most of that delta; the other two pairs alone show
> a smaller positive mean. All six runs retained 969 frames and checksum
> `1047377823`; the strict linked i486 audit and direct strict-binary parity
> run passed. The candidate is promoted under the positive-mean rule. See
> `docs/ledger/2026-10-21-zspan-step-before-store-promoted.md`.

> **Z-span step before sign branch (2026-10-22):** advancing the accumulator
> before the add/sub pair's sign check averaged **15.601289 FPS** against the
> strict control's **15.601303 FPS** (**−0.000014 FPS, −0.00008974%**). The
> trailing control was **15.601297 FPS**. All seven runs retained 969 frames
> and checksum `1047377823`; the complete strict i486 audit passed. The
> negative mean rejects the schedule and the original branch order is restored.
> See `docs/ledger/2026-10-22-zspan-step-before-sign-branch-rejected.md`.

> **Z-span sign-check/copy order (2026-10-21):** moving `testl %edx,%edx`
> before `movl %edx,%eax` in the add/sub pair macros passed exact output parity
> and the complete strict i486 audit, but averaged **15.537287333 FPS** against
> **15.537292000 FPS** for control (**−0.000004667 FPS**). All six runs matched
> 969 frames and checksum `1047377823`. Its negative pooled mean rejects the
> reorder, leaving the original instruction order active. See
> `docs/ledger/2026-10-21-zspan-sign-check-before-copy-screen-rejected.md`.

> **Z-span step between `SHLD` and `ROR` (2026-10-21):** the parity-only
> screen averaged **15.537290333 FPS** against fresh control at
> **15.537285333 FPS**, but the audited strict candidate averaged
> **15.537294333 FPS** against strict control at **15.537297000 FPS**
> (**−0.000002667 FPS**). All runs retained 969 frames and checksum
> `1047377823`, and the complete strict i486 audit passed. The negative strict
> mean rejects the schedule. See
> `docs/ledger/2026-10-21-zspan-step-between-shld-ror-screen-rejected.md`.

> **Edge-scan surface-base register cache (2026-10-21):** the parity-only
> screen averaged **15.538371667 FPS** against control at **15.537290333 FPS**
> (**+0.001081333 FPS**), but the audited strict candidate averaged
> **15.500427 FPS** after a 15.424542 FPS third sample. All runs retained 969
> frames and checksum `1047377823`; the full i486 audit passed. Including every
> sample gives a negative strict delta of **−0.036870 FPS**, so the cache is
> rejected and reverted. See
> `docs/ledger/2026-10-21-edge-scan-surface-base-cache-screen-rejected.md`.

> **Edge-scan bottom-tested row loop (2026-10-21):** moving the scanline bound
> test to the loop bottom removed the unconditional jump from each main-row
> iteration. The strict mean was **15.538384 FPS** against control at
> **15.537297 FPS** (**+0.001087 FPS, +0.00699607%**); the parity screen was
> also positive by **+0.001092333 FPS**. All runs retained 969 frames and
> checksum `1047377823`, and the complete strict i486 audit passed. The change
> is promoted under the any-positive rule. See
> `docs/ledger/2026-10-21-edge-scan-bottom-tested-row-loop-promoted.md`.

> **Edge-scan surface-index decode (2026-10-21):** reading `et_surfs` as two
> unsigned halfwords removed the packed-field copy and masks from each edge
> iteration. The strict three-run mean was **15.564254 FPS**, **+0.025870 FPS
> (+0.16649093%)** over the active strict control at **15.538384 FPS**. The
> parity-screen mean was **15.564257 FPS**. All runs retained 969 frames and
> checksum `1047377823`; the full strict i486 gate passed with zero
> above-i486, unknown, or exempt instructions. Promoted under the any-positive
> rule. See `docs/ledger/2026-10-21-edge-scan-surface-index-decode-promoted.md`.

> **Edge-scan leading-pointer retention (2026-10-21):** precomputing the
> leading-surface pointer before `TrailingEdge` let the both-edge path reuse
> `%edi` after the helper and skip the post-call `surfaces` reload. The strict
> mean was **15.564256667 FPS** against **15.564254 FPS** for control
> (**+0.000002667 FPS, +0.0000171354%**); the parity-screen mean was also
> positive by **+0.000001667 FPS**. All runs matched 969 frames and checksum
> `1047377823`, and the full strict i486 gate passed. Although the gain is
> smaller than the observed spread, it qualifies under the any-positive rule.
> See `docs/ledger/2026-10-21-edge-scan-leading-pointer-retained-promoted.md`.

> **Surface-cache hit key-pointer retention (2026-10-21):** keeping the
> `r_drawsurf.lightadj` pointer live across the style sentinel check and
> removing its reload averaged **15.537292667 FPS** against **15.537291333 FPS**
> for control (**+0.00000858%**). All six runs retained 969 frames and checksum
> `1047377823`; the complete linked i486 audit passed. This positive pooled
> mean is promoted under the user's no-minimum-gain rule even though it is
> smaller than the run spread. The preceding load-gap variant tied and was
> removed. See
> `docs/ledger/2026-10-21-surface-cache-hit-key-pointer-retained-promoted.md`.

> **Surface-cache single-style fall-through (2026-10-21):** the strict
> three-run mean was **15.499113 FPS** against the promoted key-pointer
> control's **15.537292667 FPS** (**−0.245729%**). One sample at 15.422742 FPS
> is a clear outlier but remains in the pooled mean. All six runs retained the
> expected checksum and the candidate passed the complete i486 audit; its
> negative mean rejects this branch layout. See
> `docs/ledger/2026-10-21-surface-cache-hit-single-style-fallthrough-rejected.md`.

> **Surface-cache texture preload (2026-10-21):** loading the requested texture
> pointer before testing the cache dynamic-light flag averaged **15.537290667
> FPS** against the promoted key-pointer control's **15.537292667 FPS**
> (**−0.000002 FPS, −0.00001287%**). All six runs retained 969 frames and
> checksum `1047377823`; the candidate passed the complete strict i486 audit.
> Its negative pooled mean rejects the ordering. See
> `docs/ledger/2026-10-21-surface-cache-hit-texture-preload-rejected.md`.

> **Surface-cache texture check first (2026-10-21):** moving the requested
> texture comparison ahead of the dynamic-light flag test averaged
> **15.537286667 FPS** against the promoted key-pointer control's
> **15.537292667 FPS** (**−0.000006 FPS, −0.00003862%**). All six runs retained
> 969 frames and checksum `1047377823`; the candidate passed the complete strict
> i486 audit. Its negative pooled mean rejects the order. See
> `docs/ledger/2026-10-21-surface-cache-hit-texture-check-first-rejected.md`.

> **Mip-2 horizontal-flat surface block (2026-10-21):** the assembly-only
> four-row specialization passed exact parity and the complete strict i486
> audit, but averaged **15.537008 FPS** against **15.537292667 FPS** for the
> promoted-source control (**−0.000284667 FPS, −0.00183215%**). All six runs
> retained 969 frames and checksum `1047377823`; the negative mean rejects it.
> See `docs/ledger/2026-10-21-surf8-mip2-horizontal-flat-rejected.md`.

> **Mip-2 source texel-load schedule (2026-10-21):** loading texels 2 and 3
> before the light-delta save and shift averaged **15.537300 FPS** against
> **15.537292667 FPS** for control (**+0.000007333 FPS, +0.00004720%**). The
> positive pooled mean qualifies even though it is below the run spread. All
> six runs retained 969 frames and checksum `1047377823`; the strict linked
> i486 audit passed. This schedule is promoted. See
> `docs/ledger/2026-10-21-surf8-mip2-texel-loads-promoted.md`.

> **Mip-2 row-state reload schedule (2026-10-21):** moving the `lightright`
> and `lightdelta` reloads ahead of the final two colormap reads averaged
> **15.537290667 FPS** against the promoted texel-load control's **15.537300000
> FPS** (**−0.000009333 FPS, −0.00006007%**). All six runs retained 969 frames
> and checksum `1047377823`; the strict linked i486 audit passed. The negative
> pooled mean rejects this schedule, leaving the separate texel-load promotion
> active. See
> `docs/ledger/2026-10-21-surf8-mip2-rowstate-reload-rejected.md`.

> **Mip-2 light-delta reload prefetch (2026-10-21):** moving only the
> `lightdelta` reload between the final two colormap reads averaged
> **15.537292 FPS** against the promoted texel-load control's **15.537300 FPS**
> (**−0.000008 FPS, −0.00005149%**). All six strict runs retained 969 frames
> and checksum `1047377823`; the full linked i486 audit passed. The negative
> pooled mean rejects this isolated move. See
> `docs/ledger/2026-10-21-surf8-mip2-lightdelta-prefetch-rejected.md`.

> **Mip-2 texel-read order screen (2026-10-21):** swapping the texel 2 and
> texel 3 loads averaged **15.537293667 FPS** against the promoted order's
> **15.537300000 FPS** (**−0.000006333 FPS, −0.00004076%**). All three runs
> retained 969 frames and checksum `1047377823`; the parity-only screen skipped
> the ISA audit. Its negative mean leaves the promoted load order active. See
> `docs/ledger/2026-10-21-surf8-mip2-texel-read-order-screen-rejected.md`.

> **Implementation update (2026-10-04):** `D_DrawSkyScans8` now has a complete
> selectable i486 assembly path, including viewport/time setup, UV projection,
> vector normalization, span interpolation, and pixel sampling. Direct UV and
> framebuffer parity pass; C remains selectable. `D_WarpScreen` is also a
> selectable full assembly entry point, including ratio setup, lookup tables,
> time phase, and pixel copy. Table generation is slower in isolation, so C
> remains the default. `D_DrawSolidSurface` now has a selectable assembly span
> fill; its isolated benchmark is 5.128% faster, but the pinned demo does not
> exercise the optional `r_drawflat` path, so C remains the default. See
> `docs/ledger/2026-10-04-renderer-assembler-port.md`.

> **Turbulent scan update (2026-10-04):** `Turbulent8` now has a selectable
> full i486 assembly entry for phase/setup, span traversal, projection,
> interpolation, and chunk handling. Direct parity passed across 13 span counts,
> six phases, and four x87 rounding modes with the `stosb`, ASM, and C inner
> loop choices.
> C remains the default because the separate timedemo samples were not paired
> and included an outlier; see the renderer-port ledger for the measurements.

> **Dynamic-light update (2026-10-04):** `R_AddDynamicLights` now has selectable
> i486 assembly for sparse light-bit traversal, x87 projection, surface culling,
> and sample-helper dispatch. `R_DlightContributes` also has a selectable
> assembly predicate using the shared projector. The 36-case projection and
> predicate harness, 11-case lightmap harness, release smoke, ISA gate, and
> pinned checksum passed; C remains the default. `D_CacheSurface` now has
> assembly cache-hit, key-load, miss-path metadata, texture/style tag, rover
> allocator, attachment, dispatch, and dynamic-light tag paths. Texture animation,
> high-level hit/miss policy, and profile accounting remain in C at this earlier
> helper-only stage. The complete public cache entry is covered below.
> See the renderer-port ledger.

> **Surface draw update (2026-10-04):** `R_DrawSurface` now has a selectable
> complete i486 assembly entry. Its 40-case parity harness covers four mips,
> POT and NPOT textures, five lightmap modes, output scratch, `blocklights`,
> and renderer globals. Smoke, the i486 gate, and a pinned 969-frame checksum
> passed; the single timedemo sample is not performance evidence. C remains
> the release default. The render-time dependency closure remains open; see
> the renderer-port ledger.

> **Alias-frame setup update (2026-10-07):** `R_AliasSetupFrame` now has a
> selectable i486 assembly helper for single and grouped model-frame
> resolution. Fifty-six direct comparisons passed across four x87 rounding
> modes. A two-repeat Demo 2 pair matched all 980 post-warmup checksums per
> run and both complete indexed captures and palettes. Selected-object and
> linked-runtime audits passed; C remains the release default. Alias skin
> selection and gradient setup have since received focused implementations;
> see the renderer-port ledgers.

> **Alias-skin setup update (2026-10-07):** `R_AliasSetupSkin` now has a
> selectable i486 assembly helper for single and grouped skin resolution.
> Fifty-six direct comparisons passed across four x87 rounding modes. A
> two-repeat Demo 2 pair matched all 980 post-warmup checksums per run and
> both complete indexed captures and palettes. Selected-object and linked
> runtime audits passed; C remains the release default. See the
> renderer-port ledger.

> **Alias-gradient setup update (2026-10-07):** `D_PolysetCalcGradients` now
> has an explicit C-reference/assembly selector around the existing i486 x87
> routine. Eight direct cases matched eleven gradient outputs, including the
> determinant-versus-reciprocal handoff and x87 control-word behavior. A
> two-repeat Demo 2 pair matched all 980 post-warmup checksums and complete
> indexed captures and palettes on both repeats. Object and linked-runtime
> i486 audits passed. Assembly remains the i486 default, preserving the
> existing path; see the renderer-port ledger.

> **Alias line-scan setup update (2026-10-07):**
> `D_PolysetSetUpForLineScan` now has a selectable i486 assembly path for
> small-table lookup and larger positive-edge division. The 16,416-case
> direct fixture passed across all table pairs, long edges, extreme signed
> coordinates, and four x87 rounding modes. A two-repeat Demo 2 pair matched
> every post-warmup checksum and complete indexed capture and palette on both
> repeats. Object and linked-runtime ISA audits passed; assembly is the i486
> default. Large invalid heights retain the C error path. See the
> renderer-port ledger.

> **Surface-cache entry update (2026-10-04):** `D_CacheSurface` now has a full
> selectable i486 assembly entry for texture call guarding, cache hit/miss flow,
> metadata setup, allocation handoff, tag writes, draw dispatch, and sticky
> dynamic-light state. The four-mip public-entry hit harness and helper suite
> passed. The combined cache/draw assembly selectors passed smoke and a pinned
> 969-frame checksum; one timing sample is not a speed claim. The C entry remains
> the release default. `R_TextureAnimation` frame resolution and PROFILE486
> accounting still use C helpers; the remaining render-time dependency closure
> is open.

> **Texture-animation entry update (2026-10-04):** `R_TextureAnimation` now
> has a full selectable i486 assembly entry for alternate textures, the static
> fast path, x87 time conversion, signed phase remainder, and frame lookup. The
> C/assembly harness passed 25 time values across primary, alternate, and static
> paths in all four x87 rounding modes. The complete-entry microbenchmark was
> 2.666% faster for assembly; smoke, the 168-instruction ISA gate, and a pinned
> 969-frame checksum passed. One timedemo sample is not a performance comparison.
> Assembly remains the selector default; the renderer dependency closure is open.

> **Mip-selector entry update (2026-10-04):** the selected assembly build now
> exports `D_MipLevelForScale` directly from the x87 threshold routine, with no
> C forwarding entry. Eight threshold and clamp cases matched C, release smoke
> and the pinned 969-frame checksum passed, and the ISA gate remained at 168
> enforced above-i486 instructions. The helper microbenchmarks are mixed, so C
> remains the release default.

> **Face-depth update (2026-10-05):** `R_SetSurfaceZGradients` now has a
> selectable i486 assembly entry with the same plane/entity/frame cache and
> x87 operation order as the C reference. Its 32-case parity harness passed
> across cache-key changes and all four x87 rounding modes; release smoke, the
> 168-instruction ISA gate, and the pinned 969-frame checksum also passed. The
> single timedemo run is not a speed comparison, so C remains the release
> default; see the renderer-port ledger.

> **Texture-gradient update (2026-10-05):** `D_CalcGradients` now has a
> selectable i486 assembly path that owns the x87 gradient arithmetic and a
> separate texture-axis cache. Its 20-case harness passed across mip levels,
> cache hits and key changes, and all four x87 rounding modes. Release smoke,
> the 168-instruction ISA gate, and the pinned 969-frame checksum passed; the
> single timedemo sample is not a speed comparison, so C remains the default.
> `D_DrawSurfaces` now has a selectable assembly dispatcher; the world walk has
> since gained a selectable assembly entry, while shared callees and the
> remaining helper closure stay open. See the ledger.

> **Surface-dispatch update (2026-10-05):** `D_DrawSurfaces` now has a
> selectable i486 assembly dispatcher for surface traversal, mip-scale setup,
> draw-mode selection, Z-gradient loads, and brush-model/world-state changes.
> Its release build passed smoke and the ISA gate; the pinned 969-frame timedemo
> matched checksum `1047377823`. The 59.208935-second single sample is not
> performance evidence, so C remains the default. Cache, gradient, mip, and
> span-drawing helpers remain independently selectable; shared render-time
> callees and the full dependency closure remain open.

> **World-BSP update (2026-10-05):** `R_RecursiveWorldNode` now has a selectable
> assembly walk for culling, recursion, leaf marking, BSP keys, face selection,
> and polygon ordering. The pinned 969-frame checksum, smoke, and instrumented
> timedemo passed. Three assembly runs were 0.856% slower than the C median;
> this small regression is accepted, and assembly is now the i486 default.
> C remains selectable and i386 remains on C. `R_RenderFace`, `R_RenderBmodelFace`, and
> `R_StoreEfrags` now also have selectable assembly entries. The combined
> selectors passed smoke and the pinned framebuffer checksum; a single timedemo
> sample is not a performance comparison. `R_ClipEdge` and edge
> projection/emission already use legacy handwritten assembly under `id386`,
> and `R_EmitCachedEdge` now has a separate selector. `R_RenderPoly` belongs to
> the optional polygon-driver branch; normal DOS span rendering leaves
> `r_drawpolys=0` and `D_DrawPoly()` is a no-op. See the renderer-port ledgers.

> **Brush-model clipping update (2026-10-05):** `R_RecursiveClipBPoly` now has
> a selectable i486 assembly implementation with its C reference retained.
> The i486 build and selector contract passed; C and assembly each completed
> the pinned 969-frame demo with checksum `1047377823`. Matched intermediate
> captures reproduced the wall leak: the wrong x87 divide direction produced
> off-plane vertices and 17 edge overflows. The corrected `fdivrp` path has an
> intact wall and zero overflows. The single timings are not comparative
> evidence; see the brush-model clipping ledger.

> **Alias vertex-preparation update (2026-10-05):** `R_AliasPreparePoints` now
> selects a hand-written i486 loop for transform dispatch, near-plane
> classification, projection dispatch, and viewport clip flags. The control
> and local C loops remain selectable; the triangle clipping/draw loop is still
> C. Smoke and the selector contract passed, and C-control and assembly timedemo
> runs both produced 969 frames with checksum `1047377823`. The single timings
> do not justify promotion; see the renderer-port ledger.

> **World-render orchestration update (2026-10-05):** `R_RenderWorld` now has
> a selectable i486 assembly entry for render-state setup, the frame-local
> polygon queue, BSP dispatch, and optional back-to-front polygon replay. C
> remains the release default. The assembly run passed smoke and the pinned
> 969-frame checksum. C and assembly frame captures were byte-identical, but
> the user-reported live-display smear remains under investigation because a
> buffer capture does not validate the DOSBox-X window presentation.

> **Sprite-draw orchestration update (2026-10-07):** `D_DrawSprite` now has a
> selectable i486 assembly entry for vertex bounds, scan rounding, local span
> storage, cache setup, closing-vertex copy, and dispatch to its independently
> selectable sprite stages. The direct C/assembly fixture matched color and
> depth buffers in all three cases; the two-repeat Demo 2 pair matched all 980
> post-warmup frame checksums and every captured palette index and palette
> byte. `D_SpriteDrawSpans` is the preexisting `id386` 8-bit assembly
> rasterizer. C remains selectable; see the renderer-port ledger.

> **Sprite-setup orchestration update (2026-10-07):** `R_SetupAndDrawSprite`
> now has a selectable i486 assembly entry for poster construction, world
> frustum clipping, view transformation, near-plane handling, projection, and
> dispatch. Five direct C/assembly fixtures match clip vertices, projected
> vertices, `nearzi`, color, and depth exactly. A two-repeat Demo 2 pair matched
> all 980 post-warmup frame checksums and the complete captured indexed frame
> and palette on both repeats. The focused object and linked-runtime i486 audits
> passed. Assembly is now the i486 default; C remains selectable and i386 remains C. See the renderer-port ledger.

> **Alias-lighting setup update (2026-10-07):** `R_AliasSetupLighting` now
> has a selectable i486 assembly entry for ambient and shade setup plus light
> vector rotation. Its 24 direct cases passed exact comparison across all four
> x87 rounding modes, and object and linked-runtime audits passed. A focused
> two-repeat Demo 2 pair matched all 980 post-warmup checksums per run and both
> complete indexed captures and palettes. C remains the release default; see
> the renderer-port ledger.

> **Alias matrix-setup update (2026-10-07):** the `asm` setting for
> `AliasMatrixCompositionImplementation` now selects assembly for view-basis
> setup and both matrix products in `R_AliasSetUpTransform`. Three view-basis
> fixtures and the fractional and translation-order matrix fixtures matched
> exactly. Two repeated Demo 2 runs matched all 980 post-warmup checksums plus
> both complete indexed captures and palettes. The selected and linked i486
> audits passed; assembly is now the i486 default while both C choices remain
> selectable. See the renderer-port ledger.

> **Lightmap dispatcher update (2026-10-04):** `R_BuildLightMap` now has a
> selectable full i486 assembly dispatcher, with the C dispatcher retained as
> the release default and benchmark reference. Eleven focused scenarios passed
> with assembly helpers and C helper variants. Both release selectors passed
> smoke and retained the pinned 969-frame checksum; the single timing pair was
> inconclusive. At that point `R_AddDynamicLights` orchestration was the next
> open entry; it has since gained a selectable assembly path, followed by cache
> miss-path work. `R_DrawSurface` now has a selectable assembly entry; current
> next work is the remaining rendering-time dependency closure;
> see the renderer-port ledger.

## Historical optimization survey conclusion

The earlier performance survey identified the highest-value parts to convert
to pure 32-bit assembler as tight,
integer-heavy raster loops. The renderer does not benefit from converting the
entire engine or every C function. High-level orchestration, floating-point
setup, recursion, and pointer-heavy control flow should remain in C unless a
profile identifies a very specific hot path.

**This survey is now closed as an optimization roadmap.** The alias-model path
was subsequently instrumented down to the source level and the remaining C
(`linescan-setup`, `edge-setup`, `span-package`, `step-math`, `SetEdgeTable`)
looked converged. **That convergence verdict was withdrawn on 2026-10-01**: the
per-call figures behind it (253-304 cycles/call) were measured with a profiler
whose own timer reads cost ~193 cycles, so 62-76% of each number was the clock.
Re-measured with the scope amortized to one per triangle, the C glue costs
1.83 s, a 3.1x overstatement — still thin, but now measured rather than assumed.
See `ledger/2026-10-01-attribution-corrections.md`, under "Alias attribution corrected".

The two large regions that measurement *does* trust, and that had never been
decomposed, are `world-bsp` (10.2% of frame, `R_RecursiveWorldNode` plus the
~800-line `R_RenderFace`, `R_ClipEdge` and `R_EmitCachedEdge`) and `edge-scan`
(8.0%, 1,373 cycles per scanline). Further work should not be chosen from this
list. Before spending a timedemo on any 486-specific idea, read "What this
harness can and cannot measure" in `ledger/2026-09-29-harness-and-cost-model.md`: DOSBox-X does not model
x87 latency, fetch boundaries, write-buffer occupancy, or 486 L1 cache
occupancy and replacement, so a measured null for those is weak evidence. Equal
4 KB offsets only establish same-set mapping, not a cache conflict; see the
2026-10-30 cache-layout correction. Optimization effort belongs with ideas
paid for in instruction count, memory traffic, or arithmetic.

> **Both of those regions were decomposed on 2026-10-02, and the answer was no.**
> Eleven dead-scratch probes priced them:
>
> - **`edge-scan`** is now **78% mapped, 159.2x the gate** against the profiler's
>   203.9x, as sixteen named blocks. The largest, `LNextEdge`, is 23.2x; the
>   smallest 0.9x. The four loops this file previously called "the edge routines"
>   turned out to be only 52x of a 204x bucket — most of the bucket was
>   per-edge dispatch that had never been looked at.
> - **`renderface`** is **priced at ~15.8x the gate** of C scaffolding, not the
>   70-90x an earlier estimate suggested. Its remainder is `R_ClipEdge` /
>   `R_EmitCachedEdge`, which is the essential x87 edge emit.
>
> So the "consider only a measured inner loop" advice in the Face/edge row below
> has been carried out and returned nothing. **Read the two map entries in
> `../ASM486-HANDOFF.md` and `ledger/INDEX.md` before choosing anything from this table.**

> ### 2026-10-03 — and a third region, which is now the largest open pool
>
> The two above were the *last two unexamined* closures, not the only ones left
> on an argument. A twelfth probe re-opened the biggest bucket in the renderer:
>
> - **`texture-spans`** is the largest pool in the renderer at ~24% of frame, and
>   it was closed on the claim that its per-segment setup is *"dominated by two x87
>   stores — a blind axis"*. **That is measured false.** `d_draw16.s` carries 125
>   x87 instructions out of 619, and they are in the entry divide, the
>   `LNotLastSegment` advance and the tail path — **none in the setup**. Six
>   instructions of that setup cost 0.6186% of frame, so the ~23-instruction
>   integer setup is **2.37% of frame, 47x the promotion gate**.
>
>   No candidate yet. Four reductions are recorded dead in `ledger/INDEX.md`.
>
> ### 2026-10-03, later — the clamp fusion was built, and it measured **0.0000%**
>
> The most promising of those four was the clamp fusion, nominally 0.206% and 4.1x
> the gate. The rejection said it fails because the scratch-register copy costs what
> the fusion saves, "worth revisiting if a register can be freed elsewhere first."
> **That was wrong by one instruction** — `leal -4096(%ebp),%eax` computes into the
> scratch register directly — so the candidate was buildable, and was built. It then
> measured **0.0000%**: at least 4,118,036 instructions removed, 0.206% predicted, 12
> microseconds gained, checksum-clean.
>
> **And the probe that explains it corrects the pricing rule for the whole file.**
> Four instructions of the identical shape *added* to the identical path cost
> +0.4112% at 0.988 cycles each. Every probe behind every number in the table below
> measured the cost of *adding* work; none measured what a *removal* is worth, and a
> region can charge full price for one and nothing for the other. So **the
> `edge-scan` and `renderface` prices above are additions-side prices**, they remain
> the right way to decide where to look, and **they must not be used to close
> anything.** The `texture-spans` setup is dependency-bound and is not reachable by
> instruction removal at all — only by shortening its loop-carried carry chain,
> which is a different question with no hypothesis yet.
>
> **This changes what this table is for.** The table below lists candidate *areas*
> for assembler conversion. After 2026-10-03 the best-evidenced optimisation target
> in the renderer is not on it, and is not a conversion at all — it is the
> loop-carried dependency chain of existing hand-written DDA assembly in
> `d_draw16.s`. **Read the `texture-spans` entries in `ledger/INDEX.md` before
> choosing anything from this table.**

## Candidate areas

The lightmap-combination helper is implemented as the selectable
`R_BuildLightMapStyles_asm486` path. The full `R_BuildLightMap` dispatcher and
the dynamic-light orchestration and projection now have selectable assembly
entries. Their C references remain available; exact parity and the full i486
ISA gate are required, and the pinned timedemo decides performance under the
any-positive pooled-mean rule.

| Area | Location | Feasibility | Recommended boundary |
|---|---|---:|---|
| Active dynamic-light enumeration | `src/r_light.c:R_PushDlights` | **Implemented and promoted for i486** | `DynamicLightPushImplementation=c|asm` selects the 32-slot active-light loop and dispatch to `R_MarkLights`. Five direct fixture cases passed; six scenes, two repeats each, had exact frame checksums and exact 320x200 framebuffer/palette captures. Assembly is the i486 default; C remains selectable and i386 remains C. See the R_PushDlights ledger. The four-path combined profile also passed six-scene exact parity. |
| Lightmap combination | `src/r_surf.c:R_BuildLightMap` | Implemented; assembly not promoted | The assembly dispatcher owns bounds, cache, path selection, dynamic-light dispatch, and normalization calls. A matched three-run comparison measured the C dispatcher **+0.0124666%** faster with exact checksum parity and a full strict i486 audit; C remains the release default. See the [2026-10-28 selector comparison](ledger/2026-10-28-lightmap-build-assembly-rejected.md). |
| Dynamic-light accumulation | `src/r_surf.c:R_AddDynamicLights` | Implemented | Assembly owns sparse light-bit traversal, x87 projection, culling, and dispatch; the texel sample loop remains independently selectable. |
| BSP dynamic-light marking | `src/r_light.c:R_MarkLights` | **Implemented and promoted for i486** | `MarkLightsImplementation=c|asm` selects the recursive i486 BSP walk. The 128-case x87 fixture, exact Demo 1 comparison, and six-scene paired comparison with transient notices disabled passed. With notices enabled, the only captured differences were expiring console text in rows 1–23; all other framebuffer pixels and palettes matched. Assembly is the i486 default, C remains selectable, and the separate i386 default remains C. See the renderer-port ledger. The four-path combined profile also passed six-scene exact parity. |
| Alias setup | `src/r_alias.c:R_AliasPreparePoints`, `R_AliasSetViewMatrix`, `R_AliasSetUpTransform`, `R_AliasSetupLighting`, `R_AliasSetupFrame`, `R_AliasSetupSkin`, `src/asm486_experiments.s:R_AliasSetViewMatrix_asm486`, `R_ConcatTransforms_asm486`, `src/r_aclip.c` clipping, `src/d_polyse.c:D_PolysetCalcGradients`, `D_PolysetSetUpForLineScan`, `D_PolysetSetEdgeTable`, `D_PolysetUpdateTables`, and `D_RasterizeAliasPolySmooth` | **Partial, not promoted** | `AliasPrepareImplementation=control|local|asm` selects the C control reference, a local C-loop variant, or the i486 clipped-vertex assembly loop; `asm` is now the i486 default and passed two-repeat exact Demo 2 parity. `AliasMatrixCompositionImplementation=c|special|asm` selects generic C, the specialized diagonal C path, or assembly view-basis setup plus both `R_ConcatTransforms_asm486` products; three view-basis fixtures, two matrix fixtures, and two-repeat exact Demo 2 parity passed, and assembly is now the i486 default. `AliasClipImplementation=c|asm` selects the generic clip pass and triangle-level clipping orchestration; `AliasClipZImplementation=c|asm` independently selects the Z-plane intersection callback and requires `AliasClipImplementation=asm`. `AliasSetupLightingImplementation=c|asm` selects ambient/shade and light-vector setup; 24 direct cases and a two-repeat Demo 2 pair passed exact comparison. `AliasSetupFrameImplementation=c|asm` selects single/group alias model animation frame resolution; 56 direct cases and a two-repeat Demo 2 pair passed exact comparison. `AliasSetupSkinImplementation=c|asm` selects single/group skin resolution; 56 direct cases and a two-repeat Demo 2 pair passed exact comparison. `AliasGradientImplementation=c|asm` selects the existing x87 gradient routine; eight direct cases and a two-repeat Demo 2 pair passed exact comparison, and assembly remains the i486 default. `AliasLineScanImplementation=c|asm` selects table lookup and large-edge setup; 16,416 direct cases and a two-repeat Demo 2 pair passed exact comparison, and assembly remains the i486 default. `AliasEdgeTableImplementation=c|asm` selects the original 12-way signed-Y table lookup; 1,372 direct cases and a two-repeat Demo 2 pair passed exact comparison, and assembly remains the i486 default. `AliasSkinTableImplementation=c|asm` selects the cache-key comparison and 480 byte-stride skin-row pointers; 64 direct cases and a two-repeat Demo 2 pair passed exact comparison, and assembly remains the i486 default. `AliasRasterizeImplementation=c|asm` selects the triangle rasterization orchestration and span-package setup; the focused Demo 2 pair matched exactly on both repeats, and assembly remains the i486 default. Preserve projection, clipping, and triangle order exactly. |
| Alias left-edge scan | `src/d_polysa.s:D_PolysetScanLeftEdge` | **Implemented and promoted for i486** | The height load and mask are folded into a 16-bit memory `OR` on the low scan-counter word, saving two executed instructions per call. Three matched runs gained **+0.01139489%**, with exact 969-frame checksum parity and a complete strict i486 audit. See the [left-edge scan ledger](ledger/2026-10-28-d-polyset-scan-left-height-lowword-promoted.md). |
| Surface-cache checks | `src/d_surf.c:D_CacheSurface`, `src/r_surf.c:R_DlightContributes` | Medium | `R_DlightContributes`, the public `D_CacheSurface` hit/miss flow, cache key/setup/tag work, `D_SCAlloc`, cache attachment, draw dispatch, dynamic-light tag updates, and the `R_DrawSurface` entry have assembly paths; animation-frame resolution and PROFILE486 accounting still call C helpers. |
| Surface dispatch | `src/d_edge.c:D_DrawSurfaces` | Implemented | The selectable assembly dispatcher owns the per-frame surface loop; cache, gradient, mip, and drawing callees remain independent selectors. The world walk has its own assembly selector; shared render callees remain open. |
| BSP traversal | `src/r_bsp.c:R_RecursiveWorldNode` | **Implemented; C selected for i486** | `BspWalkImplementation=c|asm` selects the recursive walk; the assembly path remains available and preserves traversal and face order. Three alternating 320x200 `demo1` pairs measured C **+0.024255%** faster than assembly, with exact color/Z/PCX parity and complete strict i486 audits, so C is the current i486 default. i386 remains on C. See the [C-default promotion ledger](ledger/2026-11-11-bsp-walk-c-default-promoted.md). |
| World-render orchestration | `src/r_bsp.c:R_RenderWorld` | **Implemented, not promoted** | `RenderWorldImplementation=c|asm` selects the assembly setup, frame-local polygon queue, BSP dispatch, and optional polygon replay; C remains the release default. C and assembly timedemo PCX captures matched byte-for-byte; a strict three-pair 320x200 A/B measured assembly **0.0005144% slower**, so C remains selected. See the [selector timing ledger](ledger/2026-10-30-render-world-asm-timing-rejected.md). |
| Face/edge setup | `src/r_draw.c:R_RenderFace`, `R_RenderBmodelFace`, `R_EmitCachedEdge` | **`R_RenderFace` promoted for i486** | `RenderFaceImplementation=c|asm` selects the world-face path. A matched three-run comparison averaged **15.564252667 FPS** for assembly and **15.502609667 FPS** for C (**+0.39763%**); all six runs matched 969 frames and checksum `1047377823`, and the candidate passed the full linked strict i486 audit. The checked-in i486 profile already selects assembly; C remains selectable and i386 remains C. The separate B-model face and cached-edge paths retain their own selectors and port status. `R_ClipEdge` and edge projection/emission are legacy handwritten assembly under `id386`. See the [RenderFace promotion ledger](ledger/2026-10-22-renderface-assembly-promoted.md). |
| Entity efrags | `src/r_efrag.c:R_StoreEfrags` | **Implemented, not promoted** | `EfragStoreImplementation=c|asm` selects the list walk; compile-time layout checks protect its 32-bit field offsets. Combined renderer selectors passed the pinned checksum; C remains the release default. |
| Particle state and simulation | `src/r_part.c:R_ClearParticles`, `R_DrawParticles` | Implemented | `ParticleUpdateImplementation=c|asm` selects free-list initialization and particle simulation, including dead-list maintenance, draw order, position, velocity, and ramp updates. The C draw wrapper retains lifecycle and PROFILE486 glue; `D_DrawParticle` remains the existing driver rasterizer. C references remain independently selectable. |
| Particle rasterization | `src/d_part.c:D_DrawParticle_C`, `src/d_parta.s:D_DrawParticle` | **Existing assembly path, parity verified** | The 32-bit assembly rasterizer predates this tranche. `ParticleDrawImplementation=c|asm` exposes it beside the retained C oracle; this work verifies the existing routine rather than claiming a new assembly port. Its 104-case fixture passed across four x87 rounding modes, and the strict two-repeat `demo2-wizspike-event` pair matched seven post-warmup checksums and exact indexed-frame/palette captures. See the [`D_DrawParticle` verification ledger](ledger/2026-10-10-d-drawparticle-assembly-port.md). |
| Submodel polygon surfaces | `src/r_bsp.c:R_DrawSubmodelPolygons` | **Implemented, not promoted** | `SubmodelPolygonsImplementation=c|asm` selects the surface loop, x87 backface test, render-key update, and face dispatch. The assembly smoke and both C/ASM combined candidates passed the pinned checksum; their live captures landed at different demo times, so visual frame parity remains open. |
| Brush-model polygon clipping | `src/r_bsp.c:R_RecursiveClipBPoly` | **Implemented, not promoted** | `BmodelPolygonClipImplementation=c|asm` selects the recursive BSP edge clipper, intersection-vertex construction, clip-boundary edges, and visible-leaf dispatch. C and assembly passed the pinned checksum; matched `demo1` captures reproduced and then cleared the wall leak, with zero edge overflows after the x87 divide fix. |
| Animated sprite-frame selection | `src/r_sprite.c:R_GetSpriteframe` | **Implemented and promoted for i486** | `SpriteFrameImplementation=c|asm` selects single/group frame resolution with the original interval boundary and x87 conversion behavior. Twelve direct cases and a two-repeat Demo 2 comparison passed exactly; focused linked ISA audit passed. Assembly is now the i486 default; C remains selectable and i386 remains C. |
| Sprite draw orchestration | `src/d_sprite.c:D_DrawSprite` | **Implemented and promoted for i486** | `SpriteDrawImplementation=c|asm` selects vertex bounds/rounding, span storage, sprite cache setup, vertex closure, and stage dispatch, with C retained. Direct color/depth fixtures and a two-repeat Demo 2 pair passed exact comparison; sprite sub-stages remain independently selectable. Assembly is now the i486 default; C remains selectable and i386 remains C. It also passed the combined four-path, six-scene exact comparison. |
| Sprite setup orchestration | `src/r_sprite.c:R_SetupAndDrawSprite` | **Implemented and promoted for i486** | `SpriteSetupImplementation=c|asm` selects backface culling, poster construction, four-plane clipping, transform, near-plane clamp, perspective projection, `nearzi`, and draw dispatch. Five direct fixtures and a two-repeat Demo 2 pair passed exact frame/checksum comparisons; focused i486 object and linked-runtime audits passed. Assembly is now the i486 default; C remains selectable and i386 remains C. |
| Edge-drawing orchestration | `src/r_main.c:R_EdgeDrawing` | **Helper timings promoted; full live visual acceptance pending** | `EdgeDrawingImplementation=c|asm` selects stack-buffer setup, world dispatch, scans, Z-enable, brush-entity dispatch, and update flow. The assembly `r_dspeeds` helper uses an integer bit test, then caches the result in `EBX`; the changes gained **+0.000168667 FPS (+0.00108130%)** and **+0.000105667 FPS (+0.00067741%)** in successive strict three-run comparisons with exact checksum parity. See the [integer-truth ledger](ledger/2026-10-22-edge-drawing-dspeeds-integer-truth-promoted.md) and [cache ledger](ledger/2026-10-22-edge-drawing-dspeeds-cache-promoted.md). The full assembly route's live captures were coherent but landed at slightly different demo states, so visual acceptance remains pending. |
| Edge scanline loop | `src/r_edge.c:R_ScanEdges` | **Callback cache, surface-base cache, bottom-tested and two-/four-/eight-span clears, and twelve-/fourteen-span clears with grouped tails promoted; thirteen-span grouped-tail batch and zero-register fourteen-span stores rejected; fifteen-/sixteen-span batches rejected; full live visual acceptance pending** | `ScanEdgesImplementation=c|asm` selects the aligned span buffer, row loop, edge updates, span flushes, and final draw. C and ASM passed smoke and the pinned checksum. Caching `pdrawfunc` in `ESI` gained **+0.001084333 FPS (+0.00695142%)**; caching `surfaces` in `EDI` with the row limit in a local gained a further **+0.001120 FPS (+0.00717957%)** in successive strict three-run comparisons. The bottom-tested span-clear loop gained **+0.000087667 FPS (+0.00056193%)**; clearing two surfaces per iteration gained **+0.000101667 FPS (+0.00065167%)**; clearing four surfaces per iteration gained **+0.000099 FPS (+0.00063457%)**; clearing eight surfaces per iteration gained **+0.000033 FPS (+0.00021152%)**; grouping the eight-span tail into 4/2/1 spans gained **+0.000007 FPS (+0.00004487%)**; increasing the batch to twelve spans with an 8/4/2/1 tail gained **+0.000008333 FPS (+0.00005341%)**; increasing it to fourteen spans with the same tail gained **+0.000015 FPS (+0.00009615%)**, promoted on its positive mean despite overlapping samples. Thirteen spans was rejected at **−0.000000333 FPS (−0.00000214%)** against fourteen under the any-positive rule. Reusing zeroed ECX for the fourteen-span stores was rejected at **−0.000013667 FPS (−0.00008759%)** against immediate stores. Fifteen spans was rejected at **−0.000001 FPS (−0.00000641%)** against fourteen, and sixteen-span unrolling was rejected at **−0.015811333 FPS (−0.10134649%)** with one slow sample retained in the mean. All runs retained exact 969-frame checksum parity and passed the complete strict i486 audit. A local `max_span_p` comparison was tested and rejected at **−0.000010 FPS**. See the [callback-cache ledger](ledger/2026-10-22-scan-edges-callback-cache-promoted.md), [surface-base ledger](ledger/2026-10-22-scan-edges-surface-base-cache-promoted.md), [bottom-tested span-clear ledger](ledger/2026-10-22-scan-edges-clear-span-bottom-tested-promoted.md), [two-span unroll ledger](ledger/2026-10-22-scan-edges-clear-span-unroll2-promoted.md), [four-span unroll ledger](ledger/2026-10-22-scan-edges-clear-span-unroll4-promoted.md), [eight-span unroll ledger](ledger/2026-10-22-scan-edges-clear-span-unroll8-promoted.md), [eight-span grouped-tail ledger](ledger/2026-10-22-scan-edges-clear-span-unroll8-group-tail-promoted.md), [twelve-span grouped-tail ledger](ledger/2026-10-22-scan-edges-clear-span-unroll12-group-tail-promoted.md), [fourteen-span grouped-tail ledger](ledger/2026-10-22-scan-edges-clear-span-unroll14-group-tail-promoted.md), [thirteen-span rejection ledger](ledger/2026-10-22-scan-edges-clear-span-unroll13-group-tail-rejected.md), [zero-register store rejection ledger](ledger/2026-10-22-scan-edges-clear-span14-zero-register-rejected.md), [fifteen-span rejection ledger](ledger/2026-10-22-scan-edges-clear-span-unroll15-rejected.md), [sixteen-span rejection ledger](ledger/2026-10-22-scan-edges-clear-span-unroll16-rejected.md), and [max-span rejection ledger](ledger/2026-10-22-scan-edges-maxspan-local-cache-rejected.md). Full live-frame visual acceptance remains open. |
| Active-edge maintenance | `src/r_edge.c:R_InsertNewEdges`, `R_RemoveEdges`, `R_StepActiveU` | **Target-U schedule promoted inside replacement assembly; selector remains opt-in** | `EdgeListMaintenanceImplementation=legacy|c|asm` preserves the original `id386` assembly as the default, exposes the true C reference, and adds replacement i486 assembly. Target-U load caching improved the replacement assembly by **0.0596%** across three runs with exact checksum parity. The replacement assembly selector averaged **0.2193% slower** than `legacy` across three runs, so `legacy` remains the default. In the active legacy search, moving the `R_InsertNewEdges` fourth-probe successor load after its comparison tested **0.24775% slower**; preloading the first, second, and third `R_StepActiveU` successors tested **0.00371%, 0.00242%, and 0.00269% slower**, respectively. Moving the `R_StepActiveU` fourth-probe successor load before the U fetch/add, between the U fetch and add, after the U store, or between the order compare and branch tested **0.0000556%, 0.0000897%, 0.0001047%, and 0.0000150% slower**, respectively. All eight changes were rejected, so the original branch/load schedules remain. Matched-frame visual acceptance remains open; see the [edge-list cache ledger](ledger/2026-10-22-edge-list-target-u-cache-promoted.md), [`R_InsertNewEdges` rejection ledger](ledger/2026-10-22-edge-insert-probe4-earlyout-rejected.md), [first edge-step rejection ledger](ledger/2026-10-22-edge-step-successor-prefetch-rejected.md), [second edge-step rejection ledger](ledger/2026-10-22-edge-step-second-successor-prefetch-rejected.md), [third edge-step rejection ledger](ledger/2026-10-22-edge-step-third-successor-prefetch-rejected.md), [first fourth-probe edge-step rejection ledger](ledger/2026-10-22-edge-step-fourth-successor-load-early-rejected.md), [second fourth-probe edge-step rejection ledger](ledger/2026-10-22-edge-step-fourth-successor-load-between-u-add-rejected.md), [third fourth-probe edge-step rejection ledger](ledger/2026-10-22-edge-step-fourth-successor-load-after-store-rejected.md), and [fourth fourth-probe edge-step rejection ledger](ledger/2026-10-22-edge-step-fourth-successor-load-after-compare-rejected.md). |

> **R_ScanEdges fourteen-span loop alignment (2026-10-22):** adding 16-byte
> code alignment averaged **15.601279 FPS** against control at **15.601303 FPS**
> (**−0.000024 FPS, −0.00015383%**). The trailing control was **15.601291 FPS**.
> All seven runs retained 969 frames and checksum `1047377823`; the complete
> strict i486 audit passed. The negative mean rejects the directive, leaving
> the unaligned loop active. See
> `docs/ledger/2026-10-22-scan-edges-clear-span14-alignment-rejected.md`.

### 1. `R_BuildLightMap`

This was the cleanest remaining candidate when the survey was written. The
complete dispatcher is now selectable in assembly, while its C implementation
and each style, fused-style, dynamic-light, and normalization helper remain
available through their own references and selectors.

The C selector keeps the original full dispatcher. The assembly selector moves
surface bounds, cache decisions, fullbright and ambient branches, helper
selection, dynamic-light dispatch, and normalization orchestration to assembler.
The single-style cached table and ambient clear/fill loops also run in assembly.
Style accumulation, fused accumulation, dynamic-light sampling, and
normalization remain independently selectable helpers. The C dispatcher
remains the release default. A matched three-run comparison measured C at
**16.240118 FPS** and assembly at **16.238093667 FPS**, a C gain of
**0.002024333 FPS (+0.0124666%)**. All six runs matched the pinned checksum,
and both variants passed the strict i486 audit. Keep the assembly path
selectable but unpromoted; see the
[comparison ledger](ledger/2026-10-28-lightmap-build-assembly-rejected.md).

### 2. `R_AddDynamicLights` orchestration

The sparse `dlightbits` traversal, x87 surface projection, culling, and helper
dispatch now have a selectable i486 assembly entry. The texel sample loop
remains independently controlled by `DynamicLightImplementation`; the C
orchestration and projection remain available for benchmark parity.

The assembler projection must preserve the existing dot-product order, plane
distance, radius/minlight rejects, `ceil`-based distance limit, texture-space
coordinates, surface-edge cull, and x87 rounding behavior. The pixel helper must
continue to preserve the exact sample predicates, signed rounding,
light-distance calculation, and accumulation order.

### 3. Alias preparation and clipping

Alias rendering remains a substantial cost and already has assembler support
for projection, clipping, and raster spans. The next useful conversion would
be a bounded helper for vertex preparation or gradient setup rather than a
rewrite of the complete alias pipeline.

Use explicit array pointers and vertex counts at the C/assembler boundary.
Avoid making the assembler routine depend on a large set of mutable renderer
globals; that makes register pressure, calling conventions, and parity audits
harder.

### 4. Surface-cache helpers

`R_DlightContributes`, the public cache hit/miss flow, key loading, miss-path
metadata, texture/style tag writes, the rover allocator, cache attachment, draw
dispatch, dynamic-light tag updates, `R_DrawSurface` setup, and the full
`R_TextureAnimation` entry now have assembly paths. PROFILE486 accounting and
the remaining render-time dependency closure stay open; keep the C path as the
reference while continuing those parts.

## Already covered by assembler

The checkout already contains substantial assembler for the hottest low-level
paths, including:

- ordinary texture spans in `src/d_draw16.s`;
- Z spans in `src/d_draw.s`;
- alias span and raster loops in `src/d_polysa.s`;
- alias projection and clipped-transform helpers in `src/r_aliasa.s`;
- turbulent span stores and the `Turbulent8` scan setup/interpolation entry;
- the complete `R_BuildLightMap` dispatcher around selectable light/style helpers;
- direct assembly entries for `D_MipLevelForScale` and `R_TextureAnimation`;
- memory, surface-cache, texture-animation, lightmap-normalization, and BSP
  micro-helpers in the existing 486 support sources.

This means the remaining opportunity is concentrated in orchestration around
those loops and in a few lightmap/alias setup loops, rather than in replacing
the basic pixel writers.

## Poor candidates for a full conversion

These areas are technically convertible but are unlikely to repay their
complexity:

- complete face and brush-model setup functions;
- file I/O, command parsing, and host/platform code;
- code dominated by floating-point setup or calls into many unrelated
  subsystems;
- code whose only benefit would be a smaller instruction count without a
  measured timedemo improvement.

Whole-function rewrites in these areas increase code size, branch pressure,
and parity risk while making later maintenance more difficult.

## Current implementation rules

1. Add a narrow assembler helper beside an unchanged C reference helper.
2. Keep the C/assembler ABI explicit: pointers, counts, strides, and scalar
   parameters should be visible at the call site.
3. Preserve operation width, signedness, rounding, accumulation order, and
   store order unless a deliberate parity change is approved.
4. Do not introduce MMX, SSE, or assumptions beyond the target i486.
5. Keep global-state reads at the C boundary where possible.
6. Integrate an assembly path only after exact reference comparisons and
   mechanical i486 ISA validation pass. Record matched timing measurements
   to detect significant regressions; a speed improvement is not required.

## Validation gate

Every new assembler path should be compared with its C reference and then
validated in the pinned DOSBox-X environment:

- same `demo1` timedemo and 969-frame run;
- current pinned framebuffer checksum `1047377823` on every matched run;
- smoke startup and clean exit;
- correctness harness pass;
- repeated timing measurements using the same `cputype=486`, dynamic core,
  fixed-cycle profile and data root.

A timing improvement without exact framebuffer parity is a rejected result.
Promote a correct, auditable i486 assembly path after its correctness and ISA
gates pass, provided measurements show no unacceptable performance regression.
Retain the C implementation as a selectable reference. Small slowdowns do not
prevent promotion and do not justify repeated optimization of correct assembly.

## Practical decision

The lightmap-combination helper, complete `R_BuildLightMap` dispatcher,
`R_AddDynamicLights` orchestration, `R_DrawSurface` entry, `D_CacheSurface`
entry, BSP traversal, and `R_RenderWorld` orchestration now have selectable
assembly paths, with C references retained. Continue through the remaining
render-time dependency closure and software-renderer code while retaining
exact-output gates.

## Measured surface-block loop follow-up (2026-09-28)

The mip-0 surface-block assembly loop now processes four 16-pixel rows per
loop branch. The row operation order and palette patching remain unchanged.
The two-row variant retained parity but measured only a 0.0387% median gain,
below the 0.05% promotion gate, so the four-row variant was selected instead.

Pinned DOSBox-X 2026.08.31, `cputype=486`, 33445 cycles, CWSDPMI, Steam Quake
data root, and `demo1` timedemo results:

| Build | Runs (seconds) | Median | Frames/checksum |
|---|---|---:|---|
| Control | 59.408192, 59.408224, 59.408267, 59.408144, 59.408194 | 59.408194 | 969 / `1047377823` |
| Mip-0 four-row unroll | 59.374140, 59.374155, 59.374076 | 59.374140 | 969 / `1047377823` |

The four-row build is 0.0573% faster by median. It passed the DOS smoke
startup/exit check and full `bench486` correctness suite (600-second harness
limit). Keep `control` selectable with `-SurfaceBlockMip0Rows control` for
future comparisons.

## Mip-1 eight-row loop follow-up (2026-09-28)

The mip-1 surface-block loop now performs eight 8-pixel rows before testing
the row-carry branch. The operation order and palette patching are unchanged.
This is enabled by default together with the mip-0 four-row loop above.

Pinned DOSBox-X 2026.08.31, `cputype=486`, 33445 cycles, CWSDPMI, Steam Quake
data root, and `demo1` timedemo results:

| Build | Runs (seconds) | Median | Frames/checksum |
|---|---|---:|---|
| Mip-0 four-row default, mip-1 control | 59.374140, 59.374155, 59.374076, 59.374145, 59.374089 | 59.374140 | 969 / `1047377823` |
| Mip-0 four-row plus mip-1 eight-row | 59.344208, 59.344257, 59.344203 | 59.344208 | 969 / `1047377823` |

The mip-1 unroll is 0.0504% faster by median than the five-run mip-0-only
control, just above the 0.05% promotion gate. All runs retained the exact
framebuffer checksum. The candidate passed DOS smoke startup/exit and the full
`bench486` correctness suite (`486 benchmark correctness PASS`, end checksum
`2378409472`). Keep the control selectable with
`-SurfaceBlockMip1Rows control` for future comparisons.

## Mip-0 eight-row loop follow-up (2026-09-28)

An opt-in mip-0 variant repeats eight 16-pixel rows before testing the carry
branch. It keeps the same row operation order and palette patching as the
four-row default. Both executables were rebuilt from the same source before
the five alternating pairs. The comparison used the pinned DOSBox-X
2026.08.31 profile, `cputype=486`, 33445 cycles, CWSDPMI, Steam Quake data
root, and `demo1` timedemo:

| Build | Runs (seconds) | Median | Frames/checksum |
|---|---|---:|---|
| Mip-0 four-row default, mip-1 eight-row | 59.344287, 59.344243, 59.344181, 59.344242, 59.344184 | 59.344242 | 969 / `1047377823` |
| Mip-0 eight-row, mip-1 eight-row | 59.338662, 59.338650, 59.338575, 59.338649, 59.338664 | 59.338650 | 969 / `1047377823` |

The candidate is 0.0094% faster by median, below the 0.05% promotion gate.
Every run completed 969 frames with checksum `1047377823`. The candidate
passed DOS smoke and full `bench486` correctness (`486 benchmark correctness
PASS`, end checksum `2378409472`), ~~but the release default stays at mip-0
unroll4. `-SurfaceBlockMip0Rows unroll8` remains available for further A/B
work.~~
**(Superseded 2026-10-02: the release default is `unroll16`, and `unroll8` is
obsolete as a candidate** — it is a strictly worse variant of a change that was
subsequently promoted, so there is nothing left to bundle it with.
`SurfaceBlockMip0Rows=unroll16` cleared the gate at 0.0620% inside the `surf8`
bundle with `SurfaceBlockMip1IndexHoist=hoist` and a fully-flat mip-1 body. The
measurements below stand. `tools\renderer-profiles\i486-asm-selectable-current.json`
is the release configuration; selector experiments use
`tools\build-dos-experimental.ps1`.

The measured binaries were 791,040-byte control SHA-256
`C5EEA1917851E674BC3DC5716B4EA7DBDB231DAD8EFF7CD095FF879BB2E4A098` and
792,576-byte candidate SHA-256
`1950674B7090971BAE6E4F45754F566775582D38BD7ECAB8E5769032F612782D`. Raw
run reports are in `out\dos-timedemo-20260928-205001`,
`out\dos-timedemo-20260928-205114`, `out\dos-timedemo-20260928-205232`,
`out\dos-timedemo-20260928-205345`, `out\dos-timedemo-20260928-205458`,
`out\dos-timedemo-20260928-205614`, `out\dos-timedemo-20260928-205725`,
`out\dos-timedemo-20260928-205839`, `out\dos-timedemo-20260928-205952`,
and `out\dos-timedemo-20260928-210109` (control first, then candidate,
alternating). All reports used profile SHA-256
`F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45` and
CWSDPMI SHA-256
`0A890815DF6CBDC052915A856C16944CEDEC825267E7B6E453C351A0CDC695F2`. The
build manifests retain the matching row selectors.

## Mip-0 sixteen-row loop follow-up (2026-09-28)

The opt-in `unroll16` variant runs one straight-line body for all sixteen
mip-0 rows before testing the row-carry branch. It keeps the same row
operations and colormap patching as the four-row default. Both executables
were rebuilt from the same source before five alternating pairs. The runs
used pinned DOSBox-X 2026.08.31, `cputype=486`, 33445 cycles, CWSDPMI, the
Steam Quake `id1` data root, and the `demo1` timedemo:

| Build | Runs (seconds) | Median | Spread | Frames/checksum |
|---|---|---:|---:|---|
| Mip-0 four-row default, mip-1 eight-row | 59.344260, 59.344296, 59.344220, 59.344213, 59.344214 | 59.344220 | 0.000083 | 969 / `1047377823` |
| Mip-0 sixteen-row, mip-1 eight-row | 59.335715, 59.335860, 59.335689, 59.335845, 59.335846 | 59.335845 | 0.000171 | 969 / `1047377823` |

The candidate is 0.008375 seconds (0.0141%) faster by median, below the
0.05% promotion gate. Every run completed all 969 frames with the exact
framebuffer checksum. Candidate smoke exited cleanly (DOSBox-X and Quake exit
codes `0`), and the full `bench486` correctness suite reported
`486 benchmark correctness PASS` with end checksum `2378409472`. ~~The release
default remains `SurfaceBlockMip0Rows=unroll4`; `unroll16` remains selectable
for further matched A/B runs.~~
**(Superseded 2026-10-02: `unroll16` IS the release default**, promoted at
0.0620% inside the `surf8` bundle. This entry is the measurement that made it
promotable. See `ledger/2026-10-02-surf8-bundle-and-promotion.md`, under "`surf8` flat axis: three measured wins
bundled and **PROMOTED, 0.0620%**".)

The control `qbench.exe` was 791,040 bytes with SHA-256
`38286C3720BFD4F7F65CD57E268015E8E4DA2490DBFB5D94864F37356080B82C`; the
candidate `qbench.exe` was 795,648 bytes with SHA-256
`91F8CFC20E2E2F0B6BF8FB40D43FA28DC6245546E693DC041C3D36684C08A557`. The
smoke `quake.exe` was 723,456 bytes with SHA-256
`AE8D3CC50DE9B2E678C30C53DB4A1B1B72985E9213D8B99235BC37D0B5E95D4F`.
The correctness report is
`out\dos-bench-20260928-212255\bench-result.json`; smoke details are in
`out\dos-smoke\smoke-result.json`. Timedemo reports are in
`out\dos-timedemo-20260928-213132`, `out\dos-timedemo-20260928-213244`,
`out\dos-timedemo-20260928-213358`, `out\dos-timedemo-20260928-213510`,
`out\dos-timedemo-20260928-213624`, `out\dos-timedemo-20260928-213736`,
`out\dos-timedemo-20260928-213847`, `out\dos-timedemo-20260928-213959`,
`out\dos-timedemo-20260928-214110`, and
`out\dos-timedemo-20260928-214223` (control first, then candidate,
alternating). All reports used profile SHA-256
`F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45` and
CWSDPMI SHA-256
`0A890815DF6CBDC052915A856C16944CEDEC825267E7B6E453C351A0CDC695F2`; build
manifests record each row selector.
