/* Reset the particle free list using the C renderer's particle_t layout. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"
#include "quakeasm.h"
#include "renderer/asm_particlelist.h"

#if id386 && (defined(ASM486_PARTICLE_UPDATE) || defined(BENCH486))

	.arch i486
	.code32
	.extern C(active_particles)
	.extern C(free_particles)
	.extern C(particles)
	.extern C(r_numparticles)

	.text
	.p2align 4,,15
	.globl C(R_ClearParticles_asm486)
#ifdef ASM486_PARTICLE_UPDATE
	.globl C(R_ClearParticles)
#endif
C(R_ClearParticles_asm486):
#ifdef ASM486_PARTICLE_UPDATE
C(R_ClearParticles):
#endif
	// C publishes the list head, clears active particles, then links each node.
	movl	C(particles),%eax
	movl	%eax,C(free_particles)
	movl	$0,C(active_particles)
	movl	C(r_numparticles),%ecx
	testl	%ecx,%ecx
	jle	.Lparticle_list_nonpositive

	// Match the C loop, including its final one-past link store before the
	// reference's final particles[count-1].next = NULL store.
.Lparticle_list_link:
	leal	particle_list_size(%eax),%edx
	movl	%edx,particle_list_next(%eax)
	addl	$particle_list_size,%eax
	decl	%ecx
	jnz	.Lparticle_list_link
	movl	$0,-particle_list_last_next_delta(%eax)
	ret

.Lparticle_list_nonpositive:
	// Initialization normally uses a positive count. Preserve the reference's
	// final indexed store for the zero/negative fixture without entering a loop.
	imull	$particle_list_size,%ecx,%edx
	leal	-particle_list_last_next_delta(%eax,%edx),%edx
	movl	$0,(%edx)
	ret

#endif
