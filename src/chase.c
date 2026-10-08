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
// chase.c -- chase camera code

#include "quakedef.h"
#include "asm_chase.h"

cvar_t	chase_back = {"chase_back", "100"};
cvar_t	chase_up = {"chase_up", "16"};
cvar_t	chase_right = {"chase_right", "0"};
cvar_t	chase_active = {"chase_active", "0"};

vec3_t	chase_pos;
vec3_t	chase_angles;

vec3_t	chase_dest;
vec3_t	chase_dest_angles;


#ifndef ASM486_CHASE
void Chase_Init (void)
{
	Cvar_RegisterVariable (&chase_back);
	Cvar_RegisterVariable (&chase_up);
	Cvar_RegisterVariable (&chase_right);
	Cvar_RegisterVariable (&chase_active);
}
#endif

#ifndef ASM486_CHASE
void Chase_Reset (void)
{
	// for respawning and teleporting
//	start position 12 units behind head
}
#endif

#ifndef ASM486_CHASE
void TraceLine (vec3_t start, vec3_t end, vec3_t impact)
{
	trace_t	trace;

	memset (&trace, 0, sizeof(trace));
	SV_RecursiveHullCheck (cl.worldmodel->hulls, 0, 0, 1, start, end, &trace);

	VectorCopy (trace.endpos, impact);
}
#endif

#ifndef ASM486_CHASE
void Chase_Update (void)
{
	int		i;
	float	dist;
	vec3_t	forward, up, right;
	vec3_t	dest, stop;


	// if can't see player, reset
	AngleVectors (cl.viewangles, forward, right, up);

	// calc exact destination
	for (i=0 ; i<3 ; i++)
		chase_dest[i] = r_refdef.vieworg[i] 
		- forward[i]*chase_back.value
		- right[i]*chase_right.value;
	chase_dest[2] = r_refdef.vieworg[2] + chase_up.value;

	// find the spot the player is looking at
	VectorMA (r_refdef.vieworg, 4096, forward, dest);
	TraceLine (r_refdef.vieworg, dest, stop);

	// calculate pitch to look at the same spot from camera
	VectorSubtract (stop, r_refdef.vieworg, stop);
	dist = DotProduct (stop, forward);
	if (dist < 1)
		dist = 1;
	r_refdef.viewangles[PITCH] = -atan(stop[2] / dist) / M_PI * 180;

	// move towards destination
	VectorCopy (chase_dest, r_refdef.vieworg);
}
#endif


#ifdef BENCH486
void (*bench486_chase_register_probe)(cvar_t *);
qboolean (*bench486_chase_hull_probe)(hull_t *,int,int,int,vec3_t,vec3_t,trace_t *);
void Bench486ChaseRegister(cvar_t *value)
{
    if(bench486_chase_register_probe)bench486_chase_register_probe(value);
    else Cvar_RegisterVariable(value);
}
qboolean Bench486ChaseHullCheck(hull_t *hull,int node,int first_bits,int last_bits,vec3_t start,vec3_t end,trace_t *trace)
{
    float first,last;
    if(bench486_chase_hull_probe)return bench486_chase_hull_probe(hull,node,first_bits,last_bits,start,end,trace);
    Q_memcpy(&first,&first_bits,4);Q_memcpy(&last,&last_bits,4);
    return Bench486ChaseOriginalHull(hull,node,first,last,start,end,trace);
}
void Chase_Init_Chase_C (void)
{
	Bench486ChaseRegister (&chase_back);
	Bench486ChaseRegister (&chase_up);
	Bench486ChaseRegister (&chase_right);
	Bench486ChaseRegister (&chase_active);
}

void Chase_Reset_Chase_C (void)
{
	// for respawning and teleporting
//	start position 12 units behind head
}

void TraceLine_Chase_C (vec3_t start, vec3_t end, vec3_t impact)
{
	trace_t	trace;

	memset (&trace, 0, sizeof(trace));
	Bench486ChaseHullCheck (cl.worldmodel->hulls, 0, 0, 1, start, end, &trace);

	VectorCopy (trace.endpos, impact);
}

void Chase_Update_Chase_C (void)
{
	int		i;
	float	dist;
	vec3_t	forward, up, right;
	vec3_t	dest, stop;


	// if can't see player, reset
	AngleVectors (cl.viewangles, forward, right, up);

	// calc exact destination
	for (i=0 ; i<3 ; i++)
		chase_dest[i] = r_refdef.vieworg[i]
		- forward[i]*chase_back.value
		- right[i]*chase_right.value;
	chase_dest[2] = r_refdef.vieworg[2] + chase_up.value;

	// find the spot the player is looking at
	VectorMA (r_refdef.vieworg, 4096, forward, dest);
	TraceLine_Chase_C (r_refdef.vieworg, dest, stop);

	// calculate pitch to look at the same spot from camera
	VectorSubtract (stop, r_refdef.vieworg, stop);
	dist = DotProduct (stop, forward);
	if (dist < 1)
		dist = 1;
	r_refdef.viewangles[PITCH] = -atan(stop[2] / dist) / M_PI * 180;

	// move towards destination
	VectorCopy (chase_dest, r_refdef.vieworg);
}
#endif
