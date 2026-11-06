# Whole-model alias tile anchor early-out promoted (2026-11-06)

## Candidate

`R_AliasModelOccluded` now samples the top-left Z value when it first visits a
fully in-viewport, uncached 4-by-4 tile. If that anchor depth is less than or
equal to the model's conservative nearest depth, one pixel is enough to prove
that the tile cannot occlude the model, so the query returns without reading
the other fifteen values.

The existing signed-short tile-min array stores this partial anchor using the
sign bit as `-(anchor + 1)`. Later queries reuse the anchor while it still
proves the tile cannot occlude. If a model is nearer than the anchor, the code
reads the rest of the tile and replaces the partial value with the complete
minimum. Negative Z values and tiles cut by the viewport continue to disable
rejection. Since entity depth writes only increase Z, both the saved anchor and
the complete tile minimum remain conservative lower bounds for the frame.

The existing 8-bit epoch array and 4-by-4 layout are unchanged. This adds no
cache memory: the 4,000 signed-short minima still use 8 KB and the epoch tags
use 4 KB.

## Output parity and profile

The fixed-step PROFILE486 replay at `out/dos-timedemo-20261106-115558` recorded
4,503 occlusion queries, 1,627 model culls, 36,940 tile checks, and 530,082 Z
samples. It retained the same cull count and avoided 37,470 Z reads, a 6.6020%
reduction from the prior 567,552-sample profile.

The candidate color and Z checksum files and captured frame 482 PCX match the
control at
`out/worktree-bsp-face-ranges-control-20261106/out/dos-timedemo-20261106-113751`.
Their SHA-256 values are:

| Output | SHA-256 |
| --- | --- |
| Color checksum stream | `3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B` |
| Z checksum stream | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |
| Frame 482 PCX | `31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213` |

The candidate release replay at `out/dos-timedemo-20261106-121111` rendered
969 timed frames and ended at framebuffer checksum `1047377823`.

## Strict i486 audit

The strict release gate passed with 315,256 verified instructions across 435
source-bound CODE ranges, 529 startup CODE rows, and 9,207 DPMI-provider
instructions. It found zero above-i486, unknown, exempt, undecoded, or
non-instruction bytes. All 403 source proofs (168 project and 235 runtime
objects) matched exactly. The audit result is PASS.

## Matched release timing

The control source is `f3804dc`; its renderer sources match the candidate base
before this change. Both variants used DOSBox-X 2026.08.31, the 320-by-200
`demo1` workload, `cputype=486`, and profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Neither
timing run used frame-FPS instrumentation.

The control and candidate source fingerprints are
`ADDDB187EEC6EE7C758906016A91C2409DC68373CE167431445B3695629FCE68` and
`01B6BC3262B39756B02FFAF529E76A9725725EC7FBF4AC7DDA26C302C776AC88`.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Control | 16.751569, 16.751619, 16.751617 | 16.751601667 |
| Anchor early-out | 16.755720, 16.755707, 16.755697 | 16.755708000 |

The candidate mean is **0.0245131% faster**. Every candidate sample exceeded
every control sample; the smallest gap was 0.004078 FPS. The highest recorded
candidate sample is 16.755720 FPS. Timing artifacts are in
`out/worktree-bsp-face-ranges-control-20261106/out/dos-timedemo-20261106-113119`
and `out/dos-timedemo-20261106-121337`. This is DOSBox-X evidence, not a claim
about performance on physical 486 hardware.

## Rendering test suite

`rtk python tools/test-rendering.py` ran 112 tests: 107 passed and five failed.
The same five failures occurred at the clean control revision `f3804dc`:

- Alias stats and linegraph fixtures expect 122 selectors but contain 140.
- The smoke-runner fixture does not expose `VideoUpdateImplementation`.
- The sprite face-clipping assembly fixture expects a `testb` instruction
  absent from the current reference assembly.
- The timegraph fixture expects 122 selectors but contains 140.

The deterministic DOSBox parity checks, strict release build and audit, and
three-run release timing completed successfully for this candidate.
