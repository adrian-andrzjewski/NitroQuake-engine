/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#if defined(BENCH486) && defined(ASM486_ALIAS_MODEL_LOAD_FIXTURE)
#include <stdarg.h>
#include "assets/asm_modelload.h"

typedef struct
{
	model_t *model;
	int header;
	int missing;
	void *cache_result;
	void *stack_buffer;
	unsigned cache_calls;
	unsigned file_calls;
	unsigned base_calls;
	unsigned alias_calls;
	unsigned sprite_calls;
	unsigned brush_calls;
	unsigned error_calls;
	unsigned bad_calls;
	int loader_kind;
	char error_format[64];
	char error_model[MAX_QPATH];
} bench486_alias_load_state_t;

typedef struct
{
	model_t model;
	char loadname[32];
	int result_kind;
	int loadmodel_matches;
	unsigned cache_calls;
	unsigned file_calls;
	unsigned base_calls;
	unsigned alias_calls;
	unsigned sprite_calls;
	unsigned brush_calls;
	unsigned error_calls;
	unsigned bad_calls;
	int loader_kind;
	int stack_buffer_seen;
	char error_format[64];
	char error_model[MAX_QPATH];
} bench486_alias_load_snapshot_t;

static bench486_alias_load_state_t bench486_alias_load_state;
static model_t bench486_alias_load_model;
static byte bench486_alias_load_cache_data[16];

void *Bench486AliasLoadCacheCheck (cache_user_t *cache)
{
	if (cache != &bench486_alias_load_model.cache)
		bench486_alias_load_state.bad_calls++;
	bench486_alias_load_state.cache_calls++;
	return bench486_alias_load_state.cache_result;
}

byte *Bench486AliasLoadStackFile (char *path, void *buffer, int bufsize)
{
	bench486_alias_load_state.file_calls++;
	if (!path || path != bench486_alias_load_model.name ||
		!buffer || bufsize != 1024)
		bench486_alias_load_state.bad_calls++;
	bench486_alias_load_state.stack_buffer = buffer;
	if (bench486_alias_load_state.missing)
		return NULL;
	Q_memcpy (buffer, &bench486_alias_load_state.header,
				 sizeof (bench486_alias_load_state.header));
	return (byte *)buffer;
}

void Bench486AliasLoadFileBase (char *in, char *out)
{
	bench486_alias_load_state.base_calls++;
	if (!in || in != bench486_alias_load_model.name || !out)
		bench486_alias_load_state.bad_calls++;
	Q_memcpy (out, "fixture", 8);
}

static void Bench486AliasLoadRecordModel (model_t *mod, void *buffer,
										 int kind)
{
	if (mod != &bench486_alias_load_model ||
		buffer != bench486_alias_load_state.stack_buffer)
		bench486_alias_load_state.bad_calls++;
	bench486_alias_load_state.loader_kind = kind;
	if (kind == mod_alias)
	{
		bench486_alias_load_state.alias_calls++;
		mod->cache.data = bench486_alias_load_cache_data;
		mod->numframes = 7;
	}
	else if (kind == mod_sprite)
	{
		bench486_alias_load_state.sprite_calls++;
		mod->numframes = 3;
	}
	else
	{
		bench486_alias_load_state.brush_calls++;
		mod->numframes = 2;
	}
	mod->type = (modtype_t)kind;
}

void Bench486AliasLoadAliasModel (model_t *mod, void *buffer)
{
	Bench486AliasLoadRecordModel (mod, buffer, mod_alias);
}

void Bench486AliasLoadSpriteModel (model_t *mod, void *buffer)
{
	Bench486AliasLoadRecordModel (mod, buffer, mod_sprite);
}

void Bench486AliasLoadBrushModel (model_t *mod, void *buffer)
{
	Bench486AliasLoadRecordModel (mod, buffer, mod_brush);
}

void Bench486AliasLoadError (char *format, ...)
{
	va_list arguments;
	char *model_name;
	bench486_alias_load_state.error_calls++;
	va_start (arguments, format);
	model_name = va_arg (arguments, char *);
	va_end (arguments);
	Q_memcpy (bench486_alias_load_state.error_format, format,
				 Q_strlen (format) + 1);
	if (model_name)
		Q_memcpy (bench486_alias_load_state.error_model, model_name,
					 Q_strlen (model_name) + 1);
}

static void Bench486AliasLoadReset (int type, int needload, int header,
									int missing, void *cache_result)
{
	Q_memset (&bench486_alias_load_state, 0,
			  sizeof (bench486_alias_load_state));
	Q_memset (&bench486_alias_load_model, 0,
			  sizeof (bench486_alias_load_model));
	Q_memset (loadname, 0xa5, sizeof (loadname));
	Q_strcpy (bench486_alias_load_model.name, "models/fixture.mdl");
	bench486_alias_load_model.type = (modtype_t)type;
	bench486_alias_load_model.needload = needload;
	bench486_alias_load_model.cache.data = cache_result;
	bench486_alias_load_state.model = &bench486_alias_load_model;
	bench486_alias_load_state.header = header;
	bench486_alias_load_state.missing = missing;
	bench486_alias_load_state.cache_result = cache_result;
	loadmodel = NULL;
}

static void Bench486AliasLoadCapture (bench486_alias_load_snapshot_t *out,
									  model_t *result)
{
	Q_memset (out, 0, sizeof (*out));
	Q_memcpy (&out->model, &bench486_alias_load_model,
			  sizeof (out->model));
	Q_memcpy (out->loadname, loadname, sizeof (out->loadname));
	out->result_kind = (result == &bench486_alias_load_model) ? 1 :
					   (result == NULL) ? 0 : -1;
	out->loadmodel_matches = (loadmodel == &bench486_alias_load_model);
	out->cache_calls = bench486_alias_load_state.cache_calls;
	out->file_calls = bench486_alias_load_state.file_calls;
	out->base_calls = bench486_alias_load_state.base_calls;
	out->alias_calls = bench486_alias_load_state.alias_calls;
	out->sprite_calls = bench486_alias_load_state.sprite_calls;
	out->brush_calls = bench486_alias_load_state.brush_calls;
	out->error_calls = bench486_alias_load_state.error_calls;
	out->bad_calls = bench486_alias_load_state.bad_calls;
	out->loader_kind = bench486_alias_load_state.loader_kind;
	out->stack_buffer_seen =
		(bench486_alias_load_state.stack_buffer != NULL);
	Q_memcpy (out->error_format, bench486_alias_load_state.error_format,
			  sizeof (out->error_format));
	Q_memcpy (out->error_model, bench486_alias_load_state.error_model,
			  sizeof (out->error_model));
}

static void Bench486AliasLoadRun (int use_asm, int type, int needload,
								 int header, int missing, int crash,
								 void *cache_result,
								 bench486_alias_load_snapshot_t *snapshot)
{
	model_t *result;
	Bench486AliasLoadReset (type, needload, header, missing, cache_result);
	if (use_asm)
		result = Mod_LoadModel_asm486 (&bench486_alias_load_model, crash);
	else
		result = Mod_LoadModel_C (&bench486_alias_load_model, crash);
	Bench486AliasLoadCapture (snapshot, result);
}

static qboolean Bench486AliasLoadSnapshotsMatch (
									bench486_alias_load_snapshot_t *c,
									bench486_alias_load_snapshot_t *a)
{
	return Q_memcmp (c, a, sizeof (*c)) == 0;
}

static void Bench486AliasLoadCase (char *name, int type, int needload,
								 int header, int missing, int crash,
								 void *cache_result, int expected_kind,
								 unsigned expected_cache_calls,
								 unsigned expected_file_calls,
								 unsigned expected_base_calls,
								 unsigned expected_error_calls)
{
	bench486_alias_load_snapshot_t c, a;
	unsigned failures_before = (unsigned)bench486_memory_failures;
	Bench486AliasLoadRun (0, type, needload, header, missing, crash,
						 cache_result, &c);
	Bench486AliasLoadRun (1, type, needload, header, missing, crash,
						 cache_result, &a);
	if (!Bench486AliasLoadSnapshotsMatch (&c, &a) || c.bad_calls ||
		c.loader_kind != expected_kind ||
		((expected_kind != 0) && !c.loadmodel_matches) ||
		(c.result_kind != (missing ? 0 : 1)) ||
		(c.cache_calls != expected_cache_calls) ||
		(c.file_calls != expected_file_calls) ||
		(c.base_calls != expected_base_calls) ||
		(c.error_calls != expected_error_calls) ||
		(c.stack_buffer_seen != (expected_file_calls != 0)) ||
		(expected_error_calls &&
		 (Q_strcmp (c.error_format, "Mod_NumForName: %s not found") ||
		  Q_strcmp (c.error_model, bench486_alias_load_model.name))))
	{
		bench486_memory_failures++;
		Bench486ReportPrintf ("alias model load %s FAIL\n", name);
	}
	else
		Bench486ReportPrintf ("alias model load %s PASS\n", name);
	if ((unsigned)bench486_memory_failures != failures_before)
		Bench486ReportPrintf ("  c calls %u/%u/%u/%u, asm %u/%u/%u/%u\n",
					c.cache_calls, c.file_calls, c.base_calls, c.error_calls,
					a.cache_calls, a.file_calls, a.base_calls, a.error_calls);
}

static void Bench486AliasModelLoadCases (void)
{
	Bench486AliasLoadCase ("alias cache hit", mod_alias, 1, IDPOLYHEADER,
						 0, false, bench486_alias_load_cache_data, 0,
						 1, 0, 0, 0);
	Bench486AliasLoadCase ("alias cache miss", mod_alias, 1, IDPOLYHEADER,
						 0, false, NULL, mod_alias, 1, 1, 1, 0);
	Bench486AliasLoadCase ("sprite dispatch", mod_sprite, 1, IDSPRITEHEADER,
						 0, false, NULL, mod_sprite, 0, 1, 1, 0);
	Bench486AliasLoadCase ("brush fallback", mod_brush, 1, 0x12345678,
						 0, false, NULL, mod_brush, 0, 1, 1, 0);
	Bench486AliasLoadCase ("loaded brush fast path", mod_brush, 0,
						 IDPOLYHEADER, 0, false, NULL, 0, 0, 0, 0, 0);
	Bench486AliasLoadCase ("missing optional model", mod_alias, 1,
						 IDPOLYHEADER, 1, false, NULL, 0, 1, 1, 0, 0);
	Bench486AliasLoadCase ("missing required model", mod_alias, 1,
						 IDPOLYHEADER, 1, true, NULL, 0, 1, 1, 0, 1);
}
#endif
