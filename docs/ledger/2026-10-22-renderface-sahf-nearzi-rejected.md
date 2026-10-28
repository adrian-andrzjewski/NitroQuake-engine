# Reject `SAHF/JNA` for the RenderFace nearzi update

Replacing the cached-edge nearzi status-mask test with `SAHF` plus `JNA`
preserved exact output and passed the full linked strict i486 audit, but its
three-run mean was negative. The original `testb $0x45,%ah` / `jnz` sequence
has been restored.

| Variant | FPS samples | Mean |
|---|---|---:|
| Current `testb` / `jnz` control | 15.564257, 15.564254, 15.564249 | 15.564253333 |
| Candidate `sahf` / `jna` | 15.563354, 15.563333, 15.563361 | 15.563349333 |

The candidate delta was **−0.000904 FPS (−0.00580818%)**. Both variants used
the pinned DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`RenderFaceImplementation=asm`, `EdgeListMaintenanceImplementation=asm`,
three uninstrumented `demo1` runs, and 969 frames with checksum `1047377823` on
every run. The candidate passed the strict i486 ISA audit with 313,316 linked
instructions, 435 code ranges, zero above-i486 instructions, and zero
exemptions.

Artifacts:

- Control: `out/dos-timedemo-20261022-013532/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-020040/timedemo-result.json`

The negative mean rejects this instruction substitution. The restored
`src/asm486_experiments.s` SHA-256 is
`740265FC97698A2CFE34B875EB3E61519715C9C8EF9DE563AEA94E8F768776A2`.
