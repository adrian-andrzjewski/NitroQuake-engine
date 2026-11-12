# Experiment ledger

This index covers measurements, rejections, and corrections from the i486
optimization work and renderer port. Historical experiment records moved from
`ASM486-HANDOFF.md` beginning 2026-10-03; their evidence remains in the ledger.

The **Files** table is the complete inventory. Its entry count is the number of
level-two headings in that file. The region map below is a curated cross-reference
for selected work; use the Files table to find any record. Date-named records are
ordered newest first, followed by undated records imported from source reports.

Read the entry by its heading, never by a line number - see the process rule in
`ASM486-HANDOFF.md` under "Process rules". Ten of twelve line-number citations in
this material were found wrong by an audit on 2026-10-03, each invalidated by a
later insertion above it.

## Files

| File | Entries | Summary / region |
|---|---:|---|
| [2026-11-12-surf8-mip0-fullyflat-unroll16-promoted.md](2026-11-12-surf8-mip0-fullyflat-unroll16-promoted.md) | 5 | `surf8.s` / fully unroll the 16-row mip-0 fully-flat loop; exact color/Z/PCX parity, strict release and qbench i486 passes, and +0.00114636% matched demo1 mean |
| [2026-11-11-surf8-mip0-fullyflat-sourcetstep-hoist-rejected.md](2026-11-11-surf8-mip0-fullyflat-sourcetstep-hoist-rejected.md) | 1 | `surf8.s` / hoist the mip-0 fully-flat source row stride into `%ebp`; exact VGA color/Z/PCX parity and strict i486 pass, but −0.0002517% matched demo1 mean FPS |
| [2026-11-11-surf8-mip0-fullyflat-unroll8-promoted.md](2026-11-11-surf8-mip0-fullyflat-unroll8-promoted.md) | 5 | `surf8.s` / unroll the fully-flat mip-0 row loop eight rows at a time; exact color/Z/PCX parity, strict i486 pass, and positive four-sample means on demo1 and demo3 |
| [2026-11-11-surf8-mip0-horizontal-flat-unroll8-promoted.md](2026-11-11-surf8-mip0-horizontal-flat-unroll8-promoted.md) | 5 | `surf8.s` / mip-0 horizontal-flat blocks process eight rows per counter iteration; exact color/Z/PCX parity, strict i486 pass, and +0.0003315% demo1 plus +0.0003391% demo3 means |
| [2026-11-11-surf8-mip0-horizontal-flat-unroll4-promoted.md](2026-11-11-surf8-mip0-horizontal-flat-unroll4-promoted.md) | 5 | `surf8.s` / mip-0 horizontal-flat blocks process four rows per counter iteration; exact color/Z/PCX parity, strict i486 pass, and +0.0023887% matched demo1 mean |
| [2026-11-11-renderface-signed-surfedge-memory-compare-promoted.md](2026-11-11-renderface-signed-surfedge-memory-compare-promoted.md) | 1 | `R_RenderFace` / compare the signed surfedge in memory; exact demo1 and entity color/Z/PCX parity, strict i486 pass, and +0.0377846% matched mean |
| [2026-11-11-renderface-signed-surfedge-register-reuse-rejected.md](2026-11-11-renderface-signed-surfedge-register-reuse-rejected.md) | 1 | `R_RenderFace` / reuse the signed surfedge register on clipping paths; exact color/Z/PCX parity and complete i486 gate, but -0.0323705% matched mean FPS |
| [2026-11-11-span16-zero-tstep-accumulator-mov-reclassified-promoted.md](2026-11-11-span16-zero-tstep-accumulator-mov-reclassified-promoted.md) | 6 | `D_DrawSpans16` / reclassify the positive +0.000033% five-pair mean under the current thresholdless acceptance rule; exact color/Z/PCX parity and fresh complete i486 gate |
| [2026-11-11-span16-zero-tstep-accumulator-mov-rejected.md](2026-11-11-span16-zero-tstep-accumulator-mov-rejected.md) | 1 | `D_DrawSpans16` / original noise-based rejection, superseded after applying the current positive-pooled-mean rule |
| [2026-11-11-edge-stepactiveu-ebx-scratch-promoted.md](2026-11-11-edge-stepactiveu-ebx-scratch-promoted.md) | 7 | `R_StepActiveU` / reuse dead `%eax` for edge links, remove the normal-path `%ebx` save and restore, exact fixed-clock color/Z/PCX parity, complete strict i486 gate, and +0.015157% three-run mean |
| [2026-11-11-r-clipedge-combined-sign-live-eax-reload-promoted.md](2026-11-11-r-clipedge-combined-sign-live-eax-reload-promoted.md) | 6 | `R_ClipEdge` / combine sign bits on the no-crossing path while reloading live `%eax` at `Lp2`; exact color/Z/PCX parity, strict i486 pass, and +0.048263% three-run mean |
| [2026-11-11-r-clipedge-combined-sign-live-eax-rejected.md](2026-11-11-r-clipedge-combined-sign-live-eax-rejected.md) | 1 | `R_ClipEdge` / combined sign check clobbered live `%eax` used by `Lp2`; first-frame color and Z parity failed, flawed variant reverted |
| [2026-11-11-alias-scan-ubasestep-specialization-rejected.md](2026-11-11-alias-scan-ubasestep-specialization-rejected.md) | 1 | alias scan / 83.71% of 102,654 left-edge steps used 0 or ±1; exact parity and strict i486 passed, but the best matched mean regressed 0.005825% |
| [2026-11-11-alias-gradient-y-reciprocal-fchs-rejected.md](2026-11-11-alias-gradient-y-reciprocal-fchs-rejected.md) | 1 | alias gradient / replace the multiply by -1 with FCHS; exact color/Z/PCX parity and strict i486 pass, but matched mean was 0.0000296% lower |
| [2026-11-11-edge-trailing-spanstate-branch-polarity-rejected.md](2026-11-11-edge-trailing-spanstate-branch-polarity-rejected.md) | 1 | `TrailingEdge` / make the frequent no-span return the fall-through path; exact color/Z/PCX parity and strict i486 pass, but matched mean was 0.0000434% lower |
| [2026-11-11-bsp-walk-c-default-promoted.md](2026-11-11-bsp-walk-c-default-promoted.md) | 6 | BSP traversal / select the exact C walk as the i486 default after +0.024255% across three alternating demo1 pairs, exact color/Z/PCX parity, and complete strict i486 gates |
| [2026-11-11-r-clipedge-dot-product-stack-reschedule-promoted.md](2026-11-11-r-clipedge-dot-product-stack-reschedule-promoted.md) | 6 | R_ClipEdge / remove five x87 FXCH operations per plane test with exact color/Z/PCX parity, strict i486 pass, and +0.383695% matched demo1 mean FPS |
| [2026-11-10-underwater-warp-pixel-unroll8-promoted.md](2026-11-10-underwater-warp-pixel-unroll8-promoted.md) | 5 | underwater warp / copy eight pixels per loop in the assembly pixel routine; exact color/Z/PCX parity, strict i486 pass, and +0.321885% matched demo2 mean FPS |
| [2026-11-09-surface-cache-dlight-probe-census.md](2026-11-09-surface-cache-dlight-probe-census.md) | 5 | surface cache / repaired profile-only assembly probe coverage; 330 checks across 512 frames, with 314 contributing; counts only, no timing or FPS claim |
| [2026-11-09-cliplinks-final-child-frame-promoted.md](2026-11-09-cliplinks-final-child-frame-promoted.md) | 4 | collision area tree / final-child frame reuse; exact 6,912 native cases and +0.050689% pooled e1m2 diagnostic FPS screen; final integration required |
| [2026-11-09-moveclip-overwrite-initialization-promoted.md](2026-11-09-moveclip-overwrite-initialization-promoted.md) | 4 | collision initialization / remove overwritten 124-byte clear; 18,432 native cases, full four-group state/count matches and +0.072735% pooled diagnostic FPS |
| [2026-11-08-qc-opcode-operands-promoted.md](2026-11-08-qc-opcode-operands-promoted.md) | 4 | QuakeC operand work / exact 11,076 native cases; preserved profiling, matched local state and statement counts; +0.143550% pooled diagnostic FPS |
| [2026-11-08-warp-geometry-table-cache-promoted.md](2026-11-08-warp-geometry-table-cache-promoted.md) | 4 | underwater warp / invariant geometry tables with complete input and x87 key; 1,512 native cases, exact three-demo parity, +0.022348% pooled diagnostic FPS |
| [2026-11-08-commit-validation-and-test-debt.md](2026-11-08-commit-validation-and-test-debt.md) | 3 | commit review / fresh normal and BENCH i486 builds pass; focused identity and retained parity checks pass; 11 of 19 host gates pass, with remaining failures reproduced at the untouched baseline |
| [2026-11-08-engine-wide-profile-and-ai-cache.md](2026-11-08-engine-wide-profile-and-ai-cache.md) | 5 | engine-wide measured budgets / promoted immutable AI leaf-query cache: exact state/color/Z, x87/reset and normal-release gates; +0.387% pooled local-gameplay diagnostic FPS; current normal v0.999+26 comparison and charts |
| [2026-11-07-alias-triangle-vertex-prefilter-rejected.md](2026-11-07-alias-triangle-vertex-prefilter-rejected.md) | 4 | alias triangle visibility / vertex Z prefilter avoided 70.4% of full queries and passed 2,304 native cases, complete replay parity and strict i486, but three matched pairs regressed mean FPS by 0.1622784%; rejected |
| [2026-11-07-alias-triangle-cache-fill-rejected.md](2026-11-07-alias-triangle-cache-fill-rejected.md) | 4 | alias triangle visibility / assembly cache completion and batch guards passed 2,048 native cases, both complete color/Z/image replays and strict i486; 14,498 culls, but three matched pairs regressed mean FPS by 0.4382345%; rejected |
| [2026-11-07-alias-triangle-cache-miss-diagnosis.md](2026-11-07-alias-triangle-cache-miss-diagnosis.md) | 4 | alias triangle visibility / unpromoted read-only i486 prototype: 1,024 native cases and two exact complete color/Z/image replays; 60,300 of 61,984 queries stop at stale tiles, motivating conservative tile completion; no timing claim |
| [2026-11-07-span-coordinate-float-table-rejected.md](2026-11-07-span-coordinate-float-table-rejected.md) | 4 | surface spans / exact 5,124-byte U/V float table passed strict i486 and subsequent complete replay comparisons, but the three-pair mean was 0.0000693455% lower; restored, with initial startup variation retained |
| [2026-11-07-three-executable-benchmark.md](2026-11-07-three-executable-benchmark.md) | 4 | delivered game comparison / nine fresh 320x200 runs: original Quake 13.4 FPS, 486quake 14.2 FPS, NitroQuake v0.999+7 16.9 FPS; approximately +26.1% and +18.8% from median elapsed times, chart and provenance retained |
| [2026-11-07-alias-line-scan-unsigned-division-rejected.md](2026-11-07-alias-line-scan-unsigned-division-rejected.md) | 4 | alias line setup / unsigned positive long-edge division passed 16,416 native cases, exact color/Z/image parity and complete i486 audits, but regressed the three-pair mean by 0.0000832146%; rejected |
| [2026-11-07-alias-line-scan-biased-bounds-promoted.md](2026-11-07-alias-line-scan-biased-bounds-promoted.md) | 5 | alias line setup / two unsigned biased bounds checks reuse the table index; +0.0468282% matched FPS, 16,416 native cases, four exact full-clock color/Z/image replays, complete i486 gate |
| [2026-11-07-span-coordinate-packed-store-rejected.md](2026-11-07-span-coordinate-packed-store-rejected.md) | 4 | surface span emission / one packed U/V store passed strict i486 but regressed the three-run matched mean FPS by 0.0229443%; restored |
| [2026-11-07-span-record-layout-12-byte-promoted.md](2026-11-07-span-record-layout-12-byte-promoted.md) | 4 | surface span pool / reduce `espan_t` from 16 to 12 bytes; exact color/Z and PCX parity, strict i486 pass, and +0.3436% matched mean FPS |
| [2026-11-07-renderface-clipchain-cache-promoted.md](2026-11-07-renderface-clipchain-cache-promoted.md) | 5 | R_RenderFace / reuse the last partial clip-plane chain on 79.6% of eligible calls; exact color/Z parity, strict i486 pass, and +0.0144664% matched mean FPS |
| [2026-11-07-alias-occlusion-cache-invalidation-rejected.md](2026-11-07-alias-occlusion-cache-invalidation-rejected.md) | 3 | alias visibility / rechecking tile minima after alias Z writes retained the total cull count but changed 462 color and 141 Z checksum rows; rejected before release timing |
| [2026-11-07-alias-tile-depth-pack-rejected.md](2026-11-07-alias-tile-depth-pack-rejected.md) | 4 | alias visibility / 8 KB packed tile-depth entries passed exact color/Z and strict i486, but the matched mean was 0.929071% slower than the 12 KB cache |
| [2026-11-07-alias-tile-group-min-hierarchy-rejected.md](2026-11-07-alias-tile-group-min-hierarchy-rejected.md) | 6 | alias visibility / 4-by-4 tile-group summaries cut profile tile checks by 12.04%, but the tested version was 0.19657% slower and had an unsafe epoch invalidation path; removed |
| [2026-11-07-bmodel-plane-entity-mixed-hash-rejected.md](2026-11-07-bmodel-plane-entity-mixed-hash-rejected.md) | 4 | brush clipping / mixing entity bits into the 512-slot hash retained exactly 31,160 hits and 9,998 misses; rejected before release timing |
| [2026-11-07-bmodel-plane-transform-cache1024-rejected.md](2026-11-07-bmodel-plane-transform-cache1024-rejected.md) | 4 | brush clipping / 1,024-entry table doubled BSS but retained the 512-entry cache's exact 31,160-hit/9,998-miss result; rejected before release timing |
| [2026-11-07-world-clipvertex-inline-sign-cache-rejected.md](2026-11-07-world-clipvertex-inline-sign-cache-rejected.md) | 5 | world clipping / inline 16-byte vertex sign cache passed exact parity and strict i486 but regressed matched mean FPS by 0.30731% |
| [2026-11-07-world-clipvertex-one-hit-sign-cache-rejected.md](2026-11-07-world-clipvertex-one-hit-sign-cache-rejected.md) | 4 | world clipping / one-hit sign cache preserved exact color/Z and strict i486 compatibility but regressed matched mean FPS by 0.4612% |
| [2026-11-06-world-clipvertex-side-sign-cache-rejected.md](2026-11-06-world-clipvertex-side-sign-cache-rejected.md) | 4 | world clipping / exact sign-cache parity and strict i486 pass, but matched uninstrumented mean FPS regressed 3.7546% |
| [2026-11-06-clipvertex-plane-cache-capacity-census.md](2026-11-06-clipvertex-plane-cache-capacity-census.md) | 4 | world clipping / 64-slot tags hit 59.18% of endpoints but both-hit only 32.19% of world/world calls, pointing to independent endpoint handling |
| [2026-11-06-world-clipvertex-plane-cache-rejected.md](2026-11-06-world-clipvertex-plane-cache-rejected.md) | 4 | world clipping / distance and sign-only per-plane caches passed strict i486 but shared six recurring color mismatches; Z matched outside late-run variance, no timing A/B |
| [2026-11-06-bmodel-plane-transform-cache1024-rejected.md](2026-11-06-bmodel-plane-transform-cache1024-rejected.md) | 2 | brush clipping / reject 1,024 entries: same 31,160 hits and 9,998 misses as the 512-entry table, exact profile output, but another 14 KB of BSS and no additional transforms |
| [2026-11-06-bmodel-endpoint-distance-cache-rejected.md](2026-11-06-bmodel-endpoint-distance-cache-rejected.md) | 3 | brush clipping / release color and Z streams differ on four late frames despite profile parity, a strict i486 pass, matching frame 482 and final checksum; candidate removed |
| [2026-11-06-alias-tile-minimum-early-exit-rejected.md](2026-11-06-alias-tile-minimum-early-exit-rejected.md) | 3 | alias visibility / 3,514 fewer profile Z samples, but one color checksum mismatch at frame 690; Z stream matched and candidate was removed |
| [2026-11-06-bmodel-plane-transform-cache512-promoted.md](2026-11-06-bmodel-plane-transform-cache512-promoted.md) | 4 | brush clipping / expand the direct-mapped splitter-plane cache to 512 entries; 1,051 fewer profile misses, exact color/Z/PCX, strict i486, and +0.0022838% matched mean FPS |
| [2026-11-06-alias-tile-anchor-early-out-promoted.md](2026-11-06-alias-tile-anchor-early-out-promoted.md) | 5 | alias visibility / early-return on one low anchor Z sample in a 4-by-4 tile; exact color/Z/PCX, strict i486, 37,470 fewer profile reads, and +0.0245131% matched mean FPS |
| [2026-11-06-active-edge-order-skip-rejected.md](2026-11-06-active-edge-order-skip-rejected.md) | 4 | active edge scan / monotone slope tags preserved exact color, Z, and PCX output and passed the full i486 gate, but regressed matched mean FPS by 2.121206% |
| [2026-11-06-bmodel-face-plane-cache-rejected.md](2026-11-06-bmodel-face-plane-cache-rejected.md) | 3 | brush-model facing / reject cached per-plane surface decisions: one framebuffer row differed at frame 254 despite matching Z stream, frame-482 PCX, final checksum, and strict i486 audit |
| [2026-11-06-bsp-node-surface-order-rejected.md](2026-11-06-bsp-node-surface-order-rejected.md) | 4 | world BSP traversal / front/back surface index matched exact output and strict i486, but was -0.386045% in three uninstrumented runs |
| [2026-11-06-bmodel-world-tile-occlusion-rejected.md](2026-11-06-bmodel-world-tile-occlusion-rejected.md) | 3 | brush-model occlusion / reject reuse of alias 4-by-4 world-Z tiles: 894/2,310 models culled, but 54 color and 52 Z rows differ from control |
| [2026-11-06-bmodel-plane-transform-cache256-promoted.md](2026-11-06-bmodel-plane-transform-cache256-promoted.md) | 4 | brush clipping / double the direct-mapped cache to 256 entries; 2,266 fewer profile misses, exact color/Z parity, strict i486 audit, and +0.004928% matched mean FPS |
| [2026-11-06-bmodel-plane-cache-generation-rejected.md](2026-11-06-bmodel-plane-cache-generation-rejected.md) | 4 | brush clipping / generation tags removed one comparison per cache hit and 1,020 BSS bytes, with exact color/Z and strict i486; matched mean was -0.256% |
| [2026-11-06-bmodel-plane-cache-layout-and-hash-rejected.md](2026-11-06-bmodel-plane-cache-layout-and-hash-rejected.md) | 4 | brush clipping / reject aligned 32-byte records (-0.000713%) and XOR-folded indexing (-0.004438%); both exact and strict i486, XOR saved 413 profile misses |
| [2026-11-06-bmodel-plane-victim-cache-rejected.md](2026-11-06-bmodel-plane-victim-cache-rejected.md) | 4 | brush clipping / reject four-entry and one-entry victim caches after 3,301 and 2,060 recovered transforms still regressed matched release FPS by 0.02035% and 0.00896%; exact color/Z parity and strict i486 audits passed |
| [2026-11-05-alias-triangle-tile-occlusion-rejected.md](2026-11-05-alias-triangle-tile-occlusion-rejected.md) | 2 | alias visibility / old rejection retained; frame-72 recheck identifies all 756 changed pixels as one pickup notification, allowing a fresh full-clock requalification; triangle predicate remains unpromoted |
| [2026-11-05-alias-model-tile-occlusion-2x2-rejected.md](2026-11-05-alias-model-tile-occlusion-2x2-rejected.md) | 3 | alias visibility / reject 2-by-2 tiles after 57 extra culls still changed color at frame 690; a 32-unit depth margin repeated the mismatch and reduced culls |
| [2026-11-05-bmodel-plane-transform-crossframe-rejected.md](2026-11-05-bmodel-plane-transform-crossframe-rejected.md) | 4 | brush clipping / reject cross-frame transformed-plane reuse after 1,017 fewer profile misses but a -0.02049% matched release mean; exact parity and strict i486 audit passed |
| [2026-11-05-bmodel-plane-transform-cache128-promoted.md](2026-11-05-bmodel-plane-transform-cache128-promoted.md) | 4 | brush clipping / expand the direct-mapped transformed splitter-plane cache to 128 entries; 471 fewer profile misses, exact color/Z parity, strict i486 audit, and +0.000812% matched mean FPS |
| [2026-11-05-bmodel-plane-transform-cache64-promoted.md](2026-11-05-bmodel-plane-transform-cache64-promoted.md) | 4 | brush clipping / expand the transformed splitter-plane cache to 64 entries; profile hits rise from 64.88% to 66.50%, exact color/Z parity, strict i486 audit, and +0.001051% matched mean FPS |
| [2026-11-05-alias-parent-hierarchy-rejected.md](2026-11-05-alias-parent-hierarchy-rejected.md) | 3 | alias visibility / reject a lazy 8-by-8 parent-min hierarchy: direct scans reduced cache checks but added Z reads and were -0.06134% in release timing; child-derived parents had only 151/6,318 hits and increased cache work |
| [2026-11-05-alias-model-tile-occlusion-promoted.md](2026-11-05-alias-model-tile-occlusion-promoted.md) | 6 | alias visibility / 8-bit epochs cut the 4-by-4 Z cache from 24 KB to 12 KB with exact parity, strict i486 audit, and +0.00194%; validity bitset (-0.07990%), 4-by-8 (-0.07672%), 8-by-4 (-0.45532%), and temporal witness ordering (0.41% fewer tile checks) rejected |
| [2026-11-05-bmodel-endpoint-distance-forwarding-rejected.md](2026-11-05-bmodel-endpoint-distance-forwarding-rejected.md) | 3 | brush clipping / reject previous-edge endpoint-distance forwarding after exact framebuffer, Z, PCX and strict i486 checks, but a 0.1145% slower three-run mean |
| [2026-11-05-bmodel-plane-transform-cache-promoted.md](2026-11-05-bmodel-plane-transform-cache-promoted.md) | 3 | brush clipping / retain a 32-entry transformed BSP splitter-plane cache after 64.88% profile hits, exact color/Z profile parity, a complete i486 audit, and +0.01258% in matched three-run mean FPS |
| [2026-11-05-zspan-row-term-cache-rejected.md](2026-11-05-zspan-row-term-cache-rejected.md) | 3 | Z-spans / reject a 200-row `v*d_zistepv` term cache after a 29.1% hit rate still produced a -0.363% three-run mean; exact checksum streams and complete strict i486 audit passed |
| [2026-11-05-alias-span-tile-depth-hierarchy-rejected.md](2026-11-05-alias-span-tile-depth-hierarchy-rejected.md) | 3 | renderer acceleration / reject a lazy horizontal tile-min Z hierarchy after only 103/39,990 and 140/39,990 span rejections, increased instrumented self time, and a frame-83 color/Z checksum difference |
| [2026-11-04-world-span-hzb-alias-rejected.md](2026-11-04-world-span-hzb-alias-rejected.md) | 3 | alias visibility / reject world-span depth hierarchies after both tile layouts changed color checksum streams; the refined layout culled only 12 models across 2,974 queries |
| [2026-11-04-edge-bucket-and-pvs-surface-cache-rejected.md](2026-11-04-edge-bucket-and-pvs-surface-cache-rejected.md) | 4 | renderer acceleration / reject 16-pixel active-edge buckets and PVS surface epochs after color parity failures; bucket search also increased list work, PVS marks ignored per-frame frustum filtering |
| [2026-11-04-edge-pushback-finger-rejected.md](2026-11-04-edge-pushback-finger-rejected.md) | 2 | renderer acceleration / reject a scanline-local active-edge predecessor finger after only 467 selections, 484 fewer iterations, and 288/970 color checksum differences |
| [2026-11-04-bsp-plane-dot-cache-and-surface-stamp-rejected.md](2026-11-04-bsp-plane-dot-cache-and-surface-stamp-rejected.md) | 4 | BSP acceleration / reject shared-plane dot and direct classification caches plus redundant surface-stamp store suppression after negative three-run uninstrumented means |
| [2026-11-04-renderface-cliparg-hoist-promoted.md](2026-11-04-renderface-cliparg-hoist-promoted.md) | 4 | `R_RenderFace` / hoist the constant clip-plane argument out of per-edge loops; +0.0612% mean, exact fixed-step and PCX parity, complete strict i486 audit |
| [2026-11-04-renderface-outgoing-argument-frame-promoted.md](2026-11-04-renderface-outgoing-argument-frame-promoted.md) | 4 | `R_RenderFace` / reserve an outgoing argument frame for `R_ClipEdge`; +0.0021% mean, exact fixed-step and PCX parity, complete strict i486 audit |
| [2026-11-04-renderface-prelinked-all-mask-chains-rejected.md](2026-11-04-renderface-prelinked-all-mask-chains-rejected.md) | 4 | `R_RenderFace` / prelinked chains for all 15 nonempty masks; reject after 436/970 fixed-step checksums differ, despite matching final checksum and passing i486 audit |
| [2026-11-04-renderface-clipplane-order-rejected.md](2026-11-04-renderface-clipplane-order-rejected.md) | 3 | `R_RenderFace` / reject view-plane order 1,0,2,3 after 591/970 fixed-step checksums and the captured frame 695 PCX differed |
| [2026-11-04-span16-segment-endpoint-order-promoted.md](2026-11-04-span16-segment-endpoint-order-promoted.md) | 4 | Span16 / store full-segment endpoint T before S; +0.0000427% mean, exact replay parity, complete strict i486 audit |
| [2026-11-04-span16-initial-span-product-order-promoted.md](2026-11-04-span16-initial-span-product-order-promoted.md) | 4 | Span16 / calculate initial-span T before S; +0.07002% pooled mean over four runs per variant, including the low-rate pair; exact parity and strict audit recorded |
| [2026-11-04-r-genspans-trailing-to-leading-tail-jump-promoted.md](2026-11-04-r-genspans-trailing-to-leading-tail-jump-promoted.md) | 4 | `R_GenerateSpans` / tail-jump through `TrailingEdge` to the leading continuation; +0.2570% pooled mean with one control hitch, exact parity and strict i486 audit |
| [2026-11-04-bsp-walk-packed-continuation-state-promoted.md](2026-11-04-bsp-walk-packed-continuation-state-promoted.md) | 4 | `R_RecursiveWorldNode_asm486` / pack side and resume phase into a 20-byte continuation record; +0.0000672% mean, exact fixed-step parity, complete strict i486 audit |
| [2026-11-03-bsp-framecount-snapshot-promoted.md](2026-11-03-bsp-framecount-snapshot-promoted.md) | 4 | `R_RecursiveWorldNode_asm486` / snapshot the frame count once per traversal; +0.0001325% mean, exact fixed-step parity, complete strict i486 audit |
| [2026-11-03-renderface-prelinked-fullmask-chain-promoted.md](2026-11-03-renderface-prelinked-fullmask-chain-promoted.md) | 4 | `R_RenderFace` / reuse a prelinked four-plane chain for mask 15; +0.0227% uninstrumented mean, exact per-frame and PCX parity, complete strict i486 audit |
| [2026-11-03-renderface-fourclip-mask-fastpath-promoted.md](2026-11-03-renderface-fourclip-mask-fastpath-promoted.md) | 4 | `R_RenderFace` / directly link the full four-plane clip chain; +0.0443% median on DOSBox-X, exact pixel parity and full i486 audit |
| [2026-11-03-span16-same-texel-endpoint-census.md](2026-11-03-span16-same-texel-endpoint-census.md) | 3 | texture spans / conservative endpoint test found 0 qualifying segments out of 2,059,043 full segments; no repeated-texel fast path or FPS claim |
| [2026-11-03-zspan-constant-depth-runs-promoted.md](2026-11-03-zspan-constant-depth-runs-promoted.md) | 4 | Z-spans / promote monotone constant-depth fills with aligned `rep stosl` after 0.1220% median gain, exact 970-frame parity, and full i486 audit |
| [2026-11-03-r-clipedge-projection-cache-withdrawn.md](2026-11-03-r-clipedge-projection-cache-withdrawn.md) | 5 | renderer performance / withdraw the 80-bit endpoint cache after inconsistent control-schedule parity; 32-bit projection-value follow-up had no measurable gain |
| [2026-11-03-zspan-row-recurrence-rejected.md](2026-11-03-zspan-row-recurrence-rejected.md) | 3 | Z-spans / reject vertical-term recurrence after 38 per-frame checksum differences, despite matching final checksum and one captured PCX |
| [2026-11-03-bsp-clip-plane-order-census-rejected.md](2026-11-03-bsp-clip-plane-order-census-rejected.md) | 4 | renderer performance / reject all BSP plane reorders after `0123` had the lowest modeled test count; zero clip-mask prediction mismatches, DOSBox timedemo parity and strict i486 audit |
| [2026-11-02-renderface-outcode-cache-rejected.md](2026-11-02-renderface-outcode-cache-rejected.md) | 3 | renderer performance / reject cached vertex frustum signs after 13 per-frame color-checksum mismatches; no valid speed result |
| [2026-11-02-span16-destination-aligned-word-stores-abandoned.md](2026-11-02-span16-destination-aligned-word-stores-abandoned.md) | 3 | texture spans / abandon word-store experiment after byte-order corruption; corrected variant was not rebuilt, so parity and timing remain unverified |
| [2026-11-02-span16-row-scale-table-unqualified.md](2026-11-02-span16-row-scale-table-unqualified.md) | 4 | texture spans / reject row-scale table after repaired 3-run exact parity and strict i486 audit; median 0.4301% slower on pinned 320x200 DOSBox-X profile |
| [2026-11-02-span16-linear-address-delta-rejected.md](2026-11-02-span16-linear-address-delta-rejected.md) | 3 | texture spans / reject row-major Q32.32 address accumulation after 969 of 970 indexed framebuffer checksums differed; i486 ISA audit passed; no timing claim |
| [2026-11-02-surface-cache-6000-recheck-rejected.md](2026-11-02-surface-cache-6000-recheck-rejected.md) | 4 | surface cache / reject 6000 KB default: +0.0129% DOSBox-X median but 27 per-frame checksum differences against two identical 2400 KB control streams |
| [2026-11-02-span16-same-row-link-census.md](2026-11-02-span16-same-row-link-census.md) | 3 | renderer performance / only 31,256 of 1,454,547 texture-span links share a row (2.1488%); no reuse candidate, qprof used only for attribution, and cross-run frame streams differ at six frames |
| [2026-11-02-clipvertex-distance-cache-rejected.md](2026-11-02-clipvertex-distance-cache-rejected.md) | 5 | renderer performance / 66.27-68.05% global reuse falls to 29.40-29.59% for a one-entry per-plane cache; retain diagnostic profile only, prior cache variants slower, no FPS or cross-run parity claim |
| [2026-11-02-clipedge-shared-endpoint-cache-rejected.md](2026-11-02-clipedge-shared-endpoint-cache-rejected.md) | 3 | renderer performance / reject shared endpoint distance reuse after -0.229% and -0.339% DOSBox-X results; corrected profile: 789,751 calls and 1.479M plane tests |
| [2026-11-02-renderface-trivial-frustum-cull-rejected.md](2026-11-02-renderface-trivial-frustum-cull-rejected.md) | 4 | renderer performance / reject the per-face all-vertices-outside frustum check after a -0.53017% DOSBox-X result; exact Z stream, color parity unresolved, strict i486 audit |
| [2026-11-02-alias-span-constant-depth-reject-rejected.md](2026-11-02-alias-span-constant-depth-reject-rejected.md) | 4 | alias rasterization / reject per-span occlusion scan (-0.0724%) and whole-model Z-rectangle scan (+0.00064%, below noise); spot PCX/Z parity, incomplete color-hash parity, both reverted |
| [2026-11-02-zspan-pair-add-schedule-recheck-rejected.md](2026-11-02-zspan-pair-add-schedule-recheck-rejected.md) | 3 | Z-span performance / recheck the SHLD/ROR depth-add schedule on the current combined source; no repeatable gain across ten 320x200 runs, exact checksum/event traces, full i486 audit |
| [2026-11-02-alias-span-register-entry-promoted.md](2026-11-02-alias-span-register-entry-promoted.md) | 3 | alias rasterization / pass prepared span pointer in EAX to remove stack argument traffic; +0.0078% across two 320x200 screens, exact full checksum-stream and golden-frame parity, strict i486 audit |
| [2026-11-01-alias-span-triangle-constant-setup-promoted.md](2026-11-01-alias-span-triangle-constant-setup-promoted.md) | 3 | alias rasterization / prepare triangle-constant span steps once per triangle; +0.0149% across 15 320x200 runs, exact fixed-clock frame and full checksum-stream parity, and full i486 audit |
| [2026-11-01-edge-sort-nonbmodel-sixteen-recheck-rejected.md](2026-11-01-edge-sort-nonbmodel-sixteen-recheck-rejected.md) | 1 | renderer performance / reject the 16-comparison continuation: no standalone or combined gain across 20 candidate runs; exact final checksums/event traces and strict i486 audit |
| [2026-10-31-zspan-no-fxch-promoted-and-renderface-no-clip-rejected.md](2026-10-31-zspan-no-fxch-promoted-and-renderface-no-clip-rejected.md) | 4 | Z-spans / historical +0.0714% no-FXCH gain remains opt-in after 37 changed frame-99 pixels and the later visible-artifact report restored control as default |
| [2026-10-31-alias-line-scan-negative-division-promoted.md](2026-10-31-alias-line-scan-negative-division-promoted.md) | 5 | alias rasterization / replace the double divide for negative long-edge line setup with one exact magnitude divide; +0.139512% at 320x200, 16,416 setup cases pass, and strict source-bound i486 audit |
| [2026-10-31-surface-cache-hit-leaf-entry-promoted.md](2026-10-31-surface-cache-hit-leaf-entry-promoted.md) | 4 | renderer performance / move the eligible static-texture hit return before callee-save and local-frame setup; +0.019160% in matched 320x200 runs, exact frame/PCX/checksum/event parity, and full i486 audit |
| [2026-10-31-span16-perspective-arithmetic-trials-rejected.md](2026-10-31-span16-perspective-arithmetic-trials-rejected.md) | 5 | renderer performance / reject zero-step reciprocal reuse after a 0.7705% slowdown; reject the FDIV stack rewrite after visible texture banding; reject direct stack-slot updates after two frame differences and a slower three-run mean |
| [2026-10-30-span8-alignment-and-prologue-schedules-rejected.md](2026-10-30-span8-alignment-and-prologue-schedules-rejected.md) | 2 | renderer performance / reject 8-pixel body alignment after a negligible negative 320x200 mean; reject combined and isolated span-row/pointer schedules after 9–32 per-frame checksum differences despite matching final checksums |
| [2026-10-30-surface-cache-hit-ebx-current-recheck-promoted.md](2026-10-30-surface-cache-hit-ebx-current-recheck-promoted.md) | 4 | renderer performance / retain the surface-cache hit pointer in EBX after a positive current-source three-run 320x200 mean, exact 970-frame checksum and PCX parity, golden-image pass, and full i486 audit (+0.0019312%) |
| [2026-10-30-edge-sort-nonbmodel-thirteen-continuation-rejected.md](2026-10-30-edge-sort-nonbmodel-thirteen-continuation-rejected.md) | 3 | renderer performance / reject the thirteen-continuation non-bmodel edge-sort group after a negative 320x200 mean; final checksums and event traces matched, candidate ISA audit skipped |
| [2026-10-30-span16-tfrac-between-store-width-rejected.md](2026-10-30-span16-tfrac-between-store-width-rejected.md) | 4 | renderer performance / reject moving the Span16 tfrac reload between the base store and cache-width add after a 0.00001633% negative 320x200 mean; captured frame 169 matched and full i486 gate passed |
| [2026-10-30-zspan-unroll-64-rejected.md](2026-10-30-zspan-unroll-64-rejected.md) | 3 | renderer performance / reject 64-pixel Z-span groups after 149 per-frame checksum mismatches and a 29.4141% changed-pixel fraction despite matching final checksums; slower mean and full i486 audit |
| [2026-10-30-zspan-pair-add-schedule-rejected.md](2026-10-30-zspan-pair-add-schedule-rejected.md) | 3 | renderer performance / reject moving the independent depth add between SHLD and ROR after a negligible negative 320x200 mean, exact final checksum and event parity, and complete i486 audit |
| [2026-10-30-surface-cache-key-order-rejected.md](2026-10-30-surface-cache-key-order-rejected.md) | 2 | renderer performance / reject checking the texture key before dlight after a negative three-run 320x200 mean, exact final checksum and event parity, and full i486 audit |
| [2026-10-30-edge-sort-nonbmodel-fifteen-continuation-rejected.md](2026-10-30-edge-sort-nonbmodel-fifteen-continuation-rejected.md) | 3 | renderer performance / reject one added non-bmodel edge-sort continuation after a negative 320x200 mean, exact final checksums and event traces, and a full i486 audit |
| [2026-10-30-cl-parseupdate-bitcounts-promoted.md](2026-10-30-cl-parseupdate-bitcounts-promoted.md) | 3 | client message parsing / remove unread 16-bit update counters; +0.03945% at 320x200 with exact framebuffer and event parity and a full i486 audit |
| [2026-10-30-zspan-row-table-before-fild-rejected.md](2026-10-30-zspan-row-table-before-fild-rejected.md) | 4 | renderer performance / reject moving the Z-row lookup before the second FILD after a negative 0.0000980% 320x200 mean, exact final checksums, and complete i486 audit |
| [2026-10-30-edge-sort-nonbmodel-sixteen-current-source-recheck-rejected.md](2026-10-30-edge-sort-nonbmodel-sixteen-current-source-recheck-rejected.md) | 3 | renderer performance / recheck two added non-bmodel edge-sort comparisons; +0.0000143% 320x200 mean below both sample spreads, exact final checksums, full i486 audit |
| [2026-10-30-surface-cache-hit-fastpath-rejected.md](2026-10-30-surface-cache-hit-fastpath-rejected.md) | 2 | renderer performance / reject a static surface-cache leaf hit after a positive +0.0231% 320x200 mean because 34 per-frame checksums differed; captured frame 500 and final checksum matched, but exact stream parity was not established |
| [2026-10-30-edge-sort-nonbmodel-fourteen-unroll-promoted.md](2026-10-30-edge-sort-nonbmodel-fourteen-unroll-promoted.md) | 3 | renderer performance / retain fourteen comparisons per non-bmodel edge-sort back-edge after three positive matched 320x200 pairs, exact fixed-step frame and PCX parity, and a complete i486 audit |
| [2026-10-30-edge-sort-nonbmodel-sixteen-continuation-rejected.md](2026-10-30-edge-sort-nonbmodel-sixteen-continuation-rejected.md) | 4 | renderer performance / reject two added non-bmodel edge-sort comparisons after a +0.00003880% mean below candidate run spread, exact 969-frame checksum parity, and full i486 audits |
| [2026-10-30-render-world-asm-timing-rejected.md](2026-10-30-render-world-asm-timing-rejected.md) | 3 | renderer performance / reject the `R_RenderWorld` assembly selector after three exact 320x200 pairs averaged 0.0005144% slower than C, with exact 969-frame checksum parity and strict i486 audits |
| [2026-10-30-renderface-empty-clipflags-fastpath-rejected.md](2026-10-30-renderface-empty-clipflags-fastpath-rejected.md) | 3 | renderer performance / reject a no-clip shortcut in `R_RenderFace` after five exact-source 320x200 pairs averaged 0.01290% slower, despite exact checksum, visual-golden, and strict i486 ISA passes |
| [2026-10-30-edge-sort-unroll-10-vs-12-rejected.md](2026-10-30-edge-sort-unroll-10-vs-12-rejected.md) | 1 | renderer performance / reject the ten-comparison non-bmodel edge-sort loop after five exact-source 320x200 runs averaged 0.00000490% below the twelve-comparison control, with exact checksum parity |
| [2026-10-30-zspan-x87-overlap-model-correction.md](2026-10-30-zspan-x87-overlap-model-correction.md) | 1 | measurement correction / the 80-cycle Z-span figure sums x87 latencies without integer/FPU overlap and is not net runtime or an attainable ceiling |
| [2026-10-30-vga-cache-set-model-correction.md](2026-10-30-vga-cache-set-model-correction.md) | 1 | measurement correction / equal 4 KB offsets establish L1 set congruence, not a guaranteed conflict; current 320x200 pad selects adjacent sets |
| [2026-10-30-vga-framebuffer-page-offset-pad-promoted.md](2026-10-30-vga-framebuffer-page-offset-pad-promoted.md) | 2 | renderer performance / shift the single-buffer 320x200 framebuffer by 16 bytes to avoid matching the surface-cache 4 KB page offset; positive +0.00002246% three-run mean, exact checksum parity, complete i486 audit; physical cache-conflict benefit unverified |
| [2026-10-29-edge-trailing-return-call-parity-rejected.md](2026-10-29-edge-trailing-return-call-parity-rejected.md) | 2 | renderer performance / reject the trailing-edge direct-call layout after the framebuffer checksum changed (3586745294 vs 1047377823); measured FPS invalid |
| [2026-10-29-span16-norowcross-current-recheck-rejected.md](2026-10-29-span16-norowcross-current-recheck-rejected.md) | 1 | renderer performance / reject the current-source Span16 no-row-cross specialization after a repeatable 0.5847% slowdown at 320x200 despite final checksum parity; strict ISA and frame-stream audits skipped |
| [2026-10-29-edge-sort-nonbmodel-twelve-unroll-promoted.md](2026-10-29-edge-sort-nonbmodel-twelve-unroll-promoted.md) | 2 | renderer performance / retain a twelve-way non-bmodel edge-sort unroll after a tiny positive three-run 320x200 mean, exact frame-checksum and PCX parity, and strict linked i486 ISA audit |
| [2026-10-29-zspan-row-index-load-interleave-promoted.md](2026-10-29-zspan-row-index-load-interleave-promoted.md) | 2 | renderer performance / promote interleaving the Z-span row-index load between coordinate FILDs after a positive strict 320x200 mean, exact full-frame checksum parity, golden-image pass, and complete i486 audit |
| [2026-10-29-surface-cache-hit-edi-pointer-strict-rejected.md](2026-10-29-surface-cache-hit-edi-pointer-strict-rejected.md) | 2 | renderer performance / reject retaining the cache pointer in EDI across the dynamic-light probe after a zero strict mean delta despite a tiny positive parity-only screen; exact checksum parity and complete i486 audits |
| [2026-10-29-surface-cache-prepare-keys-on-miss-promoted.md](2026-10-29-surface-cache-prepare-keys-on-miss-promoted.md) | 2 | renderer performance / skip surface-cache draw-key stores on hits after a positive three-run 320x200 mean, exact checksum parity, golden-image pass, and strict linked i486 audit (+0.000104%) |
| [2026-10-29-edge-sort-nonbmodel-twentyfour-unroll-rejected.md](2026-10-29-edge-sort-nonbmodel-twentyfour-unroll-rejected.md) | 2 | renderer performance / reject a twenty-four-way non-bmodel edge-sort unroll after two 320x200 candidate screens moved in opposite directions and did not show a repeatable gain; exact checksum parity; strict ISA audit skipped |
| [2026-10-29-span16-pow2-cachewidth-multiply-screen-rejected.md](2026-10-29-span16-pow2-cachewidth-multiply-screen-rejected.md) | 2 | renderer performance / reject replacing Span16 cache-width IMULs with guarded power-of-two shifts after a repeated negative 320x200 parity screen with exact checksum parity; full ISA audit skipped |
| [2026-10-29-span16-tfrac-load-hoist-rejected.md](2026-10-29-span16-tfrac-load-hoist-rejected.md) | 2 | renderer performance / reject hoisting the Span16 `tfracf` load before the address-table store and cache-width add after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-span16-full-segment-entry-alignment-rejected.md](2026-10-29-span16-full-segment-entry-alignment-rejected.md) | 2 | renderer performance / reject aligning the Span16 full-segment path to 16 bytes after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-alias-span-early-carry-delta-preload-rejected.md](2026-10-29-alias-span-early-carry-delta-preload-rejected.md) | 2 | renderer performance / reject loading the alias-span carry-selected address delta before the Z and S-fraction updates after a negative three-run 320x200 mean with exact checksum parity; full strict ISA audit skipped |
| [2026-10-29-span16-snext-reload-during-t-endpoint-rejected.md](2026-10-29-span16-snext-reload-during-t-endpoint-rejected.md) | 2 | renderer performance / reject moving the Span16 `snext` reload into T-endpoint math after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-span16-tadjust-between-endpoint-fistps-rejected.md](2026-10-29-span16-tadjust-between-endpoint-fistps-rejected.md) | 2 | renderer performance / reject moving the Span16 T-adjust load between endpoint FISTPs after a positive parity screen but a negative strict 320x200 mean despite exact checksum parity and complete executable i486 audit |
| [2026-10-29-alias-span-deferred-z-store-after-colormap-screen-rejected.md](2026-10-29-alias-span-deferred-z-store-after-colormap-screen-rejected.md) | 2 | renderer performance / reject delaying Alias Z-buffer stores until after the colormap load after a negative three-run 320x200 mean with exact checksum parity and a fresh control recheck; strict ISA audit skipped |
| [2026-10-29-alias-span-z-store-after-colormap-invalid.md](2026-10-29-alias-span-z-store-after-colormap-invalid.md) | 2 | renderer performance experiment / invalidated the post-colormap Alias Z-store reorder because it moved `LPatchN-4` into the store instruction; no timedemo timing or checksum result |
| [2026-10-29-alias-span-carry-delta-preload-screen-rejected.md](2026-10-29-alias-span-carry-delta-preload-screen-rejected.md) | 2 | renderer performance / reject preloading the alias-span carry-selected address delta before the S-fraction add after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-alias-span-hotloop-alignment-rejected.md](2026-10-29-alias-span-hotloop-alignment-rejected.md) | 2 | renderer performance / reject 16-byte alignment of the alias span hot-loop entry after a negative strict three-run 320x200 mean despite a positive parity screen, exact checksum parity, and complete executable i486 audit |
| [2026-10-29-alias-span-z-store-before-texel-load-screen-rejected.md](2026-10-29-alias-span-z-store-before-texel-load-screen-rejected.md) | 2 | renderer performance / reject moving Alias span Z-buffer stores before the texture fetch after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-renderface-branchless-edge-magnitude-rejected.md](2026-10-29-renderface-branchless-edge-magnitude-rejected.md) | 2 | renderer performance / reject branchless `CLTD/XOR/SUB` signed-edge magnitude in both RenderFace loops after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-surface-cache-hit-cache-register-rejected.md](2026-10-29-surface-cache-hit-cache-register-rejected.md) | 2 | renderer performance / reject retaining the surface-cache hit pointer in `%ebx` after a negative three-run 320x200 mean with exact checksum parity and a wide timing spread; strict ISA audit skipped |
| [2026-10-29-span16-byte-stores-rejected.md](2026-10-29-span16-byte-stores-rejected.md) | 2 | renderer performance / reject unrolled per-pixel Span16 byte stores after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-span16-loop-stores-rejected.md](2026-10-29-span16-loop-stores-rejected.md) | 2 | renderer performance / reject compact per-byte Span16 `STOSB` loops after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-span16-low-byte-fetch-in-sadd-adc-gap-rejected.md](2026-10-29-span16-low-byte-fetch-in-sadd-adc-gap-rejected.md) | 2 | renderer performance / reject moving Span16 low-byte texture fetches into the S-add/ADC gap after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-span16-loadfirst-fild-window-recheck-rejected.md](2026-10-29-span16-loadfirst-fild-window-recheck-rejected.md) | 2 | renderer performance / reject the existing Span16 `loadfirst` schedule against the promoted FILD-window control after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-edge-sort-nonbmodel-thirtytwo-unroll-rejected.md](2026-10-29-edge-sort-nonbmodel-thirtytwo-unroll-rejected.md) | 2 | renderer performance / reject extending the non-bmodel surface sort from sixteen to thirty-two comparisons per backedge after a neutral three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-edge-surface-base-before-indices-rejected.md](2026-10-29-edge-surface-base-before-indices-rejected.md) | 2 | renderer performance / reject loading the surface base before both edge indices after a negative strict 320x200 three-run mean despite a positive parity screen, exact checksum parity, and complete executable i486 audit |
| [2026-10-29-edge-surface-base-load-interleave-rejected.md](2026-10-29-edge-surface-base-load-interleave-rejected.md) | 2 | renderer performance / reject interleaving the independent surface-base load between edge-index loads after a negative strict 320x200 mean, exact checksum parity, and complete executable i486 audit |
| [2026-10-29-span16-u-load-before-rowbase-rejected.md](2026-10-29-span16-u-load-before-rowbase-rejected.md) | 2 | renderer performance / reject moving the Span16 U-coordinate load before the row-table lookup after a negative three-run 320x200 mean with exact checksum parity; strict ISA audit skipped |
| [2026-10-29-span16-carry-table-preload-schedules-rejected.md](2026-10-29-span16-carry-table-preload-schedules-rejected.md) | 2 | renderer performance / reject two Span16 carry-table preload schedules after negative three-run 320x200 means despite exact framebuffer parity; strict ISA audit skipped |
| [2026-10-29-span16-branch-address-parity-rejected.md](2026-10-29-span16-branch-address-parity-rejected.md) | 2 | renderer performance / reject branch-selected Span16 address updates after the first 320x200 frame failed exact checksum parity; no timing or strict ISA result |
| [2026-10-29-span16-split-fdiv-overlap-rejected.md](2026-10-29-span16-split-fdiv-overlap-rejected.md) | 2 | renderer performance / reject splitting Span16 integer loads between the FILD and FDIV windows after a negative pooled-mean parity screen; ISA audit skipped |
| [2026-10-29-span16-fild-window-setup-promoted.md](2026-10-29-span16-fild-window-setup-promoted.md) | 3 | renderer performance / schedule independent destination and continuation loads after Span16 `FILD`s after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.00008373% over paired-`FILD` parent) |
| [2026-10-29-span16-x87-load-spaced-rejected.md](2026-10-29-span16-x87-load-spaced-rejected.md) | 2 | renderer performance / reject spacing an integer load between Span16 `FILD`s after a strict pooled-mean loss, exact checksum parity, and complete i486 ISA audit |
| [2026-10-29-span16-x87-load-schedule-promoted.md](2026-10-29-span16-x87-load-schedule-promoted.md) | 3 | renderer performance / schedule independent integer loads after the paired Span16 `FILD`s after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.004863%) |
| [2026-10-29-surf8-mip0-lightdelta-stack-spill-promoted.md](2026-10-29-surf8-mip0-lightdelta-stack-spill-promoted.md) | 3 | renderer performance / replace the unrolled mip-0 row's absolute `lightdelta` global spill/reload with balanced stack operations after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.0001288%) |
| [2026-10-29-renderface-shared-edge-address-promoted.md](2026-10-29-renderface-shared-edge-address-promoted.md) | 2 | renderer performance / share signed-edge address formation and remove a negative-path jump and duplicate `lea` after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.0261%) |
| [2026-10-29-renderface-nearzionly-direct-compare-promoted.md](2026-10-29-renderface-nearzionly-direct-compare-promoted.md) | 2 | renderer performance / replace the `R_RenderFace` near-z-only load/test with one direct compare after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.0180%) |
| [2026-10-29-renderface-edge-marker-memory-test-promoted.md](2026-10-29-renderface-edge-marker-memory-test-promoted.md) | 2 | renderer performance / test the RenderFace cached-offset marker in memory and defer its load until the marked path after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.0205%) |
| [2026-10-29-renderface-cacheoffset-sentinel-direct-compare-promoted.md](2026-10-29-renderface-cacheoffset-sentinel-direct-compare-promoted.md) | 2 | renderer performance / compare the `R_RenderFace` cacheoffset sentinel directly in memory and remove its unused register load after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.00379%) |
| [2026-10-29-r-clipsprite-clipcurrent-direct-compare-promoted.md](2026-10-29-r-clipsprite-clipcurrent-direct-compare-promoted.md) | 2 | renderer performance / replace the sprite clip buffer load/test with one direct memory compare after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.0001553%) |
| [2026-10-29-r-clipedge-leftclipped-direct-compare-rejected.md](2026-10-29-r-clipedge-leftclipped-direct-compare-rejected.md) | 0 | renderer performance / reject comparing `r_leftclipped` directly in memory after a negative pooled parity screen with exact checksum parity |
| [2026-10-29-edge-trailing-insubmodel-direct-compare-promoted.md](2026-10-29-edge-trailing-insubmodel-direct-compare-promoted.md) | 2 | renderer performance / remove the `TrailingEdge` bmodel-flag register load and test after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.1197%) |
| [2026-10-29-edge-sort-nonbmodel-sixteen-unroll-promoted.md](2026-10-29-edge-sort-nonbmodel-sixteen-unroll-promoted.md) | 2 | renderer performance / check sixteen active surfaces per non-bmodel sort back-edge after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.00003676%) |
| [2026-10-29-edge-sort-nonbmodel-pair-unroll-promoted.md](2026-10-29-edge-sort-nonbmodel-pair-unroll-promoted.md) | 2 | renderer performance / check two active surfaces per non-bmodel sort back-edge after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.0175%) |
| [2026-10-29-edge-sort-nonbmodel-four-unroll-promoted.md](2026-10-29-edge-sort-nonbmodel-four-unroll-promoted.md) | 2 | renderer performance / check four active surfaces per non-bmodel sort back-edge after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.003974%) |
| [2026-10-29-edge-sort-nonbmodel-exit-branch-promoted.md](2026-10-29-edge-sort-nonbmodel-exit-branch-promoted.md) | 2 | renderer performance / invert the non-bmodel active-surface search exit branch after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.0344%) |
| [2026-10-29-edge-sort-nonbmodel-eight-unroll-promoted.md](2026-10-29-edge-sort-nonbmodel-eight-unroll-promoted.md) | 2 | renderer performance / check eight active surfaces per non-bmodel sort back-edge after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.0002553%) |
| [2026-10-29-edge-genspans-loop-alignment-rejected.md](2026-10-29-edge-genspans-loop-alignment-rejected.md) | 1 | renderer performance / reject 16-byte `R_GenerateSpans` loop-head alignment after a negative pooled parity screen with exact checksum parity |
| [2026-10-29-cross-object-isa-batching.md](2026-10-29-cross-object-isa-batching.md) | 2 | verification performance / batch proved instruction ranges across objects while preserving exact audit output |
| [2026-10-28-zspan-sub-nonnegative-stosl-promoted.md](2026-10-28-zspan-sub-nonnegative-stosl-promoted.md) | 3 | Nonnegative subtract-pair Z-span STOSL store (2026-10-28) |
| [2026-10-28-zspan-positive-pair-depth-step-reorder-promoted.md](2026-10-28-zspan-positive-pair-depth-step-reorder-promoted.md) | 3 | renderer performance / reorder the positive-pair Z-span depth add after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.00003695% mean) |
| [2026-10-28-vga-linear-copy-tail-fix.md](2026-10-28-vga-linear-copy-tail-fix.md) | 3 | renderer correctness / copy one-to-three trailing bytes on VGA dirty-rectangle rows and verify the destination against an independent expected buffer under the strict i486 gate |
| [2026-10-28-surface-cache-unused-style-lookup-promoted.md](2026-10-28-surface-cache-unused-style-lookup-promoted.md) | 2 | Surface-cache unused style lookup removed (2026-10-28) |
| [2026-10-28-surface-cache-style2-sentinel-promoted.md](2026-10-28-surface-cache-style2-sentinel-promoted.md) | 3 | Surface-cache second style sentinel check (2026-10-28) |
| [2026-10-28-surface-cache-style2-direct-compare-promoted.md](2026-10-28-surface-cache-style2-direct-compare-promoted.md) | 3 | renderer performance / compare the style2 sentinel directly in memory and skip the byte load when unused after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.00008004%) |
| [2026-10-28-surface-cache-style1-direct-compare-promoted.md](2026-10-28-surface-cache-style1-direct-compare-promoted.md) | 3 | renderer performance / compare the style1 sentinel directly in memory and skip the byte load when unused after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.00218581%) |
| [2026-10-28-surface-cache-hit-inline-return-promoted.md](2026-10-28-surface-cache-hit-inline-return-promoted.md) | 3 | renderer performance / inline the surface-cache hit epilogue and remove its unconditional jump after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.00249156%) |
| [2026-10-28-span16-sstep-shift-before-tstep-branch-promoted.md](2026-10-28-span16-sstep-shift-before-tstep-branch-promoted.md) | 3 | renderer performance / hoist the Span16 S integer shift before the T branch after a positive three-run mean, exact checksum parity, and complete i486 ISA audit (+0.0000595%) |
| [2026-10-28-span16-cachewidth-memory-operand-promoted.md](2026-10-28-span16-cachewidth-memory-operand-promoted.md) | 3 | renderer performance / use direct-memory cachewidth operands in Span16 setup after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.05146%) |
| [2026-10-28-renderface-cached-surface-compare-promoted.md](2026-10-28-renderface-cached-surface-compare-promoted.md) | 3 | renderer performance / replace the cached-edge surface load and test with one direct 16-bit compare after a positive strict mean, exact checksum parity, and complete i486 ISA audit (+0.006188%) |
| [2026-10-28-lightmap-build-assembly-rejected.md](2026-10-28-lightmap-build-assembly-rejected.md) | 0 | renderer performance / retain the C lightmap dispatcher after a strict three-run comparison measured it +0.0124666% faster than assembly with exact checksum parity |
| [2026-10-28-edge-leading-spanstate-direct-compare-promoted.md](2026-10-28-edge-leading-spanstate-direct-compare-promoted.md) | 2 | `R_GenerateSpans` leading-edge spanstate direct compare promoted (2026-10-28) |
| [2026-10-28-edge-leading-insubmodel-compare-promoted.md](2026-10-28-edge-leading-insubmodel-compare-promoted.md) | 2 | `R_GenerateSpans` leading-edge `insubmodel` direct compare promoted (2026-10-28) |
| [2026-10-28-dlight-edi-mask-register-promoted.md](2026-10-28-dlight-edi-mask-register-promoted.md) | 0 | renderer performance / keep the sparse dynamic-light mask in EDI and remove per-light stack traffic after a positive matched strict mean with exact checksum parity |
| [2026-10-28-dlight-btr-mask-clear-promoted.md](2026-10-28-dlight-btr-mask-clear-promoted.md) | 0 | renderer performance / replace two instructions with `BTR` to clear the selected dynamic-light bit after a positive strict mean and exact checksum parity |
| [2026-10-28-d-polyset-y-difference-memory-source-promoted.md](2026-10-28-d-polyset-y-difference-memory-source-promoted.md) | 0 | renderer performance / use memory-source subtraction in the three recursive alias-triangle Y checks after a positive matched mean, exact checksum parity, and complete i486 ISA audit |
| [2026-10-28-d-polyset-x-midpoint-memory-add-promoted.md](2026-10-28-d-polyset-x-midpoint-memory-add-promoted.md) | 3 | renderer performance / remove the unconditional X-midpoint source load and defer it to the equal-Y edge tie-break after a positive matched mean, exact checksum parity, and complete i486 ISA audit (+0.009289% mean) |
| [2026-10-28-d-polyset-x-difference-memory-source-promoted.md](2026-10-28-d-polyset-x-difference-memory-source-promoted.md) | 3 | renderer performance / use memory-source subtraction in the three recursive alias-triangle X checks after a positive matched mean, exact checksum parity, and complete i486 ISA audit (+0.050976% mean) |
| [2026-10-28-d-polyset-scan-left-height-lowword-promoted.md](2026-10-28-d-polyset-scan-left-height-lowword-promoted.md) | 3 | renderer performance / merge the left-edge scan height into the low-word loop counter after a positive matched strict mean, exact framebuffer checksum parity, and full i486 ISA audit |
| [2026-10-28-alias-raster-constant-pointer-cache-promoted.md](2026-10-28-alias-raster-constant-pointer-cache-promoted.md) | 0 | renderer performance / retain alias-raster triangle-constant pointers in callee-saved registers after a positive matched mean, exact checksum parity, and full i486 ISA gate |
| [2026-10-27-zspan-zero-step-positive-rep-promoted.md](2026-10-27-zspan-zero-step-positive-rep-promoted.md) | 0 | renderer performance / use aligned dword stores for repeated positive-depth zero-step Z spans after a positive strict mean, exact checksum parity, and complete i486 ISA audit |
| [2026-10-27-zspan-zero-step-negative-rep-rejected.md](2026-10-27-zspan-zero-step-negative-rep-rejected.md) | 0 | renderer performance / reject negative-depth zero-step `rep stosl` after a strict mean loss, exact checksum parity, and complete i486 ISA audit |
| [2026-10-27-zspan-negative-gradient-stosl-current-recheck-rejected.md](2026-10-27-zspan-negative-gradient-stosl-current-recheck-rejected.md) | 0 | Negative-gradient Z-span nonnegative-pair STOSL current-source recheck (2026-10-27) |
| [2026-10-27-zspan-cutoff20-recheck-rejected.md](2026-10-27-zspan-cutoff20-recheck-rejected.md) | 0 | Recheck D_DrawZSpans positive-gradient cutoff 20 (2026-10-27) |
| [2026-10-27-turbulent-t-index-fuse-promoted.md](2026-10-27-turbulent-t-index-fuse-promoted.md) | 0 | Fold turbulent T-index scaling into its shift and mask (2026-10-27) |
| [2026-10-27-turbulent-step-hoist-rejected.md](2026-10-27-turbulent-step-hoist-rejected.md) | 0 | Turbulent S/T-step scheduling rejected (2026-10-27) |
| [2026-10-27-turbulent-span-ten-loop-screen-rejected.md](2026-10-27-turbulent-span-ten-loop-screen-rejected.md) | 0 | renderer performance / reject the ten-pixel turbulent-span main loop after a negative parity-screen mean, exact checksum parity, and skip strict ISA after the screen failed |
| [2026-10-27-turbulent-span-fourteen-base-cache-promoted.md](2026-10-27-turbulent-span-fourteen-base-cache-promoted.md) | 0 | renderer performance / cache the turbulent texture base in EBX for the fourteen-pixel loop after a positive strict mean, exact checksum parity, and complete i486 ISA audit |
| [2026-10-27-turbulent-span-eleven-loop-screen-rejected.md](2026-10-27-turbulent-span-eleven-loop-screen-rejected.md) | 0 | renderer performance / reject the eleven-pixel turbulent-span main loop after a negative parity-screen mean, exact checksum parity, and skip strict ISA after the screen failed |
| [2026-10-27-turbulent-lookup-interleave-promoted.md](2026-10-27-turbulent-lookup-interleave-promoted.md) | 3 | renderer performance / interleave independent sine-table lookups in the turbulent span pixel loop after a positive three-run mean, exact checksum parity, and strict i486 ISA audit |
| [2026-10-27-turbulent-fourteen-stosb-promoted.md](2026-10-27-turbulent-fourteen-stosb-promoted.md) | 0 | renderer performance / use STOSB in the cached fourteen-pixel turbulent loop after a positive alternating mean, exact checksum parity, and complete i486 ISA audit |
| [2026-10-27-surf8-mip1-loop-alignment-screen-rejected.md](2026-10-27-surf8-mip1-loop-alignment-screen-rejected.md) | 0 | `surf8` mip-1 8-row loop alignment screen rejected (2026-10-27) |
| [2026-10-27-surf8-mip0-unroll8-rejected.md](2026-10-27-surf8-mip0-unroll8-rejected.md) | 1 | renderer performance / reject the mip-0 surface-block unroll8 selector after a strict pooled-mean loss, exact checksum parity, and full i486 ISA pass |
| [2026-10-27-surf8-mip0-loop-alignment-screen-rejected.md](2026-10-27-surf8-mip0-loop-alignment-screen-rejected.md) | 0 | `surf8` mip-0 16-row loop alignment screen rejected (2026-10-27) |
| [2026-10-27-span16-tailcount-indirect-dispatch-runtime-rejected.md](2026-10-27-span16-tailcount-indirect-dispatch-runtime-rejected.md) | 0 | renderer performance / reject the Span16 tail-count indirect dispatch after strict i486 audit passed but startup produced no timedemo report |
| [2026-10-27-span16-shorttail-memory-decrement-promoted.md](2026-10-27-span16-shorttail-memory-decrement-promoted.md) | 0 | renderer performance / decrement the final Span16 short-tail count directly in memory after a positive strict mean and complete i486 ISA gate |
| [2026-10-27-span16-row-path-rejected.md](2026-10-27-span16-row-path-rejected.md) | 0 | Span16 same-row specialized path rejected (2026-10-27) |
| [2026-10-27-span16-deferred-count-load-promoted.md](2026-10-27-span16-deferred-count-load-promoted.md) | 0 | renderer performance / skip the repeated remaining-count load when entering another full Span16 segment after a positive strict mean and complete i486 ISA gate |
| [2026-10-27-span16-counttemp-sadjust-order-rejected.md](2026-10-27-span16-counttemp-sadjust-order-rejected.md) | 0 | renderer performance / reject moving the full-segment count subtraction after the sadjust load after a negative strict mean, exact checksum parity, and complete i486 ISA audit |
| [2026-10-27-span16-counttemp-middle-segment-promoted.md](2026-10-27-span16-counttemp-middle-segment-promoted.md) | 0 | renderer performance / remove the repeated count load and writeback from full Span16 middle segments after a positive strict mean and complete i486 ISA gate |
| [2026-10-27-span16-counttemp-direct-subtract-promoted.md](2026-10-27-span16-counttemp-direct-subtract-promoted.md) | 0 | renderer performance / subtract each full Span16 segment directly from the seeded remaining count after a positive strict mean and complete i486 ISA gate |
| [2026-10-27-renderface-edge-cache-sign-test-screen-rejected.md](2026-10-27-renderface-edge-cache-sign-test-screen-rejected.md) | 0 | R_RenderFace edge-cache sentinel sign-test screen rejected (2026-10-27) |
| [2026-10-27-r-scan-edges-cached-state-promoted.md](2026-10-27-r-scan-edges-cached-state-promoted.md) | 0 | renderer performance / cache the draw callback and surface base, and clear span-state entries in bounded groups after a positive matched mean and strict i486 audit |
| [2026-10-27-edge-trailing-spanstate-fastpath-promoted.md](2026-10-27-edge-trailing-spanstate-fastpath-promoted.md) | 2 | renderer performance / bypass backward trailing-edge helper calls on non-transition spans after a positive strict mean, exact checksum parity, and complete i486 audit |
| [2026-10-27-d-cachesurface-hit-key-store-deferral-promoted.md](2026-10-27-d-cachesurface-hit-key-store-deferral-promoted.md) | 2 | renderer performance / defer surface-cache draw-key stores on hits after a positive strict mean, exact checksum parity, and complete i486 audit |
| [2026-10-27-alias-span-pointer-add-order-rejected.md](2026-10-27-alias-span-pointer-add-order-rejected.md) | 0 | renderer performance / reject the alias-span pointer-add reorder after a negative strict mean, exact checksum parity, and full i486 ISA pass |
| [2026-10-27-alias-draw-span-count-decrement-promoted.md](2026-10-27-alias-draw-span-count-decrement-promoted.md) | 3 | renderer performance / decrement the alias span count once and remove one common-path branch after a positive strict mean, exact checksum parity, and complete i486 ISA audit |
| [2026-10-26-zspan-sub-pair-stosl-promoted.md](2026-10-26-zspan-sub-pair-stosl-promoted.md) | 0 | renderer performance / promote STOSL in the general subtract-pair Z-span fallback after a 0.000005 FPS strict gain, exact checksum parity, and complete i486 ISA pass |
| [2026-10-26-zspan-nonnegative-stosl-promoted.md](2026-10-26-zspan-nonnegative-stosl-promoted.md) | 0 | renderer performance / promote STOSL for the nonnegative Z-span pair store after a 0.137316 FPS strict gain, exact checksum parity, and complete i486 ISA pass |
| [2026-10-26-zspan-negative-gradient-stosl-strict-rejected.md](2026-10-26-zspan-negative-gradient-stosl-strict-rejected.md) | 0 | renderer performance / reject STOSL in the nonnegative negative-gradient Z-span loop after a 0.000002333 FPS strict mean loss, exact checksum parity, and complete i486 ISA pass |
| [2026-10-26-zspan-negative-depth-sub-stosl-screen-rejected.md](2026-10-26-zspan-negative-depth-sub-stosl-screen-rejected.md) | 0 | renderer performance / reject STOSL in the negative-depth subtract-pair Z-span path after a repeat parity-screen mean loss, exact checksum parity |
| [2026-10-26-zspan-negative-depth-add-stosl-promoted.md](2026-10-26-zspan-negative-depth-add-stosl-promoted.md) | 0 | renderer performance / promote STOSL in the negative-depth Z-span pair after a 0.000008 FPS strict gain, exact checksum parity, and complete i486 ISA pass |
| [2026-10-26-zspan-general-add-pair-stosl-promoted.md](2026-10-26-zspan-general-add-pair-stosl-promoted.md) | 0 | renderer performance / promote STOSL for the general positive-sample Z-span pair after a 0.021634 FPS strict gain, exact checksum parity, and complete i486 ISA pass |
| [2026-10-26-span16-zero-t-outofline-cold-block-strict-rejected.md](2026-10-26-span16-zero-t-outofline-cold-block-strict-rejected.md) | 3 | renderer performance / reject moving the Span16 zero-T setup after the return because the full strict mean was 0.000008334 FPS below control, despite exact parity and complete i486 ISA pass |
| [2026-10-26-span16-zero-t-branch-fallthrough-strict-rejected.md](2026-10-26-span16-zero-t-branch-fallthrough-strict-rejected.md) | 3 | renderer performance / reject the `D_DrawSpans16` nonzero-T fallthrough layout after a 0.000470 FPS strict regression, exact checksum parity, and complete i486 ISA pass |
| [2026-10-26-span16-row-index-before-x87-strict-rejected.md](2026-10-26-span16-row-index-before-x87-strict-rejected.md) | 0 | Span16 row-index load before x87 rejected |
| [2026-10-26-span16-high-byte-load-before-tcarry-screen-rejected.md](2026-10-26-span16-high-byte-load-before-tcarry-screen-rejected.md) | 0 | renderer performance / reject moving later Span16 high-byte loads before T-carry capture after a repeat parity-screen mean loss, exact checksum parity |
| [2026-10-26-span16-full-segment-align-screen-rejected.md](2026-10-26-span16-full-segment-align-screen-rejected.md) | 0 | Reject 16-byte alignment of the full Span16 segment loop (2026-10-26) |
| [2026-10-26-span16-fild-load-interleave-promoted.md](2026-10-26-span16-fild-load-interleave-promoted.md) | 0 | Span16 coordinate-load interleave promoted (2026-10-26) |
| [2026-10-26-span16-cachewidth16-shift-screen-rejected.md](2026-10-26-span16-cachewidth16-shift-screen-rejected.md) | 3 | renderer performance / reject replacing Span16's width-16 integer multiply with a shift after a 0.016378 FPS parity-screen regression |
| [2026-10-26-edge-trailing-current-iv-load-screen-rejected.md](2026-10-26-edge-trailing-current-iv-load-screen-rejected.md) | 0 | Reject `current_iv` load interleave in `TrailingEdge` (2026-10-26) |
| [2026-10-26-edge-step-third-u-store-after-compare-screen-rejected.md](2026-10-26-edge-step-third-u-store-after-compare-screen-rejected.md) | 0 | renderer performance / reject moving the third `R_StepActiveU` U-store after its compare on a negative parity-screen mean |
| [2026-10-26-edge-step-second-u-store-after-compare-promoted.md](2026-10-26-edge-step-second-u-store-after-compare-promoted.md) | 0 | renderer performance / schedule the second `R_StepActiveU` U-store after its compare with a positive strict mean, exact checksum parity, and complete i486 ISA gate |
| [2026-10-26-edge-step-fourth-u-store-after-compare-strict-tied.md](2026-10-26-edge-step-fourth-u-store-after-compare-strict-tied.md) | 0 | renderer performance / strict recheck ties the fourth `R_StepActiveU` U-store schedule despite a positive parity screen |
| [2026-10-26-edge-step-fourth-next-load-hoist-promoted.md](2026-10-26-edge-step-fourth-next-load-hoist-promoted.md) | 0 | renderer performance / hoist the fourth `R_StepActiveU` next-link load ahead of its U update after a positive strict mean, exact checksum parity, and complete i486 ISA gate |
| [2026-10-26-edge-step-first-u-store-after-compare-screen-rejected.md](2026-10-26-edge-step-first-u-store-after-compare-screen-rejected.md) | 0 | renderer performance / reject moving the first `R_StepActiveU` U-store after its compare on a negative parity-screen mean |
| [2026-10-26-edge-remove-test-before-final-unlink-store-rejected.md](2026-10-26-edge-remove-test-before-final-unlink-store-rejected.md) | 0 | `R_RemoveEdges`: test `nextremove` before the final unlink store — rejected |
| [2026-10-26-edge-remove-reverse-unlink-store-order-promoted.md](2026-10-26-edge-remove-reverse-unlink-store-order-promoted.md) | 0 | Legacy `R_RemoveEdges` unlink-store order promoted (2026-10-26) |
| [2026-10-26-edge-remove-nextremove-load-before-unlink-stores-rejected.md](2026-10-26-edge-remove-nextremove-load-before-unlink-stores-rejected.md) | 0 | `R_RemoveEdges`: load `nextremove` before both unlink stores — rejected |
| [2026-10-26-edge-remove-nextremove-load-after-unlink-promoted.md](2026-10-26-edge-remove-nextremove-load-after-unlink-promoted.md) | 0 | Legacy `R_RemoveEdges` nextremove load after unlink promoted (2026-10-26) |
| [2026-10-26-edge-remove-nextremove-between-unlink-stores-rejected.md](2026-10-26-edge-remove-nextremove-between-unlink-stores-rejected.md) | 0 | `R_RemoveEdges`: advance `nextremove` between unlink stores — rejected |
| [2026-10-26-edge-remove-neighbor-load-order-promoted.md](2026-10-26-edge-remove-neighbor-load-order-promoted.md) | 0 | Legacy `R_RemoveEdges` neighbor-pointer load order promoted (2026-10-26) |
| [2026-10-26-edge-pushback-unlink-store-order-screen-rejected.md](2026-10-26-edge-pushback-unlink-store-order-screen-rejected.md) | 0 | Edge pushback unlink-store order screen rejected (2026-10-26) |
| [2026-10-26-edge-pushback-link-store-order-screen-rejected.md](2026-10-26-edge-pushback-link-store-order-screen-rejected.md) | 0 | Edge pushback neighbor-link store order screen rejected (2026-10-26) |
| [2026-10-26-edge-newtop-current-iv-preload-rejected.md](2026-10-26-edge-newtop-current-iv-preload-rejected.md) | 1 | Reject `current_iv` preload in `R_GenerateSpans` `Lnewtop` (2026-10-26) |
| [2026-10-26-edge-leading-spanstate-first-screen-rejected.md](2026-10-26-edge-leading-spanstate-first-screen-rejected.md) | 1 | Reject spanstate-first leading-edge dispatch (2026-10-26) |
| [2026-10-26-edge-leading-load-order-screen-rejected.md](2026-10-26-edge-leading-load-order-screen-rejected.md) | 1 | Reject leading-edge load-order swap (2026-10-26) |
| [2026-10-26-bsp-walk-framecount-register-cache-promoted.md](2026-10-26-bsp-walk-framecount-register-cache-promoted.md) | 0 | renderer performance / cache the frame count in a register across the BSP node-surface loop after a positive strict mean, exact checksum parity, and complete i486 ISA gate |
| [2026-10-26-bsp-surface-cursor-register-promoted.md](2026-10-26-bsp-surface-cursor-register-promoted.md) | 1 | renderer performance / retain the BSP surface cursor in ESI after a positive strict mean, exact checksum parity, and complete i486 ISA gate |
| [2026-10-26-alias-span-texel-load-before-z-screen-rejected.md](2026-10-26-alias-span-texel-load-before-z-screen-rejected.md) | 0 | Alias span texel load before Z comparison screen rejected (2026-10-26) |
| [2026-10-26-alias-span-depth-update-first-strict-rejected.md](2026-10-26-alias-span-depth-update-first-strict-rejected.md) | 0 | Alias span depth-update-first schedule rejected |
| [2026-10-26-alias-span-address-before-depth-screen-rejected.md](2026-10-26-alias-span-address-before-depth-screen-rejected.md) | 0 | Alias span address-update-before-depth schedule rejected |
| [2026-10-26-alias-scan-no-turnover-fallthrough-strict-rejected.md](2026-10-26-alias-scan-no-turnover-fallthrough-strict-rejected.md) | 0 | Alias scan no-turnover fallthrough layout rejected (2026-10-26) |
| [2026-10-26-alias-scan-low-word-decrement-promoted.md](2026-10-26-alias-scan-low-word-decrement-promoted.md) | 0 | renderer performance / replace the alias scan's 32-bit decrement and low-word test with a 16-bit decrement after a positive matched mean and strict i486 ISA gate |
| [2026-10-25-zspan-positive-group32-fixed-offset-stores-parity-rejected.md](2026-10-25-zspan-positive-group32-fixed-offset-stores-parity-rejected.md) | 0 | D_DrawZSpans positive 32-pixel fixed-offset stores rejected |
| [2026-10-25-zspan-exact-zero-u-gradient-rejected.md](2026-10-25-zspan-exact-zero-u-gradient-rejected.md) | 0 | D_DrawZSpans exact zero-U-gradient shortcut (2026-10-25) |
| [2026-10-25-zspan-common-fastpath-fallthrough-promoted.md](2026-10-25-zspan-common-fastpath-fallthrough-promoted.md) | 0 | renderer performance / make the proven nonnegative Z-span path fall through into its fast loop after a positive strict mean, exact checksum parity, and complete i486 ISA gate |
| [2026-10-25-texture-span-stosw-current-schedule-recheck-rejected.md](2026-10-25-texture-span-stosw-current-schedule-recheck-rejected.md) | 0 | Texture-span `stosw` recheck on the current schedule rejected |
| [2026-10-25-texture-span-next-pointer-stack-promotion.md](2026-10-25-texture-span-next-pointer-stack-promotion.md) | 1 | Texture-span next-pointer carry (2026-10-25) |
| [2026-10-25-texture-span-fold-extents-into-clamp-compares-promoted.md](2026-10-25-texture-span-fold-extents-into-clamp-compares-promoted.md) | 1 | Texture-span clamp compares read extents directly (2026-10-25) |
| [2026-10-25-surf8-mip3-sourcetstep-load-hoist-rejected.md](2026-10-25-surf8-mip3-sourcetstep-load-hoist-rejected.md) | 0 | Mip-3 source-step load hoist rejected |
| [2026-10-25-surf8-mip3-paired-word-store-rejected.md](2026-10-25-surf8-mip3-paired-word-store-rejected.md) | 0 | Mip-3 paired word store rejected |
| [2026-10-25-surf8-mip1-texel-load-pair-before-lightdelta-rejected.md](2026-10-25-surf8-mip1-texel-load-pair-before-lightdelta-rejected.md) | 0 | Mip-1 source-texel pair before light-delta save rejected |
| [2026-10-25-surf8-mip1-lightdelta-stack-roundtrip-rejected.md](2026-10-25-surf8-mip1-lightdelta-stack-roundtrip-rejected.md) | 0 | Mip-1 light-delta stack round trip rejected |
| [2026-10-25-surf8-mip1-horizontal-flat-single-pass.md](2026-10-25-surf8-mip1-horizontal-flat-single-pass.md) | 1 | Mip-1 horizontal-flat blocks use a straight-line row body (2026-10-25) |
| [2026-10-25-surf8-mip1-flat-helper-tail-jump-promoted.md](2026-10-25-surf8-mip1-flat-helper-tail-jump-promoted.md) | 1 | Mip-1 flat surface helpers tail-jump to block completion (2026-10-25) |
| [2026-10-25-surf8-mip1-first-texel-load-before-lightdelta-rejected.md](2026-10-25-surf8-mip1-first-texel-load-before-lightdelta-rejected.md) | 0 | Mip-1 first source-texel read before light-delta save rejected |
| [2026-10-25-surf8-mip0-texel-load-pair-before-lightdelta-rejected.md](2026-10-25-surf8-mip0-texel-load-pair-before-lightdelta-rejected.md) | 0 | Mip-0 source-texel pair before light-delta save rejected |
| [2026-10-25-surf8-mip0-lightdelta-stack-roundtrip-rejected.md](2026-10-25-surf8-mip0-lightdelta-stack-roundtrip-rejected.md) | 0 | Mip-0 light-delta stack round trip rejected |
| [2026-10-25-surf8-mip0-horizontal-flat-dword-packing.md](2026-10-25-surf8-mip0-horizontal-flat-dword-packing.md) | 1 | Mip-0 horizontal-flat rows use packed dword stores (2026-10-25) |
| [2026-10-25-surf8-mip0-flat-row-counter.md](2026-10-25-surf8-mip0-flat-row-counter.md) | 1 | Mip-0 flat surface row counter in AH (2026-10-25) |
| [2026-10-25-surf8-mip0-flat-helper-tail-jump-promoted.md](2026-10-25-surf8-mip0-flat-helper-tail-jump-promoted.md) | 1 | Mip-0 flat surface helpers tail-jump to block completion (2026-10-25) |
| [2026-10-25-surf8-mip0-flat-dword-packing.md](2026-10-25-surf8-mip0-flat-dword-packing.md) | 1 | Mip-0 fully-flat rows use packed dword stores (2026-10-25) |
| [2026-10-25-surf8-mip0-first-texel-load-before-lightdelta-strict-rejected.md](2026-10-25-surf8-mip0-first-texel-load-before-lightdelta-strict-rejected.md) | 0 | Mip-0 first texel load before light-delta save rejected |
| [2026-10-25-span16-u-load-early-screen-rejected.md](2026-10-25-span16-u-load-early-screen-rejected.md) | 0 | Span16 U-coordinate load moved into initial setup rejected |
| [2026-10-25-span16-split-adjustment-load-schedule-promoted.md](2026-10-25-span16-split-adjustment-load-schedule-promoted.md) | 0 | Span16 split adjustment-load schedule promoted |
| [2026-10-25-span16-sadjust-in-u-load-gap-screen-rejected.md](2026-10-25-span16-sadjust-in-u-load-gap-screen-rejected.md) | 0 | Span16 `sadjust` load in U-coordinate load gap rejected |
| [2026-10-25-span16-sadjust-after-row-count-screen-rejected.md](2026-10-25-span16-sadjust-after-row-count-screen-rejected.md) | 0 | Span16 `sadjust` load after row and count setup rejected |
| [2026-10-25-span16-row-base-early-load-screen-rejected.md](2026-10-25-span16-row-base-early-load-screen-rejected.md) | 0 | Span16 row-base lookup moved into initial setup rejected |
| [2026-10-25-span16-row-base-before-sadjust-screen-rejected.md](2026-10-25-span16-row-base-before-sadjust-screen-rejected.md) | 0 | Span16 row-base lookup before `sadjust` rejected |
| [2026-10-25-span16-row-address-x87-overlap-rejected.md](2026-10-25-span16-row-address-x87-overlap-rejected.md) | 0 | Span16 row-address and next-span load overlap rejected |
| [2026-10-25-span16-next-pointer-promotion.md](2026-10-25-span16-next-pointer-promotion.md) | 1 | 16-bit texture-span next-pointer carry (2026-10-25) |
| [2026-10-25-span16-adjustment-loads-early-promoted.md](2026-10-25-span16-adjustment-loads-early-promoted.md) | 0 | Span16 S/T adjustment loads moved into initial setup promoted |
| [2026-10-25-renderface-numedges-load-hoist-promoted.md](2026-10-25-renderface-numedges-load-hoist-promoted.md) | 1 | renderer performance / load `fa->numedges` before the surface-capacity branch in `R_RenderFace` after a positive strict mean, exact checksum parity, and complete i486 ISA gate |
| [2026-10-25-drawspans16-row-index-early-load-promoted.md](2026-10-25-drawspans16-row-index-early-load-promoted.md) | 0 | Span16 row-index load moved into initial setup promoted |
| [2026-10-25-alias-transform-x87-load-order-promoted.md](2026-10-25-alias-transform-x87-load-order-promoted.md) | 0 | Alias transform load order removes an FXCH (2026-10-25) |
| [2026-10-25-alias-transform-third-term-load-promoted.md](2026-10-25-alias-transform-third-term-load-promoted.md) | 0 | Alias transform adds the first two terms before loading the third (2026-10-25) |
| [2026-10-25-alias-transform-final-store-order-promoted.md](2026-10-25-alias-transform-final-store-order-promoted.md) | 0 | Alias transform stores projected fields in stack order (2026-10-25) |
| [2026-10-25-alias-normal-x87-load-order-promoted.md](2026-10-25-alias-normal-x87-load-order-promoted.md) | 0 | Alias normal load order removes an FXCH (2026-10-25) |
| [2026-10-25-alias-nonnegative-light-fallthrough-promoted.md](2026-10-25-alias-nonnegative-light-fallthrough-promoted.md) | 2 | renderer performance / let common nonnegative alias light fall through to projection after a positive strict mean, exact checksum parity, and complete i486 ISA gate |
| [2026-10-25-alias-light-sign-memory-test-promoted.md](2026-10-25-alias-light-sign-memory-test-promoted.md) | 0 | Alias light-sign test uses a direct memory operand (2026-10-25) |
| [2026-10-25-alias-light-dot-before-x-partial-promoted.md](2026-10-25-alias-light-dot-before-x-partial-promoted.md) | 0 | Alias light dot product completes before the X partial (2026-10-25) |
| [2026-10-24-zspan-sub-nonnegative-destination-lea-shld-gap-rejected.md](2026-10-24-zspan-sub-nonnegative-destination-lea-shld-gap-rejected.md) | 0 | renderer performance / reject scheduling the negative-gradient nonnegative Z-span destination pointer increment between SHLD and ROR after a slower strict mean with exact checksum parity and full i486 ISA gate |
| [2026-10-24-zspan-positive-gradient-overflow-guard-promoted.md](2026-10-24-zspan-positive-gradient-overflow-guard-promoted.md) | 0 | renderer performance / replace the positive-gradient Z-span endpoint's 64-bit carry chain with signed overflow checks after a positive strict mean and full i486 ISA audit |
| [2026-10-24-zspan-positive-cutoff21-promoted.md](2026-10-24-zspan-positive-cutoff21-promoted.md) | 0 | D_DrawZSpans positive-gradient cutoff lowered to 21 pixels (2026-10-24) |
| [2026-10-24-zspan-nonnegative-step-between-shld-ror-promoted.md](2026-10-24-zspan-nonnegative-step-between-shld-ror-promoted.md) | 0 | renderer performance / schedule the second fixed-point step between SHLD and ROR in the nonnegative i486 Z-span pair loop after a positive strict mean |
| [2026-10-24-zspan-nonnegative-step-after-store-rejected.md](2026-10-24-zspan-nonnegative-step-after-store-rejected.md) | 0 | D_DrawZSpans second-step add after store (2026-10-24) |
| [2026-10-24-zspan-nonnegative-span-cutoff32-rejected.md](2026-10-24-zspan-nonnegative-span-cutoff32-rejected.md) | 0 | D_DrawZSpans nonnegative span cutoff at 32 pixels |
| [2026-10-24-zspan-nonnegative-second-step-lea-screen-rejected.md](2026-10-24-zspan-nonnegative-second-step-lea-screen-rejected.md) | 0 | D_DrawZSpans second accumulator step with LEA (2026-10-24) |
| [2026-10-24-zspan-nonnegative-pointer-add-rejected.md](2026-10-24-zspan-nonnegative-pointer-add-rejected.md) | 0 | D_DrawZSpans nonnegative pointer increment with ADD (2026-10-24) |
| [2026-10-24-zspan-nonnegative-group64-screen-rejected.md](2026-10-24-zspan-nonnegative-group64-screen-rejected.md) | 0 | D_DrawZSpans branch-free 64-pixel group (2026-10-24) |
| [2026-10-24-zspan-nonnegative-group48-rejected.md](2026-10-24-zspan-nonnegative-group48-rejected.md) | 0 | renderer performance / reject the 48-pixel nonnegative Z-span group after a slower strict timedemo |
| [2026-10-24-zspan-nonnegative-group40-rejected.md](2026-10-24-zspan-nonnegative-group40-rejected.md) | 0 | renderer performance / reject the 40-pixel nonnegative Z-span group after a slower strict timedemo |
| [2026-10-24-zspan-nonnegative-group32-promoted.md](2026-10-24-zspan-nonnegative-group32-promoted.md) | 1 | D_DrawZSpans branch-free 32-pixel group (2026-10-24) |
| [2026-10-24-zspan-nonnegative-group32-alignment-rejected.md](2026-10-24-zspan-nonnegative-group32-alignment-rejected.md) | 0 | renderer performance / reject 16-byte alignment of the 32-pixel nonnegative Z-span loop after a slower strict timedemo |
| [2026-10-24-zspan-nonnegative-group24-screen-rejected.md](2026-10-24-zspan-nonnegative-group24-screen-rejected.md) | 0 | renderer performance / reject the 24-pixel nonnegative Z-span group after a slower parity screen |
| [2026-10-24-zspan-nonnegative-first-step-lea-strict-rejected.md](2026-10-24-zspan-nonnegative-first-step-lea-strict-rejected.md) | 0 | D_DrawZSpans first accumulator step with LEA (2026-10-24) |
| [2026-10-24-zspan-nonnegative-cutoff8-screen-rejected.md](2026-10-24-zspan-nonnegative-cutoff8-screen-rejected.md) | 0 | D_DrawZSpans nonnegative fast-path cutoff 8 (2026-10-24) |
| [2026-10-24-zspan-nonnegative-cutoff20-strict-rejected.md](2026-10-24-zspan-nonnegative-cutoff20-strict-rejected.md) | 0 | D_DrawZSpans nonnegative fast-path cutoff 20 (2026-10-24) |
| [2026-10-24-zspan-nonnegative-cutoff19-strict-rejected.md](2026-10-24-zspan-nonnegative-cutoff19-strict-rejected.md) | 0 | D_DrawZSpans nonnegative fast-path cutoff 19 (2026-10-24) |
| [2026-10-24-zspan-nonnegative-cutoff18-promoted.md](2026-10-24-zspan-nonnegative-cutoff18-promoted.md) | 1 | D_DrawZSpans nonnegative fast-path cutoff 18 (2026-10-24) |
| [2026-10-24-zspan-nonnegative-cutoff17-screen-rejected.md](2026-10-24-zspan-nonnegative-cutoff17-screen-rejected.md) | 0 | D_DrawZSpans nonnegative fast-path cutoff 17 (2026-10-24) |
| [2026-10-24-zspan-nonnegative-cutoff16-promoted.md](2026-10-24-zspan-nonnegative-cutoff16-promoted.md) | 1 | D_DrawZSpans nonnegative fast-path cutoff 16 (2026-10-24) |
| [2026-10-24-zspan-nonnegative-cutoff12-screen-rejected.md](2026-10-24-zspan-nonnegative-cutoff12-screen-rejected.md) | 0 | D_DrawZSpans nonnegative fast-path cutoff 12 (2026-10-24) |
| [2026-10-24-zspan-nonnegative-both-adds-to-lea-screen-rejected.md](2026-10-24-zspan-nonnegative-both-adds-to-lea-screen-rejected.md) | 0 | D_DrawZSpans two accumulator LEAs (2026-10-24) |
| [2026-10-24-zspan-negative-subtract-step-overlap-promoted.md](2026-10-24-zspan-negative-subtract-step-overlap-promoted.md) | 0 | renderer performance / schedule the second fixed-point step between SHLD and ROR in the negative-depth i486 Z-span pair loop after a positive strict mean |
| [2026-10-24-zspan-negative-gradient-overflow-guard-screen-rejected.md](2026-10-24-zspan-negative-gradient-overflow-guard-screen-rejected.md) | 0 | renderer performance / reject the signed-overflow endpoint guard in the negative-gradient Z-span path after a slower parity screen |
| [2026-10-24-zspan-negative-gradient-nonnegative-fastpath-promoted.md](2026-10-24-zspan-negative-gradient-nonnegative-fastpath-promoted.md) | 0 | renderer performance / bypass per-pair sign tests for long negative-gradient Z spans when an exact endpoint proof guarantees nonnegative depths |
| [2026-10-24-zspan-negative-gradient-group32-screen-rejected.md](2026-10-24-zspan-negative-gradient-group32-screen-rejected.md) | 0 | renderer performance / reject 32-pixel groups for the negative-gradient nonnegative Z-span path after a slower parity screen |
| [2026-10-24-zspan-negative-gradient-cutoff24-screen-rejected.md](2026-10-24-zspan-negative-gradient-cutoff24-screen-rejected.md) | 0 | renderer performance / reject a cutoff of 24 pixels for the negative-gradient nonnegative Z-span path after a slower parity screen |
| [2026-10-24-zspan-negative-gradient-cutoff20-screen-rejected.md](2026-10-24-zspan-negative-gradient-cutoff20-screen-rejected.md) | 0 | renderer performance / reject a cutoff of 20 pixels for the negative-gradient nonnegative Z-span path after a slower parity screen |
| [2026-10-24-zspan-negative-gradient-cutoff18-screen-rejected.md](2026-10-24-zspan-negative-gradient-cutoff18-screen-rejected.md) | 0 | renderer performance / reject a cutoff of 18 pixels for the negative-gradient nonnegative Z-span path after a slower parity screen |
| [2026-10-24-zspan-negative-endpoint-sign-check-rejected.md](2026-10-24-zspan-negative-endpoint-sign-check-rejected.md) | 0 | renderer performance / reject removal of the negative-gradient endpoint low-word sign check after a slower strict mean with exact parity and complete i486 ISA audit |
| [2026-10-24-zspan-negative-destination-lea-shld-gap-rejected.md](2026-10-24-zspan-negative-destination-lea-shld-gap-rejected.md) | 0 | renderer performance / reject scheduling the negative-depth Z-span destination pointer increment between SHLD and ROR after a slower strict mean with exact checksum parity and full i486 ISA gate |
| [2026-10-24-zspan-negative-depth-step-overlap-rejected.md](2026-10-24-zspan-negative-depth-step-overlap-rejected.md) | 0 | renderer performance / reject scheduling the second Z step between SHLD and ROR in the negative-depth i486 pair path after a slower strict mean |
| [2026-10-24-zspan-negative-cutoff21-promoted.md](2026-10-24-zspan-negative-cutoff21-promoted.md) | 0 | renderer performance / lower the negative-gradient Z-span fast-path cutoff to 21 pixels after a positive strict mean, checksum parity, and complete i486 ISA audit |
| [2026-10-24-zspan-length-guard-before-sign-promoted.md](2026-10-24-zspan-length-guard-before-sign-promoted.md) | 1 | D_DrawZSpans length guard before sign check (2026-10-24) |
| [2026-10-24-zspan-length-first-cutoff24-screen-rejected.md](2026-10-24-zspan-length-first-cutoff24-screen-rejected.md) | 0 | D_DrawZSpans length-first guard with cutoff 24 (2026-10-24) |
| [2026-10-24-zspan-length-first-cutoff23-strict-rejected.md](2026-10-24-zspan-length-first-cutoff23-strict-rejected.md) | 0 | D_DrawZSpans length-first guard with cutoff 23 (2026-10-24) |
| [2026-10-24-zspan-length-first-cutoff22-promoted.md](2026-10-24-zspan-length-first-cutoff22-promoted.md) | 1 | D_DrawZSpans length-first guard with cutoff 22 (2026-10-24) |
| [2026-10-24-zspan-length-first-cutoff20-promoted.md](2026-10-24-zspan-length-first-cutoff20-promoted.md) | 1 | D_DrawZSpans length-first guard with cutoff 20 (2026-10-24) |
| [2026-10-24-zspan-group32-cutoff24-screen-rejected.md](2026-10-24-zspan-group32-cutoff24-screen-rejected.md) | 0 | D_DrawZSpans 32-pixel group with cutoff 24 (2026-10-24) |
| [2026-10-24-zspan-group32-cutoff23-screen-rejected.md](2026-10-24-zspan-group32-cutoff23-screen-rejected.md) | 0 | D_DrawZSpans 32-pixel group with cutoff 23 (2026-10-24) |
| [2026-10-24-zspan-group32-cutoff21-screen-rejected.md](2026-10-24-zspan-group32-cutoff21-screen-rejected.md) | 0 | D_DrawZSpans 32-pixel group with cutoff 21 (2026-10-24) |
| [2026-10-24-zspan-group32-cutoff20-screen-rejected.md](2026-10-24-zspan-group32-cutoff20-screen-rejected.md) | 0 | D_DrawZSpans 32-pixel group with cutoff 20 (2026-10-24) |
| [2026-10-24-zspan-endpoint-retain-edx-promoted.md](2026-10-24-zspan-endpoint-retain-edx-promoted.md) | 0 | D_DrawZSpans endpoint check keeps the start depth in `%edx` (2026-10-24) |
| [2026-10-24-zspan-destination-lea-shld-gap-promoted.md](2026-10-24-zspan-destination-lea-shld-gap-promoted.md) | 0 | renderer performance / schedule the destination pointer increment between SHLD and ROR in the nonnegative i486 Z-span pair path after a positive strict mean and full i486 ISA gate |
| [2026-10-24-zspan-cutoff20-current-promoted.md](2026-10-24-zspan-cutoff20-current-promoted.md) | 0 | D_DrawZSpans nonnegative fast-path cutoff lowered to 20 (2026-10-24) |
| [2026-10-24-zspan-cutoff19-current-promoted.md](2026-10-24-zspan-cutoff19-current-promoted.md) | 0 | D_DrawZSpans nonnegative fast-path cutoff lowered to 19 (2026-10-24) |
| [2026-10-24-zspan-cutoff18-current-rejected.md](2026-10-24-zspan-cutoff18-current-rejected.md) | 0 | D_DrawZSpans nonnegative fast-path cutoff 18 recheck (2026-10-24) |
| [2026-10-24-span16-x87-t-fistp-overlap-rejected.md](2026-10-24-span16-x87-t-fistp-overlap-rejected.md) | 0 | renderer performance / reject moving Span16's T endpoint pop and integer reloads after independent pixel setup following a negative strict mean |
| [2026-10-24-span16-x87-pop-s-compute-t-promoted.md](2026-10-24-span16-x87-pop-s-compute-t-promoted.md) | 0 | renderer performance / remove the remaining x87 exchange in Span16 by popping the S endpoint before computing T, after a positive strict mean, exact checksum parity, and the complete i486 ISA gate |
| [2026-10-24-span16-tail-x87-pop-schedule.md](2026-10-24-span16-tail-x87-pop-schedule.md) | 1 | Span16 tail x87 pop schedule promoted (2026-10-24) |
| [2026-10-24-span16-tail-tfracf-reload-screen-rejected.md](2026-10-24-span16-tail-tfracf-reload-screen-rejected.md) | 1 | Span16 tail `tfracf` reload schedule rejected (2026-10-24) |
| [2026-10-24-span16-tail-texel-load-before-fistp-rejected.md](2026-10-24-span16-tail-texel-load-before-fistp-rejected.md) | 0 | Span16 tail texel load before T endpoint pop rejected (2026-10-24) |
| [2026-10-24-span16-tail-cachewidth-load-hoist-rejected.md](2026-10-24-span16-tail-cachewidth-load-hoist-rejected.md) | 0 | Span16 tail cache-width load hoist rejected (2026-10-24) |
| [2026-10-24-span16-full-texel-load-before-fistp-screen-rejected.md](2026-10-24-span16-full-texel-load-before-fistp-screen-rejected.md) | 0 | Span16 full-segment texel load before T endpoint pop rejected (2026-10-24) |
| [2026-10-24-span16-fistp-stack-order-promoted.md](2026-10-24-span16-fistp-stack-order-promoted.md) | 0 | renderer performance / remove one x87 stack exchange from each full-width Span16 segment by storing endpoint T then S after a positive strict mean, exact checksum parity, and the complete i486 ISA gate |
| [2026-10-24-renderface-zero-clipflags-screen-rejected.md](2026-10-24-renderface-zero-clipflags-screen-rejected.md) | 0 | renderer performance / reject the R_RenderFace zero-clipflags shortcut after a slower matched parity screen |
| [2026-10-24-bsp-walk-solid-first-check-promoted.md](2026-10-24-bsp-walk-solid-first-check-promoted.md) | 0 | renderer performance / check solid BSP nodes before loading the visibility frame after a positive strict mean and full i486 ISA gate |
| [2026-10-23-zspan-sign-flag-reuse-promoted.md](2026-10-23-zspan-sign-flag-reuse-promoted.md) | 3 | D_DrawZSpans sign-flag reuse |
| [2026-10-23-zspan-nonnegative-span-fast-path-promoted.md](2026-10-23-zspan-nonnegative-span-fast-path-promoted.md) | 3 | D_DrawZSpans nonnegative span fast path |
| [2026-10-23-zspan-nonnegative-span-cutoff24-promoted.md](2026-10-23-zspan-nonnegative-span-cutoff24-promoted.md) | 3 | D_DrawZSpans nonnegative span cutoff |
| [2026-10-23-turbulent-span-twelve-loop-release-default.md](2026-10-23-turbulent-span-twelve-loop-release-default.md) | 0 | renderer performance / promote twelve-pixel turbulent span loop to the i486 default after a positive matched three-run mean, checksum parity, and complete i486 ISA gates |
| [2026-10-23-turbulent-span-thirteen-loop-rejected.md](2026-10-23-turbulent-span-thirteen-loop-rejected.md) | 0 | renderer performance / reject the thirteen-pixel turbulent span loop after a negative matched three-run mean, with checksum parity and complete i486 ISA gates |
| [2026-10-23-turbulent-span-sixteen-loop-rejected.md](2026-10-23-turbulent-span-sixteen-loop-rejected.md) | 0 | renderer performance / reject sixteen-pixel turbulent span loop after a negative matched three-run mean, with checksum parity and complete i486 ISA gates |
| [2026-10-23-turbulent-span-quad-loop.md](2026-10-23-turbulent-span-quad-loop.md) | 2 | renderer performance / promote four-pixel turbulent span loop after a positive strict mean, checksum parity, and complete i486 ISA gate |
| [2026-10-23-turbulent-span-paired-loop.md](2026-10-23-turbulent-span-paired-loop.md) | 3 | renderer performance / promote two-pixel turbulent span loop after a positive strict mean, checksum parity, and complete i486 ISA gate |
| [2026-10-23-turbulent-span-octa-release-default.md](2026-10-23-turbulent-span-octa-release-default.md) | 0 | renderer performance / promote the eight-pixel turbulent span loop to the i486 default after a positive matched three-run mean, checksum parity, and complete i486 ISA gate |
| [2026-10-23-turbulent-span-octa-loop.md](2026-10-23-turbulent-span-octa-loop.md) | 2 | renderer performance / promote an opt-in eight-pixel turbulent span loop after a positive strict mean, checksum parity, and complete i486 ISA gate |
| [2026-10-23-turbulent-span-fourteen-loop-release-default.md](2026-10-23-turbulent-span-fourteen-loop-release-default.md) | 0 | renderer performance / promote fourteen-pixel turbulent span loop to the i486 default after a positive matched three-run mean, checksum parity, and complete i486 ISA gates |
| [2026-10-23-turbulent-span-fifteen-loop-rejected.md](2026-10-23-turbulent-span-fifteen-loop-rejected.md) | 0 | renderer performance / reject the fifteen-pixel turbulent span loop after a negative matched three-run mean, with checksum parity and complete i486 ISA gates |
| [2026-10-23-sprite-clip-integer-distance-tests-promoted.md](2026-10-23-sprite-clip-integer-distance-tests-promoted.md) | 0 | renderer performance / replace repeated sprite distance x87 comparisons with IEEE single-precision integer predicates after a positive matched three-run mean, checksum parity, and complete ISA audits |
| [2026-10-23-span16-segment-alignment-rejected.md](2026-10-23-span16-segment-alignment-rejected.md) | 0 | Reject sixteen-byte alignment of the Span16 segment loop (2026-10-23) |
| [2026-10-23-lightmap-fullbright-mask-promoted.md](2026-10-23-lightmap-fullbright-mask-promoted.md) | 0 | renderer performance / promote immediate-mask float truth testing in the i486 lightmap builder after a positive matched three-run mean, checksum parity, and complete ISA audits |
| [2026-10-23-lightmap-fullbright-integer-truth-promoted.md](2026-10-23-lightmap-fullbright-integer-truth-promoted.md) | 0 | renderer performance / promote an i486 integer truth test for lightmap `r_fullbright` after a positive matched three-run mean, checksum parity, and complete ISA audits |
| [2026-10-23-bsp-walk-double-distance-integer-test-promoted.md](2026-10-23-bsp-walk-double-distance-integer-test-promoted.md) | 0 | renderer performance / classify the stored BSP plane dot with exact IEEE-754 binary64 integer checks after a positive matched three-run mean, checksum parity, and complete ISA audits |
| [2026-10-23-bmodel-clip-integer-distance-test-promoted.md](2026-10-23-bmodel-clip-integer-distance-test-promoted.md) | 0 | renderer performance / replace two x87 strict-positive tests with IEEE single-precision integer range checks in brush polygon clipping after a positive matched three-run mean, checksum parity, and complete ISA audits |
| [2026-10-23-alias-transform-u16-coordinate-table-promoted.md](2026-10-23-alias-transform-u16-coordinate-table-promoted.md) | 0 | Promote 16-bit indexed coordinate loads in the i486 alias transform |
| [2026-10-23-alias-transform-t-store-after-fdivrs-promoted.md](2026-10-23-alias-transform-t-store-after-fdivrs-promoted.md) | 0 | renderer performance / move the alias T-coordinate copy after reciprocal division so it overlaps x87 work after a positive matched mean, exact checksum parity, and complete i486 ISA gates |
| [2026-10-23-alias-transform-pointer-advance-promoted.md](2026-10-23-alias-transform-pointer-advance-promoted.md) | 0 | renderer performance / move alias transform source-pointer increments after their final reads following a positive matched mean, exact checksum parity, and full i486 ISA gates |
| [2026-10-23-alias-transform-normal-index-read-hoist-promoted.md](2026-10-23-alias-transform-normal-index-read-hoist-promoted.md) | 0 | renderer performance / overlap the normal-index read, scaling, and vertex-pointer advance with alias transform arithmetic after a positive matched mean, exact checksum parity, and complete i486 ISA gates |
| [2026-10-23-alias-transform-normal-index-hoist-promoted.md](2026-10-23-alias-transform-normal-index-hoist-promoted.md) | 0 | Promote early light-normal index scaling in the i486 alias transform |
| [2026-10-23-alias-transform-integer-coordinate-table-promoted.md](2026-10-23-alias-transform-integer-coordinate-table-promoted.md) | 0 | Promote indexed integer coordinate loads in the i486 alias transform |
| [2026-10-22-zspan-u-load-before-origin-add-rejected.md](2026-10-22-zspan-u-load-before-origin-add-rejected.md) | 0 | renderer performance / reject moving the Z-span U load before the origin add after a negative strict mean |
| [2026-10-22-zspan-step-before-sign-branch-rejected.md](2026-10-22-zspan-step-before-sign-branch-rejected.md) | 0 | renderer performance / reject advancing Z-span accumulators before the sign branch after a negative strict mean |
| [2026-10-22-span16-tstep-store9-overlap-rejected.md](2026-10-22-span16-tstep-store9-overlap-rejected.md) | 0 | renderer performance / reject moving the Span16 T-step addition before store 9 after a negative strict mean |
| [2026-10-22-span16-tstep-store5-overlap-rejected.md](2026-10-22-span16-tstep-store5-overlap-rejected.md) | 0 | renderer performance / reject moving the Span16 T-step addition before store 5 after a negative strict mean |
| [2026-10-22-span16-tstep-store3-overlap-rejected.md](2026-10-22-span16-tstep-store3-overlap-rejected.md) | 0 | renderer performance / reject moving the Span16 T-step addition before store 3 after a negative strict mean |
| [2026-10-22-span16-tstep-store11-overlap-rejected.md](2026-10-22-span16-tstep-store11-overlap-rejected.md) | 0 | renderer performance / reject moving the Span16 T-step addition before B-half store 11 after a negative strict mean |
| [2026-10-22-span16-tstep-b-half-overlap-rejected.md](2026-10-22-span16-tstep-b-half-overlap-rejected.md) | 0 | renderer performance / reject moving Span16 T-step additions before B-half stores 9, 11, and 13 after a negative strict mean |
| [2026-10-22-span16-sadjust-x87-overlap-rejected.md](2026-10-22-span16-sadjust-x87-overlap-rejected.md) | 0 | renderer performance / reject moving the Span16 S-adjust load into x87 endpoint math after a negative strict mean |
| [2026-10-22-span16-fistp-reload-interleave-rejected.md](2026-10-22-span16-fistp-reload-interleave-rejected.md) | 0 | renderer performance / reject delaying the Span16 endpoint integer reloads after a negative strict mean |
| [2026-10-22-span16-first-texel-x87-overlap-rejected.md](2026-10-22-span16-first-texel-x87-overlap-rejected.md) | 0 | renderer performance / reject moving the first Span16 texel load into x87 endpoint math after a negative strict mean |
| [2026-10-22-span16-counttemp-x87-overlap-rejected.md](2026-10-22-span16-counttemp-x87-overlap-rejected.md) | 0 | renderer performance / reject overlapping the Span16 count update with x87 endpoint math after a negative strict mean |
| [2026-10-22-scan-edges-surface-base-cache-promoted.md](2026-10-22-scan-edges-surface-base-cache-promoted.md) | 1 | renderer performance / promote the scan surface-base cache after a positive strict mean |
| [2026-10-22-scan-edges-maxspan-local-cache-rejected.md](2026-10-22-scan-edges-maxspan-local-cache-rejected.md) | 1 | renderer performance / reject the local max-span limit after a negative strict mean |
| [2026-10-22-scan-edges-clear-span14-zero-register-rejected.md](2026-10-22-scan-edges-clear-span14-zero-register-rejected.md) | 1 | renderer performance / reject reusing ECX zero for fourteen scan-edge clear stores after a negative strict mean |
| [2026-10-22-scan-edges-clear-span14-alignment-rejected.md](2026-10-22-scan-edges-clear-span14-alignment-rejected.md) | 0 | renderer performance / reject sixteen-byte alignment of the fourteen-span scan-edge clear loop after a negative strict mean |
| [2026-10-22-scan-edges-clear-span-unroll8-promoted.md](2026-10-22-scan-edges-clear-span-unroll8-promoted.md) | 1 | renderer performance / promote eight-span unrolling in scan-edge span clearing after a positive strict mean |
| [2026-10-22-scan-edges-clear-span-unroll8-group-tail-promoted.md](2026-10-22-scan-edges-clear-span-unroll8-group-tail-promoted.md) | 1 | renderer performance / promote grouped 4/2/1 tail after a positive strict mean |
| [2026-10-22-scan-edges-clear-span-unroll4-promoted.md](2026-10-22-scan-edges-clear-span-unroll4-promoted.md) | 1 | renderer performance / promote four-span unrolling in scan-edge span clearing after a positive strict mean |
| [2026-10-22-scan-edges-clear-span-unroll2-promoted.md](2026-10-22-scan-edges-clear-span-unroll2-promoted.md) | 1 | renderer performance / promote two-span unrolling in scan-edge span clearing after a positive strict mean |
| [2026-10-22-scan-edges-clear-span-unroll16-rejected.md](2026-10-22-scan-edges-clear-span-unroll16-rejected.md) | 1 | renderer performance / reject sixteen-span unrolling after a negative strict mean |
| [2026-10-22-scan-edges-clear-span-unroll15-rejected.md](2026-10-22-scan-edges-clear-span-unroll15-rejected.md) | 1 | renderer performance / reject fifteen-span batches with grouped 8/4/2/1 tail after a negative strict mean |
| [2026-10-22-scan-edges-clear-span-unroll14-group-tail-promoted.md](2026-10-22-scan-edges-clear-span-unroll14-group-tail-promoted.md) | 1 | renderer performance / promote fourteen-span batches with grouped 8/4/2/1 tail after a positive strict mean |
| [2026-10-22-scan-edges-clear-span-unroll13-group-tail-rejected.md](2026-10-22-scan-edges-clear-span-unroll13-group-tail-rejected.md) | 1 | renderer performance / reject thirteen-span batches with grouped 8/4/2/1 tail after a negative strict mean |
| [2026-10-22-scan-edges-clear-span-unroll12-group-tail-promoted.md](2026-10-22-scan-edges-clear-span-unroll12-group-tail-promoted.md) | 1 | renderer performance / promote twelve-span batches with grouped 8/4/2/1 tail after a positive strict mean |
| [2026-10-22-scan-edges-clear-span-bottom-tested-promoted.md](2026-10-22-scan-edges-clear-span-bottom-tested-promoted.md) | 1 | renderer performance / promote the bottom-tested scan-edge span-clear loop after a positive strict mean |
| [2026-10-22-scan-edges-callback-cache-promoted.md](2026-10-22-scan-edges-callback-cache-promoted.md) | 1 | renderer performance / promote the scanline callback cache after a positive strict mean |
| [2026-10-22-renderface-sahf-nearzi-rejected.md](2026-10-22-renderface-sahf-nearzi-rejected.md) | 0 | renderer performance / reject the RenderFace `SAHF/JNA` nearzi check after a negative strict mean |
| [2026-10-22-renderface-assembly-promoted.md](2026-10-22-renderface-assembly-promoted.md) | 2 | renderer performance / promote `R_RenderFace` assembly for i486 after a positive strict mean |
| [2026-10-22-edge-step-third-successor-prefetch-rejected.md](2026-10-22-edge-step-third-successor-prefetch-rejected.md) | 1 | renderer performance / reject preloading the third edge-step successor after a negative strict mean |
| [2026-10-22-edge-step-successor-prefetch-rejected.md](2026-10-22-edge-step-successor-prefetch-rejected.md) | 1 | renderer performance / reject preloading the first edge-step successor after a negative strict mean |
| [2026-10-22-edge-step-second-successor-prefetch-rejected.md](2026-10-22-edge-step-second-successor-prefetch-rejected.md) | 1 | renderer performance / reject preloading the second edge-step successor after a negative strict mean |
| [2026-10-22-edge-step-fourth-successor-load-early-rejected.md](2026-10-22-edge-step-fourth-successor-load-early-rejected.md) | 1 | renderer performance / reject moving the fourth edge-step successor load before the U calculation after a negative strict mean |
| [2026-10-22-edge-step-fourth-successor-load-between-u-add-rejected.md](2026-10-22-edge-step-fourth-successor-load-between-u-add-rejected.md) | 1 | renderer performance / reject moving the fourth edge-step successor load between the U fetch and add after a negative strict mean |
| [2026-10-22-edge-step-fourth-successor-load-after-store-rejected.md](2026-10-22-edge-step-fourth-successor-load-after-store-rejected.md) | 1 | renderer performance / reject moving the fourth edge-step successor load after the U store after a negative strict mean |
| [2026-10-22-edge-step-fourth-successor-load-after-compare-rejected.md](2026-10-22-edge-step-fourth-successor-load-after-compare-rejected.md) | 1 | renderer performance / reject moving the fourth edge-step successor load between the compare and branch after a negative strict mean |
| [2026-10-22-edge-list-target-u-cache-promoted.md](2026-10-22-edge-list-target-u-cache-promoted.md) | 0 | renderer performance / promote edge-list target-U load caching after a positive strict mean |
| [2026-10-22-edge-list-legacy-default-promoted.md](2026-10-22-edge-list-legacy-default-promoted.md) | 0 | renderer performance / retain legacy edge-list assembly as the i486 default after a positive matched mean |
| [2026-10-22-edge-insert-probe4-earlyout-rejected.md](2026-10-22-edge-insert-probe4-earlyout-rejected.md) | 1 | renderer performance / reject the fourth-probe early-out after a negative strict mean |
| [2026-10-22-edge-drawing-final-scan-test-rejected.md](2026-10-22-edge-drawing-final-scan-test-rejected.md) | 1 | renderer performance / reject removing the edge final-scan test after a negative strict mean |
| [2026-10-22-edge-drawing-dspeeds-integer-truth-promoted.md](2026-10-22-edge-drawing-dspeeds-integer-truth-promoted.md) | 1 | renderer performance / promote the integer `r_dspeeds` truth check after a positive strict mean |
| [2026-10-22-edge-drawing-dspeeds-cache-promoted.md](2026-10-22-edge-drawing-dspeeds-cache-promoted.md) | 1 | renderer performance / promote caching the edge-drawing `r_dspeeds` truth value after a positive strict mean |
| [2026-10-21-zspan-store-pointer-preincrement-screen-rejected.md](2026-10-21-zspan-store-pointer-preincrement-screen-rejected.md) | 0 | renderer performance / reject Z-span destination-pointer preincrement before packed stores |
| [2026-10-21-zspan-step-between-shld-ror-screen-rejected.md](2026-10-21-zspan-step-between-shld-ror-screen-rejected.md) | 0 | Z-span second step between SHLD and ROR rejected (2026-10-21) |
| [2026-10-21-zspan-step-before-store-promoted.md](2026-10-21-zspan-step-before-store-promoted.md) | 0 | renderer performance / promote the D_DrawZSpans accumulator schedule before packed stores |
| [2026-10-21-zspan-sign-check-before-copy-screen-rejected.md](2026-10-21-zspan-sign-check-before-copy-screen-rejected.md) | 0 | renderer performance / reject the Z-span sign-check reorder after a negative strict mean |
| [2026-10-21-zspan-extract-before-step-screen-rejected.md](2026-10-21-zspan-extract-before-step-screen-rejected.md) | 0 | renderer performance / reject moving Z-span high-word extraction before the accumulator step |
| [2026-10-21-texture-span-stosw-rejected.md](2026-10-21-texture-span-stosw-rejected.md) | 0 | renderer performance / reject `stosw` stores in the full texture span loop |
| [2026-10-21-texture-span-loadfirst-early-store-rejected.md](2026-10-21-texture-span-loadfirst-early-store-rejected.md) | 0 | renderer performance / reject the load-first plus early-store combination on a negative mean |
| [2026-10-21-texture-span-early-store-rejected.md](2026-10-21-texture-span-early-store-rejected.md) | 0 | historical renderer performance decision, superseded by positive-mean promotion |
| [2026-10-21-texture-span-early-store-promoted.md](2026-10-21-texture-span-early-store-promoted.md) | 0 | renderer performance / promote the positive-mean early packed-store schedule |
| [2026-10-21-surface-cache-hit-texture-preload-rejected.md](2026-10-21-surface-cache-hit-texture-preload-rejected.md) | 0 | renderer performance / reject texture preload before the surface-cache dlight check |
| [2026-10-21-surface-cache-hit-texture-check-first-rejected.md](2026-10-21-surface-cache-hit-texture-check-first-rejected.md) | 0 | renderer performance / reject texture comparison before the surface-cache dlight check |
| [2026-10-21-surface-cache-hit-single-style-fallthrough-rejected.md](2026-10-21-surface-cache-hit-single-style-fallthrough-rejected.md) | 0 | renderer performance / reject single-style fall-through in the surface-cache hit path |
| [2026-10-21-surface-cache-hit-load-gap-rejected.md](2026-10-21-surface-cache-hit-load-gap-rejected.md) | 0 | renderer performance / reject the tied surface-cache hit load-gap schedule |
| [2026-10-21-surface-cache-hit-key-pointer-retained-promoted.md](2026-10-21-surface-cache-hit-key-pointer-retained-promoted.md) | 0 | renderer performance / promote retaining the light-style pointer in the surface-cache hit path |
| [2026-10-21-surf8-mip2-texel-read-order-screen-rejected.md](2026-10-21-surf8-mip2-texel-read-order-screen-rejected.md) | 0 | renderer performance / reject swapping mip-2 source-texel reads after a negative parity screen |
| [2026-10-21-surf8-mip2-texel-loads-promoted.md](2026-10-21-surf8-mip2-texel-loads-promoted.md) | 0 | renderer performance / promote early mip-2 source-texel loads |
| [2026-10-21-surf8-mip2-rowstate-reload-rejected.md](2026-10-21-surf8-mip2-rowstate-reload-rejected.md) | 0 | renderer performance / reject the mip-2 row-state reload schedule on a negative strict mean |
| [2026-10-21-surf8-mip2-lightdelta-prefetch-rejected.md](2026-10-21-surf8-mip2-lightdelta-prefetch-rejected.md) | 0 | renderer performance / reject prefetching the mip-2 light-delta reload on a negative strict mean |
| [2026-10-21-surf8-mip2-horizontal-flat-rejected.md](2026-10-21-surf8-mip2-horizontal-flat-rejected.md) | 0 | renderer performance / reject the parity-clean mip-2 horizontal-flat fast path on a negative strict mean |
| [2026-10-21-span16-tstep-store-after-add-promoted.md](2026-10-21-span16-tstep-store-after-add-promoted.md) | 0 | renderer performance / promote moving the Span16 `tstep` store after the T-fraction add |
| [2026-10-21-span16-tstep-overlap-extension-rejected.md](2026-10-21-span16-tstep-overlap-extension-rejected.md) | 0 | renderer performance / reject extending the Span16 T-step/store overlap after a negative strict mean |
| [2026-10-21-span16-tstep-before-word-store-promoted.md](2026-10-21-span16-tstep-before-word-store-promoted.md) | 0 | renderer performance / promote placing the next Span16 T-step addition before the word store after a positive strict mean |
| [2026-10-21-span16-tstep-a-half-overlap-rejected.md](2026-10-21-span16-tstep-a-half-overlap-rejected.md) | 0 | renderer performance / reject moving Span16 T-step additions before A-half stores 3 and 5 after a negative strict mean |
| [2026-10-21-span16-tcarry-after-fetch-promoted.md](2026-10-21-span16-tcarry-after-fetch-promoted.md) | 2 | renderer performance / promote extracting the Span16 T carry after the low-byte source fetch under the positive-mean rule |
| [2026-10-21-span16-tcarry-after-all-fetches-screen-rejected.md](2026-10-21-span16-tcarry-after-all-fetches-screen-rejected.md) | 0 | renderer performance / reject extending the Span16 T-carry deferral to high-byte source fetches after a negative parity screen |
| [2026-10-21-span16-store-before-sfracf-screen-rejected.md](2026-10-21-span16-store-before-sfracf-screen-rejected.md) | 0 | renderer performance / reject moving the Span16 common store ahead of the `sfracf` reload after a negative parity screen |
| [2026-10-21-span16-store-after-tstep-shift-promoted.md](2026-10-21-span16-store-after-tstep-shift-promoted.md) | 3 | renderer performance / promote the positive-mean post-shift D_DrawSpans16 setup-store schedule |
| [2026-10-21-span16-store-after-adc-promoted.md](2026-10-21-span16-store-after-adc-promoted.md) | 2 | renderer performance / promote Span16 packed stores after the final address ADC under the positive-mean rule |
| [2026-10-21-span16-sstep-shift-after-tstep-shift-promoted.md](2026-10-21-span16-sstep-shift-after-tstep-shift-promoted.md) | 0 | renderer performance / promote the positive strict-mean Span16 S-step shift schedule |
| [2026-10-21-span16-sstep-shift-after-tcarry-rejected.md](2026-10-21-span16-sstep-shift-after-tcarry-rejected.md) | 0 | renderer performance / reject deferring the Span16 S-step shift after a negative strict mean |
| [2026-10-21-span16-sstep-shift-after-advancetable-screen-rejected.md](2026-10-21-span16-sstep-shift-after-advancetable-screen-rejected.md) | 0 | renderer performance / reject delaying the Span16 S-step shift until after the `advancetable` store |
| [2026-10-21-span16-sfracf-before-sstep-shift-screen-rejected.md](2026-10-21-span16-sfracf-before-sstep-shift-screen-rejected.md) | 0 | renderer performance / reject moving the Span16 `sfracf` reload ahead of the S-step shift after a negative parity screen |
| [2026-10-21-span16-sfracf-after-tstep-shift-screen-rejected.md](2026-10-21-span16-sfracf-after-tstep-shift-screen-rejected.md) | 0 | renderer performance / reject moving the Span16 `sfracf` reload after the T-step shift |
| [2026-10-21-span16-sfracf-after-both-shifts-screen-rejected.md](2026-10-21-span16-sfracf-after-both-shifts-screen-rejected.md) | 0 | renderer performance / reject moving the Span16 `sfracf` reload after both fractional shifts |
| [2026-10-21-span16-s-first-store-t-shift-screen-rejected.md](2026-10-21-span16-s-first-store-t-shift-screen-rejected.md) | 0 | renderer performance / reject the S-first, store, T-shift Span16 setup permutation |
| [2026-10-21-span16-s-add-before-first-high-fetch-promoted.md](2026-10-21-span16-s-add-before-first-high-fetch-promoted.md) | 0 | renderer performance / promote the Span16 S-fraction add before the first A-half high-byte fetch after a positive strict mean |
| [2026-10-21-span16-s-add-before-fetch-screen-rejected.md](2026-10-21-span16-s-add-before-fetch-screen-rejected.md) | 0 | renderer performance / reject moving the Span16 S-fraction add ahead of the paired source-byte load after a negative parity screen |
| [2026-10-21-span16-loadfirst-current-control-rejected.md](2026-10-21-span16-loadfirst-current-control-rejected.md) | 1 | renderer performance / keep `TextureSpanLoadOrder=control` after the current-baseline `loadfirst` recheck had a negative mean |
| [2026-10-21-span16-deferred-tfracf-reload-promoted.md](2026-10-21-span16-deferred-tfracf-reload-promoted.md) | 0 | renderer performance / promote the positive-mean delayed `tfracf` reload schedule in Span16 setup |
| [2026-10-21-span16-cachewidth-load-screen-rejected.md](2026-10-21-span16-cachewidth-load-screen-rejected.md) | 0 | renderer performance / reject the D_DrawSpans16 cachewidth-load hoist after a negative parity screen |
| [2026-10-21-span16-base-store-before-tfracf-screen-rejected.md](2026-10-21-span16-base-store-before-tfracf-screen-rejected.md) | 0 | renderer performance / reject moving the Span16 base store ahead of the `tfracf` reload after a negative paired screen |
| [2026-10-21-span16-advancetable-store-hoist-promoted.md](2026-10-21-span16-advancetable-store-hoist-promoted.md) | 0 | renderer performance / earlier positive-mean D_DrawSpans16 setup-store schedule, superseded by post-shift placement |
| [2026-10-21-span16-advancetable-store-after-tfrac-add-screen-rejected.md](2026-10-21-span16-advancetable-store-after-tfrac-add-screen-rejected.md) | 0 | renderer performance / reject moving the Span16 `advancetable` store after the T-fraction add |
| [2026-10-21-span16-advancetable-store-after-sfracf-screen-rejected.md](2026-10-21-span16-advancetable-store-after-sfracf-screen-rejected.md) | 0 | renderer performance / reject moving the Span16 `advancetable` store ahead of both shifts after the `sfracf` load |
| [2026-10-21-renderface-positive-edge-branch-layout.md](2026-10-21-renderface-positive-edge-branch-layout.md) | 0 | renderer performance / promote the RenderFace positive-edge branch layout |
| [2026-10-21-renderface-nonnegative-edge-branch-screen-rejected.md](2026-10-21-renderface-nonnegative-edge-branch-screen-rejected.md) | 0 | renderer performance / reject routing zero surfedges through the positive edge address path |
| [2026-10-21-edge-scan-surface-index-decode-promoted.md](2026-10-21-edge-scan-surface-index-decode-promoted.md) | 1 | renderer performance / promote direct 16-bit edge surface-index decoding after a positive strict mean |
| [2026-10-21-edge-scan-surface-base-cache-screen-rejected.md](2026-10-21-edge-scan-surface-base-cache-screen-rejected.md) | 0 | renderer performance / reject caching the edge-scan `surfaces` base after a negative strict pooled mean |
| [2026-10-21-edge-scan-span-reset-before-x87-screen-rejected.md](2026-10-21-edge-scan-span-reset-before-x87-screen-rejected.md) | 0 | renderer performance / reject moving the edge-scan span reset ahead of row x87 setup |
| [2026-10-21-edge-scan-newedges-load-hoist-screen-rejected.md](2026-10-21-edge-scan-newedges-load-hoist-screen-rejected.md) | 0 | renderer performance / reject preloading the edge-scan newedges pointer |
| [2026-10-21-edge-scan-leading-pointer-retained-promoted.md](2026-10-21-edge-scan-leading-pointer-retained-promoted.md) | 0 | renderer performance / promote retaining the leading-surface pointer across `TrailingEdge` after a positive strict mean |
| [2026-10-21-edge-scan-bottom-tested-row-loop-promoted.md](2026-10-21-edge-scan-bottom-tested-row-loop-promoted.md) | 0 | renderer performance / promote the edge-scan bottom-tested row loop after a positive strict mean |
| [2026-10-21-alias-raster-prelookup-depth-store-promoted.md](2026-10-21-alias-raster-prelookup-depth-store-promoted.md) | 1 | renderer performance / historical promotion, current-source strict recheck rejects pre-lookup alias Z-store scheduling |
| [2026-10-21-alias-raster-depth-store-reorder.md](2026-10-21-alias-raster-depth-store-reorder.md) | 0 | renderer performance / promote alias-raster Z-store scheduling |
| [2026-10-21-alias-depth-store-before-texel-screen-rejected.md](2026-10-21-alias-depth-store-before-texel-screen-rejected.md) | 0 | renderer performance / reject moving the alias Z store ahead of the texture load after a negative parity screen |
| [2026-10-21-alias-depth-store-after-light-screen-rejected.md](2026-10-21-alias-depth-store-after-light-screen-rejected.md) | 0 | renderer performance / reject moving the alias Z store after the light-byte load after a negative parity screen |
| [2026-10-20-zspan-middle-unroll32-rejected.md](2026-10-20-zspan-middle-unroll32-rejected.md) | 0 | renderer performance / reject the 32-pixel D_DrawZSpans main-loop group |
| [2026-10-20-zspan-middle-unroll16.md](2026-10-20-zspan-middle-unroll16.md) | 1 | renderer performance / promote the D_DrawZSpans 16-pixel middle-loop unroll |
| [2026-10-20-texture-span-tail-word-rejected.md](2026-10-20-texture-span-tail-word-rejected.md) | 0 | renderer performance / reject word stores for the final short texture span |
| [2026-10-20-texture-span-loadfirst-recheck.md](2026-10-20-texture-span-loadfirst-recheck.md) | 0 | renderer performance / texture-span load-first schedule recheck |
| [2026-10-20-texture-span-dword-recheck.md](2026-10-20-texture-span-dword-recheck.md) | 0 | renderer performance / texture-span dword-store recheck |
| [2026-10-20-renderface-triangle-quad-unroll-rejected.md](2026-10-20-renderface-triangle-quad-unroll-rejected.md) | 0 | renderer performance / reject the RenderFace triangle/quad edge unroll |
| [2026-10-20-renderface-owner-compare-fusion.md](2026-10-20-renderface-owner-compare-fusion.md) | 0 | renderer performance / fuse the RenderFace cache-owner compare and reuse the edge offset |
| [2026-10-20-renderface-offset-load-hoist-rejected.md](2026-10-20-renderface-offset-load-hoist-rejected.md) | 0 | renderer performance / reject preloading the RenderFace cached edge offset |
| [2026-10-20-renderface-cacheoffset-reuse.md](2026-10-20-renderface-cacheoffset-reuse.md) | 0 | renderer performance / reuse the RenderFace cache offset on the bounds-miss path |
| [2026-10-20-renderface-branchless-surfedge-rejected.md](2026-10-20-renderface-branchless-surfedge-rejected.md) | 0 | renderer performance / reject branchless absolute-value handling of signed surfedges |
| [2026-10-20-mip3-flat-block-rejected.md](2026-10-20-mip3-flat-block-rejected.md) | 2 | renderer performance / mip-3 horizontal-flat assembly block rejection |
| [2026-10-20-cache-key-fusion.md](2026-10-20-cache-key-fusion.md) | 1 | renderer performance / assembly cache-key setup and comparison fusion |
| [2026-10-20-cache-hit-key-store-deferral.md](2026-10-20-cache-hit-key-store-deferral.md) | 1 | renderer performance / defer surface-cache draw-key stores on hits |
| [2026-10-19-video-mode-menu-assembly-port.md](2026-10-19-video-mode-menu-assembly-port.md) | 4 | renderer port / DOS video-mode menu list and callback renderer (`Video mode menu behavior and selector`; `Direct C/ASM parity matrix`; `Strict i486 release audit and current ownership`; `Remaining video-menu port scope`) |
| [2026-10-19-video-mode-assembly-port.md](2026-10-19-video-mode-assembly-port.md) | 4 | renderer port / DOS video mode, palette, and shutdown orchestration (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-vesa-wait-assembly-port.md](2026-10-19-vesa-wait-assembly-port.md) | 4 | renderer port / VESA wait gates and VGA status-port polling (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification`; `Ownership and remaining scope`) |
| [2026-10-19-vesa-lifecycle-assembly-port.md](2026-10-19-vesa-lifecycle-assembly-port.md) | 4 | renderer port / VESA resource cleanup and palette-ready state (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-vesa-default-mode-wrapper-assembly-port.md](2026-10-19-vesa-default-mode-wrapper-assembly-port.md) | 4 | renderer port / exported VESA default-mode wrapper (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-setup-menu-assembly-port.md](2026-10-19-setup-menu-assembly-port.md) | 4 | renderer port / player setup menu drawing (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-server-list-menu-assembly-port.md](2026-10-19-server-list-menu-assembly-port.md) | 4 | renderer port / server-list menu drawing and host-cache sorting (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-serial-config-menu-assembly-port.md](2026-10-19-serial-config-menu-assembly-port.md) | 4 | Serial configuration menu moves to i486 assembly (2026-10-19) |
| [2026-10-19-screen-pause-loading-assembly-port.md](2026-10-19-screen-pause-loading-assembly-port.md) | 4 | renderer port / pause and loading overlay composition (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification`; `Scope and remaining work`) |
| [2026-10-19-sbar-solo-scoreboard-assembly-port.md](2026-10-19-sbar-solo-scoreboard-assembly-port.md) | 3 | Classic solo scoreboard assembly port |
| [2026-10-19-sbar-changed-assembly-port.md](2026-10-19-sbar-changed-assembly-port.md) | 3 | Status-bar refresh state setter i486 assembly port (2026-10-19) |
| [2026-10-19-quit-menu-assembly-port.md](2026-10-19-quit-menu-assembly-port.md) | 4 | Quit dialog drawing moves to i486 assembly (2026-10-19) |
| [2026-10-19-options-menu-assembly-port.md](2026-10-19-options-menu-assembly-port.md) | 4 | Options menu drawing moves to i486 assembly (2026-10-19) |
| [2026-10-19-net-menu-assembly-port.md](2026-10-19-net-menu-assembly-port.md) | 4 | renderer port / network protocol menu and help panel (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-multiplayer-menu-assembly-port.md](2026-10-19-multiplayer-menu-assembly-port.md) | 4 | renderer port / multiplayer menu page (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-modem-config-menu-assembly-port.md](2026-10-19-modem-config-menu-assembly-port.md) | 4 | renderer port / modem configuration menu drawing (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-menu-textbox-assembly-port.md](2026-10-19-menu-textbox-assembly-port.md) | 3 | Menu text-box assembly port |
| [2026-10-19-menu-state-entry-assembly-port.md](2026-10-19-menu-state-entry-assembly-port.md) | 4 | renderer port / LAN and server-list menu state entries (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-menu-saveload-assembly-port.md](2026-10-19-menu-saveload-assembly-port.md) | 4 | renderer port / Load and Save page drawing (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-menu-picture-wrappers-assembly-port.md](2026-10-19-menu-picture-wrappers-assembly-port.md) | 3 | Centered menu picture assembly port |
| [2026-10-19-menu-help-page-assembly-port.md](2026-10-19-menu-help-page-assembly-port.md) | 4 | renderer port / six help-page picture renderer (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-19-menu-frame-dispatch-assembly-port.md](2026-10-19-menu-frame-dispatch-assembly-port.md) | 4 | Menu frame dispatcher moves to i486 assembly (2026-10-19) |
| [2026-10-19-main-singleplayer-menu-pages-assembly-port.md](2026-10-19-main-singleplayer-menu-pages-assembly-port.md) | 4 | Main and single-player menu pages move to i486 assembly (2026-10-19) |
| [2026-10-19-keys-menu-assembly-port.md](2026-10-19-keys-menu-assembly-port.md) | 4 | Key binding menu drawing moves to i486 assembly (2026-10-19) |
| [2026-10-19-game-options-menu-assembly-port.md](2026-10-19-game-options-menu-assembly-port.md) | 4 | renderer port / multiplayer game-options menu drawing (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [2026-10-18-zone-memory-trace-assembly-port.md](2026-10-18-zone-memory-trace-assembly-port.md) | 4 | renderer port / zone, cache, and hunk diagnostic trace adapters (`Behavior and selector`; `Exact C/ASM fixture`; `Strict i486 verification`; `Scope and remaining work`) |
| [2026-10-18-vga-direct-rect-assembly-port.md](2026-10-18-vga-direct-rect-assembly-port.md) | 4 | renderer port / VGA direct-rectangle dispatch and planar/linear backup/restore (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Scope limits and reproduction`) |
| [2026-10-18-vesa-palette-assembly-port.md](2026-10-18-vesa-palette-assembly-port.md) | 4 | VESA palette conversion i486 assembly port (2026-10-18) |
| [2026-10-18-vesa-default-mode-assembly-port.md](2026-10-18-vesa-default-mode-assembly-port.md) | 4 | VESA default-mode selection i486 assembly port (2026-10-18) |
| [2026-10-18-surface-cache-lifecycle-assembly-port.md](2026-10-18-surface-cache-lifecycle-assembly-port.md) | 4 | renderer port / surface-cache sizing, initialization, and flush (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Scope limits and reproduction`) |
| [2026-10-18-scr-drawconsole-assembly-port.md](2026-10-18-scr-drawconsole-assembly-port.md) | 4 | renderer port / per-frame screen console dispatch (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 build and execution`; `Traceability and remaining scope`) |
| [2026-10-18-scr-check-draw-center-string-assembly-port.md](2026-10-18-scr-check-draw-center-string-assembly-port.md) | 4 | `SCR_CheckDrawCenterString` i486 assembly port (2026-10-18) |
| [2026-10-18-sbar-mini-deathmatch-assembly-port.md](2026-10-18-sbar-mini-deathmatch-assembly-port.md) | 4 | renderer port / widescreen mini-deathmatch scoreboard (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 gate and current ownership`; `Traceability and remaining scope`) |
| [2026-10-18-sbar-intermission-assembly-port.md](2026-10-18-sbar-intermission-assembly-port.md) | 4 | renderer port / normal intermission overlay and number formatting (`Behavior and selector`; `Exact C/ASM parity`; `Strict i486 verification`; `Scope and remaining work`) |
| [2026-10-18-sbar-finale-assembly-port.md](2026-10-18-sbar-finale-assembly-port.md) | 4 | renderer port / finale overlay composition (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Scope and remaining work`) |
| [2026-10-18-sbar-deathmatch-assembly-port.md](2026-10-18-sbar-deathmatch-assembly-port.md) | 4 | renderer port / full intermission deathmatch scoreboard (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Traceability and remaining scope`) |
| [2026-10-18-player-translation-assembly-port.md](2026-10-18-player-translation-assembly-port.md) | 4 | renderer port / player-color table generation and translation (`Scope and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Scope limits and reproduction`) |
| [2026-10-18-console-resize-assembly-port.md](2026-10-18-console-resize-assembly-port.md) | 4 | renderer port / console scrollback resize and reflow (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 build and execution`; `Traceability and remaining scope`) |
| [2026-10-18-console-print-assembly-port.md](2026-10-18-console-print-assembly-port.md) | 4 | renderer port / console scrollback insertion and linefeed (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification and current ownership`; `Traceability and remaining scope`) |
| [2026-10-17-zone-heap-assembly-port.md](2026-10-17-zone-heap-assembly-port.md) | 6 | renderer port / zone initialization, tagged allocation, zero-fill allocation and free/coalescing (`Behavior and selector`; `Direct C/assembly parity`; `Initial non-BENCH release verification`; `Current strict BENCH i486 verification`; `Current non-BENCH i486 release verification`; `Ownership and remaining work`) |
| [2026-10-17-vesa-swap-buffers-assembly-port.md](2026-10-17-vesa-swap-buffers-assembly-port.md) | 4 | VESA page-flip orchestration i486 assembly port (2026-10-17) |
| [2026-10-17-vesa-copy-rects-assembly-port.md](2026-10-17-vesa-copy-rects-assembly-port.md) | 4 | renderer port / VESA dirty-rectangle copy (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining scope`) |
| [2026-10-17-sbar-inventory-assembly-port.md](2026-10-17-sbar-inventory-assembly-port.md) | 4 | renderer port / status-bar inventory composition (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 build and Demo 1 run`; `Traceability and remaining scope`) |
| [2026-10-17-sbar-frags-assembly-port.md](2026-10-17-sbar-frags-assembly-port.md) | 4 | renderer port / status-bar frag strip and stable scoreboard sorter (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Traceability and remaining scope`) |
| [2026-10-17-hunk-temp-alloc-assembly-port.md](2026-10-17-hunk-temp-alloc-assembly-port.md) | 4 | renderer port / temporary high-hunk allocation (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [2026-10-17-hunk-named-alloc-assembly-port.md](2026-10-17-hunk-named-alloc-assembly-port.md) | 4 | renderer port / named low and high hunk allocation (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification`; `Ownership and remaining work`) |
| [2026-10-17-hunk-mark-release-assembly-port.md](2026-10-17-hunk-mark-release-assembly-port.md) | 4 | renderer port / low and high hunk mark release (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [2026-10-17-hunk-high-mark-assembly-port.md](2026-10-17-hunk-high-mark-assembly-port.md) | 4 | renderer port / high-hunk mark query and temporary unwind (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Cache and memory scope remaining`) |
| [2026-10-17-con-drawnotify-assembly-port.md](2026-10-17-con-drawnotify-assembly-port.md) | 4 | `Con_DrawNotify` i486 assembly port (2026-10-17) |
| [2026-10-17-con-drawconsole-assembly-port.md](2026-10-17-con-drawconsole-assembly-port.md) | 4 | renderer port / console composition (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 build and execution`; `Traceability and remaining scope`) |
| [2026-10-17-cache-move-assembly-port.md](2026-10-17-cache-move-assembly-port.md) | 4 | renderer port / cache block relocation (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [2026-10-17-cache-free-low-assembly-port.md](2026-10-17-cache-free-low-assembly-port.md) | 4 | renderer port / low-end hunk cache reclamation (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [2026-10-17-cache-free-high-assembly-port.md](2026-10-17-cache-free-high-assembly-port.md) | 4 | renderer port / high-end hunk cache reclamation (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [2026-10-17-cache-free-assembly-port.md](2026-10-17-cache-free-assembly-port.md) | 4 | renderer port / cache block removal and address/LRU unlink (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [2026-10-17-cache-check-assembly-port.md](2026-10-17-cache-check-assembly-port.md) | 4 | renderer port / cache lookup and LRU promotion (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [2026-10-17-cache-allocation-search-assembly-port.md](2026-10-17-cache-allocation-search-assembly-port.md) | 4 | renderer port / cache allocation search (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [2026-10-17-cache-alloc-assembly-port.md](2026-10-17-cache-alloc-assembly-port.md) | 4 | renderer port / cache allocation and LRU eviction (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [2026-10-16-sbar-draw-assembly-port.md](2026-10-16-sbar-draw-assembly-port.md) | 5 | Status-bar dispatcher i486 assembly slice (2026-10-16) |
| [2026-10-16-model-load-assembly-port.md](2026-10-16-model-load-assembly-port.md) | 4 | `Mod_LoadModel` i486 assembly port (2026-10-16) |
| [2026-10-16-find-touched-leafs-assembly-port.md](2026-10-16-find-touched-leafs-assembly-port.md) | 5 | renderer port / 3D entity-to-BSP-leaf traversal (`Function and selector`; `ABI and recursive behavior`; `Exact C/ASM parity`; `Strict i486 gates`; `Reproduction and limits`) |
| [2026-10-16-entity-hull-selection-assembly-port.md](2026-10-16-entity-hull-selection-assembly-port.md) | 5 | renderer port / 3D entity and BSP hull selection (`Function and selection boundary`; `Exact parity fixture`; `Strict BENCH i486 gate`; `Strict Release i486 gate`; `Reproduction`) |
| [2026-10-16-clip-to-links-assembly-port.md](2026-10-16-clip-to-links-assembly-port.md) | 5 | renderer port / 3D area-link entity clipper (`Function and selector`; `ABI and recursive behavior`; `Exact C/ASM parity`; `Strict i486 gates`; `Reproduction and limits`) |
| [2026-10-16-clip-move-to-entity-assembly-port.md](2026-10-16-clip-move-to-entity-assembly-port.md) | 5 | renderer port / 3D entity trace wrapper (`Function and selection boundary`; `Wrapper and ABI`; `Exact trace parity`; `Strict i486 gates`; `Reproduction and limits`) |
| [2026-10-16-chase-hull-check-assembly-port.md](2026-10-16-chase-hull-check-assembly-port.md) | 4 | renderer port / 3D BSP collision trace (`Function and selection boundary`; `Exact parity fixture`; `i486 executable gate`; `Reproduction`) |
| [2026-10-15-sbar-primitives-assembly-port.md](2026-10-15-sbar-primitives-assembly-port.md) | 4 | renderer port / status-bar primitives (`Reference mapping and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Remaining C ownership`) |
| [2026-10-13-timegraph-assembly-port.md](2026-10-13-timegraph-assembly-port.md) | 4 | renderer port / timing overlay (`Mapping`; `Deterministic parity`; `i486 verification`; `Reproduction instructions`) |
| [2026-10-13-screen-update-assembly-port.md](2026-10-13-screen-update-assembly-port.md) | 5 | renderer port / full screen-update orchestration (`Reference mapping and ABI`; `Direct C/assembly fixture`; `Exact paired framebuffer and ISA evidence`; `Refreshed ownership inventory and remaining C paths`; `Reproduction`) |
| [2026-10-13-screen-turtle-assembly-port.md](2026-10-13-screen-turtle-assembly-port.md) | 5 | SCR_DrawTurtle i486 assembly port |
| [2026-10-13-screen-overlays-assembly-port.md](2026-10-13-screen-overlays-assembly-port.md) | 5 | renderer port / screen update overlay dispatch (`Original branch block and selector`; `Direct C/assembly branch fixture`; `Exact paired scene and i486 audit`; `Ownership snapshot`; `Reproduction and remaining scope`) |
| [2026-10-13-screen-net-assembly-port.md](2026-10-13-screen-net-assembly-port.md) | 5 | SCR_DrawNet i486 assembly port |
| [2026-10-13-screen-drawram-assembly-port.md](2026-10-13-screen-drawram-assembly-port.md) | 4 | renderer port / RAM indicator overlay (`Mapping`; `Direct differential fixture`; `Strict i486 verification`; `Reproduction and scope`) |
| [2026-10-13-screen-calc-refdef-assembly-port.md](2026-10-13-screen-calc-refdef-assembly-port.md) | 4 | renderer port / screen view rectangle and projection setup (`Original behavior and selected assembly`; `Differential state fixture`; `Paired framebuffer parity and strict i486 audit`; `Traceability and reproduction`) |
| [2026-10-13-r-printdspeeds-assembly-port.md](2026-10-13-r-printdspeeds-assembly-port.md) | 4 | renderer port / timing diagnostics (`Original routine and selector`; `24-case console and ABI parity`; `Complete i486 build audit`; `Reproduction command and limits`) |
| [2026-10-13-alias-projection-turbulent-span-parity.md](2026-10-13-alias-projection-turbulent-span-parity.md) | 4 | renderer port / alias projection and turbulent spans (`Original-to-assembly traceability`; `Direct differential fixtures`; `Strict i486 instruction evidence`; `Reproduction and scope`) |
| [2026-10-12-screen-overlay-live-routing.md](2026-10-12-screen-overlay-live-routing.md) | 4 | renderer port / screen drawing backend routing (`Fixture hooks and production calls`; `486 fixture and ISA evidence`; `Exact scene pair`; `Reproduction`) |
| [2026-10-12-screen-console-setup-assembly-parity.md](2026-10-12-screen-console-setup-assembly-parity.md) | 3 | `SCR_SetUpToDrawConsole` -> i486+387 assembly parity (2026-10-12) |
| [2026-10-12-render-dispatch-particle-stack-alignment.md](2026-10-12-render-dispatch-particle-stack-alignment.md) | 5 | renderer port / particle call adapter (`C reference and assembly boundary`; `Call-frame contract`; `Tracked integration profile and exact parity`; `i486 instruction and runtime evidence`; `Traceability and reproduction`) |
| [2026-10-11-screen-erase-center-string-assembly-port.md](2026-10-11-screen-erase-center-string-assembly-port.md) | 4 | renderer port / centered-message erase (`Reference and selector boundary`; `x87 arithmetic and the 486DX target`; `Exact differential fixture`; `Strict executable evidence`) |
| [2026-10-11-r-parseparticleeffect-assembly-port.md](2026-10-11-r-parseparticleeffect-assembly-port.md) | 5 | renderer port / particle packet decoder (`Reference and assembly mapping`; `Direct C/assembly fixture`; `Strict 486DX+x87 executable evidence`; `Deterministic event-to-frame parity`; `Traceability and reproduction`) |
| [2026-10-10-v-parsedamage-assembly-port.md](2026-10-10-v-parsedamage-assembly-port.md) | 5 | renderer port / view damage parsing (`Damage packet behavior and assembly mapping`; `Direct damage parsing and ABI fixture`; `Paired damage-event frame parity`; `Damage parser i486 instruction evidence`; `Damage parser traceability and reproduction`) |
| [2026-10-10-v-init-assembly-port.md](2026-10-10-v-init-assembly-port.md) | 4 | `V_Init` -> i486 assembly port (2026-10-10) |
| [2026-10-10-v-cshift-assembly-port.md](2026-10-10-v-cshift-assembly-port.md) | 4 | `V_cshift_f` -> i486 assembly port (2026-10-10) |
| [2026-10-10-v-bonusflash-assembly-port.md](2026-10-10-v-bonusflash-assembly-port.md) | 5 | renderer port / view palette event (`Original command behavior and four assembly stores`; `256-pattern full-state and ABI fixture`; `Exact palette-transition differential`; `Strict i486 executable and provider evidence`; `Reference-to-assembly traceability and reproduction`) |
| [2026-10-10-screen-center-string-assembly-parity.md](2026-10-10-screen-center-string-assembly-parity.md) | 5 | renderer port / centered messages (`SCR_DrawCenterString reference and assembly boundary`; `x87 arithmetic, state and calling convention`; `18-case C/assembly differential fixture`; `Strict 486DX+x87 executable evidence`) |
| [2026-10-10-screen-calc-fov-assembly-port.md](2026-10-10-screen-calc-fov-assembly-port.md) | 6 | renderer port / view projection (`Original C behavior and selector boundary`; `Assembly mapping`; `Direct C/assembly and ABI fixture`; `i486 instruction evidence`; `Paired framebuffer evidence`; `CalcFov traceability and reproduction`) |
| [2026-10-10-scr-drawnotifystring-assembly-port.md](2026-10-10-scr-drawnotifystring-assembly-port.md) | 0 | `SCR_DrawNotifyString` -> i486 assembly port (2026-10-10) |
| [2026-10-10-render-poly-assembly-parity.md](2026-10-10-render-poly-assembly-parity.md) | 4 | renderer port / polygon projection (`Original routine and assembly behavior`; `Direct differential oracle`; `Strict i486 and paired-run evidence`; `Traceability and reproduction`) |
| [2026-10-10-r-teleportsplash-assembly-port.md](2026-10-10-r-teleportsplash-assembly-port.md) | 2 | renderer port / particles (`Port mapping and contract`; `TeleportSplash validation status`) |
| [2026-10-10-r-runparticleeffect-assembly-port.md](2026-10-10-r-runparticleeffect-assembly-port.md) | 5 | renderer port / particles (`C reference and assembly behavior`; `Selector and direct fixture`; `Paired frame parity`; `ISA evidence and remaining scope`; `RPE test commands`) |
| [2026-10-10-r-entityparticles-assembly-port.md](2026-10-10-r-entityparticles-assembly-port.md) | 5 | renderer port / entity particles (`Reference behavior and assembly mapping`; `Direct C/assembly fixture`; `Paired rendered-frame parity`; `i486 machine-code evidence`; `Traceability and reproduction`) |
| [2026-10-10-particle-update-parity-fixture.md](2026-10-10-particle-update-parity-fixture.md) | 2 | Particle update i486 parity fixture |
| [2026-10-10-efrag-store-parity-fixture.md](2026-10-10-efrag-store-parity-fixture.md) | 1 | `R_StoreEfrags` exact-state parity fixture |
| [2026-10-10-d-drawzspans-assembly-parity.md](2026-10-10-d-drawzspans-assembly-parity.md) | 5 | renderer port / depth spans (`Traceability and scope`; `Arithmetic, stores, and ABI`; `Direct differential fixture`; `Strict i486 audit`; `Reproduction and limits`) |
| [2026-10-10-d-drawparticle-assembly-port.md](2026-10-10-d-drawparticle-assembly-port.md) | 6 | renderer port / particle rasterization (`Traceability and scope`; `x87 conversion and clipping parity`; `Direct differential fixture`; `Paired scene parity`; `Strict i486 audit`; `Reproduction and limits`) |
| [2026-10-10-con-drawinput-assembly-port.md](2026-10-10-con-drawinput-assembly-port.md) | 5 | renderer port / console input overlay (`Original C behavior and ownership boundary`; `Assembly mapping and x87 behavior`; `Direct C/assembly fixture`; `ISA validation and current status`; `Traceability and remaining scope`) |
| [2026-10-09-zsubmodel-polygons-assembly-port.md](2026-10-09-zsubmodel-polygons-assembly-port.md) | 3 | renderer port / BSP |
| [2026-10-09-selectable-assembly-profile-acceptance.md](2026-10-09-selectable-assembly-profile-acceptance.md) | 3 | renderer port / combined profile |
| [2026-10-09-selectable-84-alias-control-checkpoint.md](2026-10-09-selectable-84-alias-control-checkpoint.md) | 5 | renderer port / alias-control integration |
| [2026-10-09-selectable-83-vesa-checkpoint.md](2026-10-09-selectable-83-vesa-checkpoint.md) | 5 | renderer port / 83-selector VESA checkpoint |
| [2026-10-09-selectable-77-assembly-profile-acceptance.md](2026-10-09-selectable-77-assembly-profile-acceptance.md) | 4 | renderer port / all-selector profile |
| [2026-10-09-r-transformplane-assembly-port.md](2026-10-09-r-transformplane-assembly-port.md) | 2 | renderer port / plane math |
| [2026-10-09-r-setupframe-assembly-port.md](2026-10-09-r-setupframe-assembly-port.md) | 4 | renderer port / frame setup |
| [2026-10-09-r-rockettrail-assembly-port.md](2026-10-09-r-rockettrail-assembly-port.md) | 3 | renderer port / particles (`Port and traceability`; `Reference fixture`; `Acceptance evidence`) |
| [2026-10-09-r-lavasplash-assembly-port.md](2026-10-09-r-lavasplash-assembly-port.md) | 3 | renderer port / particles (`Scope and traceability`; `Correctness fixture`; `LavaSplash validation status`) |
| [2026-10-09-r-check-variables-assembly-port.md](2026-10-09-r-check-variables-assembly-port.md) | 3 | renderer port / variable checks |
| [2026-10-09-r-blobexplosion-assembly-port.md](2026-10-09-r-blobexplosion-assembly-port.md) | 5 | renderer port / particles (`C reference and behavior`; `Assembly, selector and fixture`; `Event-driven scene trace`; `Validation status`) |
| [2026-10-09-print-times-assembly-port.md](2026-10-09-print-times-assembly-port.md) | 2 | renderer port / diagnostics |
| [2026-10-09-particle-explosion2-assembly-port.md](2026-10-09-particle-explosion2-assembly-port.md) | 2 | renderer port / particles |
| [2026-10-09-particle-explosion-assembly-port.md](2026-10-09-particle-explosion-assembly-port.md) | 2 | renderer port / particles |
| [2026-10-09-line-graph-assembly-port.md](2026-10-09-line-graph-assembly-port.md) | 3 | renderer port / timing overlay |
| [2026-10-09-frustum-transform-assembly-port.md](2026-10-09-frustum-transform-assembly-port.md) | 4 | renderer port / frustum |
| [2026-10-09-drawspans-dispatch-parity.md](2026-10-09-drawspans-dispatch-parity.md) | 4 | renderer port / span dispatch |
| [2026-10-09-bench486-live-progress.md](2026-10-09-bench486-live-progress.md) | 0 | Live `bench486` progress reporting (2026-10-09) |
| [2026-10-09-alias-stats-assembly-port.md](2026-10-09-alias-stats-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-08-world-control-assembly-port.md](2026-10-08-world-control-assembly-port.md) | 2 | renderer port / world |
| [2026-10-08-view-control-assembly-port.md](2026-10-08-view-control-assembly-port.md) | 2 | renderer port / view |
| [2026-10-08-turbulent-profile-timer.md](2026-10-08-turbulent-profile-timer.md) | 2 | validation / profiling |
| [2026-10-08-runtime-source-audit.md](2026-10-08-runtime-source-audit.md) | 2 | compatibility / runtime |
| [2026-10-08-render-dispatch-assembly-port.md](2026-10-08-render-dispatch-assembly-port.md) | 2 | renderer port / dispatch |
| [2026-10-08-framebuffer-drawing-assembly-port.md](2026-10-08-framebuffer-drawing-assembly-port.md) | 2 | renderer port / drawing |
| [2026-10-08-drawing-driver-assembly-port.md](2026-10-08-drawing-driver-assembly-port.md) | 3 | renderer port / driver |
| [2026-10-08-cwsdpmi-486-provider.md](2026-10-08-cwsdpmi-486-provider.md) | 2 | compatibility / provider |
| [2026-10-08-chase-camera-assembly-port.md](2026-10-08-chase-camera-assembly-port.md) | 2 | renderer port / camera |
| [2026-10-08-automatic-executable-isa-gate.md](2026-10-08-automatic-executable-isa-gate.md) | 2 | compatibility / workflow |
| [2026-10-08-alias-pipeline-assembly-port.md](2026-10-08-alias-pipeline-assembly-port.md) | 2 | renderer port / alias |
| [2026-10-08-accepted-renderer-checkpoint.md](2026-10-08-accepted-renderer-checkpoint.md) | 2 | renderer port / checkpoint |
| [2026-10-07-visibility-assembly-port.md](2026-10-07-visibility-assembly-port.md) | 2 | renderer port / visibility |
| [2026-10-07-sprite-setup-assembly-port.md](2026-10-07-sprite-setup-assembly-port.md) | 2 | renderer port / sprites |
| [2026-10-07-sprite-orientation-and-render-math-port.md](2026-10-07-sprite-orientation-and-render-math-port.md) | 3 | renderer port / sprites and math |
| [2026-10-07-sprite-draw-assembly-port.md](2026-10-07-sprite-draw-assembly-port.md) | 3 | renderer port / sprites |
| [2026-10-07-sky-assembly-port.md](2026-10-07-sky-assembly-port.md) | 2 | renderer port / sky |
| [2026-10-07-public-entry-assembly-port.md](2026-10-07-public-entry-assembly-port.md) | 2 | renderer port / entries |
| [2026-10-07-palette-assembly-port.md](2026-10-07-palette-assembly-port.md) | 3 | renderer port / palette |
| [2026-10-07-math-closure-assembly-port.md](2026-10-07-math-closure-assembly-port.md) | 2 | renderer port / math support |
| [2026-10-07-light-control-port.md](2026-10-07-light-control-port.md) | 1 | renderer port / lighting |
| [2026-10-07-frame-control-assembly-port.md](2026-10-07-frame-control-assembly-port.md) | 4 | renderer port / frame control |
| [2026-10-07-combined-renderer-parity-after-restart.md](2026-10-07-combined-renderer-parity-after-restart.md) | 1 | renderer port / combined parity |
| [2026-10-07-combined-direct-acceptance.md](2026-10-07-combined-direct-acceptance.md) | 2 | renderer port / parity |
| [2026-10-07-bsp-dynamic-light-push-assembly-port.md](2026-10-07-bsp-dynamic-light-push-assembly-port.md) | 5 | renderer port / lighting |
| [2026-10-07-bsp-dynamic-light-marking-assembly-port.md](2026-10-07-bsp-dynamic-light-marking-assembly-port.md) | 6 | renderer port / lighting |
| [2026-10-07-all-selectable-combined-parity.md](2026-10-07-all-selectable-combined-parity.md) | 2 | renderer port / parity |
| [2026-10-07-alias-skin-table-assembly-port.md](2026-10-07-alias-skin-table-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-07-alias-skin-setup-assembly-port.md](2026-10-07-alias-skin-setup-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-07-alias-rasterize-assembly-port.md](2026-10-07-alias-rasterize-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-07-alias-prepare-assembly-port.md](2026-10-07-alias-prepare-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-07-alias-matrix-composition-assembly-port.md](2026-10-07-alias-matrix-composition-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-07-alias-line-scan-setup-assembly-port.md](2026-10-07-alias-line-scan-setup-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-07-alias-lighting-setup-assembly-port.md](2026-10-07-alias-lighting-setup-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-07-alias-gradient-setup-assembly-port.md](2026-10-07-alias-gradient-setup-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-07-alias-frame-setup-assembly-port.md](2026-10-07-alias-frame-setup-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-07-alias-edge-table-assembly-port.md](2026-10-07-alias-edge-table-assembly-port.md) | 3 | renderer port / alias |
| [2026-10-06-surface-cache-parity-fix.md](2026-10-06-surface-cache-parity-fix.md) | 1 | renderer port / surface cache |
| [2026-10-06-sprite-scan-right-assembly-port.md](2026-10-06-sprite-scan-right-assembly-port.md) | 1 | renderer port / sprites |
| [2026-10-06-sprite-scan-left-assembly-port.md](2026-10-06-sprite-scan-left-assembly-port.md) | 1 | renderer port / sprites |
| [2026-10-06-sprite-gradient-assembly-port.md](2026-10-06-sprite-gradient-assembly-port.md) | 1 | renderer port / sprites |
| [2026-10-06-sprite-frame-assembly-port.md](2026-10-06-sprite-frame-assembly-port.md) | 1 | renderer port / sprites |
| [2026-10-06-sprite-clipping-assembly-port.md](2026-10-06-sprite-clipping-assembly-port.md) | 2 | renderer port / sprites |
| [2026-10-06-renderer-selector-benchmarks.md](2026-10-06-renderer-selector-benchmarks.md) | 1 | renderer port / performance |
| [2026-10-06-particle-update-assembly-port.md](2026-10-06-particle-update-assembly-port.md) | 4 | renderer port / particles |
| [2026-10-06-alias-transform-order-parity.md](2026-10-06-alias-transform-order-parity.md) | 3 | alias |
| [2026-10-05-world-bsp-assembly-port.md](2026-10-05-world-bsp-assembly-port.md) | 3 | renderer port / world-bsp |
| [2026-10-05-submodel-polygons-assembly-port.md](2026-10-05-submodel-polygons-assembly-port.md) | 2 | renderer port / world-bsp |
| [2026-10-05-scan-edges-assembly-port.md](2026-10-05-scan-edges-assembly-port.md) | 3 | renderer port / world-bsp |
| [2026-10-05-renderface-assembly-port.md](2026-10-05-renderface-assembly-port.md) | 3 | renderer port / renderface |
| [2026-10-05-render-world-assembly-port.md](2026-10-05-render-world-assembly-port.md) | 2 | renderer port / world-bsp |
| [2026-10-05-efrag-store-assembly-port.md](2026-10-05-efrag-store-assembly-port.md) | 2 | renderer port / world-bsp |
| [2026-10-05-edge-list-maintenance-assembly-port.md](2026-10-05-edge-list-maintenance-assembly-port.md) | 2 | renderer port / world-bsp |
| [2026-10-05-edge-drawing-assembly-port.md](2026-10-05-edge-drawing-assembly-port.md) | 3 | renderer port / world-bsp |
| [2026-10-05-bmodel-polygon-clip-assembly-port.md](2026-10-05-bmodel-polygon-clip-assembly-port.md) | 3 | renderer port / world-bsp |
| [2026-10-05-bmodel-face-assembly-port.md](2026-10-05-bmodel-face-assembly-port.md) | 2 | renderer port / renderface |
| [2026-10-04-toolchain-refactor.md](2026-10-04-toolchain-refactor.md) | 11 | harness / method |
| [2026-10-04-renderer-assembler-port.md](2026-10-04-renderer-assembler-port.md) | 23 | renderer port |
| [2026-10-03-region-pricing-sweep.md](2026-10-03-region-pricing-sweep.md) | 4 | z-spans |
| [2026-10-03-isa-audit-and-i386-codepath.md](2026-10-03-isa-audit-and-i386-codepath.md) | 3 | ISA / i386 |
| [2026-10-03-clamp-fusion-and-the-1.0-rate.md](2026-10-03-clamp-fusion-and-the-1.0-rate.md) | 1 | harness / method |
| [2026-10-03-alias-glue-closure.md](2026-10-03-alias-glue-closure.md) | 3 | ISA / i386 |
| [2026-10-02-surf8-bundle-and-promotion.md](2026-10-02-surf8-bundle-and-promotion.md) | 5 | renderface |
| [2026-10-02-edge-scan-and-texture-spans.md](2026-10-02-edge-scan-and-texture-spans.md) | 4 | harness / method |
| [2026-10-01-attribution-corrections.md](2026-10-01-attribution-corrections.md) | 5 | alias |
| [2026-09-30-harness-fidelity-and-sourcing.md](2026-09-30-harness-fidelity-and-sourcing.md) | 5 | harness / method |
| [2026-09-29-offline-precomputation-pass.md](2026-09-29-offline-precomputation-pass.md) | 2 | harness / method |
| [2026-09-29-harness-and-cost-model.md](2026-09-29-harness-and-cost-model.md) | 12 | world-bsp |
| [2026-09-29-alias-and-surface-block-experiments.md](2026-09-29-alias-and-surface-block-experiments.md) | 7 | alias |
| [2026-09-28-span-micro-experiments.md](2026-09-28-span-micro-experiments.md) | 8 | alias |
| [2026-09-26-reproducibility-baseline.md](2026-09-26-reproducibility-baseline.md) | 1 | harness / method |
| [microbenchmark-results.md](microbenchmark-results.md) | 14 | harness / method |
| [timedemo-baseline-history.md](timedemo-baseline-history.md) | 6 | harness / method |

## By region

This curated cross-reference groups selected records by renderer region. It is
not exhaustive; the Files table above is the complete inventory.

### renderer ownership and equivalence

- measured [Combined assembly selection passes the complete guest suite](2026-10-08-accepted-renderer-checkpoint.md)
- measured [Whitespace cleanup and release pins preserve all allocated behavior](2026-10-08-accepted-renderer-checkpoint.md)

- measured [Original rotation, efrag and edge preparation remain traceable](2026-10-08-world-control-assembly-port.md)
- measured [World ISA and exact scenes pass before reviewed integration](2026-10-08-world-control-assembly-port.md)

- measured [Original transforms, clipping and model state are preserved](2026-10-08-alias-pipeline-assembly-port.md)
- measured [ISA and exact scenes pass before reviewed integration](2026-10-08-alias-pipeline-assembly-port.md)

- measured [Original collision and camera behavior is preserved](2026-10-08-chase-camera-assembly-port.md)
- measured [ISA, active-camera scenes and reviewed integration pass](2026-10-08-chase-camera-assembly-port.md)

- measured [Drawing algorithms and direct fixtures](2026-10-08-framebuffer-drawing-assembly-port.md)
- measured [Drawing scene acceptance and reviewed integration](2026-10-08-framebuffer-drawing-assembly-port.md)

- measured [Correct subtraction and unchanged normal assembly](2026-10-08-turbulent-profile-timer.md)
- measured [Exact instrumented scene acceptance](2026-10-08-turbulent-profile-timer.md)

- measured [View algorithms and direct fixtures](2026-10-08-view-control-assembly-port.md)
- measured [View scene acceptance and reviewed integration](2026-10-08-view-control-assembly-port.md)

- measured [Driver algorithms and direct fixtures](2026-10-08-drawing-driver-assembly-port.md)
- measured [Drawing driver scene acceptance and reviewed integration](2026-10-08-drawing-driver-assembly-port.md)

- measured [Calling behavior and direct tests](2026-10-08-render-dispatch-assembly-port.md)
- measured [Dispatch scene acceptance and reviewed integration](2026-10-08-render-dispatch-assembly-port.md)

- measured [Exact runtime object boundaries](2026-10-08-runtime-source-audit.md)
- measured [Embedded executable startup code](2026-10-08-runtime-source-audit.md)
- measured [Original algorithms and exact direct tests](2026-10-07-sky-assembly-port.md)
- measured [Scene acceptance and reviewed integration](2026-10-07-sky-assembly-port.md)
- measured [Calling conventions and direct validation](2026-10-07-public-entry-assembly-port.md)
- measured [Public-entry scene acceptance and integration](2026-10-07-public-entry-assembly-port.md)
- measured [Exact algorithms, continuous state and ABI checks](2026-10-07-combined-direct-acceptance.md)
- measured [Reproduction and current ownership limits](2026-10-07-combined-direct-acceptance.md)
- measured [Exact six-scene comparison](2026-10-07-all-selectable-combined-parity.md)
- measured [Regression measurements and remaining scope](2026-10-07-all-selectable-combined-parity.md)
- measured [Original behavior and direct tests](2026-10-07-visibility-assembly-port.md)
- measured [Scene acceptance and integration](2026-10-07-visibility-assembly-port.md)

- `measured` [Accepted returning routines](2026-10-07-math-closure-assembly-port.md)
- `measured` [Scene equivalence and integration](2026-10-07-math-closure-assembly-port.md)
- `measured` [Accepted frame-control equivalence (2026-10-07)](2026-10-07-frame-control-assembly-port.md)
- `documented` [Reproducing the frame-control gates](2026-10-07-frame-control-assembly-port.md)
- `measured` [Direct equivalence and ABI checks](2026-10-07-palette-assembly-port.md)
- `measured` [Paired complete frames](2026-10-07-palette-assembly-port.md)
- `documented` [Reproduce](2026-10-07-palette-assembly-port.md)
- `measured` [Accepted animated-style and point-light equivalence (2026-10-07)](2026-10-07-light-control-port.md)
- `documented` [Implementation and traceability](2026-10-07-sprite-orientation-and-render-math-port.md)
- `measured` [ABI and arithmetic](2026-10-07-sprite-orientation-and-render-math-port.md)
- `measured` [Mechanical and emulator evidence](2026-10-07-sprite-orientation-and-render-math-port.md)
- `measured` [Exact output evidence](2026-10-07-combined-renderer-parity-after-restart.md)

### alias

- rejected [Alias left-edge `ubasestep` specialization (2026-11-11) - 83.71% census at 0 or ±1; exact color/Z/PCX parity and strict i486 pass, but zero-only regressed 0.005825% and full specialization 0.011733%](2026-11-11-alias-scan-ubasestep-specialization-rejected.md)
- rejected [Alias-gradient Y reciprocal sign flip (2026-11-11) - replace multiply-by-`-1.0` with x87 `FCHS`; exact color/Z/PCX parity and strict i486 pass, but mean was -0.0000296%](2026-11-11-alias-gradient-y-reciprocal-fchs-rejected.md)
- rejected [Alias 4-by-4 tile-group minimum hierarchy (2026-11-07) - 12.04% fewer profile tile checks, exact tested stream, but -0.19657% release mean and unsafe epoch invalidation; removed](2026-11-07-alias-tile-group-min-hierarchy-rejected.md)
- rejected [Alias tile-minimum early exit (2026-11-06) - 3,514 fewer profile Z samples, but frame-690 color mismatch; exact Z stream](2026-11-06-alias-tile-minimum-early-exit-rejected.md)
- promoted [Whole-model alias tile anchor early-out (2026-11-06) - 37,470 fewer profile Z reads, exact color/Z/PCX, strict i486, +0.0245131% matched mean FPS](2026-11-06-alias-tile-anchor-early-out-promoted.md)
- promoted [Whole-model alias 4-by-4 tiles with 8-bit epochs (2026-11-05) - reject 1,627 models, 12 KB cache, exact color/Z/PCX, strict i486, +0.00194% vs 32-bit tags](2026-11-05-alias-model-tile-occlusion-promoted.md)
- rejected [Whole-model alias 4-by-8 tiles (2026-11-05) - exact color/Z/PCX parity and strict i486, but -0.07672% against adjacent 4-by-4 runs](2026-11-05-alias-model-tile-occlusion-promoted.md)
- rejected [Whole-model alias 8-by-4 tiles (2026-11-05) - exact color/Z/PCX parity and strict i486, but -0.45532% against the 4-by-4 reference](2026-11-05-alias-model-tile-occlusion-promoted.md)
- rejected [Alias temporal witness tile ordering (2026-11-05) - exact color/Z/PCX parity; only 0.41% fewer tile checks in the profile, so screened out before release timing](2026-11-05-alias-model-tile-occlusion-promoted.md)
- rejected [Alias 8-by-8 parent-min hierarchy (2026-11-05) - exact 970-frame color/Z parity; direct scans were -0.06134% in release timing, child-derived parents had only 151 cache hits and increased work](2026-11-05-alias-parent-hierarchy-rejected.md)
- rejected [Alias tile validity bitset (2026-11-05) - exact parity and strict i486, but -0.07990% across three release runs](2026-11-05-alias-model-tile-occlusion-promoted.md)
- rejected [Alias span constant-depth full-occlusion rejection (2026-11-02) - exact test condition, frame-50 pixel parity and full Z-hash parity; three DOSBox-X runs were 0.0724% slower](2026-11-02-alias-span-constant-depth-reject-rejected.md)
- promoted [Alias span triangle-constant setup (2026-11-01) - +0.0149% across three uninstrumented screens, exact final checksums/events, complete i486 audit](2026-11-01-alias-span-triangle-constant-setup-promoted.md)
- promoted [Alias span prepared-entry register argument (2026-11-02) - +0.0078% over prepared-only, exact full fixed-clock checksum stream, golden frame, and strict i486 audit](2026-11-02-alias-span-register-entry-promoted.md)
- `documented` [Alias-stat leaf behavior and ownership](2026-10-09-alias-stats-assembly-port.md)
- `documented` [Alias-stat selector and oracle](2026-10-09-alias-stats-assembly-port.md)
- `pending` [Alias-stat validation status](2026-10-09-alias-stats-assembly-port.md)

- `measured` [`R_ConcatTransforms` call sites](2026-10-07-alias-matrix-composition-assembly-port.md)
- `measured` [Direct fixtures and i486 audit](2026-10-07-alias-matrix-composition-assembly-port.md)
- `measured` [Two-repeat Demo 2 parity](2026-10-07-alias-matrix-composition-assembly-port.md)
- `measured` [`R_AliasPreparePoints` per-vertex transform and clip setup](2026-10-07-alias-prepare-assembly-port.md)
- `measured` [i486 object audit and exact Demo 2 parity](2026-10-07-alias-prepare-assembly-port.md)
- `measured` [Release-default timing note](2026-10-07-alias-prepare-assembly-port.md)
- `measured` [`D_RasterizeAliasPolySmooth` setup and span orchestration](2026-10-07-alias-rasterize-assembly-port.md)
- `measured` [Selected-object and linked 486 ISA audit](2026-10-07-alias-rasterize-assembly-port.md)
- `measured` [Two-repeat Demo 2 parity and timing](2026-10-07-alias-rasterize-assembly-port.md)
- `measured` [D_PolysetUpdateTables cached skin-row lookup](2026-10-07-alias-skin-table-assembly-port.md)
- `measured` [Direct skin-table fixture and 486 ISA audit](2026-10-07-alias-skin-table-assembly-port.md)
- `measured` [Skin-table paired gameplay parity](2026-10-07-alias-skin-table-assembly-port.md)
- `measured` [D_PolysetSetEdgeTable 12-way triangle edge selection](2026-10-07-alias-edge-table-assembly-port.md)
- `measured` [Direct edge-selection fixture and 486 ISA audit](2026-10-07-alias-edge-table-assembly-port.md)
- `measured` [Edge-table paired gameplay parity](2026-10-07-alias-edge-table-assembly-port.md)
- `measured` [`D_PolysetSetUpForLineScan` edge-step setup](2026-10-07-alias-line-scan-setup-assembly-port.md)
- `measured` [Direct fixture and 486 ISA audit](2026-10-07-alias-line-scan-setup-assembly-port.md)
- `measured` [Paired gameplay parity](2026-10-07-alias-line-scan-setup-assembly-port.md)
- `measured` [`D_PolysetCalcGradients` x87 gradient setup](2026-10-07-alias-gradient-setup-assembly-port.md)
- `measured` [Gradient direct fixture and 486 ISA audit](2026-10-07-alias-gradient-setup-assembly-port.md)
- `measured` [Gradient paired gameplay parity](2026-10-07-alias-gradient-setup-assembly-port.md)
- `measured` [`R_AliasSetupSkin` single and grouped skin resolution](2026-10-07-alias-skin-setup-assembly-port.md)
- `measured` [Skin resolver direct C/assembly fixture and ISA audit](2026-10-07-alias-skin-setup-assembly-port.md)
- `measured` [Skin resolver paired gameplay parity](2026-10-07-alias-skin-setup-assembly-port.md)
- `measured` [`R_AliasSetupFrame` single and grouped frame resolution](2026-10-07-alias-frame-setup-assembly-port.md)
- `measured` [Frame resolver direct C/assembly fixture and ISA audit](2026-10-07-alias-frame-setup-assembly-port.md)
- `measured` [Frame resolver paired gameplay parity](2026-10-07-alias-frame-setup-assembly-port.md)
- `measured` [`R_AliasSetupLighting` scalar setup and light-vector rotation](2026-10-07-alias-lighting-setup-assembly-port.md)
- `measured` [Direct C/assembly fixture and ISA audit](2026-10-07-alias-lighting-setup-assembly-port.md)
- `measured` [Paired gameplay result](2026-10-07-alias-lighting-setup-assembly-port.md)
- `measured` [`R_ConcatTransforms` (2026-10-06)](2026-10-06-alias-transform-order-parity.md)
- `measured` [`R_AliasTransformVector` (2026-10-06)](2026-10-06-alias-transform-order-parity.md)
- `measured` [`R_AliasTransformFinalVert` (2026-10-06)](2026-10-06-alias-transform-order-parity.md)
- `in progress` [Alias polygon clipping now has i486 assembly paths](2026-10-04-renderer-assembler-port.md)
- `in progress` [The clipped alias vertex-preparation loop now has an i486 assembly selector](2026-10-04-renderer-assembler-port.md)
- `measured` [The alias-glue C block is **0.1703% of frame, 3.4x the gate** — the first price that region has ever had,...](2026-10-03-alias-glue-closure.md)
- `measured` [`alias-glue` reads 6.01% of frame and is **2.29%** — 62% of it is the profiler measuring itself (2026-10-...](2026-10-03-alias-glue-closure.md)
- `negative` [Aff8 AGI interlock investigation (2026-09-29) — null result, selector removed](2026-09-29-harness-and-cost-model.md)
- `superseded` [Alias-raster C-glue instrumentation (2026-09-29) — **SUPERSEDED 2026-10-01, the numbers below are instrum...](2026-09-29-harness-and-cost-model.md)
- `measured` [Alias attribution corrected (2026-10-01) — the profiler was measuring itself; C glue is 3.1x cheaper than...](2026-10-01-attribution-corrections.md)
- `measured` [Alias-raster child breakdown (2026-09-29) — C cost is 2.86%, not the predicted <1%](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Alias sub-node instrumentation and the alias cost breakdown (2026-09-29)](2026-09-29-alias-and-surface-block-experiments.md)

### video-memory

- `corrected` [320x200 VGA cache-set model (2026-10-30) — same-set mapping does not prove cache conflict or stall](2026-10-30-vga-cache-set-model-correction.md)
- `promoted` [320x200 framebuffer page-offset pad — strict mean **+0.000003667 FPS (+0.00002246%)**, exact checksum parity, complete i486 audit; the DOSBox result does not verify the physical cache-conflict effect](2026-10-30-vga-framebuffer-page-offset-pad-promoted.md)
- `rejected` [Aff8 16-byte code-alignment experiment (2026-09-29) — rejected and reverted](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Monster gib trail zero-XY experiment (2026-09-29)](2026-09-28-span-micro-experiments.md)
- `measured` [Alias-span address-update experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Alias-model prepare source-cursor experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)

### edge-scan

- `promoted` [`R_StepActiveU` EBX scratch removal (2026-11-11) — **+0.002560 FPS (+0.015157%)**, exact fixed-clock 970 color/Z records and frame 727 PCX, complete strict i486 gate](2026-11-11-edge-stepactiveu-ebx-scratch-promoted.md)
- `rejected` [`TrailingEdge` spanstate branch polarity (2026-11-11) — exact color/Z/PCX parity and strict i486 gate, but the matched mean was **−0.000007333 FPS (−0.0000434%)**, below the sample spread](2026-11-11-edge-trailing-spanstate-branch-polarity-rejected.md)
- `rejected` [Active-edge monotone-order tags (2026-11-06) — exact color/Z/PCX and strict i486 gate, but **−2.121206%** matched mean FPS](2026-11-06-active-edge-order-skip-rejected.md)
- `promoted` [`R_GenerateSpans` trailing-to-leading continuation tail-jump (2026-11-04) — pooled mean **+0.041959333 FPS (+0.2570%)**; one control hitch drives the gain, exact fixed-step parity and complete strict i486 audit](2026-11-04-r-genspans-trailing-to-leading-tail-jump-promoted.md)
- `rejected` [`R_GenerateSpans` non-bmodel fifteen-continuation trial (2026-10-30) — strict mean **−0.000007667 FPS (−0.00004696%)**, exact 969-frame checksum and event traces, complete i486 audit](2026-10-30-edge-sort-nonbmodel-fifteen-continuation-rejected.md)
- `rejected` [Sixteen-comparison edge-sort recheck (2026-11-01) - no standalone or combined gain across twenty candidate runs; bracketed control was faster; exact checksum and strict i486 audit](2026-11-01-edge-sort-nonbmodel-sixteen-recheck-rejected.md)
- `rejected` [`R_GenerateSpans` non-bmodel sixteen-comparison current-source recheck (2026-10-30) — **+0.000002333 FPS (+0.0000143%)**, below both sample spreads; exact final checksum and complete i486 audit](2026-10-30-edge-sort-nonbmodel-sixteen-current-source-recheck-rejected.md)
- `rejected` [`R_GenerateSpans` trailing-edge direct-call layout rejected for parity (2026-10-29) — checksum `3586745294` instead of `1047377823`; invalid timing](2026-10-29-edge-trailing-return-call-parity-rejected.md)
- `promoted` [`R_GenerateSpans` non-bmodel sort fourteen-way unroll (2026-10-30) — strict mean **+0.000016 FPS (+0.0000980%)**, exact fixed-step 970-record checksum and 320x200 PCX parity, complete i486 audit](2026-10-30-edge-sort-nonbmodel-fourteen-unroll-promoted.md)
- `promoted` [`R_GenerateSpans` non-bmodel sort twelve-way unroll (2026-10-29) — 320x200 three-run mean **+0.000006667 FPS (+0.00004083%)**, within run-to-run spread; exact checksum and PCX parity, changed-object i486 proof](2026-10-29-edge-sort-nonbmodel-twelve-unroll-promoted.md)
- `rejected` [`R_GenerateSpans` non-bmodel sort twenty-four-way unroll (2026-10-29) — two candidate screens moved in opposite directions; six-run mean **+0.000002333 FPS**, repeated screen slower, and median below control; exact checksum parity](2026-10-29-edge-sort-nonbmodel-twentyfour-unroll-rejected.md)
- `promoted` [`R_GenerateSpans` non-bmodel sort eight-way unroll (2026-10-29) — strict mean **+0.000041667 FPS (+0.0002553%)**, exact checksum parity and complete executable i486 gate](2026-10-29-edge-sort-nonbmodel-eight-unroll-promoted.md)
- `promoted` [`R_GenerateSpans` non-bmodel sort pair unroll (2026-10-29) — strict mean **+0.002856667 FPS (+0.01750606%)**, exact checksum parity and complete executable i486 gate](2026-10-29-edge-sort-nonbmodel-pair-unroll-promoted.md)
- `promoted` [`R_GenerateSpans` non-bmodel sort exit branch (2026-10-29) — strict mean **+0.005614 FPS (+0.03441523%)**, exact checksum parity and complete executable i486 gate](2026-10-29-edge-sort-nonbmodel-exit-branch-promoted.md)
- `rejected` [`R_GenerateSpans` edge-loop 16-byte alignment (2026-10-29) — parity-screen mean **−0.001233 FPS (−0.00755860%)**, exact checksum parity](2026-10-29-edge-genspans-loop-alignment-rejected.md)
- `promoted` [`TrailingEdge` bmodel direct compare (2026-10-29) — strict mean **+0.019496 FPS (+0.1197%)**, exact checksum parity and complete executable i486 gate](2026-10-29-edge-trailing-insubmodel-direct-compare-promoted.md)
- `promoted` [`R_GenerateSpans` leading-edge spanstate direct compare (2026-10-28) — strict mean **+0.019957666 FPS (+0.1227%)**, exact checksum parity and complete executable i486 gate](2026-10-28-edge-leading-spanstate-direct-compare-promoted.md)
- `promoted` [`R_GenerateSpans` leading-edge `insubmodel` direct compare (2026-10-28) — strict mean **+0.020008667 FPS (+0.1232%)**, exact checksum parity and complete executable i486 gate](2026-10-28-edge-leading-insubmodel-compare-promoted.md)
- `rejected` [`TrailingEdge` `current_iv` load interleave (2026-10-26) — parity-screen mean **−0.000017333 FPS**, exact checksum parity](2026-10-26-edge-trailing-current-iv-load-screen-rejected.md)
- `rejected` [`R_GenerateSpans` `Lnewtop` `current_iv` preload (2026-10-26) — strict mean **−0.000000333 FPS**, exact checksum parity and complete i486 audit](2026-10-26-edge-newtop-current-iv-preload-rejected.md)
- `rejected` [`R_GenerateSpans` spanstate-first leading-edge dispatch (2026-10-26) — parity-screen mean **−0.000012334 FPS**, exact checksum parity](2026-10-26-edge-leading-spanstate-first-screen-rejected.md)
- `rejected` [`R_GenerateSpans` leading-edge load-order swap (2026-10-26) — strict mean **−0.000000334 FPS**, exact checksum parity and complete i486 audit](2026-10-26-edge-leading-load-order-screen-rejected.md)
- `promoted` [Fourth `R_StepActiveU` next-link load hoist (2026-10-26) — strict mean **+0.000001 FPS**, exact checksum parity and full i486 audit](2026-10-26-edge-step-fourth-next-load-hoist-promoted.md)
- `promoted` [Second `R_StepActiveU` U-store after compare (2026-10-26) — strict mean **+0.000007667 FPS (+0.0000481%)**, exact checksum parity and full i486 audit](2026-10-26-edge-step-second-u-store-after-compare-promoted.md)
- `rejected` [First `R_StepActiveU` U-store after compare (2026-10-26) — parity-screen mean **−0.000017 FPS (−0.00010663%)**, exact checksum parity](2026-10-26-edge-step-first-u-store-after-compare-screen-rejected.md)
- `rejected` [Third `R_StepActiveU` U-store after compare (2026-10-26) — parity-screen mean **−0.039121667 FPS (−0.24538672%)**, exact checksum parity; one slow sample retained](2026-10-26-edge-step-third-u-store-after-compare-screen-rejected.md)
- `tied` [Fourth `R_StepActiveU` U-store after compare (2026-10-26) — strict mean tied at **15.942852333 FPS**, exact checksum parity and full i486 audit](2026-10-26-edge-step-fourth-u-store-after-compare-strict-tied.md)
- `rejected` [`R_ScanEdges` fourteen-span loop alignment (2026-10-22) — strict mean **−0.000024 FPS**](2026-10-22-scan-edges-clear-span14-alignment-rejected.md)
- `promoted` [`R_ScanEdges` bottom-tested row loop (2026-10-21) — strict mean **+0.001087 FPS**](2026-10-21-edge-scan-bottom-tested-row-loop-promoted.md)
- `rejected` [`R_ScanEdges` surface-base register cache (2026-10-21) — strict mean **−0.036870 FPS**](2026-10-21-edge-scan-surface-base-cache-screen-rejected.md)
- `closed` [The per-edge dispatch remainder, decomposed (2026-10-02, second pass) — `edge-scan` is now 78% mapped and...](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The complete `edge-scan` map — 78% of the bucket accounted for](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [A fifth probe trap, and it is a different failure from the other four](2026-10-02-edge-scan-and-texture-spans.md)
- `rejected` [What this does and does not license](2026-10-02-edge-scan-and-texture-spans.md)
- `rejected` [`edge-scan` cannot be decomposed (2026-10-01) — the arithmetic forbids it, do not retry](2026-10-01-attribution-corrections.md)

### harness / method

- `measured` [Live `bench486` progress reporting (2026-10-09)](2026-10-09-bench486-live-progress.md)
- `measured` [The duplication, measured](2026-10-04-toolchain-refactor.md)
- `measured` [Four defects that were producing a wrong...](2026-10-04-toolchain-refactor.md)
- `measured` [Two runners tested whatever binary was l...](2026-10-04-toolchain-refactor.md)
- `measured` [The generated DOSBox config was not repr...](2026-10-04-toolchain-refactor.md)
- `measured` [One selector, written five times](2026-10-04-toolchain-refactor.md)
- `measured` [Six latent defects in the source-level I...](2026-10-04-toolchain-refactor.md)
- `measured` [What is now a gate that was not](2026-10-04-toolchain-refactor.md)
- `measured` [Toolchain-audit ISA correction (2026-10-06)](2026-10-04-toolchain-refactor.md)
- `measured` [A checklist moved out of a script's tail](2026-10-04-toolchain-refactor.md)
- `measured` [Result](2026-10-04-toolchain-refactor.md)
- `measured` [Dead code, and one that was not](2026-10-04-toolchain-refactor.md)
- `measured` [The clamp fusion is measured at **0.0000%**, and the probe that explains it says **1.0 cycle per instruct...](2026-10-03-clamp-fusion-and-the-1.0-rate.md)
- `measured` [`edge-scan` decomposed by dead-scratch probe — pass 1 of 2 (2026-10-02): six probes, and **the closure be...](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The census, and what it overturned](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The six probes](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Decision 3's 0.66 rate is wrong — the risk was prospective, not realised](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Four probe traps, each of which cost a build-and-run cycle](2026-10-02-edge-scan-and-texture-spans.md)
- `closed` [What is NOT closed, and what is inadmissible](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The Z-span integer probe, measured and retired (2026-10-02) — the harness charges 1.0 cycles per instruct...](2026-10-02-surf8-bundle-and-promotion.md)
- `measured` [Harness integrity and the measured fidelity result (2026-09-30) — the gate problem is now measured, not a...](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [Legal sources for a 486 machine ROM (not pursued here)](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [Sourcing research: the legal-BIOS question, answered (2026-09-30)](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [86Box, verified against source (2026-09-30) — the best ROM-free candidate, still disqualified](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [`Turbulent8` setup precompute (2026-09-30) — priced with a bit-exact dead-scratch probe; 0.034% addressab...](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [Static 486 cost model (2026-09-29) — built; it disqualifies all three blind axes and promotes nothing](2026-09-29-harness-and-cost-model.md)
- `measured` [E3 and E4 disposition (2026-09-29)](2026-09-29-harness-and-cost-model.md)
- `rejected` [Hot-code clustering (2026-09-29) — rejected, and object granularity is the blocker](2026-09-29-harness-and-cost-model.md)
- `measured` [What this harness can and cannot measure (2026-09-29)](2026-09-29-harness-and-cost-model.md)
- `measured` [Where this leaves the project](2026-09-29-harness-and-cost-model.md)
- `measured` [`renderface` priced by premise (2026-10-01) — large pool, but the x87 in it is essential work; no probe b...](2026-10-01-attribution-corrections.md)
- `measured` [Current parity-gated closure (2026-09-28)](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Current reproducibility note (2026-09-26)](2026-09-26-reproducibility-baseline.md)

### ISA / i386

- `measured` [Strict source-bound proof is integrated into normal builds](2026-10-08-automatic-executable-isa-gate.md)
- `measured` [Cached execution and adversarial checks pass](2026-10-08-automatic-executable-isa-gate.md)
- `measured` [Exact provider boundaries and replacements are verified](2026-10-08-cwsdpmi-486-provider.md)
- `measured` [Three paired scenes preserve rendering and timing](2026-10-08-cwsdpmi-486-provider.md)
- `measured` [Correction (2026-10-06): `0F AF` IMUL is i386, not Pentium; all three i486 variants audit at zero above-target instructions](2026-10-03-isa-audit-and-i386-codepath.md)
- `measured` [The 161 `imul r32,r/m32` sites are **not** strength-reducible — three approaches refuted by measurement (2026-10-03) — historical claim, superseded by correction](2026-10-03-isa-audit-and-i386-codepath.md)
- `measured` [A separate i386 codepath exists, and the shipped "486" binary needs a Pentium — both from one root cause (2026-10-03) — historical claim, superseded by correction](2026-10-03-isa-audit-and-i386-codepath.md)
- `closed` [The alias-glue block is **63 instructions, minimal, and 5.5x the gate** — closed from its own disassembly...](2026-10-03-alias-glue-closure.md)

### lightmap

- `promoted` [`R_PushDlights` active-light enumeration](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `measured` [Five-case direct fixture, i486 ISA audit, and six-scene exact frame parity](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `promoted` [`R_MarkLights` BSP traversal and surface marking](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Direct 128-case C/assembly parity and i486 instruction audit](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Exact Demo 1 C/assembly framebuffer parity](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [`R_BuildLightMap` is **0.06% of frame, not 7.5%** — and a real loop-invariant hoist in it is worth **0.04...](2026-10-03-region-pricing-sweep.md)

### renderface

- `promoted` [`R_ClipEdge` combined distance sign check with `%eax` reload (2026-11-11) — **+0.008154 FPS (+0.048263%)**, exact 970 color/Z rows and frame 727 PCX, complete strict i486 gate](2026-11-11-r-clipedge-combined-sign-live-eax-reload-promoted.md)
- `rejected` [`R_ClipEdge` combined distance sign check (2026-11-11) — live `%eax` clobber changed clipping; frame-0 color and Z checksums diverged and the source change was reverted](2026-11-11-r-clipedge-combined-sign-live-eax-rejected.md)
- `promoted` [`R_ClipEdge` endpoint dot-product schedule (2026-11-11) — **+0.064552 FPS (+0.383695%)**, exact 970 color/Z records and frame 482 PCX, complete strict i486 gate](2026-11-11-r-clipedge-dot-product-stack-reschedule-promoted.md)
- `promoted` [`R_RenderFace` clip-plane argument hoist (2026-11-04) — **+0.010021 FPS (+0.0611856%)**, exact fixed-step and captured-frame parity, complete strict i486 gate](2026-11-04-renderface-cliparg-hoist-promoted.md)
- `promoted` [`R_RenderFace` outgoing argument frame (2026-11-04) — **+0.000343 FPS (+0.002094%)**, exact fixed-step and captured-frame parity, complete strict i486 gate](2026-11-04-renderface-outgoing-argument-frame-promoted.md)
- `rejected` [`R_RenderFace` prelinked all-mask clip chains (2026-11-04) — **436/970 fixed-step frame checksums differed**, final checksum matched, captured frame 695 did not; strict i486 audit passed](2026-11-04-renderface-prelinked-all-mask-chains-rejected.md)
- `rejected` [`R_RenderFace` view-plane order 1,0,2,3 (2026-11-04) — **591/970 fixed-step frame checksums differed**; final checksum matched, captured frame 695 did not](2026-11-04-renderface-clipplane-order-rejected.md)
- `promoted` [`R_RenderFace` prelinked full-mask chain (2026-11-03) — **+0.003736667 FPS (+0.0226579%)**, exact per-frame checksum and captured-frame parity, complete source-bound i486 audit](2026-11-03-renderface-prelinked-fullmask-chain-promoted.md)
- `promoted` [`R_RenderFace` full four-plane clip-chain fast path (2026-11-03) — **+0.007299 FPS (+0.044278%)**, exact pixel parity and complete executable i486 gate](2026-11-03-renderface-fourclip-mask-fastpath-promoted.md)
- `withdrawn` [`R_ClipEdge` exact world-endpoint projection cache (2026-11-03) — +0.0529% result invalidated by inconsistent parity; 32-bit follow-up had no measurable gain; removed](2026-11-03-r-clipedge-projection-cache-withdrawn.md)
- `rejected` [`R_RenderFace` direct no-clip emitter entry (2026-10-31) — **−0.011087 FPS (−0.0679%)**, with a 49-pixel frame-99 delta](2026-10-31-zspan-no-fxch-promoted-and-renderface-no-clip-rejected.md)
- `rejected` [`R_ClipEdge` left-clipped direct compare screen (2026-10-29) — **−0.038261 FPS (−0.23454991%)**, exact checksum parity](2026-10-29-r-clipedge-leftclipped-direct-compare-rejected.md)
- `promoted` [`R_ClipSpriteFace` clip-current direct compare (2026-10-29) — strict mean **+0.000025333 FPS (+0.00015530%)**, exact checksum parity and complete executable i486 gate](2026-10-29-r-clipsprite-clipcurrent-direct-compare-promoted.md)
- `promoted` [`R_RenderFace` cached-offset marker memory test (2026-10-29) — strict mean **+0.003342333 FPS (+0.02049357%)**, exact checksum parity and complete executable i486 gate](2026-10-29-renderface-edge-marker-memory-test-promoted.md)
- `promoted` [`R_RenderFace` shared signed-edge address calculation (2026-10-29) — strict mean **+0.004255 FPS (+0.02609641%)**, exact checksum parity and complete executable i486 gate](2026-10-29-renderface-shared-edge-address-promoted.md)
- `promoted` [`R_RenderFace` cacheoffset sentinel direct compare (2026-10-29) — strict mean **+0.000618 FPS (+0.00379%)**, exact checksum parity and complete executable i486 gate](2026-10-29-renderface-cacheoffset-sentinel-direct-compare-promoted.md)
- `promoted` [`R_RenderFace` near-z-only direct compare (2026-10-29) — strict mean **+0.002934 FPS (+0.0180%)**, exact checksum parity and complete executable i486 gate](2026-10-29-renderface-nearzionly-direct-compare-promoted.md)
- `promoted` [`R_RenderFace` cached-edge surface check with one direct 16-bit compare (2026-10-28) — **+0.001005 FPS (+0.006188%)**, exact checksum parity and complete i486 ISA audit](2026-10-28-renderface-cached-surface-compare-promoted.md)
- `rejected` [`R_RenderFace` edge cache sentinel sign-test screen (2026-10-27) — **−0.000020667 FPS (−0.0001283%)**, exact checksum parity](2026-10-27-renderface-edge-cache-sign-test-screen-rejected.md)
- `promoted` [`R_RenderFace` assembly selected for i486 (2026-10-22) — **+0.39763%** against the matched C reference](2026-10-22-renderface-assembly-promoted.md)
- `rejected` [RenderFace `SAHF/JNA` nearzi update (2026-10-22) — strict mean **−0.000904 FPS (−0.00580818%)**](2026-10-22-renderface-sahf-nearzi-rejected.md)
- `rejected` [`R_RenderFace` zero-clipflags shortcut (2026-10-24) — **−0.001965 FPS (−0.01235792%)** against the trailing control, with exact checksum parity](2026-10-24-renderface-zero-clipflags-screen-rejected.md)
- `negative` [Correction: the general block row is **minimal, and that is derivable** — the 31x gate is not reachable b...](2026-10-03-region-pricing-sweep.md)
- `closed` [`renderface` priced (2026-10-02) — **CLOSED with a price**, and the 1.0 cycle rate is not a constant](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The rate is a dependency property, not a constant — this is the important result](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [What the price does to `renderface`](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Two probe mechanics specific to C, both of which would have produced a silently wrong number](2026-10-02-edge-scan-and-texture-spans.md)

### renderer port

- `measured` [VGA linear dirty-rectangle copies preserve one-to-three-byte row tails against an independent expected display buffer](2026-10-28-vga-linear-copy-tail-fix.md)
- `measured` [`VID_GetModePtr`, `VID_ModeInfo`, `VID_SetMode`, `VID_SetPalette`, `VID_ShiftPalette`, and `VID_Shutdown` pass C/ASM parity and strict i486 BENCH/release gates](2026-10-19-video-mode-assembly-port.md)
- `open` [Hardware-specific callbacks, FPS, and full-scene parity remain](2026-10-19-video-mode-assembly-port.md)
- `measured` [`M_ModemConfig_Draw` passes 2,880 exact C/assembly cases and the complete strict i486 release gate](2026-10-19-modem-config-menu-assembly-port.md)
- `open` [Full-scene parity, FPS measurement, incomplete renderer ownership graph, and remaining console/menu/video C dependencies](2026-10-19-modem-config-menu-assembly-port.md)
- `measured` [Pause/loading overlays pass 10 exact C/ASM cases and the strict i486 release gate](2026-10-19-screen-pause-loading-assembly-port.md)
- `open` [Full-scene parity, FPS measurement, unresolved renderer ownership, and remaining menu/video dependencies](2026-10-19-screen-pause-loading-assembly-port.md)
- `measured` [Zone/cache/hunk diagnostic trace adapters pass 25 C/ASM cases and strict BENCH and release i486 gates](2026-10-18-zone-memory-trace-assembly-port.md)
- `open` [Shared console output services and full renderer ownership remain](2026-10-18-zone-memory-trace-assembly-port.md)
- `measured` [Normal intermission overlay and number formatting pass four exact C/ASM cases and the strict i486 gate](2026-10-18-sbar-intermission-assembly-port.md)
- `measured` [Finale overlay assembly passes six exact C/ASM cases and the strict i486 gate](2026-10-18-sbar-finale-assembly-port.md)
- `open` [Full-scene parity, FPS measurement, and complete renderer ownership remain](2026-10-18-sbar-intermission-assembly-port.md)
- `measured` [`Sbar_DeathmatchOverlay` assembly passes six exact C/ASM cases and the strict i486 gate](2026-10-18-sbar-deathmatch-assembly-port.md)
- `open` [Full-scene parity, FPS measurement, and broader renderer C ownership remain](2026-10-18-sbar-deathmatch-assembly-port.md)
- `measured` [`M_BuildTranslationTable` and `CL_NewTranslation` selected assembly; all 512 palette-pair cases and strict i486 gates passed (2026-10-18)](2026-10-18-player-translation-assembly-port.md)
- `open` [Full-scene parity, FPS measurement, and remaining renderer ownership](2026-10-18-player-translation-assembly-port.md)
- `measured` [`D_DrawParticle` -> verification of the existing i486 rasterizer (2026-10-10)](2026-10-10-d-drawparticle-assembly-port.md)
- `measured` [104 direct C/ASM comparisons across four x87 rounding modes](2026-10-10-d-drawparticle-assembly-port.md)
- `measured` [Exact two-repeat `demo2-wizspike-event` frame and palette parity](2026-10-10-d-drawparticle-assembly-port.md)
- `measured` [Strict i486 executable, startup, and provider audits](2026-10-10-d-drawparticle-assembly-port.md)
- `open` [Full renderer ownership, broader particle stress, sky coverage, and FPU-less 486SX scope](2026-10-10-d-drawparticle-assembly-port.md)
- `measured` [`R_EntityParticles` -> i486 assembly port (2026-10-10)](2026-10-10-r-entityparticles-assembly-port.md)
- `measured` [Exact particle-list, RNG-continuation and ABI fixture](2026-10-10-r-entityparticles-assembly-port.md)
- `measured` [Exact two-repeat `demo2` entity-particle event frame parity](2026-10-10-r-entityparticles-assembly-port.md)
- `measured` [Strict i486 executable, startup, and provider audits](2026-10-10-r-entityparticles-assembly-port.md)
- `measured` [`R_RunParticleEffect` -> i486 assembly port (2026-10-10)](2026-10-10-r-runparticleeffect-assembly-port.md)
- `measured` [12-case direct state/RNG/ABI fixture and strict i486 executable audit](2026-10-10-r-runparticleeffect-assembly-port.md)
- `measured` [Exact two-run `TE_WIZSPIKE` frame and event parity](2026-10-10-r-runparticleeffect-assembly-port.md)
- `open` [486SX FPU scope and the remaining renderer migration](2026-10-10-r-runparticleeffect-assembly-port.md)
- `measured` [`V_BonusFlash_f` -> i486 assembly port (2026-10-10)](2026-10-10-v-bonusflash-assembly-port.md)
- `measured` [256 full-state/ABI patterns and 9,728 exact palette-update frames](2026-10-10-v-bonusflash-assembly-port.md)
- `measured` [Strict i486 executable, startup, and provider audits](2026-10-10-v-bonusflash-assembly-port.md)
- `open` [Full renderer-profile parity and remaining view/screen ownership](2026-10-10-v-bonusflash-assembly-port.md)
- `measured` [`V_cshift_f` -> i486 assembly port (2026-10-10)](2026-10-10-v-cshift-assembly-port.md)
- `measured` [Original `v_cshift` command semantics and argument stores](2026-10-10-v-cshift-assembly-port.md)
- `measured` [Seven token cases and contents shift](2026-10-10-v-cshift-assembly-port.md)
- `measured` [This profile's strict i486 audit](2026-10-10-v-cshift-assembly-port.md)
- `measured` [V_cshift traceability and reproduction](2026-10-10-v-cshift-assembly-port.md)
- `open` [Full profile parity and remaining view/screen ownership](2026-10-10-v-cshift-assembly-port.md)
- `measured` [`V_Init` -> i486 assembly port (2026-10-10)](2026-10-10-v-init-assembly-port.md)
- `measured` [Original command, cvar and gamma order](2026-10-10-v-init-assembly-port.md)
- `measured` [Direct registration, gamma and ABI fixture](2026-10-10-v-init-assembly-port.md)
- `measured` [Strict i486 audit for the view-control profile](2026-10-10-v-init-assembly-port.md)
- `measured` [V_Init traceability and reproduction](2026-10-10-v-init-assembly-port.md)
- `open` [Remaining view initialization dependencies and full profile parity](2026-10-10-v-init-assembly-port.md)
- `measured` [`Con_DrawInput` console-input overlay passes exact direct C/ASM/public parity across 21 cases and four x87 rounding modes](2026-10-10-con-drawinput-assembly-port.md)
- `measured` [Strict linked-object, final-executable, startup and provider i486 audits pass with zero violations or exemptions](2026-10-10-con-drawinput-assembly-port.md)
- `measured` [`Con_DrawConsole` exact five-case C/ASM framebuffer and state parity under DOSBox-X](2026-10-17-con-drawconsole-assembly-port.md)
- `measured` [Strict i486 object, linked executable, startup and CWSDPMI provider gates pass with zero exemptions](2026-10-17-con-drawconsole-assembly-port.md)
- `measured` [`Con_DrawNotify` exact C/ASM/public framebuffer and state parity across eight cases and four x87 modes](2026-10-17-con-drawnotify-assembly-port.md)
- `measured` [Strict linked-object, executable, startup and CWSDPMI provider gates pass with zero exemptions](2026-10-17-con-drawnotify-assembly-port.md)
- `measured` [`SCR_DrawCenterString` exact 18-case C/assembly/public parity across 12 x87 settings](2026-10-10-screen-center-string-assembly-parity.md)
- `measured` [Strict linked executable, startup and CWSDPMI provider audits pass with zero violations or exemptions](2026-10-10-screen-center-string-assembly-parity.md)
- `open` [Complete-scene parity and broader screen/rendering ownership](2026-10-10-screen-center-string-assembly-parity.md)
- `measured` [`SCR_EraseCenterString` exact 252-call C/assembly/public parity across 12 x87 settings](2026-10-11-screen-erase-center-string-assembly-port.md)
- `measured` [Strict linked executable, startup and CWSDPMI provider audits pass with zero violations or exemptions](2026-10-11-screen-erase-center-string-assembly-port.md)
- `open` [Full-scene parity and remaining renderer ownership](2026-10-11-screen-erase-center-string-assembly-port.md)
- `measured` [`SCR_DrawNotifyString` -> i486 assembly port with 19 exact direct cases and i486 execution (2026-10-10)](2026-10-10-scr-drawnotifystring-assembly-port.md)
- `measured` [Strict project-object, linked/runtime, final-executable, startup and CWSDPMI i486 audits pass with zero violations or exemptions](2026-10-10-scr-drawnotifystring-assembly-port.md)
- `open` [Combined-profile/full-scene parity and remaining screen ownership](2026-10-10-scr-drawnotifystring-assembly-port.md)
- `measured` [`SCR_UpdateScreen` overlay dispatch passes eight exact branch cases and two-run Demo 1 framebuffer parity](2026-10-13-screen-overlays-assembly-port.md)
- `measured` [C and assembly profiles pass strict i486 object, executable, startup and provider audits](2026-10-13-screen-overlays-assembly-port.md)
- `measured` [`SCR_UpdateScreen` full orchestration passes fifteen direct cases, seven paired scenes and a cumulative strict i486 release smoke](2026-10-13-screen-update-assembly-port.md)
- `measured` [The refreshed production ownership scan counts console, menu, status-bar, video and cache dependencies](2026-10-13-screen-update-assembly-port.md)
- `open` [Called screen/menu/status-bar/video routines, indirect targets and full-renderer ownership remain](2026-10-13-screen-update-assembly-port.md)
- `measured` [`SCR_CheckDrawCenterString` passes 11 exact state/draw cases across 12 x87 settings and the strict i486 executable gate](2026-10-18-scr-check-draw-center-string-assembly-port.md)
- `measured` [`R_ParticleExplosion2` -> i486 assembly port (2026-10-09)](2026-10-09-particle-explosion2-assembly-port.md)
- `measured` [Particle pool semantics and ABI](2026-10-09-particle-explosion2-assembly-port.md)
- `measured` [Full-state fixture and i486 results](2026-10-09-particle-explosion2-assembly-port.md)
- `measured` [`R_ParticleExplosion` -> i486 assembly port (2026-10-09)](2026-10-09-particle-explosion-assembly-port.md)
- `measured` [Standard explosion particle pool semantics and ABI](2026-10-09-particle-explosion-assembly-port.md)
- `measured` [Full-state fixture and i486 validation](2026-10-09-particle-explosion-assembly-port.md)
- `measured` [`R_TransformPlane` assembly slice (2026-10-09)](2026-10-09-r-transformplane-assembly-port.md)
- `measured` [Semantics and focused fixture](2026-10-09-r-transformplane-assembly-port.md)
- `measured` [Focused validation and remaining scene coverage](2026-10-09-r-transformplane-assembly-port.md)
- `measured` [`R_PrintTimes` -> i486 assembly port (2026-10-09)](2026-10-09-print-times-assembly-port.md)
- `measured` [Time conversion, formatting, and ABI](2026-10-09-print-times-assembly-port.md)
- `measured` [Deterministic console fixture and i486 results](2026-10-09-print-times-assembly-port.md)
- `measured` [`R_LineGraph` -> `R_LineGraph_asm486` port](2026-10-09-line-graph-assembly-port.md)
- `measured` [Leaf behavior and ownership](2026-10-09-line-graph-assembly-port.md)
- `measured` [Selection and oracle](2026-10-09-line-graph-assembly-port.md)
- `measured` [Acceptance status](2026-10-09-line-graph-assembly-port.md)
- `measured` [Original dispatch path](2026-10-09-drawspans-dispatch-parity.md)
- `measured` [Span dispatch verification](2026-10-09-drawspans-dispatch-parity.md)
- `measured` [Reference parity](2026-10-09-drawspans-dispatch-parity.md)
- `open` [Scope boundary](2026-10-09-drawspans-dispatch-parity.md)
- `measured` [Per-frame fullbright cache check](2026-10-09-r-check-variables-assembly-port.md)
- `measured` [R_CheckVariables verification](2026-10-09-r-check-variables-assembly-port.md)
- `measured` [Parity and scope boundary](2026-10-09-r-check-variables-assembly-port.md)
- `measured` [Per-frame renderer setup](2026-10-09-r-setupframe-assembly-port.md)
- `measured` [Verification](2026-10-09-r-setupframe-assembly-port.md)
- `open` [Scope still open](2026-10-09-r-setupframe-assembly-port.md)
- `measured` [Candidate identity and strict ISA gate](2026-10-09-selectable-84-alias-control-checkpoint.md)
- `measured` [Exact entity-scene parity](2026-10-09-selectable-84-alias-control-checkpoint.md)
- `measured` [Ownership impact and remaining C paths](2026-10-09-selectable-84-alias-control-checkpoint.md)
- `measured` [Validation boundary](2026-10-09-selectable-84-alias-control-checkpoint.md)
- `measured` [Run the combined alias-control profile](2026-10-09-selectable-84-alias-control-checkpoint.md)
- `measured` [Candidate identity and strict machine-code gate](2026-10-09-selectable-83-vesa-checkpoint.md)
- `measured` [Exact parity for the VESA scene](2026-10-09-selectable-83-vesa-checkpoint.md)
- `measured` [Current ownership inventory and remaining work](2026-10-09-selectable-83-vesa-checkpoint.md)
- `measured` [Host-side startup proof helper](2026-10-09-selectable-83-vesa-checkpoint.md)
- `measured` [Reproduction command](2026-10-09-selectable-83-vesa-checkpoint.md)
- `measured` [77-selector strict assembly profile acceptance (2026-10-09)](2026-10-09-selectable-77-assembly-profile-acceptance.md)
- `measured` [Complete i486 executable gate](2026-10-09-selectable-77-assembly-profile-acceptance.md)
- `measured` [Six-scene exact 77-selector parity](2026-10-09-selectable-77-assembly-profile-acceptance.md)
- `measured` [Remaining 77-selector ownership and scope](2026-10-09-selectable-77-assembly-profile-acceptance.md)
- `measured` [76-selector combined assembly profile acceptance (2026-10-09)](2026-10-09-selectable-assembly-profile-acceptance.md)
- `measured` [Strict i486 executable gate](2026-10-09-selectable-assembly-profile-acceptance.md)
- `measured` [Six-scene exact parity](2026-10-09-selectable-assembly-profile-acceptance.md)
- `measured` [Remaining ownership and scope](2026-10-09-selectable-assembly-profile-acceptance.md)
- `in progress` [Opt-in frustum transform candidate](2026-10-09-frustum-transform-assembly-port.md)
- `in progress` [Paired scene parity (visual-only diagnostic)](2026-10-09-frustum-transform-assembly-port.md)
- `in progress` [Frustum AABB-index setup extension (2026-10-09)](2026-10-09-frustum-transform-assembly-port.md)
- `measured` [Strict paired acceptance (2026-10-09)](2026-10-09-frustum-transform-assembly-port.md)
- `measured` [Optional submodel polygon driver](2026-10-09-zsubmodel-polygons-assembly-port.md)
- `measured` [`R_MarkLights` tree walk](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Direct fixture and i486 ISA audit](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Exact Demo 1 parity](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Extended paired scenes and transient console notifications](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `promoted` [Combined fixture, ISA gate, and i486 default](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Benchmark text-data disassembly case](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [`R_PushDlights` slot loop](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `measured` [Direct fixture and instruction audit](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `measured` [Six-scene exact framebuffer parity](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `measured` [Combined promoted dynamic-light paths](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `promoted` [Promotion](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `measured` [Combined promoted sprite-draw paths](2026-10-07-sprite-draw-assembly-port.md)
- `promoted` [`R_GetSpriteframe` animated sprite-frame selection](2026-10-06-sprite-frame-assembly-port.md)
- `measured` [Twelve direct frame-selection cases and exact paired Demo 2 parity](2026-10-06-sprite-frame-assembly-port.md)
- `promoted` [`D_DrawSprite` sprite draw orchestration](2026-10-07-sprite-draw-assembly-port.md)
- `measured` [Combined four-path, six-scene exact checksum and framebuffer parity](2026-10-07-sprite-draw-assembly-port.md)
- `measured` [Three direct buffer fixtures, exact Demo 2 parity, and focused ISA audits](2026-10-07-sprite-draw-assembly-port.md)
- `promoted` [`R_SetupAndDrawSprite` world poster, clipping, projection, and dispatch](2026-10-07-sprite-setup-assembly-port.md)
- `measured` [Five direct fixtures, two-repeat exact Demo 2 parity, and focused ISA audits](2026-10-07-sprite-setup-assembly-port.md)
- `measured` [Renderer-port ISA correction (2026-10-06)](2026-10-04-renderer-assembler-port.md)

- `in progress` [`D_FillRect` is now an i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_DrawZPoint` is now an i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [The active sky span pixel loop has a selectable i486 assembly path](2026-10-04-renderer-assembler-port.md)
- `in progress` [The sky scan span loop now has an i486 assembly path](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_DrawSkyScans8` is now a complete i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_WarpScreen` is now a selectable i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_DrawSolidSurface` now has a selectable i486 assembly path](2026-10-04-renderer-assembler-port.md)
- `in progress` [The `Turbulent8` scan setup and interpolation now have a selectable i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_BuildLightMap` now has a selectable i486 assembly dispatcher](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_AddDynamicLights` orchestration and projection now have selectable i486 assembly](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_DlightContributes` now has a selectable i486 assembly entry](2026-10-04-renderer-assembler-port.md)
- `in progress` [The `D_CacheSurface` miss handoff now has i486 assembly paths](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_DrawSurface` now has a selectable i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_CacheSurface` now has a full selectable i486 assembly entry](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_TextureAnimation` now has a full selectable i486 assembly entry](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_MipLevelForScale` now exports its public i486 assembly entry directly](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_SetSurfaceZGradients` now has a selectable i486 assembly entry](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_CalcGradients` and texture-axis caching now have an i486 assembly path](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_DrawSurfaces` now has a selectable i486 assembly dispatcher](2026-10-04-renderer-assembler-port.md)
- `in progress` [Next work](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_RecursiveWorldNode` now has a selectable assembly walk](2026-10-05-world-bsp-assembly-port.md)
- `in progress` [`R_DrawParticles` now has a selectable i486 assembly path](2026-10-06-particle-update-assembly-port.md)
- `measured` [Build, ISA, and render validation](2026-10-06-particle-update-assembly-port.md)
- `in progress` [Remaining particle closure](2026-10-06-particle-update-assembly-port.md)
- `measured` [`R_ClearParticles` free-list reset follow-up (2026-10-09)](2026-10-06-particle-update-assembly-port.md)
- `in progress` [`R_RotateSprite` beam translation](2026-10-06-sprite-clipping-assembly-port.md)
- `in progress` [`R_ClipSpriteFace` plane clipping](2026-10-06-sprite-clipping-assembly-port.md)
- `in progress` [`R_GetSpriteframe` animated frame selection](2026-10-06-sprite-frame-assembly-port.md)
- `in progress` [`D_SpriteCalculateGradients` perspective setup](2026-10-06-sprite-gradient-assembly-port.md)
- `in progress` [`D_SpriteScanLeftEdge` span generation](2026-10-06-sprite-scan-left-assembly-port.md)
- `in progress` [`D_SpriteScanRightEdge` span completion](2026-10-06-sprite-scan-right-assembly-port.md)
- `in progress` [`D_DrawSprite` orchestration](2026-10-07-sprite-draw-assembly-port.md)
- `measured` [Paired render and linked-ISA validation](2026-10-07-sprite-draw-assembly-port.md)
- `measured` [`R_SetupAndDrawSprite` world poster, clipping, projection, and dispatch](2026-10-07-sprite-setup-assembly-port.md)
- `measured` [Instruction-set and paired-render validation](2026-10-07-sprite-setup-assembly-port.md)
- `in progress` [Remaining world-BSP closure](2026-10-05-world-bsp-assembly-port.md)
- `in progress` [`R_RenderWorld` now has a selectable i486 assembly entry](2026-10-05-render-world-assembly-port.md)
- `in progress` [Remaining active world-renderer closure](2026-10-05-render-world-assembly-port.md)
- `in progress` [`R_RenderFace` now has a selectable i486 assembly entry](2026-10-05-renderface-assembly-port.md)
- `in progress` [`R_EmitCachedEdge` now has a selectable i486 assembly entry](2026-10-05-renderface-assembly-port.md)
- `in progress` [Remaining face-renderer closure](2026-10-05-renderface-assembly-port.md)
- `in progress` [Remaining active renderer closure](2026-10-05-renderface-assembly-port.md)
- `in progress` [`R_RenderBmodelFace` now has a selectable i486 assembly entry](2026-10-05-bmodel-face-assembly-port.md)
- `in progress` [Remaining B-model renderer closure](2026-10-05-bmodel-face-assembly-port.md)
- `in progress` [`R_StoreEfrags` now has a selectable i486 assembly entry](2026-10-05-efrag-store-assembly-port.md)
- `in progress` [Remaining world-renderer closure](2026-10-05-efrag-store-assembly-port.md)
- `in progress` [`R_DrawSubmodelPolygons` now has a selectable i486 assembly entry](2026-10-05-submodel-polygons-assembly-port.md)
- `in progress` [Remaining submodel-polygon closure](2026-10-05-submodel-polygons-assembly-port.md)
- `in progress` [`R_EdgeDrawing` now has a selectable i486 assembly entry](2026-10-05-edge-drawing-assembly-port.md)
- `in progress` [Remaining edge-drawing closure](2026-10-05-edge-drawing-assembly-port.md)
- `promoted` [`surf8` flat axis: three measured wins bundled and **PROMOTED, 0.0620%** (2026-10-02)](2026-10-02-surf8-bundle-and-promotion.md)
- `screen rejected` [Mip-2 texel-read order — **−0.00004076%** against the promoted order](2026-10-21-surf8-mip2-texel-read-order-screen-rejected.md)
- `rejected` [Mip-2 light-delta reload prefetch — **−0.00005149%** against the promoted texel-load source](2026-10-21-surf8-mip2-lightdelta-prefetch-rejected.md)
- `rejected` [Mip-2 row-state reload schedule — **−0.00006007%** against the promoted texel-load source](2026-10-21-surf8-mip2-rowstate-reload-rejected.md)
- `promoted` [Mip-2 surface texel-load schedule — **+0.00004720%** with exact parity](2026-10-21-surf8-mip2-texel-loads-promoted.md)
- `closed` [The `surf8` horizontal-flat axis, screened (2026-10-02) — four candidates, two closed by price](2026-10-02-surf8-bundle-and-promotion.md)
- `rejected` [Mip-2 horizontal-flat surface block — parity-clean reimplementation averaged 0.00183215% slower](2026-10-21-surf8-mip2-horizontal-flat-rejected.md)
- `promoted` [mip-1 flat-row index hoist (2026-10-02) — **0.0353% alone; promoted at 0.0620% as part of a bundle**](2026-10-02-surf8-bundle-and-promotion.md)
- `measured` [Drawn-face ratio (2026-09-29) — measured at 0.9585, which closes the per-face precompute family](2026-09-29-harness-and-cost-model.md)
- `promoted` [mip-1 horizontal-flat surface blocks (2026-10-01) — **PROMOTED, 0.0513%**](2026-10-01-attribution-corrections.md)
- `measured` [Horizontal-flat mip-0 surface blocks (2026-09-29)](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Pre-surface-block-loop control and PROFILE486 baseline (2026-09-28)](2026-09-29-alias-and-surface-block-experiments.md)

### surface-blocks

- `promoted` [`surf8` mip-0 fully-flat sixteen-row unroll: +0.000194333 FPS (+0.00114636%) on demo1, exact color/Z/PCX parity and complete strict release and qbench i486 gates](2026-11-12-surf8-mip0-fullyflat-unroll16-promoted.md)
- `promoted` [`surf8` mip-0 horizontal-flat eight-row block unroll: +0.000056 FPS (+0.0003315%) on demo1 and +0.000054 FPS (+0.0003391%) on demo3, exact color/Z parity and complete i486 gate](2026-11-11-surf8-mip0-horizontal-flat-unroll8-promoted.md)

- `promoted` [`surf8` mip-0 row lightdelta stack spill (2026-10-29) — strict mean **+0.000021 FPS (+0.0001288%)**, exact checksum parity and complete executable i486 gate](2026-10-29-surf8-mip0-lightdelta-stack-spill-promoted.md)

### surface-cache

- `rejected` [Surface-cache 6000 KB recheck (2026-11-02) — **+0.002110 FPS (+0.0129076%)** in DOSBox-X, rejected after 27 frame-checksum differences against two identical 2400 KB control streams](2026-11-02-surface-cache-6000-recheck-rejected.md)
- `promoted` [Surface-cache hit inline epilogue (2026-10-28) — **+0.000404667 FPS (+0.00249156%)**, exact checksum parity and full strict i486 audit](2026-10-28-surface-cache-hit-inline-return-promoted.md)
- `promoted` [Surface-cache style1 sentinel direct compare (2026-10-28) — **+0.000355 FPS (+0.00218581%)**, exact checksum parity and full strict i486 audit](2026-10-28-surface-cache-style1-direct-compare-promoted.md)
- `promoted` [Surface-cache style2 sentinel direct compare (2026-10-28) — **+0.000013 FPS (+0.00008004%)**, exact checksum parity and full strict i486 audit](2026-10-28-surface-cache-style2-direct-compare-promoted.md)
- `rejected` [`surf8` mip-1 8-row loop alignment screen (2026-10-27) — **−0.002048 FPS (−0.0127149%)**, exact checksum parity](2026-10-27-surf8-mip1-loop-alignment-screen-rejected.md)
- `rejected` [`surf8` mip-0 16-row loop alignment screen (2026-10-27) — **−0.001361 FPS (−0.0084497%)**, exact checksum parity](2026-10-27-surf8-mip0-loop-alignment-screen-rejected.md)
- `promoted` [Surface-cache key preparation/comparison fusion (2026-10-20) — **0.0400% faster** with exact checksum parity](2026-10-20-cache-key-fusion.md)
- `measured` [`D_CacheSurface` hit predicate (2026-10-06)](2026-10-06-surface-cache-parity-fix.md)
- `promoted` [The 1800 KB surface-cache wall does not exist (2026-09-29) — root-caused, and the latent win is promoted](2026-09-30-harness-fidelity-and-sourcing.md)
- `rejected` [E4, the surface-cache eviction churn (2026-09-29) — premise falsified before it was built, 0 of 8,886 reb...](2026-09-29-harness-and-cost-model.md)

### texture-spans

- `promoted` [`D_DrawSpans16` zero-T-step accumulator move (2026-11-11) — five-pair mean **+0.0000056 FPS (+0.000033%)**; exact color/Z/PCX parity and complete strict i486 gate, accepted under the current thresholdless rule](2026-11-11-span16-zero-tstep-accumulator-mov-reclassified-promoted.md)
- `superseded` [Initial noise-based rejection of the zero-T-step accumulator move; the recorded mean and samples are unchanged](2026-11-11-span16-zero-tstep-accumulator-mov-rejected.md)
- `promoted` [Span16 initial-span S/T product order (2026-11-04) — **+0.01084125 FPS (+0.07002%)** over four runs per variant, including one slow paired sample; exact parity and strict gate recorded](2026-11-04-span16-initial-span-product-order-promoted.md)
- `promoted` [Span16 full-segment endpoint conversion order (2026-11-04) — **+0.000007 FPS (+0.0000427%)**, exact fixed-step parity and complete strict i486 gate](2026-11-04-span16-segment-endpoint-order-promoted.md)
- `measured` [Span16 same-texel endpoint census (2026-11-03) — 0 of 2,059,043 full segments met the conservative endpoint condition; no fast path justified](2026-11-03-span16-same-texel-endpoint-census.md)
- `abandoned` [Span16 destination-aligned word stores (2026-11-02) — the initial byte-packing path differed on 969 of 970 frame records; corrected source was not revalidated](2026-11-02-span16-destination-aligned-word-stores-abandoned.md)
- `rejected` [Span16 linear row-major address delta (2026-11-02) — i486 audit passed, but 969 of 970 indexed framebuffer checksums differed; reverted](2026-11-02-span16-linear-address-delta-rejected.md)
- `measured` [Span16 adjacent same-row link census (2026-11-02) — only 2.1488% of texture spans have an adjacent same-row successor; no reuse candidate justified](2026-11-02-span16-same-row-link-census.md)
- `rejected` [Span16 no-row-cross specialization current-source recheck (2026-10-29) — three-run mean **−0.095470333 FPS (−0.584663%)**, 969-frame final checksum parity; strict ISA and frame-stream audits skipped](2026-10-29-span16-norowcross-current-recheck-rejected.md)
- `rejected` [Span16 same-row specialized path (2026-10-27) — strict mean **−0.091043334 FPS (−0.565237%)**, exact checksum parity and complete ISA audit](2026-10-27-span16-row-path-rejected.md)
- `rejected` [Span16 high-byte load before T-carry capture (2026-10-26) — repeat screen **−0.000014 FPS**, exact checksum parity; candidate restored](2026-10-26-span16-high-byte-load-before-tcarry-screen-rejected.md)
- `rejected` [`D_DrawSpans16` full segment loop 16-byte alignment (2026-10-26) — parity-screen mean **−0.011190334 FPS (−0.0702%)**, exact checksum parity](2026-10-26-span16-full-segment-align-screen-rejected.md)

- `rejected` [Span16 x87 T-result overlap schedule (2026-10-24) - **-0.000006844 FPS (-0.00004313%)**, exact checksum parity](2026-10-24-span16-x87-t-fistp-overlap-rejected.md)

- `promoted` [Span16 x87 T calculation after popping S (2026-10-24) - **+0.015692978 FPS (+0.09898219%)**, exact checksum parity](2026-10-24-span16-x87-pop-s-compute-t-promoted.md)

- `promoted` [Span16 x87 endpoint stores in stack order (2026-10-24) - **+0.015733684 FPS (+0.09933753%)**, exact checksum parity](2026-10-24-span16-fistp-stack-order-promoted.md)
- `promoted` [Fourteen-pixel turbulent-span base cache (2026-10-27) — **+0.012646 FPS (+0.078227%)**, exact checksum parity and full i486 ISA audit](2026-10-27-turbulent-span-fourteen-base-cache-promoted.md)
- `promoted` [Fold T-index scaling into the turbulent shift and mask (2026-10-27) — **+0.016066699 FPS (+0.099309%)**, exact checksum parity and full strict i486 audit](2026-10-27-turbulent-t-index-fuse-promoted.md)
- `rejected` [Turbulent S/T-step scheduling (2026-10-27) — **−0.000003331 FPS (−0.00002059%)**, exact checksum parity and full i486 audit](2026-10-27-turbulent-step-hoist-rejected.md)

- `rejected` [Thirteen-pixel turbulent span loop (2026-10-23) — **−0.000842667 FPS (−0.00539926%)**, exact checksum parity](2026-10-23-turbulent-span-thirteen-loop-rejected.md)
- `rejected` [Fifteen-pixel turbulent span loop (2026-10-23) — **−0.000736667 FPS (−0.00472009%)**, exact checksum parity](2026-10-23-turbulent-span-fifteen-loop-rejected.md)
- `promoted` [Fourteen-pixel turbulent span loop (2026-10-23) — **+0.000098 FPS (+0.00062793%)**, exact checksum parity](2026-10-23-turbulent-span-fourteen-loop-release-default.md)
- `rejected` [Eleven-pixel turbulent span loop (2026-10-27) — **−0.001009 FPS (−0.0062407%)**, exact checksum parity; strict ISA skipped after negative screen](2026-10-27-turbulent-span-eleven-loop-screen-rejected.md)
- `rejected` [Ten-pixel turbulent span loop (2026-10-27) — **−0.000220667 FPS (−0.0013649%)**, exact checksum parity; strict ISA skipped after negative screen](2026-10-27-turbulent-span-ten-loop-screen-rejected.md)
- `promoted` [Twelve-pixel turbulent span loop (2026-10-23) — **+0.000754 FPS (+0.00483141%)**, exact checksum parity](2026-10-23-turbulent-span-twelve-loop-release-default.md)
- `promoted` [Four-pixel turbulent span loop (2026-10-23) — **+0.001221667 FPS (+0.00783054%)**, exact checksum parity](2026-10-23-turbulent-span-quad-loop.md)
- `rejected` [Sixteen-pixel turbulent span loop (2026-10-23) — strict mean **−0.000582333 FPS (−0.00373%)**, exact checksum parity](2026-10-23-turbulent-span-sixteen-loop-rejected.md)
- `rejected` [Span16 endpoint `snext`/`tnext` reload interleave (2026-10-22) — strict mean **−0.000009667 FPS**](2026-10-22-span16-fistp-reload-interleave-rejected.md)
- `rejected` [Span16 T-step addition before B-half store 11 (2026-10-22) — strict mean **−0.000004333 FPS**](2026-10-22-span16-tstep-store11-overlap-rejected.md)
- `promoted` [Span16 T-step store after fractional add (2026-10-21) — positive strict mean **+0.000003000 FPS**](2026-10-21-span16-tstep-store-after-add-promoted.md)
- `rejected` [Span16 `advancetable` store after T-fraction add (2026-10-21) — negative mean **−0.000002000 FPS**](2026-10-21-span16-advancetable-store-after-tfrac-add-screen-rejected.md)
- `rejected` [Span16 S-step shift after T-carry (2026-10-21) — negative strict mean **−0.000005667 FPS**](2026-10-21-span16-sstep-shift-after-tcarry-rejected.md)
- `rejected` [Span16 S-step shift after `advancetable` store (2026-10-21) — negative screen mean **−0.000001333 FPS**](2026-10-21-span16-sstep-shift-after-advancetable-screen-rejected.md)
- `promoted` [Span16 S-step shift after T-step shift (2026-10-21) — positive strict mean **+0.000002000 FPS**](2026-10-21-span16-sstep-shift-after-tstep-shift-promoted.md)
- `rejected` [Span16 `sfracf` reload after T-step shift (2026-10-21) — negative screen mean **−0.000005000 FPS**](2026-10-21-span16-sfracf-after-tstep-shift-screen-rejected.md)
- `rejected` [Span16 S-first/store/T-shift setup permutation (2026-10-21) — negative screen mean **−0.000004667 FPS**](2026-10-21-span16-s-first-store-t-shift-screen-rejected.md)
- `rejected` [Span16 `sfracf` reload after both shifts (2026-10-21) — negative screen mean **−0.000006333 FPS**](2026-10-21-span16-sfracf-after-both-shifts-screen-rejected.md)
- `rejected` [Span16 `loadfirst` recheck after S-step shift promotion (2026-10-21) — negative screen mean **−0.000001000 FPS**](2026-10-21-span16-loadfirst-current-control-rejected.md)
- `rejected` [Span16 `advancetable` store after `sfracf` load (2026-10-21) — negative screen mean **−0.000000667 FPS**](2026-10-21-span16-advancetable-store-after-sfracf-screen-rejected.md)
- `measured` [`Texture-span load-first recheck (2026-10-20) — no repeatable gain; default remains control](2026-10-20-texture-span-loadfirst-recheck.md)
- `measured` [The general surface-block path is **6.85% of frame at 0.77 cycles per instruction**, and one instruction ...](2026-10-03-region-pricing-sweep.md)
- `measured` [The span16 per-segment setup is 2.37% of frame and contains no x87 at all — **`texture-spans` is re-opened**](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Four candidates the pool suggests, and why all four are dead](2026-10-02-edge-scan-and-texture-spans.md)
- `closed` [The unit-stride span premise is zero (2026-10-02) — `texture-spans` is closed, and the arithmetic says wh...](2026-10-02-surf8-bundle-and-promotion.md)
- `measured` [`d_mip_t16` as a constant table (2026-09-29) — landed; the promotion half was not attempted](2026-09-29-harness-and-cost-model.md)
- `measured` [Current texture-span follow-up (2026-09-29)](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Texture-span address-update experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Texture-span row-cross experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Texture-span load-order experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Texture-span tail-store experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)

### world-bsp

- `promoted` [World-BSP C walk retained as the i486 default (2026-11-11) — **+0.004096 FPS (+0.024255%)**, exact 970 color/Z records and frame 482 PCX, complete strict i486 gates](2026-11-11-bsp-walk-c-default-promoted.md)
- `rejected` [Brush-model splitter-plane entity-mixed hash (2026-11-07) — exactly the same 31,160 hits and 9,998 misses as the pointer-only hash; no additional transforms avoided](2026-11-07-bmodel-plane-entity-mixed-hash-rejected.md)
- `rejected` [Brush-model splitter-plane cache at 1,024 entries (2026-11-06) — same hit/miss totals as 512 entries, no extra transforms, +14,336 BSS bytes](2026-11-06-bmodel-plane-transform-cache1024-rejected.md)
- `rejected` [Brush-model clip endpoint-distance cache (2026-11-06) — strict i486 passed, but release color and Z differ at four frames; candidate removed](2026-11-06-bmodel-endpoint-distance-cache-rejected.md)
- `promoted` [Brush-model splitter-plane cache expanded to 512 entries (2026-11-06) — **+0.0022838%** matched mean, 1,051 fewer profile misses, exact output and strict i486 gate](2026-11-06-bmodel-plane-transform-cache512-promoted.md)
- `rejected` [BSP-node front/back face-order index (2026-11-06) — exact output and strict i486, but -0.386045% in matched mean FPS](2026-11-06-bsp-node-surface-order-rejected.md)
- `promoted` [Brush-model splitter-plane transform cache expanded to 256 entries (2026-11-06) — **+0.004928%** matched mean, 2,266 fewer profile misses, exact output and strict i486 gate](2026-11-06-bmodel-plane-transform-cache256-promoted.md)
- `rejected` [Brush-model splitter-plane cache generation tags (2026-11-06) — exact color/Z and strict i486; **−0.256%** matched mean FPS](2026-11-06-bmodel-plane-cache-generation-rejected.md)
- `rejected` [Brush-plane cache record layout and hash variants (2026-11-06) — packed records **−0.000713%**, XOR-folded hash **−0.004438%**; exact output and strict i486 gates passed](2026-11-06-bmodel-plane-cache-layout-and-hash-rejected.md)
- `rejected` [Brush-model splitter-plane victim cache (2026-11-06) — **−0.00896%** one-entry mean and **−0.02035%** four-entry mean; exact output and strict i486 gates passed](2026-11-06-bmodel-plane-victim-cache-rejected.md)
- `promoted` [Brush-model splitter-plane transform cache (2026-11-05) — **+0.01258%** matched mean, 64.88% profile hit rate, exact profile color/Z stream parity, complete strict i486 gate](2026-11-05-bmodel-plane-transform-cache-promoted.md)
- `promoted` [`R_RecursiveWorldNode_asm486` packed continuation state (2026-11-04) — **+0.000011 FPS (+0.0000672%)**, exact fixed-step parity and complete strict i486 gate](2026-11-04-bsp-walk-packed-continuation-state-promoted.md)
- `promoted` [`R_RecursiveWorldNode_asm486` frame-count snapshot (2026-11-03) — **+0.000021667 FPS (+0.0001325%)**, exact fixed-step parity and complete strict i486 gate](2026-11-03-bsp-framecount-snapshot-promoted.md)
- `promoted` [`R_RecursiveWorldNode` solid-node early cull before visibility lookup: **+0.000065333 FPS (+0.00041088%)**, exact checksum parity and complete i486 ISA gate](2026-10-24-bsp-walk-solid-first-check-promoted.md)
- `rejected` [`R_ScanEdges` fourteen-span alignment — **−0.000024 FPS (−0.00015383%)**, exact checksum parity](2026-10-22-scan-edges-clear-span14-alignment-rejected.md)
- `rejected` [Fifteen-span batches with grouped 8/4/2/1 tail for `R_ScanEdges` — **−0.000001 FPS (−0.00000641%)**, exact checksum parity](2026-10-22-scan-edges-clear-span-unroll15-rejected.md)
- `promoted` [Fourteen-span batches with grouped 8/4/2/1 tail for `R_ScanEdges` — **+0.000015 FPS (+0.00009615%)**, exact checksum parity](2026-10-22-scan-edges-clear-span-unroll14-group-tail-promoted.md)
- `rejected` [Thirteen-span batches with grouped 8/4/2/1 tail for `R_ScanEdges` — **−0.000000333 FPS (−0.00000214%)**, exact checksum parity](2026-10-22-scan-edges-clear-span-unroll13-group-tail-rejected.md)
- `rejected` [Fourteen-span clear loop reusing zeroed `ECX` for stores — **−0.000013667 FPS (−0.00008759%)**, exact checksum parity](2026-10-22-scan-edges-clear-span14-zero-register-rejected.md)
- `promoted` [Twelve-span batches with grouped 8/4/2/1 tail for `R_ScanEdges` — **+0.000008333 FPS (+0.00005341%)**, exact checksum parity](2026-10-22-scan-edges-clear-span-unroll12-group-tail-promoted.md)
- `promoted` [Grouped 4/2/1 tail for eight-span `R_ScanEdges` clearing — **+0.000007 FPS (+0.00004487%)**, exact checksum parity](2026-10-22-scan-edges-clear-span-unroll8-group-tail-promoted.md)
- `rejected` [Sixteen-span unrolling in `R_ScanEdges` span clearing — **−0.015811333 FPS (−0.10134649%)**; one slow run remains in the mean](2026-10-22-scan-edges-clear-span-unroll16-rejected.md)
- `promoted` [Eight-span unrolling in `R_ScanEdges` span clearing — **+0.000033 FPS (+0.00021152%)**, exact checksum parity](2026-10-22-scan-edges-clear-span-unroll8-promoted.md)
- `promoted` [Four-span unrolling in `R_ScanEdges` span clearing — **+0.000099 FPS (+0.00063457%)**, exact checksum parity](2026-10-22-scan-edges-clear-span-unroll4-promoted.md)
- `promoted` [Two-span unrolling in `R_ScanEdges` span clearing — **+0.000101667 FPS (+0.00065167%)**, exact checksum parity](2026-10-22-scan-edges-clear-span-unroll2-promoted.md)
- `promoted` [Bottom-tested `R_ScanEdges` span clearing — **+0.000087667 FPS (+0.00056193%)**, exact checksum parity](2026-10-22-scan-edges-clear-span-bottom-tested-promoted.md)
- `rejected` [Move the fourth `R_StepActiveU` successor load between compare and branch — **-0.000002333 FPS (-0.00001496%)**](2026-10-22-edge-step-fourth-successor-load-after-compare-rejected.md)
- `rejected` [Move the fourth `R_StepActiveU` successor load after the U store — **-0.000016333 FPS (-0.00010469%)**](2026-10-22-edge-step-fourth-successor-load-after-store-rejected.md)
- `rejected` [Move the fourth `R_StepActiveU` successor load between U fetch and add — **-0.000014 FPS (-0.00008974%)**](2026-10-22-edge-step-fourth-successor-load-between-u-add-rejected.md)
- `rejected` [Move the fourth `R_StepActiveU` successor load before the U calculation — **-0.000008667 FPS (-0.00005555%)**](2026-10-22-edge-step-fourth-successor-load-early-rejected.md)
- `rejected` [Preload the third `R_StepActiveU` successor before the order test — **-0.000419 FPS (-0.00268574%)**](2026-10-22-edge-step-third-successor-prefetch-rejected.md)
- `rejected` [Preload the second `R_StepActiveU` successor before the order test — **-0.000378 FPS (-0.00242293%)**](2026-10-22-edge-step-second-successor-prefetch-rejected.md)
- `rejected` [Preload the first `R_StepActiveU` successor before the order test — **-0.000579333 FPS (-0.00371345%)**](2026-10-22-edge-step-successor-prefetch-rejected.md)
- `rejected` [Fourth-probe early-out before successor load in legacy edge insertion — **-0.038651333 FPS (-0.24774998%)**](2026-10-22-edge-insert-probe4-earlyout-rejected.md)
- `rejected` [Cache the `max_span_p` comparison in a stack local — strict mean **-0.000010 FPS (-0.00006410%)**](2026-10-22-scan-edges-maxspan-local-cache-rejected.md)
- `promoted` [Cache `surfaces` in `EDI` and keep the row bound local — **+0.001120 FPS (+0.00717957%)** with exact checksum parity](2026-10-22-scan-edges-surface-base-cache-promoted.md)
- `promoted` [Cache `pdrawfunc` in `ESI` across scanlines — **+0.001084333 FPS (+0.00695142%)** with exact checksum parity](2026-10-22-scan-edges-callback-cache-promoted.md)
- `rejected` [Final-scan `TEST` removal — strict mean **−0.038481667 FPS**](2026-10-22-edge-drawing-final-scan-test-rejected.md)
- `promoted` [Cache edge-drawing `r_dspeeds` truth in `EBX` — **+0.000105667 FPS (+0.00067741%)** with exact checksum parity](2026-10-22-edge-drawing-dspeeds-cache-promoted.md)
- `promoted` [Integer `r_dspeeds` truth check in edge-drawing assembly — **+0.000168667 FPS (+0.00108130%)** with exact checksum parity](2026-10-22-edge-drawing-dspeeds-integer-truth-promoted.md)
- `promoted` [Legacy edge-list maintenance retained as the i486 default (2026-10-22) — **+0.21977%** versus replacement assembly](2026-10-22-edge-list-legacy-default-promoted.md)
- `promoted` [Edge-list target-U load caching in the replacement i486 assembly (2026-10-22) — **+0.0596%** within `asm`; legacy selector remains faster](2026-10-22-edge-list-target-u-cache-promoted.md)
- `measured` [`Selector-set frame performance and BSP call removal (2026-10-06)`](2026-10-06-renderer-selector-benchmarks.md)
- `in progress` [`R_RecursiveClipBPoly` now has a selectable i486 assembly entry](2026-10-05-bmodel-polygon-clip-assembly-port.md)
- `in progress` [`demo1` wall leak traced to the split fraction and fixed](2026-10-05-bmodel-polygon-clip-assembly-port.md)
- `in progress` [Edge-list maintenance now has explicit implementation choices](2026-10-05-edge-list-maintenance-assembly-port.md)
- `in progress` [Remaining active-edge maintenance closure](2026-10-05-edge-list-maintenance-assembly-port.md)
- `in progress` [`R_ScanEdges` now has a selectable i486 assembly entry](2026-10-05-scan-edges-assembly-port.md)
- `in progress` [Remaining edge-scan closure](2026-10-05-scan-edges-assembly-port.md)
- `in progress` [`R_EdgeDrawing` now has a selectable i486 assembly entry](2026-10-05-edge-drawing-assembly-port.md)
- `in progress` [Remaining edge-drawing closure](2026-10-05-edge-drawing-assembly-port.md)
- `in progress` [`R_DrawSubmodelPolygons` now has a selectable i486 assembly entry](2026-10-05-submodel-polygons-assembly-port.md)
- `in progress` [Remaining submodel-polygon closure](2026-10-05-submodel-polygons-assembly-port.md)
- `in progress` [`R_StoreEfrags` now has a selectable i486 assembly entry](2026-10-05-efrag-store-assembly-port.md)
- `in progress` [`R_RenderWorld` now has a selectable i486 assembly entry](2026-10-05-render-world-assembly-port.md)
- `in progress` [Remaining active world-renderer closure](2026-10-05-render-world-assembly-port.md)
- `in progress` [`R_RecursiveWorldNode` now has a selectable assembly walk](2026-10-05-world-bsp-assembly-port.md)
- `measured` [The bmodel frustum `FIXME` (2026-09-29) — premise measured, ceiling is two orders of magnitude short, do ...](2026-09-29-harness-and-cost-model.md)
- `measured` [`world-bsp` decomposed (2026-10-01) — it was never the BSP walk; 85% of it is per-face edge setup](2026-10-01-attribution-corrections.md)
- `measured` [World-BSP frame-count cache experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)

### z-spans

- `opt-in` [`D_DrawZSpans` no-FXCH start schedule (2026-10-31) — historical **+0.011660 FPS (+0.0714%)**; now opt-in because of 37 changed frame-99 pixels and the later artifact report; default is pixel-exact control](2026-10-31-zspan-no-fxch-promoted-and-renderface-no-clip-rejected.md)
- `rejected` [`D_DrawZSpans` second-step scheduling within SHLD/ROR recheck (2026-11-02) — ten current-source candidate runs produced no repeatable gain; pooled median **−0.000006 FPS (−0.0000367%)**, exact checksum/event traces, and full i486 audit](2026-11-02-zspan-pair-add-schedule-recheck-rejected.md)
- `corrected` [Z-span x87 latency projection (2026-10-30) — 80 cycles/span is a no-overlap sum, not net runtime or an attainable ceiling](2026-10-30-zspan-x87-overlap-model-correction.md)
- `rejected` [D_DrawZSpans negative-gradient nonnegative pair store with STOSL (2026-10-27 current-source recheck) — **−0.000004667 FPS (−0.0000290%)**, exact checksum parity and complete ISA audit](2026-10-27-zspan-negative-gradient-stosl-current-recheck-rejected.md)
- `rejected` [D_DrawZSpans positive-gradient cutoff 20 recheck (2026-10-27) — **−0.000657334 FPS (−0.004082%)**, exact checksum parity and complete ISA audit](2026-10-27-zspan-cutoff20-recheck-rejected.md)
- `rejected` [D_DrawZSpans negative-depth subtract-pair STOSL (2026-10-26) — repeat screen **−0.000009 FPS**, exact checksum parity; candidate restored](2026-10-26-zspan-negative-depth-sub-stosl-screen-rejected.md)
- `promoted` [D_DrawZSpans general subtract-pair store with STOSL (2026-10-26) — **+0.000005 FPS**, exact checksum parity and strict i486 pass](2026-10-26-zspan-sub-pair-stosl-promoted.md)
- `promoted` [D_DrawZSpans negative-depth add-pair store with STOSL (2026-10-26) — **+0.000008 FPS (+0.0000497%)**, exact checksum parity and strict i486 pass](2026-10-26-zspan-negative-depth-add-stosl-promoted.md)
- `promoted` [D_DrawZSpans general positive-sample pair store with STOSL (2026-10-26) — **+0.021634 FPS (+0.1345%)**, exact checksum parity and strict i486 pass](2026-10-26-zspan-general-add-pair-stosl-promoted.md)
- `rejected` [D_DrawZSpans negative-gradient nonnegative pair store with STOSL (2026-10-26) — **−0.000002333 FPS**, exact checksum parity and strict i486 pass](2026-10-26-zspan-negative-gradient-stosl-strict-rejected.md)
- `promoted` [D_DrawZSpans nonnegative pair store with STOSL (2026-10-26) — **+0.137316 FPS (+0.861%)**, exact checksum parity](2026-10-26-zspan-nonnegative-stosl-promoted.md)

- `promoted` [`D_DrawZSpans` second-step scheduling within SHLD/ROR (2026-10-24) — **+0.000007000 FPS (+0.00004423%)**, exact checksum parity](2026-10-24-zspan-nonnegative-step-between-shld-ror-promoted.md)
- `promoted` [`D_DrawZSpans` positive-gradient cutoff lowered to 21 pixels (2026-10-24) — **+0.000339480 FPS (+0.00214342%)**, exact checksum parity](2026-10-24-zspan-positive-cutoff21-promoted.md)
- `promoted` [`D_DrawZSpans` negative-gradient cutoff lowered to 21 pixels (2026-10-24) — **+0.000003020 FPS (+0.00001907%)**, exact checksum parity](2026-10-24-zspan-negative-cutoff21-promoted.md)
- `rejected` [`D_DrawZSpans` negative-gradient endpoint sign-check removal (2026-10-24) — **−0.000005350 FPS (−0.00003378%)**, exact checksum parity and strict ISA pass](2026-10-24-zspan-negative-endpoint-sign-check-rejected.md)
- `rejected` [`D_DrawZSpans` negative-depth second-step scheduling within SHLD/ROR (2026-10-24) — **−0.000004334 FPS (−0.00002739%)** on the fresh paired recheck, exact checksum parity](2026-10-24-zspan-negative-depth-step-overlap-rejected.md)
- `rejected` [`D_DrawZSpans` 32-pixel loop alignment (2026-10-24) — **−0.003227667 FPS (−0.02039622%)**, exact checksum parity](2026-10-24-zspan-nonnegative-group32-alignment-rejected.md)
- `rejected` [`D_DrawZSpans` 40-pixel main-loop group (2026-10-24) — **−0.051709000 FPS (−0.32676%)**, exact checksum parity](2026-10-24-zspan-nonnegative-group40-rejected.md)
- `rejected` [`D_DrawZSpans` 48-pixel main-loop group (2026-10-24) — **−0.009817667 FPS (−0.06204%)**, exact checksum parity](2026-10-24-zspan-nonnegative-group48-rejected.md)
- `rejected` [`D_DrawZSpans` 24-pixel main-loop group (2026-10-24) — **−0.014731333 FPS (−0.09309%)**, exact checksum parity](2026-10-24-zspan-nonnegative-group24-screen-rejected.md)
- `rejected` [`D_DrawZSpans` first step before sign branch (2026-10-22) — strict mean **−0.000014 FPS**](2026-10-22-zspan-step-before-sign-branch-rejected.md)
- `rejected` [`D_DrawZSpans` U-coordinate load before origin add (2026-10-22) — strict mean **−0.000011667 FPS**](2026-10-22-zspan-u-load-before-origin-add-rejected.md)
- `rejected` [`D_DrawZSpans` second step between SHLD and ROR (2026-10-21) — strict mean **−0.000002667 FPS**](2026-10-21-zspan-step-between-shld-ror-screen-rejected.md)
- `rejected` [`D_DrawZSpans` sign check before accumulator copy (2026-10-21) — strict mean **−0.000004667 FPS**](2026-10-21-zspan-sign-check-before-copy-screen-rejected.md)
- `promoted` [`D_DrawZSpans` second-step scheduling before packed store (2026-10-21) — positive pooled mean; one control outlier noted](2026-10-21-zspan-step-before-store-promoted.md)
- `promoted` [`D_DrawZSpans` 16-pixel middle-loop unroll (2026-10-20) — **0.0792% faster** across nine strict candidate samples](2026-10-20-zspan-middle-unroll16.md)
- `measured` [`D_DrawZSpans` -> exact i486 assembly parity (2026-10-10)](2026-10-10-d-drawzspans-assembly-parity.md)
- `measured` [117 exact C/assembly guarded depth-buffer cases, including negative background depth](2026-10-10-d-drawzspans-assembly-parity.md)
- `measured` [Complete linked i486 audit with zero violations or exemptions](2026-10-10-d-drawzspans-assembly-parity.md)
- `measured` [`z-spans` is the last unpriced region above 2%: **42,031,372 pixels, 3 instructions each, at 1.24 cycles ...](2026-10-03-region-pricing-sweep.md)
- `rejected` [Precomputed `izistep` for the Z-span prologue (2026-09-29) — rejected, and the estimate was wrong in the ...](2026-09-29-harness-and-cost-model.md)
- `rejected` [Z-span x87 prologue (2026-09-29) — measured, and the idea does not survive](2026-09-29-harness-and-cost-model.md)

## Sourced from `BUILD-DOS.md`

These three files were results sitting inside the operational build reference. Each
section below moved verbatim.

### [2026-09-29-offline-precomputation-pass.md](2026-09-29-offline-precomputation-pass.md)

- `Offline precomputation pass (2026-09-29) — one rejection, one cleanup, one closure`
- `Latest PROFILE486 and texture-span STOSW experiment (2026-09-29)`

### [timedemo-baseline-history.md](timedemo-baseline-history.md)

- `Lightmap style accumulation`
- `VGA full-frame copy experiment`
- `Surface-cache capacity and churn`
- `Surface-cache header locality experiment`
- `Lazy viewspantable rebuild`
- `Measured texture-span change`

### [microbenchmark-results.md](microbenchmark-results.md)

- `Memory helper experiment result`
- `Runtime memory-helper result`
- `Texture-axis cache probe result`
- `Surface-cache predicate result`
- `Mip-level selector result`
- `Turbulent-span inner-loop result`
- `Alias-project projection result`
- `Texture-animation frame-selection result`
- `Lightmap normalization result`
- `BSP plane-dot result`
- `BSP frustum-clipping result`
- `BSP frustum-clipping unrolled assembly follow-up (2026-10-16)`
- `Alias bounding-box projection result`
- `Clipped alias vertex transform result`
- `Rejected negative-gradient Z-span unroll`
- [Alias transform indexed integer-coordinate loads (2026-10-23)](2026-10-23-alias-transform-integer-coordinate-table-promoted.md)
- [Alias transform 16-bit coordinate table (2026-10-23)](2026-10-23-alias-transform-u16-coordinate-table-promoted.md)
- [Alias transform early normal-index scale (2026-10-23)](2026-10-23-alias-transform-normal-index-hoist-promoted.md)
- [Surface-cache unused style lookup removal (2026-10-28)](2026-10-28-surface-cache-unused-style-lookup-promoted.md)
- [Surface-cache second style sentinel check (2026-10-28) — **+0.000082 FPS (+0.000505%)**, exact checksum parity and full i486 audit](2026-10-28-surface-cache-style2-sentinel-promoted.md)
