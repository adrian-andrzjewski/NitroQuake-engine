# Brush-model splitter-plane victim caches rejected (2026-11-06)

## Candidate and profile

The accepted 128-entry direct-mapped transformed-plane cache still had
conflict misses. Two candidates preserved its common primary-hit path and
added a victim lookup after a primary miss: a four-entry fully associative
scan, followed by a one-entry victim slot.

Each profile covered 41,158 transform requests. The direct-mapped control
reported 27,843 hits and 13,315 misses. The four-entry victim cache reported
31,144 total hits, including 3,301 victim hits, and 10,014 misses. The
one-entry victim cache reported 29,903 total hits, including 2,060 victim
hits, and 11,255 misses. The extra lookups recovered more transforms without
changing the direct-map hit count.

## Exact-output and i486 gates

Both fixed-step candidates matched the 128-entry control byte-for-byte for
the per-frame color checksums, Z checksums, and captured frame 482 PCX. The
checksum streams have SHA-256
`934c3df21f9e2aa11d402f28643ec4ba9331d52450d984fa5a131dcd78737962` and
`1b41d2ab5b0fc99fcca5158c51e4d7b9028cbf4c3ec8dfdf32c6ab96c2db85e8`;
the captured PCX has SHA-256
`82abcb38389d68e1c5c96658b66680c3ab52d50755c384f85ad1df772d760c8d`.
The final framebuffer checksum was `1047377823`.

The one-entry release build passed the complete strict i486 gate: 315,269
relocated instructions, 529 startup code rows, and 9,207 provider
instructions, with zero above-i486, unknown, exempt, or unclassified
instructions. The candidate profile builds also passed their strict audits.

## Matched uninstrumented timing

The release A/B used DOSBox-X 2026.08.31 with the pinned `cputype=486`
profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, and 969 frames. Each run used the same selectors and
`host_framerate 0.0783`, and passed the expected final framebuffer checksum.
The 128-entry baseline was built from the same source revision in a clean
detached worktree.

| Variant | Result folder | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| 128-entry direct map | `out/worktree-bmodel-victim4-control-20261106/out/dos-timedemo-20261105-231254` | 16.780320, 16.780321, 16.780326 | 16.780322333 |
| Four-entry victim | `out/dos-timedemo-20261105-232736` | 16.776911, 16.776906, 16.776906 | 16.776907667 |
| One-entry victim | `out/dos-timedemo-20261106-000013` | 16.778820, 16.778818, 16.778818 | 16.778818667 |

The four-entry layout was **0.020349% slower** than the direct-map control;
the one-entry layout was **0.008961% slower**. All candidate samples were
slower than their matched control samples.

## Conclusion

Reject both victim-cache layouts and retain the 128-entry direct-mapped
cache. The transform savings did not repay the additional miss-path lookup
and replacement work on this workload, even with the one-entry fast path.
