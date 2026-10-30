# Surface-cache hit pointer in EDI rejected (2026-10-29)

## Matched strict timing

The candidate kept the cache pointer in `%edi` across `R_DlightContributes`,
replacing its stack save and restore in
`D_CacheSurfaceCheckAndPrepare_asm486`. Both variants used DOSBox-X 2026.08.31,
`demo1`, the same aggressive i486 selector profile, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA` at
320x200.

| Variant | Artifact | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| EDI candidate | `out/dos-timedemo-20261029-192453/timedemo-result.json` | 16.321720 / 16.321702 / 16.321712 | 0.000018 | 16.321711333 |
| Stack control | `out/dos-timedemo-20261029-195024/timedemo-result.json` | 16.321729 / 16.321696 / 16.321709 | 0.000033 | 16.321711333 |

The matched strict means are equal. All six runs rendered 969 frames and ended
with checksum `1047377823`. Both builds passed the complete executable i486 ISA
gate with zero above-i486, unknown, or exempt instructions. Selector profiles,
DOSBox profile hashes, and per-frame checksum streams match.

Two prior parity-only candidate screens averaged 16.321724 FPS against the
16.321717667 FPS control mean, a pooled increase of 0.000006333 FPS. That
small screen-only gain did not reproduce in the matched strict comparison.

## Disposition

Reject the EDI retention. Keep the stack-preserving cache-pointer schedule; the
candidate has no positive strict mean. A separate 320x200 VGA visual check of
the candidate passed the named golden comparison with 12 of 64,000 pixels
changed (mean absolute channel error 0.0009375):
`out/render-validation-20261029-193234/render-validation-result.json`.
