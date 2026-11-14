#ifndef ASM_VESAPALETTE_H
#define ASM_VESAPALETTE_H

#define VP_PALETTE_ENTRIES 256
#define VP_SOURCE_BYTES (VP_PALETTE_ENTRIES * 3)
#define VP_DESTINATION_BYTES (VP_PALETTE_ENTRIES * 4)

#ifndef __ASSEMBLER__
void VID_BuildVESAPalette_C (byte *dest, const byte *source);
void VID_BuildVESAPalette_asm486 (byte *dest, const byte *source);

#if defined(BENCH486) && defined(ASM486_VESA_PALETTE_FIXTURE)
unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *return_value);
#endif
#endif

#endif
