# R_RenderFace view-plane order experiment rejected (2026-11-04)

## Candidate

The isolated candidate changed the view clip-plane chain from `0,1,2,3` to
`1,0,2,3`, including the masked-chain setup and the left/right boundary tails.
It was tested in `out/worktree-clipplane-census-20261104` against the matched
packed-BSP control in `out/worktree-bsp-state-pack-20261103`. The candidate
differs in `src/renderer/asm486_experiments.s` and `src/renderer/r_frustumasm.s`; the main
checkout was not changed.

## Parity screen

Both runs used DOSBox-X 2026.08.31, the pinned `i486` profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9B`), `demo1`, and the
fixed-step commands `+host_framerate 0.0783 +con_notifytime -1`. Each recorded
970 frame checksums and ended at framebuffer checksum `1047377823`.

- Control result: `out/worktree-bsp-state-pack-20261103/out/dos-timedemo-20261104-044748/timedemo-result.json`
- Candidate result: `out/worktree-clipplane-census-20261104/out/dos-timedemo-20261104-031203/timedemo-result.json`

The per-frame streams differ at **591 of 970 frames**, starting at frame 0.
The captured frame 695 PCX files also differ: control length 65,161 bytes,
SHA-256 `4f00a71ab1f11b53afc83984d07a0caa44f354245b029ac06471b7e97705642f`;
candidate length 65,168 bytes, SHA-256
`bc9a0c6e6fb6a4436da9fdf59595385d475692b4b344db0d8269d69d779555d5`.
The final framebuffer checksum therefore does not establish parity. No timing
A/B was run, and the candidate is rejected at the parity gate.

## Follow-up lead

The profile-only census at
`out/worktree-clipplane-census-20261104/out/dos-timedemo-20261104-025422/quake/PROFILE.JSN`
reported 777,693 one-entry last-endpoint hits from 2,635,451 world endpoint
plane-distance uses (29.5%). That profile used the reordered chain, so repeat
the census on the stable `0,1,2,3` control before building a distance-cache
candidate. These counters are not timing evidence.
