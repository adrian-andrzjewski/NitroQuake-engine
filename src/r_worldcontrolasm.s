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
/* BSP rotation, efrag lifetime and edge-frame control. */
#ifdef ASM486_WORLD_CONTROL
.arch i486
.arch .387
.code32
#ifdef BENCH486
#define _Con_Printf _Bench486WorldControlPrint
#define _R_RenderPoly _Bench486WorldControlPoly
#define _R_TransformFrustum _Bench486WorldControlFrustum
#endif
#ifdef PROFILE486
#include "r_worldrotation_profile.inc"
#include "r_worldefrags_profile.inc"
#include "r_worldedges_profile.inc"
#else
#include "r_worldrotation_release.inc"
#include "r_worldefrags_release.inc"
#include "r_worldedges_release.inc"
#endif
#endif
