/*
 * Assembly equivalent of src/r_part.c:R_TeleportSplash.
 *
 * The 8 x 8 x 14 lattice, early free-list return, prepended active-list order,
 * six rand calls per particle, and floating-point helper sequence follow the
 * C reference. VectorNormalize and VectorScale remain shared C routines.
 */
#include "asm_i386.h"
#include "quakeasm.h"

#if id386 && (defined(ASM486_TELEPORT_SPLASH) || defined(BENCH486))

	.arch i486
	.arch .387
	.code32

	.set ts_particle_org, 0
	.set ts_particle_color, 12
	.set ts_particle_type, 13
	.set ts_particle_next, 16
	.set ts_particle_vel, 20
	.set ts_particle_die, 36
	.set ts_client_time, 572
	.set ts_pt_slowgrav, 2

	.extern C(active_particles)
	.extern C(free_particles)
	.extern C(cl)
	.extern C(VectorNormalize)
	.extern C(VectorScale)
#ifdef BENCH486
	.extern C(Bench486TeleportSplashRand)
#define TELEPORT_SPLASH_RAND C(Bench486TeleportSplashRand)
#else
	.extern C(rand)
#define TELEPORT_SPLASH_RAND C(rand)
#endif

	.text
	.p2align 4,,15
	.globl C(R_TeleportSplash_asm486)
#ifdef ASM486_TELEPORT_SPLASH
	.globl C(R_TeleportSplash)
#endif
C(R_TeleportSplash_asm486):
#ifdef ASM486_TELEPORT_SPLASH
C(R_TeleportSplash):
#endif
	/* cdecl: origin is at 8(ebp); preserve all callee-saved registers. */
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$32,%esp

	movl	8(%ebp),%esi			/* input origin */
	movl	$-16,-16(%ebp)		/* i: outer lattice coordinate */

.Lts_outer_loop:
	cmpl	$16,-16(%ebp)
	jge	.Lts_return
	movl	$-16,-20(%ebp)		/* j: middle lattice coordinate */

.Lts_middle_loop:
	cmpl	$16,-20(%ebp)
	jge	.Lts_next_i
	movl	$-24,-24(%ebp)		/* k: inner lattice coordinate */

.Lts_inner_loop:
	cmpl	$32,-24(%ebp)
	jge	.Lts_next_j
	movl	C(free_particles),%ebx
	testl	%ebx,%ebx
	jz	.Lts_return			/* C returns before consuming RNG */

	/* Pop the free head and prepend the node to the active list. */
	movl	ts_particle_next(%ebx),%eax
	movl	%eax,C(free_particles)
	movl	C(active_particles),%eax
	movl	%eax,ts_particle_next(%ebx)
	movl	%ebx,C(active_particles)

	/* die = cl.time + 0.2 + (rand()&7)*0.02; store as float. */
	call	TELEPORT_SPLASH_RAND
	andl	$7,%eax
	movl	%eax,-28(%ebp)
	fildl	-28(%ebp)
	fmull	.Lts_point_zero_two
	fldl	C(cl)+ts_client_time
	faddl	.Lts_point_two
	faddp	%st,%st(1)
	fstps	ts_particle_die(%ebx)

	/* color = 7 + (rand()&7), type = pt_slowgrav. */
	call	TELEPORT_SPLASH_RAND
	andl	$7,%eax
	addl	$7,%eax
	movb	%al,ts_particle_color(%ebx)
	movb	$ts_pt_slowgrav,ts_particle_type(%ebx)

	/* Direction uses the transposed i/j axes from the origin coordinates. */
	movl	-20(%ebp),%eax
	shll	$3,%eax
	movl	%eax,-28(%ebp)
	fildl	-28(%ebp)
	fstps	-44(%ebp)			/* dir[0] = j*8 */
	movl	-16(%ebp),%eax
	shll	$3,%eax
	movl	%eax,-28(%ebp)
	fildl	-28(%ebp)
	fstps	-40(%ebp)			/* dir[1] = i*8 */
	movl	-24(%ebp),%eax
	shll	$3,%eax
	movl	%eax,-28(%ebp)
	fildl	-28(%ebp)
	fstps	-36(%ebp)			/* dir[2] = k*8 */

	/* org[0] = origin.x + i + (rand()&3), rounded on particle store. */
	call	TELEPORT_SPLASH_RAND
	andl	$3,%eax
	movl	%eax,-28(%ebp)
	flds	0(%esi)
	fiaddl	-16(%ebp)
	fiaddl	-28(%ebp)
	fstps	ts_particle_org(%ebx)

	/* org[1] = origin.y + j + (rand()&3). */
	call	TELEPORT_SPLASH_RAND
	andl	$3,%eax
	movl	%eax,-28(%ebp)
	flds	4(%esi)
	fiaddl	-20(%ebp)
	fiaddl	-28(%ebp)
	fstps	ts_particle_org+4(%ebx)

	/* org[2] = origin.z + k + (rand()&3). */
	call	TELEPORT_SPLASH_RAND
	andl	$3,%eax
	movl	%eax,-28(%ebp)
	flds	8(%esi)
	fiaddl	-24(%ebp)
	fiaddl	-28(%ebp)
	fstps	ts_particle_org+8(%ebx)

	/* Keep the C normalizer/scaler and discard Normalize's float return. */
	leal	-44(%ebp),%eax
	pushl	%eax
	call	C(VectorNormalize)
	addl	$4,%esp
	fstp	%st(0)

	/* vel = 50 + (rand()&63); VectorScale(dir, vel, p->vel). */
	call	TELEPORT_SPLASH_RAND
	andl	$63,%eax
	addl	$50,%eax
	movl	%eax,-28(%ebp)
	fildl	-28(%ebp)
	fstps	-32(%ebp)
	leal	ts_particle_vel(%ebx),%eax
	pushl	%eax				/* out = p->vel */
	pushl	-32(%ebp)			/* scale = vel */
	leal	-44(%ebp),%eax
	pushl	%eax				/* in = dir */
	call	C(VectorScale)
	addl	$12,%esp

	addl	$4,-24(%ebp)
	jmp	.Lts_inner_loop

.Lts_next_j:
	addl	$4,-20(%ebp)
	jmp	.Lts_middle_loop

.Lts_next_i:
	addl	$4,-16(%ebp)
	jmp	.Lts_outer_loop

.Lts_return:
	addl	$32,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

	.section .rodata
	.p2align 3
.Lts_point_zero_two:
	.double	0.02
.Lts_point_two:
	.double	0.2

#undef TELEPORT_SPLASH_RAND

#endif
