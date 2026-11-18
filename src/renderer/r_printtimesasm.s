/*
 * Assembly equivalents of src/renderer/r_misc.c:R_PrintTimes and R_PrintDSpeeds.
 *
 * This is a 32-bit cdecl leaf: EBP is saved/restored, no other callee-saved
 * integer register is touched, and the caller removes the 28 bytes of
 * Con_Printf arguments. The clock returns its double in x87 ST(0). We store
 * it as binary32 before subtracting r_time1, then multiply by 1000 and store
 * ms as binary32 before promoting it to the vararg double. Those stores keep
 * the source's float assignments and live x87 rounding/control-word behavior.
 * Each x87 value is popped before Con_Printf, so the entry x87 stack depth and
 * control word are preserved. c_surf is read for the printed line and reset
 * only after Con_Printf returns, matching the C statement order.
 *
 * All integer opcodes are valid on the i486; the floating-point operations
 * are baseline 80387 instructions. No compiler-generated code is involved.
 */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"

.arch i486
.arch .387
.code32

#ifdef ASM486_PRINT_TIMES
#ifdef BENCH486
.extern C(Bench486PrintTimesTime)
#define PRINT_TIMES_CLOCK C(Bench486PrintTimesTime)
#else
.extern C(Sys_FloatTime)
#define PRINT_TIMES_CLOCK C(Sys_FloatTime)
#endif
.extern C(r_time1)
.extern C(dp_time1)
.extern C(dp_time2)
.extern C(rw_time1)
.extern C(rw_time2)
.extern C(db_time1)
.extern C(db_time2)
.extern C(se_time1)
.extern C(se_time2)
.extern C(de_time1)
.extern C(de_time2)
.extern C(dv_time1)
.extern C(dv_time2)
.extern C(c_faceclip)
.extern C(r_polycount)
.extern C(r_drawnpolycount)
.extern C(c_surf)
.extern C(Con_Printf)

.section .rodata
.Lprint_times_format:
	.asciz "%5.1f ms %3i/%3i/%3i poly %3i surf\n"
.Lprint_times_1000:
	.float 1000.0

.text
.p2align 2
.globl C(R_PrintTimes)
.globl C(R_PrintTimes_asm486)
C(R_PrintTimes):
C(R_PrintTimes_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$8,%esp

	/* r_time2 = (float) timer(); keep the source assignment's narrowing. */
	call	PRINT_TIMES_CLOCK
	fstps	-4(%ebp)

	/* ms = 1000 * (r_time2 - r_time1), narrowed on assignment to ms. */
	flds	-4(%ebp)
	fsubs	C(r_time1)
	fmuls	.Lprint_times_1000
	fstps	-8(%ebp)

	/* cdecl: push trailing ints, then the promoted double and format pointer. */
	pushl	C(c_surf)
	pushl	C(r_drawnpolycount)
	pushl	C(r_polycount)
	pushl	C(c_faceclip)
	subl	$8,%esp
	flds	-8(%ebp)
	fstpl	(%esp)
	pushl	$.Lprint_times_format
	call	C(Con_Printf)
	addl	$28,%esp

	/* Preserve the C sequencing: reset the surface count after printing. */
	movl	$0,C(c_surf)
	leave
	ret

/* R_PrintDSpeeds keeps GCC's source-order x87 schedule explicit.  The timer
 * result remains on the x87 stack while the six stage intervals are evaluated
 * against the original 1000.0f constant.  Float varargs are promoted to double;
 * the three (int) casts temporarily select truncation toward zero and restore
 * the caller's control word before Con_Printf.  The first 16-byte temporary
 * area holds dv_time and de_time.  Integer results and saved control words use
 * the original 28-byte local area while the remaining arguments are pushed.
 * No callee-saved integer register is used.
 */
.section .rodata
.Lprint_dspeeds_format:
	.asciz "%3i %4.1fp %3iw %4.1fb %3is %4.1fe %4.1fv\n"

.text
.p2align 2
.globl C(R_PrintDSpeeds)
C(R_PrintDSpeeds):
	subl	$28,%esp
	call	PRINT_TIMES_CLOCK

	/* dv_time = (dv_time2 - dv_time1) * 1000; last vararg first. */
	flds	C(dv_time2)
	fsubs	C(dv_time1)
	flds	.Lprint_times_1000
	fmul	%st,%st(1)
	fxch	%st(1)
	subl	$16,%esp
	fstpl	8(%esp)

	/* de_time double argument. */
	flds	C(de_time2)
	fsubs	C(de_time1)
	fmul	%st(1),%st
	fstpl	(%esp)

	/* se_time is converted to int with truncation independent of caller CW. */
	flds	C(se_time2)
	fsubs	C(se_time1)
	fmul	%st(1),%st
	fnstcw	30(%esp)
	movw	30(%esp),%ax
	orb	$12,%ah
	movw	%ax,28(%esp)
	fldcw	28(%esp)
	fistpl	24(%esp)
	fldcw	30(%esp)
	movl	24(%esp),%edx
	pushl	%edx

	/* db_time double argument. */
	flds	C(db_time2)
	fsubs	C(db_time1)
	fmul	%st(1),%st
	subl	$8,%esp
	fstpl	(%esp)

	/* rw_time integer argument; preserve the same caller control word. */
	flds	C(rw_time2)
	fsubs	C(rw_time1)
	fmul	%st(1),%st
	fldcw	40(%esp)
	fistpl	36(%esp)
	fldcw	42(%esp)
	movl	36(%esp),%ecx
	pushl	%ecx

	/* dp_time double argument. */
	flds	C(dp_time2)
	fsubs	C(dp_time1)
	fmul	%st(1),%st
	subl	$8,%esp
	fstpl	(%esp)

	/* ms = (timer - r_time1) * 1000; the C cast truncates toward zero. */
	fxch	%st(1)
	fsubs	C(r_time1)
	fmulp	%st,%st(1)
	fldcw	52(%esp)
	fistpl	48(%esp)
	fldcw	54(%esp)
	movl	48(%esp),%eax
	pushl	%eax
	pushl	$.Lprint_dspeeds_format
	call	C(Con_Printf)
	addl	$76,%esp
	ret
#endif /* ASM486_PRINT_TIMES */
