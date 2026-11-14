/* VESA dirty-rectangle bounds and copy path from VID_ExtraSwapBuffers. */
#include "asm_i386.h"
#include "video/asm_vesacopy.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_VESA_COPY_RECTS
.text
.p2align 2
.globl C(VESA_CopyRects)
C(VESA_CopyRects):
	pushl %ebp
	pushl %ebx
	pushl %esi
	pushl %edi
	subl $20,%esp

	movl 40(%esp),%ebp
.Lvesa_rect_loop:
	testl %ebp,%ebp
	je .Lvesa_rect_done
	movl VC_RECT_WIDTH_OFFSET(%ebp),%eax
	movl VC_RECT_HEIGHT_OFFSET(%ebp),%edx
	movl %eax,0(%esp)
	movl %edx,4(%esp)
	testl %eax,%eax
	jle .Lvesa_rect_next
	testl %edx,%edx
	jle .Lvesa_rect_next
	movl VC_RECT_X_OFFSET(%ebp),%ecx
	testl %ecx,%ecx
	js .Lvesa_rect_next
	movl VC_RECT_Y_OFFSET(%ebp),%ebx
	testl %ebx,%ebx
	js .Lvesa_rect_next

	cmpl 52(%esp),%eax
	ja .Lvesa_rect_next
	cmpl 56(%esp),%edx
	ja .Lvesa_rect_next
	movl 52(%esp),%eax
	subl 0(%esp),%eax
	cmpl %eax,%ecx
	ja .Lvesa_rect_next
	movl 56(%esp),%eax
	subl 4(%esp),%eax
	cmpl %eax,%ebx
	ja .Lvesa_rect_next

	/* Keep VESA_CopyShape's contiguous full-pitch case. */
	movl 0(%esp),%eax
	cmpl 60(%esp),%eax
	jne .Lvesa_rect_shape_ready
	cmpl 64(%esp),%eax
	jne .Lvesa_rect_shape_ready
	movl 4(%esp),%edx
	imull %edx,%eax
	movl %eax,0(%esp)
	movl $1,4(%esp)
.Lvesa_rect_shape_ready:

	/* Base plus y*pitch plus x for source and destination. */
	movl VC_RECT_Y_OFFSET(%ebp),%eax
	imull 60(%esp),%eax
	addl VC_RECT_X_OFFSET(%ebp),%eax
	addl 44(%esp),%eax
	movl %eax,8(%esp)
	movl VC_RECT_Y_OFFSET(%ebp),%eax
	imull 64(%esp),%eax
	addl VC_RECT_X_OFFSET(%ebp),%eax
	addl 48(%esp),%eax
	movl %eax,12(%esp)
	movl 8(%esp),%esi
	movl 12(%esp),%edi
	movl 60(%esp),%ebx
	subl 0(%esp),%ebx
	movl 64(%esp),%edx
	subl 0(%esp),%edx
.Lvesa_copy_row:
	movl 0(%esp),%ecx
	shrl $2,%ecx
	rep/movsl (%esi),(%edi)
	movl 0(%esp),%ecx
	andl $3,%ecx
	rep/movsb (%esi),(%edi)
	decl 4(%esp)
	jz .Lvesa_rect_next
	addl %ebx,%esi
	addl %edx,%edi
	jmp .Lvesa_copy_row

.Lvesa_rect_next:
	movl VC_RECT_NEXT_OFFSET(%ebp),%ebp
	jmp .Lvesa_rect_loop

.Lvesa_rect_done:
	addl $20,%esp
	popl %edi
	popl %esi
	popl %ebx
	popl %ebp
	ret
#endif /* ASM486_VESA_COPY_RECTS */
