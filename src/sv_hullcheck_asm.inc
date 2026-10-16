/* i486/387 compiler-scheduled body for SV_RecursiveHullCheck. The C function remains the reference. Keep this x87 schedule and recursive argument order intact. */
	.data
	.p2align 2
.Lsvhc_LC12:
	.asciz "SV_RecursiveHullCheck: bad node number"
.Lsvhc_LC13:
	.long -1717986918
	.long 1069128089
.Lsvhc_LC14:
	.asciz "backup past 0\n"
.Lsvhc_LC15:
	.long 1023410176
	.text
	#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_hull_check_calls)
	#endif
	#if defined(BENCH486) && defined(ASM486_HULLCHECK)
	.extern C(bench486_hullcheck_asm_calls)
	#endif
	.globl	_SV_RecursiveHullCheck_asm486
_SV_RecursiveHullCheck_asm486:
	#if defined(BENCH486) && defined(ASM486_HULLCHECK)
	incl C(bench486_hullcheck_asm_calls)
	#endif
	#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lsvhc_profile_count_done
	incl	C(bench486_hull_check_calls)
.Lsvhc_profile_count_done:
	#endif
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$60, %esp
	movl	80(%esp), %esi
	movl	84(%esp), %ebx
	movl	96(%esp), %ebp
	movl	100(%esp), %edi
	testl	%ebx, %ebx
	jns	.Lsvhc_131
	jmp	.Lsvhc_130
	.p2align 4
	.p2align 3
.Lsvhc_174:
	andl	$255, %ecx
	flds	0(%ebp,%ecx,4)
	fsub	%st(1), %st
	fxch	%st(1)
	fsubrs	(%edi,%ecx,4)
	fxch	%st(1)
.Lsvhc_138:
	ftst
	fnstsw	%ax
	fxch	%st(1)
	movl	%eax, %ecx
	ftst
	fnstsw	%ax
	testb	$5, %ch
	jne	.Lsvhc_167
	testb	$5, %ah
	jne	.Lsvhc_168
	fstp	%st(0)
	fstp	%st(0)
	movswl	4(%edx), %ebx
	testl	%ebx, %ebx
	js	.Lsvhc_130
.Lsvhc_131:
	cmpl	%ebx, 8(%esi)
	jg	.Lsvhc_135
	cmpl	%ebx, 12(%esi)
	jge	.Lsvhc_136
.Lsvhc_135:
	subl	$12, %esp
	pushl	$.Lsvhc_LC12
	call	_Sys_Error
	addl	$16, %esp
.Lsvhc_136:
	movl	(%esi), %eax
	leal	(%eax,%ebx,8), %edx
	movl	(%edx), %ecx
	leal	(%ecx,%ecx,4), %ebx
	movl	4(%esi), %eax
	leal	(%eax,%ebx,4), %ebx
	movb	16(%ebx), %cl
	flds	12(%ebx)
	cmpb	$2, %cl
	jbe	.Lsvhc_174
	flds	(%ebx)
	flds	4(%ebx)
	flds	8(%ebx)
	flds	0(%ebp)
	fmul	%st(3), %st
	flds	4(%ebp)
	fmul	%st(3), %st
	faddp	%st, %st(1)
	flds	8(%ebp)
	fmul	%st(2), %st
	faddp	%st, %st(1)
	fsub	%st(4), %st
	fxch	%st(3)
	fmuls	(%edi)
	fxch	%st(2)
	fmuls	4(%edi)
	faddp	%st, %st(2)
	fmuls	8(%edi)
	faddp	%st, %st(1)
	fsubp	%st, %st(2)
	jmp	.Lsvhc_138
	.p2align 4
	.p2align 3
.Lsvhc_167:
	testb	$1, %ah
	je	.Lsvhc_169
	fstp	%st(0)
	fstp	%st(0)
	movswl	6(%edx), %ebx
	testl	%ebx, %ebx
	jns	.Lsvhc_131
.Lsvhc_130:
	movl	104(%esp), %ecx
	cmpl	$-2, %ebx
	je	.Lsvhc_132
	movl	$0, (%ecx)
	incl	%ebx
	je	.Lsvhc_175
	movl	$1, 12(%ecx)
.Lsvhc_134:
	movl	$1, %eax
	addl	$60, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.p2align 4
	.p2align 3
.Lsvhc_168:
	movl	%edi, 100(%esp)
	movl	%edx, %edi
	movl	100(%esp), %edx
	fld	%st(1)
	fsubs	.Lsvhc_LC15
	fxch	%st(2)
	fsubp	%st, %st(1)
	fdivrp	%st, %st(1)
.Lsvhc_160:
	ftst
	fnstsw	%ax
	testb	$5, %ah
	je	.Lsvhc_146
	fstp	%st(0)
	fldz
.Lsvhc_146:
	fld1
	fxch	%st(1)
	fcom	%st(1)
	fnstsw	%ax
	testb	$69, %ah
	jne	.Lsvhc_178
	fstp	%st(0)
	jmp	.Lsvhc_147
	.p2align 4
	.p2align 3
.Lsvhc_178:
	fstp	%st(1)
.Lsvhc_147:
	flds	92(%esp)
	fsubs	88(%esp)
	fsts	20(%esp)
	fmul	%st(1), %st
	flds	88(%esp)
	faddp	%st, %st(1)
	fsts	16(%esp)
	flds	0(%ebp)
	flds	(%edx)
	fsub	%st(1), %st
	fmul	%st(3), %st
	faddp	%st, %st(1)
	fstps	36(%esp)
	flds	4(%ebp)
	flds	4(%edx)
	fsub	%st(1), %st
	fmul	%st(3), %st
	faddp	%st, %st(1)
	fstps	40(%esp)
	flds	8(%ebp)
	flds	8(%edx)
	fsub	%st(1), %st
	movl	%edx, 100(%esp)
	fmul	%st(3), %st
	fxch	%st(3)
	fstps	24(%esp)
	faddp	%st, %st(2)
	fxch	%st(1)
	fstps	44(%esp)
	pushl	%eax
	movl	108(%esp), %edx
	pushl	%edx
	leal	44(%esp), %eax
	pushl	%eax
	pushl	%ebp
	pushl	%eax
	fstps	(%esp)
	movl	108(%esp), %edx
	pushl	%edx
	testb	$1, %ch
	movl	%ecx, 36(%esp)
	setne	%cl
	andl	$255, %ecx
	movswl	4(%edi,%ecx,2), %eax
	pushl	%eax
	pushl	%esi
	call	_SV_RecursiveHullCheck_asm486
	addl	$32, %esp
	testl	%eax, %eax
	movl	12(%esp), %ecx
	flds	24(%esp)
	movl	100(%esp), %edx
	je	.Lsvhc_179
	movl	%edx, 100(%esp)
	fstps	24(%esp)
	testb	$5, %ch
	movl	%ecx, 12(%esp)
	sete	%al
	andl	$255, %eax
	movl	%eax, 28(%esp)
	pushl	%edx
	leal	40(%esp), %ecx
	pushl	%ecx
	movswl	4(%edi,%eax,2), %edx
	pushl	%edx
	pushl	%esi
	call	_SV_HullPointContents
	addl	$16, %esp
	cmpl	$-2, %eax
	movl	12(%esp), %ecx
	flds	24(%esp)
	movl	100(%esp), %edx
	jne	.Lsvhc_176
	movl	104(%esp), %eax
	movl	(%eax), %edi
	testl	%edi, %edi
	jne	.Lsvhc_180
	flds	(%ebx)
	andb	$5, %ch
	jne	.Lsvhc_170
	fstps	32(%eax)
	flds	4(%ebx)
	fstps	36(%eax)
	flds	8(%ebx)
	fstps	40(%eax)
	flds	12(%ebx)
.Lsvhc_154:
	fstps	44(%eax)
	movl	%edx, %ebx
	jmp	.Lsvhc_155
	.p2align 4
	.p2align 3
.Lsvhc_159:
	fldl	.Lsvhc_LC13
	fsubrp	%st, %st(1)
	ftst
	fnstsw	%ax
	testb	$1, %ah
	jne	.Lsvhc_177
	flds	20(%esp)
	fmul	%st(1), %st
	fadds	88(%esp)
	fstps	16(%esp)
	flds	0(%ebp)
	flds	(%ebx)
	fsub	%st(1), %st
	fmul	%st(2), %st
	faddp	%st, %st(1)
	fstps	36(%esp)
	flds	4(%ebp)
	flds	4(%ebx)
	fsub	%st(1), %st
	fmul	%st(2), %st
	faddp	%st, %st(1)
	fstps	40(%esp)
	flds	8(%ebp)
	flds	8(%ebx)
	fsub	%st(1), %st
	fmul	%st(2), %st
	faddp	%st, %st(1)
	fstps	44(%esp)
.Lsvhc_155:
	fstps	12(%esp)
	pushl	%eax
	leal	40(%esp), %ecx
	pushl	%ecx
	movl	8(%esi), %edx
	pushl	%edx
	pushl	%esi
	call	_SV_HullPointContents
	addl	$16, %esp
	cmpl	$-2, %eax
	flds	12(%esp)
	je	.Lsvhc_159
	fstp	%st(0)
	movl	104(%esp), %esi
	flds	16(%esp)
	fstps	16(%esi)
	flds	36(%esp)
	fstps	20(%esi)
	flds	40(%esp)
	fstps	24(%esi)
	flds	44(%esp)
	fstps	28(%esi)
	jmp	.Lsvhc_158
	.p2align 4
	.p2align 3
.Lsvhc_179:
	fstp	%st(0)
	jmp	.Lsvhc_158
.Lsvhc_180:
	fstp	%st(0)
	.p2align 3
	.p2align 3
.Lsvhc_158:
	xorl	%eax, %eax
.Lsvhc_129:
	addl	$60, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.p2align 4
	.p2align 3
.Lsvhc_169:
	movl	%edi, 100(%esp)
	movl	%edx, %edi
	movl	100(%esp), %edx
	fld	%st(1)
	fadds	.Lsvhc_LC15
	fxch	%st(1)
	fsubrp	%st, %st(2)
	fdivp	%st, %st(1)
	jmp	.Lsvhc_160
.Lsvhc_175:
	movl	$1, 8(%ecx)
	jmp	.Lsvhc_134
.Lsvhc_176:
	fstp	%st(0)
	pushl	%ebp
	movl	108(%esp), %ecx
	pushl	%ecx
	pushl	%edx
	leal	48(%esp), %edx
	pushl	%edx
	movl	108(%esp), %ebx
	pushl	%ebx
	movl	36(%esp), %eax
	pushl	%eax
	movl	52(%esp), %ebp
	movswl	4(%edi,%ebp,2), %edi
	pushl	%edi
	pushl	%esi
	call	_SV_RecursiveHullCheck_asm486
	addl	$32, %esp
	jmp	.Lsvhc_129
	.p2align 4
	.p2align 3
.Lsvhc_132:
	movl	$1, 4(%ecx)
	jmp	.Lsvhc_134
.Lsvhc_177:
	fstp	%st(0)
	movl	104(%esp), %ebp
	flds	16(%esp)
	fstps	16(%ebp)
	flds	36(%esp)
	fstps	20(%ebp)
	flds	40(%esp)
	fstps	24(%ebp)
	flds	44(%esp)
	fstps	28(%ebp)
	subl	$12, %esp
	pushl	$.Lsvhc_LC14
	call	_Con_DPrintf
	addl	$16, %esp
	jmp	.Lsvhc_158
.Lsvhc_170:
	fsubrs	_vec3_origin
	fstps	32(%eax)
	flds	_vec3_origin+4
	fsubs	4(%ebx)
	fstps	36(%eax)
	flds	_vec3_origin+8
	fsubs	8(%ebx)
	fstps	40(%eax)
	flds	12(%ebx)
	fchs
	jmp	.Lsvhc_154
	.p2align 3
