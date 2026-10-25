# Mip-0 horizontal-flat rows use packed dword stores (2026-10-25)

Status: promoted assembly optimization in `src/surf8.s`.

`SURF8_MIP0_HORIZONTAL_FLAT_ROW` now packs each four adjacent colormapped
texels in `%eax` and writes them with one `movl`. This replaces 16 byte stores
per 16-pixel row with four dword stores. The `%ah`/`%al` lookup sequence and
`rorl $16,%eax` place the packed texels in framebuffer byte order. Since
`%ah` now carries a texel, the 16-row loop counter uses a stack slot. Lookup
patch-site labels remain attached to their original lookup instructions.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, three uninstrumented runs, and the same 159 build selectors.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261025-043134/timedemo-result.json` | 15.919141 / 15.919214 / 15.919200 | 15.919185000 | 15.919200 |
| Packed horizontal-flat rows | `out/dos-timedemo-20261025-045607/timedemo-result.json` | 15.921083 / 15.921085 / 15.921073 | 15.921080333 | 15.921083 |

The candidate mean is **+0.001895333 FPS (+0.01190597%)**. Every candidate
sample exceeded every control sample. All runs rendered 969 frames and
produced framebuffer checksum `1047377823`; the pinned profile and all 159
build selectors matched.

The strict linked i486 gate passed: 314,384 relocated instructions, 529
startup rows, and 9,207 provider instructions, with zero exemptions. The run
also verified 403 exact object proofs and passed final source mapping across
435 source-bound contributions.
