# R_RenderFace zero-clipflags shortcut screen rejected (2026-10-24)

Status: reverted after a negative parity screen. The branch did not reach the
strict i486 ISA gate.

The experiment added `testl %edx,%edx; je .Lrf_clip_ready` after loading the
face clip flags in `R_RenderFace_asm486`. A face with no active clip planes
would bypass the four individual plane tests. The candidate preserved the
framebuffer checksum on every run.

The uninstrumented screen used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with normalized SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with checksum `1047377823`; selector verification
passed. `VisualParityOnly` skipped the ISA audit.

| Variant | Artifact | Run FPS | Mean FPS | Median FPS | Spread |
|---|---|---|---:|---:|---:|
| Control before | `out/dos-timedemo-20261024-165939/timedemo-result.json` | 15.781586 / 15.900726 / 15.900720 | 15.861010667 | 15.900720 | 0.119140 |
| Zero-clipflags branch | `out/dos-timedemo-20261024-170425/timedemo-result.json` | 15.898729 / 15.898791 / 15.898783 | 15.898767667 | 15.898783 | 0.000062 |
| Control after | `out/dos-timedemo-20261024-170903/timedemo-result.json` | 15.900769 / 15.900711 / 15.900718 | 15.900732667 | 15.900718 | 0.000058 |

The first control contains one slow timing outlier. Against the immediate
trailing control, the candidate mean was **−0.001965 FPS (−0.01235792%)**;
every candidate run was slower than every trailing-control run. The candidate
also remained below the accepted strict baseline of 15.900733 FPS. The branch
was reverted and not committed.

Control source fingerprint: `7F9E01194E57986BDF8966E5B6BA8E9D89DFF57335D09FA057A6CBD5EC11434D`.
Candidate source fingerprint: `2D59F8916A458C1F8660959BB8A8377CCA88977BF87C9B25BE7F13E2102C53DD`.
