# Promote integer distance classification in the i486 brush polygon clipper

`R_RecursiveClipBPoly_asm486` stores each plane distance as IEEE-754 binary32.
The two strict-positive tests now load the stored word, decrement it, and use
an unsigned bound (`<= 0x7f7fffff`) to branch only for positive values. This
preserves the `dist > 0` branch result for signed zero, finite values,
infinities, and NaNs while removing each `FLDS` / `FTST` / `FNSTSW` / `SAHF` /
`FSTP` status-word round trip.

The candidate was measured against committed baseline `86ea2be` in the same
aggressive i486 profile with `BmodelPolygonClipImplementation=asm`. Both used
the pinned 32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
baseline mean was `15.607526667 FPS`; its source-tree fingerprint was
`DBA93D6460B0F1EAA01BF247E858DA4AB761A30E43A952B5FA4BBB25432F0B86`. The
candidate source-tree fingerprint was
`F8E4702568F8E8C19CEC366D9AA1FC65526E13469543348627D010C9289352ED`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| committed control | 15.607526 / 15.607526 / 15.607528 | 15.607526667 | 0.000002 |
| integer distance tests | 15.615207 / 15.615195 / 15.615200 | 15.615200667 | 0.000012 |

The change gains **0.007674 FPS (+0.04916858%)**. All six runs rendered 969
frames with framebuffer checksum `1047377823`; the enforced frame and checksum
parity gates passed.

The complete source-bound i486 ISA gate passed: 313,922 relocated executable
instructions, 529 startup code rows, and 9,207 DPMI-provider instructions,
with zero exemptions and zero above-i486 instructions.

Artifacts:

- Strict candidate build: `out/local-i486-bmodel-poly-positive-int-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-103524/`
- Committed control timedemo: `out/dos-timedemo-20261023-100243/`
