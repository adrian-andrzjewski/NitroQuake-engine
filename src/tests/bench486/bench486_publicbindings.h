/* Verify actual public-entry machine bytes and the test-hook ABI.
   Backend algorithms have separate exact-result fixtures; a direct tail
   transfer must preserve their caller arguments, registers and return address.
*/
#include "tests/bench486/bench486_sprite_hooks.h"

#ifdef ASM486_PUBLIC_BINDINGS
#if defined(BENCH486) && defined(ASM486_RENDER_POLY)
#include "tests/bench486/bench486_renderpoly.h"
#endif
void D_CalcGradients (msurface_t *pface);
void D_CalcGradients_asm486 (msurface_t *pface);
void D_DrawSurfacesCalcGradients_asm486 (msurface_t *pface);
void D_PolysetCalcGradients (int skinwidth);
void D_PolysetCalcGradients_asm486 (int skinwidth);
void D_PolysetUpdateTables (void);
void D_PolysetUpdateTables_asm486 (void);
void D_PolysetSetUpForLineScan (fixed8_t startvertu, fixed8_t startvertv,
		fixed8_t endvertu, fixed8_t endvertv);
void D_PolysetSetUpForLineScan_asm486 (fixed8_t startvertu, fixed8_t startvertv,
		fixed8_t endvertu, fixed8_t endvertv);
void D_RasterizeAliasPolySmooth (void);
void D_RasterizeAliasPolySmooth_asm486 (void);
void D_PolysetSetEdgeTable (void);
void D_PolysetSetEdgeTable_asm486 (void);
int R_AliasClip (finalvert_t *in, finalvert_t *out, int flag, int count,
	void(*clip)(finalvert_t *pfv0, finalvert_t *pfv1, finalvert_t *out));
int R_AliasClip_asm486 (finalvert_t *in, finalvert_t *out, int flag, int count,
	void(*clip)(finalvert_t *pfv0, finalvert_t *pfv1, finalvert_t *out));
void R_AliasClipTriangle (mtriangle_t *ptri);
void R_AliasClipTriangle_asm486 (mtriangle_t *ptri);
void R_AliasTransformVector (vec3_t in, vec3_t out);
void R_AliasTransformVector_asm486 (vec3_t in, vec3_t out);
void R_AliasTransformFinalVert (finalvert_t *fv, auxvert_t *av,
	trivertx_t *pverts, stvert_t *pstverts);
void R_AliasTransformFinalVert_asm486 (finalvert_t *fv, auxvert_t *av,
	trivertx_t *pverts, stvert_t *pstverts);
void R_RecursiveClipBPoly (bedge_t *pedges, mnode_t *pnode,
		msurface_t *psurf);
void R_RecursiveClipBPoly_asm486 (bedge_t *pedges, mnode_t *pnode,
		msurface_t *psurf);
void R_DrawSolidClippedSubmodelPolygons (model_t *pmodel);
void R_DrawSolidClippedSubmodelPolygons_asm486 (model_t *pmodel);
void R_DrawSubmodelPolygons (model_t *pmodel, int clipflags);
void R_DrawSubmodelPolygons_asm486 (model_t *pmodel, int clipflags);
void __attribute__((regparm(2))) R_RecursiveWorldNode
	(mnode_t *node, int clipflags);
void __attribute__((regparm(2))) R_RecursiveWorldNode_asm486
	(mnode_t *node, int clipflags);
void R_RenderWorld (void);
void R_RenderWorld_asm486 (void);
void R_EmitCachedEdge (void);
void R_EmitCachedEdge_asm486 (void);
void R_RenderBmodelFace (bedge_t *pedges, msurface_t *psurf);
void R_RenderBmodelFace_asm486 (bedge_t *pedges, msurface_t *psurf);
void R_RenderPoly (msurface_t *fa, int clipflags);
void R_RenderPoly_asm486 (msurface_t *fa, int clipflags);
void R_ZDrawSubmodelPolys (model_t *pmodel);
void R_ZDrawSubmodelPolys_asm486 (model_t *pmodel);
void R_GenerateSpansBackward (void);
void R_GenerateSpansBackward_asm486 (void);
void R_InsertNewEdges (edge_t *edgestoadd, edge_t *edgelist);
void R_InsertNewEdges_asm486 (edge_t *edgestoadd, edge_t *edgelist);
void R_RemoveEdges (edge_t *pedge);
void R_RemoveEdges_asm486 (edge_t *pedge);
void R_StepActiveU (edge_t *pedge);
void R_StepActiveU_asm486 (edge_t *pedge);
void R_CleanupSpan (void);
void R_CleanupSpan_asm486 (void);
void R_LeadingEdgeBackwards (edge_t *edge);
void R_LeadingEdgeBackwards_asm486 (edge_t *edge);
void R_TrailingEdge (surf_t *surf, edge_t *edge);
void R_TrailingEdge_asm486 (surf_t *surf, edge_t *edge);
void R_ScanEdges (void);
void R_ScanEdges_asm486 (void);
void R_StoreEfrags (efrag_t **ppefrag);
void R_StoreEfrags_asm486 (efrag_t **ppefrag);
void R_RotateSprite (float beamlength);
void R_RotateSprite_asm486 (float beamlength);
int R_ClipSpriteFace (int nump, clipplane_t *pclipplane);
int R_ClipSpriteFace_asm486 (int nump, clipplane_t *pclipplane);
void R_SetupAndDrawSprite (void);
texture_t *R_TextureAnimation (texture_t *base);
texture_t *R_TextureAnimation_asm486 (texture_t *base);
typedef struct { void (*entry)(void); void (*target)(void); } bench486_binding_pair_t;
/* This writable pointer array belongs to .data, never an instruction exemption. */
static bench486_binding_pair_t bench486_binding_pairs[] = {
    { NULL, NULL }, /* A sentinel also permits an empty selected subset. */
#ifdef ASM486_SURFACE_GRADIENTS
    { (void (*)(void))D_CalcGradients, (void (*)(void))D_CalcGradients_asm486 },
#endif
#ifdef ASM486_SURFACE_DISPATCH
#ifdef ASM486_SURFACE_GRADIENTS
    { (void (*)(void))D_DrawSurfacesCalcGradients_asm486, (void (*)(void))D_CalcGradients },
#else
    { (void (*)(void))D_DrawSurfacesCalcGradients_asm486, (void (*)(void))D_CalcGradients_C },
#endif
#endif
#ifdef ASM486_ALIAS_GRADIENTS
    { (void (*)(void))D_PolysetCalcGradients, (void (*)(void))D_PolysetCalcGradients_asm486 },
#endif
#ifdef ASM486_ALIAS_SKIN_TABLE
    { (void (*)(void))D_PolysetUpdateTables, (void (*)(void))D_PolysetUpdateTables_asm486 },
#endif
#if defined(ASM486_ALIAS_LINE_SCAN) && !defined(PROFILE486)
    { (void (*)(void))D_PolysetSetUpForLineScan, (void (*)(void))D_PolysetSetUpForLineScan_asm486 },
#endif
#if defined(ASM486_ALIAS_RASTERIZE) && !defined(PROFILE486)
    { (void (*)(void))D_RasterizeAliasPolySmooth, (void (*)(void))D_RasterizeAliasPolySmooth_asm486 },
#endif
#ifdef ASM486_ALIAS_EDGE_TABLE
    { (void (*)(void))D_PolysetSetEdgeTable, (void (*)(void))D_PolysetSetEdgeTable_asm486 },
#endif
#ifdef ASM486_ALIAS_CLIP
    { (void (*)(void))R_AliasClip, (void (*)(void))R_AliasClip_asm486 },
#endif
#ifdef ASM486_ALIAS_CLIP
    { (void (*)(void))R_AliasClipTriangle, (void (*)(void))R_AliasClipTriangle_asm486 },
#endif
#ifdef ASM486_ALIAS_BBOX_PROJECT
    { (void (*)(void))R_AliasTransformVector, (void (*)(void))R_AliasTransformVector_asm486 },
#endif
#ifdef ASM486_ALIAS_TRANSFORM_FINAL
    { (void (*)(void))R_AliasTransformFinalVert, (void (*)(void))R_AliasTransformFinalVert_asm486 },
#endif
#ifdef ASM486_BMODEL_POLYGON_CLIP
    { (void (*)(void))R_RecursiveClipBPoly, (void (*)(void))R_RecursiveClipBPoly_asm486 },
#endif
#ifdef ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS
    { (void (*)(void))R_DrawSolidClippedSubmodelPolygons, (void (*)(void))R_DrawSolidClippedSubmodelPolygons_asm486 },
#endif
#ifdef ASM486_DRAW_SUBMODEL_POLYGONS
    { (void (*)(void))R_DrawSubmodelPolygons, (void (*)(void))R_DrawSubmodelPolygons_asm486 },
#endif
#ifdef ASM486_BSP_WALK
    { (void (*)(void))R_RecursiveWorldNode, (void (*)(void))R_RecursiveWorldNode_asm486 },
#endif
#ifdef ASM486_RENDER_WORLD
    { (void (*)(void))R_RenderWorld, (void (*)(void))R_RenderWorld_asm486 },
#endif
#ifdef ASM486_EMIT_CACHED_EDGE
    { (void (*)(void))R_EmitCachedEdge, (void (*)(void))R_EmitCachedEdge_asm486 },
#endif
#ifdef ASM486_RENDER_BMODEL_FACE
    { (void (*)(void))R_RenderBmodelFace, (void (*)(void))R_RenderBmodelFace_asm486 },
#endif
#ifdef ASM486_RENDER_POLY
    { (void (*)(void))R_RenderPoly, (void (*)(void))R_RenderPoly_asm486 },
#endif
#ifdef ASM486_DRAW_Z_SUBMODEL_POLYS
    { (void (*)(void))R_ZDrawSubmodelPolys, (void (*)(void))R_ZDrawSubmodelPolys_asm486 },
#endif
#ifdef ASM486_BACKWARD_SPANS
    { (void (*)(void))R_GenerateSpansBackward, (void (*)(void))R_GenerateSpansBackward_asm486 },
#endif
#ifdef ASM486_EDGE_LIST
    { (void (*)(void))R_InsertNewEdges, (void (*)(void))R_InsertNewEdges_asm486 },
#endif
#ifdef ASM486_EDGE_LIST
    { (void (*)(void))R_RemoveEdges, (void (*)(void))R_RemoveEdges_asm486 },
#endif
#ifdef ASM486_EDGE_LIST
    { (void (*)(void))R_StepActiveU, (void (*)(void))R_StepActiveU_asm486 },
#endif
#ifdef ASM486_BACKWARD_SPANS
    { (void (*)(void))R_CleanupSpan, (void (*)(void))R_CleanupSpan_asm486 },
#endif
#ifdef ASM486_BACKWARD_SPANS
    { (void (*)(void))R_LeadingEdgeBackwards, (void (*)(void))R_LeadingEdgeBackwards_asm486 },
#endif
#ifdef ASM486_BACKWARD_SPANS
    { (void (*)(void))R_TrailingEdge, (void (*)(void))R_TrailingEdge_asm486 },
#endif
#ifdef ASM486_SCAN_EDGES
    { (void (*)(void))R_ScanEdges, (void (*)(void))R_ScanEdges_asm486 },
#endif
#ifdef ASM486_EFRAG_STORE
    { (void (*)(void))R_StoreEfrags, (void (*)(void))R_StoreEfrags_asm486 },
#endif
#ifdef ASM486_SPRITE_BEAM
    { (void (*)(void))R_RotateSprite, (void (*)(void))R_RotateSprite_asm486 },
#endif
#ifdef ASM486_SPRITE_CLIP
    { (void (*)(void))R_ClipSpriteFace, (void (*)(void))R_ClipSpriteFace_asm486 },
#endif
#ifdef ASM486_TEXTURE_ANIMATION
    { (void (*)(void))R_TextureAnimation, (void (*)(void))R_TextureAnimation_asm486 },
#endif
};
static struct {
    unsigned before[8];
    unsigned calls;
    unsigned after[8];
} bench486_binding_hook_state;
static void Bench486BindingHook (void)
{
    bench486_binding_hook_state.calls++;
}
#if defined(PROFILE486) && defined(ASM486_ALIAS_LINE_SCAN)
static void Bench486PublicLineProfileCases(void)
{
    static const unsigned modes[12]={0x007f,0x047f,0x087f,0x0c7f,
        0x027f,0x067f,0x0a7f,0x0e7f,0x037f,0x077f,0x0b7f,0x0f7f};
    unsigned short saved_cw,control;
    unsigned saved_count,expected,args[4],abi,cases,mode,step,failures;
    int saved_active,saved_base,saved_up,saved_down,saved_error;
    int reference_base,reference_up,reference_down,reference_error;
    saved_count=bench486_line_setup_calls;saved_active=bench486_profile_frame_active;
    saved_base=ubasestep;saved_up=erroradjustup;saved_down=erroradjustdown;saved_error=errorterm;
    __asm__ __volatile__("fnstcw %0" : "=m"(saved_cw));
    failures=cases=0;bench486_line_setup_calls=expected=0xffffffc0U;
    for(mode=0;mode<12;mode++)
    {
        control=(saved_cw&~0x0f00U)|(modes[mode]&0x0f00U);
        __asm__ __volatile__("fldcw %0" : : "m"(control));
        for(step=0;step<512;step++)
        {
            args[0]=100;args[1]=-700;args[2]=(step&1)?0xffffff80U:33000U;
            args[3]=(step&1)?0xfffffd55U:26300U;
            abi=Bench486Call_asm486((void(*)(void))D_PolysetSetUpForLineScan_C,4,args,NULL);
            reference_base=ubasestep;reference_up=erroradjustup;
            reference_down=erroradjustdown;reference_error=errorterm;
            bench486_profile_frame_active=(step%3) ? ((step&1)?1:-1) : 0;
            if(bench486_profile_frame_active) expected++;
            abi|=Bench486Call_asm486((void(*)(void))D_PolysetSetUpForLineScan,4,args,NULL);
            cases++;
            if(abi || expected!=bench486_line_setup_calls || reference_base!=ubasestep ||
               reference_up!=erroradjustup || reference_down!=erroradjustdown || reference_error!=errorterm)
                failures++;
        }
    }
    __asm__ __volatile__("fldcw %0" : : "m"(saved_cw));
    bench486_line_setup_calls=saved_count;bench486_profile_frame_active=saved_active;
    ubasestep=saved_base;erroradjustup=saved_up;erroradjustdown=saved_down;errorterm=saved_error;
    bench486_memory_failures+=failures;
    Bench486Printf("public-bindings profile line results/counter/inactive/wrap/ABI %s (%u cases; 12 control words; %u failures)\n",
        failures?"FAIL":"PASS",cases,failures);
}
#endif
static void Bench486PublicBindingsCases (void)
{
    static const unsigned modes[12] = {
        0x007f,0x047f,0x087f,0x0c7f,
        0x027f,0x067f,0x0a7f,0x0e7f,
        0x037f,0x077f,0x0b7f,0x0f7f
    };
    void (*saved_hook)(void);
    spritedesc_t saved_desc;
    unsigned short saved_cw,control;
    unsigned abi,expected;
    int i,mode,step,failed,pairs;
    byte *bytes,*destination;

    failed=0;
    pairs=sizeof(bench486_binding_pairs)/sizeof(bench486_binding_pairs[0]);
    for (i=1;i<pairs;i++)
    {
        bytes=(byte *)bench486_binding_pairs[i].entry;
        destination=NULL;
        if (bytes[0]==0xe9)
            destination=(byte *)((unsigned)bytes+5U+(unsigned)*(int *)(bytes+1));
        else if (bytes[0]==0xeb)
            destination=(byte *)((unsigned)bytes+2U+(unsigned)(int)(signed char)bytes[1]);
        if (destination!=(byte *)bench486_binding_pairs[i].target)
        {
            failed++;Bench486Printf("public-bindings transfer FAIL entry %d opcode %02x\n",i,bytes[0]);
        }
    }
    saved_hook=bench486_sprite_setup_hook;
    saved_desc=r_spritedesc;
    __asm__ __volatile__("fnstcw %0" : "=m"(saved_cw));
    Q_memset(&bench486_binding_hook_state,0xa5,sizeof(bench486_binding_hook_state));
    bench486_binding_hook_state.calls=0xffffffc0U;
    bench486_sprite_setup_hook=Bench486BindingHook;
    expected=bench486_binding_hook_state.calls;
    for (mode=0;mode<12;mode++)
    {
        control=(saved_cw & ~0x0f00U) | (modes[mode] & 0x0f00U);
        __asm__ __volatile__("fldcw %0" : : "m"(control));
        for (step=0;step<512;step++)
        {
            abi=Bench486Call_asm486((void (*)(void))R_SetupAndDrawSprite,0,NULL,NULL);
            expected++;
            if (abi || bench486_binding_hook_state.calls!=expected ||
                Q_memcmp(&saved_desc,&r_spritedesc,sizeof(saved_desc)))
            {
                failed++;Bench486Printf("public-bindings hook FAIL mode %d step %d ABI %x\n",mode,step,abi);
                break;
            }
        }
    }
    __asm__ __volatile__("fldcw %0" : : "m"(saved_cw));
    bench486_sprite_setup_hook=saved_hook;
    r_spritedesc=saved_desc;
    for (i=0;i<8;i++)
        if (bench486_binding_hook_state.before[i]!=0xa5a5a5a5U ||
            bench486_binding_hook_state.after[i]!=0xa5a5a5a5U) failed++;
    bench486_memory_failures+=failed;
    Bench486Printf("public-bindings exact targets/hook/ABI/guards %s (%d tail entries; 6144 hook calls; %d failures)\n",
                   failed ? "FAIL":"PASS",pairs-1,failed);
#if defined(PROFILE486) && defined(ASM486_ALIAS_LINE_SCAN)
    Bench486PublicLineProfileCases();
#endif
#if defined(BENCH486) && defined(ASM486_RENDER_POLY)
#ifdef ASM486_DRAWING_DRIVER
    Bench486Printf("render-poly direct C/ASM fixture SKIP (assembly D_DrawPoly has no capture hook)\n");
#else
    Bench486RenderPolyCases();
#endif
#endif
}
#endif
