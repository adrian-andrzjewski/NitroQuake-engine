# Active BSP dynamic-light enumeration assembly path

## `R_PushDlights` slot loop

`DynamicLightPushImplementation=c|asm` selects the retained C reference or the
i486 implementation in `src/renderer/r_lightasm.s`. The public C wrapper supplies the
current client time, frame count, fixed 32-light array, and world BSP root.
Structure offsets read by assembly are defined in `src/renderer/asm_light.h` and
checked against the C layouts at compile time.

The loop increments `r_dlightframecount`, visits all 32 slots in order, skips
lights whose float deadline is not later than the double client time, skips
zero or unordered radii using the original C predicate behavior, and calls the
public `R_MarkLights` entry with the corresponding bit. Slot 31 uses the
signed high bit exactly as in C. The routine preserves EBX, ESI, and EDI and
balances all temporary x87 stack values. `FCOMPP`, `FNSTSW`, `SAHF`, and
`FTST` implement the comparisons using pre-486 instructions.

## Direct fixture and instruction audit

The `BENCH486` fixture compares exact counter, surface-frame, and surface-bit
state for five cases: sparse active slots including bit 31, all 32 active,
the exact deadline at bit 31, positive and negative zero radii, and expired
lights with a null world. All five passed in
`out/dos-bench-20261007-090104/bench-result.json`.

The paired candidate build selected 104 objects and audited 181,531
instruction sites; the 339-object closure audited 223,043 sites. Both reported
zero enforced instructions above i486. The linked executable audit checked
220,306 opcodes across 235 runtime inputs and 334 executable text ranges, also
with zero enforced instructions above i486. Existing CRC and DOS-runtime
data/decoder exemptions remain explicit in the reports; this subsystem audit
does not close the separate whole-runtime exemption review.

The promoted i486 release build also passed the mechanical gate. Its selected
104-object audit covered 148,510 instruction sites; the complete 339-object
closure covered 190,022 sites, with zero enforced instructions above i486. The
linked executable audit verified 187,378 opcodes across 235 runtime inputs and
332 executable text ranges, again with zero enforced instructions above i486.
The release reports are under
`out/profile-95e43c556d3c5795/`. `guard-i486-release.py` passed for
104 objects and the executable.

## Six-scene exact framebuffer parity

The candidate profile
`tools/renderer-profiles/i486-asm-dlight-push.json` changes only
`DynamicLightPushImplementation` from the all-C reference profile. The paired
run disabled time-sensitive console notices and ran two repeats of each of six
scenes. All 12 captured 320x200 frames matched exactly, including palette
bytes. Every post-warmup frame checksum also matched, with zero mismatch
frames. The report is
`out/render-parity-20261007-090150/render-parity-result.json`.

The scenes covered Demo 1 VESA, VGA, fullbright, and 50-percent view size,
Demo 2 entity workload, and Demo 3 world workload. Replay checksums were
`1047377823` for Demo 1 VESA/VGA, `4021309056` for fullbright, `885630476`
for the reduced view, `1887495667` for Demo 2, and `3722973491` for Demo 3.
The source-tree fingerprint matched between the reference and candidate.

Candidate benchmark rates differed by approximately -0.004% to -0.007%
across the six scenes. This is below a material regression and does not justify
additional optimization work.

## Combined promoted dynamic-light paths

The three promoted paths were also exercised together in
tools/renderer-profiles/i486-asm-promoted-renderers.json against the all-C
reference under DOSBox-X's i486 profile. All six scenarios passed on two
repeats each. The 11,842 compared post-warmup frame checksums matched exactly;
all 12 captured 320x200 frames matched every palette index and all 768 palette
bytes. The source-tree fingerprints matched. The report is
out/render-parity-20261007-101114/render-parity-result.json.

The combined candidate rates were 0.13% to 0.81% lower across the six
scenarios. This is a small regression at this emulator speed, not a reason to
complicate the implementation for marginal timing gains.

## Promotion

`build-dos.ps1`, `bench-dos.ps1`, `timedemo-dos.ps1`, and `smoke-dos.ps1`
select assembly by default for i486. The selector remains explicitly
controllable: C is the i386 default and `-DynamicLightPushImplementation c`
restores the i486 C reference. This milestone covers active-light enumeration
and dispatch only; the full renderer conversion and runtime dependency closure
remain open.
