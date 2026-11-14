# Span16 cachewidth-16 multiplication shift rejected (2026-10-26)

## Proposal

Use `shll $4` instead of `imull %ebx,%eax` for the nonzero-T setup when
`cachewidth == 16`, retaining the generic multiply for all other widths. The
instrumented profile counted 28,718 width-16 normal surfaces out of 55,303.

## Parity screen

On the pinned DOSBox-X 486 `demo1` workload, the candidate measured 15.931765,
15.931759 and 15.931774 FPS (mean 15.931766 FPS). The control mean was
15.948143667 FPS, making this screen 0.016377667 FPS (about 0.1027%) slower.

All samples rendered 969 frames with framebuffer checksum `1047377823`. This
visual-parity screen skipped the strict ISA audit.

## Decision

Rejected on the clear screen slowdown. Restored `src/renderer/d_draw16.s` to the control
implementation; no strict audit or commit was made.

Result: `out/dos-timedemo-20261026-190740/timedemo-result.json`.
Profile: `out/dos-timedemo-20261026-172719/quake/PROFILE.JSN`.
