BaseOfLoader equ 9040h
OffsetOfLoader equ 0h

BaseOfKernel	equ	 03000h	; KERNEL.BIN 被加载到的位置 ----  段地址
OffsetOfKernel	equ	     0h	; KERNEL.BIN 被加载到的位置 ---- 偏移地址

indirectLoadBuf equ 9000h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;9040h:0=90400h 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;从9000:0开始空出的400H既1024字节
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;做为读ext2文件需要用到的indirectLoad缓存

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
  mov bx,0   ;es:bx 数据缓冲区
  
  push 56
  push 2
  call ReadSector;;;;;;;;;;;作弊手段...我不计算...直接跑到目录区....
  add esp,4
  
  
  ;ds:si->es:di
  mov ax,1000h
  mov ds,ax
  mov si,0;设置好ds:si  1000h:0h
  
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
  mov bx,0   ;es:bx 数据缓冲区
  
  push 56
  push 2
  call ReadSector;;;;;;;;;;;作弊手段...我不计算...直接跑到目录区....
  add esp,4
  
  
  ;ds:si->es:di
  mov ax,1000h
  mov ds,ax
  mov si,0;设置好ds:si  1000h:0h
  
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

;找到文件后的执行代码
  mov ax,1000h
  mov es,ax  
  mov bx,0   ;es:bx 数据缓冲区
  
  push 10
  push 10
  call ReadSector;;;;;;;;;;;;;;;;;;;还是作弊方法....直接跑到INODE_table
  add esp,4
  
  mov ax,7c0h
  mov es,ax 
  
  mov esi,dword [cs:inode];inode数放入esi/////7c64
  dec esi;inode是从1开始计数 所以这里减少1
  shl esi,7;2的7次方是128,inode数*128得到要查找的INODE相对于段地址1000h处的偏移
  
  push esi;580h,inode开头
  add esi,4;I表4字节偏移处是__u32 i_size,指示文件大小
  mov ax,1000h
  mov ds,ax;lodsd ds:si->eax
  lodsd
  
  mov bx,1024
  div bx ;i_size / 1024 = 文件所占BLOCK数
  cmp dx,0
  je  .1
  add ax,1
.1:
  mov [cs:blockCount],ax
  
  
  pop esi;恢复esi到inode开头
  add esi,40;inode结构中 i_block[EXT3_N_BLOCKS]位于40字节偏移处
  
  mov ax,[esp+4]
  mov es,ax
  mov bx,[esp+2]
  
  mov cx,word [cs:blockCount];////////////////////////////////////7ca0
  mov word [cs:indexOfBlockN],1;dh指示读取的block数组的索引
.loadCode:
  cmp word [cs:indexOfBlockN],12
  jng .NormalLoad
  cmp word [cs:indexOfBlockN],44;12+1024/32=12+32=44.....已经很大的文件了....44K的内核文件...
  jng  .indirectLoad
  cmp word [cs:indexOfBlockN],1036;12+32*32=1036......这么大..肯定用不到了,1MB
  jng  .doubleindirectLoad
  cmp word [cs:indexOfBlockN],32780;12+32*32*32=32780......32MB的内核文件?你开玩笑呢吧你
  jng  .tripleindirectLoad  
  
.NormalLoad:
  lodsd;;;;;;;;;;;;;;;;;;;;;;;;;影响的寄存器 esi+=4  ds:esi->inode表中的BLOCK占用数组数据字段
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
  
  call ReadSector;;;;;;;;;;;;;;;;;;;;;;将2级表读入2级表缓存区 既BaseOfLoader-1024字节处
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
  mov es,ax;es上加40h等于给偏移地址上加了400H既1024byte=1 block
  mov bx,0
  
  cmp cx,0
  jg  .loadCode
  
  ret
  
  
  
  
  
  
  
  
  
    
;---------------------------------------------------------  
;查找文件,使用方法: ds:si指向内存中存好的目录内容
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
  je .exitfunc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;找到文件后设置dir_entry_buff的值  
  pop si
  add si,word [cs:rec_len] ;es:07h=7c07h
  jmp .snext
.exitfunc:
  add esp,2
  ret
  
  
  
  
  
  
  
  
  
  
;---------------------------------------------------------
;---------------------------------------------------------
	;功能描述： 读扇区 
	;入口参数： AH＝02H
	;AL＝扇区数
	;CH＝柱面
	;CL＝扇区
	;DH＝磁头
	;DL＝驱动器，00H~7FH：软盘；80H~0FFH：硬盘
	;ES:BX＝缓冲区的地址 
	;出口参数： 
	;CF＝0——操作成功，AH＝00H，AL＝传输的扇区数，否则，AH＝状态代码，参见功能号01H中的说明 
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
	
times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 结束标志