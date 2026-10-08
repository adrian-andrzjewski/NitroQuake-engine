	.file	"gormcb.c"
	.section .text
	.p2align 4,,15
_setup_rmcb.constprop.2:
LFB9:
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
	subl	$44, %esp
	.cfi_def_cfa_offset 64
	movl	%eax, %esi
	movl	__go32_rmcb_stack_size, %edi
	movl	%edx, %ebp
	movl	%edi, (%esp)
	movl	%ecx, 28(%esp)
	call	_malloc
	movl	28(%esp), %ecx
	movl	%eax, %ebx
	testl	%eax, %eax
	je	L8
	movl	%edi, 4(%esp)
	movl	%eax, (%esp)
	movl	%ecx, 28(%esp)
	call	__go32_dpmi_lock_data
	movl	28(%esp), %ecx
	testl	%eax, %eax
	je	L4
L5:
	movl	$32789, %eax
L3:
	addl	$44, %esp
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
	movl	$1, (%ebx)
	movl	$0, 4(%ebx)
	movl	$0, 8(%ebx)
	movl	%ecx, (%esp)
	movl	$52, 4(%esp)
	movl	%ecx, 28(%esp)
	call	__go32_dpmi_lock_data
	movl	28(%esp), %ecx
	testl	%eax, %eax
	jne	L5
	movw	___djgpp_ds_alias, %ax
	movw	%ax, 6(%esi)
	leal	8(%ebx), %eax
	movl	%eax, 12(%esi)
	leal	4(%ebx), %eax
	addl	%edi, %ebx
	movl	%eax, 18(%esi)
	movl	%ebx, 39(%esi)
	movl	%eax, 27(%esi)
	movl	4(%ebp), %edx
	movl	%eax, 71(%esi)
	subl	$61, %edx
	subl	%esi, %edx
	movl	%edx, 57(%esi)
	movl	%esi, 0(%ebp)
	addl	$10, %ebp
	movl	%esi, (%esp)
	movl	%ebp, 8(%esp)
	movl	%ecx, 4(%esp)
	call	___dpmi_allocate_real_mode_callback
	addl	$44, %esp
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
L8:
	.cfi_restore_state
	movl	%esi, (%esp)
	call	_free
	movl	$32789, %eax
	jmp	L3
	.cfi_endproc
LFE9:
	.p2align 4,,15
	.globl	__go32_dpmi_allocate_real_mode_callback_retf
__go32_dpmi_allocate_real_mode_callback_retf:
LFB5:
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
	subl	$44, %esp
	.cfi_def_cfa_offset 64
	cmpl	$511, __go32_rmcb_stack_size
	movl	64(%esp), %ebx
	movl	68(%esp), %ebp
	ja	L17
L11:
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	$32789, %eax
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
L17:
	.cfi_restore_state
	movl	$91, (%esp)
	call	_malloc
	movl	%eax, 28(%esp)
	testl	%eax, %eax
	je	L11
	movl	$91, 4(%esp)
	movl	%eax, (%esp)
	call	__go32_dpmi_lock_data
	testl	%eax, %eax
	jne	L11
	movl	28(%esp), %edi
	movl	$_wrapper_common, %esi
	movl	$21, %ecx
	movl	_wrapper_retf, %eax
	rep movsl
	movl	28(%esp), %edx
	movl	%ebp, %ecx
	movl	%eax, 84(%edx)
	movw	_wrapper_retf+4, %ax
	movw	%ax, 88(%edx)
	movb	_wrapper_retf+6, %al
	movb	%al, 90(%edx)
	movl	28(%esp), %eax
	addl	$44, %esp
	.cfi_def_cfa_offset 20
	movl	%ebx, %edx
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
	jmp	_setup_rmcb.constprop.2
	.cfi_endproc
LFE5:
	.p2align 4,,15
	.globl	__go32_dpmi_allocate_real_mode_callback_iret
__go32_dpmi_allocate_real_mode_callback_iret:
LFB7:
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
	subl	$44, %esp
	.cfi_def_cfa_offset 64
	cmpl	$511, __go32_rmcb_stack_size
	movl	64(%esp), %ebx
	movl	68(%esp), %ebp
	ja	L26
L20:
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	$32789, %eax
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
L26:
	.cfi_restore_state
	movl	$91, (%esp)
	call	_malloc
	movl	%eax, 28(%esp)
	testl	%eax, %eax
	je	L20
	movl	$91, 4(%esp)
	movl	%eax, (%esp)
	call	__go32_dpmi_lock_data
	testl	%eax, %eax
	jne	L20
	movl	28(%esp), %edi
	movl	$_wrapper_common, %esi
	movl	$21, %ecx
	movl	_wrapper_iret, %eax
	rep movsl
	movl	28(%esp), %edx
	movl	%ebp, %ecx
	movl	%eax, 84(%edx)
	movw	_wrapper_iret+4, %ax
	movw	%ax, 88(%edx)
	movb	_wrapper_iret+6, %al
	movb	%al, 90(%edx)
	movl	28(%esp), %eax
	addl	$44, %esp
	.cfi_def_cfa_offset 20
	movl	%ebx, %edx
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
	jmp	_setup_rmcb.constprop.2
	.cfi_endproc
LFE7:
	.p2align 4,,15
	.globl	__go32_dpmi_free_real_mode_callback
__go32_dpmi_free_real_mode_callback:
LFB8:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %ebx
	movl	(%ebx), %eax
	movl	18(%eax), %edx
	leal	-4(%edx), %ecx
	testb	$1, -4(%edx)
	je	L28
	movl	%ecx, (%esp)
	call	_free
	movl	(%ebx), %eax
L28:
	movl	%eax, (%esp)
	addl	$10, %ebx
	call	_free
	movl	%ebx, 32(%esp)
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	___dpmi_free_real_mode_callback
	.cfi_endproc
LFE8:
	.globl	__go32_rmcb_stack_size
	.section .data
	.p2align 2
__go32_rmcb_stack_size:
	.long	32256
	.section .text
	.p2align 4
_wrapper_common:
	.byte	6
	.byte	30
	.byte	6
	.byte	31
	.byte	102
	.byte	-72
	.byte	0
	.byte	0
	.byte	-114
	.byte	-40
	.byte	-1
	.byte	5
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	-125
	.byte	61
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	117
	.byte	51
	.byte	-58
	.byte	5
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	1
	.byte	-114
	.byte	-64
	.byte	-114
	.byte	-32
	.byte	-114
	.byte	-24
	.byte	-69
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	-4
	.byte	-119
	.byte	-31
	.byte	-116
	.byte	-46
	.byte	-114
	.byte	-48
	.byte	-119
	.byte	-36
	.byte	82
	.byte	81
	.byte	86
	.byte	87
	.byte	-24
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	95
	.byte	94
	.byte	88
	.byte	91
	.byte	-114
	.byte	-45
	.byte	-119
	.byte	-60
	.byte	-58
	.byte	5
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	31
	.byte	7
	.byte	-117
	.byte	6
	.byte	38
	.byte	-119
	.byte	71
	.byte	42
_wrapper_retf:
	.byte	102
	.byte	38
	.byte	-125
	.byte	71
	.byte	46
	.byte	4
	.byte	-49
_wrapper_iret:
	.byte	102
	.byte	38
	.byte	-125
	.byte	71
	.byte	46
	.byte	6
	.byte	-49
	.ident	"GCC: (GNU) 4.7.4"
