/* Original r_efrag.c world-control algorithms; profile.
 * Source SHA256 ED6B7C06DE282844FED37A1A09C97DD37D34EDB5413A889E763FEA29D0717A2A
 * Normal builds assemble this maintained schedule; no C renderer generation.
 * Cdecl. Preserve EBX/ESI/EDI/EBP, ESP, DF and x87 control/stack depth.
 * Matrix stores, linked-list updates and traversal order are parity contracts. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */

.text
.p2align 3
/* R_RemoveEfrags: Unlink each entity fragment from its leaf and prepend it to the original free-fragment chain.
 * Callee registers used: %ebx.
 * Stack reservations: none bytes; all returns restore ESP. */
	.globl	_R_RemoveEfrags
_R_RemoveEfrags:
	pushl	%ebx	#
	movl	8(%esp), %ebx	# ent, ent
/* original r_efrag.c:74: 	ef = ent->efrag; */
	movl	136(%ebx), %edx	# ent_9(D)->efrag, ef
/* original r_efrag.c:76: 	while (ef) */
	testl	%edx, %edx	# ef
	je	wc_efrags_profile_L2	#,
	.p2align 3
	.p2align 3
wc_efrags_profile_L8:
/* original r_efrag.c:78: 		prev = &ef->leaf->efrags; */
	movl	(%edx), %ecx	# ef_26->leaf, _1
/* original r_efrag.c:78: 		prev = &ef->leaf->efrags; */
	movl	28(%ecx), %eax	# MEM[(struct efrag_t * *)_1 + 28B], _21
/* original r_efrag.c:82: 			if (!walk) */
	testl	%eax, %eax	# _21
	je	wc_efrags_profile_L3	#,
/* original r_efrag.c:84: 			if (walk == ef) */
	cmpl	%edx, %eax	# ef, _21
	jne	wc_efrags_profile_L5	#,
	jmp	wc_efrags_profile_L19	#
	.p2align 4
	.p2align 3
wc_efrags_profile_L7:
	cmpl	%edx, %eax	# ef, _21
	je	wc_efrags_profile_L20	#,
wc_efrags_profile_L5:
	movl	%eax, %ecx	# _21, walk
/* original r_efrag.c:90: 				prev = &walk->leafnext; */
	movl	4(%eax), %eax	# MEM[(struct efrag_t * *)walk_29 + 4B], _21
/* original r_efrag.c:82: 			if (!walk) */
	testl	%eax, %eax	# _21
	jne	wc_efrags_profile_L7	#,
wc_efrags_profile_L3:
/* original r_efrag.c:94: 		ef = ef->entnext; */
	movl	12(%edx), %eax	# ef_26->entnext, ef
/* original r_efrag.c:97: 		old->entnext = cl.free_efrags; */
	movl	_cl+2696, %ecx	# cl.free_efrags, _3
/* original r_efrag.c:97: 		old->entnext = cl.free_efrags; */
	movl	%ecx, 12(%edx)	# _3, ef_26->entnext
/* original r_efrag.c:98: 		cl.free_efrags = old; */
	movl	%edx, _cl+2696	# ef, cl.free_efrags
/* original r_efrag.c:76: 	while (ef) */
	testl	%eax, %eax	# ef
	je	wc_efrags_profile_L2	#,
/* original r_efrag.c:94: 		ef = ef->entnext; */
	movl	%eax, %edx	# ef, ef
	jmp	wc_efrags_profile_L8	#
	.p2align 4
	.p2align 3
wc_efrags_profile_L20:
/* original r_efrag.c:90: 				prev = &walk->leafnext; */
	addl	$4, %ecx	#, prev
wc_efrags_profile_L6:
/* original r_efrag.c:86: 				*prev = ef->leafnext; */
	movl	4(%edx), %eax	# ef_26->leafnext, _2
/* original r_efrag.c:86: 				*prev = ef->leafnext; */
	movl	%eax, (%ecx)	# _2, *prev_22
/* original r_efrag.c:87: 				break; */
	jmp	wc_efrags_profile_L3	#
	.p2align 4
	.p2align 3
wc_efrags_profile_L2:
/* original r_efrag.c:101: 	ent->efrag = NULL; */
	movl	$0, 136(%ebx)	#, ent_9(D)->efrag
/* original r_efrag.c:102: } */
	popl	%ebx	#
	ret
wc_efrags_profile_L19:
/* original r_efrag.c:78: 		prev = &ef->leaf->efrags; */
	addl	$28, %ecx	#, prev
	jmp	wc_efrags_profile_L6	#

.text
.p2align 3
/* R_SplitEntityOnNode: Traverse contacted BSP sides, preserve the first top node, and link available fragments into entity and leaf lists.
 * Callee registers used: %ebx.
 * Stack reservations: 24, 12, 12 bytes; all returns restore ESP. */
	.globl	_R_SplitEntityOnNode
_R_SplitEntityOnNode:
	pushl	%ebx	#
	subl	$24, %esp	#,
	movl	32(%esp), %ebx	# node, node
wc_efrags_profile_L52:
/* original r_efrag.c:116: 	if (node->contents == CONTENTS_SOLID) */
	movl	(%ebx), %eax	#* node, _1
/* original r_efrag.c:116: 	if (node->contents == CONTENTS_SOLID) */
	cmpl	$-2, %eax	#, _1
	je	wc_efrags_profile_L21	#,
wc_efrags_profile_L22:
/* original r_efrag.c:123: 	if ( node->contents < 0) */
	testl	%eax, %eax	# _1
	js	wc_efrags_profile_L54	#,
/* original r_efrag.c:156: 	splitplane = node->plane; */
	movl	24(%ebx), %edx	# node_47->plane, splitplane
/* original r_efrag.c:157: 	sides = BOX_ON_PLANE_SIDE(r_emins, r_emaxs, splitplane); */
	movb	16(%edx), %cl	# splitplane_26->type, _9
	cmpb	$2, %cl	#, _9
	ja	wc_efrags_profile_L27	#,
/* original r_efrag.c:157: 	sides = BOX_ON_PLANE_SIDE(r_emins, r_emaxs, splitplane); */
	flds	12(%edx)	# splitplane_26->dist
	xorl	%edx, %edx	# _12
	movb	%cl, %dl	# _9, _12
	fcoms	_r_emins(,%edx,4)	# r_emins[_12]
	fnstsw	%ax	# tmp108
	testb	$69, %ah	#, tmp108
	je	wc_efrags_profile_L28	#,
	fstp	%st(0)		#
/* original r_efrag.c:169: 		R_SplitEntityOnNode (node->children[0]); */
	movl	28(%ebx), %ebx	# node_47->children[0], node
	jmp	wc_efrags_profile_L52	#
	.p2align 4
	.p2align 3
wc_efrags_profile_L28:
/* original r_efrag.c:157: 	sides = BOX_ON_PLANE_SIDE(r_emins, r_emaxs, splitplane); */
	fcomps	_r_emaxs(,%edx,4)	# r_emaxs[_12]
	fnstsw	%ax	# tmp110
	testb	$5, %ah	#, tmp110
	je	wc_efrags_profile_L33	#,
wc_efrags_profile_L34:
/* original r_efrag.c:169: 		R_SplitEntityOnNode (node->children[0]); */
	movl	28(%ebx), %ecx	# node_47->children[0], pretmp_62
/* original r_efrag.c:163: 		if (!r_pefragtopnode) */
	movl	_r_pefragtopnode, %edx	# r_pefragtopnode,
	testl	%edx, %edx	#
	je	wc_efrags_profile_L55	#,
wc_efrags_profile_L51:
/* original r_efrag.c:169: 		R_SplitEntityOnNode (node->children[0]); */
	subl	$12, %esp	#,
	pushl	%ecx	# pretmp_62
	call	_R_SplitEntityOnNode	#
	addl	$16, %esp	#,
wc_efrags_profile_L33:
/* original r_efrag.c:172: 		R_SplitEntityOnNode (node->children[1]); */
	movl	32(%ebx), %ebx	# node_47->children[1], node
/* original r_efrag.c:116: 	if (node->contents == CONTENTS_SOLID) */
	movl	(%ebx), %eax	#* node, _1
/* original r_efrag.c:116: 	if (node->contents == CONTENTS_SOLID) */
	cmpl	$-2, %eax	#, _1
	jne	wc_efrags_profile_L22	#,
wc_efrags_profile_L21:
/* original r_efrag.c:173: } */
	addl	$24, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
wc_efrags_profile_L27:
/* original r_efrag.c:157: 	sides = BOX_ON_PLANE_SIDE(r_emins, r_emaxs, splitplane); */
	pushl	%eax	#
	pushl	%edx	# splitplane
	pushl	$_r_emaxs	#
	pushl	$_r_emins	#
	call	_BoxOnPlaneSide	#
/* original r_efrag.c:159: 	if (sides == 3) */
	addl	$16, %esp	#,
	cmpl	$3, %eax	#, iftmp.3_28
	je	wc_efrags_profile_L34	#,
/* original r_efrag.c:168: 	if (sides & 1) */
	testb	$1, %al	#, iftmp.3_28
	jne	wc_efrags_profile_L56	#,
wc_efrags_profile_L36:
/* original r_efrag.c:171: 	if (sides & 2) */
	testb	$2, %al	#, iftmp.3_28
	jne	wc_efrags_profile_L33	#,
/* original r_efrag.c:173: } */
	addl	$24, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
wc_efrags_profile_L55:
/* original r_efrag.c:164: 			r_pefragtopnode = node; */
	movl	%ebx, _r_pefragtopnode	# node, r_pefragtopnode
	jmp	wc_efrags_profile_L51	#
	.p2align 4
	.p2align 3
wc_efrags_profile_L54:
/* original r_efrag.c:125: 		if (!r_pefragtopnode) */
	movl	_r_pefragtopnode, %eax	# r_pefragtopnode,
	testl	%eax, %eax	#
	je	wc_efrags_profile_L57	#,
wc_efrags_profile_L25:
/* original r_efrag.c:131: 		ef = cl.free_efrags; */
	movl	_cl+2696, %ecx	# cl.free_efrags, ef
/* original r_efrag.c:132: 		if (!ef) */
	testl	%ecx, %ecx	# ef
	je	wc_efrags_profile_L58	#,
/* original r_efrag.c:137: 		cl.free_efrags = cl.free_efrags->entnext; */
	movl	12(%ecx), %edx	# MEM[(struct efrag_s *)ef_32].entnext, _4
/* original r_efrag.c:137: 		cl.free_efrags = cl.free_efrags->entnext; */
	movl	%edx, _cl+2696	# _4, cl.free_efrags
/* original r_efrag.c:139: 		ef->entity = r_addent; */
	movl	_r_addent, %eax	# r_addent, r_addent
	movl	%eax, 8(%ecx)	# r_addent, ef_32->entity
/* original r_efrag.c:142: 		*lastlink = ef; */
	movl	_lastlink, %edx	# lastlink, lastlink.2_6
/* original r_efrag.c:142: 		*lastlink = ef; */
	movl	%ecx, (%edx)	# ef, *lastlink.2_6
/* original r_efrag.c:143: 		lastlink = &ef->entnext; */
	leal	12(%ecx), %eax	#, tmp106
	movl	%eax, _lastlink	# tmp106, lastlink
/* original r_efrag.c:144: 		ef->entnext = NULL; */
	movl	$0, 12(%ecx)	#, ef_32->entnext
/* original r_efrag.c:147: 		ef->leaf = leaf; */
	movl	%ebx, (%ecx)	# node, ef_32->leaf
/* original r_efrag.c:148: 		ef->leafnext = leaf->efrags; */
	movl	28(%ebx), %edx	# MEM[(struct mleaf_t *)node_47].efrags, _8
/* original r_efrag.c:148: 		ef->leafnext = leaf->efrags; */
	movl	%edx, 4(%ecx)	# _8, ef_32->leafnext
/* original r_efrag.c:149: 		leaf->efrags = ef; */
	movl	%ecx, 28(%ebx)	# ef, MEM[(struct mleaf_t *)node_47].efrags
/* original r_efrag.c:173: } */
	addl	$24, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
wc_efrags_profile_L57:
/* original r_efrag.c:126: 			r_pefragtopnode = node; */
	movl	%ebx, _r_pefragtopnode	# node, r_pefragtopnode
	jmp	wc_efrags_profile_L25	#
	.p2align 4
	.p2align 3
wc_efrags_profile_L58:
/* original r_efrag.c:134: 			Con_Printf ("Too many efrags!\n"); */
	movl	$wc_efrags_profile_LC0, 32(%esp)	#,
/* original r_efrag.c:173: } */
	addl	$24, %esp	#,
	popl	%ebx	#
/* original r_efrag.c:134: 			Con_Printf ("Too many efrags!\n"); */
	jmp	_Con_Printf	#
wc_efrags_profile_L56:
	movl	%eax, 12(%esp)	# iftmp.3_28, %sfp
/* original r_efrag.c:169: 		R_SplitEntityOnNode (node->children[0]); */
	subl	$12, %esp	#,
	pushl	28(%ebx)	# node_47->children[0]
	call	_R_SplitEntityOnNode	#
	addl	$16, %esp	#,
	movl	12(%esp), %eax	# %sfp, iftmp.3_28
	jmp	wc_efrags_profile_L36	#
	.p2align 3

.text
.p2align 3
/* R_SplitEntityOnNode2: Find the visible first splitter/non-solid leaf using the original visibility and plane-side rules.
 * Callee registers used: %ebx.
 * Stack reservations: 8 bytes; all returns restore ESP. */
	.globl	_R_SplitEntityOnNode2
_R_SplitEntityOnNode2:
	pushl	%ebx	#
	subl	$8, %esp	#,
	movl	16(%esp), %ebx	# node, node
/* original r_efrag.c:186: 	if (node->visframe != r_visframecount) */
	movl	_r_visframecount, %ecx	# r_visframecount, prephitmp_30
/* original r_efrag.c:186: 	if (node->visframe != r_visframecount) */
	cmpl	%ecx, 4(%ebx)	# prephitmp_30,
	je	wc_efrags_profile_L61	#,
	jmp	wc_efrags_profile_L59	#
	.p2align 4
	.p2align 3
wc_efrags_profile_L83:
/* original r_efrag.c:198: 	sides = BOX_ON_PLANE_SIDE(r_emins, r_emaxs, splitplane); */
	fcomps	_r_emaxs(,%edx,4)	# r_emaxs[_7]
	fnstsw	%ax	# tmp98
	testb	$5, %ah	#, tmp98
	jne	wc_efrags_profile_L68	#,
wc_efrags_profile_L67:
/* original r_efrag.c:211: 		R_SplitEntityOnNode2 (node->children[1]); */
	movl	32(%ebx), %ebx	# node_27->children[1], node
/* original r_efrag.c:186: 	if (node->visframe != r_visframecount) */
	cmpl	%ecx, 4(%ebx)	# prephitmp_30,
	jne	wc_efrags_profile_L59	#,
wc_efrags_profile_L61:
/* original r_efrag.c:189: 	if (node->contents < 0) */
	movl	(%ebx), %eax	# node_27->contents, _3
/* original r_efrag.c:189: 	if (node->contents < 0) */
	testl	%eax, %eax	# _3
	js	wc_efrags_profile_L82	#,
/* original r_efrag.c:197: 	splitplane = node->plane; */
	movl	24(%ebx), %edx	# node_27->plane, splitplane
/* original r_efrag.c:198: 	sides = BOX_ON_PLANE_SIDE(r_emins, r_emaxs, splitplane); */
	movb	16(%edx), %al	# splitplane_17->type, _4
	cmpb	$2, %al	#, _4
	ja	wc_efrags_profile_L64	#,
/* original r_efrag.c:198: 	sides = BOX_ON_PLANE_SIDE(r_emins, r_emaxs, splitplane); */
	flds	12(%edx)	# splitplane_17->dist
	xorl	%edx, %edx	# _7
	movb	%al, %dl	# _4, _7
	fcoms	_r_emins(,%edx,4)	# r_emins[_7]
	fnstsw	%ax	# tmp96
	testb	$69, %ah	#, tmp96
	je	wc_efrags_profile_L83	#,
	fstp	%st(0)		#
/* original r_efrag.c:209: 		R_SplitEntityOnNode2 (node->children[0]); */
	movl	28(%ebx), %ebx	# node_27->children[0], node
wc_efrags_profile_L84:
/* original r_efrag.c:186: 	if (node->visframe != r_visframecount) */
	cmpl	%ecx, 4(%ebx)	# prephitmp_30,
	je	wc_efrags_profile_L61	#,
wc_efrags_profile_L59:
/* original r_efrag.c:212: } */
	addl	$8, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
wc_efrags_profile_L64:
/* original r_efrag.c:198: 	sides = BOX_ON_PLANE_SIDE(r_emins, r_emaxs, splitplane); */
	pushl	%eax	#
	pushl	%edx	# splitplane
	pushl	$_r_emaxs	#
	pushl	$_r_emins	#
	call	_BoxOnPlaneSide	#
/* original r_efrag.c:200: 	if (sides == 3) */
	addl	$16, %esp	#,
	cmpl	$3, %eax	#, iftmp.8_19
	je	wc_efrags_profile_L68	#,
/* original r_efrag.c:186: 	if (node->visframe != r_visframecount) */
	movl	_r_visframecount, %ecx	# r_visframecount, prephitmp_30
/* original r_efrag.c:208: 	if (sides & 1) */
	testb	$1, %al	#, iftmp.8_19
	je	wc_efrags_profile_L67	#,
/* original r_efrag.c:209: 		R_SplitEntityOnNode2 (node->children[0]); */
	movl	28(%ebx), %ebx	# node_27->children[0], node
	jmp	wc_efrags_profile_L84	#
	.p2align 4
	.p2align 3
wc_efrags_profile_L82:
/* original r_efrag.c:191: 		if (node->contents != CONTENTS_SOLID) */
	cmpl	$-2, %eax	#, _3
	je	wc_efrags_profile_L59	#,
wc_efrags_profile_L68:
/* original r_efrag.c:203: 		r_pefragtopnode = node; */
	movl	%ebx, _r_pefragtopnode	# node, r_pefragtopnode
/* original r_efrag.c:212: } */
	addl	$8, %esp	#,
	popl	%ebx	#
	ret
	.p2align 3

.text
.p2align 3
/* R_AddEfrags: Preserve missing-model/world early returns, translated model bounds and original fragment/top-node publication.
 * Callee registers used: %ebx.
 * Stack reservations: 8, 12 bytes; all returns restore ESP. */
	.globl	_R_AddEfrags
_R_AddEfrags:
	pushl	%ebx	#
	subl	$8, %esp	#,
	movl	16(%esp), %ebx	# ent, ent
/* original r_efrag.c:225: 	if (!ent->model) */
	movl	132(%ebx), %eax	# ent_15(D)->model, _1
/* original r_efrag.c:225: 	if (!ent->model) */
	testl	%eax, %eax	# _1
	je	wc_efrags_profile_L85	#,
/* original r_efrag.c:228: 	if (ent == cl_entities) */
	cmpl	$_cl_entities, %ebx	#, ent
	je	wc_efrags_profile_L85	#,
/* original r_efrag.c:231: 	r_addent = ent; */
	movl	%ebx, _r_addent	# ent, r_addent
/* original r_efrag.c:233: 	lastlink = &ent->efrag; */
	leal	136(%ebx), %edx	#, tmp103
	movl	%edx, _lastlink	# tmp103, lastlink
/* original r_efrag.c:234: 	r_pefragtopnode = NULL; */
	movl	$0, _r_pefragtopnode	#, r_pefragtopnode
/* original r_efrag.c:240: 		r_emins[i] = ent->origin[i] + entmodel->mins[i]; */
	flds	84(%ebx)	# ent_15(D)->origin[0]
/* original r_efrag.c:240: 		r_emins[i] = ent->origin[i] + entmodel->mins[i]; */
	flds	84(%eax)	# MEM[(struct model_t *)_1].mins[0]
	fadd	%st(1), %st	#,
/* original r_efrag.c:240: 		r_emins[i] = ent->origin[i] + entmodel->mins[i]; */
	fstps	_r_emins	# r_emins[0]
/* original r_efrag.c:241: 		r_emaxs[i] = ent->origin[i] + entmodel->maxs[i]; */
	fadds	96(%eax)	# MEM[(struct model_t *)_1].maxs[0]
/* original r_efrag.c:241: 		r_emaxs[i] = ent->origin[i] + entmodel->maxs[i]; */
	fstps	_r_emaxs	# r_emaxs[0]
/* original r_efrag.c:240: 		r_emins[i] = ent->origin[i] + entmodel->mins[i]; */
	flds	88(%ebx)	# ent_15(D)->origin[1]
/* original r_efrag.c:240: 		r_emins[i] = ent->origin[i] + entmodel->mins[i]; */
	flds	88(%eax)	# MEM[(struct model_t *)_1].mins[1]
	fadd	%st(1), %st	#,
/* original r_efrag.c:240: 		r_emins[i] = ent->origin[i] + entmodel->mins[i]; */
	fstps	_r_emins+4	# r_emins[1]
/* original r_efrag.c:241: 		r_emaxs[i] = ent->origin[i] + entmodel->maxs[i]; */
	fadds	100(%eax)	# MEM[(struct model_t *)_1].maxs[1]
/* original r_efrag.c:241: 		r_emaxs[i] = ent->origin[i] + entmodel->maxs[i]; */
	fstps	_r_emaxs+4	# r_emaxs[1]
/* original r_efrag.c:240: 		r_emins[i] = ent->origin[i] + entmodel->mins[i]; */
	flds	92(%ebx)	# ent_15(D)->origin[2]
/* original r_efrag.c:240: 		r_emins[i] = ent->origin[i] + entmodel->mins[i]; */
	flds	92(%eax)	# MEM[(struct model_t *)_1].mins[2]
	fadd	%st(1), %st	#,
/* original r_efrag.c:240: 		r_emins[i] = ent->origin[i] + entmodel->mins[i]; */
	fstps	_r_emins+8	# r_emins[2]
/* original r_efrag.c:241: 		r_emaxs[i] = ent->origin[i] + entmodel->maxs[i]; */
	fadds	104(%eax)	# MEM[(struct model_t *)_1].maxs[2]
/* original r_efrag.c:241: 		r_emaxs[i] = ent->origin[i] + entmodel->maxs[i]; */
	fstps	_r_emaxs+8	# r_emaxs[2]
/* original r_efrag.c:244: 	R_SplitEntityOnNode (cl.worldmodel->nodes); */
	subl	$12, %esp	#,
	movl	_cl+2692, %ecx	# cl.worldmodel, cl.worldmodel
	movl	164(%ecx), %eax	# _8->nodes,
	pushl	%eax	#
	call	_R_SplitEntityOnNode	#
/* original r_efrag.c:246: 	ent->topnode = r_pefragtopnode; */
	movl	_r_pefragtopnode, %edx	# r_pefragtopnode, r_pefragtopnode
	movl	%edx, 176(%ebx)	# r_pefragtopnode, ent_15(D)->topnode
	addl	$16, %esp	#,
wc_efrags_profile_L85:
/* original r_efrag.c:247: } */
	addl	$8, %esp	#,
	popl	%ebx	#
	ret

.data
/* Literal data is separate from audited CODE, never an ISA exemption. */
.p2align 3
wc_efrags_profile_LC0:
	.ascii "Too many efrags!\12\0"
	.p2align 3
