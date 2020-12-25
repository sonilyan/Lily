#define MAX_LINES	25
#define MAX_COLUMNS	80
#define TAB_WIDTH	8			/* must be power of 2 */

/* color text mode, the video ram starts from 0xb8000,
   we all have color text mode, right? :) */
#define VIDEO_RAM	0xb8000

#define LINE_RAM	(MAX_COLUMNS*2)

#define PAGE_RAM	(MAX_LINE*MAX_COLUMNS)

#define BLANK_CHAR	(' ')
#define BLANK_ATTR	(0x70)		/* white fg, black bg */

#define CHAR_OFF(x,y)	(LINE_RAM*(y)+2*(x))

void pchar(char c,char attr);
void phex(unsigned int value,char attr);
void pstring(char *s,char attr);

void kprintf(char attr,char *fmt, ...);
void set_cursor(int x, int y);