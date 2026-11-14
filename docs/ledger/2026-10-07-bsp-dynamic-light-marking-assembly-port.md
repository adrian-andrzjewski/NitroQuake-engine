# BSP dynamic-light marking assembly path

## `R_MarkLights` tree walk

`MarkLightsImplementation=c|asm` selects the retained C reference or the
i486 recursive implementation in `src/renderer/r_lightasm.s`. The public wrapper keeps
the existing `R_MarkLights(light, bit, node)` interface and supplies the
world-model surface array to `R_MarkLightsTree_asm486`. `src/renderer/asm_light.h`
defines the 32-bit field offsets used by the assembly, with C layout assertions
for the structures it reads.

The routine preserves the original front/back BSP plane tests, parent-surface
ordering, radius and minlight rejects, 8.8 ceiling conversion, impact-point
projection, lightmap bounds cull, and surface `dlightframe`/`dlightbits` writes.
The x87 control word is restored after the temporary upward-rounding conversion.
Each C float temporary is rounded through a 32-bit store to match the reference
calculation points.

The first fixture run exposed reversed x87 subtraction in both the radius
calculation and impact coordinates. Those four operations were corrected to
the reverse-subtract form; keeping the sign error would have changed which
surfaces receive the light.

## Direct fixture and i486 ISA audit

The `BENCH486` fixture builds a three-level BSP with six independently bounded
surfaces. Thirty-two deterministic light/node cases run under all four x87
rounding modes, comparing complete surface state and the caller's x87 control
word: 128 exact C/assembly comparisons passed. The fixture is available when
`MarkLightsImplementation=asm`, independently of the lightmap-dispatcher
selector.

The validation build selected 104 objects and audited 183,809 instruction
sites; it found zero enforced instructions above i486. The complete 339-object
closure audited 225,321 instruction sites, also with zero enforced instructions
above i486. The linked-image audit checked 222,563 opcodes across 235 runtime
inputs and 334 executable text ranges. The reports are under
`out/dos-memasm-fillrectasm-zpointasm-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasmatrixasm-aliasgradientasm-aliaslinescanasm-lightmapstylesasm-fusedlightmapasm-dlightasm-marklightsasm/`.

The audit still lists the existing CRC MMX site and selected DOS C-runtime
sites (`FISTTP`, `FEMMS`, and unknown decoder bytes) as exemptions. The
renderer object and linked-code gates report no enforced post-i486 instruction;
the broader runtime-exemption review remains part of the project-level CPU
compatibility work.

## Exact Demo 1 parity

The focused `i486-asm-marklights` profile changes only
`MarkLightsImplementation` from `i486-c-reference`. Both profiles used source
tree fingerprint
`A282048F937219739FAC29019319E8145F72F0F79F008DDABD6A252A3F910E14` and
passed one 969-frame Demo 1 VESA run. All 964 post-warmup frame checksums
matched. The captured 320x200 framebuffer matched exactly: zero differences
among 64,000 palette indices and 768 palette bytes. The result is
`out/render-parity-20261007-070651/render-parity-result.json`.

The diagnostic rates were 12.68 fps for C and 12.66 fps for assembly; this is
not a performance claim. At this initial Demo 1 checkpoint the subsystem was
still on the C default pending broader scene coverage. The later coverage and
promotion are recorded below. This milestone covers BSP light marking only,
not the full renderer or the remaining runtime dependency closure.

## Extended paired scenes and transient console notifications

The six-scene paired run in
`out/render-parity-20261007-072236/render-parity-result.json` compared the C
reference with `i486-asm-marklights` under the paired runner's deterministic
`con_notifytime -1` setting. All post-warmup frame checksums and captured
framebuffers matched exactly across the repeated Demo 1, Demo 2, and Demo 3
scenarios. This is a renderer-to-renderer comparison; the setting suppresses
time-limited console messages, so its Demo 3 checksum is not the pinned normal
reference checksum.

The normal C reference run in
`out/render-validation-20261007-080255/render-validation-result.json` passed
1,090 frames with checksum `2316550348`, and its captured frame 169 matched the
committed image exactly. A paired diagnostic with transient notifications
enabled is recorded in
`out/render-parity-notify-frames-20261007-083000/render-parity-result.json`.
Both profile input suites passed and both ended with the pinned checksum, but
the per-frame checksum comparator reported frames 247, 767, and 1049.

Exact PCX inspection localized every changed pixel to the timed notification
text at the top of the screen. Frame 247 changed 1,787 pixels in rows 1–23;
frames 767 and 1049 changed 500 and 412 pixels, respectively, in rows 1–7.
The palette matched and every other pixel matched in all three captures. The
frame 247 capture is in
`out/render-parity-20261007-080857/render-parity-result.json`; the other two
captures are in the paired report above. `Host_FilterTime` advances `realtime`
from elapsed time, and `Con_DrawNotify` expires messages using that value and
`con_notifytime` (`src/core/host.c`, `src/client/console.c`). The C and assembly timedemo
runs take slightly different amounts of real time, so a message can disappear
on a different frame. The observed full-frame mismatch is therefore a timed
console overlay difference; the captured world, HUD, palette, and lightmarked
rendering pixels are exact. The notifications-enabled whole-frame comparison
remains recorded as a failure rather than being counted as an exact pass.

One paired Demo 3 sample measured 12.15 fps for C and 12.05 fps for assembly.
This is a small regression check, not a performance result or a reason to
change the implementation.

## Combined fixture, ISA gate, and i486 default

The independent `LightMapBuildImplementation=asm` plus
`MarkLightsImplementation=asm` benchmark passed all 11 lightmap-build
scenarios and all 128 BSP light-marking comparisons in
`out/dos-bench-20261007-083424/bench-result.json`.

The selected benchmark build audited 104 objects and 184,581 instruction
sites, with zero enforced instructions above i486. Its linked audit verified
223,284 opcodes across 235 runtime inputs and 334 executable text ranges. The
release build with MarkLights as the i486 default also passed: the selected
audit covered 104 objects and 148,476 sites, and the linked audit verified
187,344 opcodes across 235 runtime inputs and 332 text ranges. The release
reports are under the `out/dos-...-marklightsasm/` profile directory. Existing
CRC and DOS runtime data/instruction-decoder exemptions remain visible in the
reports; project-wide runtime closure review is still open.

After those checks, `build-dos.ps1`, `bench-dos.ps1`, and `timedemo-dos.ps1`
made `MarkLightsImplementation=asm` the default for i486. The explicit C
selector and `i486-c-reference` profile remain available. The separate i386
default remains C. `tools/test-build-dos.py` pins both target configurations,
and `tools/golden/i486-release.sha256` now records the 105 release artefacts.

## Benchmark text-data disassembly case

A stale full benchmark object exposed a false positive: `objdump -d` decoded
the third pointer in `host_cmd.obj:_mode_names.42` as `minps` because DJGPP
places this five-entry label table in `.text`. The five 32-bit words each have
a `DIR32` relocation to `.text`. `build-dos.ps1` now locates the local table
symbol, verifies those five contiguous relocations, and passes only that
20-byte data range to both object and linked audits. The selected-instruction
audit still reports actual instructions in the surrounding region and fails
closed if the table layout changes.

This is a completed BSP light-marking subsystem milestone, not completion of
the renderer port or the remaining compiler/runtime compatibility review.
