# Texture-span dword-store recheck (2026-10-20)

Status: rejected for measured slowdown; `TextureSpanStores=word` remains the
default.

The `dword` selector packs pairs of sampled bytes into 32-bit destination
stores in the full 16-pixel texture-span loop. It was screened again against
the current promoted renderer because the earlier timing policy excluded small
gains by percentage. The six candidate runs used `-VisualParityOnly`, so the
linked i486 ISA audit was skipped; a strict candidate audit was not run after
the measured regression.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and otherwise identical selectors (`word` control versus
`dword` candidate). All runs completed 969 frames with framebuffer checksum
`1047377823`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS |
|---|---|---|---|---:|
| Current word-store control | `out/dos-timedemo-20261020-190238/timedemo-result.json` | 62.390208 / 62.390171 / 62.390172 / 62.390210 / 62.390211 / 62.390168 | 15.531283 / 15.531293 / 15.531293 / 15.531283 / 15.531282 / 15.531294 | 15.531288000 |
| Dword stores | `out/dos-timedemo-20261020-200045/timedemo-result.json` | 62.819061 / 62.819028 / 62.819045 / 62.818947 / 62.818954 / 62.819048 | 15.425254 / 15.425263 / 15.425258 / 15.425282 / 15.425281 / 15.425258 | 15.425266000 |

The dword variant averaged **0.6826% fewer FPS** than control; its full range
was also below every control sample. Frame parity passed, but the consistent
timing regression rejects it without a strict promotion build. The word-store
default is unchanged.
