.386
.model flat, stdcall
option casemap:none

EXTERN GetStdHandle@4: PROC
EXTERN WriteConsoleA@20: PROC
EXTERN ReadConsoleA@20: PROC
EXTERN ExitProcess@4: PROC
EXTERN lstrlenA@4: PROC

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11

.data
    hInput       dd ?
    hOutput      dd ?

    inputBuffer  db 128 dup(0)
    outputBuffer db 128 dup(0)
    charsRead    dd ?
    outputLength dd 0

    msgInput db "Enter string to compres: ", 0
    msgOutput db "Result string: ", 0
.code

main PROC

    push STD_INPUT_HANDLE
    call GetStdHandle@4
    mov hInput, eax

    push STD_OUTPUT_HANDLE
    call GetStdHandle@4
    mov hOutput, eax

    push offset msgInput
    call PrintString

    push 0
    push offset charsRead
    push 127
    push offset inputBuffer
    push hInput
    call ReadConsoleA@20

    cld

    mov esi, offset inputBuffer
    mov ebx, offset outputBuffer
    mov outputLength, 0

compress_loop:

    mov al, [esi]

    ; Проверяем конец ввода
    cmp al, 13
    je compress_done

    cmp al, 10
    je compress_done

    mov edi, offset outputBuffer
    mov ecx, outputLength

    test ecx, ecx
    jz add_unique

    repne scasb

    je next_char

add_unique:

    mov edi, ebx
    stosb
    mov ebx, edi

    inc outputLength

next_char:

    inc esi
    jmp compress_loop

compress_done:

    mov byte ptr [ebx], 0
    push offset msgOutput
    call PrintString
    push offset outputBuffer
    call PrintString

    push 0
    call ExitProcess@4

main ENDP


PrintString PROC

    push ebp
    mov ebp, esp

    mov esi, [ebp + 8]

    push esi
    call lstrlenA@4

    push 0
    push offset charsRead
    push eax
    push esi
    push hOutput
    call WriteConsoleA@20

    pop ebp
    ret 4

PrintString ENDP

END main