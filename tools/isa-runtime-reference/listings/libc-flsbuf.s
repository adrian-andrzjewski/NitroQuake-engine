	.file	"flsbuf.c"
	.section .text
	.p2align 4,,15
	.globl	__flsbuf
__flsbuf:
LFB16:
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
	movl	84(%esp), %edi
	movl	16(%edi), %ebp
	testl	$512, %ebp
	je	L2
	andl	$-73, %ebp
	orl	$16, %ebp
	movl	%ebp, 16(%edi)
L2:
	testl	$16, %ebp
	je	L46
	testl	$256, %ebp
	jne	L32
	movl	8(%edi), %esi
	testl	%esi, %esi
	je	L47
L6:
	testl	$4, %ebp
	je	L9
	movl	4(%edi), %ebx
	movb	80(%esp), %al
	movb	%al, (%ebx)
	incl	%ebx
	movl	%ebx, 4(%edi)
	subl	%esi, %ebx
	cmpl	$10, 80(%esp)
	je	L10
	cmpl	12(%edi), %ebx
	jb	L11
L10:
	movl	%esi, 4(%edi)
	movl	$0, (%edi)
	movl	16(%edi), %ebp
L16:
	testl	%ebx, %ebx
	jne	L43
	jmp	L13
	.p2align 4,,7
L17:
	movl	___libc_write_termios_hook, %eax
	testl	%eax, %eax
	je	L20
	leal	44(%esp), %edx
	movl	%ebx, 8(%esp)
	movl	%edx, 12(%esp)
	movl	%esi, 4(%esp)
	movl	20(%edi), %edx
	movl	%edx, (%esp)
	call	*%eax
	testl	%eax, %eax
	je	L20
	movl	44(%esp), %eax
	testl	%eax, %eax
	jle	L48
	.p2align 4,,7
L23:
	addl	%eax, %esi
	subl	%eax, %ebx
	movl	16(%edi), %ebp
	je	L13
L43:
	andl	$8192, %ebp
	jne	L17
L20:
	movl	20(%edi), %ebp
	testl	%ebp, %ebp
	js	L19
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L19
	movl	(%eax,%ebp,4), %eax
	testl	%eax, %eax
	je	L19
	testb	$16, 8(%eax)
	je	L19
	movl	_errno, %eax
	movl	$2, 12(%esp)
	movl	$0, 4(%esp)
	movl	$0, 8(%esp)
	movl	%ebp, (%esp)
	movl	%eax, 28(%esp)
	call	___llseek
	andl	%edx, %eax
	incl	%eax
	je	L49
L19:
	movl	%ebx, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%ebp, (%esp)
	call	__write
	movl	%eax, 44(%esp)
	testl	%eax, %eax
	jg	L23
L48:
	orl	$128, 16(%edi)
	movl	$-1, 80(%esp)
L32:
	movl	80(%esp), %eax
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
L9:
	.cfi_restore_state
	testl	$2, %ebp
	je	L14
	movb	80(%esp), %dl
	movl	$0, (%edi)
	movb	%dl, 43(%esp)
	movl	$1, %ebx
	leal	43(%esp), %esi
	jmp	L43
	.p2align 4,,7
L13:
	andl	$6, %ebp
	jne	L32
	movl	(%edi), %eax
	movb	80(%esp), %dl
	decl	%eax
	movl	%eax, (%edi)
	movl	4(%edi), %eax
	movb	%dl, (%eax)
	incl	%eax
	movl	%eax, 4(%edi)
	movl	80(%esp), %eax
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
L14:
	.cfi_restore_state
	movl	4(%edi), %ebx
	movl	12(%edi), %eax
	subl	%esi, %ebx
	movl	%esi, 4(%edi)
	movl	%eax, (%edi)
	jmp	L16
	.p2align 4,,7
L47:
	testl	$2, %ebp
	jne	L6
	movl	__go32_info_block+16, %ebx
	movl	%ebx, (%esp)
	call	_malloc
	movl	%eax, %esi
	movl	%eax, 8(%edi)
	testl	%eax, %eax
	je	L50
	orl	$32, %ebp
	movl	%ebx, 12(%edi)
	movl	%ebp, 16(%edi)
	movl	%ebx, (%edi)
	movl	%eax, 4(%edi)
	cmpl	$___dj_stdout, %edi
	jne	L6
	movl	___dj_stdout+20, %eax
	movl	%eax, (%esp)
	call	___isatty
	movl	___dj_stdout+16, %ebp
	testl	%eax, %eax
	je	L6
	orl	$4, %ebp
	movl	%ebp, ___dj_stdout+16
	jmp	L6
	.p2align 4,,7
L11:
	negl	%ebx
	movl	%ebx, (%edi)
	jmp	L32
	.p2align 4,,7
L49:
	movl	28(%esp), %edx
	movl	$-1, 80(%esp)
	movl	%edx, _errno
	jmp	L32
L46:
	orl	$128, %ebp
	movl	$-1, 80(%esp)
	movl	%ebp, 16(%edi)
	jmp	L32
L50:
	andl	$-6, %ebp
	orl	$2, %ebp
	movl	%ebp, 16(%edi)
	jmp	L6
	.cfi_endproc
LFE16:
	.ident	"GCC: (GNU) 4.7.4"
