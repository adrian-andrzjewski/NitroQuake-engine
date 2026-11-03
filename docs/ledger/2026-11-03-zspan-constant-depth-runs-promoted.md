# Z-span monotone constant-depth runs promoted (2026-11-03)

Status: promoted after exact C/assembly oracle parity, exact timedemo frame-stream
parity, repeatable uninstrumented 320x200 DOSBox-X gains, and the complete strict
i486 audit.

## Optimization

The positive- and negative-gradient `D_DrawZSpans` paths already reject
overflowing or sign-invalid endpoints. On the remaining monotone sequence, equal
upper 16-bit words at the first and last depth samples prove that every stored Z
sample has the same value. The new branch fills those spans directly. It writes
an optional leading word for alignment, uses `rep stosl` for paired 16-bit Z
values, then writes an optional trailing word. Boundary-crossing spans continue
through the original per-pixel path.

The direct fixture grew from 165 to 169 cases. It now covers positive and
negative one-unit steps that remain within one stored depth word, plus positive
and negative steps that cross a 16-bit boundary. The candidate matched the C
oracle on all 169 cases. A profiled `demo1` run counted 36,547 constant-depth
runs covering 1,831,538 of 42,018,689 Z-span pixels.

## Correctness and compatibility

The benchmark used the pinned DOSBox-X 2026.08.31 profile, `cputype=486`,
`fpu=387`, fixed 33,445 cycles, `demo1`, and 320x200 output. With
`host_framerate 0.0783` and `con_notifytime -1`, two control runs matched all
970 per-frame checksums. The candidate then matched the control on all 970
checksums, and its captured frame 482 was pixel-identical: 0 of 64,000 pixels
changed and the palette matched.

The strict i486 gate passed 314,604 relocated instructions across 435
executable ranges, 529 startup rows, and 9,207 provider instructions. There
were zero above-i486, unknown, exempt, or undecoded instructions.

## Timings

Each row is three uninstrumented `timedemo-dos.ps1` runs with the same data,
demo, profile, host-framerate command, and notification setting. All nine runs
rendered 969 frames and ended at checksum `1047377823`.

| Variant | FPS samples | Mean FPS | Median FPS |
|---|---|---:|---:|
| Control | 16.464303 / 16.335735 / 16.464304 | 16.421447333 | 16.464303 |
| Constant fill with word stores | 16.480183 / 16.480183 / 16.480184 | 16.480183333 | 16.480183 |
| Constant fill with aligned `rep stosl` | 16.484395 / 16.484395 / 16.484396 | 16.484395333 | 16.484395 |

The control median improved by **0.020092 FPS (+0.1220%)** with `rep stosl`;
the word-store to `rep stosl` step added **0.004212 FPS (+0.0256%)**. Across
all three samples, the arithmetic mean increased by **0.062948 FPS (+0.3833%)**,
but one control sample was a slow outlier. The medians and every sample are
recorded so that outlier does not define the steady-state estimate. These are
DOSBox measurements; no physical 486 result is claimed.

## Artifacts

- Control timing: `out/dos-timedemo-20261103-115813/timedemo-result.json`
- Word-store timing: `out/worktree-zspan-constant-run-20261103/out/dos-timedemo-20261103-122010/timedemo-result.json`
- `rep stosl` timing: `out/worktree-zspan-constant-run-stosd-20261103/out/dos-timedemo-20261103-120149/timedemo-result.json`
- Exact frame comparison: control `out/dos-timedemo-20261103-115225/runs/run-01/framechecksums.txt` and capture `frame.pcx`; candidate `out/worktree-zspan-constant-run-stosd-20261103/out/dos-timedemo-20261103-115551/runs/run-01/framechecksums.txt` and capture `frame.pcx`.
