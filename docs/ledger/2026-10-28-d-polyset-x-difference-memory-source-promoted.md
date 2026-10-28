# D_PolysetRecursiveTriangle X-difference memory-source subtract (2026-10-28)

Status: promoted after a positive matched three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

## Change

Each of the three X-coordinate checks in `D_PolysetRecursiveTriangle` now
subtracts the other vertex coordinate directly from memory. This removes one
register-load instruction per executed check. The inclusive `+1`, compare
against two, branch conditions, and split behavior are unchanged. The earlier
Y-check memory-source optimization remains in place.

## Matched timedemo

Control and candidate used `demo1`, DOSBox-X 2026.08.31, CWSDPMI
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`, the
aggressive optimization profile, `TextureSpanStores=word`, and pinned profile
SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
All six runs rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
| --- | --- | --- | ---: | ---: |
| Control | `out/dos-timedemo-20261028-012301/timedemo-result.json` | 16.219507 / 16.219472 / 16.219467 | 16.219482000 | 16.219472 |
| Memory-source X subtract | `out/dos-timedemo-20261028-020521/timedemo-result.json` | 16.227748 / 16.227753 / 16.227749 | 16.227750000 | 16.227749 |

The candidate gained **0.008268 FPS (+0.050976%)**. The candidate used a local
PAK copy after the original source reached NTFS's hard-link limit. SHA-256
verification confirmed byte-identical `pak0.pak`
(`35A9C55E5E5A284A159AD2A62E0E8DEF23D829561FE2F54EB402DBC0A9A946AF`) and
`pak1.pak`
(`94E355836EC42BC464E4CBE794CFB7B5163C6EFA1BCC575622BB36475BF1CF30`).

## i486 audit

The complete strict gate passed with zero above-i486, unknown, or exempt
instructions: 314,233 linked instructions, 529 startup rows, and 9,207
provider instructions. Source mapping verified 403 exact object proofs, 435
source-bound contributions, 2,376 CODE ranges, and 35 DATA ranges.

The linked ISA report is
`out/profile-107ff6406936b458/isa-qbench/isa-audit-linked.json`; the final
executable report is
`out/profile-107ff6406936b458/isa-qbench/relocated-20261028-025658069/strict-isa.json`.
