#Names: John Huang, Jomar Veloso, Joshua Gomez
#Date: 5/2
#
#				T H E	H A N G M A N
#objectives:
# - create a game of Hangman (allowed up to 7 attempts)
# - guillotine, head, torso, L/R arm, L/R leg
#
# NOTES:
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

################	DATA SEGMENT		###############################################################################
.data
#	list of words
.align 2
words: .word word1, word2, word3, word4,word5  # an array of words
word1: .asciiz "apple"
word2: .asciiz "banana"
word3: .asciiz "bomb"
word4: .asciiz "computer"
word5: .asciiz "yes"

#	guessed word
guessed_word: .space 32		#allocates space for string containing word as it is being guessed for

#	prompts/conventions
welcome: .asciiz "\nWelcome to The Hangman\n\nCan you guess the word?"
enterLetter: .asciiz "\n\nEnter a letter: "
word_is: .asciiz "\nThe word is: "

nl: .asciiz "\n"
sp: .asciiz " "

was_found: .asciiz " was found."
not_found: .asciiz " was not found."
tryAgain: .asciiz "\n\nTry again? (y/n): "
goodbye: .asciiz "\nThanks for playing, goodbye!"

numAttempts: .asciiz "\nAttempts left: "
totAttempts: .asciiz "\nYour total attempts remaining were: "
youLost: .asciiz "\n\nYou lost. The hangman is finished.\nThe word was: "
youWon: .asciiz "\n\nYou won! The hangman is spared.\nThe word was: "

kill_switch: .asciiz "\n(Press Enter at anytime to exit the code) "

################	TEXT SEGMENT		###############################################################################
.text
################	welcome_message
#	Simply prints out a heart-warming welcome message. It also lets the user know
#	that a kill switch has been implemented if the player wishes to exit the code
#	at any point
#
welcome_message:
	printStr(welcome)	#print "\nWelcome to The Hangman\n\nCan you guess the word?"
	
	printStr(kill_switch)	#print "\nPress Enter at anytime to exit the code. "

random_word:
	#random word
	li $v0, 42     #instruction for random seed
	li $a1, 5
	syscall
	
	mul $t1, $a0, 4
	
	la $s7, words
	add $s7, $s7, $t1
	lw $t8, ($s7)  # load the chosen word from memory
	
################	main section/trackers and counters
#	Asks user to enter a leter and takes in a character. Think of this section
#	as the actual round itself. This entire section runs only for the first char of the round, every
#	proceeding char goes through ask_again
#
#	$s0 = char that was read in $v0 from macro
#	$t8 = stored random word from memory
main:
	la $a1, ($t8)		#load address of random word to $a1
	la $a2, guessed_word	#load address of guessed_word to $a2

attempt_tracker:
	li $t7, 7		# Tracks number of attempts; set to 7
				# (post, head, torso, left arm, right arm, left leg, right leg)
	
asterisks_remaining:
	li $t6, 0		#tracks num of asterisks remaining, set to 0
	
	j copy_string		#jumps to copy_string (this entire section starting from main only run once every round)
	
################	ask_again
#	This asks the user again for another char. From when the first char is inputted
#	until the end of the round, this gets looped back to for all the chars that follow.
#
ask_again:
	la $a1, ($t8)		#load address of random word to $a1
	printStr(enterLetter)	#print "\n\nEnter a letter: "
	readChar		#reads char (stores it in $v0)
	move $s0, $v0		#move char from $v0 to $s0
	
	printStr(nl)		#prints a new line (for output purposes only)
	
	beq $s0, 10, exit	#KILL SWITCH (press "Enter" key incase stuck in an infinite loop)
	
	j append_guessed_preface	# jump to append_guessed_preface
					# Once the original word has been copied into the guessed string
					# using copy_string, that part of the code becomes reduntant

################	copy_string
#	This loop copies the random word string to the guessed_string and fills it
#	with the same amount of asterisks as chars in the word. Also, this
#	returns a global num of asterisks remaining, which will be used in
#	other parts of the code. It is only necessary for this section to
#	run once, as it only needed to make 1 copy of the string
#
#	$a1 = address of random word string
#	$a2 = address of guessed string
#	$t6 = num of asterisks remaining
copy_string:
	lbu  $t2, ($a1)		#load address of random word to $t2
	lbu  $t3, ($a2)		#load current char of $a2 ($a2 = guessed_word's base address) to $t3
	
	beq  $t2, $zero, copy_string_end	#when $t2 is done reading chars in random word, go to copy_string_end
	
	addu $t3, $0, 42	#adds an asterisk ('*' has ascii value 42) ro char at $t3
	
	addi $t6, $t6, 1	#increments num of asterisks remaining ($t6)
	sb   $t3, ($a2)		#store char containing asterisk ($t3) to same location in $a2
	
	addi $a1, $a1, 1	#increment address of random word $a1
	addi $a2, $a2, 1	#increment address of guessed_word $a2
	
	j copy_string
	
copy_string_end:
	printStr(word_is)	#prints "\nThe word is: "
	printStr(guessed_word)	#prints the guessed_word (now containing asterisks)
	
	printStr(enterLetter)	#prints "\n\nEnter a letter: "
	readChar		#reads a char (in $v0)
	move $s0, $v0		#stores char read in $s0
	printStr(nl)		#prints a new line (for output purposes only)
	
	beq $s0, 10, exit	#KILL SWITCH: in case stuck in an infinite loop and want to exit program,
				# press "Enter" key (10 = ascii value of "Enter" or newline key)
	
	j append_guessed_preface	# jumps to the beginning of the append_guessed section for finding the matching
					# chars that are within the string.

################	append_guessed
#	This section checks whether or not the random word contains the char entered by user.
#	If so, the char will be printed out in the guessed string (the copy string)
#
#	$a1 = address of random word string
#	$a2 = address of guessed string
#	$s0 = contains char entered by user
#	$t6 = num of asterisks remaining
append_guessed_preface:
	la $a1, ($t8)		#load address of random word to $a1
	la $a2, guessed_word
	
	add $t5, $t6, $zero	#copies old $t6 (num of asterisks remaining) to $t5 for comparison
	li  $t6, 0		#reset $t6 to be used anew
	
append_guessed_loop:	
	lbu $t2, ($a1)		#load base address of word to $t2
	lbu $t3, ($a2)		#load current char of $a2 ($a2 = guessed_word's base address) to $t3
	
	beq $t2, $zero, append_guessed_end	#if $t2 detects no more chars in word1, go to append_guessed_end
	beq $s0, $t2, append_guessed_string	#if guessed char $s0 equals char at $t2 (random word), go to append_guessed_string
	
	beq $t3, 42, append_guessed_asterisk	#if $t3 detects an asterisk, go to append_guessed_asterisk
	
	addi $a1, $a1, 1	#increment address of random word $a1
	addi $a2, $a2, 1	#increment address of guessed_word $a2
	
	j append_guessed_loop	#loop back
	
append_guessed_string:
	# Each time a letter matching $s0 is found in the random word ($a1), print each instance
	# of it in the guessed word ($a2), while keeping all other chars as asterisks
	sb $s0, ($a2)		#store the letter ($s0) in the same address of $a2
	
	addi $a1, $a1, 1	#increment address of random word $a1
	addi $a2, $a2, 1	#increment address of guessed_word $a2
	
	j append_guessed_loop	#returns to the loop
	
append_guessed_asterisk:
	# Each time an asterisk is detected in guessed string ($t3), increment the num of asterisks remaining ($t6)
	addi $t6, $t6, 1	#increment num of asterisks remaining
	
	addi $a1, $a1, 1	#increment address of random word $a1
	addi $a2, $a2, 1	#increment address of guessed_word $a2
	
	j append_guessed_loop	#returns to the loop

append_guessed_end:
	printStr(nl)		#print a newline
	printStr(guessed_word)	#prints guessed_word out to user containing asterisks and/or letters
	
	blt $t6, $t5, found	# branch if the num of asterisks remaining after guessing in $t6 is
				# less than the previous-stored num of asterisks, saved in $t5
				# (if it is, this means that a new char has indeed been found, with less asterisks remaining than before)
				
	j notFound		#default: jump to notFound if otherwise

################	found
#	This prints a series of messages when the char entered in $s0 was indeed found in the random word
#	$t6 = num of asterisks remaining
#	$t7 = num of attempts left
#	$s0 = char entered by user
#
#	same registers are used as in notFound
found:
	beqz $t6, winner	#once num of asterisks remaining = 0, go to winner
	printStr(nl)
	printChar($s0)		#prints guessed char
	printStr(was_found)	#prints " was found "
	
	printStr(numAttempts)	#print "\nAttempts left: "
	printInt($t7)		#prints out $t7 = number of attempts left
	
	j ask_again		#returns to ask_again for the next char input

################	notFound
#	This prints a series of messages when the char entered in $s0 was not found in the word
#
notFound:
	beq $t7, $zero, loser	#once num of attempts in $t7 reaches 0, go to loser
	printStr(nl)
	
	printChar($s0)		#prints out the guessed char
	printStr(not_found)	#prints " was not found "
	
	printStr(numAttempts)	#print "\nAttempts left: "
	sub $t7, $t7, 1		#decrements the number of attempts left in $t7 each time a letter is notFound
	printInt($t7)
	
	j ask_again		#returns to ask_again for the next char input

################	winner
#	This prints messages when you found all the letters of the random word
#
winner:
	printStr(youWon)	#prints "\n\nYou won! The hangman is spared.\nThe word was: "
	li $v0, 4
	move $a0, $t8		#prints the random word $t8
	syscall
	
	printStr(totAttempts)	#prints "\nYour total attempts remaining were: "
	printInt($t7)		#prints $t7, num of attempts remaining
	
	j retry			#jump to retry
	
################	loser
#	This prints messages when you've lost all your attempts
#
loser:
	printStr(youLost)	#prints "\n\nYou lost. The hangman is finished.\nThe word was: "
	li $v0, 4
	move $a0, $t8		#prints the random word $t8
	syscall
	
	printStr(totAttempts)	#prints "\nYour total attempts remaining were: "
	printInt($t7)		#print $t7, num of attempts remaining
	
	j retry			#jump to retry
	
################	retry
#	This asks user, after they've either won or lost the round, to play again.
#	Also, this functions as a loop when an invalid response is given
#
retry:
	printStr(tryAgain)	#print "\n\nTry again? (y/n): "
	readChar		#reads a char (stores it in $v0)
	
	beq $v0, 121, main	#if the answer is 'y' (ascii val = 121), go back to main
	
	beq $v0, 10, exit	#KILL SWITCH (press "Enter" key incase stuck in an infinite loop)
	
	bne $v0, 110, retry	#if the answer is neither 'y' nor 'n' (ascii val = 110), loop until acceptable input is taken
	
	j exit		#default: if 'n' is entered, jump to exit
	
exit:
	printStr(nl)
	printStr(goodbye)	#prints "\nThanks for playing, goodbye!"
	
	li $v0, 10
	syscall
