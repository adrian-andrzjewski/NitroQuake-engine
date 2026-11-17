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
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
// VBE 2.0 DOS video. Mode numbers always come from the BIOS mode list.
#include <stdlib.h>
#include <string.h>
#include <dos.h>
#include <dpmi.h>

#include "common.h"
#include "console.h"
#include "cvar.h"
#include "host.h"
#include "host_assets.h"
#include "platform/dos/dosisms.h"
#include "render.h"
#include "sys.h"
#include "vid.h"
#include "video/vid_dos.h"
#include "video/vid_vesa.h"
#include "video/asm_vesacopy.h"
#include "video/asm_vesaswap.h"
#include "video/asm_vesapalette.h"
#include "video/asm_vesadefaultmode.h"
#include "video/asm_vesalifecycle.h"
#include "video/asm_vesawait.h"

#define MAX_VESA_MODES 30
#define LINEAR_MODE 0x4000
/* Overflow slots preserve late 320x200 candidates without renumbering. */
#define VESA_SLOTS (MAX_VESA_MODES + 2)
static vmode_t vesa_modes[VESA_SLOTS];
static vesa_info_t vesa_info[VESA_SLOTS];
static char names[VESA_SLOTS][16];
byte *VID_extra_palette;
byte *VID_membase;
__dpmi_meminfo VID_extra_mapping;
qboolean VID_extra_mapped, VID_extra_palette_ok = true;
#define ppal VID_extra_palette
#define mapping VID_extra_mapping
#define mapped VID_extra_mapped
#define palette_ok VID_extra_palette_ok
int VID_currentpage, VID_displayedpage, VID_pagesize;
qboolean VID_extra_vsync_exists, VID_extra_display_enable_exists;
static qboolean wait_probed;
#define vsync_exists VID_extra_vsync_exists
#define de_exists VID_extra_display_enable_exists
extern regs_t regs;

#if defined(BENCH486) && defined(ASM486_VESA_SWAP_BUFFERS_FIXTURE)
int bench486_vesa_swap_fixture_active;
void Bench486VesaSwapWaitVsync (void);
void Bench486VesaSwapWaitDisplayEnable (void);
static void Bench486VesaSwapProbeWait (void);
static void Bench486VesaSwapDisplayStart (int x, int y, int waitflags);
#endif

#if !defined(ASM486_VESA_COPY_RECTS) || defined(BENCH486)
static void VESA_CopyRects_C (vrect_t *rects, byte *srcbase, byte *dstbase,
		int vidwidth, int vidheight, int srcrowbytes, int destrowbytes)
{
	int width, height, y, bulk;
	byte *src, *dst;
	for (; rects; rects = rects->pnext)
	{
		width = rects->width;
		height = rects->height;
		if (width <= 0 || height <= 0 || rects->x < 0 || rects->y < 0 ||
			(unsigned)width > (unsigned)vidwidth ||
			(unsigned)height > (unsigned)vidheight ||
			(unsigned)rects->x > (unsigned)(vidwidth - width) ||
			(unsigned)rects->y > (unsigned)(vidheight - height)) continue;
		src = srcbase + rects->x + rects->y * srcrowbytes;
		dst = dstbase + rects->x + rects->y * destrowbytes;
		VESA_CopyShape (&width, &height, srcrowbytes, destrowbytes);
		bulk = width & ~3;
		if (bulk) VGA_UpdateLinearScreen (src, dst, bulk, height,
				srcrowbytes, destrowbytes);
		if (width & 3)
			for (y = 0; y < height; y++)
				memcpy (dst + y * destrowbytes + bulk,
					src + y * srcrowbytes + bulk, width & 3);
	}
}
#endif

#if defined(ASM486_VESA_COPY_RECTS)
extern void VESA_CopyRects (vrect_t *rects, byte *srcbase, byte *dstbase,
		int vidwidth, int vidheight, int srcrowbytes, int destrowbytes);
#define VESA_CopyRects_Entry VESA_CopyRects
#else
#define VESA_CopyRects_Entry VESA_CopyRects_C
#endif

int VID_ExtraInitMode (viddef_t *lvid, vmode_t *mode);
void VID_ExtraSwapBuffers (viddef_t *lvid, vmode_t *mode, vrect_t *rects);

#if defined(BENCH486)
#define VID_EXTRA_RELEASE_MODE_C_ENTRY VID_ExtraReleaseMode_C
#define VID_EXTRA_SHUTDOWN_C_ENTRY VID_ShutdownExtra_C
#define VID_EXTRA_PALETTE_OK_C_ENTRY VID_ExtraPaletteOK_C
#define VID_EXTRA_RELEASE_MODE_C_CALL VID_ExtraReleaseMode_C
#else
#define VID_EXTRA_RELEASE_MODE_C_ENTRY VID_ExtraReleaseMode
#define VID_EXTRA_SHUTDOWN_C_ENTRY VID_ShutdownExtra
#define VID_EXTRA_PALETTE_OK_C_ENTRY VID_ExtraPaletteOK
#define VID_EXTRA_RELEASE_MODE_C_CALL VID_ExtraReleaseMode
#endif

#if defined(BENCH486) && defined(ASM486_VESA_LIFECYCLE_FIXTURE)
#define VID_EXTRA_FREE_MAPPING(ptr) Bench486VesaLifecycleFreeMapping (ptr)
#define VID_EXTRA_FREE_MEMORY(ptr) Bench486VesaLifecycleFreeDosMemory (ptr)
#else
#define VID_EXTRA_FREE_MAPPING(ptr) \
	__dpmi_free_physical_address_mapping (ptr)
#define VID_EXTRA_FREE_MEMORY(ptr) dos_freememory (ptr)
#endif

#if !defined(ASM486_VESA_LIFECYCLE) || defined(BENCH486)
void VID_EXTRA_RELEASE_MODE_C_ENTRY (void)
{
	if (mapped) VID_EXTRA_FREE_MAPPING (&mapping);
	mapped = false;
	VID_membase = NULL;
	VGA_pcurmode = NULL;
	palette_ok = true;
}

void VID_EXTRA_SHUTDOWN_C_ENTRY (void)
{
	VID_EXTRA_RELEASE_MODE_C_CALL ();
	if (ppal) VID_EXTRA_FREE_MEMORY (ppal);
	ppal = NULL;
}

qboolean VID_EXTRA_PALETTE_OK_C_ENTRY (void) { return palette_ok; }
#endif

#if defined(BENCH486) && !defined(ASM486_VESA_LIFECYCLE)
void VID_ExtraReleaseMode (void) { VID_ExtraReleaseMode_C (); }
void VID_ShutdownExtra (void) { VID_ShutdownExtra_C (); }
qboolean VID_ExtraPaletteOK (void) { return VID_ExtraPaletteOK_C (); }
#endif

#undef VID_EXTRA_FREE_MEMORY
#undef VID_EXTRA_FREE_MAPPING
#undef VID_EXTRA_RELEASE_MODE_C_CALL
#undef VID_EXTRA_PALETTE_OK_C_ENTRY
#undef VID_EXTRA_SHUTDOWN_C_ENTRY
#undef VID_EXTRA_RELEASE_MODE_C_ENTRY

void VID_SetVESAPalette (viddef_t *lvid, vmode_t *mode, byte *pal)
{
	UNUSED(lvid);
	UNUSED(mode);
	palette_ok = false;
	if (!ppal) return;
#ifdef ASM486_VESA_PALETTE
	VID_BuildVESAPalette_asm486 (ppal, pal);
#else
	VID_BuildVESAPalette_C (ppal, pal);
#endif
	regs.x.ax = 0x4f09;
	regs.x.bx = 0;
	regs.x.cx = 256;
	regs.x.dx = 0;
	regs.x.es = ptr2real(ppal) >> 4;
	regs.x.di = ptr2real(ppal) & 15;
	dos_int86 (0x10);
	palette_ok = regs.x.ax == 0x4f;
	if (!palette_ok) Con_SafePrintf ("VESA: palette load failed\n");
}

#if !defined(ASM486_VESA_PALETTE) || defined(BENCH486)
void VID_BuildVESAPalette_C (byte *dest, const byte *source)
{
	int i;
	for (i = 0; i < VP_PALETTE_ENTRIES; i++)
	{
		dest[i * 4] = source[i * 3 + 2] >> 2;
		dest[i * 4 + 1] = source[i * 3 + 1] >> 2;
		dest[i * 4 + 2] = source[i * 3] >> 2;
		dest[i * 4 + 3] = 0;
	}
}
#endif

static void *VID_ExtraFarToLinear (const byte *p)
{
	return real2ptr ((VESA_Word(p + 2) << 4) + VESA_Word(p));
}

void VID_InitExtra (void)
{
	byte *controller, *info;
	unsigned short *modes;
	unsigned memory, number;
	int count = 0, scanned, overflow_linear = 0, overflow_banked = 0;
	vesa_info_t candidate;
	vmode_t *mode;
	controller = dos_getmemory (512);
	info = dos_getmemory (256);
	ppal = dos_getmemory (1024);
	if (!controller || !info || !ppal)
	{
		Con_Printf ("VESA unavailable: DOS memory allocation failed\n");
		goto done;
	}
	memset (controller, 0, 512);
	memcpy (controller, "VBE2", 4);
	regs.x.ax = 0x4f00;
	regs.x.es = ptr2real(controller) >> 4;
	regs.x.di = ptr2real(controller) & 15;
	dos_int86 (0x10);
	if (regs.x.ax != 0x4f || memcmp(controller, "VESA", 4) ||
		VESA_Word(controller + 4) < 0x200)
	{
		Con_Printf ("VESA unavailable: VBE 2.0 required\n");
		goto done;
	}
	memory = VESA_Word (controller + 18) << 16;
	if (!VESA_Word(controller + 14) && !VESA_Word(controller + 16)) goto done;
	modes = VID_ExtraFarToLinear (controller + 14);
	/* Bound a malformed, unterminated list; scan past the old capacity. */
	for (scanned = 0; scanned < 1024 && (number = *modes++) != 0xffff; scanned++)
	{
		if (number & 0xc000) continue;
		memset (info, 0, 256);
		regs.x.ax = 0x4f01;
		regs.x.cx = number;
		regs.x.es = ptr2real(info) >> 4;
		regs.x.di = ptr2real(info) & 15;
		dos_int86 (0x10);
		if (regs.x.ax != 0x4f || !VESA_Decode(info, memory, &candidate)) continue;
		if (count >= MAX_VESA_MODES)
		{
			if (candidate.width != 320 || candidate.height != 200 ||
				(candidate.linear ? overflow_linear : overflow_banked)) continue;
			if (candidate.linear) overflow_linear = 1;
			else overflow_banked = 1;
		}
		candidate.mode = number;
		vesa_info[count] = candidate;
		mode = &vesa_modes[count];
		sprintf (names[count], "%3dx%3d", candidate.width, candidate.height);
		mode->name = names[count];
		mode->width = candidate.width;
		mode->height = candidate.height;
		mode->aspect = ((float)candidate.height / candidate.width) * (320.0 / 240.0);
		mode->rowbytes = candidate.pitch;
		mode->numpages = candidate.pages;
		mode->pextradata = &vesa_info[count];
		mode->setmode = VID_ExtraInitMode;
		mode->swapbuffers = VID_ExtraSwapBuffers;
		mode->setpalette = VID_SetVESAPalette;
		/* Banked modes have one fixed readable/writable window. */
		mode->begindirectrect = VGA_BeginDirectRect;
		mode->enddirectrect = VGA_EndDirectRect;
		if (count) vesa_modes[count-1].pnext = mode;
		count++;
	}
done:
	if (controller) dos_freememory (controller);
	if (info) dos_freememory (info);
	if (count)
	{
		vesa_modes[0].header = "    ********* VESA modes *********    ";
		vesa_modes[count-1].pnext = pvidmodes;
		pvidmodes = vesa_modes;
		numvidmodes += count;
	}
	else if (ppal)
	{
		dos_freememory (ppal);
		ppal = NULL;
	}
}

#if !defined(ASM486_VESA_DEFAULT_MODE) || defined(BENCH486)
int VID_SelectVesaDefaultMode_C (vmode_t *modes,
		int (*setmode)(viddef_t *vid, vmode_t *mode))
{
	vmode_t *mode;
	vesa_info_t *info;
	int i, banked = 0;
	for (mode = modes, i = 0; mode; mode = mode->pnext, i++)
	{
		if (mode->setmode != setmode || mode->width != 320 || mode->height != 200) continue;
		info = mode->pextradata;
		if (info->linear) return i;
		if (!banked) banked = i;
	}
	return banked;
}
#endif

#if !defined(ASM486_VESA_DEFAULT_MODE) || defined(BENCH486)
int VID_ExtraDefaultMode_C (void)
{
	return VID_SelectVesaDefaultMode_C (pvidmodes, VID_ExtraInitMode);
}
#endif

#if !defined(ASM486_VESA_DEFAULT_MODE)
int VID_ExtraDefaultMode (void)
{
	return VID_ExtraDefaultMode_C ();
}
#endif

void VID_ReportSystem (void)
{
	vmode_t *mode;
	vesa_info_t *info;
	int candidate;
	if (COM_CheckParm ("-stdvid"))
	{
		Sys_ReportSystem ("forced VGA; VESA discovery skipped", 0, 0);
		return;
	}
	candidate = VID_ExtraDefaultMode ();
	if (!candidate)
	{
		Sys_ReportSystem ("VGA fallback", 0, 0);
		return;
	}
	for (mode = pvidmodes; candidate; candidate--) mode = mode->pnext;
	info = mode->pextradata;
	Sys_ReportSystem (info->linear ? "VESA linear" : "VESA banked",
		info->mode, info->pitch);
}

static qboolean VID_ExtraStateFound (unsigned mask)
{
	int transition, i;
	unsigned state = 0;
	double start;
	/* Fixture builds model retrace support so startup never polls real VGA I/O. */
#if defined(BENCH486) && defined(ASM486_VESA_WAIT_FIXTURE)
	if (bench486_vesa_wait_fixture_active)
		return true;
#endif
	for (transition = 0; transition < 10; transition++, state ^= mask)
	{
		start = Sys_FloatTime ();
		for (;;)
		{
			for (i = 0; i < 100000; i++)
				if ((inportb(0x3da) & mask) == state) break;
			if (i < 100000) break;
			if (Sys_FloatTime() - start >= 0.1) return false;
		}
	}
	return true;
}

#if !defined(ASM486_VESA_WAIT) || defined(BENCH486)
static int VID_ExtraWaitStatusPortRead (void)
{
#if defined(BENCH486) && defined(ASM486_VESA_WAIT_FIXTURE)
	if (bench486_vesa_wait_fixture_active)
		return Bench486VesaWaitReadStatus (0x3da);
#endif
	return inportb (0x3da);
}

static void VID_ExtraWaitDisplayEnable (void)
{
	while (VID_ExtraWaitStatusPortRead () & 1) ;
}
#endif

int VID_ExtraInitMode (viddef_t *lvid, vmode_t *mode)
{
	vesa_info_t *info = mode->pextradata;
	const char *failure;
	int fast = mode->width == 320 && mode->height == 200;
	palette_ok = true;
	lvid->numpages = (fast || vid_nopageflip.value) ? 1 : mode->numpages;
	/* RAM is tightly packed; only the hardware pitch may include padding. */
	if (lvid->numpages == 1) lvid->rowbytes = lvid->width;
	failure = "RAM framebuffer allocation failed";
	if (!VGA_FreeAndAllocVidbuffer(lvid, lvid->numpages == 1)) goto failed;
	if (info->linear)
	{
		mapping.address = info->physical;
		mapping.size = info->pagesize * lvid->numpages;
		failure = "linear framebuffer mapping failed";
		if (__dpmi_physical_address_mapping(&mapping)) goto failed;
		mapped = true;
		VID_membase = real2ptr (mapping.address);
		if (!VID_membase) goto failed;
	}
	else VID_membase = real2ptr (info->segment << 4);
	regs.x.ax = 0x4f02;
	regs.x.bx = info->mode | (info->linear ? LINEAR_MODE : 0);
	dos_int86 (0x10);
	failure = "BIOS mode set failed";
	if (regs.x.ax != 0x4f) goto failed;
	if (!info->linear)
	{
		regs.x.ax = 0x4f05;
		regs.x.bx = info->window;
		regs.x.dx = 0;
		dos_int86 (0x10);
		failure = "bank zero selection failed";
		if (regs.x.ax != 0x4f) goto failed;
	}
	VGA_width = lvid->width;
	VGA_height = lvid->height;
	VGA_rowbytes = mode->rowbytes;
	VGA_bufferrowbytes = lvid->rowbytes;
	VID_pagesize = info->pagesize;
	VID_displayedpage = 0;
	VID_currentpage = lvid->numpages > 1 ? 1 : 0;
	vsync_exists = de_exists = wait_probed = false;
	/* The fast path does not probe or wait for retrace by default. */
	if (!(info->attributes & 0x20) && (!fast || _vid_wait_override.value || vid_wait.value))
	{
		vsync_exists = VID_ExtraStateFound (8);
		de_exists = VID_ExtraStateFound (1);
		wait_probed = true;
	}
	if (_vid_wait_override.value) Cvar_SetValue ("vid_wait", VID_WAIT_VSYNC);
	else if (!vid_wait.value)
		Cvar_SetValue ("vid_wait", lvid->numpages == 3 && de_exists ? VID_WAIT_DISPLAY_ENABLE :
			(lvid->numpages > 1 ? VID_WAIT_VSYNC : VID_WAIT_NONE));
	if (lvid->numpages > 1)
	{
		regs.x.ax = 0x4f07;
		regs.x.bx = 0;
		regs.x.cx = regs.x.dx = 0;
		dos_int86 (0x10);
		failure = "display start failed";
		if (regs.x.ax != 0x4f) goto failed;
	}
	VGA_pagebase = VID_membase + VID_currentpage * VID_pagesize;
	if (lvid->numpages > 1) lvid->buffer = lvid->conbuffer = VGA_pagebase;
	lvid->direct = VID_membase;
	lvid->colormap = Host_GetColormap ();
	lvid->fullbright = 256 - LittleLong (*((int *)lvid->colormap + 2048));
	lvid->conrowbytes = lvid->rowbytes;
	lvid->conwidth = lvid->width;
	lvid->conheight = lvid->height;
	lvid->maxwarpwidth = WARP_WIDTH;
	lvid->maxwarpheight = WARP_HEIGHT;
	VGA_pcurmode = mode;
	D_InitCaches (vid_surfcache, vid_surfcachesize);
	Con_Printf ("Video: VESA %s BIOS 0x%x pitch %d, %d page(s), %s\n",
		info->linear ? "linear" : "banked", info->mode, mode->rowbytes,
		lvid->numpages, lvid->numpages == 1 ? "RAM copy" : "page flip");
	return 1;
failed:
	Con_Printf ("VESA BIOS 0x%x: %s\n", info->mode, failure);
	VID_ExtraReleaseMode ();
	return 0;
}

#if defined(BENCH486)
#define VID_EXTRA_WAIT_DISPLAY_C_ENTRY VID_ExtraWaitDisplayIfRequested_C
#define VID_EXTRA_WAIT_VSYNC_C_ENTRY VID_ExtraWaitVsyncIfRequested_C
#define VID_EXTRA_START_WAIT_FLAGS_C_ENTRY VID_ExtraDisplayStartWaitFlags_C
#define VID_EXTRA_WAIT_DISPLAY_C_CALL VID_ExtraWaitDisplayIfRequested_C
#define VID_EXTRA_WAIT_VSYNC_C_CALL VID_ExtraWaitVsyncIfRequested_C
#define VID_EXTRA_START_WAIT_FLAGS_C_CALL VID_ExtraDisplayStartWaitFlags_C
#else
#define VID_EXTRA_WAIT_DISPLAY_C_ENTRY VID_ExtraWaitDisplayIfRequested
#define VID_EXTRA_WAIT_VSYNC_C_ENTRY VID_ExtraWaitVsyncIfRequested
#define VID_EXTRA_START_WAIT_FLAGS_C_ENTRY VID_ExtraDisplayStartWaitFlags
#define VID_EXTRA_WAIT_DISPLAY_C_CALL VID_ExtraWaitDisplayIfRequested
#define VID_EXTRA_WAIT_VSYNC_C_CALL VID_ExtraWaitVsyncIfRequested
#define VID_EXTRA_START_WAIT_FLAGS_C_CALL VID_ExtraDisplayStartWaitFlags
#endif

#if !defined(ASM486_VESA_WAIT) || defined(BENCH486)
static qboolean VID_ExtraWaitModeIs (unsigned mode_bits)
{
	union { float value; unsigned bits; } wait_mode;
	wait_mode.value = vid_wait.value;
	return wait_mode.bits == mode_bits;
}

void VID_EXTRA_WAIT_DISPLAY_C_ENTRY (void)
{
	if (!VID_ExtraWaitModeIs (0x40000000U) || !de_exists) return;
#if defined(BENCH486) && defined(ASM486_VESA_SWAP_BUFFERS_FIXTURE)
	if (bench486_vesa_swap_fixture_active)
	{
		Bench486VesaSwapWaitDisplayEnable ();
		return;
	}
#endif
	VID_ExtraWaitDisplayEnable ();
}

void VID_EXTRA_WAIT_VSYNC_C_ENTRY (void)
{
	if (!VID_ExtraWaitModeIs (0x3f800000U) || !vsync_exists) return;
#if defined(BENCH486) && defined(ASM486_VESA_SWAP_BUFFERS_FIXTURE)
	if (bench486_vesa_swap_fixture_active)
	{
		Bench486VesaSwapWaitVsync ();
		return;
	}
#endif
#if defined(BENCH486) && defined(ASM486_VESA_WAIT_FIXTURE)
	if (bench486_vesa_wait_fixture_active)
	{
		while ((VID_ExtraWaitStatusPortRead () & 0x08) == 0) ;
		return;
	}
#endif
	VGA_WaitVsync ();
}

int VID_EXTRA_START_WAIT_FLAGS_C_ENTRY (void)
{
	return VID_ExtraWaitModeIs (0x3f800000U) ? 0x80 : 0;
}
#endif

#if defined(BENCH486) && !defined(ASM486_VESA_WAIT)
void VID_ExtraWaitDisplayIfRequested (void)
	{ VID_ExtraWaitDisplayIfRequested_C (); }
void VID_ExtraWaitVsyncIfRequested (void)
	{ VID_ExtraWaitVsyncIfRequested_C (); }
int VID_ExtraDisplayStartWaitFlags (void)
	{ return VID_ExtraDisplayStartWaitFlags_C (); }
#endif

#undef VID_EXTRA_START_WAIT_FLAGS_C_ENTRY
#undef VID_EXTRA_WAIT_VSYNC_C_ENTRY
#undef VID_EXTRA_WAIT_DISPLAY_C_ENTRY

void VID_ExtraProbeWaitIfNeeded (vmode_t *mode)
{
	if (!vid_wait.value || wait_probed ||
		(((vesa_info_t *)mode->pextradata)->attributes & 0x20)) return;
#if defined(BENCH486) && defined(ASM486_VESA_SWAP_BUFFERS_FIXTURE)
	if (bench486_vesa_swap_fixture_active)
	{
		Bench486VesaSwapProbeWait ();
		return;
	}
#endif
	vsync_exists = VID_ExtraStateFound (8);
	de_exists = VID_ExtraStateFound (1);
	wait_probed = true;
}

void VID_ExtraSetDisplayStart (int x, int y, int waitflags)
{
#if defined(BENCH486) && defined(ASM486_VESA_SWAP_BUFFERS_FIXTURE)
	if (bench486_vesa_swap_fixture_active)
	{
		Bench486VesaSwapDisplayStart (x, y, waitflags);
		return;
	}
#endif
	regs.x.ax = 0x4f07;
	regs.x.bx = waitflags;
	regs.x.cx = x;
	regs.x.dx = y;
	dos_int86 (0x10);
}

void VID_ExtraCopyRects (vrect_t *rects, byte *srcbase, byte *dstbase,
		int vidwidth, int vidheight, int srcrowbytes, int destrowbytes)
{
	VESA_CopyRects_Entry (rects, srcbase, dstbase, vidwidth, vidheight,
		srcrowbytes, destrowbytes);
}

#if !defined(ASM486_VESA_SWAP_BUFFERS) || defined(BENCH486)
void VID_ExtraSwapBuffers_C (viddef_t *lvid, vmode_t *mode, vrect_t *rects)
{
	int offset;
	if (lvid->numpages > 1)
	{
		offset = VID_currentpage * VID_pagesize;
		VID_EXTRA_WAIT_DISPLAY_C_CALL ();
		VID_ExtraSetDisplayStart (offset % VGA_rowbytes,
			offset / VGA_rowbytes, VID_EXTRA_START_WAIT_FLAGS_C_CALL ());
		VID_displayedpage = VID_currentpage;
		if (++VID_currentpage >= lvid->numpages) VID_currentpage = 0;
		lvid->direct = VID_membase + VID_displayedpage * VID_pagesize;
		lvid->buffer = lvid->conbuffer = VGA_pagebase = VID_membase + VID_currentpage * VID_pagesize;
		return;
	}
	/* Probe only once when an explicit runtime wait first requests it. */
	VID_ExtraProbeWaitIfNeeded (mode);
	VID_EXTRA_WAIT_VSYNC_C_CALL ();
	VID_EXTRA_WAIT_DISPLAY_C_CALL ();
	VID_ExtraCopyRects (rects, lvid->buffer, VGA_pagebase, lvid->width,
		lvid->height, lvid->rowbytes, VGA_rowbytes);
}
#endif

#undef VID_EXTRA_START_WAIT_FLAGS_C_CALL
#undef VID_EXTRA_WAIT_VSYNC_C_CALL
#undef VID_EXTRA_WAIT_DISPLAY_C_CALL

void VID_ExtraSwapBuffers (viddef_t *lvid, vmode_t *mode, vrect_t *rects)
{
#ifdef ASM486_VESA_SWAP_BUFFERS
	VID_ExtraSwapBuffers_ASM (lvid, mode, rects);
#else
	VID_ExtraSwapBuffers_C (lvid, mode, rects);
#endif
}

#if defined(BENCH486) && defined(ASM486_VESA_COPY_RECTS_FIXTURE)
#include "tests/bench486/bench486_vesacopy.h"
#endif

#if defined(BENCH486) && defined(ASM486_VESA_SWAP_BUFFERS_FIXTURE)
#include "tests/bench486/bench486_vesaswap.h"
#endif
