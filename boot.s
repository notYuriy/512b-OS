bits 16
org 0x7c00

; some code is used from these tutorials
; http://www.brokenthorn.com/Resources/OSDevIndex.html

jmp SETUP
; BIOS PARAMETER BLOCK
OEM_NAME:               db "MSWIN1.4"
BYTES_PER_SECTOR:       dw 512
SECTORS_PER_CLUSTER:    db 1
RESERVED_SECTORS:       dw 1
NUMBER_OF_FATS:         db 2
ROOT_ENTRIES:           dw 224
TOTAL_SECTORS:          dw 2880
MEDIA:                  db 0xf0
SECTORS_PER_FAT:        dw 9
SECTORS_PER_TRACK:      dw 18
NUMBER_OF_HEADS:        dw 2
HIDDEN_SECTORS:         dd 0
TOTAL_SECTORS_BIG:      dd 0
DRIVE_NUMBER_FROM_FAT:  db 0
UNUSED:                 db 0
EXIT_BOOT_SIGN:         db 0x29
SERIAL_NUMBER:          dd 0x0123456
VOLUME_LABEL:           db "512B FLOPPY"
FILE_SYSTEM:            db "FAT12   "
; LOADING FILE DATA
FILE_CLUSTER: dw 0
FILE_SIZE: dd 0
HEAD: db 0
TRACK: db 0
SECTOR: db 0
; USER INTERFACE DATA

EXEC_DH equ 25 /2
EXEC_DL equ (80-11)/2
DRIVE_NUMBER: db 0

; USED TO SEND DATA BETWEEN SUBROUTINES
TEMP: dw 0
FAT_MOVEMENT: dw 32

; PRINT STRING IN SI (SIZE IN CX)
PRINT_STRING:
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0x00
    int 10h
    ret

; PRINT 8.3 FILENAME
RENDER_NAME:
    mov cx, 11
    mov dh, EXEC_DH
    mov dl, EXEC_DL
    mov bl, 0x5f
    call PRINT_STRING
    ret

; READ FAT TO 0x7e00
READ_FAT_FROM_DISK:
    pusha
.READ:
    xor ax, ax
    mov es, ax
    mov bx, 0x7e00
    mov ah, 0x02
    mov al, 32
    mov ch, 0x00
    mov cl, 0x02
    mov dh, 0x00
    mov dl, [DRIVE_NUMBER]
    int 13h
    popa
    ret

; FINDS NEXT CLUSTER
NEXT_CLUSTER:
    pusha
    mov ax, [FILE_CLUSTER]
    mov dx, 0
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    mov si, 0x7e00
    add si, ax
    mov ax, word[ds:si]
    or dx, dx
    jz .EVEN_CLUSTER
.ODD_CLUSTER:
    shr ax, 4
    jmp .DONE
.EVEN_CLUSTER:
    and ax, 0fffh
.DONE:
    mov word [FILE_CLUSTER], ax
    popa
    ret

; CONVERT CHS TO LBA
LBACHS:
    pusha
    xor dx, dx
    div word [SECTORS_PER_TRACK]
    inc dl
    mov byte [SECTOR], dl
    xor dx, dx
    div word [NUMBER_OF_HEADS]
    mov byte [HEAD], dl
    mov byte [TRACK], al
    popa
    ret

; LOAD BINARY EXECUTABLE AT 0x1000:0x0000
LOAD_EXECUTABLE:
    mov ax, 0x1000
    mov es, ax
    xor bx, bx
    mov ax, [FILE_CLUSTER]
.LOOP:
    mov ax, [FILE_CLUSTER]
    add ax, 31
    call LBACHS
    mov ah, 0x02
    mov al, 1
    mov ch, [TRACK]
    mov cl, [SECTOR]
    mov dh, [HEAD]
    mov dl, [DRIVE_NUMBER]
    int 13h
    add bx, 512
    call NEXT_CLUSTER
    cmp word [FILE_CLUSTER], 0x0ff8
    jge .DONE
    jmp .LOOP
.DONE:
    mov ah, 0x00
    mov al, 0x03
    int 10h
    mov ah, 0x01
    mov cx, 0607h
    int 10h
    mov ax, 0x1000
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov sp, 0xffff
    pusha
    jmp 0x1000:0x0000

; CHECK IF ENTRY AT BP OFFSET IS VALID
ISVALID:
    pusha
    mov cx, 0
.LOOP:
    cmp cx, 11
    je .DONE
    mov bx, bp
    add bx, cx
    mov ah, [bx]
    cmp ah, 0
    jne .NOTEMPTY
    inc cx
    jmp .LOOP
.NOTEMPTY:
    stc
    popa
    ret
.DONE:
    clc
    popa
    ret

FAT12_ROOT_BEGIN equ 0xa200 - 32
FAT12_ROOT_END equ 0xbe00 - 64

; MOVE TO ANOTHER FILE
; [TEMP] = 32 => NEXT FILE
; [TEMP] = -32 => PREVIOUS FILE
BROWSE_NEXT:
    pusha
.LOOP:
    add bp, word [FAT_MOVEMENT]
    cmp bp, FAT12_ROOT_BEGIN
    jl .MOVE_TO_END
    cmp bp, FAT12_ROOT_END
    jg .MOVE_TO_BEGIN
    call ISVALID
    jc .DONE
    jmp .LOOP
.MOVE_TO_END:
    mov bp, FAT12_ROOT_END
    jmp .LOOP
.MOVE_TO_BEGIN:
    mov bp, FAT12_ROOT_BEGIN
    jmp .LOOP
.DONE:
    mov [TEMP], bp
    popa
    mov bp, [TEMP]
    ret

; EXIT INTERRUPT HANDLER
EXIT:
    pop ax
    pop eax
    popa
    jmp 0x0000:SETUP

; SET DRIVE NUMBER
EARLY_SETUP:
    mov byte [DRIVE_NUMBER], dl
; SET INTERRUPT HANDLER AND DRAW UI
SETUP:
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0xffff
    ; LOAD EXIT HANDLER
    mov al, 21h
    mov bl, 4h
    mul bl
    mov bx, ax
    mov word [es:bx], EXIT
    add bx, 2
    mov word [es:bx], 0
    ; READ FAT
    call READ_FAT_FROM_DISK
    ; CLEAR SCREEN AND DISABLE CURSOR
    mov ah, 0x00
    mov al, 0x03
    int 10h
    mov ah, 0x01
    mov ch, 0x4f
    int 10h
    ; FIND NEXT ENTRY
    mov bp, 0x0
    call BROWSE_NEXT
LOOP:
    call RENDER_NAME
    mov ah, 0
    int 16h
    cmp ax, 0x4800 ; UP ARROW PRESSED
    je .NEXT
    cmp ax, 0x5000 ; DOWN ARROW PRESSED
    je .PREVIOUS
    cmp ax, 0x1c0d ; ENTER PRESSED
    je .LOAD
    jmp LOOP
.NEXT:
    mov word [FAT_MOVEMENT], 32
    call BROWSE_NEXT
    jmp LOOP
.PREVIOUS:
    mov word [FAT_MOVEMENT], -32
    call BROWSE_NEXT
    jmp LOOP
.LOAD:
    mov bx, bp
    add bx, 26
    mov ax, word [es:bx]
    mov word [FILE_CLUSTER], ax
    add bx, 2
    mov eax, dword [es:bx]
    mov dword [FILE_SIZE], eax
    cmp eax, 65536
    jg LOOP
    call LOAD_EXECUTABLE
.DONE:
    cli
    hlt
times 510 - ($ - $$) db 0
dw 0xaa55
