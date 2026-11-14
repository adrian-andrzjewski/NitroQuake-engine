# Span16 perspective arithmetic trials rejected (2026-10-31)

Status: no candidate is retained. `src/renderer/d_draw16.s` is restored to the
original implementation (SHA-256
`5626ABAF985B74F8EC2C1632164942A8C3CAA9B719DEA0FBF675C0B60F7A463A`).

All three trials targeted the per-segment perspective arithmetic in
`D_DrawSpans16`. They were built and checked for genuine i486 instruction
compatibility, but correctness and the timedemo measurements reject them.

## Shared benchmark profile

The deterministic captures used DOSBox-X 2026.08.31, `cputype=486`, fixed
33,445 cycles, 320x200 `-stdvid`, `demo1`, and the pinned profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).
Parity captures used `host_framerate 0.0783`. Timed FPS runs were uninstrumented
and used three runs per variant.

## Reuse the reciprocal when horizontal inverse depth is zero

The candidate detected `zi16stepu == 0` and reused the x87 result of
`64k / zi` across adjacent segments while still updating `s/z` and `t/z`.
This was intended to remove repeated divisions when the segment reciprocal
could be shared.

The three candidate runs measured 16.213299, 16.213306, and 16.213301 FPS
(mean 16.213302). The fresh control measured 16.339194, 16.339194, and
16.339183 FPS (mean 16.339190333). The candidate was **0.7705% slower**.

The candidate's deterministic run matched itself but its per-frame checksum
stream differed from the control at frames 509, 666, and 706, although the
final checksum remained `1047377823`. A frame-509 capture comparison found
500 changed palette pixels, all in the transient “You Got the Rockets”
message. This observation does not explain the other stream differences, so
the candidate did not pass exact frame parity. The slowdown independently
rejects it.

The strict i486 audit passed: 314,357 linked instructions, zero above-i486,
unknown, or exempt instructions; 403 exact source/object proofs, 529 startup
code rows, and 9,207 DPMI-provider instructions.

Artifacts:

- Control timing: `out/dos-timedemo-20261030-233234/timedemo-result.json`
- Candidate timing: `out/dos-timedemo-20261031-000643/timedemo-result.json`
- Deterministic candidate runs: `out/dos-timedemo-20261030-235825/` and
  `out/dos-timedemo-20261031-000041/`
- Frame-509 control capture: `out/dos-timedemo-20261031-000236/`
- Strict build and audit: `out/local-i486-zerozi-reuse-strict-20261031/`

## Move FDIV to the top of the x87 stack

The second candidate replaced the initial `flds` / `fxch` / `fadds` / `fdivr`
sequence with `fadds` / `flds` / `fdiv`, then removed two following `fxch`
instructions in the segment setup paths. The intent was to avoid x87 stack
exchanges around the division.

Its strict i486 audit passed: 314,330 linked instructions, zero above-i486,
unknown, or exempt instructions; 403 exact source/object proofs, 529 startup
code rows, and 9,207 DPMI-provider instructions. However, the deterministic
run rendered 969 frames and ended at checksum `898929148`, against the
expected `1047377823`. The frame-169 capture shows conspicuous texture
banding and missing texture regions. This candidate failed rendering parity;
no FPS result from it is valid or reported.

Artifacts:

- Candidate capture: `out/dos-timedemo-20261031-003110/runs/run-01/frame.pcx`
- Control capture: `out/dos-timedemo-20261030-233611/runs/run-01/frame.pcx`
- Strict build and audit: `out/local-i486-fdiv-top-placement-strict-20261031/`

## Direct S/T stack-slot updates

The third candidate replaced the pair of `FXCH ST(2)` instructions around the
S-step add in both full-segment setup paths with `flds sdivz16stepu` and
`faddp ST(0),ST(3)`. The S and T updates remained in the same order, and the
x87 division sequence was unchanged. The candidate was reverted.

The strict i486 audit passed 314,346 linked instructions with zero
above-i486, unknown, or exempt instructions. The 403 exact object proofs,
529 startup code rows, and 9,207 DPMI-provider instructions also passed.

The valid parity runs used `-stdvid`, `host_framerate 0.0783`, and the same
320x200 profile. An initial capture omitted `-stdvid` and was excluded. On the
valid full frame stream, the candidate differed from two control captures at
frames 270 and 412; the two control captures matched each other. The final
framebuffer checksum and event trace still matched. A direct frame-169 PCX
comparison found 0 changed palette pixels of 64,000 and identical palettes.
At frame 270, 701 indexed pixels changed, all within rows 2 through 15 where
the transient pickup message appears; the rest of that image was identical.
The candidate showed “You Got the Rockets” while the control showed “You Got
the Nailgun.” At frame 412, 412 indexed pixels changed, all within rows 1
through 7, again only in the transient pickup message; the candidate showed
“You Got the Nails” while the control had no message. The palette was identical
in both comparisons. Because the candidate changes frame output and the full
stream is not pixel-exact, it does not qualify for promotion.

The three timed candidate samples were 16.356170, 16.229343, and 16.356161
FPS (mean 16.313891333, median 16.356161). The control samples were 16.339194,
16.339194, and 16.339183 FPS (mean 16.339190333, median 16.339194). The
candidate mean was **0.025299 FPS slower (-0.15484%)**; its 0.126827 FPS sample
spread also makes the positive median insufficient evidence of a repeatable
gain.

Artifacts:

- Candidate timing: `out/dos-timedemo-20261031-005749/timedemo-result.json`
- Candidate frame-169 capture: `out/dos-timedemo-20261031-005537/runs/run-01/frame.pcx`
- Control frame-169 capture: `out/dos-timedemo-20261030-233611/runs/run-01/frame.pcx`
- Candidate frame-270 capture: `out/dos-timedemo-20261031-010255/runs/run-01/frame.pcx`
- Control frame-270 capture: `out/dos-timedemo-20261031-010433/runs/run-01/frame.pcx`
- Candidate frame-412 capture: `out/dos-timedemo-20261031-010837/runs/run-01/frame.pcx`
- Control frame-412 capture: `out/dos-timedemo-20261031-011014/runs/run-01/frame.pcx`
- Strict build and audit: `out/local-span16-stack-step-add-test-20261031/`

## Result

No perspective-arithmetic optimization from these trials is retained. Strict
ISA compatibility alone is insufficient: reciprocal reuse was slower and
changed intermediate-frame output, changing the x87 division stack order broke
texture rendering, and direct stack-slot updates changed transient frame
output without a repeatable speed gain. Keep the restored implementation as
the comparison baseline for any later experiment.

The remaining reciprocal is already shared by the S and T endpoint
calculations, and the full-segment path launches its next divide before the
second eight-pixel store group. The ordinary integer setup does not wait for
that divide. Reusing a reciprocal requires a zero-step special case, which was
slower; replacing it with a lookup or Newton approximation would alter the
rounded endpoint values unless guarded by an exact fallback. That fallback
would add work to a divide already overlapped with pixel stores. No such
approximation has demonstrated a correct positive result under the pinned
320x200 benchmark. The unmodified implementation is therefore the fastest
demonstrably correct option from this pass; any future arithmetic candidate
needs exact rounded S/T endpoints before it can be considered.
