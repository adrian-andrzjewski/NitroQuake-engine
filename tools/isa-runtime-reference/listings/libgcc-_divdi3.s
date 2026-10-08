	.file	"libgcc2.c"
	.section .text
Ltext0:
	.file 1 "workspace\\quake\\out\\isa-classifier-worktree-20261007\\out\\libgcc-primary-source-20261008\\libgcc\\libgcc2.c"
	.p2align 4
	.globl	___divdi3
___divdi3:
LVL0:
LFB2:
	.loc 1 1212 1 view -0
	.cfi_startproc
	.loc 1 1212 1 is_stmt 0 view LVU1
	pushl	%ebp
LCFI0:
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
LCFI1:
	.cfi_def_cfa_register 5
	pushl	%edi
LVL1:
	.loc 1 1212 1 view LVU2
	pushl	%esi
	pushl	%ebx
	subl	$44, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	.loc 1 1213 9 view LVU3
	movl	$0, -28(%ebp)
	.loc 1 1212 1 view LVU4
	movl	12(%ebp), %ebx
	movl	8(%ebp), %ecx
	movl	%ecx, -40(%ebp)
	movl	%ebx, -36(%ebp)
	.loc 1 1213 3 is_stmt 1 view LVU5
LVL2:
	.loc 1 1214 3 view LVU6
	.loc 1 1215 3 view LVU7
	.loc 1 1216 3 view LVU8
	.loc 1 1218 3 view LVU9
	.loc 1 1212 1 is_stmt 0 view LVU10
	movl	16(%ebp), %eax
	movl	20(%ebp), %edx
	movl	%ebx, -32(%ebp)
	.loc 1 1218 6 view LVU11
	testl	%ebx, %ebx
	jns	L2
	.loc 1 1219 5 is_stmt 1 view LVU12
LVL3:
	.loc 1 1220 13 is_stmt 0 view LVU13
	negl	%ecx
LVL4:
	.loc 1 1220 13 view LVU14
	adcl	$0, %ebx
	movl	%ecx, -40(%ebp)
	negl	%ebx
	movl	%ebx, -36(%ebp)
	.loc 1 1220 13 view LVU15
	movl	%ebx, -32(%ebp)
	.loc 1 1219 7 view LVU16
	movl	$-1, -28(%ebp)
LVL5:
L2:
	.loc 1 1221 3 is_stmt 1 view LVU17
	movl	%edx, %ebx
	.loc 1 1221 6 is_stmt 0 view LVU18
	testl	%edx, %edx
	jns	L3
	.loc 1 1222 5 is_stmt 1 view LVU19
LVL6:
	.loc 1 1223 13 is_stmt 0 view LVU20
	negl	%eax
LVL7:
	.loc 1 1223 13 view LVU21
	adcl	$0, %edx
	.loc 1 1222 7 view LVU22
	notl	-28(%ebp)
LVL8:
	.loc 1 1223 13 view LVU23
	negl	%edx
	.loc 1 1223 13 view LVU24
	movl	%edx, %ebx
L3:
LVL9:
	.loc 1 1225 3 is_stmt 1 view LVU25
LBB5:
LBI5:
	.loc 1 995 1 view LVU26
LBB6:
	.loc 1 997 3 view LVU27
	.loc 1 998 3 view LVU28
	.loc 1 999 3 view LVU29
	.loc 1 1000 3 view LVU30
	.loc 1 1001 3 view LVU31
	.loc 1 1002 3 view LVU32
	.loc 1 1004 3 view LVU33
	.loc 1 1004 6 is_stmt 0 view LVU34
	movl	%eax, %edi
LVL10:
	.loc 1 1005 3 is_stmt 1 view LVU35
	.loc 1 1006 3 view LVU36
	.loc 1 1006 6 is_stmt 0 view LVU37
	movl	-40(%ebp), %esi
LVL11:
	.loc 1 1007 3 is_stmt 1 view LVU38
	.loc 1 1010 3 view LVU39
	.loc 1 1010 6 is_stmt 0 view LVU40
	testl	%ebx, %ebx
	jne	L4
	.loc 1 1012 7 is_stmt 1 view LVU41
	.loc 1 1012 10 is_stmt 0 view LVU42
	movl	-32(%ebp), %edx
	cmpl	%eax, %edx
	jnb	L5
	.loc 1 1016 4 is_stmt 1 view LVU43
	movl	%esi, %eax
	movl	$0, -40(%ebp)
/APP
# 1016 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %edi
# 0 "" 2
LVL12:
	.loc 1 1017 4 view LVU44
	.loc 1 1203 17 is_stmt 0 view LVU45
/NO_APP
	movl	%eax, %ecx
	jmp	L6
LVL13:
	.p2align 4,,7
	.p2align 3
L4:
	.loc 1 1120 7 is_stmt 1 view LVU46
	.loc 1 1120 10 is_stmt 0 view LVU47
	movl	-32(%ebp), %ecx
	cmpl	%ebx, %ecx
	jnb	L27
	movl	$0, -40(%ebp)
	xorl	%ecx, %ecx
LVL14:
L6:
	.loc 1 1203 3 is_stmt 1 view LVU48
	.loc 1 1204 3 view LVU49
	.loc 1 1204 12 is_stmt 0 view LVU50
	movl	%ecx, %eax
LBE6:
LBE5:
	.loc 1 1226 6 view LVU51
	movl	-28(%ebp), %ecx
LBB12:
LBB10:
	.loc 1 1204 12 view LVU52
	movl	-40(%ebp), %edx
LVL15:
	.loc 1 1204 12 view LVU53
LBE10:
LBE12:
	.loc 1 1226 3 is_stmt 1 view LVU54
	.loc 1 1226 6 is_stmt 0 view LVU55
	testl	%ecx, %ecx
	je	L1
	.loc 1 1227 5 is_stmt 1 view LVU56
	.loc 1 1227 7 is_stmt 0 view LVU57
	negl	%eax
LVL16:
	.loc 1 1227 7 view LVU58
	adcl	$0, %edx
	negl	%edx
LVL17:
	.loc 1 1229 3 is_stmt 1 view LVU59
L1:
	.loc 1 1230 1 is_stmt 0 view LVU60
	addl	$44, %esp
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
LVL18:
	.p2align 4,,7
	.p2align 3
L27:
LCFI3:
	.cfi_restore_state
LBB13:
LBB11:
	.loc 1 1139 4 is_stmt 1 view LVU61
	bsrl	%ebx, %eax
LVL19:
	.loc 1 1140 4 view LVU62
	.loc 1 1140 7 is_stmt 0 view LVU63
	xorl	$31, %eax
LVL20:
	.loc 1 1140 7 view LVU64
	movl	%eax, -40(%ebp)
	jne	L8
	.loc 1 1150 8 is_stmt 1 view LVU65
	.loc 1 1150 11 is_stmt 0 view LVU66
	cmpl	%ecx, %ebx
	jb	L16
	xorl	%ecx, %ecx
	cmpl	%edi, %esi
	jb	L6
L16:
	.loc 1 1152 5 is_stmt 1 view LVU67
LVL21:
	.loc 1 1153 5 view LVU68
	.loc 1 1153 5 is_stmt 0 view LVU69
	movl	$1, %ecx
	jmp	L6
LVL22:
	.p2align 4,,7
	.p2align 3
L5:
	.loc 1 1025 4 is_stmt 1 view LVU70
	.loc 1 1025 7 is_stmt 0 view LVU71
	testl	%eax, %eax
	jne	L7
	.loc 1 1026 6 is_stmt 1 view LVU72
	.loc 1 1026 9 is_stmt 0 view LVU73
	movl	$1, %eax
	xorl	%edx, %edx
LVL23:
	.loc 1 1026 9 view LVU74
	divl	%ebx
	movl	%eax, %edi
L7:
LVL24:
	.loc 1 1028 4 is_stmt 1 view LVU75
	movl	-32(%ebp), %ebx
LVL25:
	.loc 1 1028 4 is_stmt 0 view LVU76
	xorl	%edx, %edx
	movl	%ebx, %eax
/APP
# 1028 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %edi
# 0 "" 2
/NO_APP
	movl	%eax, %ebx
LVL26:
	.loc 1 1029 4 is_stmt 1 view LVU77
	movl	%esi, %eax
LVL27:
	.loc 1 1203 17 is_stmt 0 view LVU78
	movl	%ebx, -40(%ebp)
	.loc 1 1029 4 view LVU79
/APP
# 1029 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %edi
# 0 "" 2
LVL28:
	.loc 1 1029 4 view LVU80
/NO_APP
	movl	%eax, %ecx
LVL29:
	.loc 1 1029 4 view LVU81
	jmp	L6
LVL30:
	.p2align 4,,7
	.p2align 3
L8:
LBB7:
	.loc 1 1169 8 is_stmt 1 view LVU82
	.loc 1 1172 8 view LVU83
	.loc 1 1172 10 is_stmt 0 view LVU84
	movl	-40(%ebp), %edx
	movl	$32, %eax
LVL31:
	.loc 1 1172 10 view LVU85
	subl	%edx, %eax
LVL32:
	.loc 1 1174 8 is_stmt 1 view LVU86
	.loc 1 1175 8 view LVU87
	.loc 1 1176 8 view LVU88
	.loc 1 1174 17 is_stmt 0 view LVU89
	movb	%dl, %cl
	sall	%cl, %ebx
	.loc 1 1174 30 view LVU90
	movl	%edi, %edx
	movb	%al, %cl
	shrl	%cl, %edx
	.loc 1 1174 11 view LVU91
	movl	%edx, %ecx
	.loc 1 1175 11 view LVU92
	movl	-40(%ebp), %edx
	.loc 1 1174 11 view LVU93
	orl	%ebx, %ecx
	movl	%ecx, -44(%ebp)
LVL33:
	.loc 1 1175 11 view LVU94
	movb	%dl, %cl
	sall	%cl, %edi
	movl	%edi, -48(%ebp)
LVL34:
	.loc 1 1176 11 view LVU95
	movl	-32(%ebp), %edi
	movb	%al, %cl
	movl	%edi, %ebx
	shrl	%cl, %ebx
LVL35:
	.loc 1 1177 8 is_stmt 1 view LVU96
	.loc 1 1177 17 is_stmt 0 view LVU97
	movb	%dl, %cl
	sall	%cl, %edi
	movl	%edi, %edx
	.loc 1 1177 30 view LVU98
	movb	%al, %cl
	movl	%esi, %edi
	shrl	%cl, %edi
	movl	%edi, %eax
LVL36:
	.loc 1 1177 11 view LVU99
	orl	%edx, %eax
LVL37:
	.loc 1 1178 8 is_stmt 1 view LVU100
	.loc 1 1180 8 view LVU101
	movl	%ebx, %edx
/APP
# 1180 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl -44(%ebp)
# 0 "" 2
LVL38:
	.loc 1 1180 8 is_stmt 0 view LVU102
/NO_APP
	movl	%edx, %ebx
LVL39:
	.loc 1 1180 8 view LVU103
	movl	%eax, %edi
LVL40:
	.loc 1 1181 8 is_stmt 1 view LVU104
/APP
# 1181 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	mull -48(%ebp)
# 0 "" 2
LVL41:
	.loc 1 1183 8 view LVU105
	.loc 1 1183 11 is_stmt 0 view LVU106
/NO_APP
	cmpl	%edx, %ebx
	jb	L10
	.loc 1 1178 11 view LVU107
	movb	-40(%ebp), %cl
LVL42:
	.loc 1 1178 11 view LVU108
	sall	%cl, %esi
	.loc 1 1183 20 view LVU109
	cmpl	%eax, %esi
	jnb	L17
	cmpl	%edx, %ebx
	je	L10
L17:
LBE7:
	.loc 1 1203 17 view LVU110
	movl	%edi, %ecx
	movl	$0, -40(%ebp)
LVL43:
	.loc 1 1203 17 view LVU111
	jmp	L6
LVL44:
	.p2align 4,,7
	.p2align 3
L10:
LBB8:
	.loc 1 1185 5 is_stmt 1 view LVU112
	.loc 1 1186 5 view LVU113
	.loc 1 1185 7 is_stmt 0 view LVU114
	movl	%edi, %ecx
LBE8:
	.loc 1 1203 17 view LVU115
	movl	$0, -40(%ebp)
LVL45:
LBB9:
	.loc 1 1185 7 view LVU116
	decl	%ecx
LVL46:
	.loc 1 1185 7 view LVU117
	jmp	L6
LBE9:
LBE11:
LBE13:
	.cfi_endproc
LFE2:
Letext0:
	.file 2 "workspace\\quake\\out\\isa-classifier-worktree-20261007\\out\\libgcc-primary-source-20261008\\libgcc\\libgcc2.h"
	.section	.debug_info,""
Ldebug_info0:
	.long	0x5a5
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
	.byte	0x8
	.byte	0x7
	.long	LASF0
	.uleb128 0x3
	.byte	0x4
	.byte	0x5
	.ascii "int\0"
	.uleb128 0x2
	.byte	0x4
	.byte	0x7
	.long	LASF1
	.uleb128 0x2
	.byte	0x2
	.byte	0x7
	.long	LASF2
	.uleb128 0x2
	.byte	0x8
	.byte	0x5
	.long	LASF3
	.uleb128 0x2
	.byte	0xc
	.byte	0x4
	.long	LASF4
	.uleb128 0x3
	.byte	0x10
	.byte	0x4
	.ascii "_Float128\0"
	.uleb128 0x3
	.byte	0x4
	.byte	0x4
	.ascii "float\0"
	.uleb128 0x3
	.byte	0x8
	.byte	0x4
	.ascii "double\0"
	.uleb128 0x3
	.byte	0x1
	.byte	0x6
	.ascii "char\0"
	.uleb128 0x2
	.byte	0x2
	.byte	0x5
	.long	LASF5
	.uleb128 0x3
	.byte	0x4
	.byte	0x5
	.ascii "int\0"
	.uleb128 0x2
	.byte	0x4
	.byte	0x5
	.long	LASF6
	.uleb128 0x2
	.byte	0x8
	.byte	0x5
	.long	LASF3
	.uleb128 0x2
	.byte	0x2
	.byte	0x7
	.long	LASF2
	.uleb128 0x2
	.byte	0x4
	.byte	0x7
	.long	LASF7
	.uleb128 0x2
	.byte	0x4
	.byte	0x7
	.long	LASF1
	.uleb128 0x2
	.byte	0x8
	.byte	0x7
	.long	LASF0
	.uleb128 0x3
	.byte	0x4
	.byte	0x4
	.ascii "float\0"
	.uleb128 0x3
	.byte	0x8
	.byte	0x4
	.ascii "double\0"
	.uleb128 0x2
	.byte	0xc
	.byte	0x4
	.long	LASF4
	.uleb128 0x2
	.byte	0x4
	.byte	0x5
	.long	LASF6
	.uleb128 0x3
	.byte	0x1
	.byte	0x8
	.ascii "unsigned char\0"
	.uleb128 0x2
	.byte	0x4
	.byte	0x7
	.long	LASF7
	.uleb128 0x3
	.byte	0x1
	.byte	0x6
	.ascii "signed char\0"
	.uleb128 0x2
	.byte	0x2
	.byte	0x5
	.long	LASF5
	.uleb128 0x4
	.ascii "SItype\0"
	.byte	0x2
	.byte	0x80
	.byte	0xf
	.long	0x173
	.uleb128 0x4
	.ascii "USItype\0"
	.byte	0x2
	.byte	0x81
	.byte	0x16
	.long	0x228
	.uleb128 0x4
	.ascii "DItype\0"
	.byte	0x2
	.byte	0x84
	.byte	0xf
	.long	0x188
	.uleb128 0x4
	.ascii "UDItype\0"
	.byte	0x2
	.byte	0x85
	.byte	0x16
	.long	0x16c
	.uleb128 0x3
	.byte	0x8
	.byte	0x3
	.ascii "complex float\0"
	.uleb128 0x3
	.byte	0x10
	.byte	0x3
	.ascii "complex double\0"
	.uleb128 0x3
	.byte	0x18
	.byte	0x3
	.ascii "complex long double\0"
	.uleb128 0x3
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
	.long	0x245
	.byte	0x2
	.byte	0x23
	.uleb128 0
	.uleb128 0x6
	.ascii "high\0"
	.byte	0x2
	.word	0x1ed
	.byte	0x1f
	.long	0x245
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
	.long	0x264
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
	.ascii "__divdi3\0"
	.byte	0x1
	.word	0x4bb
	.byte	0x1
	.byte	0x1
	.long	0x264
	.long	LFB2
	.long	LFE2
	.long	LLST0
	.byte	0x1
	.long	0x4ae
	.uleb128 0xc
	.ascii "u\0"
	.byte	0x1
	.word	0x4bb
	.byte	0x12
	.long	0x264
	.long	LLST1
	.long	LVUS1
	.uleb128 0xc
	.ascii "v\0"
	.byte	0x1
	.word	0x4bb
	.byte	0x1c
	.long	0x264
	.long	LLST2
	.long	LVUS2
	.uleb128 0xd
	.ascii "c\0"
	.byte	0x1
	.word	0x4bd
	.byte	0x9
	.long	0x245
	.long	LLST3
	.long	LVUS3
	.uleb128 0xd
	.ascii "uu\0"
	.byte	0x1
	.word	0x4be
	.byte	0xb
	.long	0x329
	.long	LLST4
	.long	LVUS4
	.uleb128 0xd
	.ascii "vv\0"
	.byte	0x1
	.word	0x4bf
	.byte	0xb
	.long	0x329
	.long	LLST5
	.long	LVUS5
	.uleb128 0xd
	.ascii "w\0"
	.byte	0x1
	.word	0x4c0
	.byte	0xa
	.long	0x264
	.long	LLST6
	.long	LVUS6
	.uleb128 0xe
	.long	0x4ae
	.long	LBI5
	.byte	LVU26
	.long	Ldebug_ranges0+0
	.byte	0x1
	.word	0x4c9
	.byte	0x7
	.uleb128 0xf
	.long	0x4e0
	.long	LLST7
	.long	LVUS7
	.uleb128 0x10
	.long	0x4d5
	.uleb128 0x10
	.long	0x4ca
	.uleb128 0x11
	.long	Ldebug_ranges0+0
	.uleb128 0x12
	.long	0x4ec
	.uleb128 0x12
	.long	0x4f8
	.uleb128 0x12
	.long	0x504
	.uleb128 0x13
	.long	0x510
	.long	LLST8
	.long	LVUS8
	.uleb128 0x13
	.long	0x51c
	.long	LLST9
	.long	LVUS9
	.uleb128 0x12
	.long	0x528
	.uleb128 0x13
	.long	0x534
	.long	LLST10
	.long	LVUS10
	.uleb128 0x13
	.long	0x540
	.long	LLST11
	.long	LVUS11
	.uleb128 0x13
	.long	0x54c
	.long	LLST12
	.long	LVUS12
	.uleb128 0x13
	.long	0x558
	.long	LLST13
	.long	LVUS13
	.uleb128 0x13
	.long	0x564
	.long	LLST14
	.long	LVUS14
	.uleb128 0x13
	.long	0x56f
	.long	LLST15
	.long	LVUS15
	.uleb128 0x12
	.long	0x57b
	.uleb128 0x14
	.long	0x587
	.long	Ldebug_ranges0+0x20
	.uleb128 0x13
	.long	0x588
	.long	LLST16
	.long	LVUS16
	.uleb128 0x13
	.long	0x594
	.long	LLST17
	.long	LVUS17
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.uleb128 0x15
	.ascii "__udivmoddi4\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x1
	.byte	0x1
	.long	0x273
	.byte	0x3
	.long	0x5a2
	.uleb128 0x16
	.ascii "n\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x17
	.long	0x273
	.uleb128 0x16
	.ascii "d\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x22
	.long	0x273
	.uleb128 0x16
	.ascii "rp\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x2e
	.long	0x5a2
	.uleb128 0x17
	.ascii "nn\0"
	.byte	0x1
	.word	0x3e5
	.byte	0x11
	.long	0x33a
	.uleb128 0x17
	.ascii "dd\0"
	.byte	0x1
	.word	0x3e6
	.byte	0x11
	.long	0x33a
	.uleb128 0x17
	.ascii "rr\0"
	.byte	0x1
	.word	0x3e7
	.byte	0xb
	.long	0x329
	.uleb128 0x17
	.ascii "d0\0"
	.byte	0x1
	.word	0x3e8
	.byte	0xa
	.long	0x254
	.uleb128 0x17
	.ascii "d1\0"
	.byte	0x1
	.word	0x3e8
	.byte	0xe
	.long	0x254
	.uleb128 0x17
	.ascii "n0\0"
	.byte	0x1
	.word	0x3e8
	.byte	0x12
	.long	0x254
	.uleb128 0x17
	.ascii "n1\0"
	.byte	0x1
	.word	0x3e8
	.byte	0x16
	.long	0x254
	.uleb128 0x17
	.ascii "n2\0"
	.byte	0x1
	.word	0x3e8
	.byte	0x1a
	.long	0x254
	.uleb128 0x17
	.ascii "q0\0"
	.byte	0x1
	.word	0x3e9
	.byte	0xa
	.long	0x254
	.uleb128 0x17
	.ascii "q1\0"
	.byte	0x1
	.word	0x3e9
	.byte	0xe
	.long	0x254
	.uleb128 0x17
	.ascii "b\0"
	.byte	0x1
	.word	0x3ea
	.byte	0xa
	.long	0x254
	.uleb128 0x17
	.ascii "bm\0"
	.byte	0x1
	.word	0x3ea
	.byte	0xd
	.long	0x254
	.uleb128 0x17
	.ascii "ww\0"
	.byte	0x1
	.word	0x4b3
	.byte	0x11
	.long	0x33a
	.uleb128 0x18
	.uleb128 0x17
	.ascii "m1\0"
	.byte	0x1
	.word	0x491
	.byte	0xf
	.long	0x254
	.uleb128 0x17
	.ascii "m0\0"
	.byte	0x1
	.word	0x491
	.byte	0x13
	.long	0x254
	.byte	0
	.byte	0
	.uleb128 0x19
	.byte	0x4
	.long	0x273
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
	.uleb128 0xe
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
	.uleb128 0x8
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
	.uleb128 0x2
	.uleb128 0x6
	.uleb128 0x2137
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0xe
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
	.uleb128 0xf
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
	.uleb128 0x10
	.uleb128 0x5
	.byte	0
	.uleb128 0x31
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x11
	.uleb128 0xb
	.byte	0x1
	.uleb128 0x55
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0x12
	.uleb128 0x34
	.byte	0
	.uleb128 0x31
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x13
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
	.uleb128 0x14
	.uleb128 0xb
	.byte	0x1
	.uleb128 0x31
	.uleb128 0x13
	.uleb128 0x55
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0x15
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
	.uleb128 0x16
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
	.uleb128 0x17
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
	.uleb128 0x18
	.uleb128 0xb
	.byte	0x1
	.byte	0
	.byte	0
	.uleb128 0x19
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
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x75
	.sleb128 8
	.long	0
	.long	0
LVUS1:
	.uleb128 0
	.uleb128 LVU2
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
	.uleb128 LVU2
LLST2:
	.long	LVL0-Ltext0
	.long	LVL1-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 8
	.long	0
	.long	0
LVUS3:
	.uleb128 LVU6
	.uleb128 LVU13
	.uleb128 LVU13
	.uleb128 LVU17
	.uleb128 LVU17
	.uleb128 LVU23
	.uleb128 LVU25
	.uleb128 0
LLST3:
	.long	LVL2-Ltext0
	.long	LVL3-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL3-Ltext0
	.long	LVL5-Ltext0
	.word	0x3
	.byte	0x9
	.byte	0xff
	.byte	0x9f
	.long	LVL5-Ltext0
	.long	LVL8-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -36
	.long	LVL9-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -36
	.long	0
	.long	0
LVUS4:
	.uleb128 LVU13
	.uleb128 LVU14
LLST4:
	.long	LVL3-Ltext0
	.long	LVL4-Ltext0
	.word	0x8
	.byte	0xf5
	.uleb128 0x1
	.uleb128 0x16c
	.byte	0x1f
	.byte	0x9f
	.byte	0x93
	.uleb128 0x8
	.long	0
	.long	0
LVUS5:
	.uleb128 LVU8
	.uleb128 LVU20
	.uleb128 LVU20
	.uleb128 LVU21
LLST5:
	.long	LVL2-Ltext0
	.long	LVL6-Ltext0
	.word	0x4
	.byte	0x91
	.sleb128 8
	.byte	0x93
	.uleb128 0x8
	.long	LVL6-Ltext0
	.long	LVL7-Ltext0
	.word	0x8
	.byte	0xf5
	.uleb128 0
	.uleb128 0x16c
	.byte	0x1f
	.byte	0x9f
	.byte	0x93
	.uleb128 0x8
	.long	0
	.long	0
LVUS6:
	.uleb128 LVU53
	.uleb128 LVU58
	.uleb128 LVU59
	.uleb128 LVU61
LLST6:
	.long	LVL15-Ltext0
	.long	LVL16-Ltext0
	.word	0x6
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.byte	0x52
	.byte	0x93
	.uleb128 0x4
	.long	LVL17-Ltext0
	.long	LVL18-Ltext0
	.word	0x6
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.byte	0x52
	.byte	0x93
	.uleb128 0x4
	.long	0
	.long	0
LVUS7:
	.uleb128 LVU26
	.uleb128 LVU53
	.uleb128 LVU61
	.uleb128 0
LLST7:
	.long	LVL9-Ltext0
	.long	LVL15-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL18-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	0
	.long	0
LVUS8:
	.uleb128 LVU75
	.uleb128 LVU82
	.uleb128 LVU88
	.uleb128 LVU95
LLST8:
	.long	LVL24-Ltext0
	.long	LVL30-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL32-Ltext0
	.long	LVL34-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -56
	.long	0
	.long	0
LVUS9:
	.uleb128 LVU36
	.uleb128 LVU48
	.uleb128 LVU61
	.uleb128 LVU76
	.uleb128 LVU82
	.uleb128 LVU87
	.uleb128 LVU87
	.uleb128 LVU94
LLST9:
	.long	LVL10-Ltext0
	.long	LVL14-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL18-Ltext0
	.long	LVL25-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL30-Ltext0
	.long	LVL32-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL32-Ltext0
	.long	LVL33-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -52
	.long	0
	.long	0
LVUS10:
	.uleb128 LVU39
	.uleb128 LVU48
	.uleb128 LVU61
	.uleb128 LVU69
	.uleb128 LVU70
	.uleb128 LVU74
	.uleb128 LVU74
	.uleb128 LVU77
	.uleb128 LVU77
	.uleb128 LVU80
	.uleb128 LVU82
	.uleb128 LVU100
	.uleb128 LVU100
	.uleb128 LVU102
	.uleb128 LVU102
	.uleb128 LVU104
	.uleb128 LVU104
	.uleb128 LVU105
	.uleb128 LVU105
	.uleb128 0
LLST10:
	.long	LVL11-Ltext0
	.long	LVL14-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	LVL18-Ltext0
	.long	LVL21-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	LVL22-Ltext0
	.long	LVL23-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL23-Ltext0
	.long	LVL26-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	LVL26-Ltext0
	.long	LVL28-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL30-Ltext0
	.long	LVL37-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	LVL37-Ltext0
	.long	LVL38-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL38-Ltext0
	.long	LVL40-Ltext0
	.word	0xf
	.byte	0x91
	.sleb128 -40
	.byte	0x6
	.byte	0x91
	.sleb128 -48
	.byte	0x94
	.byte	0x1
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x24
	.byte	0x77
	.sleb128 0
	.byte	0x21
	.byte	0x9f
	.long	LVL40-Ltext0
	.long	LVL41-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL41-Ltext0
	.long	LFE2-Ltext0
	.word	0x1
	.byte	0x53
	.long	0
	.long	0
LVUS11:
	.uleb128 LVU96
	.uleb128 LVU103
	.uleb128 LVU103
	.uleb128 LVU108
	.uleb128 LVU108
	.uleb128 LVU111
	.uleb128 LVU112
	.uleb128 LVU116
LLST11:
	.long	LVL35-Ltext0
	.long	LVL39-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL39-Ltext0
	.long	LVL42-Ltext0
	.word	0xa
	.byte	0x91
	.sleb128 -40
	.byte	0x6
	.byte	0x71
	.sleb128 0
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x9f
	.long	LVL42-Ltext0
	.long	LVL43-Ltext0
	.word	0xf
	.byte	0x91
	.sleb128 -40
	.byte	0x6
	.byte	0x8
	.byte	0x20
	.byte	0x91
	.sleb128 -48
	.byte	0x94
	.byte	0x1
	.byte	0x1c
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x9f
	.long	LVL44-Ltext0
	.long	LVL45-Ltext0
	.word	0xf
	.byte	0x91
	.sleb128 -40
	.byte	0x6
	.byte	0x8
	.byte	0x20
	.byte	0x91
	.sleb128 -48
	.byte	0x94
	.byte	0x1
	.byte	0x1c
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x9f
	.long	0
	.long	0
LVUS12:
	.uleb128 LVU44
	.uleb128 LVU46
	.uleb128 LVU68
	.uleb128 LVU70
	.uleb128 LVU81
	.uleb128 LVU82
	.uleb128 LVU104
	.uleb128 LVU105
	.uleb128 LVU105
	.uleb128 LVU113
	.uleb128 LVU113
	.uleb128 LVU117
	.uleb128 LVU117
	.uleb128 0
LLST12:
	.long	LVL12-Ltext0
	.long	LVL13-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL21-Ltext0
	.long	LVL22-Ltext0
	.word	0x2
	.byte	0x31
	.byte	0x9f
	.long	LVL29-Ltext0
	.long	LVL30-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL40-Ltext0
	.long	LVL41-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL41-Ltext0
	.long	LVL44-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL44-Ltext0
	.long	LVL46-Ltext0
	.word	0x3
	.byte	0x77
	.sleb128 -1
	.byte	0x9f
	.long	LVL46-Ltext0
	.long	LFE2-Ltext0
	.word	0x1
	.byte	0x51
	.long	0
	.long	0
LVUS13:
	.uleb128 LVU45
	.uleb128 LVU46
	.uleb128 LVU77
	.uleb128 LVU78
	.uleb128 LVU78
	.uleb128 LVU82
LLST13:
	.long	LVL12-Ltext0
	.long	LVL13-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL26-Ltext0
	.long	LVL27-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL27-Ltext0
	.long	LVL30-Ltext0
	.word	0x1
	.byte	0x53
	.long	0
	.long	0
LVUS14:
	.uleb128 LVU86
	.uleb128 LVU99
	.uleb128 LVU99
	.uleb128 LVU111
	.uleb128 LVU112
	.uleb128 LVU116
LLST14:
	.long	LVL32-Ltext0
	.long	LVL36-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL36-Ltext0
	.long	LVL43-Ltext0
	.word	0x7
	.byte	0x8
	.byte	0x20
	.byte	0x91
	.sleb128 -48
	.byte	0x6
	.byte	0x1c
	.byte	0x9f
	.long	LVL44-Ltext0
	.long	LVL45-Ltext0
	.word	0x7
	.byte	0x8
	.byte	0x20
	.byte	0x91
	.sleb128 -48
	.byte	0x6
	.byte	0x1c
	.byte	0x9f
	.long	0
	.long	0
LVUS15:
	.uleb128 LVU62
	.uleb128 LVU64
	.uleb128 LVU64
	.uleb128 LVU70
	.uleb128 LVU82
	.uleb128 LVU85
	.uleb128 LVU85
	.uleb128 LVU111
	.uleb128 LVU112
	.uleb128 LVU116
LLST15:
	.long	LVL19-Ltext0
	.long	LVL20-Ltext0
	.word	0x5
	.byte	0x70
	.sleb128 0
	.byte	0x4f
	.byte	0x27
	.byte	0x9f
	.long	LVL20-Ltext0
	.long	LVL22-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL30-Ltext0
	.long	LVL31-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL31-Ltext0
	.long	LVL43-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -48
	.long	LVL44-Ltext0
	.long	LVL45-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -48
	.long	0
	.long	0
LVUS16:
	.uleb128 LVU105
	.uleb128 LVU114
LLST16:
	.long	LVL41-Ltext0
	.long	LVL44-Ltext0
	.word	0x1
	.byte	0x52
	.long	0
	.long	0
LVUS17:
	.uleb128 LVU105
	.uleb128 LVU114
LLST17:
	.long	LVL41-Ltext0
	.long	LVL44-Ltext0
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
	.long	0
	.long	0
	.long	LBB7-Ltext0
	.long	LBE7-Ltext0
	.long	LBB8-Ltext0
	.long	LBE8-Ltext0
	.long	LBB9-Ltext0
	.long	LBE9-Ltext0
	.long	0
	.long	0
	.section	.debug_line,""
Ldebug_line0:
	.section	.debug_str,""
LASF7:
	.ascii "unsigned int\0"
LASF4:
	.ascii "long double\0"
LASF1:
	.ascii "long unsigned int\0"
LASF2:
	.ascii "short unsigned int\0"
LASF5:
	.ascii "short int\0"
LASF0:
	.ascii "long long unsigned int\0"
LASF6:
	.ascii "long int\0"
LASF3:
	.ascii "long long int\0"
	.ident	"GCC: (GNU) 12.2.0"
