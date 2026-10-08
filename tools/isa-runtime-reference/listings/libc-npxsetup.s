	.file	"npxsetup.c"
	.section .text
	.p2align 4,,15
_nofpsig:
LFB6:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	___djgpp_exception_state_ptr, %eax
	movl	%eax, (%esp)
	call	*__emu_entry
	testl	%eax, %eax
	je	L2
	movl	$289, 32(%esp)
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	jmp	_raise
L2:
	.cfi_restore_state
	movl	___djgpp_exception_state_ptr, %eax
	movl	(%eax), %edx
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	call	_longjmp
	.cfi_endproc
LFE6:
LC0:
	.ascii "387\0"
LC1:
	.ascii "No \0"
LC2:
	.ascii "80387 detected.\15\12\0"
	.p2align 2
LC3:
	.ascii "Warning: Coprocessor not present and DPMI setup failed!\15\12\0"
	.p2align 2
LC4:
	.ascii "         If application attempts floating operations system may hang!\15\12\0"
LC5:
	.ascii "EMU387\0"
	.p2align 4,,15
	.globl	__npxsetup
__npxsetup:
LFB7:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$548, %esp
	.cfi_def_cfa_offset 560
	movl	$LC0, (%esp)
	movl	560(%esp), %esi
	call	_getenv
	movl	%eax, %ebx
	testl	%eax, %eax
	je	L6
	xorl	%eax, %eax
	movb	(%ebx), %al
	movb	___dj_ctype_tolower+1(%eax), %al
	cmpb	$121, %al
	je	L47
	cmpb	$110, %al
	je	L9
L6:
	movl	$1, (%esp)
	call	___dpmi_set_coprocessor_emulation
	call	__detect_80387
	cmpb	$1, %al
	movb	%al, %cl
	sbbl	%edx, %edx
	xorl	$-1, %edx
	andl	$3, %edx
	testl	%ebx, %ebx
	movl	%edx, __8087
	je	L11
	xorl	%eax, %eax
	movb	(%ebx), %al
	cmpb	$113, ___dj_ctype_tolower+1(%eax)
	je	L48
L11:
	testb	%cl, %cl
	jne	L46
L13:
	movl	$3, (%esp)
	call	___dpmi_set_coprocessor_emulation
	testl	%eax, %eax
	jne	L49
	movl	$LC5, (%esp)
	call	_getenv
	testl	%eax, %eax
	je	L50
L16:
	movl	%eax, (%esp)
	call	__dxe_load
	movl	%eax, __emu_entry
	testl	%eax, %eax
	je	L5
	movl	$_nofpsig, 4(%esp)
	movl	$301, (%esp)
	call	_signal
L46:
	movl	$65535, 4(%esp)
	movl	$831, (%esp)
	call	__control87
L5:
	addl	$548, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L49:
	.cfi_restore_state
	movl	$57, 8(%esp)
	movl	$LC3, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$71, 8(%esp)
	movl	$LC4, 4(%esp)
	movl	$2, (%esp)
	call	__write
	addl	$548, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L9:
	.cfi_restore_state
	xorl	%eax, %eax
	movl	$0, __8087
	movb	(%ebx), %al
	cmpb	$113, ___dj_ctype_tolower+1(%eax)
	jne	L13
	xorl	%ecx, %ecx
L23:
	movl	$3, 8(%esp)
	movl	$LC1, 4(%esp)
	movl	$2, (%esp)
	movb	%cl, 28(%esp)
	call	__write
	movb	28(%esp), %cl
L12:
	movl	$17, 8(%esp)
	movl	$LC2, 4(%esp)
	movl	$2, (%esp)
	movb	%cl, 28(%esp)
	call	__write
	movb	28(%esp), %cl
	jmp	L11
	.p2align 4,,7
L48:
	testb	%cl, %cl
	jne	L12
	jmp	L23
	.p2align 4,,7
L47:
	movl	$65535, 4(%esp)
	movl	$831, (%esp)
	movl	$3, __8087
	call	__control87
	jmp	L5
	.p2align 4,,7
L50:
	leal	32(%esp), %ecx
	movl	%ecx, %edx
	.p2align 4,,7
L44:
	movb	(%esi), %al
	incl	%esi
	movb	%al, (%edx)
	incl	%edx
	testb	%al, %al
	je	L51
	cmpb	$92, %al
	je	L26
	cmpb	$47, %al
	jne	L44
L26:
	movl	%edx, %ecx
	jmp	L44
	.p2align 4,,7
L51:
	movb	$0, (%ecx)
	leal	32(%esp), %ecx
L19:
	movl	(%ecx), %edx
	addl	$4, %ecx
	leal	-16843009(%edx), %eax
	xorl	$-1, %edx
	andl	%edx, %eax
	andl	$-2139062144, %eax
	je	L19
	testl	$32896, %eax
	jne	L21
	shrl	$16, %eax
	addl	$2, %ecx
L21:
	addb	%al, %al
	leal	32(%esp), %eax
	sbbl	$3, %ecx
	movl	$863333733, (%ecx)
	movl	$1680750392, 4(%ecx)
	movw	$25976, 8(%ecx)
	movb	$0, 10(%ecx)
	jmp	L16
	.cfi_endproc
LFE7:
.comm ___emu387_load_hook,16
.comm __8087,16
.lcomm __emu_entry,4,4
	.ident	"GCC: (GNU) 4.7.4"
