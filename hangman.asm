#Names: John Huang, Jomar Veloso, Joshua Gomez
#Date: 5/2
#Objective: Create a simple hangman program

#objectives:
# - create a game of Hangman (allowed up to 7 attempts)
# - guillotine, head, torso, L/R arm, L/R leg
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
.align 2
words: .word word1, word2, word3, word4,word5  # an array of words
word1: .asciiz "apple"
word2: .asciiz "banana"
word3: .asciiz "bomb"
word4: .asciiz "computer"
word5: .asciiz "yes"

#	guessed word
guessed_word: .space 32	#allocates space for string containing word as it is being guessed for

#	prompts
welcome: .asciiz "\nWelcome to The Hangman\n\nCan you guess the word?"
enterLetter: .asciiz "\n\nEnter a letter: "
newline: .asciiz "\n"
sp: .asciiz " "
blanks: .asciiz " _"
yes: .asciiz " was found."
no: .asciiz " was not found."
tryAgain: .asciiz "\n\nTry again? (y/n): "
goodbye: .asciiz "\nThanks for playing, goodbye!"
numAttempts: .asciiz "\nAttempts left: "
totAttempts: .asciiz "\nYour total attempts remaining were: "
youLost: .asciiz "\n\nYou lost. The hangman is finished.\nThe word was: "
youWon: .asciiz "\n\nYou won! The hangman is spared.\nThe word was: "

################	text segment
.text
welcome_message:
	printStr(welcome)
	
attempt_tracker:
	li $t7, 7	#tracks number of attempts
	
characters_found:
	li $t6, 0	#tracks num of chars found
random_word:
	#random word
	li $v0, 42     #instruction for random seed
	li $a1, 5
	syscall
	
	mul $t1, $a0, 4
	
	la $s7, words
	add $s7, $s7, $t1
	lw $t8, ($s7)  # load the chosen word from memory

################	main section
#	Asks user to enter a leter and takes in a character. Think of this section
#	as the round itself.
#
#	$s0 = char that was read
#	$a1 = address of the word
main:
	printStr(enterLetter)
	readChar
	move $s0, $v0		#stores char in $ s0
	la   $a1, ($t8)		#load address of word to $ a1
	
length_of_string:
	li  $t0, 0		#tracks length of string to $ t0
	printStr(newline)	#prints a new line (for output purposes only)
	
loop_counter:
	li   $t1, 0	#set counter to $ t1

################	count_chars
#	This loop counts the number of chars in the string.
#
#	$a1 = still holds address of the word
#	$a0 = current char
#
#	$t0 = holds the length of the string
count_chars:
	lbu $a0, ($a1)		#load current char at base address $ a0
	beqz $a0, resetCount	#once there's no more chars to read, go to resetCount
	add $t0, $t0, 1
	add $a1, $a1, 1
	j count_chars

################	resetCount
#	This only reloads the address of the word
#
resetCount:
	la $a1, ($t8)

################	findLetter
#	This loop checks whether or not the string contains the char
#	$t1 = loop counter starting from 0
#	$t0 = string length
#	$s0 = contains char that user entered
findLetter:	
	beq $t1, $t0, decide_if_found		#if $ t1 equals $ t0, go to decide
	lbu $a0, ($a1)				#load char at base address to $ a0
	beq $s0, $a0, printIt			#if the guessed char at $s0 matches with the current char $a0, go to printIt
	
	printStr(blanks)		#if not, default is to print a blank space " _ "
	
	add $t1, $t1, 1			#increment loop counter
	add $a1, $a1, 1			#increment base address
	j findLetter

################	printIt
#	Just prints the char out
#	sp = string containing blank space " "
printIt:
	printStr(sp)		# prints a blank space
	
	printChar($s0)		# prints the char
	
	add $t6, $t6, 1		#increment $t6 = num of chars found
	add $t1, $t1, 1		#increment loop counter
	add $a1, $a1, 1		#increment base address
	
	j findLetter		#returns to the loop to find more chars to print

################	decide_if_found
#	This checks the num of chars found ( $t6) to determine whether or not to print out all blank spaces
#
#	or spaces along with the chars that were found
decide_if_found:
	bgtz $t6, found		#if the number of chars found is greater than 0, go to found

	j notFound	#default is go to notFound

################	found
#	This prints messages when the char entered was found in the string
#	$t6 = num of chars found
#	$t0 = length of the string
#	$s0 = char entered by user
#
#	registers used same as in notFound
found:
	beq $t6, $t0, winner	#once the number of chars found = string length, go to winner
	printStr(newline)
	printChar($s0)
	printStr(yes)		#prints " was found "
	
	printStr(numAttempts)	#print "\nAttempts left: "
	printInt($t7)		#prints out $t7 = number of attempts left
	
	j main			#returns to main to enter the next char

################	found
#	This prints messages when the char entered was not found
notFound:
	beq $t7, $zero, loser	#once num of attempts reachez 0, go to loser
	printStr(newline)
	printChar($s0)
	printStr(no)		#prints " was not found "
	
	printStr(numAttempts)
	sub $t7, $t7, 1		#decrements the number of attempts left in $t7
	printInt($t7)
	
	j main

################	winner
#	This prints messages when you entered all the letters in the string
winner:
	printStr(youWon)
	printStr(word1)
	printStr(totAttempts)	#prints "\nYour total attempts remaining were: "
	printInt($t7)
	
	j retry			#jump to retry
	
################	loser
#	This prints messages when you've lost all your attempts
loser:
	printStr(youLost)
	printStr(word1)
	printStr(totAttempts)	#prints "\nYour total attempts remaining were: "
	printInt($t7)
	
	j retry			#jump to retry
	
################	retry
#	This asks user after you either win or lose the round, to play again.
#	Also, this functions as a sort of loop, if an invalid response is given
retry:
	li  $t7, 7	#reset num of attempts to 7
	li  $t6, 0	#reset num of chars found to 0
	
	printStr(tryAgain)
	readChar
	
	beq $v0, 121, main	#if the answer is 'y', go back to main
	bne $v0, 110, retry	#if the answer is neither 'y' nor 'n', loop the retry until 'y' or 'n' is entered
	
	j exit		#default, if 'n' is entered, jump to exit
	
exit:
	printStr(goodbye)
	li $v0, 10
	syscall
