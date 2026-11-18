/* Hand-maintained argument-adapter layouts; shared C storage owns no algorithms. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_RENDERDISPATCH_H
#define ASM_RENDERDISPATCH_H
#define rd_desc_nump 0
#define rd_desc_vertices 4
#define rd_desc_frame 8
#define rd_frame_width 0
#define rd_frame_height 4
#define rd_frame_pixels 28
#define rd_ref_left 68
#define rd_ref_top 72
#define rd_ref_right 84
#define rd_ref_bottom 88
#define rd_entity_model 132
#define rd_model_edges 156
#define rd_model_nodes 164
#define rd_model_surfaces 180
#define rd_model_surfedges 188
#define rd_surface_firstedge 20
#define rd_client_time 572
#define rd_client_oldtime 580
#define rd_client_worldmodel 2692
#define rd_cvar_value 16
#ifndef __ASSEMBLER__
#include <stddef.h>
#define RD_LAYOUT(name,condition) typedef char rd_layout_##name[(condition) ? 1 : -1]
RD_LAYOUT(pointer32,sizeof(void *)==4);
RD_LAYOUT(integer32,sizeof(int)==4 && sizeof(long)==4);
RD_LAYOUT(float32,sizeof(float)==4);
RD_LAYOUT(double64,sizeof(double)==8);
RD_LAYOUT(desc_nump,offsetof(spritedesc_t,nump)==rd_desc_nump);
RD_LAYOUT(desc_vertices,offsetof(spritedesc_t,pverts)==rd_desc_vertices);
RD_LAYOUT(desc_frame,offsetof(spritedesc_t,pspriteframe)==rd_desc_frame);
RD_LAYOUT(frame_width,offsetof(mspriteframe_t,width)==rd_frame_width);
RD_LAYOUT(frame_height,offsetof(mspriteframe_t,height)==rd_frame_height);
RD_LAYOUT(frame_pixels,offsetof(mspriteframe_t,pixels)==rd_frame_pixels);
RD_LAYOUT(ref_left,offsetof(refdef_t,fvrectx_adj)==rd_ref_left);
RD_LAYOUT(ref_top,offsetof(refdef_t,fvrecty_adj)==rd_ref_top);
RD_LAYOUT(ref_right,offsetof(refdef_t,fvrectright_adj)==rd_ref_right);
RD_LAYOUT(ref_bottom,offsetof(refdef_t,fvrectbottom_adj)==rd_ref_bottom);
RD_LAYOUT(entity_model,offsetof(entity_t,model)==rd_entity_model);
RD_LAYOUT(model_edges,offsetof(model_t,edges)==rd_model_edges);
RD_LAYOUT(model_nodes,offsetof(model_t,nodes)==rd_model_nodes);
RD_LAYOUT(model_surfaces,offsetof(model_t,surfaces)==rd_model_surfaces);
RD_LAYOUT(model_surfedges,offsetof(model_t,surfedges)==rd_model_surfedges);
RD_LAYOUT(surface_firstedge,offsetof(msurface_t,firstedge)==rd_surface_firstedge);
RD_LAYOUT(client_time,offsetof(client_state_t,time)==rd_client_time);
RD_LAYOUT(client_oldtime,offsetof(client_state_t,oldtime)==rd_client_oldtime);
RD_LAYOUT(client_worldmodel,offsetof(client_state_t,worldmodel)==rd_client_worldmodel);
RD_LAYOUT(cvar_value,offsetof(cvar_t,value)==rd_cvar_value);
#undef RD_LAYOUT
#ifdef BENCH486
void D_SpriteScanLeftEdge(void);
void D_SpriteScanRightEdge(void);
void D_SpriteCalculateGradients(void);
struct sspan_s;
void Bench486DispatchSpriteLeft(struct sspan_s *,int,int,int,emitpoint_t *);
void Bench486DispatchSpriteRight(struct sspan_s *,int,int,int,emitpoint_t *,float,float,float,float);
void Bench486DispatchSpriteGradients(int);
void Bench486DispatchSpriteDraw(int,emitpoint_t *,int,int,byte *);
void Bench486DispatchAliasView(const float *,const float *,const float *,float *);
void Bench486DispatchMarkTree(dlight_t *,int,mnode_t *,msurface_t *);
void Bench486DispatchPushLights(double,int,dlight_t *,mnode_t *);
void Bench486DispatchRenderFace(msurface_t *,int,medge_t *,int *);
void Bench486DispatchFaceGradient(mplane_t *);
void Bench486DispatchBmodelGradient(mplane_t *);
void Bench486DispatchParticles(float,double,float
#ifdef PROFILE486
    ,unsigned long *,unsigned long *
#endif
    );
void Bench486DispatchStartParticles(void);
void Bench486DispatchEndParticles(void);
double Bench486DispatchFloatTime(void);
void R_MarkLights_asm486_Dispatch_C(dlight_t *,int,mnode_t *);
#endif
#endif
#endif
