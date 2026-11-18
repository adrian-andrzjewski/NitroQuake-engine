/* ABI contract for the i486 Mod_LoadModel dispatcher. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_MODELLOAD_H
#define ASM_MODELLOAD_H
#ifndef __ASSEMBLER__
#include <stddef.h>
#include "model.h"
extern model_t *loadmodel;
extern char loadname[32];
typedef char aml_pointer_size_must_match[(sizeof(void *)==4U)?1:-1];
typedef char aml_model_t_size_must_match[(sizeof(model_t)==392U)?1:-1];
typedef char aml_model_t_name_must_match[(offsetof(model_t,name)==0U)?1:-1];
typedef char aml_model_t_needload_must_match[(offsetof(model_t,needload)==64U)?1:-1];
typedef char aml_model_t_type_must_match[(offsetof(model_t,type)==68U)?1:-1];
typedef char aml_model_t_numframes_must_match[(offsetof(model_t,numframes)==72U)?1:-1];
typedef char aml_model_t_cache_must_match[(offsetof(model_t,cache)==388U)?1:-1];
typedef char aml_cache_data_must_match[(offsetof(cache_user_t,data)==0U)?1:-1];
typedef char aml_mod_brush_must_match[(mod_brush==0U)?1:-1];
typedef char aml_mod_sprite_must_match[(mod_sprite==1U)?1:-1];
typedef char aml_mod_alias_must_match[(mod_alias==2U)?1:-1];
typedef char aml_mod_idpoly_must_match[(IDPOLYHEADER==0x4f504449U)?1:-1];
typedef char aml_mod_idsprite_must_match[(IDSPRITEHEADER==0x50534449U)?1:-1];

model_t *Mod_LoadModel_asm486(model_t *mod, qboolean crash);
#if defined(BENCH486) && defined(ASM486_ALIAS_MODEL_LOAD_FIXTURE)
model_t *Mod_LoadModel_C(model_t *mod, qboolean crash);
void *Bench486AliasLoadCacheCheck(cache_user_t *cache);
byte *Bench486AliasLoadStackFile(char *path, void *buffer, int bufsize);
void Bench486AliasLoadFileBase(char *in, char *out);
void Bench486AliasLoadAliasModel(model_t *mod, void *buffer);
void Bench486AliasLoadSpriteModel(model_t *mod, void *buffer);
void Bench486AliasLoadBrushModel(model_t *mod, void *buffer);
void Bench486AliasLoadError(char *format, ...);
#endif
#if defined(BENCH486) && defined(ASM486_ALIAS_CONTROL) && \
	defined(ASM486_SCREEN_CENTER_STRING)
void Mod_LoadModelTrace_asm486(int phase, int x, int y, int character);
#endif
#endif
#endif
