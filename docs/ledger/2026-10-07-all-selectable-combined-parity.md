# Combined renderer parity after math support integration

## Exact six-scene comparison

The frozen main snapshot passed all six committed scenes twice with the C
reference and all current assembly selectors. Actual build manifests verified
the requested selectors before every emulator run. The pair compared 11,842
post-warmup frame checksums and twelve indexed framebuffers, including every
palette byte, exactly. There were no unexplained differences or image tolerances
in this paired gate. Both sides used source tree SHA256
`8DBDF2A38FDC195EAB4680A07A90370013D3BF6D584D10DB51E6995636284AFB`.

Evidence: `out/render-parity-all-selectable-integrated-math-20261007`.
The accepted executables, linked audit reports and verification records are
retained in its `accepted-artifact-snapshot` directory. Reference/candidate
executable SHA256 values are `A0FA84DA14F12DEFBB07895C7E1250FBCE517B361FDF51BF5A11176164AB1D85`
and `5A125802E7F0D7658315135632883D158F55FCDE59EF7DAB3C3A1DFB523FB6EC`. Their linked
instruction checks covered 224,892
and 243,207 sites
under the then-current classifier. The stronger classifier and external runtime
proof remain separate completion obligations.

The six leading checksum entries per run follow the existing startup/warmup
contract. This exclusion does not permit differences in any later frame or any
captured pixel/palette byte. Historical all-selector pixel differences do not
describe this accepted snapshot: its paired output is exact.

## Regression measurements and remaining scope

The emulator used the pinned DOSBox-X 2026.08.31 profile, `cputype=486`, fixed
33,445 cycles and authored `host_framerate 0.0783` demo playback. Median FPS:

| Scene | C reference | Assembly selections |
|---|---:|---:|
| demo1-vesa-full | 12.6464285 | 12.5570765 |
| demo1-vga-full | 12.6821475 | 12.5546630 |
| demo1-fullbright | 13.1021620 | 12.9611410 |
| demo1-viewsize-50 | 18.0652230 | 17.6889165 |
| demo2-entity-workload | 12.7816095 | 12.7068715 |
| demo3-world-workload | 12.1748535 | 11.9315995 |

The roughly 0.6 to 2.1 percent differences do not show a catastrophic regression
and do not trigger algorithm changes for speed. The source inventory still
contains renderer-time C ownership: the post-math direct-call inventory found
71 reachable C entries before the visibility port. Indirect targets and the
complete support scope require further review. This comparison accepts the
combined incremental work; it does not declare the complete assembly goal done.
