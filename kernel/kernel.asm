[section .text]
[bits 32]
global _start	
extern initGDT

_start:
  mov ax,ds
  mov es,ax
  mov fs,ax  
  jmp initGDT

