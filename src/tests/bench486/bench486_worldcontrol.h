/* Original C algorithms, real plane/frustum math, complete list/cache state and ABI. */
#include "renderer/asm_worldcontrol.h"
#ifdef ASM486_WORLD_CONTROL_FIXTURE
typedef struct {unsigned first[8];model_t data[2];unsigned last[8];} wc_models_t;
typedef struct {unsigned first[8];entity_t data[16];unsigned last[8];} wc_entities_t;
typedef struct {unsigned first[8];mnode_t data[64];unsigned last[8];} wc_nodes_t;
typedef struct {unsigned first[8];mplane_t data[64];unsigned last[8];} wc_planes_t;
typedef struct {unsigned first[8];mleaf_t data[64];unsigned last[8];} wc_leaves_t;
typedef struct {unsigned first[8];efrag_t data[256];unsigned last[8];} wc_fragments_t;
typedef struct {unsigned first[8];surf_t data[96];unsigned last[8];} wc_surfaces_t;
typedef struct {unsigned first[8];edge_t data[128];unsigned last[8];} wc_edges_t;
typedef struct {unsigned first[8];vec3_t data;unsigned last[8];} wc_vector_t;
static wc_models_t wc_models;static wc_entities_t wc_entities;
static wc_nodes_t wc_nodes;static wc_planes_t wc_planes;static wc_leaves_t wc_leaves;
static wc_fragments_t wc_fragments;static wc_surfaces_t wc_surfaces;static wc_edges_t wc_edges;
static wc_vector_t wc_vector;static msurface_t wc_faces[96];static espan_t wc_spans[96];
static unsigned wc_sequence_step,wc_cache_hits,wc_cache_misses,wc_tree_depth,wc_balanced;
typedef struct {unsigned phase,count,words[2];char text[32];} wc_event_t;
static struct {unsigned count,errors;wc_event_t events[128];} wc_trace;
static void WC_Observe(unsigned phase,unsigned count,const unsigned *words)
{
    wc_event_t *event;unsigned i;
    if(wc_trace.count==128 || count>2){wc_trace.errors++;return;}
    event=&wc_trace.events[wc_trace.count++];event->phase=phase;event->count=count;
    for(i=0;i<count;i++)event->words[i]=words[i];
    if(phase==1){Q_strncpy(event->text,(char *)words[0],31);event->words[0]=0;}
    if(phase==2 && ((msurface_t *)words[0]<wc_faces || (msurface_t *)words[0]>=wc_faces+96 || words[1]!=15))wc_trace.errors++;
}
typedef struct {
    client_state_t client;refdef_t reference;entity_t world_entity,*current;
    cvar_t draw_order;int frame,visframe,allocated,currentkey,backwards;
    vec3_t model_origin,forward,right,up,minimum,maximum;
    float rotation[3][3];clipplane_t frustum[4];mplane_t screen[4];
    mnode_t *topnode;entity_t *addentity;efrag_t **link;
    edge_t *edge_base,*edge_cursor,*edge_limit;
    surf_t *surface_base,*surface_cursor,*surface_limit;void (*span_function)(void);
    edge_t *new_edges[MAXHEIGHT],*remove_edges[MAXHEIGHT];
    entity_t *cache_entities[WORLD_BMODEL_CACHE_SLOTS];int cache_frames[WORLD_BMODEL_CACHE_SLOTS];
    float cache_rotations[WORLD_BMODEL_CACHE_SLOTS][3][3];
    wc_models_t models;wc_entities_t entities;wc_nodes_t nodes;wc_planes_t planes;
    wc_leaves_t leaves;wc_fragments_t fragments;wc_surfaces_t surfaces;wc_edges_t edges;wc_vector_t vector;
} wc_state_t;
static void WC_Save(wc_state_t *s)
{
    Q_memset(s,0,sizeof(*s));s->client=cl;s->reference=r_refdef;s->world_entity=cl_entities[0];
    s->current=currententity;s->draw_order=r_draworder;s->frame=r_framecount;s->visframe=r_visframecount;
    s->allocated=r_numallocatededges;s->currentkey=r_currentkey;s->backwards=r_worldpolysbacktofront;
    Q_memcpy(s->model_origin,modelorg,12);Q_memcpy(s->forward,vpn,12);Q_memcpy(s->right,vright,12);Q_memcpy(s->up,vup,12);
    Q_memcpy(s->minimum,r_emins,12);Q_memcpy(s->maximum,r_emaxs,12);Q_memcpy(s->rotation,entity_rotation,36);
    Q_memcpy(s->frustum,view_clipplanes,sizeof(s->frustum));Q_memcpy(s->screen,screenedge,sizeof(s->screen));
    s->topnode=r_pefragtopnode;s->addentity=r_addent;s->link=lastlink;
    s->edge_base=r_edges;s->edge_cursor=edge_p;s->edge_limit=edge_max;
    s->surface_base=surfaces;s->surface_cursor=surface_p;s->surface_limit=surf_max;s->span_function=pdrawfunc;
    Q_memcpy(s->new_edges,newedges,sizeof(s->new_edges));Q_memcpy(s->remove_edges,removeedges,sizeof(s->remove_edges));
    Q_memcpy(s->cache_entities,worldcontrol_cache_ent,sizeof(s->cache_entities));
    Q_memcpy(s->cache_frames,worldcontrol_cache_frame,sizeof(s->cache_frames));
    Q_memcpy(s->cache_rotations,worldcontrol_cache_rot,sizeof(s->cache_rotations));
    s->models=wc_models;s->entities=wc_entities;s->nodes=wc_nodes;s->planes=wc_planes;s->leaves=wc_leaves;
    s->fragments=wc_fragments;s->surfaces=wc_surfaces;s->edges=wc_edges;s->vector=wc_vector;
}
static void WC_Restore(const wc_state_t *s)
{
    cl=s->client;r_refdef=s->reference;cl_entities[0]=s->world_entity;currententity=s->current;
    r_draworder=s->draw_order;r_framecount=s->frame;r_visframecount=s->visframe;
    r_numallocatededges=s->allocated;r_currentkey=s->currentkey;r_worldpolysbacktofront=s->backwards;
    Q_memcpy(modelorg,(void *)s->model_origin,12);Q_memcpy(vpn,(void *)s->forward,12);Q_memcpy(vright,(void *)s->right,12);Q_memcpy(vup,(void *)s->up,12);
    Q_memcpy(r_emins,(void *)s->minimum,12);Q_memcpy(r_emaxs,(void *)s->maximum,12);Q_memcpy(entity_rotation,(void *)s->rotation,36);
    Q_memcpy(view_clipplanes,(void *)s->frustum,sizeof(s->frustum));Q_memcpy(screenedge,(void *)s->screen,sizeof(s->screen));
    r_pefragtopnode=s->topnode;r_addent=s->addentity;lastlink=s->link;
    r_edges=s->edge_base;edge_p=s->edge_cursor;edge_max=s->edge_limit;
    surfaces=s->surface_base;surface_p=s->surface_cursor;surf_max=s->surface_limit;pdrawfunc=s->span_function;
    Q_memcpy(newedges,(void *)s->new_edges,sizeof(s->new_edges));Q_memcpy(removeedges,(void *)s->remove_edges,sizeof(s->remove_edges));
    Q_memcpy(worldcontrol_cache_ent,(void *)s->cache_entities,sizeof(s->cache_entities));
    Q_memcpy(worldcontrol_cache_frame,(void *)s->cache_frames,sizeof(s->cache_frames));
    Q_memcpy(worldcontrol_cache_rot,(void *)s->cache_rotations,sizeof(s->cache_rotations));
    wc_models=s->models;wc_entities=s->entities;wc_nodes=s->nodes;wc_planes=s->planes;wc_leaves=s->leaves;
    wc_fragments=s->fragments;wc_surfaces=s->surfaces;wc_edges=s->edges;wc_vector=s->vector;
}
static unsigned WC_ReadOnly(void)
{
    unsigned hash=2166136261U,i;byte *p;
#define WC_HASH(obj) p=(byte *)&(obj);for(i=0;i<sizeof(obj);i++)hash=(hash^p[i])*16777619U
    WC_HASH(wc_models.data);WC_HASH(wc_planes.data);WC_HASH(wc_nodes.data);WC_HASH(wc_edges.data);
    WC_HASH(wc_faces);WC_HASH(wc_spans);
#undef WC_HASH
    return hash;
}
static int WC_Guards(void)
{
    unsigned i;for(i=0;i<8;i++){
#define WC_GUARD(obj) if(obj.first[i]!=0x5a5a5a5aU || obj.last[i]!=0xa5a5a5a5U)return 0
        WC_GUARD(wc_models);WC_GUARD(wc_entities);WC_GUARD(wc_nodes);WC_GUARD(wc_planes);WC_GUARD(wc_leaves);
        WC_GUARD(wc_fragments);WC_GUARD(wc_surfaces);WC_GUARD(wc_edges);WC_GUARD(wc_vector);
#undef WC_GUARD
    }return 1;
}
static void WC_Inputs(unsigned pattern,unsigned sequence,unsigned pair)
{
    static const float values[]={-1e20f,-8192,-32,-0.0f,0,0.03125f,4.999f,5,5.001f,32,8192,1e20f};
    entity_t *ent;unsigned i,j,count,axis,slot,entity_index,frame;
    Q_memset(wc_models.data,0,sizeof(wc_models.data));Q_memset(wc_entities.data,0,sizeof(wc_entities.data));
    Q_memset(wc_nodes.data,0,sizeof(wc_nodes.data));Q_memset(wc_planes.data,0,sizeof(wc_planes.data));
    Q_memset(wc_leaves.data,0,sizeof(wc_leaves.data));Q_memset(wc_fragments.data,0,sizeof(wc_fragments.data));
    Q_memset(wc_surfaces.data,0,sizeof(wc_surfaces.data));Q_memset(wc_edges.data,0,sizeof(wc_edges.data));
    Q_memset(wc_faces,0,sizeof(wc_faces));Q_memset(wc_spans,0,sizeof(wc_spans));
    entity_index=sequence?(wc_sequence_step/3)&15:pattern&15;ent=&wc_entities.data[entity_index];currententity=ent;
    frame=sequence?(wc_sequence_step/6<16?0xfffffff0U+wc_sequence_step/6:wc_sequence_step/6-16):pattern;
    Q_memcpy(&r_framecount,&frame,4);r_visframecount=pattern&31;
    for(i=0;i<16;i++)wc_entities.data[i].model=&wc_models.data[0];
    wc_models.data[1].nodes=wc_nodes.data;cl.worldmodel=&wc_models.data[1];
    cl_entities[0].model=&wc_models.data[1];
    for(i=0;i<3;i++){
        ent->angles[i]=((int)((pattern>>(i*5))%2881)-1440)*0.25f;
        ent->origin[i]=values[(pattern+i)%12];wc_vector.data[i]=values[(pattern+i+4)%12];
        modelorg[i]=values[(pattern+i+8)%12];vpn[i]=((int)((pattern>>(i*3))%65)-32)*0.03125f;
        vright[i]=((int)((pattern>>(i*4))%129)-64)*0.015625f;vup[i]=((int)((pattern>>(i*2))%33)-16)*0.0625f;
        wc_models.data[0].mins[i]=-32-i*0.125f;wc_models.data[0].maxs[i]=32+i*0.125f;
        r_emins[i]=(pattern&512)?ent->origin[i]-0.03125f:-32;
        r_emaxs[i]=(pattern&512)?ent->origin[i]+0.03125f:32;
        for(j=0;j<3;j++)entity_rotation[i][j]=((int)((pattern>>(i+j))%33)-16)*0.0625f;
    }
    for(i=0;i<4;i++)for(j=0;j<3;j++)screenedge[i].normal[j]=((int)((pattern>>(i+j))%17)-8)*0.125f;
    if(!sequence){
        Q_memset(worldcontrol_cache_ent,0,sizeof(worldcontrol_cache_ent));Q_memset(worldcontrol_cache_frame,0,sizeof(worldcontrol_cache_frame));
        Q_memset(worldcontrol_cache_rot,0,sizeof(worldcontrol_cache_rot));
        if(pattern&2){slot=((unsigned)ent>>5)&7;worldcontrol_cache_ent[slot]=ent;worldcontrol_cache_frame[slot]=r_framecount;
            for(i=0;i<3;i++)for(j=0;j<3;j++)worldcontrol_cache_rot[slot][i][j]=(i==j?0.5f:0.0625f);}
    }
    slot=((unsigned)ent>>5)&7;
    if(pair==2){if(worldcontrol_cache_ent[slot]==ent && worldcontrol_cache_frame[slot]==r_framecount)wc_cache_hits++;else wc_cache_misses++;}
    wc_balanced=(pattern>>8)&1;wc_tree_depth=wc_balanced?31:1+(pattern%32);
    for(i=0;i<64;i++){
        wc_leaves.data[i].contents=(pattern&(1U<<(i%16)))?CONTENTS_SOLID:((pattern&128)?CONTENTS_WATER:CONTENTS_EMPTY);
        wc_leaves.data[i].visframe=r_visframecount+((pattern>>(i%16))&1);
        wc_fragments.data[192+i].leaf=&wc_leaves.data[i];wc_fragments.data[192+i].entity=&wc_entities.data[(entity_index+1)&15];
        wc_leaves.data[i].efrags=&wc_fragments.data[192+i];
    }
    for(i=0;i<wc_tree_depth;i++){
        mplane_t *plane=&wc_planes.data[i];mnode_t *node=&wc_nodes.data[i];
        axis=(pattern+i)%4;plane->type=axis;plane->dist=((int)(pattern%129)-64)*0.03125f+i*0.125f;
        for(j=0;j<3;j++){plane->normal[j]=axis<3?(axis==j?1:0):(j==0?0.6f:j==1?-0.8f:0);if(plane->normal[j]<0)plane->signbits|=1U<<j;}
        node->plane=plane;node->visframe=r_visframecount+((pattern>>(i%16))&1);
        if(wc_balanced)for(j=0;j<2;j++)node->children[j]=2*i+j+1<31?&wc_nodes.data[2*i+j+1]:(mnode_t *)&wc_leaves.data[2*i+j+1-31];
        else {node->children[0]=i+1<wc_tree_depth?&wc_nodes.data[i+1]:(mnode_t *)&wc_leaves.data[wc_tree_depth];node->children[1]=(mnode_t *)&wc_leaves.data[i];}
    }
    count=pattern%65;cl.free_efrags=count?wc_fragments.data:NULL;
    for(i=0;i<count;i++)wc_fragments.data[i].entnext=i+1<count?&wc_fragments.data[i+1]:NULL;
    r_addent=ent;lastlink=&ent->efrag;r_pefragtopnode=(pattern&16)?&wc_nodes.data[1]:NULL;
    if(pair==3){
        count=pattern%33;ent->efrag=count?wc_fragments.data:NULL;
        cl.free_efrags=&wc_fragments.data[64];
        for(i=64;i<191;i++)wc_fragments.data[i].entnext=&wc_fragments.data[i+1];
        wc_fragments.data[191].entnext=NULL;
        for(i=0;i<count;i++){
            efrag_t *ef=&wc_fragments.data[i],*foreign=&wc_fragments.data[192+i];
            ef->entity=ent;ef->leaf=&wc_leaves.data[i];ef->entnext=i+1<count?&wc_fragments.data[i+1]:NULL;
            if((pattern+i)&1){foreign->leafnext=ef;wc_leaves.data[i].efrags=foreign;}
            else {ef->leafnext=foreign;wc_leaves.data[i].efrags=ef;}
        }
    }
    if(pair==6 && (pattern&64))ent->model=NULL;
    r_edges=wc_edges.data;r_numallocatededges=pattern%129;edge_p=r_edges+3;edge_max=r_edges+7;
    surfaces=wc_surfaces.data;surface_p=surfaces+1+(pattern%95);surf_max=surfaces+96;
    r_worldpolysbacktofront=pattern&1;r_draworder.value=(pattern&2)?1:-0.0f;r_currentkey=42;
    pdrawfunc=(pattern&4)?R_GenerateSpansBackward:R_GenerateSpans;
    for(i=0;i<96;i++){surfaces[i].data=&wc_faces[i];surfaces[i].spans=((pattern+i)&1)?&wc_spans[i]:NULL;
        surfaces[i].flags=((pattern>>(i%16))&1)?SURF_DRAWBACKGROUND:0;surfaces[i].key=i*7;}
    r_refdef.vrect.y=(pattern>>3)%(MAXHEIGHT+1);
    r_refdef.vrectbottom=r_refdef.vrect.y+(pattern%(MAXHEIGHT-r_refdef.vrect.y+1));
    for(i=0;i<MAXHEIGHT;i++){newedges[i]=&wc_edges.data[i%128];removeedges[i]=&wc_edges.data[(i+1)%128];}
}
typedef struct {const char *name;void (*reference)(void),(*assembly)(void);unsigned arguments;} wc_pair_t;
static const wc_pair_t wc_pairs[]={
 {"R_EntityRotate",(void (*)(void))R_EntityRotate_WorldControl_C,(void (*)(void))R_EntityRotate,1},
 {"R_RotateBmodel",R_RotateBmodel_WorldControl_C,R_RotateBmodel,0},
 {"R_RotateBmodelCached",R_RotateBmodelCached_WorldControl_C,R_RotateBmodelCached,0},
 {"R_RemoveEfrags",(void (*)(void))R_RemoveEfrags_WorldControl_C,(void (*)(void))R_RemoveEfrags,1},
 {"R_SplitEntityOnNode",(void (*)(void))R_SplitEntityOnNode_WorldControl_C,(void (*)(void))R_SplitEntityOnNode,1},
 {"R_SplitEntityOnNode2",(void (*)(void))R_SplitEntityOnNode2_WorldControl_C,(void (*)(void))R_SplitEntityOnNode2,1},
 {"R_AddEfrags",(void (*)(void))R_AddEfrags_WorldControl_C,(void (*)(void))R_AddEfrags,1},
 {"R_DrawCulledPolys",R_DrawCulledPolys_WorldControl_C,R_DrawCulledPolys,0},
 {"R_BeginEdgeFrame",R_BeginEdgeFrame_WorldControl_C,R_BeginEdgeFrame,0}};
static void WC_Step(unsigned pair,unsigned pattern,unsigned sequence)
{
    static wc_state_t initial,reference,assembly;static byte trace[sizeof(wc_trace)];
    unsigned arguments[1],c_abi,a_abi,hash,i;int failed;
    WC_Inputs(pattern,sequence,pair);WC_Save(&initial);hash=WC_ReadOnly();
    if(pair==0)arguments[0]=(unsigned)wc_vector.data;
    else if(pair==4 || pair==5)arguments[0]=(unsigned)wc_nodes.data;
    else arguments[0]=(unsigned)((pair==6 && (pattern&128))?&cl_entities[0]:currententity);
    Q_memset(&wc_trace,0,sizeof(wc_trace));
    c_abi=Bench486Call_asm486(wc_pairs[pair].reference,wc_pairs[pair].arguments,arguments,NULL);
    WC_Save(&reference);Q_memcpy(trace,&wc_trace,sizeof(wc_trace));
    failed=c_abi || !WC_Guards() || hash!=WC_ReadOnly() || wc_trace.errors;
    WC_Restore(&initial);Q_memset(&wc_trace,0,sizeof(wc_trace));
    a_abi=Bench486Call_asm486(wc_pairs[pair].assembly,wc_pairs[pair].arguments,arguments,NULL);
    WC_Save(&assembly);
    failed|=a_abi || !WC_Guards() || hash!=WC_ReadOnly() || wc_trace.errors ||
        Q_memcmp(&reference,&assembly,sizeof(reference)) || Q_memcmp(trace,&wc_trace,sizeof(wc_trace));
    if(failed){bench486_memory_failures++;
        if(bench486_memory_failures<32){for(i=0;i<sizeof(reference);i++)if(((byte *)&reference)[i]!=((byte *)&assembly)[i])break;
            Bench486Printf("world-control %s FAIL pattern %u ABI %x/%x state-byte %u trace %u/%u\n",
              wc_pairs[pair].name,pattern,c_abi,a_abi,i,((unsigned *)trace)[0],wc_trace.count);}}
}
static void Bench486WorldControlCases(void)
{
    static wc_state_t saved;unsigned short cw,control;
    static const unsigned modes[]={0x007f,0x047f,0x087f,0x0c7f,0x027f,0x067f,0x0a7f,0x0e7f,0x037f,0x077f,0x0b7f,0x0f7f};
    void (*probe)(unsigned,unsigned,const unsigned *);unsigned i,mode,step,pair,cases=0,negative=0,failures=bench486_memory_failures;
    WC_Save(&saved);probe=bench486_worldcontrol_probe;bench486_worldcontrol_probe=WC_Observe;
    wc_cache_hits=wc_cache_misses=0;
    for(i=0;i<8;i++){
#define WC_INIT(obj) obj.first[i]=0x5a5a5a5aU;obj.last[i]=0xa5a5a5a5U
        WC_INIT(wc_models);WC_INIT(wc_entities);WC_INIT(wc_nodes);WC_INIT(wc_planes);WC_INIT(wc_leaves);
        WC_INIT(wc_fragments);WC_INIT(wc_surfaces);WC_INIT(wc_edges);WC_INIT(wc_vector);
#undef WC_INIT
    }
    __asm__ __volatile__("fnstcw %0":"=m"(cw));
    for(mode=0;mode<12;mode++){
        Bench486Printf("world-control precision/rounding mode %u begin\n",mode);
        control=(cw&~0x0f00U)|(modes[mode]&0x0f00U);__asm__ __volatile__("fldcw %0"::"m"(control));
        for(step=0;step<32;step++)for(pair=0;pair<9;pair++){WC_Step(pair,step*0x1020305U+pair*0x486U,0);cases++;}
    }
    Bench486Printf("world-control continuous cache sequence begin\n");WC_Inputs(0,0,0);
    for(step=0;step<8192;step++){wc_sequence_step=step;WC_Step((step/4)%9,step*0x9e3779b9U,1);cases++;}
    __asm__ __volatile__("fldcw %0"::"m"(cw));
    for(i=0;i<8;i++){
#define WC_NEGATIVE(obj) obj.first[i]^=1;if(!WC_Guards())negative++;obj.first[i]^=1;obj.last[i]^=1;if(!WC_Guards())negative++;obj.last[i]^=1
        WC_NEGATIVE(wc_models);WC_NEGATIVE(wc_entities);WC_NEGATIVE(wc_nodes);WC_NEGATIVE(wc_planes);WC_NEGATIVE(wc_leaves);
        WC_NEGATIVE(wc_fragments);WC_NEGATIVE(wc_surfaces);WC_NEGATIVE(wc_edges);WC_NEGATIVE(wc_vector);
#undef WC_NEGATIVE
    }
    if(negative!=144 || !wc_cache_hits || !wc_cache_misses)bench486_memory_failures++;
    bench486_worldcontrol_probe=probe;WC_Restore(&saved);
    Bench486Printf("world control exact matrix/frustum/cache/BSP/efrag/list/edge-state/ABI %s (9 entries; %u cases; 12 control words; 8192 sequence calls; %u guard checks; %u cache hits; %u misses; %u failures)\n",
        failures==bench486_memory_failures?"PASS":"FAIL",cases,negative,wc_cache_hits,wc_cache_misses,bench486_memory_failures-failures);
}
#else
static void Bench486WorldControlCases(void)
{bench486_memory_failures++;Bench486Printf("world control fixture requires WorldControlImplementation=asm\n");}
#endif
