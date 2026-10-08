# Surface-cache hit parity correction

Status: the composite assembly implementation is selectable and now matches
the C reference in the deterministic frame-513 replay. The full renderer port
and the remaining scene-suite gates are still ongoing.

## `D_CacheSurface` hit predicate (2026-10-06)

The exact paired framebuffer harness isolated a 21-palette-index difference at
frame 513 to `SurfaceCacheImplementation`. Selecting the C surface-cache path
removed the difference while keeping the other assembly selectors enabled.
The cause was a narrower assembly cache-hit predicate: it always rebuilt a
surface when `dlightframe == r_framecount`, even when the discrete lighting
sample probe found no contributing sample. It also compared all four style
adjustments when `styles[1] == 255`, although the latter three slots are unused
in that case.

`D_CacheSurfaceHit_asm486` now follows the reference hit order for the cache
validity bit, texture, first style adjustment, the unused-style sentinel,
remaining style adjustments, and the dynamic-light probe. The probe remains
`R_DlightContributes`, so its selected C or assembly implementation is shared
with the rest of the renderer. The focused `bench486` fixture checks clean and
sticky hits, current-frame phantom and unlit marks, a lit sample, texture and
style-key misses, and the unused-style case.

Evidence:

- `tools/bench-dos.ps1 -SurfaceCacheOnly -SurfaceCacheImplementation asm -NoBootstrap`
  passed in DOSBox-X configured as an i486. Cache setup/key, tag, entry,
  allocator, and attach/tag checks also passed.
- The post-link audit inspected 103 renderer/support objects: 193,954 decoded
  instructions, zero enforced instructions above i486, zero unknown
  instructions, and the one existing data-only CRC-table MMX exemption.
- `render-parity-dos.ps1` passed for the full 969-frame Demo 1 replay with the
  C reference and selectable assembly profiles. After six warmup records, all
  964 compared checksum records matched. The frame-513 PCX matched exactly:
  64,000 pixel indices and all 768 palette bytes, with zero differences.
- Both input runs matched checksum `1047377823`; the shared source-tree
  fingerprint was `E38D061E6831EAEE031832B18F3A09EE555F023324F9971FECB483601FDEF0B4`.

The pair result is retained at
`out/surfacecache-fix-parity-20261006/render-parity-result.json`; the exact
framebuffer diff is under `out/surfacecache-fix-parity-20261006/framebuffer-diffs/`.
The remaining completion gate is the full representative scene suite and the
other required CPU, stability, and renderer-coverage checks.
