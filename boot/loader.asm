%include	"Descriptor.inc"	; 有关于GDT的 【宏，常量】 定义
DA_32		  EQU	4000h	;
DA_DRW		EQU	92h	; 存在的可读写数据段属性值
DA_DRWA		EQU	93h	; 存在的已访问可读写数据段类型值
DA_C		  EQU	98h	; 存在的只执行代码段属性值
;--------------------------------------------------------------------------------------
PG_P		EQU	1	; 页存在属性位
PG_RWR		EQU	0	; R/W 属性位值, 读/执行
PG_RWW		EQU	10b	; R/W 属性位值, 读/写/执行
PG_USS		EQU	0	; U/S 属性位值, 系统级
PG_USU		EQU	100b	; U/S 属性位值, 用户级
;-----------------------------------------------------------------------------------------
    jmp label_begin

[section .gdt]
LABEL_GDT:                Descriptor 0, 0, 0                                                  ;空描述符
LABEL_GZC:                Descriptor    0,          0fffffh, 9Ah  | 4000h | 8000h			; 0 ~ 4G  C09Ah
LABEL_DESC_FLAT_RW:		    Descriptor    0,          0fffffh, 92h | 4000h | 8000h			; 0 ~ 4G  C092h
;===============================数据段描述符
LABEL_DATA_DESC:          Descriptor    0,          Datalen-1,            (DA_DRW  +  DA_32)    
LABEL_PAGE_DIR:           Descriptor 200000h,4095,DA_DRW
LABEL_PAGE_TABLE:         Descriptor 201000h,1023,DA_DRW | 8000h	
;===============================代码段描述符
LABEL_CODE32_DESC:        Descriptor    0,          code32descLen - 1,    (DA_32 + DA_C)
;===============================视频段描述符
LABEL_VIDEO_DESC:         Descriptor    0B8000h,    0ffffh,               DA_DRW    
;===============================堆栈描述符
LABEL_STACK_RING0_DESC:   Descriptor    0,          TopOfStackRing0,      DA_DRWA  +  DA_32
;--------------------------------------------
GdtLen               equ   $ - LABEL_GDT
GdtPtr               dw    GdtLen - 1       ;长度
                     dd    0                ; gdt 地址（4位，以后初始化）
     
;===============================堆栈选择子
Selector_Stack_Ring0      equ     LABEL_STACK_RING0_DESC - LABEL_GDT
;===============================数据段选择子
Selector_Data             equ     LABEL_DATA_DESC - LABEL_GDT  
Selector_PageDir          equ     LABEL_PAGE_DIR  - LABEL_GDT
Selector_PageTable        equ     LABEL_PAGE_TABLE -LABEL_GDT 
;===============================代码段选择子
Selector_Code32           equ     LABEL_CODE32_DESC - LABEL_GDT             ;选择子的第1，2位是RPL
Selector_gzc              equ     LABEL_GZC - LABEL_GDT
Selector_gzc222              equ     LABEL_DESC_FLAT_RW - LABEL_GDT
;===============================视频段选择子
Selector_Video            equ     LABEL_VIDEO_DESC - LABEL_GDT    
;[.gdt end]


[section .stack_ring0]
ALIGN	32
[bits 32]
LABEL_STACK_RING0:
times 1024 db 0
TopOfStackRing0 equ $ - LABEL_STACK_RING0 - 1
;[.stack1 end]--------------------------------------------------------------------------------

[section .data]
ALIGN	32
[bits 32]
DATA_BEGIN:
  _index_of_display dd (80*5+0)*2  
  _pmstring db "In Portect Mode Now!",0ah,0ah,0
  _mem_info_title db "BaseAdd_H BaseAdd_L Length__H Length__L   Type  ",0ah,0
  _memSizeInfo db "Memory Size: ",0
  _memSizeInfoEnd db " MB",0ah,0
  _memchkbuf times 512 db 0
  _dw_mem_number dd 0
  _szReturn db 0ah,0
  _MemSize dd 0
;-------------------------------------------------------
  memSizeInfoEnd equ _memSizeInfoEnd-$$
  memSizeInfo equ _memSizeInfo-$$
  MemSize equ _MemSize-$$
  szReturn equ _szReturn-$$
  pmstring equ _pmstring-$$  
  index_of_display equ _index_of_display-$$
  memchkbuf equ _memchkbuf-$$
  dw_mem_number equ _dw_mem_number-$$
  mem_info_title equ _mem_info_title-$$

Datalen equ $-DATA_BEGIN
;[.data end]--------------------------------------------------------------------------------


[section .s16]
[bits 16]
label_begin:
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,0100h    
    
    ;初始化堆栈
    initDescriptor LABEL_STACK_RING0_DESC,LABEL_STACK_RING0  
    ;初始化代码段
    initDescriptor LABEL_CODE32_DESC,CODE32_BEGIN    
    ;初始化数据段
    initDescriptor LABEL_DATA_DESC,DATA_BEGIN      
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;准备加载gdtr
    xor eax,eax
    mov ax,ds       ;降段值赋值给AX ---------数据区
    shl eax,4
    add eax,LABEL_GDT    
    mov dword [GdtPtr+2],eax   ;初始化GDT
;----------------------------------------------------------

    mov ebx,0
    mov di,_memchkbuf
.1:    
    mov ecx,20
    mov eax,0E820h
    mov edx,0534D4150h
    int 15h
    jc  .CHECKFAIL
    add di,20
    inc dword [_dw_mem_number]
    cmp ebx,0
    jne .1    
    jmp .CHECKOK
.CHECKFAIL:
    mov dword [_dw_mem_number],0
.CHECKOK:

;----------------------------------------------------------    
    ;加载gdt
    lgdt [GdtPtr]
    
    ;关闭中断
    cli
    
    ;打开地址线A20
    in al,92h;10010010
    or al,00000010b
    out 92h,al
    
    ;准备切换到保护模式,至CR0最后一位为1
    mov eax,cr0
    or eax,1
    mov cr0,eax
    
    ;进入保护模式的32位代码段
    jmp dword Selector_Code32:0 
    
;[.s16 end]--------------------------------------------------------------------------------



[section .s32]
[bits 32]
CODE32_BEGIN:

    mov ax,Selector_Data   ;;;数据段选择子
    mov ds,ax
    
    mov ax,Selector_Video   ;;;视频段选择子
    mov gs,ax
    
    mov ax,Selector_Stack_Ring0   ;;;堆栈段选择子
    mov ss,ax
    mov esp,TopOfStackRing0
    
    DispStr pmstring
;-----------------------------------------
    push ecx
    push esi
    
    DispStr mem_info_title
    
    mov ecx,[dw_mem_number]
    mov esi,memchkbuf
.1
    DispInt [esi+4]
    DispInt [esi+0]
    DispInt [esi+12]
    DispInt [esi+8]
    DispInt [esi+16]
    DispStr szReturn
    cmp dword [esi+16],1
    jne .2
    push eax
    xor eax,eax
    mov eax,[esi+0]
    add eax,[esi+8]
    mov [MemSize],eax
    pop eax
.2:
    dec ecx  
    add esi,20
    cmp ecx,0
    jnz .1
    
    pop esi
    pop ecx
    
    push edx
    mov edx,[MemSize]
    shr edx,20
    DispStr szReturn
    DispStr memSizeInfo
    DispInt edx
    DispStr memSizeInfoEnd
    pop edx
    


;-----------------------------------------
    ;call SetupPaging
    mov ax,Selector_gzc222   ;;;数据段选择子
    mov ds,ax
    jmp Selector_gzc:30000h

;---------------------------------------------------------------------------------------
SetupPaging:
    mov ax,Selector_PageDir
    mov es,ax
    mov ecx,[MemSize]
    shr ecx,22;2^22=4MB 每个页表目录指向1024个4KB的页表,既4MB
    xor edi,edi
    xor eax,eax
    mov eax,201000h | PG_P | PG_RWW | PG_USU
.1:
    stosd
    add eax,1000h;4096
    loop .1
    
    mov ax,Selector_PageTable
    mov es,ax
    xor edi,edi
    xor eax,eax
    mov ecx,[MemSize]
    shr ecx,12;ecx=[MemSize]/4MB
              ;2^22=4MB 每个页表目录指向1024个4KB的页表,既4MB -----现在ecx的值表示要处理的页表目录的个数
              ;ecx=ecx*1024 (1024=2^10) 既一共要处理的页表的个数 所以shr ecx,(22-10)
              ;所以最后的语句为:shr ecx,12
    mov eax,0h | PG_P | PG_RWW | PG_USU
.2:
    stosd
    add eax,1000h;4096
    loop .2
    
    mov eax,200000h;cr3寄存器存储了页表目录的基地址
    mov cr3,eax
    
    mov eax,cr0;cr0的最高位为1时开启分页机制
    or  eax,80000000h
    mov cr0,eax
    
    ret
;---------------------------------------------------------------------------------------

    code32descLen     equ     $ - CODE32_BEGIN
;[.s32 end]--------------------------------------------------------------------------------