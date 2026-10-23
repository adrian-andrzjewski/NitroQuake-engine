# Promote integer distance tests in the i486 sprite clipper

`R_ClipSpriteFace_asm486` calculates its clip distances as stored IEEE-754
binary32 values. The vertex-copy check (`dist >= 0`), zero checks, and strict
side checks now classify those stored words with integer tests. The predicates
preserve both signed zeros, ordered positive and negative values, infinities,
and unordered NaNs while removing six x87 `FTST` / status-word sequences from
each vertex iteration.

The candidate was measured against committed baseline `817bd59` in the same
aggressive i486 profile with `SpriteClipImplementation=asm`,
`BspWalkImplementation=asm`, and `BmodelPolygonClipImplementation=asm`. Both
used the pinned 32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
baseline mean was `15.620038000 FPS`; its source-tree fingerprint was
`100EBA044F3D4FE9B861336F8EF80D2649532C9284B37076EA7FA2768473EFB0`. The
candidate source-tree fingerprint was
`96C96977F707892488EAB0D75644B880CF1D7B7D6C0028A75260091B26C53D94`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| committed control | 15.620052 / 15.620030 / 15.620032 | 15.620038000 | 0.000022 |
| integer sprite distance tests | 15.620187 / 15.620171 / 15.620176 | 15.620178000 | 0.000016 |

The change gains **0.000140 FPS (+0.00089628%)**. All six runs rendered 969
frames with framebuffer checksum `1047377823`; enforced frame and checksum
parity passed.

The complete source-bound i486 ISA gate passed: 313,910 relocated executable
instructions, 529 startup code rows, and 9,207 DPMI-provider instructions,
with zero exemptions and zero above-i486 instructions.

Artifacts:

- Strict candidate build: `out/local-i486-sprite-clip-integer-distance-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-113600/`
- Committed control timedemo: `out/dos-timedemo-20261023-110755/`
