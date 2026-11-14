/* VBE 2.0 mode-info decoding, kept independent of BIOS calls for testing. */
#ifndef VID_VESA_H
#define VID_VESA_H

typedef struct {
	unsigned mode, attributes, width, height, pitch, pagesize, pages;
	unsigned physical, window, segment, linear;
} vesa_info_t;

static unsigned VESA_Word (const unsigned char *p)
{
	return p[0] | ((unsigned)p[1] << 8);
}

static int VESA_Decode (const unsigned char *b, unsigned memory,
	vesa_info_t *m)
{
	unsigned size, granularity;
	m->attributes = VESA_Word (b);
	m->width = VESA_Word (b + 18);
	m->height = VESA_Word (b + 20);
	m->pitch = VESA_Word (b + 16);
	if ((m->attributes & 0x19) != 0x19 || b[24] != 1 ||
		b[25] != 8 || b[27] != 4 ||
		m->width < 320 || m->width > MAXWIDTH || (m->width & 7) ||
		m->height < 200 || m->height > MAXHEIGHT || m->pitch < m->width)
		return 0;
	m->pagesize = m->pitch * m->height;
	if (m->pagesize > memory)
		return 0;
	m->physical = VESA_Word (b + 40) | (VESA_Word (b + 42) << 16);
	m->linear = (m->attributes & 0x80) && m->physical;
	m->pages = b[29] ? b[29] : 1; /* preserve existing page-count policy */
	if (m->pages > 3)
		m->pages = 3;
	if (m->pages > memory / m->pagesize)
		m->pages = memory / m->pagesize;
	if (m->width == 320 && m->height == 200)
		m->pages = 1;
	if (m->linear)
		return m->physical <= 0xffffffffU - m->pagesize * m->pages;
	/* Direct drawing reads the window as well as writing it. */
	m->window = 0;
	m->segment = VESA_Word (b + 8);
	if ((b[2] & 7) != 7 || !m->segment)
	{
		m->window = 1;
		m->segment = VESA_Word (b + 10);
		if ((b[3] & 7) != 7 || !m->segment)
			return 0;
	}
	size = VESA_Word (b + 6) * 1024;
	granularity = VESA_Word (b + 4) * 1024;
	return !(m->attributes & 0x40) && m->width == 320 && m->height == 200 &&
		granularity && granularity <= size && size <= 65536 &&
		m->pagesize <= size && (m->segment << 4) + size <= 0x100000;
}

/* Only collapse when both pitches exactly match the requested row width. */
static void VESA_CopyShape (int *width, int *height, int srcpitch, int dstpitch)
{
	if (*width == srcpitch && *width == dstpitch && *height > 0)
	{
		*width *= *height;
		*height = 1;
	}
}
#endif
