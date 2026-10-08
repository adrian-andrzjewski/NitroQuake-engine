/* Alias transform algorithm; profile. Pinned source SHA256
 * BE6A06B767651363BD586FFF62BBA467F333D87820C13E7D66BF9D5A7B8FC979
 * One-time original schedule import; normal builds assemble this maintained file.
 * Cdecl, except R_AliasDrawModel receives its light pointer in EAX (regparm 1).
 * EBX/ESI/EDI/EBP are callee-owned; EAX/ECX/EDX and arithmetic flags are caller-owned.
 * Integer stores, x87 order, truncating CW changes and rounding stores are parity contracts. */

.text
.p2align 3
/* R_AliasSetUpTransform: Compose entity scale/origin, angle vectors and the cached camera matrix, retaining the original 31-bit projection scaling.
 * Saved callee registers used: %ebx.
 * Stack reservations: 120 bytes; all return paths restore ESP. */
	.globl	_R_AliasSetUpTransform
_R_AliasSetUpTransform:
	pushl	%ebx	#
	subl	$120, %esp	#,
/* original r_alias.c:575: 	angles[ROLL] = currententity->angles[ROLL]; */
	movl	_currententity, %eax	# currententity, currententity.40_1
/* original r_alias.c:575: 	angles[ROLL] = currententity->angles[ROLL]; */
	flds	128(%eax)	# currententity.40_1->angles[2]
	fstps	12(%esp)	# angles[2]
/* original r_alias.c:576: 	angles[PITCH] = -currententity->angles[PITCH]; */
	flds	120(%eax)	# currententity.40_1->angles[0]
	fchs
/* original r_alias.c:576: 	angles[PITCH] = -currententity->angles[PITCH]; */
	fstps	4(%esp)	# angles[0]
/* original r_alias.c:577: 	angles[YAW] = currententity->angles[YAW]; */
	flds	124(%eax)	# currententity.40_1->angles[1]
	fstps	8(%esp)	# angles[1]
/* original r_alias.c:578: 	AngleVectors (angles, alias_forward, alias_right, alias_up); */
	pushl	$_aliascontrol_alias_up	#
	pushl	$_aliascontrol_alias_right	#
	pushl	$_aliascontrol_alias_forward	#
	leal	16(%esp), %edx	#, tmp163
	pushl	%edx	# tmp163
	call	_AngleVectors	#
/* original r_alias.c:580: 	tmatrix[0][0] = pmdl->scale[0]; */
	movl	_pmdl, %ecx	# pmdl, pmdl.43_6
/* original r_alias.c:580: 	tmatrix[0][0] = pmdl->scale[0]; */
	flds	8(%ecx)	# pmdl.43_6->scale[0]
	fstps	_aliascontrol_tmatrix	# tmatrix[0][0]
/* original r_alias.c:581: 	tmatrix[1][1] = pmdl->scale[1]; */
	flds	12(%ecx)	# pmdl.43_6->scale[1]
/* original r_alias.c:581: 	tmatrix[1][1] = pmdl->scale[1]; */
	fstps	_aliascontrol_tmatrix+20	# tmatrix[1][1]
/* original r_alias.c:582: 	tmatrix[2][2] = pmdl->scale[2]; */
	flds	16(%ecx)	# pmdl.43_6->scale[2]
/* original r_alias.c:582: 	tmatrix[2][2] = pmdl->scale[2]; */
	fstps	_aliascontrol_tmatrix+40	# tmatrix[2][2]
/* original r_alias.c:584: 	tmatrix[0][3] = pmdl->scale_origin[0]; */
	flds	20(%ecx)	# pmdl.43_6->scale_origin[0]
	fstps	_aliascontrol_tmatrix+12	# tmatrix[0][3]
/* original r_alias.c:585: 	tmatrix[1][3] = pmdl->scale_origin[1]; */
	flds	24(%ecx)	# pmdl.43_6->scale_origin[1]
/* original r_alias.c:585: 	tmatrix[1][3] = pmdl->scale_origin[1]; */
	fstps	_aliascontrol_tmatrix+28	# tmatrix[1][3]
/* original r_alias.c:586: 	tmatrix[2][3] = pmdl->scale_origin[2]; */
	flds	28(%ecx)	# pmdl.43_6->scale_origin[2]
/* original r_alias.c:586: 	tmatrix[2][3] = pmdl->scale_origin[2]; */
	fstps	_aliascontrol_tmatrix+44	# tmatrix[2][3]
/* original r_alias.c:592: 		t2matrix[i][0] = alias_forward[i]; */
	flds	_aliascontrol_alias_forward	# alias_forward[0]
	fstps	80(%esp)	# t2matrix[0][0]
/* original r_alias.c:593: 		t2matrix[i][1] = -alias_right[i]; */
	flds	_aliascontrol_alias_right	# alias_right[0]
	fchs
/* original r_alias.c:593: 		t2matrix[i][1] = -alias_right[i]; */
	fstps	84(%esp)	# t2matrix[0][1]
/* original r_alias.c:594: 		t2matrix[i][2] = alias_up[i]; */
	flds	_aliascontrol_alias_up	# alias_up[0]
	fstps	88(%esp)	# t2matrix[0][2]
/* original r_alias.c:592: 		t2matrix[i][0] = alias_forward[i]; */
	flds	_aliascontrol_alias_forward+4	# alias_forward[1]
	fstps	96(%esp)	# t2matrix[1][0]
/* original r_alias.c:593: 		t2matrix[i][1] = -alias_right[i]; */
	flds	_aliascontrol_alias_right+4	# alias_right[1]
	fchs
/* original r_alias.c:593: 		t2matrix[i][1] = -alias_right[i]; */
	fstps	100(%esp)	# t2matrix[1][1]
/* original r_alias.c:594: 		t2matrix[i][2] = alias_up[i]; */
	flds	_aliascontrol_alias_up+4	# alias_up[1]
	fstps	104(%esp)	# t2matrix[1][2]
/* original r_alias.c:592: 		t2matrix[i][0] = alias_forward[i]; */
	flds	_aliascontrol_alias_forward+8	# alias_forward[2]
	fstps	112(%esp)	# t2matrix[2][0]
/* original r_alias.c:593: 		t2matrix[i][1] = -alias_right[i]; */
	flds	_aliascontrol_alias_right+8	# alias_right[2]
	fchs
/* original r_alias.c:593: 		t2matrix[i][1] = -alias_right[i]; */
	fstps	116(%esp)	# t2matrix[2][1]
/* original r_alias.c:594: 		t2matrix[i][2] = alias_up[i]; */
	flds	_aliascontrol_alias_up+8	# alias_up[2]
	fstps	120(%esp)	# t2matrix[2][2]
/* original r_alias.c:597: 	t2matrix[0][3] = -modelorg[0]; */
	flds	_modelorg	# modelorg[0]
	fchs
/* original r_alias.c:597: 	t2matrix[0][3] = -modelorg[0]; */
	fstps	92(%esp)	# t2matrix[0][3]
/* original r_alias.c:598: 	t2matrix[1][3] = -modelorg[1]; */
	flds	_modelorg+4	# modelorg[1]
	fchs
/* original r_alias.c:598: 	t2matrix[1][3] = -modelorg[1]; */
	fstps	108(%esp)	# t2matrix[1][3]
/* original r_alias.c:599: 	t2matrix[2][3] = -modelorg[2]; */
	flds	_modelorg+8	# modelorg[2]
	fchs
/* original r_alias.c:599: 	t2matrix[2][3] = -modelorg[2]; */
	fstps	124(%esp)	# t2matrix[2][3]
/* original r_alias.c:603: 	R_ConcatTransforms_asm486 (t2matrix, tmatrix, rotationmatrix); */
	addl	$12, %esp	#,
	leal	20(%esp), %ebx	#, tmp202
	pushl	%ebx	# tmp202
	pushl	$_aliascontrol_tmatrix	#
	leal	76(%esp), %eax	#, tmp203
	pushl	%eax	# tmp203
	call	_R_ConcatTransforms_asm486	#
/* original r_alias.c:618: 	R_ConcatTransforms_asm486 (alias_viewmatrix, rotationmatrix, aliastransform); */
	addl	$12, %esp	#,
	pushl	$_aliastransform	#
	pushl	%ebx	# tmp202
	pushl	$_aliascontrol_alias_viewmatrix	#
	call	_R_ConcatTransforms_asm486	#
/* original r_alias.c:628: 	if (trivial_accept) */
	addl	$16, %esp	#,
	movl	128(%esp), %edx	# trivial_accept,
	testl	%edx, %edx	#
	je	L33	#,
	flds	LC2	#
	fld	%st(0)	#
	fld	%st(0)	#
	fmuls	_aliasxscale	# aliasxscale
	fxch	%st(1)		#
	fmuls	_aliasyscale	# aliasyscale
/* original r_alias.c:632: 			aliastransform[0][i] *= aliasxscale * */
	fld	%st(1)	#
	fmuls	_aliastransform	# aliastransform[0][0]
	fstps	_aliastransform	# aliastransform[0][0]
/* original r_alias.c:634: 			aliastransform[1][i] *= aliasyscale * */
	fld	%st(0)	#
	fmuls	_aliastransform+16	# aliastransform[1][0]
	fstps	_aliastransform+16	# aliastransform[1][0]
/* original r_alias.c:636: 			aliastransform[2][i] *= 1.0 / ((float)0x8000 * 0x10000); */
	flds	_aliastransform+32	# aliastransform[2][0]
	fmul	%st(3), %st	#,
	fstps	_aliastransform+32	# aliastransform[2][0]
/* original r_alias.c:632: 			aliastransform[0][i] *= aliasxscale * */
	fld	%st(1)	#
	fmuls	_aliastransform+4	# aliastransform[0][1]
	fstps	_aliastransform+4	# aliastransform[0][1]
/* original r_alias.c:634: 			aliastransform[1][i] *= aliasyscale * */
	fld	%st(0)	#
	fmuls	_aliastransform+20	# aliastransform[1][1]
	fstps	_aliastransform+20	# aliastransform[1][1]
/* original r_alias.c:636: 			aliastransform[2][i] *= 1.0 / ((float)0x8000 * 0x10000); */
	flds	_aliastransform+36	# aliastransform[2][1]
	fmul	%st(3), %st	#,
	fstps	_aliastransform+36	# aliastransform[2][1]
/* original r_alias.c:632: 			aliastransform[0][i] *= aliasxscale * */
	fld	%st(1)	#
	fmuls	_aliastransform+8	# aliastransform[0][2]
	fstps	_aliastransform+8	# aliastransform[0][2]
/* original r_alias.c:634: 			aliastransform[1][i] *= aliasyscale * */
	fld	%st(0)	#
	fmuls	_aliastransform+24	# aliastransform[1][2]
	fstps	_aliastransform+24	# aliastransform[1][2]
/* original r_alias.c:636: 			aliastransform[2][i] *= 1.0 / ((float)0x8000 * 0x10000); */
	flds	_aliastransform+40	# aliastransform[2][2]
	fmul	%st(3), %st	#,
	fstps	_aliastransform+40	# aliastransform[2][2]
	fxch	%st(1)		#
/* original r_alias.c:632: 			aliastransform[0][i] *= aliasxscale * */
	fmuls	_aliastransform+12	# aliastransform[0][3]
	fstps	_aliastransform+12	# aliastransform[0][3]
/* original r_alias.c:634: 			aliastransform[1][i] *= aliasyscale * */
	fmuls	_aliastransform+28	# aliastransform[1][3]
	fstps	_aliastransform+28	# aliastransform[1][3]
/* original r_alias.c:636: 			aliastransform[2][i] *= 1.0 / ((float)0x8000 * 0x10000); */
	fmuls	_aliastransform+44	# aliastransform[2][3]
	fstps	_aliastransform+44	# aliastransform[2][3]
L33:
/* original r_alias.c:640: } */
	addl	$120, %esp	#,
	popl	%ebx	#
	ret

.text
.p2align 3
/* R_AliasProjectFinalVert: Compute reciprocal depth and the original screen/depth integer conversions without changing x87 stores.
 * Saved callee registers used: none.
 * Stack reservations: none bytes; all return paths restore ESP. */
	.globl	_R_AliasProjectFinalVert
_R_AliasProjectFinalVert:
	pushl	%eax	#
	movl	8(%esp), %eax	# fv, fv
	movl	12(%esp), %edx	# av, av
/* original r_alias.c:802: 	zi = 1.0 / av->fv[2]; */
	fld1
	fdivs	8(%edx)	# av_20(D)->fv[2]
/* original r_alias.c:804: 	fv->v[5] = zi * ziscale; */
	flds	_ziscale	# ziscale
	fmul	%st(1), %st	#,
/* original r_alias.c:804: 	fv->v[5] = zi * ziscale; */
	fnstcw	2(%esp)	#
	movw	2(%esp), %cx	#, tmp113
	orb	$12, %ch	#, tmp113
	movw	%cx, (%esp)	# tmp113,
	fldcw	(%esp)		#
	fistpl	20(%eax)	# fv_22(D)->v[5]
	fldcw	2(%esp)		#
/* original r_alias.c:806: 	fv->v[0] = (av->fv[0] * aliasxscale * zi) + aliasxcenter; */
	flds	(%edx)	# av_20(D)->fv[0]
	fmuls	_aliasxscale	# aliasxscale
/* original r_alias.c:806: 	fv->v[0] = (av->fv[0] * aliasxscale * zi) + aliasxcenter; */
	fmul	%st(1), %st	#,
/* original r_alias.c:806: 	fv->v[0] = (av->fv[0] * aliasxscale * zi) + aliasxcenter; */
	fadds	_aliasxcenter	# aliasxcenter
/* original r_alias.c:806: 	fv->v[0] = (av->fv[0] * aliasxscale * zi) + aliasxcenter; */
	fldcw	(%esp)		#
	fistpl	(%eax)	# fv_22(D)->v[0]
	fldcw	2(%esp)		#
/* original r_alias.c:807: 	fv->v[1] = (av->fv[1] * aliasyscale * zi) + aliasycenter; */
	flds	4(%edx)	# av_20(D)->fv[1]
	fmuls	_aliasyscale	# aliasyscale
/* original r_alias.c:807: 	fv->v[1] = (av->fv[1] * aliasyscale * zi) + aliasycenter; */
	fmulp	%st, %st(1)	#,
/* original r_alias.c:807: 	fv->v[1] = (av->fv[1] * aliasyscale * zi) + aliasycenter; */
	fadds	_aliasycenter	# aliasycenter
/* original r_alias.c:807: 	fv->v[1] = (av->fv[1] * aliasyscale * zi) + aliasycenter; */
	fldcw	(%esp)		#
	fistpl	4(%eax)	# fv_22(D)->v[1]
	fldcw	2(%esp)		#
/* original r_alias.c:808: } */
	popl	%edx	#
	ret
	.p2align 3
