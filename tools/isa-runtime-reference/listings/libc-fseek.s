	.file	"fseek.c"
	.section .text
	.p2align 4,,15
	.globl	_fseek
_fseek:
LFB13:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$28, %esp
	.cfi_def_cfa_offset 48
	movl	48(%esp), %ebx
	movl	20(%ebx), %esi
	testl	%esi, %esi
	js	L2
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L2
	movl	(%eax,%esi,4), %edx
	testl	%edx, %edx
	je	L2
	xorl	%eax, %eax
	testb	$32, 8(%edx)
	je	L2
L28:
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L2:
	.cfi_restore_state
	movl	16(%ebx), %eax
	movl	$512, 28(%ebx)
	movl	%eax, %edx
	andl	$-65, %edx
	testb	$8, %al
	movl	%edx, 16(%ebx)
	je	L4
	movl	8(%ebx), %edi
	testl	%edi, %edi
	je	L5
	testb	$2, %al
	je	L37
L5:
	testb	$2, %dh
	je	L9
	andl	$-9, %edx
	movl	%edx, 16(%ebx)
L9:
	movl	56(%esp), %eax
	movl	%esi, (%esp)
	movl	%eax, 8(%esp)
	movl	52(%esp), %eax
	movl	%eax, 4(%esp)
	call	___lseek
	movl	8(%ebx), %edx
	movl	%edx, 4(%ebx)
	movl	16(%ebx), %edx
	andb	$239, %dh
	movl	$0, (%ebx)
	movl	%edx, 16(%ebx)
	incl	%eax
	je	L11
	xorl	%eax, %eax
L40:
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L4:
	.cfi_restore_state
	testl	$528, %eax
	jne	L38
L11:
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	orl	$-1, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L37:
	.cfi_restore_state
	movl	%ebx, (%esp)
	call	_ftell
	cmpl	$1, 56(%esp)
	je	L39
	movl	56(%esp), %edx
	testl	%edx, %edx
	je	L7
	movl	16(%ebx), %edx
	jmp	L5
	.p2align 4,,7
L38:
	movl	%ebx, (%esp)
	call	_fflush
	movl	%esi, (%esp)
	movl	%eax, %ebx
	movl	56(%esp), %eax
	movl	%eax, 8(%esp)
	movl	52(%esp), %eax
	movl	%eax, 4(%esp)
	call	___lseek
	incl	%eax
	je	L11
	incl	%ebx
	je	L11
	xorl	%eax, %eax
	jmp	L40
	.p2align 4,,7
L39:
	movl	52(%esp), %ecx
	addl	%eax, %ecx
	movl	%ecx, 52(%esp)
L7:
	movl	16(%ebx), %edx
	testb	$18, %dh
	jne	L13
	movl	52(%esp), %edi
	movl	%eax, %ecx
	subl	%edi, %ecx
	movl	4(%ebx), %edi
	movl	%edi, %ebp
	subl	8(%ebx), %ebp
	cmpl	%ebp, %ecx
	jg	L13
	movl	52(%esp), %ebp
	movl	$0, 56(%esp)
	subl	%eax, %ebp
	movl	(%ebx), %eax
	cmpl	%eax, %ebp
	jg	L5
	addl	%ecx, %eax
	addl	%ebp, %edi
	movl	%eax, (%ebx)
	movl	%edi, 4(%ebx)
	xorl	%eax, %eax
	jmp	L28
	.p2align 4,,7
L13:
	movl	$0, 56(%esp)
	jmp	L5
	.cfi_endproc
LFE13:
	.ident	"GCC: (GNU) 4.7.4"
