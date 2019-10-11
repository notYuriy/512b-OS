bits 16
jmp code
data:
fizzbuzz: db "FizzBuzz", 0
fizz: db "Fizz", 0
buzz: db "Buzz", 0
term: db 13, 10, 0
procedures:
    puti:
        pusha
        cli
        call puti_rec
        popa
        ret
    puti_rec:
        cmp ax, 0
        je .end
        sti
        xor dx, dx
        mov bx, 10
        div bx
        push dx
        call puti_rec
        pop dx
        mov al, '0'
        add al, dl
        mov ah, 0eh
        mov bl, 0x7f
        int 10h
        ret
    .end:
        jnc .noprint
        mov ah, 0eh
        mov al, '0'
        mov bl, 0x7f
        int 10h
    .noprint:
        ret

    puts:
        pusha
    .ploop:
        lodsb
        cmp al, 0
        je .done
        mov ah, 0eh
        int 10h
        jmp .ploop
    .done:
        popa
        ret


code:
    mov cx, 1
.fbloop:
    cmp cx, 16
    je .end
    mov ax, cx
    xor dx, dx
    mov bx, 15
    div bx
    cmp dx, 0
    je .fifteen
    mov ax, cx
    xor dx, dx
    mov bx, 5
    div bx
    cmp dx, 0
    je .five
    mov ax, cx
    xor dx, dx
    mov bx, 3
    div bx
    cmp dx, 0
    je .three
    jmp .num
.fifteen:
    mov si, fizzbuzz
    call puts
    jmp .term
.five:
    mov si, buzz
    call puts
    jmp .term
.three:
    mov si, fizz
    call puts
    jmp .term
.num:
    mov ax, cx
    call puti
.term:
    mov si, term
    call puts
    inc cx
    jmp .fbloop
.end:
    xor ah, ah
    int 16h
    int 21h