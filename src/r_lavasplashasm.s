/*
 * Assembly equivalent of src/r_part.c:R_LavaSplash.
 *
 * The fixed 32-by-32 grid, free/active-list updates, six rand calls per
 * particle, and C expression order are kept explicit. VectorNormalize and
 * VectorScale remain shared C helpers so the first port uses the exact same
 * audited floating-point routines as the reference path.
 */
#include "asm_i386.h"
#include "quakeasm.h"

#if id386 && (defined(ASM486_LAVA_SPLASH) || defined(BENCH486))

	.arch i486
	.arch .387
	.code32

	.set ls_particle_org, 0
	.set ls_particle_color, 12
	.set ls_particle_type, 13
	.set ls_particle_next, 16
	.set ls_particle_vel, 20
	.set ls_particle_die, 36
	.set ls_client_time, 572
	.set ls_pt_slowgrav, 2

	.extern C(active_particles)
	.extern C(free_particles)
	.extern C(cl)
	.extern C(VectorNormalize)
	.extern C(VectorScale)
#ifdef BENCH486
	.extern C(Bench486LavaSplashRand)
#define LAVA_SPLASH_RAND C(Bench486LavaSplashRand)
#else
	.extern C(rand)
#define LAVA_SPLASH_RAND C(rand)
#endif

	.text
	.p2align 4,,15
	.globl C(R_LavaSplash_asm486)
#ifdef ASM486_LAVA_SPLASH
	.globl C(R_LavaSplash)
#endif
C(R_LavaSplash_asm486):
#ifdef ASM486_LAVA_SPLASH
C(R_LavaSplash):
#endif
	/* cdecl: origin is at 8(ebp); preserve all callee-saved registers. */
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$32,%esp

	movl	8(%ebp),%esi			/* input origin */
	movl	$-16,-16(%ebp)		/* i: outer grid row */

.Lls_outer_loop:
	cmpl	$16,-16(%ebp)
	jge	.Lls_return
	movl	$-16,-20(%ebp)		/* j: inner grid column */

.Lls_inner_loop:
	cmpl	$16,-20(%ebp)
	jge	.Lls_next_row
	movl	C(free_particles),%ebx
	testl	%ebx,%ebx
	jz	.Lls_return			/* C returns at exact free-list exhaustion */

	/* Pop the free head and prepend it to the active list. */
	movl	ls_particle_next(%ebx),%eax
	movl	%eax,C(free_particles)
	movl	C(active_particles),%eax
	movl	%eax,ls_particle_next(%ebx)
	movl	%ebx,C(active_particles)

	/* die = cl.time + 2 + (rand()&31)*0.02; round when stored to float. */
	call	LAVA_SPLASH_RAND
	andl	$31,%eax
	movl	%eax,-24(%ebp)
	fildl	-24(%ebp)
	fmull	.Lls_point_zero_two
	fldl	C(cl)+ls_client_time
	faddl	.Lls_two
	faddp	%st,%st(1)
	fstps	ls_particle_die(%ebx)

	/* Palette and particle kind are byte fields in particle_t. */
	call	LAVA_SPLASH_RAND
	andl	$7,%eax
	addl	$224,%eax
	movb	%al,ls_particle_color(%ebx)
	movb	$ls_pt_slowgrav,ls_particle_type(%ebx)

	/* dir[0] = j*8 + (rand()&7); convert the integer to float. */
	call	LAVA_SPLASH_RAND
	andl	$7,%eax
	movl	-20(%ebp),%ecx
	shll	$3,%ecx
	addl	%eax,%ecx
	movl	%ecx,-24(%ebp)
	fildl	-24(%ebp)
	fstps	-40(%ebp)			/* dir[0] */

	/* dir[1] = i*8 + (rand()&7). */
	call	LAVA_SPLASH_RAND
	andl	$7,%eax
	movl	-16(%ebp),%ecx
	shll	$3,%ecx
	addl	%eax,%ecx
	movl	%ecx,-24(%ebp)
	fildl	-24(%ebp)
	fstps	-36(%ebp)			/* dir[1] */
	movl	$0x43800000,-32(%ebp)	/* dir[2] = 256.0f */

	/* The C assignments round each stored origin component to float. */
	flds	0(%esi)
	fadds	-40(%ebp)
	fstps	ls_particle_org(%ebx)
	flds	4(%esi)
	fadds	-36(%ebp)
	fstps	ls_particle_org+4(%ebx)
	call	LAVA_SPLASH_RAND
	andl	$63,%eax
	movl	%eax,-24(%ebp)
	flds	8(%esi)
	fiaddl	-24(%ebp)
	fstps	ls_particle_org+8(%ebx)

	/* Reuse the same C helpers and operation sequence as the C oracle. */
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(VectorNormalize)
	addl	$4,%esp
	fstp	%st(0)			/* discard returned length */

	/* vel = 50 + (rand()&63); VectorScale(dir, vel, p->vel). */
	call	LAVA_SPLASH_RAND
	andl	$63,%eax
	addl	$50,%eax
	movl	%eax,-24(%ebp)
	fildl	-24(%ebp)
	fstps	-28(%ebp)
	leal	ls_particle_vel(%ebx),%eax
	pushl	%eax				/* out = p->vel */
	pushl	-28(%ebp)			/* scale = vel */
	leal	-40(%ebp),%eax
	pushl	%eax				/* in = dir */
	call	C(VectorScale)
	addl	$12,%esp

	incl	-20(%ebp)
	jmp	.Lls_inner_loop

.Lls_next_row:
	incl	-16(%ebp)
	jmp	.Lls_outer_loop

.Lls_return:
	addl	$32,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

	.section .rodata
	.p2align 3
.Lls_point_zero_two:
	.double	0.02
.Lls_two:
	.double	2.0

#undef LAVA_SPLASH_RAND

#endif
