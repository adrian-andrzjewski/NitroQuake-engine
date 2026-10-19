#include "asm_i386.h"
#include "asm_vesadefaultmode.h"

#if defined(ASM486_VESA_DEFAULT_MODE) || defined(BENCH486)
	.text
	.p2align 4,,15
	.globl C(VID_SelectVesaDefaultMode_asm486)
C(VID_SelectVesaDefaultMode_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	8(%ebp),%esi
	xorl	%ebx,%ebx
	xorl	%edi,%edi
.Lvd_mode_loop:
	testl	%esi,%esi
	jz	.Lvd_mode_done
	cmpl	$320,VD_MODE_WIDTH_OFFSET(%esi)
	jne	.Lvd_mode_next
	cmpl	$200,VD_MODE_HEIGHT_OFFSET(%esi)
	jne	.Lvd_mode_next
	movl	12(%ebp),%eax
	cmpl	%eax,VD_MODE_SETMODE_OFFSET(%esi)
	jne	.Lvd_mode_next
	movl	VD_MODE_PEXTRADATA_OFFSET(%esi),%edx
	cmpl	$0,VD_INFO_LINEAR_OFFSET(%edx)
	jne	.Lvd_mode_linear
	testl	%edi,%edi
	jne	.Lvd_mode_next
	movl	%ebx,%edi
	jmp	.Lvd_mode_next
.Lvd_mode_linear:
	movl	%ebx,%eax
	jmp	.Lvd_mode_return
.Lvd_mode_next:
	movl	VD_MODE_NEXT_OFFSET(%esi),%esi
	incl	%ebx
	jmp	.Lvd_mode_loop
.Lvd_mode_done:
	movl	%edi,%eax
.Lvd_mode_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

#ifdef ASM486_VESA_DEFAULT_MODE
	.p2align 2
	.globl C(VID_ExtraDefaultMode)
C(VID_ExtraDefaultMode):
	pushl	$C(VID_ExtraInitMode)
	pushl	C(pvidmodes)
	call	C(VID_SelectVesaDefaultMode_asm486)
	addl	$8,%esp
	ret
#endif
#endif
