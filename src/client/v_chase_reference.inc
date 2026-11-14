/* Maintained original chase instructions; 32-bit cdecl, i486/387 only.
 * EBX/ESI/EDI/EBP preserved, EAX/ECX/EDX caller-owned, DF clear on entry.
 * Preserve x87 evaluation/store order and the original zero trace defaults.
 * SV_RecursiveHullCheck originally has no prototype here: its 0/1 arguments
 * are integer stack bits, so p2f is 0x00000001, not the float encoding of 1.
 * TraceLine uses a 68-byte local frame; trace occupies 52 bytes at ESP+12.
 * Chase_Update uses a 112-byte frame; comments name each original operation. */
	.section .text
	.p2align 3
	.globl	_Chase_Init
/* Chase_Init: Register the four original chase variables in their original order. */
_Chase_Init:
	subl	$24, %esp	 /* , */
/* chase.c:38: 	Cvar_RegisterVariable (&chase_back); */
	pushl	$_chase_back	 /*  */
	call	_Cvar_RegisterVariable	 /*  */
/* chase.c:39: 	Cvar_RegisterVariable (&chase_up); */
	movl	$_chase_up, (%esp)	 /* , */
	call	_Cvar_RegisterVariable	 /*  */
/* chase.c:40: 	Cvar_RegisterVariable (&chase_right); */
	movl	$_chase_right, (%esp)	 /* , */
	call	_Cvar_RegisterVariable	 /*  */
/* chase.c:41: 	Cvar_RegisterVariable (&chase_active); */
	movl	$_chase_active, (%esp)	 /* , */
	call	_Cvar_RegisterVariable	 /*  */
/* chase.c:42: } */
	addl	$28, %esp	 /* , */
	ret
	.p2align 3
	.globl	_Chase_Reset
/* Chase_Reset: Preserve the original empty respawn/teleport hook. */
_Chase_Reset:
/* chase.c:48: } */
	ret
	.p2align 3
	.globl	_TraceLine
/* TraceLine: Zero all 52 trace bytes, check hull zero and copy its three impact coordinates. */
_TraceLine:
	pushl	%edi	 /*  */
	pushl	%ebx	 /*  */
	subl	$68, %esp	 /* , */
	movl	88(%esp), %ebx	 /* impact, impact */
/* chase.c:54: 	memset (&trace, 0, sizeof(trace)); */
	leal	12(%esp), %edx	 /* , tmp90 */
	movl	$13, %ecx	 /* , tmp93 */
	xorl	%eax, %eax	 /* tmp92 */
	movl	%edx, %edi	 /* tmp90, tmp91 */
	rep stosl
/* chase.c:55: 	SV_RecursiveHullCheck (cl.worldmodel->hulls, 0, 0, 1, start, end, &trace); */
	pushl	%eax	 /*  */
	pushl	%edx	 /* tmp90 */
	movl	92(%esp), %edx	 /* end, */
	pushl	%edx	 /*  */
	movl	92(%esp), %ecx	 /* start, */
	pushl	%ecx	 /*  */
	pushl	$1	 /*  */
	pushl	$0	 /*  */
	pushl	$0	 /*  */
/* chase.c:55: 	SV_RecursiveHullCheck (cl.worldmodel->hulls, 0, 0, 1, start, end, &trace); */
	movl	_cl+2692, %eax	 /* cl.worldmodel, tmp103 */
	addl	$208, %eax	 /* , tmp96 */
/* chase.c:55: 	SV_RecursiveHullCheck (cl.worldmodel->hulls, 0, 0, 1, start, end, &trace); */
	pushl	%eax	 /* tmp96 */
	call	_SV_RecursiveHullCheck	 /*  */
/* chase.c:57: 	VectorCopy (trace.endpos, impact); */
	flds	64(%esp)	 /* trace.endpos[0] */
	fstps	(%ebx)	 /* *impact_11(D) */
/* chase.c:57: 	VectorCopy (trace.endpos, impact); */
	flds	68(%esp)	 /* trace.endpos[1] */
	fstps	4(%ebx)	 /* MEM[(vec_t *)impact_11(D) + 4B] */
/* chase.c:57: 	VectorCopy (trace.endpos, impact); */
	flds	72(%esp)	 /* trace.endpos[2] */
	fstps	8(%ebx)	 /* MEM[(vec_t *)impact_11(D) + 8B] */
/* chase.c:58: } */
	addl	$100, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%edi	 /*  */
	ret
	.p2align 3
	.globl	_Chase_Update
/* Chase_Update: Compute the original backward/right/up destination, look trace and clamped FPATAN pitch. */
_Chase_Update:
	pushl	%edi	 /*  */
	pushl	%esi	 /*  */
	pushl	%ebx	 /*  */
	subl	$112, %esp	 /* , */
/* chase.c:69: 	AngleVectors (cl.viewangles, forward, right, up); */
	leal	24(%esp), %eax	 /* , tmp129 */
	pushl	%eax	 /* tmp129 */
	leal	40(%esp), %edx	 /* , tmp130 */
	pushl	%edx	 /* tmp130 */
	leal	20(%esp), %esi	 /* , tmp131 */
	pushl	%esi	 /* tmp131 */
	pushl	$_cl+444	 /*  */
	call	_AngleVectors	 /*  */
/* chase.c:74: 		- forward[i]*chase_back.value */
	flds	_chase_back+16	 /* chase_back.value */
/* chase.c:75: 		- right[i]*chase_right.value; */
	flds	_chase_right+16	 /* chase_right.value */
/* chase.c:75: 		- right[i]*chase_right.value; */
	flds	52(%esp)	 /* right[0] */
	fmul	%st(1), %st	 /* , */
/* chase.c:74: 		- forward[i]*chase_back.value */
	flds	28(%esp)	 /* forward[0] */
	fmul	%st(3), %st	 /* , */
/* chase.c:75: 		- right[i]*chase_right.value; */
	faddp	%st, %st(1)	 /* , */
	fsubrs	_r_refdef+112	 /* r_refdef.vieworg[0] */
/* chase.c:73: 		chase_dest[i] = r_refdef.vieworg[i] */
	fstps	_chase_dest	 /* chase_dest[0] */
	fxch	%st(1)		 /*  */
/* chase.c:74: 		- forward[i]*chase_back.value */
	fmuls	32(%esp)	 /* forward[1] */
	fxch	%st(1)		 /*  */
/* chase.c:75: 		- right[i]*chase_right.value; */
	fmuls	56(%esp)	 /* right[1] */
/* chase.c:75: 		- right[i]*chase_right.value; */
	faddp	%st, %st(1)	 /* , */
	fsubrs	_r_refdef+116	 /* r_refdef.vieworg[1] */
/* chase.c:73: 		chase_dest[i] = r_refdef.vieworg[i] */
	fstps	_chase_dest+4	 /* chase_dest[1] */
/* chase.c:76: 	chase_dest[2] = r_refdef.vieworg[2] + chase_up.value; */
	flds	_r_refdef+120	 /* r_refdef.vieworg[2] */
	fadds	_chase_up+16	 /* chase_up.value */
/* chase.c:76: 	chase_dest[2] = r_refdef.vieworg[2] + chase_up.value; */
	fstps	_chase_dest+8	 /* chase_dest[2] */
/* chase.c:79: 	VectorMA (r_refdef.vieworg, 4096, forward, dest); */
	leal	64(%esp), %ebx	 /* , tmp153 */
	pushl	%ebx	 /* tmp153 */
	pushl	%esi	 /* tmp131 */
	pushl	$0x45800000	 /*  */
	pushl	$_r_refdef+112	 /*  */
	call	_VectorMA	 /*  */
/* chase.c:54: 	memset (&trace, 0, sizeof(trace)); */
	leal	92(%esp), %edx	 /* , tmp156 */
	movl	$13, %ecx	 /* , tmp159 */
	xorl	%eax, %eax	 /* tmp158 */
	movl	%edx, %edi	 /* tmp156, tmp157 */
	rep stosl
/* chase.c:55: 	SV_RecursiveHullCheck (cl.worldmodel->hulls, 0, 0, 1, start, end, &trace); */
	addl	$28, %esp	 /* , */
	pushl	%edx	 /* tmp156 */
	pushl	%ebx	 /* tmp153 */
	pushl	$_r_refdef+112	 /*  */
	pushl	$1	 /*  */
	pushl	$0	 /*  */
	pushl	$0	 /*  */
/* chase.c:55: 	SV_RecursiveHullCheck (cl.worldmodel->hulls, 0, 0, 1, start, end, &trace); */
	movl	_cl+2692, %esi	 /* cl.worldmodel, tmp200 */
	addl	$208, %esi	 /* , tmp163 */
/* chase.c:55: 	SV_RecursiveHullCheck (cl.worldmodel->hulls, 0, 0, 1, start, end, &trace); */
	pushl	%esi	 /* tmp163 */
	call	_SV_RecursiveHullCheck	 /*  */
/* chase.c:57: 	VectorCopy (trace.endpos, impact); */
	flds	120(%esp)	 /* trace.endpos[2] */
/* chase.c:83: 	VectorSubtract (stop, r_refdef.vieworg, stop); */
	fsubs	_r_refdef+120	 /* r_refdef.vieworg[2] */
/* chase.c:83: 	VectorSubtract (stop, r_refdef.vieworg, stop); */
	flds	112(%esp)	 /* trace.endpos[0] */
	fsubs	_r_refdef+112	 /* r_refdef.vieworg[0] */
/* chase.c:84: 	dist = DotProduct (stop, forward); */
	fmuls	44(%esp)	 /* forward[0] */
/* chase.c:83: 	VectorSubtract (stop, r_refdef.vieworg, stop); */
	flds	116(%esp)	 /* trace.endpos[1] */
	fsubs	_r_refdef+116	 /* r_refdef.vieworg[1] */
/* chase.c:84: 	dist = DotProduct (stop, forward); */
	fmuls	48(%esp)	 /* forward[1] */
/* chase.c:84: 	dist = DotProduct (stop, forward); */
	faddp	%st, %st(1)	 /* , */
/* chase.c:84: 	dist = DotProduct (stop, forward); */
	flds	52(%esp)	 /* forward[2] */
	fmul	%st(2), %st	 /* , */
/* chase.c:84: 	dist = DotProduct (stop, forward); */
	faddp	%st, %st(1)	 /* , */
/* chase.c:87: 	r_refdef.viewangles[PITCH] = -atan(stop[2] / dist) / M_PI * 180; */
	addl	$32, %esp	 /* , */
	fld1
	fxch	%st(1)		 /*  */
	fcom	%st(1)	 /*  */
	fnstsw	%ax	 /* tmp176 */
	testb	$5, %ah	 /* , tmp176 */
	je	L10	 /* , */
	fstp	%st(0)		 /*  */
	jmp	L8	 /*  */
	.p2align 4
	.p2align 3
L10:
	fstp	%st(1)		 /*  */
L8:
	fdivrp	%st, %st(1)	 /* , */
/* chase.c:87: 	r_refdef.viewangles[PITCH] = -atan(stop[2] / dist) / M_PI * 180; */
	fld1
	fpatan
/* chase.c:87: 	r_refdef.viewangles[PITCH] = -atan(stop[2] / dist) / M_PI * 180; */
	fmull	LC3	 /*  */
	fstps	_r_refdef+124	 /* r_refdef.viewangles[0] */
/* chase.c:90: 	VectorCopy (chase_dest, r_refdef.vieworg); */
	flds	_chase_dest	 /* chase_dest[0] */
	fstps	_r_refdef+112	 /* r_refdef.vieworg[0] */
/* chase.c:90: 	VectorCopy (chase_dest, r_refdef.vieworg); */
	flds	_chase_dest+4	 /* chase_dest[1] */
	fstps	_r_refdef+116	 /* r_refdef.vieworg[1] */
/* chase.c:90: 	VectorCopy (chase_dest, r_refdef.vieworg); */
	flds	_chase_dest+8	 /* chase_dest[2] */
	fstps	_r_refdef+120	 /* r_refdef.vieworg[2] */
/* chase.c:91: } */
	addl	$112, %esp	 /* , */
	popl	%ebx	 /*  */
	popl	%esi	 /*  */
	popl	%edi	 /*  */
	ret
.data
/* Original binary64 -180/pi multiplier; no decimal re-rounding. */
LC3:
	.long	442745336
	.long	-1068718628
