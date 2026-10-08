# Sprite draw orchestration assembly port (2026-10-07)

## `D_DrawSprite` orchestration

The original entry remains available as `D_DrawSprite_C`. The public
`D_DrawSprite` wrapper selects `D_DrawSprite_asm486` with
`SpriteDrawImplementation=asm`; C remains independently selectable. The
assembly owns the vertex min/max scan, the two `ceil` conversions, early empty
scan return, stack allocation of `sspan_t spans[MAXHEIGHT+1]`, shared sprite
cache state, closing-vertex copy, and dispatch through gradient calculation,
both edge scanners, and the span rasterizer. `D_SpriteCalculateGradients`,
`D_SpriteScanLeftEdge`, and `D_SpriteScanRightEdge` remain separate selectors.
`D_SpriteDrawSpans` is Quake's existing `id386` 8-bit assembly rasterizer.

The assembly preserves EBX, ESI, and EDI, uses cdecl stack arguments, and
restores the x87 control word after using upward rounding for `ceil`. Compile
time layout checks pin `MAXHEIGHT=1024`, `sizeof(sspan_t)=12`, and
`sizeof(emitpoint_t)=20`, matching the local span buffer and vertex copy.

The `bench486` direct fixture compares the complete 320x200 indexed-color and
depth buffers from the C and assembly entries. All cases passed exact
comparison under DOSBox-X's i486 profile:

- `fractional-rectangle`: checksum 2619675260
- `viewport-clamp`: checksum 2734519974
- `zero-scan`: checksum 3563520512

The row-address tables are redirected into independent test buffers for each
path, so the comparison observes the pixels written by the legacy span
rasterizer. The fixture is run with
`rtk pwsh -NoProfile -File tools/bench-dos.ps1 -SpriteDrawOnly -SpriteDrawImplementation asm`.

## Paired render and linked-ISA validation

`i486-asm-sprite-draw.json` differs from `i486-c-reference.json` only in
`SpriteDrawImplementation`. Both profiles passed two `demo2-entity-workload`
runs under DOSBox-X's pinned 486 profile. Each run recorded 986 frame-checksum
entries, including six ignored startup frames; all 980 post-warmup checksums
matched exactly. Both 320x200 captures matched all 64,000 palette indices and
all 768 palette bytes. The paired report is
`out/render-parity-20261006-220332/render-parity-result.json`, and both sides
record source-tree fingerprint
`330D0A2553C640D38980D282B7E1D2D4CEFA9142E53E22053D3081F5718A2685`.

The focused candidate linked ISA audit inspected 235 runtime inputs and
verified 234254 linked opcode sites with zero enforced post-486 instructions.
The report is
`out/dos-turbc-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflatidxhoist-aliasc-aliasbboxc-aliastransformc-aliasmatrixc-textureanimc-lightmapc-spritedrawasm-edgelistc/isa-audit-linked.json`.
The normal build audit still applies its explicit static-data exemptions for
bytes disassembled from linked text/data regions.

The reference and assembly median rates were 12.805875 and 12.8057035 FPS.
That difference is negligible; this conversion is accepted on parity and
compatibility evidence, not a speed claim. The 28 rendering checks, build
selector checks, direct framebuffer fixture, object ISA gate, linked-object
gate, and executable linked-ISA gate passed. The sprite pipeline and full
renderer conversion remain in progress.


## Combined promoted sprite-draw paths

The four promoted implementations ran together under DOSBox-X's i486 profile
against the all-C reference using
tools/renderer-profiles/i486-asm-promoted-renderers-spritedraw.json. The six
scenarios ran twice each. All 11,842 post-warmup checksum comparisons matched;
all 12 captured 320x200 frames matched all 64,000 palette indices and all 768
palette bytes. There were zero mismatched frames or pixels, and the source-tree
fingerprints matched. The report is
out/render-parity-20261007-105418/render-parity-result.json.

Replay checksums were 1047377823 for Demo 1 VESA/VGA, 4021309056 for
fullbright, 885630476 for the reduced view, 1887495667 for Demo 2, and
3722973491 for Demo 3. Candidate rates were 0.13% to 0.81% lower across the
six scenarios; this is a small regression at the measured emulator speed.

The combined candidate audit checked 104 objects and 182,782 instruction
sites, then the 339-object closure and 224,294 sites. The linked audit verified
221,560 opcodes across 235 runtime inputs and 334 executable text ranges. Each
gate reported zero enforced instructions above i486. Reports are under
out/profile-bc41520769760896/. Existing DOS-runtime and linker-data exemptions
remain explicit and are not a proof of whole-runtime purity.

Assembly is now the i486 default, with explicit C available for reference and
i386 remaining on C. This stage covers D_DrawSprite orchestration; the sprite
sub-stages and the full renderer remain in progress.

The promoted i486 release build passed after SpriteDraw became the default. Its
selected 104-object audit covered 148,863 instruction sites; the 339-object
closure covered 190,375 sites, with zero enforced instructions above i486. The
linked executable audit verified 187,731 opcodes across 235 runtime inputs and
332 executable text ranges, also with zero enforced instructions above i486.
Reports are under out/profile-567a9de27f900066/. The release hash guard passed
for 104 objects and the executable.
