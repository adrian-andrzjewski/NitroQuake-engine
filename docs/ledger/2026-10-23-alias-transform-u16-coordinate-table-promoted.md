# Promote 16-bit indexed coordinate loads in the i486 alias transform

The alias transform's coordinate lookup table now stores 256 unsigned-byte
values as 16-bit integers. `FILD` reads each entry as a signed 16-bit integer;
all values from 0 through 255 remain exact and positive. This halves the table
footprint from 1 KiB to 512 bytes while retaining the same coordinate values.

The candidate was measured against committed control `5c10c8e` in the same
aggressive i486 `demo1` timedemo, with
`AliasTransformFinalImplementation=asm` and the pinned 32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
control source-tree fingerprint was
`76F5321D53335CB7EB2F51F4E1095BDA89F3871D2BE693CCA228F08CE5CA56DE`; the
candidate fingerprint was
`D18D0097CEC50D1C4388C5CB128532F2D6E2A9CC41636F9830F36D787F812A62`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| committed control | 15.626448 / 15.626483 / 15.626486 | 15.626472333 | 0.000038 |
| 16-bit coordinate table | 15.626452 / 15.626486 / 15.626488 | 15.626475333 | 0.000036 |

The pooled mean increases by **0.000003 FPS (+0.000019198%)**. All six runs
rendered 969 frames with framebuffer checksum `1047377823`; enforced frame and
checksum parity passed.

The complete source-bound i486 gate passed: 275,612 project-object instructions,
313,909 linked instructions, 529 startup code rows, and 9,207 DPMI-provider
instructions, with zero above-i486, unknown, or exempt instructions.

Artifacts:

- Candidate build: `out/local-local-alias-transform-u16-coordinate-table-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-145333/`
- Committed control timedemo: `out/dos-timedemo-20261023-142600/`
