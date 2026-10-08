	.file	"_chmod.c"
	.section .text
	.p2align 4,,15
	.globl	__chmod
__chmod:
LFB3:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	movl	$0, (%esp)
	call	__use_lfn
	testb	%al, %al
	je	L2
	movl	100(%esp), %eax
	movw	$1, 60(%esp)
	movw	$28995, 56(%esp)
	movb	%al, 44(%esp)
L3:
	movl	96(%esp), %eax
	movl	%eax, (%esp)
	call	__put_path
	cmpl	$1, 100(%esp)
	je	L11
L4:
	movl	__go32_info_block+12, %eax
	movl	$33, (%esp)
	shrl	$4, %eax
	movw	$0, 48(%esp)
	movw	%ax, 64(%esp)
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L12
	cmpw	$28928, 56(%esp)
	je	L13
	movl	52(%esp), %eax
	andl	$65535, %eax
L8:
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L2:
	.cfi_restore_state
	movl	100(%esp), %eax
	addl	$17152, %eax
	movw	%ax, 56(%esp)
	jmp	L3
	.p2align 4,,7
L11:
	movl	104(%esp), %eax
	movw	%ax, 52(%esp)
	jmp	L4
	.p2align 4,,7
L12:
	movl	56(%esp), %eax
L6:
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L8
	.p2align 4,,7
L13:
	movl	$28928, %eax
	jmp	L6
	.cfi_endproc
LFE3:
	.ident	"GCC: (GNU) 4.7.4"
