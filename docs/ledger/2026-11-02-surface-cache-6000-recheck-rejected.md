# Surface-cache 6000 KB recheck (2026-11-02)

## Experiment

Rechecked whether a 6000 KB surface cache improves the 320x200 DOSBox-X
timedemo over the existing 2400 KB default. The cache setting was supplied
with `-surfcachesize`; no source or renderer default was changed. All runs used
the same uninstrumented `qbench.exe`, data root, DOSBox-X 2026.08.31 i486
profile, and source fingerprint
`ADF52EC68EF172A7FA9B2878CA7C74518A1570FA685E94BEA2FA51A12F97AA09`.
The pinned profile SHA-256 was
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

## Timing runs

Five uninstrumented runs per setting were alternated. Every run rendered 969
timedemo frames, ended with framebuffer checksum `1047377823`, passed the
linked i486 ISA audit, and recorded matching timedemo event traces.

| Cache | FPS samples | Median | Range |
| --- | --- | ---: | ---: |
| 2400 KB | 16.346943 / 16.346950 / 16.346954 / 16.346938 / 16.346960 | 16.346950 | 16.346938–16.346960 |
| 6000 KB | 16.349072 / 16.349054 / 16.349049 / 16.349060 / 16.349060 | 16.349060 | 16.349049–16.349072 |

The 6000 KB median is **0.002110 FPS (+0.0129076%)** above the 2400 KB
median. The small timing result is repeatable in these DOSBox-X samples, but
it is not enough to accept the setting without the pixel-stream gate.

## Frame-stream correctness

With `host_framerate 0.05`, two independent 2400 KB checksum runs matched
exactly across all 970 frame records and the summary line. The 6000 KB run
matched the control at the final framebuffer checksum, but differed at **27
frame indices: 2–27 and 48**. The three files each contain 970 frame records
plus the overflow summary. Thus the 6000 KB result is not pixel-exact in this
workload. The checksum evidence does not establish whether those early-frame
differences are visible artifacts; no captured images were compared.

Checksum runs:

- 2400 KB control: `out/dos-timedemo-20261102-202624/`
- 2400 KB repeat: `out/dos-timedemo-20261102-203056/`
- 6000 KB candidate: `out/dos-timedemo-20261102-202907/`

## Disposition and reproduction

Reject the 6000 KB setting as a renderer optimization until the frame
differences are explained and visual output is checked. Keep the 2400 KB
default. DOSBox-X measurements establish only its own timedemo behavior; they
do not establish a cache-performance gain on physical 486 hardware.

From `quake/`, the timing screen can be reproduced with:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -SkipBuild -NoBootstrap -Runs 1 -QuakeExtraArgs '-surfcachesize 2400' -DataRoot .\out\dos-timedemo-20261102-173450\quake\id1
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -SkipBuild -NoBootstrap -Runs 1 -QuakeExtraArgs '-surfcachesize 6000' -DataRoot .\out\dos-timedemo-20261102-173450\quake\id1
```

For the frame-stream check, add `-FrameChecksums -AutoexecCommands
'host_framerate 0.05'` to the same command and compare the resulting
`runs/run-01/framechecksums.txt` files.
