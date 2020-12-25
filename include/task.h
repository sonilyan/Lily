
struct tss_struct{
    bits32    back_link;
    bits32    esp0, ss0;
    bits32    esp1, ss1;
    bits32    esp2, ss2;
    bits32    cr3;
    bits32    eip;
    bits32    eflags;
    bits32    eax,ecx,edx,ebx;
    bits32    esp, ebp;
    bits32    esi, edi;
    bits32    es, cs, ss, ds, fs, gs;
    bits32    ldt;
    bits32    trace_bitmap;
};

#define PROC_RUNNING 0
#define PROC_RUNABLE 1
#define PROC_STOPPED 2

typedef struct task_struct{
	struct 	tss_struct tss;
	bits64 	tss_entry;	
	bits64	ldt[2];
	bits64	ldt_entry;
	
	int 	proc_id;//进程ID
	int 	state;//进程状态 PROC_RUNNING | PROC_RUNABLE | PROC_STOPPED
	int 	priority;//进程优先级
	char 	proc_name[16];//进程名
	
	struct task_struct *next;
}TASK;

void Task_0_Code(void);

	
	