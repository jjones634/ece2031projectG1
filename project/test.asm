LOAD Address
OUT Mem_Add
LOAD Value
OUT Mem

LOAD Address2
OUT Mem_Add
LOAD Value2
OUT Mem

Load Address
OUT Mem_Add
IN Mem
OUT Hex1 ; return 5

LOAD Address3
OUT Mem_Add
LOAD Value3
OUT Mem

Load Address3
OUT Mem_Add
IN Mem
OUT Hex0 ; return 22


Here:
JUMP Here



Address: Dw 2
Address2: Dw 90
Address3: Dw 3
Value: Dw 5
Value2: Dw 9
Value3: Dw 22


; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Mem_Add:   EQU &H070
Mem:       EQU &H071