/* VESA page-flip and single-page presentation orchestration. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"
#include "video/asm_vesaswap.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_VESA_SWAP_BUFFERS
.text
.p2align 2
.globl C(VID_ExtraSwapBuffers_ASM)
C(VID_ExtraSwapBuffers_ASM):
	pushl %ebp
	pushl %ebx
	pushl %esi
	pushl %edi
	movl 20(%esp),%esi
	movl 24(%esp),%ebx
	movl 28(%esp),%ebp

	cmpl $1,VS_VID_NUMPAGES_OFFSET(%esi)
	jle .Lvesa_swap_single_page

	/* The hardware wait remains behind its DOS-aware C adapter. */
	call C(VID_ExtraWaitDisplayIfRequested)
	call C(VID_ExtraDisplayStartWaitFlags)
	movl %eax,%edi
	movl C(VID_currentpage),%eax
	imull C(VID_pagesize),%eax
	cltd
	idivl C(VGA_rowbytes)
	pushl %edi
	pushl %eax
	pushl %edx
	call C(VID_ExtraSetDisplayStart)
	addl $12,%esp

	/* Publish the page just displayed and rotate the draw page. */
	movl C(VID_currentpage),%eax
	movl %eax,C(VID_displayedpage)
	incl %eax
	cmpl VS_VID_NUMPAGES_OFFSET(%esi),%eax
	jl .Lvesa_swap_next_page_ready
	xorl %eax,%eax
.Lvesa_swap_next_page_ready:
	movl %eax,C(VID_currentpage)
	imull C(VID_pagesize),%eax
	addl C(VID_membase),%eax
	movl %eax,C(VGA_pagebase)
	movl %eax,VS_VID_BUFFER_OFFSET(%esi)
	movl %eax,VS_VID_CONBUFFER_OFFSET(%esi)

	movl C(VID_displayedpage),%edx
	imull C(VID_pagesize),%edx
	addl C(VID_membase),%edx
	movl %edx,VS_VID_DIRECT_OFFSET(%esi)
	jmp .Lvesa_swap_done

.Lvesa_swap_single_page:
	pushl %ebx
	call C(VID_ExtraProbeWaitIfNeeded)
	addl $4,%esp
	call C(VID_ExtraWaitVsyncIfRequested)
	call C(VID_ExtraWaitDisplayIfRequested)

	pushl C(VGA_rowbytes)
	pushl VS_VID_ROWBYTES_OFFSET(%esi)
	pushl VS_VID_HEIGHT_OFFSET(%esi)
	pushl VS_VID_WIDTH_OFFSET(%esi)
	pushl C(VGA_pagebase)
	pushl VS_VID_BUFFER_OFFSET(%esi)
	pushl %ebp
	call C(VID_ExtraCopyRects)
	addl $28,%esp

.Lvesa_swap_done:
	popl %edi
	popl %esi
	popl %ebx
	popl %ebp
	ret
#endif /* ASM486_VESA_SWAP_BUFFERS */
