/* Independent sky oracles: exact pixels, palette words, cached state and ABI.
   Included only by the BENCH486 harness. No similarity threshold or tolerance. */
#ifdef ASM486_SKY
extern void R_InitSky_C(texture_t *);
extern void R_MakeSky_C(void);
extern void R_GenSkyTile_C(void *);
extern void R_GenSkyTile16_C(void *);
extern void R_SetSkyFrame_C(void);
extern int iskyspeed,iskyspeed2,r_skymade,r_skydirect;
extern float skyspeed,skyspeed2,skytime;
extern byte *r_skysource;
extern byte bottomsky[128*131],bottommask[128*131],newsky[128*256];
extern int r_sky_xlast_c,r_sky_ylast_c,r_sky_xlast_asm486,r_sky_ylast_asm486;
extern byte bench486_sky_bottom_storage[32+128*131+32];
extern byte bench486_sky_mask_storage[32+128*131+32];
extern byte bench486_sky_new_storage[32+128*256+32];

typedef struct {
    byte bottom[128*131+64],mask[128*131+64],composite[128*256+64];
    int speed1,speed2,made,direct;
    float float_speed1,float_speed2,time;
    byte *source;
} bench486_sky_state_t;

static void Bench486SkySave(bench486_sky_state_t *state)
{
    Q_memcpy(state->bottom,bench486_sky_bottom_storage,sizeof(state->bottom));
    Q_memcpy(state->mask,bench486_sky_mask_storage,sizeof(state->mask));
    Q_memcpy(state->composite,bench486_sky_new_storage,sizeof(state->composite));
    state->speed1=iskyspeed; state->speed2=iskyspeed2;
    state->made=r_skymade; state->direct=r_skydirect;
    state->float_speed1=skyspeed; state->float_speed2=skyspeed2;
    state->time=skytime; state->source=r_skysource;
}

static void Bench486SkyRestore(bench486_sky_state_t *state)
{
    Q_memcpy(bench486_sky_bottom_storage,state->bottom,sizeof(state->bottom));
    Q_memcpy(bench486_sky_mask_storage,state->mask,sizeof(state->mask));
    Q_memcpy(bench486_sky_new_storage,state->composite,sizeof(state->composite));
    iskyspeed=state->speed1; iskyspeed2=state->speed2;
    r_skymade=state->made; r_skydirect=state->direct;
    skyspeed=state->float_speed1; skyspeed2=state->float_speed2;
    skytime=state->time; r_skysource=state->source;
}

static int Bench486SkyGuardsIntact(void)
{
    int i;
    for(i=0;i<32;i++)
        if(bench486_sky_bottom_storage[i]!=0x5a ||
           bench486_sky_bottom_storage[32+128*131+i]!=0xa5 ||
           bench486_sky_mask_storage[i]!=0x5a ||
           bench486_sky_mask_storage[32+128*131+i]!=0xa5 ||
           bench486_sky_new_storage[i]!=0x5a ||
           bench486_sky_new_storage[32+128*256+i]!=0xa5) return 0;
    return 1;
}

static void Bench486SkyFailure(const char *name,int phase,unsigned c_abi,unsigned a_abi)
{
    bench486_memory_failures++;
    if(bench486_memory_failures<24)
        Bench486Printf("sky %s FAIL phase %d ABI %x/%x\n",name,phase,c_abi,a_abi);
}

static void Bench486SkyStateStep(void (*c_function)(void),void (*a_function)(void),
                                unsigned words,unsigned *arguments,const char *name,int phase)
{
    static bench486_sky_state_t before,reference,assembly;
    unsigned c_abi,a_abi;
    Bench486SkySave(&before);
    c_abi=Bench486Call_asm486(c_function,words,arguments,NULL);
    Bench486SkySave(&reference);
    Bench486SkyRestore(&before);
    a_abi=Bench486Call_asm486(a_function,words,arguments,NULL);
    Bench486SkySave(&assembly);
    if(c_abi || a_abi || Q_memcmp(&reference,&assembly,sizeof(reference)))
    {
        int offset;
        Bench486SkyFailure(name,phase,c_abi,a_abi);
        if(bench486_memory_failures<24)
        {
            for(offset=0;offset<sizeof(reference);offset++)
                if(((byte *)&reference)[offset]!=((byte *)&assembly)[offset]) break;
            if(offset<sizeof(reference))
                Bench486Printf("sky first state byte %d reference %02x assembly %02x\n",offset,
                    ((byte *)&reference)[offset],((byte *)&assembly)[offset]);
        }
    }
    if(r_sky_xlast_c!=r_sky_xlast_asm486 || r_sky_ylast_c!=r_sky_ylast_asm486)
        Bench486SkyFailure("cached-shifts",phase,0,0);
    if(!Bench486SkyGuardsIntact()) Bench486SkyFailure("array-guards",phase,0,0);
}

static void Bench486SkyFrameStep(int phase)
{
    /* GreatestCommonDivisor's original domain is nonnegative integers. Some
       negative pairs never terminate; (0,0) gives the original divide fault.
       Include zero/nonzero, large coprime and wrapped-period combinations. */
    static const int speeds[][2]={{8,2},{1,1},{3,5},{7,11},{0,8},{8,0},{2,8},{1024,2},
        {128,128},{127,128},{65537,65539},{16777217,13},{32767,32749},{2147483647,2},
        {2147483647,3},{128,7}};
    static const double times[]={0.0,-0.0,0.125,-0.125,15.999999999,16.0,16.000000001,
        -16.000000001,127.999999999,128.0,65536.125,-65536.125,1.0e12,-1.0e12,
        1.0e-20,-1.0e-20};
    float c_speed1,c_speed2,c_time;
    int c_made;
    unsigned c_abi,a_abi;
    iskyspeed=speeds[phase%16][0]; iskyspeed2=speeds[phase%16][1];
    cl.time=times[(phase/16+phase*7)%16];
    r_skymade=0x48601234;
    c_abi=Bench486Call_asm486(R_SetSkyFrame_C,0,NULL,NULL);
    c_speed1=skyspeed; c_speed2=skyspeed2; c_time=skytime; c_made=r_skymade;
    skyspeed=-999; skyspeed2=999; skytime=-999; r_skymade=0x48601234;
    a_abi=Bench486Call_asm486(R_SetSkyFrame,0,NULL,NULL);
    if(c_abi || a_abi || Q_memcmp(&c_speed1,&skyspeed,4) ||
        Q_memcmp(&c_speed2,&skyspeed2,4) || Q_memcmp(&c_time,&skytime,4) || c_made!=r_skymade)
    {
        Bench486SkyFailure("time-frame",phase,c_abi,a_abi);
        if(bench486_memory_failures<24)
            Bench486Printf("sky frame speeds %d/%d time %.17g sky %.9g/%.9g\n",
                iskyspeed,iskyspeed2,cl.time,c_time,skytime);
    }
}

static void Bench486SkyTileStep(int phase,int sixteen)
{
    static byte reference[128*128*2+80],assembly[128*128*2+80];
    static unsigned short unchanged_palette[256];
    static bench486_sky_state_t before,after;
    unsigned args[1],c_abi,a_abi;
    int size=sixteen?128*128*2:128*128,offset=32+phase%4;
    Q_memset(reference,0xa6,sizeof(reference)); Q_memset(assembly,0xa6,sizeof(assembly));
    Q_memcpy(unchanged_palette,d_8to16table,sizeof(unchanged_palette));
    Bench486SkySave(&before);
    args[0]=(unsigned)(reference+offset);
    c_abi=Bench486Call_asm486((void (*)(void))(sixteen?R_GenSkyTile16_C:R_GenSkyTile_C),1,args,NULL);
    args[0]=(unsigned)(assembly+offset);
    a_abi=Bench486Call_asm486((void (*)(void))(sixteen?R_GenSkyTile16:R_GenSkyTile),1,args,NULL);
    if(c_abi || a_abi || Q_memcmp(reference,assembly,sizeof(reference)))
        Bench486SkyFailure(sixteen?"tile16":"tile8",phase,c_abi,a_abi);
    if(Q_memcmp(unchanged_palette,d_8to16table,sizeof(unchanged_palette)))
        Bench486SkyFailure("palette-input",phase,0,0);
    Bench486SkySave(&after);
    if(Q_memcmp(&before,&after,sizeof(before))) Bench486SkyFailure("tile-state-leak",phase,0,0);
    /* Whole-buffer parity is complemented by an independent destination bound. */
    {
        int i;
        for(i=0;i<sizeof(reference);i++)
            if((i<offset || i>=offset+size) && (reference[i]!=0xa6 || assembly[i]!=0xa6))
            { Bench486SkyFailure("tile-bounds",phase,0,0); break; }
    }
}

static void Bench486SkyInitStep(int phase)
{
    static byte texture[sizeof(texture_t)+128*256+80],unchanged[sizeof(texture_t)+128*256+80];
    texture_t *mt=(texture_t *)(texture+32);
    unsigned args[1];
    byte *pixels;
    int i;
    Q_memset(texture,0xa6,sizeof(texture)); Q_memset(mt,0,sizeof(*mt));
    mt->width=256; mt->height=128; mt->offsets[0]=sizeof(*mt)+phase%4;
    pixels=(byte *)mt+mt->offsets[0];
    for(i=0;i<128*256;i++)
        pixels[i]=phase%5==0?0:phase%5==1?255:(byte)((i*73+phase*29)^(i>>7));
    Q_memcpy(unchanged,texture,sizeof(texture));
    args[0]=(unsigned)mt;
    Bench486SkyStateStep((void (*)(void))R_InitSky_C,(void (*)(void))R_InitSky,1,args,"init",phase);
    if(Q_memcmp(texture,unchanged,sizeof(texture))) Bench486SkyFailure("texture-input",phase,0,0);
}

static void Bench486SkyCases(void)
{
    static bench486_sky_state_t saved;
    static unsigned short saved_palette[256];
    static const float shifts[]={0,-0.0f,0.125f,-0.125f,15.875f,16,16.125f,-16.125f,
        127.875f,128,128.125f,-128.125f,65536.125f,-65536.125f,1.0e12f,-1.0e12f,
        1.0e-20f,-1.0e-20f,268435455.0f,-268435455.0f,0.99999994f,-0.99999994f,31.999998f,-31.999998f};
    double saved_time=cl.time;
    unsigned short saved_cw,cw;
    int saved_c_x=r_sky_xlast_c,saved_c_y=r_sky_ylast_c;
    int saved_a_x=r_sky_xlast_asm486,saved_a_y=r_sky_ylast_asm486;
    int precision,mode,phase,i,sequence,scalar=0,compositors=0,before=bench486_memory_failures;
    Bench486Printf("sky exact direct and continuous fixtures begin\n");
    Bench486SkySave(&saved); Q_memcpy(saved_palette,d_8to16table,sizeof(saved_palette));
    Q_memset(bottomsky,0x69,128*131); Q_memset(bottommask,0x69,128*131); Q_memset(newsky,0x69,128*256);
    Q_memset(bench486_sky_bottom_storage,0x5a,32); Q_memset(bench486_sky_bottom_storage+32+128*131,0xa5,32);
    Q_memset(bench486_sky_mask_storage,0x5a,32); Q_memset(bench486_sky_mask_storage+32+128*131,0xa5,32);
    Q_memset(bench486_sky_new_storage,0x5a,32); Q_memset(bench486_sky_new_storage+32+128*256,0xa5,32);
    r_sky_xlast_c=r_sky_ylast_c=r_sky_xlast_asm486=r_sky_ylast_asm486=-1;
    for(i=0;i<256;i++) d_8to16table[i]=(unsigned short)((i*97)^(i<<8)^0x486a);
    __asm__ __volatile__("fnstcw %0":"=m"(saved_cw));
    for(precision=0;precision<=3;precision++)
    {
        if(precision==1) continue;
        for(mode=0;mode<4;mode++)
        {
            cw=(saved_cw & ~0x0f00)|(precision<<8)|(mode<<10);
            __asm__ __volatile__("fldcw %0"::"m"(cw));
            for(phase=0;phase<256;phase++,scalar++) Bench486SkyFrameStep(phase);
            for(phase=0;phase<24;phase++)
            {
                Bench486SkyInitStep(phase);
                skytime=shifts[phase]; skyspeed=phase%3==0?8:phase%3==1?1.0f/3.0f:-7.0f;
                r_skymade=0;
                Bench486SkyStateStep(R_MakeSky_C,R_MakeSky,0,NULL,"make",phase);
                /* Cached phase after SetSkyFrame clears made: an intentional no-op. */
                r_skymade=0;
                Bench486SkyStateStep(R_MakeSky_C,R_MakeSky,0,NULL,"cached-make",phase);
                Bench486SkyTileStep(phase,0); Bench486SkyTileStep(phase,1);
                compositors+=5;
            }
        }
    }
    __asm__ __volatile__("fldcw %0"::"m"(saved_cw));
    Bench486Printf("sky twelve x87 settings completed (%d scalar; %d compositor cases)\n",scalar,compositors);
    for(sequence=0;sequence<8192;sequence++) Bench486SkyFrameStep(sequence);
    /* Continuous texture/sky/tile state. Neither cache is reset between frames. */
    iskyspeed=8; iskyspeed2=2;
    for(sequence=0;sequence<2048;sequence++)
    {
        if(!(sequence%128)) Bench486SkyInitStep(sequence/128);
        cl.time=(double)sequence/32.0;
        Bench486SkyStateStep(R_SetSkyFrame_C,R_SetSkyFrame,0,NULL,"sequence-frame",sequence);
        Bench486SkyStateStep(R_MakeSky_C,R_MakeSky,0,NULL,"sequence-make",sequence);
        if(!(sequence%16)) Bench486SkyTileStep(sequence,0);
        if(!(sequence%32)) Bench486SkyTileStep(sequence,1);
    }
    /* Prove each independent leading/trailing array guard is checked. */
    for(i=0;i<6;i++)
    {
        byte *guard=i<2?bench486_sky_bottom_storage:i<4?bench486_sky_mask_storage:bench486_sky_new_storage;
        int offset=i%2?32+(i<4?128*131:128*256)+23:17;
        guard[offset]^=1;
        if(Bench486SkyGuardsIntact()) Bench486SkyFailure("missed-guard-fault",i,0,0);
        guard[offset]^=1;
    }
    Bench486SkyRestore(&saved); Q_memcpy(d_8to16table,saved_palette,sizeof(saved_palette)); cl.time=saved_time;
    r_sky_xlast_c=saved_c_x; r_sky_ylast_c=saved_c_y;
    r_sky_xlast_asm486=saved_a_x; r_sky_ylast_asm486=saved_a_y;
    Bench486Printf("sky exact arrays/tile8/tile16/time/cache/input/ABI/guards %s (%d scalar; %d direct compositors; 8192 time frames; 2048 composited frames; %d failures)\n",
        before==bench486_memory_failures?"PASS":"FAIL",scalar,compositors,bench486_memory_failures-before);
}
#else
static void Bench486SkyCases(void)
{ bench486_memory_failures++; Bench486Printf("sky fixture requires SkyImplementation=asm\n"); }
#endif
