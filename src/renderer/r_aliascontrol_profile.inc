/* Alias control algorithm; profile. Pinned source SHA256
 * BE6A06B767651363BD586FFF62BBA467F333D87820C13E7D66BF9D5A7B8FC979
 * One-time original schedule import; normal builds assemble this maintained file.
 * Cdecl, except R_AliasDrawModel receives its light pointer in EAX (regparm 1).
 * EBX/ESI/EDI/EBP are callee-owned; EAX/ECX/EDX and arithmetic flags are caller-owned.
 * Integer stores, x87 order, truncating CW changes and rounding stores are parity contracts. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */

.text
.p2align 3
/* R_AliasPreparePoints: Transform clipped vertices, reject triangles by flag intersection and dispatch unclipped or clipped triangles in original order.
 * Saved callee registers used: %ebp, %ebx, %edi, %esi.
 * Stack reservations: 40, 12, 12 bytes; all return paths restore ESP. */
	.globl	_R_AliasPreparePoints
_R_AliasPreparePoints:
	pushl	%ebp	#
	pushl	%edi	#
	pushl	%esi	#
	pushl	%ebx	#
	subl	$40, %esp	#,
/* original r_alias.c:441: 	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts); */
	movl	_paliashdr, %ebx	# paliashdr, paliashdr.28_1
/* original r_alias.c:441: 	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts); */
	addl	4(%ebx), %ebx	# paliashdr.28_1->stverts, paliashdr.28_1
/* original r_alias.c:442: 	r_anumverts = pmdl->numverts; */
	movl	_pmdl, %eax	# pmdl, pmdl
/* original r_alias.c:442: 	r_anumverts = pmdl->numverts; */
	movl	60(%eax), %edx	# pmdl.30_4->numverts, pmdl.30_4->numverts
	movl	%edx, _r_anumverts	# pmdl.30_4->numverts, r_anumverts
/* original r_alias.c:443:  	fv = pfinalverts; */
	movl	_pfinalverts, %esi	# pfinalverts, fv
/* original r_alias.c:444: 	av = pauxverts; */
	movl	_pauxverts, %edi	# pauxverts, av
/* original r_alias.c:446: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_TRANSFORM); */
	pushl	$26	#
	call	_Bench486ProfileEnter	#
/* original r_alias.c:448: 	R_AliasPreparePointsVertices_asm486 (fv, av, r_apverts, pstverts, */
	popl	%eax	#
	movl	_r_anumverts, %ecx	# r_anumverts,
	pushl	%ecx	#
	pushl	%ebx	# pstverts
	movl	_r_apverts, %ebp	# r_apverts,
	pushl	%ebp	#
	pushl	%edi	# av
	pushl	%esi	# fv
	call	_R_AliasPreparePointsVertices_asm486	#
/* original r_alias.c:502: 	BENCH486_PROFILE_LEAVE (); */
	addl	$32, %esp	#,
	call	_Bench486ProfileLeave	#
/* original r_alias.c:507: 	r_affinetridesc.numtriangles = 1; */
	movl	$1, _r_affinetridesc+24	#, r_affinetridesc.numtriangles
/* original r_alias.c:509: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_RASTER); */
	subl	$12, %esp	#,
	pushl	$27	#
	call	_Bench486ProfileEnter	#
/* original r_alias.c:510: 	ptri = (mtriangle_t *)((byte *)paliashdr + paliashdr->triangles); */
	movl	_paliashdr, %ebx	# paliashdr, paliashdr.33_8
/* original r_alias.c:510: 	ptri = (mtriangle_t *)((byte *)paliashdr + paliashdr->triangles); */
	addl	12(%ebx), %ebx	# paliashdr.33_8->triangles, ptri
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	movl	_pmdl, %eax	# pmdl, pmdl
	movl	64(%eax), %ebp	# pmdl.39_57->numtris, prephitmp_102
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	addl	$16, %esp	#,
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	movl	$0, 12(%esp)	#, %sfp
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	testl	%ebp, %ebp	# prephitmp_102
	jg	L23	#,
	jmp	L26	#
	.p2align 4
	.p2align 3
L32:
/* original r_alias.c:523: 			r_affinetridesc.pfinalverts = pfinalverts; */
	movl	%edx, _r_affinetridesc+20	# pfinalverts.35_11, r_affinetridesc.pfinalverts
/* original r_alias.c:524: 			r_affinetridesc.ptriangles = ptri; */
	movl	%ebx, _r_affinetridesc+16	# ptri, r_affinetridesc.ptriangles
/* original r_alias.c:525: 			D_PolysetDraw (); */
	call	_D_PolysetDraw	#
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	movl	_pmdl, %edx	# pmdl, pmdl
	movl	64(%edx), %ebp	# pretmp_103->numtris, prephitmp_102
L24:
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	incl	12(%esp)	# %sfp
	movl	12(%esp), %eax	# %sfp, i
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	addl	$16, %ebx	#, ptri
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	cmpl	%ebp, %eax	# prephitmp_102, i
	jge	L26	#,
L23:
/* original r_alias.c:513: 		pfv[0] = &pfinalverts[ptri->vertindex[0]]; */
	movl	_pfinalverts, %edx	# pfinalverts, pfinalverts.35_11
/* original r_alias.c:517: 		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) */
	movl	4(%ebx), %esi	# MEM[(int *)ptri_63 + 4B], tmp130
	sall	$5, %esi	#, tmp130
	movl	24(%edx,%esi), %eax	# _15->flags, _24
/* original r_alias.c:517: 		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) */
	movl	8(%ebx), %edi	# MEM[(int *)ptri_63 + 8B], tmp133
	sall	$5, %edi	#, tmp133
	movl	24(%edx,%edi), %edi	# _19->flags, _25
/* original r_alias.c:517: 		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) */
	movl	12(%ebx), %ecx	# MEM[(int *)ptri_63 + 12B], tmp136
	sall	$5, %ecx	#, tmp136
	movl	24(%edx,%ecx), %esi	# _23->flags, _27
/* original r_alias.c:517: 		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) */
	movl	%eax, %ecx	# _24, tmp138
	andl	%esi, %ecx	# _27, tmp138
	andl	%edi, %ecx	# _25, tmp139
/* original r_alias.c:517: 		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) */
	andl	$31, %ecx	#, tmp139
	jne	L24	#,
/* original r_alias.c:520: 		if ( ! ( (pfv[0]->flags | pfv[1]->flags | pfv[2]->flags) & */
	orl	%edi, %eax	# _25, tmp141
/* original r_alias.c:520: 		if ( ! ( (pfv[0]->flags | pfv[1]->flags | pfv[2]->flags) & */
	orl	%esi, %eax	# _27, tmp142
/* original r_alias.c:520: 		if ( ! ( (pfv[0]->flags | pfv[1]->flags | pfv[2]->flags) & */
	testb	$31, %al	#, tmp142
	je	L32	#,
/* original r_alias.c:529: 			R_AliasClipTriangle (ptri); */
	subl	$12, %esp	#,
	pushl	%ebx	# ptri
	call	_R_AliasClipTriangle	#
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	movl	_pmdl, %ebp	# pmdl, pmdl
	movl	64(%ebp), %ebp	# pretmp_104->numtris, prephitmp_102
	addl	$16, %esp	#,
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	incl	12(%esp)	# %sfp
	movl	12(%esp), %eax	# %sfp, i
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	addl	$16, %ebx	#, ptri
/* original r_alias.c:511: 	for (i=0 ; i<pmdl->numtris ; i++, ptri++) */
	cmpl	%ebp, %eax	# prephitmp_102, i
	jl	L23	#,
L26:
/* original r_alias.c:533: } */
	addl	$28, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	popl	%ebp	#
/* original r_alias.c:532: 	BENCH486_PROFILE_LEAVE (); */
	jmp	_Bench486ProfileLeave	#
	.p2align 3

.text
.p2align 3
/* R_AliasPrepareUnclippedPoints: Transform/project vertices, optionally draw subdivision vertices and publish the full triangle batch.
 * Saved callee registers used: %ebx, %esi.
 * Stack reservations: 16, 12, 8 bytes; all return paths restore ESP. */
	.globl	_R_AliasPrepareUnclippedPoints
_R_AliasPrepareUnclippedPoints:
	pushl	%esi	#
	pushl	%ebx	#
	subl	$16, %esp	#,
/* original r_alias.c:821: 	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts); */
	movl	_paliashdr, %ebx	# paliashdr, paliashdr.57_1
/* original r_alias.c:821: 	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts); */
	addl	4(%ebx), %ebx	# paliashdr.57_1->stverts, paliashdr.57_1
/* original r_alias.c:822: 	r_anumverts = pmdl->numverts; */
	movl	_pmdl, %eax	# pmdl, pmdl
/* original r_alias.c:822: 	r_anumverts = pmdl->numverts; */
	movl	60(%eax), %edx	# pmdl.59_4->numverts, pmdl.59_4->numverts
	movl	%edx, _r_anumverts	# pmdl.59_4->numverts, r_anumverts
/* original r_alias.c:824: 	fv = pfinalverts; */
	movl	_pfinalverts, %esi	# pfinalverts, fv
/* original r_alias.c:826: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_TRANSFORM); */
	pushl	$26	#
	call	_Bench486ProfileEnter	#
/* original r_alias.c:827: 	R_AliasTransformAndProjectFinalVerts (fv, pstverts); */
	popl	%edx	#
	popl	%ecx	#
	pushl	%ebx	# pstverts
	pushl	%esi	# fv
	call	_R_AliasTransformAndProjectFinalVerts	#
/* original r_alias.c:828: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* original r_alias.c:830: 	if (r_affinetridesc.drawtype) */
	addl	$16, %esp	#,
	movl	_r_affinetridesc+28, %ecx	# r_affinetridesc.drawtype,
	testl	%ecx, %ecx	#
	jne	L92	#,
L90:
/* original r_alias.c:833: 	r_affinetridesc.pfinalverts = pfinalverts; */
	movl	_pfinalverts, %eax	# pfinalverts, pfinalverts
	movl	%eax, _r_affinetridesc+20	# pfinalverts, r_affinetridesc.pfinalverts
/* original r_alias.c:835: 			((byte *)paliashdr + paliashdr->triangles); */
	movl	_paliashdr, %edx	# paliashdr, paliashdr.62_9
/* original r_alias.c:834: 	r_affinetridesc.ptriangles = (mtriangle_t *) */
	addl	12(%edx), %edx	# paliashdr.62_9->triangles, tmp107
/* original r_alias.c:834: 	r_affinetridesc.ptriangles = (mtriangle_t *) */
	movl	%edx, _r_affinetridesc+16	# tmp107, r_affinetridesc.ptriangles
/* original r_alias.c:836: 	r_affinetridesc.numtriangles = pmdl->numtris; */
	movl	_pmdl, %esi	# pmdl, pmdl
/* original r_alias.c:836: 	r_affinetridesc.numtriangles = pmdl->numtris; */
	movl	64(%esi), %ecx	# pmdl.64_13->numtris, pmdl.64_13->numtris
	movl	%ecx, _r_affinetridesc+24	# pmdl.64_13->numtris, r_affinetridesc.numtriangles
/* original r_alias.c:838: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_RASTER); */
	subl	$12, %esp	#,
	pushl	$27	#
	call	_Bench486ProfileEnter	#
/* original r_alias.c:839: 	D_PolysetDraw (); */
	call	_D_PolysetDraw	#
/* original r_alias.c:841: } */
	addl	$20, %esp	#,
	popl	%ebx	#
	popl	%esi	#
/* original r_alias.c:840: 	BENCH486_PROFILE_LEAVE (); */
	jmp	_Bench486ProfileLeave	#
	.p2align 4
	.p2align 3
L92:
/* original r_alias.c:831: 		D_PolysetDrawFinalVerts (fv, r_anumverts); */
	subl	$8, %esp	#,
	movl	_r_anumverts, %ebx	# r_anumverts,
	pushl	%ebx	#
	pushl	%esi	# fv
	call	_D_PolysetDrawFinalVerts	#
	addl	$16, %esp	#,
	jmp	L90	#
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
	movl	_currententity, %edx	# currententity, currententity.65_1
/* original r_alias.c:852: 	skinnum = currententity->skinnum; */
	movl	156(%edx), %eax	# currententity.65_1->skinnum, skinnum
/* original r_alias.c:853: 	if ((skinnum >= pmdl->numskins) || (skinnum < 0)) */
	movl	_pmdl, %ecx	# pmdl, pmdl
/* original r_alias.c:853: 	if ((skinnum >= pmdl->numskins) || (skinnum < 0)) */
	cmpl	%eax, 48(%ecx)	# skinnum, pmdl.66_2->numskins
	jle	L94	#,
/* original r_alias.c:853: 	if ((skinnum >= pmdl->numskins) || (skinnum < 0)) */
	testl	%eax, %eax	# skinnum
	js	L94	#,
L95:
/* original r_alias.c:860: 	pskindesc = R_AliasSetupSkinSelect_asm486 (skinnum, cl.time, */
	movl	144(%edx), %ecx	# prephitmp_33->syncbase,
	pushl	%ecx	#
	movl	_cl+576, %edx	# cl.time,
	pushl	%edx	#
	movl	_cl+572, %ecx	# cl.time,
	pushl	%ecx	#
	pushl	%eax	# skinnum
	call	_R_AliasSetupSkinSelect_asm486	#
/* Retain the private pointer assignment from the original C algorithm. */
	movl %eax,_aliascontrol_pskindesc
/* original r_alias.c:866: 	a_skinwidth = pmdl->skinwidth; */
	movl	_pmdl, %ecx	# pmdl, pmdl.68_8
	movl	52(%ecx), %edx	# pmdl.68_8->skinwidth, _9
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
	movl	56(%ecx), %ecx	# pmdl.68_8->skinheight, pmdl.68_8->skinheight
	movl	%ecx, _r_affinetridesc+12	# pmdl.68_8->skinheight, r_affinetridesc.skinheight
/* original r_alias.c:873: } */
	addl	$28, %esp	#,
	ret
	.p2align 4
	.p2align 3
L94:
/* original r_alias.c:855: 		Con_DPrintf ("R_AliasSetupSkin: no such skin # %d\n", skinnum); */
	subl	$8, %esp	#,
	pushl	%eax	# skinnum
	pushl	$LC5	#
	call	_Con_DPrintf	#
/* original r_alias.c:861: 			currententity->syncbase); */
	movl	_currententity, %edx	# currententity, currententity.65_1
	addl	$16, %esp	#,
/* original r_alias.c:856: 		skinnum = 0; */
	xorl	%eax, %eax	# skinnum
	jmp	L95	#
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
	movl	_currententity, %edx	# currententity, currententity.96_1
/* original r_alias.c:1019: 	frame = currententity->frame; */
	movl	140(%edx), %eax	# currententity.96_1->frame, frame
/* original r_alias.c:1020: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	movl	_pmdl, %ecx	# pmdl, pmdl
/* original r_alias.c:1020: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	cmpl	%eax, 68(%ecx)	# frame, pmdl.97_2->numframes
	jle	L134	#,
/* original r_alias.c:1020: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	testl	%eax, %eax	# frame
	js	L134	#,
L135:
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
L134:
/* original r_alias.c:1022: 		Con_DPrintf ("R_AliasSetupFrame: no such frame %d\n", frame); */
	subl	$8, %esp	#,
	pushl	%eax	# frame
	pushl	$LC8	#
	call	_Con_DPrintf	#
/* original r_alias.c:1027: 	R_AliasSetupFrame_asm486 (frame, cl.time, currententity->syncbase); */
	movl	_currententity, %edx	# currententity, currententity.96_1
	addl	$16, %esp	#,
/* original r_alias.c:1023: 		frame = 0; */
	xorl	%eax, %eax	# frame
	jmp	L135	#
	.p2align 2

.text
.p2align 3
/* R_AliasDrawModel: Retain aligned stack scratch, transform cache, setup order, colormap patching, depth scaling and triangle dispatch.
 * Saved callee registers used: %ebx.
 * Stack reservations: 88068, 12, 12, 12, 8, 12 bytes; all return paths restore ESP. */
	.globl	_R_AliasDrawModel
_R_AliasDrawModel:
	pushl	%ebx	#
	subl	$88068, %esp	#,
	movl	%eax, %ebx	# tmp149, plighting
/* original r_alias.c:1047: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_MODEL); */
	pushl	$24	#
	call	_Bench486ProfileEnter	#
/* original r_alias.c:1050: 	if (bench486_profile_frame_active) */
	addl	$16, %esp	#,
	movl	_bench486_profile_frame_active, %eax	# bench486_profile_frame_active,
	testl	%eax, %eax	#
	jne	L138	#,
/* original r_alias.c:1054: 	r_amodels_drawn++; */
	incl	_r_amodels_drawn	# r_amodels_drawn
L139:
/* original r_alias.c:1063: 			(((long)&finalverts[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1)); */
	leal	24047(%esp), %edx	#, tmp134
/* original r_alias.c:1063: 			(((long)&finalverts[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1)); */
	andl	$-32, %edx	#, tmp135
	movl	%edx, _pfinalverts	# tmp135, pfinalverts
/* original r_alias.c:1064: 	pauxverts = &auxverts[0]; */
	leal	16(%esp), %eax	#, tmp161
	movl	%eax, _pauxverts	# tmp161, pauxverts
/* original r_alias.c:1066: 	paliashdr = (aliashdr_t *)Mod_Extradata (currententity->model); */
	subl	$12, %esp	#,
/* original r_alias.c:1066: 	paliashdr = (aliashdr_t *)Mod_Extradata (currententity->model); */
	movl	_currententity, %ecx	# currententity, currententity
/* original r_alias.c:1066: 	paliashdr = (aliashdr_t *)Mod_Extradata (currententity->model); */
	movl	132(%ecx), %edx	# currententity.103_11->model,
	pushl	%edx	#
	call	_Mod_Extradata	#
/* original r_alias.c:1066: 	paliashdr = (aliashdr_t *)Mod_Extradata (currententity->model); */
	movl	%eax, _paliashdr	# _13, paliashdr
/* original r_alias.c:1067: 	pmdl = (mdl_t *)((byte *)paliashdr + paliashdr->model); */
	addl	(%eax), %eax	# MEM[(struct aliashdr_t *)_13].model, _16
/* original r_alias.c:1067: 	pmdl = (mdl_t *)((byte *)paliashdr + paliashdr->model); */
	movl	%eax, _pmdl	# _16, pmdl
/* original r_alias.c:1070: 	if (bench486_profile_frame_active) */
	addl	$16, %esp	#,
/* original r_alias.c:1071: 		bench486_alias_vertices += pmdl->numverts; */
	movl	60(%eax), %eax	# _16->numverts, _114
/* original r_alias.c:1070: 	if (bench486_profile_frame_active) */
	movl	_bench486_profile_frame_active, %ecx	# bench486_profile_frame_active,
	testl	%ecx, %ecx	#
	je	L143	#,
/* original r_alias.c:1071: 		bench486_alias_vertices += pmdl->numverts; */
	addl	%eax, _bench486_alias_vertices	# _114, bench486_alias_vertices
L143:
/* original r_alias.c:1073: 	BENCH486_PROFILE_WORK (BENCH486_PROFILE_ALIAS_MODEL, 1, */
	pushl	%ecx	#
	pushl	%eax	# _114
	pushl	$1	#
	pushl	$24	#
	call	_Bench486ProfileWork	#
/* original r_alias.c:1076: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_SETUP); */
	movl	$25, (%esp)	#,
	call	_Bench486ProfileEnter	#
/* original r_alias.c:1077: 	R_AliasSetupSkin (); */
	call	_R_AliasSetupSkin	#
/* original r_alias.c:1078: 	if (alias_transform_entity != currententity || */
	movl	_currententity, %edx	# currententity, currententity.111_25
/* original r_alias.c:1078: 	if (alias_transform_entity != currententity || */
	addl	$16, %esp	#,
	cmpl	%edx, _aliascontrol_alias_transform_entity	# currententity.111_25, alias_transform_entity
/* original r_alias.c:1079: 			alias_transform_mode != currententity->trivial_accept) */
	movl	172(%edx), %eax	# currententity.111_25->trivial_accept, _26
/* original r_alias.c:1078: 	if (alias_transform_entity != currententity || */
	je	L144	#,
L145:
/* original r_alias.c:1080: 		R_AliasSetUpTransform (currententity->trivial_accept); */
	subl	$12, %esp	#,
	pushl	%eax	# _26
	call	_R_AliasSetUpTransform	#
	addl	$16, %esp	#,
L146:
/* original r_alias.c:1081: 	alias_transform_entity = NULL; */
	movl	$0, _aliascontrol_alias_transform_entity	#, alias_transform_entity
/* original r_alias.c:960: 	R_AliasSetupLighting_asm486 (plighting, alias_forward, alias_right, */
	pushl	$_aliascontrol_alias_up	#
	pushl	$_aliascontrol_alias_right	#
	pushl	$_aliascontrol_alias_forward	#
	pushl	%ebx	# plighting
	call	_R_AliasSetupLighting_asm486	#
/* original r_alias.c:1019: 	frame = currententity->frame; */
	movl	_currententity, %ecx	# currententity, currententity.96_91
/* original r_alias.c:1019: 	frame = currententity->frame; */
	movl	140(%ecx), %eax	# currententity.96_91->frame, frame
/* original r_alias.c:1020: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	addl	$16, %esp	#,
	movl	_pmdl, %ebx	# pmdl, pmdl
	cmpl	68(%ebx), %eax	# pmdl.97_93->numframes, frame
	jge	L147	#,
/* original r_alias.c:1020: 	if ((frame >= pmdl->numframes) || (frame < 0)) */
	testl	%eax, %eax	# frame
	js	L147	#,
L148:
/* original r_alias.c:1027: 	R_AliasSetupFrame_asm486 (frame, cl.time, currententity->syncbase); */
	movl	144(%ecx), %edx	# prephitmp_119->syncbase,
	pushl	%edx	#
	movl	_cl+576, %ebx	# cl.time,
	pushl	%ebx	#
	movl	_cl+572, %ecx	# cl.time,
	pushl	%ecx	#
	pushl	%eax	# frame
	call	_R_AliasSetupFrame_asm486	#
/* original r_alias.c:1085: 	if (!currententity->colormap) */
	movl	_currententity, %eax	# currententity, currententity.115_29
/* original r_alias.c:1085: 	if (!currententity->colormap) */
	addl	$16, %esp	#,
	movl	148(%eax), %edx	# currententity.115_29->colormap,
	testl	%edx, %edx	#
	je	L158	#,
L149:
/* original r_alias.c:1088: 	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) && */
	cmpl	$3, 172(%eax)	#, prephitmp_121->trivial_accept
	je	L159	#,
L150:
/* original r_alias.c:1088: 	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) && */
	movl	$0, _r_affinetridesc+28	#, r_affinetridesc.drawtype
/* original r_alias.c:1098: 		D_Aff8Patch (currententity->colormap); */
	subl	$12, %esp	#,
	movl	148(%eax), %ecx	# prephitmp_121->colormap,
	pushl	%ecx	#
	call	_D_Aff8Patch	#
	addl	$16, %esp	#,
L151:
/* original r_alias.c:1102: 	acolormap = currententity->colormap; */
	movl	_currententity, %eax	# currententity, currententity.120_35
/* original r_alias.c:1102: 	acolormap = currententity->colormap; */
	movl	148(%eax), %edx	# currententity.120_35->colormap, currententity.120_35->colormap
	movl	%edx, _acolormap	# currententity.120_35->colormap, acolormap
/* original r_alias.c:1104: 	if (currententity != &cl.viewent) */
	cmpl	$_cl+2708, %eax	#, currententity.120_35
	je	L156	#,
/* original r_alias.c:1105: 		ziscale = (float)0x8000 * (float)0x10000; */
	flds	LC9	#
L152:
	fstps	_ziscale	# ziscale
/* original r_alias.c:1108: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* original r_alias.c:1110: 	if (currententity->trivial_accept) */
	movl	_currententity, %ebx	# currententity, currententity
/* original r_alias.c:1110: 	if (currententity->trivial_accept) */
	movl	172(%ebx), %ecx	# currententity.122_37->trivial_accept,
	testl	%ecx, %ecx	#
	je	L153	#,
/* original r_alias.c:1111: 		R_AliasPrepareUnclippedPoints (); */
	call	_R_AliasPrepareUnclippedPoints	#
/* original r_alias.c:1116: 	if (bench486_profile_frame_active) */
	movl	_bench486_profile_frame_active, %eax	# bench486_profile_frame_active,
	testl	%eax, %eax	#
	jne	L160	#,
L155:
/* original r_alias.c:1119: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* original r_alias.c:1120: } */
	addl	$88056, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L147:
/* original r_alias.c:1022: 		Con_DPrintf ("R_AliasSetupFrame: no such frame %d\n", frame); */
	subl	$8, %esp	#,
	pushl	%eax	# frame
	pushl	$LC8	#
	call	_Con_DPrintf	#
/* original r_alias.c:1027: 	R_AliasSetupFrame_asm486 (frame, cl.time, currententity->syncbase); */
	movl	_currententity, %ecx	# currententity, currententity.96_91
	addl	$16, %esp	#,
/* original r_alias.c:1023: 		frame = 0; */
	xorl	%eax, %eax	# frame
	jmp	L148	#
	.p2align 4
	.p2align 3
L153:
/* original r_alias.c:1113: 		R_AliasPreparePoints (); */
	call	_R_AliasPreparePoints	#
/* original r_alias.c:1116: 	if (bench486_profile_frame_active) */
	movl	_bench486_profile_frame_active, %eax	# bench486_profile_frame_active,
	testl	%eax, %eax	#
	je	L155	#,
L160:
/* original r_alias.c:1117: 		bench486_alias_seconds += Sys_FloatTime () - bench486_alias_start; */
	call	_Sys_FloatTime	#
/* original r_alias.c:1117: 		bench486_alias_seconds += Sys_FloatTime () - bench486_alias_start; */
	fldl	8(%esp)	# %sfp
	fsubrl	_bench486_alias_seconds	# bench486_alias_seconds
	faddp	%st, %st(1)	#,
	fstpl	_bench486_alias_seconds	# bench486_alias_seconds
/* original r_alias.c:1119: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* original r_alias.c:1120: } */
	addl	$88056, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L144:
/* original r_alias.c:1078: 	if (alias_transform_entity != currententity || */
	cmpl	_aliascontrol_alias_transform_mode, %eax	# alias_transform_mode, _26
	jne	L145	#,
	jmp	L146	#
	.p2align 4
	.p2align 3
L159:
/* original r_alias.c:1088: 	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) && */
	movl	_r_recursiveaffinetriangles, %ebx	# r_recursiveaffinetriangles,
	testl	%ebx, %ebx	#
	je	L150	#,
/* original r_alias.c:1088: 	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) && */
	movl	$1, _r_affinetridesc+28	#, r_affinetridesc.drawtype
/* original r_alias.c:1093: 		D_PolysetUpdateTables ();		// FIXME: precalc... */
	call	_D_PolysetUpdateTables	#
	jmp	L151	#
	.p2align 4
	.p2align 3
L138:
/* original r_alias.c:1051: 		bench486_alias_start = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
	fstpl	8(%esp)	# %sfp
/* original r_alias.c:1054: 	r_amodels_drawn++; */
	incl	_r_amodels_drawn	# r_amodels_drawn
/* original r_alias.c:1057: 	if (bench486_profile_frame_active) */
	movl	_bench486_profile_frame_active, %ecx	# bench486_profile_frame_active,
	testl	%ecx, %ecx	#
	je	L139	#,
/* original r_alias.c:1058: 		bench486_alias_models++; */
	incl	_bench486_alias_models	# bench486_alias_models
	jmp	L139	#
	.p2align 4
	.p2align 3
L156:
/* original r_alias.c:1107: 		ziscale = (float)0x8000 * (float)0x10000 * 3.0; */
	flds	LC10	#
	jmp	L152	#
	.p2align 4
	.p2align 3
L158:
/* original r_alias.c:1086: 		Sys_Error ("R_AliasDrawModel: !currententity->colormap"); */
	subl	$12, %esp	#,
	pushl	$LC11	#
	call	_Sys_Error	#
/* original r_alias.c:1088: 	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) && */
	movl	_currententity, %eax	# currententity, currententity.115_29
	addl	$16, %esp	#,
	jmp	L149	#
	.p2align 3
