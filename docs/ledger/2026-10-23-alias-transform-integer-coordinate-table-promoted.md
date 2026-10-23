# Promote indexed integer coordinate loads in the i486 alias transform

`R_AliasTransformAndProjectFinalVerts` now loads each unsigned vertex coordinate
from a 256-entry table of 32-bit integers with `FILD`. This removes the three
byte stores into `Lcoords` per vertex while retaining the same exact integer
values and x87 conversion path.

The candidate was measured against the current committed control in the same
aggressive i486 `demo1` timedemo, with
`AliasTransformFinalImplementation=asm` and the pinned 32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
control source-tree fingerprint was
`E1288E10805AFDA1C1248BE8B34BB2138BD6B21F6D9537D2AA83B35F03BEA4D3`; the
candidate fingerprint was
`76F5321D53335CB7EB2F51F4E1095BDA89F3871D2BE693CCA228F08CE5CA56DE`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| committed control | 15.620232 / 15.620181 / 15.620175 | 15.620196 | 0.000057 |
| indexed integer coordinate table | 15.626448 / 15.626483 / 15.626486 | 15.626472333 | 0.000038 |

The pooled mean increases by **0.006276333 FPS (+0.04018089%)**. All six runs
rendered 969 frames with framebuffer checksum `1047377823`; enforced frame and
checksum parity passed.

The complete source-bound i486 gate passed: 275,612 project-object instructions,
313,909 linked instructions, 529 startup code rows, and 9,207 DPMI-provider
instructions, with zero above-i486, unknown, or exempt instructions.

Artifacts:

- Candidate build: `out/local-local-alias-transform-integer-octet-lookup-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-142600/`
- Committed control timedemo: `out/dos-timedemo-20261023-130224/`
