/*
 * Assembly equivalent of src/renderer/r_misc.c:R_LineGraph.
 *
 * Keep the original C operation order: add the viewport origin to x/y, form
 * the byte destination from vid.buffer + rowbytes*y + x, convert
 * r_graphheight.value to int by truncation toward zero, clamp h only when
 * signed h > signed s, then paint the solid and background rows in that
 * order. Each iteration stores at dest before dest-rowbytes and advances dest
 * by exactly two rowbytes, including after the final store of each loop.
 *
 * 32-bit cdecl entry: x, y, h are at 8/12/16(%ebp) after the frame setup.
 * EAX/ECX/EDX and condition codes are caller-saved; EBX/ESI/EDI and EBP are
 * preserved. The only x87 operation is FISTP after temporarily selecting
 * truncate-toward-zero; the caller's control word is restored and the x87
 * stack depth is unchanged. The code uses baseline i486 integer instructions
 * and 387 instructions only.
 */
#include "asm_i386.h"
#include "renderer/asm_draw.h"

.arch i486
.arch .387
.code32

#ifdef ASM486_LINE_GRAPH
.extern C(vid)
.extern C(r_refdef)
.extern C(r_graphheight)

.text
.p2align 2
.globl C(R_LineGraph)
.globl C(R_LineGraph_asm486)
C(R_LineGraph):
C(R_LineGraph_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$20,%esp

	/* Apply viewport offsets before the unsigned row-major address calculation. */
	movl	8(%ebp),%eax
	addl	C(r_refdef)+LG_REFDEF_VRECT_X,%eax
	movl	%eax,-32(%ebp)
	movl	12(%ebp),%eax
	addl	C(r_refdef)+LG_REFDEF_VRECT_Y,%eax
	imull	C(vid)+LG_VID_ROWBYTES,%eax
	addl	C(vid)+LG_VID_BUFFER,%eax
	addl	-32(%ebp),%eax
	movl	%eax,%esi

	/* int s = r_graphheight.value; C float-to-int conversion truncates. */
	fnstcw	-20(%ebp)
	movw	-20(%ebp),%ax
	andw	$0xf3ff,%ax
	orw	$0x0c00,%ax
	movw	%ax,-22(%ebp)
	fldcw	-22(%ebp)
	flds	C(r_graphheight)+LG_CVAR_VALUE
	fistpl	-16(%ebp)
	fldcw	-20(%ebp)

	/* if (h > s) h = s; use signed compares, including negative inputs. */
	movl	16(%ebp),%ebx
	cmpl	-16(%ebp),%ebx
	jle	.Llinegraph_h_clamped
	movl	-16(%ebp),%ebx
.Llinegraph_h_clamped:
	movl	C(vid)+LG_VID_ROWBYTES,%edi
	addl	%edi,%edi
	xorl	%ecx,%ecx

/* for (i=0; i<h; i++): bright pixel, then row above, then two-row step. */
.Llinegraph_solid_rows:
	cmpl	%ebx,%ecx
	jge	.Llinegraph_clear_setup
	movb	$0xff,(%esi)
	movl	%esi,%eax
	subl	C(vid)+LG_VID_ROWBYTES,%eax
	movb	$0x30,(%eax)
	subl	%edi,%esi
	incl	%ecx
	jmp	.Llinegraph_solid_rows

/* for (; i<s; i++): fill both pixels with the graph background color. */
.Llinegraph_clear_setup:
	movl	-16(%ebp),%ebx
.Llinegraph_clear_rows:
	cmpl	%ebx,%ecx
	jge	.Llinegraph_done
	movb	$0x30,(%esi)
	movl	%esi,%eax
	subl	C(vid)+LG_VID_ROWBYTES,%eax
	movb	$0x30,(%eax)
	subl	%edi,%esi
	incl	%ecx
	jmp	.Llinegraph_clear_rows

.Llinegraph_done:
	addl	$20,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif /* ASM486_LINE_GRAPH */
