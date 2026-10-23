# Promote integer side classification for the i486 BSP walk

`R_RecursiveWorldNode_asm486` stores each plane dot as IEEE-754 binary64
before classifying `dot >= 0`. The side test now reads that stored value's high
and low words directly. It accepts positive finite values, both signed zeros,
and positive infinity; it rejects negative nonzero values and unordered NaNs,
matching the C comparison while removing the reload and x87 status-word test.

The candidate was measured against committed baseline `5f6db38` in the same
aggressive i486 profile with `BspWalkImplementation=asm` and
`BmodelPolygonClipImplementation=asm`. Both used the pinned 32 MB DOSBox-X
profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
baseline mean was `15.615200667 FPS`; its source-tree fingerprint was
`F8E4702568F8E8C19CEC366D9AA1FC65526E13469543348627D010C9289352ED`. The
candidate source-tree fingerprint was
`100EBA044F3D4FE9B861336F8EF80D2649532C9284B37076EA7FA2768473EFB0`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| committed control | 15.615207 / 15.615195 / 15.615200 | 15.615200667 | 0.000012 |
| integer BSP side test | 15.620052 / 15.620030 / 15.620032 | 15.620038000 | 0.000022 |

The change gains **0.004837333 FPS (+0.03097836%)**. All six runs rendered
969 frames with framebuffer checksum `1047377823`; enforced frame and checksum
parity passed.

The complete source-bound i486 ISA gate passed: 313,926 relocated executable
instructions, 529 startup code rows, and 9,207 DPMI-provider instructions,
with zero exemptions and zero above-i486 instructions.

Artifacts:

- Strict candidate build: `out/local-i486-bsp-double-classification-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-110755/`
- Committed control timedemo: `out/dos-timedemo-20261023-103524/`
