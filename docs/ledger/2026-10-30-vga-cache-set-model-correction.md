# 320x200 VGA cache-set model correction

## Correction (2026-10-30)

The 2026-09-29 cost-model entry correctly computed equal 4 KB offsets for the
surface cache and framebuffer and said the resulting stall was unmodeled. It
called the offset match a confirmed “4 KB aliasing” precondition. More precisely,
the calculation establishes that corresponding 16-byte lines select the same
L1 set. The i486 has an 8 KB unified, four-way set-associative cache with 128
sets and 16-byte lines; set congruence alone does not establish contention,
eviction, or a stall. The Intel [i486 Microprocessor Hardware Reference
Manual](https://www.bitsavers.org/components/intel/80486/1990_i486_Microprocessor_Hardware_Reference_Manual.pdf)
describes this organization.

The current 320x200 allocation includes a 16-byte framebuffer pad. Relative to
the video allocation base, `vid_surfcache` begins at byte 128,000 (set 64) and
`lvid->buffer` begins at byte 1,971,216 (set 65). Without the pad, the buffer
would begin at byte 1,971,200 (set 64); its 4 KB offset would match the surface
cache's 1,024-byte offset. The pad changes the set index by one while retaining
16-byte alignment. This is a layout fact, not evidence that the old layout
caused a miss or that the new layout speeds a physical 486.

`tools/486-cost-model.ps1` now includes the allocation pad in its 320x200
default and reports relative L1 set indices. It labels same-set mapping as
potential pressure only. DOSBox-X does not model 486 cache occupancy or
replacement, so its timedemo cannot confirm the cache effect. The 320x200
framebuffer-pad timedemo's tiny positive delta remains an emulator measurement
and does not validate the physical-cache explanation.
