/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
/* Frame control: profile instruction body. Initial C source SHA256:
 * 7450F6A210849FA0272B07AB284DFAE6A21640FB6671E216E8440B211F3B3E87
 * GCC 12.2.0 DJGPP -march=i486 -mtune=i486; see docs/renderer-assembly/frame-control-provenance.json.
 * This file is maintained assembly. Do not regenerate it in the build.
 * Cdecl: stack arguments; EAX integer results, ST(0) floating results.
 * EBX/ESI/EDI/EBP are preserved when used; EAX/ECX/EDX are caller-owned.
 * Floating operations and store boundaries retain the pinned C evaluation.
 * Source comments identify each operation and original C variable.
 */

.text
.p2align 3
/* R_InitTextures: Allocate and fill the original four-level checkerboard fallback texture.
 * Callee registers used: %ebp, %ebx, %edi, %esi.
 * Stack reservations (bytes; includes call argument areas): 36.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_InitTextures
_R_InitTextures:
	pushl	%ebp	#
	pushl	%edi	#
	pushl	%esi	#
	pushl	%ebx	#
	subl	$36, %esp	#,
/* src/renderer/r_main.c:158: 	r_notexture_mip = Hunk_AllocName (sizeof(texture_t) + 16*16+8*8+4*4+2*2, "notexture"); */
	pushl	$LC0	#
	pushl	$400	#
	call	_Hunk_AllocName	#
/* src/renderer/r_main.c:158: 	r_notexture_mip = Hunk_AllocName (sizeof(texture_t) + 16*16+8*8+4*4+2*2, "notexture"); */
	movl	%eax, _r_notexture_mip	# prephitmp_15, r_notexture_mip
/* src/renderer/r_main.c:160: 	r_notexture_mip->width = r_notexture_mip->height = 16; */
	movl	$16, 20(%eax)	#, MEM[(struct texture_t *)_1].height
/* src/renderer/r_main.c:160: 	r_notexture_mip->width = r_notexture_mip->height = 16; */
	movl	$16, 16(%eax)	#, MEM[(struct texture_t *)_1].width
/* src/renderer/r_main.c:161: 	r_notexture_mip->offsets[0] = sizeof(texture_t); */
	movl	$60, 44(%eax)	#, MEM[(struct texture_t *)_1].offsets[0]
/* src/renderer/r_main.c:162: 	r_notexture_mip->offsets[1] = r_notexture_mip->offsets[0] + 16*16; */
	movl	$316, 48(%eax)	#, MEM[(struct texture_t *)_1].offsets[1]
/* src/renderer/r_main.c:163: 	r_notexture_mip->offsets[2] = r_notexture_mip->offsets[1] + 8*8; */
	movl	$380, 52(%eax)	#, MEM[(struct texture_t *)_1].offsets[2]
/* src/renderer/r_main.c:164: 	r_notexture_mip->offsets[3] = r_notexture_mip->offsets[2] + 4*4; */
	movl	$396, 56(%eax)	#, MEM[(struct texture_t *)_1].offsets[3]
	addl	$16, %esp	#,
/* src/renderer/r_main.c:166: 	for (m=0 ; m<4 ; m++) */
	xorl	%edx, %edx	# m
/* src/renderer/r_main.c:169: 		for (y=0 ; y< (16>>m) ; y++) */
	movl	$16, %ebp	#, tmp124
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	movl	%edx, 12(%esp)	# m, %sfp
L8:
/* src/renderer/r_main.c:168: 		dest = (byte *)r_notexture_mip + r_notexture_mip->offsets[m]; */
	movl	12(%esp), %ecx	# %sfp, m
	addl	44(%eax,%ecx,4), %eax	# prephitmp_15->offsets[m_47], dest
/* src/renderer/r_main.c:169: 		for (y=0 ; y< (16>>m) ; y++) */
	movl	%ebp, %edi	# tmp124, _41
	sarl	%cl, %edi	# tmp175, _41
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	movl	$8, %ebx	#, _5
	sarl	%cl, %ebx	# tmp177, _5
	movl	%ebx, %ecx	# _5, _5
/* src/renderer/r_main.c:169: 		for (y=0 ; y< (16>>m) ; y++) */
	xorl	%esi, %esi	# y
	.p2align 3
	.p2align 3
L6:
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpl	%esi, %ecx	# y, _5
	setg	%bl	#, tmp126
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	movb	%bl, %dl	# tmp126, tmp129
	negl	%edx	# tmp129
	movb	%dl, (%eax)	# tmp129, MEM[(byte *)dest_43]
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpl	$1, %ecx	#, _5
	setg	%dl	#, tmp131
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpb	%bl, %dl	# tmp126, tmp131
	sete	%dl	#, tmp133
	negl	%edx	# tmp134
	movb	%dl, 1(%eax)	# tmp134, MEM[(byte *)dest_43 + 1B]
/* src/renderer/r_main.c:170: 			for (x=0 ; x< (16>>m) ; x++) */
	cmpl	$2, %edi	#, _41
	je	L2	#,
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpl	$2, %ecx	#, _5
	setg	%dl	#, tmp136
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpb	%bl, %dl	# tmp126, tmp136
	sete	%dl	#, tmp138
	negl	%edx	# tmp139
	movb	%dl, 2(%eax)	# tmp139, MEM[(byte *)dest_43 + 2B]
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpl	$3, %ecx	#, _5
	setg	%dl	#, tmp141
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpb	%bl, %dl	# tmp126, tmp141
	sete	%dl	#, tmp143
	negl	%edx	# tmp144
	movb	%dl, 3(%eax)	# tmp144, MEM[(byte *)dest_43 + 3B]
/* src/renderer/r_main.c:170: 			for (x=0 ; x< (16>>m) ; x++) */
	cmpl	$4, %edi	#, _41
	je	L2	#,
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpl	$4, %ecx	#, _5
	setg	%dl	#, tmp146
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpb	%bl, %dl	# tmp126, tmp146
	sete	%dl	#, tmp148
	negl	%edx	# tmp149
	movb	%dl, 4(%eax)	# tmp149, MEM[(byte *)dest_43 + 4B]
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpl	$5, %ecx	#, _5
	setg	%dl	#, tmp151
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpb	%bl, %dl	# tmp126, tmp151
	sete	%dl	#, tmp153
	negl	%edx	# tmp154
	movb	%dl, 5(%eax)	# tmp154, MEM[(byte *)dest_43 + 5B]
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpl	$6, %ecx	#, _5
	setg	%dl	#, tmp156
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpb	%bl, %dl	# tmp126, tmp156
	sete	%dl	#, tmp158
	negl	%edx	# tmp159
	movb	%dl, 6(%eax)	# tmp159, MEM[(byte *)dest_43 + 6B]
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpl	$7, %ecx	#, _5
	setg	%dl	#, tmp161
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpb	%bl, %dl	# tmp126, tmp161
	sete	%bl	#, tmp163
	negl	%ebx	# tmp164
	movb	%bl, 7(%eax)	# tmp164, MEM[(byte *)dest_43 + 7B]
/* src/renderer/r_main.c:170: 			for (x=0 ; x< (16>>m) ; x++) */
	cmpl	$8, %edi	#, _41
	je	L2	#,
/* src/renderer/r_main.c:172: 				if (  (y< (8>>m) ) ^ (x< (8>>m) ) ) */
	cmpl	%esi, %ecx	# y, _5
	jle	L3	#,
	movb	$0, 8(%eax)	#, MEM[(byte *)dest_43 + 8B]
	movb	$0, 9(%eax)	#, MEM[(byte *)dest_43 + 9B]
	movb	$0, 10(%eax)	#, MEM[(byte *)dest_43 + 10B]
	movb	$0, 11(%eax)	#, MEM[(byte *)dest_43 + 11B]
	movb	$0, 12(%eax)	#, MEM[(byte *)dest_43 + 12B]
	movb	$0, 13(%eax)	#, MEM[(byte *)dest_43 + 13B]
	movb	$0, 14(%eax)	#, MEM[(byte *)dest_43 + 14B]
	movb	$0, 15(%eax)	#, MEM[(byte *)dest_43 + 15B]
/* src/renderer/r_main.c:173: 					*dest++ = 0; */
	addl	$16, %eax	#, dest
/* src/renderer/r_main.c:169: 		for (y=0 ; y< (16>>m) ; y++) */
	incl	%esi	# y
	jmp	L6	#
	.p2align 4
	.p2align 3
L3:
	movb	$-1, 8(%eax)	#, MEM[(byte *)dest_43 + 8B]
	movb	$-1, 9(%eax)	#, MEM[(byte *)dest_43 + 9B]
	movb	$-1, 10(%eax)	#, MEM[(byte *)dest_43 + 10B]
	movb	$-1, 11(%eax)	#, MEM[(byte *)dest_43 + 11B]
	movb	$-1, 12(%eax)	#, MEM[(byte *)dest_43 + 12B]
	movb	$-1, 13(%eax)	#, MEM[(byte *)dest_43 + 13B]
	movb	$-1, 14(%eax)	#, MEM[(byte *)dest_43 + 14B]
	movb	$-1, 15(%eax)	#, MEM[(byte *)dest_43 + 15B]
L2:
/* src/renderer/r_main.c:173: 					*dest++ = 0; */
	addl	%edi, %eax	# _41, dest
/* src/renderer/r_main.c:169: 		for (y=0 ; y< (16>>m) ; y++) */
	incl	%esi	# y
/* src/renderer/r_main.c:169: 		for (y=0 ; y< (16>>m) ; y++) */
	cmpl	%edi, %esi	# _41, y
	jne	L6	#,
/* src/renderer/r_main.c:166: 	for (m=0 ; m<4 ; m++) */
	incl	12(%esp)	# %sfp
	movl	12(%esp), %eax	# %sfp, m
/* src/renderer/r_main.c:166: 	for (m=0 ; m<4 ; m++) */
	cmpl	$4, %eax	#, m
	je	L1	#,
/* src/renderer/r_main.c:168: 		dest = (byte *)r_notexture_mip + r_notexture_mip->offsets[m]; */
	movl	_r_notexture_mip, %eax	# r_notexture_mip, prephitmp_15
	jmp	L8	#
L1:
/* src/renderer/r_main.c:178: } */
	addl	$28, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	popl	%ebp	#
	ret

.text
.p2align 3
/* R_Init: Register renderer controls, initialize turbulence and the low-level drawing driver.
 * Callee registers used: none.
 * Stack reservations (bytes; includes call argument areas): 44, 8.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_Init
_R_Init:
	subl	$44, %esp	#,
	call	_R_InitWarpBuffer	#
/* src/renderer/r_main.c:1214: 		sintable[i] = AMP + sin(i*3.14159*2/CYCLE)*AMP; */
	movl	$524288, _sintable	#, sintable[0]
/* src/renderer/r_main.c:1215: 		intsintable[i] = AMP2 + sin(i*3.14159*2/CYCLE)*AMP2;	// AMP2, not 20 */
	movl	$3, _intsintable	#, intsintable[0]
/* src/renderer/r_main.c:1212: 	for (i=0 ; i<(SIN_BUFFER_SIZE) ; i++) */
	movl	$1, %ecx	#, i
/* src/renderer/r_main.c:1214: 		sintable[i] = AMP + sin(i*3.14159*2/CYCLE)*AMP; */
	fldl	LC1	#
	fnstcw	14(%esp)	#
	movw	14(%esp), %dx	#, tmp127
	orb	$12, %dh	#, tmp127
	movw	%dx, 12(%esp)	# tmp127,
	.p2align 3
	.p2align 3
L21:
	fld	%st(0)	#
	movl	%ecx, 8(%esp)	# i, %sfp
	fimull	8(%esp)	# %sfp
	fsin
/* src/renderer/r_main.c:1214: 		sintable[i] = AMP + sin(i*3.14159*2/CYCLE)*AMP; */
	fadds	LC2	#
	fld	%st(0)	#
	fmuls	LC3	#
/* src/renderer/r_main.c:1214: 		sintable[i] = AMP + sin(i*3.14159*2/CYCLE)*AMP; */
	fldcw	12(%esp)		#
	fistpl	_sintable(,%ecx,4)	# MEM[(int *)&sintable + _79 * 4]
	fldcw	14(%esp)		#
/* src/renderer/r_main.c:1215: 		intsintable[i] = AMP2 + sin(i*3.14159*2/CYCLE)*AMP2;	// AMP2, not 20 */
	fmuls	LC4	#
/* src/renderer/r_main.c:1215: 		intsintable[i] = AMP2 + sin(i*3.14159*2/CYCLE)*AMP2;	// AMP2, not 20 */
	fldcw	12(%esp)		#
	fistpl	_intsintable(,%ecx,4)	# MEM[(int *)&intsintable + _79 * 4]
	fldcw	14(%esp)		#
/* src/renderer/r_main.c:1212: 	for (i=0 ; i<(SIN_BUFFER_SIZE) ; i++) */
	incl	%ecx	# i
/* src/renderer/r_main.c:1212: 	for (i=0 ; i<(SIN_BUFFER_SIZE) ; i++) */
	cmpl	$1408, %ecx	#, i
	jne	L21	#,
	fstp	%st(0)		#
/* src/renderer/r_main.c:194: 	Cmd_AddCommand ("timerefresh", R_TimeRefresh_f); */
	subl	$8, %esp	#,
	pushl	$_R_TimeRefresh_f	#
	pushl	$LC5	#
	call	_Cmd_AddCommand	#
/* src/renderer/r_main.c:195: 	Cmd_AddCommand ("pointfile", R_ReadPointFile_f); */
	popl	%eax	#
	popl	%edx	#
	pushl	$_R_ReadPointFile_f	#
	pushl	$LC6	#
	call	_Cmd_AddCommand	#
/* src/renderer/r_main.c:197: 	Cvar_RegisterVariable (&r_draworder); */
	movl	$_r_draworder, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:198: 	Cvar_RegisterVariable (&r_speeds); */
	movl	$_r_speeds, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:199: 	Cvar_RegisterVariable (&r_timegraph); */
	movl	$_r_timegraph, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:200: 	Cvar_RegisterVariable (&r_graphheight); */
	movl	$_r_graphheight, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:201: 	Cvar_RegisterVariable (&r_drawflat); */
	movl	$_r_drawflat, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:202: 	Cvar_RegisterVariable (&r_ambient); */
	movl	$_r_ambient, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:203: 	Cvar_RegisterVariable (&r_clearcolor); */
	movl	$_r_clearcolor, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:204: 	Cvar_RegisterVariable (&r_waterwarp); */
	movl	$_r_waterwarp, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:205: 	Cvar_RegisterVariable (&r_fullbright); */
	movl	$_r_fullbright, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:206: 	Cvar_RegisterVariable (&r_drawentities); */
	movl	$_r_drawentities, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:207: 	Cvar_RegisterVariable (&r_drawviewmodel); */
	movl	$_r_drawviewmodel, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:208: 	Cvar_RegisterVariable (&r_aliasstats); */
	movl	$_r_aliasstats, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:209: 	Cvar_RegisterVariable (&r_dspeeds); */
	movl	$_r_dspeeds, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:210: 	Cvar_RegisterVariable (&r_reportsurfout); */
	movl	$_r_reportsurfout, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:211: 	Cvar_RegisterVariable (&r_maxsurfs); */
	movl	$_r_maxsurfs, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:212: 	Cvar_RegisterVariable (&r_numsurfs); */
	movl	$_r_numsurfs, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:213: 	Cvar_RegisterVariable (&r_reportedgeout); */
	movl	$_r_reportedgeout, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:214: 	Cvar_RegisterVariable (&r_maxedges); */
	movl	$_r_maxedges, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:215: 	Cvar_RegisterVariable (&r_numedges); */
	movl	$_r_numedges, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:216: 	Cvar_RegisterVariable (&r_aliastransbase); */
	movl	$_r_aliastransbase, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:217: 	Cvar_RegisterVariable (&r_aliastransadj); */
	movl	$_r_aliastransadj, (%esp)	#,
	call	_Cvar_RegisterVariable	#
/* src/renderer/r_main.c:219: 	Cvar_SetValue ("r_maxedges", (float)NUMSTACKEDGES); */
	popl	%ecx	#
	popl	%eax	#
	pushl	$0x45160000	#
	pushl	$LC8	#
	call	_Cvar_SetValue	#
/* src/renderer/r_main.c:220: 	Cvar_SetValue ("r_maxsurfs", (float)NUMSTACKSURFACES); */
	popl	%eax	#
	popl	%edx	#
	pushl	$0x44480000	#
	pushl	$LC10	#
	call	_Cvar_SetValue	#
/* src/renderer/r_main.c:224: 	view_clipplanes[1].leftedge = view_clipplanes[2].leftedge = */
	movw	$256, _view_clipplanes+44	#, MEM <unsigned short> [(unsigned char *)&view_clipplanes + 44B]
/* src/renderer/r_main.c:225: 			view_clipplanes[3].leftedge = false; */
	movw	$0, _view_clipplanes+92	#, MEM <unsigned short> [(unsigned char *)&view_clipplanes + 92B]
/* src/renderer/r_main.c:224: 	view_clipplanes[1].leftedge = view_clipplanes[2].leftedge = */
	movw	$0, _view_clipplanes+68	#, MEM <unsigned short> [(unsigned char *)&view_clipplanes + 68B]
/* src/renderer/r_main.c:222: 	view_clipplanes[0].leftedge = true; */
	movw	$1, _view_clipplanes+20	#, MEM <unsigned short> [(unsigned char *)&view_clipplanes + 20B]
/* src/renderer/r_main.c:229: 	r_refdef.xOrigin = XCENTERING; */
	flds	LC11	#
	fsts	_r_refdef+104	# r_refdef.xOrigin
/* src/renderer/r_main.c:230: 	r_refdef.yOrigin = YCENTERING; */
	fstps	_r_refdef+108	# r_refdef.yOrigin
/* src/renderer/r_main.c:232: 	R_InitParticles (); */
	call	_R_InitParticles	#
/* src/renderer/r_main.c:236: 	Sys_MakeCodeWriteable ((long)R_EdgeCodeStart, */
	popl	%ecx	#
	popl	%eax	#
/* src/renderer/r_main.c:237: 					     (long)R_EdgeCodeEnd - (long)R_EdgeCodeStart); */
	movl	$_R_EdgeCodeEnd, %eax	#, tmp126
	subl	$_R_EdgeCodeStart, %eax	#, tmp125
/* src/renderer/r_main.c:236: 	Sys_MakeCodeWriteable ((long)R_EdgeCodeStart, */
	pushl	%eax	# tmp125
	pushl	$_R_EdgeCodeStart	#
	call	_Sys_MakeCodeWriteable	#
/* src/renderer/r_main.c:240: 	D_Init (); */
	call	_D_Init	#
/* src/renderer/r_main.c:241: } */
	addl	$60, %esp	#,
	ret

.text
.p2align 3
/* R_NewMap: Reset leaf/entity/particle state and choose aligned edge/surface storage for the new map.
 * Callee registers used: none.
 * Stack reservations (bytes; includes call argument areas): 28, 8, 8.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_NewMap
_R_NewMap:
	subl	$28, %esp	#,
/* src/renderer/r_main.c:254: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	movl	_cl+2692, %ecx	# cl.worldmodel, _5
/* src/renderer/r_main.c:254: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	movl	136(%ecx), %eax	# _55->numleafs,
	xorl	%edx, %edx	# i
	testl	%eax, %eax	#
	jle	L28	#,
	.p2align 3
	.p2align 3
L25:
/* src/renderer/r_main.c:255: 		cl.worldmodel->leafs[i].efrags = NULL; */
	leal	(%edx,%edx), %eax	#, tmp113
	addl	%edx, %eax	# i, tmp114
	sall	$4, %eax	#, tmp115
	addl	140(%ecx), %eax	# _59->leafs, tmp116
	movl	$0, 28(%eax)	#, _4->efrags
/* src/renderer/r_main.c:254: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	incl	%edx	# i
/* src/renderer/r_main.c:254: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	movl	_cl+2692, %ecx	# cl.worldmodel, _5
/* src/renderer/r_main.c:254: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	cmpl	%edx, 136(%ecx)	# i, _5->numleafs
	jg	L25	#,
L28:
/* src/renderer/r_main.c:257: 	r_viewleaf = NULL; */
	movl	$0, _r_viewleaf	#, r_viewleaf
/* src/renderer/r_main.c:258: 	R_ClearParticles (); */
	call	_R_ClearParticles	#
/* src/renderer/r_main.c:260: 	r_cnumsurfs = r_maxsurfs.value; */
	fnstcw	14(%esp)	#
	movw	14(%esp), %dx	#, tmp129
	orb	$12, %dh	#, tmp129
	movw	%dx, 12(%esp)	# tmp129,
	flds	_r_maxsurfs+16	# r_maxsurfs.value
	fldcw	12(%esp)		#
	fistpl	8(%esp)	# %sfp
	fldcw	14(%esp)		#
	movl	8(%esp), %eax	# %sfp, _8
	movl	%eax, _r_cnumsurfs	# _8, r_cnumsurfs
/* src/renderer/r_main.c:262: 	if (r_cnumsurfs <= MINSURFACES) */
	cmpl	$800, %eax	#, _8
	jle	L26	#,
/* src/renderer/r_main.c:267: 		surfaces = Hunk_AllocName (r_cnumsurfs * sizeof(surf_t), "surfaces"); */
	subl	$8, %esp	#,
	pushl	$LC14	#
/* src/renderer/r_main.c:267: 		surfaces = Hunk_AllocName (r_cnumsurfs * sizeof(surf_t), "surfaces"); */
	sall	$6, %eax	#, tmp121
/* src/renderer/r_main.c:267: 		surfaces = Hunk_AllocName (r_cnumsurfs * sizeof(surf_t), "surfaces"); */
	pushl	%eax	# tmp121
	call	_Hunk_AllocName	#
/* src/renderer/r_main.c:268: 		surface_p = surfaces; */
	movl	%eax, _surface_p	# _13, surface_p
/* src/renderer/r_main.c:269: 		surf_max = &surfaces[r_cnumsurfs]; */
	movl	_r_cnumsurfs, %ecx	# r_cnumsurfs, tmp122
	sall	$6, %ecx	#, tmp122
/* src/renderer/r_main.c:269: 		surf_max = &surfaces[r_cnumsurfs]; */
	addl	%eax, %ecx	# _13, tmp124
	movl	%ecx, _surf_max	# tmp124, surf_max
/* src/renderer/r_main.c:270: 		r_surfsonstack = false; */
	movl	$0, _r_surfsonstack	#, r_surfsonstack
/* src/renderer/r_main.c:273: 		surfaces--; */
	subl	$64, %eax	#, tmp125
	movl	%eax, _surfaces	# tmp125, surfaces
/* src/renderer/r_main.c:274: 		R_SurfacePatch (); */
	call	_R_SurfacePatch	#
	addl	$16, %esp	#,
	fnstcw	14(%esp)	#
	movw	14(%esp), %dx	#, tmp128
	orb	$12, %dh	#, tmp128
	movw	%dx, 12(%esp)	# tmp128,
L33:
/* src/renderer/r_main.c:281: 	r_maxedgesseen = 0; */
	movl	$0, _r_maxedgesseen	#, r_maxedgesseen
/* src/renderer/r_main.c:282: 	r_maxsurfsseen = 0; */
	movl	$0, _r_maxsurfsseen	#, r_maxsurfsseen
/* src/renderer/r_main.c:284: 	r_numallocatededges = r_maxedges.value; */
	flds	_r_maxedges+16	# r_maxedges.value
	fldcw	12(%esp)		#
	fistpl	8(%esp)	# %sfp
	fldcw	14(%esp)		#
	movl	8(%esp), %eax	# %sfp, _20
	movl	%eax, _r_numallocatededges	# _20, r_numallocatededges
/* src/renderer/r_main.c:286: 	if (r_numallocatededges < MINEDGES) */
	cmpl	$2399, %eax	#, _20
	jg	L29	#,
/* src/renderer/r_main.c:287: 		r_numallocatededges = MINEDGES; */
	movl	$2400, _r_numallocatededges	#, r_numallocatededges
L30:
	xorl	%eax, %eax	# _25
L32:
/* src/renderer/r_main.c:291: 		auxedges = NULL; */
	movl	%eax, _auxedges	# _25, auxedges
/* src/renderer/r_main.c:299: 	r_dowarpold = false; */
	movl	$0, _r_dowarpold	#, r_dowarpold
/* src/renderer/r_main.c:300: 	r_viewchanged = false; */
	movl	$0, _r_viewchanged	#, r_viewchanged
/* src/renderer/r_main.c:304: } */
	addl	$28, %esp	#,
	ret
	.p2align 4
	.p2align 3
L26:
/* src/renderer/r_main.c:263: 		r_cnumsurfs = MINSURFACES; */
	movl	$800, _r_cnumsurfs	#, r_cnumsurfs
/* src/renderer/r_main.c:278: 		r_surfsonstack = true; */
	movl	$1, _r_surfsonstack	#, r_surfsonstack
	jmp	L33	#
	.p2align 4
	.p2align 3
L29:
/* src/renderer/r_main.c:289: 	if (r_numallocatededges <= NUMSTACKEDGES) */
	cmpl	$2400, %eax	#, _20
	je	L30	#,
/* src/renderer/r_main.c:295: 		auxedges = Hunk_AllocName (r_numallocatededges * sizeof(edge_t), */
	subl	$8, %esp	#,
	pushl	$LC13	#
/* src/renderer/r_main.c:295: 		auxedges = Hunk_AllocName (r_numallocatededges * sizeof(edge_t), */
	sall	$5, %eax	#, tmp120
/* src/renderer/r_main.c:295: 		auxedges = Hunk_AllocName (r_numallocatededges * sizeof(edge_t), */
	pushl	%eax	# tmp120
	call	_Hunk_AllocName	#
	addl	$16, %esp	#,
	jmp	L32	#
	.p2align 3

.text
.p2align 3
/* R_SetVrect: Apply intermission/view-size controls, icon minimum, width/height quantization and LCD subdivision.
 * Callee registers used: %ebp, %ebx, %edi, %esi.
 * Stack reservations (bytes; includes call argument areas): 12.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_SetVrect
_R_SetVrect:
	pushl	%ebp	#
	pushl	%edi	#
	pushl	%esi	#
	pushl	%ebx	#
	subl	$12, %esp	#,
	movl	32(%esp), %esi	# pvrectin, pvrectin
	movl	36(%esp), %ecx	# pvrect, pvrect
	movl	40(%esp), %edi	# lineadj, lineadj
/* src/renderer/r_main.c:317: 	size = scr_viewsize.value > 100 ? 100 : scr_viewsize.value; */
	flds	_scr_viewsize+16	# scr_viewsize.value
/* src/renderer/r_main.c:318: 	if (cl.intermission) */
	movl	_cl+548, %eax	# cl.intermission,
	testl	%eax, %eax	#
	jne	L49	#,
/* src/renderer/r_main.c:317: 	size = scr_viewsize.value > 100 ? 100 : scr_viewsize.value; */
	fcoms	LC15	#
	fnstsw	%ax	# tmp118
	testb	$69, %ah	#, tmp118
	je	L52	#,
L44:
/* src/renderer/r_main.c:323: 	size /= 100; */
	fmuls	LC16	#
L43:
/* src/renderer/r_main.c:325: 	h = pvrectin->height - lineadj; */
	movl	12(%esi), %eax	# pvrectin_39(D)->height, h
	subl	%edi, %eax	# lineadj, h
/* src/renderer/r_main.c:326: 	pvrect->width = pvrectin->width * size; */
	fld	%st(0)	#
	fimull	8(%esi)	# pvrectin_39(D)->width
/* src/renderer/r_main.c:326: 	pvrect->width = pvrectin->width * size; */
	fnstcw	6(%esp)	#
	movw	6(%esp), %dx	#, tmp150
	orb	$12, %dh	#, tmp150
	movw	%dx, 4(%esp)	# tmp150,
	fldcw	4(%esp)		#
	fistpl	(%esp)	# %sfp
	fldcw	6(%esp)		#
	movl	(%esp), %ebx	# %sfp, _7
	movl	%ebx, 8(%ecx)	# _7, pvrect_41(D)->width
/* src/renderer/r_main.c:327: 	if (pvrect->width < 96) */
	cmpl	$95, %ebx	#, _7
	jle	L45	#,
/* src/renderer/r_main.c:332: 	pvrect->width &= ~7; */
	andl	$-8, %ebx	#, _59
L46:
	movl	%ebx, 8(%ecx)	# _59, pvrect_41(D)->width
/* src/renderer/r_main.c:333: 	pvrect->height = pvrectin->height * size; */
	fimull	12(%esi)	# pvrectin_39(D)->height
/* src/renderer/r_main.c:333: 	pvrect->height = pvrectin->height * size; */
	fldcw	4(%esp)		#
	fistpl	(%esp)	# %sfp
	fldcw	6(%esp)		#
	movl	(%esp), %ebp	# %sfp, _16
	movl	%ebp, 12(%ecx)	# _16, pvrect_41(D)->height
/* src/renderer/r_main.c:337: 	pvrect->height &= ~1; */
	movl	12(%esi), %edx	# pvrectin_39(D)->height, _16
	subl	%edi, %edx	# lineadj, _16
	cmpl	%ebp, %edx	# _16, _16
	jle	L47	#,
	movl	%ebp, %edx	# _16, _16
L47:
	andl	$-2, %edx	#, _20
	movl	%edx, 12(%ecx)	# _20, pvrect_41(D)->height
/* src/renderer/r_main.c:339: 	pvrect->x = (pvrectin->width - pvrect->width)/2; */
	movl	8(%esi), %esi	# pvrectin_39(D)->width, pvrectin_39(D)->width
	subl	%ebx, %esi	# _59, tmp132
/* src/renderer/r_main.c:339: 	pvrect->x = (pvrectin->width - pvrect->width)/2; */
	movl	%esi, %edi	# tmp132, tmp134
	shrl	$31, %edi	#, tmp134
	addl	%esi, %edi	# tmp132, tmp135
	sarl	$1, %edi	#, tmp136
/* src/renderer/r_main.c:339: 	pvrect->x = (pvrectin->width - pvrect->width)/2; */
	movl	%edi, (%ecx)	# tmp136, pvrect_41(D)->x
/* src/renderer/r_main.c:340: 	pvrect->y = (h - pvrect->height)/2; */
	subl	%edx, %eax	# _20, tmp137
/* src/renderer/r_main.c:340: 	pvrect->y = (h - pvrect->height)/2; */
	movl	%eax, %ebx	# tmp137, tmp138
	shrl	$31, %ebx	#, tmp138
	addl	%eax, %ebx	# tmp137, tmp139
	movl	%ebx, %eax	# tmp139, tmp140
	sarl	$1, %eax	#, tmp140
/* src/renderer/r_main.c:340: 	pvrect->y = (h - pvrect->height)/2; */
	movl	%eax, 4(%ecx)	# tmp140, pvrect_41(D)->y
/* src/renderer/r_main.c:343: 		if (lcd_x.value) */
	fldz
	fcomps	_lcd_x+16	# lcd_x.value
	fnstsw	%ax	# tmp143
	testb	$64, %ah	#, tmp143
	jne	L50	#,
/* src/renderer/r_main.c:345: 			pvrect->y >>= 1; */
	sarl	$2, %ebx	#, tmp144
	movl	%ebx, 4(%ecx)	# tmp144, pvrect_41(D)->y
/* src/renderer/r_main.c:346: 			pvrect->height >>= 1; */
	sarl	$1, %edx	#, tmp145
	movl	%edx, 12(%ecx)	# tmp145, pvrect_41(D)->height
L50:
/* src/renderer/r_main.c:349: } */
	addl	$12, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	popl	%ebp	#
	ret
	.p2align 4
	.p2align 3
L45:
	fstp	%st(0)		#
/* src/renderer/r_main.c:329: 		size = 96.0 / pvrectin->width; */
	flds	LC17	#
	fidivl	8(%esi)	# pvrectin_39(D)->width
/* src/renderer/r_main.c:329: 		size = 96.0 / pvrectin->width; */
	movl	$96, %ebx	#, _59
	jmp	L46	#
	.p2align 4
	.p2align 3
L49:
	fstp	%st(0)		#
	fld1
/* src/renderer/r_main.c:321: 		lineadj = 0; */
	xorl	%edi, %edi	# lineadj
	jmp	L43	#
	.p2align 4
	.p2align 3
L52:
	fstp	%st(0)		#
/* src/renderer/r_main.c:317: 	size = scr_viewsize.value > 100 ? 100 : scr_viewsize.value; */
	flds	LC15	#
	jmp	L44	#
	.p2align 3

.text
.p2align 3
/* R_ViewChanged: Recompute viewport/perspective/scales, frustum edges and resolution-based alias transitions; patch the selected colormap driver.
 * Callee registers used: %ebx, %esi.
 * Stack reservations (bytes; includes call argument areas): 24, 8, 8.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_ViewChanged
_R_ViewChanged:
	pushl	%esi	#
	pushl	%ebx	#
	subl	$24, %esp	#,
	flds	44(%esp)	# aspect
	fstps	12(%esp)	# %sfp
/* src/renderer/r_main.c:365: 	r_viewchanged = true; */
	movl	$1, _r_viewchanged	#, r_viewchanged
/* src/renderer/r_main.c:367: 	R_SetVrect (pvrect, &r_refdef.vrect, lineadj); */
	movl	40(%esp), %eax	# lineadj,
	pushl	%eax	#
	pushl	$_r_refdef	#
	movl	44(%esp), %edx	# pvrect,
	pushl	%edx	#
	call	_R_SetVrect	#
/* src/renderer/r_main.c:369: 	r_refdef.horizontalFieldOfView = 2.0 * tan (r_refdef.fov_x/360*M_PI); */
	flds	LC19	#
	fmuls	_r_refdef+136	# r_refdef.fov_x
/* src/renderer/r_main.c:369: 	r_refdef.horizontalFieldOfView = 2.0 * tan (r_refdef.fov_x/360*M_PI); */
	fldl	LC20	#
	fmulp	%st, %st(1)	#,
	fptan
	fxch	%st(1)		#
/* src/renderer/r_main.c:369: 	r_refdef.horizontalFieldOfView = 2.0 * tan (r_refdef.fov_x/360*M_PI); */
	fadd	%st(0), %st	#,
/* src/renderer/r_main.c:369: 	r_refdef.horizontalFieldOfView = 2.0 * tan (r_refdef.fov_x/360*M_PI); */
	fsts	_r_refdef+100	# r_refdef.horizontalFieldOfView
/* src/renderer/r_main.c:370: 	r_refdef.fvrectx = (float)r_refdef.vrect.x; */
	fildl	_r_refdef	# r_refdef.vrect.x
/* src/renderer/r_main.c:370: 	r_refdef.fvrectx = (float)r_refdef.vrect.x; */
	fsts	_r_refdef+60	# r_refdef.fvrectx
/* src/renderer/r_main.c:371: 	r_refdef.fvrectx_adj = (float)r_refdef.vrect.x - 0.5; */
	flds	LC11	#
	fld	%st(1)	#
	fsub	%st(1), %st	#,
/* src/renderer/r_main.c:371: 	r_refdef.fvrectx_adj = (float)r_refdef.vrect.x - 0.5; */
	fstps	_r_refdef+68	# r_refdef.fvrectx_adj
/* src/renderer/r_main.c:372: 	r_refdef.vrect_x_adj_shift20 = (r_refdef.vrect.x<<20) + (1<<19) - 1; */
	movl	_r_refdef, %ecx	# r_refdef.vrect.x, tmp220
	sall	$20, %ecx	#, tmp220
/* src/renderer/r_main.c:372: 	r_refdef.vrect_x_adj_shift20 = (r_refdef.vrect.x<<20) + (1<<19) - 1; */
	addl	$524287, %ecx	#, tmp221
	movl	%ecx, _r_refdef+76	# tmp221, r_refdef.vrect_x_adj_shift20
/* src/renderer/r_main.c:373: 	r_refdef.fvrecty = (float)r_refdef.vrect.y; */
	fildl	_r_refdef+4	# r_refdef.vrect.y
/* src/renderer/r_main.c:373: 	r_refdef.fvrecty = (float)r_refdef.vrect.y; */
	fsts	_r_refdef+64	# r_refdef.fvrecty
/* src/renderer/r_main.c:374: 	r_refdef.fvrecty_adj = (float)r_refdef.vrect.y - 0.5; */
	fld	%st(0)	#
	fsub	%st(2), %st	#,
/* src/renderer/r_main.c:374: 	r_refdef.fvrecty_adj = (float)r_refdef.vrect.y - 0.5; */
	fstps	_r_refdef+72	# r_refdef.fvrecty_adj
/* src/renderer/r_main.c:375: 	r_refdef.vrectright = r_refdef.vrect.x + r_refdef.vrect.width; */
	movl	_r_refdef+8, %eax	# r_refdef.vrect.width, _16
/* src/renderer/r_main.c:375: 	r_refdef.vrectright = r_refdef.vrect.x + r_refdef.vrect.width; */
	movl	_r_refdef, %ebx	# r_refdef.vrect.x, _17
	addl	%eax, %ebx	# _16, _17
/* src/renderer/r_main.c:375: 	r_refdef.vrectright = r_refdef.vrect.x + r_refdef.vrect.width; */
	movl	%ebx, _r_refdef+40	# _17, r_refdef.vrectright
/* src/renderer/r_main.c:376: 	r_refdef.vrectright_adj_shift20 = (r_refdef.vrectright<<20) + (1<<19) - 1; */
	movl	%ebx, %esi	# _17, tmp230
	sall	$20, %esi	#, tmp230
/* src/renderer/r_main.c:376: 	r_refdef.vrectright_adj_shift20 = (r_refdef.vrectright<<20) + (1<<19) - 1; */
	addl	$524287, %esi	#, tmp231
	movl	%esi, _r_refdef+80	# tmp231, r_refdef.vrectright_adj_shift20
/* src/renderer/r_main.c:377: 	r_refdef.fvrectright = (float)r_refdef.vrectright; */
	movl	%ebx, 16(%esp)	# _17, %sfp
	fildl	16(%esp)	# %sfp
/* src/renderer/r_main.c:377: 	r_refdef.fvrectright = (float)r_refdef.vrectright; */
	fsts	_r_refdef+92	# r_refdef.fvrectright
/* src/renderer/r_main.c:378: 	r_refdef.fvrectright_adj = (float)r_refdef.vrectright - 0.5; */
	fld	%st(0)	#
	fsub	%st(3), %st	#,
/* src/renderer/r_main.c:378: 	r_refdef.fvrectright_adj = (float)r_refdef.vrectright - 0.5; */
	fstps	_r_refdef+84	# r_refdef.fvrectright_adj
/* src/renderer/r_main.c:379: 	r_refdef.vrectrightedge = (float)r_refdef.vrectright - 0.99; */
	fldl	LC21	#
	fsubrp	%st, %st(1)	#,
	fstps	_r_refdef+56	# r_refdef.vrectrightedge
/* src/renderer/r_main.c:380: 	r_refdef.vrectbottom = r_refdef.vrect.y + r_refdef.vrect.height; */
	movl	_r_refdef+4, %edx	# r_refdef.vrect.y, _26
	addl	_r_refdef+12, %edx	# r_refdef.vrect.height, _26
/* src/renderer/r_main.c:380: 	r_refdef.vrectbottom = r_refdef.vrect.y + r_refdef.vrect.height; */
	movl	%edx, _r_refdef+44	# _26, r_refdef.vrectbottom
/* src/renderer/r_main.c:381: 	r_refdef.fvrectbottom = (float)r_refdef.vrectbottom; */
	movl	%edx, 16(%esp)	# _26, %sfp
	fildl	16(%esp)	# %sfp
/* src/renderer/r_main.c:381: 	r_refdef.fvrectbottom = (float)r_refdef.vrectbottom; */
	fsts	_r_refdef+96	# r_refdef.fvrectbottom
/* src/renderer/r_main.c:382: 	r_refdef.fvrectbottom_adj = (float)r_refdef.vrectbottom - 0.5; */
	fsub	%st(2), %st	#,
/* src/renderer/r_main.c:382: 	r_refdef.fvrectbottom_adj = (float)r_refdef.vrectbottom - 0.5; */
	fstps	_r_refdef+88	# r_refdef.fvrectbottom_adj
/* src/renderer/r_main.c:384: 	r_refdef.aliasvrect.x = (int)(r_refdef.vrect.x * r_aliasuvscale); */
	flds	_r_aliasuvscale	# r_aliasuvscale
	fmul	%st, %st(3)	#,
	fxch	%st(3)		#
/* src/renderer/r_main.c:384: 	r_refdef.aliasvrect.x = (int)(r_refdef.vrect.x * r_aliasuvscale); */
	fnstcw	30(%esp)	#
	movw	30(%esp), %cx	#, tmp372
	orb	$12, %ch	#, tmp372
	movw	%cx, 28(%esp)	# tmp372,
	fldcw	28(%esp)		#
	fistpl	16(%esp)	# %sfp
	fldcw	30(%esp)		#
	movl	16(%esp), %ecx	# %sfp, _31
/* src/renderer/r_main.c:384: 	r_refdef.aliasvrect.x = (int)(r_refdef.vrect.x * r_aliasuvscale); */
	movl	%ecx, _r_refdef+20	# _31, r_refdef.aliasvrect.x
/* src/renderer/r_main.c:385: 	r_refdef.aliasvrect.y = (int)(r_refdef.vrect.y * r_aliasuvscale); */
	fmul	%st(2), %st	#,
/* src/renderer/r_main.c:385: 	r_refdef.aliasvrect.y = (int)(r_refdef.vrect.y * r_aliasuvscale); */
	fldcw	28(%esp)		#
	fistpl	16(%esp)	# %sfp
	fldcw	30(%esp)		#
	movl	16(%esp), %edx	# %sfp, _33
/* src/renderer/r_main.c:385: 	r_refdef.aliasvrect.y = (int)(r_refdef.vrect.y * r_aliasuvscale); */
	movl	%edx, _r_refdef+24	# _33, r_refdef.aliasvrect.y
/* src/renderer/r_main.c:386: 	r_refdef.aliasvrect.width = (int)(r_refdef.vrect.width * r_aliasuvscale); */
	movl	%eax, 16(%esp)	# _16, %sfp
	fildl	16(%esp)	# %sfp
	fld	%st(2)	#
	fmul	%st(1), %st	#,
/* src/renderer/r_main.c:386: 	r_refdef.aliasvrect.width = (int)(r_refdef.vrect.width * r_aliasuvscale); */
	fldcw	28(%esp)		#
	fistpl	16(%esp)	# %sfp
	fldcw	30(%esp)		#
	movl	16(%esp), %esi	# %sfp, _36
/* src/renderer/r_main.c:386: 	r_refdef.aliasvrect.width = (int)(r_refdef.vrect.width * r_aliasuvscale); */
	movl	%esi, _r_refdef+28	# _36, r_refdef.aliasvrect.width
/* src/renderer/r_main.c:387: 	r_refdef.aliasvrect.height = (int)(r_refdef.vrect.height * r_aliasuvscale); */
	fildl	_r_refdef+12	# r_refdef.vrect.height
	fld	%st(3)	#
	fmul	%st(1), %st	#,
/* src/renderer/r_main.c:387: 	r_refdef.aliasvrect.height = (int)(r_refdef.vrect.height * r_aliasuvscale); */
	fldcw	28(%esp)		#
	fistpl	16(%esp)	# %sfp
	fldcw	30(%esp)		#
	movl	16(%esp), %ebx	# %sfp, _39
/* src/renderer/r_main.c:387: 	r_refdef.aliasvrect.height = (int)(r_refdef.vrect.height * r_aliasuvscale); */
	movl	%ebx, _r_refdef+32	# _39, r_refdef.aliasvrect.height
/* src/renderer/r_main.c:388: 	r_refdef.aliasvrectright = r_refdef.aliasvrect.x + */
	addl	%esi, %ecx	# _36, tmp255
	movl	%ecx, _r_refdef+48	# tmp255, r_refdef.aliasvrectright
/* src/renderer/r_main.c:390: 	r_refdef.aliasvrectbottom = r_refdef.aliasvrect.y + */
	addl	%ebx, %edx	# _39, tmp257
	movl	%edx, _r_refdef+52	# tmp257, r_refdef.aliasvrectbottom
/* src/renderer/r_main.c:393: 	pixelAspect = aspect; */
	flds	24(%esp)	# %sfp
	fsts	_pixelAspect	# pixelAspect
/* src/renderer/r_main.c:394: 	xOrigin = r_refdef.xOrigin; */
	flds	_r_refdef+104	# r_refdef.xOrigin
	fstps	_xOrigin	# xOrigin
/* src/renderer/r_main.c:395: 	yOrigin = r_refdef.yOrigin; */
	flds	_r_refdef+108	# r_refdef.yOrigin
	fstps	_yOrigin	# yOrigin
/* src/renderer/r_main.c:397: 	screenAspect = r_refdef.vrect.width*pixelAspect / */
	fmul	%st(2), %st	#,
/* src/renderer/r_main.c:397: 	screenAspect = r_refdef.vrect.width*pixelAspect / */
	fdiv	%st(1), %st	#,
/* src/renderer/r_main.c:397: 	screenAspect = r_refdef.vrect.width*pixelAspect / */
	fsts	_screenAspect	# screenAspect
/* src/renderer/r_main.c:403: 	verticalFieldOfView = r_refdef.horizontalFieldOfView / screenAspect; */
	fdivr	%st(5), %st	#,
	fld	%st(0)	#
/* src/renderer/r_main.c:403: 	verticalFieldOfView = r_refdef.horizontalFieldOfView / screenAspect; */
	fstps	_verticalFieldOfView	# verticalFieldOfView
/* src/renderer/r_main.c:412: 			r_refdef.vrect.x - 0.5; */
	fld	%st(3)	#
	fisubrl	_r_refdef	# r_refdef.vrect.x
	fstpl	16(%esp)	# %sfp
/* src/renderer/r_main.c:411: 	xcenter = ((float)r_refdef.vrect.width * XCENTERING) + */
	fld	%st(3)	#
	fmul	%st(3), %st	#,
/* src/renderer/r_main.c:412: 			r_refdef.vrect.x - 0.5; */
	faddl	16(%esp)	# %sfp
/* src/renderer/r_main.c:411: 	xcenter = ((float)r_refdef.vrect.width * XCENTERING) + */
	fsts	_xcenter	# xcenter
/* src/renderer/r_main.c:413: 	aliasxcenter = xcenter * r_aliasuvscale; */
	fmul	%st(5), %st	#,
/* src/renderer/r_main.c:413: 	aliasxcenter = xcenter * r_aliasuvscale; */
	fstps	_aliasxcenter	# aliasxcenter
/* src/renderer/r_main.c:415: 			r_refdef.vrect.y - 0.5; */
	fld	%st(3)	#
	fisubrl	_r_refdef+4	# r_refdef.vrect.y
	fxch	%st(2)		#
/* src/renderer/r_main.c:414: 	ycenter = ((float)r_refdef.vrect.height * YCENTERING) + */
	fmulp	%st, %st(4)	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:415: 			r_refdef.vrect.y - 0.5; */
	faddp	%st, %st(3)	#,
	fxch	%st(2)		#
/* src/renderer/r_main.c:414: 	ycenter = ((float)r_refdef.vrect.height * YCENTERING) + */
	fsts	_ycenter	# ycenter
/* src/renderer/r_main.c:416: 	aliasycenter = ycenter * r_aliasuvscale; */
	fmul	%st(3), %st	#,
/* src/renderer/r_main.c:416: 	aliasycenter = ycenter * r_aliasuvscale; */
	fstps	_aliasycenter	# aliasycenter
/* src/renderer/r_main.c:418: 	xscale = r_refdef.vrect.width / r_refdef.horizontalFieldOfView; */
	fdiv	%st(3), %st	#,
/* src/renderer/r_main.c:418: 	xscale = r_refdef.vrect.width / r_refdef.horizontalFieldOfView; */
	fsts	_xscale	# xscale
/* src/renderer/r_main.c:419: 	aliasxscale = xscale * r_aliasuvscale; */
	fld	%st(2)	#
	fmul	%st(1), %st	#,
/* src/renderer/r_main.c:419: 	aliasxscale = xscale * r_aliasuvscale; */
	fstps	_aliasxscale	# aliasxscale
/* src/renderer/r_main.c:420: 	xscaleinv = 1.0 / xscale; */
	fld	%st(4)	#
	fdiv	%st(1), %st	#,
/* src/renderer/r_main.c:420: 	xscaleinv = 1.0 / xscale; */
	fstps	_xscaleinv	# xscaleinv
/* src/renderer/r_main.c:421: 	yscale = xscale * pixelAspect; */
	flds	24(%esp)	# %sfp
	fmul	%st, %st(1)	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:421: 	yscale = xscale * pixelAspect; */
	fsts	_yscale	# yscale
/* src/renderer/r_main.c:422: 	aliasyscale = yscale * r_aliasuvscale; */
	fmul	%st, %st(3)	#,
	fxch	%st(3)		#
/* src/renderer/r_main.c:422: 	aliasyscale = yscale * r_aliasuvscale; */
	fstps	_aliasyscale	# aliasyscale
	fxch	%st(2)		#
/* src/renderer/r_main.c:423: 	yscaleinv = 1.0 / yscale; */
	fdivr	%st(4), %st	#,
/* src/renderer/r_main.c:423: 	yscaleinv = 1.0 / yscale; */
	fstps	_yscaleinv	# yscaleinv
/* src/renderer/r_main.c:424: 	xscaleshrink = (r_refdef.vrect.width-6)/r_refdef.horizontalFieldOfView; */
	subl	$6, %eax	#, tmp287
/* src/renderer/r_main.c:424: 	xscaleshrink = (r_refdef.vrect.width-6)/r_refdef.horizontalFieldOfView; */
	fld	%st(2)	#
	movl	%eax, 24(%esp)	# tmp287, %sfp
	fidivrl	24(%esp)	# %sfp
/* src/renderer/r_main.c:424: 	xscaleshrink = (r_refdef.vrect.width-6)/r_refdef.horizontalFieldOfView; */
	fsts	_xscaleshrink	# xscaleshrink
/* src/renderer/r_main.c:425: 	yscaleshrink = xscaleshrink*pixelAspect; */
	fmulp	%st, %st(2)	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:425: 	yscaleshrink = xscaleshrink*pixelAspect; */
	fstps	_yscaleshrink	# yscaleshrink
/* src/renderer/r_main.c:428: 	screenedge[0].normal[0] = -1.0 / (xOrigin*r_refdef.horizontalFieldOfView); */
	flds	_r_refdef+104	# r_refdef.xOrigin
	fmul	%st(2), %st	#,
/* src/renderer/r_main.c:428: 	screenedge[0].normal[0] = -1.0 / (xOrigin*r_refdef.horizontalFieldOfView); */
	fld1
	fchs
	fdiv	%st, %st(1)	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:428: 	screenedge[0].normal[0] = -1.0 / (xOrigin*r_refdef.horizontalFieldOfView); */
	fstps	_screenedge	# screenedge[0].normal[0]
/* src/renderer/r_main.c:429: 	screenedge[0].normal[1] = 0; */
	fldz
	fsts	_screenedge+4	# screenedge[0].normal[1]
	fxch	%st(4)		#
/* src/renderer/r_main.c:430: 	screenedge[0].normal[2] = 1; */
	fsts	_screenedge+8	# screenedge[0].normal[2]
/* src/renderer/r_main.c:431: 	screenedge[0].type = PLANE_ANYZ; */
	movb	$5, _screenedge+16	#, screenedge[0].type
/* src/renderer/r_main.c:435: 			1.0 / ((1.0-xOrigin)*r_refdef.horizontalFieldOfView); */
	fld	%st(0)	#
	fsubs	_r_refdef+104	# r_refdef.xOrigin
/* src/renderer/r_main.c:435: 			1.0 / ((1.0-xOrigin)*r_refdef.horizontalFieldOfView); */
	fmulp	%st, %st(4)	#,
/* src/renderer/r_main.c:435: 			1.0 / ((1.0-xOrigin)*r_refdef.horizontalFieldOfView); */
	fdiv	%st, %st(3)	#,
	fxch	%st(3)		#
	fstps	_screenedge+20	# screenedge[1].normal[0]
	fxch	%st(3)		#
/* src/renderer/r_main.c:436: 	screenedge[1].normal[1] = 0; */
	fsts	_screenedge+24	# screenedge[1].normal[1]
	fxch	%st(2)		#
/* src/renderer/r_main.c:437: 	screenedge[1].normal[2] = 1; */
	fsts	_screenedge+28	# screenedge[1].normal[2]
	fxch	%st(2)		#
/* src/renderer/r_main.c:438: 	screenedge[1].type = PLANE_ANYZ; */
	movb	$5, _screenedge+36	#, screenedge[1].type
/* src/renderer/r_main.c:441: 	screenedge[2].normal[0] = 0; */
	fsts	_screenedge+40	# screenedge[2].normal[0]
/* src/renderer/r_main.c:442: 	screenedge[2].normal[1] = -1.0 / (yOrigin*verticalFieldOfView); */
	flds	_r_refdef+108	# r_refdef.yOrigin
	fmul	%st(2), %st	#,
/* src/renderer/r_main.c:442: 	screenedge[2].normal[1] = -1.0 / (yOrigin*verticalFieldOfView); */
	fdivrp	%st, %st(4)	#,
	fxch	%st(3)		#
/* src/renderer/r_main.c:442: 	screenedge[2].normal[1] = -1.0 / (yOrigin*verticalFieldOfView); */
	fstps	_screenedge+44	# screenedge[2].normal[1]
	fxch	%st(1)		#
/* src/renderer/r_main.c:443: 	screenedge[2].normal[2] = 1; */
	fsts	_screenedge+48	# screenedge[2].normal[2]
	fxch	%st(2)		#
/* src/renderer/r_main.c:444: 	screenedge[2].type = PLANE_ANYZ; */
	movb	$5, _screenedge+56	#, screenedge[2].type
/* src/renderer/r_main.c:447: 	screenedge[3].normal[0] = 0; */
	fstps	_screenedge+60	# screenedge[3].normal[0]
/* src/renderer/r_main.c:448: 	screenedge[3].normal[1] = 1.0 / ((1.0-yOrigin)*verticalFieldOfView); */
	fld	%st(1)	#
	fsubs	_r_refdef+108	# r_refdef.yOrigin
/* src/renderer/r_main.c:448: 	screenedge[3].normal[1] = 1.0 / ((1.0-yOrigin)*verticalFieldOfView); */
	fmulp	%st, %st(1)	#,
/* src/renderer/r_main.c:448: 	screenedge[3].normal[1] = 1.0 / ((1.0-yOrigin)*verticalFieldOfView); */
	fdivr	%st(1), %st	#,
	fstps	_screenedge+64	# screenedge[3].normal[1]
/* src/renderer/r_main.c:449: 	screenedge[3].normal[2] = 1; */
	fstps	_screenedge+68	# screenedge[3].normal[2]
/* src/renderer/r_main.c:450: 	screenedge[3].type = PLANE_ANYZ; */
	movb	$5, _screenedge+76	#, screenedge[3].type
/* src/renderer/r_main.c:453: 		VectorNormalize (screenedge[i].normal); */
	movl	$_screenedge, (%esp)	#,
	call	_VectorNormalize	#
	fstp	%st(0)		#
	movl	$_screenedge+20, (%esp)	#,
	call	_VectorNormalize	#
	fstp	%st(0)		#
	movl	$_screenedge+40, (%esp)	#,
	call	_VectorNormalize	#
	fstp	%st(0)		#
	movl	$_screenedge+60, (%esp)	#,
	call	_VectorNormalize	#
	fstp	%st(0)		#
/* src/renderer/r_main.c:455: 	res_scale = sqrt ((double)(r_refdef.vrect.width * r_refdef.vrect.height) / */
	movl	_r_refdef+8, %eax	# r_refdef.vrect.width, r_refdef.vrect.width
	imull	_r_refdef+12, %eax	# r_refdef.vrect.height, tmp340
/* src/renderer/r_main.c:455: 	res_scale = sqrt ((double)(r_refdef.vrect.width * r_refdef.vrect.height) / */
	fldl	LC23	#
	movl	%eax, 24(%esp)	# tmp340, %sfp
	fimull	24(%esp)	# %sfp
	fsqrt
/* src/renderer/r_main.c:457: 			(2.0 / r_refdef.horizontalFieldOfView); */
	flds	LC24	#
	fdivs	_r_refdef+100	# r_refdef.horizontalFieldOfView
/* src/renderer/r_main.c:456: 			          (320.0 * 152.0)) * */
	fmulp	%st, %st(1)	#,
/* src/renderer/r_main.c:458: 	r_aliastransition = r_aliastransbase.value * res_scale; */
	flds	_r_aliastransbase+16	# r_aliastransbase.value
	fmul	%st(1), %st	#,
/* src/renderer/r_main.c:458: 	r_aliastransition = r_aliastransbase.value * res_scale; */
	fstps	_r_aliastransition	# r_aliastransition
/* src/renderer/r_main.c:459: 	r_resfudge = r_aliastransadj.value * res_scale; */
	fmuls	_r_aliastransadj+16	# r_aliastransadj.value
/* src/renderer/r_main.c:459: 	r_resfudge = r_aliastransadj.value * res_scale; */
	fstps	_r_resfudge	# r_resfudge
/* src/renderer/r_main.c:461: 	if (scr_fov.value <= 90.0) */
	addl	$16, %esp	#,
	flds	_scr_fov+16	# scr_fov.value
	fcomps	LC25	#
	fnstsw	%ax	# tmp363
	testb	$69, %ah	#, tmp363
	sete	%cl	#, tmp360
	andl	$255, %ecx	#, tmp360
	movl	%ecx, _r_fov_greater_than_90	# tmp360, r_fov_greater_than_90
/* src/renderer/r_main.c:468: 	if (r_pixbytes == 1) */
	cmpl	$1, _r_pixbytes	#, r_pixbytes
	je	L57	#,
/* src/renderer/r_main.c:477: 		Sys_MakeCodeWriteable ((long)R_Surf16Start, */
	subl	$8, %esp	#,
/* src/renderer/r_main.c:478: 						     (long)R_Surf16End - (long)R_Surf16Start); */
	movl	$_R_Surf16End, %edx	#, tmp369
	subl	$_R_Surf16Start, %edx	#, tmp368
/* src/renderer/r_main.c:477: 		Sys_MakeCodeWriteable ((long)R_Surf16Start, */
	pushl	%edx	# tmp368
	pushl	$_R_Surf16Start	#
	call	_Sys_MakeCodeWriteable	#
/* src/renderer/r_main.c:479: 		colormap = vid.colormap16; */
	movl	_vid+8, %esi	# vid.colormap16, vid.colormap16
	movl	%esi, _colormap	# vid.colormap16, colormap
/* src/renderer/r_main.c:480: 		R_Surf16Patch (); */
	call	_R_Surf16Patch	#
	addl	$16, %esp	#,
/* src/renderer/r_main.c:485: } */
	addl	$20, %esp	#,
	popl	%ebx	#
	popl	%esi	#
/* src/renderer/r_main.c:484: 	D_ViewChanged (); */
	jmp	_D_ViewChanged	#
	.p2align 4
	.p2align 3
L57:
/* src/renderer/r_main.c:470: 		Sys_MakeCodeWriteable ((long)R_Surf8Start, */
	subl	$8, %esp	#,
/* src/renderer/r_main.c:471: 						     (long)R_Surf8End - (long)R_Surf8Start); */
	movl	$_R_Surf8End, %ebx	#, tmp365
	subl	$_R_Surf8Start, %ebx	#, tmp364
/* src/renderer/r_main.c:470: 		Sys_MakeCodeWriteable ((long)R_Surf8Start, */
	pushl	%ebx	# tmp364
	pushl	$_R_Surf8Start	#
	call	_Sys_MakeCodeWriteable	#
/* src/renderer/r_main.c:472: 		colormap = vid.colormap; */
	movl	_vid+4, %eax	# vid.colormap, vid.colormap
	movl	%eax, _colormap	# vid.colormap, colormap
/* src/renderer/r_main.c:473: 		R_Surf8Patch (); */
	call	_R_Surf8Patch	#
	addl	$16, %esp	#,
/* src/renderer/r_main.c:485: } */
	addl	$20, %esp	#,
	popl	%ebx	#
	popl	%esi	#
/* src/renderer/r_main.c:484: 	D_ViewChanged (); */
	jmp	_D_ViewChanged	#
	.p2align 3

.text
.p2align 3
/* R_MarkLeaves: Mark visible leaves and parent chains once per changed view leaf; preserve early termination at an already marked node.
 * Callee registers used: %ebp, %ebx, %edi, %esi.
 * Stack reservations (bytes; includes call argument areas): 20.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_MarkLeaves
_R_MarkLeaves:
/* src/renderer/r_main.c:499: 	if (r_oldviewleaf == r_viewleaf) */
	movl	_r_viewleaf, %eax	# r_viewleaf, r_viewleaf.64_2
/* src/renderer/r_main.c:499: 	if (r_oldviewleaf == r_viewleaf) */
	cmpl	%eax, _r_oldviewleaf	# r_viewleaf.64_2, r_oldviewleaf
	je	L71	#,
/* src/renderer/r_main.c:494: { */
	pushl	%ebp	#
	pushl	%edi	#
	pushl	%esi	#
	pushl	%ebx	#
	subl	$20, %esp	#,
/* src/renderer/r_main.c:502: 	r_visframecount++; */
	incl	_r_visframecount	# r_visframecount
/* src/renderer/r_main.c:503: 	r_oldviewleaf = r_viewleaf; */
	movl	%eax, _r_oldviewleaf	# r_viewleaf.64_2, r_oldviewleaf
/* src/renderer/r_main.c:505: 	vis = Mod_LeafPVS (r_viewleaf, cl.worldmodel); */
	movl	_cl+2692, %edx	# cl.worldmodel,
	pushl	%edx	#
	pushl	%eax	# r_viewleaf.64_2
	call	_Mod_LeafPVS	#
	movl	%eax, %ebx	# tmp123, vis
/* src/renderer/r_main.c:507: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	movl	_cl+2692, %esi	# cl.worldmodel, _41
/* src/renderer/r_main.c:507: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	movl	136(%esi), %edi	# _38->numleafs, prephitmp_59
/* src/renderer/r_main.c:507: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	addl	$16, %esp	#,
	testl	%edi, %edi	# prephitmp_59
	jle	L58	#,
/* src/renderer/r_main.c:514: 				if (node->visframe == r_visframecount) */
	movl	_r_visframecount, %edx	# r_visframecount, r_visframecount.69_19
/* src/renderer/r_main.c:507: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	xorl	%eax, %eax	# i
	jmp	L64	#
	.p2align 4
	.p2align 3
L75:
/* src/renderer/r_main.c:507: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	movl	%ecx, %eax	# i, i
/* src/renderer/r_main.c:507: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	cmpl	%edi, %ecx	# prephitmp_59, i
	jge	L58	#,
L64:
/* src/renderer/r_main.c:509: 		if (vis[i>>3] & (1<<(i&7))) */
	movl	%eax, %ecx	# i, tmp108
	sarl	$3, %ecx	#, tmp108
/* src/renderer/r_main.c:509: 		if (vis[i>>3] & (1<<(i&7))) */
	movzbl	(%ebx,%ecx), %ebp	# *_8, *_8
	andl	$255, %ebp	#, *_8
/* src/renderer/r_main.c:509: 		if (vis[i>>3] & (1<<(i&7))) */
	movl	%eax, %ecx	# i, tmp111
	andl	$7, %ecx	#, tmp111
/* src/renderer/r_main.c:509: 		if (vis[i>>3] & (1<<(i&7))) */
	sarl	%cl, %ebp	# tmp111, tmp112
/* src/renderer/r_main.c:511: 			node = (mnode_t *)&cl.worldmodel->leafs[i+1]; */
	leal	1(%eax), %ecx	#, i
/* src/renderer/r_main.c:509: 		if (vis[i>>3] & (1<<(i&7))) */
	andl	$1, %ebp	#, tmp112
	je	L75	#,
/* src/renderer/r_main.c:511: 			node = (mnode_t *)&cl.worldmodel->leafs[i+1]; */
	leal	2(%eax,%eax), %edi	#, tmp116
	leal	1(%eax,%edi), %eax	#, tmp117
	sall	$4, %eax	#, tmp118
/* src/renderer/r_main.c:511: 			node = (mnode_t *)&cl.worldmodel->leafs[i+1]; */
	addl	140(%esi), %eax	# _41->leafs, node
	jmp	L63	#
	.p2align 4
	.p2align 3
L62:
/* src/renderer/r_main.c:516: 				node->visframe = r_visframecount; */
	movl	%edx, 4(%eax)	# r_visframecount.69_19, node_22->visframe
/* src/renderer/r_main.c:517: 				node = node->parent; */
	movl	20(%eax), %eax	# node_22->parent, node
/* src/renderer/r_main.c:518: 			} while (node); */
	testl	%eax, %eax	# node
	je	L74	#,
L63:
/* src/renderer/r_main.c:514: 				if (node->visframe == r_visframecount) */
	cmpl	%edx, 4(%eax)	# r_visframecount.69_19, node_22->visframe
	jne	L62	#,
L74:
/* src/renderer/r_main.c:507: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	movl	_cl+2692, %esi	# cl.worldmodel, _41
/* src/renderer/r_main.c:507: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	movl	136(%esi), %edi	#, prephitmp_59
/* src/renderer/r_main.c:507: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	movl	%ecx, %eax	# i, i
/* src/renderer/r_main.c:507: 	for (i=0 ; i<cl.worldmodel->numleafs ; i++) */
	cmpl	%edi, %ecx	# prephitmp_59, i
	jl	L64	#,
L58:
/* src/renderer/r_main.c:521: } */
	addl	$12, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	popl	%ebp	#
	ret
	.p2align 4
	.p2align 3
L71:
	ret
	.p2align 3

.text
.p2align 3
/* R_DrawEntitiesOnList: Dispatch visible sprites and alias models in the original order, preserving ambient/dynamic lighting and clamp arithmetic.
 * Callee registers used: %ebp, %ebx, %edi, %esi.
 * Stack reservations (bytes; includes call argument areas): 76, 12, 12, 12.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_DrawEntitiesOnList
_R_DrawEntitiesOnList:
	pushl	%ebp	#
	pushl	%edi	#
	pushl	%esi	#
	pushl	%ebx	#
	subl	$76, %esp	#,
/* src/renderer/r_main.c:535: 	float		lightvec[3] = {-1, 0, 0}; */
	movl	$0xbf800000, 40(%esp)	#, lightvec[0]
	fldz
	fsts	44(%esp)	# lightvec[1]
	fsts	48(%esp)	# lightvec[2]
/* src/renderer/r_main.c:539: 	if (!r_drawentities.value) */
	fcomps	_r_drawentities+16	# r_drawentities.value
	fnstsw	%ax	# tmp147
	testb	$64, %ah	#, tmp147
	jne	L96	#,
/* src/renderer/r_main.c:542: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	movl	_cl_numvisedicts, %ebx	# cl_numvisedicts, prephitmp_136
/* src/renderer/r_main.c:542: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	xorl	%esi, %esi	# i
/* src/renderer/r_main.c:542: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	testl	%ebx, %ebx	# prephitmp_136
	jg	L78	#,
	jmp	L96	#
	.p2align 4
	.p2align 3
L99:
/* src/renderer/r_main.c:549: 		switch (currententity->model->type) */
	cmpl	$2, %edi	#, _6
	jne	L79	#,
/* src/renderer/r_main.c:560: 			VectorCopy (currententity->origin, r_entorigin); */
	flds	84(%edx)	# _2->origin[0]
	fsts	_r_entorigin	# r_entorigin[0]
	flds	88(%edx)	# _2->origin[1]
	fsts	_r_entorigin+4	# r_entorigin[1]
	flds	92(%edx)	# _2->origin[2]
	fsts	_r_entorigin+8	# r_entorigin[2]
	fxch	%st(2)		#
/* src/renderer/r_main.c:561: 			VectorSubtract (r_origin, r_entorigin, modelorg); */
	fsubrs	_r_origin	# r_origin[0]
	fstps	_modelorg	# modelorg[0]
	fsubrs	_r_origin+4	# r_origin[1]
	fstps	_modelorg+4	# modelorg[1]
	fsubrs	_r_origin+8	# r_origin[2]
	fstps	_modelorg+8	# modelorg[2]
/* src/renderer/r_main.c:565: 			if (R_AliasCheckBBox ()) */
	call	_R_AliasCheckBBox	#
/* src/renderer/r_main.c:565: 			if (R_AliasCheckBBox ()) */
	testl	%eax, %eax	# tmp215
	jne	L82	#,
L98:
/* src/renderer/r_main.c:542: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	movl	_cl_numvisedicts, %ebx	# cl_numvisedicts, prephitmp_136
L79:
/* src/renderer/r_main.c:542: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	incl	%esi	# i
/* src/renderer/r_main.c:542: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	cmpl	%ebx, %esi	# prephitmp_136, i
	jge	L96	#,
L78:
/* src/renderer/r_main.c:544: 		currententity = cl_visedicts[i]; */
	movl	_cl_visedicts(,%esi,4), %edx	# MEM[(struct entity_t * *)&cl_visedicts + _129 * 4], _2
/* src/renderer/r_main.c:544: 		currententity = cl_visedicts[i]; */
	movl	%edx, _currententity	# _2, currententity
/* src/renderer/r_main.c:546: 		if (currententity == &cl_entities[cl.viewentity]) */
	movl	_cl+2680, %ecx	# cl.viewentity, cl.viewentity
	leal	(%ecx,%ecx,4), %edi	#, tmp153
	addl	%edi, %edi	# tmp153, tmp154
	addl	%ecx, %edi	# cl.viewentity, tmp155
	leal	(%ecx,%edi,4), %ebp	#, tmp157
	leal	_cl_entities(,%ebp,4), %eax	#, tmp159
/* src/renderer/r_main.c:546: 		if (currententity == &cl_entities[cl.viewentity]) */
	cmpl	%eax, %edx	# tmp159, _2
	je	L79	#,
/* src/renderer/r_main.c:549: 		switch (currententity->model->type) */
	movl	132(%edx), %ecx	# _2->model, _2->model
	movl	68(%ecx), %edi	# _5->type, _6
/* src/renderer/r_main.c:549: 		switch (currententity->model->type) */
	cmpl	$1, %edi	#, _6
	jne	L99	#,
/* src/renderer/r_main.c:552: 			VectorCopy (currententity->origin, r_entorigin); */
	flds	84(%edx)	# _2->origin[0]
	fsts	_r_entorigin	# r_entorigin[0]
	flds	88(%edx)	# _2->origin[1]
	fsts	_r_entorigin+4	# r_entorigin[1]
	flds	92(%edx)	# _2->origin[2]
	fsts	_r_entorigin+8	# r_entorigin[2]
	fxch	%st(2)		#
/* src/renderer/r_main.c:553: 			VectorSubtract (r_origin, r_entorigin, modelorg); */
	fsubrs	_r_origin	# r_origin[0]
	fstps	_modelorg	# modelorg[0]
	fsubrs	_r_origin+4	# r_origin[1]
	fstps	_modelorg+4	# modelorg[1]
	fsubrs	_r_origin+8	# r_origin[2]
	fstps	_modelorg+8	# modelorg[2]
/* src/renderer/r_main.c:554: 			BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SPRITES); */
	subl	$12, %esp	#,
	pushl	$23	#
	call	_Bench486ProfileEnter	#
/* src/renderer/r_main.c:555: 			R_DrawSprite (); */
	call	_R_DrawSprite	#
/* src/renderer/r_main.c:556: 			BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:542: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	movl	_cl_numvisedicts, %ebx	# cl_numvisedicts, prephitmp_136
/* src/renderer/r_main.c:557: 			break; */
	addl	$16, %esp	#,
/* src/renderer/r_main.c:542: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	incl	%esi	# i
/* src/renderer/r_main.c:542: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	cmpl	%ebx, %esi	# prephitmp_136, i
	jl	L78	#,
L96:
/* src/renderer/r_main.c:603: } */
	addl	$76, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	popl	%ebp	#
	ret
	.p2align 4
	.p2align 3
L82:
/* src/renderer/r_main.c:567: 				j = R_LightPoint (currententity->origin); */
	subl	$12, %esp	#,
/* src/renderer/r_main.c:567: 				j = R_LightPoint (currententity->origin); */
	movl	_currententity, %ebx	# currententity, tmp221
	addl	$84, %ebx	#, tmp191
/* src/renderer/r_main.c:567: 				j = R_LightPoint (currententity->origin); */
	pushl	%ebx	# tmp191
	call	_R_LightPoint	#
/* src/renderer/r_main.c:569: 				lighting.ambientlight = j; */
	movl	%eax, 44(%esp)	# j, lighting.ambientlight
/* src/renderer/r_main.c:570: 				lighting.shadelight = j; */
	movl	%eax, 48(%esp)	# j, lighting.shadelight
/* src/renderer/r_main.c:572: 				lighting.plightvec = lightvec; */
	leal	56(%esp), %edx	#, tmp193
	movl	%edx, 52(%esp)	# tmp193, lighting.plightvec
	movl	$_cl_dlights, %ebx	#, ivtmp.243
	movl	$_cl_dlights+1024, %edi	#, _130
	addl	$16, %esp	#,
/* src/renderer/r_main.c:581: 						add = cl_dlights[lnum].radius - Length(dist); */
	leal	52(%esp), %ebp	#, tmp214
	jmp	L87	#
	.p2align 4
	.p2align 3
L101:
	fstp	%st(0)		#
	.p2align 3
	.p2align 3
L84:
/* src/renderer/r_main.c:574: 				for (lnum=0 ; lnum<MAX_DLIGHTS ; lnum++) */
	addl	$32, %ebx	#, ivtmp.243
	cmpl	%ebx, %edi	# ivtmp.243, _130
	je	L100	#,
L87:
/* src/renderer/r_main.c:576: 					if (cl_dlights[lnum].die >= cl.time) */
	flds	16(%ebx)	# MEM[(float *)_132 + 16B]
/* src/renderer/r_main.c:576: 					if (cl_dlights[lnum].die >= cl.time) */
	fcompl	_cl+572	# cl.time
	fnstsw	%ax	# tmp196
	testb	$5, %ah	#, tmp196
	jne	L84	#,
/* src/renderer/r_main.c:578: 						VectorSubtract (currententity->origin, */
	movl	_currententity, %ecx	# currententity, currententity.80_31
	flds	84(%ecx)	# currententity.80_31->origin[0]
	fsubs	(%ebx)	# MEM[(float *)_132]
	fstps	52(%esp)	# dist[0]
	flds	88(%ecx)	# currententity.80_31->origin[1]
	fsubs	4(%ebx)	# MEM[(float *)_132 + 4B]
	fstps	56(%esp)	# dist[1]
	flds	92(%ecx)	# currententity.80_31->origin[2]
	fsubs	8(%ebx)	# MEM[(float *)_132 + 8B]
	fstps	60(%esp)	# dist[2]
/* src/renderer/r_main.c:581: 						add = cl_dlights[lnum].radius - Length(dist); */
	flds	12(%ebx)	# MEM[(float *)_132 + 12B]
	fstps	8(%esp)	# %sfp
/* src/renderer/r_main.c:581: 						add = cl_dlights[lnum].radius - Length(dist); */
	subl	$12, %esp	#,
	pushl	%ebp	# tmp214
	call	_Length	#
/* src/renderer/r_main.c:581: 						add = cl_dlights[lnum].radius - Length(dist); */
	fsubrs	24(%esp)	# %sfp
/* src/renderer/r_main.c:583: 						if (add > 0) */
	addl	$16, %esp	#,
	ftst
	fnstsw	%ax	# tmp204
	testb	$69, %ah	#, tmp204
	jne	L101	#,
/* src/renderer/r_main.c:584: 							lighting.ambientlight += add; */
	fiaddl	28(%esp)	# lighting.ambientlight
	fnstcw	14(%esp)	#
	movw	14(%esp), %dx	#, tmp219
	orb	$12, %dh	#, tmp219
	movw	%dx, 12(%esp)	# tmp219,
	fldcw	12(%esp)		#
	fistpl	28(%esp)	# lighting.ambientlight
	fldcw	14(%esp)		#
/* src/renderer/r_main.c:574: 				for (lnum=0 ; lnum<MAX_DLIGHTS ; lnum++) */
	addl	$32, %ebx	#, ivtmp.243
	cmpl	%ebx, %edi	# ivtmp.243, _130
	jne	L87	#,
	.p2align 3
	.p2align 3
L100:
/* src/renderer/r_main.c:589: 				if (lighting.ambientlight > 128) */
	movl	28(%esp), %ebx	# lighting.ambientlight, _47
/* src/renderer/r_main.c:589: 				if (lighting.ambientlight > 128) */
	cmpl	$128, %ebx	#, _47
	jle	L88	#,
/* src/renderer/r_main.c:590: 					lighting.ambientlight = 128; */
	movl	$128, 28(%esp)	#, lighting.ambientlight
	movl	$128, %ebx	#, _47
L88:
/* src/renderer/r_main.c:591: 				if (lighting.ambientlight + lighting.shadelight > 192) */
	movl	32(%esp), %edi	# lighting.shadelight, tmp207
	addl	%ebx, %edi	# _47, tmp207
/* src/renderer/r_main.c:591: 				if (lighting.ambientlight + lighting.shadelight > 192) */
	cmpl	$192, %edi	#, tmp207
	jle	L89	#,
/* src/renderer/r_main.c:592: 					lighting.shadelight = 192 - lighting.ambientlight; */
	movl	$192, %ebp	#, tmp209
	subl	%ebx, %ebp	# _47, tmp210
	movl	%ebp, 32(%esp)	# tmp210, lighting.shadelight
L89:
/* src/renderer/r_main.c:594: 				R_AliasDrawModel (&lighting); */
	leal	28(%esp), %eax	#, tmp225
	call	_R_AliasDrawModel	#
	jmp	L98	#
	.p2align 3

.text
.p2align 3
/* R_DrawViewModel: Apply visibility gates, weapon minimum light, dynamic lights and the original ambient/shade clamps.
 * Callee registers used: %ebx, %esi.
 * Stack reservations (bytes; includes call argument areas): 52, 12, 12.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_DrawViewModel
_R_DrawViewModel:
	pushl	%esi	#
	pushl	%ebx	#
	subl	$52, %esp	#,
/* src/renderer/r_main.c:613: 	float		lightvec[3] = {-1, 0, 0}; */
	movl	$0xbf800000, 24(%esp)	#, lightvec[0]
	fldz
	fsts	28(%esp)	# lightvec[1]
	fsts	32(%esp)	# lightvec[2]
/* src/renderer/r_main.c:620: 	if (!r_drawviewmodel.value || r_fov_greater_than_90) */
	fcomps	_r_drawviewmodel+16	# r_drawviewmodel.value
	fnstsw	%ax	# tmp138
	testb	$64, %ah	#, tmp138
	jne	L115	#,
/* src/renderer/r_main.c:623: 	if (cl.items & IT_INVISIBILITY) */
	movl	_cl+156, %edx	# cl.items, tmp140
	andl	$524288, %edx	#, tmp140
/* src/renderer/r_main.c:623: 	if (cl.items & IT_INVISIBILITY) */
	orl	_r_fov_greater_than_90, %edx	# r_fov_greater_than_90, tmp212
	jne	L115	#,
/* src/renderer/r_main.c:626: 	if (cl.stats[STAT_HEALTH] <= 0) */
	movl	_cl+28, %ecx	# cl.stats[0],
	testl	%ecx, %ecx	#
	jle	L115	#,
/* src/renderer/r_main.c:629: 	currententity = &cl.viewent; */
	movl	$_cl+2708, _currententity	#, currententity
/* src/renderer/r_main.c:630: 	if (!currententity->model) */
	movl	_cl+2840, %ebx	# MEM[(struct entity_t *)&cl + 2708B].model,
	testl	%ebx, %ebx	#
	je	L115	#,
/* src/renderer/r_main.c:633: 	VectorCopy (currententity->origin, r_entorigin); */
	flds	_cl+2792	# MEM[(struct entity_t *)&cl + 2708B].origin[0]
	fsts	_r_entorigin	# r_entorigin[0]
	flds	_cl+2796	# MEM[(struct entity_t *)&cl + 2708B].origin[1]
	fsts	_r_entorigin+4	# r_entorigin[1]
	flds	_cl+2800	# MEM[(struct entity_t *)&cl + 2708B].origin[2]
	fsts	_r_entorigin+8	# r_entorigin[2]
	fxch	%st(2)		#
/* src/renderer/r_main.c:634: 	VectorSubtract (r_origin, r_entorigin, modelorg); */
	fsubrs	_r_origin	# r_origin[0]
	fstps	_modelorg	# modelorg[0]
	fsubrs	_r_origin+4	# r_origin[1]
	fstps	_modelorg+4	# modelorg[1]
	fsubrs	_r_origin+8	# r_origin[2]
	fstps	_modelorg+8	# modelorg[2]
/* src/renderer/r_main.c:636: 	VectorCopy (vup, viewlightvec); */
	flds	_vup	# vup[0]
	fstps	_viewlightvec	# viewlightvec[0]
	flds	_vup+4	# vup[1]
	fstps	_viewlightvec+4	# viewlightvec[1]
	flds	_vup+8	# vup[2]
	fstps	_viewlightvec+8	# viewlightvec[2]
/* src/renderer/r_main.c:637: 	VectorInverse (viewlightvec); */
	subl	$12, %esp	#,
	pushl	$_viewlightvec	#
	call	_VectorInverse	#
/* src/renderer/r_main.c:639: 	j = R_LightPoint (currententity->origin); */
	movl	_currententity, %esi	# currententity, tmp215
	addl	$84, %esi	#, tmp172
/* src/renderer/r_main.c:639: 	j = R_LightPoint (currententity->origin); */
	movl	%esi, (%esp)	# tmp172,
	call	_R_LightPoint	#
/* src/renderer/r_main.c:641: 	if (j < 24) */
	addl	$16, %esp	#,
	cmpl	$24, %eax	#, _6
	jge	L104	#,
	movl	$24, %eax	#, _6
L104:
/* src/renderer/r_main.c:643: 	r_viewlighting.ambientlight = j; */
	movl	%eax, _r_viewlighting	# _6, r_viewlighting.ambientlight
/* src/renderer/r_main.c:644: 	r_viewlighting.shadelight = j; */
	movl	%eax, _r_viewlighting+4	# _6, r_viewlighting.shadelight
	movl	$_cl_dlights, %ebx	#, ivtmp.256
/* src/renderer/r_main.c:658: 		add = dl->radius - Length(dist); */
	leal	36(%esp), %esi	#, tmp205
	.p2align 3
	.p2align 3
L109:
/* src/renderer/r_main.c:650: 		if (!dl->radius) */
	flds	12(%ebx)	# MEM <float> [(struct dlight_t *)_95 + 12B]
/* src/renderer/r_main.c:650: 		if (!dl->radius) */
	ftst
	fnstsw	%ax	# tmp176
	fstps	8(%esp)	# %sfp
	testb	$64, %ah	#, tmp176
	jne	L106	#,
/* src/renderer/r_main.c:654: 		if (dl->die < cl.time) */
	flds	16(%ebx)	# MEM <float> [(struct dlight_t *)_95 + 16B]
/* src/renderer/r_main.c:654: 		if (dl->die < cl.time) */
	fcompl	_cl+572	# cl.time
	fnstsw	%ax	# tmp179
	testb	$1, %ah	#, tmp179
	jne	L106	#,
/* src/renderer/r_main.c:657: 		VectorSubtract (currententity->origin, dl->origin, dist); */
	movl	_currententity, %edx	# currententity, currententity.90_26
	flds	84(%edx)	# currententity.90_26->origin[0]
	fsubs	(%ebx)	# MEM <vec_t> [(struct dlight_t *)_95]
	fstps	36(%esp)	# dist[0]
	flds	88(%edx)	# currententity.90_26->origin[1]
	fsubs	4(%ebx)	# MEM <vec_t> [(struct dlight_t *)_95 + 4B]
	fstps	40(%esp)	# dist[1]
	flds	92(%edx)	# currententity.90_26->origin[2]
	fsubs	8(%ebx)	# MEM <vec_t> [(struct dlight_t *)_95 + 8B]
	fstps	44(%esp)	# dist[2]
/* src/renderer/r_main.c:658: 		add = dl->radius - Length(dist); */
	subl	$12, %esp	#,
	pushl	%esi	# tmp205
	call	_Length	#
/* src/renderer/r_main.c:658: 		add = dl->radius - Length(dist); */
	flds	24(%esp)	# %sfp
	fsubp	%st, %st(1)	#,
/* src/renderer/r_main.c:659: 		if (add > 0) */
	addl	$16, %esp	#,
	ftst
	fnstsw	%ax	# tmp187
	testb	$69, %ah	#, tmp187
	jne	L117	#,
/* src/renderer/r_main.c:660: 			r_viewlighting.ambientlight += add; */
	fiaddl	_r_viewlighting	# r_viewlighting.ambientlight
	fnstcw	14(%esp)	#
	movw	14(%esp), %cx	#, tmp211
	orb	$12, %ch	#, tmp211
	movw	%cx, 12(%esp)	# tmp211,
	fldcw	12(%esp)		#
	fistpl	_r_viewlighting	# r_viewlighting.ambientlight
	fldcw	14(%esp)		#
	jmp	L106	#
	.p2align 4
	.p2align 3
L117:
	fstp	%st(0)		#
	.p2align 3
	.p2align 3
L106:
/* src/renderer/r_main.c:647: 	for (lnum=0 ; lnum<MAX_DLIGHTS ; lnum++) */
	addl	$32, %ebx	#, ivtmp.256
	cmpl	$_cl_dlights+1024, %ebx	#, ivtmp.256
	jne	L109	#,
/* src/renderer/r_main.c:664: 	if (r_viewlighting.ambientlight > 128) */
	movl	_r_viewlighting, %ebx	# r_viewlighting.ambientlight, _41
/* src/renderer/r_main.c:664: 	if (r_viewlighting.ambientlight > 128) */
	cmpl	$128, %ebx	#, _41
	jle	L110	#,
/* src/renderer/r_main.c:665: 		r_viewlighting.ambientlight = 128; */
	movl	$128, _r_viewlighting	#, r_viewlighting.ambientlight
	movl	$128, %ebx	#, _41
L110:
/* src/renderer/r_main.c:666: 	if (r_viewlighting.ambientlight + r_viewlighting.shadelight > 192) */
	movl	_r_viewlighting+4, %esi	# r_viewlighting.shadelight, tmp195
	addl	%ebx, %esi	# _41, tmp195
/* src/renderer/r_main.c:666: 	if (r_viewlighting.ambientlight + r_viewlighting.shadelight > 192) */
	cmpl	$192, %esi	#, tmp195
	jle	L111	#,
/* src/renderer/r_main.c:667: 		r_viewlighting.shadelight = 192 - r_viewlighting.ambientlight; */
	movl	$192, %edx	#, tmp198
	subl	%ebx, %edx	# _41, tmp199
	movl	%edx, _r_viewlighting+4	# tmp199, r_viewlighting.shadelight
L111:
/* src/renderer/r_main.c:669: 	r_viewlighting.plightvec = lightvec; */
	leal	24(%esp), %eax	#, tmp201
	movl	%eax, _r_viewlighting+8	# tmp201, r_viewlighting.plightvec
/* src/renderer/r_main.c:675: 	R_AliasDrawModel (&r_viewlighting); */
	movl	$_r_viewlighting, %eax	#,
	call	_R_AliasDrawModel	#
L115:
/* src/renderer/r_main.c:676: } */
	addl	$52, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	ret
	.p2align 3

.text
.p2align 3
/* R_BmodelCheckBBox: Classify rotated bounding spheres or unrotated accept/reject corners against the four view planes.
 * Callee registers used: %ebp, %ebx, %edi, %esi.
 * Stack reservations (bytes; includes call argument areas): 92, 12, 12, 12, 8.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_BmodelCheckBBox
_R_BmodelCheckBBox:
	pushl	%ebx	#
	movl	12(%esp), %ecx	# minmaxs, minmaxs
/* src/renderer/r_main.c:692: 	if (currententity->angles[0] || currententity->angles[1] */
	movl	_currententity, %edx	# currententity, currententity.93_1
/* src/renderer/r_main.c:692: 	if (currententity->angles[0] || currententity->angles[1] */
	fldz
	fcoms	120(%edx)	# currententity.93_1->angles[0]
	fnstsw	%ax	# tmp347
	testb	$64, %ah	#, tmp347
	je	L153	#,
/* src/renderer/r_main.c:692: 	if (currententity->angles[0] || currententity->angles[1] */
	fcoms	124(%edx)	# currententity.93_1->angles[1]
	fnstsw	%ax	# tmp349
	testb	$64, %ah	#, tmp349
	jne	L150	#,
	fstp	%st(0)		#
	jmp	L119	#
	.p2align 4
	.p2align 3
L153:
	fstp	%st(0)		#
L119:
/* src/renderer/r_main.c:697: 			d = DotProduct (currententity->origin, view_clipplanes[i].normal); */
	flds	84(%edx)	# currententity.93_1->origin[0]
	flds	88(%edx)	# currententity.93_1->origin[1]
	flds	92(%edx)	# currententity.93_1->origin[2]
/* src/renderer/r_main.c:700: 			if (d <= -clmodel->radius) */
	movl	8(%esp), %ecx	# clmodel, clmodel
	flds	108(%ecx)	# clmodel_92(D)->radius
/* src/renderer/r_main.c:700: 			if (d <= -clmodel->radius) */
	fld	%st(0)	#
	fchs
/* src/renderer/r_main.c:697: 			d = DotProduct (currententity->origin, view_clipplanes[i].normal); */
	flds	_view_clipplanes+4	# view_clipplanes[0].normal[1]
	fmul	%st(4), %st	#,
	flds	_view_clipplanes	# view_clipplanes[0].normal[0]
	fmul	%st(6), %st	#,
	faddp	%st, %st(1)	#,
	flds	_view_clipplanes+8	# view_clipplanes[0].normal[2]
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:698: 			d -= view_clipplanes[i].dist; */
	fsubs	_view_clipplanes+12	# view_clipplanes[0].dist
	fxch	%st(1)		#
/* src/renderer/r_main.c:700: 			if (d <= -clmodel->radius) */
	fcom	%st(1)	#
	fnstsw	%ax	# tmp363
	testb	$5, %ah	#, tmp363
	je	L154	#,
	fxch	%st(2)		#
/* src/renderer/r_main.c:703: 			if (d <= clmodel->radius) */
	fcom	%st(1)	#
	fnstsw	%ax	# tmp366
	fstp	%st(1)		#
	xorl	%edx, %edx	# <retval>
	testb	$5, %ah	#, tmp366
	sete	%dl	#, <retval>
/* src/renderer/r_main.c:697: 			d = DotProduct (currententity->origin, view_clipplanes[i].normal); */
	flds	_view_clipplanes+28	# view_clipplanes[1].normal[1]
	fmul	%st(4), %st	#,
	flds	_view_clipplanes+24	# view_clipplanes[1].normal[0]
	fmul	%st(6), %st	#,
	faddp	%st, %st(1)	#,
	flds	_view_clipplanes+32	# view_clipplanes[1].normal[2]
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:698: 			d -= view_clipplanes[i].dist; */
	fsubs	_view_clipplanes+36	# view_clipplanes[1].dist
	fxch	%st(2)		#
/* src/renderer/r_main.c:700: 			if (d <= -clmodel->radius) */
	fcom	%st(2)	#
	fnstsw	%ax	# tmp377
	testb	$5, %ah	#, tmp377
	je	L155	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:703: 			if (d <= clmodel->radius) */
	fcom	%st(2)	#
	fnstsw	%ax	# tmp378
	fstp	%st(2)		#
	testb	$5, %ah	#, tmp378
	je	L151	#,
L122:
/* src/renderer/r_main.c:697: 			d = DotProduct (currententity->origin, view_clipplanes[i].normal); */
	flds	_view_clipplanes+52	# view_clipplanes[2].normal[1]
	fmul	%st(4), %st	#,
	flds	_view_clipplanes+48	# view_clipplanes[2].normal[0]
	fmul	%st(6), %st	#,
	faddp	%st, %st(1)	#,
	flds	_view_clipplanes+56	# view_clipplanes[2].normal[2]
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:698: 			d -= view_clipplanes[i].dist; */
	fsubs	_view_clipplanes+60	# view_clipplanes[2].dist
	fxch	%st(1)		#
/* src/renderer/r_main.c:700: 			if (d <= -clmodel->radius) */
	fcom	%st(1)	#
	fnstsw	%ax	# tmp389
	testb	$5, %ah	#, tmp389
	je	L156	#,
	fxch	%st(2)		#
/* src/renderer/r_main.c:703: 			if (d <= clmodel->radius) */
	fcom	%st(1)	#
	fnstsw	%ax	# tmp390
	fstp	%st(1)		#
	testb	$5, %ah	#, tmp390
	je	L152	#,
	fxch	%st(4)		#
L124:
/* src/renderer/r_main.c:697: 			d = DotProduct (currententity->origin, view_clipplanes[i].normal); */
	fmuls	_view_clipplanes+72	# view_clipplanes[3].normal[0]
	fxch	%st(3)		#
	fmuls	_view_clipplanes+76	# view_clipplanes[3].normal[1]
	faddp	%st, %st(3)	#,
	fxch	%st(1)		#
	fmuls	_view_clipplanes+80	# view_clipplanes[3].normal[2]
	faddp	%st, %st(2)	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:698: 			d -= view_clipplanes[i].dist; */
	fsubs	_view_clipplanes+84	# view_clipplanes[3].dist
	fxch	%st(1)		#
/* src/renderer/r_main.c:700: 			if (d <= -clmodel->radius) */
	fcomp	%st(1)	#
	fnstsw	%ax	# tmp401
	testb	$5, %ah	#, tmp401
	je	L157	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:703: 			if (d <= clmodel->radius) */
	fcompp
	fnstsw	%ax	# tmp402
	testb	$5, %ah	#, tmp402
	jne	L118	#,
L149:
/* src/renderer/r_main.c:735: 				clipflags |= (1<<i); */
	orl	$8, %edx	#, <retval>
L118:
/* src/renderer/r_main.c:740: } */
	movl	%edx, %eax	# <retval>,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L151:
/* src/renderer/r_main.c:704: 				clipflags |= (1<<i); */
	orl	$2, %edx	#, <retval>
	jmp	L122	#
	.p2align 4
	.p2align 3
L152:
	fxch	%st(4)		#
	orl	$4, %edx	#, <retval>
	jmp	L124	#
	.p2align 4
	.p2align 3
L150:
/* src/renderer/r_main.c:693: 		|| currententity->angles[2]) */
	fcomps	128(%edx)	# currententity.93_1->angles[2]
	fnstsw	%ax	# tmp351
	testb	$64, %ah	#, tmp351
	je	L119	#,
/* src/renderer/r_main.c:715: 			pindex = pfrustum_indexes[i]; */
	movl	_pfrustum_indexes, %ebx	# pfrustum_indexes[0], pindex
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	_view_clipplanes	# view_clipplanes[0].normal[0]
	flds	_view_clipplanes+4	# view_clipplanes[0].normal[1]
	flds	_view_clipplanes+8	# view_clipplanes[0].normal[2]
/* src/renderer/r_main.c:718: 			rejectpt[1] = minmaxs[pindex[1]]; */
	movl	4(%ebx), %edx	# MEM[(int *)pindex_113 + 4B], MEM[(int *)pindex_113 + 4B]
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%edx,4)	# *_104
	fmul	%st(2), %st	#,
/* src/renderer/r_main.c:717: 			rejectpt[0] = minmaxs[pindex[0]]; */
	movl	(%ebx), %eax	# *pindex_113, *pindex_113
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%eax,4)	# *_109
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:719: 			rejectpt[2] = minmaxs[pindex[2]]; */
	movl	8(%ebx), %edx	# MEM[(int *)pindex_113 + 8B], MEM[(int *)pindex_113 + 8B]
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%edx,4)	# *_95
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:722: 			d -= view_clipplanes[i].dist; */
	flds	_view_clipplanes+12	# view_clipplanes[0].dist
/* src/renderer/r_main.c:722: 			d -= view_clipplanes[i].dist; */
	fsubr	%st, %st(1)	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:724: 			if (d <= 0) */
	ftst
	fnstsw	%ax	# tmp417
	fstp	%st(0)		#
	testb	$69, %ah	#, tmp417
	jne	L158	#,
	fxch	%st(3)		#
/* src/renderer/r_main.c:727: 			acceptpt[0] = minmaxs[pindex[3+0]]; */
	movl	12(%ebx), %edx	# MEM[(int *)pindex_113 + 12B], MEM[(int *)pindex_113 + 12B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%edx,4)	# *_190
	fxch	%st(2)		#
/* src/renderer/r_main.c:728: 			acceptpt[1] = minmaxs[pindex[3+1]]; */
	movl	16(%ebx), %eax	# MEM[(int *)pindex_113 + 16B], MEM[(int *)pindex_113 + 16B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%eax,4)	# *_195
	faddp	%st, %st(2)	#,
/* src/renderer/r_main.c:729: 			acceptpt[2] = minmaxs[pindex[3+2]]; */
	movl	20(%ebx), %ebx	# MEM[(int *)pindex_113 + 20B], MEM[(int *)pindex_113 + 20B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%ebx,4)	# *_200
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:732: 			d -= view_clipplanes[i].dist; */
	fsubp	%st, %st(1)	#,
/* src/renderer/r_main.c:734: 			if (d <= 0) */
	ftst
	fnstsw	%ax	# tmp429
	fstp	%st(0)		#
	xorl	%edx, %edx	# <retval>
	testb	$69, %ah	#, tmp429
	setne	%dl	#, <retval>
/* src/renderer/r_main.c:715: 			pindex = pfrustum_indexes[i]; */
	movl	_pfrustum_indexes+4, %ebx	# pfrustum_indexes[1], pindex
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	_view_clipplanes+24	# view_clipplanes[1].normal[0]
	flds	_view_clipplanes+28	# view_clipplanes[1].normal[1]
	flds	_view_clipplanes+32	# view_clipplanes[1].normal[2]
/* src/renderer/r_main.c:717: 			rejectpt[0] = minmaxs[pindex[0]]; */
	movl	(%ebx), %eax	# *pindex_217, *pindex_217
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%eax,4)	# *_221
	fmul	%st(3), %st	#,
/* src/renderer/r_main.c:718: 			rejectpt[1] = minmaxs[pindex[1]]; */
	movl	4(%ebx), %eax	# MEM[(int *)pindex_217 + 4B], MEM[(int *)pindex_217 + 4B]
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%eax,4)	# *_226
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:719: 			rejectpt[2] = minmaxs[pindex[2]]; */
	movl	8(%ebx), %eax	# MEM[(int *)pindex_217 + 8B], MEM[(int *)pindex_217 + 8B]
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%eax,4)	# *_231
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:722: 			d -= view_clipplanes[i].dist; */
	flds	_view_clipplanes+36	# view_clipplanes[1].dist
/* src/renderer/r_main.c:722: 			d -= view_clipplanes[i].dist; */
	fsubr	%st, %st(1)	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:724: 			if (d <= 0) */
	ftst
	fnstsw	%ax	# tmp444
	fstp	%st(0)		#
	testb	$69, %ah	#, tmp444
	jne	L159	#,
	fxch	%st(3)		#
/* src/renderer/r_main.c:727: 			acceptpt[0] = minmaxs[pindex[3+0]]; */
	movl	12(%ebx), %eax	# MEM[(int *)pindex_217 + 12B], MEM[(int *)pindex_217 + 12B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%eax,4)	# *_248
	fxch	%st(2)		#
/* src/renderer/r_main.c:728: 			acceptpt[1] = minmaxs[pindex[3+1]]; */
	movl	16(%ebx), %eax	# MEM[(int *)pindex_217 + 16B], MEM[(int *)pindex_217 + 16B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%eax,4)	# *_253
	faddp	%st, %st(2)	#,
/* src/renderer/r_main.c:729: 			acceptpt[2] = minmaxs[pindex[3+2]]; */
	movl	20(%ebx), %ebx	# MEM[(int *)pindex_217 + 20B], MEM[(int *)pindex_217 + 20B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%ebx,4)	# *_258
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:732: 			d -= view_clipplanes[i].dist; */
	fsubp	%st, %st(1)	#,
/* src/renderer/r_main.c:734: 			if (d <= 0) */
	ftst
	fnstsw	%ax	# tmp454
	fstp	%st(0)		#
	testb	$69, %ah	#, tmp454
	je	L128	#,
/* src/renderer/r_main.c:735: 				clipflags |= (1<<i); */
	orl	$2, %edx	#, <retval>
L128:
/* src/renderer/r_main.c:715: 			pindex = pfrustum_indexes[i]; */
	movl	_pfrustum_indexes+8, %ebx	# pfrustum_indexes[2], pindex
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	_view_clipplanes+48	# view_clipplanes[2].normal[0]
	flds	_view_clipplanes+52	# view_clipplanes[2].normal[1]
	flds	_view_clipplanes+56	# view_clipplanes[2].normal[2]
/* src/renderer/r_main.c:717: 			rejectpt[0] = minmaxs[pindex[0]]; */
	movl	(%ebx), %eax	# *pindex_275, *pindex_275
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%eax,4)	# *_279
	fmul	%st(3), %st	#,
/* src/renderer/r_main.c:718: 			rejectpt[1] = minmaxs[pindex[1]]; */
	movl	4(%ebx), %eax	# MEM[(int *)pindex_275 + 4B], MEM[(int *)pindex_275 + 4B]
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%eax,4)	# *_284
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:719: 			rejectpt[2] = minmaxs[pindex[2]]; */
	movl	8(%ebx), %eax	# MEM[(int *)pindex_275 + 8B], MEM[(int *)pindex_275 + 8B]
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%eax,4)	# *_289
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:722: 			d -= view_clipplanes[i].dist; */
	flds	_view_clipplanes+60	# view_clipplanes[2].dist
/* src/renderer/r_main.c:722: 			d -= view_clipplanes[i].dist; */
	fsubr	%st, %st(1)	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:724: 			if (d <= 0) */
	ftst
	fnstsw	%ax	# tmp469
	fstp	%st(0)		#
	testb	$69, %ah	#, tmp469
	jne	L160	#,
	fxch	%st(3)		#
/* src/renderer/r_main.c:727: 			acceptpt[0] = minmaxs[pindex[3+0]]; */
	movl	12(%ebx), %eax	# MEM[(int *)pindex_275 + 12B], MEM[(int *)pindex_275 + 12B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%eax,4)	# *_306
	fxch	%st(2)		#
/* src/renderer/r_main.c:728: 			acceptpt[1] = minmaxs[pindex[3+1]]; */
	movl	16(%ebx), %eax	# MEM[(int *)pindex_275 + 16B], MEM[(int *)pindex_275 + 16B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%eax,4)	# *_311
	faddp	%st, %st(2)	#,
/* src/renderer/r_main.c:729: 			acceptpt[2] = minmaxs[pindex[3+2]]; */
	movl	20(%ebx), %ebx	# MEM[(int *)pindex_275 + 20B], MEM[(int *)pindex_275 + 20B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%ebx,4)	# *_316
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:732: 			d -= view_clipplanes[i].dist; */
	fsubp	%st, %st(1)	#,
/* src/renderer/r_main.c:734: 			if (d <= 0) */
	ftst
	fnstsw	%ax	# tmp479
	fstp	%st(0)		#
	testb	$69, %ah	#, tmp479
	je	L130	#,
/* src/renderer/r_main.c:735: 				clipflags |= (1<<i); */
	orl	$4, %edx	#, <retval>
L130:
/* src/renderer/r_main.c:715: 			pindex = pfrustum_indexes[i]; */
	movl	_pfrustum_indexes+12, %ebx	# pfrustum_indexes[3], pindex
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	_view_clipplanes+72	# view_clipplanes[3].normal[0]
	flds	_view_clipplanes+76	# view_clipplanes[3].normal[1]
	flds	_view_clipplanes+80	# view_clipplanes[3].normal[2]
/* src/renderer/r_main.c:717: 			rejectpt[0] = minmaxs[pindex[0]]; */
	movl	(%ebx), %eax	# *pindex_82, *pindex_82
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%eax,4)	# *_27
	fmul	%st(3), %st	#,
/* src/renderer/r_main.c:718: 			rejectpt[1] = minmaxs[pindex[1]]; */
	movl	4(%ebx), %eax	# MEM[(int *)pindex_82 + 4B], MEM[(int *)pindex_82 + 4B]
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%eax,4)	# *_32
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:719: 			rejectpt[2] = minmaxs[pindex[2]]; */
	movl	8(%ebx), %eax	# MEM[(int *)pindex_82 + 8B], MEM[(int *)pindex_82 + 8B]
/* src/renderer/r_main.c:721: 			d = DotProduct (rejectpt, view_clipplanes[i].normal); */
	flds	(%ecx,%eax,4)	# *_37
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:722: 			d -= view_clipplanes[i].dist; */
	flds	_view_clipplanes+84	# view_clipplanes[3].dist
/* src/renderer/r_main.c:722: 			d -= view_clipplanes[i].dist; */
	fsubr	%st, %st(1)	#,
	fxch	%st(1)		#
/* src/renderer/r_main.c:724: 			if (d <= 0) */
	ftst
	fnstsw	%ax	# tmp494
	fstp	%st(0)		#
	testb	$69, %ah	#, tmp494
	jne	L161	#,
	fxch	%st(3)		#
/* src/renderer/r_main.c:727: 			acceptpt[0] = minmaxs[pindex[3+0]]; */
	movl	12(%ebx), %eax	# MEM[(int *)pindex_82 + 12B], MEM[(int *)pindex_82 + 12B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%eax,4)	# *_52
	fxch	%st(2)		#
/* src/renderer/r_main.c:728: 			acceptpt[1] = minmaxs[pindex[3+1]]; */
	movl	16(%ebx), %eax	# MEM[(int *)pindex_82 + 16B], MEM[(int *)pindex_82 + 16B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%eax,4)	# *_57
	faddp	%st, %st(2)	#,
/* src/renderer/r_main.c:729: 			acceptpt[2] = minmaxs[pindex[3+2]]; */
	movl	20(%ebx), %ebx	# MEM[(int *)pindex_82 + 20B], MEM[(int *)pindex_82 + 20B]
/* src/renderer/r_main.c:731: 			d = DotProduct (acceptpt, view_clipplanes[i].normal); */
	fmuls	(%ecx,%ebx,4)	# *_62
	faddp	%st, %st(1)	#,
/* src/renderer/r_main.c:732: 			d -= view_clipplanes[i].dist; */
	fsubp	%st, %st(1)	#,
/* src/renderer/r_main.c:734: 			if (d <= 0) */
	ftst
	fnstsw	%ax	# tmp504
	fstp	%st(0)		#
	testb	$69, %ah	#, tmp504
	je	L118	#,
	jmp	L149	#
	.p2align 4
	.p2align 3
L154:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	jmp	L141	#
	.p2align 4
	.p2align 3
L155:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	jmp	L141	#
L156:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	jmp	L141	#
L157:
	fstp	%st(0)		#
	fstp	%st(0)		#
	jmp	L141	#
L158:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	jmp	L141	#
L159:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	jmp	L141	#
L160:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	jmp	L141	#
L161:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
L141:
/* src/renderer/r_main.c:701: 				return BMODEL_FULLY_CLIPPED; */
	movl	$16, %edx	#, <retval>
/* src/renderer/r_main.c:740: } */
	movl	%edx, %eax	# <retval>,
	popl	%ebx	#
	ret
	.p2align 3
_R_DrawBEntitiesOnList.part.0:
	pushl	%ebp	#
	pushl	%edi	#
	pushl	%esi	#
	pushl	%ebx	#
	subl	$92, %esp	#,
/* src/renderer/r_main.c:758: 	VectorCopy (modelorg, oldorigin); */
	flds	_modelorg	# modelorg[0]
	flds	_modelorg+4	# modelorg[1]
	flds	_modelorg+8	# modelorg[2]
/* src/renderer/r_main.c:759: 	insubmodel = true; */
	movl	$1, _insubmodel	#, insubmodel
/* src/renderer/r_main.c:760: 	r_dlightframecount = r_framecount; */
	movl	_r_framecount, %eax	# r_framecount, r_framecount
	movl	%eax, _r_dlightframecount	# r_framecount, r_dlightframecount
/* src/renderer/r_main.c:762: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	movl	_cl_numvisedicts, %esi	# cl_numvisedicts, prephitmp_11
	testl	%esi, %esi	# prephitmp_11
	jle	L188	#,
	fxch	%st(2)		#
	xorl	%ebp, %ebp	# i
	fstps	36(%esp)	# %sfp
	fstps	40(%esp)	# %sfp
	fstps	44(%esp)	# %sfp
	jmp	L163	#
	.p2align 4
	.p2align 3
L164:
/* src/renderer/r_main.c:762: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	incl	%ebp	# i
/* src/renderer/r_main.c:762: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	cmpl	%esi, %ebp	# prephitmp_11, i
	jge	L175	#,
L163:
/* src/renderer/r_main.c:764: 		currententity = cl_visedicts[i]; */
	movl	_cl_visedicts(,%ebp,4), %edx	# MEM[(struct entity_t * *)&cl_visedicts + _138 * 4], _6
/* src/renderer/r_main.c:764: 		currententity = cl_visedicts[i]; */
	movl	%edx, _currententity	# _6, currententity
/* src/renderer/r_main.c:766: 		switch (currententity->model->type) */
	movl	132(%edx), %ebx	# _6->model, _7
/* src/renderer/r_main.c:766: 		switch (currententity->model->type) */
	movl	68(%ebx), %ecx	# _7->type,
	testl	%ecx, %ecx	#
	jne	L164	#,
/* src/renderer/r_main.c:776: 				minmaxs[j] = currententity->origin[j] + */
	flds	84(%edx)	# _6->origin[0]
/* src/renderer/r_main.c:776: 				minmaxs[j] = currententity->origin[j] + */
	flds	84(%ebx)	# MEM[(struct model_t *)_7].mins[0]
	fadd	%st(1), %st	#,
	fsts	12(%esp)	# %sfp
/* src/renderer/r_main.c:776: 				minmaxs[j] = currententity->origin[j] + */
	fstps	56(%esp)	# minmaxs[0]
/* src/renderer/r_main.c:778: 				minmaxs[3+j] = currententity->origin[j] + */
	fld	%st(0)	#
	fstps	8(%esp)	# %sfp
	fadds	96(%ebx)	# MEM[(struct model_t *)_7].maxs[0]
	fsts	16(%esp)	# %sfp
/* src/renderer/r_main.c:778: 				minmaxs[3+j] = currententity->origin[j] + */
	fstps	68(%esp)	# minmaxs[3]
/* src/renderer/r_main.c:776: 				minmaxs[j] = currententity->origin[j] + */
	flds	88(%edx)	# _6->origin[1]
/* src/renderer/r_main.c:776: 				minmaxs[j] = currententity->origin[j] + */
	flds	88(%ebx)	# MEM[(struct model_t *)_7].mins[1]
	fadd	%st(1), %st	#,
	fsts	20(%esp)	# %sfp
/* src/renderer/r_main.c:776: 				minmaxs[j] = currententity->origin[j] + */
	fstps	60(%esp)	# minmaxs[1]
/* src/renderer/r_main.c:778: 				minmaxs[3+j] = currententity->origin[j] + */
	fld	%st(0)	#
	fstps	4(%esp)	# %sfp
	fadds	100(%ebx)	# MEM[(struct model_t *)_7].maxs[1]
	fsts	24(%esp)	# %sfp
/* src/renderer/r_main.c:778: 				minmaxs[3+j] = currententity->origin[j] + */
	fstps	72(%esp)	# minmaxs[4]
/* src/renderer/r_main.c:776: 				minmaxs[j] = currententity->origin[j] + */
	flds	92(%edx)	# _6->origin[2]
/* src/renderer/r_main.c:776: 				minmaxs[j] = currententity->origin[j] + */
	flds	92(%ebx)	# MEM[(struct model_t *)_7].mins[2]
	fadd	%st(1), %st	#,
	fsts	28(%esp)	# %sfp
/* src/renderer/r_main.c:776: 				minmaxs[j] = currententity->origin[j] + */
	fstps	64(%esp)	# minmaxs[2]
/* src/renderer/r_main.c:778: 				minmaxs[3+j] = currententity->origin[j] + */
	fld	%st(0)	#
	fstps	(%esp)	# %sfp
	fadds	104(%ebx)	# MEM[(struct model_t *)_7].maxs[2]
	fsts	32(%esp)	# %sfp
/* src/renderer/r_main.c:778: 				minmaxs[3+j] = currententity->origin[j] + */
	fstps	76(%esp)	# minmaxs[5]
/* src/renderer/r_main.c:782: 			clipflags = R_BmodelCheckBBox (clmodel, minmaxs); */
	leal	56(%esp), %edi	#, tmp253
	pushl	%edi	# tmp253
	pushl	%ebx	# _7
	call	_R_BmodelCheckBBox	#
	popl	%edi	#
	popl	%edx	#
	movl	%eax, %edi	# tmp228, clipflags
/* src/renderer/r_main.c:784: 			if (clipflags != BMODEL_FULLY_CLIPPED) */
	cmpl	$16, %eax	#, clipflags
	je	L164	#,
/* src/renderer/r_main.c:786: 				VectorCopy (currententity->origin, r_entorigin); */
	flds	8(%esp)	# %sfp
	fsts	_r_entorigin	# r_entorigin[0]
	flds	4(%esp)	# %sfp
	fsts	_r_entorigin+4	# r_entorigin[1]
	flds	(%esp)	# %sfp
	fsts	_r_entorigin+8	# r_entorigin[2]
	fxch	%st(2)		#
/* src/renderer/r_main.c:787: 				VectorSubtract (r_origin, r_entorigin, modelorg); */
	fsubrs	_r_origin	# r_origin[0]
	fsts	_modelorg	# modelorg[0]
	fxch	%st(1)		#
	fsubrs	_r_origin+4	# r_origin[1]
	fsts	_modelorg+4	# modelorg[1]
	fxch	%st(2)		#
	fsubrs	_r_origin+8	# r_origin[2]
	fsts	_modelorg+8	# modelorg[2]
	fxch	%st(1)		#
/* src/renderer/r_main.c:789: 				VectorCopy (modelorg, r_worldmodelorg); */
	fstps	_r_worldmodelorg	# r_worldmodelorg[0]
	fxch	%st(1)		#
	fstps	_r_worldmodelorg+4	# r_worldmodelorg[1]
	fstps	_r_worldmodelorg+8	# r_worldmodelorg[2]
/* src/renderer/r_main.c:791: 				r_pcurrentvertbase = clmodel->vertexes; */
	movl	148(%ebx), %esi	# MEM[(struct model_t *)_7].vertexes, MEM[(struct model_t *)_7].vertexes
	movl	%esi, _r_pcurrentvertbase	# MEM[(struct model_t *)_7].vertexes, r_pcurrentvertbase
/* src/renderer/r_main.c:794: 				R_RotateBmodel (); */
	call	_R_RotateBmodel	#
/* src/renderer/r_main.c:798: 				if (clmodel->firstmodelsurface != 0) */
	movl	112(%ebx), %eax	# MEM[(struct model_t *)_7].firstmodelsurface,
	testl	%eax, %eax	#
	jne	L166	#,
L171:
/* src/renderer/r_main.c:816: 				if (r_drawpolys | r_drawculledpolys) */
	movl	_r_drawpolys, %esi	# r_drawpolys, r_drawpolys
	orl	_r_drawculledpolys, %esi	# r_drawculledpolys, tmp229
	je	L187	#,
/* src/renderer/r_main.c:818: 					R_ZDrawSubmodelPolys (clmodel); */
	subl	$12, %esp	#,
	pushl	%ebx	# _7
	call	_R_ZDrawSubmodelPolys	#
	addl	$16, %esp	#,
L172:
/* src/renderer/r_main.c:856: 				VectorCopy (base_vpn, vpn); */
	flds	_base_vpn	# base_vpn[0]
	fstps	_vpn	# vpn[0]
	flds	_base_vpn+4	# base_vpn[1]
	fstps	_vpn+4	# vpn[1]
	flds	_base_vpn+8	# base_vpn[2]
	fstps	_vpn+8	# vpn[2]
/* src/renderer/r_main.c:857: 				VectorCopy (base_vup, vup); */
	flds	_base_vup	# base_vup[0]
	fstps	_vup	# vup[0]
	flds	_base_vup+4	# base_vup[1]
	fstps	_vup+4	# vup[1]
	flds	_base_vup+8	# base_vup[2]
	fstps	_vup+8	# vup[2]
/* src/renderer/r_main.c:858: 				VectorCopy (base_vright, vright); */
	flds	_base_vright	# base_vright[0]
	fstps	_vright	# vright[0]
	flds	_base_vright+4	# base_vright[1]
	fstps	_vright+4	# vright[1]
	flds	_base_vright+8	# base_vright[2]
	fstps	_vright+8	# vright[2]
/* src/renderer/r_main.c:860: 				VectorCopy (oldorigin, modelorg); */
	flds	36(%esp)	# %sfp
	fstps	_modelorg	# modelorg[0]
	flds	40(%esp)	# %sfp
	fstps	_modelorg+4	# modelorg[1]
	flds	44(%esp)	# %sfp
	fstps	_modelorg+8	# modelorg[2]
/* src/renderer/r_main.c:861: 				R_TransformFrustum (); */
	call	_R_TransformFrustum	#
/* src/renderer/r_main.c:762: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	movl	_cl_numvisedicts, %esi	# cl_numvisedicts, prephitmp_11
/* src/renderer/r_main.c:762: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	incl	%ebp	# i
/* src/renderer/r_main.c:762: 	for (i=0 ; i<cl_numvisedicts ; i++) */
	cmpl	%esi, %ebp	# prephitmp_11, i
	jl	L163	#,
	jmp	L175	#
	.p2align 4
	.p2align 3
L188:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
L175:
/* src/renderer/r_main.c:871: 	insubmodel = false; */
	movl	$0, _insubmodel	#, insubmodel
/* src/renderer/r_main.c:872: } */
	addl	$92, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	popl	%ebp	#
	ret
	.p2align 4
	.p2align 3
L187:
/* src/renderer/r_main.c:822: 					r_pefragtopnode = NULL; */
	movl	$0, _r_pefragtopnode	#, r_pefragtopnode
/* src/renderer/r_main.c:826: 						r_emins[j] = minmaxs[j]; */
	flds	12(%esp)	# %sfp
	fstps	_r_emins	# r_emins[0]
/* src/renderer/r_main.c:827: 						r_emaxs[j] = minmaxs[3+j]; */
	flds	16(%esp)	# %sfp
	fstps	_r_emaxs	# r_emaxs[0]
/* src/renderer/r_main.c:826: 						r_emins[j] = minmaxs[j]; */
	flds	20(%esp)	# %sfp
	fstps	_r_emins+4	# r_emins[1]
/* src/renderer/r_main.c:827: 						r_emaxs[j] = minmaxs[3+j]; */
	flds	24(%esp)	# %sfp
	fstps	_r_emaxs+4	# r_emaxs[1]
/* src/renderer/r_main.c:826: 						r_emins[j] = minmaxs[j]; */
	flds	28(%esp)	# %sfp
	fstps	_r_emins+8	# r_emins[2]
/* src/renderer/r_main.c:827: 						r_emaxs[j] = minmaxs[3+j]; */
	flds	32(%esp)	# %sfp
	fstps	_r_emaxs+8	# r_emaxs[2]
/* src/renderer/r_main.c:830: 					R_SplitEntityOnNode2 (cl.worldmodel->nodes); */
	subl	$12, %esp	#,
	movl	_cl+2692, %eax	# cl.worldmodel, cl.worldmodel
	movl	164(%eax), %edx	# _50->nodes,
	pushl	%edx	#
	call	_R_SplitEntityOnNode2	#
/* src/renderer/r_main.c:832: 					if (r_pefragtopnode) */
	movl	_r_pefragtopnode, %ecx	# r_pefragtopnode, r_pefragtopnode.109_52
/* src/renderer/r_main.c:832: 					if (r_pefragtopnode) */
	addl	$16, %esp	#,
	testl	%ecx, %ecx	# r_pefragtopnode.109_52
	je	L172	#,
/* src/renderer/r_main.c:834: 						currententity->topnode = r_pefragtopnode; */
	movl	_currententity, %esi	# currententity, currententity
	movl	%ecx, 176(%esi)	# r_pefragtopnode.109_52, currententity.110_53->topnode
/* src/renderer/r_main.c:836: 						if (r_pefragtopnode->contents >= 0) */
	movl	(%ecx), %eax	# r_pefragtopnode.109_52->contents,
	testl	%eax, %eax	#
	js	L173	#,
/* src/renderer/r_main.c:839: 							r_clipflags = clipflags; */
	movl	%edi, _r_clipflags	# clipflags, r_clipflags
/* src/renderer/r_main.c:840: 							R_DrawSolidClippedSubmodelPolygons (clmodel); */
	subl	$12, %esp	#,
	pushl	%ebx	# _7
	call	_R_DrawSolidClippedSubmodelPolygons	#
	addl	$16, %esp	#,
L174:
/* src/renderer/r_main.c:850: 						currententity->topnode = NULL; */
	movl	_currententity, %ebx	# currententity, currententity
	movl	$0, 176(%ebx)	#, currententity.113_55->topnode
	jmp	L172	#
	.p2align 4
	.p2align 3
L166:
	movl	$_cl_dlights, %esi	#, ivtmp.275
/* src/renderer/r_main.c:800: 					for (k=0 ; k<MAX_DLIGHTS ; k++) */
	xorl	%edx, %edx	# k
/* src/renderer/r_main.c:808: 						R_MarkLights (&cl_dlights[k], 1<<k, */
	movl	%edi, (%esp)	# clipflags, %sfp
	movl	%ebx, %edi	# _7, _7
	movl	%edx, %ebx	# k, k
	.p2align 3
	.p2align 3
L170:
/* src/renderer/r_main.c:802: 						if ((cl_dlights[k].die < cl.time) || */
	flds	16(%esi)	# MEM[(float *)_145 + 16B]
/* src/renderer/r_main.c:802: 						if ((cl_dlights[k].die < cl.time) || */
	fcompl	_cl+572	# cl.time
	fnstsw	%ax	# tmp173
	testb	$1, %ah	#, tmp173
	jne	L169	#,
/* src/renderer/r_main.c:802: 						if ((cl_dlights[k].die < cl.time) || */
	fldz
	fcomps	12(%esi)	# MEM[(float *)_145 + 12B]
	fnstsw	%ax	# tmp175
	testb	$64, %ah	#, tmp175
	jne	L169	#,
/* src/renderer/r_main.c:808: 						R_MarkLights (&cl_dlights[k], 1<<k, */
	pushl	%ecx	#
/* src/renderer/r_main.c:809: 							clmodel->nodes + clmodel->hulls[0].firstclipnode); */
	movl	216(%edi), %ecx	# MEM[(struct model_t *)_7].hulls[0].firstclipnode, MEM[(struct model_t *)_7].hulls[0].firstclipnode
	leal	(%ecx,%ecx,4), %edx	#, tmp179
/* src/renderer/r_main.c:808: 						R_MarkLights (&cl_dlights[k], 1<<k, */
	movl	164(%edi), %eax	# MEM[(struct model_t *)_7].nodes, MEM[(struct model_t *)_7].nodes
	leal	(%eax,%edx,8), %ecx	#, tmp181
	pushl	%ecx	# tmp181
	movl	$1, %edx	#, tmp183
	movb	%bl, %cl	# k, tmp255
	sall	%cl, %edx	# tmp255, tmp183
	pushl	%edx	# tmp183
	pushl	%esi	# ivtmp.275
	call	_R_MarkLights	#
	addl	$16, %esp	#,
L169:
/* src/renderer/r_main.c:800: 					for (k=0 ; k<MAX_DLIGHTS ; k++) */
	incl	%ebx	# k
/* src/renderer/r_main.c:800: 					for (k=0 ; k<MAX_DLIGHTS ; k++) */
	addl	$32, %esi	#, ivtmp.275
	cmpl	$32, %ebx	#, k
	jne	L170	#,
	movl	%edi, %ebx	# _7, _7
	movl	(%esp), %edi	# %sfp, clipflags
	jmp	L171	#
	.p2align 4
	.p2align 3
L173:
/* src/renderer/r_main.c:847: 							R_DrawSubmodelPolygons (clmodel, clipflags); */
	subl	$8, %esp	#,
	pushl	%edi	# clipflags
	pushl	%ebx	# _7
	call	_R_DrawSubmodelPolygons	#
	addl	$16, %esp	#,
	jmp	L174	#
	.p2align 3

.text
.p2align 3
/* R_DrawBEntitiesOnList: Transform, light, clip and submit brush entities; restore view basis/model origin after each entity.
 * Callee registers used: none.
 * Stack reservations (bytes; includes call argument areas): none.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_DrawBEntitiesOnList
_R_DrawBEntitiesOnList:
/* src/renderer/r_main.c:755: 	if (!r_drawentities.value) */
	fldz
	fcomps	_r_drawentities+16	# r_drawentities.value
	fnstsw	%ax	# tmp85
	testb	$64, %ah	#, tmp85
	jne	L189	#,
	jmp	_R_DrawBEntitiesOnList.part.0	#
	.p2align 4
	.p2align 3
L189:
/* src/renderer/r_main.c:872: } */
	ret
	.p2align 3

.text
.p2align 3
/* R_EdgeDrawing: Own aligned frame-local edge/surface arrays and preserve world/brush/span submission and sound-buffer ordering.
 * Callee registers used: none.
 * Stack reservations (bytes; includes call argument areas): 128136, 12.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_EdgeDrawing_frame_reference
_R_EdgeDrawing_frame_reference:
	subl	$128136, %esp	#,
/* src/renderer/r_main.c:909: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_EDGE_DRAWING); */
	pushl	$9	#
	call	_Bench486ProfileEnter	#
/* src/renderer/r_main.c:911: 	if (auxedges) */
	movl	_auxedges, %eax	# auxedges, auxedges.115_1
/* src/renderer/r_main.c:911: 	if (auxedges) */
	addl	$16, %esp	#,
	testl	%eax, %eax	# auxedges.115_1
	je	L205	#,
L192:
	movl	%eax, _r_edges	# auxedges.115_1, r_edges
/* src/renderer/r_main.c:921: 	if (r_surfsonstack) */
	movl	_r_surfsonstack, %edx	# r_surfsonstack,
	testl	%edx, %edx	#
	jne	L206	#,
L193:
/* src/renderer/r_main.c:932: 	R_BeginEdgeFrame (); */
	call	_R_BeginEdgeFrame	#
/* src/renderer/r_main.c:934: 	if (r_dspeeds.value) */
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp130
	testb	$64, %ah	#, tmp130
	je	L207	#,
L194:
/* src/renderer/r_main.c:940: 	if (bench486_profile_frame_active) */
	movl	_bench486_profile_frame_active, %edx	# bench486_profile_frame_active,
	testl	%edx, %edx	#
	jne	L208	#,
L195:
/* src/renderer/r_main.c:943: 	R_RenderWorld (); */
	call	_R_RenderWorld	#
/* src/renderer/r_main.c:945: 	if (bench486_profile_frame_active) */
	movl	_bench486_profile_frame_active, %ecx	# bench486_profile_frame_active,
	testl	%ecx, %ecx	#
	jne	L209	#,
L196:
/* src/renderer/r_main.c:949: 	if (r_drawculledpolys) */
	movl	_r_drawculledpolys, %eax	# r_drawculledpolys,
	testl	%eax, %eax	#
	jne	L210	#,
L197:
/* src/renderer/r_main.c:954: 	D_TurnZOn (); */
	call	_D_TurnZOn	#
/* src/renderer/r_main.c:956: 	if (r_dspeeds.value) */
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp136
	testb	$64, %ah	#, tmp136
	je	L211	#,
L198:
/* src/renderer/r_main.c:962: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_BRUSH_ENTITIES); */
	subl	$12, %esp	#,
	pushl	$21	#
	call	_Bench486ProfileEnter	#
/* src/renderer/r_main.c:755: 	if (!r_drawentities.value) */
	addl	$16, %esp	#,
	fldz
	fcomps	_r_drawentities+16	# r_drawentities.value
	fnstsw	%ax	# tmp139
	testb	$64, %ah	#, tmp139
	jne	L199	#,
	call	_R_DrawBEntitiesOnList.part.0	#
L199:
/* src/renderer/r_main.c:964: 	BENCH486_PROFILE_WORK (BENCH486_PROFILE_BRUSH_ENTITIES, */
	pushl	%eax	#
	pushl	$0	#
	movl	_cl_numvisedicts, %edx	# cl_numvisedicts,
	pushl	%edx	#
	pushl	$21	#
	call	_Bench486ProfileWork	#
/* src/renderer/r_main.c:966: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:968: 	if (r_dspeeds.value) */
	addl	$16, %esp	#,
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp142
	testb	$64, %ah	#, tmp142
	je	L200	#,
L202:
/* src/renderer/r_main.c:977: 		S_ExtraUpdate ();	// don't let sound get messed up if going slow */
	call	_S_ExtraUpdate	#
/* src/renderer/r_main.c:981: 	if (!(r_drawpolys | r_drawculledpolys)) */
	movl	_r_drawpolys, %ecx	# r_drawpolys, r_drawpolys
	orl	_r_drawculledpolys, %ecx	# r_drawculledpolys, tmp157
	je	L212	#,
L203:
/* src/renderer/r_main.c:983: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:984: } */
	addl	$128124, %esp	#,
	ret
	.p2align 4
	.p2align 3
L200:
/* src/renderer/r_main.c:970: 		db_time2 = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
/* src/renderer/r_main.c:970: 		db_time2 = Sys_FloatTime (); */
	fsts	_db_time2	# db_time2
/* src/renderer/r_main.c:971: 		se_time1 = db_time2; */
	fstps	_se_time1	# se_time1
/* src/renderer/r_main.c:974: 	if (!r_dspeeds.value) */
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp145
	testb	$64, %ah	#, tmp145
	jne	L202	#,
/* src/renderer/r_main.c:981: 	if (!(r_drawpolys | r_drawculledpolys)) */
	movl	_r_drawpolys, %ecx	# r_drawpolys, r_drawpolys
	orl	_r_drawculledpolys, %ecx	# r_drawculledpolys, tmp157
	jne	L203	#,
L212:
/* src/renderer/r_main.c:982: 		R_ScanEdges (); */
	call	_R_ScanEdges	#
/* src/renderer/r_main.c:983: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:984: } */
	addl	$128124, %esp	#,
	ret
	.p2align 4
	.p2align 3
L206:
/* src/renderer/r_main.c:924: 				(((long)&lsurfs[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1)); */
	leal	47(%esp), %ecx	#, tmp123
/* src/renderer/r_main.c:924: 				(((long)&lsurfs[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1)); */
	andl	$-32, %ecx	#, _10
/* src/renderer/r_main.c:925: 		surf_max = &surfaces[r_cnumsurfs]; */
	movl	_r_cnumsurfs, %eax	# r_cnumsurfs, tmp124
	sall	$6, %eax	#, tmp124
/* src/renderer/r_main.c:925: 		surf_max = &surfaces[r_cnumsurfs]; */
	addl	%ecx, %eax	# _10, tmp126
	movl	%eax, _surf_max	# tmp126, surf_max
/* src/renderer/r_main.c:928: 		surfaces--; */
	subl	$64, %ecx	#, tmp127
	movl	%ecx, _surfaces	# tmp127, surfaces
/* src/renderer/r_main.c:929: 		R_SurfacePatch (); */
	call	_R_SurfacePatch	#
	jmp	L193	#
	.p2align 4
	.p2align 3
L211:
/* src/renderer/r_main.c:958: 		rw_time2 = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
/* src/renderer/r_main.c:958: 		rw_time2 = Sys_FloatTime (); */
	fsts	_rw_time2	# rw_time2
/* src/renderer/r_main.c:959: 		db_time1 = rw_time2; */
	fstps	_db_time1	# db_time1
	jmp	L198	#
	.p2align 4
	.p2align 3
L210:
/* src/renderer/r_main.c:950: 		R_ScanEdges (); */
	call	_R_ScanEdges	#
	jmp	L197	#
	.p2align 4
	.p2align 3
L209:
/* src/renderer/r_main.c:946: 		bench486_world_seconds += Sys_FloatTime () - bench486_world_start; */
	call	_Sys_FloatTime	#
/* src/renderer/r_main.c:946: 		bench486_world_seconds += Sys_FloatTime () - bench486_world_start; */
	fldl	8(%esp)	# %sfp
	fsubrl	_bench486_world_seconds	# bench486_world_seconds
	faddp	%st, %st(1)	#,
	fstpl	_bench486_world_seconds	# bench486_world_seconds
	jmp	L196	#
	.p2align 4
	.p2align 3
L208:
/* src/renderer/r_main.c:941: 		bench486_world_start = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
	fstpl	8(%esp)	# %sfp
	jmp	L195	#
	.p2align 4
	.p2align 3
L207:
/* src/renderer/r_main.c:936: 		rw_time1 = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
	fstps	_rw_time1	# rw_time1
	jmp	L194	#
	.p2align 4
	.p2align 3
L205:
/* src/renderer/r_main.c:918: 				(((long)&ledges[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1)); */
	leal	51311(%esp), %eax	#, tmp121
/* src/renderer/r_main.c:918: 				(((long)&ledges[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1)); */
	andl	$-32, %eax	#, auxedges.115_1
	jmp	L192	#

.text
.p2align 3
/* R_RenderView_: Preserve setup/visibility/world/entity/viewmodel/particle/warp order without a frame-local warpbuffer.
 * Callee registers used: %ebx.
 * Stack reservations (bytes; includes call argument areas): 36, 12, 12, 12, 12, 12, 12, 12, 12, 8, 8.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_RenderView_
_R_RenderView_:
	pushl	%ebx	#
	subl	$36, %esp	#,
/* src/renderer/r_main.c:1050: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_RENDERER); */
	pushl	$6	#
	call	_Bench486ProfileEnter	#
/* src/renderer/r_main.c:1054: 	if (r_timegraph.value || r_speeds.value || r_dspeeds.value) */
	addl	$16, %esp	#,
	fldz
	fcoms	_r_timegraph+16	# r_timegraph.value
	fnstsw	%ax	# tmp138
	testb	$64, %ah	#, tmp138
	je	L255	#,
/* src/renderer/r_main.c:1054: 	if (r_timegraph.value || r_speeds.value || r_dspeeds.value) */
	fcoms	_r_speeds+16	# r_speeds.value
	fnstsw	%ax	# tmp141
	testb	$64, %ah	#, tmp141
	jne	L241	#,
	fstp	%st(0)		#
	jmp	L214	#
	.p2align 4
	.p2align 3
L255:
	fstp	%st(0)		#
L214:
/* src/renderer/r_main.c:1055: 		r_time1 = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
	fstps	_r_time1	# r_time1
L215:
/* src/renderer/r_main.c:1057: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SETUP); */
	subl	$12, %esp	#,
	pushl	$7	#
	call	_Bench486ProfileEnter	#
/* src/renderer/r_main.c:1058: 	R_SetupFrame (); */
	call	_R_SetupFrame	#
/* src/renderer/r_main.c:1059: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:1062: 	if (bench486_profile_frame_active) */
	addl	$16, %esp	#,
	movl	_bench486_profile_frame_active, %edx	# bench486_profile_frame_active,
	testl	%edx, %edx	#
	jne	L242	#,
L216:
/* src/renderer/r_main.c:1065: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_VISIBILITY); */
	subl	$12, %esp	#,
	pushl	$8	#
	call	_Bench486ProfileEnter	#
/* src/renderer/r_main.c:1070: 	R_MarkLeaves ();	// done here so we know if we're in water */
	call	_R_MarkLeaves	#
/* src/renderer/r_main.c:1074: 	if (bench486_profile_frame_active) */
	addl	$16, %esp	#,
	movl	_bench486_profile_frame_active, %ecx	# bench486_profile_frame_active,
	testl	%ecx, %ecx	#
	jne	L243	#,
L217:
/* src/renderer/r_main.c:1077: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:1083: 	Sys_LowFPPrecision (); */
	call	_Sys_LowFPPrecision	#
/* src/renderer/r_main.c:1085: 	if (!cl_entities[0].model || !cl.worldmodel) */
	movl	_cl_entities+132, %ebx	# cl_entities[0].model,
	testl	%ebx, %ebx	#
	je	L218	#,
/* src/renderer/r_main.c:1085: 	if (!cl_entities[0].model || !cl.worldmodel) */
	movl	_cl+2692, %eax	# cl.worldmodel,
	testl	%eax, %eax	#
	je	L218	#,
L219:
/* src/renderer/r_main.c:1088: 	if (!r_dspeeds.value) */
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp152
	testb	$64, %ah	#, tmp152
	jne	L244	#,
L220:
/* src/renderer/r_main.c:1095: 	R_EdgeDrawing (); */
	call	_R_EdgeDrawing	#
/* src/renderer/r_main.c:1097: 	if (!r_dspeeds.value) */
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp155
	testb	$64, %ah	#, tmp155
	jne	L221	#,
L223:
/* src/renderer/r_main.c:1106: 		se_time2 = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
/* src/renderer/r_main.c:1106: 		se_time2 = Sys_FloatTime (); */
	fsts	_se_time2	# se_time2
/* src/renderer/r_main.c:1107: 		de_time1 = se_time2; */
	fstps	_de_time1	# de_time1
L222:
/* src/renderer/r_main.c:1110: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ENTITIES); */
	subl	$12, %esp	#,
	pushl	$22	#
	call	_Bench486ProfileEnter	#
/* src/renderer/r_main.c:1111: 	R_DrawEntitiesOnList (); */
	call	_R_DrawEntitiesOnList	#
/* src/renderer/r_main.c:1112: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:1113: 	BENCH486_PROFILE_WORK (BENCH486_PROFILE_ENTITIES, */
	addl	$12, %esp	#,
	pushl	$0	#
	movl	_cl_numvisedicts, %edx	# cl_numvisedicts,
	pushl	%edx	#
	pushl	$22	#
	call	_Bench486ProfileWork	#
/* src/renderer/r_main.c:1116: 	if (r_dspeeds.value) */
	addl	$16, %esp	#,
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp161
	testb	$64, %ah	#, tmp161
	je	L245	#,
L224:
/* src/renderer/r_main.c:1122: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_VIEWMODEL); */
	subl	$12, %esp	#,
	pushl	$36	#
	call	_Bench486ProfileEnter	#
/* src/renderer/r_main.c:1123: 	R_DrawViewModel (); */
	call	_R_DrawViewModel	#
/* src/renderer/r_main.c:1124: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:1125: 	BENCH486_PROFILE_WORK (BENCH486_PROFILE_VIEWMODEL, 1, 0); */
	addl	$12, %esp	#,
	pushl	$0	#
	pushl	$1	#
	pushl	$36	#
	call	_Bench486ProfileWork	#
/* src/renderer/r_main.c:1127: 	if (r_dspeeds.value) */
	addl	$16, %esp	#,
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp164
	testb	$64, %ah	#, tmp164
	je	L246	#,
L225:
/* src/renderer/r_main.c:1134: 	profile_particle_start = bench486_particle_count; */
	movl	_bench486_particle_count, %ebx	# bench486_particle_count, profile_particle_start
/* src/renderer/r_main.c:1136: 	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_PARTICLES); */
	subl	$12, %esp	#,
	pushl	$37	#
	call	_Bench486ProfileEnter	#
/* src/renderer/r_main.c:1137: 	R_DrawParticles (); */
	call	_R_DrawParticles	#
/* src/renderer/r_main.c:1138: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:1140: 	BENCH486_PROFILE_WORK (BENCH486_PROFILE_PARTICLES, */
	addl	$12, %esp	#,
	pushl	$0	#
	movl	_bench486_particle_count, %ecx	# bench486_particle_count, tmp165
	subl	%ebx, %ecx	# profile_particle_start, tmp165
	pushl	%ecx	# tmp165
	pushl	$37	#
	call	_Bench486ProfileWork	#
/* src/renderer/r_main.c:1144: 	if (r_dspeeds.value) */
	addl	$16, %esp	#,
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp169
	testb	$64, %ah	#, tmp169
	je	L247	#,
L226:
/* src/renderer/r_main.c:1147: 	if (r_dowarp) */
	movl	_r_dowarp, %edx	# r_dowarp,
	testl	%edx, %edx	#
	jne	L248	#,
L227:
/* src/renderer/r_main.c:1157: 	V_SetContentsColor (r_viewleaf->contents); */
	subl	$12, %esp	#,
	movl	_r_viewleaf, %ecx	# r_viewleaf, r_viewleaf
	movl	(%ecx), %eax	# r_viewleaf.141_39->contents,
	pushl	%eax	#
	call	_V_SetContentsColor	#
/* src/renderer/r_main.c:1159: 	if (r_timegraph.value) */
	addl	$16, %esp	#,
	fldz
	fcomps	_r_timegraph+16	# r_timegraph.value
	fnstsw	%ax	# tmp177
	testb	$64, %ah	#, tmp177
	je	L249	#,
L228:
/* src/renderer/r_main.c:1162: 	if (r_aliasstats.value) */
	fldz
	fcomps	_r_aliasstats+16	# r_aliasstats.value
	fnstsw	%ax	# tmp180
	testb	$64, %ah	#, tmp180
	je	L250	#,
L229:
/* src/renderer/r_main.c:1165: 	if (r_speeds.value) */
	fldz
	fcomps	_r_speeds+16	# r_speeds.value
	fnstsw	%ax	# tmp183
	testb	$64, %ah	#, tmp183
	je	L251	#,
L230:
/* src/renderer/r_main.c:1168: 	if (r_dspeeds.value) */
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp186
	testb	$64, %ah	#, tmp186
	je	L252	#,
L231:
/* src/renderer/r_main.c:1171: 	if (r_reportsurfout.value && r_outofsurfaces) */
	fldz
	fcomps	_r_reportsurfout+16	# r_reportsurfout.value
	fnstsw	%ax	# tmp189
	testb	$64, %ah	#, tmp189
	jne	L232	#,
/* src/renderer/r_main.c:1171: 	if (r_reportsurfout.value && r_outofsurfaces) */
	movl	_r_outofsurfaces, %edx	# r_outofsurfaces, r_outofsurfaces.142_46
	testl	%edx, %edx	# r_outofsurfaces.142_46
	jne	L253	#,
L232:
/* src/renderer/r_main.c:1174: 	if (r_reportedgeout.value && r_outofedges) */
	fldz
	fcomps	_r_reportedgeout+16	# r_reportedgeout.value
	fnstsw	%ax	# tmp192
	testb	$64, %ah	#, tmp192
	jne	L233	#,
/* src/renderer/r_main.c:1174: 	if (r_reportedgeout.value && r_outofedges) */
	movl	_r_outofedges, %ebx	# r_outofedges, r_outofedges.144_48
	testl	%ebx, %ebx	# r_outofedges.144_48
	jne	L254	#,
L233:
/* src/renderer/r_main.c:1178: 	Sys_HighFPPrecision (); */
	call	_Sys_HighFPPrecision	#
/* src/renderer/r_main.c:1179: 	BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:1180: } */
	addl	$24, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L221:
/* src/renderer/r_main.c:1100: 		S_ExtraUpdate ();	// don't let sound get messed up if going slow */
	call	_S_ExtraUpdate	#
/* src/renderer/r_main.c:1104: 	if (r_dspeeds.value) */
	fldz
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp158
	testb	$64, %ah	#, tmp158
	jne	L222	#,
	jmp	L223	#
	.p2align 4
	.p2align 3
L241:
/* src/renderer/r_main.c:1054: 	if (r_timegraph.value || r_speeds.value || r_dspeeds.value) */
	fcomps	_r_dspeeds+16	# r_dspeeds.value
	fnstsw	%ax	# tmp144
	testb	$64, %ah	#, tmp144
	jne	L215	#,
	jmp	L214	#
	.p2align 4
	.p2align 3
L218:
/* src/renderer/r_main.c:1086: 		Sys_Error ("R_RenderView: NULL worldmodel"); */
	subl	$12, %esp	#,
	pushl	$LC26	#
	call	_Sys_Error	#
	addl	$16, %esp	#,
	jmp	L219	#
	.p2align 4
	.p2align 3
L244:
/* src/renderer/r_main.c:1091: 		S_ExtraUpdate ();	// don't let sound get messed up if going slow */
	call	_S_ExtraUpdate	#
	jmp	L220	#
	.p2align 4
	.p2align 3
L243:
/* src/renderer/r_main.c:1075: 		bench486_visibility_seconds += Sys_FloatTime () - bench486_visibility_start; */
	call	_Sys_FloatTime	#
/* src/renderer/r_main.c:1075: 		bench486_visibility_seconds += Sys_FloatTime () - bench486_visibility_start; */
	fldl	8(%esp)	# %sfp
	fsubrl	_bench486_visibility_seconds	# bench486_visibility_seconds
	faddp	%st, %st(1)	#,
	fstpl	_bench486_visibility_seconds	# bench486_visibility_seconds
	jmp	L217	#
	.p2align 4
	.p2align 3
L242:
/* src/renderer/r_main.c:1063: 		bench486_visibility_start = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
	fstpl	8(%esp)	# %sfp
	jmp	L216	#
	.p2align 4
	.p2align 3
L252:
/* src/renderer/r_main.c:1169: 		R_PrintDSpeeds (); */
	call	_R_PrintDSpeeds	#
	jmp	L231	#
	.p2align 4
	.p2align 3
L251:
/* src/renderer/r_main.c:1166: 		R_PrintTimes (); */
	call	_R_PrintTimes	#
	jmp	L230	#
	.p2align 4
	.p2align 3
L250:
/* src/renderer/r_main.c:1163: 		R_PrintAliasStats (); */
	call	_R_PrintAliasStats	#
	jmp	L229	#
	.p2align 4
	.p2align 3
L249:
/* src/renderer/r_main.c:1160: 		R_TimeGraph (); */
	call	_R_TimeGraph	#
	jmp	L228	#
	.p2align 4
	.p2align 3
L248:
/* src/renderer/r_main.c:1149: 		BENCH486_PROFILE_ENTER (BENCH486_PROFILE_WARP); */
	subl	$12, %esp	#,
	pushl	$38	#
	call	_Bench486ProfileEnter	#
/* src/renderer/r_main.c:1150: 		D_WarpScreen (); */
	call	_D_WarpScreen	#
/* src/renderer/r_main.c:1151: 		BENCH486_PROFILE_LEAVE (); */
	call	_Bench486ProfileLeave	#
/* src/renderer/r_main.c:1152: 		BENCH486_PROFILE_WORK (BENCH486_PROFILE_WARP, */
	addl	$12, %esp	#,
	pushl	$0	#
	movl	_r_refdef+8, %ebx	# r_refdef.vrect.width, r_refdef.vrect.width
	imull	_r_refdef+12, %ebx	# r_refdef.vrect.height, tmp172
	pushl	%ebx	# tmp172
	pushl	$38	#
	call	_Bench486ProfileWork	#
	addl	$16, %esp	#,
	jmp	L227	#
	.p2align 4
	.p2align 3
L247:
/* src/renderer/r_main.c:1145: 		dp_time2 = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
	fstps	_dp_time2	# dp_time2
	jmp	L226	#
	.p2align 4
	.p2align 3
L246:
/* src/renderer/r_main.c:1129: 		dv_time2 = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
	fstps	_dv_time2	# dv_time2
/* src/renderer/r_main.c:1130: 		dp_time1 = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
	fstps	_dp_time1	# dp_time1
	jmp	L225	#
	.p2align 4
	.p2align 3
L245:
/* src/renderer/r_main.c:1118: 		de_time2 = Sys_FloatTime (); */
	call	_Sys_FloatTime	#
/* src/renderer/r_main.c:1118: 		de_time2 = Sys_FloatTime (); */
	fsts	_de_time2	# de_time2
/* src/renderer/r_main.c:1119: 		dv_time1 = de_time2; */
	fstps	_dv_time1	# dv_time1
	jmp	L224	#
	.p2align 4
	.p2align 3
L254:
/* src/renderer/r_main.c:1175: 		Con_Printf ("Short roughly %d edges\n", r_outofedges * 2 / 3); */
	subl	$8, %esp	#,
/* src/renderer/r_main.c:1175: 		Con_Printf ("Short roughly %d edges\n", r_outofedges * 2 / 3); */
	leal	(%ebx,%ebx), %ecx	#, tmp193
/* src/renderer/r_main.c:1175: 		Con_Printf ("Short roughly %d edges\n", r_outofedges * 2 / 3); */
	movl	$1431655766, %eax	#, tmp206
	imull	%ecx	# tmp193
	sarl	$31, %ecx	#, tmp193
	subl	%ecx, %edx	# tmp197, tmp194
	pushl	%edx	# tmp194
	pushl	$LC28	#
	call	_Con_Printf	#
	addl	$16, %esp	#,
	jmp	L233	#
	.p2align 4
	.p2align 3
L253:
/* src/renderer/r_main.c:1172: 		Con_Printf ("Short %d surfaces\n", r_outofsurfaces); */
	subl	$8, %esp	#,
	pushl	%edx	# r_outofsurfaces.142_46
	pushl	$LC27	#
	call	_Con_Printf	#
	addl	$16, %esp	#,
	jmp	L232	#
	.p2align 2

.text
.p2align 3
/* R_RenderView: Check hunk and global alignment before dispatching the bounded renderer.
 * Callee registers used: none.
 * Stack reservations (bytes; includes call argument areas): 28, 12, 12.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_RenderView
_R_RenderView:
	subl	$28, %esp	#,
/* src/renderer/r_main.c:1191: 	if ( Hunk_LowMark() & 3 ) */
	call	_Hunk_LowMark	#
/* src/renderer/r_main.c:1191: 	if ( Hunk_LowMark() & 3 ) */
	testb	$3, %al	#, tmp92
	jne	L264	#,
L258:
/* src/renderer/r_main.c:1201: } */
	addl	$28, %esp	#,
/* src/renderer/r_main.c:1200: 	R_RenderView_ (); */
	pushl	$_R_RenderView_	#
	call	_R_RenderViewDispatch	#
	addl	$4, %esp	#,
	ret
L264:
/* src/renderer/r_main.c:1192: 		Sys_Error ("Hunk is missaligned"); */
	subl	$12, %esp	#,
	pushl	$LC30	#
	call	_Sys_Error	#
	addl	$16, %esp	#,
/* src/renderer/r_main.c:1201: } */
	addl	$28, %esp	#,
/* src/renderer/r_main.c:1200: 	R_RenderView_ (); */
	pushl	$_R_RenderView_	#
	call	_R_RenderViewDispatch	#
	addl	$4, %esp	#,
	ret
	.p2align 3

.text
.p2align 3
/* R_InitTurb: Initialize the two sine tables with the exact reference double-precision constants and truncating integer stores.
 * Callee registers used: none.
 * Stack reservations (bytes; includes call argument areas): 12.
 * Each return restores its entry ESP and all saved callee registers. */
	.globl	_R_InitTurb
_R_InitTurb:
	subl	$12, %esp	#,
/* src/renderer/r_main.c:1214: 		sintable[i] = AMP + sin(i*3.14159*2/CYCLE)*AMP; */
	movl	$524288, _sintable	#, sintable[0]
/* src/renderer/r_main.c:1215: 		intsintable[i] = AMP2 + sin(i*3.14159*2/CYCLE)*AMP2;	// AMP2, not 20 */
	movl	$3, _intsintable	#, intsintable[0]
/* src/renderer/r_main.c:1212: 	for (i=0 ; i<(SIN_BUFFER_SIZE) ; i++) */
	movl	$1, %eax	#, i
/* src/renderer/r_main.c:1214: 		sintable[i] = AMP + sin(i*3.14159*2/CYCLE)*AMP; */
	fldl	LC1	#
	fnstcw	6(%esp)	#
	movw	6(%esp), %dx	#, tmp109
	orb	$12, %dh	#, tmp109
	movw	%dx, 4(%esp)	# tmp109,
	.p2align 3
	.p2align 3
L266:
	fld	%st(0)	#
	movl	%eax, (%esp)	# i, %sfp
	fimull	(%esp)	# %sfp
	fsin
/* src/renderer/r_main.c:1214: 		sintable[i] = AMP + sin(i*3.14159*2/CYCLE)*AMP; */
	fadds	LC2	#
	fld	%st(0)	#
	fmuls	LC3	#
/* src/renderer/r_main.c:1214: 		sintable[i] = AMP + sin(i*3.14159*2/CYCLE)*AMP; */
	fldcw	4(%esp)		#
	fistpl	_sintable(,%eax,4)	# MEM[(int *)&sintable + _33 * 4]
	fldcw	6(%esp)		#
/* src/renderer/r_main.c:1215: 		intsintable[i] = AMP2 + sin(i*3.14159*2/CYCLE)*AMP2;	// AMP2, not 20 */
	fmuls	LC4	#
/* src/renderer/r_main.c:1215: 		intsintable[i] = AMP2 + sin(i*3.14159*2/CYCLE)*AMP2;	// AMP2, not 20 */
	fldcw	4(%esp)		#
	fistpl	_intsintable(,%eax,4)	# MEM[(int *)&intsintable + _33 * 4]
	fldcw	6(%esp)		#
/* src/renderer/r_main.c:1212: 	for (i=0 ; i<(SIN_BUFFER_SIZE) ; i++) */
	incl	%eax	# i
/* src/renderer/r_main.c:1212: 	for (i=0 ; i<(SIN_BUFFER_SIZE) ; i++) */
	cmpl	$1408, %eax	#, i
	jne	L266	#,
	fstp	%st(0)		#
/* src/renderer/r_main.c:1217: } */
	addl	$12, %esp	#,
	ret

.data
/* Typed constants are data, outside the executable instruction section. */
.p2align 3
LC0:
	.ascii "notexture\0"
	.p2align 3
.p2align 3
LC1:
	.long	-266631570
	.long	1068048889
	.p2align 2
.p2align 3
LC2:
	.long	1065353216
	.p2align 2
.p2align 3
LC3:
	.long	1224736768
	.p2align 2
.p2align 3
LC4:
	.long	1077936128
	.p2align 2
.p2align 3
LC5:
	.ascii "timerefresh\0"
.p2align 3
LC6:
	.ascii "pointfile\0"
.p2align 3
LC8:
	.ascii "r_maxedges\0"
.p2align 3
LC10:
	.ascii "r_maxsurfs\0"
	.p2align 3
.p2align 3
LC11:
	.long	1056964608
	.p2align 2
.p2align 3
LC13:
	.ascii "edges\0"
.p2align 3
LC14:
	.ascii "surfaces\0"
	.p2align 3
.p2align 3
LC15:
	.long	1120403456
	.p2align 2
.p2align 3
LC16:
	.long	1008981770
	.p2align 2
.p2align 3
LC17:
	.long	1119879168
	.p2align 2
.p2align 3
LC19:
	.long	993397601
	.p2align 3
.p2align 3
LC20:
	.long	1413754136
	.long	1074340347
	.p2align 3
.p2align 3
LC21:
	.long	2061584302
	.long	1072672276
	.p2align 3
.p2align 3
LC23:
	.long	813783277
	.long	1056280274
	.p2align 2
.p2align 3
LC24:
	.long	1073741824
	.p2align 2
.p2align 3
LC25:
	.long	1119092736
.p2align 3
LC26:
	.ascii "R_RenderView: NULL worldmodel\0"
.p2align 3
LC27:
	.ascii "Short %d surfaces\12\0"
.p2align 3
LC28:
	.ascii "Short roughly %d edges\12\0"
	.p2align 3
LC30:
	.ascii "Hunk is missaligned\0"
	.p2align 3
