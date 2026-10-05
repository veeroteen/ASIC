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

    hInput  dd ?
    hOutput dd ?

    ; Буфер ввода
    inputBuffer db 128 dup(0)

    ; Сколько символов реально прочитано
    charsRead dd ?

    ; Переменные
    result  dd ?
    decimal dd 0
    binary dd 0
    octal dd 0
    sign dd 0
    ; Буфер для вывода
    outputBuffer db 128 dup(0)

    ; Строки
    msgInput db "Enter binary number: ", 0

    msgBinnary db 13, 10, "Binary input:", 0
    msgDecimal db 13, 10, "Decimal input: ", 0
    msgOctal   db 13, 10, "Result in octal: ", 0
    msgResult  db 13, 10, "Result in decimal: ", 0

    msgError db 13, 10, "Invalid binary number!", 13, 10, 0




.code

main PROC

    ; Получаем HANDLE стандартного ввода
    push STD_INPUT_HANDLE
    call GetStdHandle@4

    mov hInput, eax

    ; Получаем HANDLE стандартного вывода
    push STD_OUTPUT_HANDLE
    call GetStdHandle@4

    mov hOutput, eax

    ; 1. Вывод инструкции
    push offset msgInput
    call PrintString

    ; Читаем строку
    push 0
    push offset charsRead
    push 127
    push offset inputBuffer
    push hInput
    call ReadConsoleA@20

    ; Получаем длину строки
    push offset inputBuffer
    call lstrlenA@4

    ; EAX = длина строки
    mov ecx, eax
    mov esi, offset inputBuffer

    xor eax, eax
    xor edx, edx
    

    ; Проверяем первый символ
    mov bl, [esi]

    cmp bl, '-'
    jne convert_loop

    ; Если первый символ '-', запоминаем отрицательное число
    mov sign, 1

    inc esi
    dec ecx

convert_loop:

    cmp ecx, 0
    je convert_done

    ; Берем очередной символ
    mov bl, [esi]

    ; Проверяем '0'
    cmp bl, '0'
    je digit_zero

    ; Проверяем '1'
    cmp bl, '1'
    je digit_one

    ; Если это CR/LF — заканчиваем ввод
    cmp bl, 13
    je convert_done

    cmp bl, 10
    je convert_done

    ; Иначе ошибка
    jmp input_error


digit_zero:

    ; x = x * 2
    shl edx, 1
    imul eax, eax, 10
    jmp next_digit


digit_one:

    ; x = x * 2 + 1
    shl edx, 1
    inc edx

    imul eax, eax, 10
    inc eax
    


next_digit:

    inc esi
    dec ecx

    jmp convert_loop


convert_done:

    ; Если число отрицательное — меняем знак
    cmp sign, 1
    jne number_ready

    
    neg eax
    neg edx
    
number_ready:
    mov binary, eax
    mov decimal, edx

    ; 1. Вывод введеного числа в двоичном
    push offset msgBinnary
    call PrintString

    push binary
    call PrintDecimal

    ; 2. Вывод введенного числа в десятичном
    push offset msgDecimal
    call PrintString

    push decimal
    call PrintDecimal

    ; Вычисление полинома
    ; 5*x^2 + 18*x - 1

    ; 5x^2 в ecx
    mov eax, decimal
    imul eax
    mov edx, 5
    imul edx
    mov ecx, eax

    ; 18x
    mov eax, decimal
    mov edx, 18
    imul edx

    ; + 18x
    add ecx, eax

    ; -1
    sub ecx, 1

    mov result, ecx

    ; Вывод результата в восьмеричной
    push offset msgOctal
    call PrintString

    push result
    call ConvertToOctal
    push octal
    call PrintDecimal

    ; Вывод результата в десятичной
    push offset msgResult
    call PrintString

    push result
    call PrintDecimal


    push 0
    call ExitProcess@4

main ENDP

PrintString PROC

    push ebp
    mov ebp, esp

    ; Получаем адрес строки
    mov esi, [ebp + 8]

    ; Получаем длину строки
    push esi
    call lstrlenA@4

    ; EAX = длина
    push 0
    push offset charsRead
    push eax
    push esi
    push hOutput
    call WriteConsoleA@20

    pop ebp
    ret 4

PrintString ENDP
PrintDecimal PROC
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]

    ; Проверяем знак
    cmp eax, 0
    jge decimal_positive

    ; Выводим '-'
    mov byte ptr [outputBuffer], '-'
    mov byte ptr [outputBuffer + 1], 0

    push eax
    push offset outputBuffer
    call PrintString
    pop eax

    neg eax

decimal_positive:

    ; Отдельно обрабатываем 0
    cmp eax, 0
    jne decimal_convert

    mov byte ptr [outputBuffer], '0'
    mov byte ptr [outputBuffer + 1], 0

    push offset outputBuffer
    call PrintString
    jmp decimal_done


decimal_convert:

    xor ecx, ecx

decimal_divide:

    xor edx, edx
    mov ebx, 10
    div ebx

    add dl, '0'

    push dx
    inc ecx

    cmp eax, 0
    jne decimal_divide


    mov edi, offset outputBuffer

decimal_write:

    pop dx
    mov [edi], dl
    inc edi

    loop decimal_write

    mov byte ptr [edi], 0

    push offset outputBuffer
    call PrintString


decimal_done:

    pop ebp
    ret 4
PrintDecimal ENDP

ConvertToOctal PROC
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]

    mov octal, 0

    ; sign = 0 -> положительное
    ; sign = 1 -> отрицательное
    mov sign, 0

    cmp eax, 0
    jge positive

    mov sign, 1
    neg eax

positive:

    ; Отдельный случай: 0
    cmp eax, 0
    jne octal_convert

    mov octal, 0
    jmp octal_done


octal_convert:

    xor ecx, ecx

octal_divide:

    xor edx, edx
    mov ebx, 8
    div ebx

    ; Сохраняем очередную цифру
    push edx
    inc ecx

    cmp eax, 0
    jne octal_divide


    ; Собираем цифры в обратном порядке
    xor ebx, ebx

octal_write:

    pop edx

    ; EBX = EBX * 10 + цифра
    imul ebx, ebx, 10
    add ebx, edx

    loop octal_write

    mov octal, ebx


octal_done:

    ; Если исходное число было отрицательным
    cmp sign, 1
    jne convert_done

    neg octal

convert_done:

    pop ebp
    ret 4

ConvertToOctal ENDP

; Ошибка ввода

input_error:

    push offset msgError
    call PrintString

    push 1
    call ExitProcess@4

END main