#include "const.h"
#include "global.h"
#include "kprintf.h"
#include "task.h"
#include "libcc.h"

bits32 TASK0_STACK[256] = {0xf};

TASK 	TASK_0={
				{0,//back_link;
				(bits32)&TASK0_STACK+sizeof TASK0_STACK,16,//esp0, ss0;
				0,0,//esp1, ss1;
				0,0,//esp2, ss2;
				0,//cr3;
				((bits32)Task_0_Code),//eip;
				0,//eflags;
				0,0,0,0,//eax,ecx,edx,ebx;
				0,0,//esp, ebp;
				0,0,//esi, edi;
				16,8,16,16,16,16,//es, cs, ss, ds, fs, gs;
				IDX_LDT_SEC * 8,//ldt;
				0//trace_bitmap;
				},
				0,//bits64 	tss_entry;
				{0x00cffa000000ffffULL,0x00cff2000000ffffULL},//bits64	ldt[2];
				0,//bits64	ldt_entry;
				0,//int 	proc_id;//����ID
				PROC_STOPPED,//int 	state;//����״̬ PROC_RUNNING | PROC_RUNABLE | PROC_STOPPED
				0,//int 	priority;//�������ȼ�
				{"task 0"},//char 	proc_name[16];//������
				0//struct task_struct *next;
			   };

TASK*	task_head=&TASK_0;

void Task_0_Code(void)
{
	char wheel[] = {'\\', '|', '/', '-'};
	int i = 0;
	while(1)
	{
    __asm__ ("movb	%%al,	0xb8000+160*24"::"a"(wheel[i]));
		if (i == sizeof wheel)
			i = 0;
		else
			++i;
	}
}

void task_install(void)
{
	set_tss((bits64)(&(TASK_0.tss)));       // ������0��������
    set_ldt((bits64)(&(TASK_0.ldt)));
    __asm__ ("ltrw    %%ax\n\t"::"a"(24));    // ��������0ʹ�õ�TR��LDTR�Ĵ���
    __asm__ ("lldt    %%ax\n\t"::"a"(32));    // ʹ��ltrw��lldtָ��
    
    __asm__ __volatile__("movl 	%%esp,%%eax	\n\t" 
             "pushl %%ecx		\n\t"          // ss
             "pushl %%eax		\n\t"          // esp0
             "pushfl			\n\t"               // eflags
             "pushl %%ebx		\n\t"          // cs
             "pushl $0x30905	\n\t"       // eip
             "iret				\n"
             ::"b"(8),"c"(16));
    //__asm__ __volatile__("ljmp    $0x18,    $0\n\t");
}

bits64 set_tss(bits64 tss)
{
	bits64 tss_entry = 0x0080890000000067ULL;
	tss_entry |= ((tss)<<16) & 0xffffff0000ULL;                // ����ַ��24λ
    tss_entry |= ((tss)<<32) & 0xff00000000000000ULL;   // ����ַ��8λ
    return gdt[IDX_TSS_SEC] = tss_entry;
}

bits64 set_ldt(bits64 ldt)
{
    bits64 ldt_entry = 0x008082000000000fULL; //0x008082000000000fULL;        // DPL ��3������0
    ldt_entry |= ((ldt)<<16) & 0xffffff0000ULL;
    ldt_entry |= ((ldt)<<32) & 0xff00000000000000ULL;
    return gdt[IDX_LDT_SEC] = ldt_entry;
}

bits64 get_tss(void)
{
	return gdt[IDX_TSS_SEC];
}

bits64 get_ldt(void)
{
	return gdt[IDX_LDT_SEC];
}
