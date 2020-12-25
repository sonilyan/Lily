%macro Descriptor 3
	dw	%2 & 0FFFFh				; �ν��� 1				(2 �ֽ�)
	dw	%1 & 0FFFFh				; �λ�ַ 1				(2 �ֽ�)
	db	(%1 >> 16) & 0FFh			; �λ�ַ 2				(1 �ֽ�)
	dw	((%2 >> 8) & 0F00h) | (%3 & 0F0FFh)	; ���� 1 + �ν��� 2 + ���� 2		(2 �ֽ�)
	db	(%1 >> 24) & 0FFh			; �λ�ַ 3				(1 �ֽ�)
%endmacro ; �� 8 �ֽ�

%macro Gate 4;ѡ���ӣ�ƫ�ƣ������е�param count,����
	dw	(%2 & 0FFFFh)				; ƫ�� 1				(2 �ֽ�)
	dw	%1					; ѡ����				(2 �ֽ�)
	dw	(%3 & 1Fh) | ((%4 << 8) & 0FF00h)	; ����					(2 �ֽ�)
	dw	((%2 >> 16) & 0FFFFh)			; ƫ�� 2				(2 �ֽ�)
%endmacro ; �� 8 �ֽ�

%macro initDescriptor 2
    xor eax,eax
    mov ax,cs
    shl eax,4
    add eax,%2
    
    mov	word [%1 + 2], ax
    shr	eax, 16
    mov	byte [%1 + 4], al
    mov	byte [%1 + 7], ah
%endmacro ; �� 8 �ֽ�

%macro DispStr 1
  push esi
  push edi
  
	mov esi,%1	
	mov edi,[index_of_display]
%%.readb2al:
  lodsb
  test al,al
  jz %%.endput
  cmp al,0Ah
  jne %%.putbyte
  push eax
  push ebx
  mov eax,edi
  mov bl,160
  div bl
  and eax,0FFh
  inc eax
  mov bl,160
  mul bl
  mov edi,eax
  pop ebx
  pop eax 
  
  jmp %%.readb2al

%%.putbyte:
  mov ah,0Fh
  mov [gs:edi],ax
  add edi,2
  jmp %%.readb2al
  
%%.endput:
  mov [index_of_display],edi
  pop edi
  pop esi
%endmacro 
; DispStr ����------------------------------------------------------------


; ------------------------------------------------------------------------
; ��ʾ AL �е�����
; ------------------------------------------------------------------------
%macro DispAL 0
	push	ecx
	push	edx
	push	edi

	mov	edi, [index_of_display]

	mov	ah, 0Fh			; 0000b: �ڵ�    1111b: ����
	mov	dl, al
	shr	al, 4
	mov	ecx, 2
%%.begin:
	and	al, 01111b
	cmp	al, 9
	ja	%%.1
	add	al, '0'
	jmp	%%.2
%%.1:
	sub	al, 0Ah
	add	al, 'A'
%%.2:
	mov	[gs:edi], ax
	add	edi, 2

	mov	al, dl
	loop	%%.begin
	;add	edi, 2

	mov	[index_of_display], edi

	pop	edi
	pop	edx
	pop	ecx

%endmacro
; DispAL ����-------------------------------------------------------------


; ------------------------------------------------------------------------
; ��ʾһ��������
; ------------------------------------------------------------------------
%macro DispInt 1
  push eax
	mov	eax, %1
	shr	eax, 24
	DispAL

	mov	eax, %1
	shr	eax, 16
	DispAL

	mov	eax, %1
	shr	eax, 8
	DispAL

	mov	eax, %1
	DispAL

	mov	ah, 07h			; 0000b: �ڵ�    0111b: ����
	mov	al, 'h'
	push	edi
	mov	edi, [index_of_display]
	mov	[gs:edi], ax
	add	edi, 4
	mov	[index_of_display], edi
	pop	edi
	pop eax

%endmacro
; DispInt ����------------------------------------------------------------