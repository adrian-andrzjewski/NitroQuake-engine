/*
 * Assembly equivalent of src/renderer/r_misc.c:R_TimeGraph.
 *
 * Preserve the reference order: read Sys_FloatTime, subtract the float
 * r_time1, multiply by the compiler's float 100.0 constant, then convert to
 * int with FISTP under round-toward-zero. The sampled int is stored as a byte
 * in the 100-entry history ring. Columns are painted from the newest sample
 * backwards, stopping at the left viewport edge or after one full ring.
 *
 * Cdecl: no arguments. EAX/ECX/EDX and flags are caller-saved; EBX/ESI/EDI/EBP
 * are preserved. The x87 control word and stack depth are restored. Integer
 * instructions are limited to the i486 ISA; the floating-point path uses 387.
 */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"
#include "renderer/asm_timegraph.h"

.arch i486
.arch .387
.code32

#ifdef ASM486_TIME_GRAPH
.extern C(r_refdef)
.extern C(r_time1)
.extern C(r_timegraph_state)
.extern C(r_graphheight)
.extern C(R_LineGraph)
#ifdef BENCH486
.extern C(Bench486TimeGraphTime)
#else
.extern C(Sys_FloatTime)
#endif

.text
.p2align 2
.globl C(R_TimeGraph)
.globl C(R_TimeGraph_asm486)
C(R_TimeGraph):
C(R_TimeGraph_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

/* Keep the same x87 expression order as the compiler-generated C reference. */
#ifdef BENCH486
	call	C(Bench486TimeGraphTime)
#else
	call	C(Sys_FloatTime)
#endif
	fsubs	C(r_time1)
	fmuls	.Ltimegraph_hundred
	fnstcw	-14(%ebp)
	movw	-14(%ebp),%ax
	andw	$0xf3ff,%ax
	orw	$0x0c00,%ax
	movw	%ax,-16(%ebp)
	fldcw	-16(%ebp)
	fistpl	-20(%ebp)
	fldcw	-14(%ebp)

/* Store the int sample as a byte, matching C's conversion to byte. */
	movl	-20(%ebp),%eax
	movl	C(r_timegraph_state)+TG_STATE_TIMEX,%ebx
	movb	%al,C(r_timegraph_state)+TG_STATE_TIMINGS(%ebx)

/* Width <= 100 starts at width-1; wider views center the 100 samples. */
	movl	C(r_refdef)+TG_REFDEF_VRECT_WIDTH,%esi
	cmpl	$TG_MAX_TIMINGS,%esi
	jle	.Ltimegraph_width_at_most_ring
	leal	-TG_MAX_TIMINGS(%esi),%eax
	sarl	$1,%eax
	subl	%eax,%esi
	jmp	.Ltimegraph_draw
.Ltimegraph_width_at_most_ring:
	decl	%esi

/* The do/while paints the current sample first and wraps the ring at -1. */
.Ltimegraph_draw:
	movzbl	C(r_timegraph_state)+TG_STATE_TIMINGS(%ebx),%edx
	movl	C(r_refdef)+TG_REFDEF_VRECT_HEIGHT,%eax
	subl	$2,%eax
	pushl	%edx
	pushl	%eax
	pushl	%esi
	call	C(R_LineGraph)
	addl	$12,%esp

	testl	%esi,%esi
	jz	.Ltimegraph_advance
	decl	%esi
	decl	%ebx
	jns	.Ltimegraph_check_ring
	movl	$(TG_MAX_TIMINGS-1),%ebx
.Ltimegraph_check_ring:
	cmpl	C(r_timegraph_state)+TG_STATE_TIMEX,%ebx
	jne	.Ltimegraph_draw

/* timex stays in [0,99], so increment-and-wrap equals (timex+1)%100. */
.Ltimegraph_advance:
	movl	C(r_timegraph_state)+TG_STATE_TIMEX,%eax
	incl	%eax
	cmpl	$TG_MAX_TIMINGS,%eax
	jb	.Ltimegraph_store_index
	xorl	%eax,%eax
.Ltimegraph_store_index:
	movl	%eax,C(r_timegraph_state)+TG_STATE_TIMEX

	addl	$16,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.section .rodata
.p2align 2
.Ltimegraph_hundred:
	.float	100.0
#endif /* ASM486_TIME_GRAPH */
