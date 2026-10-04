.386
.model flat, stdcall
option casemap:none

EXTERN GetStdHandle@4: PROC
EXTERN WriteConsoleA@20: PROC
EXTERN ReadConsoleA@20: PROC
EXTERN ExitProcess@4: PROC
EXTERN lstrlenA@4: PROC
EXTERN wsprintfA: PROC

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
    x       dd ?
    result  dd ?

    ; Буфер для вывода
    outputBuffer db 128 dup(0)

    ; Строки
    msgInput db "Enter binary number: ", 0

    msgDecimal db 13, 10, "Decimal input: ", 0
    msgOctal   db 13, 10, "Result in octal: ", 0
    msgResult  db 13, 10, "Result in decimal: ", 0

    msgError db 13, 10, "Invalid binary number!", 13, 10, 0

    ; Форматы для wsprintfA
    formatDecimal db "%d", 0


.code

main PROC

    ; =========================================
    ; Получаем HANDLE стандартного ввода
    ; =========================================

    push STD_INPUT_HANDLE
    call GetStdHandle@4

    mov hInput, eax


    ; =========================================
    ; Получаем HANDLE стандартного вывода
    ; =========================================

    push STD_OUTPUT_HANDLE
    call GetStdHandle@4

    mov hOutput, eax


    ; =========================================
    ; 1. Вывод приглашения
    ; =========================================

    push offset msgInput
    call PrintString


    ; =========================================
    ; Читаем строку
    ; =========================================

    push 0
    push offset charsRead
    push 127
    push offset inputBuffer
    push hInput
    call ReadConsoleA@20


    ; =========================================
    ; Получаем длину строки
    ; =========================================

    push offset inputBuffer
    call lstrlenA@4

    ; EAX = длина строки

    mov ecx, eax
    mov esi, offset inputBuffer

    ; =========================================
    ; Перевод из двоичной системы
    ;
    ; x = x * 2 + digit
    ; =========================================

    xor eax, eax

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
    shl eax, 1

    jmp next_digit


digit_one:

    ; x = x * 2 + 1
    shl eax, 1
    inc eax


next_digit:

    inc esi
    dec ecx

    jmp convert_loop


convert_done:

    mov x, eax


    ; =========================================
    ; 2. Вывод введенного числа в десятичном
    ; =========================================

    push offset msgDecimal
    call PrintString

    push x
    push offset formatDecimal
    push offset outputBuffer
    call wsprintfA

    push offset outputBuffer
    call PrintString


    ; =========================================
    ; 3. Вычисление полинома
    ;
    ; 5*x^2 + 18*x - 1
    ;
    ; Преобразуем:
    ;
    ; x * (5*x + 18) - 1
    ; =========================================

    mov eax, x

    ; EBX = x
    mov ebx, eax

    ; EAX = 4*x
    shl eax, 1
    shl eax, 1

    ; EAX = 5*x
    add eax, ebx

    ; EAX = 5*x + 18
    add eax, 18

    ; EBX = 5*x + 18
    mov ebx, eax

    ; EAX = x
    mov eax, x

    ; EDX:EAX = x * (5*x + 18)
    mul ebx

    ; EAX = 5*x^2 + 18*x - 1
    dec eax

    mov result, eax


    ; =========================================
    ; 4. Вывод результата в восьмеричной
    ; =========================================

    push offset msgOctal
    call PrintString

    push result
    call PrintOctal


    ; =========================================
    ; 5. Вывод результата в десятичной
    ; =========================================

    push offset msgResult
    call PrintString

    push result
    push offset formatDecimal
    push offset outputBuffer
    call wsprintfA

    push offset outputBuffer
    call PrintString


    ; =========================================
    ; Завершение программы
    ; =========================================

    push 0
    call ExitProcess@4

main ENDP


; =========================================================
; PrintString
;
; Вход:
;     [ESP + 4] = адрес строки
;
; Использует WriteConsoleA
; =========================================================

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

; =========================================================
; PrintOctal
;
; Вход:
;     [ESP + 4] = число
;
; Вывод числа в восьмеричной системе
; =========================================================

PrintOctal PROC

    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]

    ; -----------------------------------------
    ; Если число = 0
    ; -----------------------------------------

    cmp eax, 0
    jne octal_convert

    mov byte ptr [outputBuffer], '0'
    mov byte ptr [outputBuffer + 1], 0

    push offset outputBuffer
    call PrintString

    jmp octal_done


octal_convert:

    xor ecx, ecx

    ; -----------------------------------------
    ; Делим число на 8
    ; -----------------------------------------

octal_divide:

    xor edx, edx

    mov ebx, 8
    div ebx

    ; Остаток = очередная восьмеричная цифра
    add dl, '0'

    ; Сохраняем цифру
    push dx

    inc ecx

    cmp eax, 0
    jne octal_divide


    ; -----------------------------------------
    ; Извлекаем цифры в обратном порядке
    ; -----------------------------------------

    mov edi, offset outputBuffer

octal_write:

    pop dx

    mov [edi], dl

    inc edi

    loop octal_write

    ; Нулевая строка в конце
    mov byte ptr [edi], 0


    ; -----------------------------------------
    ; Выводим полученную строку
    ; -----------------------------------------

    push offset outputBuffer
    call PrintString


octal_done:

    pop ebp
    ret 4

PrintOctal ENDP

; =========================================================
; Ошибка ввода
; =========================================================

input_error:

    push offset msgError
    call PrintString

    push 1
    call ExitProcess@4

END main