;project demo
ORG 0

Start:
	; Init address, value, switchinput, and clear display
	LOAD Zero
	STORE Address
	STORE Value
	STORE SwitchInput
	OUT Hex0
	OUT Hex1
	CALL WaitStart ;wait for all switches down
	GenerateAddress:
		CALL Delay
		IN Switches
		ADDI -512
		;if last switch is up
		JZERO WaitValue
		;increment address if last switch is not up
		LOAD Address
		ADDI 1
		STORE Address
		OUT Hex0 ;display the address 
		JUMP GenerateAddress
	WaitValue:
		CALL WaitStart
	GenerateValue:
		CALL Delay
		IN Switches
		ADDI -512
		;if last switch is up
		JZERO StoreInMem
		;increment address if last switch is not up
		LOAD Value
		ADDI 1
		STORE Value
		OUT Hex1 ;display the address 
		JUMP GenerateValue
	StoreInMem:
		;stores address and value
		LOAD Address
		OUT Mem_Add
		LOAD Value
		OUT Mem
	CALL WaitStart
	LOAD Lights3
	OUT LEDs ;turn first  2 lights to indicate got to this part
	Decision:
		CALL Delay
		IN Switches
		ADDI -1
		JZERO Start;means only first switch is up, make a new address
		;now check if first 2 switches are up
		ADDI -2
		JZERO SearchAddress;means 2 siwtches are up
		;any other combination just loop decision
		JUMP Decision
	SearchAddress:
		;clear out current address and value display
		LOAD Zero
		OUT Hex0
		OUT Hex1
		
		StartSearch:
		
		;CALL WaitStart
		LOAD Lights7
		OUT LEDs ;turn first  7 lights to indicate got to this part
		
		CALL Delay
		IN Switches
		STORE SwitchInput
		
		;if last switch then go to making a new address
		ADDI -512
		JZERO Start
		
		LOAD SwitchInput
		;if anything else, display value and address stored at that input address
		OUT Hex0 ;this will have the address aka switchinput
		OUT Mem_Add
		IN Mem
		OUT Hex1 ; return value at the address
		
		JUMP StartSearch ; loop


; To make things happen on a human timescale, the timer is
; used to delay for 0.1 seconds.
Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -1
	JNEG   WaitingLoop
	RETURN

WaitStart: ;wait for all switches to be down
	LOAD Lights
	OUT LEDs ;turn first light on until done with loop
	LoopStall:
		CALL Delay
		IN Switches
		JZERO Done
		JUMP LoopStall
	Done:
		LOAD Zero
		OUT LEDs ;turn off lights
		RETURN

; Useful values
Address: Dw 0
Value: Dw 0
One:	DW 1
Zero:	DW 0
NegOne:	DW -1
Lights: DW 1
Lights3: DW 3
Lights7: DW 7
SwitchInput: DW 0


; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Mem_Add:   EQU &H070
Mem:       EQU &H071