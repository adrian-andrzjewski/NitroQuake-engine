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
/* Maintained chase camera ownership; never generated from C during a build. */
#ifdef ASM486_CHASE
.arch i486
.arch .387
.code32
#ifdef BENCH486
#define _Cvar_RegisterVariable _Bench486ChaseRegister
#define _SV_RecursiveHullCheck _Bench486ChaseHullCheck
#else
#define _SV_RecursiveHullCheck _SV_RecursiveHullCheck_asm486
#endif
#include "client/v_chase_reference.inc"
#endif
