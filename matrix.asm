[bits 16]
[org 7C00h]

start:
  ; init stack pointer
  xor ax, ax
  mov ss, ax
  mov sp, 7C00h

  ; switch to 8x8 font, text mode 80x50
  mov ax, 1112h
  xor bl, bl
  int 10h

  ; hide cursor
  mov ah, 01h
  mov cx, 2607h
  int 10h

  ; ask BIOS what time is it
  xor ax, ax
  int 1Ah
  mov word [seed], dx ; fill seed with current time

  ; load cutom font
  mov bp, font
  mov ax, 1100h
  mov bh, 8 ; bytes per character
  xor bl, bl
  mov cx, 22 ; 22 characters
  xor dx, dx ; load to index 0 of ASCII
  int 10h

  ; scroll down
  mov ax, 0702h
  xor cx, cx
  mov dx, 314Fh
  mov bh, 07h
  int 10h ; scroll down 1 line

loop:
  ; set cursor position to [pos], 1
  mov ah, 02h
  mov dh, 1 ; y position 0
  mov dl, byte [pos] ; x postion from var pos
  xor bh, bh ; page 0
  int 10h

  ; read character at cursor
  mov ah, 08h
  xor bh, bh
  int 10h

  cmp al, ' '
  jne noSpaceBelow

  ; space below
  mov ax, 32
  call rnd
  cmp ax, 0
  je l1

  mov ax, ' '
  jmp print
l1:
  mov bx, 0Fh
  jmp l2
noSpaceBelow:
  mov bl, 2
  mov ax, 4
  call rnd
  cmp al, 0
  jne noLightColor
  add bl, 8
noLightColor:
  mov ax, 16
  call rnd
  cmp al, 0
  je l3

l2:
  mov ax, 22
  call rnd
  ;add ax, 33
  jmp print
l3:
  mov ax, ' '
print:
  ; set cursor position to [pos], 0
  mov ah, 02h ; set cursor pos
  xor dh, dh ; y position 0
  mov dl, byte [pos] ; x postion from var pos
  xor bh, bh ; page 0
  int 10h

  ; print character
  mov ah, 09h
  ;mov bh, 0
  ;mov bx, 02h
  mov cx, 1
  int 10h

  ; repeat 80 times
  inc byte [pos]
  cmp byte [pos], 80
  jne loop
  mov byte [pos], 0

  mov cx, 40
change:
  push cx

  ;set cursor in random position
  mov ax, 80
  call rnd
  mov dl, al
  mov ax, 50
  call rnd
  mov dh, al
  mov ah, 02h ; set cursor pos
  xor bh, bh ; page 0
  int 10h

  ; read character at cursor
  mov ah, 08h
  xor bh, bh
  int 10h

  pop cx

  cmp al, ' '
  je change

  mov ax, 10
  call rnd
  push cx
  ; print character
  mov ah, 0Ah
  mov bh, 0
  mov cx, 1
  int 10h

  pop cx
  dec cx
  cmp cx, 0
  jne change

  call vsync

  mov cl, 8
pLoop:
  ; shift screen [cl] pixels up
  dec cl
  mov dx, 3D4h
  mov al, 08h
  out dx, al
  mov dx, 3D5h
  mov al, cl
  out dx, al

  call vsync

  cmp cl, 1
  jne pLoop

  ;scroll down
  mov ax, 0701h
  xor cx, cx
  mov dx, 314Fh
  mov bh, 07h
  int 10h ; scroll down 1 line

  ; shift screen 8 pixels(1 row) up
  mov dx, 3D4h
  mov al, 08h
  out dx, al
  mov dx, 3D5h
  mov al, 8
  out dx, al

  jmp loop

  ;jmp $

rnd:
  push dx
  push bx

  mov bx, ax
  mov ax, 25173
  mul word [seed]
  add ax, 13849
  adc dx, 0
  mov [seed], ax
  xchg ax, dx

  ; ax = (ax % bx)
  xor dx, dx
  div bx
  mov ax, dx

  pop bx
  pop dx

  ret

vsync:
  mov dx, 3DAh
l4:
  in al, dx
  and al, 8
  jnz l4
l5:
  in al, dx
  and al, 8
  jz l5
  ret

pos: db 0
seed: dw 0

font:
  db 0x0, 0xFC, 0x4, 0xFC, 0x4, 0x4, 0x18, 0x60
  db 0x0, 0x80, 0xFC, 0x90, 0x10, 0x10, 0x20, 0xC0
  db 0x0, 0x20, 0x20, 0x40, 0x48, 0x88, 0xFC, 0x4
  db 0x0, 0xFE, 0x2, 0x14, 0x18, 0x10, 0x10, 0x20
  db 0x0, 0x20, 0x20, 0xFC, 0x20, 0xA8, 0x24, 0x20
  db 0x0, 0x4, 0x4, 0x48, 0x28, 0x10, 0x28, 0xC0
  db 0x0, 0x4, 0x8, 0x10, 0x30, 0x50, 0x90, 0x10
  db 0x0, 0x48, 0xFC, 0x48, 0x48, 0x8, 0x8, 0x30
  db 0x0, 0x20, 0x20, 0xFC, 0x10, 0xFC, 0x10, 0x10
  db 0x0, 0x20, 0xFC, 0x4, 0x4, 0x4, 0x8, 0x70
  db 0x0, 0xF8, 0x8, 0x10, 0x20, 0x50, 0x88, 0x4
  db 0x0, 0x40, 0xFC, 0x44, 0x48, 0x50, 0x40, 0x40
  db 0x0, 0x8, 0x8, 0x8, 0x10, 0x10, 0x20, 0xC0
  db 0x0, 0x40, 0xFC, 0x44, 0x48, 0x40, 0x40, 0x3C
  db 0x0, 0xFC, 0x4, 0x44, 0x28, 0x18, 0x34, 0xC0
  db 0x0, 0x10, 0xFC, 0x10, 0x30, 0x50, 0x90, 0x10
  db 0x0, 0x4, 0x4, 0x84, 0x8, 0x8, 0x10, 0x60
  db 0x0, 0x20, 0xFC, 0x24, 0x24, 0x44, 0x44, 0x98
  db 0x0, 0x20, 0xFC, 0x4, 0x18, 0x68, 0xA4, 0x20
  db 0x0, 0x90, 0x90, 0x90, 0x90, 0x88, 0x8, 0x4
  db 0x0, 0xFC, 0x4, 0x4, 0x48, 0x30, 0x10, 0x8
  db 0x0, 0x78, 0x0, 0xFC, 0x4, 0x4, 0x8, 0x70

epilogue:
%if ($ - $$) > 510
  %fatal "Bootloader code exceed 512 bytes."
%endif

times 510 - ($ - $$) db 0
db 0x55
db 0xAA
