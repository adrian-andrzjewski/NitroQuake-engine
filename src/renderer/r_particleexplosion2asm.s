/*
 * R_ParticleExplosion2: emit the 512 color-mapped explosion particles.
 *
 * The register allocation and field offsets are local to this leaf and are
 * checked against particle_t/client_state_t in r_part.c. Keep the two rand()
 * calls per axis in source order; that order is part of the visible effect and
 * of the deterministic C-versus-assembly fixture.
 */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"
#include "quakeasm.h"

#if id386 && (defined(ASM486_PARTICLE_EXPLOSION2) || defined(BENCH486))

	.arch i486
	.arch .387
	.code32

	.set pe2_particle_org, 0
	.set pe2_particle_color, 12
	.set pe2_particle_type, 13
	.set pe2_particle_next, 16
	.set pe2_particle_vel, 20
	.set pe2_particle_die, 36
	.set pe2_cl_time, 572

	.extern C(active_particles)
	.extern C(free_particles)
	.extern C(cl)
	.extern C(rand)

	.text
	.p2align 4,,15
	.globl C(R_ParticleExplosion2_asm486)
#ifdef ASM486_PARTICLE_EXPLOSION2
	.globl C(R_ParticleExplosion2)
#endif
C(R_ParticleExplosion2_asm486):
#ifdef ASM486_PARTICLE_EXPLOSION2
C(R_ParticleExplosion2):
#endif
	/* cdecl: org, colorStart, colorLength. Preserve ebx/esi/edi. */
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

	movl	8(%ebp),%esi			/* org */
	movl	12(%ebp),%ebx			/* colorStart */
	movl	16(%ebp),%eax			/* colorLength */
	movl	%eax,-16(%ebp)
	movl	$0,-20(%ebp)			/* colorMod */
	movl	$512,-28(%ebp)		/* remaining particles */

.Lpe2_particle_loop:
	movl	C(free_particles),%edi
	testl	%edi,%edi
	jz	.Lpe2_return			/* exact early-exhaustion boundary */

	/* Pop free head, then push the particle onto the active list. */
	movl	pe2_particle_next(%edi),%eax
	movl	%eax,C(free_particles)
	movl	C(active_particles),%eax
	movl	%eax,pe2_particle_next(%edi)
	movl	%edi,C(active_particles)

	/* C expression: p->die = cl.time + 0.3; */
	fldl	C(cl)+pe2_cl_time
	faddl	.Lpe2_lifetime
	fstps	pe2_particle_die(%edi)

	/* Preserve signed C remainder for the general colorLength parameter. */
	movl	-20(%ebp),%eax
	cltd
	movl	-16(%ebp),%ecx
	idivl	%ecx
	addl	%ebx,%edx
	movb	%dl,pe2_particle_color(%edi)
	movb	$6,pe2_particle_type(%edi)	/* pt_blob */
	movl	$0,-24(%ebp)			/* j */

.Lpe2_axis_loop:
	/* org[j] = org[j] + ((rand() % 32) - 16); */
	call	C(rand)
	andl	$31,%eax
	subl	$16,%eax
	pushl	%eax
	movl	-24(%ebp),%ecx
	flds	(%esi,%ecx,4)
	fildl	(%esp)
	faddp	%st(0),%st(1)
	fstps	pe2_particle_org(%edi,%ecx,4)
	addl	$4,%esp

	/* vel[j] = (rand() % 512) - 256; */
	call	C(rand)
	andl	$511,%eax
	subl	$256,%eax
	pushl	%eax
	movl	-24(%ebp),%ecx
	fildl	(%esp)
	fstps	pe2_particle_vel(%edi,%ecx,4)
	addl	$4,%esp

	incl	-24(%ebp)
	cmpl	$3,-24(%ebp)
	jl	.Lpe2_axis_loop

	incl	-20(%ebp)			/* colorMod++ */
	decl	-28(%ebp)
	jnz	.Lpe2_particle_loop

.Lpe2_return:
	addl	$16,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

	.section .rodata
	.p2align 3
.Lpe2_lifetime:
	.double	0.3

#endif
