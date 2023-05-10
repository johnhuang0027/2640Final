#Names: John Huang, Jomar Veloso, Joshua Gomez
#Date: 5/2
#Objective: Create a simple hangman program

#objectives:
# - create a game of Hangman (allowed up to 7 attempts)
# NOTES:
# - need to implement a tracker for however many attempts the player has left. 
# - if possible, make use of the bit map display in order to make the game more lively and fun
# - as of right now, the words are hardcoded into the program

.macro printStr(%str)
	li $v0, 4
	la $a0, %str
	syscall
.end_macro

.macro readChar
	li $v0, 12
	syscall
	move $s0, $v0
.end_macro

.macro readInt
	li $v0, 5
	syscall
	move $s0, $v0
.end_macro

.macro printInt(%int)
	li $v0, 1
	move $a0, %int
	syscall
.end_macro

.data
word1: .asciiz "word"

welcome: .asciiz "\nWelcome to The Hangman\n\nCan you guess the word?"
enterLetter: .asciiz "\n\nEnter a letter: "
yes: .asciiz "\nLetter was found"
no: .asciiz "\nLetter was not found"
tryAgain: .asciiz "\nTry again? (1 for yes, 2 for no) : "

.text
	printStr(welcome)
main:
	printStr(enterLetter)
	readChar
	la $a1, word1	#load address of word1
	li $s1, 0	#set counter
	
findLetter:
	beq $s1, 4, notFound	#if counter reaches 4, go to notFound
	lbu $a0, ($a1)		#load char at base address $s1
	
	beq $s0, $a0, found	#if they match, go to found
	
	add $s1, $s1, 1		#increment counter
	add $a1, $a1, 1		#increment address
	
	j findLetter
	
found:
	printStr(yes)
	j retry
	
notFound:
	printStr(no)
	j retry
	
retry:
	printStr(tryAgain)
	readInt
	beq $s0, 1, main
	beq $s0, 2, exit
	
exit:
	li $v0, 10
	syscall
