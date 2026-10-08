	.file	"libgcc2.c"
	.section .text
Ltext0:
	.file 1 "workspace\\quake\\out\\isa-classifier-worktree-20261007\\out\\libgcc-primary-source-20261008\\libgcc\\libgcc2.c"
	.p2align 4
	.globl	___udivdi3
___udivdi3:
LVL0:
LFB2:
	.loc 1 1299 1 view -0
	.cfi_startproc
	.loc 1 1299 1 is_stmt 0 view LVU1
	pushl	%ebp
LCFI0:
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
LCFI1:
	.cfi_def_cfa_register 5
	.loc 1 1300 3 is_stmt 1 view LVU2
	.loc 1 1299 1 is_stmt 0 view LVU3
	pushl	%edi
LVL1:
	.loc 1 1299 1 view LVU4
	pushl	%esi
	pushl	%ebx
	subl	$28, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	.loc 1 1299 1 view LVU5
	movl	8(%ebp), %edi
	movl	20(%ebp), %eax
	movl	%edi, -28(%ebp)
	movl	12(%ebp), %esi
LVL2:
	.loc 1 1299 1 view LVU6
	movl	16(%ebp), %ebx
LVL3:
LBB5:
LBI5:
	.loc 1 995 1 is_stmt 1 view LVU7
LBB6:
	.loc 1 997 3 view LVU8
	.loc 1 998 3 view LVU9
	.loc 1 999 3 view LVU10
	.loc 1 1000 3 view LVU11
	.loc 1 1001 3 view LVU12
	.loc 1 1002 3 view LVU13
	.loc 1 1004 3 view LVU14
	.loc 1 1005 3 view LVU15
	.loc 1 1006 3 view LVU16
	.loc 1 1007 3 view LVU17
	.loc 1 1010 3 view LVU18
	.loc 1 1010 6 is_stmt 0 view LVU19
	testl	%eax, %eax
	jne	L2
	.loc 1 1012 7 is_stmt 1 view LVU20
	.loc 1 1012 10 is_stmt 0 view LVU21
	cmpl	%ebx, %esi
	jnb	L3
	.loc 1 1016 4 is_stmt 1 view LVU22
	movl	%edi, %eax
LVL4:
	.loc 1 1016 4 is_stmt 0 view LVU23
	xorl	%edi, %edi
	movl	%esi, %edx
/APP
# 1016 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %ebx
# 0 "" 2
LVL5:
	.loc 1 1017 4 is_stmt 1 view LVU24
	.loc 1 1203 3 view LVU25
	.loc 1 1204 3 view LVU26
	.loc 1 1204 3 is_stmt 0 view LVU27
/NO_APP
LBE6:
LBE5:
	.loc 1 1301 1 view LVU28
	movl	%edi, %edx
	addl	$28, %esp
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
LCFI2:
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
LVL6:
	.p2align 4,,7
	.p2align 3
L2:
LCFI3:
	.cfi_restore_state
LBB12:
LBB9:
	.loc 1 1120 7 is_stmt 1 view LVU29
	.loc 1 1120 10 is_stmt 0 view LVU30
	cmpl	%eax, %esi
	jnb	L20
	xorl	%edi, %edi
	xorl	%eax, %eax
LVL7:
L4:
	.loc 1 1203 3 is_stmt 1 view LVU31
	.loc 1 1204 3 view LVU32
	.loc 1 1204 3 is_stmt 0 view LVU33
LBE9:
LBE12:
	.loc 1 1301 1 view LVU34
	movl	%edi, %edx
	addl	$28, %esp
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
LCFI4:
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
LVL8:
	.p2align 4,,7
	.p2align 3
L20:
LCFI5:
	.cfi_restore_state
LBB13:
LBB10:
	.loc 1 1139 4 is_stmt 1 view LVU35
	bsrl	%eax, %edi
LVL9:
	.loc 1 1140 4 view LVU36
	.loc 1 1140 7 is_stmt 0 view LVU37
	xorl	$31, %edi
LVL10:
	.loc 1 1140 7 view LVU38
	jne	L6
	.loc 1 1150 8 is_stmt 1 view LVU39
	.loc 1 1150 11 is_stmt 0 view LVU40
	cmpl	%esi, %eax
	jb	L12
	xorl	%eax, %eax
LVL11:
	.loc 1 1150 11 view LVU41
	cmpl	%ebx, -28(%ebp)
	jb	L4
L12:
	.loc 1 1152 5 is_stmt 1 view LVU42
LVL12:
	.loc 1 1153 5 view LVU43
	.loc 1 1153 5 is_stmt 0 view LVU44
	movl	$1, %eax
	jmp	L4
LVL13:
	.p2align 4,,7
	.p2align 3
L3:
	.loc 1 1153 5 view LVU45
	movl	%ebx, %ecx
	.loc 1 1025 4 is_stmt 1 view LVU46
	.loc 1 1025 7 is_stmt 0 view LVU47
	testl	%ebx, %ebx
	jne	L5
LVL14:
	.loc 1 1026 6 is_stmt 1 view LVU48
	.loc 1 1026 9 is_stmt 0 view LVU49
	movl	$1, %eax
LVL15:
	.loc 1 1026 9 view LVU50
	xorl	%edx, %edx
	divl	%ebx
	movl	%eax, %ecx
LVL16:
L5:
	.loc 1 1028 4 is_stmt 1 view LVU51
	xorl	%edx, %edx
	movl	%esi, %eax
/APP
# 1028 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %ecx
# 0 "" 2
/NO_APP
	movl	%eax, %esi
LVL17:
	.loc 1 1029 4 view LVU52
	movl	-28(%ebp), %eax
LVL18:
	.loc 1 1203 17 is_stmt 0 view LVU53
	movl	%esi, %edi
	.loc 1 1029 4 view LVU54
/APP
# 1029 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %ecx
# 0 "" 2
LVL19:
	.loc 1 1203 3 is_stmt 1 view LVU55
	.loc 1 1204 3 view LVU56
	.loc 1 1204 3 is_stmt 0 view LVU57
/NO_APP
LBE10:
LBE13:
	.loc 1 1301 1 view LVU58
	movl	%edi, %edx
	addl	$28, %esp
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
LCFI6:
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
LVL20:
	.p2align 4,,7
	.p2align 3
L6:
LCFI7:
	.cfi_restore_state
LBB14:
LBB11:
LBB7:
	.loc 1 1169 8 is_stmt 1 view LVU59
	.loc 1 1172 8 view LVU60
	.loc 1 1174 17 is_stmt 0 view LVU61
	movl	%edi, %ecx
	.loc 1 1172 10 view LVU62
	movl	$32, %edx
	subl	%edi, %edx
LVL21:
	.loc 1 1174 8 is_stmt 1 view LVU63
	.loc 1 1175 8 view LVU64
	.loc 1 1176 8 view LVU65
	.loc 1 1174 17 is_stmt 0 view LVU66
	sall	%cl, %eax
LVL22:
	.loc 1 1174 17 view LVU67
	movl	%eax, -32(%ebp)
LVL23:
	.loc 1 1174 30 view LVU68
	movb	%dl, %cl
	movl	%ebx, %eax
	shrl	%cl, %eax
	movl	%eax, %ecx
	.loc 1 1174 11 view LVU69
	movl	-32(%ebp), %eax
	orl	%eax, %ecx
	.loc 1 1176 11 view LVU70
	movl	%esi, %eax
	.loc 1 1174 11 view LVU71
	movl	%ecx, -32(%ebp)
	.loc 1 1175 11 view LVU72
	movl	%edi, %ecx
	sall	%cl, %ebx
LVL24:
	.loc 1 1176 11 view LVU73
	movb	%dl, %cl
	.loc 1 1175 11 view LVU74
	movl	%ebx, -36(%ebp)
LVL25:
	.loc 1 1176 11 view LVU75
	shrl	%cl, %eax
LVL26:
	.loc 1 1177 8 is_stmt 1 view LVU76
	.loc 1 1177 17 is_stmt 0 view LVU77
	movl	%edi, %ecx
	.loc 1 1177 30 view LVU78
	movl	-28(%ebp), %ebx
	.loc 1 1177 17 view LVU79
	sall	%cl, %esi
LVL27:
	.loc 1 1177 30 view LVU80
	movb	%dl, %cl
	shrl	%cl, %ebx
	.loc 1 1177 11 view LVU81
	orl	%esi, %ebx
LVL28:
	.loc 1 1178 8 is_stmt 1 view LVU82
	.loc 1 1180 8 view LVU83
	movl	%eax, %esi
	movl	%esi, %edx
LVL29:
	.loc 1 1180 8 is_stmt 0 view LVU84
	movl	%ebx, %eax
LVL30:
	.loc 1 1180 8 view LVU85
/APP
# 1180 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl -32(%ebp)
# 0 "" 2
LVL31:
	.loc 1 1180 8 view LVU86
/NO_APP
	movl	%edx, %esi
LVL32:
	.loc 1 1180 8 view LVU87
	movl	%eax, %ebx
LVL33:
	.loc 1 1181 8 is_stmt 1 view LVU88
/APP
# 1181 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	mull -36(%ebp)
# 0 "" 2
LVL34:
	.loc 1 1183 8 view LVU89
	.loc 1 1183 11 is_stmt 0 view LVU90
/NO_APP
	movl	%edx, -32(%ebp)
	cmpl	%edx, %esi
	jb	L8
	.loc 1 1178 11 view LVU91
	movl	-28(%ebp), %edx
LVL35:
	.loc 1 1178 11 view LVU92
	movl	%edi, %ecx
LVL36:
	.loc 1 1178 11 view LVU93
	sall	%cl, %edx
	.loc 1 1183 20 view LVU94
	cmpl	%eax, %edx
	jnb	L13
	movl	-32(%ebp), %edx
	cmpl	%edx, %esi
	je	L8
L13:
	.loc 1 1183 20 view LVU95
LBE7:
	.loc 1 1203 17 view LVU96
	movl	%ebx, %eax
LVL37:
	.loc 1 1203 17 view LVU97
	xorl	%edi, %edi
LVL38:
	.loc 1 1203 17 view LVU98
	jmp	L4
LVL39:
	.p2align 4,,7
	.p2align 3
L8:
LBB8:
	.loc 1 1185 5 is_stmt 1 view LVU99
	.loc 1 1186 5 view LVU100
	.loc 1 1185 7 is_stmt 0 view LVU101
	leal	-1(%ebx), %eax
LVL40:
	.loc 1 1185 7 view LVU102
LBE8:
	.loc 1 1203 17 view LVU103
	xorl	%edi, %edi
LVL41:
	.loc 1 1203 17 view LVU104
	jmp	L4
LBE11:
LBE14:
	.cfi_endproc
LFE2:
Letext0:
	.file 2 "workspace\\quake\\out\\isa-classifier-worktree-20261007\\out\\libgcc-primary-source-20261008\\libgcc\\libgcc2.h"
	.section	.debug_info,""
Ldebug_info0:
	.long	0x560
	.word	0x2
	.long	Ldebug_abbrev0
	.byte	0x4
	.uleb128 0x1
	.ascii "GNU C17 12.2.0 -remap -march=pentium -mtune=pentium -g -O2 -fbuilding-libgcc -fno-stack-protector -fexceptions -fnon-call-exceptions -fno-omit-frame-pointer\0"
	.byte	0xc
	.ascii "workspace\\quake\\out\\isa-classifier-worktree-20261007\\out\\libgcc-primary-source-20261008\\libgcc\\libgcc2.c\0"
	.ascii "workspace\\quake\\out\\isa-classifier-worktree-20261007\0"
	.long	Ltext0
	.long	Letext0
	.long	Ldebug_line0
	.uleb128 0x2
	.byte	0x4
	.byte	0x5
	.ascii "int\0"
	.uleb128 0x3
	.byte	0x4
	.byte	0x7
	.long	LASF0
	.uleb128 0x3
	.byte	0x2
	.byte	0x7
	.long	LASF1
	.uleb128 0x3
	.byte	0x8
	.byte	0x5
	.long	LASF2
	.uleb128 0x3
	.byte	0xc
	.byte	0x4
	.long	LASF3
	.uleb128 0x2
	.byte	0x10
	.byte	0x4
	.ascii "_Float128\0"
	.uleb128 0x2
	.byte	0x4
	.byte	0x4
	.ascii "float\0"
	.uleb128 0x2
	.byte	0x8
	.byte	0x4
	.ascii "double\0"
	.uleb128 0x2
	.byte	0x1
	.byte	0x6
	.ascii "char\0"
	.uleb128 0x3
	.byte	0x2
	.byte	0x5
	.long	LASF4
	.uleb128 0x2
	.byte	0x4
	.byte	0x5
	.ascii "int\0"
	.uleb128 0x3
	.byte	0x4
	.byte	0x5
	.long	LASF5
	.uleb128 0x3
	.byte	0x8
	.byte	0x5
	.long	LASF2
	.uleb128 0x3
	.byte	0x2
	.byte	0x7
	.long	LASF1
	.uleb128 0x3
	.byte	0x4
	.byte	0x7
	.long	LASF6
	.uleb128 0x3
	.byte	0x4
	.byte	0x7
	.long	LASF0
	.uleb128 0x3
	.byte	0x8
	.byte	0x7
	.long	LASF7
	.uleb128 0x2
	.byte	0x4
	.byte	0x4
	.ascii "float\0"
	.uleb128 0x2
	.byte	0x8
	.byte	0x4
	.ascii "double\0"
	.uleb128 0x3
	.byte	0xc
	.byte	0x4
	.long	LASF3
	.uleb128 0x3
	.byte	0x4
	.byte	0x5
	.long	LASF5
	.uleb128 0x2
	.byte	0x1
	.byte	0x8
	.ascii "unsigned char\0"
	.uleb128 0x3
	.byte	0x4
	.byte	0x7
	.long	LASF6
	.uleb128 0x2
	.byte	0x1
	.byte	0x6
	.ascii "signed char\0"
	.uleb128 0x3
	.byte	0x2
	.byte	0x5
	.long	LASF4
	.uleb128 0x4
	.ascii "SItype\0"
	.byte	0x2
	.byte	0x80
	.byte	0xf
	.long	0x16c
	.uleb128 0x4
	.ascii "USItype\0"
	.byte	0x2
	.byte	0x81
	.byte	0x16
	.long	0x221
	.uleb128 0x4
	.ascii "DItype\0"
	.byte	0x2
	.byte	0x84
	.byte	0xf
	.long	0x181
	.uleb128 0x4
	.ascii "UDItype\0"
	.byte	0x2
	.byte	0x85
	.byte	0x16
	.long	0x27c
	.uleb128 0x3
	.byte	0x8
	.byte	0x7
	.long	LASF7
	.uleb128 0x2
	.byte	0x8
	.byte	0x3
	.ascii "complex float\0"
	.uleb128 0x2
	.byte	0x10
	.byte	0x3
	.ascii "complex double\0"
	.uleb128 0x2
	.byte	0x18
	.byte	0x3
	.ascii "complex long double\0"
	.uleb128 0x2
	.byte	0x20
	.byte	0x3
	.ascii "complex _Float128\0"
	.uleb128 0x5
	.ascii "DWstruct\0"
	.byte	0x8
	.byte	0x2
	.word	0x1ed
	.byte	0xa
	.long	0x307
	.uleb128 0x6
	.ascii "low\0"
	.byte	0x2
	.word	0x1ed
	.byte	0x1a
	.long	0x23e
	.byte	0x2
	.byte	0x23
	.uleb128 0
	.uleb128 0x6
	.ascii "high\0"
	.byte	0x2
	.word	0x1ed
	.byte	0x1f
	.long	0x23e
	.byte	0x2
	.byte	0x23
	.uleb128 0x4
	.byte	0
	.uleb128 0x7
	.byte	0x8
	.byte	0x2
	.word	0x1f4
	.byte	0x9
	.long	0x329
	.uleb128 0x8
	.ascii "s\0"
	.byte	0x2
	.word	0x1f6
	.byte	0x13
	.long	0x2d2
	.uleb128 0x8
	.ascii "ll\0"
	.byte	0x2
	.word	0x1f7
	.byte	0xa
	.long	0x25d
	.byte	0
	.uleb128 0x9
	.ascii "DWunion\0"
	.byte	0x2
	.word	0x1f8
	.byte	0x3
	.long	0x307
	.uleb128 0xa
	.long	0x329
	.uleb128 0xb
	.byte	0x1
	.ascii "__udivdi3\0"
	.byte	0x1
	.word	0x512
	.byte	0x1
	.byte	0x1
	.long	0x26c
	.long	LFB2
	.long	LFE2
	.long	LLST0
	.byte	0x1
	.long	0x469
	.uleb128 0xc
	.ascii "n\0"
	.byte	0x1
	.word	0x512
	.byte	0x14
	.long	0x26c
	.long	LLST1
	.long	LVUS1
	.uleb128 0xc
	.ascii "d\0"
	.byte	0x1
	.word	0x512
	.byte	0x1f
	.long	0x26c
	.long	LLST2
	.long	LVUS2
	.uleb128 0xd
	.long	0x469
	.long	LBI5
	.byte	LVU7
	.long	Ldebug_ranges0+0
	.byte	0x1
	.word	0x514
	.byte	0xa
	.uleb128 0xe
	.long	0x49b
	.long	LLST3
	.long	LVUS3
	.uleb128 0xe
	.long	0x490
	.long	LLST4
	.long	LVUS4
	.uleb128 0xf
	.long	0x485
	.uleb128 0x10
	.long	Ldebug_ranges0+0
	.uleb128 0x11
	.long	0x4a7
	.uleb128 0x11
	.long	0x4b3
	.uleb128 0x11
	.long	0x4bf
	.uleb128 0x12
	.long	0x4cb
	.long	LLST5
	.long	LVUS5
	.uleb128 0x12
	.long	0x4d7
	.long	LLST6
	.long	LVUS6
	.uleb128 0x11
	.long	0x4e3
	.uleb128 0x12
	.long	0x4ef
	.long	LLST7
	.long	LVUS7
	.uleb128 0x12
	.long	0x4fb
	.long	LLST8
	.long	LVUS8
	.uleb128 0x12
	.long	0x507
	.long	LLST9
	.long	LVUS9
	.uleb128 0x12
	.long	0x513
	.long	LLST10
	.long	LVUS10
	.uleb128 0x12
	.long	0x51f
	.long	LLST11
	.long	LVUS11
	.uleb128 0x12
	.long	0x52a
	.long	LLST12
	.long	LVUS12
	.uleb128 0x11
	.long	0x536
	.uleb128 0x13
	.long	0x542
	.long	Ldebug_ranges0+0x28
	.uleb128 0x12
	.long	0x543
	.long	LLST13
	.long	LVUS13
	.uleb128 0x12
	.long	0x54f
	.long	LLST14
	.long	LVUS14
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.uleb128 0x14
	.ascii "__udivmoddi4\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x1
	.byte	0x1
	.long	0x26c
	.byte	0x3
	.long	0x55d
	.uleb128 0x15
	.ascii "n\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x17
	.long	0x26c
	.uleb128 0x15
	.ascii "d\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x22
	.long	0x26c
	.uleb128 0x15
	.ascii "rp\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x2e
	.long	0x55d
	.uleb128 0x16
	.ascii "nn\0"
	.byte	0x1
	.word	0x3e5
	.byte	0x11
	.long	0x33a
	.uleb128 0x16
	.ascii "dd\0"
	.byte	0x1
	.word	0x3e6
	.byte	0x11
	.long	0x33a
	.uleb128 0x16
	.ascii "rr\0"
	.byte	0x1
	.word	0x3e7
	.byte	0xb
	.long	0x329
	.uleb128 0x16
	.ascii "d0\0"
	.byte	0x1
	.word	0x3e8
	.byte	0xa
	.long	0x24d
	.uleb128 0x16
	.ascii "d1\0"
	.byte	0x1
	.word	0x3e8
	.byte	0xe
	.long	0x24d
	.uleb128 0x16
	.ascii "n0\0"
	.byte	0x1
	.word	0x3e8
	.byte	0x12
	.long	0x24d
	.uleb128 0x16
	.ascii "n1\0"
	.byte	0x1
	.word	0x3e8
	.byte	0x16
	.long	0x24d
	.uleb128 0x16
	.ascii "n2\0"
	.byte	0x1
	.word	0x3e8
	.byte	0x1a
	.long	0x24d
	.uleb128 0x16
	.ascii "q0\0"
	.byte	0x1
	.word	0x3e9
	.byte	0xa
	.long	0x24d
	.uleb128 0x16
	.ascii "q1\0"
	.byte	0x1
	.word	0x3e9
	.byte	0xe
	.long	0x24d
	.uleb128 0x16
	.ascii "b\0"
	.byte	0x1
	.word	0x3ea
	.byte	0xa
	.long	0x24d
	.uleb128 0x16
	.ascii "bm\0"
	.byte	0x1
	.word	0x3ea
	.byte	0xd
	.long	0x24d
	.uleb128 0x16
	.ascii "ww\0"
	.byte	0x1
	.word	0x4b3
	.byte	0x11
	.long	0x33a
	.uleb128 0x17
	.uleb128 0x16
	.ascii "m1\0"
	.byte	0x1
	.word	0x491
	.byte	0xf
	.long	0x24d
	.uleb128 0x16
	.ascii "m0\0"
	.byte	0x1
	.word	0x491
	.byte	0x13
	.long	0x24d
	.byte	0
	.byte	0
	.uleb128 0x18
	.byte	0x4
	.long	0x26c
	.byte	0
	.section	.debug_abbrev,""
Ldebug_abbrev0:
	.uleb128 0x1
	.uleb128 0x11
	.byte	0x1
	.uleb128 0x25
	.uleb128 0x8
	.uleb128 0x13
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x1b
	.uleb128 0x8
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x1
	.uleb128 0x10
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0x2
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0x8
	.byte	0
	.byte	0
	.uleb128 0x3
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0xe
	.byte	0
	.byte	0
	.uleb128 0x4
	.uleb128 0x16
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x5
	.uleb128 0x13
	.byte	0x1
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x6
	.uleb128 0xd
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x38
	.uleb128 0xa
	.byte	0
	.byte	0
	.uleb128 0x7
	.uleb128 0x17
	.byte	0x1
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x8
	.uleb128 0xd
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x9
	.uleb128 0x16
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0xa
	.uleb128 0x26
	.byte	0
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0xb
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0xc
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0xc
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x1
	.uleb128 0x40
	.uleb128 0x6
	.uleb128 0x2117
	.uleb128 0xc
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0xc
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x6
	.uleb128 0x2137
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0xd
	.uleb128 0x1d
	.byte	0x1
	.uleb128 0x31
	.uleb128 0x13
	.uleb128 0x52
	.uleb128 0x1
	.uleb128 0x2138
	.uleb128 0xb
	.uleb128 0x55
	.uleb128 0x6
	.uleb128 0x58
	.uleb128 0xb
	.uleb128 0x59
	.uleb128 0x5
	.uleb128 0x57
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0xe
	.uleb128 0x5
	.byte	0
	.uleb128 0x31
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x6
	.uleb128 0x2137
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0xf
	.uleb128 0x5
	.byte	0
	.uleb128 0x31
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x10
	.uleb128 0xb
	.byte	0x1
	.uleb128 0x55
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0x11
	.uleb128 0x34
	.byte	0
	.uleb128 0x31
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x12
	.uleb128 0x34
	.byte	0
	.uleb128 0x31
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x6
	.uleb128 0x2137
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0x13
	.uleb128 0xb
	.byte	0x1
	.uleb128 0x31
	.uleb128 0x13
	.uleb128 0x55
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0x14
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0xc
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x20
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x15
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x16
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x17
	.uleb128 0xb
	.byte	0x1
	.byte	0
	.byte	0
	.uleb128 0x18
	.uleb128 0xf
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.byte	0
	.section	.debug_loc,""
Ldebug_loc0:
LLST0:
	.long	LFB2-Ltext0
	.long	LCFI0-Ltext0
	.word	0x2
	.byte	0x74
	.sleb128 4
	.long	LCFI0-Ltext0
	.long	LCFI1-Ltext0
	.word	0x2
	.byte	0x74
	.sleb128 8
	.long	LCFI1-Ltext0
	.long	LCFI2-Ltext0
	.word	0x2
	.byte	0x75
	.sleb128 8
	.long	LCFI2-Ltext0
	.long	LCFI3-Ltext0
	.word	0x2
	.byte	0x74
	.sleb128 4
	.long	LCFI3-Ltext0
	.long	LCFI4-Ltext0
	.word	0x2
	.byte	0x75
	.sleb128 8
	.long	LCFI4-Ltext0
	.long	LCFI5-Ltext0
	.word	0x2
	.byte	0x74
	.sleb128 4
	.long	LCFI5-Ltext0
	.long	LCFI6-Ltext0
	.word	0x2
	.byte	0x75
	.sleb128 8
	.long	LCFI6-Ltext0
	.long	LCFI7-Ltext0
	.word	0x2
	.byte	0x74
	.sleb128 4
	.long	LCFI7-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x75
	.sleb128 8
	.long	0
	.long	0
LVUS1:
	.uleb128 0
	.uleb128 LVU4
LLST1:
	.long	LVL0-Ltext0
	.long	LVL1-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 0
	.long	0
	.long	0
LVUS2:
	.uleb128 0
	.uleb128 LVU4
LLST2:
	.long	LVL0-Ltext0
	.long	LVL1-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 8
	.long	0
	.long	0
LVUS3:
	.uleb128 LVU7
	.uleb128 LVU27
	.uleb128 LVU29
	.uleb128 LVU33
	.uleb128 LVU35
	.uleb128 LVU57
	.uleb128 LVU59
	.uleb128 0
LLST3:
	.long	LVL3-Ltext0
	.long	LVL5-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL6-Ltext0
	.long	LVL7-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL8-Ltext0
	.long	LVL19-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL20-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	0
	.long	0
LVUS4:
	.uleb128 LVU7
	.uleb128 LVU23
	.uleb128 LVU23
	.uleb128 LVU27
	.uleb128 LVU29
	.uleb128 LVU31
	.uleb128 LVU31
	.uleb128 LVU33
	.uleb128 LVU35
	.uleb128 LVU41
	.uleb128 LVU41
	.uleb128 LVU45
	.uleb128 LVU45
	.uleb128 LVU48
	.uleb128 LVU48
	.uleb128 LVU50
	.uleb128 LVU50
	.uleb128 LVU51
	.uleb128 LVU51
	.uleb128 LVU57
	.uleb128 LVU59
	.uleb128 LVU67
	.uleb128 LVU67
	.uleb128 LVU73
	.uleb128 LVU73
	.uleb128 0
LLST4:
	.long	LVL3-Ltext0
	.long	LVL4-Ltext0
	.word	0x6
	.byte	0x53
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL4-Ltext0
	.long	LVL5-Ltext0
	.word	0x7
	.byte	0x53
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL6-Ltext0
	.long	LVL7-Ltext0
	.word	0x6
	.byte	0x53
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL7-Ltext0
	.long	LVL7-Ltext0
	.word	0x8
	.byte	0x91
	.sleb128 8
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL8-Ltext0
	.long	LVL11-Ltext0
	.word	0x6
	.byte	0x53
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL11-Ltext0
	.long	LVL13-Ltext0
	.word	0x7
	.byte	0x53
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL13-Ltext0
	.long	LVL14-Ltext0
	.word	0x6
	.byte	0x53
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL14-Ltext0
	.long	LVL15-Ltext0
	.word	0x6
	.byte	0x51
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL15-Ltext0
	.long	LVL16-Ltext0
	.word	0x7
	.byte	0x51
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL16-Ltext0
	.long	LVL19-Ltext0
	.word	0x7
	.byte	0x53
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL20-Ltext0
	.long	LVL22-Ltext0
	.word	0x6
	.byte	0x53
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL22-Ltext0
	.long	LVL24-Ltext0
	.word	0x7
	.byte	0x53
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL24-Ltext0
	.long	LFE2-Ltext0
	.word	0x8
	.byte	0x91
	.sleb128 8
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	0
	.long	0
LVUS5:
	.uleb128 LVU15
	.uleb128 LVU27
	.uleb128 LVU29
	.uleb128 LVU31
	.uleb128 LVU35
	.uleb128 LVU48
	.uleb128 LVU48
	.uleb128 LVU57
	.uleb128 LVU59
	.uleb128 LVU65
	.uleb128 LVU65
	.uleb128 LVU75
LLST5:
	.long	LVL3-Ltext0
	.long	LVL5-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL6-Ltext0
	.long	LVL7-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL8-Ltext0
	.long	LVL14-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL14-Ltext0
	.long	LVL19-Ltext0
	.word	0x1
	.byte	0x51
	.long	LVL20-Ltext0
	.long	LVL21-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL21-Ltext0
	.long	LVL25-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -44
	.long	0
	.long	0
LVUS6:
	.uleb128 LVU16
	.uleb128 LVU23
	.uleb128 LVU23
	.uleb128 LVU27
	.uleb128 LVU29
	.uleb128 LVU31
	.uleb128 LVU35
	.uleb128 LVU41
	.uleb128 LVU41
	.uleb128 LVU45
	.uleb128 LVU45
	.uleb128 LVU50
	.uleb128 LVU50
	.uleb128 LVU57
	.uleb128 LVU59
	.uleb128 LVU64
	.uleb128 LVU64
	.uleb128 LVU68
LLST6:
	.long	LVL3-Ltext0
	.long	LVL4-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL4-Ltext0
	.long	LVL5-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 12
	.long	LVL6-Ltext0
	.long	LVL7-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL8-Ltext0
	.long	LVL11-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL11-Ltext0
	.long	LVL13-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 12
	.long	LVL13-Ltext0
	.long	LVL15-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL15-Ltext0
	.long	LVL19-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 12
	.long	LVL20-Ltext0
	.long	LVL21-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL21-Ltext0
	.long	LVL23-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	0
	.long	0
LVUS7:
	.uleb128 LVU18
	.uleb128 LVU25
	.uleb128 LVU29
	.uleb128 LVU31
	.uleb128 LVU35
	.uleb128 LVU44
	.uleb128 LVU45
	.uleb128 LVU52
	.uleb128 LVU52
	.uleb128 LVU55
	.uleb128 LVU59
	.uleb128 LVU80
	.uleb128 LVU80
	.uleb128 LVU82
	.uleb128 LVU82
	.uleb128 LVU88
	.uleb128 LVU88
	.uleb128 LVU89
	.uleb128 LVU89
	.uleb128 0
LLST7:
	.long	LVL3-Ltext0
	.long	LVL5-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL6-Ltext0
	.long	LVL7-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL8-Ltext0
	.long	LVL12-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL13-Ltext0
	.long	LVL17-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL17-Ltext0
	.long	LVL19-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL20-Ltext0
	.long	LVL27-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL27-Ltext0
	.long	LVL28-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 4
	.long	LVL28-Ltext0
	.long	LVL33-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL33-Ltext0
	.long	LVL34-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL34-Ltext0
	.long	LFE2-Ltext0
	.word	0x1
	.byte	0x56
	.long	0
	.long	0
LVUS8:
	.uleb128 LVU76
	.uleb128 LVU85
	.uleb128 LVU85
	.uleb128 LVU86
	.uleb128 LVU86
	.uleb128 LVU87
	.uleb128 LVU87
	.uleb128 LVU93
	.uleb128 LVU93
	.uleb128 LVU98
	.uleb128 LVU98
	.uleb128 LVU99
	.uleb128 LVU99
	.uleb128 LVU104
	.uleb128 LVU104
	.uleb128 0
LLST8:
	.long	LVL26-Ltext0
	.long	LVL30-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL30-Ltext0
	.long	LVL31-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL31-Ltext0
	.long	LVL32-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL32-Ltext0
	.long	LVL36-Ltext0
	.word	0xa
	.byte	0x91
	.sleb128 4
	.byte	0x6
	.byte	0x71
	.sleb128 0
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x9f
	.long	LVL36-Ltext0
	.long	LVL38-Ltext0
	.word	0xd
	.byte	0x91
	.sleb128 4
	.byte	0x6
	.byte	0x8
	.byte	0x20
	.byte	0x77
	.sleb128 0
	.byte	0x1c
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x9f
	.long	LVL38-Ltext0
	.long	LVL39-Ltext0
	.word	0x30
	.byte	0x91
	.sleb128 4
	.byte	0x6
	.byte	0x8
	.byte	0x20
	.byte	0x4f
	.byte	0x91
	.sleb128 12
	.byte	0x6
	.byte	0x12
	.byte	0x28
	.word	0x6
	.byte	0x13
	.byte	0x8
	.byte	0x20
	.byte	0x2f
	.word	0x14
	.byte	0x30
	.byte	0x16
	.byte	0x12
	.byte	0x40
	.byte	0x4b
	.byte	0x24
	.byte	0x1a
	.byte	0x28
	.word	0x9
	.byte	0x31
	.byte	0x24
	.byte	0x16
	.byte	0x23
	.uleb128 0x1
	.byte	0x16
	.byte	0x2f
	.word	0xffef
	.byte	0x13
	.byte	0x1c
	.byte	0x4f
	.byte	0x27
	.byte	0x1c
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x9f
	.long	LVL39-Ltext0
	.long	LVL41-Ltext0
	.word	0xd
	.byte	0x91
	.sleb128 4
	.byte	0x6
	.byte	0x8
	.byte	0x20
	.byte	0x77
	.sleb128 0
	.byte	0x1c
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x9f
	.long	LVL41-Ltext0
	.long	LFE2-Ltext0
	.word	0x30
	.byte	0x91
	.sleb128 4
	.byte	0x6
	.byte	0x8
	.byte	0x20
	.byte	0x4f
	.byte	0x91
	.sleb128 12
	.byte	0x6
	.byte	0x12
	.byte	0x28
	.word	0x6
	.byte	0x13
	.byte	0x8
	.byte	0x20
	.byte	0x2f
	.word	0x14
	.byte	0x30
	.byte	0x16
	.byte	0x12
	.byte	0x40
	.byte	0x4b
	.byte	0x24
	.byte	0x1a
	.byte	0x28
	.word	0x9
	.byte	0x31
	.byte	0x24
	.byte	0x16
	.byte	0x23
	.uleb128 0x1
	.byte	0x16
	.byte	0x2f
	.word	0xffef
	.byte	0x13
	.byte	0x1c
	.byte	0x4f
	.byte	0x27
	.byte	0x1c
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x9f
	.long	0
	.long	0
LVUS9:
	.uleb128 LVU24
	.uleb128 LVU25
	.uleb128 LVU43
	.uleb128 LVU45
	.uleb128 LVU88
	.uleb128 LVU89
	.uleb128 LVU89
	.uleb128 LVU100
	.uleb128 LVU100
	.uleb128 LVU102
	.uleb128 LVU102
	.uleb128 0
LLST9:
	.long	LVL5-Ltext0
	.long	LVL5-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL12-Ltext0
	.long	LVL13-Ltext0
	.word	0x2
	.byte	0x31
	.byte	0x9f
	.long	LVL33-Ltext0
	.long	LVL34-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL34-Ltext0
	.long	LVL39-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL39-Ltext0
	.long	LVL40-Ltext0
	.word	0x3
	.byte	0x73
	.sleb128 -1
	.byte	0x9f
	.long	LVL40-Ltext0
	.long	LFE2-Ltext0
	.word	0x1
	.byte	0x50
	.long	0
	.long	0
LVUS10:
	.uleb128 LVU52
	.uleb128 LVU53
	.uleb128 LVU53
	.uleb128 LVU55
LLST10:
	.long	LVL17-Ltext0
	.long	LVL18-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL18-Ltext0
	.long	LVL19-Ltext0
	.word	0x1
	.byte	0x56
	.long	0
	.long	0
LVUS11:
	.uleb128 LVU63
	.uleb128 LVU84
	.uleb128 LVU84
	.uleb128 LVU98
	.uleb128 LVU98
	.uleb128 LVU99
	.uleb128 LVU99
	.uleb128 LVU104
	.uleb128 LVU104
	.uleb128 0
LLST11:
	.long	LVL21-Ltext0
	.long	LVL29-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL29-Ltext0
	.long	LVL38-Ltext0
	.word	0x6
	.byte	0x8
	.byte	0x20
	.byte	0x77
	.sleb128 0
	.byte	0x1c
	.byte	0x9f
	.long	LVL38-Ltext0
	.long	LVL39-Ltext0
	.word	0x29
	.byte	0x8
	.byte	0x20
	.byte	0x4f
	.byte	0x91
	.sleb128 12
	.byte	0x6
	.byte	0x12
	.byte	0x28
	.word	0x6
	.byte	0x13
	.byte	0x8
	.byte	0x20
	.byte	0x2f
	.word	0x14
	.byte	0x30
	.byte	0x16
	.byte	0x12
	.byte	0x40
	.byte	0x4b
	.byte	0x24
	.byte	0x1a
	.byte	0x28
	.word	0x9
	.byte	0x31
	.byte	0x24
	.byte	0x16
	.byte	0x23
	.uleb128 0x1
	.byte	0x16
	.byte	0x2f
	.word	0xffef
	.byte	0x13
	.byte	0x1c
	.byte	0x4f
	.byte	0x27
	.byte	0x1c
	.byte	0x9f
	.long	LVL39-Ltext0
	.long	LVL41-Ltext0
	.word	0x6
	.byte	0x8
	.byte	0x20
	.byte	0x77
	.sleb128 0
	.byte	0x1c
	.byte	0x9f
	.long	LVL41-Ltext0
	.long	LFE2-Ltext0
	.word	0x29
	.byte	0x8
	.byte	0x20
	.byte	0x4f
	.byte	0x91
	.sleb128 12
	.byte	0x6
	.byte	0x12
	.byte	0x28
	.word	0x6
	.byte	0x13
	.byte	0x8
	.byte	0x20
	.byte	0x2f
	.word	0x14
	.byte	0x30
	.byte	0x16
	.byte	0x12
	.byte	0x40
	.byte	0x4b
	.byte	0x24
	.byte	0x1a
	.byte	0x28
	.word	0x9
	.byte	0x31
	.byte	0x24
	.byte	0x16
	.byte	0x23
	.uleb128 0x1
	.byte	0x16
	.byte	0x2f
	.word	0xffef
	.byte	0x13
	.byte	0x1c
	.byte	0x4f
	.byte	0x27
	.byte	0x1c
	.byte	0x9f
	.long	0
	.long	0
LVUS12:
	.uleb128 LVU36
	.uleb128 LVU38
	.uleb128 LVU38
	.uleb128 LVU45
	.uleb128 LVU59
	.uleb128 LVU98
	.uleb128 LVU98
	.uleb128 LVU99
	.uleb128 LVU99
	.uleb128 LVU104
	.uleb128 LVU104
	.uleb128 0
LLST12:
	.long	LVL9-Ltext0
	.long	LVL10-Ltext0
	.word	0x5
	.byte	0x77
	.sleb128 0
	.byte	0x4f
	.byte	0x27
	.byte	0x9f
	.long	LVL10-Ltext0
	.long	LVL13-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL20-Ltext0
	.long	LVL38-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL38-Ltext0
	.long	LVL39-Ltext0
	.word	0x26
	.byte	0x4f
	.byte	0x91
	.sleb128 12
	.byte	0x6
	.byte	0x12
	.byte	0x28
	.word	0x6
	.byte	0x13
	.byte	0x8
	.byte	0x20
	.byte	0x2f
	.word	0x14
	.byte	0x30
	.byte	0x16
	.byte	0x12
	.byte	0x40
	.byte	0x4b
	.byte	0x24
	.byte	0x1a
	.byte	0x28
	.word	0x9
	.byte	0x31
	.byte	0x24
	.byte	0x16
	.byte	0x23
	.uleb128 0x1
	.byte	0x16
	.byte	0x2f
	.word	0xffef
	.byte	0x13
	.byte	0x1c
	.byte	0x4f
	.byte	0x27
	.byte	0x9f
	.long	LVL39-Ltext0
	.long	LVL41-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL41-Ltext0
	.long	LFE2-Ltext0
	.word	0x26
	.byte	0x4f
	.byte	0x91
	.sleb128 12
	.byte	0x6
	.byte	0x12
	.byte	0x28
	.word	0x6
	.byte	0x13
	.byte	0x8
	.byte	0x20
	.byte	0x2f
	.word	0x14
	.byte	0x30
	.byte	0x16
	.byte	0x12
	.byte	0x40
	.byte	0x4b
	.byte	0x24
	.byte	0x1a
	.byte	0x28
	.word	0x9
	.byte	0x31
	.byte	0x24
	.byte	0x16
	.byte	0x23
	.uleb128 0x1
	.byte	0x16
	.byte	0x2f
	.word	0xffef
	.byte	0x13
	.byte	0x1c
	.byte	0x4f
	.byte	0x27
	.byte	0x9f
	.long	0
	.long	0
LVUS13:
	.uleb128 LVU89
	.uleb128 LVU92
	.uleb128 LVU92
	.uleb128 LVU99
	.uleb128 LVU99
	.uleb128 LVU101
LLST13:
	.long	LVL34-Ltext0
	.long	LVL35-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL35-Ltext0
	.long	LVL39-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	LVL39-Ltext0
	.long	LVL39-Ltext0
	.word	0x1
	.byte	0x52
	.long	0
	.long	0
LVUS14:
	.uleb128 LVU89
	.uleb128 LVU97
	.uleb128 LVU99
	.uleb128 LVU101
LLST14:
	.long	LVL34-Ltext0
	.long	LVL37-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL39-Ltext0
	.long	LVL39-Ltext0
	.word	0x1
	.byte	0x50
	.long	0
	.long	0
	.section	.debug_aranges,""
	.long	0x1c
	.word	0x2
	.long	Ldebug_info0
	.byte	0x4
	.byte	0
	.word	0
	.word	0
	.long	Ltext0
	.long	Letext0-Ltext0
	.long	0
	.long	0
	.section	.debug_ranges,""
Ldebug_ranges0:
	.long	LBB5-Ltext0
	.long	LBE5-Ltext0
	.long	LBB12-Ltext0
	.long	LBE12-Ltext0
	.long	LBB13-Ltext0
	.long	LBE13-Ltext0
	.long	LBB14-Ltext0
	.long	LBE14-Ltext0
	.long	0
	.long	0
	.long	LBB7-Ltext0
	.long	LBE7-Ltext0
	.long	LBB8-Ltext0
	.long	LBE8-Ltext0
	.long	0
	.long	0
	.section	.debug_line,""
Ldebug_line0:
	.section	.debug_str,""
LASF6:
	.ascii "unsigned int\0"
LASF3:
	.ascii "long double\0"
LASF0:
	.ascii "long unsigned int\0"
LASF1:
	.ascii "short unsigned int\0"
LASF4:
	.ascii "short int\0"
LASF7:
	.ascii "long long unsigned int\0"
LASF5:
	.ascii "long int\0"
LASF2:
	.ascii "long long int\0"
	.ident	"GCC: (GNU) 12.2.0"
