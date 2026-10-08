/* View/camera control: release; pinned original source SHA256
 * E71420D256B86CEF9321E54A091631C1BB394D0F583DA73F8B49B6F6A07D0A00
 * Initial instruction schedule imported once from the unchanged C algorithm.
 * Maintained assembly: normal builds never compile C into this module.
 * Cdecl; stack arguments; EAX integer and ST(0) floating results.
 * EBX/ESI/EDI/EBP preserved when used; EAX/ECX/EDX caller-owned.
 * Preserve the documented x87 operation order and every rounding store.
 * Constants are typed data outside the instruction section. */

.text
.p2align 3
/* V_CalcRoll: Project velocity onto the right vector, scale the original speed limit and return signed roll.
 * Saved callee registers used: %ebx.
 * Stack reservations: 8 bytes; every return restores entry ESP. */
	.globl	_V_CalcRoll
_V_CalcRoll:
	pushl	%ebx	#
	subl	$8, %esp	#,
	movl	20(%esp), %ebx	# velocity, velocity
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:104: 	AngleVectors (angles, forward, right, up); */
	pushl	$_up	#
	pushl	$_right	#
	pushl	$_forward	#
	movl	28(%esp), %eax	# angles,
	pushl	%eax	#
	call	_AngleVectors	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:105: 	side = DotProduct (velocity, right); */
	flds	(%ebx)	# *velocity_18(D)
	fmuls	_right	# right[0]
	flds	4(%ebx)	# MEM[(vec_t *)velocity_18(D) + 4B]
	fmuls	_right+4	# right[1]
	faddp	%st, %st(1)	#,
	flds	8(%ebx)	# MEM[(vec_t *)velocity_18(D) + 8B]
	fmuls	_right+8	# right[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:105: 	side = DotProduct (velocity, right); */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:106: 	sign = side < 0 ? -1 : 1; */
	addl	$16, %esp	#,
	ftst
	fnstsw	%ax	# tmp111
	fld1
	testb	$1, %ah	#, tmp111
	je	L19	#,
	fchs
	fxch	%st(1)		#
	jmp	L10	#
	.p2align 4
	.p2align 3
L19:
	fxch	%st(1)		#
L10:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:107: 	side = fabs(side); */
	fabs
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:109: 	value = cl_rollangle.value; */
	flds	_cl_rollangle+16	# cl_rollangle.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:113: 	if (side < cl_rollspeed.value) */
	flds	_cl_rollspeed+16	# cl_rollspeed.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:113: 	if (side < cl_rollspeed.value) */
	fcom	%st(2)	#
	fnstsw	%ax	# tmp114
	testb	$69, %ah	#, tmp114
	jne	L20	#,
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:114: 		side = side * value / cl_rollspeed.value; */
	fmulp	%st, %st(2)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:114: 		side = side * value / cl_rollspeed.value; */
	fdivrp	%st, %st(1)	#,
	jmp	L12	#
	.p2align 4
	.p2align 3
L20:
	fstp	%st(0)		#
	fstp	%st(1)		#
L12:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:118: 	return side*sign; */
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:120: } */
	addl	$8, %esp	#,
	popl	%ebx	#
	ret
	.p2align 3

.text
.p2align 3
/* V_CalcBob: Retain the original time-cycle reduction, horizontal speed, sine modulation and asymmetric bob clamp.
 * Saved callee registers used: none.
 * Stack reservations: 12 bytes; every return restores entry ESP. */
	.globl	_V_CalcBob
_V_CalcBob:
	subl	$12, %esp	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:134: 	cycle = cl.time - (int)(cl.time/cl_bobcycle.value)*cl_bobcycle.value; */
	fldl	_cl+572	# cl.time
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:134: 	cycle = cl.time - (int)(cl.time/cl_bobcycle.value)*cl_bobcycle.value; */
	flds	_cl_bobcycle+16	# cl_bobcycle.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:134: 	cycle = cl.time - (int)(cl.time/cl_bobcycle.value)*cl_bobcycle.value; */
	fld	%st(1)	#
	fdiv	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:134: 	cycle = cl.time - (int)(cl.time/cl_bobcycle.value)*cl_bobcycle.value; */
	fnstcw	6(%esp)	#
	movw	6(%esp), %ax	#, tmp172
	orb	$12, %ah	#, tmp172
	movw	%ax, 4(%esp)	# tmp172,
	fldcw	4(%esp)		#
	fistpl	(%esp)	# %sfp
	fldcw	6(%esp)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:134: 	cycle = cl.time - (int)(cl.time/cl_bobcycle.value)*cl_bobcycle.value; */
	fld	%st(0)	#
	fimull	(%esp)	# %sfp
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:134: 	cycle = cl.time - (int)(cl.time/cl_bobcycle.value)*cl_bobcycle.value; */
	fsubrp	%st, %st(2)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:135: 	cycle /= cl_bobcycle.value; */
	fdivrp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:136: 	if (cycle < cl_bobup.value) */
	flds	_cl_bobup+16	# cl_bobup.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:137: 		cycle = M_PI * cycle / cl_bobup.value; */
	fld	%st(0)	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:136: 	if (cycle < cl_bobup.value) */
	fcom	%st(2)	#
	fnstsw	%ax	# tmp136
	testb	$69, %ah	#, tmp136
	jne	L28	#,
	fstp	%st(0)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:137: 		cycle = M_PI * cycle / cl_bobup.value; */
	fldl	LC4	#
	fmulp	%st, %st(2)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:137: 		cycle = M_PI * cycle / cl_bobup.value; */
	fdivrp	%st, %st(1)	#,
L24:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:144: 	bob = sqrt(cl.velocity[0]*cl.velocity[0] + cl.velocity[1]*cl.velocity[1]) * cl_bob.value; */
	flds	_cl+484	# cl.velocity[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:144: 	bob = sqrt(cl.velocity[0]*cl.velocity[0] + cl.velocity[1]*cl.velocity[1]) * cl_bob.value; */
	flds	_cl+480	# cl.velocity[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:144: 	bob = sqrt(cl.velocity[0]*cl.velocity[0] + cl.velocity[1]*cl.velocity[1]) * cl_bob.value; */
	fmul	%st(0), %st	#,
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:144: 	bob = sqrt(cl.velocity[0]*cl.velocity[0] + cl.velocity[1]*cl.velocity[1]) * cl_bob.value; */
	fmul	%st(0), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:144: 	bob = sqrt(cl.velocity[0]*cl.velocity[0] + cl.velocity[1]*cl.velocity[1]) * cl_bob.value; */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:144: 	bob = sqrt(cl.velocity[0]*cl.velocity[0] + cl.velocity[1]*cl.velocity[1]) * cl_bob.value; */
	fsqrt
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:146: 	bob = bob*0.3 + bob*0.7*sin(cycle); */
	fsin
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:144: 	bob = sqrt(cl.velocity[0]*cl.velocity[0] + cl.velocity[1]*cl.velocity[1]) * cl_bob.value; */
	fmuls	_cl_bob+16	# cl_bob.value
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:146: 	bob = bob*0.3 + bob*0.7*sin(cycle); */
	fmull	LC5	#
	faddl	LC6	#
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:151: 	return bob; */
	fcoms	LC7	#
	fnstsw	%ax	# tmp170
	testb	$5, %ah	#, tmp170
	je	L25	#,
	fstp	%st(0)		#
	flds	LC7	#
L25:
	fcoms	LC8	#
	fnstsw	%ax	# tmp171
	testb	$69, %ah	#, tmp171
	jne	L29	#,
	fstp	%st(0)		#
	flds	LC8	#
L29:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:153: } */
	addl	$12, %esp	#,
	ret
	.p2align 4
	.p2align 3
L28:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:139: 		cycle = M_PI + M_PI*(cycle-cl_bobup.value)/(1.0 - cl_bobup.value); */
	fsubrp	%st, %st(2)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:139: 		cycle = M_PI + M_PI*(cycle-cl_bobup.value)/(1.0 - cl_bobup.value); */
	fldl	LC4	#
	fmul	%st, %st(2)	#,
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:139: 		cycle = M_PI + M_PI*(cycle-cl_bobup.value)/(1.0 - cl_bobup.value); */
	fsubrs	LC3	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:139: 		cycle = M_PI + M_PI*(cycle-cl_bobup.value)/(1.0 - cl_bobup.value); */
	fdivrp	%st, %st(2)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:139: 		cycle = M_PI + M_PI*(cycle-cl_bobup.value)/(1.0 - cl_bobup.value); */
	faddp	%st, %st(1)	#,
	jmp	L24	#
	.p2align 3

.text
.p2align 3
/* V_StartPitchDrift: Honor same-frame drift cancellation and initialize the original pitch acceleration state.
 * Saved callee registers used: none.
 * Stack reservations: none bytes; every return restores entry ESP. */
	.globl	_V_StartPitchDrift
_V_StartPitchDrift:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:166: 	if (cl.laststop == cl.time) */
	fldl	_cl+520	# cl.laststop
	fcompl	_cl+572	# cl.time
	fnstsw	%ax	# tmp90
	testb	$64, %ah	#, tmp90
	jne	L5	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:171: 	if (cl.nodrift || !cl.pitchvel) */
	movl	_cl+512, %edx	# cl.nodrift,
	testl	%edx, %edx	#
	je	L8	#,
L7:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:173: 		cl.pitchvel = v_centerspeed.value; */
	flds	_v_centerspeed+16	# v_centerspeed.value
	fstps	_cl+508	# cl.pitchvel
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:174: 		cl.nodrift = false; */
	movl	$0, _cl+512	#, cl.nodrift
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:175: 		cl.driftmove = 0; */
	movl	$0x00000000, _cl+516	#, cl.driftmove
L5:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:177: } */
	ret
	.p2align 4
	.p2align 3
L8:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:171: 	if (cl.nodrift || !cl.pitchvel) */
	fldz
	fcomps	_cl+508	# cl.pitchvel
	fnstsw	%ax	# tmp94
	testb	$64, %ah	#, tmp94
	je	L5	#,
	jmp	L7	#
	.p2align 3

.text
.p2align 3
/* V_StopPitchDrift: Record cancellation time and clear pitch motion.
 * Saved callee registers used: none.
 * Stack reservations: none bytes; every return restores entry ESP. */
	.globl	_V_StopPitchDrift
_V_StopPitchDrift:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:181: 	cl.laststop = cl.time; */
	fldl	_cl+572	# cl.time
	fstpl	_cl+520	# cl.laststop
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:182: 	cl.nodrift = true; */
	movl	$1, _cl+512	#, cl.nodrift
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:183: 	cl.pitchvel = 0; */
	movl	$0x00000000, _cl+508	#, cl.pitchvel
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:184: } */
	ret
	.p2align 3

.text
.p2align 3
/* V_DriftPitch: Preserve noclip/demo/ground gates, movement threshold, acceleration and overshoot clamp.
 * Saved callee registers used: none.
 * Stack reservations: none bytes; every return restores entry ESP. */
	.globl	_V_DriftPitch
_V_DriftPitch:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:203: 	if (noclip_anglehack || !cl.onground || cls.demoplayback ) */
	movl	_noclip_anglehack, %eax	# noclip_anglehack, noclip_anglehack.1_1
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:203: 	if (noclip_anglehack || !cl.onground || cls.demoplayback ) */
	movl	_cl+540, %edx	# cl.onground,
	testl	%edx, %edx	#
	je	L33	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:203: 	if (noclip_anglehack || !cl.onground || cls.demoplayback ) */
	orl	_cls+2252, %eax	# cls.demoplayback, tmp163
	jne	L33	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:211: 	if (cl.nodrift) */
	movl	_cl+512, %ecx	# cl.nodrift,
	testl	%ecx, %ecx	#
	jne	L51	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:225: 	delta = cl.idealpitch - cl.viewangles[PITCH]; */
	flds	_cl+504	# cl.idealpitch
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:225: 	delta = cl.idealpitch - cl.viewangles[PITCH]; */
	flds	_cl+444	# cl.viewangles[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:225: 	delta = cl.idealpitch - cl.viewangles[PITCH]; */
	fld	%st(1)	#
	fsub	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:227: 	if (!delta) */
	ftst
	fnstsw	%ax	# tmp144
	testb	$64, %ah	#, tmp144
	jne	L52	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:233: 	move = host_frametime * cl.pitchvel; */
	flds	_cl+508	# cl.pitchvel
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:233: 	move = host_frametime * cl.pitchvel; */
	fldl	_host_frametime	# host_frametime
	fld	%st(1)	#
	fmul	%st(1), %st	#,
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:234: 	cl.pitchvel += host_frametime * v_centerspeed.value; */
	fmuls	_v_centerspeed+16	# v_centerspeed.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:234: 	cl.pitchvel += host_frametime * v_centerspeed.value; */
	faddp	%st, %st(2)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:238: 	if (delta > 0) */
	testb	$69, %ah	#, tmp144
	jne	L50	#,
	fxch	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:240: 		if (move > delta) */
	fcomp	%st(2)	#
	fnstsw	%ax	# tmp154
	testb	$1, %ah	#, tmp154
	je	L53	#,
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
	jmp	L48	#
	.p2align 4
	.p2align 3
L54:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
L48:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:251: 			cl.pitchvel = 0; */
	fldz
L45:
	fstps	_cl+508	# MEM <struct client_state_t> [(void *)&cl].pitchvel
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:254: 		cl.viewangles[PITCH] -= move; */
	fstps	_cl+444	# cl.viewangles[0]
L32:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:256: } */
	ret
	.p2align 4
	.p2align 3
L33:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:205: 		cl.driftmove = 0; */
	fldz
	fsts	_cl+516	# cl.driftmove
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:206: 		cl.pitchvel = 0; */
	fstps	_cl+508	# cl.pitchvel
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:207: 		return; */
	ret
	.p2align 4
	.p2align 3
L51:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:213: 		if ( fabs(cl.cmd.forwardmove) < cl_forwardspeed.value) */
	flds	_cl+16	# cl.cmd.forwardmove
	fabs
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:213: 		if ( fabs(cl.cmd.forwardmove) < cl_forwardspeed.value) */
	fcomps	_cl_forwardspeed+16	# cl_forwardspeed.value
	fnstsw	%ax	# tmp125
	testb	$1, %ah	#, tmp125
	jne	L46	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:216: 			cl.driftmove += host_frametime; */
	flds	_cl+516	# cl.driftmove
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:216: 			cl.driftmove += host_frametime; */
	faddl	_host_frametime	# host_frametime
L37:
	fsts	_cl+516	# cl.driftmove
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:218: 		if ( cl.driftmove > v_centermove.value) */
	fcomps	_v_centermove+16	# v_centermove.value
	fnstsw	%ax	# tmp131
	testb	$69, %ah	#, tmp131
	jne	L32	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:166: 	if (cl.laststop == cl.time) */
	fldl	_cl+520	# cl.laststop
	fcompl	_cl+572	# cl.time
	fnstsw	%ax	# tmp135
	testb	$64, %ah	#, tmp135
	jne	L32	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:173: 		cl.pitchvel = v_centerspeed.value; */
	flds	_v_centerspeed+16	# v_centerspeed.value
	fstps	_cl+508	# cl.pitchvel
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:174: 		cl.nodrift = false; */
	movl	$0, _cl+512	#, cl.nodrift
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:175: 		cl.driftmove = 0; */
	movl	$0x00000000, _cl+516	#, cl.driftmove
	ret
	.p2align 4
	.p2align 3
L52:
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:229: 		cl.pitchvel = 0; */
	movl	$0x00000000, _cl+508	#, cl.pitchvel
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:230: 		return; */
	ret
	.p2align 4
	.p2align 3
L50:
	fstp	%st(2)		#
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:247: 	else if (delta < 0) */
	testb	$1, %ah	#, tmp144
	jne	L44	#,
	fstp	%st(0)		#
	fstp	%st(1)		#
	fstp	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:234: 	cl.pitchvel += host_frametime * v_centerspeed.value; */
	fstps	_cl+508	# cl.pitchvel
	ret
	.p2align 4
	.p2align 3
L46:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:214: 			cl.driftmove = 0; */
	fldz
	jmp	L37	#
	.p2align 4
	.p2align 3
L53:
	fstp	%st(3)		#
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:245: 		cl.viewangles[PITCH] += move; */
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
	jmp	L45	#
	.p2align 4
	.p2align 3
L44:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:249: 		if (move > -delta) */
	fld	%st(2)	#
	fsub	%st(4), %st	#,
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:249: 		if (move > -delta) */
	fcom	%st(1)	#
	fnstsw	%ax	# tmp160
	fstp	%st(1)		#
	testb	$69, %ah	#, tmp160
	je	L54	#,
	fstp	%st(3)		#
	fxch	%st(1)		#
	fxch	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:254: 		cl.viewangles[PITCH] -= move; */
	fsubrp	%st, %st(2)	#,
	jmp	L45	#
	.p2align 3

.text
.p2align 3
/* angledelta: Quantize through anglemod and preserve the original signed angle interval.
 * Saved callee registers used: none.
 * Stack reservations: 24 bytes; every return restores entry ESP. */
	.globl	_angledelta
_angledelta:
	subl	$24, %esp	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:641: 	a = anglemod(a); */
	movl	28(%esp), %eax	# a,
	pushl	%eax	#
	call	_anglemod	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:642: 	if (a > 180) */
	addl	$16, %esp	#,
	fcoms	LC13	#
	fnstsw	%ax	# tmp84
	testb	$69, %ah	#, tmp84
	jne	L66	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:643: 		a -= 360; */
	fsubs	LC14	#
L66:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:645: } */
	addl	$12, %esp	#,
	ret
	.p2align 3

.text
.p2align 3
/* CalcGunAngle: Maintain the two persistent gun-angle latches and subtract the original idle sway.
 * Saved callee registers used: none.
 * Stack reservations: 40, 16 bytes; every return restores entry ESP. */
	.globl	_CalcGunAngle
_CalcGunAngle:
	subl	$40, %esp	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:659: 	pitch = -r_refdef.viewangles[PITCH]; */
	flds	_r_refdef+124	# r_refdef.viewangles[0]
	fstps	24(%esp)	# %sfp
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:641: 	a = anglemod(a); */
	pushl	$0x00000000	#
	call	_anglemod	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:642: 	if (a > 180) */
	addl	$16, %esp	#,
	fcoms	LC13	#
	fnstsw	%ax	# tmp152
	testb	$69, %ah	#, tmp152
	flds	12(%esp)	# %sfp
	jne	L99	#,
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:643: 		a -= 360; */
	fsubs	LC14	#
	jmp	L72	#
	.p2align 4
	.p2align 3
L99:
	fxch	%st(1)		#
L72:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:661: 	yaw = angledelta(yaw - r_refdef.viewangles[YAW]) * 0.4; */
	fldl	LC15	#
	fmulp	%st, %st(1)	#,
	fcoms	LC10	#
	fnstsw	%ax	# tmp157
	testb	$69, %ah	#, tmp157
	jne	L74	#,
	fstp	%st(0)		#
	flds	LC10	#
L74:
	fcoms	LC16	#
	fnstsw	%ax	# tmp158
	testb	$5, %ah	#, tmp158
	je	L75	#,
	fstp	%st(0)		#
	flds	LC16	#
L75:
	fstps	12(%esp)	# %sfp
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:641: 	a = anglemod(a); */
	subl	$16, %esp	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:666: 	pitch = angledelta(-pitch - r_refdef.viewangles[PITCH]) * 0.4; */
	fsubs	_r_refdef+124	# r_refdef.viewangles[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:641: 	a = anglemod(a); */
	fstps	(%esp)	#
	call	_anglemod	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:642: 	if (a > 180) */
	addl	$16, %esp	#,
	fcoms	LC13	#
	fnstsw	%ax	# tmp161
	testb	$69, %ah	#, tmp161
	flds	12(%esp)	# %sfp
	jne	L100	#,
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:643: 		a -= 360; */
	fsubs	LC14	#
	jmp	L76	#
	.p2align 4
	.p2align 3
L100:
	fxch	%st(1)		#
L76:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:666: 	pitch = angledelta(-pitch - r_refdef.viewangles[PITCH]) * 0.4; */
	fldl	LC15	#
	fmulp	%st, %st(1)	#,
	fcoms	LC10	#
	fnstsw	%ax	# tmp166
	testb	$69, %ah	#, tmp166
	jne	L78	#,
	fstp	%st(0)		#
	flds	LC10	#
L78:
	fcoms	LC16	#
	fnstsw	%ax	# tmp167
	testb	$5, %ah	#, tmp167
	je	L79	#,
	fstp	%st(0)		#
	flds	LC16	#
L79:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:671: 	move = host_frametime*20; */
	flds	LC17	#
	fmull	_host_frametime	# host_frametime
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:672: 	if (yaw > oldyaw) */
	flds	_viewcontrol_oldyaw	# oldyaw
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:672: 	if (yaw > oldyaw) */
	fcom	%st(3)	#
	fnstsw	%ax	# tmp172
	testb	$1, %ah	#, tmp172
	je	L94	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:674: 		if (oldyaw + move < yaw) */
	fadd	%st(1), %st	#,
	fcom	%st(3)	#
	fnstsw	%ax	# tmp174
	testb	$69, %ah	#, tmp174
	je	L101	#,
	fstp	%st(3)		#
	jmp	L83	#
	.p2align 4
	.p2align 3
L104:
	fstp	%st(3)		#
L83:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:683: 	if (pitch > oldpitch) */
	flds	_viewcontrol_oldpitch	# oldpitch
	fxch	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:683: 	if (pitch > oldpitch) */
	fcom	%st(2)	#
	fnstsw	%ax	# tmp177
	testb	$69, %ah	#, tmp177
	jne	L95	#,
	fxch	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:685: 		if (oldpitch + move < pitch) */
	faddp	%st, %st(1)	#,
	fcom	%st(1)	#
	fnstsw	%ax	# tmp179
	testb	$69, %ah	#, tmp179
	je	L102	#,
	fstp	%st(1)		#
	fxch	%st(1)		#
	jmp	L88	#
	.p2align 4
	.p2align 3
L103:
	fstp	%st(1)		#
	fxch	%st(1)		#
L88:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:694: 	oldyaw = yaw; */
	fsts	_viewcontrol_oldyaw	# oldyaw
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:695: 	oldpitch = pitch; */
	fsts	_viewcontrol_oldpitch	# oldpitch
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:697: 	cl.viewent.angles[YAW] = r_refdef.viewangles[YAW] + yaw; */
	fadds	_r_refdef+128	# r_refdef.viewangles[1]
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:698: 	cl.viewent.angles[PITCH] = - (r_refdef.viewangles[PITCH] + pitch); */
	fadds	_r_refdef+124	# r_refdef.viewangles[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:698: 	cl.viewent.angles[PITCH] = - (r_refdef.viewangles[PITCH] + pitch); */
	fchs
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:700: 	cl.viewent.angles[ROLL] -= v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value; */
	flds	_v_idlescale+16	# v_idlescale.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:700: 	cl.viewent.angles[ROLL] -= v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value; */
	fldl	_cl+572	# cl.time
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:700: 	cl.viewent.angles[ROLL] -= v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value; */
	fld	%st(0)	#
	fmuls	_v_iroll_cycle+16	# v_iroll_cycle.value
	fsin
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:700: 	cl.viewent.angles[ROLL] -= v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value; */
	fld	%st(2)	#
	fmuls	_v_iroll_level+16	# v_iroll_level.value
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:700: 	cl.viewent.angles[ROLL] -= v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value; */
	fsubrs	_cl+2836	# cl.viewent.angles[2]
	fstps	_cl+2836	# cl.viewent.angles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:701: 	cl.viewent.angles[PITCH] -= v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value; */
	fld	%st(0)	#
	fmuls	_v_ipitch_cycle+16	# v_ipitch_cycle.value
	fsin
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:701: 	cl.viewent.angles[PITCH] -= v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value; */
	fld	%st(2)	#
	fmuls	_v_ipitch_level+16	# v_ipitch_level.value
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:701: 	cl.viewent.angles[PITCH] -= v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value; */
	fsubrp	%st, %st(3)	#,
	fxch	%st(2)		#
	fstps	_cl+2828	# cl.viewent.angles[0]
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:702: 	cl.viewent.angles[YAW] -= v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value; */
	fmuls	_v_iyaw_cycle+16	# v_iyaw_cycle.value
	fsin
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:702: 	cl.viewent.angles[YAW] -= v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value; */
	fmuls	_v_iyaw_level+16	# v_iyaw_level.value
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:702: 	cl.viewent.angles[YAW] -= v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value; */
	fsubrp	%st, %st(1)	#,
	fstps	_cl+2832	# cl.viewent.angles[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:703: } */
	addl	$28, %esp	#,
	ret
	.p2align 4
	.p2align 3
L95:
	fxch	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:690: 		if (oldpitch - move > pitch) */
	fsubp	%st, %st(1)	#,
	fcom	%st(1)	#
	fnstsw	%ax	# tmp181
	testb	$5, %ah	#, tmp181
	je	L103	#,
	fstp	%st(0)		#
	jmp	L98	#
	.p2align 4
	.p2align 3
L102:
	fstp	%st(0)		#
L98:
	fxch	%st(1)		#
	jmp	L88	#
	.p2align 4
	.p2align 3
L94:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:679: 		if (oldyaw - move > yaw) */
	fsub	%st(1), %st	#,
	fcom	%st(3)	#
	fnstsw	%ax	# tmp176
	testb	$5, %ah	#, tmp176
	je	L104	#,
	fstp	%st(0)		#
	jmp	L97	#
	.p2align 4
	.p2align 3
L101:
	fstp	%st(0)		#
L97:
	jmp	L83	#
	.p2align 3

.text
.p2align 3
/* V_BoundOffsets: Clamp camera origin to the original asymmetric entity clipping bounds.
 * Saved callee registers used: none.
 * Stack reservations: none bytes; every return restores entry ESP. */
	.globl	_V_BoundOffsets
_V_BoundOffsets:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:714: 	ent = &cl_entities[cl.viewentity]; */
	movl	_cl+2680, %edx	# cl.viewentity, _1
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:719: 	if (r_refdef.vieworg[0] < ent->origin[0] - 14) */
	flds	_r_refdef+112	# r_refdef.vieworg[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:719: 	if (r_refdef.vieworg[0] < ent->origin[0] - 14) */
	leal	0(,%edx,4), %ecx	#, tmp150
	leal	(%ecx,%edx), %eax	#, tmp100
	addl	%eax, %eax	# tmp100, tmp101
	addl	%edx, %eax	# _1, tmp102
	leal	(%edx,%eax,4), %eax	#, tmp104
	flds	_cl_entities+84(,%eax,4)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:719: 	if (r_refdef.vieworg[0] < ent->origin[0] - 14) */
	flds	LC18	#
	fld	%st(1)	#
	fsub	%st(1), %st	#,
	fxch	%st(3)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:719: 	if (r_refdef.vieworg[0] < ent->origin[0] - 14) */
	fcom	%st(3)	#
	fnstsw	%ax	# tmp109
	testb	$1, %ah	#, tmp109
	je	L124	#,
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:720: 		r_refdef.vieworg[0] = ent->origin[0] - 14; */
	fstps	_r_refdef+112	# r_refdef.vieworg[0]
	jmp	L108	#
	.p2align 4
	.p2align 3
L127:
	fstp	%st(0)		#
L108:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:723: 	if (r_refdef.vieworg[1] < ent->origin[1] - 14) */
	flds	_r_refdef+116	# r_refdef.vieworg[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:723: 	if (r_refdef.vieworg[1] < ent->origin[1] - 14) */
	leal	(%ecx,%edx), %eax	#, tmp118
	addl	%eax, %eax	# tmp118, tmp119
	addl	%edx, %eax	# _1, tmp120
	leal	(%edx,%eax,4), %eax	#, tmp122
	flds	_cl_entities+88(,%eax,4)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:723: 	if (r_refdef.vieworg[1] < ent->origin[1] - 14) */
	flds	LC18	#
	fld	%st(1)	#
	fsub	%st(1), %st	#,
	fxch	%st(3)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:723: 	if (r_refdef.vieworg[1] < ent->origin[1] - 14) */
	fcom	%st(3)	#
	fnstsw	%ax	# tmp127
	testb	$1, %ah	#, tmp127
	je	L125	#,
	fstp	%st(0)		#
	fstp	%st(0)		#
	fstp	%st(0)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:724: 		r_refdef.vieworg[1] = ent->origin[1] - 14; */
	fstps	_r_refdef+116	# r_refdef.vieworg[1]
	jmp	L112	#
	.p2align 4
	.p2align 3
L129:
	fstp	%st(0)		#
L112:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:727: 	if (r_refdef.vieworg[2] < ent->origin[2] - 22) */
	flds	_r_refdef+120	# r_refdef.vieworg[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:727: 	if (r_refdef.vieworg[2] < ent->origin[2] - 22) */
	addl	%edx, %ecx	# _1, tmp136
	addl	%ecx, %ecx	# tmp136, tmp137
	addl	%edx, %ecx	# _1, tmp138
	leal	(%edx,%ecx,4), %edx	#, tmp140
	flds	_cl_entities+92(,%edx,4)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:727: 	if (r_refdef.vieworg[2] < ent->origin[2] - 22) */
	flds	LC19	#
	fsubr	%st(1), %st	#,
	fxch	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:727: 	if (r_refdef.vieworg[2] < ent->origin[2] - 22) */
	fcom	%st(2)	#
	fnstsw	%ax	# tmp145
	testb	$1, %ah	#, tmp145
	je	L126	#,
	fstp	%st(0)		#
	fstp	%st(0)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:728: 		r_refdef.vieworg[2] = ent->origin[2] - 22; */
	fstps	_r_refdef+120	# r_refdef.vieworg[2]
	ret
	.p2align 4
	.p2align 3
L124:
	fstp	%st(3)		#
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:721: 	else if (r_refdef.vieworg[0] > ent->origin[0] + 14) */
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:721: 	else if (r_refdef.vieworg[0] > ent->origin[0] + 14) */
	fcomp	%st(1)	#
	fnstsw	%ax	# tmp112
	testb	$69, %ah	#, tmp112
	jne	L127	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:722: 		r_refdef.vieworg[0] = ent->origin[0] + 14; */
	fstps	_r_refdef+112	# r_refdef.vieworg[0]
	jmp	L108	#
	.p2align 4
	.p2align 3
L126:
	fstp	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:729: 	else if (r_refdef.vieworg[2] > ent->origin[2] + 30) */
	fadds	LC20	#
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:729: 	else if (r_refdef.vieworg[2] > ent->origin[2] + 30) */
	fcomp	%st(1)	#
	fnstsw	%ax	# tmp148
	testb	$69, %ah	#, tmp148
	jne	L128	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:730: 		r_refdef.vieworg[2] = ent->origin[2] + 30; */
	fstps	_r_refdef+120	# r_refdef.vieworg[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:731: } */
	jmp	L105	#
	.p2align 4
	.p2align 3
L128:
	fstp	%st(0)		#
L105:
	ret
	.p2align 4
	.p2align 3
L125:
	fstp	%st(3)		#
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:725: 	else if (r_refdef.vieworg[1] > ent->origin[1] + 14) */
	faddp	%st, %st(1)	#,
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:725: 	else if (r_refdef.vieworg[1] > ent->origin[1] + 14) */
	fcomp	%st(1)	#
	fnstsw	%ax	# tmp130
	testb	$69, %ah	#, tmp130
	jne	L129	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:726: 		r_refdef.vieworg[1] = ent->origin[1] + 14; */
	fstps	_r_refdef+116	# r_refdef.vieworg[1]
	jmp	L112	#
	.p2align 3

.text
.p2align 3
/* V_AddIdle: Apply each original idle frequency/amplitude in roll, pitch, yaw order.
 * Saved callee registers used: none.
 * Stack reservations: none bytes; every return restores entry ESP. */
	.globl	_V_AddIdle
_V_AddIdle:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:742: 	r_refdef.viewangles[ROLL] += v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value; */
	flds	_v_idlescale+16	# v_idlescale.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:742: 	r_refdef.viewangles[ROLL] += v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value; */
	fldl	_cl+572	# cl.time
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:742: 	r_refdef.viewangles[ROLL] += v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value; */
	fld	%st(0)	#
	fmuls	_v_iroll_cycle+16	# v_iroll_cycle.value
	fsin
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:742: 	r_refdef.viewangles[ROLL] += v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value; */
	fld	%st(2)	#
	fmuls	_v_iroll_level+16	# v_iroll_level.value
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:742: 	r_refdef.viewangles[ROLL] += v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value; */
	fadds	_r_refdef+132	# r_refdef.viewangles[2]
	fstps	_r_refdef+132	# r_refdef.viewangles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:743: 	r_refdef.viewangles[PITCH] += v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value; */
	fld	%st(0)	#
	fmuls	_v_ipitch_cycle+16	# v_ipitch_cycle.value
	fsin
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:743: 	r_refdef.viewangles[PITCH] += v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value; */
	fld	%st(2)	#
	fmuls	_v_ipitch_level+16	# v_ipitch_level.value
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:743: 	r_refdef.viewangles[PITCH] += v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value; */
	fadds	_r_refdef+124	# r_refdef.viewangles[0]
	fstps	_r_refdef+124	# r_refdef.viewangles[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:744: 	r_refdef.viewangles[YAW] += v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value; */
	fmuls	_v_iyaw_cycle+16	# v_iyaw_cycle.value
	fsin
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:744: 	r_refdef.viewangles[YAW] += v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value; */
	fmuls	_v_iyaw_level+16	# v_iyaw_level.value
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:744: 	r_refdef.viewangles[YAW] += v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value; */
	fadds	_r_refdef+128	# r_refdef.viewangles[1]
	fstps	_r_refdef+128	# r_refdef.viewangles[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:745: } */
	ret
	.p2align 3

.text
.p2align 3
/* V_CalcViewRoll: Preserve movement roll, damage kick decay and the dead-player roll override.
 * Saved callee registers used: none.
 * Stack reservations: 12 bytes; every return restores entry ESP. */
	.globl	_V_CalcViewRoll
_V_CalcViewRoll:
	subl	$12, %esp	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:104: 	AngleVectors (angles, forward, right, up); */
	pushl	$_up	#
	pushl	$_right	#
	pushl	$_forward	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:759: 	side = V_CalcRoll (cl_entities[cl.viewentity].angles, cl.velocity); */
	movl	_cl+2680, %edx	# cl.viewentity, cl.viewentity
	leal	(%edx,%edx,4), %eax	#, tmp124
	addl	%eax, %eax	# tmp124, tmp125
	addl	%edx, %eax	# cl.viewentity, tmp126
	leal	(%edx,%eax,4), %ecx	#, tmp128
	leal	_cl_entities+120(,%ecx,4), %edx	#, tmp131
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:104: 	AngleVectors (angles, forward, right, up); */
	pushl	%edx	# tmp131
	call	_AngleVectors	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:105: 	side = DotProduct (velocity, right); */
	flds	_cl+480	# MEM[(vec_t *)&cl + 480B]
	fmuls	_right	# right[0]
	flds	_cl+484	# MEM[(vec_t *)&cl + 484B]
	fmuls	_right+4	# right[1]
	faddp	%st, %st(1)	#,
	flds	_cl+488	# MEM[(vec_t *)&cl + 488B]
	fmuls	_right+8	# right[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:105: 	side = DotProduct (velocity, right); */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:106: 	sign = side < 0 ? -1 : 1; */
	addl	$16, %esp	#,
	ftst
	fnstsw	%ax	# tmp145
	fld1
	testb	$1, %ah	#, tmp145
	je	L146	#,
	fchs
	fxch	%st(1)		#
	jmp	L132	#
	.p2align 4
	.p2align 3
L146:
	fxch	%st(1)		#
L132:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:107: 	side = fabs(side); */
	fabs
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:109: 	value = cl_rollangle.value; */
	flds	_cl_rollangle+16	# cl_rollangle.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:113: 	if (side < cl_rollspeed.value) */
	flds	_cl_rollspeed+16	# cl_rollspeed.value
	fxch	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:113: 	if (side < cl_rollspeed.value) */
	fcom	%st(2)	#
	fnstsw	%ax	# tmp148
	testb	$1, %ah	#, tmp148
	je	L147	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:114: 		side = side * value / cl_rollspeed.value; */
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:114: 		side = side * value / cl_rollspeed.value; */
	fdivp	%st, %st(1)	#,
	jmp	L134	#
	.p2align 4
	.p2align 3
L147:
	fstp	%st(0)		#
	fstp	%st(1)		#
L134:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:118: 	return side*sign; */
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:760: 	r_refdef.viewangles[ROLL] += side; */
	fadds	_r_refdef+132	# r_refdef.viewangles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:762: 	if (v_dmg_time > 0) */
	flds	_v_dmg_time	# v_dmg_time
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:762: 	if (v_dmg_time > 0) */
	ftst
	fnstsw	%ax	# tmp152
	testb	$69, %ah	#, tmp152
	jne	L148	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:764: 		r_refdef.viewangles[ROLL] += v_dmg_time/v_kicktime.value*v_dmg_roll; */
	flds	_v_kicktime+16	# v_kicktime.value
	fdivr	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:764: 		r_refdef.viewangles[ROLL] += v_dmg_time/v_kicktime.value*v_dmg_roll; */
	flds	_v_dmg_roll	# v_dmg_roll
	fmul	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:764: 		r_refdef.viewangles[ROLL] += v_dmg_time/v_kicktime.value*v_dmg_roll; */
	faddp	%st, %st(3)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:765: 		r_refdef.viewangles[PITCH] += v_dmg_time/v_kicktime.value*v_dmg_pitch; */
	fmuls	_v_dmg_pitch	# v_dmg_pitch
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:765: 		r_refdef.viewangles[PITCH] += v_dmg_time/v_kicktime.value*v_dmg_pitch; */
	fadds	_r_refdef+124	# r_refdef.viewangles[0]
	fstps	_r_refdef+124	# r_refdef.viewangles[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:766: 		v_dmg_time -= host_frametime; */
	fsubl	_host_frametime	# host_frametime
	fstps	_v_dmg_time	# v_dmg_time
	jmp	L136	#
	.p2align 4
	.p2align 3
L148:
	fstp	%st(0)		#
L136:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:769: 	if (cl.stats[STAT_HEALTH] <= 0) */
	movl	_cl+28, %ecx	# cl.stats[0],
	testl	%ecx, %ecx	#
	jle	L145	#,
	fstps	_r_refdef+132	# MEM <struct refdef_t> [(void *)&r_refdef].viewangles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:775: } */
	addl	$12, %esp	#,
	ret
	.p2align 4
	.p2align 3
L145:
	fstp	%st(0)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:771: 		r_refdef.viewangles[ROLL] = 80;	// dead view angle */
	flds	LC21	#
	fstps	_r_refdef+132	# MEM <struct refdef_t> [(void *)&r_refdef].viewangles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:775: } */
	addl	$12, %esp	#,
	ret
	.p2align 3

.text
.p2align 3
/* V_CalcIntermissionRefdef: Copy entity pose, hide the gun and temporarily enable idle sway.
 * Saved callee registers used: none.
 * Stack reservations: 12 bytes; every return restores entry ESP. */
	.globl	_V_CalcIntermissionRefdef
_V_CalcIntermissionRefdef:
	subl	$12, %esp	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:790: 	ent = &cl_entities[cl.viewentity]; */
	movl	_cl+2680, %edx	# cl.viewentity, _1
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:794: 	VectorCopy (ent->origin, r_refdef.vieworg); */
	leal	(%edx,%edx,4), %eax	#, tmp95
	addl	%eax, %eax	# tmp95, tmp96
	addl	%edx, %eax	# _1, tmp97
	leal	(%edx,%eax,4), %ecx	#, tmp99
	leal	_cl_entities(,%ecx,4), %edx	#, tmp101
	flds	84(%edx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[0]
	fstps	_r_refdef+112	# r_refdef.vieworg[0]
	flds	88(%edx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[1]
	fstps	_r_refdef+116	# r_refdef.vieworg[1]
	flds	92(%edx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[2]
	fstps	_r_refdef+120	# r_refdef.vieworg[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:795: 	VectorCopy (ent->angles, r_refdef.viewangles); */
	flds	120(%edx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].angles[0]
	fstps	_r_refdef+124	# r_refdef.viewangles[0]
	flds	124(%edx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].angles[1]
	fstps	_r_refdef+128	# r_refdef.viewangles[1]
	flds	128(%edx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].angles[2]
	fstps	_r_refdef+132	# r_refdef.viewangles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:796: 	view->model = NULL; */
	movl	$0, _cl+2840	#, MEM[(struct entity_t *)&cl + 2708B].model
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:799: 	old = v_idlescale.value; */
	flds	_v_idlescale+16	# v_idlescale.value
	fstps	4(%esp)	# %sfp
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:800: 	v_idlescale.value = 1; */
	movl	$0x3f800000, _v_idlescale+16	#, v_idlescale.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:801: 	V_AddIdle (); */
	call	_V_AddIdle	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:802: 	v_idlescale.value = old; */
	flds	4(%esp)	# %sfp
	fstps	_v_idlescale+16	# v_idlescale.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:803: } */
	addl	$12, %esp	#,
	ret
	.p2align 3

.text
.p2align 3
/* V_CalcRefdef: Preserve drift, bob, node-line bias, camera limits, gun pose, stair smoothing and chase order.
 * Saved callee registers used: %ebx.
 * Stack reservations: 72 bytes; every return restores entry ESP. */
	.globl	_V_CalcRefdef
_V_CalcRefdef:
	pushl	%ebx	#
	subl	$72, %esp	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:820: 	V_DriftPitch (); */
	call	_V_DriftPitch	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:823: 	ent = &cl_entities[cl.viewentity]; */
	movl	_cl+2680, %edx	# cl.viewentity, _1
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:830: 	ent->angles[YAW] = cl.viewangles[YAW];	// the model should face */
	flds	_cl+448	# cl.viewangles[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:830: 	ent->angles[YAW] = cl.viewangles[YAW];	// the model should face */
	leal	(%edx,%edx,4), %eax	#, tmp198
	addl	%eax, %eax	# tmp198, tmp199
	addl	%edx, %eax	# _1, tmp200
	leal	(%edx,%eax,4), %ecx	#, tmp202
	leal	_cl_entities(,%ecx,4), %ebx	#, tmp204
	fsts	124(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].angles[1]
	fstps	12(%esp)	# %sfp
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:832: 	ent->angles[PITCH] = -cl.viewangles[PITCH];	// the model should face */
	flds	_cl+444	# cl.viewangles[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:832: 	ent->angles[PITCH] = -cl.viewangles[PITCH];	// the model should face */
	fld	%st(0)	#
	fstps	8(%esp)	# %sfp
	fchs
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:832: 	ent->angles[PITCH] = -cl.viewangles[PITCH];	// the model should face */
	fstps	120(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].angles[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:836: 	bob = V_CalcBob (); */
	call	_V_CalcBob	#
	flds	LC23	#
	flds	_cl+528	# cl.viewheight
	fadd	%st(1), %st	#,
	fadds	92(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:845: 	r_refdef.vieworg[0] += 1.0/32; */
	flds	84(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[0]
	fadd	%st(2), %st	#,
	fstps	_r_refdef+112	# r_refdef.vieworg[0]
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:846: 	r_refdef.vieworg[1] += 1.0/32; */
	fadds	88(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[1]
	fstps	_r_refdef+116	# r_refdef.vieworg[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:847: 	r_refdef.vieworg[2] += 1.0/32; */
	fadd	%st(1), %st	#,
	fxch	%st(1)		#
	fstps	4(%esp)	# %sfp
	fstps	_r_refdef+120	# r_refdef.vieworg[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:849: 	VectorCopy (cl.viewangles, r_refdef.viewangles); */
	flds	8(%esp)	# %sfp
	fstps	_r_refdef+124	# r_refdef.viewangles[0]
	flds	12(%esp)	# %sfp
	fstps	_r_refdef+128	# r_refdef.viewangles[1]
	flds	_cl+452	# cl.viewangles[2]
	fstps	_r_refdef+132	# r_refdef.viewangles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:850: 	V_CalcViewRoll (); */
	call	_V_CalcViewRoll	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:851: 	V_AddIdle (); */
	call	_V_AddIdle	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:854: 	angles[PITCH] = -ent->angles[PITCH];	// because entity pitches are */
	flds	120(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].angles[0]
	fchs
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:854: 	angles[PITCH] = -ent->angles[PITCH];	// because entity pitches are */
	fstps	52(%esp)	# angles[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:856: 	angles[YAW] = ent->angles[YAW]; */
	flds	124(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].angles[1]
	fstps	56(%esp)	# angles[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:857: 	angles[ROLL] = ent->angles[ROLL]; */
	flds	128(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].angles[2]
	fstps	60(%esp)	# angles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:859: 	AngleVectors (angles, forward, right, up); */
	leal	40(%esp), %edx	#, tmp307
	pushl	%edx	# tmp307
	leal	32(%esp), %eax	#, tmp308
	pushl	%eax	# tmp308
	leal	24(%esp), %ecx	#, tmp309
	pushl	%ecx	# tmp309
	leal	64(%esp), %edx	#, tmp310
	pushl	%edx	# tmp310
	call	_AngleVectors	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:862: 		r_refdef.vieworg[i] += scr_ofsx.value*forward[i] */
	flds	_scr_ofsx+16	# scr_ofsx.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:863: 			+ scr_ofsy.value*right[i] */
	flds	_scr_ofsy+16	# scr_ofsy.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:864: 			+ scr_ofsz.value*up[i]; */
	flds	_scr_ofsz+16	# scr_ofsz.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:863: 			+ scr_ofsy.value*right[i] */
	flds	44(%esp)	# right[0]
	fmul	%st(2), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:862: 		r_refdef.vieworg[i] += scr_ofsx.value*forward[i] */
	flds	32(%esp)	# forward[0]
	fmul	%st(4), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:863: 			+ scr_ofsy.value*right[i] */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:862: 		r_refdef.vieworg[i] += scr_ofsx.value*forward[i] */
	fadds	_r_refdef+112	# r_refdef.vieworg[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:864: 			+ scr_ofsz.value*up[i]; */
	flds	56(%esp)	# up[0]
	fmul	%st(2), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:862: 		r_refdef.vieworg[i] += scr_ofsx.value*forward[i] */
	faddp	%st, %st(1)	#,
	fstps	_r_refdef+112	# r_refdef.vieworg[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:863: 			+ scr_ofsy.value*right[i] */
	flds	48(%esp)	# right[1]
	fmul	%st(2), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:862: 		r_refdef.vieworg[i] += scr_ofsx.value*forward[i] */
	flds	36(%esp)	# forward[1]
	fmul	%st(4), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:863: 			+ scr_ofsy.value*right[i] */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:862: 		r_refdef.vieworg[i] += scr_ofsx.value*forward[i] */
	fadds	_r_refdef+116	# r_refdef.vieworg[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:864: 			+ scr_ofsz.value*up[i]; */
	flds	60(%esp)	# up[1]
	fmul	%st(2), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:862: 		r_refdef.vieworg[i] += scr_ofsx.value*forward[i] */
	faddp	%st, %st(1)	#,
	fstps	_r_refdef+116	# r_refdef.vieworg[1]
	fxch	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:862: 		r_refdef.vieworg[i] += scr_ofsx.value*forward[i] */
	fmuls	40(%esp)	# forward[2]
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:863: 			+ scr_ofsy.value*right[i] */
	fmuls	52(%esp)	# right[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:863: 			+ scr_ofsy.value*right[i] */
	faddp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:862: 		r_refdef.vieworg[i] += scr_ofsx.value*forward[i] */
	fadds	_r_refdef+120	# r_refdef.vieworg[2]
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:864: 			+ scr_ofsz.value*up[i]; */
	fmuls	64(%esp)	# up[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:862: 		r_refdef.vieworg[i] += scr_ofsx.value*forward[i] */
	faddp	%st, %st(1)	#,
	fstps	_r_refdef+120	# r_refdef.vieworg[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:867: 	V_BoundOffsets (); */
	call	_V_BoundOffsets	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:870: 	VectorCopy (cl.viewangles, view->angles); */
	flds	_cl+444	# cl.viewangles[0]
	fstps	_cl+2828	# MEM[(struct entity_t *)&cl + 2708B].angles[0]
	flds	_cl+448	# cl.viewangles[1]
	fstps	_cl+2832	# MEM[(struct entity_t *)&cl + 2708B].angles[1]
	flds	_cl+452	# cl.viewangles[2]
	fstps	_cl+2836	# MEM[(struct entity_t *)&cl + 2708B].angles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:872: 	CalcGunAngle (); */
	call	_CalcGunAngle	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:874: 	VectorCopy (ent->origin, view->origin); */
	flds	92(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:875: 	view->origin[2] += cl.viewheight; */
	flds	_cl+528	# cl.viewheight
	fadd	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:879: 		view->origin[i] += forward[i]*bob*0.4; */
	flds	20(%esp)	# %sfp
	flds	32(%esp)	# forward[0]
	fmul	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:879: 		view->origin[i] += forward[i]*bob*0.4; */
	fldl	LC15	#
	fmul	%st, %st(1)	#,
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:879: 		view->origin[i] += forward[i]*bob*0.4; */
	fadds	84(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[0]
	fstps	_cl+2792	# MEM[(struct entity_t *)&cl + 2708B].origin[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:879: 		view->origin[i] += forward[i]*bob*0.4; */
	flds	36(%esp)	# forward[1]
	fmul	%st(2), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:879: 		view->origin[i] += forward[i]*bob*0.4; */
	fmul	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:879: 		view->origin[i] += forward[i]*bob*0.4; */
	fadds	88(%ebx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_1].origin[1]
	fstps	_cl+2796	# MEM[(struct entity_t *)&cl + 2708B].origin[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:879: 		view->origin[i] += forward[i]*bob*0.4; */
	flds	40(%esp)	# forward[2]
	fmul	%st(2), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:879: 		view->origin[i] += forward[i]*bob*0.4; */
	fmulp	%st, %st(1)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:879: 		view->origin[i] += forward[i]*bob*0.4; */
	faddp	%st, %st(2)	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:883: 	view->origin[2] += bob; */
	faddp	%st, %st(1)	#,
	fsts	_cl+2800	# MEM[(struct entity_t *)&cl + 2708B].origin[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:891: 	if (scr_viewsize.value == 110) */
	flds	_scr_viewsize+16	# scr_viewsize.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:891: 	if (scr_viewsize.value == 110) */
	addl	$16, %esp	#,
	fcoms	LC24	#
	fnstsw	%ax	# tmp404
	testb	$64, %ah	#, tmp404
	jne	L170	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:893: 	else if (scr_viewsize.value == 100) */
	fcoms	LC25	#
	fnstsw	%ax	# tmp407
	testb	$64, %ah	#, tmp407
	je	L154	#,
	fstp	%st(0)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:894: 		view->origin[2] += 2; */
	fadds	LC26	#
	fsts	_cl+2800	# MEM[(struct entity_t *)&cl + 2708B].origin[2]
	jmp	L153	#
	.p2align 4
	.p2align 3
L154:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:895: 	else if (scr_viewsize.value == 90) */
	fcoms	LC27	#
	fnstsw	%ax	# tmp410
	testb	$64, %ah	#, tmp410
	je	L155	#,
	fstp	%st(0)		#
	jmp	L166	#
	.p2align 4
	.p2align 3
L170:
	fstp	%st(0)		#
L166:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:896: 		view->origin[2] += 1; */
	fadds	LC3	#
	fsts	_cl+2800	# MEM[(struct entity_t *)&cl + 2708B].origin[2]
L153:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:900: 	view->model = cl.model_precache[cl.stats[STAT_WEAPON]]; */
	movl	_cl+36, %ebx	# cl.stats[2], cl.stats[2]
	movl	_cl+592(,%ebx,4), %ecx	# cl.model_precache[_55], cl.model_precache[_55]
	movl	%ecx, _cl+2840	# cl.model_precache[_55], MEM[(struct entity_t *)&cl + 2708B].model
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:901: 	view->frame = cl.stats[STAT_WEAPONFRAME]; */
	movl	_cl+48, %edx	# cl.stats[5], cl.stats[5]
	movl	%edx, _cl+2848	# cl.stats[5], MEM[(struct entity_t *)&cl + 2708B].frame
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:902: 	view->colormap = vid.colormap; */
	movl	_vid+4, %eax	# vid.colormap, vid.colormap
	movl	%eax, _cl+2856	# vid.colormap, MEM[(struct entity_t *)&cl + 2708B].colormap
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:905: 	VectorAdd (r_refdef.viewangles, cl.punchangle, r_refdef.viewangles); */
	flds	_r_refdef+124	# r_refdef.viewangles[0]
	fadds	_cl+492	# cl.punchangle[0]
	fstps	_r_refdef+124	# r_refdef.viewangles[0]
	flds	_r_refdef+128	# r_refdef.viewangles[1]
	fadds	_cl+496	# cl.punchangle[1]
	fstps	_r_refdef+128	# r_refdef.viewangles[1]
	flds	_r_refdef+132	# r_refdef.viewangles[2]
	fadds	_cl+500	# cl.punchangle[2]
	fstps	_r_refdef+132	# r_refdef.viewangles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:908: if (cl.onground && ent->origin[2] - oldz > 0) */
	movl	_cl+540, %ebx	# cl.onground,
	testl	%ebx, %ebx	#
	je	L171	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:908: if (cl.onground && ent->origin[2] - oldz > 0) */
	flds	_viewcontrol_oldz	# oldz
	fld	%st(2)	#
	fsub	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:908: if (cl.onground && ent->origin[2] - oldz > 0) */
	ftst
	fnstsw	%ax	# tmp445
	fstp	%st(0)		#
	testb	$69, %ah	#, tmp445
	jne	L172	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:912: 	steptime = cl.time - cl.oldtime; */
	fldl	_cl+572	# cl.time
	fsubl	_cl+580	# cl.oldtime
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:917: 	oldz += steptime * 80; */
	ftst
	fnstsw	%ax	# tmp451
	testb	$5, %ah	#, tmp451
	jne	L167	#,
L158:
	fmuls	LC21	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:917: 	oldz += steptime * 80; */
	faddp	%st, %st(1)	#,
	fxch	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:918: 	if (oldz > ent->origin[2]) */
	fcom	%st(2)	#
	fnstsw	%ax	# tmp454
	testb	$1, %ah	#, tmp454
	jne	L163	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:920: 	if (ent->origin[2] - oldz > 12) */
	fld	%st(0)	#
	fsub	%st(3), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:920: 	if (ent->origin[2] - oldz > 12) */
	fcomps	LC28	#
	fnstsw	%ax	# tmp456
	testb	$69, %ah	#, tmp456
	jne	L168	#,
	fstp	%st(2)		#
	fxch	%st(1)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:921: 		oldz = ent->origin[2] - 12; */
	flds	LC28	#
	fsubr	%st, %st(1)	#,
	fsubrp	%st, %st(2)	#,
	flds	LC22	#
	fxch	%st(1)		#
L159:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:917: 	oldz += steptime * 80; */
	fstps	_viewcontrol_oldz	# oldz
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:922: 	r_refdef.vieworg[2] += oldz - ent->origin[2]; */
	fadds	_r_refdef+120	# r_refdef.vieworg[2]
	fstps	_r_refdef+120	# r_refdef.vieworg[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:923: 	view->origin[2] += oldz - ent->origin[2]; */
	fstps	_cl+2800	# MEM[(struct entity_t *)&cl + 2708B].origin[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:909: { */
	jmp	L161	#
	.p2align 4
	.p2align 3
L171:
	fstp	%st(0)		#
	jmp	L156	#
	.p2align 4
	.p2align 3
L172:
	fstp	%st(0)		#
	fstp	%st(0)		#
L156:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:926: 	oldz = ent->origin[2]; */
	fstps	_viewcontrol_oldz	# oldz
L161:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:928: 	if (chase_active.value) */
	fldz
	fcomps	_chase_active+16	# chase_active.value
	fnstsw	%ax	# tmp466
	testb	$64, %ah	#, tmp466
	je	L169	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:930: } */
	addl	$72, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L169:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:929: 		Chase_Update (); */
	call	_Chase_Update	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:930: } */
	addl	$72, %esp	#,
	popl	%ebx	#
	ret
	.p2align 4
	.p2align 3
L163:
	fstp	%st(2)		#
	fxch	%st(1)		#
	fldz
	fxch	%st(1)		#
	jmp	L159	#
	.p2align 4
	.p2align 3
L167:
	fstp	%st(0)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:917: 	oldz += steptime * 80; */
	fldz
	jmp	L158	#
	.p2align 4
	.p2align 3
L155:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:897: 	else if (scr_viewsize.value == 80) */
	fcomps	LC21	#
	fnstsw	%ax	# tmp413
	testb	$64, %ah	#, tmp413
	je	L153	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:898: 		view->origin[2] += 0.5; */
	fadds	LC9	#
	fsts	_cl+2800	# MEM[(struct entity_t *)&cl + 2708B].origin[2]
	jmp	L153	#
L168:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:922: 	r_refdef.vieworg[2] += oldz - ent->origin[2]; */
	fsubr	%st(2), %st	#,
	fld	%st(0)	#
	fxch	%st(2)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:923: 	view->origin[2] += oldz - ent->origin[2]; */
	faddp	%st, %st(1)	#,
	fxch	%st(2)		#
	jmp	L159	#

.text
.p2align 3
/* V_RenderView: Preserve forced-console/multiplayer/pause/intermission gates, light dispatch, stereo views and crosshair.
 * Saved callee registers used: none.
 * Stack reservations: 28, 8 bytes; every return restores entry ESP. */
	.globl	_V_RenderView
_V_RenderView:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:944: 	if (con_forcedup) */
	movl	_con_forcedup, %eax	# con_forcedup,
	testl	%eax, %eax	#
	jne	L184	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:943: { */
	subl	$28, %esp	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:948: 	if (cl.maxclients > 1) */
	cmpl	$1, _cl+2684	#, cl.maxclients
	jg	L187	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:955: 	if (cl.intermission) */
	movl	_cl+548, %ecx	# cl.intermission,
	testl	%ecx, %ecx	#
	jne	L188	#,
L177:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:961: 		if (!cl.paused /* && (sv.maxclients > 1 || key_dest == key_game) * / ) */
	movl	_cl+536, %edx	# cl.paused,
	testl	%edx, %edx	#
	je	L189	#,
L178:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:966: 	R_PushDlights (); */
	call	_R_PushDlights	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:969: 	if (lcd_x.value) */
	flds	_lcd_x+16	# lcd_x.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:969: 	if (lcd_x.value) */
	ftst
	fnstsw	%ax	# tmp250
	testb	$64, %ah	#, tmp250
	jne	L179	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:976: 		vid.rowbytes <<= 1; */
	sall	$1, _vid+16	#, vid.rowbytes
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:977: 		vid.aspect *= 0.5; */
	flds	LC9	#
	fmuls	_vid+28	# vid.aspect
	fstps	_vid+28	# vid.aspect
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:979: 		r_refdef.viewangles[YAW] -= lcd_yaw.value; */
	flds	_r_refdef+128	# r_refdef.viewangles[1]
	fsubs	_lcd_yaw+16	# lcd_yaw.value
	fstps	_r_refdef+128	# r_refdef.viewangles[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:981: 			r_refdef.vieworg[i] -= right[i]*lcd_x.value; */
	flds	_right	# right[0]
	fmul	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:981: 			r_refdef.vieworg[i] -= right[i]*lcd_x.value; */
	fsubrs	_r_refdef+112	# r_refdef.vieworg[0]
	fstps	_r_refdef+112	# r_refdef.vieworg[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:981: 			r_refdef.vieworg[i] -= right[i]*lcd_x.value; */
	flds	_right+4	# right[1]
	fmul	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:981: 			r_refdef.vieworg[i] -= right[i]*lcd_x.value; */
	fsubrs	_r_refdef+116	# r_refdef.vieworg[1]
	fstps	_r_refdef+116	# r_refdef.vieworg[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:981: 			r_refdef.vieworg[i] -= right[i]*lcd_x.value; */
	fmuls	_right+8	# right[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:981: 			r_refdef.vieworg[i] -= right[i]*lcd_x.value; */
	fsubrs	_r_refdef+120	# r_refdef.vieworg[2]
	fstps	_r_refdef+120	# r_refdef.vieworg[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:982: 		R_RenderView (); */
	call	_R_RenderView	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:984: 		vid.buffer += vid.rowbytes>>1; */
	movl	_vid+16, %edx	# vid.rowbytes, tmp286
	shrl	$1, %edx	#, tmp286
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:984: 		vid.buffer += vid.rowbytes>>1; */
	addl	%edx, _vid	# tmp286, vid.buffer
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:987: 			R_PushDlights (); */
	call	_R_PushDlights	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:990: 		r_refdef.viewangles[YAW] += lcd_yaw.value*2; */
	flds	_lcd_yaw+16	# lcd_yaw.value
	fadd	%st(0), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:990: 		r_refdef.viewangles[YAW] += lcd_yaw.value*2; */
	fadds	_r_refdef+128	# r_refdef.viewangles[1]
	fstps	_r_refdef+128	# r_refdef.viewangles[1]
	flds	_lcd_x+16	# lcd_x.value
	fadd	%st(0), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:992: 			r_refdef.vieworg[i] += 2*right[i]*lcd_x.value; */
	flds	_right	# right[0]
	fmul	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:992: 			r_refdef.vieworg[i] += 2*right[i]*lcd_x.value; */
	fadds	_r_refdef+112	# r_refdef.vieworg[0]
	fstps	_r_refdef+112	# r_refdef.vieworg[0]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:992: 			r_refdef.vieworg[i] += 2*right[i]*lcd_x.value; */
	flds	_right+4	# right[1]
	fmul	%st(1), %st	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:992: 			r_refdef.vieworg[i] += 2*right[i]*lcd_x.value; */
	fadds	_r_refdef+116	# r_refdef.vieworg[1]
	fstps	_r_refdef+116	# r_refdef.vieworg[1]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:992: 			r_refdef.vieworg[i] += 2*right[i]*lcd_x.value; */
	fmuls	_right+8	# right[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:992: 			r_refdef.vieworg[i] += 2*right[i]*lcd_x.value; */
	fadds	_r_refdef+120	# r_refdef.vieworg[2]
	fstps	_r_refdef+120	# r_refdef.vieworg[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:993: 		R_RenderView (); */
	call	_R_RenderView	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:995: 		vid.buffer -= vid.rowbytes>>1; */
	movl	_vid+16, %ecx	# vid.rowbytes, _33
	shrl	$1, %ecx	#, _33
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:995: 		vid.buffer -= vid.rowbytes>>1; */
	subl	%ecx, _vid	# _33, vid.buffer
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:997: 		r_refdef.vrect.height <<= 1; */
	sall	$1, _r_refdef+12	#, r_refdef.vrect.height
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:999: 		vid.rowbytes >>= 1; */
	movl	%ecx, _vid+16	# _33, vid.rowbytes
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1000: 		vid.aspect *= 2; */
	flds	_vid+28	# vid.aspect
	fadd	%st(0), %st	#,
	fstps	_vid+28	# vid.aspect
L180:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1007: 	if (crosshair.value) */
	fldz
	fcomps	_crosshair+16	# crosshair.value
	fnstsw	%ax	# tmp334
	testb	$64, %ah	#, tmp334
	je	L190	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1011: } */
	addl	$28, %esp	#,
	ret
	.p2align 4
	.p2align 3
L187:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:950: 		Cvar_Set ("scr_ofsx", "0"); */
	subl	$8, %esp	#,
	pushl	$LC29	#
	pushl	$LC30	#
	call	_Cvar_Set	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:951: 		Cvar_Set ("scr_ofsy", "0"); */
	popl	%eax	#
	popl	%edx	#
	pushl	$LC29	#
	pushl	$LC31	#
	call	_Cvar_Set	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:952: 		Cvar_Set ("scr_ofsz", "0"); */
	popl	%ecx	#
	popl	%eax	#
	pushl	$LC29	#
	pushl	$LC32	#
	call	_Cvar_Set	#
	addl	$16, %esp	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:955: 	if (cl.intermission) */
	movl	_cl+548, %ecx	# cl.intermission,
	testl	%ecx, %ecx	#
	je	L177	#,
L188:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:790: 	ent = &cl_entities[cl.viewentity]; */
	movl	_cl+2680, %ecx	# cl.viewentity, _90
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:794: 	VectorCopy (ent->origin, r_refdef.vieworg); */
	leal	(%ecx,%ecx,4), %eax	#, tmp169
	addl	%eax, %eax	# tmp169, tmp170
	addl	%ecx, %eax	# _90, tmp171
	leal	(%ecx,%eax,4), %edx	#, tmp173
	leal	_cl_entities(,%edx,4), %ecx	#, tmp175
	flds	84(%ecx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_90].origin[0]
	fstps	_r_refdef+112	# r_refdef.vieworg[0]
	flds	88(%ecx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_90].origin[1]
	fstps	_r_refdef+116	# r_refdef.vieworg[1]
	flds	92(%ecx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_90].origin[2]
	fstps	_r_refdef+120	# r_refdef.vieworg[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:795: 	VectorCopy (ent->angles, r_refdef.viewangles); */
	flds	120(%ecx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_90].angles[0]
	fstps	_r_refdef+124	# r_refdef.viewangles[0]
	flds	124(%ecx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_90].angles[1]
	fstps	_r_refdef+128	# r_refdef.viewangles[1]
	flds	128(%ecx)	# MEM <struct entity_t[600]> [(struct entity_t *)&cl_entities][_90].angles[2]
	fstps	_r_refdef+132	# r_refdef.viewangles[2]
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:796: 	view->model = NULL; */
	movl	$0, _cl+2840	#, MEM[(struct entity_t *)&cl + 2708B].model
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:799: 	old = v_idlescale.value; */
	flds	_v_idlescale+16	# v_idlescale.value
	fstps	8(%esp)	# %sfp
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:800: 	v_idlescale.value = 1; */
	movl	$0x3f800000, _v_idlescale+16	#, v_idlescale.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:801: 	V_AddIdle (); */
	call	_V_AddIdle	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:802: 	v_idlescale.value = old; */
	flds	8(%esp)	# %sfp
	fstps	_v_idlescale+16	# v_idlescale.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:803: } */
	jmp	L178	#
	.p2align 4
	.p2align 3
L184:
	ret
	.p2align 4
	.p2align 3
L190:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1008: 		Draw_Character (scr_vrect.x + scr_vrect.width/2 + cl_crossx.value, */
	pushl	%eax	#
	pushl	$43	#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1009: 			scr_vrect.y + scr_vrect.height/2 + cl_crossy.value, '+'); */
	movl	_scr_vrect+12, %edx	# scr_vrect.height, scr_vrect.height
	movl	%edx, %ecx	# scr_vrect.height, tmp338
	shrl	$31, %ecx	#, tmp338
	addl	%edx, %ecx	# scr_vrect.height, tmp339
	sarl	$1, %ecx	#, tmp340
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1009: 			scr_vrect.y + scr_vrect.height/2 + cl_crossy.value, '+'); */
	addl	_scr_vrect+4, %ecx	# scr_vrect.y, tmp342
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1009: 			scr_vrect.y + scr_vrect.height/2 + cl_crossy.value, '+'); */
	movl	%ecx, 16(%esp)	# tmp342, %sfp
	fildl	16(%esp)	# %sfp
	fadds	_cl_crossy+16	# cl_crossy.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1008: 		Draw_Character (scr_vrect.x + scr_vrect.width/2 + cl_crossx.value, */
	fnstcw	22(%esp)	#
	movw	22(%esp), %ax	#, tmp361
	orb	$12, %ah	#, tmp361
	movw	%ax, 20(%esp)	# tmp361,
	fldcw	20(%esp)		#
	fistpl	16(%esp)	# %sfp
	fldcw	22(%esp)		#
	movl	16(%esp), %edx	# %sfp, tmp347
	pushl	%edx	# tmp347
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1008: 		Draw_Character (scr_vrect.x + scr_vrect.width/2 + cl_crossx.value, */
	movl	_scr_vrect+8, %ecx	# scr_vrect.width, scr_vrect.width
	movl	%ecx, %eax	# scr_vrect.width, tmp351
	shrl	$31, %eax	#, tmp351
	addl	%ecx, %eax	# scr_vrect.width, tmp352
	sarl	$1, %eax	#, tmp353
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1008: 		Draw_Character (scr_vrect.x + scr_vrect.width/2 + cl_crossx.value, */
	addl	_scr_vrect, %eax	# scr_vrect.x, tmp355
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1008: 		Draw_Character (scr_vrect.x + scr_vrect.width/2 + cl_crossx.value, */
	movl	%eax, 20(%esp)	# tmp355, %sfp
	fildl	20(%esp)	# %sfp
	fadds	_cl_crossx+16	# cl_crossx.value
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1008: 		Draw_Character (scr_vrect.x + scr_vrect.width/2 + cl_crossx.value, */
	fldcw	24(%esp)		#
	fistpl	20(%esp)	# %sfp
	fldcw	26(%esp)		#
	movl	20(%esp), %edx	# %sfp, tmp360
	pushl	%edx	# tmp360
	call	_Draw_Character	#
	addl	$16, %esp	#,
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1011: } */
	addl	$28, %esp	#,
	ret
	.p2align 4
	.p2align 3
L179:
	fstp	%st(0)		#
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:1004: 		R_RenderView (); */
	call	_R_RenderView	#
	jmp	L180	#
	.p2align 4
	.p2align 3
L189:
/* workspace\quake\out\view-control-worktree-20261008\src\view.c:962: 			V_CalcRefdef (); */
	call	_V_CalcRefdef	#
	jmp	L178	#

.data
/* Typed original constants, never executable bytes. */
.p2align 3
LC3:
	.long	1065353216
	.p2align 3
.p2align 3
LC4:
	.long	1413754136
	.long	1074340347
	.p2align 3
.p2align 3
LC5:
	.long	1717986918
	.long	1072064102
	.p2align 3
.p2align 3
LC6:
	.long	858993459
	.long	1070805811
	.p2align 2
.p2align 3
LC7:
	.long	-1059061760
	.p2align 2
.p2align 3
LC8:
	.long	1082130432
	.p2align 2
.p2align 3
LC9:
	.long	1056964608
	.p2align 2
.p2align 3
LC10:
	.long	1092616192
	.p2align 3
.p2align 3
LC13:
	.long	1127481344
	.p2align 2
.p2align 3
LC14:
	.long	1135869952
	.p2align 3
.p2align 3
LC15:
	.long	-1717986918
	.long	1071225241
	.p2align 2
.p2align 3
LC16:
	.long	-1054867456
	.p2align 2
.p2align 3
LC17:
	.long	1101004800
	.p2align 2
.p2align 3
LC18:
	.long	1096810496
	.p2align 2
.p2align 3
LC19:
	.long	1102053376
	.p2align 2
.p2align 3
LC20:
	.long	1106247680
	.p2align 2
.p2align 3
LC21:
	.long	1117782016
	.p2align 2
.p2align 3
LC22:
	.long	-1052770304
	.p2align 2
.p2align 3
LC23:
	.long	1023410176
	.p2align 2
.p2align 3
LC24:
	.long	1121714176
	.p2align 2
.p2align 3
LC25:
	.long	1120403456
	.p2align 2
.p2align 3
LC26:
	.long	1073741824
	.p2align 2
.p2align 3
LC27:
	.long	1119092736
	.p2align 2
.p2align 3
LC28:
	.long	1094713344
.p2align 3
LC29:
	.ascii "0\0"
.p2align 3
LC30:
	.ascii "scr_ofsx\0"
.p2align 3
LC31:
	.ascii "scr_ofsy\0"
.p2align 3
LC32:
	.ascii "scr_ofsz\0"
	.p2align 3
