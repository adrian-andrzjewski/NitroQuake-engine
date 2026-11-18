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
*/
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */

#ifndef NITROQUAKE_CPU_H
#define NITROQUAKE_CPU_H

#if defined(__i386__)
#define id386 1
#define UNALIGNED_OK 1
#else
#define id386 0
#define UNALIGNED_OK 0
#endif

#endif
