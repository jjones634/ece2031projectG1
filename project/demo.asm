;project demo
;limitation, whatever gets displayed in hex1 only goes up to 255
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
	LOAD Lights511
	OUT LEDs
	;determine mode
	DetermineMode:
		CALL Delay
		IN Switches
		STORE SwitchInput
		;determine mode to go into
		SUB Lights ;first switch on
		JZERO GenerateAddress ;regular mode, pick address
		LOAD SwitchInput
		SUB Lights3
		JZERO FillAddress ;other mode, fill addresses
		LOAD SwitchInput
		SUB Lights31
		JZERO AttemptPassword ;enterpassword
		LOAD SwitchInput
		SUB Lights15
		JZERO SearchAddress ;jump to searchaddress
		JUMP DetermineMode
	AttemptPassword:
		LOAD Lights31
		OUT LEDs
		CALL Delay
		IN Switches
		STORE SwitchInput
		ADDI -512
		;if last switch is up at all
		JZERO Start
		JPOS Start
		LOAD SwitchInput
		STORE PasswordInput
		OUT Hex0 ;display Password
		OUT Pass ;give password
		IN Pass ;see if access was granted
		OUT Hex1 ; if 0 denied, if 1 granted
		JUMP AttemptPassword	
	FillAddress:
		LOAD Lights3
		OUT LEDs
		CALL Delay
		IN Switches
		ADDI -512
		;if last switch is up
		JZERO NextPhase
		LOAD Address
		OUT Hex0 ;display the address
		OUT Mem_Add
		LOAD Value
		OUT Hex1 ;display the address
		OUT Mem
		LOAD Address
		ADDI 1
		STORE Address
		LOAD Value
		ADDI 1
		STORE Value
		JUMP FillAddress
	GenerateAddress:
		LOAD Lights
		OUT LEDs
		CALL Delay
		IN Switches
		STORE SwitchInput
		ADDI -512
		;if last switch is up at all
		JZERO WaitValue
		JPOS WaitValue
		;User input address, just dont use last switch
		LOAD SwitchInput
		STORE Address
		OUT Hex0 ;display the address 
		JUMP GenerateAddress
	WaitValue:
		CALL WaitStart
		LOAD Lights
		OUT LEDs
	GenerateValue:
		CALL Delay
		IN Switches
		STORE SwitchInput
		ADDI -512
		;if last switch is up at all
		JZERO StoreInMem
		JPOS StoreInMem
		;User input value, just dont use last switch
		LOAD SwitchInput
		STORE Value
		OUT Hex1 ;display the value 
		JUMP GenerateValue
	StoreInMem:
		;stores address and value
		LOAD Address
		OUT Mem_Add
		LOAD Value
		OUT Mem
	NextPhase:
		CALL WaitStart
		LOAD Lights7
		OUT LEDs ;turn first  3 lights to indicate got to this part
		Decision:
			CALL Delay
			IN Switches
			ADDI -1
			JZERO Start;means only first switch is up, go to the start
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
			LOAD Lights15
			OUT LEDs ;turn first 3 lights to indicate got to this mode
			
			StartSearch:
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
	LOAD Lights512
	OUT LEDs ;turn last light on until done with loop
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
Lights512: DW 512 ;final light (wait start)
Lights511: DW 511 ; 9 lights (determine mode)
Lights: DW 1 ;1 light (generate)
Lights3: DW 3 ;2 lights (fill)
Lights7: DW 7 ;3 lights (next phase decision)
Lights15: DW 15 ;4 lighrs (search addresses)
Lights31: DW 31 ;5 lights (attempt password)
SwitchInput: DW 0
PasswordInput: DW 0
RealPassword: DW 511 ;unused by good reminder


; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Mem_Add:   EQU &H070
Mem:       EQU &H071
Pass:      EQU &H072