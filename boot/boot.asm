BaseOfLoader equ 9040h
OffsetOfLoader equ 0h

BaseOfKernel	equ	 03000h	; KERNEL.BIN �����ص���λ�� ----  �ε�ַ
OffsetOfKernel	equ	     0h	; KERNEL.BIN �����ص���λ�� ---- ƫ�Ƶ�ַ

indirectLoadBuf equ 9000h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;9040h:0=90400h 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;��9000:0��ʼ�ճ���400H��1024�ֽ�
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;��Ϊ��ext2�ļ���Ҫ�õ���indirectLoad����

[SECTION .s16]
[BITS	16]
org	07c00h
	jmp	LABEL_BEGIN
	
dir_entry_buff:
inode:      dd  0;//7c03
rec_len:    dw  0;//7c07
name_len:   db  0;//7c08
file_type:  db  0;//7c09


blockCount: dw  0 ;//7c0a
indexOfBlockN: dw 0

loaderName db 'loader.bin'
kernelName db 'kernel.bin'

loaderNameLen equ 10
kernelNameLen equ 10

LABEL_BEGIN:
  mov ax,1000h
  mov es,ax  
  mov bx,0   ;es:bx ���ݻ�����
  
  push 56
  push 2
  call ReadSector;;;;;;;;;;;�����ֶ�...�Ҳ�����...ֱ���ܵ�Ŀ¼��....
  add esp,4
  
  
  ;ds:si->es:di
  mov ax,1000h
  mov ds,ax
  mov si,0;���ú�ds:si  1000h:0h
  
  push loaderName
  push loaderNameLen  
  call SearchFile
  add esp,4  
  
  push BaseOfLoader
  push OffsetOfLoader
  call LoadingFile
  add esp,4
  
;-------------------------------------

  mov ax,1000h
  mov es,ax  
  mov bx,0   ;es:bx ���ݻ�����
  
  push 56
  push 2
  call ReadSector;;;;;;;;;;;�����ֶ�...�Ҳ�����...ֱ���ܵ�Ŀ¼��....
  add esp,4
  
  
  ;ds:si->es:di
  mov ax,1000h
  mov ds,ax
  mov si,0;���ú�ds:si  1000h:0h
  
  push kernelName
  push kernelNameLen  
  call SearchFile
  add esp,4  
  
  push BaseOfKernel
  push OffsetOfLoader
  call LoadingFile
  add esp,4
  
  ;jmp $
  jmp BaseOfLoader:OffsetOfLoader
  
;--------------------------------------------------------------------------------------
LoadingFile:

;�ҵ��ļ����ִ�д���
  mov ax,1000h
  mov es,ax  
  mov bx,0   ;es:bx ���ݻ�����
  
  push 10
  push 10
  call ReadSector;;;;;;;;;;;;;;;;;;;�������׷���....ֱ���ܵ�INODE_table
  add esp,4
  
  mov ax,7c0h
  mov es,ax 
  
  mov esi,dword [cs:inode];inode������esi/////7c64
  dec esi;inode�Ǵ�1��ʼ���� �����������1
  shl esi,7;2��7�η���128,inode��*128�õ�Ҫ���ҵ�INODE����ڶε�ַ1000h����ƫ��
  
  push esi;580h,inode��ͷ
  add esi,4;I��4�ֽ�ƫ�ƴ���__u32 i_size,ָʾ�ļ���С
  mov ax,1000h
  mov ds,ax;lodsd ds:si->eax
  lodsd
  
  mov bx,1024
  div bx ;i_size / 1024 = �ļ���ռBLOCK��
  cmp dx,0
  je  .1
  add ax,1
.1:
  mov [cs:blockCount],ax
  
  
  pop esi;�ָ�esi��inode��ͷ
  add esi,40;inode�ṹ�� i_block[EXT3_N_BLOCKS]λ��40�ֽ�ƫ�ƴ�
  
  mov ax,[esp+4]
  mov es,ax
  mov bx,[esp+2]
  
  mov cx,word [cs:blockCount];////////////////////////////////////7ca0
  mov word [cs:indexOfBlockN],1;dhָʾ��ȡ��block���������
.loadCode:
  cmp word [cs:indexOfBlockN],12
  jng .NormalLoad
  cmp word [cs:indexOfBlockN],44;12+1024/32=12+32=44.....�Ѿ��ܴ���ļ���....44K���ں��ļ�...
  jng  .indirectLoad
  cmp word [cs:indexOfBlockN],1036;12+32*32=1036......��ô��..�϶��ò�����,1MB
  jng  .doubleindirectLoad
  cmp word [cs:indexOfBlockN],32780;12+32*32*32=32780......32MB���ں��ļ�?�㿪��Ц�ذ���
  jng  .tripleindirectLoad  
  
.NormalLoad:
  lodsd;;;;;;;;;;;;;;;;;;;;;;;;;Ӱ��ļĴ��� esi+=4  ds:esi->inode���е�BLOCKռ�����������ֶ�
  shl eax,1
  push ax
  push 2
  call ReadSector
  add esp,4
  jmp .LoadNext
  
.indirectLoad:
  mov ax,ds
  cmp ax,indirectLoadBuf
  je  .NormalLoad
  
  push es
  push bx

  mov ax,indirectLoadBuf
  mov es,ax
  mov bx,0
    
  lodsd
  shl eax,1
  push ax
  push 2
  
  call ReadSector;;;;;;;;;;;;;;;;;;;;;;��2�������2�������� ��BaseOfLoader-1024�ֽڴ�
  add esp,4
  
  pop bx
  pop es
  
  mov ax,indirectLoadBuf
  mov ds,ax
  mov esi,0
  jmp .NormalLoad  
  jmp .LoadNext
  
.doubleindirectLoad:
  jmp .LoadNext
  
.tripleindirectLoad:
  jmp .LoadNext

.LoadNext:
  inc word [cs:indexOfBlockN]
  dec cx
  
  mov ax,es
  add ax,40h
  mov es,ax;es�ϼ�40h���ڸ�ƫ�Ƶ�ַ�ϼ���400H��1024byte=1 block
  mov bx,0
  
  cmp cx,0
  jg  .loadCode
  
  ret
  
  
  
  
  
  
  
  
  
    
;---------------------------------------------------------  
;�����ļ�,ʹ�÷���: ds:siָ���ڴ��д�õ�Ŀ¼����
SearchFile:  
  mov ax,cs
  mov es,ax
.snext:
  push si
  mov di,inode;es:di = 7c03h  
  cld
  movsd
  movsd  
  mov cx,[esp+4]
  mov di,[esp+6]
  repe cmpsb
  je .exitfunc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;�ҵ��ļ�������dir_entry_buff��ֵ  
  pop si
  add si,word [cs:rec_len] ;es:07h=7c07h
  jmp .snext
.exitfunc:
  add esp,2
  ret
  
  
  
  
  
  
  
  
  
  
;---------------------------------------------------------
;---------------------------------------------------------
	;���������� ������ 
	;��ڲ����� AH��02H
	;AL��������
	;CH������
	;CL������
	;DH����ͷ
	;DL����������00H~7FH�����̣�80H~0FFH��Ӳ��
	;ES:BX���������ĵ�ַ 
	;���ڲ����� 
	;CF��0���������ɹ���AH��00H��AL�������������������AH��״̬���룬�μ����ܺ�01H�е�˵�� 
;---------------------------------------------------------
;BIOS_sector_num = 1 + (DOS_sector_num MOD Sectors_per_track)
;BIOS_Head_num   = (DOS_sector_num DIV Sectors_per_track) MOD Total_heads
;BIOS_Track_num  = (DOS_sector_num DIV Sectors_per_track) DIV Total_heads

;Format   Size   Cyls   Heads  Sec/Trk   FATs   Sec/FAT   Sec/Root   Media
;1.2M     5 1/4   80      2      15       2       14        14        F9
;1.44M    3 1/2   80      2      18       2       18        14        F0

;BIOS INT13H
;AH = 02h
;AL = number of sectors to read (must be nonzero)
;CH = low eight bits of cylinder number
;CL = sector number 1-63 (bits 0-5) 
;     high two bits of cylinder (bits 6-7, hard disk only)
;DH = head number
;DL = drive number (bit 7 set for hard disk)
;ES:BX -> data buffer


ReadSector:
;push the start sector number and the number how many sector you wanna to read
;then call this function
  Total_heads equ 2
  Sectors_per_track equ 18
  mov ax,[esp+4]             
  mov dl,Total_heads*Sectors_per_track              
  div dl                    
  mov ch,al                 ;C->CH
  mov al,ah
  cbw
  mov dl,Sectors_per_track
  div dl
  
  mov dh,al                 ;H->DH
  mov cl,ah
  inc cl                    ;S->CL
  
.1:
	mov al,[esp+2]            ;AL=n
  mov dl,0                  ;DH=0
  mov ah,02h                ;AH=02H
  int 13h
	jc	.1
	ret
	
times 	510-($-$$)	db	0	; ���ʣ�µĿռ䣬ʹ���ɵĶ����ƴ���ǡ��Ϊ512�ֽ�
dw 	0xaa55				; ������־