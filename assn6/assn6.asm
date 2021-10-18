; Assignment #6
; Author: Matthew Shiroma
; Name: Matthew Shiroma
; Section: 1004
; Date Last Modified: 
; This program

; yasm -g dwarf2 -f elf64 assn6.asm
; g++ -g -no-pie helper.cpp assn6.o
; ./a.out

section .data
;externs
extern atof, ceil, printBallonsRequired

;	System Service Constants
	SYSTEM_EXIT 				equ 60
	SUCCESS 					equ 0
	SYSTEM_READ 				equ 0 
	STANDARD_IN 				equ 0
	SYSTEM_WRITE 				equ 1
	STANDARD_OUT 				equ 1
	LF 							equ 10
	NULL						equ 0

;	String messages
	oneArgMsg					db "ERROR: Only a single command line argument was used", LF, NULL
	incorrectNumOfArgsMsg		db "ERROR: Incorrect Number of arguments inputed", LF, NULL
	unexpectedArg2Msg			db "ERROR: Unexpected argument 2 value", LF, NULL
	unexpectedArg4Msg			db "ERROR: Unexpected argument 4 value", LF,NULL
	invalidNumMsg				db "ERROR: Numbers inputed must be greater than 0.0", LF,NULL
	expectedArgInputMsg			db "Example of expected input is: ./a.out -W <num> -D <num>", LF,NULL

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
; Arg 3.) rdx - weight value float
; Arg 4.) rcx - diameter value float

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

;ANOTHER CHECK ADD LATER

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

arg2ERROR:
	mov rax, -2
	jmp endProccessCommandLine

arg4ERROR:
	mov rax, -4
	jmp endProccessCommandLine

endProccessCommandLine:		;end the function with error return
ret

;Fuction that calculates the numbers of ballons required to lift
;Using STL ceil to round up to whole number
global ballonCalculations
ballonCalculations:

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

skipErrorOutput:

endProgram:
	mov rax, SYSTEM_EXIT
	mov rdi, SUCCESS
	syscall