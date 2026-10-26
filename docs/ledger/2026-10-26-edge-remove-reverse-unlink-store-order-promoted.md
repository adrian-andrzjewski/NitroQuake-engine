# Legacy `R_RemoveEdges` unlink-store order promoted (2026-10-26)

After loading both neighbor pointers, each unlink now writes `prev->next` before `next->prev`. The two stores update distinct link fields, preserve the same list and traversal result, and run in both positions of the two-edge unrolled loop.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the same `testdata\id1` root, the aggressive selector set, and the pinned 32 MB i486 profile with SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| Strict control | `out/dos-timedemo-20261026-030315` | 15.942841 / 15.942841 / 15.942879 | 15.942853667 |
| Candidate parity screen | `out/dos-timedemo-20261026-042547` | 15.942837 / 15.942860 / 15.942869 | 15.942855333 |
| Strict candidate | `out/dos-timedemo-20261026-044845` | 15.942841 / 15.942874 / 15.942874 | 15.942863000 |

The strict mean increased by **0.000009333 FPS (+0.00005854%)**. All six strict runs completed 969 frames with framebuffer checksum `1047377823`. The complete linked i486 audit passed: 314,408 linked instructions, 529 startup rows, and 9,207 provider instructions; zero above-i486, unknown, or exempt instructions. The candidate source-tree fingerprint is `32053DF30673D73FB108843C6132E1605CC866232A376EF6272977FC9C91F57F`.
