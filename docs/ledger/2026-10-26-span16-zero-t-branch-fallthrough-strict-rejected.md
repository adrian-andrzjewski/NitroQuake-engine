# D_DrawSpans16 nonzero-T fallthrough branch layout rejected (2026-10-26)

## Proposal

Put the common nonzero integer-T setup on the fallthrough path and branch to a
cold zero-T setup. The instrumented demo profile showed a nonzero integer T
delta for about 71% of segments.

## Strict measurement

The candidate used the pinned DOSBox-X 486 profile and `demo1` with the i486
target. Its three samples were 15.947677, 15.947671 and 15.947673 FPS, for a
mean of 15.947673667 FPS. The strict control mean was 15.948143667 FPS, so the
candidate was 0.000470 FPS (about 0.00295%) slower.

All samples rendered 969 frames with framebuffer checksum `1047377823`.
The complete ISA gate passed: 314,382 relocated instructions, 529 startup
rows and 9,207 provider instructions, with zero above-i486, unknown or exempt
instructions.

## Decision

Rejected on the lower strict mean. Restored `src/renderer/d_draw16.s` to the control
implementation; no commit was made.

Candidate result: `out/dos-timedemo-20261026-181830/timedemo-result.json`.
Strict control: `out/dos-timedemo-20261026-150012/timedemo-result.json`.
