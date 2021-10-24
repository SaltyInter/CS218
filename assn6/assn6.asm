; Assignment #6
; Author: Matthew Shiroma
; Name: Matthew Shiroma
; Section: 1004
; Date Last Modified: 10-24-21
; This program	will calculate floating point numbers and use extern to call
; c++ function

; yasm -g dwarf2 -f elf64 assn6.asm
; g++ -g -no-pie helper.cpp assn6.o
; ./a.out

section .data
;externs
extern atof, ceil, printBalloonsRequired

;	System Service Constants
	SYSTEM_EXIT 				equ 60
	SUCCESS 					equ 0
	SYSTEM_READ 				equ 0 
	STANDARD_IN 				equ 0
	SYSTEM_WRITE 				equ 1
	STANDARD_OUT 				equ 1

; 	Constants
	LF 							equ 10
	NULL						equ 0

;	String messages
	oneArgMsg					db "ERROR: Only a single command line argument was used", LF, NULL
	incorrectNumOfArgsMsg		db "ERROR: Incorrect Number of arguments inputed", LF, NULL
	unexpectedArg2Msg			db "ERROR: Unexpected argument 2 value", LF, NULL
	unexpectedArg4Msg			db "ERROR: Unexpected argument 4 value", LF,NULL
	invalidNumMsg				db "ERROR: Numbers inputed must be greater than 0.0", LF,NULL
	expectedArgInputMsg			db "Example of expected input is: ./a.out -W <num> -D <num>", LF,NULL
	
	;Numerical vars
	Zero						dq 0
	Weight						dd 0.0
	Diameter					dd 0.0
	HeliumLift					dq 0.06689
	PI							dq 3.14159

section .bss

section .text

;Code from assn5 for string output and length:
;Finds the length of null terminated string
;Return in 32 bit value
;arg 1 rdi: address to string
global getStrLength
getStrLength:

	mov rax, 0		;counter	
	
	getStrLengthLoop:
		cmp byte[rdi + rax], NULL		;check if its null
			je getStrLengthLoopDone	;if null skip to end
			inc rax								;if not null it will inc counter
			jmp getStrLengthLoop		;and jump back up
	getStrLengthLoopDone:	
	
ret

;Print NULL terminated string
;No return value
;arg1 rdi: address to string
global printStr
printStr:

	mov r10, rdi		;move into temp reg
	
	call getStrLength
	mov r11, rax		;put string length into r11
	
	;Print out message
	mov rax, SYSTEM_WRITE
	mov rsi, r10							;got message adress from arg 1
	mov rdi, STANDARD_OUT
	mov rdx, r11							;got count from getStrLength
	syscall
	
ret
;End of assn5 code

;Fuction that will check and convert the command line args
; Arg 1.) rdi - argc 
; Arg 2.) rsi - argv
; Arg 3.) rdx - weight var address
; Arg 4.) rcx - diameter var address

; Returns:	argc is 1 		 return 0
;			argc != 5 		 return -1
;			arg 2 != "-W"	 return -2
;			arg 4 != "-D"	 return -4
; if either double value 0.0 or less	return -3
;			return 1 if success
global proccessCommandLine
proccessCommandLine:
;	rdi = argc
;	rsi = argv

;preservered registers
push rbx
push r12
push r13

mov rcx, 0		;used for chars later

cmp rdi, 1	;only 1 arg was sent
	je oneArgERROR

cmp rdi, 5	;not correct amount of args
	jne incorrectNumOfArgs

;arg 2 != "-W"	 return -2
mov rcx, qword[rsi + 8]		;go to the 2nd arg
cmp byte[rcx], "-"			;Check if it equal to expect input
	jne arg2ERROR			;jump if its not equal
cmp byte[rcx+1], "W"
	jne arg2ERROR
cmp byte[rcx+2], NULL		;check if string has ended
	jne arg2ERROR			;string did not end

;arg 4 != "-D"	 return -4
mov rcx, qword[rsi + 24]	;go to the 4th arg
cmp byte[rcx], "-"			;Check if it equal to expect input
	jne arg4ERROR			;jump if its not equal
cmp byte[rcx+1], "D"
	jne arg4ERROR
cmp byte[rcx+2], NULL		;check if string has ended
	jne arg4ERROR			;string did not end

;Check Floats if they are greater than 0
;Checking arg 3 the weight

;Place into temp registers as function calls will mess up rsi
mov r12, qword[rsi + 16]
mov r13, qword[rsi + 32]

;Move stack by multiple of 16 before c++ function
mov rax, rsp
mov rdx, 0
mov rcx, 16
div rcx
sub rsp, rdx
mov rbx, rdx

mov rdi, r12					;get the value from argv
call atof						;call c++ function
cvtsd2ss xmm0, xmm0
add rsp, rbx					;restore stack pointer
ucomisd xmm0, qword[Zero]		;check if less than 0
	jbe incorrectNumValueERROR	;jump if <= 0 since its an error
movss dword[Weight], xmm0
;Checking arg 4 the diameter of ballon

;Move stack by multiple of 16 before c++ function
mov rax, rsp
mov rdx, 0
mov rcx, 16
div rcx
sub rsp, rdx
mov rbx, rdx

mov rdi, r13					;get the value from argv
call atof						;call c++ function
cvtsd2ss xmm0, xmm0
add rsp, rbx					;restore stack pointer
ucomisd xmm0, qword[Zero]		;check if less than 0
	jbe incorrectNumValueERROR	;jump if <= 0 since its an error
movss dword[Diameter], xmm0
;Passed all checks so return a success
mov rax, 1
jmp endProccessCommandLine

;ERROR returns:
;--------------------
;Sets up return values for the function
;Then jumps to end of the function where it returns
oneArgERROR:
	mov rax, 0
	jmp endProccessCommandLine

incorrectNumOfArgs:
	mov rax, -1
	jmp endProccessCommandLine

incorrectNumValueERROR:
	mov rax, -3
	jmp endProccessCommandLine

arg2ERROR:
	mov rax, -2
	jmp endProccessCommandLine

arg4ERROR:
	mov rax, -4
	jmp endProccessCommandLine


endProccessCommandLine:		;end the function with error return
;pop preserved registers
pop r13
pop r12
pop rbx

ret

;Fuction that calculates the numbers of ballons required to lift
;Using STL ceil to round up to whole number
global ballonCalculations
ballonCalculations:

;Get weight and diameter into registers
movss xmm0, dword[Weight]
movss xmm1, dword[Diameter]
cvtss2sd xmm0, xmm0		;increase size for calculations
cvtss2sd xmm1, xmm1	

;Find ballon volume
;Use xmm3 for holding volume
;Use xmm4 as temp register to hold intermediate values

;4/3 into volume
mov ecx, 4
cvtsi2sd xmm4, ecx			;temp reg to hold four
movsd xmm3, xmm4 			;move 4 into volume
mov ecx, 3
cvtsi2sd xmm4, ecx			;temp reg to hold three
divsd xmm3, xmm4			;4/3 into volume

;Volume times PI
mulsd xmm3, qword[PI]

;Get (diameter/2)^3
mov ecx, 2
cvtsi2sd xmm4, ecx			;temp reg to hold 2
divsd xmm1, xmm4			;divide diameter by 2
movsd xmm8, xmm1			;temp reg to hold diameter/2
mulsd xmm1, xmm8			;to the second power
mulsd xmm1, xmm8			;to the third power

;Ballon volume times (diameter/2)^3
mulsd xmm3, xmm1

;Ballon volume times helium Lift
mulsd xmm3, qword[HeliumLift]

;Weight divied by (Ballon volume times helium Lift)
divsd xmm0, xmm3

;Move stack by multiple of 16 before c++ function
mov rax, rsp
mov rdx, 0
mov rcx, 16
div rcx
sub rsp, rdx
mov rbx, rdx

call ceil						;call c++ function places into rax
add rsp, rbx					;restore stack pointer

ret

;Main
global main
main:

;call proccessCommandLine and recieve return based on error to output
; Returns:	argc is 1 		 return 0
;			argc != 5 		 return -1
;			arg 2 != "-W"	 return -2
;			arg 4 != "-D"	 return -4
; if either double value 0.0 or less	return -3
call proccessCommandLine

;compare rax to output correct error
;mov correct error message into rdi then jump to an output function
;if no errors are found skip this
cmp rax, 0
	jne skipErrorCheck1
	mov rdi, oneArgMsg
	jmp outputERROR
skipErrorCheck1:

cmp rax, -1
	jne skipErrorCheck2
	mov rdi, incorrectNumOfArgsMsg
	jmp outputERROR
skipErrorCheck2:

cmp rax, -2
	jne skipErrorCheck3
	mov rdi, unexpectedArg2Msg
	jmp outputERROR
skipErrorCheck3:

cmp rax, -4
	jne skipErrorCheck4
	mov rdi, unexpectedArg4Msg
	jmp outputERROR
skipErrorCheck4:

cmp rax, -3
	jne skipErrorCheck5
	mov rdi, invalidNumMsg
	jmp outputERROR
skipErrorCheck5:

;Passed all the checks
jmp skipErrorOutput

;outputs error and expected inputs
outputERROR:
call printStr
mov rdi, expectedArgInputMsg
call printStr
jmp endProgram		;end the program

;No Errors were found so continue with program
skipErrorOutput:

;Move stack by multiple of 16 before c++ function
mov rax, rsp
mov rdx, 0
mov rcx, 16
div rcx
sub rsp, rdx
mov rbx, rdx

;Passing values to print function
;Move total ballons needed
call ballonCalculations
movsd xmm2, xmm0
;Move weight
movss xmm0, dword[Weight]
cvtss2sd xmm0, xmm0
;Move Diameter
movss xmm1, dword[Diameter]
cvtss2sd xmm1, xmm1

call printBalloonsRequired
add rsp, rbx					;restore stack pointer

endProgram:
	mov rax, SYSTEM_EXIT
	mov rdi, SUCCESS
	syscall