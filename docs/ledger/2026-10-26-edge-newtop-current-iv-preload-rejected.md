# Reject `current_iv` preload in `R_GenerateSpans` `Lnewtop` (2026-10-26)

The candidate moved the `current_iv` load from after the span-count arithmetic
to just after the positive-emission branch. It held the value in `%ecx` while
loading and subtracting `st_last_u`, then stored it into `espan_t_v`. The path
added no instructions and left the no-emission branch unchanged.

## Strict timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned
32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
The candidate used byte-for-byte copies of the same `pak0.pak` and `pak1.pak`
after the original PAK hardlink source reached the filesystem link limit.

| Variant | Artifact | FPS samples | Mean FPS | Spread |
|---|---|---|---:|---:|
| Current strict control | `out/dos-timedemo-20261026-150012` | 15.948144 / 15.948137 / 15.948150 | 15.948143667 | 0.000013 |
| `current_iv` preload | `out/dos-timedemo-20261026-161036` | 15.948141 / 15.948140 / 15.948149 | 15.948143333 | 0.000009 |

Every run completed 969 frames with framebuffer checksum `1047377823`. The
candidate mean was **−0.000000333 FPS (−0.00000209%)** against control, so the
schedule is rejected and the original load order is restored.

The complete strict i486 candidate gate passed: 314,394 relocated game
instructions, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. Its source-tree fingerprint was
`00C8F9054362D2FBBCCBB81F53545ED5D790752D7C09B0457938EEC9694312B6`; the
restored control source tree is `93263CFB3C70E98579EAB64A825AF165175A8918225611ED82B8F8C6256EF3F0`.

Candidate audit and build artifacts are under
`out/local-local-currentiv-lnewtop-candidate-20261026/`.
