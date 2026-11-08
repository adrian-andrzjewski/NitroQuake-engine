# Alias line-scan biased bounds checks promoted (2026-11-07)

## Change

`D_PolysetSetUpForLineScan_asm486` biases each signed delta by 31 and uses
an unsigned comparison against 63 to recognize the original `[-31,32]`
table domain. The biased values are reused to form the table index. The
common table path removes two comparisons/branches and two repeated address
calculations. An out-of-range vertical delta restores the original horizontal
delta before entering the unchanged long-edge path. Signed extremes and the
`INT_MIN` C fallback retain their original behavior.

The qualified assembly source was copied byte-for-byte into the primary
worktree. The version/build-number changes were preserved. Both variants in
the final comparison included the same versioning and benchmark-clock code.

## Correctness and replay clock

The focused native C/assembly line-scan test passed **16,416 cases across four
x87 rounding modes with zero mismatches**. The final report is
`out/worktree-alias-linescan-bounds-20261107/out/dos-bench-20261107-163458/bench-result.json`.

An ordinary-clock comparison varied at frames 727-731. Setting only
`host_framerate` stabilized that window but a later repeat varied in color at
frames 73-75, with identical depth records. A frame-74 diagnostic reproduced
the unexpected checksum `485206324` by removing the pickup notification. The
756 changed pixels were confined to x=10..231, y=1..7; the world and depth
buffer matched. This diagnostic identified presentation-time notification
expiry; it was not used as a promotion replay.

The benchmark-only `-parityclock` now advances both simulation and presentation
time by an exact 1/16 second from the first host frame. Notifications and HUD
animation remain active. It requires `-framechecksums` and `-timedemoexit`.
The runner rejects FPS statistics in this mode, marks reports as parity-only,
and writes `medianFps: null`. The clock is absent from normal game code, as
verified in the retained compiler listing. Ordinary timing uses the original
clock with this option disabled.

Two control and two candidate full-clock replays match **all 970 color records,
all 970 depth records, and the complete frame-154 PCX**, byte-for-byte. No
frames were excluded. All four completed 969 timed frames with the expected
final framebuffer checksum `1047377823`.

| Output | Shared SHA-256 |
| --- | --- |
| Color stream | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Depth stream | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 154 PCX | `2859081411D55AE034030CD26E741127C69CE027DB81BCA0357046AEF8D5CB5B` |

Control replay: `out/dos-timedemo-20261107-163041/`.
Candidate replay:
`out/worktree-alias-linescan-bounds-20261107/out/dos-timedemo-20261107-163509/`.

## Strict i486 builds

The complete source-bound executable gate passed for the control benchmark
(315,244 instructions), candidate benchmark (315,248), and normal game
(163,518). Each also passed 529 startup rows, 9,207 provider instructions,
and all 403 project/runtime source proofs. All above-i486, unknown, and exempt
counts were zero.

The normal game is `NitroQuake v0.999+7`; its console runtime check passed at
`out/linescan-clock-normal-console-20261107-172736/version-result.json`.

## Matched uninstrumented timing

Both variants used DOSBox-X 2026.08.31, the pinned 320x200 `demo1` workload,
CWSDPMI, and profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Replay-clock mode, frame/depth checksums, FPS statistics, and instrumentation
were disabled for these measurements. All six runs completed 969 frames and
ended at framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean FPS | FPS spread |
| --- | --- | ---: | ---: |
| Control | 16.816101, 16.816080, 16.816062 | 16.816081000 | 0.000039 |
| Biased bounds | 16.823960, 16.823956, 16.823951 | 16.823955667 | 0.000009 |

The candidate improved mean FPS by **0.0468282%**. Every candidate sample was
faster than every control sample. This is a small DOSBox-X gain, not a
physical-486 FPS claim.

Control timing: `out/dos-timedemo-20261107-163906/timedemo-result.json`.
Candidate timing:
`out/worktree-alias-linescan-bounds-20261107/out/dos-timedemo-20261107-164230/timedemo-result.json`.

## Artifacts and disposition

Promote under the positive pooled-mean rule, exact output gate, and strict ISA
gate. The compiled normal game is retained under
`out/worktree-alias-linescan-bounds-20261107/out/local-linescan-clock-normal/`.
Its executable and CWSDPMI are also copied, with hash/provenance metadata, to
`out/accepted-linescan-bounds/`.

The complete timing/parity/build verification is retained in
`out/worktree-alias-linescan-bounds-20261107/out/integrated-promotion-evidence.json`;
`verify-promotion.py` and `verify-clock-replays.py` beside it check the underlying
reports and files. Earlier variable-clock and fixed-simulation-only evidence is
retained as diagnostic history and was not substituted for the final gates.
