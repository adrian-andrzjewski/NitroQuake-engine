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
/* Complete r_main frame-control instruction ownership.
 * The C-selected module remains the reference; shared declarations remain C data.
 * Every normal build assembles these frozen, inspectable instruction bodies.
 */
#ifdef ASM486_FRAME_CONTROL
.arch i486
/* The integer CPU selector is separate from the 387-compatible x87 unit. */
.arch .387
.code32
#ifdef PROFILE486
#include "r_framecontrol_profile.inc"
#else
#include "r_framecontrol_release.inc"
#endif
.text
.p2align 3
.globl _R_EdgeDrawing
#ifdef ASM486_EDGE_DRAWING
_R_EdgeDrawing:
    jmp _R_EdgeDrawing_asm486
#else
.set _R_EdgeDrawing, _R_EdgeDrawing_frame_reference
#endif
#endif
