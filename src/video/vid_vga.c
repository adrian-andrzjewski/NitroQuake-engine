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
//
// vid_vga.c: VGA-specific DOS video stuff
//

// TODO: proper handling of page-swap failure

#include <dos.h>
#include <dpmi.h>
#include <string.h>

#include "common.h"
#include "console.h"
#include "cvar.h"
#include "host.h"
#include "host_assets.h"
#include "platform/dos/dosisms.h"
#include "render.h"
#include "vid.h"
#include "video/vid_dos.h"
#include "video/asm_viddirectrect.h"
#include "video/asm_vgaswap.h"
#include "zone.h"

extern regs_t regs;

int		VGA_width, VGA_height, VGA_rowbytes, VGA_bufferrowbytes;
byte	*VGA_pagebase;
vmode_t	*VGA_pcurmode;

int		VGA_planar;
static int		VGA_numpages;
static int		VGA_buffersize;
static int		VGA_zbuffersize;
static int		VGA_framebuffersize;
static int		VGA_bufferpad;
static int		VGA_video_hunkbytes;
static int		VGA_hunk_gap_after_setup;
static qboolean	VGA_hunk_gap_after_setup_valid;

void	*vid_surfcache;
int		vid_surfcachesize;

int		VGA_highhunkmark;

#include "video/vgamodes.h"

#define NUMVIDMODES		(sizeof(vgavidmodes) / sizeof(vgavidmodes[0]))

void VGA_UpdatePlanarScreen (void *srcbuffer);

byte	VGA_directrect_backingbuf[VD_BACKINGBUF_SIZE];

/*
================
VGA_BeginDirectRect
================
*/
#if defined(BENCH486) && defined(ASM486_VID_UPDATE)
#define VGA_BEGIN_DIRECTRECT_C_ENTRY VGA_BeginDirectRect_C
#define VGA_END_DIRECTRECT_C_ENTRY VGA_EndDirectRect_C
#else
#define VGA_BEGIN_DIRECTRECT_C_ENTRY VGA_BeginDirectRect
#define VGA_END_DIRECTRECT_C_ENTRY VGA_EndDirectRect
#endif

#if !defined(ASM486_VID_UPDATE) || defined(BENCH486)
void VGA_BEGIN_DIRECTRECT_C_ENTRY (viddef_t *lvid,
	struct vmode_s *pcurrentmode, int x,
	int y, byte *pbitmap, int width, int height)
{
	int		i, j, k, plane, reps, repshift;

	if (!lvid->direct)
		return;

	if (lvid->aspect > 1.5)
	{
		reps = 2;
		repshift = 1;
	}
	else
	{
		reps = 1;
		repshift = 0;
	}

	if (pcurrentmode->planar)
	{
		for (plane=0 ; plane<4 ; plane++)
		{
		// select the correct plane for reading and writing
			outportb (SC_INDEX, MAP_MASK);
			outportb (SC_DATA, 1 << plane);
			outportb (GC_INDEX, READ_MAP);
			outportb (GC_DATA, plane);

			for (i=0 ; i<(height << repshift) ; i += reps)
			{
				for (k=0 ; k<reps ; k++)
				{
					for (j=0 ; j<(width >> 2) ; j++)
					{
						VGA_directrect_backingbuf[(i + k) * 24 + (j << 2) + plane] =
								lvid->direct[(y + i + k) * VGA_rowbytes +
								(x >> 2) + j];
						lvid->direct[(y + i + k) * VGA_rowbytes + (x>>2) + j] =
								pbitmap[(i >> repshift) * 24 +
								(j << 2) + plane];
					}
				}
			}
		}
	}
	else
	{
		for (i=0 ; i<(height << repshift) ; i += reps)
		{
			for (j=0 ; j<reps ; j++)
			{
				memcpy (&VGA_directrect_backingbuf[(i + j) * 24],
						lvid->direct + x + ((y << repshift) + i + j) *
						 VGA_rowbytes,
						width);
				memcpy (lvid->direct + x + ((y << repshift) + i + j) *
						 VGA_rowbytes,
						&pbitmap[(i >> repshift) * width],
						width);
			}
		}
	}
}


/*
================
VGA_EndDirectRect
================
*/

void VGA_END_DIRECTRECT_C_ENTRY (viddef_t *lvid,
	struct vmode_s *pcurrentmode, int x,
	int y, int width, int height)
{
	int		i, j, k, plane, reps, repshift;

	if (!lvid->direct)
		return;

	if (lvid->aspect > 1.5)
	{
		reps = 2;
		repshift = 1;
	}
	else
	{
		reps = 1;
		repshift = 0;
	}

	if (pcurrentmode->planar)
	{
		for (plane=0 ; plane<4 ; plane++)
		{
		// select the correct plane for writing
			outportb (SC_INDEX, MAP_MASK);
			outportb (SC_DATA, 1 << plane);

			for (i=0 ; i<(height << repshift) ; i += reps)
			{
				for (k=0 ; k<reps ; k++)
				{
					for (j=0 ; j<(width >> 2) ; j++)
					{
						lvid->direct[(y + i + k) * VGA_rowbytes + (x>>2) + j] =
								VGA_directrect_backingbuf[(i + k) * 24 + (j << 2) + plane];
					}
				}
			}
		}
	}
	else
	{
		for (i=0 ; i<(height << repshift) ; i += reps)
		{
			for (j=0 ; j<reps ; j++)
			{
				memcpy (lvid->direct + x + ((y << repshift) + i + j) *
						 VGA_rowbytes,
						&VGA_directrect_backingbuf[(i + j) * 24],
						width);
			}
		}
	}
}
#endif

#undef VGA_BEGIN_DIRECTRECT_C_ENTRY
#undef VGA_END_DIRECTRECT_C_ENTRY


/*
================
VGA_Init
================
*/
void VGA_Init (void)
{
	int		i;

// link together all the VGA modes
	for (i=0 ; i<(NUMVIDMODES - 1) ; i++)
	{
		vgavidmodes[i].pnext = &vgavidmodes[i+1];
	}

// add the VGA modes at the start of the mode list
	vgavidmodes[NUMVIDMODES-1].pnext = pvidmodes;
	pvidmodes = &vgavidmodes[0];

	numvidmodes += NUMVIDMODES;
}


/*
================
VGA_WaitVsync
================
*/
#if defined(BENCH486)
#define VGA_WAIT_VSYNC_C_ENTRY VGA_WaitVsync_C
#define VGA_SWAP_COPY_C_ENTRY VGA_SwapBuffersCopy_C
#define VGA_SWAP_C_ENTRY VGA_SwapBuffers_C
#else
#define VGA_WAIT_VSYNC_C_ENTRY VGA_WaitVsync
#define VGA_SWAP_COPY_C_ENTRY VGA_SwapBuffersCopy
#define VGA_SWAP_C_ENTRY VGA_SwapBuffers
#endif

#if !defined(ASM486_VGA_PRESENTATION) || defined(BENCH486)
void VGA_WAIT_VSYNC_C_ENTRY (void)
{
	while ((inportb (0x3DA) & 0x08) == 0)
		;
}
#endif


/*
================
VGA_ClearVideoMem
================
*/
void VGA_ClearVideoMem (int planar)
{

	if (planar)
	{
	// enable all planes for writing
		outportb (SC_INDEX, MAP_MASK);
		outportb (SC_DATA, 0x0F);
	}

	Q_memset (VGA_pagebase, 0, VGA_rowbytes * VGA_height);
}

/*
================
VGA_FreeAndAllocVidbuffer
================
*/
qboolean VGA_FreeAndAllocVidbuffer (viddef_t *lvid, int allocnewbuffer)
{
	int		tsize, tbuffersize, bufferpad, adjusted_memory;
	int		zbuffersize, framebuffersize;

	// Add one cache line between the surface cache and single-buffer 320x200
	// framebuffer. The high hunk grows downward, so this changes the relative
	// set mapping by moving the Z-buffer and surface-cache base. Standard
	// Intel486 write misses do not allocate lines; any L1 benefit depends on
	// already-resident data. DOSBox timing does not validate the cache theory.
	// Sixteen bytes preserves packed-store alignment.
	bufferpad = allocnewbuffer && lvid->width == 320 && lvid->height == 200 ?
			16 : 0;
	zbuffersize = lvid->width * lvid->height * sizeof (*d_pzbuffer);
	framebuffersize = allocnewbuffer ?
			lvid->rowbytes * (lvid->height + 1) : 0;

	if (allocnewbuffer)
	{
	// alloc an extra line in case we want to wrap, and allocate the z-buffer
		tbuffersize = framebuffersize + zbuffersize;
	}
	else
	{
	// just allocate the z-buffer
		tbuffersize = zbuffersize;
	}

	tsize = D_SurfaceCacheForRes (lvid->width, lvid->height);

	tbuffersize += tsize + bufferpad;

// see if there's enough memory, allowing for the normal mode 0x13 pixel,
// z, and surface buffers
	adjusted_memory = host_parms.memsize - tbuffersize +
			SURFCACHE_SIZE_AT_320X200 + 0x10000 * 3;
	if (adjusted_memory < minimum_memory)
	{
		Con_Printf ("Not enough memory for video mode %dx%d: block payload "
				"%d bytes, engine block %d, minimum %d, mode allowance %d\n",
				lvid->width, lvid->height, tbuffersize,
				host_parms.memsize, minimum_memory, adjusted_memory);
		VGA_pcurmode = NULL;	// so no further accesses to the buffer are
								//  attempted, particularly when clearing
		return false;		// not enough memory for mode
	}

	VGA_zbuffersize = zbuffersize;
	VGA_framebuffersize = framebuffersize;
	VGA_bufferpad = bufferpad;
	VGA_buffersize = tbuffersize;
	vid_surfcachesize = tsize;
	VGA_video_hunkbytes = 0;
	VGA_hunk_gap_after_setup_valid = false;

	if (d_pzbuffer)
	{
		D_FlushCaches ();
		Hunk_FreeToHighMark (VGA_highhunkmark);
		d_pzbuffer = NULL;
	}

	VGA_highhunkmark = Hunk_HighMark ();

	d_pzbuffer = Hunk_HighAllocName (VGA_buffersize, "video");
	if (!d_pzbuffer)
	{
		vid_surfcache = NULL;
		lvid->buffer = lvid->conbuffer = NULL;
		VGA_pcurmode = NULL;
		Con_Printf ("Video high-hunk allocation failed: payload %d bytes "
				"(cache %d, Z %d, framebuffer %d, pad %d)\n",
				VGA_buffersize, vid_surfcachesize, VGA_zbuffersize,
				VGA_framebuffersize, VGA_bufferpad);
		return false;
	}
	VGA_video_hunkbytes = Hunk_HighMark () - VGA_highhunkmark;
	VGA_hunk_gap_after_setup = host_parms.memsize - Hunk_LowMark () -
			Hunk_HighMark ();
	VGA_hunk_gap_after_setup_valid = true;

	vid_surfcache = (byte *)d_pzbuffer
		+ lvid->width * lvid->height * sizeof (*d_pzbuffer);
	
	if (allocnewbuffer)
	{
		lvid->buffer = (void *)( (byte *)vid_surfcache + vid_surfcachesize +
				bufferpad);
		lvid->conbuffer = lvid->buffer;
	}

	return true;
}

/*
================
VID_ReportMemoryBudget
================
*/
void VID_ReportMemoryBudget (void)
{
	int requested_cache, allocated_cache;
	const char *mode_name;

	requested_cache = D_SurfaceCacheForRes (vid.width, vid.height);

	allocated_cache = d_pzbuffer && vid_surfcache ? vid_surfcachesize : 0;
	mode_name = VGA_pcurmode ? VGA_pcurmode->name : "unavailable";

	Con_Printf ("Video: %s %dx%d; cache request=%d allocated=%d usable=%d bytes\n",
			mode_name, vid.width, vid.height, requested_cache, allocated_cache,
			allocated_cache > 4 ? allocated_cache - 4 : 0);
	Con_Printf ("  Z=%d framebuffer=%d pad=%d; video high-hunk=%d bytes "
			"(payload=%d); gap after setup=",
			VGA_zbuffersize, VGA_framebuffersize, VGA_bufferpad,
			VGA_video_hunkbytes, d_pzbuffer ? VGA_buffersize : 0);
	if (VGA_hunk_gap_after_setup_valid)
		Con_Printf ("%d bytes\n", VGA_hunk_gap_after_setup);
	else
		Con_Printf ("unavailable\n");
}


/*
================
VGA_CheckAdequateMem
================
*/
qboolean VGA_CheckAdequateMem (int width, int height, int rowbytes,
	int allocnewbuffer)
{
	int		tbuffersize;

	tbuffersize = width * height * sizeof (*d_pzbuffer);

	if (allocnewbuffer)
	{
	// alloc an extra line in case we want to wrap, and allocate the z-buffer
		tbuffersize += (rowbytes * (height + 1));
	}

	tbuffersize += D_SurfaceCacheForRes (width, height);

// see if there's enough memory, allowing for the normal mode 0x13 pixel,
// z, and surface buffers
	if ((host_parms.memsize - tbuffersize + SURFCACHE_SIZE_AT_320X200 +
		 0x10000 * 3) < minimum_memory)
	{
		return false;		// not enough memory for mode
	}

	return true;
}


/*
================
VGA_InitMode
================
*/
int VGA_InitMode (viddef_t *lvid, vmode_t *pcurrentmode)
{
	vextra_t		*pextra;

	pextra = pcurrentmode->pextradata;

	if (!VGA_FreeAndAllocVidbuffer (lvid, pextra->vidbuffer))
		return -1;	// memory alloc failed

	if (VGA_pcurmode)
		VGA_ClearVideoMem (VGA_pcurmode->planar);

// mode 0x13 is the base for all the Mode X-class mode sets
	regs.h.ah = 0;
	regs.h.al = 0x13;
	dos_int86(0x10);

	VGA_pagebase = (void *)real2ptr(0xa0000);
	lvid->direct = (pixel_t *)VGA_pagebase;

// set additional registers as needed
	VideoRegisterSet (pextra->pregset);

	VGA_numpages = 1;
	lvid->numpages = VGA_numpages;

	VGA_width = (lvid->width + 0x1F) & ~0x1F;
	VGA_height = lvid->height;
	VGA_planar = pcurrentmode->planar;
	if (VGA_planar)
		VGA_rowbytes = lvid->rowbytes / 4;
	else
		VGA_rowbytes = lvid->rowbytes;
	VGA_bufferrowbytes = lvid->rowbytes;
	lvid->colormap = Host_GetColormap ();
	lvid->fullbright = 256 - LittleLong (*((int *)lvid->colormap + 2048));

	lvid->maxwarpwidth = WARP_WIDTH;
	lvid->maxwarpheight = WARP_HEIGHT;

	lvid->conbuffer = lvid->buffer;
	lvid->conrowbytes = lvid->rowbytes;
	lvid->conwidth = lvid->width;
	lvid->conheight = lvid->height;

	VGA_pcurmode = pcurrentmode;

	VGA_ClearVideoMem (pcurrentmode->planar);

	if (_vid_wait_override.value)
	{
		Cvar_SetValue ("vid_wait", (float)VID_WAIT_VSYNC);
	}
	else
	{
		Cvar_SetValue ("vid_wait", (float)VID_WAIT_NONE);
	}

	D_InitCaches (vid_surfcache, vid_surfcachesize);

	return 1;
}


/*
================
VGA_SetPalette
================
*/
void VGA_SetPalette(viddef_t *lvid, vmode_t *pcurrentmode, unsigned char *pal)
{
	int shiftcomponents=2;
	int i;

	UNUSED(lvid);
	UNUSED(pcurrentmode);

	dos_outportb(0x3c8, 0);
	for (i=0 ; i<768 ; i++)
		outportb(0x3c9, pal[i]>>shiftcomponents);
}


/*
================
VGA_SwapBuffersCopy
================
*/
#if !defined(ASM486_VGA_PRESENTATION) || defined(BENCH486)
void VGA_SWAP_COPY_C_ENTRY (viddef_t *lvid, vmode_t *pcurrentmode,
		vrect_t *rects)
{
	UNUSED(pcurrentmode);

	if (VGA_planar)
	{
		VGA_UpdatePlanarScreen (lvid->buffer);
	}
	else
	{
		while (rects)
		{
			VGA_UpdateLinearScreen (
					lvid->buffer + rects->x + (rects->y * lvid->rowbytes),
					VGA_pagebase + rects->x + (rects->y * VGA_rowbytes),
					rects->width,
					rects->height,
					lvid->rowbytes,
					VGA_rowbytes);

			rects = rects->pnext;
		}
	}
}
#endif


/*
================
VGA_SwapBuffers
================
*/
#if !defined(ASM486_VGA_PRESENTATION) || defined(BENCH486)
void VGA_SWAP_C_ENTRY (viddef_t *lvid, vmode_t *pcurrentmode,
		vrect_t *rects)
{
	UNUSED(lvid);

	if (vid_wait.value == VID_WAIT_VSYNC)
	{
#if defined(BENCH486)
		VGA_WaitVsync_C ();
#else
		VGA_WaitVsync ();
#endif
	}

#if defined(BENCH486)
	VGA_SwapBuffersCopy_C (lvid, pcurrentmode, rects);
#else
	VGA_SwapBuffersCopy (lvid, pcurrentmode, rects);
#endif
}
#endif

#undef VGA_WAIT_VSYNC_C_ENTRY
#undef VGA_SWAP_COPY_C_ENTRY
#undef VGA_SWAP_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_VGA_PRESENTATION)
void VGA_WaitVsync (void)
{
	VGA_WaitVsync_C ();
}

void VGA_SwapBuffersCopy (viddef_t *lvid, vmode_t *pcurrentmode,
		vrect_t *rects)
{
	VGA_SwapBuffersCopy_C (lvid, pcurrentmode, rects);
}

void VGA_SwapBuffers (viddef_t *lvid, vmode_t *pcurrentmode,
		vrect_t *rects)
{
	VGA_SwapBuffers_C (lvid, pcurrentmode, rects);
}
#endif

#if defined(BENCH486) && defined(ASM486_VGA_PRESENTATION_FIXTURE)
#include "tests/bench486/bench486_vgaswap.h"
#endif

