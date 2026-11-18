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

/* Math support instruction ownership, imported once from the pinned C oracle.
 * Source SHA256: A57CC56F7BF565AEA70BC6E324B82CD393DC5F2A075E0B5F184019A76B798D70
 * DJGPP GCC 12.2.0, -march=i486 -mtune=i486. Normal builds do not regenerate this file.
 * Cdecl: arguments at entry ESP+4; EAX integer / ST(0) float returns.
 * EBX/ESI/EDI/EBP preserved; EAX/ECX/EDX and arithmetic flags caller-owned.
 * Instructions and x87 store boundaries preserve the original algorithms.
 * Adjacent source comments identify the C expression and variables.
 */
#ifdef ASM486_MATH_CLOSURE
.arch i486
.arch .387
.code32

.text
.p2align 3
/* ProjectPointOnPlane: Project a point using the original reciprocal squared-normal length and scalar products.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	_ProjectPointOnPlane
_ProjectPointOnPlane:
	movl	4(%esp), %edx	# dst, dst
	movl	8(%esp), %eax	# p, p
	movl	12(%esp), %ecx	# normal, normal
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:40: 	inv_denom = 1.0F / DotProduct( normal, normal ); */
	flds	(%ecx)	# *normal_29(D)
	flds	4(%ecx)	# MEM[(const vec_t *)normal_29(D) + 4B]
	flds	8(%ecx)	# MEM[(const vec_t *)normal_29(D) + 8B]
	fld	%st(2)	#
	fmul	%st(3), %st	#,
	fld	%st(2)	#
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
	fld	%st(1)	#
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:40: 	inv_denom = 1.0F / DotProduct( normal, normal ); */
	fdivrs	LC0	#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:42: 	d = DotProduct( normal, p ) * inv_denom; */
	flds	(%eax)	# *p_31(D)
	flds	4(%eax)	# MEM[(const vec_t *)p_31(D) + 4B]
	fmul	%st(4), %st	#,
	fld	%st(5)	#
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
	flds	8(%eax)	# MEM[(const vec_t *)p_31(D) + 8B]
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:42: 	d = DotProduct( normal, p ) * inv_denom; */
	fmul	%st(2), %st	#,
	fxch	%st(5)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:44: 	n[0] = normal[0] * inv_denom; */
	fmul	%st(2), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:48: 	dst[0] = p[0] - d * n[0]; */
	fmul	%st(5), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:48: 	dst[0] = p[0] - d * n[0]; */
	fsubrp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:48: 	dst[0] = p[0] - d * n[0]; */
	fstps	(%edx)	# *dst_33(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:45: 	n[1] = normal[1] * inv_denom; */
	fmul	%st, %st(2)	#,
	fxch	%st(2)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:49: 	dst[1] = p[1] - d * n[1]; */
	fmul	%st(3), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:49: 	dst[1] = p[1] - d * n[1]; */
	fsubrs	4(%eax)	# MEM[(const vec_t *)p_31(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:49: 	dst[1] = p[1] - d * n[1]; */
	fstps	4(%edx)	# MEM[(vec_t *)dst_33(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:46: 	n[2] = normal[2] * inv_denom; */
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:50: 	dst[2] = p[2] - d * n[2]; */
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:50: 	dst[2] = p[2] - d * n[2]; */
	fsubrs	8(%eax)	# MEM[(const vec_t *)p_31(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:50: 	dst[2] = p[2] - d * n[2]; */
	fstps	8(%edx)	# MEM[(vec_t *)dst_33(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:51: } */
	ret
	.p2align 3

.text
.p2align 3
/* PerpendicularVector: Choose the least-magnitude axis, project it and normalize the perpendicular vector.
 * Preserved registers used: %ebx.
 * Stack reservations, including call areas: 16 bytes. */
	.globl	_PerpendicularVector
_PerpendicularVector:
	pushl	%ebx	#
	subl	$16, %esp	#,
	movl	24(%esp), %edx	# dst, dst
	movl	28(%esp), %ecx	# src, src
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:68: 		if ( fabs( src[i] ) < minelem ) */
	flds	(%ecx)	# *src_18(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:68: 		if ( fabs( src[i] ) < minelem ) */
	fld	%st(0)	#
	fabs
	fld1
	fcom	%st(1)	#
	fnstsw	%ax	# tmp129
	testb	$69, %ah	#, tmp129
	jne	L15	#,
	fstp	%st(0)		#
	jmp	L4	#
	.p2align 4
	.p2align 3
L15:
	fstp	%st(1)		#
L4:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:68: 		if ( fabs( src[i] ) < minelem ) */
	flds	4(%ecx)	# MEM[(const vec_t *)src_18(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:68: 		if ( fabs( src[i] ) < minelem ) */
	fld	%st(0)	#
	fabs
	fxch	%st(2)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:68: 		if ( fabs( src[i] ) < minelem ) */
	fcom	%st(2)	#
	fnstsw	%ax	# tmp130
	testb	$69, %ah	#, tmp130
	jne	L13	#,
	fstp	%st(0)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:66: 	for ( pos = 0, i = 0; i < 3; i++ ) */
	movl	$1, %ebx	#, pos
L5:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:68: 		if ( fabs( src[i] ) < minelem ) */
	flds	8(%ecx)	# MEM[(const vec_t *)src_18(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:68: 		if ( fabs( src[i] ) < minelem ) */
	fld	%st(0)	#
	fabs
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:68: 		if ( fabs( src[i] ) < minelem ) */
	fcomp	%st(3)	#
	fnstsw	%ax	# tmp132
	fstp	%st(2)		#
	testb	$1, %ah	#, tmp132
	je	L7	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:66: 	for ( pos = 0, i = 0; i < 3; i++ ) */
	movl	$2, %ebx	#, pos
L7:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:74: 	tempvec[0] = tempvec[1] = tempvec[2] = 0.0F; */
	fldz
	fsts	12(%esp)	# tempvec[2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:74: 	tempvec[0] = tempvec[1] = tempvec[2] = 0.0F; */
	fsts	8(%esp)	# tempvec[1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:74: 	tempvec[0] = tempvec[1] = tempvec[2] = 0.0F; */
	fstps	4(%esp)	# tempvec[0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:75: 	tempvec[pos] = 1.0F; */
	fld1
	fsts	4(%esp,%ebx,4)	# tempvec[pos_79]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:40: 	inv_denom = 1.0F / DotProduct( normal, normal ); */
	fld	%st(1)	#
	fmul	%st(2), %st	#,
	fld	%st(3)	#
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
	fld	%st(4)	#
	fmul	%st(5), %st	#,
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:40: 	inv_denom = 1.0F / DotProduct( normal, normal ); */
	fdivr	%st(1), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:42: 	d = DotProduct( normal, p ) * inv_denom; */
	flds	4(%esp)	# MEM[(const vec_t *)&tempvec]
	flds	8(%esp)	# MEM[(const vec_t *)&tempvec + 4B]
	fmul	%st(4), %st	#,
	flds	12(%esp)	# MEM[(const vec_t *)&tempvec + 8B]
	fmul	%st(6), %st	#,
	faddp	%st, %st(1)	#,
	fld	%st(6)	#
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:42: 	d = DotProduct( normal, p ) * inv_denom; */
	fmul	%st(2), %st	#,
	fxch	%st(6)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:44: 	n[0] = normal[0] * inv_denom; */
	fmul	%st(2), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:48: 	dst[0] = p[0] - d * n[0]; */
	fmul	%st(6), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:48: 	dst[0] = p[0] - d * n[0]; */
	fsubrp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:48: 	dst[0] = p[0] - d * n[0]; */
	fsts	(%edx)	# *dst_17(D)
	fxch	%st(3)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:45: 	n[1] = normal[1] * inv_denom; */
	fmul	%st(1), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:49: 	dst[1] = p[1] - d * n[1]; */
	fmul	%st(5), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:49: 	dst[1] = p[1] - d * n[1]; */
	fsubrs	8(%esp)	# MEM[(const vec_t *)&tempvec + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:49: 	dst[1] = p[1] - d * n[1]; */
	fsts	4(%edx)	# MEM[(vec_t *)dst_17(D) + 4B]
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:46: 	n[2] = normal[2] * inv_denom; */
	fmulp	%st, %st(4)	#,
	fxch	%st(3)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:50: 	dst[2] = p[2] - d * n[2]; */
	fmulp	%st, %st(4)	#,
	fxch	%st(3)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:50: 	dst[2] = p[2] - d * n[2]; */
	fsubrs	12(%esp)	# MEM[(const vec_t *)&tempvec + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:50: 	dst[2] = p[2] - d * n[2]; */
	fsts	8(%edx)	# MEM[(vec_t *)dst_17(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:387: 	length = v[0]*v[0] + v[1]*v[1] + v[2]*v[2]; */
	fld	%st(1)	#
	fmul	%st(2), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:387: 	length = v[0]*v[0] + v[1]*v[1] + v[2]*v[2]; */
	fld	%st(3)	#
	fmul	%st(4), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:387: 	length = v[0]*v[0] + v[1]*v[1] + v[2]*v[2]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:387: 	length = v[0]*v[0] + v[1]*v[1] + v[2]*v[2]; */
	fld	%st(1)	#
	fmul	%st(2), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:387: 	length = v[0]*v[0] + v[1]*v[1] + v[2]*v[2]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:388: 	length = sqrt (length);		// FIXME */
	fsqrt
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:390: 	if (length) */
	ftst
	fnstsw	%ax	# tmp162
	testb	$64, %ah	#, tmp162
	jne	L16	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:392: 		ilength = 1/length; */
	fdivrp	%st, %st(4)	#,
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:393: 		v[0] *= ilength; */
	fmul	%st(3), %st	#,
	fstps	(%edx)	# *dst_17(D)
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:394: 		v[1] *= ilength; */
	fmul	%st(2), %st	#,
	fstps	4(%edx)	# MEM[(vec_t *)dst_17(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:395: 		v[2] *= ilength; */
	fmulp	%st, %st(1)	#,
	fstps	8(%edx)	# MEM[(vec_t *)dst_17(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:86: } */
	jmp	L3	#
	.p2align 4
	.p2align 3
L16:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
L3:
	addl	$16, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L13:
	fstp	%st(2)		#
	fxch	%st(1)		#
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:68: 		if ( fabs( src[i] ) < minelem ) */
	xorl	%ebx, %ebx	# pos
	jmp	L5	#
	.p2align 3

.text
.p2align 3
/* RotatePointAroundVector: Build the original basis, transpose and degree rotation, concatenate matrices, and transform the point.
 * Preserved registers used: %ebx, %esi.
 * Stack reservations, including call areas: 172 bytes. */
	.globl	_RotatePointAroundVector
_RotatePointAroundVector:
	pushl	%esi	#
	pushl	%ebx	#
	subl	$172, %esp	#,
	movl	184(%esp), %esi	# dst, dst
	movl	188(%esp), %eax	# dir, dir
	movl	192(%esp), %ebx	# point, point
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:98: 	vf[0] = dir[0]; */
	flds	(%eax)	# *dir_28(D)
	fstps	8(%esp)	# %sfp
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:99: 	vf[1] = dir[1]; */
	flds	4(%eax)	# MEM[(const vec_t *)dir_28(D) + 4B]
	fstps	(%esp)	# %sfp
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:100: 	vf[2] = dir[2]; */
	flds	8(%eax)	# MEM[(const vec_t *)dir_28(D) + 8B]
	fstps	4(%esp)	# %sfp
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:102: 	PerpendicularVector( vr, dir ); */
	pushl	%eax	# dir
	leal	52(%esp), %edx	#, tmp161
	pushl	%edx	# tmp161
	call	_PerpendicularVector	#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:363: 	cross[0] = v1[1]*v2[2] - v1[2]*v2[1]; */
	flds	60(%esp)	# MEM[(vec_t *)&vr + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:363: 	cross[0] = v1[1]*v2[2] - v1[2]*v2[1]; */
	flds	12(%esp)	# %sfp
	fmul	%st(1), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:363: 	cross[0] = v1[1]*v2[2] - v1[2]*v2[1]; */
	flds	64(%esp)	# MEM[(vec_t *)&vr + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:363: 	cross[0] = v1[1]*v2[2] - v1[2]*v2[1]; */
	flds	8(%esp)	# %sfp
	fmul	%st(1), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:363: 	cross[0] = v1[1]*v2[2] - v1[2]*v2[1]; */
	fld	%st(2)	#
	fxch	%st(1)		#
	fsts	24(%esp)	# %sfp
	fsubrp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:364: 	cross[1] = v1[2]*v2[0] - v1[0]*v2[2]; */
	flds	16(%esp)	# %sfp
	fld	%st(0)	#
	fmul	%st(3), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:364: 	cross[1] = v1[2]*v2[0] - v1[0]*v2[2]; */
	flds	56(%esp)	# MEM[(vec_t *)&vr]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:364: 	cross[1] = v1[2]*v2[0] - v1[0]*v2[2]; */
	flds	12(%esp)	# %sfp
	fmul	%st(1), %st	#,
	fxch	%st(2)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:364: 	cross[1] = v1[2]*v2[0] - v1[0]*v2[2]; */
	fsts	28(%esp)	# %sfp
	fxch	%st(2)		#
	fsts	32(%esp)	# %sfp
	fsubrp	%st, %st(2)	#,
	fxch	%st(1)		#
	fstps	20(%esp)	# %sfp
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:365: 	cross[2] = v1[0]*v2[1] - v1[1]*v2[0]; */
	flds	8(%esp)	# %sfp
	fmul	%st(1), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:365: 	cross[2] = v1[0]*v2[1] - v1[1]*v2[0]; */
	fld	%st(2)	#
	fmul	%st(7), %st	#,
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:365: 	cross[2] = v1[0]*v2[1] - v1[1]*v2[0]; */
	fsts	36(%esp)	# %sfp
	fxch	%st(1)		#
	fsts	40(%esp)	# %sfp
	fsubrp	%st, %st(1)	#,
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:117: 	memcpy( im, m, sizeof( im ) ); */
	fsts	68(%esp)	# MEM <float> [(char * {ref-all})&im]
	flds	20(%esp)	# %sfp
	fstps	84(%esp)	# MEM <float> [(char * {ref-all})&im + 16B]
	flds	12(%esp)	# %sfp
	fstps	100(%esp)	# MEM <float> [(char * {ref-all})&im + 32B]
	fxch	%st(6)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:119: 	im[0][1] = m[1][0]; */
	fsts	72(%esp)	# im[0][1]
	fxch	%st(4)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:120: 	im[0][2] = m[2][0]; */
	fsts	76(%esp)	# im[0][2]
	fxch	%st(3)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:121: 	im[1][0] = m[0][1]; */
	fsts	80(%esp)	# im[1][0]
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:122: 	im[1][2] = m[2][1]; */
	fsts	44(%esp)	# %sfp
	fstps	88(%esp)	# im[1][2]
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:123: 	im[2][0] = m[0][2]; */
	fstps	92(%esp)	# im[2][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:124: 	im[2][1] = m[1][2]; */
	flds	8(%esp)	# %sfp
	fstps	96(%esp)	# im[2][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:129: 	zrot[0][0] = cos( DEG2RAD( degrees ) ); */
	fldl	LC6	#
	fmuls	204(%esp)	# degrees
	fld	%st(0)	#
	fcos
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:130: 	zrot[0][1] = sin( DEG2RAD( degrees ) ); */
	fsin
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:440: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	flds	24(%esp)	# %sfp
	fsubp	%st, %st(6)	#,
	fmul	%st, %st(5)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:440: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	fld	%st(1)	#
	fmul	%st(7), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:440: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	faddp	%st, %st(6)	#,
	fxch	%st(5)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:440: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	fstps	104(%esp)	# MEM[(float[3] *)&tmpmat][0]
	fxch	%st(5)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:442: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	fmul	%st(4), %st	#,
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:442: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	fmul	%st(5), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:442: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:442: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	fstps	108(%esp)	# MEM[(float[3] *)&tmpmat][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:444: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	flds	16(%esp)	# %sfp
	fstps	112(%esp)	# MEM[(float[3] *)&tmpmat][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:446: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	flds	32(%esp)	# %sfp
	fsubs	28(%esp)	# %sfp
	fmul	%st(3), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:446: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	fld	%st(4)	#
	fmul	%st(3), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:446: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:446: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	fstps	116(%esp)	# MEM[(float[3] *)&tmpmat + 12B][0]
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:448: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	fmul	%st(2), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:448: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	flds	20(%esp)	# %sfp
	fmul	%st(4), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:448: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:448: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	fstps	120(%esp)	# MEM[(float[3] *)&tmpmat + 12B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:450: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	flds	8(%esp)	# %sfp
	fstps	124(%esp)	# MEM[(float[3] *)&tmpmat + 12B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:452: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	flds	40(%esp)	# %sfp
	fsubs	36(%esp)	# %sfp
	fmul	%st(2), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:452: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	fld	%st(3)	#
	fmul	%st(2), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:452: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:452: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	fstps	128(%esp)	# MEM[(float[3] *)&tmpmat + 24B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:454: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	fmulp	%st, %st(1)	#,
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:454: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	fmuls	44(%esp)	# %sfp
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:454: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:454: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	fstps	132(%esp)	# MEM[(float[3] *)&tmpmat + 24B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:456: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	flds	12(%esp)	# %sfp
	fstps	136(%esp)	# MEM[(float[3] *)&tmpmat + 24B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:135: 	R_ConcatRotations( tmpmat, im, rot ); */
	popl	%eax	#
	leal	136(%esp), %ecx	#, tmp189
	pushl	%ecx	# tmp189
	leal	68(%esp), %eax	#, tmp190
	pushl	%eax	# tmp190
	leal	108(%esp), %edx	#, tmp191
	pushl	%edx	# tmp191
	call	_R_ConcatRotations	#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	flds	4(%ebx)	# MEM[(const vec_t *)point_61(D) + 4B]
	fmuls	152(%esp)	# rot[0][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	flds	148(%esp)	# rot[0][0]
	fmuls	(%ebx)	# *point_61(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	flds	8(%ebx)	# MEM[(const vec_t *)point_61(D) + 8B]
	fmuls	156(%esp)	# rot[0][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	fstps	(%esi)	# *dst_62(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	flds	4(%ebx)	# MEM[(const vec_t *)point_61(D) + 4B]
	fmuls	164(%esp)	# rot[1][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	flds	(%ebx)	# *point_61(D)
	fmuls	160(%esp)	# rot[1][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	flds	168(%esp)	# rot[1][2]
	fmuls	8(%ebx)	# MEM[(const vec_t *)point_61(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	fstps	4(%esi)	# MEM[(vec_t *)dst_62(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	flds	172(%esp)	# rot[2][0]
	fmuls	(%ebx)	# *point_61(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	flds	176(%esp)	# rot[2][1]
	fmuls	4(%ebx)	# MEM[(const vec_t *)point_61(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	flds	180(%esp)	# rot[2][2]
	fmuls	8(%ebx)	# MEM[(const vec_t *)point_61(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:139: 		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2]; */
	fstps	8(%esi)	# MEM[(vec_t *)dst_62(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:141: } */
	addl	$188, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	ret
	.p2align 3

.text
.p2align 3
/* anglemod: Truncate to the original 16-bit angular grid and wrap with the 65535 mask.
 * Preserved registers used: none.
 * Stack reservations, including call areas: 12 bytes. */
	.globl	_anglemod
_anglemod:
	subl	$12, %esp	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:154: 	a = (360.0/65536) * ((int)(a*(65536/360.0)) & 65535); */
	fldl	LC3	#
	fmuls	16(%esp)	# a
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:154: 	a = (360.0/65536) * ((int)(a*(65536/360.0)) & 65535); */
	fnstcw	6(%esp)	#
	movw	6(%esp), %ax	#, tmp99
	orb	$12, %ah	#, tmp99
	movw	%ax, 4(%esp)	# tmp99,
	fldcw	4(%esp)		#
	fistpl	(%esp)	# %sfp
	fldcw	6(%esp)		#
	movl	(%esp), %edx	# %sfp, tmp93
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:154: 	a = (360.0/65536) * ((int)(a*(65536/360.0)) & 65535); */
	andl	$65535, %edx	#, tmp94
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:154: 	a = (360.0/65536) * ((int)(a*(65536/360.0)) & 65535); */
	flds	LC4	#
	movl	%edx, (%esp)	# tmp94, %sfp
	fimull	(%esp)	# %sfp
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:156: } */
	addl	$12, %esp	#,
	ret

.text
.p2align 3
/* BOPS_Error: Preserve the renderer plane-sign error boundary and diagnostic.
 * Preserved registers used: none.
 * Stack reservations, including call areas: 24 bytes. */
	.globl	_BOPS_Error
_BOPS_Error:
	subl	$24, %esp	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:167: 	Sys_Error ("BoxOnPlaneSide:  Bad signbits"); */
	pushl	$LC5	#
	call	_Sys_Error	#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:168: } */
	addl	$28, %esp	#,
	ret
	.p2align 3

.text
.p2align 3
/* VectorCompare: Compare all three floating components using the reference comparison behavior.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	_VectorCompare
_VectorCompare:
	movl	4(%esp), %ecx	# v1, v1
	movl	8(%esp), %edx	# v2, v2
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:321: 		if (v1[i] != v2[i]) */
	flds	(%ecx)	# *v1_9(D)
	fcomps	(%edx)	# *v2_11(D)
	fnstsw	%ax	# tmp93
	testb	$64, %ah	#, tmp93
	je	L28	#,
	flds	4(%ecx)	# MEM[(vec_t *)v1_9(D) + 4B]
	fcomps	4(%edx)	# MEM[(vec_t *)v2_11(D) + 4B]
	fnstsw	%ax	# tmp95
	testb	$64, %ah	#, tmp95
	je	L28	#,
	flds	8(%ecx)	# MEM[(vec_t *)v1_9(D) + 8B]
	fcomps	8(%edx)	# MEM[(vec_t *)v2_11(D) + 8B]
	fnstsw	%ax	# tmp99
	testb	$64, %ah	#, tmp99
	setne	%al	#, <retval>
	andl	$255, %eax	#, <retval>
	ret
	.p2align 4
	.p2align 3
L28:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:322: 			return 0; */
	xorl	%eax, %eax	# <retval>
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:325: } */
	ret
	.p2align 3

.text
.p2align 3
/* VectorMA: Preserve sequential component multiply/add stores, including permitted vector aliases.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	_VectorMA
_VectorMA:
	movl	4(%esp), %edx	# veca, veca
	flds	8(%esp)	# scale
	movl	12(%esp), %ecx	# vecb, vecb
	movl	16(%esp), %eax	# vecc, vecc
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:329: 	vecc[0] = veca[0] + scale*vecb[0]; */
	flds	(%ecx)	# *vecb_15(D)
	fmul	%st(1), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:329: 	vecc[0] = veca[0] + scale*vecb[0]; */
	fadds	(%edx)	# *veca_14(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:329: 	vecc[0] = veca[0] + scale*vecb[0]; */
	fstps	(%eax)	# *vecc_17(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:330: 	vecc[1] = veca[1] + scale*vecb[1]; */
	flds	4(%ecx)	# MEM[(vec_t *)vecb_15(D) + 4B]
	fmul	%st(1), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:330: 	vecc[1] = veca[1] + scale*vecb[1]; */
	fadds	4(%edx)	# MEM[(vec_t *)veca_14(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:330: 	vecc[1] = veca[1] + scale*vecb[1]; */
	fstps	4(%eax)	# MEM[(vec_t *)vecc_17(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:331: 	vecc[2] = veca[2] + scale*vecb[2]; */
	fmuls	8(%ecx)	# MEM[(vec_t *)vecb_15(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:331: 	vecc[2] = veca[2] + scale*vecb[2]; */
	fadds	8(%edx)	# MEM[(vec_t *)veca_14(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:331: 	vecc[2] = veca[2] + scale*vecb[2]; */
	fstps	8(%eax)	# MEM[(vec_t *)vecc_17(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:332: } */
	ret
	.p2align 3

.text
.p2align 3
/* _DotProduct: Evaluate the original three-component dot product and return ST(0).
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	__DotProduct
__DotProduct:
	movl	4(%esp), %edx	# v1, v1
	movl	8(%esp), %eax	# v2, v2
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:337: 	return v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2]; */
	flds	(%edx)	# *v1_12(D)
	fmuls	(%eax)	# *v2_13(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:337: 	return v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2]; */
	flds	4(%edx)	# MEM[(vec_t *)v1_12(D) + 4B]
	fmuls	4(%eax)	# MEM[(vec_t *)v2_13(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:337: 	return v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:337: 	return v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2]; */
	flds	8(%edx)	# MEM[(vec_t *)v1_12(D) + 8B]
	fmuls	8(%eax)	# MEM[(vec_t *)v2_13(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:337: 	return v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:338: } */
	ret
	.p2align 3

.text
.p2align 3
/* _VectorSubtract: Subtract and store the three vector components in source order.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	__VectorSubtract
__VectorSubtract:
	movl	4(%esp), %ecx	# veca, veca
	movl	8(%esp), %edx	# vecb, vecb
	movl	12(%esp), %eax	# out, out
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:342: 	out[0] = veca[0]-vecb[0]; */
	flds	(%ecx)	# *veca_11(D)
	fsubs	(%edx)	# *vecb_12(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:342: 	out[0] = veca[0]-vecb[0]; */
	fstps	(%eax)	# *out_13(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:343: 	out[1] = veca[1]-vecb[1]; */
	flds	4(%ecx)	# MEM[(vec_t *)veca_11(D) + 4B]
	fsubs	4(%edx)	# MEM[(vec_t *)vecb_12(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:343: 	out[1] = veca[1]-vecb[1]; */
	fstps	4(%eax)	# MEM[(vec_t *)out_13(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:344: 	out[2] = veca[2]-vecb[2]; */
	flds	8(%ecx)	# MEM[(vec_t *)veca_11(D) + 8B]
	fsubs	8(%edx)	# MEM[(vec_t *)vecb_12(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:344: 	out[2] = veca[2]-vecb[2]; */
	fstps	8(%eax)	# MEM[(vec_t *)out_13(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:345: } */
	ret
	.p2align 3

.text
.p2align 3
/* _VectorAdd: Add and store the three vector components in source order.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	__VectorAdd
__VectorAdd:
	movl	4(%esp), %ecx	# veca, veca
	movl	8(%esp), %edx	# vecb, vecb
	movl	12(%esp), %eax	# out, out
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:349: 	out[0] = veca[0]+vecb[0]; */
	flds	(%ecx)	# *veca_11(D)
	fadds	(%edx)	# *vecb_12(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:349: 	out[0] = veca[0]+vecb[0]; */
	fstps	(%eax)	# *out_13(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:350: 	out[1] = veca[1]+vecb[1]; */
	flds	4(%ecx)	# MEM[(vec_t *)veca_11(D) + 4B]
	fadds	4(%edx)	# MEM[(vec_t *)vecb_12(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:350: 	out[1] = veca[1]+vecb[1]; */
	fstps	4(%eax)	# MEM[(vec_t *)out_13(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:351: 	out[2] = veca[2]+vecb[2]; */
	flds	8(%ecx)	# MEM[(vec_t *)veca_11(D) + 8B]
	fadds	8(%edx)	# MEM[(vec_t *)vecb_12(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:351: 	out[2] = veca[2]+vecb[2]; */
	fstps	8(%eax)	# MEM[(vec_t *)out_13(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:352: } */
	ret
	.p2align 3

.text
.p2align 3
/* _VectorCopy: Copy the original three vector words with the same sequential alias behavior.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	__VectorCopy
__VectorCopy:
	movl	4(%esp), %edx	# in, in
	movl	8(%esp), %eax	# out, out
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:356: 	out[0] = in[0]; */
	flds	(%edx)	# *in_5(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:356: 	out[0] = in[0]; */
	fstps	(%eax)	# *out_6(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:357: 	out[1] = in[1]; */
	flds	4(%edx)	# MEM[(vec_t *)in_5(D) + 4B]
	fstps	4(%eax)	# MEM[(vec_t *)out_6(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:358: 	out[2] = in[2]; */
	flds	8(%edx)	# MEM[(vec_t *)in_5(D) + 8B]
	fstps	8(%eax)	# MEM[(vec_t *)out_6(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:359: } */
	ret
	.p2align 3

.text
.p2align 3
/* CrossProduct: Preserve the original sequential cross-product expressions and stores.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	_CrossProduct
_CrossProduct:
	movl	4(%esp), %edx	# v1, v1
	movl	8(%esp), %eax	# v2, v2
	movl	12(%esp), %ecx	# cross, cross
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:363: 	cross[0] = v1[1]*v2[2] - v1[2]*v2[1]; */
	flds	4(%edx)	# MEM[(vec_t *)v1_22(D) + 4B]
	fmuls	8(%eax)	# MEM[(vec_t *)v2_24(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:363: 	cross[0] = v1[1]*v2[2] - v1[2]*v2[1]; */
	flds	8(%edx)	# MEM[(vec_t *)v1_22(D) + 8B]
	fmuls	4(%eax)	# MEM[(vec_t *)v2_24(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:363: 	cross[0] = v1[1]*v2[2] - v1[2]*v2[1]; */
	fsubrp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:363: 	cross[0] = v1[1]*v2[2] - v1[2]*v2[1]; */
	fstps	(%ecx)	# *cross_25(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:364: 	cross[1] = v1[2]*v2[0] - v1[0]*v2[2]; */
	flds	8(%edx)	# MEM[(vec_t *)v1_22(D) + 8B]
	fmuls	(%eax)	# *v2_24(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:364: 	cross[1] = v1[2]*v2[0] - v1[0]*v2[2]; */
	flds	(%edx)	# *v1_22(D)
	fmuls	8(%eax)	# MEM[(vec_t *)v2_24(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:364: 	cross[1] = v1[2]*v2[0] - v1[0]*v2[2]; */
	fsubrp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:364: 	cross[1] = v1[2]*v2[0] - v1[0]*v2[2]; */
	fstps	4(%ecx)	# MEM[(vec_t *)cross_25(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:365: 	cross[2] = v1[0]*v2[1] - v1[1]*v2[0]; */
	flds	(%edx)	# *v1_22(D)
	fmuls	4(%eax)	# MEM[(vec_t *)v2_24(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:365: 	cross[2] = v1[0]*v2[1] - v1[1]*v2[0]; */
	flds	4(%edx)	# MEM[(vec_t *)v1_22(D) + 4B]
	fmuls	(%eax)	# *v2_24(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:365: 	cross[2] = v1[0]*v2[1] - v1[1]*v2[0]; */
	fsubrp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:365: 	cross[2] = v1[0]*v2[1] - v1[1]*v2[0]; */
	fstps	8(%ecx)	# MEM[(vec_t *)cross_25(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:366: } */
	ret
	.p2align 3

.text
.p2align 3
/* Length: Accumulate squared components from zero, apply square root and return the reference float.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	_Length
_Length:
	movl	4(%esp), %eax	# v, v
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:377: 		length += v[i]*v[i]; */
	flds	(%eax)	# *v_13(D)
	flds	4(%eax)	# MEM[(vec_t *)v_13(D) + 4B]
	flds	8(%eax)	# MEM[(vec_t *)v_13(D) + 8B]
	fxch	%st(2)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:377: 		length += v[i]*v[i]; */
	fmul	%st(0), %st	#,
	fxch	%st(1)		#
	fmul	%st(0), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:377: 		length += v[i]*v[i]; */
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:377: 		length += v[i]*v[i]; */
	fmul	%st(0), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:377: 		length += v[i]*v[i]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:378: 	length = sqrt (length);		// FIXME */
	fsqrt
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:381: } */
	ret
	.p2align 3

.text
.p2align 3
/* VectorInverse: Negate the three components with the original floating store behavior.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	_VectorInverse
_VectorInverse:
	movl	4(%esp), %eax	# v, v
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:411: 	v[0] = -v[0]; */
	flds	(%eax)	# *v_8(D)
	fchs
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:411: 	v[0] = -v[0]; */
	fstps	(%eax)	# *v_8(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:412: 	v[1] = -v[1]; */
	flds	4(%eax)	# MEM[(vec_t *)v_8(D) + 4B]
	fchs
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:412: 	v[1] = -v[1]; */
	fstps	4(%eax)	# MEM[(vec_t *)v_8(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:413: 	v[2] = -v[2]; */
	flds	8(%eax)	# MEM[(vec_t *)v_8(D) + 8B]
	fchs
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:413: 	v[2] = -v[2]; */
	fstps	8(%eax)	# MEM[(vec_t *)v_8(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:414: } */
	ret
	.p2align 3

.text
.p2align 3
/* VectorScale: Scale and store the three components with the reference alias behavior.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	_VectorScale
_VectorScale:
	movl	4(%esp), %edx	# in, in
	flds	8(%esp)	# scale
	movl	12(%esp), %eax	# out, out
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:418: 	out[0] = in[0]*scale; */
	flds	(%edx)	# *in_8(D)
	fmul	%st(1), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:418: 	out[0] = in[0]*scale; */
	fstps	(%eax)	# *out_10(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:419: 	out[1] = in[1]*scale; */
	flds	4(%edx)	# MEM[(vec_t *)in_8(D) + 4B]
	fmul	%st(1), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:419: 	out[1] = in[1]*scale; */
	fstps	4(%eax)	# MEM[(vec_t *)out_10(D) + 4B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:420: 	out[2] = in[2]*scale; */
	fmuls	8(%edx)	# MEM[(vec_t *)in_8(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:420: 	out[2] = in[2]*scale; */
	fstps	8(%eax)	# MEM[(vec_t *)out_10(D) + 8B]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:421: } */
	ret
	.p2align 3

.text
.p2align 3
/* Q_log2: Count positive-value right shifts; zero returns zero.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	_Q_log2
_Q_log2:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:427: 	while (val>>=1) */
	movl	4(%esp), %eax	# val, val
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:426: 	int answer=0; */
	xorl	%edx, %edx	# <retval>
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:427: 	while (val>>=1) */
	sarl	$1, %eax	#, val
	je	L44	#,
	.p2align 3
	.p2align 3
L46:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:428: 		answer++; */
	incl	%edx	# <retval>
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:427: 	while (val>>=1) */
	sarl	$1, %eax	#, val
	jne	L46	#,
L44:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:430: } */
	movl	%edx, %eax	# <retval>,
	ret
	.p2align 3

.text
.p2align 3
/* R_ConcatRotations: Compose the two 3x3 matrices with the exact evaluation and sequential output stores.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	_R_ConcatRotations
_R_ConcatRotations:
	movl	4(%esp), %edx	# in1, in1
	movl	8(%esp), %eax	# in2, in2
	movl	12(%esp), %ecx	# out, out
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:440: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	flds	(%edx)	# (*in1_101(D))[0]
	fmuls	(%eax)	# (*in2_102(D))[0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:440: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	flds	4(%edx)	# (*in1_101(D))[1]
	fmuls	12(%eax)	# MEM[(float[3] *)in2_102(D) + 12B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:440: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:441: 				in1[0][2] * in2[2][0]; */
	flds	8(%edx)	# (*in1_101(D))[2]
	fmuls	24(%eax)	# MEM[(float[3] *)in2_102(D) + 24B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:440: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:440: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	fstps	(%ecx)	# (*out_103(D))[0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:442: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	flds	(%edx)	# (*in1_101(D))[0]
	fmuls	4(%eax)	# (*in2_102(D))[1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:442: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	flds	4(%edx)	# (*in1_101(D))[1]
	fmuls	16(%eax)	# MEM[(float[3] *)in2_102(D) + 12B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:442: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:443: 				in1[0][2] * in2[2][1]; */
	flds	8(%edx)	# (*in1_101(D))[2]
	fmuls	28(%eax)	# MEM[(float[3] *)in2_102(D) + 24B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:442: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:442: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	fstps	4(%ecx)	# (*out_103(D))[1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:444: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	flds	(%edx)	# (*in1_101(D))[0]
	fmuls	8(%eax)	# (*in2_102(D))[2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:444: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	flds	4(%edx)	# (*in1_101(D))[1]
	fmuls	20(%eax)	# MEM[(float[3] *)in2_102(D) + 12B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:444: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:445: 				in1[0][2] * in2[2][2]; */
	flds	8(%edx)	# (*in1_101(D))[2]
	fmuls	32(%eax)	# MEM[(float[3] *)in2_102(D) + 24B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:444: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:444: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	fstps	8(%ecx)	# (*out_103(D))[2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:446: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	flds	12(%edx)	# MEM[(float[3] *)in1_101(D) + 12B][0]
	fmuls	(%eax)	# (*in2_102(D))[0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:446: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	flds	16(%edx)	# MEM[(float[3] *)in1_101(D) + 12B][1]
	fmuls	12(%eax)	# MEM[(float[3] *)in2_102(D) + 12B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:446: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:447: 				in1[1][2] * in2[2][0]; */
	flds	20(%edx)	# MEM[(float[3] *)in1_101(D) + 12B][2]
	fmuls	24(%eax)	# MEM[(float[3] *)in2_102(D) + 24B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:446: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:446: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	fstps	12(%ecx)	# MEM[(float[3] *)out_103(D) + 12B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:448: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	flds	12(%edx)	# MEM[(float[3] *)in1_101(D) + 12B][0]
	fmuls	4(%eax)	# (*in2_102(D))[1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:448: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	flds	16(%edx)	# MEM[(float[3] *)in1_101(D) + 12B][1]
	fmuls	16(%eax)	# MEM[(float[3] *)in2_102(D) + 12B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:448: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:449: 				in1[1][2] * in2[2][1]; */
	flds	20(%edx)	# MEM[(float[3] *)in1_101(D) + 12B][2]
	fmuls	28(%eax)	# MEM[(float[3] *)in2_102(D) + 24B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:448: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:448: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	fstps	16(%ecx)	# MEM[(float[3] *)out_103(D) + 12B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:450: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	flds	12(%edx)	# MEM[(float[3] *)in1_101(D) + 12B][0]
	fmuls	8(%eax)	# (*in2_102(D))[2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:450: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	flds	16(%edx)	# MEM[(float[3] *)in1_101(D) + 12B][1]
	fmuls	20(%eax)	# MEM[(float[3] *)in2_102(D) + 12B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:450: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:451: 				in1[1][2] * in2[2][2]; */
	flds	20(%edx)	# MEM[(float[3] *)in1_101(D) + 12B][2]
	fmuls	32(%eax)	# MEM[(float[3] *)in2_102(D) + 24B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:450: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:450: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	fstps	20(%ecx)	# MEM[(float[3] *)out_103(D) + 12B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:452: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	flds	24(%edx)	# MEM[(float[3] *)in1_101(D) + 24B][0]
	fmuls	(%eax)	# (*in2_102(D))[0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:452: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	flds	28(%edx)	# MEM[(float[3] *)in1_101(D) + 24B][1]
	fmuls	12(%eax)	# MEM[(float[3] *)in2_102(D) + 12B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:452: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:453: 				in1[2][2] * in2[2][0]; */
	flds	32(%edx)	# MEM[(float[3] *)in1_101(D) + 24B][2]
	fmuls	24(%eax)	# MEM[(float[3] *)in2_102(D) + 24B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:452: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:452: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	fstps	24(%ecx)	# MEM[(float[3] *)out_103(D) + 24B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:454: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	flds	24(%edx)	# MEM[(float[3] *)in1_101(D) + 24B][0]
	fmuls	4(%eax)	# (*in2_102(D))[1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:454: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	flds	28(%edx)	# MEM[(float[3] *)in1_101(D) + 24B][1]
	fmuls	16(%eax)	# MEM[(float[3] *)in2_102(D) + 12B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:454: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:455: 				in1[2][2] * in2[2][1]; */
	flds	32(%edx)	# MEM[(float[3] *)in1_101(D) + 24B][2]
	fmuls	28(%eax)	# MEM[(float[3] *)in2_102(D) + 24B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:454: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:454: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	fstps	28(%ecx)	# MEM[(float[3] *)out_103(D) + 24B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:456: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	flds	24(%edx)	# MEM[(float[3] *)in1_101(D) + 24B][0]
	fmuls	8(%eax)	# (*in2_102(D))[2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:456: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	flds	28(%edx)	# MEM[(float[3] *)in1_101(D) + 24B][1]
	fmuls	20(%eax)	# MEM[(float[3] *)in2_102(D) + 12B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:456: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:457: 				in1[2][2] * in2[2][2]; */
	flds	32(%edx)	# MEM[(float[3] *)in1_101(D) + 24B][2]
	fmuls	32(%eax)	# MEM[(float[3] *)in2_102(D) + 24B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:456: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:456: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	fstps	32(%ecx)	# MEM[(float[3] *)out_103(D) + 24B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:458: } */
	ret
	.p2align 3

.text
.p2align 3
/* R_ConcatTransforms: Compose the 3x4 affine matrices, including the original translation additions.
 * Preserved registers used: none.
 * Stack reservations, including call areas: none bytes. */
	.globl	_R_ConcatTransforms
_R_ConcatTransforms:
	movl	4(%esp), %eax	# in1, in1
	movl	8(%esp), %edx	# in2, in2
	movl	12(%esp), %ecx	# out, out
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:468: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	flds	(%eax)	# (*in1_140(D))[0]
	fmuls	(%edx)	# (*in2_141(D))[0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:468: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	flds	4(%eax)	# (*in1_140(D))[1]
	fmuls	16(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:468: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:469: 				in1[0][2] * in2[2][0]; */
	flds	8(%eax)	# (*in1_140(D))[2]
	fmuls	32(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:468: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:468: 	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] + */
	fstps	(%ecx)	# (*out_142(D))[0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:470: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	flds	(%eax)	# (*in1_140(D))[0]
	fmuls	4(%edx)	# (*in2_141(D))[1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:470: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	flds	4(%eax)	# (*in1_140(D))[1]
	fmuls	20(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:470: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:471: 				in1[0][2] * in2[2][1]; */
	flds	8(%eax)	# (*in1_140(D))[2]
	fmuls	36(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:470: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:470: 	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] + */
	fstps	4(%ecx)	# (*out_142(D))[1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:472: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	flds	(%eax)	# (*in1_140(D))[0]
	fmuls	8(%edx)	# (*in2_141(D))[2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:472: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	flds	4(%eax)	# (*in1_140(D))[1]
	fmuls	24(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:472: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:473: 				in1[0][2] * in2[2][2]; */
	flds	8(%eax)	# (*in1_140(D))[2]
	fmuls	40(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:472: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:472: 	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] + */
	fstps	8(%ecx)	# (*out_142(D))[2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:474: 	out[0][3] = in1[0][0] * in2[0][3] + in1[0][1] * in2[1][3] + */
	flds	(%eax)	# (*in1_140(D))[0]
	fmuls	12(%edx)	# (*in2_141(D))[3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:474: 	out[0][3] = in1[0][0] * in2[0][3] + in1[0][1] * in2[1][3] + */
	flds	4(%eax)	# (*in1_140(D))[1]
	fmuls	28(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:474: 	out[0][3] = in1[0][0] * in2[0][3] + in1[0][1] * in2[1][3] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:475: 				in1[0][2] * in2[2][3] + in1[0][3]; */
	fadds	12(%eax)	# (*in1_140(D))[3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:475: 				in1[0][2] * in2[2][3] + in1[0][3]; */
	flds	8(%eax)	# (*in1_140(D))[2]
	fmuls	44(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:475: 				in1[0][2] * in2[2][3] + in1[0][3]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:474: 	out[0][3] = in1[0][0] * in2[0][3] + in1[0][1] * in2[1][3] + */
	fstps	12(%ecx)	# (*out_142(D))[3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:476: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	flds	16(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][0]
	fmuls	(%edx)	# (*in2_141(D))[0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:476: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	flds	20(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][1]
	fmuls	16(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:476: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:477: 				in1[1][2] * in2[2][0]; */
	flds	24(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][2]
	fmuls	32(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:476: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:476: 	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] + */
	fstps	16(%ecx)	# MEM[(float[4] *)out_142(D) + 16B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:478: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	flds	16(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][0]
	fmuls	4(%edx)	# (*in2_141(D))[1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:478: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	flds	20(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][1]
	fmuls	20(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:478: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:479: 				in1[1][2] * in2[2][1]; */
	flds	24(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][2]
	fmuls	36(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:478: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:478: 	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] + */
	fstps	20(%ecx)	# MEM[(float[4] *)out_142(D) + 16B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:480: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	flds	16(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][0]
	fmuls	8(%edx)	# (*in2_141(D))[2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:480: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	flds	20(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][1]
	fmuls	24(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:480: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:481: 				in1[1][2] * in2[2][2]; */
	flds	24(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][2]
	fmuls	40(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:480: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:480: 	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] + */
	fstps	24(%ecx)	# MEM[(float[4] *)out_142(D) + 16B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:482: 	out[1][3] = in1[1][0] * in2[0][3] + in1[1][1] * in2[1][3] + */
	flds	16(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][0]
	fmuls	12(%edx)	# (*in2_141(D))[3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:482: 	out[1][3] = in1[1][0] * in2[0][3] + in1[1][1] * in2[1][3] + */
	flds	20(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][1]
	fmuls	28(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:482: 	out[1][3] = in1[1][0] * in2[0][3] + in1[1][1] * in2[1][3] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:483: 				in1[1][2] * in2[2][3] + in1[1][3]; */
	fadds	28(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:483: 				in1[1][2] * in2[2][3] + in1[1][3]; */
	flds	24(%eax)	# MEM[(float[4] *)in1_140(D) + 16B][2]
	fmuls	44(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:483: 				in1[1][2] * in2[2][3] + in1[1][3]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:482: 	out[1][3] = in1[1][0] * in2[0][3] + in1[1][1] * in2[1][3] + */
	fstps	28(%ecx)	# MEM[(float[4] *)out_142(D) + 16B][3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:484: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	flds	32(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][0]
	fmuls	(%edx)	# (*in2_141(D))[0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:484: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	flds	36(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][1]
	fmuls	16(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:484: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:485: 				in1[2][2] * in2[2][0]; */
	flds	40(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][2]
	fmuls	32(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:484: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:484: 	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] + */
	fstps	32(%ecx)	# MEM[(float[4] *)out_142(D) + 32B][0]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:486: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	flds	32(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][0]
	fmuls	4(%edx)	# (*in2_141(D))[1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:486: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	flds	36(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][1]
	fmuls	20(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:486: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:487: 				in1[2][2] * in2[2][1]; */
	flds	40(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][2]
	fmuls	36(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:486: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:486: 	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] + */
	fstps	36(%ecx)	# MEM[(float[4] *)out_142(D) + 32B][1]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:488: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	flds	32(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][0]
	fmuls	8(%edx)	# (*in2_141(D))[2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:488: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	flds	36(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][1]
	fmuls	24(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:488: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:489: 				in1[2][2] * in2[2][2]; */
	flds	40(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][2]
	fmuls	40(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:488: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:488: 	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] + */
	fstps	40(%ecx)	# MEM[(float[4] *)out_142(D) + 32B][2]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:490: 	out[2][3] = in1[2][0] * in2[0][3] + in1[2][1] * in2[1][3] + */
	flds	32(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][0]
	fmuls	12(%edx)	# (*in2_141(D))[3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:490: 	out[2][3] = in1[2][0] * in2[0][3] + in1[2][1] * in2[1][3] + */
	flds	36(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][1]
	fmuls	28(%edx)	# MEM[(float[4] *)in2_141(D) + 16B][3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:490: 	out[2][3] = in1[2][0] * in2[0][3] + in1[2][1] * in2[1][3] + */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:491: 				in1[2][2] * in2[2][3] + in1[2][3]; */
	fadds	44(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:491: 				in1[2][2] * in2[2][3] + in1[2][3]; */
	flds	40(%eax)	# MEM[(float[4] *)in1_140(D) + 32B][2]
	fmuls	44(%edx)	# MEM[(float[4] *)in2_141(D) + 32B][3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:491: 				in1[2][2] * in2[2][3] + in1[2][3]; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:490: 	out[2][3] = in1[2][0] * in2[0][3] + in1[2][1] * in2[1][3] + */
	fstps	44(%ecx)	# MEM[(float[4] *)out_142(D) + 32B][3]
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:492: } */
	ret
	.p2align 2

.text
.p2align 3
/* FloorDivMod: Preserve floor-based positive/negative quotient and remainder, truncation and error checks.
 * Preserved registers used: none.
 * Stack reservations, including call areas: 44, 12 bytes. */
	.globl	_FloorDivMod
_FloorDivMod:
	subl	$44, %esp	#,
	fldl	48(%esp)	# numer
	fldl	56(%esp)	# denom
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:512: 	if (denom <= 0.0) */
	ftst
	fnstsw	%ax	# tmp101
	testb	$69, %ah	#, tmp101
	jne	L64	#,
	fxch	%st(1)		#
L54:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:520: 	if (numer >= 0.0) */
	ftst
	fnstsw	%ax	# tmp102
	testb	$5, %ah	#, tmp102
	jne	L62	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:523: 		x = floor(numer / denom); */
	fld	%st(0)	#
	fdiv	%st(2), %st	#,
	fnstcw	30(%esp)	#
	movw	30(%esp), %dx	#, tmp120
	andb	$-13, %dh	#, tmp120
	orb	$4, %dh	#, tmp120
	movw	%dx, 26(%esp)	# tmp120,
	fldcw	26(%esp)	#
	frndint
	fldcw	30(%esp)	#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:524: 		q = (int)x; */
	movw	30(%esp), %cx	#, tmp118
	orb	$12, %ch	#, tmp118
	movw	%cx, 28(%esp)	# tmp118,
	fldcw	28(%esp)		#
	fistl	8(%esp)	# %sfp
	fldcw	30(%esp)		#
	movl	8(%esp), %edx	# %sfp, q
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:525: 		r = (int)floor(numer - (x * denom)); */
	fmulp	%st, %st(2)	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:525: 		r = (int)floor(numer - (x * denom)); */
	fsubp	%st, %st(1)	#,
	fldcw	26(%esp)	#
	frndint
	fldcw	30(%esp)	#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:525: 		r = (int)floor(numer - (x * denom)); */
	fldcw	28(%esp)		#
	fistpl	8(%esp)	# %sfp
	fldcw	30(%esp)		#
	movl	8(%esp), %eax	# %sfp, r
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:542: 	*quotient = q; */
	movl	64(%esp), %ecx	# quotient, quotient
	movl	%edx, (%ecx)	# q, *quotient_26(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:543: 	*rem = r; */
	movl	68(%esp), %edx	# rem, rem
	movl	%eax, (%edx)	# r, *rem_28(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:544: } */
	addl	$44, %esp	#,
	ret
	.p2align 4
	.p2align 3
L62:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:532: 		x = floor(-numer / denom); */
	fchs
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:532: 		x = floor(-numer / denom); */
	fld	%st(0)	#
	fdiv	%st(2), %st	#,
	fnstcw	30(%esp)	#
	movw	30(%esp), %dx	#, tmp121
	andb	$-13, %dh	#, tmp121
	orb	$4, %dh	#, tmp121
	movw	%dx, 26(%esp)	# tmp121,
	fldcw	26(%esp)	#
	frndint
	fldcw	30(%esp)	#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:533: 		q = -(int)x; */
	movw	30(%esp), %cx	#, tmp119
	orb	$12, %ch	#, tmp119
	movw	%cx, 28(%esp)	# tmp119,
	fldcw	28(%esp)		#
	fistl	8(%esp)	# %sfp
	fldcw	30(%esp)		#
	movl	8(%esp), %edx	# %sfp, _7
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:534: 		r = (int)floor(-numer - (x * denom)); */
	fmul	%st(2), %st	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:534: 		r = (int)floor(-numer - (x * denom)); */
	fsubrp	%st, %st(1)	#,
	fldcw	26(%esp)	#
	frndint
	fldcw	30(%esp)	#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:534: 		r = (int)floor(-numer - (x * denom)); */
	fldcw	28(%esp)		#
	fistpl	8(%esp)	# %sfp
	fldcw	30(%esp)		#
	movl	8(%esp), %eax	# %sfp, r
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:535: 		if (r != 0) */
	testl	%eax, %eax	# r
	jne	L59	#,
	fstp	%st(0)		#
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:533: 		q = -(int)x; */
	negl	%edx	# q
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:542: 	*quotient = q; */
	movl	64(%esp), %ecx	# quotient, quotient
	movl	%edx, (%ecx)	# q, *quotient_26(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:543: 	*rem = r; */
	movl	68(%esp), %edx	# rem, rem
	movl	%eax, (%edx)	# r, *rem_28(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:544: } */
	addl	$44, %esp	#,
	ret
	.p2align 4
	.p2align 3
L64:
	fxch	%st(1)		#
	fstpl	16(%esp)	# %sfp
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:513: 		Sys_Error ("FloorDivMod: bad denominator %d\n", denom); */
	subl	$12, %esp	#,
	fstl	(%esp)	#
	fstpl	20(%esp)	# %sfp
	pushl	$LC7	#
	call	_Sys_Error	#
	addl	$16, %esp	#,
	fldl	8(%esp)	# %sfp
	fldl	16(%esp)	# %sfp
	jmp	L54	#
	.p2align 4
	.p2align 3
L59:
	notl	%edx	# q
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:538: 			r = (int)denom - r; */
	fldcw	28(%esp)		#
	fistpl	8(%esp)	# %sfp
	fldcw	30(%esp)		#
	movl	8(%esp), %ecx	# %sfp, tmp117
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:538: 			r = (int)denom - r; */
	subl	%eax, %ecx	# r, tmp117
	movl	%ecx, %eax	# tmp117, r
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:542: 	*quotient = q; */
	movl	64(%esp), %ecx	# quotient, quotient
	movl	%edx, (%ecx)	# q, *quotient_26(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:543: 	*rem = r; */
	movl	68(%esp), %edx	# rem, rem
	movl	%eax, (%edx)	# r, *rem_28(D)
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:544: } */
	addl	$44, %esp	#,
	ret
	.p2align 3

.text
.p2align 3
/* GreatestCommonDivisor: Preserve the nonnegative recursive Euclidean algorithm and its zero-argument results.
 * Preserved registers used: %ebx.
 * Stack reservations, including call areas: none bytes. */
	.globl	_GreatestCommonDivisor
_GreatestCommonDivisor:
	pushl	%ebx	#
	movl	8(%esp), %ebx	# i1, i1
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:553: { */
	movl	12(%esp), %ecx	# i2, <retval>
	.p2align 3
	.p2align 3
L70:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:554: 	if (i1 > i2) */
	cmpl	%ecx, %ebx	# <retval>, i1
	jg	L77	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:562: 		if (i1 == 0) */
	testl	%ebx, %ebx	# i1
	jne	L78	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:566: } */
	movl	%ecx, %eax	# <retval>,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L77:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:556: 		if (i2 == 0) */
	testl	%ecx, %ecx	# <retval>
	je	L71	#,
L79:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:558: 		return GreatestCommonDivisor (i2, i1 % i2); */
	movl	%ebx, %eax	# i1, i1
	cltd
	idivl	%ecx	# <retval>
	movl	%edx, %eax	# tmp86, _4
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:554: 	if (i1 > i2) */
	movl	%ecx, %ebx	# <retval>, i1
	cmpl	%ecx, %edx	# <retval>, _4
	jge	L69	#,
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:558: 		return GreatestCommonDivisor (i2, i1 % i2); */
	movl	%edx, %ecx	# tmp86, <retval>
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:556: 		if (i2 == 0) */
	testl	%ecx, %ecx	# <retval>
	jne	L79	#,
L71:
	movl	%ebx, %ecx	# i1, <retval>
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:566: } */
	movl	%ecx, %eax	# <retval>,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L78:
	movl	%ecx, %eax	# <retval>, _4
L69:
/* workspace\quake\out\math-closure-worktree-20261007\out\math-closure-instruction-reference-20261007\mathlib-reference.c:564: 		return GreatestCommonDivisor (i1, i2 % i1); */
	cltd
	idivl	%ebx	# i1
	movl	%edx, %ecx	# <retval>, <retval>
	jmp	L70	#

.data
/* Original typed constants: data, never executable instruction bytes. */
.p2align 3
LC0:
	.long	1065353216
	.p2align 3
.p2align 3
LC3:
	.long	381774871
	.long	1080476012
	.p2align 2
.p2align 3
LC4:
	.long	1001652224
	.p2align 3
.p2align 3
LC5:
	.ascii "BoxOnPlaneSide:  Bad signbits\0"
	.p2align 3
.p2align 3
LC6:
	.long	-1571644103
	.long	1066524486
.p2align 3
LC7:
	.ascii "FloorDivMod: bad denominator %d\12\0"
	.p2align 3
#endif
