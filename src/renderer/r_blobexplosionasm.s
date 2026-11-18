/*
 * Assembly equivalent of src/renderer/r_part.c:R_BlobExplosion.
 *
 * The list updates, x87 operation order, particle-type alternation and eight
 * random calls per emitted particle follow the C oracle.  IDIV is used for
 * each signed C remainder; no post-486 integer instruction is needed.
 */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"
#include "quakeasm.h"

#if id386 && (defined(ASM486_BLOB_EXPLOSION) || defined(BENCH486))

	.arch i486
	.arch .387
	.code32

	.set be_particle_org, 0
	.set be_particle_color, 12
	.set be_particle_type, 13
	.set be_particle_next, 16
	.set be_particle_vel, 20
	.set be_particle_die, 36
	.set be_client_time, 572

	.extern C(active_particles)
	.extern C(free_particles)
	.extern C(cl)
#ifdef BENCH486
	.extern C(Bench486BlobExplosionRand)
#define BLOB_EXPLOSION_RAND C(Bench486BlobExplosionRand)
#else
	.extern C(rand)
#define BLOB_EXPLOSION_RAND C(rand)
#endif

	.text
	.p2align 4,,15
	.globl C(R_BlobExplosion_asm486)
#ifdef ASM486_BLOB_EXPLOSION
	.globl C(R_BlobExplosion)
#endif
C(R_BlobExplosion_asm486):
#ifdef ASM486_BLOB_EXPLOSION
C(R_BlobExplosion):
#endif
	/* cdecl: org is at 8(ebp); preserve all callee-saved GPRs. */
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$24,%esp

	movl	8(%ebp),%esi			/* input origin */
	xorl	%edi,%edi			/* emitted count i */

.Lbe_particle_loop:
	cmpl	$1024,%edi
	jge	.Lbe_return
	movl	C(free_particles),%ebx
	testl	%ebx,%ebx
	jz	.Lbe_return			/* C exits at exact free-list exhaustion */

	/* Pop free node and prepend it to the active list, in C source order. */
	movl	be_particle_next(%ebx),%eax
	movl	%eax,C(free_particles)
	movl	C(active_particles),%eax
	movl	%eax,be_particle_next(%ebx)
	movl	%ebx,C(active_particles)

	/*
	 * Preserve cl.time across rand, just as the C compiler does.  The C
	 * reference's evaluated order is: double(0.05)*int(rand&8), then
	 * (saved_time + float(1.0)), then an x87 faddp and narrowing to float.
	 */
	fldl	C(cl)+be_client_time
	fstpl	-36(%ebp)
	call	BLOB_EXPLOSION_RAND
	andl	$8,%eax
	movl	%eax,-28(%ebp)
	fldl	.Lbe_point_zero_five
	fimull	-28(%ebp)
	fldl	-36(%ebp)
	fadds	.Lbe_one
	faddp	%st,%st(1)
	fstps	be_particle_die(%ebx)

	/* Odd particles are pt_blob/base 66; even are pt_blob2/base 150. */
	testl	$1,%edi
	jnz	.Lbe_odd_particle
	movb	$7,be_particle_type(%ebx)	/* pt_blob2 */
	movl	$150,-24(%ebp)
	jmp	.Lbe_type_ready
.Lbe_odd_particle:
	movb	$6,be_particle_type(%ebx)	/* pt_blob */
	movl	$66,-24(%ebp)
.Lbe_type_ready:

	/* color = base + rand()%6, preserving signed C remainder semantics. */
	call	BLOB_EXPLOSION_RAND
	cltd
	movl	$6,%ecx
	idivl	%ecx
	addl	-24(%ebp),%edx
	movb	%dl,be_particle_color(%ebx)

	movl	$0,-20(%ebp)			/* j */
.Lbe_axis_loop:
	/* org[j] = org[j] + ((rand()%32)-16). */
	call	BLOB_EXPLOSION_RAND
	cltd
	movl	$32,%ecx
	idivl	%ecx
	subl	$16,%edx
	movl	%edx,-28(%ebp)
	movl	-20(%ebp),%ecx
	flds	(%esi,%ecx,4)
	fiaddl	-28(%ebp)
	fstps	be_particle_org(%ebx,%ecx,4)

	/* vel[j] = (rand()%512)-256. */
	call	BLOB_EXPLOSION_RAND
	cltd
	movl	$512,%ecx
	idivl	%ecx
	subl	$256,%edx
	movl	%edx,-28(%ebp)
	fildl	-28(%ebp)
	movl	-20(%ebp),%ecx
	fstps	be_particle_vel(%ebx,%ecx,4)

	incl	-20(%ebp)
	cmpl	$3,-20(%ebp)
	jl	.Lbe_axis_loop

	incl	%edi
	jmp	.Lbe_particle_loop

.Lbe_return:
	addl	$24,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

	.section .rodata
	.p2align 3
.Lbe_point_zero_five:
	.double	0.05
.Lbe_one:
	.float	1.0

#endif
