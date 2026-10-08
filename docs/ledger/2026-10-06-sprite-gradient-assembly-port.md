# Sprite gradient assembly port (2026-10-06)

## `D_SpriteCalculateGradients` perspective setup

The original function remains as `D_SpriteCalculateGradients_C`; the public
entry selects `D_SpriteCalculateGradients_asm486` when
`SpriteGradientImplementation=asm`. The C wrapper passes the current sprite
height, which remains owned by the existing raster setup. A compile-time layout
assertion pins the sprite descriptor axes at `vup=12`, `vright=24`, and
`vpn=36` bytes.

The assembly calls the existing `TransformVector` for the three sprite axes and
model origin, then computes the perspective texture and inverse-depth steps,
screen origins, 16.16 texture adjustments, and texture extents. It uses the
original cdecl convention, preserves EBX, and restores the caller's x87 control
word after truncating the C float-to-integer casts toward zero. Inspection of
the C object showed that GCC keeps `distinv` and the two depth-step results in
extended x87 precision across later expressions. The assembly keeps those
values live as well. Storing `distinv` as a float first caused one-bit
differences in depth gradients; reloading rounded depth-step globals then left
one one-bit difference in `d_ziorigin`. Retaining the corresponding x87 values
made all result fields exact.

The direct DOSBox-X i486 fixture compares all six step floats, three origin
floats, two texture adjustments, and two extent integers against C. All three
cases passed exactly:

- `oblique-camera`: checksum 1375311114
- `positive-plane-distance`: checksum 4063960724
- `large-viewport`: checksum 4095606232

Run the direct fixture with
`rtk pwsh -NoProfile -File tools/bench-dos.ps1 -SpriteGradientOnly -NoBootstrap`.
The same cases are included in the `bench486` aggregate.

### Paired render and linked-ISA validation

The C-reference profile and a focused profile with only
`SpriteGradientImplementation=asm` ran the pinned Demo 1 VESA scene under the
i486 DOSBox-X profile. Both passed at the 969-frame golden checksum
`1047377823`. The pair compared 964 post-warmup frame checksums exactly. The
320x200 capture had zero differences across all 64,000 palette indices and all
768 palette bytes. The report is
`out/render-parity-spritegradient-focused-20261006/render-parity-result.json`;
the source-tree fingerprint recorded by the pair is
`3CFA1A6ED72263191B2858D906E6740AD5BD15AD645ADA924C6297F1B03DB089`.

The assembly-selected candidate's linked i486 ISA audit passed with 338 input
objects, 235 runtime inputs, 232419 linked opcode sites verified, and zero
opcode mismatches. The report retains the current bounded toolchain and data
exemptions. It is
`out/dos-turbc-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasc-aliasbboxc-aliastransformc-aliasmatrixc-textureanimc-lightmapc-spritegradientasm-edgelistc/isa-audit-linked.json`.

The selector build test, 22 rendering source/harness tests, render-report
tests, and ISA-audit tests passed. The focused timedemo measured 12.710792 FPS
for the C reference and 12.710795 FPS for the assembly profile; the difference
is negligible and did not motivate a performance change.

This ports the sprite texture/depth gradient setup only. Sprite axis
generation, polygon clipping and projection orchestration, scan conversion,
span texture mapping, and downstream sprite rasterization still need their own
ports and parity coverage. The complete renderer migration remains in progress.
