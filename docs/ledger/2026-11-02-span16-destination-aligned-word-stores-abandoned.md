# Span16 destination-aligned word stores abandoned (2026-11-02)

## Candidate

The opt-in `TextureSpanStores=wordaligned` path packed pairs of texels into
word stores at even framebuffer addresses. It kept the control interpolation,
tail, row, and load paths. The candidate was built for `-march=i486` and passed
the complete i486 audit: 314,528 relocated instructions, with no above-i486,
unknown, or exempt instructions. Its source hash was
`285293D6E0E9CDA9D858F060076A863F549A6163574119E0E4BF465150E1EF44`.

## Correctness result

The two control runs, `out/dos-timedemo-20261102-202624` and
`out/dos-timedemo-20261102-203056`, had identical 970-frame checksum streams
(SHA-256
`6A5C1EC913D3436B051A5B427FC5945901288D042DE8560B7B0758D7B09085C4`). The
candidate run, `out/dos-timedemo-20261102-215358`, differed on 969 of 970
indexed framebuffer records. Its final checksum was `244721151`, versus
`1047377823` for control; its checksum-stream SHA-256 was
`56B58A61D3E134F79B9725B3C7787EDB5F99B77F6A7157426F2698CA75B902CA`.

Inspection found the first candidate's first aligned pair stored in reversed
byte order. A one-line correction was made after that run, but the corrected
candidate was not rebuilt or rechecked. The mismatch therefore does not
establish whether the corrected path is pixel-exact. No performance result is
claimed; the checksum-instrumented timing is not comparable with normal runs.

## Disposition

The unverified selector and assembly path were removed, leaving the committed
control renderer active. A fresh strict i486 build passed with 314,433 relocated
instructions, zero above-i486 instructions, zero unknowns or exemptions, and
all startup/provider gates passing. Its 970-frame checksum stream matched both
controls exactly, including SHA-256
`6A5C1EC913D3436B051A5B427FC5945901288D042DE8560B7B0758D7B09085C4` and final
checksum `1047377823`. Any future attempt must validate the corrected packing
before measuring performance. No physical 486 test was run.
