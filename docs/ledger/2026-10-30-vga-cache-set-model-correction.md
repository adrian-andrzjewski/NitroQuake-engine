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

The current 320x200 allocation includes a 16-byte pad between `vid_surfcache`
and `lvid->buffer`. Relative to `d_pzbuffer`, `vid_surfcache` begins at byte
128,000 (+64 L1 sets) and `lvid->buffer` begins at byte 1,971,216 (+65 sets).
Without the pad, the buffer offset is 1,971,200 (+64 sets); its 4 KB offset
matches the surface cache's 1,024-byte offset. These are relative set deltas,
not absolute L1 set numbers: the actual 7-bit index depends on the physical
address of `d_pzbuffer`, and the Hunk allocator guarantees 16-byte alignment,
not 2 KB alignment.

The video allocation comes from the high Hunk. Increasing its size by 16 bytes
moves the `d_pzbuffer` and surface-cache base down by 16 bytes while keeping the
framebuffer at the same high-end address in this layout. So the pad changes
the Z/surface-cache set phase relative to the framebuffer and other allocations;
it does not simply move the framebuffer's absolute address. This is a layout
fact, not evidence that the old layout caused a miss or that the new layout
speeds a physical 486.

`tools/486-cost-model.ps1` now includes the allocation pad in its 320x200
default and reports relative L1 set indices. It labels same-set mapping as
potential pressure only. DOSBox-X does not model 486 cache occupancy or
replacement, so its timedemo cannot confirm the cache effect. The 320x200
framebuffer-pad timedemo's tiny positive delta remains an emulator measurement
and does not validate the physical-cache explanation.

### Follow-up (2026-11-02): write-through, no-allocation stores narrow the hypothesis

The earlier set-index calculation omitted an important part of the standard
Intel486 cache policy. The Intel486 Developer's Manual states that the cache is
write-through and that a write miss updates external memory without allocating
a cache line. (The Write-Back Enhanced IntelDX4 is a separate configuration.)
Therefore a cold streaming store does not populate or evict an L1 set. A Z
buffer address mapping to the same set as a texture or instruction line is not
by itself a conflict for `D_DrawZSpans`; set placement can matter there only
when the destination Z line is already resident due to an earlier read. Every
store still reaches external memory, so set coloring does not remove the bus
write traffic.

The current Z layout already has the properties that make its writes orderly:
`Hunk` allocations are guaranteed 16-byte aligned, 320 pixels occupy 640 bytes
per row (40 cache lines), and `zspantable` supplies each row base. The assembly
peels one 16-bit pixel when a span starts at the other dword alignment, then
uses aligned dword stores for its paired-pixel body. This avoids the obvious
unaligned-store and row-crossing cases without adding row padding.

The existing 16-byte pad changes the Z/surface-cache set phase relative to the
framebuffer, while leaving the framebuffer's high-end address fixed in this
allocation. A current-source, three-run recheck produced a -0.0000428% mean
delta (pad vs no pad), below both spreads; the previous tiny positive sign did
not repeat. The six runs had exact final-frame checksum and timedemo-event
parity. See [`2026-10-30-vga-framebuffer-page-offset-pad-promoted.md`](2026-10-30-vga-framebuffer-page-offset-pad-promoted.md)
for the sample table and ISA evidence. This remains a flat DOSBox result, not a
hardware cache measurement. The local benchmark host is a Ryzen 5 3600; no
genuine 486 timing is available. DOSBox-X's `cputype=486` timedemo has no model
of the Intel486 L1 allocation/replacement behavior.

No Z-buffer padding or base-offset change is promoted from this review. A
16-byte-per-row pad would alter the row-to-set phase and may affect later
alias-model depth reads, but the direction and size depend on the actual cache
state and memory system; DOSBox-X cannot measure that effect. A useful follow-up
requires matched timings on physical 486 hardware, with the CPU model, clock,
cache configuration, memory wait states, and effective buffer addresses
recorded. It should compare the isolated Z-span fixture and the same 320x200
969-frame timedemo, and require exact frame output parity.
