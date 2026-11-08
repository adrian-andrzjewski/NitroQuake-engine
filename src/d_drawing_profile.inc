/* Maintained profile assembly imported once from original draw.c.
 * Cdecl unless the private glyph helper states its register arguments.
 * EBX/ESI/EDI/EBP preserved; EAX/ECX/EDX caller-owned.
 * Original loops, transparent indices, byte strides and division semantics.
 * Original source SHA256: 2A3CB6610EF604885AFF99B1A7F341494D8A0F43D2A46CBB183C3ABBD7FA6A45 */
 /* GNU C89 (GCC) version 12.2.0 (i586-pc-msdosdjgpp) */
 /* compiled by GNU C version 9.2.0, GMP version 6.2.1, MPFR version 4.1.0, MPC version 1.2.1, isl version none */
 /* GGC heuristics: --param ggc-min-expand=100 --param ggc-min-heapsize=131072 */
 /* options passed: -remap -march=i486 -mtune=i486 -O3 -std=gnu90 -falign-loops=8 -falign-jumps=16 -falign-functions=8 -freorder-blocks -freorder-functions -fomit-frame-pointer -frename-registers -fno-strict-aliasing -fcommon -ffast-math */
	.section .text
	.p2align 3
/* Private glyph helper: x=EAX, y=EDX, character=ECX; caller already rejected y<=-8. */
_Draw_Character.part.0:
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	movl	%eax, %esi	 /* tmp218, x */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:157: 	source = draw_chars + (row<<10) + (col<<3); */
	movl	%ecx, %eax	 /* num, tmp163 */
	sall	$6, %eax	 /* , tmp163 */
	andl	$15360, %eax	 /* , tmp164 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:157: 	source = draw_chars + (row<<10) + (col<<3); */
	sall	$3, %ecx	 /* , tmp165 */
	andl	$120, %ecx	 /* , tmp166 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:157: 	source = draw_chars + (row<<10) + (col<<3); */
	orl	%ecx, %eax	 /* tmp166, tmp167 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:157: 	source = draw_chars + (row<<10) + (col<<3); */
	addl	_draw_chars, %eax	 /* draw_chars, source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:159: 	if (y < 0) */
	testl	%edx, %edx	 /* y */
	js	L70	 /* , */
	movl	$7, %ebx	 /* , _196 */
L2:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:171: 		dest = vid.conbuffer + y*vid.conrowbytes + x; */
	imull	_vid+44, %edx	 /* vid.conrowbytes, _223 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:171: 		dest = vid.conbuffer + y*vid.conrowbytes + x; */
	movl	_vid+40, %edi	 /* vid.conbuffer, pretmp_224 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:169: 	if (r_pixbytes == 1) */
	cmpl	$1, _r_pixbytes	 /* , r_pixbytes */
	je	L71	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:199: 				((byte *)vid.conbuffer + y*vid.conrowbytes + (x<<1)); */
	addl	%esi, %esi	 /* x, tmp183 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:199: 				((byte *)vid.conbuffer + y*vid.conrowbytes + (x<<1)); */
	addl	%edx, %esi	 /* _223, tmp184 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:198: 		pusdest = (unsigned short *) */
	leal	(%edi,%esi), %edx	 /* , pusdest */
	incl	%ebx	 /* tmp185 */
	sall	$7, %ebx	 /* , tmp186 */
	addl	%eax, %ebx	 /* source, _214 */
	.p2align 3
	.p2align 3
L24:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:203: 			if (source[0]) */
	movb	(%eax), %cl	 /* MEM[(byte *)source_156], _53 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:203: 			if (source[0]) */
	testb	%cl, %cl	 /* _53 */
	je	L15	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:204: 				pusdest[0] = d_8to16table[source[0]]; */
	andl	$255, %ecx	 /* , _53 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:204: 				pusdest[0] = d_8to16table[source[0]]; */
	movw	_d_8to16table(%ecx,%ecx), %si	 /* d_8to16table[_54], _55 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:204: 				pusdest[0] = d_8to16table[source[0]]; */
	movw	%si, (%edx)	 /* _55, *pusdest_148 */
L15:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:205: 			if (source[1]) */
	movb	1(%eax), %cl	 /* MEM[(byte *)source_156 + 1B], _57 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:205: 			if (source[1]) */
	testb	%cl, %cl	 /* _57 */
	je	L16	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:206: 				pusdest[1] = d_8to16table[source[1]]; */
	andl	$255, %ecx	 /* , _57 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:206: 				pusdest[1] = d_8to16table[source[1]]; */
	movw	_d_8to16table(%ecx,%ecx), %di	 /* d_8to16table[_58], _59 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:206: 				pusdest[1] = d_8to16table[source[1]]; */
	movw	%di, 2(%edx)	 /* _59, MEM[(short unsigned int *)pusdest_148 + 2B] */
L16:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:207: 			if (source[2]) */
	movb	2(%eax), %cl	 /* MEM[(byte *)source_156 + 2B], _60 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:207: 			if (source[2]) */
	testb	%cl, %cl	 /* _60 */
	je	L17	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:208: 				pusdest[2] = d_8to16table[source[2]]; */
	andl	$255, %ecx	 /* , _60 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:208: 				pusdest[2] = d_8to16table[source[2]]; */
	movw	_d_8to16table(%ecx,%ecx), %si	 /* d_8to16table[_61], _62 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:208: 				pusdest[2] = d_8to16table[source[2]]; */
	movw	%si, 4(%edx)	 /* _62, MEM[(short unsigned int *)pusdest_148 + 4B] */
L17:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:209: 			if (source[3]) */
	movb	3(%eax), %cl	 /* MEM[(byte *)source_156 + 3B], _63 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:209: 			if (source[3]) */
	testb	%cl, %cl	 /* _63 */
	je	L18	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:210: 				pusdest[3] = d_8to16table[source[3]]; */
	andl	$255, %ecx	 /* , _63 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:210: 				pusdest[3] = d_8to16table[source[3]]; */
	movw	_d_8to16table(%ecx,%ecx), %di	 /* d_8to16table[_64], _65 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:210: 				pusdest[3] = d_8to16table[source[3]]; */
	movw	%di, 6(%edx)	 /* _65, MEM[(short unsigned int *)pusdest_148 + 6B] */
L18:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:211: 			if (source[4]) */
	movb	4(%eax), %cl	 /* MEM[(byte *)source_156 + 4B], _66 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:211: 			if (source[4]) */
	testb	%cl, %cl	 /* _66 */
	je	L19	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:212: 				pusdest[4] = d_8to16table[source[4]]; */
	andl	$255, %ecx	 /* , _66 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:212: 				pusdest[4] = d_8to16table[source[4]]; */
	movw	_d_8to16table(%ecx,%ecx), %si	 /* d_8to16table[_67], _68 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:212: 				pusdest[4] = d_8to16table[source[4]]; */
	movw	%si, 8(%edx)	 /* _68, MEM[(short unsigned int *)pusdest_148 + 8B] */
L19:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:213: 			if (source[5]) */
	movb	5(%eax), %cl	 /* MEM[(byte *)source_156 + 5B], _69 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:213: 			if (source[5]) */
	testb	%cl, %cl	 /* _69 */
	je	L20	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:214: 				pusdest[5] = d_8to16table[source[5]]; */
	andl	$255, %ecx	 /* , _69 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:214: 				pusdest[5] = d_8to16table[source[5]]; */
	movw	_d_8to16table(%ecx,%ecx), %di	 /* d_8to16table[_70], _71 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:214: 				pusdest[5] = d_8to16table[source[5]]; */
	movw	%di, 10(%edx)	 /* _71, MEM[(short unsigned int *)pusdest_148 + 10B] */
L20:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:215: 			if (source[6]) */
	movb	6(%eax), %cl	 /* MEM[(byte *)source_156 + 6B], _72 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:215: 			if (source[6]) */
	testb	%cl, %cl	 /* _72 */
	je	L21	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:216: 				pusdest[6] = d_8to16table[source[6]]; */
	andl	$255, %ecx	 /* , _72 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:216: 				pusdest[6] = d_8to16table[source[6]]; */
	movw	_d_8to16table(%ecx,%ecx), %si	 /* d_8to16table[_73], _74 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:216: 				pusdest[6] = d_8to16table[source[6]]; */
	movw	%si, 12(%edx)	 /* _74, MEM[(short unsigned int *)pusdest_148 + 12B] */
L21:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:217: 			if (source[7]) */
	movb	7(%eax), %cl	 /* MEM[(byte *)source_156 + 7B], _75 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:217: 			if (source[7]) */
	testb	%cl, %cl	 /* _75 */
	je	L22	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:218: 				pusdest[7] = d_8to16table[source[7]]; */
	andl	$255, %ecx	 /* , _75 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:218: 				pusdest[7] = d_8to16table[source[7]]; */
	movw	_d_8to16table(%ecx,%ecx), %di	 /* d_8to16table[_76], _77 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:218: 				pusdest[7] = d_8to16table[source[7]]; */
	movw	%di, 14(%edx)	 /* _77, MEM[(short unsigned int *)pusdest_148 + 14B] */
L22:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:220: 			source += 128; */
	subl	$-128, %eax	 /* , source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:221: 			pusdest += (vid.conrowbytes >> 1); */
	movl	_vid+44, %esi	 /* vid.conrowbytes, tmp210 */
	andl	$-2, %esi	 /* , tmp210 */
	addl	%esi, %edx	 /* tmp210, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:201: 		while (drawline--) */
	cmpl	%ebx, %eax	 /* _214, source */
	jne	L24	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:224: } */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	ret
	.p2align 4
	.p2align 3
L70:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:162: 		source -= 128*y; */
	movl	%edx, %ecx	 /* y, tmp169 */
	sall	$7, %ecx	 /* , tmp169 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:162: 		source -= 128*y; */
	subl	%ecx, %eax	 /* tmp169, source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:173: 		while (drawline--) */
	leal	7(%edx), %ebx	 /* , _196 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:163: 		y = 0; */
	xorl	%edx, %edx	 /* y */
	jmp	L2	 /*  */
	.p2align 4
	.p2align 3
L71:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:171: 		dest = vid.conbuffer + y*vid.conrowbytes + x; */
	leal	(%esi,%edx), %edx	 /* , tmp172 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:171: 		dest = vid.conbuffer + y*vid.conrowbytes + x; */
	leal	(%edi,%edx), %edi	 /* , dest */
	incl	%ebx	 /* tmp173 */
	sall	$7, %ebx	 /* , tmp174 */
	addl	%eax, %ebx	 /* source, _218 */
	.p2align 3
	.p2align 3
L14:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:175: 			if (source[0]) */
	movb	(%eax), %cl	 /* MEM[(byte *)source_150], _29 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:175: 			if (source[0]) */
	testb	%cl, %cl	 /* _29 */
	je	L4	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:176: 				dest[0] = source[0]; */
	movb	%cl, (%edi)	 /* _29, *dest_157 */
L4:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:177: 			if (source[1]) */
	movb	1(%eax), %dl	 /* MEM[(byte *)source_150 + 1B], _31 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:177: 			if (source[1]) */
	testb	%dl, %dl	 /* _31 */
	je	L5	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:178: 				dest[1] = source[1]; */
	movb	%dl, 1(%edi)	 /* _31, MEM[(byte *)dest_157 + 1B] */
L5:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:179: 			if (source[2]) */
	movb	2(%eax), %cl	 /* MEM[(byte *)source_150 + 2B], _32 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:179: 			if (source[2]) */
	testb	%cl, %cl	 /* _32 */
	je	L6	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:180: 				dest[2] = source[2]; */
	movb	%cl, 2(%edi)	 /* _32, MEM[(byte *)dest_157 + 2B] */
L6:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:181: 			if (source[3]) */
	movb	3(%eax), %dl	 /* MEM[(byte *)source_150 + 3B], _33 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:181: 			if (source[3]) */
	testb	%dl, %dl	 /* _33 */
	je	L7	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:182: 				dest[3] = source[3]; */
	movb	%dl, 3(%edi)	 /* _33, MEM[(byte *)dest_157 + 3B] */
L7:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:183: 			if (source[4]) */
	movb	4(%eax), %cl	 /* MEM[(byte *)source_150 + 4B], _34 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:183: 			if (source[4]) */
	testb	%cl, %cl	 /* _34 */
	je	L8	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:184: 				dest[4] = source[4]; */
	movb	%cl, 4(%edi)	 /* _34, MEM[(byte *)dest_157 + 4B] */
L8:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:185: 			if (source[5]) */
	movb	5(%eax), %dl	 /* MEM[(byte *)source_150 + 5B], _35 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:185: 			if (source[5]) */
	testb	%dl, %dl	 /* _35 */
	je	L9	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:186: 				dest[5] = source[5]; */
	movb	%dl, 5(%edi)	 /* _35, MEM[(byte *)dest_157 + 5B] */
L9:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:187: 			if (source[6]) */
	movb	6(%eax), %cl	 /* MEM[(byte *)source_150 + 6B], _36 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:187: 			if (source[6]) */
	testb	%cl, %cl	 /* _36 */
	je	L10	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:188: 				dest[6] = source[6]; */
	movb	%cl, 6(%edi)	 /* _36, MEM[(byte *)dest_157 + 6B] */
L10:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:189: 			if (source[7]) */
	movb	7(%eax), %dl	 /* MEM[(byte *)source_150 + 7B], _37 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:189: 			if (source[7]) */
	testb	%dl, %dl	 /* _37 */
	je	L11	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:190: 				dest[7] = source[7]; */
	movb	%dl, 7(%edi)	 /* _37, MEM[(byte *)dest_157 + 7B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:191: 			source += 128; */
	subl	$-128, %eax	 /* , source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:192: 			dest += vid.conrowbytes; */
	addl	_vid+44, %edi	 /* vid.conrowbytes, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:173: 		while (drawline--) */
	cmpl	%ebx, %eax	 /* _218, source */
	jne	L14	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:224: } */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	ret
	.p2align 4
	.p2align 3
L11:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:191: 			source += 128; */
	subl	$-128, %eax	 /* , source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:192: 			dest += vid.conrowbytes; */
	addl	_vid+44, %edi	 /* vid.conrowbytes, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:173: 		while (drawline--) */
	cmpl	%ebx, %eax	 /* _218, source */
	jne	L14	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:224: } */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	ret
	.p2align 3
	.globl	_Draw_PicFromWad
/* Draw_PicFromWad: Return the original named WAD picture. */
_Draw_PicFromWad:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:56: 	return W_GetLumpName (name); */
	jmp	_W_GetLumpName	 /*  */
	.p2align 2
.data
LC0:
	.ascii "menu_numcachepics == MAX_CACHED_PICS\0"
	.p2align 2
LC1:
	.ascii "Draw_CachePic: failed to load %s\0"
	.p2align 3
.text
	.globl	_Draw_CachePic
/* Draw_CachePic: Preserve bounded menu lookup, cache checking, loading and byte-order conversion. */
_Draw_CachePic:
	pushl	%ebp	 /*  */
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	subl	$28, %esp	 /* , */
	movl	48(%esp), %ebp	 /* path, path */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:70: 	for (pic=menu_cachepics, i=0 ; i<menu_numcachepics ; pic++, i++) */
	movl	_menu_numcachepics, %edi	 /* menu_numcachepics, prephitmp_3 */
	testl	%edi, %edi	 /* prephitmp_3 */
	jle	L74	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:70: 	for (pic=menu_cachepics, i=0 ; i<menu_numcachepics ; pic++, i++) */
	xorl	%esi, %esi	 /* i */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:70: 	for (pic=menu_cachepics, i=0 ; i<menu_numcachepics ; pic++, i++) */
	movl	$_menu_cachepics, %ebx	 /* , pic */
	jmp	L76	 /*  */
	.p2align 4
	.p2align 3
L85:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:70: 	for (pic=menu_cachepics, i=0 ; i<menu_numcachepics ; pic++, i++) */
	addl	$68, %ebx	 /* , pic */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:70: 	for (pic=menu_cachepics, i=0 ; i<menu_numcachepics ; pic++, i++) */
	incl	%esi	 /* i */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:70: 	for (pic=menu_cachepics, i=0 ; i<menu_numcachepics ; pic++, i++) */
	cmpl	%esi, %edi	 /* i, prephitmp_3 */
	je	L77	 /* , */
L76:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:71: 		if (!strcmp (path, pic->name)) */
	subl	$8, %esp	 /* , */
	pushl	%ebx	 /* pic */
	pushl	%ebp	 /* path */
	call	_strcmp	 /*  */
	addl	$16, %esp	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:71: 		if (!strcmp (path, pic->name)) */
	testl	%eax, %eax	 /* tmp93 */
	jne	L85	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:74: 	if (i == menu_numcachepics) */
	cmpl	%esi, %edi	 /* i, prephitmp_3 */
	je	L77	 /* , */
L79:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:82: 	dat = Cache_Check (&pic->cache); */
	leal	64(%ebx), %esi	 /* , _9 */
	subl	$12, %esp	 /* , */
	pushl	%esi	 /* _9 */
	call	_Cache_Check	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:84: 	if (dat) */
	addl	$16, %esp	 /* , */
	testl	%eax, %eax	 /* <retval> */
	je	L86	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:101: } */
	addl	$28, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
	.p2align 4
	.p2align 3
L77:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:76: 		if (menu_numcachepics == MAX_CACHED_PICS) */
	cmpl	$128, %edi	 /* , prephitmp_3 */
	je	L87	 /* , */
L78:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:78: 		menu_numcachepics++; */
	incl	%edi	 /* tmp91 */
	movl	%edi, _menu_numcachepics	 /* tmp91, menu_numcachepics */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:79: 		strcpy (pic->name, path); */
	subl	$8, %esp	 /* , */
	pushl	%ebp	 /* path */
	pushl	%ebx	 /* pic */
	call	_strcpy	 /*  */
	addl	$16, %esp	 /* , */
	jmp	L79	 /*  */
	.p2align 4
	.p2align 3
L86:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:90: 	COM_LoadCacheFile (path, &pic->cache); */
	subl	$8, %esp	 /* , */
	pushl	%esi	 /* _9 */
	pushl	%ebp	 /* path */
	call	_COM_LoadCacheFile	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:92: 	dat = (qpic_t *)pic->cache.data; */
	movl	64(%ebx), %eax	 /* pic_35->cache.data, <retval> */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:93: 	if (!dat) */
	addl	$16, %esp	 /* , */
	testl	%eax, %eax	 /* <retval> */
	je	L88	 /* , */
L81:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:98: 	SwapPic (dat); */
	subl	$12, %esp	 /* , */
	pushl	%eax	 /* <retval> */
	movl	%eax, 28(%esp)	 /* <retval>, %sfp */
	call	_SwapPic	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:100: 	return dat; */
	addl	$16, %esp	 /* , */
	movl	12(%esp), %eax	 /* %sfp, <retval> */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:101: } */
	addl	$28, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
L87:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:77: 			Sys_Error ("menu_numcachepics == MAX_CACHED_PICS"); */
	subl	$12, %esp	 /* , */
	pushl	$LC0	 /*  */
	call	_Sys_Error	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:78: 		menu_numcachepics++; */
	movl	_menu_numcachepics, %edi	 /* menu_numcachepics, prephitmp_3 */
	addl	$16, %esp	 /* , */
	jmp	L78	 /*  */
L74:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:70: 	for (pic=menu_cachepics, i=0 ; i<menu_numcachepics ; pic++, i++) */
	movl	$_menu_cachepics, %ebx	 /* , pic */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:74: 	if (i == menu_numcachepics) */
	jne	L79	 /* , */
	jmp	L78	 /*  */
L88:
	movl	%eax, 12(%esp)	 /* <retval>, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:95: 		Sys_Error ("Draw_CachePic: failed to load %s", path); */
	subl	$8, %esp	 /* , */
	pushl	%ebp	 /* path */
	pushl	$LC1	 /*  */
	call	_Sys_Error	 /*  */
	addl	$16, %esp	 /* , */
	movl	12(%esp), %eax	 /* %sfp, <retval> */
	jmp	L81	 /*  */
.data
LC2:
	.ascii "conchars\0"
LC3:
	.ascii "disc\0"
LC4:
	.ascii "backtile\0"
	.p2align 3
.text
	.globl	_Draw_Init
/* Draw_Init: Load console characters, disc icon and background tile; initialize the rectangle descriptor. */
_Draw_Init:
	subl	$24, %esp	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:114: 	draw_chars = W_GetLumpName ("conchars"); */
	pushl	$LC2	 /*  */
	call	_W_GetLumpName	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:114: 	draw_chars = W_GetLumpName ("conchars"); */
	movl	%eax, _draw_chars	 /* tmp94, draw_chars */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:115: 	draw_disc = W_GetLumpName ("disc"); */
	movl	$LC3, (%esp)	 /* , */
	call	_W_GetLumpName	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:115: 	draw_disc = W_GetLumpName ("disc"); */
	movl	%eax, _draw_disc	 /* tmp95, draw_disc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:116: 	draw_backtile = W_GetLumpName ("backtile"); */
	movl	$LC4, (%esp)	 /* , */
	call	_W_GetLumpName	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:116: 	draw_backtile = W_GetLumpName ("backtile"); */
	movl	%eax, _draw_backtile	 /* _3, draw_backtile */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:118: 	r_rectdesc.width = draw_backtile->width; */
	movl	(%eax), %edx	 /* MEM[(struct qpic_t *)_3].width, _4 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:118: 	r_rectdesc.width = draw_backtile->width; */
	movl	%edx, _r_rectdesc+20	 /* _4, r_rectdesc.width */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:119: 	r_rectdesc.height = draw_backtile->height; */
	movl	4(%eax), %ecx	 /* MEM[(struct qpic_t *)_3].height, MEM[(struct qpic_t *)_3].height */
	movl	%ecx, _r_rectdesc+24	 /* MEM[(struct qpic_t *)_3].height, r_rectdesc.height */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:120: 	r_rectdesc.ptexbytes = draw_backtile->data; */
	addl	$8, %eax	 /* , tmp92 */
	movl	%eax, _r_rectdesc+28	 /* tmp92, r_rectdesc.ptexbytes */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:121: 	r_rectdesc.rowbytes = draw_backtile->width; */
	movl	%edx, _r_rectdesc+32	 /* _4, r_rectdesc.rowbytes */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:122: } */
	addl	$28, %esp	 /* , */
	ret
	.p2align 3
	.globl	_Draw_Character
/* Draw_Character: Preserve zero-transparent 8 by 8 glyphs, top clipping and both pixel formats. */
_Draw_Character:
	movl	4(%esp), %eax	 /* x, x */
	movl	8(%esp), %edx	 /* y, y */
	movl	12(%esp), %ecx	 /* num, num */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:145: 	if (y <= -8) */
	cmpl	$-7, %edx	 /* , y */
	jl	L91	 /* , */
	jmp	_Draw_Character.part.0	 /*  */
	.p2align 4
	.p2align 3
L91:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:224: } */
	ret
	.p2align 3
	.globl	_Draw_String
/* Draw_String: Advance eight pixels per signed character; retain the private register-argument glyph helper. */
_Draw_String:
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	movl	12(%esp), %esi	 /* x, x */
	movl	20(%esp), %ebx	 /* str, str */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:233: 	while (*str) */
	movsbl	(%ebx), %ecx	 /* *str_7(D), */
	testb	%cl, %cl	 /* _22 */
	je	L93	 /* , */
	cmpl	$-7, 16(%esp)	 /* , y */
	jl	L93	 /* , */
	.p2align 3
	.p2align 3
L95:
	movl	16(%esp), %edx	 /* y, */
	movl	%esi, %eax	 /* x, */
	call	_Draw_Character.part.0	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:236: 		str++; */
	incl	%ebx	 /* str */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:237: 		x += 8; */
	addl	$8, %esi	 /* , x */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:233: 	while (*str) */
	movsbl	(%ebx), %ecx	 /* MEM[(char *)str_24], */
	testb	%cl, %cl	 /* _22 */
	jne	L95	 /* , */
L93:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:239: } */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	ret
	.p2align 3
	.globl	_Draw_DebugChar
/* Draw_DebugChar: Write all glyph bytes to the original fixed 320-byte direct framebuffer stride. */
_Draw_DebugChar:
	movl	4(%esp), %ecx	 /* num, num */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:258: 	if (!vid.direct) */
	movl	_vid+64, %edx	 /* vid.direct, _1 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:258: 	if (!vid.direct) */
	testl	%edx, %edx	 /* _1 */
	je	L101	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:263: 	row = num>>4; */
	movb	%cl, %al	 /* num, tmp159 */
	sarb	$4, %al	 /* , tmp159 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:265: 	source = draw_chars + (row<<10) + (col<<3); */
	movsbl	%al, %eax	 /* tmp159, tmp160 */
	sall	$10, %eax	 /* , tmp161 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:265: 	source = draw_chars + (row<<10) + (col<<3); */
	andl	$15, %ecx	 /* , tmp163 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:265: 	source = draw_chars + (row<<10) + (col<<3); */
	leal	(%eax,%ecx,8), %eax	 /* , tmp165 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:265: 	source = draw_chars + (row<<10) + (col<<3); */
	addl	_draw_chars, %eax	 /* draw_chars, source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:271: 		dest[0] = source[0]; */
	movb	(%eax), %cl	 /* *source_23, tmp169 */
	movb	%cl, 312(%edx)	 /* tmp169, MEM[(byte *)_1 + 312B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:272: 		dest[1] = source[1]; */
	movb	1(%eax), %cl	 /* MEM[(byte *)source_23 + 1B], tmp170 */
	movb	%cl, 313(%edx)	 /* tmp170, MEM[(byte *)_1 + 313B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:273: 		dest[2] = source[2]; */
	movb	2(%eax), %cl	 /* MEM[(byte *)source_23 + 2B], tmp171 */
	movb	%cl, 314(%edx)	 /* tmp171, MEM[(byte *)_1 + 314B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:274: 		dest[3] = source[3]; */
	movb	3(%eax), %cl	 /* MEM[(byte *)source_23 + 3B], tmp172 */
	movb	%cl, 315(%edx)	 /* tmp172, MEM[(byte *)_1 + 315B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:275: 		dest[4] = source[4]; */
	movb	4(%eax), %cl	 /* MEM[(byte *)source_23 + 4B], tmp173 */
	movb	%cl, 316(%edx)	 /* tmp173, MEM[(byte *)_1 + 316B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:276: 		dest[5] = source[5]; */
	movb	5(%eax), %cl	 /* MEM[(byte *)source_23 + 5B], tmp174 */
	movb	%cl, 317(%edx)	 /* tmp174, MEM[(byte *)_1 + 317B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:277: 		dest[6] = source[6]; */
	movb	6(%eax), %cl	 /* MEM[(byte *)source_23 + 6B], tmp175 */
	movb	%cl, 318(%edx)	 /* tmp175, MEM[(byte *)_1 + 318B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:278: 		dest[7] = source[7]; */
	movb	7(%eax), %cl	 /* MEM[(byte *)source_23 + 7B], tmp176 */
	movb	%cl, 319(%edx)	 /* tmp176, MEM[(byte *)_1 + 319B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:271: 		dest[0] = source[0]; */
	movb	128(%eax), %cl	 /* MEM[(byte *)source_23 + 128B], tmp177 */
	movb	%cl, 632(%edx)	 /* tmp177, MEM[(byte *)_1 + 632B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:272: 		dest[1] = source[1]; */
	movb	129(%eax), %cl	 /* MEM[(byte *)source_23 + 129B], tmp178 */
	movb	%cl, 633(%edx)	 /* tmp178, MEM[(byte *)_1 + 633B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:273: 		dest[2] = source[2]; */
	movb	130(%eax), %cl	 /* MEM[(byte *)source_23 + 130B], tmp179 */
	movb	%cl, 634(%edx)	 /* tmp179, MEM[(byte *)_1 + 634B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:274: 		dest[3] = source[3]; */
	movb	131(%eax), %cl	 /* MEM[(byte *)source_23 + 131B], tmp180 */
	movb	%cl, 635(%edx)	 /* tmp180, MEM[(byte *)_1 + 635B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:275: 		dest[4] = source[4]; */
	movb	132(%eax), %cl	 /* MEM[(byte *)source_23 + 132B], tmp181 */
	movb	%cl, 636(%edx)	 /* tmp181, MEM[(byte *)_1 + 636B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:276: 		dest[5] = source[5]; */
	movb	133(%eax), %cl	 /* MEM[(byte *)source_23 + 133B], tmp182 */
	movb	%cl, 637(%edx)	 /* tmp182, MEM[(byte *)_1 + 637B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:277: 		dest[6] = source[6]; */
	movb	134(%eax), %cl	 /* MEM[(byte *)source_23 + 134B], tmp183 */
	movb	%cl, 638(%edx)	 /* tmp183, MEM[(byte *)_1 + 638B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:278: 		dest[7] = source[7]; */
	movb	135(%eax), %cl	 /* MEM[(byte *)source_23 + 135B], tmp184 */
	movb	%cl, 639(%edx)	 /* tmp184, MEM[(byte *)_1 + 639B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:271: 		dest[0] = source[0]; */
	movb	256(%eax), %cl	 /* MEM[(byte *)source_23 + 256B], tmp185 */
	movb	%cl, 952(%edx)	 /* tmp185, MEM[(byte *)_1 + 952B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:272: 		dest[1] = source[1]; */
	movb	257(%eax), %cl	 /* MEM[(byte *)source_23 + 257B], tmp186 */
	movb	%cl, 953(%edx)	 /* tmp186, MEM[(byte *)_1 + 953B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:273: 		dest[2] = source[2]; */
	movb	258(%eax), %cl	 /* MEM[(byte *)source_23 + 258B], tmp187 */
	movb	%cl, 954(%edx)	 /* tmp187, MEM[(byte *)_1 + 954B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:274: 		dest[3] = source[3]; */
	movb	259(%eax), %cl	 /* MEM[(byte *)source_23 + 259B], tmp188 */
	movb	%cl, 955(%edx)	 /* tmp188, MEM[(byte *)_1 + 955B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:275: 		dest[4] = source[4]; */
	movb	260(%eax), %cl	 /* MEM[(byte *)source_23 + 260B], tmp189 */
	movb	%cl, 956(%edx)	 /* tmp189, MEM[(byte *)_1 + 956B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:276: 		dest[5] = source[5]; */
	movb	261(%eax), %cl	 /* MEM[(byte *)source_23 + 261B], tmp190 */
	movb	%cl, 957(%edx)	 /* tmp190, MEM[(byte *)_1 + 957B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:277: 		dest[6] = source[6]; */
	movb	262(%eax), %cl	 /* MEM[(byte *)source_23 + 262B], tmp191 */
	movb	%cl, 958(%edx)	 /* tmp191, MEM[(byte *)_1 + 958B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:278: 		dest[7] = source[7]; */
	movb	263(%eax), %cl	 /* MEM[(byte *)source_23 + 263B], tmp192 */
	movb	%cl, 959(%edx)	 /* tmp192, MEM[(byte *)_1 + 959B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:271: 		dest[0] = source[0]; */
	movb	384(%eax), %cl	 /* MEM[(byte *)source_23 + 384B], tmp193 */
	movb	%cl, 1272(%edx)	 /* tmp193, MEM[(byte *)_1 + 1272B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:272: 		dest[1] = source[1]; */
	movb	385(%eax), %cl	 /* MEM[(byte *)source_23 + 385B], tmp194 */
	movb	%cl, 1273(%edx)	 /* tmp194, MEM[(byte *)_1 + 1273B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:273: 		dest[2] = source[2]; */
	movb	386(%eax), %cl	 /* MEM[(byte *)source_23 + 386B], tmp195 */
	movb	%cl, 1274(%edx)	 /* tmp195, MEM[(byte *)_1 + 1274B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:274: 		dest[3] = source[3]; */
	movb	387(%eax), %cl	 /* MEM[(byte *)source_23 + 387B], tmp196 */
	movb	%cl, 1275(%edx)	 /* tmp196, MEM[(byte *)_1 + 1275B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:275: 		dest[4] = source[4]; */
	movb	388(%eax), %cl	 /* MEM[(byte *)source_23 + 388B], tmp197 */
	movb	%cl, 1276(%edx)	 /* tmp197, MEM[(byte *)_1 + 1276B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:276: 		dest[5] = source[5]; */
	movb	389(%eax), %cl	 /* MEM[(byte *)source_23 + 389B], tmp198 */
	movb	%cl, 1277(%edx)	 /* tmp198, MEM[(byte *)_1 + 1277B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:277: 		dest[6] = source[6]; */
	movb	390(%eax), %cl	 /* MEM[(byte *)source_23 + 390B], tmp199 */
	movb	%cl, 1278(%edx)	 /* tmp199, MEM[(byte *)_1 + 1278B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:278: 		dest[7] = source[7]; */
	movb	391(%eax), %cl	 /* MEM[(byte *)source_23 + 391B], tmp200 */
	movb	%cl, 1279(%edx)	 /* tmp200, MEM[(byte *)_1 + 1279B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:271: 		dest[0] = source[0]; */
	movb	512(%eax), %cl	 /* MEM[(byte *)source_23 + 512B], tmp201 */
	movb	%cl, 1592(%edx)	 /* tmp201, MEM[(byte *)_1 + 1592B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:272: 		dest[1] = source[1]; */
	movb	513(%eax), %cl	 /* MEM[(byte *)source_23 + 513B], tmp202 */
	movb	%cl, 1593(%edx)	 /* tmp202, MEM[(byte *)_1 + 1593B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:273: 		dest[2] = source[2]; */
	movb	514(%eax), %cl	 /* MEM[(byte *)source_23 + 514B], tmp203 */
	movb	%cl, 1594(%edx)	 /* tmp203, MEM[(byte *)_1 + 1594B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:274: 		dest[3] = source[3]; */
	movb	515(%eax), %cl	 /* MEM[(byte *)source_23 + 515B], tmp204 */
	movb	%cl, 1595(%edx)	 /* tmp204, MEM[(byte *)_1 + 1595B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:275: 		dest[4] = source[4]; */
	movb	516(%eax), %cl	 /* MEM[(byte *)source_23 + 516B], tmp205 */
	movb	%cl, 1596(%edx)	 /* tmp205, MEM[(byte *)_1 + 1596B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:276: 		dest[5] = source[5]; */
	movb	517(%eax), %cl	 /* MEM[(byte *)source_23 + 517B], tmp206 */
	movb	%cl, 1597(%edx)	 /* tmp206, MEM[(byte *)_1 + 1597B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:277: 		dest[6] = source[6]; */
	movb	518(%eax), %cl	 /* MEM[(byte *)source_23 + 518B], tmp207 */
	movb	%cl, 1598(%edx)	 /* tmp207, MEM[(byte *)_1 + 1598B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:278: 		dest[7] = source[7]; */
	movb	519(%eax), %cl	 /* MEM[(byte *)source_23 + 519B], tmp208 */
	movb	%cl, 1599(%edx)	 /* tmp208, MEM[(byte *)_1 + 1599B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:271: 		dest[0] = source[0]; */
	movb	640(%eax), %cl	 /* MEM[(byte *)source_23 + 640B], tmp209 */
	movb	%cl, 1912(%edx)	 /* tmp209, MEM[(byte *)_1 + 1912B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:272: 		dest[1] = source[1]; */
	movb	641(%eax), %cl	 /* MEM[(byte *)source_23 + 641B], tmp210 */
	movb	%cl, 1913(%edx)	 /* tmp210, MEM[(byte *)_1 + 1913B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:273: 		dest[2] = source[2]; */
	movb	642(%eax), %cl	 /* MEM[(byte *)source_23 + 642B], tmp211 */
	movb	%cl, 1914(%edx)	 /* tmp211, MEM[(byte *)_1 + 1914B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:274: 		dest[3] = source[3]; */
	movb	643(%eax), %cl	 /* MEM[(byte *)source_23 + 643B], tmp212 */
	movb	%cl, 1915(%edx)	 /* tmp212, MEM[(byte *)_1 + 1915B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:275: 		dest[4] = source[4]; */
	movb	644(%eax), %cl	 /* MEM[(byte *)source_23 + 644B], tmp213 */
	movb	%cl, 1916(%edx)	 /* tmp213, MEM[(byte *)_1 + 1916B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:276: 		dest[5] = source[5]; */
	movb	645(%eax), %cl	 /* MEM[(byte *)source_23 + 645B], tmp214 */
	movb	%cl, 1917(%edx)	 /* tmp214, MEM[(byte *)_1 + 1917B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:277: 		dest[6] = source[6]; */
	movb	646(%eax), %cl	 /* MEM[(byte *)source_23 + 646B], tmp215 */
	movb	%cl, 1918(%edx)	 /* tmp215, MEM[(byte *)_1 + 1918B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:278: 		dest[7] = source[7]; */
	movb	647(%eax), %cl	 /* MEM[(byte *)source_23 + 647B], tmp216 */
	movb	%cl, 1919(%edx)	 /* tmp216, MEM[(byte *)_1 + 1919B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:271: 		dest[0] = source[0]; */
	movb	768(%eax), %cl	 /* MEM[(byte *)source_23 + 768B], tmp217 */
	movb	%cl, 2232(%edx)	 /* tmp217, MEM[(byte *)_1 + 2232B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:272: 		dest[1] = source[1]; */
	movb	769(%eax), %cl	 /* MEM[(byte *)source_23 + 769B], tmp218 */
	movb	%cl, 2233(%edx)	 /* tmp218, MEM[(byte *)_1 + 2233B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:273: 		dest[2] = source[2]; */
	movb	770(%eax), %cl	 /* MEM[(byte *)source_23 + 770B], tmp219 */
	movb	%cl, 2234(%edx)	 /* tmp219, MEM[(byte *)_1 + 2234B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:274: 		dest[3] = source[3]; */
	movb	771(%eax), %cl	 /* MEM[(byte *)source_23 + 771B], tmp220 */
	movb	%cl, 2235(%edx)	 /* tmp220, MEM[(byte *)_1 + 2235B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:275: 		dest[4] = source[4]; */
	movb	772(%eax), %cl	 /* MEM[(byte *)source_23 + 772B], tmp221 */
	movb	%cl, 2236(%edx)	 /* tmp221, MEM[(byte *)_1 + 2236B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:276: 		dest[5] = source[5]; */
	movb	773(%eax), %cl	 /* MEM[(byte *)source_23 + 773B], tmp222 */
	movb	%cl, 2237(%edx)	 /* tmp222, MEM[(byte *)_1 + 2237B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:277: 		dest[6] = source[6]; */
	movb	774(%eax), %cl	 /* MEM[(byte *)source_23 + 774B], tmp223 */
	movb	%cl, 2238(%edx)	 /* tmp223, MEM[(byte *)_1 + 2238B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:278: 		dest[7] = source[7]; */
	movb	775(%eax), %cl	 /* MEM[(byte *)source_23 + 775B], tmp224 */
	movb	%cl, 2239(%edx)	 /* tmp224, MEM[(byte *)_1 + 2239B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:271: 		dest[0] = source[0]; */
	movb	896(%eax), %cl	 /* MEM[(byte *)source_23 + 896B], tmp225 */
	movb	%cl, 2552(%edx)	 /* tmp225, MEM[(byte *)_1 + 2552B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:272: 		dest[1] = source[1]; */
	movb	897(%eax), %cl	 /* MEM[(byte *)source_23 + 897B], tmp226 */
	movb	%cl, 2553(%edx)	 /* tmp226, MEM[(byte *)_1 + 2553B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:273: 		dest[2] = source[2]; */
	movb	898(%eax), %cl	 /* MEM[(byte *)source_23 + 898B], tmp227 */
	movb	%cl, 2554(%edx)	 /* tmp227, MEM[(byte *)_1 + 2554B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:274: 		dest[3] = source[3]; */
	movb	899(%eax), %cl	 /* MEM[(byte *)source_23 + 899B], tmp228 */
	movb	%cl, 2555(%edx)	 /* tmp228, MEM[(byte *)_1 + 2555B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:275: 		dest[4] = source[4]; */
	movb	900(%eax), %cl	 /* MEM[(byte *)source_23 + 900B], tmp229 */
	movb	%cl, 2556(%edx)	 /* tmp229, MEM[(byte *)_1 + 2556B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:276: 		dest[5] = source[5]; */
	movb	901(%eax), %cl	 /* MEM[(byte *)source_23 + 901B], tmp230 */
	movb	%cl, 2557(%edx)	 /* tmp230, MEM[(byte *)_1 + 2557B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:277: 		dest[6] = source[6]; */
	movb	902(%eax), %cl	 /* MEM[(byte *)source_23 + 902B], tmp231 */
	movb	%cl, 2558(%edx)	 /* tmp231, MEM[(byte *)_1 + 2558B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:278: 		dest[7] = source[7]; */
	movb	903(%eax), %al	 /* MEM[(byte *)source_23 + 903B], tmp232 */
	movb	%al, 2559(%edx)	 /* tmp232, MEM[(byte *)_1 + 2559B] */
L101:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:282: } */
	ret
.data
LC5:
	.ascii "Draw_Pic: bad coordinates\0"
	.p2align 3
.text
	.globl	_Draw_Pic
/* Draw_Pic: Copy opaque indexed rows or translate each index through the original 16-bit palette. */
_Draw_Pic:
	pushl	%ebp	 /*  */
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	subl	$12, %esp	 /* , */
	movl	32(%esp), %edi	 /* x, x */
	movl	36(%esp), %ebp	 /* y, y */
	movl	40(%esp), %esi	 /* pic, pic */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:295: 	if ((x < 0) || */
	testl	%edi, %edi	 /* x */
	js	L107	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:296: 		(x + pic->width > vid.width) || */
	movl	(%esi), %eax	 /* pic_57(D)->width, tmp124 */
	addl	%edi, %eax	 /* x, tmp124 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:295: 	if ((x < 0) || */
	cmpl	%eax, _vid+20	 /* tmp124, vid.width */
	jnb	L118	 /* , */
L107:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:300: 		Sys_Error ("Draw_Pic: bad coordinates"); */
	subl	$12, %esp	 /* , */
	pushl	$LC5	 /*  */
	call	_Sys_Error	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:309: 		for (v=0 ; v<pic->height ; v++) */
	movl	4(%esi), %eax	 /* pic_57(D)->height, prephitmp_40 */
	addl	$16, %esp	 /* , */
L108:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:303: 	source = pic->data; */
	leal	8(%esi), %ebx	 /* , source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:307: 		dest = vid.buffer + y * vid.rowbytes + x; */
	movl	_vid, %ecx	 /* vid.buffer, pretmp_120 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:307: 		dest = vid.buffer + y * vid.rowbytes + x; */
	movl	_vid+16, %edx	 /* vid.rowbytes, pretmp_121 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:305: 	if (r_pixbytes == 1) */
	cmpl	$1, _r_pixbytes	 /* , r_pixbytes */
	je	L119	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:319: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	shrl	$1, %edx	 /* , tmp137 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:319: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	imull	%ebp, %edx	 /* y, tmp138 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:319: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	addl	%edi, %edx	 /* x, tmp139 */
	addl	%edx, %edx	 /* tmp139, tmp140 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:319: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	addl	%edx, %ecx	 /* tmp140, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:321: 		for (v=0 ; v<pic->height ; v++) */
	testl	%eax, %eax	 /* prephitmp_40 */
	jle	L106	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:323: 			for (u=0 ; u<pic->width ; u++) */
	movl	(%esi), %edx	 /* pic_57(D)->width, _36 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:321: 		for (v=0 ; v<pic->height ; v++) */
	xorl	%edi, %edi	 /* v */
	.p2align 3
	.p2align 3
L112:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:323: 			for (u=0 ; u<pic->width ; u++) */
	testl	%edx, %edx	 /* _36 */
	jle	L106	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:323: 			for (u=0 ; u<pic->width ; u++) */
	xorl	%ebp, %ebp	 /* u */
	.p2align 3
	.p2align 3
L113:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:325: 				pusdest[u] = d_8to16table[source[u]]; */
	xorl	%eax, %eax	 /* MEM[(byte *)source_87 + _11 * 1] */
	movb	(%ebx,%ebp), %al	 /* MEM[(byte *)source_87 + _11 * 1], MEM[(byte *)source_87 + _11 * 1] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:325: 				pusdest[u] = d_8to16table[source[u]]; */
	movw	_d_8to16table(%eax,%eax), %dx	 /* d_8to16table[_32], _35 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:325: 				pusdest[u] = d_8to16table[source[u]]; */
	movw	%dx, (%ecx,%ebp,2)	 /* _35, MEM[(short unsigned int *)pusdest_88 + _11 * 2] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:323: 			for (u=0 ; u<pic->width ; u++) */
	incl	%ebp	 /* u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:323: 			for (u=0 ; u<pic->width ; u++) */
	movl	(%esi), %edx	 /* pic_57(D)->width, _36 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:323: 			for (u=0 ; u<pic->width ; u++) */
	cmpl	%ebp, %edx	 /* u, _36 */
	jg	L113	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:328: 			pusdest += vid.rowbytes >> 1; */
	movl	_vid+16, %ebp	 /* vid.rowbytes, tmp147 */
	andl	$-2, %ebp	 /* , tmp147 */
	addl	%ebp, %ecx	 /* tmp147, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:329: 			source += pic->width; */
	addl	%edx, %ebx	 /* _36, source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:321: 		for (v=0 ; v<pic->height ; v++) */
	incl	%edi	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:321: 		for (v=0 ; v<pic->height ; v++) */
	cmpl	4(%esi), %edi	 /* pic_57(D)->height, v */
	jl	L112	 /* , */
L106:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:332: } */
	addl	$12, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
L118:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:296: 		(x + pic->width > vid.width) || */
	testl	%ebp, %ebp	 /* y */
	js	L107	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:298: 		(y + pic->height > vid.height)) */
	movl	4(%esi), %eax	 /* pic_57(D)->height, prephitmp_40 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:298: 		(y + pic->height > vid.height)) */
	leal	(%eax,%ebp), %edx	 /* , tmp127 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:297: 		(y < 0) || */
	cmpl	%edx, _vid+24	 /* tmp127, vid.height */
	jnb	L108	 /* , */
	jmp	L107	 /*  */
L119:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:307: 		dest = vid.buffer + y * vid.rowbytes + x; */
	imull	%ebp, %edx	 /* y, tmp131 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:307: 		dest = vid.buffer + y * vid.rowbytes + x; */
	addl	%edx, %edi	 /* tmp131, tmp132 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:307: 		dest = vid.buffer + y * vid.rowbytes + x; */
	addl	%ecx, %edi	 /* pretmp_120, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:309: 		for (v=0 ; v<pic->height ; v++) */
	testl	%eax, %eax	 /* prephitmp_40 */
	jle	L106	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:323: 			for (u=0 ; u<pic->width ; u++) */
	movl	(%esi), %ecx	 /* pic_57(D)->width, _18 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:309: 		for (v=0 ; v<pic->height ; v++) */
	xorl	%ebp, %ebp	 /* v */
	.p2align 3
	.p2align 3
L111:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:311: 			Q_memcpy (dest, source, pic->width); */
	pushl	%edx	 /*  */
	pushl	%ecx	 /* _18 */
	pushl	%ebx	 /* source */
	pushl	%edi	 /* dest */
	call	_Q_memcpy	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:312: 			dest += vid.rowbytes; */
	addl	_vid+16, %edi	 /* vid.rowbytes, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:313: 			source += pic->width; */
	movl	(%esi), %ecx	 /* pic_57(D)->width, _18 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:313: 			source += pic->width; */
	addl	%ecx, %ebx	 /* _18, source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:309: 		for (v=0 ; v<pic->height ; v++) */
	incl	%ebp	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:309: 		for (v=0 ; v<pic->height ; v++) */
	addl	$16, %esp	 /* , */
	cmpl	%ebp, 4(%esi)	 /* v, pic_57(D)->height */
	jg	L111	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:332: } */
	addl	$12, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
	.p2align 2
.data
LC6:
	.ascii "Draw_TransPic: bad coordinates\0"
	.p2align 3
.text
	.globl	_Draw_TransPic
/* Draw_TransPic: Preserve index-255 transparency, general and eight-pixel row paths. */
_Draw_TransPic:
	pushl	%ebp	 /*  */
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	subl	$28, %esp	 /* , */
	movl	48(%esp), %ebx	 /* x, x */
	movl	52(%esp), %ebp	 /* y, y */
	movl	56(%esp), %edi	 /* pic, pic */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:346: 	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 || */
	testl	%ebx, %ebx	 /* x */
	js	L121	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:346: 	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 || */
	movl	(%edi), %eax	 /* pic_108(D)->width, tmp152 */
	addl	%ebx, %eax	 /* x, tmp152 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:346: 	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 || */
	cmpl	%eax, _vid+20	 /* tmp152, vid.width */
	jnb	L181	 /* , */
L121:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:349: 		Sys_Error ("Draw_TransPic: bad coordinates"); */
	subl	$12, %esp	 /* , */
	pushl	$LC6	 /*  */
	call	_Sys_Error	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:372: 			for (v=0 ; v<pic->height ; v++) */
	movl	4(%edi), %eax	 /* pic_108(D)->height, pretmp_206 */
	addl	$16, %esp	 /* , */
L122:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:352: 	source = pic->data; */
	leal	8(%edi), %esi	 /* , source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:356: 		dest = vid.buffer + y * vid.rowbytes + x; */
	movl	_vid, %ecx	 /* vid.buffer, pretmp_260 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:356: 		dest = vid.buffer + y * vid.rowbytes + x; */
	movl	_vid+16, %edx	 /* vid.rowbytes, pretmp_261 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:354: 	if (r_pixbytes == 1) */
	cmpl	$1, _r_pixbytes	 /* , r_pixbytes */
	je	L182	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:401: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	shrl	$1, %edx	 /* , tmp169 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:401: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	imull	%ebp, %edx	 /* y, tmp170 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:401: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	addl	%ebx, %edx	 /* x, tmp171 */
	addl	%edx, %edx	 /* tmp171, tmp172 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:401: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	addl	%edx, %ecx	 /* tmp172, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:403: 		for (v=0 ; v<pic->height ; v++) */
	testl	%eax, %eax	 /* pretmp_206 */
	jle	L120	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:358: 		if (pic->width & 7) */
	movl	(%edi), %ebp	 /* pic_108(D)->width, prephitmp_41 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:403: 		for (v=0 ; v<pic->height ; v++) */
	xorl	%ebx, %ebx	 /* v */
	.p2align 3
	.p2align 3
L144:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:405: 			for (u=0 ; u<pic->width ; u++) */
	testl	%ebp, %ebp	 /* prephitmp_41 */
	jle	L120	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:405: 			for (u=0 ; u<pic->width ; u++) */
	xorl	%eax, %eax	 /* u */
	.p2align 3
	.p2align 3
L148:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:407: 				tbyte = source[u]; */
	movb	(%esi,%eax), %dl	 /* MEM[(byte *)source_174 + _326 * 1], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:409: 				if (tbyte != TRANSPARENT_COLOR) */
	cmpb	$-1, %dl	 /* , tbyte */
	je	L145	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:411: 					pusdest[u] = d_8to16table[tbyte]; */
	andl	$255, %edx	 /* , tbyte */
	movw	_d_8to16table(%edx,%edx), %bp	 /* d_8to16table[_64], _68 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:411: 					pusdest[u] = d_8to16table[tbyte]; */
	movw	%bp, (%ecx,%eax,2)	 /* _68, MEM[(short unsigned int *)pusdest_175 + _326 * 2] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:405: 			for (u=0 ; u<pic->width ; u++) */
	movl	(%edi), %ebp	 /* pic_108(D)->width, prephitmp_41 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:405: 			for (u=0 ; u<pic->width ; u++) */
	incl	%eax	 /* u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:405: 			for (u=0 ; u<pic->width ; u++) */
	cmpl	%ebp, %eax	 /* prephitmp_41, u */
	jl	L148	 /* , */
L147:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:415: 			pusdest += vid.rowbytes >> 1; */
	movl	_vid+16, %eax	 /* vid.rowbytes, tmp178 */
	andl	$-2, %eax	 /* , tmp178 */
	addl	%eax, %ecx	 /* tmp178, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:416: 			source += pic->width; */
	addl	%ebp, %esi	 /* prephitmp_41, source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:403: 		for (v=0 ; v<pic->height ; v++) */
	incl	%ebx	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:403: 		for (v=0 ; v<pic->height ; v++) */
	cmpl	4(%edi), %ebx	 /* pic_108(D)->height, v */
	jl	L144	 /* , */
L120:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:419: } */
	addl	$28, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
	.p2align 4
	.p2align 3
L145:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:405: 			for (u=0 ; u<pic->width ; u++) */
	incl	%eax	 /* u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:405: 			for (u=0 ; u<pic->width ; u++) */
	cmpl	%ebp, %eax	 /* prephitmp_41, u */
	jl	L148	 /* , */
	jmp	L147	 /*  */
L181:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:346: 	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 || */
	testl	%ebp, %ebp	 /* y */
	js	L121	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:347: 		 (unsigned)(y + pic->height) > vid.height) */
	movl	4(%edi), %eax	 /* pic_108(D)->height, pretmp_206 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:347: 		 (unsigned)(y + pic->height) > vid.height) */
	leal	(%eax,%ebp), %edx	 /* , tmp155 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:346: 	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 || */
	cmpl	%edx, _vid+24	 /* tmp155, vid.height */
	jnb	L122	 /* , */
	jmp	L121	 /*  */
L182:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:356: 		dest = vid.buffer + y * vid.rowbytes + x; */
	imull	%ebp, %edx	 /* y, tmp159 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:356: 		dest = vid.buffer + y * vid.rowbytes + x; */
	addl	%ebx, %edx	 /* x, tmp160 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:356: 		dest = vid.buffer + y * vid.rowbytes + x; */
	leal	(%ecx,%edx), %ebp	 /* , dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:358: 		if (pic->width & 7) */
	movl	(%edi), %ebx	 /* pic_108(D)->width, prephitmp_43 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:358: 		if (pic->width & 7) */
	testb	$7, %bl	 /* , prephitmp_43 */
	jne	L124	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:372: 			for (v=0 ; v<pic->height ; v++) */
	xorl	%ecx, %ecx	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:372: 			for (v=0 ; v<pic->height ; v++) */
	testl	%eax, %eax	 /* pretmp_206 */
	jle	L120	 /* , */
	movl	%esi, 12(%esp)	 /* source, %sfp */
	movl	%ecx, %esi	 /* v, v */
	.p2align 3
	.p2align 3
L125:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:374: 				for (u=0 ; u<pic->width ; u+=8) */
	testl	%ebx, %ebx	 /* prephitmp_43 */
	jle	L120	 /* , */
	movl	12(%esp), %eax	 /* %sfp, ivtmp.216 */
	movl	%ebp, %edx	 /* dest, ivtmp.217 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:374: 				for (u=0 ; u<pic->width ; u+=8) */
	xorl	%ecx, %ecx	 /* u */
	.p2align 3
	.p2align 3
L142:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:376: 					if ( (tbyte=source[u]) != TRANSPARENT_COLOR) */
	movb	(%eax), %bl	 /* MEM[(byte *)_331], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:376: 					if ( (tbyte=source[u]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %bl	 /* , tbyte */
	je	L132	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:377: 						dest[u] = tbyte; */
	movb	%bl, (%edx)	 /* tbyte, MEM[(byte *)_293] */
L132:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:378: 					if ( (tbyte=source[u+1]) != TRANSPARENT_COLOR) */
	movb	1(%eax), %bl	 /* MEM[(byte *)_331 + 1B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:378: 					if ( (tbyte=source[u+1]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %bl	 /* , tbyte */
	je	L133	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:379: 						dest[u+1] = tbyte; */
	movb	%bl, 1(%edx)	 /* tbyte, MEM[(byte *)_292 + 1B] */
L133:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:380: 					if ( (tbyte=source[u+2]) != TRANSPARENT_COLOR) */
	movb	2(%eax), %bl	 /* MEM[(byte *)_331 + 2B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:380: 					if ( (tbyte=source[u+2]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %bl	 /* , tbyte */
	je	L134	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:381: 						dest[u+2] = tbyte; */
	movb	%bl, 2(%edx)	 /* tbyte, MEM[(byte *)_291 + 2B] */
L134:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:382: 					if ( (tbyte=source[u+3]) != TRANSPARENT_COLOR) */
	movb	3(%eax), %bl	 /* MEM[(byte *)_331 + 3B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:382: 					if ( (tbyte=source[u+3]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %bl	 /* , tbyte */
	je	L135	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:383: 						dest[u+3] = tbyte; */
	movb	%bl, 3(%edx)	 /* tbyte, MEM[(byte *)_321 + 3B] */
L135:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:384: 					if ( (tbyte=source[u+4]) != TRANSPARENT_COLOR) */
	movb	4(%eax), %bl	 /* MEM[(byte *)_331 + 4B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:384: 					if ( (tbyte=source[u+4]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %bl	 /* , tbyte */
	je	L136	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:385: 						dest[u+4] = tbyte; */
	movb	%bl, 4(%edx)	 /* tbyte, MEM[(byte *)_322 + 4B] */
L136:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:386: 					if ( (tbyte=source[u+5]) != TRANSPARENT_COLOR) */
	movb	5(%eax), %bl	 /* MEM[(byte *)_331 + 5B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:386: 					if ( (tbyte=source[u+5]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %bl	 /* , tbyte */
	je	L137	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:387: 						dest[u+5] = tbyte; */
	movb	%bl, 5(%edx)	 /* tbyte, MEM[(byte *)_323 + 5B] */
L137:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:388: 					if ( (tbyte=source[u+6]) != TRANSPARENT_COLOR) */
	movb	6(%eax), %bl	 /* MEM[(byte *)_331 + 6B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:388: 					if ( (tbyte=source[u+6]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %bl	 /* , tbyte */
	je	L138	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:389: 						dest[u+6] = tbyte; */
	movb	%bl, 6(%edx)	 /* tbyte, MEM[(byte *)_324 + 6B] */
L138:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:390: 					if ( (tbyte=source[u+7]) != TRANSPARENT_COLOR) */
	movb	7(%eax), %bl	 /* MEM[(byte *)_331 + 7B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:390: 					if ( (tbyte=source[u+7]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %bl	 /* , tbyte */
	je	L139	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:391: 						dest[u+7] = tbyte; */
	movb	%bl, 7(%edx)	 /* tbyte, MEM[(byte *)_325 + 7B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:374: 				for (u=0 ; u<pic->width ; u+=8) */
	addl	$8, %ecx	 /* , u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:374: 				for (u=0 ; u<pic->width ; u+=8) */
	movl	(%edi), %ebx	 /* pic_108(D)->width, prephitmp_43 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:374: 				for (u=0 ; u<pic->width ; u+=8) */
	addl	$8, %eax	 /* , ivtmp.216 */
	addl	$8, %edx	 /* , ivtmp.217 */
	cmpl	%ebx, %ecx	 /* prephitmp_43, u */
	jl	L142	 /* , */
L141:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:393: 				dest += vid.rowbytes; */
	addl	_vid+16, %ebp	 /* vid.rowbytes, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:394: 				source += pic->width; */
	addl	%ebx, 12(%esp)	 /* prephitmp_43, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:372: 			for (v=0 ; v<pic->height ; v++) */
	incl	%esi	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:372: 			for (v=0 ; v<pic->height ; v++) */
	cmpl	4(%edi), %esi	 /* pic_108(D)->height, v */
	jl	L125	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:419: } */
	addl	$28, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
L124:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:360: 			for (v=0 ; v<pic->height ; v++) */
	xorl	%edx, %edx	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:360: 			for (v=0 ; v<pic->height ; v++) */
	testl	%eax, %eax	 /* pretmp_206 */
	jle	L120	 /* , */
	.p2align 3
	.p2align 3
L127:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:362: 				for (u=0 ; u<pic->width ; u++) */
	testl	%ebx, %ebx	 /* prephitmp_43 */
	jle	L120	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:362: 				for (u=0 ; u<pic->width ; u++) */
	xorl	%eax, %eax	 /* u */
	.p2align 3
	.p2align 3
L131:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:363: 					if ( (tbyte=source[u]) != TRANSPARENT_COLOR) */
	movb	(%esi,%eax), %cl	 /* MEM[(byte *)source_156 + _334 * 1], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:363: 					if ( (tbyte=source[u]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , tbyte */
	je	L128	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:364: 						dest[u] = tbyte; */
	movb	%cl, 0(%ebp,%eax)	 /* tbyte, MEM[(byte *)dest_157 + _334 * 1] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:362: 				for (u=0 ; u<pic->width ; u++) */
	movl	(%edi), %ebx	 /* pic_108(D)->width, prephitmp_43 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:362: 				for (u=0 ; u<pic->width ; u++) */
	incl	%eax	 /* u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:362: 				for (u=0 ; u<pic->width ; u++) */
	cmpl	%ebx, %eax	 /* prephitmp_43, u */
	jl	L131	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:366: 				dest += vid.rowbytes; */
	addl	_vid+16, %ebp	 /* vid.rowbytes, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:367: 				source += pic->width; */
	addl	%ebx, %esi	 /* prephitmp_43, source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:360: 			for (v=0 ; v<pic->height ; v++) */
	incl	%edx	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:360: 			for (v=0 ; v<pic->height ; v++) */
	cmpl	%edx, 4(%edi)	 /* v, pic_108(D)->height */
	jg	L127	 /* , */
L180:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:419: } */
	addl	$28, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
	.p2align 4
	.p2align 3
L128:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:362: 				for (u=0 ; u<pic->width ; u++) */
	incl	%eax	 /* u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:362: 				for (u=0 ; u<pic->width ; u++) */
	cmpl	%ebx, %eax	 /* prephitmp_43, u */
	jl	L131	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:366: 				dest += vid.rowbytes; */
	addl	_vid+16, %ebp	 /* vid.rowbytes, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:367: 				source += pic->width; */
	addl	%ebx, %esi	 /* prephitmp_43, source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:360: 			for (v=0 ; v<pic->height ; v++) */
	incl	%edx	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:360: 			for (v=0 ; v<pic->height ; v++) */
	cmpl	%edx, 4(%edi)	 /* v, pic_108(D)->height */
	jg	L127	 /* , */
	jmp	L180	 /*  */
	.p2align 4
	.p2align 3
L139:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:374: 				for (u=0 ; u<pic->width ; u+=8) */
	addl	$8, %ecx	 /* , u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:374: 				for (u=0 ; u<pic->width ; u+=8) */
	movl	(%edi), %ebx	 /* pic_108(D)->width, prephitmp_43 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:374: 				for (u=0 ; u<pic->width ; u+=8) */
	addl	$8, %eax	 /* , ivtmp.216 */
	addl	$8, %edx	 /* , ivtmp.217 */
	cmpl	%ecx, %ebx	 /* u, prephitmp_43 */
	jg	L142	 /* , */
	jmp	L141	 /*  */
	.p2align 3
	.globl	_Draw_TransPicTranslate
/* Draw_TransPicTranslate: Apply the translation table only in the original indexed path. */
_Draw_TransPicTranslate:
	pushl	%ebp	 /*  */
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	subl	$28, %esp	 /* , */
	movl	48(%esp), %edi	 /* x, x */
	movl	56(%esp), %esi	 /* pic, pic */
	movl	60(%esp), %ebx	 /* translation, translation */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:433: 	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 || */
	testl	%edi, %edi	 /* x */
	js	L184	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:433: 	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 || */
	movl	(%esi), %eax	 /* pic_135(D)->width, tmp180 */
	addl	%edi, %eax	 /* x, tmp180 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:433: 	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 || */
	cmpl	%eax, _vid+20	 /* tmp180, vid.width */
	jnb	L244	 /* , */
L184:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:436: 		Sys_Error ("Draw_TransPic: bad coordinates"); */
	subl	$12, %esp	 /* , */
	pushl	$LC6	 /*  */
	call	_Sys_Error	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:459: 			for (v=0 ; v<pic->height ; v++) */
	movl	4(%esi), %eax	 /* pic_135(D)->height, pretmp_234 */
	addl	$16, %esp	 /* , */
L185:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:439: 	source = pic->data; */
	leal	8(%esi), %ecx	 /* , source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:443: 		dest = vid.buffer + y * vid.rowbytes + x; */
	movl	_vid, %ebp	 /* vid.buffer, pretmp_315 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:443: 		dest = vid.buffer + y * vid.rowbytes + x; */
	movl	_vid+16, %edx	 /* vid.rowbytes, pretmp_316 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:441: 	if (r_pixbytes == 1) */
	cmpl	$1, _r_pixbytes	 /* , r_pixbytes */
	je	L245	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:488: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	shrl	$1, %edx	 /* , tmp206 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:488: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	imull	52(%esp), %edx	 /* y, tmp207 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:488: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	leal	(%edx,%edi), %ebx	 /* , tmp208 */
	addl	%ebx, %ebx	 /* tmp208, tmp209 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:488: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	addl	%ebp, %ebx	 /* pretmp_315, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:490: 		for (v=0 ; v<pic->height ; v++) */
	testl	%eax, %eax	 /* pretmp_234 */
	jle	L183	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:445: 		if (pic->width & 7) */
	movl	(%esi), %ebp	 /* pic_135(D)->width, prephitmp_59 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:490: 		for (v=0 ; v<pic->height ; v++) */
	xorl	%edi, %edi	 /* v */
	.p2align 3
	.p2align 3
L207:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:492: 			for (u=0 ; u<pic->width ; u++) */
	testl	%ebp, %ebp	 /* prephitmp_59 */
	jle	L183	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:492: 			for (u=0 ; u<pic->width ; u++) */
	xorl	%eax, %eax	 /* u */
	.p2align 3
	.p2align 3
L211:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:494: 				tbyte = source[u]; */
	movb	(%ecx,%eax), %dl	 /* MEM[(byte *)source_202 + _381 * 1], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:496: 				if (tbyte != TRANSPARENT_COLOR) */
	cmpb	$-1, %dl	 /* , tbyte */
	je	L208	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:498: 					pusdest[u] = d_8to16table[tbyte]; */
	andl	$255, %edx	 /* , tbyte */
	movw	_d_8to16table(%edx,%edx), %bp	 /* d_8to16table[_91], _95 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:498: 					pusdest[u] = d_8to16table[tbyte]; */
	movw	%bp, (%ebx,%eax,2)	 /* _95, MEM[(short unsigned int *)pusdest_203 + _381 * 2] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:492: 			for (u=0 ; u<pic->width ; u++) */
	movl	(%esi), %ebp	 /* pic_135(D)->width, prephitmp_59 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:492: 			for (u=0 ; u<pic->width ; u++) */
	incl	%eax	 /* u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:492: 			for (u=0 ; u<pic->width ; u++) */
	cmpl	%ebp, %eax	 /* prephitmp_59, u */
	jl	L211	 /* , */
L210:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:502: 			pusdest += vid.rowbytes >> 1; */
	movl	_vid+16, %eax	 /* vid.rowbytes, tmp215 */
	andl	$-2, %eax	 /* , tmp215 */
	addl	%eax, %ebx	 /* tmp215, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:503: 			source += pic->width; */
	addl	%ebp, %ecx	 /* prephitmp_59, source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:490: 		for (v=0 ; v<pic->height ; v++) */
	incl	%edi	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:490: 		for (v=0 ; v<pic->height ; v++) */
	cmpl	%edi, 4(%esi)	 /* v, pic_135(D)->height */
	jg	L207	 /* , */
L183:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:506: } */
	addl	$28, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
	.p2align 4
	.p2align 3
L208:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:492: 			for (u=0 ; u<pic->width ; u++) */
	incl	%eax	 /* u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:492: 			for (u=0 ; u<pic->width ; u++) */
	cmpl	%ebp, %eax	 /* prephitmp_59, u */
	jl	L211	 /* , */
	jmp	L210	 /*  */
L244:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:433: 	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 || */
	movl	52(%esp), %edx	 /* y, */
	testl	%edx, %edx	 /*  */
	js	L184	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:434: 		 (unsigned)(y + pic->height) > vid.height) */
	movl	4(%esi), %eax	 /* pic_135(D)->height, pretmp_234 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:434: 		 (unsigned)(y + pic->height) > vid.height) */
	movl	52(%esp), %ecx	 /* y, tmp183 */
	addl	%eax, %ecx	 /* pretmp_234, tmp183 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:433: 	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 || */
	cmpl	%ecx, _vid+24	 /* tmp183, vid.height */
	jnb	L185	 /* , */
	jmp	L184	 /*  */
L245:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:443: 		dest = vid.buffer + y * vid.rowbytes + x; */
	imull	52(%esp), %edx	 /* y, tmp187 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:443: 		dest = vid.buffer + y * vid.rowbytes + x; */
	addl	%edi, %edx	 /* x, tmp188 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:443: 		dest = vid.buffer + y * vid.rowbytes + x; */
	leal	0(%ebp,%edx), %edx	 /* , dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:445: 		if (pic->width & 7) */
	movl	(%esi), %edi	 /* pic_135(D)->width, prephitmp_64 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:445: 		if (pic->width & 7) */
	testl	$7, %edi	 /* , prephitmp_64 */
	jne	L187	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:459: 			for (v=0 ; v<pic->height ; v++) */
	movl	$0, 8(%esp)	 /* , %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:459: 			for (v=0 ; v<pic->height ; v++) */
	testl	%eax, %eax	 /* pretmp_234 */
	jle	L183	 /* , */
	movl	%ecx, 12(%esp)	 /* source, %sfp */
	movl	%edi, %ecx	 /* prephitmp_64, prephitmp_64 */
	movl	%edx, %edi	 /* dest, dest */
	.p2align 3
	.p2align 3
L188:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:461: 				for (u=0 ; u<pic->width ; u+=8) */
	testl	%ecx, %ecx	 /* prephitmp_64 */
	jle	L183	 /* , */
	movl	12(%esp), %eax	 /* %sfp, ivtmp.244 */
	movl	%edi, %edx	 /* dest, ivtmp.245 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:461: 				for (u=0 ; u<pic->width ; u+=8) */
	xorl	%ebp, %ebp	 /* u */
	.p2align 3
	.p2align 3
L205:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:463: 					if ( (tbyte=source[u]) != TRANSPARENT_COLOR) */
	movb	(%eax), %cl	 /* MEM[(byte *)_386], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:463: 					if ( (tbyte=source[u]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , tbyte */
	je	L195	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:464: 						dest[u] = translation[tbyte]; */
	andl	$255, %ecx	 /* , tbyte */
	movb	(%ebx,%ecx), %cl	 /* *_31, tmp252 */
	movb	%cl, (%edx)	 /* tmp252, MEM[(byte *)_348] */
L195:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:465: 					if ( (tbyte=source[u+1]) != TRANSPARENT_COLOR) */
	movb	1(%eax), %cl	 /* MEM[(byte *)_386 + 1B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:465: 					if ( (tbyte=source[u+1]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , tbyte */
	je	L196	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:466: 						dest[u+1] = translation[tbyte]; */
	andl	$255, %ecx	 /* , tbyte */
	movb	(%ebx,%ecx), %cl	 /* *_37, tmp253 */
	movb	%cl, 1(%edx)	 /* tmp253, MEM[(byte *)_347 + 1B] */
L196:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:467: 					if ( (tbyte=source[u+2]) != TRANSPARENT_COLOR) */
	movb	2(%eax), %cl	 /* MEM[(byte *)_386 + 2B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:467: 					if ( (tbyte=source[u+2]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , tbyte */
	je	L197	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:468: 						dest[u+2] = translation[tbyte]; */
	andl	$255, %ecx	 /* , tbyte */
	movb	(%ebx,%ecx), %cl	 /* *_43, tmp254 */
	movb	%cl, 2(%edx)	 /* tmp254, MEM[(byte *)_346 + 2B] */
L197:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:469: 					if ( (tbyte=source[u+3]) != TRANSPARENT_COLOR) */
	movb	3(%eax), %cl	 /* MEM[(byte *)_386 + 3B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:469: 					if ( (tbyte=source[u+3]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , tbyte */
	je	L198	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:470: 						dest[u+3] = translation[tbyte]; */
	andl	$255, %ecx	 /* , tbyte */
	movb	(%ebx,%ecx), %cl	 /* *_49, tmp255 */
	movb	%cl, 3(%edx)	 /* tmp255, MEM[(byte *)_376 + 3B] */
L198:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:471: 					if ( (tbyte=source[u+4]) != TRANSPARENT_COLOR) */
	movb	4(%eax), %cl	 /* MEM[(byte *)_386 + 4B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:471: 					if ( (tbyte=source[u+4]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , tbyte */
	je	L199	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:472: 						dest[u+4] = translation[tbyte]; */
	andl	$255, %ecx	 /* , tbyte */
	movb	(%ebx,%ecx), %cl	 /* *_55, tmp256 */
	movb	%cl, 4(%edx)	 /* tmp256, MEM[(byte *)_377 + 4B] */
L199:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:473: 					if ( (tbyte=source[u+5]) != TRANSPARENT_COLOR) */
	movb	5(%eax), %cl	 /* MEM[(byte *)_386 + 5B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:473: 					if ( (tbyte=source[u+5]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , tbyte */
	je	L200	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:474: 						dest[u+5] = translation[tbyte]; */
	andl	$255, %ecx	 /* , tbyte */
	movb	(%ebx,%ecx), %cl	 /* *_61, tmp257 */
	movb	%cl, 5(%edx)	 /* tmp257, MEM[(byte *)_378 + 5B] */
L200:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:475: 					if ( (tbyte=source[u+6]) != TRANSPARENT_COLOR) */
	movb	6(%eax), %cl	 /* MEM[(byte *)_386 + 6B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:475: 					if ( (tbyte=source[u+6]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , tbyte */
	je	L201	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:476: 						dest[u+6] = translation[tbyte]; */
	andl	$255, %ecx	 /* , tbyte */
	movb	(%ebx,%ecx), %cl	 /* *_67, tmp258 */
	movb	%cl, 6(%edx)	 /* tmp258, MEM[(byte *)_379 + 6B] */
L201:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:477: 					if ( (tbyte=source[u+7]) != TRANSPARENT_COLOR) */
	movb	7(%eax), %cl	 /* MEM[(byte *)_386 + 7B], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:477: 					if ( (tbyte=source[u+7]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , tbyte */
	je	L202	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:478: 						dest[u+7] = translation[tbyte]; */
	andl	$255, %ecx	 /* , tbyte */
	movb	(%ebx,%ecx), %cl	 /* *_73, tmp259 */
	movb	%cl, 7(%edx)	 /* tmp259, MEM[(byte *)_380 + 7B] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:461: 				for (u=0 ; u<pic->width ; u+=8) */
	addl	$8, %ebp	 /* , u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:461: 				for (u=0 ; u<pic->width ; u+=8) */
	movl	(%esi), %ecx	 /* pic_135(D)->width, prephitmp_64 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:461: 				for (u=0 ; u<pic->width ; u+=8) */
	addl	$8, %eax	 /* , ivtmp.244 */
	addl	$8, %edx	 /* , ivtmp.245 */
	cmpl	%ecx, %ebp	 /* prephitmp_64, u */
	jl	L205	 /* , */
L204:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:480: 				dest += vid.rowbytes; */
	addl	_vid+16, %edi	 /* vid.rowbytes, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:481: 				source += pic->width; */
	addl	%ecx, 12(%esp)	 /* prephitmp_64, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:459: 			for (v=0 ; v<pic->height ; v++) */
	incl	8(%esp)	 /* %sfp */
	movl	8(%esp), %eax	 /* %sfp, v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:459: 			for (v=0 ; v<pic->height ; v++) */
	cmpl	4(%esi), %eax	 /* pic_135(D)->height, v */
	jl	L188	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:506: } */
	addl	$28, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
L187:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:447: 			for (v=0 ; v<pic->height ; v++) */
	xorl	%ebp, %ebp	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:447: 			for (v=0 ; v<pic->height ; v++) */
	testl	%eax, %eax	 /* pretmp_234 */
	jle	L183	 /* , */
	movl	%ebp, 8(%esp)	 /* v, %sfp */
	movl	%edx, %ebp	 /* dest, dest */
	.p2align 3
	.p2align 3
L190:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:449: 				for (u=0 ; u<pic->width ; u++) */
	testl	%edi, %edi	 /* prephitmp_64 */
	jle	L183	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:449: 				for (u=0 ; u<pic->width ; u++) */
	xorl	%eax, %eax	 /* u */
	.p2align 3
	.p2align 3
L194:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:450: 					if ( (tbyte=source[u]) != TRANSPARENT_COLOR) */
	movb	(%ecx,%eax), %dl	 /* MEM[(byte *)source_184 + _389 * 1], tbyte */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:450: 					if ( (tbyte=source[u]) != TRANSPARENT_COLOR) */
	cmpb	$-1, %dl	 /* , tbyte */
	je	L191	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:451: 						dest[u] = translation[tbyte]; */
	andl	$255, %edx	 /* , tbyte */
	movb	(%ebx,%edx), %dl	 /* *_21, tmp249 */
	movb	%dl, 0(%ebp,%eax)	 /* tmp249, MEM[(byte *)dest_185 + _389 * 1] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:449: 				for (u=0 ; u<pic->width ; u++) */
	movl	(%esi), %edi	 /* pic_135(D)->width, prephitmp_64 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:449: 				for (u=0 ; u<pic->width ; u++) */
	incl	%eax	 /* u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:449: 				for (u=0 ; u<pic->width ; u++) */
	cmpl	%edi, %eax	 /* prephitmp_64, u */
	jl	L194	 /* , */
L193:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:453: 				dest += vid.rowbytes; */
	addl	_vid+16, %ebp	 /* vid.rowbytes, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:454: 				source += pic->width; */
	addl	%edi, %ecx	 /* prephitmp_64, source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:447: 			for (v=0 ; v<pic->height ; v++) */
	incl	8(%esp)	 /* %sfp */
	movl	8(%esp), %eax	 /* %sfp, v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:447: 			for (v=0 ; v<pic->height ; v++) */
	cmpl	%eax, 4(%esi)	 /* v, pic_135(D)->height */
	jg	L190	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:506: } */
	addl	$28, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
	.p2align 4
	.p2align 3
L191:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:449: 				for (u=0 ; u<pic->width ; u++) */
	incl	%eax	 /* u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:449: 				for (u=0 ; u<pic->width ; u++) */
	cmpl	%edi, %eax	 /* prephitmp_64, u */
	jl	L194	 /* , */
	jmp	L193	 /*  */
	.p2align 4
	.p2align 3
L202:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:461: 				for (u=0 ; u<pic->width ; u+=8) */
	addl	$8, %ebp	 /* , u */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:461: 				for (u=0 ; u<pic->width ; u+=8) */
	movl	(%esi), %ecx	 /* pic_135(D)->width, prephitmp_64 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:461: 				for (u=0 ; u<pic->width ; u+=8) */
	addl	$8, %eax	 /* , ivtmp.244 */
	addl	$8, %edx	 /* , ivtmp.245 */
	cmpl	%ebp, %ecx	 /* u, prephitmp_64 */
	jg	L205	 /* , */
	jmp	L204	 /*  */
	.p2align 3
	.globl	_Draw_CharToConback
/* Draw_CharToConback: Stamp nonzero glyph pixels with the original wrapping 0x60 palette bias. */
_Draw_CharToConback:
	pushl	%ebx	 /*  */
	movl	8(%esp), %eax	 /* num, num */
	movl	12(%esp), %edx	 /* dest, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:516: 	row = num>>4; */
	movl	%eax, %ecx	 /* num, row */
	sarl	$4, %ecx	 /* , row */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:518: 	source = draw_chars + (row<<10) + (col<<3); */
	sall	$10, %ecx	 /* , tmp111 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:518: 	source = draw_chars + (row<<10) + (col<<3); */
	sall	$3, %eax	 /* , tmp112 */
	andl	$120, %eax	 /* , tmp113 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:518: 	source = draw_chars + (row<<10) + (col<<3); */
	addl	%ecx, %eax	 /* tmp111, tmp114 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:518: 	source = draw_chars + (row<<10) + (col<<3); */
	addl	_draw_chars, %eax	 /* draw_chars, source */
	leal	1024(%eax), %ebx	 /* , _95 */
	.p2align 3
	.p2align 3
L255:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	(%eax), %cl	 /* MEM[(byte *)source_17], _34 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _34 */
	je	L247	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp116 */
	movb	%cl, (%edx)	 /* tmp116, MEM[(byte *)dest_85] */
L247:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	1(%eax), %cl	 /* MEM[(byte *)source_17 + 1B], _44 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _44 */
	je	L248	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp117 */
	movb	%cl, 1(%edx)	 /* tmp117, MEM[(byte *)dest_85 + 1B] */
L248:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	2(%eax), %cl	 /* MEM[(byte *)source_17 + 2B], _54 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _54 */
	je	L249	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp118 */
	movb	%cl, 2(%edx)	 /* tmp118, MEM[(byte *)dest_85 + 2B] */
L249:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	3(%eax), %cl	 /* MEM[(byte *)source_17 + 3B], _64 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _64 */
	je	L250	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp119 */
	movb	%cl, 3(%edx)	 /* tmp119, MEM[(byte *)dest_85 + 3B] */
L250:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	4(%eax), %cl	 /* MEM[(byte *)source_17 + 4B], _74 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _74 */
	je	L251	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp120 */
	movb	%cl, 4(%edx)	 /* tmp120, MEM[(byte *)dest_85 + 4B] */
L251:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	5(%eax), %cl	 /* MEM[(byte *)source_17 + 5B], _84 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _84 */
	je	L252	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp121 */
	movb	%cl, 5(%edx)	 /* tmp121, MEM[(byte *)dest_85 + 5B] */
L252:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	6(%eax), %cl	 /* MEM[(byte *)source_17 + 6B], _94 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _94 */
	je	L253	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp122 */
	movb	%cl, 6(%edx)	 /* tmp122, MEM[(byte *)dest_85 + 6B] */
L253:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	7(%eax), %cl	 /* MEM[(byte *)source_17 + 7B], _104 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _104 */
	je	L254	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp123 */
	movb	%cl, 7(%edx)	 /* tmp123, MEM[(byte *)dest_85 + 7B] */
L254:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:527: 		source += 128; */
	subl	$-128, %eax	 /* , source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:528: 		dest += 320; */
	addl	$320, %edx	 /* , dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:522: 	while (drawline--) */
	cmpl	%ebx, %eax	 /* _95, source */
	jne	L255	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:531: } */
	popl	%ebx	 /*  */
	ret
.data
LC7:
	.ascii "gfx/conback.lmp\0"
LC9:
	.ascii "%s\0"
	.p2align 3
.text
	.globl	_Draw_ConsoleBackground
/* Draw_ConsoleBackground: Stamp the version and preserve integer vertical selection and 16.16 horizontal scaling. */
_Draw_ConsoleBackground:
	pushl	%ebp	 /*  */
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	subl	$168, %esp	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:548: 	conback = Draw_CachePic ("gfx/conback.lmp"); */
	pushl	$LC7	 /*  */
	call	_Draw_CachePic	 /*  */
	movl	%eax, %edi	 /* tmp398, conback */
 /* Copy the shared identity, preserving the outgoing stack layout. */
	pushl	$0
	pushl	$_nitroquake_version
	pushl	$LC9	 /*  */
	leal	72(%esp), %ebx	 /* , tmp385 */
	pushl	%ebx	 /* tmp385 */
	call	_sprintf	 /*  */
	leal	56637(%edi), %ebp	 /* right margin before text width */
	shll	$3, %eax	 /* sprintf returned the version length */
	subl	%eax, %ebp
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:554: 	for (x=0 ; x<strlen(ver) ; x++) */
	addl	$32, %esp	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:554: 	for (x=0 ; x<strlen(ver) ; x++) */
	movl	$0, 8(%esp)	 /* first identity line */
	xorl	%esi, %esi	 /* x */
	movl	%edi, 12(%esp)	 /* conback, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:554: 	for (x=0 ; x<strlen(ver) ; x++) */
	subl	$12, %esp	 /* , */
	pushl	%ebx	 /* tmp385 */
	call	_strlen	 /*  */
	addl	$16, %esp	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:554: 	for (x=0 ; x<strlen(ver) ; x++) */
	cmpl	%eax, %esi	 /* tmp399, x */
	jnb	L345	 /* , */
	.p2align 3
	.p2align 3
L293:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:555: 		Draw_CharToConback (ver[x], dest+(x<<3)); */
	movl	%ebp, %edx	 /* ivtmp.315, dest */
	movsbl	(%ebx,%esi), %eax	 /* MEM[(char *)&ver + _333 * 1], _5 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:516: 	row = num>>4; */
	movl	%eax, %edi	 /* _5, row */
	sarl	$4, %edi	 /* , row */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:518: 	source = draw_chars + (row<<10) + (col<<3); */
	sall	$10, %edi	 /* , tmp250 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:518: 	source = draw_chars + (row<<10) + (col<<3); */
	sall	$3, %eax	 /* , tmp251 */
	andl	$120, %eax	 /* , tmp252 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:518: 	source = draw_chars + (row<<10) + (col<<3); */
	addl	%edi, %eax	 /* tmp250, tmp253 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:518: 	source = draw_chars + (row<<10) + (col<<3); */
	addl	_draw_chars, %eax	 /* draw_chars, source */
	leal	1024(%eax), %edi	 /* , _338 */
	.p2align 3
	.p2align 3
L292:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	(%eax), %cl	 /* MEM[(byte *)source_191], _186 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _186 */
	je	L284	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp255 */
	movb	%cl, (%edx)	 /* tmp255, MEM[(byte *)dest_192] */
L284:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	1(%eax), %cl	 /* MEM[(byte *)source_191 + 1B], _196 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _196 */
	je	L285	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp256 */
	movb	%cl, 1(%edx)	 /* tmp256, MEM[(byte *)dest_192 + 1B] */
L285:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	2(%eax), %cl	 /* MEM[(byte *)source_191 + 2B], _206 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _206 */
	je	L286	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp257 */
	movb	%cl, 2(%edx)	 /* tmp257, MEM[(byte *)dest_192 + 2B] */
L286:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	3(%eax), %cl	 /* MEM[(byte *)source_191 + 3B], _216 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _216 */
	je	L287	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp258 */
	movb	%cl, 3(%edx)	 /* tmp258, MEM[(byte *)dest_192 + 3B] */
L287:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	4(%eax), %cl	 /* MEM[(byte *)source_191 + 4B], _226 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _226 */
	je	L288	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp259 */
	movb	%cl, 4(%edx)	 /* tmp259, MEM[(byte *)dest_192 + 4B] */
L288:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	5(%eax), %cl	 /* MEM[(byte *)source_191 + 5B], _236 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _236 */
	je	L289	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp260 */
	movb	%cl, 5(%edx)	 /* tmp260, MEM[(byte *)dest_192 + 5B] */
L289:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	6(%eax), %cl	 /* MEM[(byte *)source_191 + 6B], _246 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _246 */
	je	L290	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp261 */
	movb	%cl, 6(%edx)	 /* tmp261, MEM[(byte *)dest_192 + 6B] */
L290:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	movb	7(%eax), %cl	 /* MEM[(byte *)source_191 + 7B], _256 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:525: 			if (source[x]) */
	testb	%cl, %cl	 /* _256 */
	je	L291	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:526: 				dest[x] = 0x60 + source[x]; */
	addl	$96, %ecx	 /* , tmp262 */
	movb	%cl, 7(%edx)	 /* tmp262, MEM[(byte *)dest_192 + 7B] */
L291:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:527: 		source += 128; */
	subl	$-128, %eax	 /* , source */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:528: 		dest += 320; */
	addl	$320, %edx	 /* , dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:522: 	while (drawline--) */
	cmpl	%edi, %eax	 /* _338, source */
	jne	L292	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:554: 	for (x=0 ; x<strlen(ver) ; x++) */
	incl	%esi	 /* x */
	addl	$8, %ebp	 /* , ivtmp.315 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:554: 	for (x=0 ; x<strlen(ver) ; x++) */
	subl	$12, %esp	 /* , */
	pushl	%ebx	 /* tmp385 */
	call	_strlen	 /*  */
	addl	$16, %esp	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:554: 	for (x=0 ; x<strlen(ver) ; x++) */
	cmpl	%eax, %esi	 /* tmp399, x */
	jb	L293	 /* , */
L345:
	/* Reuse the glyph loop for the separately aligned build line. */
	cmpl	$0, 8(%esp)
	jne	.LConsoleIdentityDone
	movl	$1, 8(%esp)
	movl	12(%esp), %edi
	subl	$4, %esp
	pushl	$_nitroquake_build
	pushl	$LC9
	pushl	%ebx
	call	_sprintf
	addl	$16, %esp
	leal	59837(%edi), %ebp
	shll	$3, %eax
	subl	%eax, %ebp
	xorl	%esi, %esi
	jmp	L293
.LConsoleIdentityDone:

 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:560: 		dest = vid.conbuffer; */
	movl	12(%esp), %ecx	 /* %sfp, conback */
	movl	_vid+40, %ebp	 /* vid.conbuffer, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:558: 	if (r_pixbytes == 1) */
	cmpl	$1, _r_pixbytes	 /* , r_pixbytes */
	je	L346	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:590: 		for (y=0 ; y<lines ; y++, pusdest += (vid.conrowbytes >> 1)) */
	movl	176(%esp), %eax	 /* lines, */
	testl	%eax, %eax	 /*  */
	jle	L282	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:565: 			src = conback->data + v*320; */
	leal	8(%ecx), %edx	 /* , pretmp_350 */
	movl	%edx, 28(%esp)	 /* pretmp_350, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:597: 			fstep = 320*0x10000/vid.conwidth; */
	movl	_vid+48, %edi	 /* vid.conwidth, _95 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:590: 		for (y=0 ; y<lines ; y++, pusdest += (vid.conrowbytes >> 1)) */
	movl	$0, 24(%esp)	 /* , %sfp */
L307:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:594: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	movl	_vid+52, %esi	 /* vid.conheight, _48 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:594: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	movl	%esi, %ecx	 /* _48, tmp336 */
	subl	176(%esp), %ecx	 /* lines, tmp336 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:594: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	movl	24(%esp), %ebx	 /* %sfp, y */
	addl	%ebx, %ecx	 /* y, tmp337 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:594: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	leal	(%ecx,%ecx,4), %eax	 /* , tmp340 */
	leal	(%eax,%eax,4), %eax	 /* , tmp342 */
	sall	$3, %eax	 /* , tmp343 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:594: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	xorl	%edx, %edx	 /* tmp346 */
	divl	%esi	 /* _48 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:595: 			src = conback->data + v*320; */
	leal	(%eax,%eax,4), %ebx	 /* , tmp349 */
	sall	$6, %ebx	 /* , tmp350 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:595: 			src = conback->data + v*320; */
	movl	28(%esp), %esi	 /* %sfp, pretmp_350 */
	addl	%esi, %ebx	 /* pretmp_350, src */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:597: 			fstep = 320*0x10000/vid.conwidth; */
	movl	$20971520, %eax	 /* , tmp351 */
	xorl	%edx, %edx	 /* tmp352 */
	divl	%edi	 /* _95 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:598: 			for (x=0 ; x<vid.conwidth ; x+=4) */
	testl	%edi, %edi	 /* _95 */
	je	L282	 /* , */
	leal	0(,%eax,4), %edi	 /* , _292 */
	movl	%edi, 16(%esp)	 /* _292, %sfp */
	leal	(%eax,%eax), %ecx	 /* , ivtmp.299 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:596: 			f = 0; */
	xorl	%esi, %esi	 /* f */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:598: 			for (x=0 ; x<vid.conwidth ; x+=4) */
	xorl	%edx, %edx	 /* x */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:598: 			for (x=0 ; x<vid.conwidth ; x+=4) */
	leal	(%ecx,%eax), %edi	 /* , tmp375 */
	movl	%edi, 20(%esp)	 /* tmp375, %sfp */
	movl	%eax, 12(%esp)	 /* tmp351, %sfp */
	.p2align 3
	.p2align 3
L305:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:600: 				pusdest[x] = d_8to16table[src[f>>16]]; */
	movl	%esi, %eax	 /* f, tmp356 */
	sarl	$16, %eax	 /* , tmp356 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:600: 				pusdest[x] = d_8to16table[src[f>>16]]; */
	movb	(%ebx,%eax), %al	 /* *_62, *_62 */
	andl	$255, %eax	 /* , *_62 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:600: 				pusdest[x] = d_8to16table[src[f>>16]]; */
	movw	_d_8to16table(%eax,%eax), %di	 /* d_8to16table[_64], _67 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:600: 				pusdest[x] = d_8to16table[src[f>>16]]; */
	movw	%di, 0(%ebp,%edx,2)	 /* _67, MEM[(short unsigned int *)pusdest_182 + _289 * 2] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:601: 				f += fstep; */
	movl	12(%esp), %eax	 /* %sfp, tmp351 */
	leal	(%eax,%esi), %edi	 /* , f */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:602: 				pusdest[x+1] = d_8to16table[src[f>>16]]; */
	sarl	$16, %edi	 /* , tmp361 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:602: 				pusdest[x+1] = d_8to16table[src[f>>16]]; */
	movb	(%ebx,%edi), %al	 /* *_70, *_70 */
	andl	$255, %eax	 /* , *_70 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:602: 				pusdest[x+1] = d_8to16table[src[f>>16]]; */
	movw	_d_8to16table(%eax,%eax), %di	 /* d_8to16table[_72], _76 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:602: 				pusdest[x+1] = d_8to16table[src[f>>16]]; */
	movw	%di, 2(%ebp,%edx,2)	 /* _76, MEM[(short unsigned int *)pusdest_182 + 2B + _289 * 2] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:604: 				pusdest[x+2] = d_8to16table[src[f>>16]]; */
	movl	%ecx, %eax	 /* ivtmp.299, tmp365 */
	sarl	$16, %eax	 /* , tmp365 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:604: 				pusdest[x+2] = d_8to16table[src[f>>16]]; */
	movb	(%ebx,%eax), %al	 /* *_79, *_79 */
	andl	$255, %eax	 /* , *_79 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:604: 				pusdest[x+2] = d_8to16table[src[f>>16]]; */
	movw	_d_8to16table(%eax,%eax), %di	 /* d_8to16table[_81], _85 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:604: 				pusdest[x+2] = d_8to16table[src[f>>16]]; */
	movw	%di, 4(%ebp,%edx,2)	 /* _85, MEM[(short unsigned int *)pusdest_182 + 4B + _289 * 2] */
	movl	12(%esp), %eax	 /* %sfp, tmp351 */
	addl	%eax, %ecx	 /* tmp351, _346 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:606: 				pusdest[x+3] = d_8to16table[src[f>>16]]; */
	movl	%ecx, %edi	 /* _346, tmp369 */
	sarl	$16, %edi	 /* , tmp369 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:606: 				pusdest[x+3] = d_8to16table[src[f>>16]]; */
	movb	(%ebx,%edi), %al	 /* *_88, *_88 */
	andl	$255, %eax	 /* , *_88 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:606: 				pusdest[x+3] = d_8to16table[src[f>>16]]; */
	movw	_d_8to16table(%eax,%eax), %di	 /* d_8to16table[_90], _94 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:606: 				pusdest[x+3] = d_8to16table[src[f>>16]]; */
	movw	%di, 6(%ebp,%edx,2)	 /* _94, MEM[(short unsigned int *)pusdest_182 + 6B + _289 * 2] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:607: 				f += fstep; */
	movl	16(%esp), %eax	 /* %sfp, _292 */
	addl	%eax, %esi	 /* _292, f */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:598: 			for (x=0 ; x<vid.conwidth ; x+=4) */
	addl	$4, %edx	 /* , x */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:598: 			for (x=0 ; x<vid.conwidth ; x+=4) */
	movl	_vid+48, %edi	 /* vid.conwidth, _95 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:598: 			for (x=0 ; x<vid.conwidth ; x+=4) */
	movl	20(%esp), %eax	 /* %sfp, tmp375 */
	addl	%eax, %ecx	 /* tmp375, ivtmp.299 */
	cmpl	%edi, %edx	 /* _95, x */
	jb	L305	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:590: 		for (y=0 ; y<lines ; y++, pusdest += (vid.conrowbytes >> 1)) */
	incl	24(%esp)	 /* %sfp */
	movl	24(%esp), %ebx	 /* %sfp, y */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:590: 		for (y=0 ; y<lines ; y++, pusdest += (vid.conrowbytes >> 1)) */
	movl	_vid+44, %ecx	 /* vid.conrowbytes, tmp383 */
	andl	$-2, %ecx	 /* , tmp383 */
	addl	%ecx, %ebp	 /* tmp383, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:590: 		for (y=0 ; y<lines ; y++, pusdest += (vid.conrowbytes >> 1)) */
	cmpl	%ebx, 176(%esp)	 /* y, lines */
	jne	L307	 /* , */
L282:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:611: } */
	addl	$156, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
L346:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	movl	176(%esp), %esi	 /* lines, */
	testl	%esi, %esi	 /*  */
	jle	L282	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:565: 			src = conback->data + v*320; */
	leal	8(%ecx), %edx	 /* , pretmp_394 */
	movl	%edx, 28(%esp)	 /* pretmp_394, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:597: 			fstep = 320*0x10000/vid.conwidth; */
	movl	_vid+48, %esi	 /* vid.conwidth, prephitmp_371 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	movl	$0, 24(%esp)	 /* , %sfp */
	movl	_vid+52, %ecx	 /* vid.conheight, _9 */
L304:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:564: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	movl	%ecx, %edi	 /* _9, tmp270 */
	subl	176(%esp), %edi	 /* lines, tmp270 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:564: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	movl	24(%esp), %ebx	 /* %sfp, y */
	addl	%ebx, %edi	 /* y, tmp271 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:564: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	leal	(%edi,%edi,4), %eax	 /* , tmp274 */
	leal	(%eax,%eax,4), %eax	 /* , tmp276 */
	sall	$3, %eax	 /* , tmp277 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:564: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	xorl	%edx, %edx	 /* tmp280 */
	divl	%ecx	 /* _9 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:565: 			src = conback->data + v*320; */
	leal	(%eax,%eax,4), %edi	 /* , tmp283 */
	sall	$6, %edi	 /* , tmp284 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:565: 			src = conback->data + v*320; */
	movl	28(%esp), %eax	 /* %sfp, pretmp_394 */
	addl	%eax, %edi	 /* pretmp_394, src */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:566: 			if (vid.conwidth == 320) */
	cmpl	$320, %esi	 /* , prephitmp_371 */
	je	L347	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:571: 				fstep = 320*0x10000/vid.conwidth; */
	movl	$20971520, %eax	 /* , tmp293 */
	xorl	%edx, %edx	 /* tmp294 */
	divl	%esi	 /* prephitmp_371 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:572: 				for (x=0 ; x<vid.conwidth ; x+=4) */
	testl	%esi, %esi	 /* prephitmp_371 */
	je	L299	 /* , */
	leal	0(,%eax,4), %ecx	 /* , _287 */
	movl	%ecx, 16(%esp)	 /* _287, %sfp */
	leal	(%eax,%eax), %ecx	 /* , ivtmp.288 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:570: 				f = 0; */
	xorl	%ebx, %ebx	 /* f */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:572: 				for (x=0 ; x<vid.conwidth ; x+=4) */
	xorl	%edx, %edx	 /* x */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:572: 				for (x=0 ; x<vid.conwidth ; x+=4) */
	leal	(%ecx,%eax), %esi	 /* , tmp305 */
	movl	%esi, 20(%esp)	 /* tmp305, %sfp */
	movl	%eax, 12(%esp)	 /* tmp293, %sfp */
	.p2align 3
	.p2align 3
L300:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:574: 					dest[x] = src[f>>16]; */
	movl	%ebx, %eax	 /* f, tmp297 */
	sarl	$16, %eax	 /* , tmp297 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:574: 					dest[x] = src[f>>16]; */
	movb	(%edi,%eax), %al	 /* *_23, tmp454 */
	movb	%al, 0(%ebp,%edx)	 /* tmp454, MEM[(byte *)dest_173 + _369 * 1] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:575: 					f += fstep; */
	movl	12(%esp), %esi	 /* %sfp, tmp293 */
	leal	(%esi,%ebx), %eax	 /* , f */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:576: 					dest[x+1] = src[f>>16]; */
	sarl	$16, %eax	 /* , tmp299 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:576: 					dest[x+1] = src[f>>16]; */
	movb	(%edi,%eax), %al	 /* *_28, tmp455 */
	movb	%al, 1(%ebp,%edx)	 /* tmp455, MEM[(byte *)dest_173 + 1B + _369 * 1] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:578: 					dest[x+2] = src[f>>16]; */
	movl	%ecx, %esi	 /* ivtmp.288, tmp300 */
	sarl	$16, %esi	 /* , tmp300 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:578: 					dest[x+2] = src[f>>16]; */
	movb	(%edi,%esi), %al	 /* *_34, tmp457 */
	movb	%al, 2(%ebp,%edx)	 /* tmp457, MEM[(byte *)dest_173 + 2B + _369 * 1] */
	movl	12(%esp), %esi	 /* %sfp, tmp293 */
	addl	%esi, %ecx	 /* tmp293, _358 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:580: 					dest[x+3] = src[f>>16]; */
	movl	%ecx, %eax	 /* _358, tmp301 */
	sarl	$16, %eax	 /* , tmp301 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:580: 					dest[x+3] = src[f>>16]; */
	movb	(%edi,%eax), %al	 /* *_40, tmp459 */
	movb	%al, 3(%ebp,%edx)	 /* tmp459, MEM[(byte *)dest_173 + 3B + _369 * 1] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:581: 					f += fstep; */
	movl	16(%esp), %esi	 /* %sfp, _287 */
	addl	%esi, %ebx	 /* _287, f */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:572: 				for (x=0 ; x<vid.conwidth ; x+=4) */
	addl	$4, %edx	 /* , x */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:572: 				for (x=0 ; x<vid.conwidth ; x+=4) */
	movl	_vid+48, %esi	 /* vid.conwidth, prephitmp_371 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:572: 				for (x=0 ; x<vid.conwidth ; x+=4) */
	movl	20(%esp), %eax	 /* %sfp, tmp305 */
	addl	%eax, %ecx	 /* tmp305, ivtmp.288 */
	cmpl	%esi, %edx	 /* prephitmp_371, x */
	jb	L300	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	incl	24(%esp)	 /* %sfp */
	movl	24(%esp), %edi	 /* %sfp, y */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	cmpl	%edi, 176(%esp)	 /* y, lines */
	je	L282	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	addl	_vid+44, %ebp	 /* vid.conrowbytes, pusdest */
	movl	_vid+52, %ecx	 /* vid.conheight, _9 */
	jmp	L304	 /*  */
L347:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:567: 				memcpy (dest, src, vid.conwidth); */
	movl	(%edi), %edx	 /* * src, tmp288 */
	movl	%edx, 0(%ebp)	 /* tmp288,* pusdest */
	movl	316(%edi), %esi	 /* , tmp289 */
	movl	%esi, 316(%ebp)	 /* tmp289, */
	leal	4(%ebp), %edx	 /* , tmp290 */
	andl	$-4, %edx	 /* , tmp290 */
	movl	%ebp, %ecx	 /* pusdest, pusdest */
	subl	%edx, %ecx	 /* tmp290, pusdest */
	movl	%edi, %esi	 /* src, src */
	subl	%ecx, %esi	 /* pusdest, src */
	addl	$320, %ecx	 /* , tmp287 */
	shrl	$2, %ecx	 /* , tmp287 */
	movl	%edx, %edi	 /* tmp290, tmp290 */
	rep movsl
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	movl	%ebx, %eax	 /* y, y */
	incl	%eax	 /* y */
	movl	%eax, 12(%esp)	 /* y, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	movl	_vid+44, %ebx	 /* vid.conrowbytes, _47 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	addl	%ebx, %ebp	 /* _47, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	cmpl	%eax, 176(%esp)	 /* y, lines */
	je	L282	 /* , */
L297:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:564: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	movl	_vid+52, %ecx	 /* vid.conheight, _434 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:564: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	movl	%ecx, %edx	 /* _434, tmp311 */
	subl	176(%esp), %edx	 /* lines, tmp311 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:564: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	movl	12(%esp), %esi	 /* %sfp, y */
	addl	%esi, %edx	 /* y, tmp312 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:564: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	leal	(%edx,%edx,4), %edi	 /* , tmp315 */
	leal	(%edi,%edi,4), %eax	 /* , tmp317 */
	sall	$3, %eax	 /* , tmp318 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:564: 			v = (vid.conheight - lines + y)*200/vid.conheight; */
	xorl	%edx, %edx	 /* tmp321 */
	divl	%ecx	 /* _434 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:565: 			src = conback->data + v*320; */
	leal	(%eax,%eax,4), %esi	 /* , tmp324 */
	sall	$6, %esi	 /* , tmp325 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:565: 			src = conback->data + v*320; */
	movl	28(%esp), %ecx	 /* %sfp, pretmp_394 */
	addl	%ecx, %esi	 /* pretmp_394, src */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:567: 				memcpy (dest, src, vid.conwidth); */
	movl	(%esi), %edi	 /* * src, tmp330 */
	movl	%edi, 0(%ebp)	 /* tmp330,* dest */
	movl	316(%esi), %eax	 /* , tmp331 */
	movl	%eax, 316(%ebp)	 /* tmp331, */
	leal	4(%ebp), %edi	 /* , tmp332 */
	andl	$-4, %edi	 /* , tmp332 */
	movl	%ebp, %ecx	 /* dest, dest */
	subl	%edi, %ecx	 /* tmp332, dest */
	subl	%ecx, %esi	 /* dest, src */
	addl	$320, %ecx	 /* , tmp329 */
	shrl	$2, %ecx	 /* , tmp329 */
	rep movsl
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	incl	12(%esp)	 /* %sfp */
	movl	12(%esp), %edx	 /* %sfp, y */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	addl	%ebx, %ebp	 /* _47, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	cmpl	%edx, 176(%esp)	 /* y, lines */
	jg	L297	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:611: } */
	addl	$156, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
L299:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	incl	24(%esp)	 /* %sfp */
	movl	24(%esp), %ebx	 /* %sfp, y */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	addl	_vid+44, %ebp	 /* vid.conrowbytes, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:562: 		for (y=0 ; y<lines ; y++, dest += vid.conrowbytes) */
	cmpl	%ebx, 176(%esp)	 /* y, lines */
	jne	L304	 /* , */
	jmp	L282	 /*  */
	.p2align 3
	.globl	_R_DrawRect8
/* R_DrawRect8: Copy rectangle rows with optional index-255 transparency and independent source/destination strides. */
_R_DrawRect8:
	pushl	%ebp	 /*  */
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	subl	$8, %esp	 /* , */
	movl	28(%esp), %ebp	 /* prect, prect */
	movl	36(%esp), %eax	 /* psrc, psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:626: 	pdest = vid.buffer + (prect->y * vid.rowbytes) + prect->x; */
	movl	_vid+16, %ebx	 /* vid.rowbytes, vid.rowbytes */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:626: 	pdest = vid.buffer + (prect->y * vid.rowbytes) + prect->x; */
	movl	4(%ebp), %edx	 /* prect_37(D)->y, tmp111 */
	imull	%ebx, %edx	 /* vid.rowbytes, tmp111 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:626: 	pdest = vid.buffer + (prect->y * vid.rowbytes) + prect->x; */
	addl	0(%ebp), %edx	 /* prect_37(D)->x, tmp112 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:626: 	pdest = vid.buffer + (prect->y * vid.rowbytes) + prect->x; */
	addl	_vid, %edx	 /* vid.buffer, pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:628: 	srcdelta = rowbytes - prect->width; */
	movl	8(%ebp), %ecx	 /* prect_37(D)->width, prephitmp_28 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:653: 		for (i=0 ; i<prect->height ; i++) */
	movl	12(%ebp), %esi	 /* prect_37(D)->height, pretmp_10 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:631: 	if (transparent) */
	movl	40(%esp), %edi	 /* transparent, */
	testl	%edi, %edi	 /*  */
	jne	L349	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:653: 		for (i=0 ; i<prect->height ; i++) */
	testl	%esi, %esi	 /* pretmp_10 */
	jg	L360	 /* , */
L348:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:660: } */
	addl	$8, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
	.p2align 4
	.p2align 3
L373:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:655: 			memcpy (pdest, psrc, prect->width); */
	testl	%ecx, %ecx	 /* prephitmp_28 */
	je	L358	 /* , */
	movb	(%eax), %bl	 /* * psrc, tmp153 */
	movb	%bl, (%edx)	 /* tmp153,* pdest */
	testb	$2, %cl	 /* , prephitmp_28 */
	jne	L368	 /* , */
L371:
	movl	_vid+16, %ebx	 /* vid.rowbytes, vid.rowbytes */
L358:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:656: 			psrc += rowbytes; */
	addl	32(%esp), %eax	 /* rowbytes, psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:657: 			pdest += vid.rowbytes; */
	addl	%ebx, %edx	 /* vid.rowbytes, pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:653: 		for (i=0 ; i<prect->height ; i++) */
	incl	40(%esp)	 /* transparent */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:653: 		for (i=0 ; i<prect->height ; i++) */
	movl	40(%esp), %ecx	 /* transparent, tmp161 */
	cmpl	%ecx, 12(%ebp)	 /* tmp161, prect_37(D)->height */
	jle	L348	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:655: 			memcpy (pdest, psrc, prect->width); */
	movl	8(%ebp), %ecx	 /* prect_37(D)->width, prephitmp_28 */
L360:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:655: 			memcpy (pdest, psrc, prect->width); */
	cmpl	$4, %ecx	 /* , prephitmp_28 */
	jb	L373	 /* , */
	movl	(%eax), %edi	 /* * psrc, tmp121 */
	movl	%edi, (%edx)	 /* tmp121,* pdest */
	movl	-4(%eax,%ecx), %ebx	 /* , tmp122 */
	movl	%ebx, -4(%edx,%ecx)	 /* tmp122, */
	leal	4(%edx), %edi	 /* , tmp123 */
	andl	$-4, %edi	 /* , tmp123 */
	movl	%edx, %ebx	 /* pdest, pdest */
	subl	%edi, %ebx	 /* tmp123, pdest */
	movl	%eax, %esi	 /* psrc, psrc */
	subl	%ebx, %esi	 /* pdest, psrc */
	addl	%ebx, %ecx	 /* pdest, prephitmp_28 */
	shrl	$2, %ecx	 /* , tmp124 */
	rep movsl
	jmp	L371	 /*  */
	.p2align 4
	.p2align 3
L349:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:633: 		for (i=0 ; i<prect->height ; i++) */
	testl	%esi, %esi	 /* pretmp_10 */
	jle	L348	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:629: 	destdelta = vid.rowbytes - prect->width; */
	subl	%ecx, %ebx	 /* prephitmp_28, vid.rowbytes */
	movl	%ebx, (%esp)	 /* vid.rowbytes, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:628: 	srcdelta = rowbytes - prect->width; */
	movl	32(%esp), %edi	 /* rowbytes, _24 */
	subl	%ecx, %edi	 /* prephitmp_28, _24 */
	movl	%edi, 4(%esp)	 /* _24, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:633: 		for (i=0 ; i<prect->height ; i++) */
	xorl	%edi, %edi	 /* i */
	movl	%ecx, %esi	 /* prephitmp_28, prephitmp_28 */
	.p2align 3
	.p2align 3
L352:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:635: 			for (j=0 ; j<prect->width ; j++) */
	testl	%esi, %esi	 /* prephitmp_28 */
	jle	L348	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:635: 			for (j=0 ; j<prect->width ; j++) */
	xorl	%ebx, %ebx	 /* j */
	.p2align 3
	.p2align 3
L356:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:637: 				t = *psrc; */
	movb	(%eax), %cl	 /* MEM[(byte *)psrc_68], t */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:638: 				if (t != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , t */
	je	L353	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:640: 					*pdest = t; */
	movb	%cl, (%edx)	 /* t, MEM[(byte *)pdest_75] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:635: 			for (j=0 ; j<prect->width ; j++) */
	movl	8(%ebp), %esi	 /* prect_37(D)->width, prephitmp_28 */
L353:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:643: 				psrc++; */
	incl	%eax	 /* psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:644: 				pdest++; */
	incl	%edx	 /* pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:635: 			for (j=0 ; j<prect->width ; j++) */
	incl	%ebx	 /* j */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:635: 			for (j=0 ; j<prect->width ; j++) */
	cmpl	%ebx, %esi	 /* j, prephitmp_28 */
	jg	L356	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:647: 			psrc += srcdelta; */
	movl	4(%esp), %ebx	 /* %sfp, _24 */
	addl	%ebx, %eax	 /* _24, psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:648: 			pdest += destdelta; */
	movl	(%esp), %ecx	 /* %sfp, _13 */
	addl	%ecx, %edx	 /* _13, pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:633: 		for (i=0 ; i<prect->height ; i++) */
	incl	%edi	 /* i */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:633: 		for (i=0 ; i<prect->height ; i++) */
	cmpl	%edi, 12(%ebp)	 /* i, prect_37(D)->height */
	jg	L352	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:660: } */
	addl	$8, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
L368:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:655: 			memcpy (pdest, psrc, prect->width); */
	movw	-2(%eax,%ecx), %si	 /* , tmp120 */
	movw	%si, -2(%edx,%ecx)	 /* tmp120, */
	movl	_vid+16, %ebx	 /* vid.rowbytes, vid.rowbytes */
	jmp	L358	 /*  */
	.p2align 3
	.globl	_R_DrawRect16
/* R_DrawRect16: Translate rectangle indices with the original half-byte-stride truncation. */
_R_DrawRect16:
	pushl	%ebp	 /*  */
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	subl	$8, %esp	 /* , */
	movl	28(%esp), %edi	 /* prect, prect */
	movl	36(%esp), %eax	 /* psrc, psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:678: 			(prect->y * (vid.rowbytes >> 1)) + prect->x; */
	movl	_vid+16, %esi	 /* vid.rowbytes, _5 */
	shrl	$1, %esi	 /* , _5 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:678: 			(prect->y * (vid.rowbytes >> 1)) + prect->x; */
	movl	4(%edi), %edx	 /* prect_49(D)->y, tmp121 */
	imull	%esi, %edx	 /* _5, tmp121 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:678: 			(prect->y * (vid.rowbytes >> 1)) + prect->x; */
	addl	(%edi), %edx	 /* prect_49(D)->x, tmp122 */
	addl	%edx, %edx	 /* tmp122, tmp124 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:677: 	pdest = (unsigned short *)vid.buffer + */
	addl	_vid, %edx	 /* vid.buffer, pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:680: 	srcdelta = rowbytes - prect->width; */
	movl	8(%edi), %ebx	 /* prect_49(D)->width, prephitmp_109 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:680: 	srcdelta = rowbytes - prect->width; */
	movl	32(%esp), %ecx	 /* rowbytes, srcdelta */
	subl	%ebx, %ecx	 /* prephitmp_109, srcdelta */
	movl	%ecx, (%esp)	 /* srcdelta, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:681: 	destdelta = (vid.rowbytes >> 1) - prect->width; */
	subl	%ebx, %esi	 /* prephitmp_109, _16 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:705: 		for (i=0 ; i<prect->height ; i++) */
	movl	12(%edi), %ecx	 /* prect_49(D)->height, pretmp_115 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:683: 	if (transparent) */
	movl	40(%esp), %ebp	 /* transparent, */
	testl	%ebp, %ebp	 /*  */
	jne	L375	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:705: 		for (i=0 ; i<prect->height ; i++) */
	testl	%ecx, %ecx	 /* pretmp_115 */
	jle	L374	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:715: 			pdest += destdelta; */
	addl	%esi, %esi	 /* _16, tmp126 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:705: 		for (i=0 ; i<prect->height ; i++) */
	xorl	%ebp, %ebp	 /* i */
	.p2align 3
	.p2align 3
L377:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:707: 			for (j=0 ; j<prect->width ; j++) */
	testl	%ebx, %ebx	 /* prephitmp_109 */
	jle	L374	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:707: 			for (j=0 ; j<prect->width ; j++) */
	xorl	%ecx, %ecx	 /* j */
	.p2align 3
	.p2align 3
L383:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:709: 				*pdest = d_8to16table[*psrc]; */
	xorl	%ebx, %ebx	 /* MEM[(byte *)psrc_90] */
	movb	(%eax), %bl	 /* MEM[(byte *)psrc_90], MEM[(byte *)psrc_90] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:709: 				*pdest = d_8to16table[*psrc]; */
	movw	_d_8to16table(%ebx,%ebx), %bx	 /* d_8to16table[_24], _25 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:709: 				*pdest = d_8to16table[*psrc]; */
	movw	%bx, (%edx)	 /* _25, MEM[(short unsigned int *)pdest_100] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:710: 				psrc++; */
	incl	%eax	 /* psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:711: 				pdest++; */
	addl	$2, %edx	 /* , pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:707: 			for (j=0 ; j<prect->width ; j++) */
	incl	%ecx	 /* j */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:707: 			for (j=0 ; j<prect->width ; j++) */
	movl	8(%edi), %ebx	 /* prect_49(D)->width, prephitmp_109 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:707: 			for (j=0 ; j<prect->width ; j++) */
	cmpl	%ecx, %ebx	 /* j, prephitmp_109 */
	jg	L383	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:714: 			psrc += srcdelta; */
	movl	(%esp), %ecx	 /* %sfp, srcdelta */
	addl	%ecx, %eax	 /* srcdelta, psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:715: 			pdest += destdelta; */
	addl	%esi, %edx	 /* tmp126, pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:705: 		for (i=0 ; i<prect->height ; i++) */
	incl	%ebp	 /* i */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:705: 		for (i=0 ; i<prect->height ; i++) */
	cmpl	%ebp, 12(%edi)	 /* i, prect_49(D)->height */
	jg	L377	 /* , */
L374:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:718: } */
	addl	$8, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
	.p2align 4
	.p2align 3
L375:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:685: 		for (i=0 ; i<prect->height ; i++) */
	testl	%ecx, %ecx	 /* pretmp_115 */
	jle	L374	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:700: 			pdest += destdelta; */
	addl	%esi, %esi	 /* _16, tmp127 */
	movl	%esi, 4(%esp)	 /* tmp127, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:685: 		for (i=0 ; i<prect->height ; i++) */
	xorl	%ebp, %ebp	 /* i */
	.p2align 3
	.p2align 3
L378:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:687: 			for (j=0 ; j<prect->width ; j++) */
	testl	%ebx, %ebx	 /* prephitmp_109 */
	jle	L374	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:687: 			for (j=0 ; j<prect->width ; j++) */
	xorl	%esi, %esi	 /* j */
	.p2align 3
	.p2align 3
L382:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:689: 				t = *psrc; */
	movb	(%eax), %cl	 /* MEM[(byte *)psrc_87], t */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:690: 				if (t != TRANSPARENT_COLOR) */
	cmpb	$-1, %cl	 /* , t */
	je	L379	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:692: 					*pdest = d_8to16table[t]; */
	andl	$255, %ecx	 /* , t */
	movw	_d_8to16table(%ecx,%ecx), %bx	 /* d_8to16table[_17], _18 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:692: 					*pdest = d_8to16table[t]; */
	movw	%bx, (%edx)	 /* _18, MEM[(short unsigned int *)pdest_97] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:687: 			for (j=0 ; j<prect->width ; j++) */
	movl	8(%edi), %ebx	 /* prect_49(D)->width, prephitmp_109 */
L379:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:695: 				psrc++; */
	incl	%eax	 /* psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:696: 				pdest++; */
	addl	$2, %edx	 /* , pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:687: 			for (j=0 ; j<prect->width ; j++) */
	incl	%esi	 /* j */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:687: 			for (j=0 ; j<prect->width ; j++) */
	cmpl	%ebx, %esi	 /* prephitmp_109, j */
	jl	L382	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:699: 			psrc += srcdelta; */
	movl	(%esp), %esi	 /* %sfp, srcdelta */
	addl	%esi, %eax	 /* srcdelta, psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:700: 			pdest += destdelta; */
	movl	4(%esp), %ecx	 /* %sfp, tmp127 */
	addl	%ecx, %edx	 /* tmp127, pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:685: 		for (i=0 ; i<prect->height ; i++) */
	incl	%ebp	 /* i */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:685: 		for (i=0 ; i<prect->height ; i++) */
	cmpl	%ebp, 12(%edi)	 /* i, prect_49(D)->height */
	jg	L378	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:718: } */
	addl	$8, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
	.p2align 3
	.globl	_Draw_TileClear
/* Draw_TileClear: Preserve partial first tiles, tile wrapping and clipped final rectangles. */
_Draw_TileClear:
	pushl	%ebp	 /*  */
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	subl	$44, %esp	 /* , */
	movl	76(%esp), %ebx	 /* h, h */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:735: 	r_rectdesc.rect.x = x; */
	movl	64(%esp), %eax	 /* x, tmp216 */
	movl	%eax, _r_rectdesc	 /* tmp216, r_rectdesc.rect.x */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:736: 	r_rectdesc.rect.y = y; */
	movl	68(%esp), %edx	 /* y, tmp217 */
	movl	%edx, _r_rectdesc+4	 /* tmp217, r_rectdesc.rect.y */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:737: 	r_rectdesc.rect.width = w; */
	movl	72(%esp), %ecx	 /* w, tmp218 */
	movl	%ecx, _r_rectdesc+8	 /* tmp218, r_rectdesc.rect.width */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:738: 	r_rectdesc.rect.height = h; */
	movl	%ebx, _r_rectdesc+12	 /* h, r_rectdesc.rect.height */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:743: 	tileoffsety = vr.y % r_rectdesc.height; */
	movl	_r_rectdesc+24, %esi	 /* r_rectdesc.height, _1 */
	movl	%esi, 36(%esp)	 /* _1, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:743: 	tileoffsety = vr.y % r_rectdesc.height; */
	movl	68(%esp), %eax	 /* y, tmp142 */
	cltd
	idivl	%esi	 /* _1 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:745: 	while (height > 0) */
	testl	%ebx, %ebx	 /* h */
	jle	L389	 /* , */
	movl	%edx, %ecx	 /* tileoffsety, tileoffsety */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:758: 		tileoffsetx = vr.x % r_rectdesc.width; */
	movl	_r_rectdesc+20, %ebp	 /* r_rectdesc.width, pretmp_23 */
	movl	%ebp, 28(%esp)	 /* pretmp_23, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:758: 		tileoffsetx = vr.x % r_rectdesc.width; */
	movl	64(%esp), %eax	 /* x, tmp145 */
	cltd
	idivl	%ebp	 /* pretmp_23 */
	movl	72(%esp), %esi	 /* w, */
	testl	%esi, %esi	 /*  */
	jle	L389	 /* , */
	movl	%edx, 40(%esp)	 /* tmp144, %sfp */
L406:
	movl	36(%esp), %edi	 /* %sfp, _35 */
	subl	%ecx, %edi	 /* tileoffsety, _35 */
	movl	%edi, (%esp)	 /* _35, %sfp */
	cmpl	%ebx, %edi	 /* h, _35 */
	jle	L392	 /* , */
	movl	%ebx, (%esp)	 /* h, %sfp */
L392:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:770: 			psrc = r_rectdesc.ptexbytes + */
	movl	_r_rectdesc+28, %ebp	 /* r_rectdesc.ptexbytes, pretmp_62 */
	movl	%ebp, 24(%esp)	 /* pretmp_62, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:771: 					(tileoffsety * r_rectdesc.rowbytes) + tileoffsetx; */
	movl	_r_rectdesc+32, %eax	 /* r_rectdesc.rowbytes, pretmp_139 */
	movl	%eax, 4(%esp)	 /* pretmp_139, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:771: 					(tileoffsety * r_rectdesc.rowbytes) + tileoffsetx; */
	imull	%eax, %ecx	 /* pretmp_139, tileoffsety */
	movl	%ecx, 20(%esp)	 /* tileoffsety, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:747: 		vr.x = r_rectdesc.rect.x; */
	movl	64(%esp), %ecx	 /* x, vr$x */
	movl	%ecx, 16(%esp)	 /* vr$x, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:758: 		tileoffsetx = vr.x % r_rectdesc.width; */
	movl	40(%esp), %ebp	 /* %sfp, tileoffsetx */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:748: 		width = r_rectdesc.rect.width; */
	movl	72(%esp), %edx	 /* w, width */
	movl	%edx, 12(%esp)	 /* width, %sfp */
	movl	_vid, %esi	 /* vid.buffer, pretmp_29 */
	movl	_vid+16, %ecx	 /* vid.rowbytes, vid.rowbytes */
	movl	%ebx, 76(%esp)	 /* h, h */
	.p2align 3
	.p2align 3
L393:
	movl	28(%esp), %edx	 /* %sfp, _149 */
	subl	%ebp, %edx	 /* tileoffsetx, _149 */
	movl	12(%esp), %ebx	 /* %sfp, width */
	cmpl	%ebx, %edx	 /* width, _149 */
	jle	L395	 /* , */
	movl	%ebx, %edx	 /* width, _149 */
L395:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:771: 					(tileoffsety * r_rectdesc.rowbytes) + tileoffsetx; */
	movl	20(%esp), %edi	 /* %sfp, _48 */
	addl	%edi, %ebp	 /* _48, tmp150 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:770: 			psrc = r_rectdesc.ptexbytes + */
	movl	24(%esp), %eax	 /* %sfp, pretmp_62 */
	addl	%eax, %ebp	 /* pretmp_62, psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:773: 			if (r_pixbytes == 1) */
	cmpl	$1, _r_pixbytes	 /* , r_pixbytes */
	je	L421	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:678: 			(prect->y * (vid.rowbytes >> 1)) + prect->x; */
	movl	%ecx, %ebx	 /* vid.rowbytes, _110 */
	shrl	$1, %ebx	 /* , _110 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:678: 			(prect->y * (vid.rowbytes >> 1)) + prect->x; */
	movl	68(%esp), %eax	 /* y, tmp169 */
	imull	%ebx, %eax	 /* _110, tmp169 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:678: 			(prect->y * (vid.rowbytes >> 1)) + prect->x; */
	movl	16(%esp), %edi	 /* %sfp, vr$x */
	addl	%edi, %eax	 /* vr$x, tmp170 */
	addl	%eax, %eax	 /* tmp170, tmp171 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:705: 		for (i=0 ; i<prect->height ; i++) */
	movl	(%esp), %edi	 /* %sfp, */
	testl	%edi, %edi	 /*  */
	jle	L397	 /* , */
	testl	%edx, %edx	 /* _149 */
	jle	L422	 /* , */
	leal	(%edx,%edx), %edi	 /* , tmp172 */
	addl	%ebx, %ebx	 /* _110, tmp173 */
	movl	%ebx, 8(%esp)	 /* tmp173, %sfp */
	addl	%edi, %eax	 /* tmp172, tmp174 */
	leal	(%esi,%eax), %ebx	 /* , ivtmp.400 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:705: 		for (i=0 ; i<prect->height ; i++) */
	xorl	%esi, %esi	 /* i */
	movl	%edx, 32(%esp)	 /* _149, %sfp */
	.p2align 3
	.p2align 3
L404:
	movl	%ebx, %eax	 /* ivtmp.400, pdest */
	subl	%edi, %eax	 /* tmp172, pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:653: 		for (i=0 ; i<prect->height ; i++) */
	movl	%ebp, %edx	 /* psrc, psrc */
	.p2align 3
	.p2align 3
L405:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:709: 				*pdest = d_8to16table[*psrc]; */
	xorl	%ecx, %ecx	 /* MEM[(byte *)psrc_123] */
	movb	(%edx), %cl	 /* MEM[(byte *)psrc_123], MEM[(byte *)psrc_123] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:709: 				*pdest = d_8to16table[*psrc]; */
	movw	_d_8to16table(%ecx,%ecx), %cx	 /* d_8to16table[_142], _143 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:709: 				*pdest = d_8to16table[*psrc]; */
	movw	%cx, (%eax)	 /* _143, MEM[(short unsigned int *)pdest_122] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:710: 				psrc++; */
	incl	%edx	 /* psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:711: 				pdest++; */
	addl	$2, %eax	 /* , pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:707: 			for (j=0 ; j<prect->width ; j++) */
	cmpl	%ebx, %eax	 /* ivtmp.400, pdest */
	jne	L405	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:714: 			psrc += srcdelta; */
	movl	4(%esp), %eax	 /* %sfp, pretmp_139 */
	addl	%eax, %ebp	 /* pretmp_139, psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:705: 		for (i=0 ; i<prect->height ; i++) */
	incl	%esi	 /* i */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:705: 		for (i=0 ; i<prect->height ; i++) */
	movl	8(%esp), %edx	 /* %sfp, tmp173 */
	addl	%edx, %ebx	 /* tmp173, ivtmp.400 */
	cmpl	%esi, (%esp)	 /* i, %sfp */
	jne	L404	 /* , */
	movl	32(%esp), %edx	 /* %sfp, _149 */
L397:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:782: 			vr.x += vr.width; */
	addl	%edx, 16(%esp)	 /* _149, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:783: 			width -= vr.width; */
	subl	%edx, 12(%esp)	 /* _149, %sfp */
	movl	12(%esp), %ebp	 /* %sfp, width */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:760: 		while (width > 0) */
	testl	%ebp, %ebp	 /* width */
	jle	L417	 /* , */
	movl	_vid, %esi	 /* vid.buffer, pretmp_29 */
	movl	_vid+16, %ecx	 /* vid.rowbytes, vid.rowbytes */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:784: 			tileoffsetx = 0;	// only the left tile can be left-clipped */
	xorl	%ebp, %ebp	 /* tileoffsetx */
	jmp	L393	 /*  */
L421:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:626: 	pdest = vid.buffer + (prect->y * vid.rowbytes) + prect->x; */
	movl	68(%esp), %eax	 /* y, tmp153 */
	imull	%ecx, %eax	 /* vid.rowbytes, tmp153 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:626: 	pdest = vid.buffer + (prect->y * vid.rowbytes) + prect->x; */
	movl	16(%esp), %ebx	 /* %sfp, vr$x */
	addl	%ebx, %eax	 /* vr$x, tmp154 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:626: 	pdest = vid.buffer + (prect->y * vid.rowbytes) + prect->x; */
	addl	%esi, %eax	 /* pretmp_29, pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:653: 		for (i=0 ; i<prect->height ; i++) */
	movl	(%esp), %esi	 /* %sfp, */
	testl	%esi, %esi	 /*  */
	jle	L397	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:653: 		for (i=0 ; i<prect->height ; i++) */
	xorl	%ebx, %ebx	 /* i */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:655: 			memcpy (pdest, psrc, prect->width); */
	movl	%edx, %edi	 /* _149, tmp184 */
	andl	$2, %edi	 /* , tmp184 */
	movl	%edi, 8(%esp)	 /* tmp184, %sfp */
	jmp	L401	 /*  */
	.p2align 4
	.p2align 3
L423:
	testl	%edx, %edx	 /* _149 */
	je	L399	 /* , */
	movb	0(%ebp), %cl	 /* * psrc, tmp242 */
	movb	%cl, (%eax)	 /* tmp242,* pdest */
	movl	8(%esp), %esi	 /* %sfp, */
	testl	%esi, %esi	 /*  */
	jne	L416	 /* , */
L420:
	movl	_vid+16, %ecx	 /* vid.rowbytes, vid.rowbytes */
L399:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:656: 			psrc += rowbytes; */
	movl	4(%esp), %edi	 /* %sfp, pretmp_139 */
	addl	%edi, %ebp	 /* pretmp_139, psrc */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:657: 			pdest += vid.rowbytes; */
	addl	%ecx, %eax	 /* vid.rowbytes, pdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:653: 		for (i=0 ; i<prect->height ; i++) */
	incl	%ebx	 /* i */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:653: 		for (i=0 ; i<prect->height ; i++) */
	cmpl	%ebx, (%esp)	 /* i, %sfp */
	je	L397	 /* , */
L401:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:655: 			memcpy (pdest, psrc, prect->width); */
	cmpl	$4, %edx	 /* , _149 */
	jb	L423	 /* , */
	movl	0(%ebp), %ecx	 /* * psrc, tmp161 */
	movl	%ecx, (%eax)	 /* tmp161,* pdest */
	movl	-4(%ebp,%edx), %esi	 /* , tmp162 */
	movl	%esi, -4(%eax,%edx)	 /* tmp162, */
	leal	4(%eax), %edi	 /* , tmp163 */
	andl	$-4, %edi	 /* , tmp163 */
	movl	%eax, %ecx	 /* pdest, pdest */
	subl	%edi, %ecx	 /* tmp163, pdest */
	movl	%ebp, %esi	 /* psrc, psrc */
	subl	%ecx, %esi	 /* pdest, psrc */
	addl	%edx, %ecx	 /* _149, _82 */
	shrl	$2, %ecx	 /* , tmp164 */
	rep movsl
	jmp	L420	 /*  */
L417:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:787: 		vr.y += vr.height; */
	movl	76(%esp), %ebx	 /* h, h */
	movl	(%esp), %edx	 /* %sfp, _35 */
	addl	%edx, 68(%esp)	 /* _35, y */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:788: 		height -= vr.height; */
	subl	%edx, %ebx	 /* _35, h */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:789: 		tileoffsety = 0;		// only the top tile can be top-clipped */
	xorl	%ecx, %ecx	 /* tileoffsety */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:745: 	while (height > 0) */
	testl	%ebx, %ebx	 /* h */
	jg	L406	 /* , */
L389:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:791: } */
	addl	$44, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
L416:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:655: 			memcpy (pdest, psrc, prect->width); */
	movw	-2(%ebp,%edx), %di	 /* , tmp160 */
	movw	%di, -2(%eax,%edx)	 /* tmp160, */
	movl	_vid+16, %ecx	 /* vid.rowbytes, vid.rowbytes */
	jmp	L399	 /*  */
L422:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:782: 			vr.x += vr.width; */
	addl	%edx, 16(%esp)	 /* _149, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:783: 			width -= vr.width; */
	subl	%edx, 12(%esp)	 /* _149, %sfp */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:784: 			tileoffsetx = 0;	// only the left tile can be left-clipped */
	xorl	%ebp, %ebp	 /* tileoffsetx */
	jmp	L393	 /*  */
	.p2align 3
	.globl	_Draw_Fill
/* Draw_Fill: Preserve indexed byte truncation and native 16-bit palette fills. */
_Draw_Fill:
	pushl	%ebp	 /*  */
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	pushl	%esi	 /*  */
	movl	28(%esp), %eax	 /* y, y */
	movl	32(%esp), %esi	 /* w, w */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:810: 		dest = vid.buffer + y*vid.rowbytes + x; */
	movl	_vid, %edx	 /* vid.buffer, pretmp_79 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:810: 		dest = vid.buffer + y*vid.rowbytes + x; */
	movl	_vid+16, %ecx	 /* vid.rowbytes, vid.rowbytes */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:808: 	if (r_pixbytes == 1) */
	cmpl	$1, _r_pixbytes	 /* , r_pixbytes */
	je	L448	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:819: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	shrl	$1, %ecx	 /* , tmp131 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:819: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	imull	%eax, %ecx	 /* y, tmp132 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:819: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	movl	24(%esp), %ebx	 /* x, tmp132 */
	addl	%ecx, %ebx	 /* tmp132, tmp132 */
	addl	%ebx, %ebx	 /* tmp133, tmp134 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:819: 		pusdest = (unsigned short *)vid.buffer + y * (vid.rowbytes >> 1) + x; */
	leal	(%edx,%ebx), %ebx	 /* , pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:820: 		for (v=0 ; v<h ; v++, pusdest += (vid.rowbytes >> 1)) */
	movl	36(%esp), %ecx	 /* h, */
	testl	%ecx, %ecx	 /*  */
	jle	L424	 /* , */
	testl	%esi, %esi	 /* w */
	jle	L424	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:817: 		uc = d_8to16table[c]; */
	movl	40(%esp), %edi	 /* c, tmp160 */
	movw	_d_8to16table(%edi,%edi), %cx	 /* d_8to16table[c_39(D)], _12 */
	addl	%esi, %esi	 /* w, tmp136 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:820: 		for (v=0 ; v<h ; v++, pusdest += (vid.rowbytes >> 1)) */
	xorl	%edi, %edi	 /* v */
	movl	36(%esp), %ebp	 /* h, h */
	.p2align 3
	.p2align 3
L433:
	movl	%ebx, %eax	 /* pusdest, ivtmp.412 */
	leal	(%ebx,%esi), %edx	 /* , _74 */
	.p2align 3
	.p2align 3
L434:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:822: 				pusdest[u] = uc; */
	movw	%cx, (%eax)	 /* _12, MEM[(short unsigned int *)_9] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:821: 			for (u=0 ; u<w ; u++) */
	addl	$2, %eax	 /* , ivtmp.412 */
	cmpl	%edx, %eax	 /* _74, ivtmp.412 */
	jne	L434	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:820: 		for (v=0 ; v<h ; v++, pusdest += (vid.rowbytes >> 1)) */
	incl	%edi	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:820: 		for (v=0 ; v<h ; v++, pusdest += (vid.rowbytes >> 1)) */
	movl	_vid+16, %eax	 /* vid.rowbytes, tmp140 */
	andl	$-2, %eax	 /* , tmp140 */
	addl	%eax, %ebx	 /* tmp140, pusdest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:820: 		for (v=0 ; v<h ; v++, pusdest += (vid.rowbytes >> 1)) */
	cmpl	%edi, %ebp	 /* v, h */
	jne	L433	 /* , */
L424:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:824: } */
	popl	%eax	 /*  */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	popl	%ebp	 /*  */
	ret
L448:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:810: 		dest = vid.buffer + y*vid.rowbytes + x; */
	imull	%ecx, %eax	 /* vid.rowbytes, tmp116 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:810: 		dest = vid.buffer + y*vid.rowbytes + x; */
	addl	24(%esp), %eax	 /* x, tmp117 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:810: 		dest = vid.buffer + y*vid.rowbytes + x; */
	addl	%eax, %edx	 /* tmp117, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:811: 		for (v=0 ; v<h ; v++, dest += vid.rowbytes) */
	movl	36(%esp), %ebx	 /* h, */
	testl	%ebx, %ebx	 /*  */
	jle	L424	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:811: 		for (v=0 ; v<h ; v++, dest += vid.rowbytes) */
	xorl	%ebp, %ebp	 /* v */
	testl	%esi, %esi	 /* w */
	jle	L424	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:813: 				dest[u] = c; */
	movl	40(%esp), %ebx	 /* c, tmp118 */
	andl	$255, %ebx	 /* , tmp118 */
	movl	%esi, %edi	 /* w, tmp142 */
	andl	$2, %edi	 /* , tmp142 */
	movl	%edi, (%esp)	 /* tmp142, %sfp */
	jmp	L427	 /*  */
	.p2align 4
	.p2align 3
L449:
	testl	%esi, %esi	 /* w */
	je	L429	 /* , */
	movb	%al, (%edx)	 /* tmp121,* dest */
	movl	(%esp), %ecx	 /* %sfp, */
	testl	%ecx, %ecx	 /*  */
	jne	L445	 /* , */
L447:
	movl	_vid+16, %ecx	 /* vid.rowbytes, vid.rowbytes */
L429:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:811: 		for (v=0 ; v<h ; v++, dest += vid.rowbytes) */
	incl	%ebp	 /* v */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:811: 		for (v=0 ; v<h ; v++, dest += vid.rowbytes) */
	addl	%ecx, %edx	 /* vid.rowbytes, dest */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:811: 		for (v=0 ; v<h ; v++, dest += vid.rowbytes) */
	cmpl	%ebp, 36(%esp)	 /* v, h */
	je	L424	 /* , */
L427:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:813: 				dest[u] = c; */
	xorl	%eax, %eax	 /* tmp121 */
	movb	%bl, %al	 /* tmp118, tmp121 */
	movb	%al, %ah	 /* tmp121, tmp121 */
	movl	%eax, %edi	 /* tmp121, tmp123 */
	sall	$16, %edi	 /* , tmp123 */
	orl	%edi, %eax	 /* tmp123, tmp121 */
	cmpl	$4, %esi	 /* , w */
	jb	L449	 /* , */
	movl	%eax, (%edx)	 /* tmp121,* dest */
	movl	%eax, -4(%edx,%esi)	 /* tmp121, */
	leal	4(%edx), %edi	 /* , tmp125 */
	andl	$-4, %edi	 /* , tmp125 */
	movl	%edx, %ecx	 /* dest, dest */
	subl	%edi, %ecx	 /* tmp125, dest */
	addl	%esi, %ecx	 /* w, w */
	shrl	$2, %ecx	 /* , tmp126 */
	rep stosl
	jmp	L447	 /*  */
L445:
	movw	%ax, -2(%edx,%esi)	 /* tmp121, */
	movl	_vid+16, %ecx	 /* vid.rowbytes, vid.rowbytes */
	jmp	L429	 /*  */
	.p2align 3
	.globl	_Draw_FadeScreen
/* Draw_FadeScreen: Preserve the byte-oriented stipple and both unlock/sound/lock sequences. */
_Draw_FadeScreen:
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:839: 	S_ExtraUpdate (); */
	call	_S_ExtraUpdate	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:842: 	for (y=0 ; y<vid.height ; y++) */
	movl	_vid+24, %eax	 /* vid.height, */
	testl	%eax, %eax	 /*  */
	je	L452	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:849: 		for (x=0 ; x<vid.width ; x++) */
	movl	_vid+20, %ecx	 /* vid.width, prephitmp_27 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:842: 	for (y=0 ; y<vid.height ; y++) */
	xorl	%edi, %edi	 /* y */
	.p2align 3
	.p2align 3
L457:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:846: 		pbuf = (byte *)(vid.buffer + vid.rowbytes*y); */
	movl	_vid, %esi	 /* vid.buffer, _1 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:846: 		pbuf = (byte *)(vid.buffer + vid.rowbytes*y); */
	movl	_vid+16, %edx	 /* vid.rowbytes, _3 */
	imull	%edi, %edx	 /* y, _3 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:847: 		t = (y & 1) << 1; */
	leal	(%edi,%edi), %ebx	 /* , tmp104 */
	andl	$2, %ebx	 /* , t */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:849: 		for (x=0 ; x<vid.width ; x++) */
	testl	%ecx, %ecx	 /* prephitmp_27 */
	je	L452	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:849: 		for (x=0 ; x<vid.width ; x++) */
	xorl	%eax, %eax	 /* x */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:852: 				pbuf[x] = 0; */
	addl	%edx, %esi	 /* _3, tmp109 */
	.p2align 3
	.p2align 3
L456:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:851: 			if ((x & 3) != t) */
	movl	%eax, %edx	 /* x, tmp105 */
	andl	$3, %edx	 /* , tmp105 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:851: 			if ((x & 3) != t) */
	cmpl	%ebx, %edx	 /* t, tmp105 */
	je	L453	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:852: 				pbuf[x] = 0; */
	movb	$0, (%esi,%eax)	 /* , MEM[(byte *)_29 + _71 * 1] */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:849: 		for (x=0 ; x<vid.width ; x++) */
	movl	_vid+20, %ecx	 /* vid.width, prephitmp_27 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:849: 		for (x=0 ; x<vid.width ; x++) */
	incl	%eax	 /* x */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:849: 		for (x=0 ; x<vid.width ; x++) */
	cmpl	%ecx, %eax	 /* prephitmp_27, x */
	jb	L456	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:842: 	for (y=0 ; y<vid.height ; y++) */
	incl	%edi	 /* y */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:842: 	for (y=0 ; y<vid.height ; y++) */
	cmpl	_vid+24, %edi	 /* vid.height, y */
	jb	L457	 /* , */
L452:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:859: } */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:857: 	S_ExtraUpdate (); */
	jmp	_S_ExtraUpdate	 /*  */
	.p2align 4
	.p2align 3
L453:
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:849: 		for (x=0 ; x<vid.width ; x++) */
	incl	%eax	 /* x */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:849: 		for (x=0 ; x<vid.width ; x++) */
	cmpl	%ecx, %eax	 /* prephitmp_27, x */
	jb	L456	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:842: 	for (y=0 ; y<vid.height ; y++) */
	incl	%edi	 /* y */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:842: 	for (y=0 ; y<vid.height ; y++) */
	cmpl	_vid+24, %edi	 /* vid.height, y */
	jb	L457	 /* , */
	jmp	L452	 /*  */
	.p2align 3
	.globl	_Draw_BeginDisc
/* Draw_BeginDisc: Pass the original five direct-rectangle arguments in order. */
_Draw_BeginDisc:
	subl	$24, %esp	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:874: 	D_BeginDirectRect (vid.width - 24, 0, draw_disc->data, 24, 24); */
	pushl	$24	 /*  */
	pushl	$24	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:874: 	D_BeginDirectRect (vid.width - 24, 0, draw_disc->data, 24, 24); */
	movl	_draw_disc, %eax	 /* draw_disc, tmp93 */
	addl	$8, %eax	 /* , tmp87 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:874: 	D_BeginDirectRect (vid.width - 24, 0, draw_disc->data, 24, 24); */
	pushl	%eax	 /* tmp87 */
	pushl	$0	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:874: 	D_BeginDirectRect (vid.width - 24, 0, draw_disc->data, 24, 24); */
	movl	_vid+20, %edx	 /* vid.width, tmp94 */
	subl	$24, %edx	 /* , tmp90 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:874: 	D_BeginDirectRect (vid.width - 24, 0, draw_disc->data, 24, 24); */
	pushl	%edx	 /* tmp90 */
	call	_D_BeginDirectRect	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:875: } */
	addl	$44, %esp	 /* , */
	ret
	.p2align 3
	.globl	_Draw_EndDisc
/* Draw_EndDisc: Pass the original four restore-rectangle arguments in order. */
_Draw_EndDisc:
	subl	$12, %esp	 /* , */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:889: 	D_EndDirectRect (vid.width - 24, 0, 24, 24); */
	pushl	$24	 /*  */
	pushl	$24	 /*  */
	pushl	$0	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:889: 	D_EndDirectRect (vid.width - 24, 0, 24, 24); */
	movl	_vid+20, %eax	 /* vid.width, tmp89 */
	subl	$24, %eax	 /* , tmp86 */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:889: 	D_EndDirectRect (vid.width - 24, 0, 24, 24); */
	pushl	%eax	 /* tmp86 */
	call	_D_EndDirectRect	 /*  */
 /* workspace\quake\out\drawing-worktree-20261008\src\draw.c:890: } */
	addl	$28, %esp	 /* , */
	ret
