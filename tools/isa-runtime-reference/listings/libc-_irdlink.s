	.file	"_irdlink.c"
	.section .text
	.p2align 4,,15
___FSEXT_call_open_handlers_wrapper.constprop.0:
LFB4:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	40(%esp), %eax
	movl	$17, (%esp)
	movl	%eax, 8(%esp)
	movl	36(%esp), %eax
	movl	%eax, 4(%esp)
	call	___FSEXT_call_open_handlers
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE4:
	.p2align 4,,15
___FSEXT_func_wrapper.constprop.1:
LFB3:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	44(%esp), %eax
	movl	$17, (%esp)
	movl	%eax, 8(%esp)
	movl	40(%esp), %eax
	movl	%eax, 4(%esp)
	call	*32(%esp)
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE3:
LC0:
	.ascii "!<symlink>\0"
LC1:
	.ascii "\15\12\0"
	.p2align 4,,15
	.globl	___internal_readlink
___internal_readlink:
LFB2:
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
	subl	$588, %esp
	.cfi_def_cfa_offset 608
	movl	616(%esp), %eax
	movl	608(%esp), %ebp
	movl	612(%esp), %edi
	testl	%eax, %eax
	je	L25
	testl	%ebp, %ebp
	setne	%al
	testl	%edi, %edi
	setne	%bl
	jne	L65
L27:
	testl	%edi, %edi
	sete	47(%esp)
	je	L66
L8:
	testb	%al, %al
	je	L10
	movl	620(%esp), %eax
	movl	%ebp, 8(%esp)
	movl	%eax, 16(%esp)
	movl	616(%esp), %eax
	movl	%eax, 12(%esp)
	leal	60(%esp), %eax
	movl	%eax, 4(%esp)
	movl	$17, (%esp)
	call	___FSEXT_call_open_handlers_wrapper.constprop.0
	testl	%eax, %eax
	je	L11
L63:
	movl	60(%esp), %ebx
L58:
	addl	$588, %esp
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
L67:
	.cfi_restore_state
	cmpb	$0, 47(%esp)
	je	L25
	movl	%ebx, (%esp)
	call	___close
	.p2align 4,,7
L25:
	movl	$14, _errno
L62:
	addl	$588, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	orl	$-1, %ebx
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
L10:
	.cfi_restore_state
	testb	%bl, %bl
	je	L25
	movl	%edi, (%esp)
	call	___FSEXT_get_function
	testl	%eax, %eax
	je	L16
	leal	60(%esp), %edx
	movl	$0, 12(%esp)
	movl	%edx, 8(%esp)
	movl	$17, 4(%esp)
	movl	%eax, (%esp)
	call	___FSEXT_func_wrapper.constprop.1
	testl	%eax, %eax
	jne	L63
L16:
	movl	%edi, (%esp)
	call	___filelength
	cmpl	$510, %eax
	jne	L25
L20:
	movl	%edi, (%esp)
	call	___tell
	movl	%eax, %ebx
	cmpl	$-1, %eax
	je	L62
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%edi, (%esp)
	leal	66(%esp), %esi
	call	___lseek
	movl	$510, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%edi, (%esp)
	call	__read
	movl	%ebx, 4(%esp)
	movl	$0, 8(%esp)
	movl	%edi, (%esp)
	movl	%eax, %ebp
	call	___lseek
	movl	%edi, %ebx
L22:
	incl	%ebp
	je	L62
	movl	$LC0, %edi
	movl	$10, %ecx
	repe cmpsb
	jne	L67
	leal	76(%esp), %esi
	movl	$LC1, 4(%esp)
	movl	%esi, (%esp)
	call	_strpbrk
	movl	%eax, %ebx
	subl	%esi, %ebx
	movl	%ebx, %eax
	cmpl	%ebx, 620(%esp)
	jae	L26
	movl	620(%esp), %ebx
	movl	%ebx, %eax
L26:
	movl	%eax, 8(%esp)
	movl	616(%esp), %eax
	movl	%esi, 4(%esp)
	movl	%eax, (%esp)
	call	_memcpy
	addl	$588, %esp
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
L11:
	.cfi_restore_state
	leal	66(%esp), %esi
	movl	$33, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%ebp, (%esp)
	call	___findfirst
	testl	%eax, %eax
	je	L13
	movl	$22, _errno
	orl	$-1, %ebx
	jmp	L58
	.p2align 4,,7
L13:
	cmpl	$510, 92(%esp)
	jne	L25
	testb	%bl, %bl
	jne	L20
	movl	$0, 4(%esp)
	movl	%ebp, (%esp)
	call	__open
	movl	%eax, %ebx
	testl	%eax, %eax
	js	L68
L23:
	movl	$510, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%ebx, (%esp)
	call	__read
	movl	%ebx, (%esp)
	movl	%eax, %ebp
	call	__close
	jmp	L22
	.p2align 4,,7
L65:
	testb	%al, %al
	je	L27
	jmp	L25
	.p2align 4,,7
L66:
	testl	%ebp, %ebp
	jne	L8
	jmp	L25
	.p2align 4,,7
L68:
	movl	$64, 4(%esp)
	movl	%ebp, (%esp)
	call	__open
	movl	%eax, %ebx
	testl	%eax, %eax
	jns	L23
	jmp	L62
	.cfi_endproc
LFE2:
	.ident	"GCC: (GNU) 4.7.4"
