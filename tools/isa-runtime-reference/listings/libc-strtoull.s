	.file	"strtoull.c"
	.section .text
	.p2align 4,,15
	.globl	_strtoull
_strtoull:
LFB0:
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
	subl	$60, %esp
	.cfi_def_cfa_offset 80
	movl	80(%esp), %ebp
	.p2align 4,,7
L2:
	movb	0(%ebp), %bl
	xorl	%eax, %eax
	movb	%bl, %al
	incl	%ebp
	testb	$1, ___dj_ctype_flags+3(%eax,%eax)
	jne	L2
	cmpb	$45, %bl
	je	L51
	movl	$0, 44(%esp)
	cmpb	$43, %bl
	je	L52
L4:
	testl	$-17, 88(%esp)
	jne	L49
	movl	88(%esp), %eax
	testl	%eax, %eax
	sete	%al
	cmpb	$48, %bl
	je	L53
	testb	%al, %al
	je	L49
	movl	$5, 40(%esp)
	movl	$-1717986919, %esi
	movl	$429496729, %edi
	movl	$10, 32(%esp)
	movl	$0, 36(%esp)
	movl	$10, 88(%esp)
	jmp	L9
L53:
	movb	0(%ebp), %dl
	andl	$-33, %edx
	cmpb	$88, %dl
	je	L54
	testb	%al, %al
	jne	L32
	.p2align 4,,7
L49:
	movl	88(%esp), %eax
	movl	$-1, (%esp)
	movl	%eax, %edx
	movl	%eax, 8(%esp)
	sarl	$31, %edx
	movl	$-1, 4(%esp)
	movl	%edx, 12(%esp)
	movl	%eax, 32(%esp)
	movl	%edx, 36(%esp)
	call	___udivdi3
	movl	36(%esp), %ecx
	movl	%edx, %edi
	movl	32(%esp), %edx
	movl	%ecx, 12(%esp)
	movl	%edx, 8(%esp)
	movl	$-1, (%esp)
	movl	$-1, 4(%esp)
	movl	%eax, %esi
	call	___umoddi3
	movl	%eax, 40(%esp)
L9:
	xorl	%edx, %edx
	xorl	%ecx, %ecx
	xorl	%eax, %eax
	movl	%esi, 24(%esp)
	movl	%edi, 28(%esp)
	movl	%eax, %esi
	movl	%edx, %edi
	movl	%ecx, %edx
	jmp	L18
	.p2align 4,,7
L56:
	subl	$48, %ebx
	xorl	%eax, %eax
	movb	%bl, %al
	cmpl	%eax, 88(%esp)
	jle	L12
L57:
	cmpl	28(%esp), %edi
	ja	L29
	jb	L16
	cmpl	24(%esp), %esi
	ja	L29
L16:
	shrl	$31, %edx
	jne	L29
	movl	28(%esp), %ecx
	movl	24(%esp), %edx
	xorl	%edi, %ecx
	xorl	%esi, %edx
	orl	%edx, %ecx
	je	L55
L17:
	movl	32(%esp), %ecx
	movl	36(%esp), %eax
	imull	%esi, %eax
	imull	%edi, %ecx
	addl	%eax, %ecx
	movl	32(%esp), %eax
	mull	%esi
	andl	$255, %ebx
	movl	%eax, 16(%esp)
	movl	%ebx, %esi
	addl	%ecx, %edx
	xorl	%edi, %edi
	addl	16(%esp), %esi
	movl	%edx, 20(%esp)
	movl	$1, %edx
	adcl	20(%esp), %edi
L14:
	movb	0(%ebp), %bl
	incl	%ebp
L18:
	xorl	%eax, %eax
	movb	%bl, %al
	movw	___dj_ctype_flags+2(%eax,%eax), %ax
	testb	$8, %al
	jne	L56
	testb	$2, %al
	je	L12
	andl	$512, %eax
	cmpw	$1, %ax
	sbbl	%eax, %eax
	andl	$32, %eax
	addl	$55, %eax
	subl	%eax, %ebx
	xorl	%eax, %eax
	movb	%bl, %al
	cmpl	%eax, 88(%esp)
	jg	L57
L12:
	movl	%edx, %ecx
	movl	%esi, %eax
	movl	%edi, %edx
	cmpl	$-1, %ecx
	je	L58
	movl	44(%esp), %esi
	testl	%esi, %esi
	jne	L59
L22:
	movl	84(%esp), %ebx
	testl	%ebx, %ebx
	je	L38
	testl	%ecx, %ecx
	jne	L20
L23:
	movl	84(%esp), %ecx
	movl	80(%esp), %ebx
	movl	%ebx, (%ecx)
L38:
	addl	$60, %esp
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
L29:
	.cfi_restore_state
	orl	$-1, %edx
	jmp	L14
	.p2align 4,,7
L55:
	orl	$-1, %edx
	cmpl	40(%esp), %eax
	jg	L14
	jmp	L17
	.p2align 4,,7
L58:
	movl	84(%esp), %edi
	orl	$-1, %eax
	orl	$-1, %edx
	movl	$2, _errno
	testl	%edi, %edi
	je	L38
L20:
	decl	%ebp
	movl	%ebp, 80(%esp)
	jmp	L23
	.p2align 4,,7
L59:
	negl	%eax
	adcl	$0, %edx
	negl	%edx
	jmp	L22
	.p2align 4,,7
L51:
	movb	0(%ebp), %bl
	movl	$1, 44(%esp)
	incl	%ebp
	jmp	L4
	.p2align 4,,7
L52:
	movb	0(%ebp), %bl
	incl	%ebp
	jmp	L4
L54:
	movb	1(%ebp), %bl
	movl	$15, 40(%esp)
	addl	$2, %ebp
	orl	$-1, %esi
	movl	$268435455, %edi
	movl	$16, 32(%esp)
	movl	$0, 36(%esp)
	movl	$16, 88(%esp)
	jmp	L9
L32:
	movl	$7, 40(%esp)
	orl	$-1, %esi
	movl	$536870911, %edi
	movl	$8, 32(%esp)
	movl	$0, 36(%esp)
	movl	$8, 88(%esp)
	jmp	L9
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
