org 7c00h

mov ax,0xb800
mov ds,ax
mov ax,0
mov bx,ax

mov byte ds:[bx],"h"
add bx,1
mov byte ds:[bx],0x07

jmp $

