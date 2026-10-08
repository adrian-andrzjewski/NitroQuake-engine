	.file	"dosio.c"
	.section .text
	.p2align 4,,15
	.globl	___file_handle_set
___file_handle_set:
LFB0:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$84, %esp
	.cfi_def_cfa_offset 96
	movl	___bss_count, %eax
	movl	96(%esp), %ebx
	cmpl	%eax, _dosio_bss_count
	je	L2
	movl	%eax, _dosio_bss_count
	movl	$20, _count
	movl	$_init_file_handle_modes, ___file_handle_modes
L2:
	testl	%ebx, %ebx
	js	L1
	movl	_count, %esi
	leal	-1(%esi), %eax
	cmpl	%eax, %ebx
	jb	L4
	cmpl	$254, %esi
	jbe	L8
L4:
	movl	___file_handle_modes, %edx
	movl	100(%esp), %eax
	movb	%al, (%edx,%ebx)
L1:
	addl	$84, %esp
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
L8:
	.cfi_restore_state
	movl	$255, (%esp)
	movl	$255, _count
	call	_malloc
	movl	_init_file_handle_modes, %edx
	movl	%eax, ___file_handle_modes
	movl	%edx, (%eax)
	movl	_init_file_handle_modes+4, %edx
	movl	%edx, 4(%eax)
	movl	_init_file_handle_modes+8, %edx
	movl	%edx, 8(%eax)
	movl	_init_file_handle_modes+12, %edx
	movl	%edx, 12(%eax)
	movl	_init_file_handle_modes+16, %edx
	movl	%edx, 16(%eax)
	movl	$255, %edx
	subl	%esi, %edx
	addl	%eax, %esi
	movl	%edx, 8(%esp)
	movl	$0, 4(%esp)
	movl	%esi, (%esp)
	call	_memset
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movl	$33, (%esp)
	movb	$103, 57(%esp)
	movw	$255, 44(%esp)
	call	___dpmi_int
	jmp	L4
	.cfi_endproc
LFE0:
	.globl	___file_handle_modes
	.section .data
	.p2align 2
___file_handle_modes:
	.long	_init_file_handle_modes
	.p2align 2
_dosio_bss_count:
	.long	-1
	.p2align 2
_count:
	.long	20
	.p2align 4
_init_file_handle_modes:
	.byte	8
	.byte	8
	.byte	8
	.byte	4
	.byte	4
	.space 15
	.ident	"GCC: (GNU) 4.7.4"
