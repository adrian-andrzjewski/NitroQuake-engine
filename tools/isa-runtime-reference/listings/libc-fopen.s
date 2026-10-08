	.file	"fopen.c"
	.section .text
	.p2align 4,,15
	.globl	_fopen
_fopen:
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
	movl	48(%esp), %esi
	movl	52(%esp), %edi
	testl	%esi, %esi
	je	L37
	testl	%edi, %edi
	je	L37
	call	___alloc_file
	movl	%eax, %ebx
	testl	%eax, %eax
	je	L37
	movb	1(%edi), %al
	cmpb	$43, %al
	je	L20
	xorl	%ebp, %ebp
	testb	%al, %al
	jne	L40
L5:
	movb	(%edi), %dl
	cmpb	$114, %dl
	je	L7
L42:
	cmpb	$119, %dl
	je	L8
	cmpb	$97, %dl
	je	L41
L37:
	xorl	%ebx, %ebx
L29:
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%ebx, %eax
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
L40:
	.cfi_restore_state
	cmpb	$43, 2(%edi)
	sete	%dl
	andl	$255, %edx
	movl	%edx, %ebp
	movb	(%edi), %dl
	cmpb	$114, %dl
	jne	L42
L7:
	movl	%ebp, %edx
	negl	%edx
	andl	$2, %edx
	cmpb	$43, %al
	jne	L10
L43:
	movb	2(%edi), %al
	cmpb	$116, %al
	jne	L11
L44:
	movl	%edx, %eax
	orl	$8, %eax
	jmp	L12
	.p2align 4,,7
L8:
	cmpl	$1, %ebp
	sbbl	%edx, %edx
	addl	$2306, %edx
L9:
	cmpb	$43, %al
	je	L43
L10:
	cmpb	$116, %al
	je	L44
L11:
	cmpb	$98, %al
	je	L45
	movl	__fmode, %eax
	andl	$12, %eax
	orl	%edx, %eax
L12:
	movl	%esi, (%esp)
	movl	$438, 8(%esp)
	movl	%eax, 4(%esp)
	call	___open
	movl	%eax, %esi
	testl	%eax, %eax
	js	L37
	movl	$0, (%ebx)
	movl	%eax, 20(%ebx)
	movl	$0, 12(%ebx)
	testl	%ebp, %ebp
	je	L14
	movl	$512, 16(%ebx)
L15:
	cmpb	$97, (%edi)
	je	L46
L17:
	movl	___fd_properties, %eax
	movl	$0, 4(%ebx)
	movl	$0, 8(%ebx)
	testl	%eax, %eax
	je	L29
	movl	(%eax,%esi,4), %eax
	testl	%eax, %eax
	je	L29
	testb	$32, 8(%eax)
	je	L29
	movl	16(%ebx), %eax
	andl	$-537, %eax
	orl	$64, %eax
	movl	%eax, 16(%ebx)
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%ebx, %eax
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
L41:
	.cfi_restore_state
	cmpl	$1, %ebp
	sbbl	%edx, %edx
	addl	$4354, %edx
	jmp	L9
	.p2align 4,,7
L14:
	cmpb	$114, (%edi)
	setne	%al
	andl	$255, %eax
	leal	8(,%eax,8), %eax
	movl	%eax, 16(%ebx)
	jmp	L15
	.p2align 4,,7
L20:
	movl	$1, %ebp
	jmp	L5
	.p2align 4,,7
L45:
	movl	%edx, %eax
	orl	$4, %eax
	jmp	L12
	.p2align 4,,7
L46:
	movl	$2, 12(%esp)
	movl	$0, 4(%esp)
	movl	$0, 8(%esp)
	movl	%esi, (%esp)
	call	___llseek
	jmp	L17
	.cfi_endproc
LFE13:
	.ident	"GCC: (GNU) 4.7.4"
