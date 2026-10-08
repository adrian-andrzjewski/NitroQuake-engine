	.file	"access.c"
	.section .text
LC0:
	.ascii "LFN32\0"
	.p2align 4,,15
	.globl	___access
___access:
LFB0:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	subl	$832, %esp
	.cfi_def_cfa_offset 848
	movl	848(%esp), %eax
	leal	22(%esp), %ebx
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	___solve_symlinks
	testl	%eax, %eax
	je	L13
	movl	$0, 4(%esp)
	movl	%ebx, (%esp)
	call	__chmod
	cmpl	$-1, %eax
	je	L36
	testb	$16, %al
	jne	L32
	testb	$16, 852(%esp)
	jne	L31
	testb	$4, 852(%esp)
	je	L11
	testb	$3, %al
	jne	L31
L11:
	testb	$8, 852(%esp)
	jne	L37
L32:
	xorl	%eax, %eax
L2:
	addl	$832, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L37:
	.cfi_restore_state
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%ebx, (%esp)
	call	__is_executable
	testl	%eax, %eax
	jne	L32
	.p2align 4,,7
L31:
	movl	$4, _errno
	orl	$-1, %eax
	jmp	L2
	.p2align 4,,7
L36:
	leal	282(%esp), %edi
	movl	%ebx, (%esp)
	movl	%edi, 4(%esp)
	leal	542(%esp), %esi
	call	__fixpath
	cmpb	$58, 283(%esp)
	jne	L4
	cmpb	$47, 284(%esp)
	je	L38
L4:
	movl	$33, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%ebx, (%esp)
	call	___findfirst
	testl	%eax, %eax
	jne	L7
	testb	$64, 563(%esp)
	je	L7
	testb	$24, 852(%esp)
	jne	L7
L34:
	movl	$LC0, %edi
	movl	$6, %ecx
	repe cmpsb
	jne	L32
	movswl	548(%esp), %eax
	movl	%eax, (%esp)
	call	__lfn_find_close
	jmp	L32
	.p2align 4,,7
L7:
	movl	$22, _errno
	addl	$832, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	orl	$-1, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L13:
	.cfi_restore_state
	orl	$-1, %eax
	jmp	L2
	.p2align 4,,7
L38:
	cmpb	$0, 285(%esp)
	jne	L4
	movl	$16, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%edi, (%esp)
	movb	$42, 285(%esp)
	movb	$46, 286(%esp)
	movb	$42, 287(%esp)
	movb	$0, 288(%esp)
	call	___findfirst
	testl	%eax, %eax
	jne	L4
	jmp	L34
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
