#include "const.h"
#include "global.h"
#include "kprintf.h"
#include "libcc.h"

void init()
{
	kprintf(KP_NORMAL,"kprintf test %x,%x,%s\n",100,1,"string");
	kprintf(KP_ALARM,"fire in the hole!!!");
  
	idt_install();
	pic_install();		
	timer_install(100);
	
	
	sti();
	task_install();
	while(1);
}

void initGDT()//切换GDT到内核GDT
{	
	struct DESCR 
	{
		bits16 length;
		bits32 address;
	} __attribute__((packed)) pgdt = {GDT_SIZE * sizeof(bits64) - 1, (bits32)&gdt};

	gdt[IDX_CODE_SEC]=0x00cf9a000000ffffULL;//代码段0-4G
	gdt[IDX_DATA_SEC]=0x00cf92000000ffffULL;//数据段0-4G
	
	__asm__ ("lgdt	%0\n\t"::"m"(pgdt));	
	
	__asm__ ("movw	$16,	%ax");//16=数据段
	__asm__ ("movw	%ax,	%ds");
	__asm__ ("movw	%ax,	%es");
	__asm__ ("movw	%ax,	%fs");
	__asm__ ("movw	%ax,	%gs");	
	__asm__ ("movw	%ax,	%ss");
	__asm__ ("movl	$0xa0000,	%esp");	
	
	__asm__ ("ljmp $0x8,$init");//GDT设置完毕 跳到初始化函数init还是执行
}