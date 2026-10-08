# Renderer assembly conventions

## Ownership and module structure

The target is 32-bit i486 protected-mode code with the original x87 floating
point behavior. An i486 DX/DX2/DX4 or an i486 system with a compatible x87 FPU
is required. This is not a software-FPU implementation for an unassisted SX.
The application loader and DPMI provider have separately verified 16-bit code;
they do not change the renderer's 32-bit calling convention.

Each conversion has a selector, a maintained `.s` module or named assembly
region, independently retained original C, a direct fixture and a paired
framebuffer comparison. `docs/renderer-assembly/*-provenance.json` maps original
functions to assembly entries and verification. New modules should group one
subsystem. Large original instruction schedules may use separate normal and
profiling includes. Their includes are maintained source files: the normal
build never regenerates renderer assembly from C.

C may own shared variables and compile-time layout checks. That storage does
not implement the rendering algorithm. Retained C implementations provide
reference profiles and benchmark oracles; they must not be called by the
selected assembly renderer. The ownership inventory lists C dependencies and
indirect transfers explicitly. Initialization, diagnostic paths and indirect
callbacks also require review before the complete renderer is declared pure
assembly. Passing a C object's ISA audit alone does not establish that ownership.

## Calls, registers and stack frames

Most public entries use the original DJGPP 32-bit cdecl ABI. Arguments occupy
four-byte stack slots, binary64 arguments occupy two slots, integer/pointer
returns use EAX and floating returns use x87 ST(0). The caller removes stack
arguments. EBX, ESI, EDI and EBP are callee-preserved; EAX, ECX and EDX are
caller-owned. ESP must return exactly to its entry value, apart from the return
address. DF is clear at entry and return. A routine using `std` must restore
`cld` before returning or calling ordinary C support.

Keep an explicit stack-frame description for nontrivial routines: saved
registers, argument offsets, local sizes, outgoing arguments and temporary
x87 stores. Preserve the original ABI's call-site stack residue and alignment
where support routines depend on it. Do not infer parameter locations from a
function name or from cdecl being the common case.

Existing private or attributed entries have additional contracts. The alias
model draw entry passes its lighting pointer in EAX (`regparm(1)`). The BSP
walker uses EAX/EDX (`regparm(2)`). The private drawing glyph clone uses
EAX/EDX/ECX. Their declarations, module comments and fixtures define these
exceptions. Cdecl benchmark adapters must transfer the arguments explicitly
and must not hide a callee register-preservation failure.

An ordinary void/integer routine balances its x87 stack and preserves the
control word. A floating return adds precisely its ST(0) result. Explicit FPU
control routines retain their original documented state-changing contract.
Direct fixtures check integer registers, ESP, DF, the x87 control word and
stack/tag state, and repeat arithmetic under twelve precision/rounding settings.

## Arithmetic, constants and storage

Preserve the original operation and store order. A single-precision store
rounds an extended x87 intermediate and can affect clipping, light values or
pixel coordinates. Do not reassociate expressions, replace stores with longer
register lifetimes, approximate division or change conversion rounding solely
for speed. AT&T x87 subtract/divide operand order requires explicit review;
prefer named memory operations where they make the intended order clearer.

Retain original fixed-point contracts at every boundary. Texture coordinates
and seam correction use the original 16.16 representation; reciprocal depth
and raster interpolants retain their subsystem-specific scaling and shifts.
The original headers and routines define their signedness and overflow behavior.
An integer multiply, arithmetic shift, truncation or wrap must not be replaced
with saturation or a different format without a separately justified behavior
change. Bit-exact comparison is the default.

Keep constants as exact original integer or binary floating encodings when
decimal re-rounding could change output. Explain the scale and algorithmic use.
Keep code in `.text`, constants/storage in their original appropriate sections,
and use assembler directives rather than opaque numeric instruction encodings
where possible. Alignment may pad code only with verified permitted encodings.
Jump tables, patch fields and deliberate overlapping streams need source-bound
code/data classification and explicit target checks.

Structure offsets and sizes used in assembly have compile-time checks in the
associated `asm_*.h` header. Public COFF symbols use the leading underscore.
Private shared state should have a named alias or declaration rather than a
duplicated copy. A profiling include must implement the same renderer behavior
and preserve its explicit instrumentation stack/timer contracts.

## Verification and integration

Declare `.arch i486`, `.arch .387` and `.code32` in new renderer modules. Those
directives help the assembler reject mistakes; they do not replace inspection
of actual object and executable bytes. The complete gate rejects post-i486
instructions, undocumented encodings, unknown bytes and instruction exemptions.
It also verifies remaining C support, runtime members, embedded startup and the
maintained provider. Follow [ISA verification](ISA-VERIFICATION.md) to reproduce it.

For a conversion, preserve the source baseline, understand the original
algorithm and establish direct deterministic cases before acceptance. Compare
the assembly entry against independent C through identical typed boundaries.
Exercise unusual counts, near clipping planes, large coordinates, preserved
state and uninterrupted sequences. Guard working buffers and validate their
guards with deliberate corruption cases. Compare complete defined results;
normalize transient stack addresses only when their different storage cannot
affect the algorithm, and validate the pointed-to data while it is live.

Then run identical fixed-time scenes through reference and candidate profiles.
Require exact indexed pixels and palette bytes, and compare frame streams
after the explicitly defined startup interval. Investigate every difference.
Verify actual selectors before execution and retain the executable, manifest,
ISA binding and frame artifacts used by the accepted run. Previously accepted
assembly modules should retain identical allocated bytes and normalized
relocations unless an intentional change has its own validation.

Timing measurements detect significant regressions. They do not authorize
visual changes or make a faster implementation the completion criterion.
Keep unresolved scope in [completion gaps](RENDERER-COMPLETION-GAPS.md).
