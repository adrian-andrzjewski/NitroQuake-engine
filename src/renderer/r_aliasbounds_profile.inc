/* Alias bounds algorithm; profile. Pinned source SHA256
 * BE6A06B767651363BD586FFF62BBA467F333D87820C13E7D66BF9D5A7B8FC979
 * One-time original schedule import; normal builds assemble this maintained file.
 * Cdecl, except R_AliasDrawModel receives its light pointer in EAX (regparm 1).
 * EBX/ESI/EDI/EBP are callee-owned; EAX/ECX/EDX and arithmetic flags are caller-owned.
 * Integer stores, x87 order, truncating CW changes and rounding stores are parity contracts. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */

.text
.p2align 3
/* R_AliasCheckBBox: Transform eight frame corners, clip the twelve original near-plane edges, reject XY bounds and retain the entity transform cache.
 * Saved callee registers used: %ebp, %ebx, %edi, %esi.
 * Stack reservations: 840, 8, 12 bytes; all return paths restore ESP. */
	.globl	_R_AliasCheckBBox
_R_AliasCheckBBox:
	pushl	%ebp	#
	pushl	%edi	#
	pushl	%esi	#
	pushl	%ebx	#
	subl	$840, %esp	#,
/* original r_alias.c:180: 	alias_transform_entity = NULL; */
	movl	$0, _aliascontrol_alias_transform_entity	#, alias_transform_entity
/* original r_alias.c:184: 	currententity->trivial_accept = 0; */
	movl	_currententity, %eax	# currententity, currententity.0_1
/* original r_alias.c:184: 	currententity->trivial_accept = 0; */
	movl	$0, 172(%eax)	#, currententity.0_1->trivial_accept
/* original r_alias.c:185: 	pmodel = currententity->model; */
	movl	132(%eax), %edx	# currententity.0_1->model, _3
/* original r_alias.c:185: 	pmodel = currententity->model; */
	movl	%edx, _aliascontrol_pmodel	# _3, pmodel
/* original r_alias.c:186: 	pahdr = Mod_Extradata (pmodel); */
	pushl	%edx	# _3
	call	_Mod_Extradata	#
	movl	%eax, %ebx	# tmp785, pahdr
/* original r_alias.c:187: 	pmdl = (mdl_t *)((byte *)pahdr + pahdr->model); */
	addl	(%eax), %eax	# pahdr_92->model, tmp331
/* original r_alias.c:187: 	pmdl = (mdl_t *)((byte *)pahdr + pahdr->model); */
	movl	%eax, _pmdl	# tmp331, pmdl
/* original r_alias.c:189: 	R_AliasSetUpTransform (0); */
	movl	$0, (%esp)	#,
	call	_R_AliasSetUpTransform	#
/* original r_alias.c:192: 	frame = currententity->frame; */
	movl	_currententity, %ecx	# currententity, currententity
	movl	140(%ecx), %ebp	# currententity.3_8->frame, frame
/* original r_alias.c:194: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	addl	$16, %esp	#,
	movl	_pmdl, %esi	# pmdl, pmdl
	cmpl	%ebp, 68(%esi)	# frame, pmdl.4_9->numframes
	jle	L40	#,
/* original r_alias.c:194: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	testl	%ebp, %ebp	# frame
	js	L40	#,
L41:
/* original r_alias.c:205: 			(float)pframedesc->bboxmin.v[0]; */
	sall	$5, %ebp	#, tmp335
/* original r_alias.c:205: 			(float)pframedesc->bboxmin.v[0]; */
	xorl	%eax, %eax	#
	movb	20(%ebx,%ebp), %al	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmin.v[0], MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmin.v[0]
	movw	%ax, (%esp)	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmin.v[0], %sfp
	filds	(%esp)	# %sfp
/* original r_alias.c:204: 	basepts[0][0] = basepts[1][0] = basepts[2][0] = basepts[3][0] = */
	fsts	52(%esp)	# basepts[3][0]
/* original r_alias.c:204: 	basepts[0][0] = basepts[1][0] = basepts[2][0] = basepts[3][0] = */
	fsts	40(%esp)	# basepts[2][0]
/* original r_alias.c:204: 	basepts[0][0] = basepts[1][0] = basepts[2][0] = basepts[3][0] = */
	fsts	28(%esp)	# basepts[1][0]
/* original r_alias.c:204: 	basepts[0][0] = basepts[1][0] = basepts[2][0] = basepts[3][0] = */
	fstps	16(%esp)	# basepts[0][0]
/* original r_alias.c:207: 			(float)pframedesc->bboxmax.v[0]; */
	xorl	%edx, %edx	#
	movb	24(%ebx,%ebp), %dl	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmax.v[0], MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmax.v[0]
	movw	%dx, (%esp)	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmax.v[0], %sfp
	filds	(%esp)	# %sfp
/* original r_alias.c:206: 	basepts[4][0] = basepts[5][0] = basepts[6][0] = basepts[7][0] = */
	fsts	100(%esp)	# basepts[7][0]
/* original r_alias.c:206: 	basepts[4][0] = basepts[5][0] = basepts[6][0] = basepts[7][0] = */
	fsts	88(%esp)	# basepts[6][0]
/* original r_alias.c:206: 	basepts[4][0] = basepts[5][0] = basepts[6][0] = basepts[7][0] = */
	fsts	76(%esp)	# basepts[5][0]
/* original r_alias.c:206: 	basepts[4][0] = basepts[5][0] = basepts[6][0] = basepts[7][0] = */
	fstps	64(%esp)	# basepts[4][0]
/* original r_alias.c:211: 			(float)pframedesc->bboxmin.v[1]; */
	xorl	%ecx, %ecx	#
	movb	21(%ebx,%ebp), %cl	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmin.v[1], MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmin.v[1]
	movw	%cx, (%esp)	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmin.v[1], %sfp
	filds	(%esp)	# %sfp
/* original r_alias.c:210: 	basepts[0][1] = basepts[3][1] = basepts[5][1] = basepts[6][1] = */
	fsts	92(%esp)	# basepts[6][1]
/* original r_alias.c:210: 	basepts[0][1] = basepts[3][1] = basepts[5][1] = basepts[6][1] = */
	fsts	80(%esp)	# basepts[5][1]
/* original r_alias.c:210: 	basepts[0][1] = basepts[3][1] = basepts[5][1] = basepts[6][1] = */
	fsts	56(%esp)	# basepts[3][1]
/* original r_alias.c:210: 	basepts[0][1] = basepts[3][1] = basepts[5][1] = basepts[6][1] = */
	fstps	20(%esp)	# basepts[0][1]
/* original r_alias.c:213: 			(float)pframedesc->bboxmax.v[1]; */
	xorl	%eax, %eax	#
	movb	25(%ebx,%ebp), %al	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmax.v[1], MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmax.v[1]
	movw	%ax, (%esp)	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmax.v[1], %sfp
	filds	(%esp)	# %sfp
/* original r_alias.c:212: 	basepts[1][1] = basepts[2][1] = basepts[4][1] = basepts[7][1] = */
	fsts	104(%esp)	# basepts[7][1]
/* original r_alias.c:212: 	basepts[1][1] = basepts[2][1] = basepts[4][1] = basepts[7][1] = */
	fsts	68(%esp)	# basepts[4][1]
/* original r_alias.c:212: 	basepts[1][1] = basepts[2][1] = basepts[4][1] = basepts[7][1] = */
	fsts	44(%esp)	# basepts[2][1]
/* original r_alias.c:212: 	basepts[1][1] = basepts[2][1] = basepts[4][1] = basepts[7][1] = */
	fstps	32(%esp)	# basepts[1][1]
/* original r_alias.c:217: 			(float)pframedesc->bboxmin.v[2]; */
	xorl	%edx, %edx	#
	movb	22(%ebx,%ebp), %dl	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmin.v[2], MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmin.v[2]
	movw	%dx, (%esp)	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmin.v[2], %sfp
	filds	(%esp)	# %sfp
/* original r_alias.c:216: 	basepts[0][2] = basepts[1][2] = basepts[4][2] = basepts[5][2] = */
	fsts	84(%esp)	# basepts[5][2]
/* original r_alias.c:216: 	basepts[0][2] = basepts[1][2] = basepts[4][2] = basepts[5][2] = */
	fsts	72(%esp)	# basepts[4][2]
/* original r_alias.c:216: 	basepts[0][2] = basepts[1][2] = basepts[4][2] = basepts[5][2] = */
	fsts	36(%esp)	# basepts[1][2]
/* original r_alias.c:216: 	basepts[0][2] = basepts[1][2] = basepts[4][2] = basepts[5][2] = */
	fstps	24(%esp)	# basepts[0][2]
/* original r_alias.c:219: 			(float)pframedesc->bboxmax.v[2]; */
	xorl	%eax, %eax	#
	movb	26(%ebx,%ebp), %al	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmax.v[2], MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmax.v[2]
	movw	%ax, (%esp)	# MEM <struct aliashdr_t> [(struct maliasframedesc_t *)pahdr_92].frames[frame_66].bboxmax.v[2], %sfp
	filds	(%esp)	# %sfp
/* original r_alias.c:218: 	basepts[2][2] = basepts[3][2] = basepts[6][2] = basepts[7][2] = */
	fsts	108(%esp)	# basepts[7][2]
/* original r_alias.c:218: 	basepts[2][2] = basepts[3][2] = basepts[6][2] = basepts[7][2] = */
	fsts	96(%esp)	# basepts[6][2]
/* original r_alias.c:218: 	basepts[2][2] = basepts[3][2] = basepts[6][2] = basepts[7][2] = */
	fsts	60(%esp)	# basepts[3][2]
/* original r_alias.c:218: 	basepts[2][2] = basepts[3][2] = basepts[6][2] = basepts[7][2] = */
	fstps	48(%esp)	# basepts[2][2]
	leal	328(%esp), %esi	#, ivtmp.187
	xorl	%ebx, %ebx	# ivtmp.189
/* original r_alias.c:224: 	minz = 9999; */
	movl	$9999, (%esp)	#, %sfp
/* original r_alias.c:222: 	zfullyclipped = true; */
	movl	$1, %ebp	#, zfullyclipped
/* original r_alias.c:221: 	zclipped = false; */
	xorl	%edi, %edi	# zclipped
	jmp	L45	#
	.p2align 4
	.p2align 3
L77:
/* original r_alias.c:237: 			if (viewaux[i].fv[2] < minz) */
	ficoml	(%esp)	# %sfp
	fnstsw	%ax	# tmp375
	testb	$1, %ah	#, tmp375
	je	L79	#,
/* original r_alias.c:238: 				minz = viewaux[i].fv[2]; */
	fnstcw	14(%esp)	#
	movw	14(%esp), %cx	#, tmp790
	orb	$12, %ch	#, tmp790
	movw	%cx, 12(%esp)	# tmp790,
	fldcw	12(%esp)		#
	fistpl	(%esp)	# %sfp
	fldcw	14(%esp)		#
	jmp	L43	#
	.p2align 4
	.p2align 3
L79:
	fstp	%st(0)		#
L43:
/* original r_alias.c:233: 			zclipped = true; */
	xorl	%edx, %edx	# _165
/* original r_alias.c:240: 			zfullyclipped = false; */
	xorl	%ebp, %ebp	# zfullyclipped
/* original r_alias.c:232: 			viewpts[i].flags = ALIAS_Z_CLIP; */
	movl	%edx, (%esi)	# _165, MEM[(int *)_192]
/* original r_alias.c:225: 	for (i=0; i<8 ; i++) */
	addl	$32, %esi	#, ivtmp.187
	addl	$12, %ebx	#, ivtmp.189
	cmpl	$96, %ebx	#, ivtmp.189
	je	L76	#,
L45:
/* original r_alias.c:227: 		R_AliasTransformVector  (&basepts[i][0], &viewaux[i].fv[0]); */
	subl	$8, %esp	#,
/* original r_alias.c:227: 		R_AliasTransformVector  (&basepts[i][0], &viewaux[i].fv[0]); */
	leal	120(%esp), %ecx	#, tmp804
	addl	%ebx, %ecx	# ivtmp.189, tmp367
/* original r_alias.c:227: 		R_AliasTransformVector  (&basepts[i][0], &viewaux[i].fv[0]); */
	pushl	%ecx	# tmp367
/* original r_alias.c:227: 		R_AliasTransformVector  (&basepts[i][0], &viewaux[i].fv[0]); */
	leal	28(%esp), %edx	#, tmp805
	addl	%ebx, %edx	# ivtmp.189, tmp369
/* original r_alias.c:227: 		R_AliasTransformVector  (&basepts[i][0], &viewaux[i].fv[0]); */
	pushl	%edx	# tmp369
	call	_R_AliasTransformVector	#
/* original r_alias.c:229: 		if (viewaux[i].fv[2] < ALIAS_Z_CLIP_PLANE) */
	flds	136(%esp,%ebx)	# MEM[(float *)&viewaux + 8B + ivtmp.189_61 * 1]
/* original r_alias.c:229: 		if (viewaux[i].fv[2] < ALIAS_Z_CLIP_PLANE) */
	addl	$16, %esp	#,
	fcoms	LC4	#
	fnstsw	%ax	# tmp373
	testb	$1, %ah	#, tmp373
	je	L77	#,
	fstp	%st(0)		#
	movl	$16, %edx	#, _165
/* original r_alias.c:233: 			zclipped = true; */
	movl	$1, %edi	#, zclipped
/* original r_alias.c:232: 			viewpts[i].flags = ALIAS_Z_CLIP; */
	movl	%edx, (%esi)	# _165, MEM[(int *)_192]
/* original r_alias.c:225: 	for (i=0; i<8 ; i++) */
	addl	$32, %esi	#, ivtmp.187
	addl	$12, %ebx	#, ivtmp.189
	cmpl	$96, %ebx	#, ivtmp.189
	jne	L45	#,
L76:
/* original r_alias.c:245: 	if (zfullyclipped) */
	testl	%ebp, %ebp	# zfullyclipped
	jne	L61	#,
/* original r_alias.c:252: 	if (zclipped) */
	testl	%edi, %edi	# zclipped
	je	L48	#,
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	movl	328(%esp), %edi	# MEM <struct finalvert_t[16]> [(struct finalvert_t *)&viewpts][0].flags, _48
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	movl	360(%esp), %edx	# MEM <struct finalvert_t[16]> [(struct finalvert_t *)&viewpts][1].flags, _4
	movl	%edx, (%esp)	# _4, %sfp
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%edi, %edx	# _48, _4
	je	L67	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	120(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][0].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	132(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][1].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	112(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][0].fv[0]
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	124(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][1].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	208(%esp)	# viewaux[8].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	116(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][0].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	128(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][1].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	212(%esp)	# viewaux[8].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	216(%esp)	# viewaux[8].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	$0, 584(%esp)	#, viewpts[8].flags
/* original r_alias.c:275: 				numv++; */
	movl	$9, %eax	#, numv
L49:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	movl	392(%esp), %esi	# MEM <struct finalvert_t[16]> [(struct finalvert_t *)&viewpts][2].flags, _193
	movl	%esi, 4(%esp)	# _193, %sfp
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%esi, (%esp)	# _193, %sfp
	je	L50	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	132(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][1].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	144(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][2].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	124(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][1].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %ebx	#, tmp394
	addl	%eax, %ebx	# numv, tmp395
	leal	816(%esp,%ebx,4), %ebp	#, tmp397
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	136(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][2].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%ebp)	# viewaux[numv_182].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	128(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][1].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	140(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][2].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%ebp)	# viewaux[numv_182].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%ebp)	# viewaux[numv_182].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %ecx	# numv, tmp420
	sall	$5, %ecx	#, tmp420
	movl	$0, 328(%esp,%ecx)	#, viewpts[numv_182].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L50:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	movl	424(%esp), %ecx	# MEM <struct finalvert_t[16]> [(struct finalvert_t *)&viewpts][3].flags, _225
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%ecx, 4(%esp)	# _225, %sfp
	je	L51	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	144(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][2].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	156(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][3].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	136(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][2].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %edx	#, tmp428
	addl	%eax, %edx	# numv, tmp429
	leal	816(%esp,%edx,4), %esi	#, tmp431
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	148(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][3].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%esi)	# viewaux[numv_214].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	140(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][2].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	152(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][3].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%esi)	# viewaux[numv_214].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%esi)	# viewaux[numv_214].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %ebx	# numv, tmp454
	sall	$5, %ebx	#, tmp454
	movl	$0, 328(%esp,%ebx)	#, viewpts[numv_214].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L51:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%ecx, %edi	# _225, _48
	je	L52	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	156(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][3].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	120(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][0].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	148(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][3].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %ebp	#, tmp462
	addl	%eax, %ebp	# numv, tmp463
	leal	816(%esp,%ebp,4), %edx	#, tmp465
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	112(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][0].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%edx)	# viewaux[numv_246].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	152(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][3].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	116(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][0].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%edx)	# viewaux[numv_246].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%edx)	# viewaux[numv_246].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %esi	# numv, tmp488
	sall	$5, %esi	#, tmp488
	movl	$0, 328(%esp,%esi)	#, viewpts[numv_246].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L52:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	movl	456(%esp), %ebx	# MEM <struct finalvert_t[16]> [(struct finalvert_t *)&viewpts][4].flags, _288
	movl	%ebx, 8(%esp)	# _288, %sfp
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	movl	488(%esp), %esi	# MEM <struct finalvert_t[16]> [(struct finalvert_t *)&viewpts][5].flags, _289
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%esi, %ebx	# _289, _288
	je	L53	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	168(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][4].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	180(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][5].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	160(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][4].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %ebp	#, tmp496
	addl	%eax, %ebp	# numv, tmp497
	leal	816(%esp,%ebp,4), %edx	#, tmp499
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	172(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][5].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%edx)	# viewaux[numv_278].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	164(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][4].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	176(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][5].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%edx)	# viewaux[numv_278].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%edx)	# viewaux[numv_278].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %ebx	# numv, tmp522
	sall	$5, %ebx	#, tmp522
	movl	$0, 328(%esp,%ebx)	#, viewpts[numv_278].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L53:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	movl	520(%esp), %edx	# MEM <struct finalvert_t[16]> [(struct finalvert_t *)&viewpts][6].flags, _321
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%edx, %esi	# _321, _289
	je	L54	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	180(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][5].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	192(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][6].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	172(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][5].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %ebp	#, tmp530
	addl	%eax, %ebp	# numv, tmp531
	leal	816(%esp,%ebp,4), %ebx	#, tmp533
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	184(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][6].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%ebx)	# viewaux[numv_310].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	176(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][5].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	188(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][6].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%ebx)	# viewaux[numv_310].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%ebx)	# viewaux[numv_310].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %ebp	# numv, tmp556
	sall	$5, %ebp	#, tmp556
	movl	$0, 328(%esp,%ebp)	#, viewpts[numv_310].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L54:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	movl	552(%esp), %ebx	# MEM <struct finalvert_t[16]> [(struct finalvert_t *)&viewpts][7].flags, _353
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%ebx, %edx	# _353, _321
	je	L55	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	192(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][6].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	204(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][7].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	184(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][6].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %ebp	#, tmp564
	addl	%eax, %ebp	# numv, tmp565
	leal	816(%esp,%ebp,4), %ebp	#, tmp567
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	196(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][7].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%ebp)	# viewaux[numv_342].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	188(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][6].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	200(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][7].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%ebp)	# viewaux[numv_342].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%ebp)	# viewaux[numv_342].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %ebp	# numv, tmp590
	sall	$5, %ebp	#, tmp590
	movl	$0, 328(%esp,%ebp)	#, viewpts[numv_342].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L55:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%ebx, 8(%esp)	# _353, %sfp
	je	L56	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	204(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][7].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	168(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][4].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	196(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][7].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %ebp	#, tmp598
	addl	%eax, %ebp	# numv, tmp599
	leal	816(%esp,%ebp,4), %ebp	#, tmp601
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	160(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][4].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%ebp)	# viewaux[numv_374].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	200(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][7].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	164(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][4].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%ebp)	# viewaux[numv_374].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%ebp)	# viewaux[numv_374].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %ebp	# numv, tmp624
	sall	$5, %ebp	#, tmp624
	movl	$0, 328(%esp,%ebp)	#, viewpts[numv_374].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L56:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%esi, %edi	# _289, _48
	je	L57	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	120(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][0].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	180(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][5].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	112(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][0].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %edi	#, tmp632
	addl	%eax, %edi	# numv, tmp633
	leal	816(%esp,%edi,4), %esi	#, tmp635
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	172(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][5].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%esi)	# viewaux[numv_406].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	116(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][0].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	176(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][5].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%esi)	# viewaux[numv_406].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%esi)	# viewaux[numv_406].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %ebp	# numv, tmp658
	sall	$5, %ebp	#, tmp658
	movl	$0, 328(%esp,%ebp)	#, viewpts[numv_406].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L57:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	movl	8(%esp), %edi	# %sfp, _288
	cmpl	%edi, (%esp)	# _288, %sfp
	je	L58	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	132(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][1].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	168(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][4].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	124(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][1].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %esi	#, tmp666
	addl	%eax, %esi	# numv, tmp667
	leal	816(%esp,%esi,4), %ebp	#, tmp669
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	160(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][4].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%ebp)	# viewaux[numv_438].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	128(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][1].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	164(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][4].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%ebp)	# viewaux[numv_438].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%ebp)	# viewaux[numv_438].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %edi	# numv, tmp692
	sall	$5, %edi	#, tmp692
	movl	$0, 328(%esp,%edi)	#, viewpts[numv_438].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L58:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%ebx, 4(%esp)	# _353, %sfp
	je	L59	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	144(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][2].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	204(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][7].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	136(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][2].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %ebx	#, tmp700
	addl	%eax, %ebx	# numv, tmp701
	leal	816(%esp,%ebx,4), %esi	#, tmp703
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	196(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][7].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%esi)	# viewaux[numv_470].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	140(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][2].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	200(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][7].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%esi)	# viewaux[numv_470].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%esi)	# viewaux[numv_470].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %ebp	# numv, tmp726
	sall	$5, %ebp	#, tmp726
	movl	$0, 328(%esp,%ebp)	#, viewpts[numv_470].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L59:
/* original r_alias.c:265: 			if (pv0->flags ^ pv1->flags) */
	cmpl	%edx, %ecx	# _321, _225
	je	L60	#,
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	156(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][3].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	flds	LC4	#
	fld	%st(0)	#
	fsub	%st(2), %st	#,
	fxch	%st(2)		#
/* original r_alias.c:268: 					   (pa1->fv[2] - pa0->fv[2]); */
	fsubrs	192(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][6].fv[2]
/* original r_alias.c:267: 				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) / */
	fdivrp	%st, %st(2)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	flds	148(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][3].fv[0]
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	leal	(%eax,%eax), %ecx	#, tmp734
	addl	%eax, %ecx	# numv, tmp735
	leal	816(%esp,%ecx,4), %edx	#, tmp737
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	flds	184(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][6].fv[0]
	fsub	%st(1), %st	#,
/* original r_alias.c:270: 						(pa1->fv[0] - pa0->fv[0]) * frac; */
	fmul	%st(3), %st	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	faddp	%st, %st(1)	#,
/* original r_alias.c:269: 				viewaux[numv].fv[0] = pa0->fv[0] + */
	fstps	-704(%edx)	# viewaux[numv_502].fv[0]
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	flds	152(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][3].fv[1]
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	flds	188(%esp)	# MEM <struct auxvert_t[16]> [(struct auxvert_t *)&viewaux][6].fv[1]
	fsub	%st(1), %st	#,
/* original r_alias.c:272: 						(pa1->fv[1] - pa0->fv[1]) * frac; */
	fmulp	%st, %st(3)	#,
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* original r_alias.c:271: 				viewaux[numv].fv[1] = pa0->fv[1] + */
	fstps	-700(%edx)	# viewaux[numv_502].fv[1]
/* original r_alias.c:273: 				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE; */
	fstps	-696(%edx)	# viewaux[numv_502].fv[2]
/* original r_alias.c:274: 				viewpts[numv].flags = 0; */
	movl	%eax, %edi	# numv, tmp760
	sall	$5, %edi	#, tmp760
	movl	$0, 328(%esp,%edi)	#, viewpts[numv_502].flags
/* original r_alias.c:275: 				numv++; */
	incl	%eax	# numv
L60:
/* original r_alias.c:288: 		clipresult = R_AliasCheckBBoxProject_asm486 (viewaux, viewpts, numv); */
	pushl	%edx	#
	pushl	%eax	# numv
	leal	312(%esp), %eax	#, tmp763
	pushl	%eax	# tmp763
	leal	124(%esp), %ebx	#, tmp865
	pushl	%ebx	# tmp865
	call	_R_AliasCheckBBoxProject_asm486	#
	movzbl	%ah, %esi	# tmp786, prephitmp_170
/* original r_alias.c:322: 	if (allclip) */
	addl	$16, %esp	#,
	testb	$-1, %ah	#, tmp786
	jne	L61	#,
#if ASM486_ALIAS_MODEL_OCCLUSION
	pushl	%eax	# preserve clip flags
	call	_R_AliasModelOccluded	#
	testl	%eax, %eax	# occluded
	popl	%eax	# restore clip flags
	jne	L61	#,
#endif
/* original r_alias.c:325: 	currententity->trivial_accept = !anyclip & !zclipped; */
	movl	_currententity, %ecx	# currententity, prephitmp_168
/* original r_alias.c:325: 	currententity->trivial_accept = !anyclip & !zclipped; */
	movl	$0, 172(%ecx)	#, currententity.7_319->trivial_accept
L63:
/* original r_alias.c:340: 	alias_transform_entity = currententity; */
	movl	%ecx, _aliascontrol_alias_transform_entity	# prephitmp_168, alias_transform_entity
/* original r_alias.c:341: 	alias_transform_mode = currententity->trivial_accept; */
	movl	%esi, _aliascontrol_alias_transform_mode	# prephitmp_170, alias_transform_mode
/* original r_alias.c:343: 	return true; */
	movl	$1, %eax	#, <retval>
/* original r_alias.c:344: } */
	addl	$828, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	popl	%ebp	#
	ret
	.p2align 4
	.p2align 3
L40:
/* original r_alias.c:196: 		Con_DPrintf ("No such frame %d %s\n", frame, */
	pushl	%ecx	#
	movl	_aliascontrol_pmodel, %edi	# pmodel,
	pushl	%edi	#
	pushl	%ebp	# frame
	pushl	$LC3	#
	call	_Con_DPrintf	#
	addl	$16, %esp	#,
/* original r_alias.c:198: 		frame = 0; */
	xorl	%ebp, %ebp	# frame
	jmp	L41	#
	.p2align 4
	.p2align 3
L61:
/* original r_alias.c:247: 		return false;	// everything was near-z-clipped */
	xorl	%eax, %eax	# <retval>
/* original r_alias.c:344: } */
	addl	$828, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	popl	%ebp	#
	ret
	.p2align 4
	.p2align 3
L48:
/* original r_alias.c:288: 		clipresult = R_AliasCheckBBoxProject_asm486 (viewaux, viewpts, numv); */
	pushl	%eax	#
	pushl	$8	#
	leal	312(%esp), %esi	#, tmp766
	pushl	%esi	# tmp766
	leal	124(%esp), %ebx	#, tmp866
	pushl	%ebx	# tmp866
	call	_R_AliasCheckBBoxProject_asm486	#
	movzbl	%ah, %esi	# clipresult, prephitmp_170
/* original r_alias.c:322: 	if (allclip) */
	addl	$16, %esp	#,
	testb	$-1, %ah	#, clipresult
	jne	L61	#,
#if ASM486_ALIAS_MODEL_OCCLUSION
	pushl	%eax	# preserve clip flags
	call	_R_AliasModelOccluded	#
	testl	%eax, %eax	# occluded
	popl	%eax	# restore clip flags
	jne	L61	#,
#endif
/* original r_alias.c:325: 	currententity->trivial_accept = !anyclip & !zclipped; */
	movl	_currententity, %ecx	# currententity, prephitmp_168
/* original r_alias.c:325: 	currententity->trivial_accept = !anyclip & !zclipped; */
	andl	$255, %eax	#, anyclip
	sete	%bl	#, tmp769
	andl	$255, %ebx	#, tmp769
/* original r_alias.c:325: 	currententity->trivial_accept = !anyclip & !zclipped; */
	movl	%ebx, 172(%ecx)	# tmp769, currententity.7_52->trivial_accept
/* original r_alias.c:327: 	if (currententity->trivial_accept) */
	testl	%eax, %eax	# anyclip
	jne	L63	#,
/* original r_alias.c:329: 		if (minz > (r_aliastransition + (pmdl->size * r_resfudge))) */
	fildl	(%esp)	# %sfp
/* original r_alias.c:329: 		if (minz > (r_aliastransition + (pmdl->size * r_resfudge))) */
	movl	_pmdl, %ebp	# pmdl, pmdl
/* original r_alias.c:329: 		if (minz > (r_aliastransition + (pmdl->size * r_resfudge))) */
	flds	80(%ebp)	# pmdl.9_55->size
	fmuls	_r_resfudge	# r_resfudge
/* original r_alias.c:329: 		if (minz > (r_aliastransition + (pmdl->size * r_resfudge))) */
	fadds	_r_aliastransition	# r_aliastransition
	fxch	%st(1)		#
/* original r_alias.c:329: 		if (minz > (r_aliastransition + (pmdl->size * r_resfudge))) */
	fcompp
	fnstsw	%ax	# tmp776
	testb	$69, %ah	#, tmp776
	je	L78	#,
	movl	$1, %ecx	#, prephitmp_166
L64:
/* original r_alias.c:339: 		R_AliasSetUpTransform (currententity->trivial_accept); */
	subl	$12, %esp	#,
	pushl	%ecx	# prephitmp_166
	call	_R_AliasSetUpTransform	#
/* original r_alias.c:340: 	alias_transform_entity = currententity; */
	movl	_currententity, %ecx	# currententity, prephitmp_168
/* original r_alias.c:341: 	alias_transform_mode = currententity->trivial_accept; */
	movl	172(%ecx), %esi	# pretmp_167->trivial_accept, prephitmp_170
	addl	$16, %esp	#,
	jmp	L63	#
	.p2align 4
	.p2align 3
L78:
/* original r_alias.c:331: 			currententity->trivial_accept |= 2; */
	movl	$3, 172(%ecx)	#, currententity.7_52->trivial_accept
	movl	$3, %ecx	#, prephitmp_166
	jmp	L64	#
	.p2align 4
	.p2align 3
L67:
/* original r_alias.c:250: 	numv = 8; */
	movl	$8, %eax	#, numv
	jmp	L49	#
	.p2align 3
