# Sprite setup assembly port (2026-10-07)

## `R_SetupAndDrawSprite` world poster, clipping, projection, and dispatch

The original implementation remains available as
`R_SetupAndDrawSprite_C`; `SpriteSetupImplementation=c|asm` selects the public
entry. The assembly path owns the backface test, frame-bound scaling, four
world-space poster corners and texture coordinates, four frustum clipping
calls, view transform, near-plane clamp, reciprocal depth, projected vertices,
`nearzi`, and `D_DrawSprite` dispatch. The renderer algorithm and draw order are
unchanged.

Compile-time layout checks pin `MAXWORKINGVERTS=20`, the 400-byte clip buffer,
20-byte `vec5_t` and `emitpoint_t` records, the 24-byte clip plane, sprite
descriptor offsets, and sprite-frame bound offsets. The cdecl routine preserves
EBX, ESI, and EDI. It uses x87 only for floating-point operations; input XYZ is
laid out contiguously for the legacy `TransformVector` helper, integer texture
dimensions are explicitly converted to float, and unordered depth comparisons
retain the C near-plane behavior.

The `bench486` fixture compares the C and assembly paths through the existing
sprite draw stages. It checks all final clip-buffer bytes, projected
`emitpoint_t` records, `nearzi`, and the full 320x200 indexed-color and depth
buffers. All five cases passed exact comparison under the DOSBox-X i486
configuration:

- `centered`: 1042167839
- `frustum-clipped`: 2150379761
- `near-plane`: 861759357
- `outside-frustum`: 957228192
- `backface`: 957228192

Run the focused fixture with
`rtk pwsh -NoProfile -File tools/bench-dos.ps1 -SpriteSetupOnly -SpriteSetupImplementation asm`.
The all-stage `+bench486` harness also includes these cases.

## Instruction-set and paired-render validation

The focused profile `i486-asm-sprite-setup.json` differs from
`i486-c-reference.json` only in `SpriteSetupImplementation`. The selected
benchmark objects passed the i486 object audit: 198010 instruction sites, zero
enforced above-i486 encodings, and zero unclassified instructions. The linked
closure audit passed with 235 runtime inputs and 236855 linked opcode sites
verified; it reported zero enforced post-486 instructions. The reports are
`out/dos-memasm-fillrectasm-zpointasm-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm-spritesetupasm/isa-audit.json`
and `isa-audit-linked.json`. Existing runtime/data exemptions remain listed in
those reports and are not represented as executable renderer instructions.

The deterministic paired Demo 2 gameplay run is recorded in
`out/render-parity-20261006-231549/render-parity-result.json`. Both the C
reference and assembly candidate completed two 985-frame runs. Each run had
986 recorded checksums including startup; all 980 post-warmup checksums matched
between implementations on both repeats. The two captured 320x200 frames also
matched exactly: 64,000 palette indices and all 768 palette bytes. Both profiles
used source fingerprint
`4D105D359263201938102E26A23022605C30F8CFA621E4B3D156C123E40121BD`.

The paired timing medians were 12.805879 FPS for C and 12.8058765 FPS for
assembly, effectively equal within this run. This is not a performance claim.
The candidate build's linked audit covered 235 runtime inputs and 235669 linked
opcode sites, with zero enforced post-i486 instructions. Its object audit
covered 103 objects and 196823 instruction sites, with zero above-i486 and zero
unknown instructions. Existing runtime/data exemptions remain explicit in the
reports. The direct-fixture and deterministic gameplay parity evidence
passed before promotion. Assembly is now the i486 default, with C selectable
and i386 remaining on C. The combined promoted paths are recorded in
`tools/renderer-profiles/i486-asm-promoted-renderers.json`.


The promoted i486 release build passed after this selector became default. Its
selected 104-object audit covered 148,754 instruction sites; the complete
339-object closure covered 190,266 sites, with zero enforced instructions above
i486. The linked executable audit verified 187,622 opcodes across 235 runtime
inputs and 332 executable text ranges, again with zero enforced instructions
above i486. Reports are under `out/profile-5201948ab7d15c1b/`.
 `guard-i486-release.py` passed for 104 objects and the executable.

The three promoted paths were then tested together using
tools/renderer-profiles/i486-asm-promoted-renderers.json. All six deterministic
scenarios passed on two repeats each against the all-C reference. The 11,842
post-warmup checksum comparisons were exact, and all 12 captured 320x200
frames matched every palette index and all 768 palette bytes. The source-tree
fingerprints matched; see
out/render-parity-20261007-101114/render-parity-result.json.
