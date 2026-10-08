	.file	"libgcc2.c"
	.section .text
Ltext0:
	.file 1 "workspace\\quake\\out\\isa-classifier-worktree-20261007\\out\\libgcc-primary-source-20261008\\libgcc\\libgcc2.c"
	.p2align 4
	.globl	___moddi3
___moddi3:
LVL0:
LFB2:
	.loc 1 1236 1 view -0
	.cfi_startproc
	.loc 1 1236 1 is_stmt 0 view LVU1
	pushl	%ebp
LCFI0:
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
LCFI1:
	.cfi_def_cfa_register 5
	pushl	%edi
LVL1:
	.loc 1 1236 1 view LVU2
	pushl	%esi
	pushl	%ebx
	subl	$44, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	.loc 1 1237 9 view LVU3
	movl	$0, -36(%ebp)
	.loc 1 1236 1 view LVU4
	movl	12(%ebp), %edx
	movl	8(%ebp), %eax
	movl	%eax, -32(%ebp)
	movl	%edx, -28(%ebp)
	.loc 1 1237 3 is_stmt 1 view LVU5
LVL2:
	.loc 1 1238 3 view LVU6
	.loc 1 1239 3 view LVU7
	.loc 1 1240 3 view LVU8
	.loc 1 1242 3 view LVU9
	.loc 1 1236 1 is_stmt 0 view LVU10
	movl	16(%ebp), %ecx
	movl	20(%ebp), %ebx
	movl	%edx, %esi
	.loc 1 1242 6 view LVU11
	testl	%edx, %edx
	jns	L2
	.loc 1 1243 5 is_stmt 1 view LVU12
LVL3:
	.loc 1 1244 13 is_stmt 0 view LVU13
	negl	%eax
LVL4:
	.loc 1 1244 13 view LVU14
	adcl	$0, %edx
	movl	%eax, -32(%ebp)
	negl	%edx
	movl	%edx, -28(%ebp)
LVL5:
	.loc 1 1244 13 view LVU15
	movl	%edx, %esi
	.loc 1 1243 7 view LVU16
	movl	$-1, -36(%ebp)
LVL6:
L2:
	.loc 1 1245 3 is_stmt 1 view LVU17
	movl	%ebx, %edi
	.loc 1 1245 6 is_stmt 0 view LVU18
	testl	%ebx, %ebx
	jns	L3
	.loc 1 1246 5 is_stmt 1 view LVU19
LVL7:
	.loc 1 1246 13 is_stmt 0 view LVU20
	negl	%ecx
LVL8:
	.loc 1 1246 13 view LVU21
	adcl	$0, %ebx
	negl	%ebx
	.loc 1 1246 13 view LVU22
	movl	%ebx, %edi
L3:
	.loc 1 1248 3 is_stmt 1 view LVU23
LVL9:
LBB5:
LBI5:
	.loc 1 995 1 view LVU24
LBB6:
	.loc 1 997 3 view LVU25
	.loc 1 998 3 view LVU26
	.loc 1 999 3 view LVU27
	.loc 1 1000 3 view LVU28
	.loc 1 1001 3 view LVU29
	.loc 1 1002 3 view LVU30
	.loc 1 1004 3 view LVU31
	.loc 1 1006 6 is_stmt 0 view LVU32
	movl	-32(%ebp), %eax
	.loc 1 1004 6 view LVU33
	movl	%ecx, %ebx
LVL10:
	.loc 1 1005 3 is_stmt 1 view LVU34
	.loc 1 1006 3 view LVU35
	.loc 1 1006 6 is_stmt 0 view LVU36
	movl	%eax, -40(%ebp)
LVL11:
	.loc 1 1007 3 is_stmt 1 view LVU37
	.loc 1 1010 3 view LVU38
	.loc 1 1010 6 is_stmt 0 view LVU39
	testl	%edi, %edi
	jne	L4
	.loc 1 1012 7 is_stmt 1 view LVU40
	.loc 1 1012 10 is_stmt 0 view LVU41
	cmpl	%ecx, %esi
	jnb	L5
	.loc 1 1016 4 is_stmt 1 view LVU42
	movl	%esi, %edx
/APP
# 1016 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %ecx
# 0 "" 2
LVL12:
	.loc 1 1016 4 is_stmt 0 view LVU43
/NO_APP
	movl	%edx, %ecx
LVL13:
	.loc 1 1017 4 is_stmt 1 view LVU44
L6:
	.loc 1 1034 7 view LVU45
	.loc 1 1036 4 view LVU46
	.loc 1 1037 4 view LVU47
	.loc 1 1038 4 view LVU48
	.loc 1 1038 12 is_stmt 0 view LVU49
	movl	%ecx, %eax
	xorl	%edx, %edx
LVL14:
	.loc 1 1038 12 view LVU50
	jmp	L8
LVL15:
	.p2align 4,,7
	.p2align 3
L4:
	.loc 1 1038 12 view LVU51
	movl	-32(%ebp), %ecx
	.loc 1 1120 7 is_stmt 1 view LVU52
	.loc 1 1120 10 is_stmt 0 view LVU53
	cmpl	%edi, %esi
	jnb	L9
LVL16:
L11:
	.loc 1 1158 8 is_stmt 1 view LVU54
	.loc 1 1160 8 view LVU55
	.loc 1 1162 5 view LVU56
	.loc 1 1163 5 view LVU57
	.loc 1 1164 5 view LVU58
	.loc 1 1164 13 is_stmt 0 view LVU59
	movl	%ecx, %eax
	movl	%esi, %edx
LVL17:
L8:
	.loc 1 1203 3 is_stmt 1 view LVU60
	.loc 1 1204 3 view LVU61
	.loc 1 1204 3 is_stmt 0 view LVU62
LBE6:
LBE5:
	.loc 1 1249 3 is_stmt 1 view LVU63
	.loc 1 1249 6 is_stmt 0 view LVU64
	movl	-36(%ebp), %ecx
	testl	%ecx, %ecx
	je	L1
	.loc 1 1250 5 is_stmt 1 view LVU65
	.loc 1 1250 9 is_stmt 0 view LVU66
	negl	%eax
LVL18:
	.loc 1 1250 9 view LVU67
	adcl	$0, %edx
	negl	%edx
LVL19:
	.loc 1 1252 3 is_stmt 1 view LVU68
L1:
	.loc 1 1253 1 is_stmt 0 view LVU69
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
LVL20:
	.p2align 4,,7
	.p2align 3
L5:
LCFI3:
	.cfi_restore_state
LBB9:
LBB8:
	.loc 1 1025 4 is_stmt 1 view LVU70
	.loc 1 1025 7 is_stmt 0 view LVU71
	testl	%ecx, %ecx
	jne	L7
	.loc 1 1026 6 is_stmt 1 view LVU72
	.loc 1 1026 9 is_stmt 0 view LVU73
	movl	$1, %eax
LVL21:
	.loc 1 1026 9 view LVU74
	xorl	%edx, %edx
	divl	%edi
	movl	%eax, %ebx
L7:
LVL22:
	.loc 1 1028 4 is_stmt 1 view LVU75
	movl	%esi, %eax
	xorl	%edx, %edx
/APP
# 1028 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %ebx
# 0 "" 2
LVL23:
	.loc 1 1029 4 view LVU76
/NO_APP
	movl	-40(%ebp), %eax
/APP
# 1029 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl %ebx
# 0 "" 2
LVL24:
	.loc 1 1029 4 is_stmt 0 view LVU77
/NO_APP
	movl	%edx, %ecx
	jmp	L6
LVL25:
	.p2align 4,,7
	.p2align 3
L9:
	.loc 1 1139 4 is_stmt 1 view LVU78
	bsrl	%edi, %eax
LVL26:
	.loc 1 1140 4 view LVU79
	.loc 1 1140 7 is_stmt 0 view LVU80
	xorl	$31, %eax
LVL27:
	.loc 1 1140 7 view LVU81
	movl	%eax, -32(%ebp)
LVL28:
	.loc 1 1140 7 view LVU82
	jne	L10
	.loc 1 1150 8 is_stmt 1 view LVU83
	.loc 1 1150 11 is_stmt 0 view LVU84
	cmpl	%esi, %edi
	jb	L17
	cmpl	%ebx, -40(%ebp)
	jb	L11
L17:
	.loc 1 1152 5 is_stmt 1 view LVU85
LVL29:
	.loc 1 1153 5 view LVU86
	movl	-40(%ebp), %eax
LVL30:
	.loc 1 1153 5 is_stmt 0 view LVU87
/APP
# 1153 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	subl %ebx,%eax
	sbbl %edi,%esi
# 0 "" 2
LVL31:
	.loc 1 1153 5 view LVU88
/NO_APP
	movl	%eax, %ecx
LVL32:
	.loc 1 1153 5 view LVU89
	jmp	L11
LVL33:
	.p2align 4,,7
	.p2align 3
L10:
LBB7:
	.loc 1 1169 8 is_stmt 1 view LVU90
	.loc 1 1172 8 view LVU91
	.loc 1 1172 10 is_stmt 0 view LVU92
	movl	-32(%ebp), %eax
LVL34:
	.loc 1 1172 10 view LVU93
	movl	$32, %edx
	subl	%eax, %edx
	.loc 1 1174 17 view LVU94
	movb	%al, %cl
	sall	%cl, %edi
LVL35:
	.loc 1 1174 30 view LVU95
	movl	%ebx, %eax
	movb	%dl, %cl
	shrl	%cl, %eax
	.loc 1 1174 11 view LVU96
	orl	%eax, %edi
	.loc 1 1175 11 view LVU97
	movl	-32(%ebp), %eax
	movb	%al, %cl
	.loc 1 1174 11 view LVU98
	movl	%edi, -44(%ebp)
	.loc 1 1175 11 view LVU99
	sall	%cl, %ebx
	.loc 1 1176 11 view LVU100
	movl	%esi, %edi
	movb	%dl, %cl
	shrl	%cl, %edi
	.loc 1 1175 11 view LVU101
	movl	%ebx, -48(%ebp)
	.loc 1 1177 17 view LVU102
	movb	%al, %cl
	.loc 1 1176 11 view LVU103
	movl	%edx, %ebx
	.loc 1 1172 10 view LVU104
	movl	%edx, -52(%ebp)
LVL36:
	.loc 1 1174 8 is_stmt 1 view LVU105
	.loc 1 1175 8 view LVU106
	.loc 1 1176 8 view LVU107
	.loc 1 1176 11 is_stmt 0 view LVU108
	movl	%edi, %edx
LVL37:
	.loc 1 1177 8 is_stmt 1 view LVU109
	.loc 1 1177 30 is_stmt 0 view LVU110
	movl	-40(%ebp), %edi
	.loc 1 1177 17 view LVU111
	sall	%cl, %esi
LVL38:
	.loc 1 1177 30 view LVU112
	movl	%edi, %eax
	movb	%bl, %cl
	shrl	%cl, %eax
	.loc 1 1177 11 view LVU113
	orl	%esi, %eax
LVL39:
	.loc 1 1178 8 is_stmt 1 view LVU114
	.loc 1 1178 11 is_stmt 0 view LVU115
	movb	-32(%ebp), %cl
	movl	%edi, %esi
	sall	%cl, %esi
	.loc 1 1180 8 view LVU116
/APP
# 1180 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	divl -44(%ebp)
# 0 "" 2
LVL40:
	.loc 1 1180 8 view LVU117
/NO_APP
	movl	%edx, %ebx
LVL41:
	.loc 1 1178 11 view LVU118
	movl	%esi, %edi
	.loc 1 1181 8 view LVU119
/APP
# 1181 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	mull -48(%ebp)
# 0 "" 2
	.loc 1 1178 11 view LVU120
/NO_APP
	movl	%esi, -40(%ebp)
LVL42:
	.loc 1 1180 8 is_stmt 1 view LVU121
	.loc 1 1181 8 view LVU122
	movl	%eax, %ecx
	movl	%edx, %esi
LVL43:
	.loc 1 1183 8 view LVU123
	.loc 1 1183 11 is_stmt 0 view LVU124
	cmpl	%edx, %ebx
	jb	L13
	.loc 1 1183 20 view LVU125
	jne	L14
	cmpl	%eax, %edi
	jnb	L14
L13:
	.loc 1 1185 5 is_stmt 1 view LVU126
	.loc 1 1186 5 view LVU127
/APP
# 1186 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	subl -48(%ebp),%eax
	sbbl -44(%ebp),%edx
# 0 "" 2
LVL44:
	.loc 1 1186 5 is_stmt 0 view LVU128
/NO_APP
	movl	%edx, %esi
LVL45:
	.loc 1 1186 5 view LVU129
	movl	%eax, %ecx
LVL46:
L14:
	.loc 1 1189 8 is_stmt 1 view LVU130
	.loc 1 1192 8 view LVU131
	.loc 1 1194 5 view LVU132
	movl	-40(%ebp), %edx
	.loc 1 1195 32 is_stmt 0 view LVU133
	movl	-32(%ebp), %edi
LVL47:
	.loc 1 1194 5 view LVU134
/APP
# 1194 "workspace\quake\out\isa-classifier-worktree-20261007\out\libgcc-primary-source-20261008\libgcc\libgcc2.c" 1
	subl %ecx,%edx
	sbbl %esi,%ebx
# 0 "" 2
LVL48:
	.loc 1 1195 5 is_stmt 1 view LVU135
	.loc 1 1196 5 view LVU136
	.loc 1 1197 5 view LVU137
	.loc 1 1195 20 is_stmt 0 view LVU138
/NO_APP
	movb	-52(%ebp), %cl
LVL49:
	.loc 1 1195 20 view LVU139
	movl	%ebx, %esi
LVL50:
	.loc 1 1195 20 view LVU140
	sall	%cl, %esi
	.loc 1 1195 32 view LVU141
	movl	%edi, %ecx
	shrl	%cl, %edx
LVL51:
	.loc 1 1197 13 view LVU142
	orl	%edx, %esi
	shrl	%cl, %ebx
LVL52:
	.loc 1 1197 13 view LVU143
	movl	%esi, %eax
	movl	%ebx, %edx
LVL53:
	.loc 1 1197 13 view LVU144
	jmp	L8
LBE7:
LBE8:
LBE9:
	.cfi_endproc
LFE2:
Letext0:
	.file 2 "workspace\\quake\\out\\isa-classifier-worktree-20261007\\out\\libgcc-primary-source-20261008\\libgcc\\libgcc2.h"
	.section	.debug_info,""
Ldebug_info0:
	.long	0x5b9
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
	.ascii "__moddi3\0"
	.byte	0x1
	.word	0x4d3
	.byte	0x1
	.byte	0x1
	.long	0x264
	.long	LFB2
	.long	LFE2
	.long	LLST0
	.byte	0x1
	.long	0x4c2
	.uleb128 0xc
	.ascii "u\0"
	.byte	0x1
	.word	0x4d3
	.byte	0x12
	.long	0x264
	.long	LLST1
	.long	LVUS1
	.uleb128 0xc
	.ascii "v\0"
	.byte	0x1
	.word	0x4d3
	.byte	0x1c
	.long	0x264
	.long	LLST2
	.long	LVUS2
	.uleb128 0xd
	.ascii "c\0"
	.byte	0x1
	.word	0x4d5
	.byte	0x9
	.long	0x245
	.long	LLST3
	.long	LVUS3
	.uleb128 0xd
	.ascii "uu\0"
	.byte	0x1
	.word	0x4d6
	.byte	0xb
	.long	0x329
	.long	LLST4
	.long	LVUS4
	.uleb128 0xd
	.ascii "vv\0"
	.byte	0x1
	.word	0x4d7
	.byte	0xb
	.long	0x329
	.long	LLST5
	.long	LVUS5
	.uleb128 0xd
	.ascii "w\0"
	.byte	0x1
	.word	0x4d8
	.byte	0xa
	.long	0x264
	.long	LLST6
	.long	LVUS6
	.uleb128 0xe
	.long	0x4c2
	.long	LBI5
	.byte	LVU24
	.long	Ldebug_ranges0+0
	.byte	0x1
	.word	0x4e0
	.byte	0xa
	.uleb128 0xf
	.long	0x4f4
	.long	LLST7
	.long	LVUS7
	.uleb128 0x10
	.long	0x4e9
	.uleb128 0xf
	.long	0x4de
	.long	LLST8
	.long	LVUS8
	.uleb128 0x11
	.long	Ldebug_ranges0+0
	.uleb128 0x12
	.long	0x500
	.uleb128 0x12
	.long	0x50c
	.uleb128 0x12
	.long	0x518
	.uleb128 0x13
	.long	0x524
	.long	LLST9
	.long	LVUS9
	.uleb128 0x13
	.long	0x530
	.long	LLST10
	.long	LVUS10
	.uleb128 0x13
	.long	0x53c
	.long	LLST11
	.long	LVUS11
	.uleb128 0x13
	.long	0x548
	.long	LLST12
	.long	LVUS12
	.uleb128 0x13
	.long	0x554
	.long	LLST13
	.long	LVUS13
	.uleb128 0x13
	.long	0x560
	.long	LLST14
	.long	LVUS14
	.uleb128 0x13
	.long	0x56c
	.long	LLST15
	.long	LVUS15
	.uleb128 0x13
	.long	0x578
	.long	LLST16
	.long	LVUS16
	.uleb128 0x13
	.long	0x583
	.long	LLST17
	.long	LVUS17
	.uleb128 0x12
	.long	0x58f
	.uleb128 0x14
	.long	0x59b
	.long	LBB7
	.long	LBE7
	.uleb128 0x13
	.long	0x59c
	.long	LLST18
	.long	LVUS18
	.uleb128 0x13
	.long	0x5a8
	.long	LLST19
	.long	LVUS19
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
	.long	0x5b6
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
	.long	0x5b6
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
	.uleb128 0
LLST3:
	.long	LVL2-Ltext0
	.long	LVL3-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL3-Ltext0
	.long	LVL6-Ltext0
	.word	0x3
	.byte	0x9
	.byte	0xff
	.byte	0x9f
	.long	LVL6-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -44
	.long	0
	.long	0
LVUS4:
	.uleb128 LVU7
	.uleb128 LVU14
	.uleb128 LVU17
	.uleb128 LVU54
	.uleb128 LVU70
	.uleb128 LVU82
LLST4:
	.long	LVL2-Ltext0
	.long	LVL4-Ltext0
	.word	0x6
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.byte	0x52
	.byte	0x93
	.uleb128 0x4
	.long	LVL6-Ltext0
	.long	LVL16-Ltext0
	.word	0x4
	.byte	0x91
	.sleb128 -40
	.byte	0x93
	.uleb128 0x8
	.long	LVL20-Ltext0
	.long	LVL28-Ltext0
	.word	0x4
	.byte	0x91
	.sleb128 -40
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
	.long	LVL7-Ltext0
	.word	0x4
	.byte	0x91
	.sleb128 8
	.byte	0x93
	.uleb128 0x8
	.long	LVL7-Ltext0
	.long	LVL8-Ltext0
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
LVUS6:
	.uleb128 LVU50
	.uleb128 LVU51
	.uleb128 LVU60
	.uleb128 LVU67
	.uleb128 LVU68
	.uleb128 LVU69
	.uleb128 LVU144
	.uleb128 0
LLST6:
	.long	LVL14-Ltext0
	.long	LVL15-Ltext0
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
	.long	LVL19-Ltext0
	.long	LVL19-Ltext0
	.word	0x6
	.byte	0x50
	.byte	0x93
	.uleb128 0x4
	.byte	0x52
	.byte	0x93
	.uleb128 0x4
	.long	LVL53-Ltext0
	.long	LFE2-Ltext0
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
	.uleb128 LVU24
	.uleb128 LVU62
	.uleb128 LVU70
	.uleb128 0
LLST7:
	.long	LVL9-Ltext0
	.long	LVL17-Ltext0
	.word	0x6
	.byte	0xf2
	.long	Ldebug_info0+965
	.sleb128 0
	.long	LVL20-Ltext0
	.long	LFE2-Ltext0
	.word	0x6
	.byte	0xf2
	.long	Ldebug_info0+965
	.sleb128 0
	.long	0
	.long	0
LVUS8:
	.uleb128 LVU24
	.uleb128 LVU54
	.uleb128 LVU70
	.uleb128 LVU82
LLST8:
	.long	LVL9-Ltext0
	.long	LVL16-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	LVL20-Ltext0
	.long	LVL28-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	0
	.long	0
LVUS9:
	.uleb128 LVU75
	.uleb128 LVU78
	.uleb128 LVU107
	.uleb128 0
LLST9:
	.long	LVL22-Ltext0
	.long	LVL25-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL36-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -56
	.long	0
	.long	0
LVUS10:
	.uleb128 LVU35
	.uleb128 LVU60
	.uleb128 LVU70
	.uleb128 LVU95
	.uleb128 LVU106
	.uleb128 0
LLST10:
	.long	LVL10-Ltext0
	.long	LVL17-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL20-Ltext0
	.long	LVL35-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL36-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -52
	.long	0
	.long	0
LVUS11:
	.uleb128 LVU37
	.uleb128 LVU43
	.uleb128 LVU43
	.uleb128 LVU44
	.uleb128 LVU44
	.uleb128 LVU45
	.uleb128 LVU45
	.uleb128 LVU51
	.uleb128 LVU51
	.uleb128 LVU54
	.uleb128 LVU70
	.uleb128 LVU74
	.uleb128 LVU74
	.uleb128 LVU77
	.uleb128 LVU77
	.uleb128 LVU78
	.uleb128 LVU78
	.uleb128 LVU79
	.uleb128 LVU79
	.uleb128 LVU82
	.uleb128 LVU82
	.uleb128 LVU89
	.uleb128 LVU89
	.uleb128 LVU90
	.uleb128 LVU90
	.uleb128 LVU121
	.uleb128 LVU121
	.uleb128 LVU123
	.uleb128 LVU123
	.uleb128 LVU134
	.uleb128 LVU134
	.uleb128 LVU135
	.uleb128 LVU135
	.uleb128 LVU142
LLST11:
	.long	LVL11-Ltext0
	.long	LVL12-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL12-Ltext0
	.long	LVL13-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	LVL13-Ltext0
	.long	LVL13-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL13-Ltext0
	.long	LVL15-Ltext0
	.word	0x1
	.byte	0x51
	.long	LVL15-Ltext0
	.long	LVL16-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL20-Ltext0
	.long	LVL21-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL21-Ltext0
	.long	LVL24-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	LVL24-Ltext0
	.long	LVL25-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL25-Ltext0
	.long	LVL26-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL26-Ltext0
	.long	LVL28-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	LVL28-Ltext0
	.long	LVL32-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -48
	.long	LVL32-Ltext0
	.long	LVL33-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL33-Ltext0
	.long	LVL42-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -48
	.long	LVL42-Ltext0
	.long	LVL43-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL43-Ltext0
	.long	LVL47-Ltext0
	.word	0x1
	.byte	0x57
	.long	LVL47-Ltext0
	.long	LVL48-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -48
	.long	LVL48-Ltext0
	.long	LVL51-Ltext0
	.word	0x1
	.byte	0x52
	.long	0
	.long	0
LVUS12:
	.uleb128 LVU38
	.uleb128 LVU45
	.uleb128 LVU51
	.uleb128 LVU54
	.uleb128 LVU70
	.uleb128 LVU76
	.uleb128 LVU76
	.uleb128 LVU77
	.uleb128 LVU78
	.uleb128 LVU88
	.uleb128 LVU89
	.uleb128 LVU112
	.uleb128 LVU114
	.uleb128 LVU117
	.uleb128 LVU122
	.uleb128 LVU143
LLST12:
	.long	LVL11-Ltext0
	.long	LVL13-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL15-Ltext0
	.long	LVL16-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL20-Ltext0
	.long	LVL23-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL23-Ltext0
	.long	LVL24-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL25-Ltext0
	.long	LVL31-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL32-Ltext0
	.long	LVL38-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL39-Ltext0
	.long	LVL40-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL42-Ltext0
	.long	LVL52-Ltext0
	.word	0x1
	.byte	0x53
	.long	0
	.long	0
LVUS13:
	.uleb128 LVU109
	.uleb128 LVU117
LLST13:
	.long	LVL37-Ltext0
	.long	LVL40-Ltext0
	.word	0x1
	.byte	0x52
	.long	0
	.long	0
LVUS14:
	.uleb128 LVU86
	.uleb128 LVU90
LLST14:
	.long	LVL29-Ltext0
	.long	LVL33-Ltext0
	.word	0x2
	.byte	0x31
	.byte	0x9f
	.long	0
	.long	0
LVUS15:
	.uleb128 LVU55
	.uleb128 LVU60
	.uleb128 LVU131
	.uleb128 0
LLST15:
	.long	LVL16-Ltext0
	.long	LVL17-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	LVL46-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x30
	.byte	0x9f
	.long	0
	.long	0
LVUS16:
	.uleb128 LVU105
	.uleb128 LVU109
	.uleb128 LVU109
	.uleb128 LVU118
	.uleb128 LVU118
	.uleb128 0
LLST16:
	.long	LVL36-Ltext0
	.long	LVL37-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL37-Ltext0
	.long	LVL41-Ltext0
	.word	0x1
	.byte	0x53
	.long	LVL41-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -60
	.long	0
	.long	0
LVUS17:
	.uleb128 LVU79
	.uleb128 LVU81
	.uleb128 LVU81
	.uleb128 LVU87
	.uleb128 LVU87
	.uleb128 LVU90
	.uleb128 LVU90
	.uleb128 LVU93
	.uleb128 LVU93
	.uleb128 0
LLST17:
	.long	LVL26-Ltext0
	.long	LVL27-Ltext0
	.word	0x5
	.byte	0x70
	.sleb128 0
	.byte	0x4f
	.byte	0x27
	.byte	0x9f
	.long	LVL27-Ltext0
	.long	LVL30-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL30-Ltext0
	.long	LVL33-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	LVL33-Ltext0
	.long	LVL34-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL34-Ltext0
	.long	LFE2-Ltext0
	.word	0x2
	.byte	0x91
	.sleb128 -40
	.long	0
	.long	0
LVUS18:
	.uleb128 LVU123
	.uleb128 LVU128
	.uleb128 LVU128
	.uleb128 LVU129
	.uleb128 LVU130
	.uleb128 LVU140
LLST18:
	.long	LVL43-Ltext0
	.long	LVL44-Ltext0
	.word	0x1
	.byte	0x52
	.long	LVL44-Ltext0
	.long	LVL45-Ltext0
	.word	0x1
	.byte	0x56
	.long	LVL46-Ltext0
	.long	LVL50-Ltext0
	.word	0x1
	.byte	0x56
	.long	0
	.long	0
LVUS19:
	.uleb128 LVU123
	.uleb128 LVU128
	.uleb128 LVU128
	.uleb128 LVU139
LLST19:
	.long	LVL43-Ltext0
	.long	LVL44-Ltext0
	.word	0x1
	.byte	0x50
	.long	LVL44-Ltext0
	.long	LVL49-Ltext0
	.word	0x1
	.byte	0x51
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
