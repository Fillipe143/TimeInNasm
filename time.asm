section .data
    in_msg db "Informe um fuso horário (ex: -3): "
    in_msg_len equ $ -in_msg

    err_msg db "Fuso horário inválido.", 10, "Formatos aceitos: (\+|-)\d{1,2}", 10
    err_msg_len equ $ -err_msg
    
    out_msg db "Horário atual: "
    out_msg_len equ $ -out_msg

section .text
global _start
_start:
    ;; print input message
    mov rsi, in_msg
    mov rdx, in_msg_len
    call print
    
    ;; read input
    xor rax, rax
    xor rdi, rdi
    lea rsi, [rsp]
    mov rdx, 4
    syscall

    ;; parse input
    call parse_input
    push rax

    ;; rax = current timestamp
    mov rax, 201
    xor rdi, rdi
    syscall

    ;; convert do timezone
    pop rdi
    add rax, rdi

    ;; rax = minutes ;; rdx = seconds
    xor rdx, rdx
    mov rdi, 60
    div rdi

    ;; stack -> seconds
    push rdx

    ;; rax = hours ;; rdx = minutes
    xor rdx, rdx
    mov rdi, 60
    div rdi

    ;; stack -> minutes, seconds
    push rdx

    ;; rax = days ;; rdx = hours 
    xor rdx, rdx
    mov rdi, 24
    div rdi

    ;; stack -> hours, minutes, seconds
    push rdx

    ;; print input message
    mov rsi, out_msg
    mov rdx, out_msg_len
    call print

    ;; print hours
    pop rax
    call print_zero_is_less_than_ten
    call print_int

    ;; print :
    mov al, 58
    call print_char
    
    ;; print minutes
    pop rax
    call print_zero_is_less_than_ten
    call print_int

    ;; print :
    mov al, 58
    call print_char

    ;; print seconds
    pop rax
    call print_zero_is_less_than_ten
    call print_int

    ;; print \n
    mov al, 10
    call print_char

    ;; exit 0
    mov rax, 60
    xor rdi, rdi
    syscall

parse_input:
    ;; al = rsi[0]
    xor rax, rax
    mov al, BYTE [rsi]

    ;; al == '+': continue
    cmp al, 43
    je .continue

    ;; al != '-': exit
    cmp al, 45
    jne .exit_with_error

    .continue:
        xor rdi, rdi

        ;; dl = rsi[1]
        inc rsi
        xor rdx, rdx
        mov dl, BYTE [rsi]

        ;; dl < '0':  exit
        cmp dl, 48
        jl .exit_with_error

        ;; dl > '9':  exit
        cmp dl, 57
        jg .exit_with_error

        ;; char number to int
        sub rdx, 48
        imul rdi, 10
        add rdi, rdx

        ;; dl = rsi[1]
        inc rsi
        xor rdx, rdx
        mov dl, BYTE [rsi]

        ;; dl < '0':  exit
        cmp dl, 48
        jl .exit

        ;; dl > '9': exit
        cmp dl, 57
        jg .exit

        ;; char number to int
        sub rdx, 48
        imul rdi, 10
        add rdi, rdx

    .exit:
        ;; parse to hours
        imul rdi, 3600

        ;; al == '+': sum
        cmp al, 43
        jne .else

        mov rax, rdi
        ret

        .else:
            sub rax, rdi
            ret

    .exit_with_error:
        ;; Show error message
        mov rsi, err_msg
        mov rdx, err_msg_len
        call print

        ;; exit 1
        mov rax, 60
        mov rdi, 1
        syscall
    ret


print:
    mov rax, 1
    mov rdi, 1
    syscall
    ret

print_int:
    call int_to_string
    mov rdx, r8
    call print
    ret

print_char:
    mov BYTE [rsp-1], al
    lea rsi, [rsp-1]
    mov rdx, 1

    mov rax, 1
    mov rdi, 1
    syscall
    ret

print_zero_is_less_than_ten:
    cmp rax, 10
    jl .print_zero
    ret

    .print_zero:
        push rax
        mov rax, 48
        call print_char
        pop rax
        ret

int_to_string:
    xor r8, r8
    mov rsi, rsp
    mov rcx, 10

    .next_digit:
        xor rdx, rdx

        idiv rcx
        add rdx, 48

        dec rsi
        mov [rsi], dl
        add r8, 1

        cmp rax, 0
        jne .next_digit
        ret
