# Alias raster triangle-constant pointer caching (2026-10-28)

Status: promoted after a positive matched three-run mean, exact framebuffer
checksum parity, and a complete linked i486 ISA pass.

`D_RasterizeAliasPolySmooth_asm486` now keeps `a_spans` in `%ebx` and reuses
`%esi` for `pedgetable` across the cdecl scan and draw helpers. This removes
repeated global pointer fetches while retaining the existing operation order
and callee-saved register contract.

The matched comparison used DOSBox-X 2026.08.31, `demo1`, CWSDPMI
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`, and the
pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Both
variants used the aggressive optimization profile and `TextureSpanStores=word`.
Every run rendered 969 frames and reported framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261027-230726/timedemo-result.json` | 16.210785 / 16.210788 / 16.210780 | 16.210784333 | 16.210785 |
| Cached pointers | `out/dos-timedemo-20261027-233600/timedemo-result.json` | 16.211792 / 16.211782 / 16.211787 | 16.211787000 | 16.211787 |

The candidate gained **0.001002667 FPS (+0.006185%)** over the matched control.
The complete strict i486 gate passed: 314,243 relocated instructions, 529
startup code rows, and 9,207 provider instructions, with zero above-i486,
unknown, or exempt instructions. Source mapping covered 403 exact native and
annotated object proofs, 435 source-bound contributions, 2,376 CODE ranges,
and 35 DATA ranges.

The automated DOSBox run is hidden and did not capture the host window. Its
expected final framebuffer checksum confirms rendered game pixels, but does
not verify visible DOSBox window presentation.
