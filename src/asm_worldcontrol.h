/* World-control storage contracts and independent original-C boundaries. */
#ifndef ASM_WORLDCONTROL_H
#define ASM_WORLDCONTROL_H
#define WORLD_BMODEL_CACHE_SLOTS 8
#ifndef __ASSEMBLER__
#include <stddef.h>
extern entity_t *worldcontrol_cache_ent[WORLD_BMODEL_CACHE_SLOTS];
extern int worldcontrol_cache_frame[WORLD_BMODEL_CACHE_SLOTS];
extern float worldcontrol_cache_rot[WORLD_BMODEL_CACHE_SLOTS][3][3];
#if defined(ASM486_SCAN_EDGES) || defined(ASM486_WORLD_EDGE_FRAME)
extern void (*pdrawfunc)(void);
#endif
extern efrag_t **lastlink;
extern entity_t *r_addent;
extern vec3_t r_emins,r_emaxs;
extern mnode_t *r_pefragtopnode;
void R_EntityRotate(vec3_t),R_RotateBmodel(void),R_RotateBmodelCached(void);
void R_SplitEntityOnNode(mnode_t *),R_SplitEntityOnNode2(mnode_t *);
void R_DrawCulledPolys(void),R_BeginEdgeFrame(void);
void R_GenerateSpans(void);
#if defined(BENCH486) && defined(ASM486_WORLD_CONTROL_FIXTURE)
extern void (*bench486_worldcontrol_probe)(unsigned,unsigned,const unsigned *);
void Bench486WorldControlPrint(char *,...);
void Bench486WorldControlPoly(msurface_t *,int),Bench486WorldControlFrustum(void);
void R_EntityRotate_WorldControl_C (vec3_t vec);
void R_RotateBmodel_WorldControl_C (void);
void R_RotateBmodelCached_WorldControl_C (void);
void R_RemoveEfrags_WorldControl_C (entity_t *ent);
void R_SplitEntityOnNode_WorldControl_C (mnode_t *node);
void R_SplitEntityOnNode2_WorldControl_C (mnode_t *node);
void R_AddEfrags_WorldControl_C (entity_t *ent);
void R_DrawCulledPolys_WorldControl_C (void);
void R_BeginEdgeFrame_WorldControl_C (void);
#endif
typedef char wc_pointer_size_must_match[(sizeof(void *)==4U)?1:-1];
typedef char wc_float_size_must_match[(sizeof(float)==4U)?1:-1];
typedef char wc_integer_size_must_match[(sizeof(int)==4U)?1:-1];
typedef char wc_entity_t_size_must_match[(sizeof(entity_t)==180U)?1:-1];
typedef char wc_entity_t_model_must_match[(offsetof(entity_t,model)==132U)?1:-1];
typedef char wc_entity_t_efrag_must_match[(offsetof(entity_t,efrag)==136U)?1:-1];
typedef char wc_entity_t_topnode_must_match[(offsetof(entity_t,topnode)==176U)?1:-1];
typedef char wc_entity_t_angles_must_match[(offsetof(entity_t,angles)==120U)?1:-1];
typedef char wc_entity_t_origin_must_match[(offsetof(entity_t,origin)==84U)?1:-1];
typedef char wc_model_t_size_must_match[(sizeof(model_t)==392U)?1:-1];
typedef char wc_model_t_mins_must_match[(offsetof(model_t,mins)==84U)?1:-1];
typedef char wc_model_t_maxs_must_match[(offsetof(model_t,maxs)==96U)?1:-1];
typedef char wc_model_t_nodes_must_match[(offsetof(model_t,nodes)==164U)?1:-1];
typedef char wc_mnode_t_size_must_match[(sizeof(mnode_t)==40U)?1:-1];
typedef char wc_mnode_t_contents_must_match[(offsetof(mnode_t,contents)==0U)?1:-1];
typedef char wc_mnode_t_visframe_must_match[(offsetof(mnode_t,visframe)==4U)?1:-1];
typedef char wc_mnode_t_plane_must_match[(offsetof(mnode_t,plane)==24U)?1:-1];
typedef char wc_mnode_t_children_must_match[(offsetof(mnode_t,children)==28U)?1:-1];
typedef char wc_mleaf_t_size_must_match[(sizeof(mleaf_t)==48U)?1:-1];
typedef char wc_mleaf_t_contents_must_match[(offsetof(mleaf_t,contents)==0U)?1:-1];
typedef char wc_mleaf_t_visframe_must_match[(offsetof(mleaf_t,visframe)==4U)?1:-1];
typedef char wc_mleaf_t_efrags_must_match[(offsetof(mleaf_t,efrags)==28U)?1:-1];
typedef char wc_mplane_t_size_must_match[(sizeof(mplane_t)==20U)?1:-1];
typedef char wc_mplane_t_normal_must_match[(offsetof(mplane_t,normal)==0U)?1:-1];
typedef char wc_mplane_t_dist_must_match[(offsetof(mplane_t,dist)==12U)?1:-1];
typedef char wc_mplane_t_type_must_match[(offsetof(mplane_t,type)==16U)?1:-1];
typedef char wc_mplane_t_signbits_must_match[(offsetof(mplane_t,signbits)==17U)?1:-1];
typedef char wc_efrag_t_size_must_match[(sizeof(efrag_t)==16U)?1:-1];
typedef char wc_efrag_t_leaf_must_match[(offsetof(efrag_t,leaf)==0U)?1:-1];
typedef char wc_efrag_t_leafnext_must_match[(offsetof(efrag_t,leafnext)==4U)?1:-1];
typedef char wc_efrag_t_entity_must_match[(offsetof(efrag_t,entity)==8U)?1:-1];
typedef char wc_efrag_t_entnext_must_match[(offsetof(efrag_t,entnext)==12U)?1:-1];
typedef char wc_client_state_t_size_must_match[(sizeof(client_state_t)==2900U)?1:-1];
typedef char wc_client_state_t_worldmodel_must_match[(offsetof(client_state_t,worldmodel)==2692U)?1:-1];
typedef char wc_client_state_t_free_efrags_must_match[(offsetof(client_state_t,free_efrags)==2696U)?1:-1];
typedef char wc_refdef_t_size_must_match[(sizeof(refdef_t)==148U)?1:-1];
typedef char wc_refdef_t_vrect_must_match[(offsetof(refdef_t,vrect)==0U)?1:-1];
typedef char wc_refdef_t_vrectbottom_must_match[(offsetof(refdef_t,vrectbottom)==44U)?1:-1];
typedef char wc_vrect_t_size_must_match[(sizeof(vrect_t)==20U)?1:-1];
typedef char wc_vrect_t_y_must_match[(offsetof(vrect_t,y)==4U)?1:-1];
typedef char wc_surf_t_size_must_match[(sizeof(surf_t)==64U)?1:-1];
typedef char wc_surf_t_spans_must_match[(offsetof(surf_t,spans)==8U)?1:-1];
typedef char wc_surf_t_flags_must_match[(offsetof(surf_t,flags)==24U)?1:-1];
typedef char wc_surf_t_key_must_match[(offsetof(surf_t,key)==12U)?1:-1];
typedef char wc_surf_t_data_must_match[(offsetof(surf_t,data)==28U)?1:-1];
typedef char wc_edge_t_size_must_match[(sizeof(edge_t)==32U)?1:-1];
typedef char wc_edge_t_u_must_match[(offsetof(edge_t,u)==0U)?1:-1];
typedef char wc_cvar_t_size_must_match[(sizeof(cvar_t)==24U)?1:-1];
typedef char wc_cvar_t_value_must_match[(offsetof(cvar_t,value)==16U)?1:-1];
typedef char wc_clipplane_t_size_must_match[(sizeof(clipplane_t)==24U)?1:-1];
typedef char wc_clipplane_t_normal_must_match[(offsetof(clipplane_t,normal)==0U)?1:-1];
typedef char wc_clipplane_t_dist_must_match[(offsetof(clipplane_t,dist)==12U)?1:-1];
typedef char wc_MAXHEIGHT_must_match[(MAXHEIGHT==1024U)?1:-1];
typedef char wc_CONTENTS_SOLID_must_match[(CONTENTS_SOLID==4294967294U)?1:-1];
typedef char wc_SURF_DRAWBACKGROUND_must_match[(SURF_DRAWBACKGROUND==64U)?1:-1];
#endif
#endif
