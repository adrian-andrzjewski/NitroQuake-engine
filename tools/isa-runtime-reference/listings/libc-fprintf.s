	.file	"fprintf.c"
	.section .text
	.p2align 4,,15
	.globl	_fprintf
_fprintf:
LFB8:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$16404, %esp
	.cfi_def_cfa_offset 16416
	movl	16416(%esp), %ebx
	movl	16420(%esp), %edx
	leal	16424(%esp), %ecx
	movl	16(%ebx), %eax
	testb	$2, %al
	je	L2
	andl	$-3, %eax
	movl	$16384, 12(%ebx)
	movl	%eax, 16(%ebx)
	leal	16(%esp), %eax
	movl	%eax, 8(%ebx)
	movl	%eax, 4(%ebx)
	movl	%edx, (%esp)
	movl	%ecx, 4(%esp)
	movl	%ebx, 8(%esp)
	call	__doprnt
	movl	%ebx, (%esp)
	movl	%eax, %esi
	call	_fflush
	movl	16(%ebx), %edx
	movl	$0, 8(%ebx)
	orl	$2, %edx
	movl	$0, 12(%ebx)
	movl	%edx, 16(%ebx)
	movl	$0, (%ebx)
L3:
	andl	$128, %edx
	jne	L10
L4:
	addl	$16404, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	movl	%esi, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L2:
	.cfi_restore_state
	movl	%edx, (%esp)
	movl	%ebx, 8(%esp)
	movl	%ecx, 4(%esp)
	call	__doprnt
	movl	16(%ebx), %edx
	movl	%eax, %esi
	jmp	L3
	.p2align 4,,7
L10:
	orl	$-1, %esi
	jmp	L4
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
