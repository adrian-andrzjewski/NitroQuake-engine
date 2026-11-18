/* Exact original drawing-driver state, argument order, x87 and cdecl fixtures. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifdef ASM486_DRAWING_DRIVER
extern void (*bench486_driver_probe)(unsigned,unsigned,const unsigned *);
extern cvar_t d_mipcap,d_mipscale;
extern int d_aflatcolor;
extern void (*d_drawspans)(espan_t *);
extern void D_CopyRects(vrect_t *,int);
extern void D_Init_Driver_C(void),D_EnableBackBufferAccess_Driver_C(void);
extern void D_DisableBackBufferAccess_Driver_C(void),D_TurnZOn_Driver_C(void);
extern void D_SetupFrame_Driver_C(void),D_ViewChanged_Driver_C(void);
extern void D_StartParticles_Driver_C(void),D_EndParticles_Driver_C(void);
extern void D_FlushCaches_Driver_C(void),D_DrawPoly_Driver_C(void);
extern void D_CopyRects_Driver_C(vrect_t *,int),D_UpdateRects_Driver_C(vrect_t *);

typedef struct {unsigned phase,count,words[2],flags[6];} bench486_driver_event_t;
typedef struct {unsigned count,errors;bench486_driver_event_t event[4];} bench486_driver_trace_t;
static bench486_driver_trace_t bench486_driver_trace;
static void Bench486DriverObserve(unsigned phase,unsigned count,const unsigned *words)
{
    bench486_driver_event_t *e;unsigned i;
    if(bench486_driver_trace.count>=4 || count>2){bench486_driver_trace.errors++;return;}
    e=&bench486_driver_trace.event[bench486_driver_trace.count++];e->phase=phase;e->count=count;
    for(i=0;i<count;i++)e->words[i]=words[i];
    e->flags[0]=r_skydirect;e->flags[1]=r_drawpolys;e->flags[2]=r_worldpolysbacktofront;
    e->flags[3]=r_recursiveaffinetriangles;e->flags[4]=r_pixbytes;
    Q_memcpy(e->flags+5,&r_aliasuvscale,4);
}
void Bench486DriverRegister(cvar_t *v)
{unsigned word=(unsigned)v;Bench486DriverObserve(1,1,&word);}
void Bench486DriverMakeWritable(int address,int bytes)
{unsigned words[2];words[0]=address;words[1]=bytes;Bench486DriverObserve(2,2,words);}

static struct {unsigned before[8];surfcache_t nodes[128];surfcache_t *owners[128];unsigned after[8];}
    bench486_driver_cache;
static struct {unsigned before[8];byte data[640*MAXHEIGHT];unsigned after[8];}
    bench486_driver_video,bench486_driver_warp;
static struct {unsigned before[8];short data[640*MAXHEIGHT];unsigned after[8];}
    bench486_driver_depth;
typedef struct {
    viddef_t video;refdef_t ref;
    byte *warp,*view,*row_base;short *depth;
    surfcache_t *base,*rover,*initial;
    void (*spans)(espan_t *);
    int warp_on,width,zwidth,zbytes,minimum,flat,wrapped,size,row_stride,protected8;
    int pix_min,pix_max,pix_shift,aspect_shift,left,top,right,bottom;
    int sky,polys,back,recursive,pixbytes;
    float aliasuv,mipcap,mipscale,subdiv,scalemip[3],mip,x,y,aspect;
    int rows[MAXHEIGHT];short *zrows[MAXHEIGHT];pixel_t *viewrows[MAXHEIGHT];
    byte cache[sizeof(bench486_driver_cache)];
} bench486_driver_state_t;
static void Bench486DriverSave(bench486_driver_state_t *s)
{
    Q_memset(s,0,sizeof(*s));Q_memcpy(&s->video,&vid,sizeof(vid));Q_memcpy(&s->ref,&r_refdef,sizeof(r_refdef));
    s->warp=r_warpbuffer;s->view=d_viewbuffer;s->depth=d_pzbuffer;s->warp_on=r_dowarp;
    s->row_base=d_driver_viewspan_base;s->row_stride=d_driver_viewspan_stride;s->protected8=d_driver_protectset8;
    s->width=screenwidth;s->zwidth=d_zwidth;s->zbytes=d_zrowbytes;s->minimum=d_minmip;
    s->flat=d_aflatcolor;s->wrapped=d_roverwrapped;s->size=sc_size;
    s->base=sc_base;s->rover=sc_rover;s->initial=d_initial_rover;s->spans=d_drawspans;
    s->pix_min=d_pix_min;s->pix_max=d_pix_max;s->pix_shift=d_pix_shift;s->aspect_shift=d_y_aspect_shift;
    s->left=d_vrectx;s->top=d_vrecty;s->right=d_vrectright_particle;s->bottom=d_vrectbottom_particle;
    s->sky=r_skydirect;s->polys=r_drawpolys;s->back=r_worldpolysbacktofront;
    s->recursive=r_recursiveaffinetriangles;s->pixbytes=r_pixbytes;
    Q_memcpy(&s->aliasuv,&r_aliasuvscale,4);Q_memcpy(&s->mipcap,&d_mipcap.value,4);
    Q_memcpy(&s->mipscale,&d_mipscale.value,4);Q_memcpy(&s->subdiv,&d_subdiv16.value,4);
    Q_memcpy(s->scalemip,d_scalemip,12);Q_memcpy(&s->mip,&scale_for_mip,4);
    Q_memcpy(&s->x,&xscale,4);Q_memcpy(&s->y,&yscale,4);Q_memcpy(&s->aspect,&pixelAspect,4);
    Q_memcpy(s->rows,d_scantable,sizeof(s->rows));Q_memcpy(s->zrows,zspantable,sizeof(s->zrows));
    Q_memcpy(s->viewrows,viewspantable,sizeof(s->viewrows));Q_memcpy(s->cache,&bench486_driver_cache,sizeof(s->cache));
}
static void Bench486DriverRestore(const bench486_driver_state_t *s)
{
    Q_memcpy(&vid,(void *)&s->video,sizeof(vid));Q_memcpy(&r_refdef,(void *)&s->ref,sizeof(r_refdef));
    r_warpbuffer=s->warp;d_viewbuffer=s->view;d_pzbuffer=s->depth;r_dowarp=s->warp_on;
    d_driver_viewspan_base=s->row_base;d_driver_viewspan_stride=s->row_stride;d_driver_protectset8=s->protected8;
    screenwidth=s->width;d_zwidth=s->zwidth;d_zrowbytes=s->zbytes;d_minmip=s->minimum;
    d_aflatcolor=s->flat;d_roverwrapped=s->wrapped;sc_size=s->size;
    sc_base=s->base;sc_rover=s->rover;d_initial_rover=s->initial;d_drawspans=s->spans;
    d_pix_min=s->pix_min;d_pix_max=s->pix_max;d_pix_shift=s->pix_shift;d_y_aspect_shift=s->aspect_shift;
    d_vrectx=s->left;d_vrecty=s->top;d_vrectright_particle=s->right;d_vrectbottom_particle=s->bottom;
    r_skydirect=s->sky;r_drawpolys=s->polys;r_worldpolysbacktofront=s->back;
    r_recursiveaffinetriangles=s->recursive;r_pixbytes=s->pixbytes;
    Q_memcpy(&r_aliasuvscale,(void *)&s->aliasuv,4);Q_memcpy(&d_mipcap.value,(void *)&s->mipcap,4);
    Q_memcpy(&d_mipscale.value,(void *)&s->mipscale,4);Q_memcpy(&d_subdiv16.value,(void *)&s->subdiv,4);
    Q_memcpy(d_scalemip,(void *)s->scalemip,12);Q_memcpy(&scale_for_mip,(void *)&s->mip,4);
    Q_memcpy(&xscale,(void *)&s->x,4);Q_memcpy(&yscale,(void *)&s->y,4);Q_memcpy(&pixelAspect,(void *)&s->aspect,4);
    Q_memcpy(d_scantable,(void *)s->rows,sizeof(s->rows));Q_memcpy(zspantable,(void *)s->zrows,sizeof(s->zrows));
    Q_memcpy(viewspantable,(void *)s->viewrows,sizeof(s->viewrows));Q_memcpy(&bench486_driver_cache,(void *)s->cache,sizeof(s->cache));
}
static int Bench486DriverGuards(void)
{
    unsigned i;
    for(i=0;i<8;i++)
        if(bench486_driver_cache.before[i]!=0x5a5a5a5aU || bench486_driver_cache.after[i]!=0xa5a5a5a5U ||
           bench486_driver_video.before[i]!=0x5a5a5a5aU || bench486_driver_video.after[i]!=0xa5a5a5a5U ||
           bench486_driver_warp.before[i]!=0x5a5a5a5aU || bench486_driver_warp.after[i]!=0xa5a5a5a5U ||
           bench486_driver_depth.before[i]!=0x5a5a5a5aU || bench486_driver_depth.after[i]!=0xa5a5a5a5U)return 0;
    return 1;
}
static unsigned Bench486DriverBufferHash(void)
{
    unsigned i,hash=0x48600101U;
    for(i=0;i<sizeof(bench486_driver_video.data);i++)
        hash=(hash*33U)^bench486_driver_video.data[i]^(bench486_driver_warp.data[i]<<8);
    for(i=0;i<sizeof(bench486_driver_depth.data);i++)hash=(hash*33U)^((byte *)bench486_driver_depth.data)[i];
    return hash;
}
typedef struct {void (*c)(void),(*a)(void);unsigned words;const char *name;} bench486_driver_pair_t;
static const bench486_driver_pair_t bench486_driver_pairs[]={
    {D_Init_Driver_C,D_Init,0,"init"},
    {(void(*)(void))D_CopyRects_Driver_C,(void(*)(void))D_CopyRects,2,"copy-noop"},
    {D_EnableBackBufferAccess_Driver_C,D_EnableBackBufferAccess,0,"lock-noop"},
    {D_TurnZOn_Driver_C,D_TurnZOn,0,"z-noop"},
    {D_DisableBackBufferAccess_Driver_C,D_DisableBackBufferAccess,0,"unlock-noop"},
    {D_SetupFrame_Driver_C,D_SetupFrame,0,"frame-setup"},
    {(void(*)(void))D_UpdateRects_Driver_C,(void(*)(void))D_UpdateRects,1,"update-noop"},
    {D_Patch_Driver_C,D_Patch,0,"patch"},{D_ViewChanged_Driver_C,D_ViewChanged,0,"view-change"},
    {D_EndParticles_Driver_C,D_EndParticles,0,"end-particles-noop"},
    {D_StartParticles_Driver_C,D_StartParticles,0,"start-particles-noop"},
    {D_FlushCaches_Driver_C,D_FlushCaches,0,"flush-cache"},
    {D_DrawPoly_Driver_C,D_DrawPoly,0,"poly-noop"}
};
static void Bench486DriverInputs(unsigned pattern,unsigned sequence)
{
    static const unsigned floats[]={0,0x80000000U,0x3f800000U,0xbf800000U,1,0x00800000U,
        0x7f7fffffU,0xff7fffffU,0x3f7fffffU,0x407fffffU,0x4b800001U,0xcb800001U,
        0x3f333333U,0x40000000U,0x40400000U,0x40800000U};
    static const unsigned aspects[]={0,0x80000000U,0x3f800000U,0x3fb33332U,0x3fb33333U,0x3fb33334U,0x40000000U,0xbf800000U};
    static const int widths[]={0,1,79,80,159,160,319,320,321,639,640,641,16777217,2147483647,-1,(-2147483647-1)};
    static const unsigned heights[]={0,1,2,17,199,200,201,480,768,1023,1024};
    unsigned i,bits,n=1+pattern%128;
    vid.buffer=bench486_driver_video.data;vid.width=(pattern&1)?320:640;vid.rowbytes=vid.width;
    vid.height=heights[(pattern>>4)%11];r_warpbuffer=bench486_driver_warp.data;r_dowarp=(pattern>>2)&1;
    d_pzbuffer=bench486_driver_depth.data;
    r_refdef.vrect.width=widths[pattern%16];r_refdef.vrect.x=(int)(pattern^0x7fffffffU);
    r_refdef.vrect.y=(int)(pattern^0x80000000U);r_refdef.vrectright=(int)~pattern;r_refdef.vrectbottom=(int)pattern;
    bits=floats[(pattern>>3)%16];Q_memcpy(&d_mipcap.value,&bits,4);
    bits=floats[(pattern>>5)%16];Q_memcpy(&d_mipscale.value,&bits,4);
    bits=floats[(pattern>>7)%16];Q_memcpy(&d_subdiv16.value,&bits,4);
    bits=floats[(pattern>>9)%16];Q_memcpy(&xscale,&bits,4);
    bits=floats[(pattern>>11)%16];Q_memcpy(&yscale,&bits,4);
    bits=aspects[(pattern>>13)%8];Q_memcpy(&pixelAspect,&bits,4);
    if(!sequence)
    {
        r_skydirect=pattern;r_drawpolys=~pattern;r_worldpolysbacktofront=pattern^0x486U;
        r_recursiveaffinetriangles=pattern^0x80000000U;r_pixbytes=pattern;
        bits=floats[(pattern>>15)%16];Q_memcpy(&r_aliasuvscale,&bits,4);
        d_driver_viewspan_base=(pattern&1)?NULL:(r_dowarp?r_warpbuffer:vid.buffer);
        d_driver_viewspan_stride=(pattern&2)?-1:(r_dowarp?WARP_WIDTH:vid.rowbytes);
        for(i=0;i<MAXHEIGHT;i++)
        {d_scantable[i]=i*640;viewspantable[i]=(pixel_t *)(0x48600000U+4*i);zspantable[i]=(short *)(0x48610000U+4*i);}
    }
    /* Revisit both unchanged cache keys and changed heights across consecutive calls. */
    d_driver_protectset8=(pattern&3)==0?0:(pattern&3)==1?1:-1;
    d_roverwrapped=pattern;d_initial_rover=NULL;d_minmip=pattern;d_aflatcolor=pattern;
    Q_memset(&bench486_driver_cache,(int)pattern,sizeof(bench486_driver_cache));
    for(i=0;i<8;i++){bench486_driver_cache.before[i]=0x5a5a5a5aU;bench486_driver_cache.after[i]=0xa5a5a5a5U;}
    for(i=0;i<128;i++)
    {
        surfcache_t *node=&bench486_driver_cache.nodes[i];
        node->next=i+1<n?node+1:NULL;node->size=64+(int)i;
        bench486_driver_cache.owners[i]=node;
        node->owner=(i&3)==0?NULL:&bench486_driver_cache.owners[i];
    }
    if(pattern&4)bench486_driver_cache.nodes[pattern%n].owner=&bench486_driver_cache.nodes[pattern%n].next;
    if(pattern&8)bench486_driver_cache.nodes[(pattern>>8)%n].owner=(surfcache_t **)&bench486_driver_cache.nodes[(pattern>>8)%n].owner;
    sc_base=(pattern&16)?NULL:bench486_driver_cache.nodes;sc_rover=&bench486_driver_cache.nodes[pattern%128];sc_size=pattern;
}
static void Bench486DriverStep(unsigned pair,unsigned pattern,unsigned sequence)
{
    static bench486_driver_state_t initial,reference,assembly;
    bench486_driver_trace_t trace;unsigned args[2],c_abi,a_abi,i;int failed;
    Bench486DriverInputs(pattern,sequence);Bench486DriverSave(&initial);
    args[0]=(unsigned)&r_refdef.vrect;args[1]=pattern;
    Q_memset(&bench486_driver_trace,0,sizeof(bench486_driver_trace));
    c_abi=Bench486Call_asm486(bench486_driver_pairs[pair].c,bench486_driver_pairs[pair].words,args,NULL);
    Bench486DriverSave(&reference);Q_memcpy(&trace,&bench486_driver_trace,sizeof(trace));
    failed=!Bench486DriverGuards();Bench486DriverRestore(&initial);
    Q_memset(&bench486_driver_trace,0,sizeof(bench486_driver_trace));
    a_abi=Bench486Call_asm486(bench486_driver_pairs[pair].a,bench486_driver_pairs[pair].words,args,NULL);
    Bench486DriverSave(&assembly);
    failed|=c_abi || a_abi || !Bench486DriverGuards() || trace.errors || bench486_driver_trace.errors ||
        Q_memcmp(&trace,&bench486_driver_trace,sizeof(trace)) || Q_memcmp(&reference,&assembly,sizeof(reference));
    if(failed)
    {
        bench486_memory_failures++;
        if(bench486_memory_failures<24)
        {
            for(i=0;i<sizeof(reference);i++)if(((byte *)&reference)[i]!=((byte *)&assembly)[i])break;
            Bench486Printf("driver %s FAIL pattern %u ABI %x/%x state-byte %u trace %u/%u\n",
                bench486_driver_pairs[pair].name,pattern,c_abi,a_abi,i,trace.count,bench486_driver_trace.count);
            if(i<sizeof(reference))Bench486Printf("driver state C %02x assembly %02x\n",((byte *)&reference)[i],((byte *)&assembly)[i]);
        }
    }
}
static void Bench486DrawingDriverCases(void)
{
    static bench486_driver_state_t saved;
    static const unsigned modes[12]={0x007f,0x047f,0x087f,0x0c7f,0x027f,0x067f,0x0a7f,0x0e7f,0x037f,0x077f,0x0b7f,0x0f7f};
    void (*probe)(unsigned,unsigned,const unsigned *);unsigned short cw,control;
    unsigned i,mode,step,pair,cases=0,failures=bench486_memory_failures,hash,negative=0;
    Bench486DriverSave(&saved);probe=bench486_driver_probe;bench486_driver_probe=Bench486DriverObserve;
    __asm__ __volatile__("fnstcw %0":"=m"(cw));
    for(i=0;i<8;i++)
    {
        bench486_driver_cache.before[i]=bench486_driver_video.before[i]=bench486_driver_warp.before[i]=bench486_driver_depth.before[i]=0x5a5a5a5aU;
        bench486_driver_cache.after[i]=bench486_driver_video.after[i]=bench486_driver_warp.after[i]=bench486_driver_depth.after[i]=0xa5a5a5a5U;
    }
    for(i=0;i<sizeof(bench486_driver_video.data);i++)
    {bench486_driver_video.data[i]=(byte)(i*37U);bench486_driver_warp.data[i]=(byte)(i*61U);}
    for(i=0;i<sizeof(bench486_driver_depth.data);i++)((byte *)bench486_driver_depth.data)[i]=(byte)(i*97U);
    hash=Bench486DriverBufferHash();
    for(mode=0;mode<12;mode++)
    {
        control=(cw&~0x0f00U)|(modes[mode]&0x0f00U);__asm__ __volatile__("fldcw %0"::"m"(control));
        for(step=0;step<64;step++)for(pair=0;pair<13;pair++)
        {Bench486DriverStep(pair,step*0x1020305U+pair*0x486U,0);cases++;}
    }
    for(step=0;step<8192;step++)
    {Bench486DriverStep(step%13,step*0x9e3779b9U,1);cases++;}
    __asm__ __volatile__("fldcw %0"::"m"(cw));
    if(hash!=Bench486DriverBufferHash())bench486_memory_failures++;
    for(i=0;i<8;i++)
    {
        bench486_driver_cache.before[i]^=1;if(!Bench486DriverGuards())negative++;bench486_driver_cache.before[i]^=1;
        bench486_driver_cache.after[i]^=1;if(!Bench486DriverGuards())negative++;bench486_driver_cache.after[i]^=1;
        bench486_driver_video.after[i]^=1;if(!Bench486DriverGuards())negative++;bench486_driver_video.after[i]^=1;
        bench486_driver_warp.after[i]^=1;if(!Bench486DriverGuards())negative++;bench486_driver_warp.after[i]^=1;
        bench486_driver_depth.after[i]^=1;if(!Bench486DriverGuards())negative++;bench486_driver_depth.after[i]^=1;
    }
    if(negative!=40)bench486_memory_failures++;
    bench486_driver_probe=probe;Bench486DriverRestore(&saved);
    Bench486Printf("drawing driver exact state/rows/cache owners/ABI %s (13 entries; %u cases; 12 control words; 8192 sequence calls; %u guard checks; %u failures)\n",
        failures==bench486_memory_failures?"PASS":"FAIL",cases,negative,bench486_memory_failures-failures);
}
#else
static void Bench486DrawingDriverCases(void)
{bench486_memory_failures++;Bench486Printf("drawing driver fixture requires DrawingDriverImplementation=asm\n");}
#endif
