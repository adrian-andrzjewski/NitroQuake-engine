# Assembly surface-cache dynamic-light probe census

<!-- optimization-attempts: none -->

## Scope

The 2026-11-08 engine report showed zero dynamic-light probe counts because its
counters covered the C reference helper while the measured build selected the
assembly `D_CacheSurface` path. This change adds counts at that active assembly
call site under `PROFILE486`; it measures probe population and predicate results,
not elapsed time or a production optimization.

## Instrumentation

`D_CacheSurface` increments `bench486_surface_cache_dlight_probes` immediately
before `R_DlightContributes` and increments
`bench486_surface_cache_dlight_contributing_probes` when the predicate returns
true. Both references and increments are guarded by `PROFILE486`. The
non-profile branch retains the original test and branch sequence. The counters
already existed in the benchmark report and C reference path; this change closes
the selected-assembly coverage gap.

## Results

Runs used detailed profiling at 320x200 with a fixed 0.0625 simulation step,
64 warm-up frames, god mode, continuous forward movement and attack, and sound
disabled. The runner verified the active local map and frame count.

| Workload | Frames | Probes | Contributing | Non-contributing | Probes/frame |
| --- | ---: | ---: | ---: | ---: | ---: |
| e1m1 | 256 | 193 | 188 | 5 | 0.754 |
| e1m2 | 256 | 137 | 126 | 11 | 0.535 |
| Combined | 512 | 330 | 314 | 16 | 0.645 |

A separate 64-frame e1m2 capture saw 106 probes, all contributing. Its shorter
initial interval is retained as a separate run and is not pooled with the two
256-frame captures.

The 16 false predicates are 4.85% of the combined probes. Their presence shows
that a marked surface does not always receive a contributing dynamic light, so
the result does not justify skipping the predicate. The probe rate is low, and
the profile data reports zero `dlight_probe_seconds` because this assembly census
counts calls but does not time them.

## Interpretation

The earlier zero was an instrumentation coverage gap, not evidence of zero
dynamic-light work. These measurements establish only the population and outcome
of this check in two scripted local scenes. Detailed profiling is intrusive;
its elapsed time and FPS are not suitable for attributing production cost or
claiming a speed gain. No renderer optimization is proposed from this census.

## Reproduction and retained artifacts

From the worktree root, build the profile executable with:

```powershell
rtk proxy pwsh -NoProfile -File tools/build-dos.ps1 `
  -Benchmark -Instrumentation -CpuTarget i486 -NoBootstrap `
  -LocalOutputDirectoryName dlight-census-profile-v1
```

From the outer repository root, set `GameRoot` to this worktree and run both
workloads with:

```powershell
$GameRoot = (Resolve-Path .\quake\out\dlight-census-20261109).Path
$DataRoot = (Resolve-Path .\quake\testdata\id1).Path
rtk proxy pwsh -NoProfile -File .\benchmarks\tools\engine-profile-dos.ps1 `
  -GameRoot $GameRoot -LocalOutputDirectoryName dlight-census-profile-v1 `
  -DataRoot $DataRoot -Workload e1m1 -Mode detailed -Instrumentation `
  -Frames 256 -WarmupFrames 64 `
  -ResultJson .\benchmarks\out\dlight-census-e1m1-20261109.json
rtk proxy pwsh -NoProfile -File .\benchmarks\tools\engine-profile-dos.ps1 `
  -GameRoot $GameRoot -LocalOutputDirectoryName dlight-census-profile-v1 `
  -DataRoot $DataRoot -Workload e1m2 -Mode detailed -Instrumentation `
  -Frames 256 -WarmupFrames 64 `
  -ResultJson .\benchmarks\out\dlight-census-e1m2-256-20261109.json
```

The JSON captures retain the exact console commands, options, staged data hashes,
executable identity, profiler data, and result checksums. Generated captures
remain in the ignored `benchmarks/out` directory and are excluded from Git.

The two 256-frame captures used executable SHA-256
`4A52606F588686A5DD88FA6324A99CA42EA541A3558F14422693F3259E7A5C16` and source
tree fingerprint
`35FC970A2C71CB0914D8233F88D570B2AFD2FA90ACF97AAD069FC476C9FB341B`.
Their final checksums were e1m1 simulation `2568184557` / framebuffer
`1299435123`, and e1m2 simulation `1496920581` / framebuffer `1246513233`.

| Capture | Frames | JSON SHA-256 |
| --- | ---: | --- |
| `dlight-census-e1m1-20261109.json` | 256 | `dc4c58ea631d7a8f414402c6d6a3a0a0ff69b00e926f17e064cd9b837387a2f1` |
| `dlight-census-e1m2-256-20261109.json` | 256 | `8238183db0428d361fe95961a153e05fb4ab05c1645bc12737f599ab3330bc8d` |
| `dlight-census-e1m2-20261109.json` | 64 | `b8f65ec247feb57e0dc28082068266d73b8caae428befd99e3077a06abc24a02` |

Both profile and release builds passed the complete source-bound i486 gate.
The profile executable audit covered 324,191 relocated instructions, 529
startup instructions, and 9,207 DPMI-provider instructions; the release audit
covered 163,878 relocated instructions plus the same startup and provider
inputs. Neither reported above-i486, unknown, or exempt instructions.
