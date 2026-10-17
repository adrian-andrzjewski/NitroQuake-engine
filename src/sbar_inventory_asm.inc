/* i486 -O3 assembly for src/sbar.c:Sbar_DrawInventory.
 * Keep the C implementation in BENCH builds as an exact rendering/state oracle.
 */
.section .rodata
.p2align 2
LC99:
    .long 1092616192
.p2align 2
LC101:
    .long 1073741824
LC100:
    .byte 37,51,105,0
.text
.globl _Sbar_DrawInventory_asm486
_Sbar_DrawInventory_asm486:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$44, %esp
	movl	_rogue, %eax
	testl	%eax, %eax
	je	L131
	cmpl	$4095, _cl+68
	jg	L299
	pushl	%esi
	movl	_rsb_invbar+4, %edi
	pushl	%edi
	pushl	$-24
	pushl	$0
	call	_Sbar_DrawPic
	addl	$16, %esp
L133:
	xorl	%ebx, %ebx
	xorl	%ecx, %ecx
	movl	$1717986919, %esi
	movl	$1, %ebp
	jmp	L139
	.p2align 4
	.p2align 3
L302:
	movl	%ebp, %edx
	sall	%cl, %edx
	cmpl	%edx, _cl+68
	je	L300
	pushl	%eax
	movl	_sb_weapons(,%ecx,4), %edi
	pushl	%edi
L282:
	movl	%ecx, 12(%esp)
	pushl	$-16
	pushl	%ebx
	call	_Sbar_DrawPic
	addl	$16, %esp
	movl	4(%esp), %ecx
L135:
	incl	%ecx
	addl	$24, %ebx
	cmpl	$7, %ecx
	je	L301
L139:
	movl	_cl+156, %eax
	sarl	%cl, %eax
	testb	$1, %al
	je	L135
	fldl	_cl+572
	fsubs	_cl+160(,%ecx,4)
	fmuls	LC99
	fnstcw	14(%esp)
	movw	14(%esp), %dx
	orb	$12, %dh
	movw	%dx, 12(%esp)
	fldcw	12(%esp)
	fistpl	4(%esp)
	fldcw	14(%esp)
	movl	4(%esp), %edi
	cmpl	$9, %edi
	jg	L302
	movl	%edi, %eax
	imull	%esi
	sarl	$1, %edx
	movl	%edi, %eax
	sarl	$31, %eax
	subl	%eax, %edx
	leal	(%edx,%edx,4), %eax
	movl	%edi, %edx
	subl	%eax, %edx
	leal	2(%edx), %edi
	pushl	%eax
	leal	16(%ecx,%edx,8), %eax
	movl	%ecx, 8(%esp)
	movl	_sb_weapons(,%eax,4), %ecx
	pushl	%ecx
	pushl	$-16
	pushl	%ebx
	call	_Sbar_DrawPic
	addl	$16, %esp
	decl	%edi
	movl	4(%esp), %ecx
	jle	L135
	movl	$0, _sb_updates
	incl	%ecx
	addl	$24, %ebx
	cmpl	$7, %ecx
	jne	L139
L301:
	movl	_hipnotic, %ebx
	testl	%ebx, %ebx
	je	L140
	movl	$176, %ebp
	movl	$0, 8(%esp)
	xorl	%esi, %esi
L284:
	movl	_cl+156, %ebx
L164:
	movl	_hipweapons(,%esi,4), %ecx
	movl	%ebx, %edi
	sarl	%cl, %edi
	andl	$1, %edi
	je	L141
L305:
	fldl	_cl+572
	fsubs	_cl+160(,%ecx,4)
	fmuls	LC99
	fnstcw	14(%esp)
	movw	14(%esp), %dx
	orb	$12, %dh
	movw	%dx, 12(%esp)
	fldcw	12(%esp)
	fistpl	4(%esp)
	fldcw	14(%esp)
	movl	4(%esp), %eax
	cmpl	$9, %eax
	jle	L142
	movl	$1, %eax
	sall	%cl, %eax
	cmpl	%eax, _cl+68
	je	L303
	cmpl	$2, %esi
	je	L279
	cmpl	$3, %esi
	je	L304
	pushl	%edx
	movl	_hsb_weapons(,%esi,4), %edi
	pushl	%edi
L285:
	pushl	$-16
	pushl	%ebp
	call	_Sbar_DrawPic
	incl	%esi
	addl	$24, %ebp
	addl	$16, %esp
	movl	_cl+156, %ebx
	movl	_hipweapons(,%esi,4), %ecx
	movl	%ebx, %edi
	sarl	%cl, %edi
	andl	$1, %edi
	jne	L305
	.p2align 3
	.p2align 3
L141:
	incl	%esi
	addl	$24, %ebp
	cmpl	$4, %esi
	jne	L284
	.p2align 3
	.p2align 3
L140:
	movl	_rogue, %edx
	testl	%edx, %edx
	je	L165
	movl	_cl+68, %ecx
	cmpl	$4095, %ecx
	jle	L165
	cmpl	$4096, %ecx
	je	L306
L166:
	cmpl	$8192, _cl+68
	je	L307
L167:
	cmpl	$16384, _cl+68
	je	L308
L168:
	cmpl	$32768, _cl+68
	je	L309
L169:
	cmpl	$65536, _cl+68
	je	L310
	.p2align 3
	.p2align 3
L165:
	movl	$_cl, %esi
	movl	$22, %ebx
	leal	26(%esp), %edi
L174:
	pushl	%eax
	movl	52(%esi), %edx
	pushl	%edx
	pushl	$LC100
	pushl	%edi
	call	_sprintf
	movsbl	42(%esp), %ecx
	addl	$16, %esp
	cmpb	$32, %cl
	je	L171
	pushl	%ebp
	subl	$30, %ecx
	pushl	%ecx
	pushl	$-24
	leal	-16(%ebx), %eax
	pushl	%eax
	call	_Sbar_DrawCharacter
	addl	$16, %esp
L171:
	movsbl	27(%esp), %edx
	cmpb	$32, %dl
	je	L172
	pushl	%ecx
	subl	$30, %edx
	pushl	%edx
	pushl	$-24
	leal	-8(%ebx), %ebp
	pushl	%ebp
	call	_Sbar_DrawCharacter
	addl	$16, %esp
L172:
	movsbl	28(%esp), %ecx
	cmpb	$32, %cl
	je	L173
	pushl	%edx
	subl	$30, %ecx
	pushl	%ecx
	pushl	$-24
	pushl	%ebx
	call	_Sbar_DrawCharacter
	addl	$16, %esp
L173:
	addl	$4, %esi
	addl	$48, %ebx
	cmpl	$214, %ebx
	jne	L174
	movl	_cl+156, %ebx
	movl	%ebx, %edx
	movl	$192, %edi
	xorl	%esi, %esi
	.p2align 3
	.p2align 3
L182:
	leal	17(%esi), %ecx
	movl	%ebx, %eax
	sarl	%cl, %eax
	testb	$1, %al
	je	L175
	flds	_cl+228(,%esi,4)
	movl	_hipnotic, %edx
	testl	%edx, %edx
	je	L176
	cmpl	$1, %esi
	jle	L311
L176:
	fstps	4(%esp)
	pushl	%eax
	movl	_sb_items(,%esi,4), %ebx
	pushl	%ebx
	pushl	$-16
	pushl	%edi
	call	_Sbar_DrawPic
	addl	$16, %esp
	flds	4(%esp)
	ftst
	fnstsw	%ax
	movl	_cl+156, %ebx
	testb	$64, %ah
	jne	L325
L177:
	flds	LC101
	fsubrl	_cl+572
	fxch	%st(1)
	fcompp
	fnstsw	%ax
	testb	$69, %ah
	jne	L287
	movl	$0, _sb_updates
	jmp	L287
	.p2align 4
	.p2align 3
L325:
	fstp	%st(0)
L287:
	movl	%ebx, %edx
L175:
	incl	%esi
	addl	$16, %edi
	cmpl	$6, %esi
	jne	L182
	movl	_hipnotic, %ebp
	testl	%ebp, %ebp
	je	L183
	testl	$16777216, %ebx
	jne	L312
L184:
	testl	$33554432, %ebx
	jne	L313
	jmp	L183
	.p2align 4
	.p2align 3
L330:
	fstp	%st(0)
	.p2align 3
	.p2align 3
L183:
	movl	_rogue, %ecx
	testl	%ecx, %ecx
	jne	L191
	testl	$268435456, %ebx
	jne	L314
	testl	$536870912, %ebx
	jne	L315
L197:
	testl	$1073741824, %ebx
	jne	L316
L200:
	testl	%ebx, %ebx
	js	L317
	jmp	L280
	.p2align 4
	.p2align 3
L326:
	fstp	%st(0)
L280:
	addl	$44, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.p2align 4
	.p2align 3
L299:
	pushl	%ebp
	movl	_rsb_invbar, %edx
	pushl	%edx
	pushl	$-24
	pushl	$0
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L133
	.p2align 4
	.p2align 3
L300:
	pushl	%eax
	movl	_sb_weapons+32(,%ecx,4), %eax
	pushl	%eax
	jmp	L282
	.p2align 4
	.p2align 3
L142:
	movl	%eax, %ecx
	movl	$1717986919, %edx
	imull	%edx
	sarl	$1, %edx
	movl	%ecx, %eax
	sarl	$31, %eax
	subl	%eax, %edx
	leal	(%edx,%edx,4), %eax
	movl	%ecx, %edx
	subl	%eax, %edx
	addl	$2, %edx
	cmpl	$2, %esi
	je	L318
	cmpl	$3, %esi
	je	L319
	pushl	%eax
	leal	(%edx,%edx,4), %ebx
	movl	%edx, 8(%esp)
	addl	%esi, %ebx
	movl	_hsb_weapons(,%ebx,4), %edi
	pushl	%edi
	pushl	$-16
	pushl	%ebp
	call	_Sbar_DrawPic
	addl	$16, %esp
	movl	4(%esp), %ecx
	decl	%ecx
	jle	L283
	movl	$0, _sb_updates
L283:
	incl	%esi
	addl	$24, %ebp
	movl	_cl+156, %ebx
	jmp	L164
	.p2align 4
	.p2align 3
L191:
	andl	$536870912, %ebx
	jne	L320
L203:
	andl	$1073741824, %edx
	je	L280
	flds	_cl+280
	fstps	4(%esp)
	pushl	%ebx
	movl	_rsb_items+4, %ecx
	pushl	%ecx
	pushl	$-16
	pushl	$304
L298:
	call	_Sbar_DrawPic
	addl	$16, %esp
	flds	4(%esp)
	ftst
	fnstsw	%ax
	testb	$64, %ah
	jne	L326
	flds	LC101
	fsubrl	_cl+572
	fxch	%st(1)
	fcompp
	fnstsw	%ax
	testb	$69, %ah
	jne	L280
	movl	$0, _sb_updates
	jmp	L280
	.p2align 4
	.p2align 3
L311:
	ftst
	fnstsw	%ax
	testb	$64, %ah
	je	L177
	fstp	%st(0)
	movl	%ebx, %edx
	incl	%esi
	addl	$16, %edi
	jmp	L182
	.p2align 4
	.p2align 3
L131:
	pushl	%ecx
	movl	_sb_ibar, %ebx
	pushl	%ebx
	pushl	$-24
	pushl	$0
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L133
	.p2align 4
	.p2align 3
L304:
	andl	$16, %ebx
	je	L156
L160:
	movl	8(%esp), %ecx
	testl	%ecx, %ecx
	jne	L140
	pushl	%eax
	movl	_hsb_weapons+12, %ebx
	pushl	%ebx
	pushl	$-16
	pushl	$96
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L141
L309:
	pushl	%eax
	movl	_rsb_weapons+12, %ebp
	pushl	%ebp
	pushl	$-16
	pushl	$120
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L169
L308:
	pushl	%ecx
	movl	_rsb_weapons+8, %esi
	pushl	%esi
	pushl	$-16
	pushl	$96
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L168
L307:
	pushl	%esi
	movl	_rsb_weapons+4, %eax
	pushl	%eax
	pushl	$-16
	pushl	$72
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L167
L306:
	pushl	%ebp
	movl	_rsb_weapons, %ebx
	pushl	%ebx
	pushl	$-16
	pushl	$48
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L166
L310:
	pushl	%eax
	movl	_rsb_weapons+16, %edi
	pushl	%edi
	pushl	$-16
	pushl	$144
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L165
	.p2align 4
	.p2align 3
L303:
	cmpl	$2, %esi
	je	L321
	cmpl	$3, %esi
	je	L322
	pushl	%eax
	movl	_hsb_weapons+20(,%esi,4), %eax
	pushl	%eax
	jmp	L285
	.p2align 4
	.p2align 3
L314:
	flds	_cl+272
	fstps	4(%esp)
	pushl	%eax
	movl	_sb_sigil, %edx
	pushl	%edx
	pushl	$-16
	pushl	$288
	call	_Sbar_DrawPic
	addl	$16, %esp
	flds	4(%esp)
	ftst
	fnstsw	%ax
	testb	$64, %ah
	jne	L327
	flds	LC101
	fsubrl	_cl+572
	fcompp
	fnstsw	%ax
	testb	$1, %ah
	je	L289
	movl	$0, _sb_updates
	jmp	L289
	.p2align 4
	.p2align 3
L327:
	fstp	%st(0)
L289:
	movl	_cl+156, %ebx
	testl	$536870912, %ebx
	je	L197
L315:
	flds	_cl+276
	fstps	4(%esp)
	pushl	%eax
	movl	_sb_sigil+4, %ebx
	pushl	%ebx
	pushl	$-16
	pushl	$296
	call	_Sbar_DrawPic
	addl	$16, %esp
	flds	4(%esp)
	ftst
	fnstsw	%ax
	testb	$64, %ah
	jne	L328
	flds	LC101
	fsubrl	_cl+572
	fcompp
	fnstsw	%ax
	testb	$1, %ah
	je	L290
	movl	$0, _sb_updates
	jmp	L290
	.p2align 4
	.p2align 3
L328:
	fstp	%st(0)
L290:
	movl	_cl+156, %ebx
	testl	$1073741824, %ebx
	je	L200
L316:
	flds	_cl+280
	fstps	4(%esp)
	pushl	%eax
	movl	_sb_sigil+8, %ebp
	pushl	%ebp
	pushl	$-16
	pushl	$304
	call	_Sbar_DrawPic
	addl	$16, %esp
	flds	4(%esp)
	ftst
	fnstsw	%ax
	testb	$64, %ah
	jne	L329
	flds	LC101
	fsubrl	_cl+572
	fcompp
	fnstsw	%ax
	testb	$1, %ah
	je	L291
	movl	$0, _sb_updates
	jmp	L291
	.p2align 4
	.p2align 3
L329:
	fstp	%st(0)
L291:
	movl	_cl+156, %ebx
	testl	%ebx, %ebx
	jns	L280
L317:
	flds	_cl+284
	fstps	4(%esp)
	pushl	%edx
	movl	_sb_sigil+12, %edi
	pushl	%edi
	pushl	$-16
	pushl	$312
	jmp	L298
	.p2align 4
	.p2align 3
L313:
	flds	_cl+260
	fstps	4(%esp)
	pushl	%ebx
	movl	_hsb_items+4, %esi
	pushl	%esi
	pushl	$-16
	pushl	$304
	call	_Sbar_DrawPic
	addl	$16, %esp
	flds	4(%esp)
	ftst
	fnstsw	%ax
	movl	_cl+156, %ebx
	movl	%ebx, %edx
	testb	$64, %ah
	jne	L330
	flds	LC101
	fsubrl	_cl+572
	fxch	%st(1)
	fcompp
	fnstsw	%ax
	testb	$69, %ah
	jne	L183
	movl	$0, _sb_updates
	jmp	L183
	.p2align 4
	.p2align 3
L312:
	flds	_cl+256
	fstps	4(%esp)
	pushl	%edi
	movl	_hsb_items, %edi
	pushl	%edi
	pushl	$-16
	pushl	$288
	call	_Sbar_DrawPic
	addl	$16, %esp
	flds	4(%esp)
	ftst
	fnstsw	%ax
	testb	$64, %ah
	jne	L331
	flds	LC101
	fsubrl	_cl+572
	fxch	%st(1)
	fcompp
	fnstsw	%ax
	testb	$69, %ah
	jne	L288
	movl	$0, _sb_updates
	jmp	L288
	.p2align 4
	.p2align 3
L331:
	fstp	%st(0)
L288:
	movl	_cl+156, %ebx
	movl	%ebx, %edx
	jmp	L184
	.p2align 4
	.p2align 3
L320:
	flds	_cl+276
	fstps	4(%esp)
	pushl	%edi
	movl	_rsb_items, %esi
	pushl	%esi
	pushl	$-16
	pushl	$288
	call	_Sbar_DrawPic
	addl	$16, %esp
	flds	4(%esp)
	ftst
	fnstsw	%ax
	testb	$64, %ah
	jne	L332
	flds	LC101
	fsubrl	_cl+572
	fxch	%st(1)
	fcompp
	fnstsw	%ax
	testb	$69, %ah
	jne	L292
	movl	$0, _sb_updates
	jmp	L292
	.p2align 4
	.p2align 3
L332:
	fstp	%st(0)
L292:
	movl	_cl+156, %edx
	jmp	L203
	.p2align 4
	.p2align 3
L319:
	andl	$16, %ebx
	je	L159
	testl	%edx, %edx
	je	L160
	movl	8(%esp), %eax
	testl	%eax, %eax
	je	L323
L162:
	decl	%edx
	jle	L140
	movl	$0, _sb_updates
	jmp	L140
	.p2align 4
	.p2align 3
L318:
	testl	$65536, %ebx
	je	L149
	testl	%edx, %edx
	jne	L324
L279:
	addl	$24, %ebp
	movl	$3, %esi
	jmp	L164
L324:
	pushl	%eax
	leal	(%edx,%edx,4), %ecx
	movl	%edx, 8(%esp)
	movl	_hsb_weapons+8(,%ecx,4), %esi
	pushl	%esi
	pushl	$-16
	pushl	$96
	call	_Sbar_DrawPic
	addl	$16, %esp
	movl	%edi, 8(%esp)
	movl	_cl+156, %ebx
	movl	4(%esp), %edx
L149:
	decl	%edx
	jle	L279
	movl	$0, _sb_updates
	addl	$24, %ebp
	movl	$3, %esi
	jmp	L164
L323:
	pushl	%ecx
	leal	(%edx,%edx,4), %ebx
	movl	%edx, 8(%esp)
	movl	_hsb_weapons+12(,%ebx,4), %edx
	pushl	%edx
L293:
	pushl	$-16
	pushl	$96
	call	_Sbar_DrawPic
	addl	$16, %esp
	movl	4(%esp), %edx
	jmp	L162
L322:
	andl	$16, %ebx
	je	L153
	movl	8(%esp), %ebp
	testl	%ebp, %ebp
	jne	L140
	pushl	%edi
	movl	_hsb_weapons+32, %edi
	pushl	%edi
	pushl	$-16
	pushl	$96
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L140
L159:
	pushl	%ebx
	leal	(%edx,%edx,4), %esi
	movl	%edx, 8(%esp)
	movl	_hsb_weapons+16(,%esi,4), %ebp
	pushl	%ebp
	jmp	L293
L321:
	testl	$65536, %ebx
	je	L279
	pushl	%eax
	movl	_hsb_weapons+28, %ebx
	pushl	%ebx
	pushl	$-16
	pushl	$96
	call	_Sbar_DrawPic
	addl	$24, %ebp
	addl	$16, %esp
	movl	%edi, 8(%esp)
	movl	$3, %esi
	movl	_cl+156, %ebx
	jmp	L164
L156:
	pushl	%edi
	movl	_hsb_weapons+16, %edx
	pushl	%edx
	pushl	$-16
	pushl	$96
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L140
L153:
	pushl	%eax
	movl	_hsb_weapons+36, %esi
	pushl	%esi
	pushl	$-16
	pushl	$96
	call	_Sbar_DrawPic
	addl	$16, %esp
	jmp	L140
	.p2align 3
