/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "quakedef.h"
#include "r_local.h"
#include "asm_renderdispatch.h"

#if defined(ASM486_PARTICLE_UPDATE) && id386
#include <stddef.h>
typedef char particle_update_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char particle_update_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, ramp) == 32 &&
		offsetof(particle_t, die) == 36 &&
		sizeof(particle_t) == 40) ? 1 : -1];
#endif

#if (defined(ASM486_PARTICLE_EXPLOSION2) || defined(BENCH486)) && id386
#include <stddef.h>
typedef char particle_explosion2_i386_pointer_size[
		(sizeof(void *) == 4) ? 1 : -1];
typedef char particle_explosion2_particle_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, die) == 36 &&
		sizeof(((particle_t *)0)->die) == 4 &&
		sizeof(particle_t) == 40) ? 1 : -1];
typedef char particle_explosion2_client_time_offset[
		(offsetof(client_state_t, time) == 572) ? 1 : -1];
typedef char particle_explosion2_blob_type[(pt_blob == 6) ? 1 : -1];
#endif

#if (defined(ASM486_PARTICLE_EXPLOSION) || defined(BENCH486)) && id386
#include <stddef.h>
typedef char particle_explosion_i386_pointer_size[
		(sizeof(void *) == 4) ? 1 : -1];
typedef char particle_explosion_particle_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, ramp) == 32 &&
		offsetof(particle_t, die) == 36 &&
		sizeof(particle_t) == 40) ? 1 : -1];
typedef char particle_explosion_client_time_offset[
		(offsetof(client_state_t, time) == 572) ? 1 : -1];
typedef char particle_explosion_type_values[
		(pt_explode == 4 && pt_explode2 == 5) ? 1 : -1];
#endif

#if (defined(ASM486_RUN_PARTICLE_EFFECT) || defined(BENCH486)) && id386
#include <stddef.h>
typedef char run_particle_effect_i386_pointer_size[
		(sizeof(void *) == 4) ? 1 : -1];
typedef char run_particle_effect_particle_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, ramp) == 32 &&
		offsetof(particle_t, die) == 36 &&
		sizeof(particle_t) == 40) ? 1 : -1];
typedef char run_particle_effect_client_time_layout[
		(offsetof(client_state_t, time) == 572 &&
		sizeof(((client_state_t *)0)->time) == 8) ? 1 : -1];
typedef char run_particle_effect_type_values[
		(pt_slowgrav == 2 && pt_explode == 4 && pt_explode2 == 5) ? 1 : -1];
#endif

#if (defined(ASM486_ROCKET_TRAIL) || defined(BENCH486)) && id386
#include <stddef.h>
typedef char rocket_trail_i386_pointer_size[
		(sizeof(void *) == 4) ? 1 : -1];
typedef char rocket_trail_particle_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, ramp) == 32 &&
		offsetof(particle_t, die) == 36 &&
		sizeof(particle_t) == 40) ? 1 : -1];
typedef char rocket_trail_client_time_offset[
		(offsetof(client_state_t, time) == 572 &&
		sizeof(((client_state_t *)0)->time) == 8) ? 1 : -1];
typedef char rocket_trail_particle_types[
		(pt_static == 0 && pt_grav == 1 && pt_fire == 3) ? 1 : -1];
#endif

#if (defined(ASM486_BLOB_EXPLOSION) || defined(BENCH486)) && id386
#include <stddef.h>
typedef char blob_explosion_i386_pointer_size[
		(sizeof(void *) == 4) ? 1 : -1];
typedef char blob_explosion_particle_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, die) == 36 &&
		sizeof(((particle_t *)0)->die) == 4 &&
		sizeof(particle_t) == 40) ? 1 : -1];
typedef char blob_explosion_client_time_layout[
		(offsetof(client_state_t, time) == 572 &&
		sizeof(((client_state_t *)0)->time) == 8) ? 1 : -1];
typedef char blob_explosion_particle_types[
		(pt_blob == 6 && pt_blob2 == 7) ? 1 : -1];
#endif

#if (defined(ASM486_LAVA_SPLASH) || defined(BENCH486)) && id386
#include <stddef.h>
typedef char lava_splash_i386_pointer_size[
		(sizeof(void *) == 4) ? 1 : -1];
typedef char lava_splash_particle_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, ramp) == 32 &&
		offsetof(particle_t, die) == 36 &&
		sizeof(particle_t) == 40) ? 1 : -1];
typedef char lava_splash_client_time_layout[
		(offsetof(client_state_t, time) == 572 &&
		sizeof(((client_state_t *)0)->time) == 8) ? 1 : -1];
typedef char lava_splash_particle_type[(pt_slowgrav == 2) ? 1 : -1];
#endif

#if (defined(ASM486_TELEPORT_SPLASH) || defined(BENCH486)) && id386
#include <stddef.h>
typedef char teleport_splash_i386_pointer_size[
		(sizeof(void *) == 4) ? 1 : -1];
typedef char teleport_splash_particle_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, ramp) == 32 &&
		offsetof(particle_t, die) == 36 &&
		sizeof(particle_t) == 40) ? 1 : -1];
typedef char teleport_splash_client_time_layout[
		(offsetof(client_state_t, time) == 572 &&
		sizeof(((client_state_t *)0)->time) == 8) ? 1 : -1];
typedef char teleport_splash_particle_type[(pt_slowgrav == 2) ? 1 : -1];
#endif

#ifdef BENCH486
int (*bench486_lavasplash_rand_probe) (void);
unsigned bench486_lavasplash_rand_calls;

int Bench486LavaSplashRand (void)
{
	bench486_lavasplash_rand_calls++;
	if (bench486_lavasplash_rand_probe)
		return bench486_lavasplash_rand_probe ();
	return rand ();
}
#define LAVA_SPLASH_RAND() Bench486LavaSplashRand ()
#else
#define LAVA_SPLASH_RAND() rand ()
#endif

#ifdef BENCH486
int (*bench486_particleexplosion_rand_probe) (void);
unsigned bench486_particleexplosion_rand_calls;

int Bench486ParticleExplosionRand (void)
{
	bench486_particleexplosion_rand_calls++;
	if (bench486_particleexplosion_rand_probe)
		return bench486_particleexplosion_rand_probe ();
	return rand ();
}
#define PARTICLE_EXPLOSION_RAND() Bench486ParticleExplosionRand ()
#else
#define PARTICLE_EXPLOSION_RAND() rand ()
#endif

#ifdef BENCH486
int (*bench486_runparticleeffect_rand_probe) (void);
unsigned bench486_runparticleeffect_rand_calls;

int Bench486RunParticleEffectRand (void)
{
	bench486_runparticleeffect_rand_calls++;
	if (bench486_runparticleeffect_rand_probe)
		return bench486_runparticleeffect_rand_probe ();
	return rand ();
}
#define RUN_PARTICLE_EFFECT_RAND() Bench486RunParticleEffectRand ()
#else
#define RUN_PARTICLE_EFFECT_RAND() rand ()
#endif

#ifdef PROFILE486
extern unsigned long bench486_gib_trail_particles;
#endif

#define MAX_PARTICLES			2048	// default max # of particles at one
										//  time
#define ABSOLUTE_MIN_PARTICLES	512		// no fewer than this no matter what's
										//  on the command line

int		ramp1[8] = {0x6f, 0x6d, 0x6b, 0x69, 0x67, 0x65, 0x63, 0x61};
int		ramp2[8] = {0x6f, 0x6e, 0x6d, 0x6c, 0x6b, 0x6a, 0x68, 0x66};
int		ramp3[8] = {0x6d, 0x6b, 6, 5, 4, 3};

particle_t	*active_particles, *free_particles;

particle_t	*particles;
int			r_numparticles;

vec3_t			r_pright, r_pup, r_ppn;


/*
===============
R_InitParticles
===============
*/
void R_InitParticles (void)
{
	int		i;

	i = COM_CheckParm ("-particles");

	if (i)
	{
		r_numparticles = (int)(Q_atoi(com_argv[i+1]));
		if (r_numparticles < ABSOLUTE_MIN_PARTICLES)
			r_numparticles = ABSOLUTE_MIN_PARTICLES;
	}
	else
	{
		r_numparticles = MAX_PARTICLES;
	}

	particles = (particle_t *)
			Hunk_AllocName (r_numparticles * sizeof(particle_t), "particles");
}

#ifdef QUAKE2
void R_DarkFieldParticles (entity_t *ent)
{
	int			i, j, k;
	particle_t	*p;
	float		vel;
	vec3_t		dir;
	vec3_t		org;

	org[0] = ent->origin[0];
	org[1] = ent->origin[1];
	org[2] = ent->origin[2];
	for (i=-16 ; i<16 ; i+=8)
		for (j=-16 ; j<16 ; j+=8)
			for (k=0 ; k<32 ; k+=8)
			{
				if (!free_particles)
					return;
				p = free_particles;
				free_particles = p->next;
				p->next = active_particles;
				active_particles = p;
		
				p->die = cl.time + 0.2 + (rand()&7) * 0.02;
				p->color = 150 + rand()%6;
				p->type = pt_slowgrav;
				
				dir[0] = j*8;
				dir[1] = i*8;
				dir[2] = k*8;
	
				p->org[0] = org[0] + i + (rand()&3);
				p->org[1] = org[1] + j + (rand()&3);
				p->org[2] = org[2] + k + (rand()&3);
	
				VectorNormalize (dir);						
				vel = 50 + (rand()&63);
				VectorScale (dir, vel, p->vel);
			}
}
#endif


/*
===============
R_EntityParticles
===============
*/

#define NUMVERTEXNORMALS	162
extern	float	r_avertexnormals[NUMVERTEXNORMALS][3];
vec3_t	avelocities[NUMVERTEXNORMALS];
static qboolean avelocities_initialized;
float	beamlength = 16;
vec3_t	avelocity = {23, 7, 3};
float	partstep = 0.01;
float	timescale = 0.01;

void R_EntityParticles (entity_t *ent)
{
	int			i;
	particle_t	*p;
	float		angle;
	float		sp, sy, cp, cy;
	vec3_t		forward;
	float		dist;
	float		*avelocity_values;
	float		time;
	
	dist = 64;
	time = cl.time;

	if (!avelocities_initialized)
	{
		avelocity_values = &avelocities[0][0];
		for (i=0 ; i<NUMVERTEXNORMALS*3 ; i++)
			avelocity_values[i] = (rand()&255) * 0.01;
		avelocities_initialized = true;
	}


	for (i=0 ; i<NUMVERTEXNORMALS ; i++)
	{
		angle = time * avelocities[i][0];
		sy = sin(angle);
		cy = cos(angle);
		angle = time * avelocities[i][1];
		sp = sin(angle);
		cp = cos(angle);
	
		forward[0] = cp*cy;
		forward[1] = cp*sy;
		forward[2] = -sp;

		if (!free_particles)
			return;
		p = free_particles;
		free_particles = p->next;
		p->next = active_particles;
		active_particles = p;

		p->die = time + 0.01;
		p->color = 0x6f;
		p->type = pt_explode;
		
		p->org[0] = ent->origin[0] + r_avertexnormals[i][0]*dist + forward[0]*beamlength;			
		p->org[1] = ent->origin[1] + r_avertexnormals[i][1]*dist + forward[1]*beamlength;			
		p->org[2] = ent->origin[2] + r_avertexnormals[i][2]*dist + forward[2]*beamlength;			
	}
}


/*
===============
R_ClearParticles
===============
*/
#if !defined(ASM486_PARTICLE_UPDATE) || !id386 || defined(BENCH486)
#if defined(ASM486_PARTICLE_UPDATE) && id386 && defined(BENCH486)
#define R_ClearParticles R_ClearParticles_C
#endif
void R_ClearParticles (void)
{
	int		i;
	
	free_particles = &particles[0];
	active_particles = NULL;

	for (i=0 ;i<r_numparticles ; i++)
		particles[i].next = &particles[i+1];
	particles[r_numparticles-1].next = NULL;
}
#if defined(ASM486_PARTICLE_UPDATE) && id386 && defined(BENCH486)
#undef R_ClearParticles
#endif
#endif


void R_ReadPointFile_f (void)
{
	FILE	*f;
	vec3_t	org;
	int		r;
	int		c;
	particle_t	*p;
	char	name[MAX_OSPATH];
	
	sprintf (name,"maps/%s.pts", sv.name);

	COM_FOpenFile (name, &f);
	if (!f)
	{
		Con_Printf ("couldn't open %s\n", name);
		return;
	}
	
	Con_Printf ("Reading %s...\n", name);
	c = 0;
	for ( ;; )
	{
		r = fscanf (f,"%f %f %f\n", &org[0], &org[1], &org[2]);
		if (r != 3)
			break;
		c++;
		
		if (!free_particles)
		{
			Con_Printf ("Not enough free particles\n");
			break;
		}
		p = free_particles;
		free_particles = p->next;
		p->next = active_particles;
		active_particles = p;
		
		p->die = 99999;
		p->color = (-c)&15;
		p->type = pt_static;
		VectorCopy (vec3_origin, p->vel);
		VectorCopy (org, p->org);
	}

	fclose (f);
	Con_Printf ("%i points read\n", c);
}

/*
===============
R_ParseParticleEffect

Parse an effect out of the server message
===============
*/
void R_ParseParticleEffect (void)
{
	vec3_t		org, dir;
	int			i, count, msgcount, color;
	
	for (i=0 ; i<3 ; i++)
		org[i] = MSG_ReadCoord ();
	for (i=0 ; i<3 ; i++)
		dir[i] = MSG_ReadChar () * (1.0/16);
	msgcount = MSG_ReadByte ();
	color = MSG_ReadByte ();

if (msgcount == 255)
	count = 1024;
else
	count = msgcount;
	
	R_RunParticleEffect (org, dir, color, count);
}
	
/*
===============
R_ParticleExplosion

===============
*/
#ifdef ASM486_PARTICLE_EXPLOSION
#define R_ParticleExplosion R_ParticleExplosion_C
#endif
#if !defined(ASM486_PARTICLE_EXPLOSION) || defined(BENCH486)
void R_ParticleExplosion (vec3_t org)
{
	int			i, j;
	particle_t	*p;
	
	for (i=0 ; i<1024 ; i++)
	{
		if (!free_particles)
			return;
		p = free_particles;
		free_particles = p->next;
		p->next = active_particles;
		active_particles = p;

		p->die = cl.time + 5;
		p->color = ramp1[0];
		p->ramp = PARTICLE_EXPLOSION_RAND ()&3;
		if (i & 1)
		{
			p->type = pt_explode;
			for (j=0 ; j<3 ; j++)
			{
				p->org[j] = org[j] + ((PARTICLE_EXPLOSION_RAND ()%32)-16);
				p->vel[j] = (PARTICLE_EXPLOSION_RAND ()%512)-256;
			}
		}
		else
		{
			p->type = pt_explode2;
			for (j=0 ; j<3 ; j++)
			{
				p->org[j] = org[j] + ((PARTICLE_EXPLOSION_RAND ()%32)-16);
				p->vel[j] = (PARTICLE_EXPLOSION_RAND ()%512)-256;
			}
		}
	}
}
#endif
#ifdef ASM486_PARTICLE_EXPLOSION
#undef R_ParticleExplosion
#endif
#undef PARTICLE_EXPLOSION_RAND

/*
===============
R_ParticleExplosion2

===============
*/
#ifdef ASM486_PARTICLE_EXPLOSION2
#define R_ParticleExplosion2 R_ParticleExplosion2_C
#endif
#if !defined(ASM486_PARTICLE_EXPLOSION2) || defined(BENCH486)
void R_ParticleExplosion2 (vec3_t org, int colorStart, int colorLength)
{
	int			i, j;
	particle_t	*p;
	int			colorMod = 0;

	for (i=0; i<512; i++)
	{
		if (!free_particles)
			return;
		p = free_particles;
		free_particles = p->next;
		p->next = active_particles;
		active_particles = p;

		p->die = cl.time + 0.3;
		p->color = colorStart + (colorMod % colorLength);
		colorMod++;

		p->type = pt_blob;
		for (j=0 ; j<3 ; j++)
		{
			p->org[j] = org[j] + ((rand()%32)-16);
			p->vel[j] = (rand()%512)-256;
		}
	}
}
#endif
#ifdef ASM486_PARTICLE_EXPLOSION2
#undef R_ParticleExplosion2
#endif

#ifdef BENCH486
int (*bench486_blobexplosion_rand_probe) (void);
unsigned bench486_blobexplosion_rand_calls;

int Bench486BlobExplosionRand (void)
{
	bench486_blobexplosion_rand_calls++;
	if (bench486_blobexplosion_rand_probe)
		return bench486_blobexplosion_rand_probe ();
	return rand ();
}
#define BLOB_EXPLOSION_RAND() Bench486BlobExplosionRand ()
#else
#define BLOB_EXPLOSION_RAND() rand ()
#endif

/*
===============
R_BlobExplosion

===============
*/
#ifdef ASM486_BLOB_EXPLOSION
#define R_BlobExplosion R_BlobExplosion_C
#endif
#if !defined(ASM486_BLOB_EXPLOSION) || defined(BENCH486)
void R_BlobExplosion (vec3_t org)
{
	int			i, j;
	particle_t	*p;
	
	for (i=0 ; i<1024 ; i++)
	{
		if (!free_particles)
			return;
		p = free_particles;
		free_particles = p->next;
		p->next = active_particles;
		active_particles = p;

		p->die = cl.time + 1 + (BLOB_EXPLOSION_RAND ()&8)*0.05;

		if (i & 1)
		{
			p->type = pt_blob;
			p->color = 66 + BLOB_EXPLOSION_RAND ()%6;
			for (j=0 ; j<3 ; j++)
			{
				p->org[j] = org[j] + ((BLOB_EXPLOSION_RAND ()%32)-16);
				p->vel[j] = (BLOB_EXPLOSION_RAND ()%512)-256;
			}
		}
		else
		{
			p->type = pt_blob2;
			p->color = 150 + BLOB_EXPLOSION_RAND ()%6;
			for (j=0 ; j<3 ; j++)
			{
				p->org[j] = org[j] + ((BLOB_EXPLOSION_RAND ()%32)-16);
				p->vel[j] = (BLOB_EXPLOSION_RAND ()%512)-256;
			}
		}
	}
}
#endif
#ifdef ASM486_BLOB_EXPLOSION
#undef R_BlobExplosion
#endif
#undef BLOB_EXPLOSION_RAND

/*
===============
R_RunParticleEffect

===============
*/
#ifdef ASM486_RUN_PARTICLE_EFFECT
#define R_RunParticleEffect R_RunParticleEffect_C
#endif
#if !defined(ASM486_RUN_PARTICLE_EFFECT) || defined(BENCH486)
void R_RunParticleEffect (vec3_t org, vec3_t dir, int color, int count)
{
	int			i, j;
	particle_t	*p;
	
	for (i=0 ; i<count ; i++)
	{
		if (!free_particles)
			return;
		p = free_particles;
		free_particles = p->next;
		p->next = active_particles;
		active_particles = p;

		if (count == 1024)
		{	// rocket explosion
			p->die = cl.time + 5;
			p->color = ramp1[0];
			p->ramp = RUN_PARTICLE_EFFECT_RAND()&3;
			if (i & 1)
			{
				p->type = pt_explode;
				for (j=0 ; j<3 ; j++)
				{
					p->org[j] = org[j] + ((RUN_PARTICLE_EFFECT_RAND()%32)-16);
					p->vel[j] = (RUN_PARTICLE_EFFECT_RAND()%512)-256;
				}
			}
			else
			{
				p->type = pt_explode2;
				for (j=0 ; j<3 ; j++)
				{
					p->org[j] = org[j] + ((RUN_PARTICLE_EFFECT_RAND()%32)-16);
					p->vel[j] = (RUN_PARTICLE_EFFECT_RAND()%512)-256;
				}
			}
		}
		else
		{
			p->die = cl.time + 0.1*(RUN_PARTICLE_EFFECT_RAND()%5);
			p->color = (color&~7) + (RUN_PARTICLE_EFFECT_RAND()&7);
			p->type = pt_slowgrav;
			for (j=0 ; j<3 ; j++)
			{
				p->org[j] = org[j] + ((RUN_PARTICLE_EFFECT_RAND()&15)-8);
				p->vel[j] = dir[j]*15;// + (rand()%300)-150;
			}
		}
	}
}
#endif
#ifdef ASM486_RUN_PARTICLE_EFFECT
#undef R_RunParticleEffect
#endif
#undef RUN_PARTICLE_EFFECT_RAND


/*
===============
R_LavaSplash

===============
*/
#ifdef ASM486_LAVA_SPLASH
#define R_LavaSplash R_LavaSplash_C
#endif
#if !defined(ASM486_LAVA_SPLASH) || defined(BENCH486)
void R_LavaSplash (vec3_t org)
{
	int			i, j, k;
	particle_t	*p;
	float		vel;
	vec3_t		dir;

	for (i=-16 ; i<16 ; i++)
		for (j=-16 ; j<16 ; j++)
			for (k=0 ; k<1 ; k++)
			{
				if (!free_particles)
					return;
				p = free_particles;
				free_particles = p->next;
				p->next = active_particles;
				active_particles = p;
		
				p->die = cl.time + 2 + (LAVA_SPLASH_RAND()&31) * 0.02;
				p->color = 224 + (LAVA_SPLASH_RAND()&7);
				p->type = pt_slowgrav;
				
				dir[0] = j*8 + (LAVA_SPLASH_RAND()&7);
				dir[1] = i*8 + (LAVA_SPLASH_RAND()&7);
				dir[2] = 256;
	
				p->org[0] = org[0] + dir[0];
				p->org[1] = org[1] + dir[1];
				p->org[2] = org[2] + (LAVA_SPLASH_RAND()&63);
	
				VectorNormalize (dir);						
				vel = 50 + (LAVA_SPLASH_RAND()&63);
				VectorScale (dir, vel, p->vel);
			}
}
#endif
#ifdef ASM486_LAVA_SPLASH
#undef R_LavaSplash
#endif
#undef LAVA_SPLASH_RAND

#ifdef BENCH486
int (*bench486_teleportsplash_rand_probe) (void);
unsigned bench486_teleportsplash_rand_calls;

int Bench486TeleportSplashRand (void)
{
	bench486_teleportsplash_rand_calls++;
	if (bench486_teleportsplash_rand_probe)
		return bench486_teleportsplash_rand_probe ();
	return rand ();
}
#define TELEPORT_SPLASH_RAND() Bench486TeleportSplashRand ()
#else
#define TELEPORT_SPLASH_RAND() rand ()
#endif

/*
===============
R_TeleportSplash

===============
*/
#ifdef ASM486_TELEPORT_SPLASH
#define R_TeleportSplash R_TeleportSplash_C
#endif
#if !defined(ASM486_TELEPORT_SPLASH) || defined(BENCH486)
void R_TeleportSplash (vec3_t org)
{
	int			i, j, k;
	particle_t	*p;
	float		vel;
	vec3_t		dir;

	for (i=-16 ; i<16 ; i+=4)
		for (j=-16 ; j<16 ; j+=4)
			for (k=-24 ; k<32 ; k+=4)
			{
				if (!free_particles)
					return;
				p = free_particles;
				free_particles = p->next;
				p->next = active_particles;
				active_particles = p;
		
				p->die = cl.time + 0.2 + (TELEPORT_SPLASH_RAND()&7) * 0.02;
				p->color = 7 + (TELEPORT_SPLASH_RAND()&7);
				p->type = pt_slowgrav;
				
				dir[0] = j*8;
				dir[1] = i*8;
				dir[2] = k*8;
	
				p->org[0] = org[0] + i + (TELEPORT_SPLASH_RAND()&3);
				p->org[1] = org[1] + j + (TELEPORT_SPLASH_RAND()&3);
				p->org[2] = org[2] + k + (TELEPORT_SPLASH_RAND()&3);
	
				VectorNormalize (dir);						
				vel = 50 + (TELEPORT_SPLASH_RAND()&63);
				VectorScale (dir, vel, p->vel);
			}
}
#endif
#ifdef ASM486_TELEPORT_SPLASH
#undef R_TeleportSplash
#endif
#undef TELEPORT_SPLASH_RAND

#ifdef BENCH486
int (*bench486_rockettrail_rand_probe) (void);
unsigned bench486_rockettrail_rand_calls;
int bench486_rockettrail_c_tracercount;

int Bench486RocketTrailRand (void)
{
	bench486_rockettrail_rand_calls++;
	if (bench486_rockettrail_rand_probe)
		return bench486_rockettrail_rand_probe ();
	return rand ();
}
#define ROCKET_TRAIL_RAND() Bench486RocketTrailRand ()
#else
#define ROCKET_TRAIL_RAND() rand ()
#endif

#ifdef ASM486_ROCKET_TRAIL
#define R_RocketTrail R_RocketTrail_C
#endif
#if !defined(ASM486_ROCKET_TRAIL) || defined(BENCH486)
void R_RocketTrail (vec3_t start, vec3_t end, int type)
{
	vec3_t		vec;
	float		len;
	int			j;
	particle_t	*p;
	int			dec;
#ifdef BENCH486
#define ROCKET_TRAIL_TRACERCOUNT bench486_rockettrail_c_tracercount
#else
	static int	tracercount;
#define ROCKET_TRAIL_TRACERCOUNT tracercount
#endif

	VectorSubtract (end, start, vec);
	len = VectorNormalize (vec);
	if (type < 128)
		dec = 3;
	else
	{
		dec = 1;
		type -= 128;
	}

	while (len > 0)
	{
		len -= dec;

		if (!free_particles)
			return;
		p = free_particles;
		free_particles = p->next;
		p->next = active_particles;
		active_particles = p;
		
		VectorCopy (vec3_origin, p->vel);
		p->die = cl.time + 2;

		switch (type)
		{
		case 0:	// rocket trail
				p->ramp = (ROCKET_TRAIL_RAND()&3);
				p->color = ramp3[(int)p->ramp];
				p->type = pt_fire;
				for (j=0 ; j<3 ; j++)
					p->org[j] = start[j] + ((ROCKET_TRAIL_RAND()%6)-3);
				break;

			case 1:	// smoke smoke
				p->ramp = (ROCKET_TRAIL_RAND()&3) + 2;
				p->color = ramp3[(int)p->ramp];
				p->type = pt_fire;
				for (j=0 ; j<3 ; j++)
					p->org[j] = start[j] + ((ROCKET_TRAIL_RAND()%6)-3);
				break;

			case 2:	// blood
				p->type = pt_grav;
				p->color = 67 + (ROCKET_TRAIL_RAND()&3);
				for (j=0 ; j<3 ; j++)
					p->org[j] = start[j] + ((ROCKET_TRAIL_RAND()%6)-3);
				break;

			case 3:
			case 5:	// tracer
				p->die = cl.time + 0.5;
				p->type = pt_static;
				if (type == 3)
					p->color = 52 + ((ROCKET_TRAIL_TRACERCOUNT&4)<<1);
				else
					p->color = 230 + ((ROCKET_TRAIL_TRACERCOUNT&4)<<1);
			
				ROCKET_TRAIL_TRACERCOUNT++;

				VectorCopy (start, p->org);
				if (ROCKET_TRAIL_TRACERCOUNT & 1)
				{
					p->vel[0] = 30*vec[1];
					p->vel[1] = 30*-vec[0];
				}
				else
				{
					p->vel[0] = 30*-vec[1];
					p->vel[1] = 30*vec[0];
				}
				break;

		case 4:	// slight blood
				p->type = pt_grav;
				p->color = 67 + (ROCKET_TRAIL_RAND()&3);
				for (j=0 ; j<3 ; j++)
					p->org[j] = start[j] + ((ROCKET_TRAIL_RAND()%6)-3);
				len -= 3;
				break;

		case 6:	// voor trail
				p->color = 9*16 + 8 + (ROCKET_TRAIL_RAND()&3);
				p->type = pt_static;
				p->die = cl.time + 0.3;
				for (j=0 ; j<3 ; j++)
					p->org[j] = start[j] + ((ROCKET_TRAIL_RAND()&15)-8);
				break;
		}
		

		VectorAdd (start, vec, start);
	}
}
#undef ROCKET_TRAIL_TRACERCOUNT
#endif
#ifdef ASM486_ROCKET_TRAIL
#undef R_RocketTrail
#endif
#undef ROCKET_TRAIL_RAND


/*
===============
R_DrawParticles
===============
*/
extern	cvar_t	sv_gravity;

#if !defined(ASM486_PARTICLE_UPDATE) || !id386 || defined(BENCH486)
void R_DrawParticles_C (void)
{
	particle_t		*p;
	particle_t		**link;
	float			grav;
	int				i;
	float			time2, time3;
	float			time1;
	float			dvel;
	float			frametime;
	float			time;
#ifdef PROFILE486
	double		particle_start;
#endif
	
#ifdef PROFILE486
	if (bench486_profile_frame_active)
		particle_start = Sys_FloatTime ();
#endif
	D_StartParticles ();

	if (!active_particles)
	{
		D_EndParticles ();
#ifdef PROFILE486
		if (bench486_profile_frame_active)
			bench486_particle_seconds += Sys_FloatTime () - particle_start;
#endif
		return;
	}

	time = cl.time;

	VectorScale (vright, xscaleshrink, r_pright);
	VectorScale (vup, yscaleshrink, r_pup);
	VectorCopy (vpn, r_ppn);
	frametime = time - cl.oldtime;
	time3 = frametime * 15;
	time2 = frametime * 10; // 15;
	time1 = frametime * 5;
	grav = frametime * sv_gravity.value * 0.05;
	dvel = 4*frametime;
	
	link = &active_particles;
	while ((p = *link) != NULL)
	{
		if (p->die < time)
		{
			*link = p->next;
			p->next = free_particles;
			free_particles = p;
			continue;
		}

#ifdef PROFILE486
		if (bench486_profile_frame_active)
		{
			bench486_particle_count++;
			if (p->type == pt_grav)
				bench486_gib_trail_particles++;
		}
#endif
		D_DrawParticle (p);
		/* Gib trails have zero horizontal velocity.  Avoid two zero-valued
		   multiply/adds for every live blood particle on 486-class CPUs. */
#ifdef ASM486_GIB_TRAIL_SKIP_ZERO_XY
		if (p->type == pt_grav)
		{
			p->org[2] += p->vel[2]*frametime;
#ifdef QUAKE2
			p->vel[2] -= grav * 20;
#else
			p->vel[2] -= grav;
#endif
			link = &p->next;
			continue;
		}
#endif

		p->org[0] += p->vel[0]*frametime;
		p->org[1] += p->vel[1]*frametime;
		p->org[2] += p->vel[2]*frametime;
		
		switch (p->type)
		{
		case pt_static:
			break;
		case pt_fire:
			p->ramp += time1;
			if (p->ramp >= 6)
				p->die = -1;
			else
				p->color = ramp3[(int)p->ramp];
			p->vel[2] += grav;
			break;

		case pt_explode:
			p->ramp += time2;
			if (p->ramp >=8)
				p->die = -1;
			else
				p->color = ramp1[(int)p->ramp];
			for (i=0 ; i<3 ; i++)
				p->vel[i] += p->vel[i]*dvel;
			p->vel[2] -= grav;
			break;

		case pt_explode2:
			p->ramp += time3;
			if (p->ramp >=8)
				p->die = -1;
			else
				p->color = ramp2[(int)p->ramp];
			for (i=0 ; i<3 ; i++)
				p->vel[i] -= p->vel[i]*frametime;
			p->vel[2] -= grav;
			break;

		case pt_blob:
			for (i=0 ; i<3 ; i++)
				p->vel[i] += p->vel[i]*dvel;
			p->vel[2] -= grav;
			break;

		case pt_blob2:
			for (i=0 ; i<2 ; i++)
				p->vel[i] -= p->vel[i]*dvel;
			p->vel[2] -= grav;
			break;

		case pt_grav:
#ifdef QUAKE2
			p->vel[2] -= grav * 20;
			break;
#endif
		case pt_slowgrav:
			p->vel[2] -= grav;
			break;
		}
		link = &p->next;
	}

	D_EndParticles ();
#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_particle_seconds += Sys_FloatTime () - particle_start;
#endif
}
#endif

#if defined(ASM486_PARTICLE_UPDATE) && id386
void R_DrawParticles_asm486 (float time, double oldtime, float gravity
#ifdef PROFILE486
		, unsigned long *particle_count, unsigned long *gib_trail_count
#endif
		);

#if !(defined(ASM486_RENDER_DISPATCH) && defined(ASM486_PARTICLE_UPDATE) && id386)
void R_DrawParticles (void)
{
#ifdef PROFILE486
	unsigned long	particle_count, gib_trail_count;
	double			particle_start;
	qboolean		profiled;

	particle_count = 0;
	gib_trail_count = 0;
	profiled = bench486_profile_frame_active;
	if (profiled)
		particle_start = Sys_FloatTime ();
#endif

	D_StartParticles ();
#ifdef PROFILE486
	R_DrawParticles_asm486 ((float)cl.time, cl.oldtime, sv_gravity.value,
			&particle_count, &gib_trail_count);
#else
	R_DrawParticles_asm486 ((float)cl.time, cl.oldtime, sv_gravity.value);
#endif
	D_EndParticles ();

#ifdef PROFILE486
	if (profiled)
	{
		bench486_particle_count += particle_count;
		bench486_gib_trail_particles += gib_trail_count;
		bench486_particle_seconds += Sys_FloatTime () - particle_start;
	}
#endif
}
#endif
#else
void R_DrawParticles (void)
{
	R_DrawParticles_C ();
}
#endif


/* Pinned original argument adapters, compiled only as independent test oracles. */
#if defined(BENCH486) && defined(ASM486_RENDER_DISPATCH) && defined(ASM486_PARTICLE_UPDATE) && id386
void R_DrawParticles_Dispatch_C (void)
{
#ifdef PROFILE486
	unsigned long	particle_count, gib_trail_count;
	double			particle_start;
	qboolean		profiled;

	particle_count = 0;
	gib_trail_count = 0;
	profiled = bench486_profile_frame_active;
	if (profiled)
		particle_start = Bench486DispatchFloatTime ();
#endif

	Bench486DispatchStartParticles ();
#ifdef PROFILE486
	Bench486DispatchParticles ((float)cl.time, cl.oldtime, sv_gravity.value,
			&particle_count, &gib_trail_count);
#else
	Bench486DispatchParticles ((float)cl.time, cl.oldtime, sv_gravity.value);
#endif
	Bench486DispatchEndParticles ();

#ifdef PROFILE486
	if (profiled)
	{
		bench486_particle_count += particle_count;
		bench486_gib_trail_particles += gib_trail_count;
		bench486_particle_seconds += Bench486DispatchFloatTime () - particle_start;
	}
#endif
}
#endif
