/*
 * Assembly equivalent of src/renderer/r_misc.c:R_CheckVariables.
 *
 * Preserve the original x87 comparison sequence: the i486-safe FCOMS result
 * is inspected through FNSTSW, and the single-precision value is stored only
 * when the comparison is ordered and unequal.  The benchmark C oracle uses
 * separately exposed state so direct tests can save and restore both paths.
 */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
.section .bss
.balign 4
#ifdef BENCH486
#define RCHECK_OLDBRIGHT _bench486_rcheck_oldbright_asm
.globl _bench486_rcheck_oldbright_asm
_bench486_rcheck_oldbright_asm:
#else
#define RCHECK_OLDBRIGHT .Lrcheck_oldbright
.Lrcheck_oldbright:
#endif
	.long 0

.text
.globl _R_CheckVariables
_R_CheckVariables:
	flds	_r_fullbright+VC_CVAR_VALUE
	fcoms	RCHECK_OLDBRIGHT
	fnstsw	%ax
	testb	$0x40,%ah		/* C3 is set for equality or unordered. */
	je	.Lrcheck_changed
	fstp	%st(0)
	ret

.Lrcheck_changed:
	fstps	RCHECK_OLDBRIGHT
#ifdef BENCH486
	/* The fixture records the flush request; normal benchmark execution still
	 * reaches D_FlushCaches through the helper when capture mode is disabled. */
	jmp	_Bench486ViewControlFlushCaches
#else
	jmp	_D_FlushCaches
#endif
