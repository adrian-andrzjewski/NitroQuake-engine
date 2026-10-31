# i486 Z-span start schedule promoted; RenderFace no-clip entry rejected (2026-10-31)

## Promoted: Z-span start schedule

`D_DrawZSpans` now has an i486-default schedule that moves the `d_ziorigin`
addition ahead of the final x87 exchange in both positive and negative
gradient loops, removing the second `fxch` from each setup. It keeps the
fixed-point depth updates, pixel stores, and per-sample multiply/add
operations. The reordered single-precision x87 operations can change a few
rendered pixels.

Three uninstrumented 320x200 `demo1` runs on DOSBox-X 2026.08.31 with
`cputype=486`, fixed 33445 cycles, and the pinned 969-frame profile gave:

| Run | Control FPS | Candidate FPS | Delta FPS |
|---:|---:|---:|---:|
| 1 | 16.331571 | 16.343224 | +0.011653 |
| 2 | 16.331577 | 16.343248 | +0.011671 |
| 3 | 16.331575 | 16.343232 | +0.011657 |
| **Mean** | **16.331574** | **16.343235** | **+0.011660 (+0.0714%)** |

Every full run reached 969 frames and final checksum `1047377823`. The focused
Z-span fixture passed 117 guarded C/assembly depth-buffer cases with zero
mismatches. The complete candidate i486 audit found 314,336 linked/executable
instructions, 529 startup rows, and 9,207 provider instructions, with no
above-i486 or unknown instructions and no exemptions.

The candidate frame-checksum stream differs from its control at 35 recorded
frame indices. The frame-99 captures differed at 37 of 64,000 pixels
(0.0578%), mean absolute channel error 0.00501, and maximum channel error 56.
The user accepted this measured visual delta because the timedemo was faster.
The schedule is now the default for omitted i486 build/benchmark selectors;
`-ZSpanStartSchedule control` remains available, and i386 remains on control.

## Rejected: direct no-clip entry from `R_RenderFace`

The experiment branched around `R_ClipEdge`'s clip-pointer load/null test when
`RF_PCLIP` was zero, then entered the shared edge emitter through a small
no-clip entry point. It passed the complete i486 instruction audit, but three
uninstrumented runs were slower than the matched control:

| Run | Control FPS | Candidate FPS | Delta FPS |
|---:|---:|---:|---:|
| 1 | 16.331571 | 16.320498 | -0.011073 |
| 2 | 16.331577 | 16.320485 | -0.011092 |
| 3 | 16.331575 | 16.320479 | -0.011096 |
| **Mean** | **16.331574** | **16.320487** | **-0.011087 (-0.0679%)** |

Every run reached 969 frames and checksum `1047377823`. Its frame-99 capture
differed from a repeated control capture at 49 pixels; a repeated pair of
control captures differed at one pixel. Because it was slower and changed the
captured frame more than the accepted Z-span schedule, the helper, call-site
branches, and selector plumbing were removed.

## Artifacts

- Z-span candidate timings: `out/dos-timedemo-20261031-063217`
- Z-span control timings: `out/dos-timedemo-20261031-065339`
- Z-span frame capture/checksums: `out/dos-timedemo-20261031-065009`
- Direct-entry candidate timings: `out/dos-timedemo-20261031-071736`
- Direct-entry visual capture: `out/dos-timedemo-20261031-071305`
- Repeated control visual capture: `out/dos-timedemo-20261031-071524`
