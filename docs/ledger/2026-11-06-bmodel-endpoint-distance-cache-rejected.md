# Brush-model clip endpoint-distance cache rejected (2026-11-06)

## Candidate

The candidate kept the previous edge's two vertex pointers and their exact
binary32 splitter-plane distances in per-call stack locals. A matching pointer
could reuse its stored distance instead of evaluating another three-component
dot product. It added no global table. The PROFILE486 workload reported 170,266
edge visits and 105,123 adjacent endpoint pointer matches.

The diagnostic profile run at `out/dos-timedemo-20261106-141149` matched its
control's color and Z checksum streams. This result did not predict release
behavior.

## Release build and ISA gate

The release candidate used source fingerprint
`A2A51C67DACB2180944C01ED95369F9D47BACE8754712B49BE258E981D109BAA` and
executable SHA-256
`31A5C0A400E08954814096B8FC3126476A051BC217AD24BBD435E4A7A9A3B452`.
The pinned DOSBox-X 2026.08.31 `cputype=486` profile hash was
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

The complete strict release audit passed: 315,286 relocated instructions,
529 startup code rows, and 9,207 runtime-provider instructions were verified,
with zero above-i486, unknown, exempt, or unclassified instructions.

## Release output and disposition

The detached control at
`out/worktree-bmodel-endpoint-cache-control-20261106/out/dos-timedemo-20261106-142916`
and two release candidate replays at `out/dos-timedemo-20261106-145237` and
`out/dos-timedemo-20261106-145817` used the same pinned profile and game data.
Both candidate replays differed from control in color and Z checksums at frames
727, 728, 730, and 731. The color-stream difference reproduced exactly across
the candidate replays. Their frame-482 PCX matched control byte-for-byte
(SHA-256 `82ABCB38389D68E1C5C96658B66680C3AB52D50755C384F85AD1DF772D760C8D`),
and all runs ended at framebuffer checksum `1047377823`; these matches do not
override the per-frame differences. The candidate Z checksum at frame 731 also
varied between its two replays.

No release timing was accepted because exact release output failed. The
checksum-enabled runs are diagnostic and are not comparable to uninstrumented
FPS results. The candidate assembly change was removed; the existing 512-entry
splitter-plane transform cache remains the retained implementation.
