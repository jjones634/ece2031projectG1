LOAD Value1
OUT Stack

LOAD Value2
OUT Stack

LOAD Value3
OUT Stack

IN Stack
OUT Hex0

IN Stack
OUT Hex1


Here:
JUMP Here

Value1: Dw 5
Value2: Dw 9
Value3: Dw 22


; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Stack:     EQU &H073