#include "const.h"
#include "global.h"
#include "kprintf.h"

void set_cursor(int x, int y) 
{
	csr_x = x;
	csr_y = y;
	outb(0x0e, 0x3d4);
	outb(((csr_x+csr_y*MAX_COLUMNS)>>8)&0xff, 0x3d5);
	outb(0x0f, 0x3d4);
	outb(((csr_x+csr_y*MAX_COLUMNS))&0xff, 0x3d5);
}

void pchar(char c,char attr)
{
	char *p; 
	p = (char *)VIDEO_RAM+CHAR_OFF(csr_x, csr_y);
	
	switch (c) 
	{
	case '\n':
		for (; csr_x<MAX_COLUMNS; ++csr_x) {*(p++) = BLANK_CHAR;*(p++) = attr;}
		break;
	case '\t':
		c = csr_x+TAB_WIDTH-(csr_x&(TAB_WIDTH-1));
		c = c<MAX_COLUMNS?c:MAX_COLUMNS;
		for (; csr_x<c; ++csr_x) {*p++ = BLANK_CHAR;*p++ = attr;}
		break;
	default:
		
		*(p++) = c;		
		*(p++) = attr;
		++csr_x;
		break;
	}
	
	if (csr_x >= MAX_COLUMNS) 
	{
		csr_x = 0;
		if (csr_y < MAX_LINES-1)
			++csr_y;
		else 
			csr_y = 0;
	}
	set_cursor(csr_x, csr_y);
}
void phex(unsigned int value,char attr) 
{
  int i;
  char c;
  char s=0;
  pchar( '0',attr);pchar( 'x',attr);
  for(i=7;i>=0;i--)
  {
    c="01234567890abcdef"[(value>>(i*4))&0xf];
    if(c!='0')
      s=1;
    if(s==1)    pchar(c,attr);
  }
  if(s==0) pchar('0',attr);
}

void pstring(char *s,char attr)
{
	while(*s)
		pchar(*s++,attr);
}

void kprintf(char attr,char *fmt, ...)
{
  bits32 *args=(bits32 *)(&fmt);
  unsigned int test=1;
	while(*fmt)
	{
		if(*fmt=='%')
		{
      switch(*(++fmt))
      {
      case 'x':  
        phex((bits32)(*(++args)),attr);      
        break;
      case 's':  
        pstring((char *)(*(++args)),attr);      
        break;
      default:
        break;
      }
      ++fmt;
		}
		else
		{
			pchar(*fmt,attr);
			++fmt;
		}
	}
}