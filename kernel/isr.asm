%macro isrNoError 1
push	0
push	%1
jmp		isr_exception
%endmacro

%macro isrError 1
push	%1
jmp		isr_exception
%endmacro
extern exception_handler
extern timer_handler
[bits 32]
global do_timer
global isr
isr:
  dd divide_error,debug_exception,breakpoint,nmi
  dd overflow,bounds_check,invalid_opcode,cop_not_avalid
  dd double_fault,overrun,invalid_tss,seg_not_present
  dd stack_exception,general_protection,page_fault,reversed00
  dd coprocessor_error,reversed01,reversed02,reversed03
  dd reversed04,reversed05,reversed06,reversed07
  dd reversed08,reversed09,reversed0a,reversed0b
  dd reversed0c,reversed0d,reversed0e

isr_exception:
	;堆栈中已经存在： 
	;push eflags ;push cs;push eip;push errorcode or 0;push %1
  push esp
  push ss
  push eax
  push ebx
  push ecx
  push edx
  call exception_handler
  hlt
  
divide_error:         isrNoError		0x00
debug_exception:      isrNoError		0x01
breakpoint:           isrNoError		0x02
nmi:                  isrNoError		0x03
overflow :            isrNoError		0x04
bounds_check :        isrNoError		0x05
invalid_opcode :      isrNoError		0x06		
cop_not_avalid :      isrNoError		0x07	
double_fault :        isrError		    0x08
overrun :             isrNoError		0x09
invalid_tss :         isrError		    0x0a
seg_not_present :     isrError		    0x0b
stack_exception :     isrError		    0x0c
general_protection :  isrError		    0x0d
page_fault :          isrError		    0x0e
reversed00:           isrNoError		0x0f
coprocessor_error :   isrError		    0x10
reversed01:           isrNoError		0x11
reversed02:           isrNoError		0x12
reversed03:           isrNoError		0x13
reversed04:           isrNoError		0x14
reversed05:           isrNoError		0x15
reversed06:           isrNoError		0x16
reversed07:           isrNoError		0x17
reversed08:           isrNoError		0x19
reversed09:           isrNoError		0x1a
reversed0a:           isrNoError		0x1b
reversed0b:           isrNoError		0x1c
reversed0c:           isrNoError		0x1d
reversed0d:           isrNoError		0x1e
reversed0e:           isrNoError		0x1f
  
do_timer:;堆栈中已存在： push eflags;push cs;push eip;异常或者中断发生时CPU自动压入的数据
	mov eax,0
	mov eax,0
	mov eax,0
	mov eax,0
	mov eax,0
	mov eax,0
	mov eax,0
	mov eax,0
	mov eax,0
	mov eax,0

  call timer_handler;奇怪的是它会自己清理堆栈，这么神奇。。。。。
  ;add esp,4 《自己动手编写操作系统》书上是错误的 堆栈ret指令会自己清理。
  ;call指令（长CALL压入push cs;push eip; 短CALL直接push eip;) 而ret会自动弹出堆栈 所以不用手动清理。
  iret