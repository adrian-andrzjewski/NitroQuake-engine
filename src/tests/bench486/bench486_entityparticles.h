/* Exact C-oracle versus i486 state/RNG coverage for R_EntityParticles. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_ENTITYPARTICLES_H
#define BENCH486_ENTITYPARTICLES_H

#ifdef ASM486_ENTITY_PARTICLES

#include <limits.h>
#include <stddef.h>
#include <stdlib.h>

#define EP_NORMAL_COUNT 162
#define EP_RANDOM_PATTERN_COUNT 41
#define EP_GUARD_WORDS 8
#define EP_FREE_BASE 1
#define EP_FREE_MAX EP_NORMAL_COUNT
#define EP_ACTIVE_HEAD (EP_FREE_BASE + EP_FREE_MAX)
#define EP_ACTIVE_TAIL (EP_ACTIVE_HEAD + 1)
#define EP_NODE_COUNT (EP_ACTIVE_TAIL + 1)
#define EP_CALL_COUNT 3

extern particle_t *active_particles, *free_particles;
extern vec3_t avelocities[EP_NORMAL_COUNT];
extern float r_avertexnormals[EP_NORMAL_COUNT][3];
extern float beamlength;
extern client_state_t cl;
extern int (*bench486_entityparticles_rand_probe) (void);
extern unsigned bench486_entityparticles_rand_calls;
extern void Bench486EntityParticlesResetState (void);
extern void R_EntityParticles_C (entity_t *ent);
extern void R_EntityParticles_asm486 (entity_t *ent);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
        const unsigned *arguments, float *float_return);

typedef char bench486_entityparticles_pointer32[
        (sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
        1 : -1];
typedef char bench486_entityparticles_particle_layout[
        (offsetof(particle_t, org) == 0 &&
        offsetof(particle_t, color) == 12 &&
        offsetof(particle_t, type) == 13 &&
        offsetof(particle_t, next) == 16 &&
        offsetof(particle_t, vel) == 20 &&
        offsetof(particle_t, ramp) == 32 &&
        offsetof(particle_t, die) == 36 && sizeof(particle_t) == 40 &&
        offsetof(client_state_t, time) == 572 &&
        sizeof(((client_state_t *)0)->time) == 8 && pt_explode == 4) ?
        1 : -1];

typedef struct
{
        unsigned before[EP_GUARD_WORDS];
        particle_t nodes[EP_NODE_COUNT];
        unsigned after[EP_GUARD_WORDS];
} bench486_entityparticles_fixture_t;

typedef struct
{
        unsigned before[EP_GUARD_WORDS];
        entity_t value;
        unsigned after[EP_GUARD_WORDS];
} bench486_entityparticles_entity_guard_t;

typedef struct
{
        const char *name;
        int free_count[EP_CALL_COUNT];
        double base_time;
        float beam_length;
        unsigned seed;
        unsigned script_start;
        qboolean scripted;
} bench486_entityparticles_case_t;

typedef struct
{
        byte fixture[EP_CALL_COUNT][sizeof(bench486_entityparticles_fixture_t)];
        byte velocity_table[sizeof(avelocities)];
        particle_t *active[EP_CALL_COUNT];
        particle_t *free[EP_CALL_COUNT];
        unsigned abi[EP_CALL_COUNT];
        unsigned rand_calls[EP_CALL_COUNT];
        unsigned script_index[EP_CALL_COUNT];
        int next_random[EP_CALL_COUNT];
        int valid[EP_CALL_COUNT];
        int state_reason[EP_CALL_COUNT];
} bench486_entityparticles_result_t;

static bench486_entityparticles_fixture_t bench486_entityparticles_fixture;
static bench486_entityparticles_entity_guard_t
        bench486_entityparticles_entity_guard;
static byte bench486_entityparticles_entity_before[
        sizeof(bench486_entityparticles_entity_guard_t)];
static bench486_entityparticles_result_t bench486_entityparticles_c_result;
static bench486_entityparticles_result_t bench486_entityparticles_asm_result;
static unsigned bench486_entityparticles_script_index;
static int bench486_entityparticles_state_reason;

/* Low-byte-distinct values make initialization order and all 486 calls visible. */
static const int bench486_entityparticles_script[EP_RANDOM_PATTERN_COUNT] =
{
        0, 1, 2, 3, 4, 5, 7, 8, 15, 16, 31, 32, 63, 64, 127, 128, 129,
        191, 192, 254, 255, -1, -2, -3, -7, -8, -15, -16, -31, -32,
        -63, -64, -127, -128, -191, -192, -254, -255, INT_MIN, INT_MAX, 42
};

static int Bench486EntityParticlesScript (void)
{
        unsigned index;

        index = bench486_entityparticles_script_index %
                EP_RANDOM_PATTERN_COUNT;
        bench486_entityparticles_script_index++;
        return bench486_entityparticles_script[index];
}

static int Bench486EntityParticlesScriptPeek (void)
{
        return bench486_entityparticles_script[
                bench486_entityparticles_script_index %
                EP_RANDOM_PATTERN_COUNT];
}

static double Bench486EntityParticlesTime (
        const bench486_entityparticles_case_t *test, int call_index)
{
        return test->base_time + (double)call_index * 0.125;
}

static void Bench486EntityParticlesPrepare (int free_count,
        const float *origin)
{
        int i;

        Q_memset (&bench486_entityparticles_fixture, 0x5a,
                sizeof(bench486_entityparticles_fixture));
        for (i = 0 ; i < EP_GUARD_WORDS ; i++)
        {
                bench486_entityparticles_fixture.before[i] = 0x5a5a5a5aU;
                bench486_entityparticles_fixture.after[i] = 0xa5a5a5a5U;
        }
        bench486_entityparticles_fixture.nodes[EP_ACTIVE_HEAD].next =
                &bench486_entityparticles_fixture.nodes[EP_ACTIVE_TAIL];
        bench486_entityparticles_fixture.nodes[EP_ACTIVE_TAIL].next = NULL;
        for (i = 0 ; i < free_count ; i++)
                bench486_entityparticles_fixture.nodes[EP_FREE_BASE+i].next =
                        i+1 < free_count ?
                        &bench486_entityparticles_fixture.nodes[EP_FREE_BASE+i+1] :
                        NULL;

        active_particles =
                &bench486_entityparticles_fixture.nodes[EP_ACTIVE_HEAD];
        free_particles = free_count ?
                &bench486_entityparticles_fixture.nodes[EP_FREE_BASE] : NULL;

        Q_memset (&bench486_entityparticles_entity_guard, 0x3c,
                sizeof(bench486_entityparticles_entity_guard));
        for (i = 0 ; i < EP_GUARD_WORDS ; i++)
        {
                bench486_entityparticles_entity_guard.before[i] = 0x3c3c3c3cU;
                bench486_entityparticles_entity_guard.after[i] = 0xc3c3c3c3U;
        }
        bench486_entityparticles_entity_guard.value.origin[0] = origin[0];
        bench486_entityparticles_entity_guard.value.origin[1] = origin[1];
        bench486_entityparticles_entity_guard.value.origin[2] = origin[2];
        Q_memcpy (bench486_entityparticles_entity_before,
                &bench486_entityparticles_entity_guard,
                sizeof(bench486_entityparticles_entity_guard));
}

static int Bench486EntityParticlesBytesAre (const byte *bytes, unsigned count,
        byte value)
{
        unsigned i;

        for (i = 0 ; i < count ; i++)
                if (bytes[i] != value)
                        return 0;
        return 1;
}

static int Bench486EntityParticlesParticlePaddingValid (const particle_t *p)
{
        const byte *bytes;

        bytes = (const byte *)p;
        return Bench486EntityParticlesBytesAre (bytes + 14, 2, 0x5a) &&
                Bench486EntityParticlesBytesAre (bytes + 20, 12, 0x5a) &&
                Bench486EntityParticlesBytesAre (bytes + 32, 4, 0x5a);
}

static int Bench486EntityParticlesAvelocitiesValid (unsigned script_start)
{
        int i, axis, value;
        unsigned index;
        float expected;

        for (i = 0 ; i < EP_NORMAL_COUNT ; i++)
                for (axis = 0 ; axis < 3 ; axis++)
                {
                        index = (script_start + (unsigned)(i * 3 + axis)) %
                                EP_RANDOM_PATTERN_COUNT;
                        value = bench486_entityparticles_script[index];
                        expected = (float)((value & 255) * 0.01);
                        if (Q_memcmp (&avelocities[i][axis], &expected,
                                sizeof(expected)) != 0)
                        {
                                bench486_entityparticles_state_reason = 1;
                                return 0;
                        }
                }
        return 1;
}

static int Bench486EntityParticlesStateValid (
        const bench486_entityparticles_case_t *test, int call_index,
        double expected_time)
{
        int i, emitted;
        particle_t *expected_active, *expected_free;
        float time, expected_die;
        const particle_t *head, *tail;

        emitted = test->free_count[call_index] < EP_NORMAL_COUNT ?
                test->free_count[call_index] : EP_NORMAL_COUNT;
        expected_active = emitted ?
                &bench486_entityparticles_fixture.nodes[
                        EP_FREE_BASE+emitted-1] :
                &bench486_entityparticles_fixture.nodes[EP_ACTIVE_HEAD];
        expected_free = test->free_count[call_index] > emitted ?
                &bench486_entityparticles_fixture.nodes[EP_FREE_BASE+emitted] :
                NULL;
        head = &bench486_entityparticles_fixture.nodes[EP_ACTIVE_HEAD];
        tail = &bench486_entityparticles_fixture.nodes[EP_ACTIVE_TAIL];
        if (free_particles != expected_free || active_particles != expected_active ||
                head->next != &bench486_entityparticles_fixture.nodes[EP_ACTIVE_TAIL] ||
                tail->next != NULL)
        {
                bench486_entityparticles_state_reason = 2;
                return 0;
        }

        if (!Bench486EntityParticlesBytesAre ((const byte *)head, 16, 0x5a) ||
                !Bench486EntityParticlesBytesAre ((const byte *)head + 20, 20, 0x5a) ||
                !Bench486EntityParticlesBytesAre ((const byte *)tail, 16, 0x5a) ||
                !Bench486EntityParticlesBytesAre ((const byte *)tail + 20, 20, 0x5a))
        {
                bench486_entityparticles_state_reason = 3;
                return 0;
        }

        time = (float)expected_time;
        expected_die = time + 0.01;
        for (i = 0 ; i < emitted ; i++)
        {
                const particle_t *particle, *expected_next;

                particle = &bench486_entityparticles_fixture.nodes[EP_FREE_BASE+i];
                expected_next = i ?
                        &bench486_entityparticles_fixture.nodes[EP_FREE_BASE+i-1] :
                        &bench486_entityparticles_fixture.nodes[EP_ACTIVE_HEAD];
                if (particle->next != expected_next ||
                        particle->type != pt_explode || particle->color != 0x6f ||
                        Q_memcmp ((void *)&particle->die, &expected_die,
                                sizeof(expected_die)) != 0 ||
                        !Bench486EntityParticlesParticlePaddingValid (particle))
                {
                        bench486_entityparticles_state_reason = 4;
                        return 0;
                }
        }

        for (i = emitted ; i < test->free_count[call_index] ; i++)
        {
                const particle_t *particle, *expected_next;

                particle = &bench486_entityparticles_fixture.nodes[EP_FREE_BASE+i];
                expected_next = i+1 < test->free_count[call_index] ?
                        &bench486_entityparticles_fixture.nodes[EP_FREE_BASE+i+1] :
                        NULL;
                if (particle->next != expected_next ||
                        !Bench486EntityParticlesBytesAre ((const byte *)particle,
                                16, 0x5a) ||
                        !Bench486EntityParticlesBytesAre ((const byte *)particle + 20,
                                20, 0x5a))
                {
                        bench486_entityparticles_state_reason = 5;
                        return 0;
                }
        }

        for (i = 0 ; i < EP_GUARD_WORDS ; i++)
                if (bench486_entityparticles_fixture.before[i] != 0x5a5a5a5aU ||
                        bench486_entityparticles_fixture.after[i] != 0xa5a5a5a5U ||
                        bench486_entityparticles_entity_guard.before[i] != 0x3c3c3c3cU ||
                        bench486_entityparticles_entity_guard.after[i] != 0xc3c3c3c3U)
                {
                        bench486_entityparticles_state_reason = 6;
                        return 0;
                }

        if (Q_memcmp (&bench486_entityparticles_entity_guard,
                bench486_entityparticles_entity_before,
                sizeof(bench486_entityparticles_entity_guard)) != 0 ||
                Q_memcmp (&cl.time, &expected_time, sizeof(expected_time)) != 0)
        {
                bench486_entityparticles_state_reason = 7;
                return 0;
        }

        bench486_entityparticles_state_reason = 0;
        return 1;
}

static unsigned Bench486EntityParticlesCall (void (*function)(void),
        entity_t *ent)
{
        unsigned arguments[1];

        arguments[0] = (unsigned)(size_t)ent;
        return Bench486Call_asm486 (function, 1, arguments, NULL);
}

static int Bench486EntityParticlesRandomContinuation (int scripted)
{
        if (scripted)
                return Bench486EntityParticlesScriptPeek ();
        return rand ();
}

static void Bench486EntityParticlesRunSide (void (*function)(void),
        const bench486_entityparticles_case_t *test,
        bench486_entityparticles_result_t *result)
{
        static const float origins[EP_CALL_COUNT][3] = {
                { -123.25f, 8.5f, 1024.75f },
                { 0.125f, -4096.5f, 31.75f },
                { 3.0e+30f, -2.0e+30f, -4.0e+30f }
        };
        particle_t *saved_active, *saved_free;
        double saved_time, call_time;
        float saved_beamlength;
        int (*saved_probe) (void);
        unsigned saved_rand_calls, saved_script_index;
        unsigned abi, phase;
        int valid;

        saved_active = active_particles;
        saved_free = free_particles;
        Q_memcpy (&saved_time, &cl.time, sizeof(saved_time));
        saved_beamlength = beamlength;
        saved_probe = bench486_entityparticles_rand_probe;
        saved_rand_calls = bench486_entityparticles_rand_calls;
        saved_script_index = bench486_entityparticles_script_index;

        Q_memset (result, 0, sizeof(*result));
        Bench486EntityParticlesResetState ();
        bench486_entityparticles_rand_probe = test->scripted ?
                Bench486EntityParticlesScript : NULL;
        bench486_entityparticles_rand_calls = 0;
        bench486_entityparticles_script_index = test->script_start;
        srand (test->seed);
        beamlength = test->beam_length;

        for (phase = 0 ; phase < EP_CALL_COUNT ; phase++)
        {
                call_time = Bench486EntityParticlesTime (test, (int)phase);
                cl.time = call_time;
                Bench486EntityParticlesPrepare (test->free_count[phase],
                        origins[phase]);
                bench486_entityparticles_state_reason = 0;
                abi = Bench486EntityParticlesCall (function,
                        &bench486_entityparticles_entity_guard.value);
                result->abi[phase] = abi;
                result->rand_calls[phase] =
                        bench486_entityparticles_rand_calls;
                result->script_index[phase] =
                        bench486_entityparticles_script_index;
                result->next_random[phase] =
                        Bench486EntityParticlesRandomContinuation (test->scripted);
                result->active[phase] = active_particles;
                result->free[phase] = free_particles;
                valid = Bench486EntityParticlesStateValid (test, (int)phase,
                        call_time);
                if (phase == 0)
                {
                        Q_memcpy (result->velocity_table, avelocities,
                                sizeof(avelocities));
                        if (test->scripted)
                                valid = valid &&
                                        Bench486EntityParticlesAvelocitiesValid (
                                                test->script_start);
                }
                else if (Q_memcmp (result->velocity_table, avelocities,
                        sizeof(avelocities)) != 0)
                {
                        bench486_entityparticles_state_reason = 8;
                        valid = 0;
                }
                if (result->rand_calls[phase] != EP_NORMAL_COUNT * 3 ||
                        (test->scripted && result->script_index[phase] !=
                                test->script_start + EP_NORMAL_COUNT * 3))
                {
                        bench486_entityparticles_state_reason = 9;
                        valid = 0;
                }
                result->valid[phase] = valid;
                result->state_reason[phase] =
                        bench486_entityparticles_state_reason;
                Q_memcpy (result->fixture[phase],
                        &bench486_entityparticles_fixture,
                        sizeof(bench486_entityparticles_fixture));
        }

        Bench486EntityParticlesResetState ();
        active_particles = saved_active;
        free_particles = saved_free;
        Q_memcpy (&cl.time, &saved_time, sizeof(saved_time));
        beamlength = saved_beamlength;
        bench486_entityparticles_rand_probe = saved_probe;
        bench486_entityparticles_rand_calls = saved_rand_calls;
        bench486_entityparticles_script_index = saved_script_index;
}

static void Bench486EntityParticlesCases (void)
{
        /* The unhooked case intentionally advances libc rand; run this direct
         * fixture in the disposable BENCH486 process. Bench486Call_asm486
         * checks stack balance and callee-saved registers for every call. */
        static const bench486_entityparticles_case_t cases[] = {
                { "cold-empty-warm-empty-single", { 0, 0, 1 },
                        31.125, 16.0f, 0x486e0001U, 3, 1 },
                { "cold-single-warm-partial-full", { 1, 37, 162 },
                        33.625, 16.0f, 0x486e0002U, 14, 1 },
                { "cold-partial-warm-full-empty", { 37, 162, 0 },
                        35.875, 16.0f, 0x486e0003U, 27, 1 },
                { "cold-full-warm-single-partial", { 162, 1, 37 },
                        37.250, 16.0f, 0x486e0004U, 40, 1 },
                { "libc-rng-full-and-repeat", { 162, 162, 0 },
                        39.500, 16.0f, 0x486e0005U, 0, 0 },
                { "negative-time-wide-beam", { 162, 37, 0 },
                        -8192.5, -256.0f, 0x486e0006U, 52, 1 },
                { "large-time-and-coordinate", { 37, 1, 162 },
                        1.0e+20, 4096.0f, 0x486e0007U, 0, 1 }
        };
        particle_t *saved_active, *saved_free;
        double saved_time;
        int (*saved_probe) (void);
        unsigned saved_rand_calls, saved_script_index;
        int i, phase, failures, equal;

        saved_active = active_particles;
        saved_free = free_particles;
        Q_memcpy (&saved_time, &cl.time, sizeof(saved_time));
        saved_probe = bench486_entityparticles_rand_probe;
        saved_rand_calls = bench486_entityparticles_rand_calls;
        saved_script_index = bench486_entityparticles_script_index;
        failures = 0;
        Bench486Printf ("entity-particles C/ASM begin (%d cases, cold plus two warm calls)\n",
                (int)(sizeof(cases)/sizeof(cases[0])));

        for (i = 0 ; i < (int)(sizeof(cases)/sizeof(cases[0])) ; i++)
        {
                Bench486Printf ("entity-particles %d/%d %s\n", i+1,
                        (int)(sizeof(cases)/sizeof(cases[0])), cases[i].name);
                Bench486EntityParticlesRunSide (
                        (void (*)(void))R_EntityParticles_C, &cases[i],
                        &bench486_entityparticles_c_result);
                Bench486EntityParticlesRunSide (
                        (void (*)(void))R_EntityParticles_asm486, &cases[i],
                        &bench486_entityparticles_asm_result);

                for (phase = 0 ; phase < EP_CALL_COUNT ; phase++)
                {
                        equal = bench486_entityparticles_c_result.abi[phase] == 0 &&
                                bench486_entityparticles_asm_result.abi[phase] == 0 &&
                                bench486_entityparticles_c_result.valid[phase] &&
                                bench486_entityparticles_asm_result.valid[phase] &&
                                bench486_entityparticles_c_result.rand_calls[phase] ==
                                        EP_NORMAL_COUNT * 3 &&
                                bench486_entityparticles_asm_result.rand_calls[phase] ==
                                        EP_NORMAL_COUNT * 3 &&
                                bench486_entityparticles_c_result.script_index[phase] ==
                                        bench486_entityparticles_asm_result.script_index[phase] &&
                                bench486_entityparticles_c_result.next_random[phase] ==
                                        bench486_entityparticles_asm_result.next_random[phase] &&
                                bench486_entityparticles_c_result.active[phase] ==
                                        bench486_entityparticles_asm_result.active[phase] &&
                                bench486_entityparticles_c_result.free[phase] ==
                                        bench486_entityparticles_asm_result.free[phase] &&
                                Q_memcmp (
                                        bench486_entityparticles_c_result.fixture[phase],
                                        bench486_entityparticles_asm_result.fixture[phase],
                                        sizeof(bench486_entityparticles_fixture)) == 0;
                        if (!equal)
                        {
                                failures++;
                                Bench486Printf (
                                        "entity-particles %s call %d FAIL abi %u/%u valid %d(%d)/%d(%d) rng %u/%u next %d/%d\n",
                                        cases[i].name, phase+1,
                                        bench486_entityparticles_c_result.abi[phase],
                                        bench486_entityparticles_asm_result.abi[phase],
                                        bench486_entityparticles_c_result.valid[phase],
                                        bench486_entityparticles_c_result.state_reason[phase],
                                        bench486_entityparticles_asm_result.valid[phase],
                                        bench486_entityparticles_asm_result.state_reason[phase],
                                        bench486_entityparticles_c_result.rand_calls[phase],
                                        bench486_entityparticles_asm_result.rand_calls[phase],
                                        bench486_entityparticles_c_result.next_random[phase],
                                        bench486_entityparticles_asm_result.next_random[phase]);
                        }
                        else
                                Bench486Printf (
                                        "entity-particles %s call %d PASS (%d free nodes, %u initialization RNG calls)\n",
                                        cases[i].name, phase+1,
                                        cases[i].free_count[phase],
                                        bench486_entityparticles_c_result.rand_calls[phase]);
                }

                if (Q_memcmp (bench486_entityparticles_c_result.velocity_table,
                        bench486_entityparticles_asm_result.velocity_table,
                        sizeof(avelocities)) != 0)
                {
                        failures++;
                        Bench486Printf ("entity-particles %s FAIL avelocity table differs\n",
                                cases[i].name);
                }
        }

        active_particles = saved_active;
        free_particles = saved_free;
        Q_memcpy (&cl.time, &saved_time, sizeof(saved_time));
        bench486_entityparticles_rand_probe = saved_probe;
        bench486_entityparticles_rand_calls = saved_rand_calls;
        bench486_entityparticles_script_index = saved_script_index;
        bench486_memory_failures += failures;
        Bench486Printf ("entity-particles C/ASM exact state and RNG continuation %s (%d failures)\n",
                failures ? "FAIL" : "PASS", failures);
}

#endif /* ASM486_ENTITY_PARTICLES */
#endif /* BENCH486_ENTITYPARTICLES_H */
