# World-render orchestration assembly port

Status: ongoing renderer port. This entry records the selectable conversion of
`R_RenderWorld`; it does not close the software-renderer conversion or its
render-time dependency closure.

## `R_RenderWorld` now has a selectable i486 assembly entry

`RenderWorldImplementation=c|asm` selects the orchestration routine. The C
implementation remains the release default and benchmark reference. The
assembly routine allocates the 5000-entry back-to-front polygon queue in its
frame, initializes `pbtofpolys`, `currententity`, `modelorg`, and
`r_pcurrentvertbase`, calls the selected BSP walk, and replays queued polygons
back to front when requested. Compile-time layout checks pin the 32-bit entity,
model, and polygon-queue fields read by the assembly.

The first DOS run faulted after the BSP walk completed. A temporary trace
isolated the fault to the assembly epilogue: it reset `ESP` before restoring
the saved callee registers. The epilogue now restores `EDI`, `ESI`, `EBX`, and
`EBP` from their saved stack slots before returning. The temporary trace code
was removed.

The clean assembly timedemo completed 969 frames in `59.170603 s` with the
pinned framebuffer checksum `1047377823`; DOS smoke passed. The release ISA
gate passed at 168 enforced above-i486 instructions versus the 170-instruction
baseline. The qbench ISA gate passed at 172 versus its 173-instruction
baseline. These single timing samples do not establish a performance gain, so
the assembly selector remains opt-in.

For a framebuffer diagnostic, the built-in PCX writer captured the last
timedemo frame from the C and assembly selectors. Both runs completed 969
frames with checksum `1047377823`; the resulting 320x200 PCX files were
byte-for-byte identical (SHA-256
`B4B737FE7A0ADB5E88D9D4CE698EB7C23C723F7DF84BA7FD61A762011BC44D5E`). This
checks the rendered buffer for the pinned demo, not DOSBox-X's live window
presentation. The user has reported smear in the live display, so visual
acceptance remains pending a capture of that reproduction and its launch
configuration.

A follow-up live `playdemo` capture produced two 320x200 PCX frames from the C
and `R_RenderWorld` assembly selectors. Both frame pairs matched byte-for-byte:
`QUAKE00.PCX` SHA-256
`D46E30DB34ADF7A43ABB42BB3BEE0E043BD6AE0ECBEFF34382CA0A9F9651B00E` and
`QUAKE01.PCX` SHA-256
`A8D91F6530CB8073FECF34D097719D99580A64354D8A74FD6CB452E0B5CA7A82`. Those
controlled frames were clean and did not reproduce the supplied fault; the
exact staged executable and launch configuration remain unidentified.

## Remaining active world-renderer closure

The selectable `R_RenderWorld` entry still calls the selected BSP traversal
and shared renderer routines. Continue through active C paths such as
`R_DrawSubmodelPolygons`, `R_EdgeDrawing`, edge scanning, and the remaining
setup and draw dependencies. Keep the C reference selectable, retain the
pinned framebuffer gate, and check live display output alongside buffer
parity.
