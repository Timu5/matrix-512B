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

  ; switch from 9bit to 8bit mode
  mov dx, 3C4h
  mov al, 01h
  out dx, al
  mov dx, 3C5h
  mov al, 1
  out dx, al

  ; hide cursor
  mov ah, 01h
  mov cx, 2607h
  int 10h

_j:
  ; ImC = y + (j - ny/2) * FRACTION / zoom / 2;
  mov eax, dword [j]
  sub eax, 49
  shl eax, 13
  cdq
  idiv dword [zoom]
  mov ebx, dword [y]
  add eax, ebx
  mov dword [ImC], eax
  _i:
    ; ReC = x + (i - nx / 2) * FRACTION / zoom;
    mov eax, dword [i]
    sub eax, 39
    shl eax, 14
    cdq
    idiv dword [zoom]
    mov ebx, dword[x]
    add eax, ebx
    mov dword [ReC], eax
    ; ReZ = 0; ImZ = 0; n = 0;
    mov dword [ReZ], 0
    mov dword [ImZ], 0
    mov dword [n], 0
    _l:
      ; int tmp1 = ((ReZ * ReZ) - (ImZ * ImZ)) / FRACTION + ReC;
      mov eax, dword [ReZ]
      imul eax
      push eax
      mov eax, dword [ImZ]
      imul eax
      pop ebx
      sub ebx, eax
      mov eax, ebx
      mov ecx, 16384
      cdq
      idiv ecx
      mov ebx, dword [ReC]
      add eax, ebx
      push eax ; tmp1

      ; int tmp2 = ((ImZ * ReZ) / FRACTION * 2) + ImC;
      mov eax, dword [ImZ]
      mov ebx, dword [ReZ]
      imul ebx
      mov ecx, 8192
      cdq
      idiv ecx
      add eax, dword [ImC]

      ; ImZ = tmp2;
      mov dword [ImZ], eax

      ; ReZ = tmp1;
      pop eax
      mov dword [ReZ], eax

      ; int modulus = ((ReZ * ReZ) + (ImZ * ImZ))/FRACTION;
      mov eax, dword [ReZ]
      imul eax
      push eax
      mov eax, dword [ImZ]
      imul eax
      pop ebx
      add ebx, eax
      mov eax, ebx
      mov ecx, 16384
      cdq
      idiv ecx

      cmp eax, 2*2*16384
      jge _l_end

      inc dword [n]
      cmp dword [n], 149
      jle _l
    _l_end:

    ; color = n == 150 ? 0x00 : (n % 15) + 1;
    mov eax, dword[n]
    mov ebx, 15
    cdq
    div ebx
    mov eax, edx
    mov bl, al
    inc bl
    xor cx, cx
    cmp dword[n], 150
    cmove bx, cx

    ; print
    push bx

    ; set cursor position
    mov eax, dword[j]
    mov dh, al
    shr dh, 1
    mov eax, dword[i]
    mov dl, al
    mov ah, 02h
    xor bh, bh
    int 10h

    mov ebx, 2
    mov eax, dword [j]
    cdq
    div ebx
    mov eax, edx
    cmp eax, 1
    jne l_a

    mov ah, 08h
    xor bh, bh
    int 10h

    pop bx
    or bl, ah
    jmp l_e

    l_a:
    pop bx
    shl bl, 4
    and bl, 01111111b
    l_e:
    mov ah, 09h
    mov al, 220
    xor bh, bh
    mov cx, 1
    int 10h

    inc dword [i]
    cmp dword [i], 79
    jle _i
    mov dword [i], 0

  inc dword [j]
  cmp dword [j], 99
  jle _j
  mov dword [j], 0

  mov eax, dword[zoom]
  shr eax, 3
  add dword[zoom], eax
  mov eax, dword [maxzoom]
  cmp dword[zoom], eax
  jge inf

  ;vsync
  mov dx, 3DAh
  v1:
  in al, dx
  and al, 8
  jnz v1
  v2:
  in al, dx
  and al, 8
  jz v2

  jmp _j

inf:
  jmp $

j: dd 0
i: dd 0
x: dd -330*8
y: dd -2115*8
zoom: dd 8
maxzoom: dd 2000
ReZ: dd 0
ImZ: dd 0
ReC: dd 0
ImC: dd 0
n: dd 0

epilogue:
%if ($ - $$) > 510
  %fatal "Bootloader code exceed 512 bytes."
%endif

times 510 - ($ - $$) db 0
db 0x55
db 0xAA