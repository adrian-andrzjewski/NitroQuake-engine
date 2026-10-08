	.file	"libgcc2.c"
	.section .text
Ltext0:
	.file 1 "workspace\\quake\\out\\isa-classifier-worktree-20261007\\out\\libgcc-primary-source-20261008\\libgcc\\libgcc2.c"
	.p2align 4
	.globl	___umoddi3
___umoddi3:
LVL0:
LFB2:
	.loc 1 1287 1 view -0
	.cfi_startproc
	.loc 1 1287 1 is_stmt 0 view LVU1
	pushl	%ebp
LCFI0:
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
LCFI1:
	.cfi_def_cfa_register 5
	pushl	%edi
LVL1:
	.loc 1 1287 1 view LVU2
	pushl	%esi
	pushl	%ebx
	subl	$44, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	.loc 1 1287 1 view LVU3
	movl	12(%ebp), %ebx
	movl	20(%ebp), %eax
	movl	8(%ebp), %esi
	.loc 1 1288 3 is_stmt 1 view LVU4
	.loc 1 1290 3 view LVU5
LVL2:
	.loc 1 1287 1 is_stmt 0 view LVU6
	movl	16(%ebp), %edi
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
	movl	%ebx, %edx
LVL4:
	.loc 1 1010 3 view LVU18
	.loc 1 1010 6 is_stmt 0 view LVU19
	testl	%eax, %eax
	jne	L2
	.loc 1 1012 7 is_stmt 1 view LVU20
	.loc 1 1012 10 is_stmt 0 view LVU21
	cmpl	%edi, %ebx
	jnb	L3
	.loc 1 1016 4 is_stmt 1 view LVU22
	movl	%esi, %eax
LVL5:
	.loc 1 1016 4 is_stmt 0 view LVU23
/APP
# 1016 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %edi
# 0 "" 2
LVL6:
	.loc 1 1017 4 is_stmt 1 view LVU24
/NO_APP
L4:
	.loc 1 1034 7 view LVU25
	.loc 1 1036 4 view LVU26
	.loc 1 1037 4 view LVU27
	.loc 1 1038 4 view LVU28
	.loc 1 1038 12 is_stmt 0 view LVU29
	movl	%edx, %eax
	xorl	%edx, %edx
LVL7:
	.loc 1 1203 3 is_stmt 1 view LVU30
	.loc 1 1204 3 view LVU31
	.loc 1 1204 3 is_stmt 0 view LVU32
LBE6:
LBE5:
	.loc 1 1292 3 is_stmt 1 view LVU33
	.loc 1 1293 1 is_stmt 0 view LVU34
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
LVL8:
	.p2align 4,,7
	.p2align 3
L2:
LCFI3:
	.cfi_restore_state
	.loc 1 1293 1 view LVU35
	movl	%esi, -32(%ebp)
LBB12:
LBB8:
	.loc 1 1120 7 is_stmt 1 view LVU36
	.loc 1 1120 10 is_stmt 0 view LVU37
	cmpl	%eax, %ebx
	jnb	L7
	.loc 1 1124 4 is_stmt 1 view LVU38
LVL9:
	.loc 1 1125 4 view LVU39
	.loc 1 1128 4 view LVU40
	.loc 1 1130 8 view LVU41
	.loc 1 1131 8 view LVU42
	.loc 1 1132 8 view LVU43
	.loc 1 1132 16 is_stmt 0 view LVU44
	movl	%esi, %eax
LVL10:
	.loc 1 1203 3 is_stmt 1 view LVU45
	.loc 1 1204 3 view LVU46
	.loc 1 1204 3 is_stmt 0 view LVU47
LBE8:
LBE12:
	.loc 1 1292 3 is_stmt 1 view LVU48
	.loc 1 1293 1 is_stmt 0 view LVU49
	addl	$44, %esp
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
LVL11:
	.p2align 4,,7
	.p2align 3
L7:
LCFI5:
	.cfi_restore_state
LBB13:
LBB9:
	.loc 1 1139 4 is_stmt 1 view LVU50
	bsrl	%eax, %ecx
LVL12:
	.loc 1 1140 4 view LVU51
	.loc 1 1140 7 is_stmt 0 view LVU52
	xorl	$31, %ecx
LVL13:
	.loc 1 1140 7 view LVU53
	movl	%ecx, -28(%ebp)
	jne	L8
	.loc 1 1150 8 is_stmt 1 view LVU54
	.loc 1 1150 11 is_stmt 0 view LVU55
	cmpl	%ebx, %eax
	jb	L13
	cmpl	%edi, %esi
	jnb	L13
LVL14:
L9:
	.loc 1 1158 8 is_stmt 1 view LVU56
	.loc 1 1160 8 view LVU57
	.loc 1 1162 5 view LVU58
	.loc 1 1163 5 view LVU59
	.loc 1 1164 5 view LVU60
	.loc 1 1164 13 is_stmt 0 view LVU61
	movl	-32(%ebp), %eax
LVL15:
	.loc 1 1203 3 is_stmt 1 view LVU62
	.loc 1 1204 3 view LVU63
	.loc 1 1204 3 is_stmt 0 view LVU64
LBE9:
LBE13:
	.loc 1 1292 3 is_stmt 1 view LVU65
	.loc 1 1293 1 is_stmt 0 view LVU66
	addl	$44, %esp
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
LVL16:
	.p2align 4,,7
	.p2align 3
L3:
LCFI7:
	.cfi_restore_state
	.loc 1 1293 1 view LVU67
	movl	%edi, %ecx
LBB14:
LBB10:
	.loc 1 1025 4 is_stmt 1 view LVU68
	.loc 1 1025 7 is_stmt 0 view LVU69
	testl	%edi, %edi
	jne	L5
LVL17:
	.loc 1 1026 6 is_stmt 1 view LVU70
	.loc 1 1026 9 is_stmt 0 view LVU71
	movl	$1, %eax
LVL18:
	.loc 1 1026 9 view LVU72
	xorl	%edx, %edx
LVL19:
	.loc 1 1026 9 view LVU73
	divl	%edi
	movl	%eax, %ecx
LVL20:
L5:
	.loc 1 1028 4 is_stmt 1 view LVU74
	movl	%ebx, %eax
	xorl	%edx, %edx
/APP
# 1028 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %ecx
# 0 "" 2
LVL21:
	.loc 1 1029 4 view LVU75
/NO_APP
	movl	%esi, %eax
/APP
# 1029 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %ecx
# 0 "" 2
LVL22:
	.loc 1 1029 4 is_stmt 0 view LVU76
/NO_APP
	jmp	L4
LVL23:
	.p2align 4,,7
	.p2align 3
L8:
LBB7:
	.loc 1 1169 8 is_stmt 1 view LVU77
	.loc 1 1172 8 view LVU78
	.loc 1 1172 10 is_stmt 0 view LVU79
	movl	-28(%ebp), %ecx
LVL24:
	.loc 1 1172 10 view LVU80
	movl	$32, %edx
LVL25:
	.loc 1 1172 10 view LVU81
	subl	%ecx, %edx
LVL26:
	.loc 1 1174 8 is_stmt 1 view LVU82
	.loc 1 1175 8 view LVU83
	.loc 1 1176 8 view LVU84
	.loc 1 1174 17 is_stmt 0 view LVU85
	sall	%cl, %eax
LVL27:
	.loc 1 1174 17 view LVU86
	movl	%eax, -36(%ebp)
LVL28:
	.loc 1 1174 30 view LVU87
	movb	%dl, %cl
	movl	%edi, %eax
	movl	%edx, -32(%ebp)
	shrl	%cl, %eax
	movl	%eax, %edx
LVL29:
	.loc 1 1174 11 view LVU88
	movl	-36(%ebp), %eax
	orl	%eax, %edx
	.loc 1 1175 11 view LVU89
	movb	-28(%ebp), %cl
	.loc 1 1176 11 view LVU90
	movl	-32(%ebp), %eax
	.loc 1 1174 11 view LVU91
	movl	%edx, -36(%ebp)
	.loc 1 1175 11 view LVU92
	sall	%cl, %edi
LVL30:
	.loc 1 1176 11 view LVU93
	movl	%ebx, %edx
	movb	%al, %cl
	shrl	%cl, %edx
LVL31:
	.loc 1 1177 8 is_stmt 1 view LVU94
	.loc 1 1177 17 is_stmt 0 view LVU95
	movb	-28(%ebp), %cl
	.loc 1 1175 11 view LVU96
	movl	%edi, -40(%ebp)
LVL32:
	.loc 1 1177 17 view LVU97
	sall	%cl, %ebx
LVL33:
	.loc 1 1177 30 view LVU98
	movl	%esi, %edi
	movb	%al, %cl
	shrl	%cl, %edi
	movl	%edi, %eax
	.loc 1 1178 11 view LVU99
	movb	-28(%ebp), %cl
	sall	%cl, %esi
	.loc 1 1177 11 view LVU100
	orl	%ebx, %eax
LVL34:
	.loc 1 1178 8 is_stmt 1 view LVU101
	.loc 1 1178 11 is_stmt 0 view LVU102
	movl	%esi, %edi
	.loc 1 1180 8 view LVU103
/APP
# 1180 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl -36(%ebp)
# 0 "" 2
LVL35:
	.loc 1 1180 8 view LVU104
/NO_APP
	movl	%edx, %ebx
LVL36:
	.loc 1 1178 11 view LVU105
	movl	%esi, -44(%ebp)
LVL37:
	.loc 1 1180 8 is_stmt 1 view LVU106
	.loc 1 1181 8 view LVU107
/APP
# 1181 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	mull -40(%ebp)
# 0 "" 2
LVL38:
	.loc 1 1181 8 is_stmt 0 view LVU108
/NO_APP
	movl	%eax, %esi
LVL39:
	.loc 1 1181 8 view LVU109
	movl	%edx, %ecx
LVL40:
	.loc 1 1183 8 is_stmt 1 view LVU110
	.loc 1 1183 11 is_stmt 0 view LVU111
	cmpl	%edx, %ebx
	jb	L11
	.loc 1 1183 20 view LVU112
	jne	L12
	cmpl	%eax, %edi
	jnb	L12
L11:
	.loc 1 1185 5 is_stmt 1 view LVU113
	.loc 1 1186 5 view LVU114
/APP
# 1186 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	subl -40(%ebp),%eax
	sbbl -36(%ebp),%edx
# 0 "" 2
LVL41:
	.loc 1 1186 5 is_stmt 0 view LVU115
/NO_APP
	movl	%edx, %ecx
LVL42:
	.loc 1 1186 5 view LVU116
	movl	%eax, %esi
LVL43:
L12:
	.loc 1 1189 8 is_stmt 1 view LVU117
	.loc 1 1192 8 view LVU118
	.loc 1 1194 5 view LVU119
	movl	-44(%ebp), %eax
	.loc 1 1195 32 is_stmt 0 view LVU120
	movl	-28(%ebp), %edi
LVL44:
	.loc 1 1194 5 view LVU121
/APP
# 1194 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	subl %esi,%eax
	sbbl %ecx,%ebx
# 0 "" 2
LVL45:
	.loc 1 1195 5 is_stmt 1 view LVU122
	.loc 1 1195 20 is_stmt 0 view LVU123
/NO_APP
	movb	-32(%ebp), %cl
LVL46:
	.loc 1 1195 20 view LVU124
	movl	%ebx, %edx
	sall	%cl, %edx
	.loc 1 1195 32 view LVU125
	movl	%edi, %ecx
	shrl	%cl, %eax
LVL47:
	.loc 1 1196 5 is_stmt 1 view LVU126
	.loc 1 1197 5 view LVU127
	.loc 1 1197 13 is_stmt 0 view LVU128
	shrl	%cl, %ebx
LVL48:
	.loc 1 1197 13 view LVU129
	orl	%edx, %eax
	movl	%ebx, %edx
LVL49:
	.loc 1 1197 13 view LVU130
LBE7:
	.loc 1 1203 3 is_stmt 1 view LVU131
	.loc 1 1204 3 view LVU132
	.loc 1 1204 3 is_stmt 0 view LVU133
LBE10:
LBE14:
	.loc 1 1292 3 is_stmt 1 view LVU134
	.loc 1 1293 1 is_stmt 0 view LVU135
	addl	$44, %esp
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
LCFI8:
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
LVL50:
	.p2align 4,,7
	.p2align 3
L13:
LCFI9:
	.cfi_restore_state
LBB15:
LBB11:
	.loc 1 1152 5 is_stmt 1 view LVU136
	.loc 1 1153 5 view LVU137
	movl	%ebx, %edx
LVL51:
	.loc 1 1153 5 is_stmt 0 view LVU138
/APP
# 1153 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	subl %edi,%esi
	sbbl %eax,%edx
# 0 "" 2
/NO_APP
	movl	%esi, -32(%ebp)
LVL52:
	.loc 1 1153 5 view LVU139
	jmp	L9
LBE11:
LBE15:
	.cfi_endproc
LFE2:
Letext0:
	.file 2 "workspace\\quake\\out\\isa-classifier-worktree-20261007\\out\\libgcc-primary-source-20261008\\libgcc\\libgcc2.h"
	.section	.debug_info,""
Ldebug_info0:
	.long	0x57f
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
	.ascii "__umoddi3\0"
	.byte	0x1
	.word	0x506
	.byte	0x1
	.byte	0x1
	.long	0x26c
	.long	LFB2
	.long	LFE2
	.long	LLST0
	.byte	0x1
	.long	0x488
	.uleb128 0xc
	.ascii "u\0"
	.byte	0x1
	.word	0x506
	.byte	0x14
	.long	0x26c
	.long	LLST1
	.long	LVUS1
	.uleb128 0xc
	.ascii "v\0"
	.byte	0x1
	.word	0x506
	.byte	0x1f
	.long	0x26c
	.long	LLST2
	.long	LVUS2
	.uleb128 0xd
	.ascii "w\0"
	.byte	0x1
	.word	0x508
	.byte	0xb
	.long	0x26c
	.long	LLST3
	.long	LVUS3
	.uleb128 0xe
	.long	0x488
	.long	LBI5
	.byte	LVU7
	.long	Ldebug_ranges0+0
	.byte	0x1
	.word	0x50a
	.byte	0xa
	.uleb128 0xf
	.long	0x4ba
	.long	LLST4
	.long	LVUS4
	.uleb128 0xf
	.long	0x4af
	.long	LLST5
	.long	LVUS5
	.uleb128 0x10
	.long	0x4a4
	.uleb128 0x11
	.long	Ldebug_ranges0+0
	.uleb128 0x12
	.long	0x4c6
	.uleb128 0x12
	.long	0x4d2
	.uleb128 0x12
	.long	0x4de
	.uleb128 0x13
	.long	0x4ea
	.long	LLST6
	.long	LVUS6
	.uleb128 0x13
	.long	0x4f6
	.long	LLST7
	.long	LVUS7
	.uleb128 0x13
	.long	0x502
	.long	LLST8
	.long	LVUS8
	.uleb128 0x13
	.long	0x50e
	.long	LLST9
	.long	LVUS9
	.uleb128 0x13
	.long	0x51a
	.long	LLST10
	.long	LVUS10
	.uleb128 0x13
	.long	0x526
	.long	LLST11
	.long	LVUS11
	.uleb128 0x13
	.long	0x532
	.long	LLST12
	.long	LVUS12
	.uleb128 0x13
	.long	0x53e
	.long	LLST13
	.long	LVUS13
	.uleb128 0x13
	.long	0x549
	.long	LLST14
	.long	LVUS14
	.uleb128 0x12
	.long	0x555
	.uleb128 0x14
	.long	0x561
	.long	LBB7
	.long	LBE7
	.uleb128 0x13
	.long	0x562
	.long	LLST15
	.long	LVUS15
	.uleb128 0x13
	.long	0x56e
	.long	LLST16
	.long	LVUS16
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
	.long	0x26c
	.byte	0x3
	.long	0x57c
	.uleb128 0x16
	.ascii "n\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x17
	.long	0x26c
	.uleb128 0x16
	.ascii "d\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x22
	.long	0x26c
	.uleb128 0x16
	.ascii "rp\0"
	.byte	0x1
	.word	0x3e3
	.byte	0x2e
	.long	0x57c
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
	.long	0x24d
	.uleb128 0x17
	.ascii "d1\0"
	.byte	0x1
	.word	0x3e8
	.byte	0xe
	.long	0x24d
	.uleb128 0x17
	.ascii "n0\0"
	.byte	0x1
	.word	0x3e8
	.byte	0x12
	.long	0x24d
	.uleb128 0x17
	.ascii "n1\0"
	.byte	0x1
	.word	0x3e8
	.byte	0x16
	.long	0x24d
	.uleb128 0x17
	.ascii "n2\0"
	.byte	0x1
	.word	0x3e8
	.byte	0x1a
	.long	0x24d
	.uleb128 0x17
	.ascii "q0\0"
	.byte	0x1
	.word	0x3e9
	.byte	0xa
	.long	0x24d
	.uleb128 0x17
	.ascii "q1\0"
	.byte	0x1
	.word	0x3e9
	.byte	0xe
	.long	0x24d
	.uleb128 0x17
	.ascii "b\0"
	.byte	0x1
	.word	0x3ea
	.byte	0xa
	.long	0x24d
	.uleb128 0x17
	.ascii "bm\0"
	.byte	0x1
	.word	0x3ea
	.byte	0xd
	.long	0x24d
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
	.long	0x24d
	.uleb128 0x17
	.ascii "m0\0"
	.byte	0x1
	.word	0x491
	.byte	0x13
	.long	0x24d
	.byte	0
	.byte	0
	.uleb128 0x19
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
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x1
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
	.long	LCFI8-Ltext0
	.word	0x2
	.byte	0x75
	.sleb128 8
	.long	LCFI8-Ltext0
	.long	LCFI9-Ltext0
	.word	0x2
	.byte	0x74
	.sleb128 4
	.long	LCFI9-Ltext0
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
	.uleb128 LVU30
	.uleb128 LVU34
	.uleb128 LVU45
	.uleb128 LVU49
	.uleb128 LVU62
	.uleb128 LVU66
	.uleb128 LVU130
	.uleb128 LVU135
LLST3:
	.long	LVL7-Ltext0
	.long	LVL7-Ltext0
	.word	0x6
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.byte	0x52
	.byte	0x93
	.uleb128 0x4
	.long	LVL10-Ltext0
	.long	LVL10-Ltext0
	.word	0x6
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.byte	0x52
	.byte	0x93
	.uleb128 0x4
	.long	LVL15-Ltext0
	.long	LVL15-Ltext0
	.word	0x6
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.byte	0x52
	.byte	0x93
	.uleb128 0x4
	.long	LVL49-Ltext0
	.long	LVL49-Ltext0
	.word	0x6
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.byte	0x52
	.byte	0x93
	.uleb128 0x4
	.long	0
	.long	0
LVUS4:
	.uleb128 LVU7
	.uleb128 LVU32
	.uleb128 LVU35
	.uleb128 LVU47
	.uleb128 LVU50
	.uleb128 LVU64
	.uleb128 LVU67
	.uleb128 LVU133
	.uleb128 LVU136
	.uleb128 0
LLST4:
	.long	LVL3-Ltext0
	.long	LVL7-Ltext0
	.word	0x6
	.byte	0xf2
	.long	Ldebug_info0+907
	.sleb128 0
	.long	LVL8-Ltext0
	.long	LVL10-Ltext0
	.word	0x6
	.byte	0xf2
	.long	Ldebug_info0+907
	.sleb128 0
	.long	LVL11-Ltext0
	.long	LVL15-Ltext0
	.word	0x6
	.byte	0xf2
	.long	Ldebug_info0+907
	.sleb128 0
	.long	LVL16-Ltext0
	.long	LVL49-Ltext0
	.word	0x6
	.byte	0xf2
	.long	Ldebug_info0+907
	.sleb128 0
	.long	LVL50-Ltext0
	.long	LFE2-Ltext0
	.word	0x6
	.byte	0xf2
	.long	Ldebug_info0+907
	.sleb128 0
	.long	0
	.long	0
LVUS5:
	.uleb128 LVU7
	.uleb128 LVU23
	.uleb128 LVU23
	.uleb128 LVU32
	.uleb128 LVU35
	.uleb128 LVU45
	.uleb128 LVU45
	.uleb128 LVU47
	.uleb128 LVU50
	.uleb128 LVU62
	.uleb128 LVU62
	.uleb128 LVU64
	.uleb128 LVU67
	.uleb128 LVU70
	.uleb128 LVU70
	.uleb128 LVU72
	.uleb128 LVU72
	.uleb128 LVU74
	.uleb128 LVU74
	.uleb128 LVU77
	.uleb128 LVU77
	.uleb128 LVU86
	.uleb128 LVU86
	.uleb128 LVU93
	.uleb128 LVU93
	.uleb128 LVU133
	.uleb128 LVU136
	.uleb128 0
LLST5:
	.long	LVL3-Ltext0
	.long	LVL5-Ltext0
	.word	0x6
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL5-Ltext0
	.long	LVL7-Ltext0
	.word	0x7
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL8-Ltext0
	.long	LVL10-Ltext0
	.word	0x6
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL10-Ltext0
	.long	LVL10-Ltext0
	.word	0x7
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL11-Ltext0
	.long	LVL15-Ltext0
	.word	0x6
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL15-Ltext0
	.long	LVL15-Ltext0
	.word	0x7
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL16-Ltext0
	.long	LVL17-Ltext0
	.word	0x6
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL17-Ltext0
	.long	LVL18-Ltext0
	.word	0x6
	.byte	0x51
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL18-Ltext0
	.long	LVL20-Ltext0
	.word	0x7
	.byte	0x51
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL20-Ltext0
	.long	LVL23-Ltext0
	.word	0x7
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL23-Ltext0
	.long	LVL27-Ltext0
	.word	0x6
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	LVL27-Ltext0
	.long	LVL30-Ltext0
	.word	0x7
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL30-Ltext0
	.long	LVL49-Ltext0
	.word	0x8
	.byte	0x91
	.sleb128 8
	.byte	0x93
	.uleb128 0x4
	.byte	0x91
	.sleb128 12
	.byte	0x93
	.uleb128 0x4
	.long	LVL50-Ltext0
	.long	LFE2-Ltext0
	.word	0x6
	.byte	0x57
	.byte	0x93
	.uleb128 0x4
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.long	0
	.long	0
LVUS6:
	.uleb128 LVU15
	.uleb128 LVU25
	.uleb128 LVU35
	.uleb128 LVU47
	.uleb128 LVU50
	.uleb128 LVU64
	.uleb128 LVU67
	.uleb128 LVU70
	.uleb128 LVU70
	.uleb128 LVU77
	.uleb128 LVU77
	.uleb128 LVU84
	.uleb128 LVU84
	.uleb128 LVU97
	.uleb128 LVU136
	.uleb128 0
LLST6:
	.long	LVL3-Ltext0
	.long	LVL6-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL8-Ltext0
	.long	LVL10-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL11-Ltext0
	.long	LVL15-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL16-Ltext0
	.long	LVL17-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL17-Ltext0
	.long	LVL23-Ltext0
	.word	0x1
	.byte	0x51
	.long	LVL23-Ltext0
	.long	LVL26-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL26-Ltext0
	.long	LVL32-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -48
	.long	LVL50-Ltext0
	.long	LFE2-Ltext0
	.word	0x1
	.byte	0x57
	.long	0
	.long	0
LVUS7:
	.uleb128 LVU16
	.uleb128 LVU23
	.uleb128 LVU23
	.uleb128 LVU32
	.uleb128 LVU35
	.uleb128 LVU45
	.uleb128 LVU45
	.uleb128 LVU47
	.uleb128 LVU50
	.uleb128 LVU62
	.uleb128 LVU62
	.uleb128 LVU64
	.uleb128 LVU67
	.uleb128 LVU72
	.uleb128 LVU72
	.uleb128 LVU77
	.uleb128 LVU77
	.uleb128 LVU83
	.uleb128 LVU83
	.uleb128 LVU87
	.uleb128 LVU136
	.uleb128 0
LLST7:
	.long	LVL3-Ltext0
	.long	LVL5-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL5-Ltext0
	.long	LVL7-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 12
	.long	LVL8-Ltext0
	.long	LVL10-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL10-Ltext0
	.long	LVL10-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 12
	.long	LVL11-Ltext0
	.long	LVL15-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL15-Ltext0
	.long	LVL15-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 12
	.long	LVL16-Ltext0
	.long	LVL18-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL18-Ltext0
	.long	LVL23-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 12
	.long	LVL23-Ltext0
	.long	LVL26-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL26-Ltext0
	.long	LVL28-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -44
	.long	LVL50-Ltext0
	.long	LFE2-Ltext0
	.word	0x1
	.byte	0x50
	.long	0
	.long	0
LVUS8:
	.uleb128 LVU24
	.uleb128 LVU30
	.uleb128 LVU30
	.uleb128 LVU32
	.uleb128 LVU76
	.uleb128 LVU77
	.uleb128 LVU106
	.uleb128 LVU109
	.uleb128 LVU109
	.uleb128 LVU121
	.uleb128 LVU121
	.uleb128 LVU122
	.uleb128 LVU122
	.uleb128 LVU126
LLST8:
	.long	LVL6-Ltext0
	.long	LVL7-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL7-Ltext0
	.long	LVL7-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL22-Ltext0
	.long	LVL23-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL37-Ltext0
	.long	LVL39-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL39-Ltext0
	.long	LVL44-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL44-Ltext0
	.long	LVL45-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -52
	.long	LVL45-Ltext0
	.long	LVL47-Ltext0
	.word	0x1
	.byte	0x50
	.long	0
	.long	0
LVUS9:
	.uleb128 LVU18
	.uleb128 LVU24
	.uleb128 LVU24
	.uleb128 LVU25
	.uleb128 LVU35
	.uleb128 LVU47
	.uleb128 LVU50
	.uleb128 LVU56
	.uleb128 LVU67
	.uleb128 LVU73
	.uleb128 LVU73
	.uleb128 LVU75
	.uleb128 LVU75
	.uleb128 LVU76
	.uleb128 LVU77
	.uleb128 LVU81
	.uleb128 LVU81
	.uleb128 LVU98
	.uleb128 LVU98
	.uleb128 LVU101
	.uleb128 LVU101
	.uleb128 LVU104
	.uleb128 LVU104
	.uleb128 LVU105
	.uleb128 LVU105
	.uleb128 LVU107
	.uleb128 LVU107
	.uleb128 LVU108
	.uleb128 LVU108
	.uleb128 LVU129
	.uleb128 LVU136
	.uleb128 LVU138
	.uleb128 LVU138
	.uleb128 LVU139
	.uleb128 LVU139
	.uleb128 0
LLST9:
	.long	LVL4-Ltext0
	.long	LVL6-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL6-Ltext0
	.long	LVL6-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL8-Ltext0
	.long	LVL10-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL11-Ltext0
	.long	LVL14-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL16-Ltext0
	.long	LVL19-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL19-Ltext0
	.long	LVL21-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL21-Ltext0
	.long	LVL22-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL23-Ltext0
	.long	LVL25-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL25-Ltext0
	.long	LVL33-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL33-Ltext0
	.long	LVL34-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 4
	.long	LVL34-Ltext0
	.long	LVL35-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL35-Ltext0
	.long	LVL36-Ltext0
	.word	0xf
	.byte	0x91
	.sleb128 0
	.byte	0x6
	.byte	0x91
	.sleb128 -40
	.byte	0x94
	.byte	0x1
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x73
	.sleb128 0
	.byte	0x21
	.byte	0x9f
	.long	LVL36-Ltext0
	.long	LVL37-Ltext0
	.word	0x16
	.byte	0x91
	.sleb128 0
	.byte	0x6
	.byte	0x91
	.sleb128 -40
	.byte	0x94
	.byte	0x1
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x91
	.sleb128 4
	.byte	0x6
	.byte	0x71
	.sleb128 0
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x24
	.byte	0x21
	.byte	0x9f
	.long	LVL37-Ltext0
	.long	LVL38-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL38-Ltext0
	.long	LVL48-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL50-Ltext0
	.long	LVL51-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL51-Ltext0
	.long	LVL52-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL52-Ltext0
	.long	LFE2-Ltext0
	.word	0x1
	.byte	0x52
	.long	0
	.long	0
LVUS10:
	.uleb128 LVU94
	.uleb128 LVU104
	.uleb128 LVU104
	.uleb128 LVU133
LLST10:
	.long	LVL31-Ltext0
	.long	LVL35-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL35-Ltext0
	.long	LVL49-Ltext0
	.word	0xc
	.byte	0x91
	.sleb128 4
	.byte	0x6
	.byte	0x91
	.sleb128 -40
	.byte	0x94
	.byte	0x1
	.byte	0x8
	.byte	0xff
	.byte	0x1a
	.byte	0x25
	.byte	0x9f
	.long	0
	.long	0
LVUS11:
	.uleb128 LVU39
	.uleb128 LVU45
	.uleb128 LVU107
	.uleb128 LVU108
	.uleb128 LVU137
	.uleb128 0
LLST11:
	.long	LVL9-Ltext0
	.long	LVL10-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL37-Ltext0
	.long	LVL38-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL50-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x31
	.byte	0x9f
	.long	0
	.long	0
LVUS12:
	.uleb128 LVU40
	.uleb128 LVU45
	.uleb128 LVU57
	.uleb128 LVU62
	.uleb128 LVU118
	.uleb128 LVU130
LLST12:
	.long	LVL9-Ltext0
	.long	LVL10-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL14-Ltext0
	.long	LVL15-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL43-Ltext0
	.long	LVL49-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	0
	.long	0
LVUS13:
	.uleb128 LVU82
	.uleb128 LVU88
	.uleb128 LVU88
	.uleb128 LVU133
LLST13:
	.long	LVL26-Ltext0
	.long	LVL29-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL29-Ltext0
	.long	LVL49-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	0
	.long	0
LVUS14:
	.uleb128 LVU51
	.uleb128 LVU53
	.uleb128 LVU53
	.uleb128 LVU64
	.uleb128 LVU77
	.uleb128 LVU80
	.uleb128 LVU80
	.uleb128 LVU133
	.uleb128 LVU136
	.uleb128 0
LLST14:
	.long	LVL12-Ltext0
	.long	LVL13-Ltext0
	.word	0x5
	.byte	0x71
	.sleb128 0
	.byte	0x4f
	.byte	0x27
	.byte	0x9f
	.long	LVL13-Ltext0
	.long	LVL15-Ltext0
	.word	0x1
	.byte	0x51
	.long	LVL23-Ltext0
	.long	LVL24-Ltext0
	.word	0x1
	.byte	0x51
	.long	LVL24-Ltext0
	.long	LVL49-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -36
	.long	LVL50-Ltext0
	.long	LFE2-Ltext0
	.word	0x1
	.byte	0x51
	.long	0
	.long	0
LVUS15:
	.uleb128 LVU110
	.uleb128 LVU115
	.uleb128 LVU115
	.uleb128 LVU116
	.uleb128 LVU117
	.uleb128 LVU124
LLST15:
	.long	LVL40-Ltext0
	.long	LVL41-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL41-Ltext0
	.long	LVL42-Ltext0
	.word	0x1
	.byte	0x51
	.long	LVL43-Ltext0
	.long	LVL46-Ltext0
	.word	0x1
	.byte	0x51
	.long	0
	.long	0
LVUS16:
	.uleb128 LVU110
	.uleb128 LVU115
	.uleb128 LVU115
	.uleb128 LVU133
LLST16:
	.long	LVL40-Ltext0
	.long	LVL41-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL41-Ltext0
	.long	LVL49-Ltext0
	.word	0x1
	.byte	0x56
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
	.long	LBB15-Ltext0
	.long	LBE15-Ltext0
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
