/* VGA BIOS page-copy presentation path for i486 builds. */
#include "asm_i386.h"
#include "video/asm_vgaswap.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_VGA_PRESENTATION
.text
.p2align 2

/* VGA_WaitVsync: wait until the VGA status register reports active display. */
.globl C(VGA_WaitVsync)
C(VGA_WaitVsync):
	movl	$0x3DA,%edx
.Lvga_wait_retrace:
	inb	%dx,%al
	testb	$0x08,%al
	je	.Lvga_wait_retrace
	ret

/* VGA_SwapBuffersCopy: copy changed linear rectangles or the whole planar page. */
.p2align 2
.globl C(VGA_SwapBuffersCopy)
C(VGA_SwapBuffersCopy):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%ebx		/* viddef_t * */
	cmpl	$0,C(VGA_planar)
	jne	.Lvga_swap_planar
	movl	16(%ebp),%esi		/* first dirty rectangle */
	testl	%esi,%esi
	je	.Lvga_swap_copy_done

.Lvga_swap_rect:
	/* Rebuild source and VGA byte offsets from each rectangle's origin. */
	movl	VGS_RECT_Y_OFFSET(%esi),%eax
	imull	VGS_VID_ROWBYTES_OFFSET(%ebx),%eax
	addl	VGS_RECT_X_OFFSET(%esi),%eax
	movl	VGS_VID_BUFFER_OFFSET(%ebx),%edx
	addl	%eax,%edx			/* source */

	movl	VGS_RECT_Y_OFFSET(%esi),%eax
	imull	C(VGA_rowbytes),%eax
	addl	VGS_RECT_X_OFFSET(%esi),%eax
	movl	C(VGA_pagebase),%edi
	addl	%eax,%edi			/* destination */

	pushl	C(VGA_rowbytes)
	pushl	VGS_VID_ROWBYTES_OFFSET(%ebx)
	pushl	VGS_RECT_HEIGHT_OFFSET(%esi)
	pushl	VGS_RECT_WIDTH_OFFSET(%esi)
	pushl	%edi
	pushl	%edx
	call	C(VGA_UpdateLinearScreen)
	addl	$24,%esp
	movl	VGS_RECT_NEXT_OFFSET(%esi),%esi
	testl	%esi,%esi
	jne	.Lvga_swap_rect
	jmp	.Lvga_swap_copy_done

.Lvga_swap_planar:
	movl	VGS_VID_BUFFER_OFFSET(%ebx),%eax
	pushl	%eax
	call	C(VGA_UpdatePlanarScreen)
	addl	$4,%esp

.Lvga_swap_copy_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

/* Equality with the IEEE-754 encoding of 1.0 matches the C wait decision. */
.p2align 2
.globl C(VGA_SwapBuffers)
C(VGA_SwapBuffers):
	pushl	%ebp
	movl	%esp,%ebp
	cmpl	$VGS_VSYNC_BITS,C(vid_wait)+VGS_CVAR_VALUE_OFFSET
	jne	.Lvga_swap_no_wait
	call	C(VGA_WaitVsync)
.Lvga_swap_no_wait:
	pushl	16(%ebp)			/* vrect_t * */
	pushl	12(%ebp)			/* vmode_t * */
	pushl	8(%ebp)			/* viddef_t * */
	call	C(VGA_SwapBuffersCopy)
	addl	$12,%esp
	leave
	ret

#endif /* ASM486_VGA_PRESENTATION */
