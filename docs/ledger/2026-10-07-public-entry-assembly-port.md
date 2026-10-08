# Assembly ownership of existing kernel entries

## Calling conventions and direct validation

`r_publicbindingsasm.s` owns thirty-two public entries that formerly delegated
to accepted assembly kernels from C. Direct tail transfers preserve caller
arguments, registers, return addresses and the x87 state. The BSP entry keeps
its `regparm(2)` ABI, with node in EAX and clip flags in EDX. Profiling retains
the line-scan counter and alias-glue stage boundary. Benchmark builds retain
the sprite setup hook. Normal builds do not generate this assembly from C.

Public prototypes remain visible when C definitions are excluded. The direct
test caught the missing sprite beam-length prototype, which had promoted a
float argument to double; the explicit declaration fixes it. The byte check
accepts both valid E9 and EB direct-transfer encodings. The original failed
test is retained in `out/public-bindings-worktree-20261007/out/dos-bench-20261007-200411`.

The corrected full selection passed thirty-one exact tail destinations and
6,144 hook calls under twelve x87 settings, with ABI, descriptor and guard
checks, plus the existing exact alias, sprite, math and animation fixtures.
The mixed default selection passed eight selected tails and the same hook
sequence. Evidence: `dos-bench-20261007-201916` and
`dos-bench-20261007-205044` in the isolated worktree's `out` directory.
Build, rendering-harness and selector-forwarding regressions also pass.

## Public-entry scene acceptance and integration

The focused three-scene, two-repeat comparison matched 6,058 post-warmup frame
checksums and six indexed framebuffers, including every palette byte, exactly.
Both profiles keep the accepted algorithm kernels selected; the public-entry
implementation is the changed selector. Source tree SHA256:
`F613393CF12BC573261B2DDAE3CF0A09B1A31794344D7A07C4EC427D20E2D2F5`. Executables, manifests, linked audits and
the actual execution bindings are retained in
`out/public-bindings-worktree-20261007/out/render-parity-public-bindings-verified-selection-20261007/accepted-artifact-snapshot`.

| Scene | C entries FPS | Assembly entries FPS |
|---|---:|---:|
| demo1-vga-full | 12.5546720 | 12.5538480 |
| demo2-entity-workload | 12.7068050 | 12.7062625 |
| demo3-world-workload | 11.9316460 | 11.9310380 |

The release verification proves all thirty-two entries are assembly-owned
and all twenty-nine earlier assembly modules have identical allocated code,
data and normalized relocations. The isolated release inventory still finds
forty-nine reachable renderer C dependencies; this is incremental acceptance.
Seventy-three reviewed files were integrated with preimages and an allowlist
in `out/public-bindings-integration-preimages-20261007/manifest.json`.
Traceability lives in `docs/renderer-assembly/public-bindings-provenance.json`
and its retained original C definitions. Whole-renderer ownership, indirect
closure, stronger runtime/provider proof and final stability gates remain open.
