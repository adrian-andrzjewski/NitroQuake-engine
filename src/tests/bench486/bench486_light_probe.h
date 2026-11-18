/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
/* BENCH486 C and assembly interface for dynamic-light probe records. */
#ifndef BENCH486_LIGHT_PROBE_H
#define BENCH486_LIGHT_PROBE_H

#ifdef BENCH486

#define ml_probe_planedist      0
#define ml_probe_rad            4
#define ml_probe_fmin           8
#define ml_probe_local0        12
#define ml_probe_local1        16
#define ml_probe_cs            20
#define ml_probe_ct            24
#define ml_probe_fmin_scaled   28
#define ml_probe_sd            32
#define ml_probe_td            36
#define ml_probe_idist         40
#define ml_probe_stage         44
#define ml_probe_marked        48
#define ml_probe_size          52

#ifndef __ASSEMBLER__
#include "client.h"
#include "model.h"

typedef struct
{
	float planedist;
	float rad;
	float fmin;
	float local0;
	float local1;
	float cs;
	float ct;
	int fmin_scaled;
	int sd;
	int td;
	int idist;
	int stage;
	int marked;
} bench486_mark_lights_probe_t;

extern bench486_mark_lights_probe_t *bench486_mark_lights_probe;
void R_MarkLights_C (dlight_t *light, int bit, mnode_t *node);
void R_PushDlights_C (void);
#endif /* !__ASSEMBLER__ */

#endif /* BENCH486 */

#endif /* BENCH486_LIGHT_PROBE_H */
