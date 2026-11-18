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
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// host_assets.h -- host-owned game assets shared through narrow interfaces

#ifndef HOST_ASSETS_H
#define HOST_ASSETS_H

#include "q_types.h"

/* The returned hunk-backed colormap is valid after Host_Init loads game data. */
byte *Host_GetColormap (void);

#endif /* HOST_ASSETS_H */
