/* 32-bit drawing storage contracts shared by C data and maintained assembly. */
#ifndef ASM_DRAWING_H
#define ASM_DRAWING_H
#ifndef __ASSEMBLER__
#include <stddef.h>
typedef struct {
	vrect_t	rect;
	int		width;
	int		height;
	byte	*ptexbytes;
	int		rowbytes;
} rectdesc_t;
typedef struct cachepic_s
{
	char		name[MAX_QPATH];
	cache_user_t	cache;
} cachepic_t;
#define MAX_CACHED_PICS 128
extern rectdesc_t r_rectdesc;
extern byte *draw_chars;
extern qpic_t *draw_disc,*draw_backtile;
extern cachepic_t menu_cachepics[MAX_CACHED_PICS];
extern int menu_numcachepics;
void Draw_DebugChar(char),Draw_CharToConback(int,byte *);
void R_DrawRect8(vrect_t *,int,byte *,int),R_DrawRect16(vrect_t *,int,byte *,int);
#ifdef BENCH486
extern unsigned (*bench486_drawing_probe)(unsigned,unsigned,const unsigned *);
void *Bench486DrawingLump(char *),*Bench486DrawingCacheCheck(cache_user_t *);
void Bench486DrawingLoad(char *,cache_user_t *),Bench486DrawingSwap(qpic_t *);
void Bench486DrawingBegin(int,int,byte *,int,int),Bench486DrawingEnd(int,int,int,int);
void Bench486DrawingUnlock(void),Bench486DrawingLock(void),Bench486DrawingSound(void);
void Bench486DrawingPointerCall(void);
extern unsigned bench486_drawing_pointer_result;
qpic_t	*Draw_PicFromWad_Drawing_C (char *name);
qpic_t	*Draw_CachePic_Drawing_C (char *path);
void Draw_Init_Drawing_C (void);
void Draw_Character_Drawing_C (int x, int y, int num);
void Draw_String_Drawing_C (int x, int y, char *str);
void Draw_DebugChar_Drawing_C (char num);
void Draw_Pic_Drawing_C (int x, int y, qpic_t *pic);
void Draw_TransPic_Drawing_C (int x, int y, qpic_t *pic);
void Draw_TransPicTranslate_Drawing_C (int x, int y, qpic_t *pic, byte *translation);
void Draw_CharToConback_Drawing_C (int num, byte *dest);
void Draw_ConsoleBackground_Drawing_C (int lines);
void R_DrawRect8_Drawing_C (vrect_t *prect, int rowbytes, byte *psrc,
	int transparent);
void R_DrawRect16_Drawing_C (vrect_t *prect, int rowbytes, byte *psrc,
	int transparent);
void Draw_TileClear_Drawing_C (int x, int y, int w, int h);
void Draw_Fill_Drawing_C (int x, int y, int w, int h, int c);
void Draw_FadeScreen_Drawing_C (void);
void Draw_BeginDisc_Drawing_C (void);
void Draw_EndDisc_Drawing_C (void);
#endif
typedef char drawing_pointer_size_must_match[(sizeof(void *)==4U)?1:-1];
typedef char drawing_int_size_must_match[(sizeof(int)==4U)?1:-1];
typedef char drawing_vrect_size_must_match[(sizeof(vrect_t)==20U)?1:-1];
typedef char drawing_vid_size_must_match[(sizeof(viddef_t)==68U)?1:-1];
typedef char drawing_rectdesc_size_must_match[(sizeof(rectdesc_t)==36U)?1:-1];
typedef char drawing_cachepic_size_must_match[(sizeof(cachepic_t)==68U)?1:-1];
typedef char drawing_cache_user_size_must_match[(sizeof(cache_user_t)==4U)?1:-1];
typedef char drawing_viddef_t_buffer_must_match[(offsetof(viddef_t,buffer)==0U)?1:-1];
typedef char drawing_viddef_t_rowbytes_must_match[(offsetof(viddef_t,rowbytes)==16U)?1:-1];
typedef char drawing_viddef_t_width_must_match[(offsetof(viddef_t,width)==20U)?1:-1];
typedef char drawing_viddef_t_height_must_match[(offsetof(viddef_t,height)==24U)?1:-1];
typedef char drawing_viddef_t_conbuffer_must_match[(offsetof(viddef_t,conbuffer)==40U)?1:-1];
typedef char drawing_viddef_t_conrowbytes_must_match[(offsetof(viddef_t,conrowbytes)==44U)?1:-1];
typedef char drawing_viddef_t_conwidth_must_match[(offsetof(viddef_t,conwidth)==48U)?1:-1];
typedef char drawing_viddef_t_conheight_must_match[(offsetof(viddef_t,conheight)==52U)?1:-1];
typedef char drawing_viddef_t_direct_must_match[(offsetof(viddef_t,direct)==64U)?1:-1];
typedef char drawing_vrect_t_x_must_match[(offsetof(vrect_t,x)==0U)?1:-1];
typedef char drawing_vrect_t_y_must_match[(offsetof(vrect_t,y)==4U)?1:-1];
typedef char drawing_vrect_t_width_must_match[(offsetof(vrect_t,width)==8U)?1:-1];
typedef char drawing_vrect_t_height_must_match[(offsetof(vrect_t,height)==12U)?1:-1];
typedef char drawing_vrect_t_pnext_must_match[(offsetof(vrect_t,pnext)==16U)?1:-1];
typedef char drawing_qpic_t_width_must_match[(offsetof(qpic_t,width)==0U)?1:-1];
typedef char drawing_qpic_t_height_must_match[(offsetof(qpic_t,height)==4U)?1:-1];
typedef char drawing_qpic_t_data_must_match[(offsetof(qpic_t,data)==8U)?1:-1];
typedef char drawing_rectdesc_t_rect_must_match[(offsetof(rectdesc_t,rect)==0U)?1:-1];
typedef char drawing_rectdesc_t_width_must_match[(offsetof(rectdesc_t,width)==20U)?1:-1];
typedef char drawing_rectdesc_t_height_must_match[(offsetof(rectdesc_t,height)==24U)?1:-1];
typedef char drawing_rectdesc_t_ptexbytes_must_match[(offsetof(rectdesc_t,ptexbytes)==28U)?1:-1];
typedef char drawing_rectdesc_t_rowbytes_must_match[(offsetof(rectdesc_t,rowbytes)==32U)?1:-1];
typedef char drawing_cachepic_t_name_must_match[(offsetof(cachepic_t,name)==0U)?1:-1];
typedef char drawing_cachepic_t_cache_must_match[(offsetof(cachepic_t,cache)==64U)?1:-1];
typedef char drawing_cache_user_t_data_must_match[(offsetof(cache_user_t,data)==0U)?1:-1];
#endif
#endif
