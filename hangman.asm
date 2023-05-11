#Names: John Huang, Jomar Veloso, Joshua Gomez
#Date: 5/2
#Objective: Create a simple hangman program

#objectives:
# - create a game of Hangman (allowed up to 7 attempts)
# NOTES:
# - if possible, make use of the bit map display in order to make the game more lively and fun
# - as of right now, the words are hardcoded into the program
#
################	macro segment
.macro printStr(%str)
	li $v0, 4
	la $a0, %str
	syscall
.end_macro

.macro readChar
	li $v0, 12
	syscall
.end_macro

.macro printChar(%char)
	li $v0, 11
	move $a0, %char
	syscall
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

################	data segment
.data
#	words
word1: .asciiz "bomb"

#	prompts
welcome: .asciiz "\nWelcome to The Hangman\n\nCan you guess the word?"
enterLetter: .asciiz "\n\nEnter a letter: "
newline: .asciiz "\n"
blanks: .asciiz " _ "
yes: .asciiz " was found."
no: .asciiz " was not found."
tryAgain: .asciiz "\nTry again? (1 for yes, 2 for no) : "
goodbye: .asciiz "\nThanks for playing, goodbye!"
numAttempts: .asciiz "\nAttempts left: "
totAttempts: .asciiz "\nYour total attempts remaining were: "
youLost: .asciiz "\n\nYou lost. The hangman is finished.\nThe word was: "
youWon: .asciiz "\n\nYou won! The hangman is spared.\nThe word was: "

################	text segment
.text
	printStr(welcome)
	li  $t7, 7	#tracks number of attempts
	add $t6, $t6, $zero	#tracks num of chars found
main:
	printStr(enterLetter)
	readChar
	move $s0, $v0	#stores char in $s0
	la   $a1, word1	#load address of word1
	li   $s1, 0	#set counter
	
#	loop to check whether or not the string contains the char
findLetter:
	beq $s1, 4, notFound		#if counter reaches 4, go to notFound
	lbu $a0, ($a1)			#load char at base address $s1
	
	beq $s0, $a0, resetCounter	#if current address matches char, go to found
	
	add $s1, $s1, 1			#increment counter
	add $a1, $a1, 1			#increment address
	
	j findLetter
	
resetCounter:
	move $s1, $zero
	la   $a1, word1
	printStr(newline)
	
#	loop to print blank spaces, as well as the chars found within the string
printBlanks:
	beq $s1, 4, found	#once counter reaches 4, go to found
	lbu $a0, ($a1)		#load char at base address $s1
	beq $s0, $a0, printIt	#if they match, go to printIt
	
	printStr(blanks)
	add $s1, $s1, 1		#increment counter
	add $a1, $a1, 1		#increment address
	
	j printBlanks
	
printIt:
	printChar($s0)
	add $t6, $t6, 1		#increment num of chars found
	add $s1, $s1, 1		#increment counter
	add $a1, $a1, 1		#increment address
	j printBlanks
	
found:
	beq $t6, 4, winner	#once all chars in the string are found, you win
	printStr(newline)
	printChar($s0)
	printStr(yes)
	
	printStr(numAttempts)	#print out number of attempts left
	printInt($t7)
	j main
	
notFound:
	printStr(newline)
	printChar($s0)
	printStr(no)
	
	printStr(numAttempts)
	sub $t7, $t7, 1
	printInt($t7)
	beq $t7, $zero, loser	#once num of tries reachez 0, you lose
	j main

winner:
	printStr(youWon)
	printStr(word1)
	printStr(totAttempts)
	printInt($t7)
	j retry
	
loser:
	printStr(youLost)
	printStr(word1)
	printStr(totAttempts)
	printInt($t7)
	j retry
	
retry:
	li   $t7, 7	#reset num of attempts
	li   $t6, 0	#resent num of chars found
	printStr(tryAgain)
	readInt
	beq  $v0, 1, main
	beq  $v0, 2, exit
	
exit:
	printStr(goodbye)
	li $v0, 10
	syscall
