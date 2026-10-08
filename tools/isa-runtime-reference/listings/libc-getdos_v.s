	.file	"getdos_v.c"
	.section .text
LC0:
	.ascii "??Unknown??\0"
	.p2align 4,,15
	.globl	__get_dos_version
__get_dos_version:
LFB6:
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
	subl	$92, %esp
	.cfi_def_cfa_offset 112
	movl	___bss_count, %eax
	movl	112(%esp), %esi
	cmpl	%eax, _getdosv_count
	je	L2
	movl	%eax, _getdosv_count
	movw	$0, __osmajor
L3:
	leal	28(%esp), %ebp
	movl	$33, (%esp)
	movl	%ebp, 4(%esp)
	movw	$12288, 56(%esp)
	call	___dpmi_int
	xorl	%eax, %eax
	movb	57(%esp), %al
	movb	56(%esp), %dl
	movw	%ax, __osminor
	movl	$1, %edi
	testb	%dl, %dl
	jne	L34
L5:
	movl	_dos_flavors+4, %ecx
	movw	%di, __osmajor
	movb	45(%esp), %bl
	testl	%ecx, %ecx
	je	L6
	cmpb	%bl, _dos_flavors
	je	L7
	movl	$_dos_flavors, %edx
	jmp	L8
	.p2align 4,,7
L35:
	cmpb	%bl, (%edx)
	je	L7
L8:
	addl	$8, %edx
	movl	4(%edx), %ecx
	testl	%ecx, %ecx
	jne	L35
L6:
	movl	$LC0, __os_flavor
	testl	%esi, %esi
	jne	L36
L9:
	sall	$8, %edi
	addl	%edi, %eax
L30:
	addl	$92, %esp
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
L34:
	.cfi_restore_state
	andl	$255, %edx
	movl	%edx, %edi
	jmp	L5
	.p2align 4,,7
L7:
	movl	%ecx, __os_flavor
	testl	%esi, %esi
	je	L9
L36:
	movl	%ebp, 4(%esp)
	movl	$33, (%esp)
	movw	$13062, 56(%esp)
	movw	$0, 44(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L32
	cmpb	$-1, 56(%esp)
	je	L32
	movb	45(%esp), %dl
	cmpb	$99, %dl
	ja	L32
	movb	44(%esp), %al
	cmpb	$4, %al
	jbe	L32
	sall	$8, %eax
	andl	$255, %edx
	addl	%edx, %eax
	jmp	L30
	.p2align 4,,7
L2:
	movw	__osmajor, %ax
	testw	%ax, %ax
	je	L3
	testl	%esi, %esi
	jne	L3
	sall	$8, %eax
	addw	__osminor, %ax
	addl	$92, %esp
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
L32:
	.cfi_restore_state
	movw	__osmajor, %di
	movw	__osminor, %ax
	jmp	L9
	.cfi_endproc
LFE6:
	.section .data
	.p2align 2
_getdosv_count:
	.long	-1
	.section .text
LC1:
	.ascii "IBMPcDos\0"
LC2:
	.ascii "CompqDOS\0"
LC3:
	.ascii "MsoftDOS\0"
LC4:
	.ascii "AT&T DOS\0"
LC5:
	.ascii "ZenitDOS\0"
LC6:
	.ascii "HP DOS\0"
LC7:
	.ascii "GrBulDOS\0"
LC8:
	.ascii "PBellDOS\0"
LC9:
	.ascii "DEC DOS\0"
LC10:
	.ascii "OlivtDOS\0"
LC11:
	.ascii "TI DOS\0"
LC12:
	.ascii "Toshiba\0"
LC13:
	.ascii "NWin3Dev\0"
LC14:
	.ascii "MSWinDev\0"
LC15:
	.ascii "RxDOS\0"
LC16:
	.ascii "PTS-DOS\0"
LC17:
	.ascii "GenSoft\0"
LC18:
	.ascii "DR-DOS\0"
LC19:
	.ascii "NovelDOS\0"
LC20:
	.ascii "FreeDOS\0"
LC21:
	.ascii "MS-DOS\0"
	.section .data
	.p2align 4
_dos_flavors:
	.byte	0
	.space 3
	.long	LC1
	.byte	1
	.space 3
	.long	LC2
	.byte	2
	.space 3
	.long	LC3
	.byte	4
	.space 3
	.long	LC4
	.byte	5
	.space 3
	.long	LC5
	.byte	6
	.space 3
	.long	LC6
	.byte	7
	.space 3
	.long	LC7
	.byte	13
	.space 3
	.long	LC8
	.byte	22
	.space 3
	.long	LC9
	.byte	35
	.space 3
	.long	LC10
	.byte	40
	.space 3
	.long	LC11
	.byte	41
	.space 3
	.long	LC12
	.byte	51
	.space 3
	.long	LC13
	.byte	52
	.space 3
	.long	LC14
	.byte	53
	.space 3
	.long	LC14
	.byte	77
	.space 3
	.long	LC6
	.byte	94
	.space 3
	.long	LC15
	.byte	102
	.space 3
	.long	LC16
	.byte	-103
	.space 3
	.long	LC17
	.byte	-18
	.space 3
	.long	LC18
	.byte	-17
	.space 3
	.long	LC19
	.byte	-3
	.space 3
	.long	LC20
	.byte	-1
	.space 3
	.long	LC21
	.byte	0
	.space 3
	.long	0
	.ident	"GCC: (GNU) 4.7.4"
