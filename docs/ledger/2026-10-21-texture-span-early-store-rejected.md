# Texture-span early packed-store schedule: original decision (2026-10-21)

Historical status: rejected under the former repeatability rule after a
twelve-run parity-screen comparison. Superseded on 2026-10-21 by
[`2026-10-21-texture-span-early-store-promoted.md`](2026-10-21-texture-span-early-store-promoted.md)
after the user directed promotion of any positive pooled FPS mean. The sample
data below are unchanged.

The candidate moved each packed word store to immediately after both texels
were loaded, before the final carry-based source-address update. `MOV` leaves
flags and the DDA registers unchanged, so this only changed the independent
framebuffer-store schedule. The experiment touched `src/renderer/d_draw16.s` only and
has been reverted.

All samples used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the same uninstrumented
timedemo runner, and the pinned 32 MB i486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Every
run completed 969 frames and reported framebuffer checksum `1047377823`.

| Variant block | Artifact | Run FPS | Mean FPS |
|---|---|---|---:|
| Control, strict baseline | `out/dos-timedemo-20261020-224647/timedemo-result.json` | 15.537300 / 15.537292 / 15.537300 | 15.537297333 |
| Control, fresh 1 | `out/dos-timedemo-20261020-230605/timedemo-result.json` | 15.537292 / 15.537304 / 15.537297 | 15.537297667 |
| Control, fresh 2 | `out/dos-timedemo-20261020-231527/timedemo-result.json` | 15.537299 / 15.537287 / 15.537296 | 15.537294000 |
| Control, fresh 3 | `out/dos-timedemo-20261020-232438/timedemo-result.json` | 15.537300 / 15.537300 / 15.537307 | 15.537302333 |
| Early store, block 1 | `out/dos-timedemo-20261020-230113/timedemo-result.json` | 15.537297 / 15.537296 / 15.537295 | 15.537296000 |
| Early store, block 2 | `out/dos-timedemo-20261020-231040/timedemo-result.json` | 15.537317 / 15.537307 / 15.537290 | 15.537304667 |
| Early store, block 3 | `out/dos-timedemo-20261020-231958/timedemo-result.json` | 15.537292 / 15.537306 / 15.537298 | 15.537298667 |
| Early store, block 4 | `out/dos-timedemo-20261020-232910/timedemo-result.json` | 15.537304 / 15.537283 / 15.537292 | 15.537293000 |

Across twelve runs, control averaged **15.537297833 FPS** and the candidate
averaged **15.537298083 FPS**, a difference of **+0.000000250 FPS
(+0.0000016%)**. Two candidate blocks were faster than their fresh controls and
two were slower. At the time, the result was held below the former
repeatability gate; the newer promotion entry records the user's changed
acceptance rule and strict audit.
