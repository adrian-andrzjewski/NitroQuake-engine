/* Original r_edge.c world-control algorithms; profile.
 * Source SHA256 4FCC88B6C6FBB3A698DFC5C4C32CA17C603686B8B750B623401FD78AB079369C
 * Normal builds assemble this maintained schedule; no C renderer generation.
 * Cdecl. Preserve EBX/ESI/EDI/EBP, ESP, DF and x87 control/stack depth.
 * Matrix stores, linked-list updates and traversal order are parity contracts. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */

.text
.p2align 3
/* R_DrawCulledPolys: Visit span-bearing non-background surfaces in the original forward/backward order with clip flags 15.
 * Callee registers used: %ebx, %esi.
 * Stack reservations: 8, 8 bytes; all returns restore ESP. */
	.globl	_R_DrawCulledPolys
_R_DrawCulledPolys:
	pushl	%esi	#
	pushl	%ebx	#
	pushl	%ecx	#
/* original r_edge.c:94: 	currententity = &cl_entities[0]; */
	movl	$_cl_entities, _currententity	#, currententity
/* original r_edge.c:98: 		for (s=surface_p-1 ; s>&surfaces[1] ; s--) */
	movl	_surfaces, %ecx	# surfaces, prephitmp_31
	addl	$64, %ecx	#, tmp101
/* original r_edge.c:98: 		for (s=surface_p-1 ; s>&surfaces[1] ; s--) */
	movl	_surface_p, %ebx	# surface_p, prephitmp_20
/* original r_edge.c:96: 	if (r_worldpolysbacktofront) */
	movl	_r_worldpolysbacktofront, %esi	# r_worldpolysbacktofront,
	testl	%esi, %esi	#
	jne	wc_edges_profile_L12	#,
	movl	%ecx, %esi	# tmp101, s
/* original r_edge.c:112: 		for (s = &surfaces[1] ; s<surface_p ; s++) */
	cmpl	%ebx, %ecx	# prephitmp_20, s
	jb	wc_edges_profile_L7	#,
wc_edges_profile_L1:
/* original r_edge.c:124: } */
	popl	%eax	#
	popl	%ebx	#
	popl	%esi	#
	ret
	.p2align 4
	.p2align 3
wc_edges_profile_L14:
/* original r_edge.c:120: 				R_RenderPoly (pface, 15); */
	subl	$8, %esp	#,
	pushl	$15	#
	movl	28(%esi), %edx	# MEM[(void * *)s_37 + 28B],
	pushl	%edx	#
	call	_R_RenderPoly	#
/* original r_edge.c:112: 		for (s = &surfaces[1] ; s<surface_p ; s++) */
	movl	_surface_p, %ebx	# surface_p, prephitmp_20
	addl	$16, %esp	#,
wc_edges_profile_L6:
/* original r_edge.c:112: 		for (s = &surfaces[1] ; s<surface_p ; s++) */
	addl	$64, %esi	#, s
/* original r_edge.c:112: 		for (s = &surfaces[1] ; s<surface_p ; s++) */
	cmpl	%ebx, %esi	# prephitmp_20, s
	jnb	wc_edges_profile_L1	#,
wc_edges_profile_L7:
/* original r_edge.c:114: 			if (!s->spans) */
	movl	8(%esi), %ecx	# MEM[(struct espan_s * *)s_37 + 8B],
	testl	%ecx, %ecx	#
	je	wc_edges_profile_L6	#,
/* original r_edge.c:117: 			if (!(s->flags & SURF_DRAWBACKGROUND)) */
	testb	$64, 24(%esi)	#, MEM[(int *)s_37 + 24B]
	jne	wc_edges_profile_L6	#,
	jmp	wc_edges_profile_L14	#
	.p2align 4
	.p2align 3
wc_edges_profile_L15:
/* original r_edge.c:106: 				R_RenderPoly (pface, 15); */
	subl	$8, %esp	#,
	pushl	$15	#
	movl	28(%ebx), %eax	# MEM[(void * *)s_39 + 28B],
	pushl	%eax	#
	call	_R_RenderPoly	#
/* original r_edge.c:98: 		for (s=surface_p-1 ; s>&surfaces[1] ; s--) */
	movl	_surfaces, %ecx	# surfaces, prephitmp_31
	addl	$16, %esp	#,
	addl	$64, %ecx	#, tmp101
wc_edges_profile_L12:
/* original r_edge.c:98: 		for (s=surface_p-1 ; s>&surfaces[1] ; s--) */
	subl	$64, %ebx	#, s
/* original r_edge.c:98: 		for (s=surface_p-1 ; s>&surfaces[1] ; s--) */
	cmpl	%ebx, %ecx	# s, tmp101
	jnb	wc_edges_profile_L1	#,
/* original r_edge.c:100: 			if (!s->spans) */
	movl	8(%ebx), %esi	# MEM[(struct espan_s * *)s_39 + 8B],
	testl	%esi, %esi	#
	je	wc_edges_profile_L12	#,
/* original r_edge.c:103: 			if (!(s->flags & SURF_DRAWBACKGROUND)) */
	testb	$64, 24(%ebx)	#, MEM[(int *)s_39 + 24B]
	jne	wc_edges_profile_L12	#,
	jmp	wc_edges_profile_L15	#
	.p2align 3

.text
.p2align 3
/* R_BeginEdgeFrame: Reset edge/surface cursors, background/key/span direction and only the active scanline lists.
 * Callee registers used: %ebx, %edi, %esi.
 * Stack reservations: none bytes; all returns restore ESP. */
	.globl	_R_BeginEdgeFrame
_R_BeginEdgeFrame:
	pushl	%edi	#
	pushl	%esi	#
	pushl	%ebx	#
/* original r_edge.c:136: 	edge_p = r_edges; */
	movl	_r_edges, %eax	# r_edges, r_edges.5_1
	movl	%eax, _edge_p	# r_edges.5_1, edge_p
/* original r_edge.c:137: 	edge_max = &r_edges[r_numallocatededges]; */
	movl	_r_numallocatededges, %edx	# r_numallocatededges, tmp102
	sall	$5, %edx	#, tmp102
/* original r_edge.c:137: 	edge_max = &r_edges[r_numallocatededges]; */
	addl	%edx, %eax	# tmp102, tmp104
	movl	%eax, _edge_max	# tmp104, edge_max
/* original r_edge.c:139: 	surface_p = &surfaces[2];	// background is surface 1, */
	movl	_surfaces, %esi	# surfaces, surfaces.9_6
	leal	128(%esi), %ecx	#, tmp105
	movl	%ecx, _surface_p	# tmp105, surface_p
/* original r_edge.c:141: 	surfaces[1].spans = NULL;	// no background spans yet */
	movl	$0, 72(%esi)	#, MEM[(struct surf_t *)surfaces.9_6 + 64B].spans
/* original r_edge.c:142: 	surfaces[1].flags = SURF_DRAWBACKGROUND; */
	movl	$64, 88(%esi)	#, MEM[(struct surf_t *)surfaces.9_6 + 64B].flags
/* original r_edge.c:145: 	if (r_draworder.value) */
	fldz
	fcomps	_r_draworder+16	# r_draworder.value
	fnstsw	%ax	# tmp108
	testb	$64, %ah	#, tmp108
	je	wc_edges_profile_L25	#,
	movl	$_R_GenerateSpans, %ebx	#, _35
	movl	$2147483647, %edi	#, _29
	xorl	%edx, %edx	# _12
wc_edges_profile_L17:
/* original r_edge.c:147: 		pdrawfunc = R_GenerateSpansBackward; */
	movl	%ebx, _pdrawfunc	# _35, pdrawfunc
/* original r_edge.c:148: 		surfaces[1].key = 0; */
	movl	%edi, 76(%esi)	# _29, MEM[(struct surf_t *)surfaces.9_6 + 64B].key
/* original r_edge.c:149: 		r_currentkey = 1; */
	movl	%edx, _r_currentkey	# _12, r_currentkey
/* original r_edge.c:159: 	for (v=r_refdef.vrect.y ; v<r_refdef.vrectbottom ; v++) */
	movl	_r_refdef+4, %esi	# r_refdef.vrect.y, v
/* original r_edge.c:159: 	for (v=r_refdef.vrect.y ; v<r_refdef.vrectbottom ; v++) */
	movl	_r_refdef+44, %edx	# r_refdef.vrectbottom, _31
/* original r_edge.c:159: 	for (v=r_refdef.vrect.y ; v<r_refdef.vrectbottom ; v++) */
	cmpl	%edx, %esi	# _31, v
	jge	wc_edges_profile_L16	#,
/* original r_edge.c:161: 		newedges[v] = removeedges[v] = NULL; */
	subl	%esi, %edx	# v, tmp111
	sall	$2, %edx	#, _22
	leal	0(,%esi,4), %esi	#, _23
	leal	_removeedges(%esi), %ebx	#, tmp112
	cmpl	$4, %edx	#, _22
	jnb	wc_edges_profile_L19	#,
	testl	%edx, %edx	# _22
	je	wc_edges_profile_L20	#,
	movb	$0, _removeedges(%esi)	#,
wc_edges_profile_L20:
/* original r_edge.c:161: 		newedges[v] = removeedges[v] = NULL; */
	leal	_newedges(%esi), %ebx	#, tmp118
	cmpl	$4, %edx	#, _22
	jnb	wc_edges_profile_L22	#,
wc_edges_profile_L33:
	testl	%edx, %edx	# _22
	je	wc_edges_profile_L16	#,
	movb	$0, _newedges(%esi)	#,
wc_edges_profile_L16:
/* original r_edge.c:163: } */
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	ret
	.p2align 4
	.p2align 3
wc_edges_profile_L25:
	movl	$_R_GenerateSpansBackward, %ebx	#, _35
	xorl	%edi, %edi	# _29
	movl	$1, %edx	#, _12
	jmp	wc_edges_profile_L17	#
	.p2align 4
	.p2align 3
wc_edges_profile_L19:
/* original r_edge.c:161: 		newedges[v] = removeedges[v] = NULL; */
	movl	$0, -4(%ebx,%edx)	#,
	leal	-1(%edx), %ecx	#, _22
	shrl	$2, %ecx	#, tmp117
	xorl	%eax, %eax	# tmp115
	movl	%ebx, %edi	# tmp112, tmp112
	rep stosl
/* original r_edge.c:161: 		newedges[v] = removeedges[v] = NULL; */
	leal	_newedges(%esi), %ebx	#, tmp118
	cmpl	$4, %edx	#, _22
	jb	wc_edges_profile_L33	#,
wc_edges_profile_L22:
	movl	$0, -4(%ebx,%edx)	#,
	leal	-1(%edx), %ecx	#, _22
	shrl	$2, %ecx	#, tmp123
	xorl	%eax, %eax	# tmp121
	movl	%ebx, %edi	# tmp118, tmp118
	rep stosl
/* original r_edge.c:163: } */
	popl	%ebx	#
	popl	%esi	#
	popl	%edi	#
	ret
	.p2align 3

.data
/* Literal data is separate from audited CODE, never an ISA exemption. */
