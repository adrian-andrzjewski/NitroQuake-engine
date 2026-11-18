/* Exact visibility buffer, leaf identity, unchanged-input and ABI comparisons.
 * Independent C routines use their own static buffer and call each other. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifdef ASM486_VISIBILITY
extern mleaf_t *Mod_PointInLeaf_C (vec3_t,model_t *);
extern byte *Mod_DecompressVis (byte *,model_t *);
extern byte *Mod_DecompressVis_C (byte *,model_t *);
extern byte *Mod_LeafPVS_C (mleaf_t *,model_t *);
extern byte mod_novis[MAX_MAP_LEAFS/8];
extern byte asm486_vis_decompressed[MAX_MAP_LEAFS/8];
extern byte bench486_vis_before[32],bench486_vis_after[32];

static void Bench486VisFailure(const char *name,int phase,unsigned c_abi,unsigned a_abi)
{
    bench486_memory_failures++;
    if(bench486_memory_failures<24)
        Bench486Printf("visibility %s FAIL phase %d ABI %x/%x\n",name,phase,c_abi,a_abi);
}

static int Bench486VisGuardsIntact(void)
{
    int i;
    for(i=0;i<32;i++) if(bench486_vis_before[i]!=0x5a || bench486_vis_after[i]!=0xa5) return 0;
    return 1;
}

static void Bench486VisDecodeStep(int phase)
{
    static const int widths[]={0,1,7,8,9,16,31,63,127,255,511,1023,2047,4095,8191,8192};
    static struct { unsigned first; byte stream[2052]; unsigned last; } input,unchanged;
    static byte raw[1024],saved_novis[1024];
    static model_t model,model_before;
    static mleaf_t leaves[2],leaves_before[2];
    byte *c_result,*a_result,*stream;
    unsigned args[2],c_abi,a_abi;
    int row,i,n,run,solid;
    Q_memset(&input,0xa6,sizeof(input)); input.first=0x486a1357; input.last=0x486b2468;
    Q_memset(&model,0,sizeof(model)); Q_memset(leaves,0,sizeof(leaves));
    model.numleafs=widths[phase%16]; model.leafs=leaves;
    row=(model.numleafs+7)>>3;
    for(i=0;i<(row?row:1);i++)
    {
        raw[i]=(byte)((i*73+phase*19)%255+1);
        if(phase%5==1 || (phase%5==2 && i%2) || (phase%5==3 && i%257<255)) raw[i]=0;
    }
    n=0;
    if(phase%7==0) { input.stream[n++]=0; input.stream[n++]=0; } /* legal zero-count packet */
    for(i=0;i<(row?row:1);)
    {
        if(raw[i]) input.stream[n++]=raw[i++];
        else
        {
            run=0;
            while(i<(row?row:1) && !raw[i] && run<255) { i++; run++; }
            input.stream[n++]=0; input.stream[n++]=(byte)run;
        }
    }
    stream=phase%8==0?NULL:input.stream;
    leaves[0].contents=CONTENTS_SOLID; leaves[1].contents=CONTENTS_EMPTY;
    leaves[1].compressed_vis=stream;
    unchanged=input; model_before=model; Q_memcpy(leaves_before,leaves,sizeof(leaves));
    Q_memcpy(saved_novis,mod_novis,sizeof(saved_novis));
    c_result=Mod_DecompressVis_C(stream,&model);
    a_result=Mod_DecompressVis(stream,&model);
    args[0]=(unsigned)stream; args[1]=(unsigned)&model;
    c_abi=Bench486Call_asm486((void (*)(void))Mod_DecompressVis_C,2,args,NULL);
    a_abi=Bench486Call_asm486((void (*)(void))Mod_DecompressVis,2,args,NULL);
    if(c_abi || a_abi || a_result!=asm486_vis_decompressed ||
            Q_memcmp(c_result,a_result,1024)) Bench486VisFailure("decode",phase,c_abi,a_abi);
    solid=phase%3==0;
    args[0]=(unsigned)&leaves[solid?0:1];
    c_result=Mod_LeafPVS_C((mleaf_t *)args[0],&model);
    a_result=Mod_LeafPVS((mleaf_t *)args[0],&model);
    c_abi=Bench486Call_asm486((void (*)(void))Mod_LeafPVS_C,2,args,NULL);
    a_abi=Bench486Call_asm486((void (*)(void))Mod_LeafPVS,2,args,NULL);
    if(c_abi || a_abi || (solid && (c_result!=mod_novis || a_result!=mod_novis)) ||
            (!solid && a_result!=asm486_vis_decompressed) || Q_memcmp(c_result,a_result,1024))
        Bench486VisFailure("leaf-pvs",phase,c_abi,a_abi);
    if(Q_memcmp(&input,&unchanged,sizeof(input)) || Q_memcmp(&model,&model_before,sizeof(model)) ||
            Q_memcmp(leaves,leaves_before,sizeof(leaves)) || Q_memcmp(mod_novis,saved_novis,1024))
        Bench486VisFailure("unchanged-input",phase,0,0);
    if(!Bench486VisGuardsIntact()) Bench486VisFailure("buffer-guard",phase,0,0);
}

static void Bench486VisPointStep(int phase)
{
    static const float coordinates[]={0,-0.0f,0.125f,-0.125f,1,-1,32,-32,65536,-65536,
        16777216,-16777216,1.0e15f,-1.0e15f,1.0e-25f,-1.0e-25f};
    static struct {
        unsigned first; model_t model; mnode_t nodes[128]; mplane_t planes[128];
        mleaf_t leaves[3]; vec3_t point; unsigned last;
    } input,unchanged;
    mleaf_t *c_result,*a_result;
    mnode_t *next;
    unsigned args[2],c_abi,a_abi;
    int i,depth;
    Q_memset(&input,0,sizeof(input));
    input.first=0x486a1357; input.last=0x486b2468;
    for(i=0;i<3;i++) input.leaves[i].contents=CONTENTS_EMPTY-i;
    for(i=0;i<3;i++) input.point[i]=coordinates[(phase+i*7)%16];
    depth=phase%129;
    if(phase%16==0) depth=128;
    if(phase%19==0) depth=0;
    input.model.nodes=depth?input.nodes:(mnode_t *)&input.leaves[phase%3];
    for(i=0;i<depth;i++)
    {
        input.nodes[i].plane=&input.planes[i];
        input.planes[i].type=(phase+i)%4;
        input.planes[i].signbits=(phase+i)%8;
        input.planes[i].normal[0]=coordinates[(phase+i)%16];
        input.planes[i].normal[1]=coordinates[(phase+i+5)%16];
        input.planes[i].normal[2]=coordinates[(phase+i+9)%16];
        input.planes[i].dist=coordinates[(phase+i+3)%16];
        if(phase%11==0) /* exact zero-distance classification */
        { Q_memset(input.planes[i].normal,0,sizeof(vec3_t)); input.planes[i].dist=0; }
        next=i+1<depth?&input.nodes[i+1]:(mnode_t *)&input.leaves[2];
        input.nodes[i].children[0]=phase%4==2?(mnode_t *)&input.leaves[1]:next;
        input.nodes[i].children[1]=phase%4==1?(mnode_t *)&input.leaves[0]:next;
    }
    unchanged=input;
    args[0]=depth?(unsigned)input.point:0; args[1]=(unsigned)&input.model;
    c_result=Mod_PointInLeaf_C((float *)args[0],&input.model);
    a_result=Mod_PointInLeaf((float *)args[0],&input.model);
    c_abi=Bench486Call_asm486((void (*)(void))Mod_PointInLeaf_C,2,args,NULL);
    a_abi=Bench486Call_asm486((void (*)(void))Mod_PointInLeaf,2,args,NULL);
    if(c_abi || a_abi || c_result!=a_result) Bench486VisFailure("point-leaf",phase,c_abi,a_abi);
    if(Q_memcmp(&input,&unchanged,sizeof(input))) Bench486VisFailure("point-input",phase,0,0);
}

static void Bench486VisibilityCases(void)
{
    static byte saved_c_buffer[1024],saved_a_buffer[1024],saved_novis[1024];
    static byte saved_before[32],saved_after[32];
    model_t model;
    byte *c_buffer;
    unsigned short saved_cw,cw;
    int mode,precision,phase,direct=0,sequence,before=bench486_memory_failures;
    Q_memset(&model,0,sizeof(model));
    c_buffer=Mod_DecompressVis_C(NULL,&model); /* row 0: obtain buffer without a write */
    Q_memcpy(saved_c_buffer,c_buffer,1024); Q_memcpy(saved_a_buffer,asm486_vis_decompressed,1024);
    Q_memcpy(saved_novis,mod_novis,1024);
    Q_memcpy(saved_before,bench486_vis_before,32); Q_memcpy(saved_after,bench486_vis_after,32);
    Q_memset(c_buffer,0x69,1024); Q_memset(asm486_vis_decompressed,0x69,1024);
    Q_memset(bench486_vis_before,0x5a,32); Q_memset(bench486_vis_after,0xa5,32);
    __asm__ __volatile__("fnstcw %0":"=m"(saved_cw));
    for(precision=0;precision<=3;precision++)
    {
        if(precision==1) continue; /* reserved x87 precision-control value */
        for(mode=0;mode<4;mode++)
        {
            cw=(saved_cw & ~0x0f00)|(precision<<8)|(mode<<10);
            __asm__ __volatile__("fldcw %0"::"m"(cw));
            for(phase=0;phase<256;phase++,direct+=3)
            { Bench486VisDecodeStep(phase); Bench486VisPointStep(phase); }
        }
    }
    __asm__ __volatile__("fldcw %0"::"m"(saved_cw));
    for(sequence=0;sequence<8192;sequence++)
    { Bench486VisDecodeStep(sequence); Bench486VisPointStep(sequence); }
    /* Prove the same guard predicate rejects corruption on either side. */
    bench486_vis_before[17]^=1;
    if(Bench486VisGuardsIntact()) Bench486VisFailure("missed-leading-guard-fault",0,0,0);
    bench486_vis_before[17]^=1;
    bench486_vis_after[23]^=1;
    if(Bench486VisGuardsIntact()) Bench486VisFailure("missed-trailing-guard-fault",0,0,0);
    bench486_vis_after[23]^=1;
    Q_memcpy(c_buffer,saved_c_buffer,1024); Q_memcpy(asm486_vis_decompressed,saved_a_buffer,1024);
    Q_memcpy(mod_novis,saved_novis,1024);
    Q_memcpy(bench486_vis_before,saved_before,32); Q_memcpy(bench486_vis_after,saved_after,32);
    Bench486Printf("visibility exact buffer/leaf/input/ABI/guards %s (%d direct cases; %d sequence frames; %d failures)\n",
        before==bench486_memory_failures?"PASS":"FAIL",direct,sequence,bench486_memory_failures-before);
}
#else
static void Bench486VisibilityCases(void)
{ bench486_memory_failures++; Bench486Printf("visibility fixture requires VisibilityImplementation=asm\n"); }
#endif
