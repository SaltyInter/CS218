; Assignment #7
; Author: Matthew Shiroma
; Name: Matthew Shiroma
; Section: 1004
; Date Last Modified: 10-24-21
; This program	will calculate floating point numbers and use extern to call
; c++ function

; yasm -g dwarf2 -f elf64 assn7.asm
; g++ -g -no-pie assn7.o
; ./a.out

section .data
;externs

;	System Service Constants
	SYSTEM_EXIT 				equ 60
	SUCCESS 					equ 0
	SYSTEM_READ 				equ 0 
	STANDARD_IN 				equ 0
	SYSTEM_WRITE 				equ 1
	STANDARD_OUT 				equ 1
	SYSTEM_CLOSE				equ 3

	;File Constants
	SYS_OPEN					equ 2
	O_RDONLY					equ 000000q
	O_WRONLY					equ 000001q
	O_RDWR						equ 000002q

; 	Constants
	LF 							equ 10
	NULL						equ 0
	BUFFER_SIZE					equ 100000

;	String messages
	
	invalidArgMsg				db "Invalid argument.", LF, NULL
	incorrectNumOfArgsMsg		db "Incorrect number of arguments.", LF, NULL
	;I know this is long but idk how to use multiple lines in assembly for one statement
	howToUseMsg					db "To use this program include the name of the file you wish to analyze", LF, "-echo may be added to print the file to the terminal.", LF, NULL
	cantOpenTextPart1			db "Could not open ", 34, NULL
	cantOpenTextPart2			db 34, ".", LF, NULL
	fileReadERRORMsg			db "There was an error while reading file! ", LF, NULL
	wordCountMsg				db LF, "Word Counter: ", NULL
	avgWordLengthMsg			db "Average Word Length: ", NULL
	fileTestMsg					db "File text: ", LF, NULL

	;Numerical vars
	charactersRead				dq 0
	charactersBuffered			dq 0
	eofReached					dq 0
	echoUsed					dq 0	;1 if used 0 if not

	;vars used by main primarly
	wordCount					dd 0
	charAvg						dd 0
	charVar						dq 0

section .bss
	buffer				resb BUFFER_SIZE
	fileDescriptor 		resw 1

	stringOutput1 resb 12
	stringOutput2 resb 12

section .text

;code from assn4 to convert a int to a string
%macro int32ToString 2
	; Your Code Here
	mov rax, 0		;mul and div	
	mov r8d, 0		;to hold if the number is postitive or neg 0 = pos | 1 = neg
	mov r9d, 0		;keep track of push and pops
	mov r10d, 10	;hold the value 10 for dividing
	mov r11, 0		;hold the value passed in
	
	mov r11d, %1
	cmp r11d, 0
	jge %%skipSignCheck	;If its >= 0 then it will skip
		mov r8d, 1				;didn't skip so its a neg value
		imul r11d, r11d, -1		;change it to pos value
	%%skipSignCheck:
	
	%%intToStrLoop:
		mov eax, r11d
		cdq
		idiv r10d			;divide by r10d holds the value 10. store in eax:edx 
		mov ecx, edx
		push rcx
		inc r9d
		cmp eax, 0		;if its 0 it is done
			je %%endIntLoop
		mov r11d, eax
		jmp %%intToStrLoop
	%%endIntLoop:
		
	;Assemble string
	;check if it was posititve
	mov rbx, 0		;indexing
	cmp r8d, 0
		je %%skipSignChangeStr	;It was 0 so it is postitive
			mov byte[%2 + rbx], '-'		;Place - sign
			inc rbx
	%%skipSignChangeStr:
	
	%%stringAssembleLoop:
	pop rax		;get the numbers from stack
	add rax, '0'	;move ascii values to numbers
	mov byte[%2 + rbx], al		;parse number from stack into string
	inc rbx
	
	dec r9d
	cmp r9d, 0
		jne %%stringAssembleLoop
		
	mov byte[%2 + rbx], LF	
	inc rbx
	mov byte[%2 + rbx], NULL		;add null to the end
	
%endmacro

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

;Process the command line and determine what is supposed to run
; Arg 1.) rdi - argc 
; Arg 2.) rsi - argv

;Returns|	Value meaning:
;1			success
;-1			invalid argument
;-2			incorrect num of args
;-3			only 1 arg sent
;-4			cannot open text file.
global commandLineArg
commandLineArg:

	;only one arg
	cmp rdi, 1		;Check if argc is 1
		je oneArgERROR

	;incorrect num of args
	cmp rdi, 3		;check if there is more than 3 args
		ja incorrectNumOfArgs

	;check -echo
	cmp rdi, 3		;check if echo was passed
		jne skipEchoCheck	;Not 3 args so echo wasnt passed
		;Check if echo was passed in correctly
		mov rcx, qword[rsi + 16]	;go to the 3rd arg
		cmp byte[rcx], "-"			;Check if it equal to expect input
			jne invalidArg			;jump if its not equal
		cmp byte[rcx+1], "e"
			jne invalidArg
		cmp byte[rcx+2], "c"
			jne invalidArg
		cmp byte[rcx+3], "h"
			jne invalidArg
		cmp byte[rcx+4], "o"
			jne invalidArg
		cmp byte[rcx+5], NULL		;check if string has ended
			jne invalidArg			;string did not end
		;pass check if it gets here without jumping
		mov qword[echoUsed], 1
	skipEchoCheck:

	;open file check
	mov rax, SYS_OPEN
	mov rdi, qword[rsi+8]
	mov rsi, O_RDONLY
	syscall

	;check if was a success opeing
	cmp rax, 0
		jle fileOpenERROR		;if lower than 0 an error has occured
	mov word[fileDescriptor], ax	;move the file descriptor into a var for later use

	;Skip error checks as it got here normally without jump to an error
	mov rax, 1		;return success
	jmp endOfFunc

	;ERROR returns:
	;--------------------
	;Sets up return values for the function
	;Then jumps to end of the function where it returns
	fileOpenERROR:
		mov rax, -4
		jmp endOfFunc

	oneArgERROR:
		mov rax, -3
		jmp endOfFunc

	incorrectNumOfArgs:
		mov rax, -2
		jmp endOfFunc

	invalidArg:
		mov rax, -1
		jmp endOfFunc
		

endOfFunc:
;epilog

ret
;end of commandLineArg

;Function that will calculate the average word length
;arg 1.) number of words by ref
;	 2.) calulated calculate average word length
global getWordCountAndAverage
getWordCountAndAverage:

	;need local variable to hold char
	;push rbp
	push r12	;hold address of arg 1
	push r13	;hold address of arg 2
	push r14	;used as a bool for word counting
	;mov rbp, rsp
	;sub rsp, 1	;char rbp-1

	;zero out regs
	mov rax, 0
	mov rcx, 0
	mov r12, rdi
	mov r13, rsi
	mov r14, 0

	;start off word count at one
	mov dword[r12], 1

	;output "File Text: if echo was used"
	cmp qword[echoUsed], 1
	jne getWordLoop
		mov rdi, fileTestMsg
		call printStr

getWordLoop:
	;call getChar for use of calculations
	mov rdi, charVar
	call getCharacter
	mov r8, rax		;temp reg to hold the return value of getChar

	;if echo was used print the chars as we go
	cmp qword[echoUsed], 1		;if 1 echo was used if not it wasnt
		jne skipEcho
	;echo was used so keep going
	;Print out message
	mov rax, SYSTEM_WRITE
	mov rsi, charVar
	mov rdi, STANDARD_OUT
	mov rdx, 1			
	syscall

	;echo call is done
	skipEcho:
	mov rax, r8		;restore rax with the function return call
	;compare return values
	;returns 1 if char was retrieved
	;		 0 if there is no more chars
	;		 -1 if there was an error
	cmp rax, 1
		je skipReturnValueCheck		;success when grabing the char
	cmp rax, 0
		je reachedEOF				;reached end of file
	cmp rax, -1
		ja reachedEOF				;jumps if there wasnt a error return
		mov rdi, fileReadERRORMsg
		call printStr				;output error message
		jmp endGetWordCountFunc

	;a char was return successfully
	;process the value to figure out how to inc it
	skipReturnValueCheck:
	;check if the char is a letter
	cmp byte[charVar], 'A'
		jb notLetter
	cmp byte[charVar], 'Z'
		ja notUpperCase
	jmp isLetter

	;might be lower case letter
	notUpperCase:
	cmp byte[charVar], 'a'
		jb notLetter
	cmp byte[charVar], 'z'
		ja notLetter
	;passed all checks so its lower case

	;is a letter so inc char count
	isLetter:
	inc dword[r13]
	mov r14, 1
	jmp getWordLoop

	notLetter:
	cmp byte[charVar], ' '
		je	isWhiteSpace
	cmp byte[charVar], LF
		je	isWhiteSpace
	cmp byte[charVar], 9	;tab
		je	isWhiteSpace
	cmp byte[charVar], 13	;carriage return
		je	isWhiteSpace

	;last char is not a whitespace
	mov r14, 1
	jmp getWordLoop

	;set bool to show char is a white space
	isWhiteSpace:
	cmp r14, 1				;check if last char was a valid char for word
		jne getWordLoop		;1 is valid and it was not 1
		inc dword[r12]		;inc the word count
		mov r14, 0			;reset bool

	jmp getWordLoop

	;do calculations and place into args and return
	reachedEOF:
	mov edx, 0
	mov eax, dword[r13]
	div dword[r12]	;number by number of words
	mov dword[r13], 0
	mov word[r13], ax

	endGetWordCountFunc:
	;fix stack
	;mov rsp, rbp
	pop r14
	pop r13
	pop r12
	;pop rbp
ret
;end of getWordCounterAndAverage

;Function that retrieves a single char from a buffer
;args:	reference to store the char in
;returns 1 if char was retrieved
;		 0 if there is no more chars
;		 -1 if there was an error
global getCharacter
getCharacter:

	;preserved reg
	push r15

	mov r15, rdi	;move the arg ref to r15

	getCharLoop:
	mov rcx, 0		;clear reg
	mov rdx,0
	;check if there is chars to read from buffer
	mov rax, qword[charactersRead]		;move into temp reg for compare
	mov rdx, qword[charactersBuffered]
	cmp rax, rdx
		jae skipCharReturn
		;put the char into the arg that was pass by ref
		mov cl, byte[buffer + rax]				;put char into temp reg
		mov byte[r15], cl						;place char into arg
		inc qword[charactersRead]				;inc charactersRead for next call
		mov rax, 1								;return success
		jmp endGetChar
	skipCharReturn:

	;check if end of file
	cmp qword[eofReached], 1
	jne skipEOFReachCondtion
		;reached end of file return 0 to signal it
		mov rax, 0
		jmp endGetChar
	skipEOFReachCondtion:

	;refill buffer
	movzx rdi, word[fileDescriptor]
	mov rax, SYSTEM_READ
	mov rsi, buffer
	mov rdx, BUFFER_SIZE
	syscall

	cmp rax, 0
		jge fileReadSuccess
		;file return value lower than 1 indicating error
		mov rax, -1
		jmp endGetChar
	fileReadSuccess:
	cmp rax, BUFFER_SIZE
		jge notEOF
		;compare is less than buffer_size so it should be at EOF
		mov qword[eofReached], 1 
	notEOF:
	mov qword[charactersBuffered], rax
	mov qword[charactersRead], 0 

	jmp getCharLoop	;jump to back to loop

	endGetChar:		;used to skip to end of function for return
	;pop preserved regs
	pop r15

	ret
;end of getCharacter

global main
main:

mov rbx, qword[rsi+8]	;save the file name for later

call commandLineArg

;compare rax to output correct error
;mov correct error message into rdi then jump to an output function
;if no errors are found skip this
cmp rax, -1
	jne skipErrorCheck1
	mov rdi, invalidArgMsg
	jmp outputERROR
skipErrorCheck1:

cmp rax, -2
	jne skipErrorCheck2
	mov rdi, incorrectNumOfArgsMsg
	jmp outputERROR
skipErrorCheck2:

cmp rax, -3
	jne skipErrorCheck3
	mov rdi, howToUseMsg
	jmp outputERROR
skipErrorCheck3:

;file error output is special as its two parts
cmp rax, -4
	jne skipErrorCheck4
	mov rdi, cantOpenTextPart1		;call print string on first part of msg
	call printStr
	mov rdi, rbx			;call print string on file name
	call printStr
	mov rdi, cantOpenTextPart2		;call print string on second part of msg
	call printStr
	jmp endProgram
skipErrorCheck4:

;Passed all the checks
jmp skipErrorOutput

;outputs error and expected inputs
outputERROR:
call printStr
	jmp endProgram		;end the program

;No Errors were found so continue with program
skipErrorOutput:

mov rdi, wordCount
mov rsi, charAvg
call getWordCountAndAverage

;output the count to console
;output "Word Count: "
mov rdi, wordCountMsg
call printStr

;print out the number
int32ToString dword[wordCount], stringOutput1
mov rdi, stringOutput1
call printStr

;output "Average Word Length: "
mov rdi, avgWordLengthMsg
call printStr

;print out the number
int32ToString dword[charAvg], stringOutput2
mov rdi, stringOutput2
call printStr

;mov rdi, charAvg
;add rdi, '0'
;call printStr
endProgram:
	mov rax, SYSTEM_EXIT
	mov rdi, SUCCESS
	syscall