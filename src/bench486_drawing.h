/* Exact original framebuffer algorithms, including persistent cache/descriptor state. */
#ifdef ASM486_DRAWING
unsigned bench486_drawing_pointer_result;
typedef struct {unsigned first[8];byte data[10496];unsigned last[8];} bench486_drawing_buffer_t;
typedef struct {unsigned first[8];byte data[2560];unsigned last[8];} bench486_drawing_direct_t;
typedef struct {unsigned first[8];byte data[16384];unsigned last[8];} bench486_drawing_chars_t;
typedef struct {unsigned first[8];int width,height;byte data[768];unsigned last[8];} bench486_drawing_pic_t;
typedef struct {unsigned first[8];int width,height;byte data[64000];unsigned last[8];} bench486_drawing_conback_t;
typedef struct {unsigned first[8];int width,height;byte data[64];unsigned last[8];} bench486_drawing_tile_t;
typedef struct {unsigned first[8];int width,height;byte data[576];unsigned last[8];} bench486_drawing_disc_t;
typedef struct {unsigned phase,count,words[5];} bench486_drawing_event_t;
typedef struct {unsigned count,errors;bench486_drawing_event_t events[32];} bench486_drawing_trace_t;
typedef struct {
    viddef_t video;rectdesc_t descriptor;byte *characters;qpic_t *disc,*tile;
    cachepic_t cache[128];int cache_count,pixel_bytes;unsigned result;
    byte framebuffer[10496],console[10496],direct[2560],version[4096];
    int picture_width,picture_height;unsigned short palette[256];
} bench486_drawing_state_t;
typedef struct {
    bench486_drawing_buffer_t video,console;
    bench486_drawing_direct_t direct;
    bench486_drawing_chars_t chars;
    bench486_drawing_pic_t pic;
    bench486_drawing_conback_t conback;
    bench486_drawing_tile_t tile;
    bench486_drawing_disc_t disc;
    byte translation[256];
    char string[10],path[64];
    vrect_t rect;
    bench486_drawing_trace_t trace;
    bench486_drawing_state_t saved,initial,c_state,a_state;
    byte c_trace[sizeof(bench486_drawing_trace_t)];
} bench486_drawing_workspace_t;
static bench486_drawing_workspace_t *bench486_drawing_workspace;
#define bench486_drawing_video (bench486_drawing_workspace->video)
#define bench486_drawing_console (bench486_drawing_workspace->console)
#define bench486_drawing_direct (bench486_drawing_workspace->direct)
#define bench486_drawing_chars (bench486_drawing_workspace->chars)
#define bench486_drawing_pic (bench486_drawing_workspace->pic)
#define bench486_drawing_conback (bench486_drawing_workspace->conback)
#define bench486_drawing_tile (bench486_drawing_workspace->tile)
#define bench486_drawing_disc (bench486_drawing_workspace->disc)
#define bench486_drawing_translation (bench486_drawing_workspace->translation)
#define bench486_drawing_string (bench486_drawing_workspace->string)
#define bench486_drawing_path (bench486_drawing_workspace->path)
#define bench486_drawing_rect (bench486_drawing_workspace->rect)
#define bench486_drawing_trace (bench486_drawing_workspace->trace)
static unsigned Bench486DrawingStringHash(const char *s)
{unsigned hash=2166136261U;while(*s)hash=(hash^(byte)*s++)*16777619U;return hash;}
static unsigned Bench486DrawingFixture(unsigned phase,unsigned count,const unsigned *words)
{
    unsigned i;bench486_drawing_event_t *e;
    if(bench486_drawing_trace.count>=32 || count>5){bench486_drawing_trace.errors++;return 0;}
    e=&bench486_drawing_trace.events[bench486_drawing_trace.count++];e->phase=phase;e->count=count;
    for(i=0;i<count;i++)e->words[i]=((phase==1 || phase==3)&&i==0)?Bench486DrawingStringHash((char *)words[i]):words[i];
    if(phase==1){
        if(!strcmp((char *)words[0],"conchars"))return (unsigned)bench486_drawing_chars.data;
        if(!strcmp((char *)words[0],"disc"))return (unsigned)&bench486_drawing_disc.width;
        if(!strcmp((char *)words[0],"backtile"))return (unsigned)&bench486_drawing_tile.width;
        return (unsigned)&bench486_drawing_pic.width;
    }
    if(phase==2)return (unsigned)((cache_user_t *)words[0])->data;
    if(phase==3)((cache_user_t *)words[1])->data=!strcmp((char *)words[0],"gfx/conback.lmp")?
        (void *)&bench486_drawing_conback.width:(void *)&bench486_drawing_pic.width;
    /* SwapPic is traced; fixture headers already contain canonical little-endian dimensions. */
    return 0;
}
static void Bench486DrawingSave(bench486_drawing_state_t *s)
{
    Q_memset(s,0,sizeof(*s));Q_memcpy(&s->video,&vid,sizeof(vid));Q_memcpy(&s->descriptor,&r_rectdesc,sizeof(r_rectdesc));
    s->characters=draw_chars;s->disc=draw_disc;s->tile=draw_backtile;s->cache_count=menu_numcachepics;s->pixel_bytes=r_pixbytes;
    s->result=bench486_drawing_pointer_result;Q_memcpy(s->cache,menu_cachepics,sizeof(s->cache));
    Q_memcpy(s->framebuffer,bench486_drawing_video.data,sizeof(s->framebuffer));
    Q_memcpy(s->console,bench486_drawing_console.data,sizeof(s->console));Q_memcpy(s->direct,bench486_drawing_direct.data,sizeof(s->direct));
    Q_memcpy(s->version,bench486_drawing_conback.data+59000,sizeof(s->version));
    s->picture_width=bench486_drawing_pic.width;s->picture_height=bench486_drawing_pic.height;
    Q_memcpy(s->palette,d_8to16table,sizeof(s->palette));
}
static void Bench486DrawingRestore(const bench486_drawing_state_t *s)
{
    Q_memcpy(&vid,(void *)&s->video,sizeof(vid));Q_memcpy(&r_rectdesc,(void *)&s->descriptor,sizeof(r_rectdesc));
    draw_chars=s->characters;draw_disc=s->disc;draw_backtile=s->tile;menu_numcachepics=s->cache_count;r_pixbytes=s->pixel_bytes;
    bench486_drawing_pointer_result=s->result;Q_memcpy(menu_cachepics,(void *)s->cache,sizeof(s->cache));
    Q_memcpy(bench486_drawing_video.data,(void *)s->framebuffer,sizeof(s->framebuffer));
    Q_memcpy(bench486_drawing_console.data,(void *)s->console,sizeof(s->console));Q_memcpy(bench486_drawing_direct.data,(void *)s->direct,sizeof(s->direct));
    Q_memcpy(bench486_drawing_conback.data+59000,(void *)s->version,sizeof(s->version));
    bench486_drawing_pic.width=s->picture_width;bench486_drawing_pic.height=s->picture_height;
    Q_memcpy(d_8to16table,(void *)s->palette,sizeof(s->palette));
}
#define DRAWING_GUARDS(object) do {for(i=0;i<8;i++)if(object.first[i]!=0x5a5a5a5aU || object.last[i]!=0xa5a5a5a5U)return 0;}while(0)
static int Bench486DrawingGuards(void)
{
    unsigned i;DRAWING_GUARDS(bench486_drawing_video);DRAWING_GUARDS(bench486_drawing_console);
    DRAWING_GUARDS(bench486_drawing_direct);DRAWING_GUARDS(bench486_drawing_chars);DRAWING_GUARDS(bench486_drawing_pic);
    DRAWING_GUARDS(bench486_drawing_conback);DRAWING_GUARDS(bench486_drawing_tile);DRAWING_GUARDS(bench486_drawing_disc);return 1;
}
#undef DRAWING_GUARDS
typedef struct {const char *name;void (*c)(void),(*a)(void);unsigned words,pointer;} bench486_drawing_pair_t;
#define DRAWING_PAIR(n,w,p) {#n,(void (*)(void))n##_Drawing_C,(void (*)(void))n,w,p}
static const bench486_drawing_pair_t bench486_drawing_pairs[]={
    DRAWING_PAIR(Draw_PicFromWad,1,1),DRAWING_PAIR(Draw_CachePic,1,1),DRAWING_PAIR(Draw_Init,0,0),
    DRAWING_PAIR(Draw_Character,3,0),DRAWING_PAIR(Draw_String,3,0),DRAWING_PAIR(Draw_DebugChar,1,0),
    DRAWING_PAIR(Draw_Pic,3,0),DRAWING_PAIR(Draw_TransPic,3,0),DRAWING_PAIR(Draw_TransPicTranslate,4,0),
    DRAWING_PAIR(Draw_CharToConback,2,0),DRAWING_PAIR(Draw_ConsoleBackground,1,0),
    DRAWING_PAIR(R_DrawRect8,4,0),DRAWING_PAIR(R_DrawRect16,4,0),DRAWING_PAIR(Draw_TileClear,4,0),
    DRAWING_PAIR(Draw_Fill,5,0),DRAWING_PAIR(Draw_FadeScreen,0,0),DRAWING_PAIR(Draw_BeginDisc,0,0),DRAWING_PAIR(Draw_EndDisc,0,0)};
#undef DRAWING_PAIR
static void Bench486DrawingInputs(unsigned pair,unsigned pattern,unsigned sequence,unsigned *args)
{
    static const unsigned widths[]={8,12,16,20,32,64,128,320};
    static const unsigned picture_widths[]={0,1,7,8,9,15,16,24};
    unsigned i,n,x,y,w,h,srcstride,conwidth;
    r_pixbytes=(pattern&1)+1;vid.width=widths[(pattern>>1)%8];vid.height=16;vid.rowbytes=vid.width*r_pixbytes+((pattern>>4)%7);
    conwidth=widths[(pattern>>7)%8];vid.conwidth=conwidth;vid.conheight=16;vid.conrowbytes=conwidth*r_pixbytes+((pattern>>10)%7);
    vid.buffer=bench486_drawing_video.data;vid.conbuffer=bench486_drawing_console.data;
    vid.direct=(pattern&0x1000)?NULL:bench486_drawing_direct.data;
    draw_chars=bench486_drawing_chars.data;draw_disc=(qpic_t *)&bench486_drawing_disc.width;draw_backtile=(qpic_t *)&bench486_drawing_tile.width;
    bench486_drawing_tile.width=4+(pattern%5);bench486_drawing_tile.height=4+((pattern>>4)%5);
    Q_memset(&r_rectdesc,0,sizeof(r_rectdesc));r_rectdesc.width=bench486_drawing_tile.width;r_rectdesc.height=bench486_drawing_tile.height;
    r_rectdesc.rowbytes=r_rectdesc.width;r_rectdesc.ptexbytes=bench486_drawing_tile.data;
    w=picture_widths[(pattern>>12)%8];if(w>vid.width)w=vid.width;h=(pattern>>15)%9;
    bench486_drawing_pic.width=w;bench486_drawing_pic.height=h;
    for(i=0;i<256;i++){d_8to16table[i]=(unsigned short)(i*251U+pattern);bench486_drawing_translation[i]=(byte)(255-i+(pattern>>16));}
    if(!sequence){
        for(i=0;i<10496;i++){bench486_drawing_video.data[i]=(byte)(i*37U+pattern);bench486_drawing_console.data[i]=(byte)(i*19U-pattern);}
        for(i=0;i<2560;i++)bench486_drawing_direct.data[i]=(byte)(i*53U+pattern);
        for(i=59000;i<63096;i++)bench486_drawing_conback.data[i]=(byte)(i*13U+pattern);
    }
    if(!sequence || menu_numcachepics>=126){
        Q_memset(menu_cachepics,0,sizeof(menu_cachepics));menu_numcachepics=0;
        n=(pattern>>19)%4;n=n==3?127:n;
        for(i=0;i<n;i++){sprintf(menu_cachepics[i].name,"fixture-%u",i);menu_cachepics[i].cache.data=(void *)&bench486_drawing_pic.width;}
        menu_numcachepics=n;
    }
    strcpy(bench486_drawing_path,(pattern&0x100000)?"gfx/conback.lmp":"fixture-miss");
    if(menu_numcachepics && (pattern&0x200000)){strcpy(bench486_drawing_path,menu_cachepics[menu_numcachepics-1].name);
        if(pattern&0x400000)menu_cachepics[menu_numcachepics-1].cache.data=NULL;}
    bench486_drawing_pointer_result=0x486abcdeU;Q_memset(args,0,5*sizeof(*args));
    x=(pattern>>22)%(vid.width-w+1);y=(pattern>>25)%(17-h);
    args[0]=x;args[1]=y;args[2]=(unsigned)&bench486_drawing_pic.width;
    if(pair==0){static char *names[]={"conchars","disc","backtile","fixture"};args[0]=(unsigned)names[(pattern>>28)%4];}
    if(pair==1)args[0]=(unsigned)bench486_drawing_path;
    if(pair==3){args[0]=(pattern>>22)%(vid.conwidth-7);args[1]=(int)((pattern>>25)%17)-8;args[2]=pattern;}
    if(pair==4){n=(pattern>>26)%((vid.conwidth/8<8?vid.conwidth/8:8)+1);for(i=0;i<n;i++)bench486_drawing_string[i]=(char)(1+(pattern+i*67)%255);
        bench486_drawing_string[n]=0;args[0]=(pattern>>20)%(vid.conwidth-n*8+1);args[1]=(int)((pattern>>25)%17)-8;args[2]=(unsigned)bench486_drawing_string;}
    if(pair==5)args[0]=pattern&127;
    if(pair==8)args[3]=(unsigned)bench486_drawing_translation;
    if(pair==9){args[0]=pattern&255;args[1]=(unsigned)(bench486_drawing_conback.data+320*186+(pattern%64));}
    if(pair==10)args[0]=(pattern>>20)%17;
    if(pair==11 || pair==12){Q_memset(&bench486_drawing_rect,0,sizeof(bench486_drawing_rect));
        bench486_drawing_rect.x=x;bench486_drawing_rect.y=y;bench486_drawing_rect.width=w;bench486_drawing_rect.height=h;
        srcstride=w+(pattern%9);args[0]=(unsigned)&bench486_drawing_rect;args[1]=srcstride;args[2]=(unsigned)bench486_drawing_pic.data;args[3]=(pattern>>8)&1;
        if(pair==11){vid.rowbytes=vid.width+((pattern>>4)%7);r_pixbytes=1;}
        else {vid.rowbytes=vid.width*2+((pattern>>4)%7);r_pixbytes=2;}}
    if(pair==13 || pair==14){args[0]=x;args[1]=y;args[2]=w;args[3]=h;args[4]=r_pixbytes==1?pattern:(pattern&255);}
}
static void Bench486DrawingStep(unsigned pair,unsigned pattern,unsigned sequence)
{
    bench486_drawing_state_t *initial=&bench486_drawing_workspace->initial;
    bench486_drawing_state_t *c_state=&bench486_drawing_workspace->c_state;
    bench486_drawing_state_t *a_state=&bench486_drawing_workspace->a_state;
    byte *c_trace=bench486_drawing_workspace->c_trace;
    unsigned args[5],pointer_args[2],c_abi,a_abi,i;int failed;const bench486_drawing_pair_t *p=&bench486_drawing_pairs[pair];
    Bench486DrawingInputs(pair,pattern,sequence,args);Bench486DrawingSave(initial);Q_memset(&bench486_drawing_trace,0,sizeof(bench486_drawing_trace));
    pointer_args[0]=(unsigned)p->c;pointer_args[1]=args[0];
    c_abi=Bench486Call_asm486(p->pointer?Bench486DrawingPointerCall:p->c,p->pointer?2:p->words,p->pointer?pointer_args:args,NULL);
    Bench486DrawingSave(c_state);Q_memcpy(c_trace,&bench486_drawing_trace,sizeof(bench486_drawing_trace));failed=!Bench486DrawingGuards();
    Bench486DrawingRestore(initial);Q_memset(&bench486_drawing_trace,0,sizeof(bench486_drawing_trace));pointer_args[0]=(unsigned)p->a;
    a_abi=Bench486Call_asm486(p->pointer?Bench486DrawingPointerCall:p->a,p->pointer?2:p->words,p->pointer?pointer_args:args,NULL);
    Bench486DrawingSave(a_state);
    failed|=c_abi || a_abi || !Bench486DrawingGuards() || bench486_drawing_trace.errors ||
        Q_memcmp(c_trace,&bench486_drawing_trace,sizeof(bench486_drawing_trace)) || Q_memcmp(c_state,a_state,sizeof(*c_state));
    if(failed){bench486_memory_failures++;if(bench486_memory_failures<24){
        for(i=0;i<sizeof(*c_state);i++)if(((byte *)c_state)[i]!=((byte *)a_state)[i])break;
        Bench486Printf("drawing %s FAIL pattern %u ABI %x/%x state-byte %u trace %u\n",p->name,pattern,c_abi,a_abi,i,bench486_drawing_trace.count);}}
}
#define DRAWING_INIT_GUARDS(object) do {for(i=0;i<8;i++){object.first[i]=0x5a5a5a5aU;object.last[i]=0xa5a5a5a5U;}}while(0)
#define DRAWING_NEGATIVE_GUARDS(object) do {for(i=0;i<8;i++){object.first[i]^=1;if(!Bench486DrawingGuards())negative++;object.first[i]^=1;object.last[i]^=1;if(!Bench486DrawingGuards())negative++;object.last[i]^=1;}}while(0)
static unsigned Bench486DrawingImmutable(void)
{
    unsigned i,hash=2166136261U;
    for(i=0;i<16384;i++)hash=(hash^bench486_drawing_chars.data[i])*16777619U;
    for(i=0;i<768;i++)hash=(hash^bench486_drawing_pic.data[i])*16777619U;
    for(i=0;i<64000;i++)if(i<59000 || i>=63096)hash=(hash^bench486_drawing_conback.data[i])*16777619U;
    for(i=0;i<64;i++)hash=(hash^bench486_drawing_tile.data[i])*16777619U;
    for(i=0;i<576;i++)hash=(hash^bench486_drawing_disc.data[i])*16777619U;
    return hash;
}
static void Bench486DrawingCases(void)
{
    bench486_drawing_state_t *saved;int hunk_mark;unsigned short cw,control;
    static const unsigned modes[]={0x007f,0x047f,0x087f,0x0c7f,0x027f,0x067f,0x0a7f,0x0e7f,0x037f,0x077f,0x0b7f,0x0f7f};
    unsigned (*probe)(unsigned,unsigned,const unsigned *);unsigned i,mode,step,pair,cases=0,negative=0,hash,failures=bench486_memory_failures;
    hunk_mark=Hunk_LowMark();
    bench486_drawing_workspace=Hunk_AllocName(sizeof(*bench486_drawing_workspace),"drawtest");
    saved=&bench486_drawing_workspace->saved;
    Bench486DrawingSave(saved);probe=bench486_drawing_probe;bench486_drawing_probe=Bench486DrawingFixture;
    __asm__ __volatile__("fnstcw %0":"=m"(cw));
    DRAWING_INIT_GUARDS(bench486_drawing_video);DRAWING_INIT_GUARDS(bench486_drawing_console);DRAWING_INIT_GUARDS(bench486_drawing_direct);
    DRAWING_INIT_GUARDS(bench486_drawing_chars);DRAWING_INIT_GUARDS(bench486_drawing_pic);DRAWING_INIT_GUARDS(bench486_drawing_conback);
    DRAWING_INIT_GUARDS(bench486_drawing_tile);DRAWING_INIT_GUARDS(bench486_drawing_disc);
    for(i=0;i<16384;i++)bench486_drawing_chars.data[i]=(i%5)?(byte)(i*37U):0;
    for(i=0;i<768;i++)bench486_drawing_pic.data[i]=(i%3)?(byte)(i*67U):255;
    for(i=0;i<64000;i++)bench486_drawing_conback.data[i]=(byte)(i*13U);
    for(i=0;i<64;i++)bench486_drawing_tile.data[i]=(byte)(i*29U);
    for(i=0;i<576;i++)bench486_drawing_disc.data[i]=(byte)(i*53U);
    bench486_drawing_conback.width=320;bench486_drawing_conback.height=200;bench486_drawing_disc.width=24;bench486_drawing_disc.height=24;
    hash=Bench486DrawingImmutable();
    for(mode=0;mode<12;mode++){control=(cw&~0x0f00U)|(modes[mode]&0x0f00U);__asm__ __volatile__("fldcw %0"::"m"(control));
        for(step=0;step<16;step++)for(pair=0;pair<18;pair++){Bench486DrawingStep(pair,step*0x1020305U+pair*0x486U,0);cases++;}}
    for(step=0;step<8192;step++){Bench486DrawingStep(step%18,step*0x9e3779b9U,1);cases++;}
    __asm__ __volatile__("fldcw %0"::"m"(cw));if(hash!=Bench486DrawingImmutable())bench486_memory_failures++;
    DRAWING_NEGATIVE_GUARDS(bench486_drawing_video);DRAWING_NEGATIVE_GUARDS(bench486_drawing_console);DRAWING_NEGATIVE_GUARDS(bench486_drawing_direct);
    DRAWING_NEGATIVE_GUARDS(bench486_drawing_chars);DRAWING_NEGATIVE_GUARDS(bench486_drawing_pic);DRAWING_NEGATIVE_GUARDS(bench486_drawing_conback);
    DRAWING_NEGATIVE_GUARDS(bench486_drawing_tile);DRAWING_NEGATIVE_GUARDS(bench486_drawing_disc);if(negative!=128)bench486_memory_failures++;
    bench486_drawing_probe=probe;Bench486DrawingRestore(saved);
    bench486_drawing_workspace=NULL;Hunk_FreeToLowMark(hunk_mark);
    Bench486Printf("framebuffer drawing exact pixels/cache/console/tile/trace/ABI %s (18 entries; %u cases; 12 control words; 8192 sequence calls; %u guard checks; %u failures)\n",
        failures==bench486_memory_failures?"PASS":"FAIL",cases,negative,bench486_memory_failures-failures);
}
#undef DRAWING_INIT_GUARDS
#undef DRAWING_NEGATIVE_GUARDS
#else
static void Bench486DrawingCases(void)
{bench486_memory_failures++;Bench486Printf("drawing fixture requires DrawingImplementation=asm\n");}
#endif
