# Z-span second-step scheduling promoted (2026-10-21)

Status: promoted in `src/d_draw.s` under the positive pooled-mean performance
rule. In the 16-pixel middle-loop macros, the second Z-accumulator step now
runs immediately before the packed framebuffer store, after `ZPACK16`. This
overlaps independent integer arithmetic with the memory write. The change
covers `ZSPAN_ADD_PAIR`, `ZSPAN_ADD_NEGATIVE_PAIR`, `ZSPAN_SUB_PAIR`, and
`ZSPAN_SUB_NEGATIVE_PAIR`; the rendered pixel and depth values are unchanged.

The comparison used three alternating control/candidate pairs on the pinned
DOSBox-X 2026.08.31 i486 `demo1` profile, with per-frame FPS collection
disabled. Each run completed 969 frames and produced framebuffer checksum
`1047377823`.

| Pair | Control seconds | Control FPS | Candidate seconds | Candidate FPS | Paired delta |
|---:|---:|---:|---:|---:|---:|
| 1 | 62.366075 | 15.537294 | 62.366064 | 15.537296 | +0.000002 FPS |
| 2 | 62.822924 | 15.424306 | 62.366081 | 15.537292 | +0.112986 FPS |
| 3 | 62.366094 | 15.537289 | 62.366016 | 15.537308 | +0.000019 FPS |

Across all three pairs, control averaged **15.499629667 FPS** and the candidate
averaged **15.537298667 FPS**, a positive pooled delta of **+0.037669 FPS
(+0.2430316%)**. The pair-2 control sample at 15.424306 FPS is a clear outlier
and drives most of the pooled delta. Excluding that pair for diagnostic
context, the other two pairs average **15.5372915 FPS** for control and
**15.537302 FPS** for the candidate (**+0.0000105 FPS, +0.0000676%**). All
samples remain in the promotion average; the smaller two-pair result shows
that the causal gain size is uncertain. The positive full pooled mean
qualifies under the current rule.

The measured A/B control executable SHA-256 is
`5F7D255C0E6E19CEAF1E3B755C3FBAB3CC6389ED33F53AF86D9364A48C7A69D8`; the
candidate diagnostic executable SHA-256 is
`F92F13D8A202651C22E5CDA506B0B9243AF0B9EAE3A9F51B265F47F5543EB500`. The
AB summary and metadata are in
`out/zspan-add-before-store-ab-20261021/`.

The strict i486 build passed a complete linked audit: 313,316 instructions
across 435 executable ranges, with zero above-i486, unknown, or exempt
instructions. The measured diagnostic candidate skipped its own audit; this
separate strict build audited the promoted source and its exact output directly.
The strict executable SHA-256 is
`5344A07F7A6B3DD20CEA35A1359EA79F0570987786F5166D1641B0FC89E02376`.
A direct run of that strict binary completed at **15.537298 FPS**, 969 frames,
checksum `1047377823`, and audit status `PASS`. The strict manifest is
`out/local-zspan-add-before-store-strict-20261021/build-manifest-bench.json`;
the runtime parity result is
`out/zspan-add-before-store-strict-parity-20261021/parity.json`.

The pinned profile template SHA-256 is
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
