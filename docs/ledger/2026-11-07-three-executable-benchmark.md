# NitroQuake, Quake.exe, and 486quake.exe comparison (2026-11-07)

## Method

Benchmark the accepted normal game, `NitroQuake v0.999+7`, against the user's
`tools/QUAKE.EXE` and `tools/486quake.exe`. This measures the delivered game
executables, not the instrumentable `qbench.exe` used for optimization A/Bs.
The earlier approximately 16.824 FPS figure describes that benchmark build;
the fresh normal-game measurement below is a separate executable comparison.

All runs use DOSBox-X 2026.08.31, the pinned 486/387 profile, fixed 33,445
cycles, 32 MiB RAM, the same PAK files, `demo1`, 320x200, and sound, CD audio,
joystick, and mouse disabled. Every run gets fresh staging with no saved user
configuration. The startup script sets `viewsize 100`, disables the legacy
demo loop with an empty `startdemos`, and starts `timedemo demo1`.

Three balanced rounds use these orders: Quake/486quake/NitroQuake,
486quake/NitroQuake/Quake, and NitroQuake/Quake/486quake. All nine completed
samples are retained. No per-frame FPS statistics, checksum streams, or queued
`wait` commands run during measurement. A host watcher reads `qconsole.log`
and terminates only its own emulator process after a valid 969-frame timing
result has been written. Host process elapsed time is not the benchmark time.

Each executable retains its default 320x200 presentation path and cache size.
NitroQuake starts in VGA mode 0, then selects VESA linear BIOS 0x153, mode 17,
pitch 320 and one RAM-copy page before playback. It uses a 2,400 KiB surface
cache; both supplied executables report 320x200 and a 600 KiB cache. This is a
comparison of delivered defaults, not of equalized internal engine settings.

## Results

| Executable | FPS samples | Seconds samples | Median reported FPS | Median seconds |
| --- | --- | --- | ---: | ---: |
| Quake.exe | 13.4, 13.4, 13.4 | 72.4, 72.4, 72.4 | 13.4 | 72.4 |
| 486quake.exe | 14.2, 14.2, 14.2 | 68.2, 68.2, 68.2 | 14.2 | 68.2 |
| NitroQuake v0.999+7 | 16.9, 16.9, 16.9 | 57.4, 57.4, 57.4 | 16.9 | 57.4 |

Every sample completed **969 frames**. All repeats agree at the executables'
printed precision of 0.1 second and 0.1 FPS; this does not prove zero underlying
timing variation. Using median elapsed times for the same frame count gives
NitroQuake approximately **26.1% more FPS than Quake.exe** and **18.8% more FPS
than 486quake.exe**. The chart rounds these gains to approximately 26% and 19%.
These are emulator results; physical 486 performance was not measured.

## Provenance and artifacts

| Input | SHA-256 |
| --- | --- |
| Quake.exe, 409,600 bytes | `E0A1936400CA56E94D44D585097BD9E490035FCFB6E7D806D7E879F423928642` |
| 486quake.exe, 834,560 bytes | `CF461CFA0FEA989AA1E2E834B6D5482B7C64F3279BD7BE56C52F92752FFF429E` |
| NitroQuake game | `D5F878E4F1EB295DA62816CA04777E464E4F242AD942378331ECFCE8EE7185FC` |
| CWSDPMI | `FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883` |
| Normalized profile | `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA` |

The 486quake input has the same hash as the supplied older NitroQuake executable
in the historical benchmark record. Inputs were not modified. The normal game
comes from `out/accepted-linescan-bounds/`, with its complete source-bound
i486 audit and build manifest retained in that bundle's provenance record.

Evidence is under `out/exe-comparison-20261107-hostwatch/`: `results.json`
contains every raw console result and source log path; `verified-summary.json`
contains medians, gains, quantization intervals, and limitations. All nine
staging directories retain their executables, configuration, and console logs.
The failed ninth launch is preserved alongside its successful retry.

The runner is `out/compare-three-executables.ps1`; the independent verifier is
`out/verify-exe-comparison.py`. It checks all nine console results, frame counts,
input/staged executable hashes, PAK/provider hashes, runtime profile contents,
320x200 declarations, empty per-frame command queues, and normal-game manifest.
The chart source is `out/chart-exe-comparison.py`; output files are
`comparison-chart.png`, `comparison-chart.svg`, and `chart-data.csv` in the
evidence directory.

## Setup failures and limits

`out/exe-comparison-20261107/` retains a first setup run that entered the legacy
demo loop without producing a timing result. A second setup under
`out/exe-comparison-20261107-formal/` used queued `wait` commands to capture and
exit automatically. That added command-buffer work to measured frames; it was
stopped and replaced with the host watcher before this nine-sample protocol.
Neither setup is included in the table.

Within the host-watcher protocol, the initial round-three 486quake launch timed
out after 240 seconds without creating a console log or producing frames/time/
FPS. That directory is retained, and only the missing run was retried in
`round-03-quake486-retry-01`. No completed formal sample was discarded.

The supplied executables do not emit framebuffer or depth checksum streams.
This comparison verifies timing and frame counts; it does not establish exact
cross-executable image parity. Renderer promotion remains subject to the
separate exact-output and strict i486 gates.
