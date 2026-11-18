/* Benchmark-only drawing assembly adapters and C-oracle entry points. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_DRAWING_IFACE_H
#define BENCH486_DRAWING_IFACE_H

#include "common.h"
#include "draw.h"
#include "vid.h"
#include "zone.h"

#if defined(BENCH486) && defined(ASM486_DRAWING)
extern unsigned (*bench486_drawing_probe)(unsigned, unsigned, const unsigned *);
extern unsigned bench486_drawing_pointer_result;

void *Bench486DrawingLump (char *name);
void *Bench486DrawingCacheCheck (cache_user_t *cache);
void Bench486DrawingLoad (char *name, cache_user_t *cache);
void Bench486DrawingSwap (qpic_t *pic);
void Bench486DrawingBegin (int x, int y, byte *data, int width, int height);
void Bench486DrawingEnd (int x, int y, int width, int height);
void Bench486DrawingUnlock (void);
void Bench486DrawingLock (void);
void Bench486DrawingSound (void);
void Bench486DrawingPointerCall (void);

qpic_t *Draw_PicFromWad_Drawing_C (char *name);
qpic_t *Draw_CachePic_Drawing_C (char *path);
void Draw_Init_Drawing_C (void);
void Draw_Character_Drawing_C (int x, int y, int num);
void Draw_String_Drawing_C (int x, int y, char *str);
void Draw_DebugChar_Drawing_C (char num);
void Draw_Pic_Drawing_C (int x, int y, qpic_t *pic);
void Draw_TransPic_Drawing_C (int x, int y, qpic_t *pic);
void Draw_TransPicTranslate_Drawing_C (int x, int y, qpic_t *pic, byte *translation);
void Draw_CharToConback_Drawing_C (int num, byte *dest);
void Draw_ConsoleBackground_Drawing_C (int lines);
void R_DrawRect8_Drawing_C (vrect_t *prect, int rowbytes, byte *psrc, int transparent);
void R_DrawRect16_Drawing_C (vrect_t *prect, int rowbytes, byte *psrc, int transparent);
void Draw_TileClear_Drawing_C (int x, int y, int w, int h);
void Draw_Fill_Drawing_C (int x, int y, int w, int h, int c);
void Draw_FadeScreen_Drawing_C (void);
void Draw_BeginDisc_Drawing_C (void);
void Draw_EndDisc_Drawing_C (void);
#endif

#endif /* BENCH486_DRAWING_IFACE_H */
