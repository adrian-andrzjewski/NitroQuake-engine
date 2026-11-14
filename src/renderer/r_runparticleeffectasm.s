/*
 * Assembly equivalent of src/renderer/r_part.c:R_RunParticleEffect.
 *
 * The ordinary impact path uses five random values per emitted particle.
 * The count==1024 rocket-explosion path uses seven and alternates the two
 * explosion types. Keep the random calls in the source order: they are part
 * of Quake's visible particle state and the libc RNG stream.
 */
#include "asm_i386.h"
#include "quakeasm.h"

#if id386 && (defined(ASM486_RUN_PARTICLE_EFFECT) || defined(BENCH486))

	.arch i486
	.arch .387
	.code32

	.set rpe_particle_org, 0
	.set rpe_particle_color, 12
	.set rpe_particle_type, 13
	.set rpe_particle_next, 16
	.set rpe_particle_vel, 20
	.set rpe_particle_ramp, 32
	.set rpe_particle_die, 36
	.set rpe_client_time, 572

	.extern C(active_particles)
	.extern C(free_particles)
	.extern C(cl)
	.extern C(ramp1)
#ifdef BENCH486
	.extern C(Bench486RunParticleEffectRand)
#define RUN_PARTICLE_EFFECT_RAND C(Bench486RunParticleEffectRand)
#else
	.extern C(rand)
#define RUN_PARTICLE_EFFECT_RAND C(rand)
#endif

	.text
	.p2align 4,,15
	.globl C(R_RunParticleEffect_asm486)
#ifdef ASM486_RUN_PARTICLE_EFFECT
	.globl C(R_RunParticleEffect)
#endif
C(R_RunParticleEffect_asm486):
#ifdef ASM486_RUN_PARTICLE_EFFECT
C(R_RunParticleEffect):
#endif
	/* cdecl arguments: org, dir, color, count. Preserve EBX, ESI and EDI. */
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

	movl	8(%ebp),%esi			/* origin vector */
	movl	12(%ebp),%ebx			/* direction vector */
	movl	16(%ebp),%eax
	andl	$-8,%eax
	movl	%eax,-24(%ebp)			/* color with low three bits clear */
	movl	20(%ebp),%eax
	movl	%eax,-28(%ebp)			/* exact count selects the explosion path */
	movl	$0,-16(%ebp)			/* i */

.Lrpe_particle_loop:
	movl	-16(%ebp),%eax
	cmpl	-28(%ebp),%eax
	jge	.Lrpe_return
	movl	C(free_particles),%edi
	testl	%edi,%edi
	jz	.Lrpe_return			/* match C's early free-list exhaustion */

	/* Pop one free particle and prepend it to active_particles. */
	movl	rpe_particle_next(%edi),%eax
	movl	%eax,C(free_particles)
	movl	C(active_particles),%eax
	movl	%eax,rpe_particle_next(%edi)
	movl	%edi,C(active_particles)

	cmpl	$1024,-28(%ebp)
	je	.Lrpe_rocket_explosion

	/* Slow-gravity impact: die = cl.time + 0.1 * signed(rand() % 5). */
	call	RUN_PARTICLE_EFFECT_RAND
	cltd
	movl	$5,%ecx
	idivl	%ecx
	pushl	%edx
	fildl	(%esp)
	fmull	.Lrpe_tenth
	faddl	C(cl)+rpe_client_time
	fstps	rpe_particle_die(%edi)
	addl	$4,%esp

	/* Preserve the original color mask and random-call order. */
	call	RUN_PARTICLE_EFFECT_RAND
	andl	$7,%eax
	addl	-24(%ebp),%eax
	movb	%al,rpe_particle_color(%edi)
	movb	$2,rpe_particle_type(%edi)	/* pt_slowgrav */
	movl	$0,-20(%ebp)			/* j */

.Lrpe_impact_axis_loop:
	/* org[j] = org[j] + ((rand() & 15) - 8). */
	call	RUN_PARTICLE_EFFECT_RAND
	andl	$15,%eax
	subl	$8,%eax
	pushl	%eax
	movl	-20(%ebp),%ecx
	flds	(%esi,%ecx,4)
	fildl	(%esp)
	faddp	%st(0),%st(1)
	fstps	rpe_particle_org(%edi,%ecx,4)
	addl	$4,%esp

	/* vel[j] = dir[j] * 15, rounded once on the particle float store. */
	movl	-20(%ebp),%ecx
	flds	(%ebx,%ecx,4)
	fmuls	.Lrpe_fifteen
	fstps	rpe_particle_vel(%edi,%ecx,4)

	incl	-20(%ebp)
	cmpl	$3,-20(%ebp)
	jl	.Lrpe_impact_axis_loop
	incl	-16(%ebp)
	jmp	.Lrpe_particle_loop

.Lrpe_rocket_explosion:
	/* The alternate branch is the original 1024-particle rocket effect. */
	fldl	C(cl)+rpe_client_time
	faddl	.Lrpe_five
	fstps	rpe_particle_die(%edi)
	movl	C(ramp1),%eax
	movb	%al,rpe_particle_color(%edi)
	call	RUN_PARTICLE_EFFECT_RAND
	andl	$3,%eax
	pushl	%eax
	fildl	(%esp)
	fstps	rpe_particle_ramp(%edi)
	addl	$4,%esp

	testl	$1,-16(%ebp)
	jnz	.Lrpe_rocket_odd
	movb	$5,rpe_particle_type(%edi)	/* pt_explode2 on even i */
	jmp	.Lrpe_rocket_type_ready
.Lrpe_rocket_odd:
	movb	$4,rpe_particle_type(%edi)	/* pt_explode on odd i */
.Lrpe_rocket_type_ready:
	movl	$0,-20(%ebp)			/* j */

.Lrpe_rocket_axis_loop:
	/* org[j] = org[j] + ((rand() % 32) - 16), with signed C remainder. */
	call	RUN_PARTICLE_EFFECT_RAND
	cltd
	movl	$32,%ecx
	idivl	%ecx
	subl	$16,%edx
	pushl	%edx
	movl	-20(%ebp),%ecx
	flds	(%esi,%ecx,4)
	fildl	(%esp)
	faddp	%st(0),%st(1)
	fstps	rpe_particle_org(%edi,%ecx,4)
	addl	$4,%esp

	/* vel[j] = (rand() % 512) - 256, also with signed C remainder. */
	call	RUN_PARTICLE_EFFECT_RAND
	cltd
	movl	$512,%ecx
	idivl	%ecx
	subl	$256,%edx
	pushl	%edx
	movl	-20(%ebp),%ecx
	fildl	(%esp)
	fstps	rpe_particle_vel(%edi,%ecx,4)
	addl	$4,%esp

	incl	-20(%ebp)
	cmpl	$3,-20(%ebp)
	jl	.Lrpe_rocket_axis_loop
	incl	-16(%ebp)
	jmp	.Lrpe_particle_loop

.Lrpe_return:
	addl	$16,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

	.section .rodata
	.p2align 3
.Lrpe_tenth:
	.double	0.1
.Lrpe_five:
	.double	5.0
.Lrpe_fifteen:
	.float	15.0

#endif
