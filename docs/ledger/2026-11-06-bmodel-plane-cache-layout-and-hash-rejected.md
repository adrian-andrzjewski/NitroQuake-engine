# Brush-plane cache layout and hash variants rejected (2026-11-06)

## Candidate variants

Two variants attempted to improve the accepted 128-entry direct-mapped cache
without adding a collision probe. The packed-record layout stored each
three-word key and four transformed float words in a 32-byte aligned entry;
its BSS grew from 3,584 to 4,096 bytes. The folded-hash layout retained the
original arrays and used
`((plane_pointer >> 2) ^ (plane_pointer >> 9)) & 127` for slot selection.

The packed-record profile retained the 128-entry control's 27,843 hits and
13,315 misses. XOR folding produced 28,256 hits and 12,902 misses, recovering
413 transforms but adding address-mixing instructions to every lookup.

## Exact-output and i486 gates

Both fixed-step candidates matched the 128-entry control byte-for-byte for
all per-frame color and Z checksum records and captured frame 482 PCX. The
checksum streams have SHA-256
`934c3df21f9e2aa11d402f28643ec4ba9331d52450d984fa5a131dcd78737962` and
`1b41d2ab5b0fc99fcca5158c51e4d7b9028cbf4c3ec8dfdf32c6ab96c2db85e8`;
the captured PCX has SHA-256
`82abcb38389d68e1c5c96658b66680c3ab52d50755c384f85ad1df772d760c8d`.
The final framebuffer checksum was `1047377823`.

Both release builds passed the complete strict i486 audit with zero
above-i486, unknown, exempt, or unclassified instructions. The packed-record
build audited 315,198 relocated instructions; the folded-hash build audited
315,190. Each audit also covered 529 startup rows and 9,207 provider
instructions.

## Matched uninstrumented timing

The release A/B used DOSBox-X 2026.08.31 and the pinned 320x200 `demo1`
`cputype=486` profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). All
runs used the same selectors, 969 frames, `host_framerate 0.0783`, data root,
and expected final framebuffer checksum. The 128-entry baseline came from a
clean detached worktree with the same renderer source contents.

| Variant | Result folder | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| 128-entry baseline | `out/worktree-bmodel-victim4-control-20261106/out/dos-timedemo-20261105-231254` | 16.780320, 16.780321, 16.780326 | 16.780322333 |
| Packed 32-byte records | `out/dos-timedemo-20261106-003815` | 16.780200, 16.780204, 16.780204 | 16.780202667 |
| XOR-folded hash | `out/dos-timedemo-20261106-010913` | 16.779575, 16.779579, 16.779579 | 16.779577667 |

The packed-record mean was **0.000713% slower** than the baseline. XOR
folding was **0.004438% slower**. Every candidate sample was slower than its
matched control sample.

## Conclusion

Reject both variants and retain the separate-array layout with the original
128-entry hash. The packed layout did not improve hit counts, and the folded
hash's 413 recovered transforms did not repay its per-request arithmetic.
The subsequent 256-entry direct-map capacity test is recorded in the
[promotion ledger](2026-11-06-bmodel-plane-transform-cache256-promoted.md).
