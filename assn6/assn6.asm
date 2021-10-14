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
	
section .bss

section .text

;Fuction that will check and convert the command line args
; Arg 1.) rdi - argc 
; Arg 2.) rsi - argv
; Arg 3.) rdx - weight value float
; Arg 4.) rcx - diameter value float
global proccessCommandLine
proccessCommandLine:

global main
main:


endProgram:
	mov rax, SYSTEM_EXIT
	mov rdi, SUCCESS
	syscall