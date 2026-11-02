# Span16 linear row-major address delta rejected (2026-11-02)

## Candidate

The `linear` `D_DrawSpans16` selector replaced the two per-pixel S/T
fractional updates with one row-major Q32.32 address accumulator for full
16-pixel segments. The candidate was constrained to word stores and the
control tail, row, and load paths. Its i486 build passed the linked and final
executable ISA audit: 314,450 instructions, with no above-i486, unknown,
exempt, or unaccounted instructions. Candidate source fingerprint:
`A4F7544B0144D2FF5D5D76B9CFBEF4EFE2C94FCB21BDF551D09F8354A1097E12`.

## Correctness result

Two control runs, `out/dos-timedemo-20261102-202624` and
`out/dos-timedemo-20261102-203056`, produced byte-identical checksum streams
(SHA-256
`6A5C1EC913D3436B051A5B427FC5945901288D042DE8560B7B0758D7B09085C4`). The
candidate run, `out/dos-timedemo-20261102-212701`, differed on 969 of the 970
indexed framebuffer records; only the blank frame record matched. Its final
framebuffer checksum was `1068386987`, versus `1047377823` for both controls.
The candidate checksum stream SHA-256 was
`E8E54036FAA5FC1FC33E35D3C146C8A528CEEDF969CA352F36B5DB0C1E00B7BB`.

The run used the pinned DOSBox-X i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Its
checksum-instrumented timedemo reported 969 frames, 74.250233 seconds, and
13.050463 FPS. This timing is diagnostic only and is not comparable with
uninstrumented runs. No performance gain is claimed. The precise cause of the
framebuffer mismatch was not isolated.

## Disposition

The `linear` assembly path and its build/timedemo selector were reverted. The
default renderer remains on the control path. The candidate executable and
run output were temporary and removed after this result was recorded. No
physical 486 test was run.
