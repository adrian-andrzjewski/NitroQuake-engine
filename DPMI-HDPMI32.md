# DPMI host experiment: CWSDPMI vs HDPMI32

Experiment date (UTC): 2026-09-15. Engine binary unchanged; only the external
DPMI server and staging/launch path differed.

## Goal

Determine whether Japheth's **HDPMI32** provides a measurable performance
benefit over the project's vendored **CWSDPMI** on the pinned DOSBox-X
486-class profile, without modifying the Quake engine.

## Setup

| Item | Value |
| --- | --- |
| Binary | Same `out\dos\qbench.exe` for both arms |
| Demo | `demo1` (969 frames) |
| Emulator | DOSBox-X 2026.08.31, `tools\dosbox-x-486-high.conf` (`cputype=486`, fixed 33445 cycles, 16 MB) |
| Flags | `-timedemoexit -fpsstats -nosound -nojoy -nomouse -nocdaudio` |
| Runs | 5 per host |
| Engine edits | None |

### CWSDPMI (control)

- Stage `src\cwsdpmi.exe` beside `qbench.exe`.
- DJGPP GO32 stub auto-loads `CWSDPMI.EXE` when no DPMI host is resident.
- SHA-256: `0A890815DF6CBDC052915A856C16944CEDEC825267E7B6E453C351A0CDC695F2`
- Result: `out\dos-timedemo-20260915-084120\timedemo-result.json`

### HDPMI32 (treatment)

- Vendored from HX runtime 2.20 (`tools\thirdparty\hdpmi\`; see `SOURCE.txt`).
- Stage `HDPMI32.EXE` and **omit** `cwsdpmi.exe` so the stub cannot auto-load CWSDPMI.
- Launch: `HDPMI32 -r`, then `DPMI.EXE` identity probe, then `qbench.exe`.
- Probe confirmed `vendor: 'HDPMI', version: 3.20`.
- SHA-256: `F9C1A21A0673B9E771AC0BFE09AE11E90E264882AC067E27E94DEA2AACA66415`
- Result: `out\dos-timedemo-hdpmi32-20260915-084734\timedemo-result.json`

### How to reproduce

```powershell
.\tools\timedemo-dos.ps1 -SkipBuild -DpmiHost cwsdpmi -Runs 5
.\tools\timedemo-dos.ps1 -SkipBuild -DpmiHost hdpmi32 -Runs 5
# Or both, with a merged report:
.\tools\compare-dpmi-dos.ps1 -SkipBuild -Runs 5
```

## Results (5 runs each)

| Host | Median FPS | Duration (s) | 1% low | 0.1% low | High 1% | Stddev | Drops | Spikes | FPS range | Checksum |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| CWSDPMI | 15.205703 | 63.726091 | 7.321064 | 6.731469 | 28.323158 | 4.543760 | 120 | 264 | 0.000066 | **4154140932** |
| HDPMI32 -r | 15.213613 | 63.692958 | 7.328464 | 6.732913 | 28.321388 | 4.539461 | 122 | 264 | 0.325214 | **2955717646** |

Per-run averages:

- CWSDPMI: `15.205649 / 15.205705 / 15.205700 / 15.205715 / 15.205703` (all checksum `4154140932`)
- HDPMI32: `15.213593 / 15.213621 / 15.213613 / 15.213633 / 14.888419` (all checksum `2955717646`)

Delta (HDPMI − CWSDPMI), median FPS: **+0.007910 (+0.052%)**, duration **−33.1 ms**.
CWSDPMI noise floor across five runs is ~0.00007 FPS; HDPMI's fifth run hitched to
14.888 FPS, widening its range to 0.325 FPS.

## Compatibility observations

1. **Resident host works.** With `cwsdpmi.exe` absent and `HDPMI32 -r` installed,
   Quake starts as a DPMI client of HDPMI (probe vendor string `HDPMI` 3.20).
2. **Completes timedemo.** All five HDPMI runs finished 969 frames without a
   hard crash under the 486 DOSBox-X profile.
3. **Framebuffer mismatch.** Every HDPMI run produced checksum `2955717646`
   instead of the known-good `4154140932`. That hash previously appeared when
   oversized surface-cache experiments corrupted rendering parity; it is a hard
   gate failure for this project.
4. **Variants still mismatched.** Also tried (1 run each), all still `2955717646`:
   - `HDPMI32 -r -m` (disable DPMI 1.0 memory APIs; DJGPP hint from HDPMI.TXT)
   - `HDPMI=512` then `-r` (low system tables)
   - `-r -a -m` (separate address contexts + `-m`)
   - `-r` without the `DPMI.EXE` probe
   - `-heapsize 10240` clamp (CWSDPMI kept `4154140932`; HDPMI still mismatched)
5. **Stability.** CWSDPMI run-to-run spread is effectively measurement noise.
   HDPMI produced one clear hitch (~1.4 s slower) in the five-run series.

## Likely source of differences (not “faster mode switches”)

Quake's DOS path (`Sys_GetMemory` / `dos_getmaxlockedmem` in `sys_dos.c`) sizes
and locks the heap from DPMI free-memory information. HDPMI reports a different
memory geometry (very large address space, different lockable-page figures) than
CWSDPMI under the same 16 MB DOSBox-X VM.

The persistent checksum failure even after `-heapsize` clamping indicates the
divergence is not only “more heap bytes,” but deeper host semantics Quake relies
on: linear-region locking, paging/sbrk behavior, and/or how uninitialized or
guarded pages are presented to DJGPP. That aligns with a memory-management /
DPMI-service difference rather than a pure protected-mode transition or IRQ
fast-path win.

Any raw FPS delta therefore compares **different rendered frames**, so it is not
evidence that HDPMI is a faster DPMI server for the same workload.

## Conclusion

**Do not make HDPMI32 the preferred DPMI configuration** for the optimized 486
build.

- Compatibility fails the project's framebuffer checksum gate on every run.
- Apparent median FPS gain (~0.05%) is smaller than HDPMI's own hitch range and
  measures a different pixel stream.
- CWSDPMI remains extremely consistent and produces the known-good checksum.

Keep staging `cwsdpmi.exe` as today. Retain the `-DpmiHost hdpmi32` tooling for
future retests only; do not promote HDPMI into smoke/default launch paths.
