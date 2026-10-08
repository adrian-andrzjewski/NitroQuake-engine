	.file	"frlist.c"
	.section .text
	.p2align 4,,15
	.globl	___setup_file_rec_list
___setup_file_rec_list:
LFB8:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	$0, ___initial_file_rec
	movl	___dj_stdin+20, %eax
	movl	$5, ___initial_file_rec+4
	movl	%eax, (%esp)
	movl	$___dj_stdin, ___initial_file_rec+8
	movl	$___dj_stdout, ___initial_file_rec+12
	movl	$___dj_stderr, ___initial_file_rec+16
	movl	$___dj_stdprn, ___initial_file_rec+20
	movl	$___dj_stdaux, ___initial_file_rec+24
	call	__get_dev_info
	incw	%ax
	je	L9
L2:
	movl	___dj_stdout+20, %eax
	movl	%eax, (%esp)
	call	__get_dev_info
	incw	%ax
	je	L10
L3:
	movl	___dj_stderr+20, %eax
	movl	%eax, (%esp)
	call	__get_dev_info
	incw	%ax
	je	L11
L4:
	movl	___dj_stdprn+20, %eax
	movl	%eax, (%esp)
	call	__get_dev_info
	incw	%ax
	je	L12
L5:
	movl	___dj_stdaux+20, %eax
	movl	%eax, (%esp)
	call	__get_dev_info
	incw	%ax
	jne	L1
	movl	$-1, ___dj_stdaux+20
L1:
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L12:
	.cfi_restore_state
	movl	$-1, ___dj_stdprn+20
	jmp	L5
	.p2align 4,,7
L11:
	movl	$-1, ___dj_stderr+20
	jmp	L4
	.p2align 4,,7
L10:
	movl	$-1, ___dj_stdout+20
	jmp	L3
	.p2align 4,,7
L9:
	movl	$-1, ___dj_stdin+20
	jmp	L2
	.cfi_endproc
LFE8:
	.globl	___file_rec_list
	.section .data
	.p2align 2
___file_rec_list:
	.long	___initial_file_rec
.lcomm ___initial_file_rec,88,16
	.ident	"GCC: (GNU) 4.7.4"
