# Promote early light-normal index scaling in the i486 alias transform

The alias transform now scales `tv_lightnormalindex` into its `index * 3`
form as soon as the byte is loaded, then uses that register for the three
normal-vector loads. This overlaps the scale with the remaining vertex and
texture-coordinate work. A zero-extending first-coordinate load clears the
index register for the next loop iteration, replacing the one-time initial
clear while preserving each unsigned byte value.

The candidate was measured against committed control `b6aa155048b2` in the same
aggressive i486 `demo1` timedemo, with
`AliasTransformFinalImplementation=asm` and the pinned 32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
control source-tree fingerprint was
`D18D0097CEC50D1C4388C5CB128532F2D6E2A9CC41636F9830F36D787F812A62`; the
candidate fingerprint was
`1215D37CC792A5F324C5D96D9FC148B6F7213DA6AFA6F3D35B866C2D62AF8D18`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| committed control | 15.626452 / 15.626486 / 15.626488 | 15.626475333 | 0.000036 |
| early normal-index scale | 15.626479 / 15.626519 / 15.626520 | 15.626506 | 0.000041 |

The pooled mean increases by **0.000030667 FPS (+0.000196248%)**. All six runs
rendered 969 frames with framebuffer checksum `1047377823`; enforced frame and
checksum parity passed.

The complete source-bound i486 gate passed: 275,596 project-object instructions,
313,893 linked instructions, 529 startup code rows, and 9,207 DPMI-provider
instructions, with zero above-i486, unknown, or exempt instructions.

Artifacts:

- Candidate build: `out/local-local-alias-transform-normal-index-hoist-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-151853/`
- Committed control timedemo: `out/dos-timedemo-20261023-145333/`
