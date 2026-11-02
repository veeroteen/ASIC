.386
.model flat, stdcall
option casemap:none
.data
    currentChar BYTE 0
.code

PUBLIC _CompressString@12

_CompressString@12 PROC

    push ebp
    mov ebp, esp

    push ebx
    push esi
    push edi

    cld

    mov eax, [ebp + 16]
    test eax, eax
    jz compress_return


    mov esi, [ebp + 8]
    mov ebx, [ebp + 12]
    xor edx, edx

compress_loop:

    mov al, [esi]
    mov currentChar, al

    test al, al
    jz compress_done

    mov edi, [ebp + 12]
    mov ecx, edx

    test ecx, ecx
    jz add_unique

    repne scasb
    je next_char

add_unique:

    mov eax, [ebp + 16]
    dec eax
    cmp edx, eax
    jae compress_done

    mov al, currentChar

    mov edi, ebx
    stosb
    mov ebx, edi

    inc edx

next_char:

    inc esi
    jmp compress_loop

compress_done:

    mov byte ptr [ebx], 0

compress_return:

    pop edi
    pop esi
    pop ebx

    pop ebp
    ret 12

_CompressString@12 ENDP

END