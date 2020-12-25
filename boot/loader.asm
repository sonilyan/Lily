%include	"Descriptor.inc"	; �й���GDT�� ���꣬������ ����
DA_32		  EQU	4000h	;
DA_DRW		EQU	92h	; ���ڵĿɶ�д���ݶ�����ֵ
DA_DRWA		EQU	93h	; ���ڵ��ѷ��ʿɶ�д���ݶ�����ֵ
DA_C		  EQU	98h	; ���ڵ�ִֻ�д��������ֵ
;--------------------------------------------------------------------------------------
PG_P		EQU	1	; ҳ��������λ
PG_RWR		EQU	0	; R/W ����λֵ, ��/ִ��
PG_RWW		EQU	10b	; R/W ����λֵ, ��/д/ִ��
PG_USS		EQU	0	; U/S ����λֵ, ϵͳ��
PG_USU		EQU	100b	; U/S ����λֵ, �û���
;-----------------------------------------------------------------------------------------
    jmp label_begin

[section .gdt]
LABEL_GDT:                Descriptor 0, 0, 0                                                  ;��������
LABEL_GZC:                Descriptor    0,          0fffffh, 9Ah  | 4000h | 8000h			; 0 ~ 4G  C09Ah
LABEL_DESC_FLAT_RW:		    Descriptor    0,          0fffffh, 92h | 4000h | 8000h			; 0 ~ 4G  C092h
;===============================���ݶ�������
LABEL_DATA_DESC:          Descriptor    0,          Datalen-1,            (DA_DRW  +  DA_32)    
LABEL_PAGE_DIR:           Descriptor 200000h,4095,DA_DRW
LABEL_PAGE_TABLE:         Descriptor 201000h,1023,DA_DRW | 8000h	
;===============================�����������
LABEL_CODE32_DESC:        Descriptor    0,          code32descLen - 1,    (DA_32 + DA_C)
;===============================��Ƶ��������
LABEL_VIDEO_DESC:         Descriptor    0B8000h,    0ffffh,               DA_DRW    
;===============================��ջ������
LABEL_STACK_RING0_DESC:   Descriptor    0,          TopOfStackRing0,      DA_DRWA  +  DA_32
;--------------------------------------------
GdtLen               equ   $ - LABEL_GDT
GdtPtr               dw    GdtLen - 1       ;����
                     dd    0                ; gdt ��ַ��4λ���Ժ��ʼ����
     
;===============================��ջѡ����
Selector_Stack_Ring0      equ     LABEL_STACK_RING0_DESC - LABEL_GDT
;===============================���ݶ�ѡ����
Selector_Data             equ     LABEL_DATA_DESC - LABEL_GDT  
Selector_PageDir          equ     LABEL_PAGE_DIR  - LABEL_GDT
Selector_PageTable        equ     LABEL_PAGE_TABLE -LABEL_GDT 
;===============================�����ѡ����
Selector_Code32           equ     LABEL_CODE32_DESC - LABEL_GDT             ;ѡ���ӵĵ�1��2λ��RPL
Selector_gzc              equ     LABEL_GZC - LABEL_GDT
Selector_gzc222              equ     LABEL_DESC_FLAT_RW - LABEL_GDT
;===============================��Ƶ��ѡ����
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
    
    ;��ʼ����ջ
    initDescriptor LABEL_STACK_RING0_DESC,LABEL_STACK_RING0  
    ;��ʼ�������
    initDescriptor LABEL_CODE32_DESC,CODE32_BEGIN    
    ;��ʼ�����ݶ�
    initDescriptor LABEL_DATA_DESC,DATA_BEGIN      
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;׼������gdtr
    xor eax,eax
    mov ax,ds       ;����ֵ��ֵ��AX ---------������
    shl eax,4
    add eax,LABEL_GDT    
    mov dword [GdtPtr+2],eax   ;��ʼ��GDT
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
    ;����gdt
    lgdt [GdtPtr]
    
    ;�ر��ж�
    cli
    
    ;�򿪵�ַ��A20
    in al,92h;10010010
    or al,00000010b
    out 92h,al
    
    ;׼���л�������ģʽ,��CR0���һλΪ1
    mov eax,cr0
    or eax,1
    mov cr0,eax
    
    ;���뱣��ģʽ��32λ�����
    jmp dword Selector_Code32:0 
    
;[.s16 end]--------------------------------------------------------------------------------



[section .s32]
[bits 32]
CODE32_BEGIN:

    mov ax,Selector_Data   ;;;���ݶ�ѡ����
    mov ds,ax
    
    mov ax,Selector_Video   ;;;��Ƶ��ѡ����
    mov gs,ax
    
    mov ax,Selector_Stack_Ring0   ;;;��ջ��ѡ����
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
    mov ax,Selector_gzc222   ;;;���ݶ�ѡ����
    mov ds,ax
    jmp Selector_gzc:30000h

;---------------------------------------------------------------------------------------
SetupPaging:
    mov ax,Selector_PageDir
    mov es,ax
    mov ecx,[MemSize]
    shr ecx,22;2^22=4MB ÿ��ҳ��Ŀ¼ָ��1024��4KB��ҳ��,��4MB
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
              ;2^22=4MB ÿ��ҳ��Ŀ¼ָ��1024��4KB��ҳ��,��4MB -----����ecx��ֵ��ʾҪ�����ҳ��Ŀ¼�ĸ���
              ;ecx=ecx*1024 (1024=2^10) ��һ��Ҫ�����ҳ��ĸ��� ����shr ecx,(22-10)
              ;�����������Ϊ:shr ecx,12
    mov eax,0h | PG_P | PG_RWW | PG_USU
.2:
    stosd
    add eax,1000h;4096
    loop .2
    
    mov eax,200000h;cr3�Ĵ����洢��ҳ��Ŀ¼�Ļ���ַ
    mov cr3,eax
    
    mov eax,cr0;cr0�����λΪ1ʱ������ҳ����
    or  eax,80000000h
    mov cr0,eax
    
    ret
;---------------------------------------------------------------------------------------

    code32descLen     equ     $ - CODE32_BEGIN
;[.s32 end]--------------------------------------------------------------------------------