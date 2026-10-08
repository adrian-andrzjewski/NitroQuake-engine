# Sprite right-edge scan conversion assembly port (2026-10-06)

## `D_SpriteScanRightEdge` span completion

The reference remains available as `D_SpriteScanRightEdge_C`; the public
entry selects `D_SpriteScanRightEdge_asm486` with
`SpriteScanRightImplementation=asm`. The assembly receives the span buffer,
vertex range, duplicated-vertex array and four adjusted viewport bounds through
the cdecl stack. It clamps both edge endpoints to the same viewport bounds,
rounds vertical endpoints with `ceil`, computes the same slope and 16.16 `u`
step, then stores `count = right_u - left_u` for each row and writes the
`DS_SPAN_LIST_END` terminator. EBX, ESI and EDI are preserved; the routine
restores the caller's x87 control word after its local ceil and truncating
conversions.

The direct `bench486` fixture compares the full C and assembly span arrays,
including untouched sentinel entries. All three cases passed exactly on the
DOSBox-X i486 profile:

- `fractional-quad`: checksum 1403395987
- `viewport-clamp-wrap`: checksum 2951613424
- `negative-slope-narrow-view`: checksum 492926117

The viewport case clips coordinates beyond all four viewport bounds and checks
the wrapped edge range. Run these cases with
`rtk pwsh -NoProfile -File tools/bench-dos.ps1 -SpriteScanRightOnly -NoBootstrap`.

### Paired render and linked-ISA validation

`i486-asm-sprite-scan-right.json` changes only this selector relative to
`i486-c-reference.json`. Both profiles passed two Demo 2 entity-workload runs
under DOSBox-X's i486 configuration. Each run produced the pinned 985-frame
checksum `1887495667`; all 980 post-warmup checksums matched exactly on both
repeats. Each 320x200 capture matched across all 64,000 palette indices and all
768 palette bytes. The paired report is
`out/render-parity-spritescanright-focused-20261006/render-parity-result.json`.
Both sides recorded source-tree fingerprint
`951BEDE3C742B6283A20D6A618930364E50F5DC5B990B7237EF626D4E1D9C5AD`.

The candidate linked ISA audit passed with 235 runtime inputs and 233458 linked
opcode sites verified; it found zero enforced post-486 instructions. The report
is
`out/dos-turbc-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflatidxhoist-aliasc-aliasbboxc-aliastransformc-aliasmatrixc-textureanimc-lightmapc-spritescanrightasm-edgelistc/isa-audit-linked.json`.

The C and assembly timedemo medians were both 12.8 FPS (12.805875 and
12.805793 FPS respectively). The measured difference is negligible. The
selector build test and 26 rendering tests passed. At this stage
`D_DrawSprite` orchestration remained C; `D_SpriteDrawSpans` was already the
legacy `id386` 8-bit assembly rasterizer. The orchestration has since gained a
selectable assembly entry; the full sprite subsystem and renderer migration
remain in progress.
