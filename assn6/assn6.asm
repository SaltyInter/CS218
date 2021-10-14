;	Assignment #5
; Author: Matthew Shiroma
; Section: 1004
; Date Last Modified: 10-10-21
;	This program will explore the use of functions

section .data
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
global main
main:


endProgram:
	mov rax, SYSTEM_EXIT
	mov rdi, SUCCESS
	syscall