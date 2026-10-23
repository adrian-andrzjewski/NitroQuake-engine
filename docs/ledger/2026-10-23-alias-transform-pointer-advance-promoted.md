# Promote pointer scheduling in the i486 alias transform loop

`R_AliasTransformAndProjectFinalVerts` now advances the source vertex pointer
after reading `tv_lightnormalindex` and the texture-coordinate pointer after
reading `stv_onseam`. These increments are independent of the remaining x87
transform and projection work, so the integer updates can execute while the
FPU finishes the current vertex. The transform arithmetic, x87 operation
order, and output stores are unchanged.

The candidate was measured against committed baseline `cd5f7f0` in the same
aggressive i486 `demo1` timedemo, with `AliasTransformFinalImplementation=asm`
and the pinned 32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
control source-tree fingerprint was
`96C96977F707892488EAB0D75644B880CF1D7B7D6C0028A75260091B26C53D94`; the
candidate fingerprint was
`E1288E10805AFDA1C1248BE8B34BB2138BD6B21F6D9537D2AA83B35F03BEA4D3`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| committed control | 15.620187 / 15.620171 / 15.620176 | 15.620178 | 0.000016 |
| pointer advances after final reads | 15.620232 / 15.620181 / 15.620175 | 15.620196 | 0.000057 |

The pooled mean increases by **0.000018 FPS (+0.0001152%)**. All six runs
rendered 969 frames with framebuffer checksum `1047377823`; enforced frame and
checksum parity passed.

The complete source-bound i486 ISA gate passed: 313,897 relocated executable
instructions, 529 startup code rows, and 9,207 DPMI-provider instructions,
with zero exemptions and zero above-i486 instructions.

Artifacts:

- Strict candidate build: `out/local-local-alias-transform-pointer-advance-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-130224/`
- Committed control timedemo: `out/dos-timedemo-20261023-113600/`
