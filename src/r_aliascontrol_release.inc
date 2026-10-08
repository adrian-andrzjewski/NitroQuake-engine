/* Alias control algorithm; release. Pinned source SHA256
 * BE6A06B767651363BD586FFF62BBA467F333D87820C13E7D66BF9D5A7B8FC979
 * One-time original schedule import; normal builds assemble this maintained file.
 * Cdecl, except R_AliasDrawModel receives its light pointer in EAX (regparm 1).
 * EBX/ESI/EDI/EBP are callee-owned; EAX/ECX/EDX and arithmetic flags are caller-owned.
 * Integer stores, x87 order, truncating CW changes and rounding stores are parity contracts. */

.text
.p2align 3
/* R_AliasPreparePoints: Transform clipped vertices, reject triangles by flag intersection and dispatch unclipped or clipped triangles in original order.
 * Saved callee registers used: %ebp, %ebx, %edi, %esi.
 * Stack reservations: 40, 12 bytes; all return paths restore ESP. */
	.globl	_R_AliasPreparePoints
_R_AliasPreparePoints:
	pushl	%ebp	#
	pushl	%edi	#
	pushl	%esi	#
	pushl	%ebx	#
	subl	$40, %esp	#,
/* original r_alias.c:441: 	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts); */
	movl	_paliashdr, %eax	# paliashdr, paliashdr.18_1
/* original r_alias.c:441: 	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts); */
	addl	4(%eax), %eax	# paliashdr.18_1->stverts, pstverts
/* original r_alias.c:442: 	r_anumverts = pmdl->numverts; */
	movl	_pmdl, %edx	# pmdl, pmdl
	movl	60(%edx), %ecx	# pmdl.20_4->numverts, _5
/* original r_alias.c:442: 	r_anumverts = pmdl->numverts; */
	movl	%ecx, _r_anumverts	# _5, r_anumverts
/* original r_alias.c:448: 	R_AliasPreparePointsVertices_asm486 (fv, av, r_apverts, pstverts, */
	pushl	%ecx	# _5
	pushl	%eax	# pstverts
	movl	_r_apverts, %ebx	# r_apverts,
	pushl	%ebx	#
	movl	_pauxverts, %esi	# pauxverts,
	pushl	%esi	#
	movl	_pfinalverts, %edi	# pfinalverts,
	pushl	%edi	#
	call	_R_AliasPreparePointsVertices_asm486	#
/* original r_alias.c:507: 	r_affinetridesc.numtriangles = 1; */
	movl	$1, _r_affinetridesc+24	#, r_affinetridesc.numtriangles
/* original r_alias.c:510: 	ptri = (mtriangle_t *)((byte *)paliashdr + paliashdr->triangles); */
	movl	_paliashdr, %ebx	# paliashdr, paliashdr.23_7
/* original r_alias.c:510: 	ptri = (mtriangle_t *)((byte *)paliashdr + paliashdr->triangles); */
	addl	12(%ebx), %ebx	# paliashdr.23_7->triangles, ptri
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	movl	_pmdl, %ebp	# pmdl, pmdl
	movl	64(%ebp), %ebp	# pmdl.29_52->numtris, prephitmp_97
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	addl	$32, %esp	#,
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	movl	$0, 12(%esp)	#, %sfp
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	testl	%ebp, %ebp	# prephitmp_97
	jg	L2	#,
	jmp	L1	#
	.p2align 4
	.p2align 3
L11:
/* original r_alias.c:523: 			r_affinetridesc.pfinalverts = pfinalverts; */
	movl	%edx, _r_affinetridesc+20	# pfinalverts.25_10, r_affinetridesc.pfinalverts
/* original r_alias.c:524: 			r_affinetridesc.ptriangles = ptri; */
	movl	%ebx, _r_affinetridesc+16	# ptri, r_affinetridesc.ptriangles
/* original r_alias.c:525: 			D_PolysetDraw (); */
	call	_D_PolysetDraw	#
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	movl	_pmdl, %edx	# pmdl, pmdl
	movl	64(%edx), %ebp	# pretmp_98->numtris, prephitmp_97
L3:
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	incl	12(%esp)	# %sfp
	movl	12(%esp), %eax	# %sfp, i
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	addl	$16, %ebx	#, ptri
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	cmpl	%ebp, %eax	# prephitmp_97, i
	jge	L1	#,
L2:
/* original r_alias.c:513: 		pfv[0] = &pfinalverts[ptri->vertindex[0]]; */
	movl	_pfinalverts, %edx	# pfinalverts, pfinalverts.25_10
/* original r_alias.c:517: 		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) */
	movl	4(%ebx), %eax	# MEM[(int *)ptri_58 + 4B], tmp128
	sall	$5, %eax	#, tmp128
	movl	24(%edx,%eax), %eax	# _14->flags, _23
/* original r_alias.c:517: 		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) */
	movl	8(%ebx), %ecx	# MEM[(int *)ptri_58 + 8B], tmp131
	sall	$5, %ecx	#, tmp131
	movl	24(%edx,%ecx), %edi	# _18->flags, _24
/* original r_alias.c:517: 		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) */
	movl	12(%ebx), %esi	# MEM[(int *)ptri_58 + 12B], tmp134
	sall	$5, %esi	#, tmp134
	movl	24(%edx,%esi), %esi	# _22->flags, _26
/* original r_alias.c:517: 		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) */
	movl	%eax, %ecx	# _23, tmp136
	andl	%esi, %ecx	# _26, tmp136
	andl	%edi, %ecx	# _24, tmp137
/* original r_alias.c:517: 		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) */
	andl	$31, %ecx	#, tmp137
	jne	L3	#,
/* original r_alias.c:520: 		if ( ! ( (pfv[0]->flags | pfv[1]->flags | pfv[2]->flags) & */
	orl	%edi, %eax	# _24, tmp139
/* original r_alias.c:520: 		if ( ! ( (pfv[0]->flags | pfv[1]->flags | pfv[2]->flags) & */
	orl	%esi, %eax	# _26, tmp140
/* original r_alias.c:520: 		if ( ! ( (pfv[0]->flags | pfv[1]->flags | pfv[2]->flags) & */
	testb	$31, %al	#, tmp140
	je	L11	#,
/* original r_alias.c:529: 			R_AliasClipTriangle (ptri); */
	subl	$12, %esp	#,
	pushl	%ebx	# ptri
	call	_R_AliasClipTriangle	#
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	movl	_pmdl, %ebp	# pmdl, pmdl
	movl	64(%ebp), %ebp	# pretmp_99->numtris, prephitmp_97
	addl	$16, %esp	#,
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	incl	12(%esp)	# %sfp
	movl	12(%esp), %eax	# %sfp, i
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	addl	$16, %ebx	#, ptri
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	cmpl	%ebp, %eax	# prephitmp_97, i
	jl	L2	#,
L1:
/* original r_alias.c:533: } */
	addl	$28, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	popl	%ebp	#
	ret
	.p2align 3

.text
.p2align 3
/* R_AliasPrepareUnclippedPoints: Transform/project vertices, optionally draw subdivision vertices and publish the full triangle batch.
 * Saved callee registers used: %ebx.
 * Stack reservations: 16, 8 bytes; all return paths restore ESP. */
	.globl	_R_AliasPrepareUnclippedPoints
_R_AliasPrepareUnclippedPoints:
	pushl	%ebx	#
	subl	$16, %esp	#,
/* original r_alias.c:821: 	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts); */
	movl	_paliashdr, %eax	# paliashdr, paliashdr.46_1
/* original r_alias.c:821: 	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts); */
	addl	4(%eax), %eax	# paliashdr.46_1->stverts, pstverts
/* original r_alias.c:822: 	r_anumverts = pmdl->numverts; */
	movl	_pmdl, %edx	# pmdl, pmdl
/* original r_alias.c:822: 	r_anumverts = pmdl->numverts; */
	movl	60(%edx), %ecx	# pmdl.48_4->numverts, pmdl.48_4->numverts
	movl	%ecx, _r_anumverts	# pmdl.48_4->numverts, r_anumverts
/* original r_alias.c:824: 	fv = pfinalverts; */
	movl	_pfinalverts, %ebx	# pfinalverts, fv
/* original r_alias.c:827: 	R_AliasTransformAndProjectFinalVerts (fv, pstverts); */
	pushl	%eax	# pstverts
	pushl	%ebx	# fv
	call	_R_AliasTransformAndProjectFinalVerts	#
/* original r_alias.c:830: 	if (r_affinetridesc.drawtype) */
	addl	$16, %esp	#,
	movl	_r_affinetridesc+28, %eax	# r_affinetridesc.drawtype,
	testl	%eax, %eax	#
	jne	L64	#,
L62:
/* original r_alias.c:833: 	r_affinetridesc.pfinalverts = pfinalverts; */
	movl	_pfinalverts, %ecx	# pfinalverts, pfinalverts
	movl	%ecx, _r_affinetridesc+20	# pfinalverts, r_affinetridesc.pfinalverts
/* original r_alias.c:835: 			((byte *)paliashdr + paliashdr->triangles); */
	movl	_paliashdr, %ebx	# paliashdr, paliashdr.51_9
/* original r_alias.c:834: 	r_affinetridesc.ptriangles = (mtriangle_t *) */
	addl	12(%ebx), %ebx	# paliashdr.51_9->triangles, tmp107
/* original r_alias.c:834: 	r_affinetridesc.ptriangles = (mtriangle_t *) */
	movl	%ebx, _r_affinetridesc+16	# tmp107, r_affinetridesc.ptriangles
/* original r_alias.c:836: 	r_affinetridesc.numtriangles = pmdl->numtris; */
	movl	_pmdl, %eax	# pmdl, pmdl
/* original r_alias.c:836: 	r_affinetridesc.numtriangles = pmdl->numtris; */
	movl	64(%eax), %edx	# pmdl.53_13->numtris, pmdl.53_13->numtris
	movl	%edx, _r_affinetridesc+24	# pmdl.53_13->numtris, r_affinetridesc.numtriangles
/* original r_alias.c:841: } */
	addl	$8, %esp	#,
	popl	%ebx	#
/* original r_alias.c:839: 	D_PolysetDraw (); */
	jmp	_D_PolysetDraw	#
	.p2align 4
	.p2align 3
L64:
/* original r_alias.c:831: 		D_PolysetDrawFinalVerts (fv, r_anumverts); */
	subl	$8, %esp	#,
	movl	_r_anumverts, %edx	# r_anumverts,
	pushl	%edx	#
	pushl	%ebx	# fv
	call	_D_PolysetDrawFinalVerts	#
	addl	$16, %esp	#,
	jmp	L62	#
	.p2align 2

.text
.p2align 3
/* R_AliasSetupSkin: Preserve invalid-skin fallback, animated selection and skin dimensions/seam correction.
 * Saved callee registers used: none.
 * Stack reservations: 12, 8 bytes; all return paths restore ESP. */
	.globl	_R_AliasSetupSkin
_R_AliasSetupSkin:
	subl	$12, %esp	#,
/* original r_alias.c:852: 	skinnum = currententity->skinnum; */
	movl	_currententity, %edx	# currententity, currententity.54_1
/* original r_alias.c:852: 	skinnum = currententity->skinnum; */
	movl	156(%edx), %eax	# currententity.54_1->skinnum, skinnum
/* original r_alias.c:853: 	if ((skinnum >= pmdl->numskins) || (skinnum < 0)) */
	movl	_pmdl, %ecx	# pmdl, pmdl
/* original r_alias.c:853: 	if ((skinnum >= pmdl->numskins) || (skinnum < 0)) */
	cmpl	%eax, 48(%ecx)	# skinnum, pmdl.55_2->numskins
	jle	L66	#,
/* original r_alias.c:853: 	if ((skinnum >= pmdl->numskins) || (skinnum < 0)) */
	testl	%eax, %eax	# skinnum
	js	L66	#,
L67:
/* original r_alias.c:860: 	pskindesc = R_AliasSetupSkinSelect_asm486 (skinnum, cl.time, */
	movl	144(%edx), %ecx	# prephitmp_33->syncbase,
	pushl	%ecx	#
	movl	_cl+576, %edx	# cl.time,
	pushl	%edx	#
	movl	_cl+572, %ecx	# cl.time,
	pushl	%ecx	#
	pushl	%eax	# skinnum
	call	_R_AliasSetupSkinSelect_asm486	#
/* Publish the original C assignment explicitly. The initial optimized listing
 * omitted this private pointer store; the independent state oracle retains it. */
	movl %eax,_aliascontrol_pskindesc
/* original r_alias.c:866: 	a_skinwidth = pmdl->skinwidth; */
	movl	_pmdl, %ecx	# pmdl, pmdl.57_8
	movl	52(%ecx), %edx	# pmdl.57_8->skinwidth, _9
/* original r_alias.c:866: 	a_skinwidth = pmdl->skinwidth; */
	movl	%edx, _a_skinwidth	# _9, a_skinwidth
/* original r_alias.c:868: 	r_affinetridesc.pskindesc = pskindesc; */
	movl	%eax, _r_affinetridesc+4	# _7, r_affinetridesc.pskindesc
/* original r_alias.c:869: 	r_affinetridesc.pskin = (void *)((byte *)paliashdr + pskindesc->skin); */
	movl	8(%eax), %eax	# _7->skin, _7->skin
	addl	_paliashdr, %eax	# paliashdr, tmp105
/* original r_alias.c:869: 	r_affinetridesc.pskin = (void *)((byte *)paliashdr + pskindesc->skin); */
	movl	%eax, _r_affinetridesc	# tmp105, r_affinetridesc.pskin
/* original r_alias.c:870: 	r_affinetridesc.skinwidth = a_skinwidth; */
	movl	%edx, _r_affinetridesc+8	# _9, r_affinetridesc.skinwidth
/* original r_alias.c:871: 	r_affinetridesc.seamfixupX16 =  (a_skinwidth >> 1) << 16; */
	sarl	$1, %edx	#, tmp110
/* original r_alias.c:871: 	r_affinetridesc.seamfixupX16 =  (a_skinwidth >> 1) << 16; */
	sall	$16, %edx	#, tmp111
	movl	%edx, _r_affinetridesc+32	# tmp111, r_affinetridesc.seamfixupX16
/* original r_alias.c:872: 	r_affinetridesc.skinheight = pmdl->skinheight; */
	movl	56(%ecx), %ecx	# pmdl.57_8->skinheight, pmdl.57_8->skinheight
	movl	%ecx, _r_affinetridesc+12	# pmdl.57_8->skinheight, r_affinetridesc.skinheight
/* original r_alias.c:873: } */
	addl	$28, %esp	#,
	ret
	.p2align 4
	.p2align 3
L66:
/* original r_alias.c:855: 		Con_DPrintf ("R_AliasSetupSkin: no such skin # %d\n", skinnum); */
	subl	$8, %esp	#,
	pushl	%eax	# skinnum
	pushl	$LC5	#
	call	_Con_DPrintf	#
/* original r_alias.c:861: 			currententity->syncbase); */
	movl	_currententity, %edx	# currententity, currententity.54_1
	addl	$16, %esp	#,
/* original r_alias.c:856: 		skinnum = 0; */
	xorl	%eax, %eax	# skinnum
	jmp	L67	#
	.p2align 3

.text
.p2align 3
/* R_AliasSetupLighting: Pass the original model basis and light descriptor to the accepted lighting primitive.
 * Saved callee registers used: none.
 * Stack reservations: 12 bytes; all return paths restore ESP. */
	.globl	_R_AliasSetupLighting
_R_AliasSetupLighting:
	subl	$12, %esp	#,
/* original r_alias.c:960: 	R_AliasSetupLighting_asm486 (plighting, alias_forward, alias_right, */
	pushl	$_aliascontrol_alias_up	#
	pushl	$_aliascontrol_alias_right	#
	pushl	$_aliascontrol_alias_forward	#
	movl	28(%esp), %eax	# plighting,
	pushl	%eax	#
	call	_R_AliasSetupLighting_asm486	#
/* original r_alias.c:965: } */
	addl	$28, %esp	#,
	ret
	.p2align 3

.text
.p2align 3
/* R_AliasSetupFrame: Preserve invalid-frame fallback and animated frame selection at client time plus sync base.
 * Saved callee registers used: none.
 * Stack reservations: 12, 8 bytes; all return paths restore ESP. */
	.globl	_R_AliasSetupFrame
_R_AliasSetupFrame:
	subl	$12, %esp	#,
/* original r_alias.c:1019: 	frame = currententity->frame; */
	movl	_currententity, %edx	# currententity, currententity.85_1
/* original r_alias.c:1019: 	frame = currententity->frame; */
	movl	140(%edx), %eax	# currententity.85_1->frame, frame
/* original r_alias.c:1020: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	movl	_pmdl, %ecx	# pmdl, pmdl
/* original r_alias.c:1020: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	cmpl	%eax, 68(%ecx)	# frame, pmdl.86_2->numframes
	jle	L106	#,
/* original r_alias.c:1020: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	testl	%eax, %eax	# frame
	js	L106	#,
L107:
/* original r_alias.c:1027: 	R_AliasSetupFrame_asm486 (frame, cl.time, currententity->syncbase); */
	movl	144(%edx), %ecx	# prephitmp_13->syncbase,
	pushl	%ecx	#
	movl	_cl+576, %edx	# cl.time,
	pushl	%edx	#
	movl	_cl+572, %ecx	# cl.time,
	pushl	%ecx	#
	pushl	%eax	# frame
	call	_R_AliasSetupFrame_asm486	#
/* original r_alias.c:1031: } */
	addl	$28, %esp	#,
	ret
	.p2align 4
	.p2align 3
L106:
/* original r_alias.c:1022: 		Con_DPrintf ("R_AliasSetupFrame: no such frame %d\n", frame); */
	subl	$8, %esp	#,
	pushl	%eax	# frame
	pushl	$LC8	#
	call	_Con_DPrintf	#
/* original r_alias.c:1027: 	R_AliasSetupFrame_asm486 (frame, cl.time, currententity->syncbase); */
	movl	_currententity, %edx	# currententity, currententity.85_1
	addl	$16, %esp	#,
/* original r_alias.c:1023: 		frame = 0; */
	xorl	%eax, %eax	# frame
	jmp	L107	#
	.p2align 2

.text
.p2align 3
/* R_AliasDrawModel: Retain aligned stack scratch, transform cache, setup order, colormap patching, depth scaling and triangle dispatch.
 * Saved callee registers used: %ebx.
 * Stack reservations: 88040, 12, 12, 12, 8, 8, 8, 12 bytes; all return paths restore ESP. */
	.globl	_R_AliasDrawModel
_R_AliasDrawModel:
	pushl	%ebx	#
	subl	$88040, %esp	#,
	movl	%eax, %ebx	# tmp158, plighting
/* original r_alias.c:1054: 	r_amodels_drawn++; */
	incl	_r_amodels_drawn	# r_amodels_drawn
/* original r_alias.c:1063: 			(((long)&finalverts[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1)); */
	leal	24031(%esp), %eax	#, tmp131
/* original r_alias.c:1063: 			(((long)&finalverts[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1)); */
	andl	$-32, %eax	#, tmp132
	movl	%eax, _pfinalverts	# tmp132, pfinalverts
/* original r_alias.c:1064: 	pauxverts = &auxverts[0]; */
	movl	%esp, _pauxverts	#, pauxverts
/* original r_alias.c:1066: 	paliashdr = (aliashdr_t *)Mod_Extradata (currententity->model); */
	subl	$12, %esp	#,
/* original r_alias.c:1066: 	paliashdr = (aliashdr_t *)Mod_Extradata (currententity->model); */
	movl	_currententity, %edx	# currententity, currententity
/* original r_alias.c:1066: 	paliashdr = (aliashdr_t *)Mod_Extradata (currententity->model); */
	movl	132(%edx), %ecx	# currententity.89_7->model,
	pushl	%ecx	#
	call	_Mod_Extradata	#
/* original r_alias.c:1066: 	paliashdr = (aliashdr_t *)Mod_Extradata (currententity->model); */
	movl	%eax, _paliashdr	# _9, paliashdr
/* original r_alias.c:1067: 	pmdl = (mdl_t *)((byte *)paliashdr + paliashdr->model); */
	addl	(%eax), %eax	# MEM[(struct aliashdr_t *)_9].model, tmp137
/* original r_alias.c:1067: 	pmdl = (mdl_t *)((byte *)paliashdr + paliashdr->model); */
	movl	%eax, _pmdl	# tmp137, pmdl
/* original r_alias.c:1077: 	R_AliasSetupSkin (); */
	call	_R_AliasSetupSkin	#
/* original r_alias.c:1078: 	if (alias_transform_entity != currententity || */
	movl	_currententity, %eax	# currententity, currententity.93_14
/* original r_alias.c:1078: 	if (alias_transform_entity != currententity || */
	addl	$16, %esp	#,
	cmpl	%eax, _aliascontrol_alias_transform_entity	# currententity.93_14, alias_transform_entity
/* original r_alias.c:1079: 			alias_transform_mode != currententity->trivial_accept) */
	movl	172(%eax), %edx	# currententity.93_14->trivial_accept, _15
/* original r_alias.c:1078: 	if (alias_transform_entity != currententity || */
	je	L110	#,
L111:
/* original r_alias.c:1080: 		R_AliasSetUpTransform (currententity->trivial_accept); */
	subl	$12, %esp	#,
	pushl	%edx	# _15
	call	_R_AliasSetUpTransform	#
	addl	$16, %esp	#,
L112:
/* original r_alias.c:1081: 	alias_transform_entity = NULL; */
	movl	$0, _aliascontrol_alias_transform_entity	#, alias_transform_entity
/* original r_alias.c:960: 	R_AliasSetupLighting_asm486 (plighting, alias_forward, alias_right, */
	pushl	$_aliascontrol_alias_up	#
	pushl	$_aliascontrol_alias_right	#
	pushl	$_aliascontrol_alias_forward	#
	pushl	%ebx	# plighting
	call	_R_AliasSetupLighting_asm486	#
/* original r_alias.c:1019: 	frame = currententity->frame; */
	movl	_currententity, %ecx	# currententity, currententity.85_57
/* original r_alias.c:1019: 	frame = currententity->frame; */
	movl	140(%ecx), %eax	# currententity.85_57->frame, frame
/* original r_alias.c:1020: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	addl	$16, %esp	#,
	movl	_pmdl, %ebx	# pmdl, pmdl
	cmpl	68(%ebx), %eax	# pmdl.86_59->numframes, frame
	jge	L113	#,
/* original r_alias.c:1020: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	testl	%eax, %eax	# frame
	js	L113	#,
L114:
/* original r_alias.c:1027: 	R_AliasSetupFrame_asm486 (frame, cl.time, currententity->syncbase); */
	movl	144(%ecx), %edx	# prephitmp_111->syncbase,
	pushl	%edx	#
	movl	_cl+576, %ebx	# cl.time,
	pushl	%ebx	#
	movl	_cl+572, %ecx	# cl.time,
	pushl	%ecx	#
	pushl	%eax	# frame
	call	_R_AliasSetupFrame_asm486	#
/* original r_alias.c:1085: 	if (!currententity->colormap) */
	movl	_currententity, %eax	# currententity, currententity.97_18
/* original r_alias.c:1085: 	if (!currententity->colormap) */
	addl	$16, %esp	#,
	movl	148(%eax), %edx	# currententity.97_18->colormap,
	testl	%edx, %edx	#
	je	L124	#,
L115:
/* original r_alias.c:1088: 	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) && */
	cmpl	$3, 172(%eax)	#, prephitmp_113->trivial_accept
	je	L125	#,
L116:
/* original r_alias.c:1088: 	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) && */
	movl	$0, _r_affinetridesc+28	#, r_affinetridesc.drawtype
/* original r_alias.c:1098: 		D_Aff8Patch (currententity->colormap); */
	subl	$12, %esp	#,
	movl	148(%eax), %ecx	# prephitmp_113->colormap,
	pushl	%ecx	#
	call	_D_Aff8Patch	#
	addl	$16, %esp	#,
L117:
/* original r_alias.c:1102: 	acolormap = currententity->colormap; */
	movl	_currententity, %eax	# currententity, currententity.102_24
/* original r_alias.c:1102: 	acolormap = currententity->colormap; */
	movl	148(%eax), %edx	# currententity.102_24->colormap, currententity.102_24->colormap
	movl	%edx, _acolormap	# currententity.102_24->colormap, acolormap
/* original r_alias.c:1104: 	if (currententity != &cl.viewent) */
	cmpl	$_cl+2708, %eax	#, currententity.102_24
	je	L122	#,
/* original r_alias.c:1105: 		ziscale = (float)0x8000 * (float)0x10000; */
	flds	LC9	#
L118:
	fstps	_ziscale	# ziscale
/* original r_alias.c:1110: 	if (currententity->trivial_accept) */
	movl	172(%eax), %ebx	# currententity.102_24->trivial_accept,
	testl	%ebx, %ebx	#
	je	L119	#,
/* original r_alias.c:821: 	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts); */
	movl	_paliashdr, %ecx	# paliashdr, paliashdr.46_65
/* original r_alias.c:821: 	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts); */
	addl	4(%ecx), %ecx	# paliashdr.46_65->stverts, pstverts
/* original r_alias.c:822: 	r_anumverts = pmdl->numverts; */
	movl	_pmdl, %eax	# pmdl, pmdl
/* original r_alias.c:822: 	r_anumverts = pmdl->numverts; */
	movl	60(%eax), %edx	# pmdl.48_69->numverts, pmdl.48_69->numverts
	movl	%edx, _r_anumverts	# pmdl.48_69->numverts, r_anumverts
/* original r_alias.c:824: 	fv = pfinalverts; */
	movl	_pfinalverts, %ebx	# pfinalverts, fv
/* original r_alias.c:827: 	R_AliasTransformAndProjectFinalVerts (fv, pstverts); */
	subl	$8, %esp	#,
	pushl	%ecx	# pstverts
	pushl	%ebx	# fv
	call	_R_AliasTransformAndProjectFinalVerts	#
/* original r_alias.c:830: 	if (r_affinetridesc.drawtype) */
	addl	$16, %esp	#,
	movl	_r_affinetridesc+28, %ecx	# r_affinetridesc.drawtype,
	testl	%ecx, %ecx	#
	jne	L126	#,
L120:
/* original r_alias.c:833: 	r_affinetridesc.pfinalverts = pfinalverts; */
	movl	_pfinalverts, %edx	# pfinalverts, pfinalverts
	movl	%edx, _r_affinetridesc+20	# pfinalverts, r_affinetridesc.pfinalverts
/* original r_alias.c:835: 			((byte *)paliashdr + paliashdr->triangles); */
	movl	_paliashdr, %ebx	# paliashdr, paliashdr.51_75
/* original r_alias.c:834: 	r_affinetridesc.ptriangles = (mtriangle_t *) */
	addl	12(%ebx), %ebx	# paliashdr.51_75->triangles, tmp153
/* original r_alias.c:834: 	r_affinetridesc.ptriangles = (mtriangle_t *) */
	movl	%ebx, _r_affinetridesc+16	# tmp153, r_affinetridesc.ptriangles
/* original r_alias.c:836: 	r_affinetridesc.numtriangles = pmdl->numtris; */
	movl	_pmdl, %ecx	# pmdl, pmdl
/* original r_alias.c:836: 	r_affinetridesc.numtriangles = pmdl->numtris; */
	movl	64(%ecx), %eax	# pmdl.53_79->numtris, pmdl.53_79->numtris
	movl	%eax, _r_affinetridesc+24	# pmdl.53_79->numtris, r_affinetridesc.numtriangles
/* original r_alias.c:839: 	D_PolysetDraw (); */
	call	_D_PolysetDraw	#
/* original r_alias.c:1120: } */
	addl	$88040, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L113:
/* original r_alias.c:1022: 		Con_DPrintf ("R_AliasSetupFrame: no such frame %d\n", frame); */
	subl	$8, %esp	#,
	pushl	%eax	# frame
	pushl	$LC8	#
	call	_Con_DPrintf	#
/* original r_alias.c:1027: 	R_AliasSetupFrame_asm486 (frame, cl.time, currententity->syncbase); */
	movl	_currententity, %ecx	# currententity, currententity.85_57
	addl	$16, %esp	#,
/* original r_alias.c:1023: 		frame = 0; */
	xorl	%eax, %eax	# frame
	jmp	L114	#
	.p2align 4
	.p2align 3
L119:
/* original r_alias.c:1113: 		R_AliasPreparePoints (); */
	call	_R_AliasPreparePoints	#
/* original r_alias.c:1120: } */
	addl	$88040, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L110:
/* original r_alias.c:1078: 	if (alias_transform_entity != currententity || */
	cmpl	_aliascontrol_alias_transform_mode, %edx	# alias_transform_mode, _15
	jne	L111	#,
	jmp	L112	#
	.p2align 4
	.p2align 3
L125:
/* original r_alias.c:1088: 	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) && */
	movl	_r_recursiveaffinetriangles, %ebx	# r_recursiveaffinetriangles,
	testl	%ebx, %ebx	#
	je	L116	#,
/* original r_alias.c:1088: 	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) && */
	movl	$1, _r_affinetridesc+28	#, r_affinetridesc.drawtype
/* original r_alias.c:1093: 		D_PolysetUpdateTables ();		// FIXME: precalc... */
	call	_D_PolysetUpdateTables	#
	jmp	L117	#
	.p2align 4
	.p2align 3
L122:
/* original r_alias.c:1107: 		ziscale = (float)0x8000 * (float)0x10000 * 3.0; */
	flds	LC10	#
	jmp	L118	#
	.p2align 4
	.p2align 3
L126:
/* original r_alias.c:831: 		D_PolysetDrawFinalVerts (fv, r_anumverts); */
	subl	$8, %esp	#,
	movl	_r_anumverts, %eax	# r_anumverts,
	pushl	%eax	#
	pushl	%ebx	# fv
	call	_D_PolysetDrawFinalVerts	#
	addl	$16, %esp	#,
	jmp	L120	#
	.p2align 4
	.p2align 3
L124:
/* original r_alias.c:1086: 		Sys_Error ("R_AliasDrawModel: !currententity->colormap"); */
	subl	$12, %esp	#,
	pushl	$LC11	#
	call	_Sys_Error	#
/* original r_alias.c:1088: 	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) && */
	movl	_currententity, %eax	# currententity, currententity.97_18
	addl	$16, %esp	#,
	jmp	L115	#
