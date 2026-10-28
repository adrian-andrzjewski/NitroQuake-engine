# Texture-span `stosw` stores (2026-10-21)

Status: rejected after a three-run parity screen; `TextureSpanStores=word`
remains the default.

The opt-in `TextureSpanStores=stosw` assembly path uses `stosw` for the eight
packed word stores in each full 16-pixel texture segment. The indexed word-store
path remains unchanged at `TextureSpanStores=word`.

The screen used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile `out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). All
runs completed 969 frames and reported the expected framebuffer checksum
`1047377823`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS |
|---|---|---|---|---:|
| Promoted word-store control, strict set | `out/dos-timedemo-20261020-224647/timedemo-result.json` | 62.366046 / 62.366082 / 62.366046 | 15.537300 / 15.537292 / 15.537300 | 15.537297333 |
| `stosw` stores, parity-only screen | `out/dos-timedemo-20261020-225431/timedemo-result.json` | 62.427440 / 62.427415 / 62.427477 | 15.522020 / 15.522027 / 15.522012 | 15.522019667 |

The candidate was **0.015277667 FPS slower (−0.0983%)**; each candidate sample
was slower than each control sample. Exact frame and checksum parity passed.
The parity-only build skipped the ISA audit, but the measured regression is
clear and the candidate was not advanced to a strict build. The opt-in assembly
variant remains available for reproduction; the default stays on indexed word
stores.

The candidate result records source-tree fingerprint
`E40384B12F44BE9F7540DE10198DC26E5E9D84510E60D965636DF48981AE3F19`.
