
#define	EXTERN extern

#define outb(value, port) __asm__ (	\
"outb	%%al,	%%dx\n\t"::"al"(value), "dx"(port))

#define inb(port) (__extension__({	\
unsigned char __res;	\
__asm__ ("inb	%%dx,	%%al\n\t"	\
					 :"=a"(__res)	\
					 :"dx"(port));	\
__res;	\
}))

#define cli() __asm__ ("cli\n\t")
#define sti() __asm__ ("sti\n\t")

typedef unsigned long long bits64;
typedef unsigned int  bits32;
typedef unsigned short  bits16;
typedef unsigned char bits8;

#define GDT_SIZE 5
#define IDT_SIZE 256

#define IDX_CODE_SEC	1
#define IDX_DATA_SEC	2
#define IDX_TSS_SEC		3
#define IDX_LDT_SEC		4



#define KP_NORMAL (0<<4)|7
#define KP_ALARM  (7<<4)|0
