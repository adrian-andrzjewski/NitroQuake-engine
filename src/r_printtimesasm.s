/*
 * Assembly equivalent of src/r_misc.c:R_PrintTimes.
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
#endif /* ASM486_PRINT_TIMES */
