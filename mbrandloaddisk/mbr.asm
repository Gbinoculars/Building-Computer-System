org 0x7c00
LOADER_BASE_ADDR equ 0x9000
LOADER_BASE_SECTOR equ 0x2

mov ax,0xb800
mov ds,ax
mov ax,0
mov bx,ax
mov ax,cs


mov byte ds:[bx], 'M'
add bx,1
mov byte ds:[bx], 0x07
add bx,1
mov byte ds:[bx], 'B'
add bx,1
mov byte ds:[bx], 0x07
add bx,1
mov byte ds:[bx],'R'
add bx,1
mov byte ds:[bx], 0x07

mov ax,LOADER_BASE_SECTOR
mov bx,LOADER_BASE_ADDR
mov cs,bx
mov cl,0x01
call rd_disk

jmp LOADER_BASE_ADDR

rd_disk:
	mov si,ax
	mov di,bx
	
	mov al,cl
	mov dx,0x1f2
	out dx,al
	
	mov dx,0x1f3
	out dx,al
	
	mov dx,0x1f4
	mov cl,8
	shr ax,cl
	out dx,al
	
	mov dx,0x1f5
	shr ax,cl
	out dx,al
	
	mov dx,0x1f6
	and al,0x0f
	or al,0xe0
	out dx,al
	
	mov dx,0x1f7
	mov al,0x20
	out dx,al

	.chech_status:	
		;check status of disk
		in al,dx
		and al,0x48 
		cmp al,0x08
		jnz .chech_status
		
	mov dx,256
	mov ax,cx
	mul dx
	mov cx,ax
	mov dx,0x1f0
	
	.go_on:
		in ax,dx
		mov [bx],ax
		add bx,0x2
		loop .go_on
	ret
	
times 510 - ($-$$) db 0
db 0x55
db 0xaa
	

