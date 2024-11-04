LOAD Address
OUT Mem_Add
LOAD Value
OUT Mem
OUT Hex1
Load Address
OUT Mem_Add
IN Mem
OUT Hex0
Here:
JUMP Here



Address: Dw 2
Value: Dw 5


; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Mem_Add:   EQU 070
Mem:       EQU 071