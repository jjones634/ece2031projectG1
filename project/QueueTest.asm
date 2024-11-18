LOAD Value1
OUT Queue

LOAD Value2
OUT Queue

LOAD Value3
OUT Queue

IN Queue
OUT Queue

IN Queue
OUT Queue


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
Queue:     EQU &H074