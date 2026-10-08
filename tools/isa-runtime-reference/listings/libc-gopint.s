	.file	"gopint.c"
	.section .text
	.p2align 4,,15
	.globl	__go32_dpmi_lock_data
__go32_dpmi_lock_data:
LFB3:
	.cfi_startproc
	subl	$44, %esp
	.cfi_def_cfa_offset 48
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%ax
# 0 "" 2
/NO_APP
	leal	16(%esp), %edx
	andl	$65535, %eax
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	___dpmi_get_segment_base_address
	incl	%eax
	je	L4
	movl	48(%esp), %edx
	movl	16(%esp), %ecx
	addl	%ecx, %edx
	leal	20(%esp), %eax
	movl	%edx, 28(%esp)
	movl	%eax, (%esp)
	movl	52(%esp), %edx
	movl	$0, 20(%esp)
	movl	%edx, 24(%esp)
	call	___dpmi_lock_linear_region
	incl	%eax
	je	L4
	xorl	%eax, %eax
L3:
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L4:
	.cfi_restore_state
	orl	$-1, %eax
	jmp	L3
	.cfi_endproc
LFE3:
	.p2align 4,,15
	.globl	__go32_dpmi_lock_code
__go32_dpmi_lock_code:
LFB4:
	.cfi_startproc
	subl	$44, %esp
	.cfi_def_cfa_offset 48
/APP
# 28 "c:/djgpp/include/sys/segments.h" 1
	movw %cs,%ax
# 0 "" 2
/NO_APP
	leal	16(%esp), %edx
	andl	$65535, %eax
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	___dpmi_get_segment_base_address
	incl	%eax
	je	L13
	movl	48(%esp), %edx
	movl	16(%esp), %ecx
	addl	%ecx, %edx
	leal	20(%esp), %eax
	movl	%edx, 28(%esp)
	movl	%eax, (%esp)
	movl	52(%esp), %edx
	movl	$0, 20(%esp)
	movl	%edx, 24(%esp)
	call	___dpmi_lock_linear_region
	incl	%eax
	je	L13
	xorl	%eax, %eax
L12:
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L13:
	.cfi_restore_state
	orl	$-1, %eax
	jmp	L12
	.cfi_endproc
LFE4:
	.p2align 4,,15
	.globl	__go32_dpmi_chain_protected_mode_interrupt_vector
__go32_dpmi_chain_protected_mode_interrupt_vector:
LFB6:
	.cfi_startproc
	cmpl	$511, __go32_interrupt_stack_size
	ja	L19
	movl	$32789, %eax
	ret
	.p2align 4,,7
L19:
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
	movl	$97, (%esp)
	call	_malloc
	movl	%eax, %ebx
	testl	%eax, %eax
	je	L28
	movl	$97, 4(%esp)
	movl	%eax, (%esp)
	call	__go32_dpmi_lock_data
	testl	%eax, %eax
	je	L29
L28:
	movl	$32789, %eax
L20:
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
	movl	__go32_interrupt_stack_size, %ebp
	movl	%ebp, (%esp)
	call	_malloc
	testl	%eax, %eax
	je	L30
	movl	%ebp, 4(%esp)
	movl	%eax, (%esp)
	movl	%eax, 28(%esp)
	call	__go32_dpmi_lock_data
	movl	28(%esp), %edx
	testl	%eax, %eax
	jne	L28
	leal	40(%esp), %eax
	movl	$1, (%edx)
	movl	$0, 4(%edx)
	movl	$0, 8(%edx)
	movl	%eax, 4(%esp)
	movl	80(%esp), %eax
	movl	%eax, (%esp)
	movl	$_wrapper_intcommon, %esi
	call	___dpmi_get_protected_mode_interrupt_vector
	movl	%ebx, %edi
	movl	$20, %ecx
	rep movsl
	movl	(%esi), %eax
	movw	%ax, (%edi)
	movb	_wrapper_intcommon+82, %al
	movb	%al, 2(%edi)
	movl	_wrapper_intchain, %eax
	movl	%eax, 83(%ebx)
	movl	_wrapper_intchain+4, %eax
	movl	%eax, 87(%ebx)
	movl	_wrapper_intchain+8, %eax
	movl	%eax, 91(%ebx)
	movl	28(%esp), %edx
	movw	_wrapper_intchain+12, %ax
	movw	%ax, 95(%ebx)
	movw	___djgpp_ds_alias, %ax
	movw	%ax, 9(%ebx)
	leal	8(%edx), %eax
	movl	%eax, 15(%ebx)
	leal	4(%edx), %eax
	addl	%ebp, %edx
	movl	%eax, 21(%ebx)
	movl	%edx, 42(%ebx)
	movl	84(%esp), %edx
	movl	%eax, 30(%ebx)
	movl	4(%edx), %edx
	movl	%eax, 70(%ebx)
	leal	91(%ebx), %eax
	subl	$62, %edx
	movl	%eax, 86(%ebx)
	movl	40(%esp), %eax
	movl	%eax, 91(%ebx)
	movl	44(%esp), %eax
	movw	%ax, 95(%ebx)
	subl	%ebx, %edx
/APP
# 28 "c:/djgpp/include/sys/segments.h" 1
	movw %cs,%ax
# 0 "" 2
/NO_APP
	movw	%ax, 44(%esp)
	leal	40(%esp), %eax
	movl	%eax, 4(%esp)
	movl	80(%esp), %eax
	movl	%edx, 58(%ebx)
	movl	%ebx, 40(%esp)
	movl	%eax, (%esp)
	call	___dpmi_set_protected_mode_interrupt_vector
	xorl	%eax, %eax
	jmp	L20
L30:
	movl	%ebx, (%esp)
	call	_free
	jmp	L28
	.cfi_endproc
LFE6:
	.p2align 4,,15
	.globl	__go32_dpmi_allocate_iret_wrapper
__go32_dpmi_allocate_iret_wrapper:
LFB8:
	.cfi_startproc
	cmpl	$511, __go32_interrupt_stack_size
	ja	L32
	movl	$32789, %eax
	ret
	.p2align 4,,7
L32:
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
	movl	$84, (%esp)
	call	_malloc
	movl	%eax, %ebx
	testl	%eax, %eax
	je	L41
	movl	$84, 4(%esp)
	movl	%eax, (%esp)
	call	__go32_dpmi_lock_data
	testl	%eax, %eax
	je	L42
L41:
	movl	$32789, %eax
L33:
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
L42:
	.cfi_restore_state
	movl	__go32_interrupt_stack_size, %ebp
	movl	%ebp, (%esp)
	call	_malloc
	testl	%eax, %eax
	je	L43
	movl	%ebp, 4(%esp)
	movl	%eax, (%esp)
	movl	%eax, 24(%esp)
	call	__go32_dpmi_lock_data
	movl	24(%esp), %edx
	testl	%eax, %eax
	jne	L41
	movl	$_wrapper_intcommon, %esi
	movl	$20, %ecx
	movl	%ebx, %edi
	movl	$0, 4(%edx)
	rep movsl
	movl	$0, 8(%edx)
	movl	$1, (%edx)
	movl	(%esi), %eax
	movw	%ax, (%edi)
	movb	_wrapper_intcommon+82, %al
	movb	%al, 2(%edi)
	movb	_wrapper_intiret, %al
	movb	%al, 83(%ebx)
	movw	___djgpp_ds_alias, %ax
	movw	%ax, 9(%ebx)
	leal	8(%edx), %eax
	movl	%eax, 15(%ebx)
	leal	4(%edx), %eax
	addl	%ebp, %edx
	movl	%eax, 21(%ebx)
	movl	%edx, 42(%ebx)
	movl	64(%esp), %edx
	movl	%eax, 30(%ebx)
	movl	4(%edx), %edx
	movl	%eax, 70(%ebx)
	movl	%edx, 28(%esp)
	subl	$62, %edx
	subl	%ebx, %edx
	movl	64(%esp), %eax
	movl	%edx, 58(%ebx)
	movl	64(%esp), %edx
	movl	%ebx, 4(%eax)
/APP
# 28 "c:/djgpp/include/sys/segments.h" 1
	movw %cs,%ax
# 0 "" 2
/NO_APP
	movw	%ax, 8(%edx)
	xorl	%eax, %eax
	jmp	L33
L43:
	movl	%ebx, (%esp)
	call	_free
	jmp	L41
	.cfi_endproc
LFE8:
	.p2align 4,,15
	.globl	__go32_dpmi_free_iret_wrapper
__go32_dpmi_free_iret_wrapper:
LFB9:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	movl	4(%eax), %ebx
	movl	15(%ebx), %eax
	leal	-8(%eax), %edx
	testb	$1, -8(%eax)
	je	L45
	movl	%edx, (%esp)
	call	_free
L45:
	movl	%ebx, (%esp)
	call	_free
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE9:
	.globl	__go32_interrupt_stack_size
	.section .data
	.p2align 2
__go32_interrupt_stack_size:
	.long	32256
	.section .text
	.p2align 4
_wrapper_intcommon:
	.byte	30
	.byte	6
	.byte	15
	.byte	-96
	.byte	15
	.byte	-88
	.byte	96
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
	.byte	47
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
	.byte	-24
	.byte	0
	.byte	0
	.byte	0
	.byte	0
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
	.byte	97
	.byte	-112
	.byte	15
	.byte	-87
	.byte	15
	.byte	-95
	.byte	7
	.byte	31
_wrapper_intchain:
	.byte	46
	.byte	-1
	.byte	45
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	-49
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
_wrapper_intiret:
	.byte	-49
	.ident	"GCC: (GNU) 4.7.4"
