# Alias span Z-store after colormap load invalidated by runtime patch site (2026-10-29)

Status: invalidated before timing; no performance result was produced and the source order was restored.

The candidate moved each Z-buffer `movw` between the colormap lookup instruction and the destination-pixel store in the sixteen unrolled `D_PolysetDrawSpans8` sites. The executable built, but the first DOSBox-X launch exited without producing `timedemo.txt`.

## Runtime patch constraint

`D_Aff8Patch` writes the colormap base to each `LPatchN-4` address. Each `LPatch` label must immediately follow its five-byte colormap lookup so that the preceding four bytes are that instruction's displacement. Inserting the Z-buffer store before the label moved the patch address into the store instruction and invalidated the executable. The runner produced neither a timedemo result nor a checksum, so this was not a usable benchmark.

## Disposition

The original instruction order was restored. Future schedules must preserve the colormap lookup's adjacency to its `LPatch` label or deliberately update the patch-site contract before timing.
