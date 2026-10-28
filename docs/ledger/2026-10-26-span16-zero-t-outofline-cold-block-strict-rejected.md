# Span16 out-of-line zero-T setup rejected (2026-10-26)

## Proposal

Move the cold zero-integer-T setup after `D_DrawSpans16`'s `ret`, allowing the
common nonzero-T setup to fall through without an entry jump to skip the cold
block.

## Measurements

The pinned DOSBox-X 486 `demo1` parity screen measured 15.948136, 15.948133 and
15.948116 FPS (mean 15.948128333 FPS). The strict control mean was
15.948143667 FPS.

The full strict candidate measured 15.948144, 15.948133 and 15.948129 FPS
(mean 15.948135333 FPS), 0.000008334 FPS (about 0.0000523%) below control.
Every run rendered 969 frames with framebuffer checksum `1047377823`.

The complete i486 ISA gate passed: 314,399 relocated instructions, 529 startup
rows and 9,207 provider instructions, with zero above-i486, unknown or exempt
instructions.

## Decision

Rejected on the lower strict mean. Restored `src/d_draw16.s` to the control
implementation; no commit was made.

Parity screen: `out/dos-timedemo-20261026-182824/timedemo-result.json`.
Strict result: `out/dos-timedemo-20261026-190033/timedemo-result.json`.
Strict control: `out/dos-timedemo-20261026-150012/timedemo-result.json`.
