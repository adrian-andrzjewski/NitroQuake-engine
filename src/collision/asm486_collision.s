// asm486_collision.s
// i486 collision and movement helpers.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

.text

#if defined(ASM486_CHASE) || defined(ASM486_HULLCHECK)
#include "collision/sv_hullcheck_asm.inc"
#endif

#if defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
#include "collision/sv_hullforentity_asm.inc"
#endif

#if defined(ASM486_CLIP_MOVE_TO_ENTITY) && !defined(QUAKE2)
#include "collision/sv_clipmovetoentity_asm.inc"
#endif

#if defined(ASM486_CLIP_TO_LINKS) && !defined(QUAKE2)
#include "collision/sv_cliptolinks_asm.inc"
#endif

#if defined(ASM486_FIND_TOUCHED_LEAFS) && !defined(QUAKE2)
#include "collision/sv_findtouchedleafs_asm.inc"
#endif
