# `R_RenderFace` assembly selected for i486

`RenderFaceImplementation=asm` beats the matched C reference in the pinned
`demo1` timedemo, so the assembly path is promoted for i486. The checked-in
i486 selector profile already selected it; this result updates the promotion
record and confirms that routing. C remains explicitly selectable, and the
i386 profile remains on C.

## Matched comparison

Both variants used source tree fingerprint
`DB27F40690187D296BAB82BCB2BACFDB10BA309F34B3E5054BC7E22FE5E30689`, the same
pinned DOSBox-X profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
the same `EdgeListMaintenanceImplementation=asm` setting, and three
uninstrumented runs. Every run rendered 969 frames with checksum
`1047377823`.

| Variant | FPS samples | Mean |
|---|---|---:|
| `RenderFaceImplementation=asm` | 15.564259, 15.564240, 15.564259 | 15.564252667 |
| `RenderFaceImplementation=c` | 15.502612, 15.502613, 15.502604 | 15.502609667 |

The assembly mean is **+0.061643 FPS (+0.39763%)**. The positive mean meets the
current promotion rule regardless of gain size. The assembly candidate passed
the full linked strict i486 audit. The C control used the parity-only route,
which skips that assembly audit.

Artifacts:

- Assembly candidate: `out/dos-timedemo-20261022-012108/timedemo-result.json`
- C control: `out/dos-timedemo-20261022-012558/timedemo-result.json`

## Decision

Keep `RenderFaceImplementation=asm` in the i486 default profile. Preserve
`RenderFaceImplementation=c` as the explicit reference and the i386 default.
This result promotes only the world `R_RenderFace` path; it does not close the
separate B-model face or cached-edge implementation work.
