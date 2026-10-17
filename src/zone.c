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
// Z_zone.c

#include "quakedef.h"

#define	DYNAMIC_SIZE	0xc000

#define	ZONEID	0x1d4a11
#define MINFRAGMENT	64

typedef struct memblock_s
{
	int		size;           // including the header and possibly tiny fragments
	int     tag;            // a tag of 0 is a free block
	int     id;        		// should be ZONEID
	struct memblock_s       *next, *prev;
	int		pad;			// pad to 64 bit boundary
} memblock_t;

typedef struct
{
	int		size;		// total bytes malloced, including header
	memblock_t	blocklist;		// start / end cap for linked list
	memblock_t	*rover;
} memzone_t;

#include "asm_zoneheap.h"

#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
void Bench486MemoryAddCommand (char *cmd_name, xcommand_t function);
void Bench486ZoneHeapError (char *message);
#endif

void Cache_FreeLow (int new_low_hunk);
void Cache_FreeHigh (int new_high_hunk);

#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
extern int bench486_screen_center_trace_active;
extern void Bench486ScreenCenterTraceGlyph (int phase, int x, int y, int character);
#define HUNK_TRACE(phase, x, y, character) \
	do { if (bench486_screen_center_trace_active < 0) \
		bench486_screen_center_trace_active = COM_CheckParm ("-benchcentercalltrace") != 0; \
		if (bench486_screen_center_trace_active) \
		Bench486ScreenCenterTraceGlyph (phase, x, y, character); } while (0)
#else
#define HUNK_TRACE(phase, x, y, character) ((void)0)
#endif

#if defined(BENCH486) && defined(ASM486_HUNK_NAMED_ALLOC) && defined(ASM486_SCREEN_CENTER_STRING)
void Bench486HunkNamedAllocTrace (int phase, int x, int y, int character)
{
	HUNK_TRACE (phase, x, y, character);
}
#endif


/*
==============================================================================

						ZONE MEMORY ALLOCATION

There is never any space between memblocks, and there will never be two
contiguous free memblocks.

The rover can be left pointing at a non-empty block

The zone calls are pretty much only used for small strings and structures,
all big things are allocated on the hunk.
==============================================================================
*/

memzone_t	*mainzone;

#ifdef PROFILE486
unsigned long bench486_zone_malloc_calls;
unsigned long bench486_zone_malloc_bytes;
unsigned long bench486_zone_check_calls;
unsigned long bench486_zone_check_blocks;
unsigned long bench486_zone_scan_iterations;
unsigned long bench486_zone_splits;
unsigned long bench486_zone_coalesces;
unsigned long bench486_zone_failed_allocations;
unsigned long bench486_hunk_low_calls;
unsigned long bench486_hunk_low_bytes;
unsigned long bench486_hunk_high_calls;
unsigned long bench486_hunk_high_bytes;
unsigned long bench486_cache_checks;
unsigned long bench486_cache_hits;
unsigned long bench486_cache_misses;
unsigned long bench486_cache_lru_relinks;
unsigned long bench486_cache_allocations;
unsigned long bench486_cache_frees;
unsigned long bench486_cache_evictions;
unsigned long bench486_cache_tryalloc_scans;
unsigned long bench486_cache_tryalloc_failures;
unsigned long bench486_cache_moves;
unsigned long bench486_cache_move_bytes;

void Zone_ResetProfileCounters (void)
{
	bench486_zone_malloc_calls = 0;
	bench486_zone_malloc_bytes = 0;
	bench486_zone_check_calls = 0;
	bench486_zone_check_blocks = 0;
	bench486_zone_scan_iterations = 0;
	bench486_zone_splits = 0;
	bench486_zone_coalesces = 0;
	bench486_zone_failed_allocations = 0;
	bench486_hunk_low_calls = 0;
	bench486_hunk_low_bytes = 0;
	bench486_hunk_high_calls = 0;
	bench486_hunk_high_bytes = 0;
	bench486_cache_checks = 0;
	bench486_cache_hits = 0;
	bench486_cache_misses = 0;
	bench486_cache_lru_relinks = 0;
	bench486_cache_allocations = 0;
	bench486_cache_frees = 0;
	bench486_cache_evictions = 0;
	bench486_cache_tryalloc_scans = 0;
	bench486_cache_tryalloc_failures = 0;
	bench486_cache_moves = 0;
	bench486_cache_move_bytes = 0;
}
#endif

#if defined(BENCH486)
#define Z_CLEAR_ZONE_C_ENTRY Z_ClearZone_C
#define Z_FREE_C_ENTRY Z_Free_C
#define Z_TAG_MALLOC_C_ENTRY Z_TagMalloc_C
#else
#define Z_CLEAR_ZONE_C_ENTRY Z_ClearZone
#define Z_FREE_C_ENTRY Z_Free
#define Z_TAG_MALLOC_C_ENTRY Z_TagMalloc
#endif

void Z_ClearZone (memzone_t *zone, int size);


/*
========================
Z_ClearZone
========================
*/
#if !defined(ASM486_ZONE_HEAP) || defined(BENCH486)
void Z_CLEAR_ZONE_C_ENTRY (memzone_t *zone, int size)
{
	memblock_t	*block;
	
// set the entire zone to one free block

	zone->blocklist.next = zone->blocklist.prev = block =
		(memblock_t *)( (byte *)zone + sizeof(memzone_t) );
	zone->blocklist.tag = 1;	// in use block
	zone->blocklist.id = 0;
	zone->blocklist.size = 0;
	zone->rover = block;
	
	block->prev = block->next = &zone->blocklist;
	block->tag = 0;			// free block
	block->id = ZONEID;
	block->size = size - sizeof(memzone_t);
}
#endif

#if defined(BENCH486) && !defined(ASM486_ZONE_HEAP)
void Z_ClearZone (memzone_t *zone, int size)
{
	Z_ClearZone_C (zone, size);
}
#endif


/*
========================
Z_Free
========================
*/
#if !defined(ASM486_ZONE_HEAP) || defined(BENCH486)
void Z_FREE_C_ENTRY (void *ptr)
{
	memblock_t	*block, *other;
	
	if (!ptr)
		Sys_Error ("Z_Free: NULL pointer");

	block = (memblock_t *) ( (byte *)ptr - sizeof(memblock_t));
	if (block->id != ZONEID)
		Sys_Error ("Z_Free: freed a pointer without ZONEID");
	if (block->tag == 0)
		Sys_Error ("Z_Free: freed a freed pointer");

	block->tag = 0;		// mark as free
	
	other = block->prev;
	if (!other->tag)
	{	// merge with previous free block
#ifdef PROFILE486
		bench486_zone_coalesces++;
#endif
		other->size += block->size;
		other->next = block->next;
		other->next->prev = other;
		if (block == mainzone->rover)
			mainzone->rover = other;
		block = other;
	}
	
	other = block->next;
	if (!other->tag)
	{	// merge the next free block onto the end
#ifdef PROFILE486
		bench486_zone_coalesces++;
#endif
		block->size += other->size;
		block->next = other->next;
		block->next->prev = block;
		if (other == mainzone->rover)
			mainzone->rover = block;
	}
}
#endif

#if defined(BENCH486) && !defined(ASM486_ZONE_HEAP)
void Z_Free (void *ptr)
{
	Z_Free_C (ptr);
}
#endif


/*
========================
Z_Malloc
========================
*/
#if defined(BENCH486)
#define Z_MALLOC_C_ENTRY Z_Malloc_C
#else
#define Z_MALLOC_C_ENTRY Z_Malloc
#endif

#if !defined(ASM486_ZONE_HEAP) || defined(BENCH486)
void *Z_MALLOC_C_ENTRY (int size)
{
	void	*buf;
	
#ifdef PROFILE486
	bench486_zone_malloc_calls++;
	bench486_zone_malloc_bytes += size;
#endif
#ifdef PARANOID
	Z_CheckHeap ();
#endif
	buf = Z_TagMalloc (size, 1);
	if (!buf)
		Sys_Error ("Z_Malloc: failed on allocation of %i bytes",size);
	Q_memset (buf, 0, size);

	return buf;
}
#endif

#undef Z_MALLOC_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_ZONE_HEAP)
void *Z_Malloc (int size)
{
	return Z_Malloc_C (size);
}
#endif

#if !defined(ASM486_ZONE_HEAP) || defined(BENCH486)
void *Z_TAG_MALLOC_C_ENTRY (int size, int tag)
{
	int		extra;
	memblock_t	*start, *rover, *new, *base;

	if (!tag)
		Sys_Error ("Z_TagMalloc: tried to use a 0 tag");

//
// scan through the block list looking for the first free block
// of sufficient size
//
	size += sizeof(memblock_t);	// account for size of block header
	size += 4;					// space for memory trash tester
	size = (size + 7) & ~7;		// align to 8-byte boundary
	
	base = rover = mainzone->rover;
	start = base->prev;
	
	do
	{
#ifdef PROFILE486
		bench486_zone_scan_iterations++;
#endif
		if (rover == start)	// scaned all the way around the list
		{
#ifdef PROFILE486
			bench486_zone_failed_allocations++;
#endif
			return NULL;
		}
		if (rover->tag)
			base = rover = rover->next;
		else
			rover = rover->next;
	} while (base->tag || base->size < size);
	
//
// found a block big enough
//
	extra = base->size - size;
	if (extra >  MINFRAGMENT)
	{	// there will be a free fragment after the allocated block
#ifdef PROFILE486
		bench486_zone_splits++;
#endif
		new = (memblock_t *) ((byte *)base + size );
		new->size = extra;
		new->tag = 0;			// free block
		new->prev = base;
		new->id = ZONEID;
		new->next = base->next;
		new->next->prev = new;
		base->next = new;
		base->size = size;
	}
	
	base->tag = tag;				// no longer a free block
	
	mainzone->rover = base->next;	// next allocation will start looking here
	
	base->id = ZONEID;

// marker for memory trash testing
	*(int *)((byte *)base + base->size - 4) = ZONEID;

	return (void *) ((byte *)base + sizeof(memblock_t));
}
#endif

#if defined(BENCH486) && !defined(ASM486_ZONE_HEAP)
void *Z_TagMalloc (int size, int tag)
{
	return Z_TagMalloc_C (size, tag);
}
#endif

#undef Z_CLEAR_ZONE_C_ENTRY
#undef Z_FREE_C_ENTRY
#undef Z_TAG_MALLOC_C_ENTRY


/*
========================
Z_Print
========================
*/
void Z_Print (memzone_t *zone)
{
	memblock_t	*block;
	
	Con_Printf ("zone size: %i  location: %p\n",mainzone->size,mainzone);
	
	for (block = zone->blocklist.next ; ; block = block->next)
	{
		Con_Printf ("block:%p    size:%7i    tag:%3i\n",
			block, block->size, block->tag);
		
		if (block->next == &zone->blocklist)
			break;			// all blocks have been hit	
		if ( (byte *)block + block->size != (byte *)block->next)
			Con_Printf ("ERROR: block size does not touch the next block\n");
		if ( block->next->prev != block)
			Con_Printf ("ERROR: next block doesn't have proper back link\n");
		if (!block->tag && !block->next->tag)
			Con_Printf ("ERROR: two consecutive free blocks\n");
	}
}


/*
========================
Z_CheckHeap
========================
*/
#if defined(BENCH486)
#define Z_CHECK_HEAP_C_ENTRY Z_CheckHeap_C
#else
#define Z_CHECK_HEAP_C_ENTRY Z_CheckHeap
#endif

#if !defined(ASM486_ZONE_HEAP) || defined(BENCH486)
void Z_CHECK_HEAP_C_ENTRY (void)
{
	memblock_t	*block;
	
#ifdef PROFILE486
	bench486_zone_check_calls++;
#endif
	for (block = mainzone->blocklist.next ; ; block = block->next)
	{
		if (block->next == &mainzone->blocklist)
			break;			// all blocks have been hit	
#ifdef PROFILE486
		bench486_zone_check_blocks++;
#endif
		if ( (byte *)block + block->size != (byte *)block->next)
		{
#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
			Bench486ZoneHeapError ("Z_CheckHeap: block size does not touch the next block\n");
#else
			Sys_Error ("Z_CheckHeap: block size does not touch the next block\n");
#endif
		}
		if ( block->next->prev != block)
		{
#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
			Bench486ZoneHeapError ("Z_CheckHeap: next block doesn't have proper back link\n");
#else
			Sys_Error ("Z_CheckHeap: next block doesn't have proper back link\n");
#endif
		}
		if (!block->tag && !block->next->tag)
		{
#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
			Bench486ZoneHeapError ("Z_CheckHeap: two consecutive free blocks\n");
#else
			Sys_Error ("Z_CheckHeap: two consecutive free blocks\n");
#endif
		}
	}
}
#endif

#undef Z_CHECK_HEAP_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_ZONE_HEAP)
void Z_CheckHeap (void)
{
	Z_CheckHeap_C ();
}
#endif

//============================================================================

#define	HUNK_SENTINAL	0x1df001ed

typedef struct
{
	int		sentinal;
	int		size;		// including sizeof(hunk_t), -1 = not allocated
	char	name[8];
} hunk_t;

#include "asm_hunknamedalloc.h"

byte	*hunk_base;
int		hunk_size;

int		hunk_low_used;
int		hunk_high_used;

qboolean	hunk_tempactive;
int		hunk_tempmark;

#include "asm_hunkmarkfree.h"
#include "asm_hunktempalloc.h"

void R_FreeTextures (void);

/*
==============
Hunk_Check

Run consistancy and sentinal trahing checks
==============
*/
#if defined(BENCH486)
#define HUNK_CHECK_C_ENTRY Hunk_Check_C
#else
#define HUNK_CHECK_C_ENTRY Hunk_Check
#endif

#if !defined(ASM486_ZONE_HEAP) || defined(BENCH486)
void HUNK_CHECK_C_ENTRY (void)
{
	hunk_t	*h;
	
	for (h = (hunk_t *)hunk_base ; (byte *)h != hunk_base + hunk_low_used ; )
	{
		if (h->sentinal != HUNK_SENTINAL)
		{
#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
			Bench486ZoneHeapError ("Hunk_Check: trahsed sentinal");
#else
			Sys_Error ("Hunk_Check: trahsed sentinal");
#endif
		}
		if (h->size < 16 || h->size + (byte *)h - hunk_base > hunk_size)
		{
#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
			Bench486ZoneHeapError ("Hunk_Check: bad size");
#else
			Sys_Error ("Hunk_Check: bad size");
#endif
		}
		h = (hunk_t *)((byte *)h+h->size);
	}
}
#endif

#undef HUNK_CHECK_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_ZONE_HEAP)
void Hunk_Check (void)
{
	Hunk_Check_C ();
}
#endif

/*
==============
Hunk_Print

If "all" is specified, every single allocation is printed.
Otherwise, allocations with the same name will be totaled up before printing.
==============
*/
void Hunk_Print (qboolean all)
{
	hunk_t	*h, *next, *endlow, *starthigh, *endhigh;
	int		count, sum;
	int		totalblocks;
	char	name[9];

	name[8] = 0;
	count = 0;
	sum = 0;
	totalblocks = 0;
	
	h = (hunk_t *)hunk_base;
	endlow = (hunk_t *)(hunk_base + hunk_low_used);
	starthigh = (hunk_t *)(hunk_base + hunk_size - hunk_high_used);
	endhigh = (hunk_t *)(hunk_base + hunk_size);

	Con_Printf ("          :%8i total hunk size\n", hunk_size);
	Con_Printf ("-------------------------\n");

	while (1)
	{
	//
	// skip to the high hunk if done with low hunk
	//
		if ( h == endlow )
		{
			Con_Printf ("-------------------------\n");
			Con_Printf ("          :%8i REMAINING\n", hunk_size - hunk_low_used - hunk_high_used);
			Con_Printf ("-------------------------\n");
			h = starthigh;
		}
		
	//
	// if totally done, break
	//
		if ( h == endhigh )
			break;

	//
	// run consistancy checks
	//
		if (h->sentinal != HUNK_SENTINAL)
			Sys_Error ("Hunk_Check: trahsed sentinal");
		if (h->size < 16 || h->size + (byte *)h - hunk_base > hunk_size)
			Sys_Error ("Hunk_Check: bad size");
			
		next = (hunk_t *)((byte *)h+h->size);
		count++;
		totalblocks++;
		sum += h->size;

	//
	// print the single block
	//
		memcpy (name, h->name, 8);
		if (all)
			Con_Printf ("%8p :%8i %8s\n",h, h->size, name);
			
	//
	// print the total
	//
		if (next == endlow || next == endhigh || 
		strncmp (h->name, next->name, 8) )
		{
			if (!all)
				Con_Printf ("          :%8i %8s (TOTAL)\n",sum, name);
			count = 0;
			sum = 0;
		}

		h = next;
	}

	Con_Printf ("-------------------------\n");
	Con_Printf ("%8i total blocks\n", totalblocks);
	
}

/*
===================
Hunk_AllocName
===================
*/
#if defined(BENCH486)
#define HUNK_ALLOC_NAME_C_ENTRY Hunk_AllocName_C
#define HUNK_HIGH_ALLOC_NAME_C_ENTRY Hunk_HighAllocName_C
#else
#define HUNK_ALLOC_NAME_C_ENTRY Hunk_AllocName
#define HUNK_HIGH_ALLOC_NAME_C_ENTRY Hunk_HighAllocName
#endif

#if !defined(ASM486_HUNK_NAMED_ALLOC) || defined(BENCH486)
void *HUNK_ALLOC_NAME_C_ENTRY (int size, char *name)
{
	hunk_t	*h;
	HUNK_TRACE (72, size, hunk_low_used, hunk_high_used);
	
#ifdef PARANOID
	Hunk_Check ();
#endif

	if (size < 0)
		Sys_Error ("Hunk_Alloc: bad size: %i", size);
		
	size = sizeof(hunk_t) + ((size+15)&~15);
	HUNK_TRACE (73, size, hunk_size - hunk_low_used - hunk_high_used, hunk_size);
	
	if (hunk_size - hunk_low_used - hunk_high_used < size)
		Sys_Error ("Hunk_Alloc: failed on %i bytes",size);
	
	h = (hunk_t *)(hunk_base + hunk_low_used);
#ifdef PROFILE486
	bench486_hunk_low_calls++;
	bench486_hunk_low_bytes += size;
#endif
	hunk_low_used += size;

	Cache_FreeLow (hunk_low_used);
	HUNK_TRACE (74, size, hunk_low_used, hunk_high_used);

	memset (h, 0, size);
	HUNK_TRACE (75, size, hunk_low_used, 0);
	
	h->size = size;
	h->sentinal = HUNK_SENTINAL;
	Q_strncpy (h->name, name, 8);
	HUNK_TRACE (76, size, hunk_low_used, 0);
	
	return (void *)(h+1);
}
#endif

#if defined(BENCH486) && !defined(ASM486_HUNK_NAMED_ALLOC)
void *Hunk_AllocName (int size, char *name)
{
	return Hunk_AllocName_C (size, name);
}
#endif

/*
===================
Hunk_Alloc
===================
*/
void *Hunk_Alloc (int size)
{
	return Hunk_AllocName (size, "unknown");
}

#if defined(ASM486_FRAME_CONTROL)
#if defined(BENCH486)
int Hunk_LowMark_C (void)
{
	return hunk_low_used;
}
#endif
#else
int Hunk_LowMark (void)
{
	return hunk_low_used;
}
#endif

#if defined(BENCH486)
#define HUNK_HIGH_MARK_C_ENTRY Hunk_HighMark_C
#else
#define HUNK_HIGH_MARK_C_ENTRY Hunk_HighMark
#endif

#if !defined(ASM486_HUNK_MARK_RELEASE) || defined(BENCH486)
int HUNK_HIGH_MARK_C_ENTRY (void)
{
	if (hunk_tempactive)
	{
		hunk_tempactive = false;
		Hunk_FreeToHighMark (hunk_tempmark);
	}

	return hunk_high_used;
}
#endif

#undef HUNK_HIGH_MARK_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_HUNK_MARK_RELEASE)
int Hunk_HighMark (void)
{
	return Hunk_HighMark_C ();
}
#endif

#if defined(BENCH486)
#define HUNK_FREE_LOW_C_ENTRY Hunk_FreeToLowMark_C
#define HUNK_FREE_HIGH_C_ENTRY Hunk_FreeToHighMark_C
#define HUNK_FREE_HIGH_RECURSIVE_ENTRY Hunk_FreeToHighMark_C
#else
#define HUNK_FREE_LOW_C_ENTRY Hunk_FreeToLowMark
#define HUNK_FREE_HIGH_C_ENTRY Hunk_FreeToHighMark
#define HUNK_FREE_HIGH_RECURSIVE_ENTRY Hunk_FreeToHighMark
#endif

#if !defined(ASM486_HUNK_MARK_RELEASE) || defined(BENCH486)
void HUNK_FREE_LOW_C_ENTRY (int mark)
{
	if (mark < 0 || mark > hunk_low_used)
		Sys_Error ("Hunk_FreeToLowMark: bad mark %i", mark);
	memset (hunk_base + mark, 0, hunk_low_used - mark);
	hunk_low_used = mark;
}

void HUNK_FREE_HIGH_C_ENTRY (int mark)
{
	if (hunk_tempactive)
	{
		hunk_tempactive = false;
		HUNK_FREE_HIGH_RECURSIVE_ENTRY (hunk_tempmark);
	}
	if (mark < 0 || mark > hunk_high_used)
		Sys_Error ("Hunk_FreeToHighMark: bad mark %i", mark);
	memset (hunk_base + hunk_size - hunk_high_used, 0, hunk_high_used - mark);
	hunk_high_used = mark;
}
#endif

#undef HUNK_FREE_HIGH_RECURSIVE_ENTRY
#undef HUNK_FREE_LOW_C_ENTRY
#undef HUNK_FREE_HIGH_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_HUNK_MARK_RELEASE)
void Hunk_FreeToLowMark (int mark)
{
	Hunk_FreeToLowMark_C (mark);
}

void Hunk_FreeToHighMark (int mark)
{
	Hunk_FreeToHighMark_C (mark);
}
#endif

#if defined(BENCH486) && defined(ASM486_HUNK_MARK_RELEASE_FIXTURE)
#include "bench486_hunkmarkfree.h"
#endif

/*
===================
Hunk_HighAllocName
===================
*/
#if !defined(ASM486_HUNK_NAMED_ALLOC) || defined(BENCH486)
void *HUNK_HIGH_ALLOC_NAME_C_ENTRY (int size, char *name)
{
	hunk_t	*h;
	HUNK_TRACE (77, size, hunk_low_used, hunk_high_used);

	if (size < 0)
		Sys_Error ("Hunk_HighAllocName: bad size: %i", size);

	if (hunk_tempactive)
	{
		Hunk_FreeToHighMark (hunk_tempmark);
		hunk_tempactive = false;
	}

#ifdef PARANOID
	Hunk_Check ();
#endif

	size = sizeof(hunk_t) + ((size+15)&~15);
	HUNK_TRACE (78, size, hunk_size - hunk_low_used - hunk_high_used, hunk_size);

	if (hunk_size - hunk_low_used - hunk_high_used < size)
	{
		Con_Printf ("Hunk_HighAlloc: failed on %i bytes\n",size);
		return NULL;
	}

	hunk_high_used += size;
	HUNK_TRACE (79, size, hunk_low_used, hunk_high_used);
#ifdef PROFILE486
	bench486_hunk_high_calls++;
	bench486_hunk_high_bytes += size;
#endif
	Cache_FreeHigh (hunk_high_used);
	HUNK_TRACE (80, size, hunk_low_used, hunk_high_used);

	h = (hunk_t *)(hunk_base + hunk_size - hunk_high_used);

	memset (h, 0, size);
	h->size = size;
	h->sentinal = HUNK_SENTINAL;
	Q_strncpy (h->name, name, 8);
	HUNK_TRACE (81, size, hunk_low_used, hunk_high_used);

	return (void *)(h+1);
}
#endif

#if defined(BENCH486) && !defined(ASM486_HUNK_NAMED_ALLOC)
void *Hunk_HighAllocName (int size, char *name)
{
	return Hunk_HighAllocName_C (size, name);
}
#endif

#undef HUNK_ALLOC_NAME_C_ENTRY
#undef HUNK_HIGH_ALLOC_NAME_C_ENTRY


/*
=================
Hunk_TempAlloc

Return space from the top of the hunk
=================
*/
#if defined(BENCH486)
#define HUNK_TEMP_ALLOC_C_ENTRY Hunk_TempAlloc_C
#else
#define HUNK_TEMP_ALLOC_C_ENTRY Hunk_TempAlloc
#endif

#if !defined(ASM486_HUNK_TEMP_ALLOC) || defined(BENCH486)
void *HUNK_TEMP_ALLOC_C_ENTRY (int size)
{
	void	*buf;

	size = (size+15)&~15;
	
	if (hunk_tempactive)
	{
		Hunk_FreeToHighMark (hunk_tempmark);
		hunk_tempactive = false;
	}
	
	hunk_tempmark = Hunk_HighMark ();

	buf = Hunk_HighAllocName (size, "temp");

	hunk_tempactive = true;

	return buf;
}
#endif

#undef HUNK_TEMP_ALLOC_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_HUNK_TEMP_ALLOC)
void *Hunk_TempAlloc (int size)
{
	return Hunk_TempAlloc_C (size);
}
#endif

/*
===============================================================================

CACHE MEMORY

===============================================================================
*/

typedef struct cache_system_s
{
	int						size;		// including this header
	cache_user_t			*user;
	char					name[16];
	struct cache_system_s	*prev, *next;
	struct cache_system_s	*lru_prev, *lru_next;	// for LRU flushing	
} cache_system_t;

#include "asm_cachecheck.h"
#include "asm_cachealloc.h"
#include "asm_cachefree.h"
#include "asm_cachetryalloc.h"
#include "asm_cachefreelow.h"
#include "asm_cachefreehigh.h"

cache_system_t *Cache_TryAlloc (int size, qboolean nobottom);

cache_system_t	cache_head;

/*
===========
Cache_Move
===========
*/
#if defined(BENCH486)
#define CACHE_MOVE_C_ENTRY Cache_Move_C
#else
#define CACHE_MOVE_C_ENTRY Cache_Move
#endif

#if !defined(ASM486_CACHE_MOVE) || defined(BENCH486)
void CACHE_MOVE_C_ENTRY ( cache_system_t *c)
{
	cache_system_t		*new;

// we are clearing up space at the bottom, so only allocate it late
	new = Cache_TryAlloc (c->size, true);
#ifdef PROFILE486
	bench486_cache_moves++;
	bench486_cache_move_bytes += c->size - sizeof(cache_system_t);
#endif
	if (new)
	{
//		Con_Printf ("cache_move ok\n");

		Q_memcpy ( new+1, c+1, c->size - sizeof(cache_system_t) );
		new->user = c->user;
		Q_memcpy (new->name, c->name, sizeof(new->name));
		Cache_Free (c->user);
		new->user->data = (void *)(new+1);
	}
	else
	{
//		Con_Printf ("cache_move failed\n");

		Cache_Free (c->user);		// tough luck...
	}
}

#endif

#undef CACHE_MOVE_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_CACHE_MOVE)
void Cache_Move (cache_system_t *c)
{
	Cache_Move_C (c);
}
#endif

#if defined(BENCH486) && defined(ASM486_CACHE_MOVE_FIXTURE)
#include "bench486_cachemove.h"
#endif

/*
============
Cache_FreeLow

Throw things out until the hunk can be expanded to the given point
============
*/
#if defined(BENCH486)
#define CACHE_FREE_LOW_C_ENTRY Cache_FreeLow_C
#else
#define CACHE_FREE_LOW_C_ENTRY Cache_FreeLow
#endif

#if !defined(ASM486_CACHE_FREE_LOW) || defined(BENCH486)
void CACHE_FREE_LOW_C_ENTRY (int new_low_hunk)
{
	cache_system_t	*c;
	
	while (1)
	{
		c = cache_head.next;
		if (c == &cache_head)
			return;		// nothing in cache at all
		if ((byte *)c >= hunk_base + new_low_hunk)
			return;		// there is space to grow the hunk
		Cache_Move ( c );	// reclaim the space
	}
}
#endif

#undef CACHE_FREE_LOW_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_CACHE_FREE_LOW)
void Cache_FreeLow (int new_low_hunk)
{
	Cache_FreeLow_C (new_low_hunk);
}
#endif

#if defined(BENCH486) && defined(ASM486_CACHE_FREE_LOW_FIXTURE)
#include "bench486_cachefreelow.h"
#endif

/*
============
Cache_FreeHigh

Throw things out until the hunk can be expanded to the given point
============
*/
#if defined(BENCH486)
#define CACHE_FREE_HIGH_C_ENTRY Cache_FreeHigh_C
#else
#define CACHE_FREE_HIGH_C_ENTRY Cache_FreeHigh
#endif

#if !defined(ASM486_CACHE_FREE_HIGH) || defined(BENCH486)
void CACHE_FREE_HIGH_C_ENTRY (int new_high_hunk)
{
	cache_system_t	*c, *prev;
	
	prev = NULL;
	while (1)
	{
		c = cache_head.prev;
		if (c == &cache_head)
			return;		// nothing in cache at all
		if ( (byte *)c + c->size <= hunk_base + hunk_size - new_high_hunk)
			return;		// there is space to grow the hunk
		if (c == prev)
			Cache_Free (c->user);	// didn't move out of the way
		else
		{
			Cache_Move (c);	// try to move it
			prev = c;
		}
	}
}
#endif

#undef CACHE_FREE_HIGH_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_CACHE_FREE_HIGH)
void Cache_FreeHigh (int new_high_hunk)
{
	Cache_FreeHigh_C (new_high_hunk);
}
#endif

#if defined(BENCH486) && defined(ASM486_CACHE_FREE_HIGH_FIXTURE)
#include "bench486_cachefreehigh.h"
#endif

void Cache_UnlinkLRU (cache_system_t *cs)
{
	if (!cs->lru_next || !cs->lru_prev)
		Sys_Error ("Cache_UnlinkLRU: NULL link");

	cs->lru_next->lru_prev = cs->lru_prev;
	cs->lru_prev->lru_next = cs->lru_next;
	
	cs->lru_prev = cs->lru_next = NULL;
}

void Cache_MakeLRU (cache_system_t *cs)
{
	if (cs->lru_next || cs->lru_prev)
		Sys_Error ("Cache_MakeLRU: active link");

	cache_head.lru_next->lru_prev = cs;
	cs->lru_next = cache_head.lru_next;
	cs->lru_prev = &cache_head;
	cache_head.lru_next = cs;
}

/*
============
Cache_TryAlloc

Looks for a free block of memory between the high and low hunk marks
Size should already include the header and padding
============
*/
#if defined(BENCH486)
#define CACHE_TRYALLOC_C_ENTRY Cache_TryAlloc_C
#else
#define CACHE_TRYALLOC_C_ENTRY Cache_TryAlloc
#endif

#if !defined(ASM486_CACHE_TRY_ALLOC) || defined(BENCH486)
cache_system_t *CACHE_TRYALLOC_C_ENTRY (int size, qboolean nobottom)
{
	cache_system_t	*cs, *new;
	
// is the cache completely empty?

	if (!nobottom && cache_head.prev == &cache_head)
	{
		if (hunk_size - hunk_high_used - hunk_low_used < size)
			Sys_Error ("Cache_TryAlloc: %i is greater then free hunk", size);

		new = (cache_system_t *) (hunk_base + hunk_low_used);
		memset (new, 0, sizeof(*new));
		new->size = size;

		cache_head.prev = cache_head.next = new;
		new->prev = new->next = &cache_head;
		
		Cache_MakeLRU (new);
		return new;
	}
	
// search from the bottom up for space

	new = (cache_system_t *) (hunk_base + hunk_low_used);
	cs = cache_head.next;
	
	do
	{
#ifdef PROFILE486
		bench486_cache_tryalloc_scans++;
#endif
		if (!nobottom || cs != cache_head.next)
		{
			if ( (byte *)cs - (byte *)new >= size)
			{	// found space
				memset (new, 0, sizeof(*new));
				new->size = size;
				
				new->next = cs;
				new->prev = cs->prev;
				cs->prev->next = new;
				cs->prev = new;
				
				Cache_MakeLRU (new);
	
				return new;
			}
		}

	// continue looking		
		new = (cache_system_t *)((byte *)cs + cs->size);
		cs = cs->next;

	} while (cs != &cache_head);
	
// try to allocate one at the very end
	if ( hunk_base + hunk_size - hunk_high_used - (byte *)new >= size)
	{
		memset (new, 0, sizeof(*new));
		new->size = size;
		
		new->next = &cache_head;
		new->prev = cache_head.prev;
		cache_head.prev->next = new;
		cache_head.prev = new;
		
		Cache_MakeLRU (new);

		return new;
	}
	
#ifdef PROFILE486
	bench486_cache_tryalloc_failures++;
#endif
	return NULL;		// couldn't allocate
}
#endif

#undef CACHE_TRYALLOC_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_CACHE_TRY_ALLOC)
cache_system_t *Cache_TryAlloc (int size, qboolean nobottom)
{
	return Cache_TryAlloc_C (size, nobottom);
}
#endif

/*
============
Cache_Flush

Throw everything out, so new data will be demand cached
============
*/
#if defined(BENCH486)
#define CACHE_FLUSH_C_ENTRY Cache_Flush_C
#else
#define CACHE_FLUSH_C_ENTRY Cache_Flush
#endif

#if !defined(ASM486_CACHE_FREE) || defined(BENCH486)
void CACHE_FLUSH_C_ENTRY (void)
{
	while (cache_head.next != &cache_head)
		Cache_Free ( cache_head.next->user );	// reclaim the space
}
#endif

#undef CACHE_FLUSH_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_CACHE_FREE)
void Cache_Flush (void)
{
	Cache_Flush_C ();
}
#endif


/*
============
Cache_Print

============
*/
void Cache_Print (void)
{
	cache_system_t	*cd;

	for (cd = cache_head.next ; cd != &cache_head ; cd = cd->next)
	{
		Con_Printf ("%8i : %s\n", cd->size, cd->name);
	}
}

/*
============
Cache_Report

============
*/
void Cache_Report (void)
{
	Con_DPrintf ("%4.1f megabyte data cache\n", (hunk_size - hunk_high_used - hunk_low_used) / (float)(1024*1024) );
}

/*
============
Cache_Compact

============
*/
void Cache_Compact (void)
{
}

/*
============
Cache_Init

============
*/
#if defined(BENCH486)
#define CACHE_INIT_C_ENTRY Cache_Init_C
#else
#define CACHE_INIT_C_ENTRY Cache_Init
#endif

#if !defined(ASM486_ZONE_HEAP) || defined(BENCH486)
void CACHE_INIT_C_ENTRY (void)
{
	cache_head.next = cache_head.prev = &cache_head;
	cache_head.lru_next = cache_head.lru_prev = &cache_head;

#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
	Bench486MemoryAddCommand ("flush", Cache_Flush);
#else
	Cmd_AddCommand ("flush", Cache_Flush);
#endif
}
#endif

#undef CACHE_INIT_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_ZONE_HEAP)
void Cache_Init (void)
{
	Cache_Init_C ();
}
#endif

/*
==============
Cache_Free

Frees the memory and removes it from the LRU list
==============
*/
#if defined(BENCH486)
#define CACHE_FREE_C_ENTRY Cache_Free_C
#else
#define CACHE_FREE_C_ENTRY Cache_Free
#endif

#if !defined(ASM486_CACHE_FREE) || defined(BENCH486)
void CACHE_FREE_C_ENTRY (cache_user_t *c)
{
	cache_system_t	*cs;

	if (!c->data)
		Sys_Error ("Cache_Free: not allocated");

	cs = ((cache_system_t *)c->data) - 1;
#ifdef PROFILE486
	bench486_cache_frees++;
#endif

	cs->prev->next = cs->next;
	cs->next->prev = cs->prev;
	cs->next = cs->prev = NULL;

	c->data = NULL;

	Cache_UnlinkLRU (cs);
}
#endif

#undef CACHE_FREE_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_CACHE_FREE)
void Cache_Free (cache_user_t *c)
{
	Cache_Free_C (c);
}
#endif



/*
==============
Cache_Check
==============
*/
#if defined(BENCH486)
#define CACHE_CHECK_C_ENTRY Cache_Check_C
#else
#define CACHE_CHECK_C_ENTRY Cache_Check
#endif

#if !defined(ASM486_CACHE_CHECK) || defined(BENCH486)
void *CACHE_CHECK_C_ENTRY (cache_user_t *c)
{
	cache_system_t	*cs;

#ifdef PROFILE486
	bench486_cache_checks++;
#endif
	if (!c->data)
	{
#ifdef PROFILE486
		bench486_cache_misses++;
#endif
		return NULL;
	}

	cs = ((cache_system_t *)c->data) - 1;

// move to head of LRU
	if (cs != cache_head.lru_next)
	{
#ifdef PROFILE486
		bench486_cache_lru_relinks++;
#endif
		Cache_UnlinkLRU (cs);
		Cache_MakeLRU (cs);
	}
#ifdef PROFILE486
	bench486_cache_hits++;
#endif
	
	return c->data;
}
#endif

#undef CACHE_CHECK_C_ENTRY

#if !defined(ASM486_CACHE_CHECK) && defined(BENCH486)
void *Cache_Check (cache_user_t *c)
{
	return Cache_Check_C (c);
}
#endif

#if defined(BENCH486) && defined(ASM486_CACHE_CHECK_FIXTURE)
#include "bench486_cachecheck.h"
#endif

#if defined(BENCH486) && defined(ASM486_CACHE_TRY_ALLOC_FIXTURE)
#include "bench486_cachetryalloc.h"
#endif

#if defined(BENCH486) && defined(ASM486_CACHE_FREE_FIXTURE)
#include "bench486_cachefree.h"
#endif


/*
==============
Cache_Alloc
==============
*/
#if defined(BENCH486)
#define CACHE_ALLOC_C_ENTRY Cache_Alloc_C
#else
#define CACHE_ALLOC_C_ENTRY Cache_Alloc
#endif

#if !defined(ASM486_CACHE_ALLOC) || defined(BENCH486)
void *CACHE_ALLOC_C_ENTRY (cache_user_t *c, int size, char *name)
{
	cache_system_t	*cs;

	if (c->data)
		Sys_Error ("Cache_Alloc: allready allocated");
	
	if (size <= 0)
		Sys_Error ("Cache_Alloc: size %i", size);

	size = (size + sizeof(cache_system_t) + 15) & ~15;

// find memory for it	
	while (1)
	{
		cs = Cache_TryAlloc (size, false);
		if (cs)
		{
#ifdef PROFILE486
			bench486_cache_allocations++;
#endif
			strncpy (cs->name, name, sizeof(cs->name)-1);
			c->data = (void *)(cs+1);
			cs->user = c;
			break;
		}
	
	// free the least recently used cahedat
		if (cache_head.lru_prev == &cache_head)
			Sys_Error ("Cache_Alloc: out of memory");
													// not enough memory at all
#ifdef PROFILE486
		bench486_cache_evictions++;
#endif
		Cache_Free ( cache_head.lru_prev->user );
	} 
	
	// Cache_TryAlloc already placed this new block at the LRU head.
	return c->data;
}
#endif

#undef CACHE_ALLOC_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_CACHE_ALLOC)
void *Cache_Alloc (cache_user_t *c, int size, char *name)
{
	return Cache_Alloc_C (c, size, name);
}
#endif

#if defined(BENCH486) && defined(ASM486_CACHE_ALLOC_FIXTURE)
#include "bench486_cachealloc.h"
#endif

//============================================================================


/*
========================
Memory_Init
========================
*/
#if defined(BENCH486)
#define MEMORY_INIT_C_ENTRY Memory_Init_C
#else
#define MEMORY_INIT_C_ENTRY Memory_Init
#endif

#if !defined(ASM486_ZONE_HEAP) || defined(BENCH486)
void MEMORY_INIT_C_ENTRY (void *buf, int size)
{
	int p;
	int zonesize = DYNAMIC_SIZE;

	hunk_base = buf;
	hunk_size = size;
	hunk_low_used = 0;
	hunk_high_used = 0;
	
	Cache_Init ();
	p = COM_CheckParm ("-zone");
	if (p)
	{
		if (p < com_argc-1)
			zonesize = Q_atoi (com_argv[p+1]) * 1024;
		else
			Sys_Error ("Memory_Init: you must specify a size in KB after -zone");
	}
	mainzone = Hunk_AllocName (zonesize, "zone" );
	Z_ClearZone (mainzone, zonesize);
}
#endif

#undef MEMORY_INIT_C_ENTRY

#if defined(BENCH486) && !defined(ASM486_ZONE_HEAP)
void Memory_Init (void *buf, int size)
{
	Memory_Init_C (buf, size);
}
#endif

#if defined(BENCH486) && defined(ASM486_HUNK_TEMP_ALLOC_FIXTURE)
#include "bench486_hunktempalloc.h"
#endif

#if defined(BENCH486) && defined(ASM486_HUNK_NAMED_ALLOC_FIXTURE)
#include "bench486_hunknamedalloc.h"
#endif

#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
#include "bench486_zoneheap.h"
#endif

