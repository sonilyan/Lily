#include "const.h"
#include "global.h"
#include "kprintf.h"

extern int isr[]; 

void timer_handler(void);
void do_timer(void);

void pic_install(void) 
{
	outb(0x11, 0x20);
	outb(0x11, 0xa0);
	outb(0x20, 0x21);
	outb(0x28, 0xa1);
	outb(0x04, 0x21);
	outb(0x02, 0xa1);
	outb(0x01, 0x21);
	outb(0x01, 0xa1);
	outb(0xff, 0x21);
	outb(0xff, 0xa1);
}

void isr_entry(int index, bits64 offset) 
{
	bits64 idt_entry = 0x00008e0000000000ULL |	((bits64)(8)<<16);
	idt_entry |= (offset<<32) & 0xffff000000000000ULL;
	idt_entry |= (offset) & 0xffff;
	idt[index] = idt_entry;
}

void idt_install(void) 
{
	unsigned int i = 0;
	struct DESCR 
	{
		bits16 length;
		bits32 address;
	} __attribute__((packed)) idt_descr = {256*8-1, (bits32)idt};
	
	for (i=0; i<=0x1f; ++i)
		isr_entry(i, (bits32)(isr[i]));//安装异常处理
	
	isr_entry(0x20, (bits32)(do_timer));//安装定时器中断
	
	__asm__ ("lidt	%0\n\t"::"m"(idt_descr));
}

void exception_handler(int edx,
                        int ecx,
                        int ebx,
                        int eax,
                        int ss,
                        int esp,
                        int vec_no,
                        int err_code,
                        int eip,
                        int cs,
                        int eflags)
{
	int i;
	static const char *err_description[] = {
		"DIVIDE ERROR",
		"DEBUG EXCEPTION",
		"BREAK POINT",
		"NMI",
		"OVERFLOW",
		"BOUNDS CHECK",
		"INVALID OPCODE",
		"COPROCESSOR NOT VALID",
		"DOUBLE FAULT",
		"OVERRUN",
		"INVALID TSS",
		"SEGMENTATION NOT PRESENT",
		"STACK EXCEPTION",
		"GENERAL PROTECTION",
		"PAGE FAULT",
		"REVERSED",
		"COPROCESSOR_ERROR",
	};
	
	set_cursor(0,16);
  
	kprintf(KP_ALARM,"Exception(%x) --- %s\n",vec_no,err_description[vec_no]);
	kprintf(KP_ALARM,"EFLAGS\t:\t%x\nCS:EIP\t:\t%x:%x\nSS:ESP\t:\t%x:%x\n", eflags,cs,eip,ss,esp);
	kprintf(KP_ALARM,"eax\t:\t%x\nebx\t:\t%x\necx\t:\t%x\nedx\t:\t%x",eax,ebx,ecx,edx);
	
	if(err_code != 0)
		kprintf(KP_ALARM,"\nError code:%x\n", err_code);
	else
		kprintf(KP_ALARM,"\n\n", err_code);
}
//------------------------------------------------------------------------------------------------------------


unsigned int timer_ticks = 0;

void timer_handler(void) {
	int x , y;
	++timer_ticks;
	x=csr_x;
	y=csr_y;
	set_cursor(2, 24);
	kprintf(KP_NORMAL, "%x", timer_ticks);
	set_cursor(x, y);
	outb(0x20, 0x20);
}

void timer_install(int hz) {
	unsigned int divisor = 1193180/hz;
	outb(0x36, 0x43);
	outb(divisor&0xff, 0x40);
	outb(divisor>>8, 0x40);
	outb(inb(0x21)&0xfe, 0x21);
}

