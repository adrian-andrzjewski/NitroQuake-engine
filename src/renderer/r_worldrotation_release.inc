/* Original r_bsp.c world-control algorithms; release.
 * Source SHA256 91D1B008964C23C04F2EBBE21EBE34C1E64FF0C3593F71CBB38BD8CD456DB59D
 * Normal builds assemble this maintained schedule; no C renderer generation.
 * Cdecl. Preserve EBX/ESI/EDI/EBP, ESP, DF and x87 control/stack depth.
 * Matrix stores, linked-list updates and traversal order are parity contracts. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */

.text
.p2align 3
/* R_EntityRotate: Copy the original vector before applying the three stored matrix rows, including aliased input/output.
 * Callee registers used: none.
 * Stack reservations: none bytes; all returns restore ESP. */
	.globl	_R_EntityRotate
_R_EntityRotate:
	movl	4(%esp), %eax	# vec, vec
/* original r_bsp.c:204: 	VectorCopy (vec, tvec); */
	flds	(%eax)	# *vec_29(D)
	flds	4(%eax)	# MEM[(vec_t *)vec_29(D) + 4B]
	flds	8(%eax)	# MEM[(vec_t *)vec_29(D) + 8B]
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	flds	_entity_rotation	# entity_rotation[0][0]
	fmul	%st(3), %st	#,
	flds	_entity_rotation+4	# entity_rotation[0][1]
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
	flds	_entity_rotation+8	# entity_rotation[0][2]
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fstps	(%eax)	# *vec_29(D)
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	flds	_entity_rotation+12	# entity_rotation[1][0]
	fmul	%st(3), %st	#,
	flds	_entity_rotation+16	# entity_rotation[1][1]
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
	flds	_entity_rotation+20	# entity_rotation[1][2]
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	fstps	4(%eax)	# MEM[(vec_t *)vec_29(D) + 4B]
	fxch	%st(2)		#
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fmuls	_entity_rotation+24	# entity_rotation[2][0]
	fxch	%st(1)		#
	fmuls	_entity_rotation+28	# entity_rotation[2][1]
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
	fmuls	_entity_rotation+32	# entity_rotation[2][2]
	faddp	%st, %st(1)	#,
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fstps	8(%eax)	# MEM[(vec_t *)vec_29(D) + 8B]
/* original r_bsp.c:208: } */
	ret
	.p2align 3

.text
.p2align 3
/* R_RotateBmodel: Compose original yaw/pitch/roll matrices, rotate model/camera vectors and update the frustum in original x87 order.
 * Callee registers used: %ebx, %esi.
 * Stack reservations: 120 bytes; all returns restore ESP. */
	.globl	_R_RotateBmodel
_R_RotateBmodel:
	pushl	%esi	#
	pushl	%ebx	#
	subl	$120, %esp	#,
/* original r_bsp.c:226: 	angle = currententity->angles[YAW]; */
	movl	_currententity, %eax	# currententity, currententity.0_1
/* original r_bsp.c:227: 	angle = angle * M_PI*2 / 360; */
	fldl	wc_rotation_release_LC1	#
	fld	%st(0)	#
	fmuls	124(%eax)	# currententity.0_1->angles[1]
/* original r_bsp.c:228: 	s = sin(angle); */
	fld	%st(0)	#
	fsin
	fxch	%st(1)		#
/* original r_bsp.c:229: 	c = cos(angle); */
	fcos
/* original r_bsp.c:231: 	temp1[0][0] = c; */
	fsts	8(%esp)	# temp1[0][0]
	fxch	%st(1)		#
/* original r_bsp.c:232: 	temp1[0][1] = s; */
	fsts	12(%esp)	# temp1[0][1]
/* original r_bsp.c:233: 	temp1[0][2] = 0; */
	fldz
	fsts	16(%esp)	# temp1[0][2]
	fxch	%st(1)		#
/* original r_bsp.c:234: 	temp1[1][0] = -s; */
	fchs
/* original r_bsp.c:234: 	temp1[1][0] = -s; */
	fstps	20(%esp)	# temp1[1][0]
	fxch	%st(1)		#
/* original r_bsp.c:235: 	temp1[1][1] = c; */
	fstps	24(%esp)	# temp1[1][1]
/* original r_bsp.c:236: 	temp1[1][2] = 0; */
	fsts	28(%esp)	# temp1[1][2]
/* original r_bsp.c:237: 	temp1[2][0] = 0; */
	fsts	32(%esp)	# temp1[2][0]
/* original r_bsp.c:238: 	temp1[2][1] = 0; */
	fsts	36(%esp)	# temp1[2][1]
/* original r_bsp.c:239: 	temp1[2][2] = 1; */
	fld1
	fsts	40(%esp)	# temp1[2][2]
	fxch	%st(2)		#
/* original r_bsp.c:244: 	angle = angle * M_PI*2 / 360; */
	fmuls	120(%eax)	# currententity.0_1->angles[0]
/* original r_bsp.c:245: 	s = sin(angle); */
	fld	%st(0)	#
	fsin
	fxch	%st(1)		#
/* original r_bsp.c:246: 	c = cos(angle); */
	fcos
/* original r_bsp.c:248: 	temp2[0][0] = c; */
	fsts	44(%esp)	# temp2[0][0]
	fxch	%st(2)		#
/* original r_bsp.c:249: 	temp2[0][1] = 0; */
	fsts	48(%esp)	# temp2[0][1]
/* original r_bsp.c:250: 	temp2[0][2] = -s; */
	fld	%st(1)	#
	fchs
/* original r_bsp.c:250: 	temp2[0][2] = -s; */
	fstps	52(%esp)	# temp2[0][2]
/* original r_bsp.c:251: 	temp2[1][0] = 0; */
	fsts	56(%esp)	# temp2[1][0]
	fxch	%st(3)		#
/* original r_bsp.c:252: 	temp2[1][1] = 1; */
	fstps	60(%esp)	# temp2[1][1]
	fxch	%st(2)		#
/* original r_bsp.c:253: 	temp2[1][2] = 0; */
	fsts	64(%esp)	# temp2[1][2]
	fxch	%st(2)		#
/* original r_bsp.c:254: 	temp2[2][0] = s; */
	fstps	68(%esp)	# temp2[2][0]
	fxch	%st(1)		#
/* original r_bsp.c:255: 	temp2[2][1] = 0; */
	fstps	72(%esp)	# temp2[2][1]
/* original r_bsp.c:256: 	temp2[2][2] = c; */
	fstps	76(%esp)	# temp2[2][2]
/* original r_bsp.c:258: 	R_ConcatRotations (temp2, temp1, temp3); */
	leal	80(%esp), %esi	#, tmp221
	pushl	%esi	# tmp221
	leal	12(%esp), %ebx	#, tmp222
	pushl	%ebx	# tmp222
	leal	52(%esp), %edx	#, tmp223
	pushl	%edx	# tmp223
	call	_R_ConcatRotations	#
/* original r_bsp.c:262: 	angle = angle * M_PI*2 / 360; */
	movl	_currententity, %ecx	# currententity, currententity
	fldl	wc_rotation_release_LC1	#
	fmuls	128(%ecx)	# currententity.2_14->angles[2]
/* original r_bsp.c:263: 	s = sin(angle); */
	fld	%st(0)	#
	fsin
	fxch	%st(1)		#
/* original r_bsp.c:264: 	c = cos(angle); */
	fcos
/* original r_bsp.c:266: 	temp1[0][0] = 1; */
	fld1
	fstps	20(%esp)	# temp1[0][0]
/* original r_bsp.c:267: 	temp1[0][1] = 0; */
	fldz
	fsts	24(%esp)	# temp1[0][1]
/* original r_bsp.c:268: 	temp1[0][2] = 0; */
	fsts	28(%esp)	# temp1[0][2]
/* original r_bsp.c:269: 	temp1[1][0] = 0; */
	fsts	32(%esp)	# temp1[1][0]
	fxch	%st(1)		#
/* original r_bsp.c:270: 	temp1[1][1] = c; */
	fsts	36(%esp)	# temp1[1][1]
	fxch	%st(2)		#
/* original r_bsp.c:271: 	temp1[1][2] = s; */
	fsts	40(%esp)	# temp1[1][2]
	fxch	%st(1)		#
/* original r_bsp.c:272: 	temp1[2][0] = 0; */
	fstps	44(%esp)	# temp1[2][0]
/* original r_bsp.c:273: 	temp1[2][1] = -s; */
	fchs
/* original r_bsp.c:273: 	temp1[2][1] = -s; */
	fstps	48(%esp)	# temp1[2][1]
/* original r_bsp.c:274: 	temp1[2][2] = c; */
	fstps	52(%esp)	# temp1[2][2]
/* original r_bsp.c:276: 	R_ConcatRotations (temp1, temp3, entity_rotation); */
	addl	$12, %esp	#,
	pushl	$_entity_rotation	#
	pushl	%esi	# tmp221
	pushl	%ebx	# tmp222
	call	_R_ConcatRotations	#
/* original r_bsp.c:204: 	VectorCopy (vec, tvec); */
	flds	_modelorg	# MEM[(vec_t *)&modelorg]
	flds	_modelorg+4	# MEM[(vec_t *)&modelorg + 4B]
	flds	_modelorg+8	# MEM[(vec_t *)&modelorg + 8B]
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	flds	_entity_rotation	# entity_rotation[0][0]
	flds	_entity_rotation+4	# entity_rotation[0][1]
	fld	%st(4)	#
	fmul	%st(2), %st	#,
	fld	%st(4)	#
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
	flds	_entity_rotation+8	# entity_rotation[0][2]
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fstps	_modelorg	# MEM[(vec_t *)&modelorg]
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	flds	_entity_rotation+12	# entity_rotation[1][0]
	fmul	%st(5), %st	#,
	flds	_entity_rotation+16	# entity_rotation[1][1]
	fmul	%st(5), %st	#,
	faddp	%st, %st(1)	#,
	flds	_entity_rotation+20	# entity_rotation[1][2]
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	fstps	_modelorg+4	# MEM[(vec_t *)&modelorg + 4B]
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	flds	_entity_rotation+32	# entity_rotation[2][2]
	fxch	%st(5)		#
	fmuls	_entity_rotation+24	# entity_rotation[2][0]
	fxch	%st(4)		#
	fmuls	_entity_rotation+28	# entity_rotation[2][1]
	faddp	%st, %st(4)	#,
	fxch	%st(2)		#
	fmul	%st(4), %st	#,
	faddp	%st, %st(3)	#,
	fxch	%st(2)		#
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fstps	_modelorg+8	# MEM[(vec_t *)&modelorg + 8B]
/* original r_bsp.c:204: 	VectorCopy (vec, tvec); */
	flds	_vpn	# MEM[(vec_t *)&vpn]
	flds	_vpn+4	# MEM[(vec_t *)&vpn + 4B]
	flds	_vpn+8	# MEM[(vec_t *)&vpn + 8B]
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fld	%st(2)	#
	fmul	%st(5), %st	#,
	fld	%st(2)	#
	fmul	%st(5), %st	#,
	faddp	%st, %st(1)	#,
	flds	_entity_rotation+8	# entity_rotation[0][2]
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fstps	_vpn	# MEM[(vec_t *)&vpn]
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	flds	_entity_rotation+12	# entity_rotation[1][0]
	fmul	%st(3), %st	#,
	flds	_entity_rotation+16	# entity_rotation[1][1]
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
	flds	_entity_rotation+20	# entity_rotation[1][2]
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	fstps	_vpn+4	# MEM[(vec_t *)&vpn + 4B]
	fxch	%st(2)		#
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fmuls	_entity_rotation+24	# entity_rotation[2][0]
	fxch	%st(1)		#
	fmuls	_entity_rotation+28	# entity_rotation[2][1]
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fstps	_vpn+8	# MEM[(vec_t *)&vpn + 8B]
/* original r_bsp.c:204: 	VectorCopy (vec, tvec); */
	flds	_vright	# MEM[(vec_t *)&vright]
	flds	_vright+4	# MEM[(vec_t *)&vright + 4B]
	flds	_vright+8	# MEM[(vec_t *)&vright + 8B]
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fld	%st(2)	#
	fmul	%st(5), %st	#,
	fld	%st(2)	#
	fmul	%st(5), %st	#,
	faddp	%st, %st(1)	#,
	flds	_entity_rotation+8	# entity_rotation[0][2]
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fstps	_vright	# MEM[(vec_t *)&vright]
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	flds	_entity_rotation+12	# entity_rotation[1][0]
	fmul	%st(3), %st	#,
	flds	_entity_rotation+16	# entity_rotation[1][1]
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
	flds	_entity_rotation+20	# entity_rotation[1][2]
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	fstps	_vright+4	# MEM[(vec_t *)&vright + 4B]
	fxch	%st(2)		#
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fmuls	_entity_rotation+24	# entity_rotation[2][0]
	fxch	%st(1)		#
	fmuls	_entity_rotation+28	# entity_rotation[2][1]
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fstps	_vright+8	# MEM[(vec_t *)&vright + 8B]
/* original r_bsp.c:204: 	VectorCopy (vec, tvec); */
	flds	_vup	# MEM[(vec_t *)&vup]
	flds	_vup+4	# MEM[(vec_t *)&vup + 4B]
	flds	_vup+8	# MEM[(vec_t *)&vup + 8B]
	fxch	%st(4)		#
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fmul	%st(2), %st	#,
	fxch	%st(3)		#
	fmul	%st(1), %st	#,
	faddp	%st, %st(3)	#,
	flds	_entity_rotation+8	# entity_rotation[0][2]
	fmul	%st(4), %st	#,
	faddp	%st, %st(3)	#,
	fxch	%st(2)		#
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fstps	_vup	# MEM[(vec_t *)&vup]
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	flds	_entity_rotation+12	# entity_rotation[1][0]
	fmul	%st(1), %st	#,
	flds	_entity_rotation+16	# entity_rotation[1][1]
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
	flds	_entity_rotation+20	# entity_rotation[1][2]
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	fstps	_vup+4	# MEM[(vec_t *)&vup + 4B]
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fmuls	_entity_rotation+24	# entity_rotation[2][0]
	fxch	%st(1)		#
	fmuls	_entity_rotation+28	# entity_rotation[2][1]
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
	fmulp	%st, %st(2)	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fstps	_vup+8	# MEM[(vec_t *)&vup + 8B]
/* original r_bsp.c:286: 	R_TransformFrustum (); */
	call	_R_TransformFrustum	#
/* original r_bsp.c:287: } */
	addl	$132, %esp	#,
	popl	%ebx	#
	popl	%esi	#
	ret
	.p2align 3

.text
.p2align 3
/* R_RotateBmodelCached: Preserve the eight-slot pointer/frame rotation cache, including same-frame hits and slot collisions.
 * Callee registers used: %ebx.
 * Stack reservations: 40 bytes; all returns restore ESP. */
	.globl	_R_RotateBmodelCached
_R_RotateBmodelCached:
	pushl	%ebx	#
	subl	$40, %esp	#,
/* original r_bsp.c:309: 	slot = ((unsigned)currententity >> 5) & (BMODEL_ROTCACHE_SLOTS - 1); */
	movl	_currententity, %eax	# currententity, currententity.3_1
/* original r_bsp.c:309: 	slot = ((unsigned)currententity >> 5) & (BMODEL_ROTCACHE_SLOTS - 1); */
	movl	%eax, %ebx	# currententity.3_1, tmp181
	shrl	$5, %ebx	#, tmp181
/* original r_bsp.c:309: 	slot = ((unsigned)currententity >> 5) & (BMODEL_ROTCACHE_SLOTS - 1); */
	andl	$7, %ebx	#, slot
/* original r_bsp.c:310: 	if (cache_ent[slot] == currententity && cache_frame[slot] == r_framecount) */
	cmpl	_worldcontrol_cache_ent(,%ebx,4), %eax	# cache_ent[slot_21], currententity.3_1
	je	wc_rotation_release_L8	#,
wc_rotation_release_L6:
/* original r_bsp.c:323: 	R_RotateBmodel (); */
	call	_R_RotateBmodel	#
/* original r_bsp.c:324: 	cache_ent[slot] = currententity; */
	movl	_currententity, %ecx	# currententity, currententity
	movl	%ecx, _worldcontrol_cache_ent(,%ebx,4)	# currententity, cache_ent[slot_21]
/* original r_bsp.c:325: 	cache_frame[slot] = r_framecount; */
	movl	_r_framecount, %eax	# r_framecount, r_framecount
	movl	%eax, _worldcontrol_cache_frame(,%ebx,4)	# r_framecount, cache_frame[slot_21]
/* original r_bsp.c:328: 			cache_rot[slot][i][j] = entity_rotation[i][j]; */
	leal	(%ebx,%ebx,8), %ebx	#, tmp349
	sall	$2, %ebx	#, tmp350
	flds	_entity_rotation	# entity_rotation[0][0]
	fstps	_worldcontrol_cache_rot(%ebx)	# cache_rot[slot_21][0][0]
	flds	_entity_rotation+4	# entity_rotation[0][1]
	fstps	_worldcontrol_cache_rot+4(%ebx)	# cache_rot[slot_21][0][1]
	flds	_entity_rotation+8	# entity_rotation[0][2]
	fstps	_worldcontrol_cache_rot+8(%ebx)	# cache_rot[slot_21][0][2]
	flds	_entity_rotation+12	# entity_rotation[1][0]
	fstps	_worldcontrol_cache_rot+12(%ebx)	# cache_rot[slot_21][1][0]
	flds	_entity_rotation+16	# entity_rotation[1][1]
	fstps	_worldcontrol_cache_rot+16(%ebx)	# cache_rot[slot_21][1][1]
	flds	_entity_rotation+20	# entity_rotation[1][2]
	fstps	_worldcontrol_cache_rot+20(%ebx)	# cache_rot[slot_21][1][2]
	flds	_entity_rotation+24	# entity_rotation[2][0]
	fstps	_worldcontrol_cache_rot+24(%ebx)	# cache_rot[slot_21][2][0]
	flds	_entity_rotation+28	# entity_rotation[2][1]
	fstps	_worldcontrol_cache_rot+28(%ebx)	# cache_rot[slot_21][2][1]
	flds	_entity_rotation+32	# entity_rotation[2][2]
	fstps	_worldcontrol_cache_rot+32(%ebx)	# cache_rot[slot_21][2][2]
/* original r_bsp.c:329: } */
	addl	$40, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
wc_rotation_release_L8:
/* original r_bsp.c:310: 	if (cache_ent[slot] == currententity && cache_frame[slot] == r_framecount) */
	movl	_r_framecount, %edx	# r_framecount, tmp428
	cmpl	%edx, _worldcontrol_cache_frame(,%ebx,4)	# tmp428, cache_frame[slot_21]
	jne	wc_rotation_release_L6	#,
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	leal	(%ebx,%ebx,8), %edx	#, tmp189
	sall	$2, %edx	#, tmp190
	flds	_worldcontrol_cache_rot(%edx)	# cache_rot[slot_21][0][0]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	fsts	_entity_rotation	# entity_rotation[0][0]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	flds	_worldcontrol_cache_rot+4(%edx)	# cache_rot[slot_21][0][1]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	fsts	_entity_rotation+4	# entity_rotation[0][1]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	flds	_worldcontrol_cache_rot+8(%edx)	# cache_rot[slot_21][0][2]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	fsts	_entity_rotation+8	# entity_rotation[0][2]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	flds	_worldcontrol_cache_rot+12(%edx)	# cache_rot[slot_21][1][0]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	fsts	16(%esp)	# %sfp
	fstps	_entity_rotation+12	# entity_rotation[1][0]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	flds	_worldcontrol_cache_rot+16(%edx)	# cache_rot[slot_21][1][1]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	fsts	8(%esp)	# %sfp
	fstps	_entity_rotation+16	# entity_rotation[1][1]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	flds	_worldcontrol_cache_rot+20(%edx)	# cache_rot[slot_21][1][2]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	fsts	12(%esp)	# %sfp
	fstps	_entity_rotation+20	# entity_rotation[1][2]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	flds	_worldcontrol_cache_rot+24(%edx)	# cache_rot[slot_21][2][0]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	fsts	24(%esp)	# %sfp
	fstps	_entity_rotation+24	# entity_rotation[2][0]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	flds	_worldcontrol_cache_rot+28(%edx)	# cache_rot[slot_21][2][1]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	fsts	28(%esp)	# %sfp
	fstps	_entity_rotation+28	# entity_rotation[2][1]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	flds	_worldcontrol_cache_rot+32(%edx)	# cache_rot[slot_21][2][2]
/* original r_bsp.c:314: 				entity_rotation[i][j] = cache_rot[slot][i][j]; */
	fsts	20(%esp)	# %sfp
	fstps	_entity_rotation+32	# entity_rotation[2][2]
/* original r_bsp.c:204: 	VectorCopy (vec, tvec); */
	flds	_modelorg	# MEM[(vec_t *)&modelorg]
	flds	_modelorg+4	# MEM[(vec_t *)&modelorg + 4B]
	flds	_modelorg+8	# MEM[(vec_t *)&modelorg + 8B]
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fld	%st(5)	#
	fmul	%st(3), %st	#,
	fld	%st(5)	#
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
	fld	%st(4)	#
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fstps	_modelorg	# MEM[(vec_t *)&modelorg]
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	flds	16(%esp)	# %sfp
	fmul	%st(3), %st	#,
	flds	8(%esp)	# %sfp
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
	flds	12(%esp)	# %sfp
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	fstps	_modelorg+4	# MEM[(vec_t *)&modelorg + 4B]
	fxch	%st(2)		#
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fmuls	24(%esp)	# %sfp
	fxch	%st(1)		#
	fmuls	28(%esp)	# %sfp
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
	fmuls	20(%esp)	# %sfp
	faddp	%st, %st(1)	#,
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fstps	_modelorg+8	# MEM[(vec_t *)&modelorg + 8B]
/* original r_bsp.c:204: 	VectorCopy (vec, tvec); */
	flds	_vpn	# MEM[(vec_t *)&vpn]
	flds	_vpn+4	# MEM[(vec_t *)&vpn + 4B]
	flds	_vpn+8	# MEM[(vec_t *)&vpn + 8B]
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fld	%st(2)	#
	fmul	%st(6), %st	#,
	fld	%st(2)	#
	fmul	%st(6), %st	#,
	faddp	%st, %st(1)	#,
	fld	%st(4)	#
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fstps	_vpn	# MEM[(vec_t *)&vpn]
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	flds	16(%esp)	# %sfp
	fmul	%st(3), %st	#,
	flds	8(%esp)	# %sfp
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
	flds	12(%esp)	# %sfp
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	fstps	_vpn+4	# MEM[(vec_t *)&vpn + 4B]
	fxch	%st(2)		#
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fmuls	24(%esp)	# %sfp
	fxch	%st(1)		#
	fmuls	28(%esp)	# %sfp
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
	fmuls	20(%esp)	# %sfp
	faddp	%st, %st(1)	#,
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fstps	_vpn+8	# MEM[(vec_t *)&vpn + 8B]
/* original r_bsp.c:204: 	VectorCopy (vec, tvec); */
	flds	_vright	# MEM[(vec_t *)&vright]
	flds	_vright+4	# MEM[(vec_t *)&vright + 4B]
	flds	_vright+8	# MEM[(vec_t *)&vright + 8B]
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fld	%st(2)	#
	fmul	%st(6), %st	#,
	fld	%st(2)	#
	fmul	%st(6), %st	#,
	faddp	%st, %st(1)	#,
	fld	%st(1)	#
	fmul	%st(5), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fstps	_vright	# MEM[(vec_t *)&vright]
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	flds	16(%esp)	# %sfp
	fmul	%st(3), %st	#,
	flds	8(%esp)	# %sfp
	fmul	%st(3), %st	#,
	faddp	%st, %st(1)	#,
	flds	12(%esp)	# %sfp
	fmul	%st(2), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	fstps	_vright+4	# MEM[(vec_t *)&vright + 4B]
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	flds	24(%esp)	# %sfp
	fmul	%st, %st(3)	#,
	flds	28(%esp)	# %sfp
	fmul	%st, %st(3)	#,
	fxch	%st(3)		#
	faddp	%st, %st(4)	#,
	fxch	%st(1)		#
	fmuls	20(%esp)	# %sfp
	faddp	%st, %st(3)	#,
	fxch	%st(2)		#
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fstps	_vright+8	# MEM[(vec_t *)&vright + 8B]
/* original r_bsp.c:204: 	VectorCopy (vec, tvec); */
	flds	_vup	# MEM[(vec_t *)&vup]
	flds	_vup+4	# MEM[(vec_t *)&vup + 4B]
	flds	_vup+8	# MEM[(vec_t *)&vup + 8B]
	fxch	%st(7)		#
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fmul	%st(2), %st	#,
	fxch	%st(6)		#
	fmul	%st(1), %st	#,
	faddp	%st, %st(6)	#,
	fxch	%st(4)		#
	fmul	%st(6), %st	#,
	faddp	%st, %st(5)	#,
	fxch	%st(4)		#
/* original r_bsp.c:205: 	vec[0] = DotProduct (entity_rotation[0], tvec); */
	fstps	_vup	# MEM[(vec_t *)&vup]
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	flds	16(%esp)	# %sfp
	fmul	%st(4), %st	#,
	flds	8(%esp)	# %sfp
	fmul	%st(4), %st	#,
	faddp	%st, %st(1)	#,
	flds	12(%esp)	# %sfp
	fmul	%st(6), %st	#,
	faddp	%st, %st(1)	#,
/* original r_bsp.c:206: 	vec[1] = DotProduct (entity_rotation[1], tvec); */
	fstps	_vup+4	# MEM[(vec_t *)&vup + 4B]
	fxch	%st(1)		#
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fmulp	%st, %st(3)	#,
	fmulp	%st, %st(1)	#,
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
	fmuls	20(%esp)	# %sfp
	faddp	%st, %st(1)	#,
/* original r_bsp.c:207: 	vec[2] = DotProduct (entity_rotation[2], tvec); */
	fstps	_vup+8	# MEM[(vec_t *)&vup + 8B]
/* original r_bsp.c:329: } */
	addl	$40, %esp	#,
	popl	%ebx	#
/* original r_bsp.c:319: 		R_TransformFrustum (); */
	jmp	_R_TransformFrustum	#
	.p2align 3

.data
/* Literal data is separate from audited CODE, never an ISA exemption. */
.p2align 3
wc_rotation_release_LC1:
	.long	-1571644103
	.long	1066524486
	.p2align 3
