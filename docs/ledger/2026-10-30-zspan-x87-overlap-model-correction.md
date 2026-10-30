# Z-span x87 latency projection correction

## Correction (2026-10-30)

`tools/486-cost-model.ps1` sums the published latency assigned to each x87
instruction in `LFSpanLoop`. Its 80-cycle/span value and 119.6-million-cycle
profile projection assume those latencies add with no overlap. The Intel
[i486 Microprocessor Hardware Reference Manual](https://www.bitsavers.org/components/intel/80486/1990_i486_Microprocessor_Hardware_Reference_Manual.pdf)
describes the floating-point unit operating in parallel with the integer
arithmetic/logic unit, allowing integer work to overlap floating-point
execution. Therefore the reported 4.46% of instrumented profile time is a
gross no-overlap sum, not measured elapsed time, a hard removable ceiling, or a
predicted speedup.

The Z-span path schedules integer address work between x87 operations, so the
amount hidden by overlap depends on instruction dependencies, FPU throughput,
integer issue, loads, and stalls. DOSBox-X's x87 timing does not reproduce the
486DX pipeline. A meaningful estimate needs an instruction-level critical-path
model; a confirmed speedup needs a real 486DX measurement. The cost-model
report now labels this number as a no-overlap latency sum.
