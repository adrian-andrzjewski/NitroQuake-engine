	.file	"qsort.c"
	.section .text
	.p2align 4,,15
_Swap:
LFB4:
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
	subl	$300, %esp
	.cfi_def_cfa_offset 320
	movl	%edx, %esi
	movl	_DataWidth, %edx
	movl	%eax, %edi
	cmpl	$2, %edx
	je	L4
	cmpl	$4, %edx
	je	L5
	cmpl	$1, %edx
	je	L3
	leal	32(%esp), %ebp
	testl	%edx, %edx
	je	L1
	.p2align 4,,7
L12:
	movl	%edx, %ebx
	cmpl	$256, %edx
	jbe	L8
	movl	$256, %ebx
L8:
	movl	%edi, 4(%esp)
	movl	%ebx, 8(%esp)
	movl	%ebp, (%esp)
	movl	%edx, 28(%esp)
	call	_memcpy
	movl	%esi, 4(%esp)
	movl	%edi, (%esp)
	movl	%ebx, 8(%esp)
	call	_memcpy
	movl	%esi, (%esp)
	movl	%ebx, 8(%esp)
	movl	%ebp, 4(%esp)
	call	_memcpy
	movl	28(%esp), %edx
	addl	%ebx, %edi
	addl	%ebx, %esi
	subl	%ebx, %edx
	jne	L12
L1:
	addl	$300, %esp
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
L3:
	.cfi_restore_state
	movb	(%esi), %dl
	movb	(%eax), %al
	movb	%dl, (%edi)
	movb	%al, (%esi)
	addl	$300, %esp
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
L5:
	.cfi_restore_state
	movl	(%esi), %edx
	movl	(%eax), %eax
	movl	%edx, (%edi)
	movl	%eax, (%esi)
	addl	$300, %esp
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
	movw	(%esi), %dx
	movw	(%eax), %ax
	movw	%dx, (%edi)
	movw	%ax, (%esi)
	addl	$300, %esp
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
	.cfi_endproc
LFE4:
	.p2align 4,,15
_QuickSort:
LFB3:
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
	subl	$76, %esp
	.cfi_def_cfa_offset 96
	cmpl	%edx, %eax
	movl	%eax, 60(%esp)
	movl	%edx, 56(%esp)
	jae	L16
	movl	%edx, %eax
	movl	60(%esp), %ebx
	subl	%ebx, %eax
	cmpl	$8, %eax
	jbe	L18
L56:
	movl	60(%esp), %eax
	movl	56(%esp), %edx
	movl	60(%esp), %edi
	movl	56(%esp), %esi
	leal	1(%eax,%edx), %ecx
	movl	_DataWidth, %edx
	shrl	%ecx
	movl	_MyBase, %eax
	addl	%ecx, %edi
	addl	%ecx, %esi
	shrl	%edi
	decl	%ecx
	imull	%edx, %ecx
	shrl	%esi
	decl	%edi
	leal	(%eax,%ecx), %ebx
	movl	60(%esp), %ecx
	imull	%edx, %edi
	decl	%ecx
	decl	%esi
	imull	%edx, %ecx
	imull	%edx, %esi
	addl	%eax, %edi
	addl	%eax, %ecx
	movl	%edi, 4(%esp)
	movl	%ebx, (%esp)
	addl	%eax, %esi
	movl	%ecx, 40(%esp)
	call	*_Cmpr
	testl	%eax, %eax
	jle	L26
	movl	%esi, 4(%esp)
	movl	%edi, (%esp)
	call	*_Cmpr
	testl	%eax, %eax
	js	L68
L27:
	cmpl	%edi, 40(%esp)
	je	L28
	movl	%edi, %edx
	movl	40(%esp), %eax
	call	_Swap
L28:
	movl	60(%esp), %edx
	movl	56(%esp), %ecx
	incl	%edx
	decl	%ecx
	movl	%edx, 32(%esp)
	movl	60(%esp), %esi
	movl	_DataWidth, %edx
	movl	_MyBase, %eax
	imull	%edx, %esi
	imull	%ecx, %edx
	addl	%eax, %esi
	leal	(%eax,%edx), %ebx
	movl	56(%esp), %edx
	cmpl	%edx, 32(%esp)
	ja	L69
	movl	56(%esp), %edi
	movl	$1, 48(%esp)
	movl	$0, 44(%esp)
	xorl	%ebp, %ebp
	.p2align 4,,7
L62:
	movl	40(%esp), %eax
	movl	%esi, (%esp)
	movl	%eax, 4(%esp)
	call	*_Cmpr
	movl	%eax, 36(%esp)
	testl	%eax, %eax
	jns	L31
	movl	32(%esp), %ecx
	movl	_DataWidth, %eax
	incl	%ecx
	addl	%eax, %esi
	movl	%ecx, 32(%esp)
	cmpl	%edi, 32(%esp)
	jbe	L62
	cmpl	32(%esp), %edi
	jbe	L52
	.p2align 4,,7
L39:
	movl	%esi, %eax
	movl	%ebx, %edx
	call	_Swap
	movl	36(%esp), %eax
	testl	%eax, %eax
	jle	L41
	testw	%bp, %bp
	jne	L42
	movl	_DataWidth, %eax
	movl	%eax, %edx
	negl	%edx
L43:
	movl	32(%esp), %ecx
	decl	%edi
	incl	%ecx
	addl	%eax, %esi
	movl	%ecx, 32(%esp)
	addl	%edx, %ebx
	cmpl	%edi, 32(%esp)
	jbe	L62
	movl	48(%esp), %eax
	movl	56(%esp), %esi
	addl	%edi, %eax
	incl	%esi
	movl	%eax, 32(%esp)
	subl	%eax, %esi
	leal	-1(%edi), %ecx
	movl	%edi, %ebp
L40:
	cmpl	%ebx, 40(%esp)
	je	L45
	movl	%ebx, %edx
	movl	40(%esp), %eax
	movl	%ecx, 28(%esp)
	call	_Swap
	movl	28(%esp), %ecx
L45:
	movl	60(%esp), %eax
	subl	%eax, %ebp
	cmpl	%esi, %ebp
	jae	L46
	movl	%ecx, %edx
	movl	60(%esp), %eax
	call	_QuickSort
	movl	32(%esp), %eax
	movl	%eax, 60(%esp)
	movl	56(%esp), %edx
	cmpl	%edx, 60(%esp)
	jae	L16
L48:
	movl	56(%esp), %eax
	movl	60(%esp), %ecx
	subl	%ecx, %eax
	cmpl	$8, %eax
	ja	L56
L18:
	movl	_DataWidth, %eax
	movl	60(%esp), %ebp
	imull	%eax, %ebp
	movl	60(%esp), %edi
	movl	_MyBase, %edx
	incl	%edi
	addl	%edx, %ebp
	cmpl	%edi, 56(%esp)
	jb	L16
L63:
	leal	0(%ebp,%eax), %edx
	cmpl	$1, %edi
	movl	%edx, 32(%esp)
	jbe	L22
	movl	%edi, %esi
	jmp	L23
	.p2align 4,,7
L70:
	movl	%ebp, %edx
	movl	%ebx, %eax
	decl	%esi
	call	_Swap
	cmpl	$1, %esi
	je	L22
	movl	_DataWidth, %eax
	movl	%ebx, %ebp
L23:
	movl	%ebp, %ebx
	movl	%ebp, 4(%esp)
	subl	%eax, %ebx
	movl	%ebx, (%esp)
	call	*_Cmpr
	testl	%eax, %eax
	jg	L70
L22:
	incl	%edi
	cmpl	%edi, 56(%esp)
	jb	L16
	movl	_DataWidth, %eax
	movl	32(%esp), %ebp
	jmp	L63
	.p2align 4,,7
L31:
	cmpl	32(%esp), %edi
	jb	L52
	movl	%esi, 52(%esp)
	movl	40(%esp), %esi
	jmp	L57
	.p2align 4,,7
L71:
	testw	%bp, %bp
	jne	L35
	movl	_DataWidth, %eax
	negl	%eax
L36:
	decl	%edi
	addl	%eax, %ebx
	cmpl	32(%esp), %edi
	jb	L65
L57:
	movl	%esi, 4(%esp)
	movl	%ebx, (%esp)
	call	*_Cmpr
	cmpl	$0, %eax
	jl	L65
	jne	L71
	movl	48(%esp), %eax
	incl	%eax
	movl	%eax, 48(%esp)
	movl	_DataWidth, %eax
	negl	%eax
	testw	%bp, %bp
	jne	L37
	decl	%edi
	movl	%ebx, 44(%esp)
	movl	$1, %ebp
	addl	%eax, %ebx
	cmpl	32(%esp), %edi
	jae	L57
	.p2align 4,,7
L65:
	movl	52(%esp), %esi
	cmpl	32(%esp), %edi
	ja	L39
L52:
	movl	48(%esp), %edx
	movl	56(%esp), %esi
	addl	%edi, %edx
	incl	%esi
	movl	%edx, 32(%esp)
	subl	%edx, %esi
	leal	-1(%edi), %ecx
	movl	%edi, %ebp
	jmp	L40
	.p2align 4,,7
L35:
	movl	%ebx, %edx
	movl	44(%esp), %eax
	call	_Swap
	movl	_DataWidth, %eax
	movl	44(%esp), %edx
	movl	$1, %ebp
	negl	%eax
	addl	%eax, %edx
	movl	%edx, 44(%esp)
	jmp	L36
	.p2align 4,,7
L37:
	movl	$1, %ebp
	jmp	L36
	.p2align 4,,7
L41:
	movl	48(%esp), %eax
	incl	%eax
	movl	%eax, 48(%esp)
	movl	_DataWidth, %eax
	movl	%eax, %edx
	negl	%edx
	testw	%bp, %bp
	jne	L44
	movl	%ebx, 44(%esp)
	movl	$1, %ebp
	jmp	L43
	.p2align 4,,7
L42:
	movl	%ebx, %edx
	movl	44(%esp), %eax
	call	_Swap
	movl	_DataWidth, %eax
	movl	%eax, %edx
	movl	44(%esp), %ecx
	negl	%edx
	addl	%edx, %ecx
	movl	$1, %ebp
	movl	%ecx, 44(%esp)
	jmp	L43
	.p2align 4,,7
L44:
	movl	$1, %ebp
	jmp	L43
L46:
	movl	56(%esp), %edx
	movl	32(%esp), %eax
	movl	%ecx, 28(%esp)
	call	_QuickSort
	movl	28(%esp), %ecx
	movl	%ecx, 56(%esp)
	movl	56(%esp), %edx
	cmpl	%edx, 60(%esp)
	jb	L48
L16:
	addl	$76, %esp
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
L26:
	.cfi_restore_state
	movl	%edi, 4(%esp)
	movl	%esi, (%esp)
	call	*_Cmpr
	testl	%eax, %eax
	jg	L27
	movl	%esi, 4(%esp)
	movl	%ebx, (%esp)
	call	*_Cmpr
	testl	%eax, %eax
	jle	L50
L67:
	movl	%ebx, %edi
	jmp	L27
L68:
	movl	%ebx, 4(%esp)
	movl	%esi, (%esp)
	call	*_Cmpr
	testl	%eax, %eax
	jns	L67
L50:
	movl	%esi, %edi
	jmp	L27
L69:
	movl	56(%esp), %edx
	movl	56(%esp), %ebp
	incl	%edx
	xorl	%esi, %esi
	movl	%edx, 32(%esp)
	jmp	L40
	.cfi_endproc
LFE3:
	.p2align 4,,15
	.globl	_qsort
_qsort:
LFB0:
	.cfi_startproc
	movl	16(%esp), %eax
	movl	8(%esp), %edx
	movl	%eax, _Cmpr
	movl	12(%esp), %eax
	movl	%eax, _DataWidth
	movl	4(%esp), %eax
	movl	%eax, _MyBase
	movl	$1, %eax
	jmp	_QuickSort
	.cfi_endproc
LFE0:
.lcomm _Cmpr,4,4
.lcomm _DataWidth,4,4
.lcomm _MyBase,4,4
	.ident	"GCC: (GNU) 4.7.4"
