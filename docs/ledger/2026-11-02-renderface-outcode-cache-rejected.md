# RenderFace outcode cache rejected (2026-11-02)

## Candidate

The `asm-outcode` experiment cached per-vertex frustum signs and reused them
inside `R_ClipEdge` to avoid repeating some plane-distance calculations. It
was restricted to the assembly `R_RenderFace` path and passed the strict
linked i486 instruction audit (314,612 linked instructions; no above-i486,
unknown, exempt, or unaccounted instructions).

## Correctness result

The candidate failed exact per-frame color-checksum parity. Two 2400 KB
control runs, `out/dos-timedemo-20261102-202624` and
`out/dos-timedemo-20261102-203056`, matched each other. The candidate run at
`out/dos-timedemo-20261102-205756` differed at frames 48, 70, 168, 270, 311,
412, 467, 509, 666, 691, 694, 706, and 948. Its final checksum (`1047377823`)
and event trace matched the controls, which is insufficient to establish
rendering correctness.

The tested binary had source fingerprint
`D5FA7C46362CDDACB7A53CEF1EA091A06100D34E246C480F03D7951B6B7D8145` and
used the pinned DOSBox-X profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
The checksum run took 77.482119 seconds (12.506112 FPS), but checksumming was
enabled, so this is diagnostic-only and must not be compared with uninstrumented
timing samples. No valid performance gain was measured.

The precise cause of the pixel differences was not isolated. A later,
unbuilt source edit attempted to reuse only signs observed during the original
clipper arithmetic; it was also discarded rather than treated as a fix.
The temporary candidate run and binary directories were removed after these
results were recorded; the two matching control runs remain available.

## Disposition

The candidate implementation and `asm-outcode` selector were restored. The
default assembly renderer remains the previously verified path. No part of
this experiment is retained as executable code, and no FPS improvement is
claimed. DOSBox-X parity is the evidence here; no physical 486 test was run.
