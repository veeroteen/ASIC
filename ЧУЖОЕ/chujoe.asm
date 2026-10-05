.386
.MODEL FLAT, STDCALL

;EXTERN позволяет описывать прототипы внешних ф-ий:
EXTERN GetStdHandle@4	:PROC
EXTERN lstrlenA@4		:PROC
EXTERN WriteConsoleA@20	:PROC
EXTERN ReadConsoleA@20	:PROC

;CONST сегмент констант
;sdword - signed double word (Знаковые 32 битные числа)
.CONST
ConstA		sdword	  5
ConstB		sdword	 18
ConstC		sdword	 -1
BaseA		sdword	  2
BaseB		sdword	  8
Base10      sdword	 10

;DB - define byte(Позволяет хранить что-то определенное в 1 байт)
StrOut1		DB	"Enter X in 2 base: ",13,10,0
StrOut2		DB	"Your X in 10 base is: ",13,10,0
StrOut3		DB	"Result in  8 base - ",13,10,0
StrOut4		DB	"Result in 10 base - ",13,10,0
StrOutError	DB	"Error: uncorrect input data! Base is 2.",13,10,0
;13,10,0 - управляющие символы:
;13 - Возврат каретки;
;10 - Переход на новую строку
;0 - терминирующий ноль

;DATA - Сегмент переменных 
.DATA
signVar	sdword	1
varX	sdword  0
buf		sdword  0
base	sdword	0

;_num_ dup - выделить _num_ типов в памяти;
;? в конце строки - неинициализированная память (мусор)
strIn	DB 200 dup (?)
strBuf	DB 10  dup (?)
strOut	DB 200 dup (?)
;DD - Data Doulbeword (Беззнаковые 4 байтовые )
lens	DD ?
dout	DD ?
din		DD ?

.CODE
;Для передачи параметра используется регистр EAX.
;В нем лежит основание системы исчесления, 
;в которой необходимо вывести число.
;=========================================
OutputNumberBase PROC
;Сохраняем переданое основание системы счисления:
MOV base, EAX			

;Обнуляем lens для подсчета длинны строки:
MOV lens, 0
;Сохраняем значение x в EAX для произведения вычислений:
MOV EAX, varX
;Сохраняем ссылку на начало строки, для итерирования:
MOV EDI, OFFSET strOut

;Сравниваем X с нулем:
CMP EAX, 0
;Если больше нуля, то идем сразу в цикл, иначе обрабатываем '-':
JGE FOR5

;Переводим число в положительное (для корректной обработки):
NEG EAX
;Записываем '-' первым символом числа:
MOV BYTE PTR [EDI], '-'
;Переводим строку на второй символ:
INC EDI

;Цикл перевода числа в строку:
FOR5:
	;Обнуление регистра EDX:
    XOR EDX, EDX
	;Делим на основание сис.счис.. Остаток при 
	;целочисленном делении записывается в регистр EDX:
    DIV base
	;Переводим EDX в символ, смещая его на '0', 
	;чтобы получить соответсвующую цифру:
	ADD EDX, '0'
	;Добавляем 1 к длинне строки:
	ADD lens, 1
	;Добавляем в стек символ:
	PUSH EDX
	;Сравниваем EAX с 0:
	CMP EAX, 0
	;Если равен - выходим:
	je FINISH5
JMP FOR5
;Метка выхода:
FINISH5:

;Формирование строки для вывода
;=======================
;ECX - итератор цикла.
;Записываем кол-во необходимых действий для сбора строки:
MOV ECX, lens
FOR6:
	;Достаем символы, положенные в стек:
	POP EAX
	;Кладем младший байт регистра EAX(AL) и дописываем его в
	;строку. Это можно сделать из-за беззнаковости DB:
	MOV [EDI], AL
	;Перемещаем итератор:
	INC EDI
LOOP FOR6

;В конец строки дописываем управ. символы:
;(BYTE) PTR - фиксирует размер разыменованой области. В этом
;случае - одним байтом для записи символа:
MOV BYTE PTR [EDI], 13
MOV BYTE PTR [EDI+1], 10
MOV BYTE PTR [EDI+2], 0
;=======================

;Проверяем знак X. Если X < 0, тогда добавляем к длинне 1:
CMP signVar, 0
JG SKIPNEGATIVE
INC lens
SKIPNEGATIVE:

ADD lens, 2

;Сохранение длинны строки:
MOV EAX, lens

PUSH 0				;5 пар.-Должно быть равно 0
PUSH OFFSET lens	;4 пар.-Буфер для кол-ва выведенных символов
PUSH EAX			;3 пар.-Кол-во выводимых символов
PUSH OFFSET strOut	;2 пар.-Что выводить
PUSH dout			;1 пар.-Дискриптор вывода

;Вызов вывода в консоль с переданными параметрами
CALL WriteConsoleA@20

;Возврат на точку вызова
ret
OutputNumberBase ENDP
;=======================================

MAIN PROC
;Получение дискриптора ввода:
PUSH	-10
CALL	GetStdHandle@4
MOV		din, EAX
;Получение дискриптора вывода:
PUSH	-11
CALL	GetStdHandle@4
MOV		dout, EAX

;Получение длинны строки:
PUSH OFFSET StrOut1
CALL lstrlenA@4

PUSH 0
PUSH OFFSET lens
PUSH EAX
PUSH OFFSET StrOut1
PUSH dout
CALL WriteConsoleA@20


PUSH 0				 ;5 пар.-Должно быть равно 0
PUSH OFFSET lens	 ;4 пар.-Буфер для кол-ва введенных символов
PUSH 200			 ;3 пар.-Кол-во вводимых символов
PUSH OFFSET strIn	 ;2 пар.-Куда записывать
PUSH din			 ;1 пар.-Дискриптор ввода
CALL ReadConsoleA@20

;Проверка корректности введенного числа, + учет его знака
;====================
;убираем последние два символа, 
;которые отвечают за перенос строки:
SUB lens, 2

MOV ESI, OFFSET strIn
MOV ECX, lens
XOR EBX, EBX
XOR EAX, EAX
;Проверка знака:
MOV AL, [ESI]
CMP AL, '-'
JNE FOR1
DEC lens
NEG signVar
INC ESI
MOV ECX, lens
;Проверка, что система двоичная:
FOR1:
	MOV AL, [ESI]
	CMP AL, '0'
	JE GOOD?
	MOV AL, [ESI]
	CMP AL, '1'
	JE GOOD?
	JMP ERROR
	GOOD?:
	INC ESI
LOOP FOR1
JMP GOOD
;====================

;Обработка ошибки:
ERROR:
PUSH OFFSET StrOutError
CALL lstrlenA@4
PUSH 0
PUSH OFFSET lens
PUSH EAX
PUSH OFFSET StrOutError
PUSH dout
CALL WriteConsoleA@20
JMP EXIT

;Успешная проверка:
GOOD:

MOV ECX, lens
MOV ESI, OFFSET strIn
XOR EBX, EBX
XOR EAX, EAX

;Проверка знака:
CMP signVar, 0
JG FOR2
INC ESI

;Парсер числа из строки:
FOR2:
	IMUL EAX, BaseA

	MOV BL, [ESI]
	SUB BL, '0'
	ADD EAX, EBX

	INC ESI
LOOP FOR2

;Учет знака:
CMP signVar, 0
JG RESULT
NEG EAX

;Сохранение 
RESULT:
MOV varX, EAX

PUSH OFFSET StrOut2
CALL lstrlenA@4

PUSH 0
PUSH OFFSET lens
PUSH EAX
PUSH OFFSET StrOut2
PUSH dout
CALL WriteConsoleA@20

;Сохранение в регистр необходимого основания:
MOV EAX, Base10
;Вызов пользовательской функции:
CALL OutputNumberBase

;Считать полином
MOV EAX, varX
IMUL varX
IMUL constA
MOV buf, EAX
MOV EAX, varX
IMUL constB
ADD EAX, buf
ADD EAX, constC

MOV varX, EAX

PUSH OFFSET StrOut3
CALL lstrlenA@4

PUSH 0
PUSH OFFSET lens
PUSH EAX
PUSH OFFSET StrOut3
PUSH dout
CALL WriteConsoleA@20

MOV EAX, BaseB
CALL OutputNumberBase

PUSH OFFSET StrOut4
CALL lstrlenA@4

PUSH 0
PUSH OFFSET lens
PUSH EAX
PUSH OFFSET StrOut4
PUSH dout
CALL WriteConsoleA@20

MOV EAX, Base10
CALL OutputNumberBase

EXIT:
ret
MAIN ENDP
END MAIN