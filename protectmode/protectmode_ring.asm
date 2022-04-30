org 0x7c00
jmp BEGIN

;GDT STRACTURE
%macro Descriptor 3
	dw %2 & 0xffff ;segment limitation 0-15
	dw %1 & 0xffff ;segment base address 0-15 bit
	db (%1 >> 16) & 0xff ; segment base address 16-23 bit
	dw ((%2 >> 8) & 0x0f00) | (%3 & 0xf0ff);段属性+段界限+段属性
	db (%1 >>24) & 0xff ;段基址最后8位
%endmacro
;END_OF_GDT_STRACTURE

;ATTR DEF
DA_32 equ 4000h ; 32位代码段
DA_C equ 98h ; 只执行代码段的属性
DA_DAW equ 92h ; 可读写的数据段
DA_DAWA equ 93h ; 已经访问过的可读写的数据段
SA_TIL equ 0x4 
DA_LDT equ 0x82 

SA_RPL0 equ 0
SA_RPL3 equ 3  
DA_DPL0 equ 0x00  
DA_DPL1 equ 0x20  
DA_DPL2 equ 0x40  
DA_DPL3 equ 0x60 
;ATTR DEF END

;GDT SEG
[SEGMENT .gdt]				               ;段基址       ;段界限                          ;属性
GDT:                           Descriptor  0,            0,                             0
GDT_CODE_32_SEG:               Descriptor  0,            GDT_CODE_32_SEG_LEN -1,        DA_C + DA_32
GDT_DATA_SEG:                  Descriptor  0,            GDT_DATA_SEG_LEN - 1,          DA_DAW + DA_DPL0
GDT_SCREEN_SEG:                Descriptor  0xb8000,      0xFFFF,                        DA_DAW
GDT_TEST_SEG:                  Descriptor  0x1fffff,     0xffff,                        DA_DAW
LDT_SEG:                       Descriptor  0,            LDT_LEN - 1,                   DA_LDT
;END OF GDT SEG

GDT_LEN equ $ - GDT
GDT_PTR: dw GDT_LEN      ;GDT长度
		dd 0            ;GDT基地址

[SEGMENT .selector]
SELECTOR_CODE_32_SEG equ GDT_CODE_32_SEG - GDT
SELECTOR_DATA_SEG equ GDT_DATA_SEG - GDT + SA_RPL0
SELECTOR_SCREEN_SEG equ GDT_SCREEN_SEG - GDT
SELECTOR_TEST_SEG equ GDT_TEST_SEG - GDT
SELECTOR_LDT_SEG equ LDT_SEG - GDT


[SEGMENT .code_16]
[BITS 16]
BEGIN:
	mov ax,0
	mov bx,ax
	mov cx,ax
	mov dx,ax
	mov ax,cs
	mov ds,ax
	
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,CODE_32_SEG
	mov word [GDT_CODE_32_SEG+2],ax
	shr eax,16
	mov byte [GDT_CODE_32_SEG+4],al
	shr eax,8
	mov byte [GDT_CODE_32_SEG+7],al
	
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,DATA_32_SEG
	mov word [GDT_DATA_SEG+2],ax
	shr eax,16
	mov byte [GDT_DATA_SEG+4],al
	shr eax,8
	mov byte [GDT_DATA_SEG+7],al
	
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,LDT
	mov word [LDT_SEG+2],ax
	shr eax,16
	mov byte [LDT_SEG+4],al
	mov byte [LDT_SEG+7],ah
	
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,LDT_Code_32
	mov word [LDT_Code_32_SEG+2],ax
	shr eax,16
	mov byte [LDT_Code_32_SEG+4],al
	mov byte [LDT_Code_32_SEG+7],ah
	
	
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,GDT
	mov dword [GDT_PTR+2],eax
	lgdt [GDT_PTR]
	
	;A20
	cli
	in al,92h
	or al,02h
	out 92h,al
	
	;切换保护模式
	mov eax,cr0
	or eax,1
	mov cr0,eax

	jmp dword SELECTOR_CODE_32_SEG:0


[SEGMENT .code_32]
[BITS 32]
CODE_32_SEG:
	xor eax,eax
	mov ax,SELECTOR_DATA_SEG
	mov ds,ax
	
	xor ax,ax
	mov ax,SELECTOR_SCREEN_SEG
	mov es,ax
	
	xor ax,ax
	mov ax,SELECTOR_TEST_SEG
	mov gs,ax
	
	
	xor edi,edi
	xor esi,esi
	xor eax,eax
	mov esi,OFFSET_STR_HELLO_WORLD
	cld
	;mov eax,STR_PROTECTED_MODE
	.READ_STR:
		lodsb
		test al,al
		jz .FINISH_READ
		mov byte es:[edi],al
		add edi,2
		jmp .READ_STR
	.FINISH_READ:
	
	xor edi,edi
	xor esi,esi
	xor eax,eax
	mov esi,OFFSET_STR_PROTECT_MODE
	mov edi,(80*1+0)*2
	cld
	.READ_STR_2:
		lodsb
		test al,al
		jz .FINISH_READ_2
		mov byte es:[edi],al
		add edi,2
		jmp .READ_STR_2
	.FINISH_READ_2:
		
	
	.TEST_OUT_ONE_MB:
		mov byte gs:[0],"O"
		mov byte gs:[1],"K"
		mov ax,gs
		mov ds,ax
		xor ax,ax
		xor edi,edi
		mov edi,(80*2+0)*2
		mov al,[0]
		mov byte es:[edi],al
		add edi,1
		mov byte es:[edi],0x07
		add edi,1
		mov al,[1]
		mov byte es:[edi],al
		add edi,1
		mov byte es:[edi],0x07
		
		mov ax,SELECTOR_LDT_SEG
		lldt ax
		jmp dword SELECTOR_LDT_CODE_32_SEG:0
	
GDT_CODE_32_SEG_LEN equ $ - CODE_32_SEG

[SEGMENT .data_32]
[BITS 32]
DATA_32_SEG:
OFFSET_STR_PROTECT_MODE equ $ - DATA_32_SEG
STR_PROTECTED_MODE: db "PROTECTED_MODE",0
OFFSET_STR_HELLO_WORLD equ $ - DATA_32_SEG
STR_HELLO_WORLD: db "HELLO_WORLD",0

GDT_DATA_SEG_LEN equ $ - DATA_32_SEG

[SEGMENT .ldt]
LDT: Descriptor 0, 0, 0
LDT_Code_32_SEG: Descriptor 0,              LDT_Code_32_LEN - 1,              DA_C+DA_32
LDT_LEN equ $ - LDT

[SEGMENT .selector_ldt]
SELECTOR_LDT_CODE_32_SEG equ LDT_Code_32_SEG - LDT + SA_TIL

[SEGMENT .ldt_code_32]
[BITS 32]
LDT_Code_32:
	
	xor edi,edi
	xor eax,eax
	
	mov edi,(80*3+0)*2
	xor eax,eax
	mov ah,0x07
	mov al,"L"
	mov word es:[edi],ax
	jmp $
	
LDT_Code_32_LEN equ $ - LDT_Code_32
  
times 510 - 469 db 0
db 0x55
db 0xaa