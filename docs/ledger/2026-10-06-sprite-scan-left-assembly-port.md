# Sprite left-edge scan conversion assembly port (2026-10-06)

## `D_SpriteScanLeftEdge` span generation

The C implementation remains available as `D_SpriteScanLeftEdge_C`; the public
wrapper selects `D_SpriteScanLeftEdge_asm486` with
`SpriteScanLeftImplementation=asm`. The assembly routine receives the span
buffer, edge indices, vertex count and emitted vertices as cdecl arguments. It
walks the same wrapped polygon edge range, applies `ceil` to the vertical
boundaries, computes the floating slope, and emits the same integer `u/v`
coordinates while stepping `u` in 16.16 fixed point. Its x87 control-word
changes are local to the C-equivalent `ceil` and truncating conversions and the
caller's control word is restored. Compile-time assertions pin the `u/v`
offsets, `emitpoint_t` stride and `sspan_t` layout used by the assembly.

The direct `bench486` fixture compares the entire C and assembly span arrays,
including untouched sentinel entries. All three cases passed exactly on the
DOSBox-X i486 profile:

- `fractional-quad-wrap`: checksum 2477019243
- `five-vertex-nonzero-start`: checksum 2013903492
- `negative-u`: checksum 221657559

Run these cases with
`rtk pwsh -NoProfile -File tools/bench-dos.ps1 -SpriteScanLeftOnly -NoBootstrap`.

### Paired render and linked-ISA validation

`i486-asm-sprite-scan-left.json` changes only this selector relative to
`i486-c-reference.json`. The paired Demo 2 entity workload passed twice per
profile under DOSBox-X's i486 configuration. Each run produced the pinned 985
frame checksum `1887495667`; the pair compared all 980 post-warmup frame
checksums on each repeat with no mismatches. Both 320x200 captures matched in
all 64,000 palette indices and all 768 palette bytes. The report is
`out/render-parity-spritescanleft-focused-20261006/render-parity-result.json`.
Both profiles recorded the same source-tree fingerprint:
`E4DF70FC804288C056921257AE452C85DDA7730D5FDA3342674D25D7BE5708EE`.

The candidate linked ISA audit passed with 235 runtime inputs and 232874 linked
opcode sites verified; it found zero enforced post-486 instructions. The report
is
`out/dos-turbc-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasc-aliasbboxc-aliastransformc-aliasmatrixc-textureanimc-lightmapc-spritescanleftasm-edgelistc/isa-audit-linked.json`.

The C and assembly timedemo medians were both 12.8 FPS (12.805875 and
12.805793 FPS respectively); this is not a reason to complicate the routine.
The selector build test and 24 rendering tests passed. This ports only the
left-edge span generator: right-edge span generation, sprite span rasterization
and the remaining sprite pipeline still need independent ports and checks. The
complete renderer migration remains in progress.
