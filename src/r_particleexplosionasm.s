/*
 * Assembly equivalent of src/r_part.c:R_ParticleExplosion.
 *
 * Keep the list mutation and seven rand calls per particle in source order.
 * The modulo operations use signed IDIV so they implement C's signed remainder
 * even for a test provider that supplies negative values. The standard C
 * rand() contract is nonnegative; the signed cases in the BENCH fixture make
 * this property auditable rather than relying on power-of-two masking.
 */
#include "asm_i386.h"
#include "quakeasm.h"

#if id386 && (defined(ASM486_PARTICLE_EXPLOSION) || defined(BENCH486))

	.arch i486
	.arch .387
	.code32

	.set pe_particle_org, 0
	.set pe_particle_color, 12
	.set pe_particle_type, 13
	.set pe_particle_next, 16
	.set pe_particle_vel, 20
	.set pe_particle_ramp, 32
	.set pe_particle_die, 36
	.set pe_client_time, 572

	.extern C(active_particles)
	.extern C(free_particles)
	.extern C(cl)
	.extern C(ramp1)
#ifdef BENCH486
	.extern C(Bench486ParticleExplosionRand)
#define PARTICLE_EXPLOSION_RAND C(Bench486ParticleExplosionRand)
#else
	.extern C(rand)
#define PARTICLE_EXPLOSION_RAND C(rand)
#endif

	.text
	.p2align 4,,15
	.globl C(R_ParticleExplosion_asm486)
#ifdef ASM486_PARTICLE_EXPLOSION
	.globl C(R_ParticleExplosion)
#endif
C(R_ParticleExplosion_asm486):
#ifdef ASM486_PARTICLE_EXPLOSION
C(R_ParticleExplosion):
#endif
	/* cdecl: org pointer at 8(ebp); preserve EBX, ESI and EDI. */
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$8,%esp

	movl	8(%ebp),%esi			/* input origin */
	movl	$0,-16(%ebp)			/* i */

.Lpe_particle_loop:
	cmpl	$1024,-16(%ebp)
	jge	.Lpe_return
	movl	C(free_particles),%edi
	testl	%edi,%edi
	jz	.Lpe_return			/* stop at exact free-list exhaustion */

	/* Pop from free_particles and prepend to active_particles. */
	movl	pe_particle_next(%edi),%eax
	movl	%eax,C(free_particles)
	movl	C(active_particles),%eax
	movl	%eax,pe_particle_next(%edi)
	movl	%edi,C(active_particles)

	/* p->die = cl.time + 5; narrow the double expression to float. */
	fldl	C(cl)+pe_client_time
	faddl	.Lpe_five
	fstps	pe_particle_die(%edi)

	/* p->color = ramp1[0], narrowed to the particle palette byte. */
	movl	C(ramp1),%eax
	movb	%al,pe_particle_color(%edi)

	/* p->ramp = rand() & 3; C converts this int to float. */
	call	PARTICLE_EXPLOSION_RAND
	andl	$3,%eax
	pushl	%eax
	fildl	(%esp)
	fstps	pe_particle_ramp(%edi)
	addl	$4,%esp

	/* Keep the original alternating particle type. */
	testl	$1,-16(%ebp)
	jnz	.Lpe_odd_type
	movb	$5,pe_particle_type(%edi)	/* pt_explode2 */
	jmp	.Lpe_type_ready
.Lpe_odd_type:
	movb	$4,pe_particle_type(%edi)	/* pt_explode */
.Lpe_type_ready:
	movl	$0,-20(%ebp)			/* j */

.Lpe_axis_loop:
	/* org[j] = org[j] + ((rand() % 32) - 16), signed C remainder. */
	call	PARTICLE_EXPLOSION_RAND
	cltd
	movl	$32,%ecx
	idivl	%ecx
	subl	$16,%edx
	pushl	%edx
	movl	-20(%ebp),%ecx
	flds	(%esi,%ecx,4)
	fildl	(%esp)
	faddp	%st(0),%st(1)
	fstps	pe_particle_org(%edi,%ecx,4)
	addl	$4,%esp

	/* vel[j] = (rand() % 512) - 256, also with signed C remainder. */
	call	PARTICLE_EXPLOSION_RAND
	cltd
	movl	$512,%ecx
	idivl	%ecx
	subl	$256,%edx
	pushl	%edx
	movl	-20(%ebp),%ecx
	fildl	(%esp)
	fstps	pe_particle_vel(%edi,%ecx,4)
	addl	$4,%esp

	incl	-20(%ebp)
	cmpl	$3,-20(%ebp)
	jl	.Lpe_axis_loop

	incl	-16(%ebp)
	jmp	.Lpe_particle_loop

.Lpe_return:
	addl	$8,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

	.section .rodata
	.p2align 3
.Lpe_five:
	.double	5.0

#endif
