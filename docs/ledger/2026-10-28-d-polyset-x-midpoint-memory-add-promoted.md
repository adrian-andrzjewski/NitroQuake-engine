# D_PolysetRecursiveTriangle X-midpoint memory-source add (2026-10-28)

Status: promoted after a positive matched three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

## Change

In `D_PolysetRecursiveTriangle`, the X midpoint now loads `lp2[0]` into
`%edx` and adds `lp1[0]` directly from memory. The unconditional `%ecx` load
of `lp1[0]` is removed. The equal-Y edge tie-break now compares `lp2[0]`
against `lp1[0]` with a memory-source compare, so that operand is only read
for the equal-Y path. The computed midpoint remains in `%edx`; midpoint
arithmetic and draw/no-draw decisions are unchanged.

## Matched timedemo

Control and candidate used `demo1`, DOSBox-X 2026.08.31, CWSDPMI
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`, the
aggressive optimization profile, `TextureSpanStores=word`, and pinned profile
SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
All six runs rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
| --- | --- | --- | ---: | ---: |
| Control | `out/dos-timedemo-20261028-020521/timedemo-result.json` | 16.227748 / 16.227753 / 16.227749 | 16.227750000 | 16.227749 |
| Memory-source X midpoint | `out/dos-timedemo-20261028-023932/timedemo-result.json` | 16.229258 / 16.229257 / 16.229257 | 16.229257333 | 16.229257 |

The candidate gained **0.001507333 FPS (+0.009289%)**. Both variants used the
byte-verified local PAK copy. Its `pak0.pak` SHA-256 is
`35A9C55E5E5A284A159AD2A62E0E8DEF23D829561FE2F54EB402DBC0A9A946AF`; its
`pak1.pak` SHA-256 is
`94E355836EC42BC464E4CBE794CFB7B5163C6EFA1BCC575622BB36475BF1CF30`.

## i486 audit

The complete strict gate passed with zero above-i486, unknown, or exempt
instructions: 314,234 linked instructions, 529 startup rows, and 9,207
provider instructions. Source mapping verified 403 exact object proofs, 435
source-bound contributions, 2,376 CODE ranges, and 35 DATA ranges.

The linked ISA report is
`out/profile-107ff6406936b458/isa-qbench/isa-audit-linked.json`; the final
executable report is
`out/profile-107ff6406936b458/isa-qbench/relocated-20261028-033313547/strict-isa.json`.
