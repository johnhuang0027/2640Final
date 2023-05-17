#Names: John Huang, Jomar Veloso, Joshua Gomez
#Updated: 5/17/2022
#
#
#				T H E	H A N G M A N
#\n				 ______________
#\n				//	    |_
#\n		    ||	    (_)
#\n       ||      /|\
#\n			  ||       |
#\n			  ||      /\
#\n			  ||
#\n			 /__\___________
#\n
#
#objectives:
# - create a game of Hangman (allowed up to 7 attempts)
# - hangpost, head, torso, L/R arm, L/R leg
#
#
################	macro segment
.macro printStr(%str)
	# This macro prints a predefined string using syscall
	li $v0, 4
	la $a0, %str
	syscall
.end_macro

.macro readChar
	# This macro reads the next character using syscall
	li $v0, 12
	syscall
.end_macro

.macro printChar(%char)
	# This macro prints a predefined character stored in a register using syscall
	li $v0, 11
	move $a0, %char
	syscall
.end_macro

.macro printInt(%int)
	# This macro prints a predefined integer stored in a register using syscall
	li $v0, 1
	move $a0, %int
	syscall
.end_macro

.macro printHangMan(%string)
	# This macro prints the drawing of the hangman out to the user;
	# Needs to be called constantly to print out line by line
	li $v0, 4
	.data
	programmerString: .asciiz %string #initializes a programmer-defined string
	.text
	la $a0, programmerString	#reads address of programmerString into $a0 in main text
	syscall
.end_macro

################	DATA SEGMENT		###############################################################################
.data
#	word bank
.align 2

#	array of words
words: .word word1, word2, word3, word4, word5, word6, word7, word8, word9, word10, word11, word12, word13, word14

word1: .asciiz "apple"
word2: .asciiz "banana"
word3: .asciiz "bomb"
word4: .asciiz "computer"
word5: .asciiz "yes"
word6: .asciiz "marginalization"
word7: .asciiz "endianess"
word8: .asciiz "mississippi"
word9: .asciiz "endeavor"
word10:.asciiz "science"
word11: .asciiz "byte"
word12: .asciiz "hexadecimal"
word13: .asciiz "concrete"
word14: .asciiz "food"


#	guessed word
guessed_word: .space 52		#allocates space for string containing word as it is being guessed for
				# used ro be 32

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
youLost: .asciiz "\nYou lost. The hangman is finished.\nThe word was: "
youWon: .asciiz "\nYou won! The hangman is spared.\nThe word was: "

kill_switch: .asciiz "\n(Press Enter at anytime to exit the code) "

################	TEXT SEGMENT		###############################################################################
.text	
################	main/ random_word/ trackers and counters
#	Prints a heart warming welcome message This section is preliminary.
#	It is responsible for loading/reloading all the variables before
#	execution of the code starts. Hence, this entire section runs
#	once only: before the round officially starts.
#
#	$s0 = char that was read in $v0 from macro
#	$t8 = stored random word from memory
main:
	printStr(welcome)	#print "\nWelcome to The Hangman\n\nCan you guess the word?"
	
	printStr(kill_switch)	#print "\nPress Enter at anytime to exit the code. "

random_word:
	#random word
	li $v0, 42	#instruction for random seed
	li $a1, 14	#$a1 stores a range number of words from the bank in order to select one at random
	syscall
	
	mul $t1, $a0, 4
	
	la $s7, words
	add $s7, $s7, $t1
	lw $t8, ($s7)  # load the chosen word from memory into register $t8 (will hold random word from here on out)

attempt_tracker:
	li $t7, 7		# Tracks number of attempts; set to 7
				# (post, head, torso, left arm, right arm, left leg, right leg)
	
asterisks_remaining:
	li $t6, 0		#tracks num of asterisks remaining, set to 0
				# NOTE: $t5 is also in use, it stores copy of $t6
	
number_of_times_printed:
	li $s5, 0		#tracks each time the guessed_word is printed
	
	j copy_string_preface	#jumps to copy_string (this entire section starting from main only run once every round)

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
copy_string_preface:
	la $a1, ($t8)		#load address of random word to $a1
	la $a2, guessed_word	#load address of guessed_word to $a2
	
copy_string_loop:
	lbu  $t2, ($a1)		#load address of random word to $t2
	lbu  $t3, ($a2)		#load current char of $a2 ($a2 = guessed_word's base address) to $t3
	
	beq  $t2, $zero, copy_string_end	#when $t2 is done reading chars in random word, go to copy_string_end
	
	addu $t3, $zero, 42	#adds an asterisk ('*' has ascii value 42) ro char at $t3
	addi $t6, $t6, 1	#increments num of asterisks remaining ($t6)
	sb   $t3, ($a2)		#store char containing asterisk ($t3) to same location in $a2
	
	addi $a1, $a1, 1	#increment address of random word $a1
	addi $a2, $a2, 1	#increment address of guessed_word $a2
	
	j copy_string_loop
	
copy_string_end:
	printStr(word_is)	#prints "\nThe word is: "
	
	j print_string_preface	#jump to print_string_preface

################	append_guessed
#	This section checks whether or not the random word contains the char entered by user.
#	Hence, this only runs when the user has enter a character, not the first time it is
#	printed because no char can be accepted at this point. If a char is detected in the
#	random word, the char will be printed out in the guessed string (the copy string)
#
#	$a1 = address of random word string
#	$a2 = address of guessed string
#	$s0 = contains char entered by user
#	$t5 = num of chars found
#	$t6 = num of asterisks remaining
append_guessed_preface:
	la $a1, ($t8)		#load address of random word to $a1
	la $a2, guessed_word
	
	add $t5, $t6, $zero	#copies old $t6 (num of asterisks remaining) to $t5 for comparison
	li  $t6, 0		#reset num of asterisks in $t6 to be used anew
	
	li  $t5, 0		#set num of chars found to 0 in $t5
	
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
	
	addi $t5, $t5, 1	#increment num of chars found
	
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
	
################	print_string
#	This loop prints out the correct amount of chars in the guessed word string
#	as there are in the random word that was picked. Basically, instead of using
#	a syscall, this loop will print out the string for every round
#
#	$s5 = num of times guessed_word gets printed out
#	$t5 = old num of asterisks remaining
#	$t6 = new num of asterisks remaining
print_string_preface:
	la $a1, ($t8)		#load address of random word and guessed_word
	la $a2, guessed_word
	
print_string_loop:
	lbu $t2, ($a1)		#load base address of word to $t2
	lbu $t3, ($a2)		#load current char of $a2 ($a2 = guessed_word's base address) to $t3
	
	beq $t2, $zero, print_string_end	#if $t2 detects no more chars in word1, go to print_string_end
	
	printChar($t3)		#prints out character in $t3 (stores base address of guessed word)
	
	addi $a1, $a1, 1	#increment address of random word $a1
	addi $a2, $a2, 1	#increment address of guessed_word $a2
	
	j print_string_loop

print_string_end:
	addi $s5, $s5, 1	#increment num of times this guessed word is printed
	beq $s5, 1, ask_again	# if it's the first time this is printed, ignore instructions underneath
				# and jump to ask again

	blt $t6, $t5, found	# branch if the num of asterisks remaining after guessing in $t6 is
				# less than the previous-stored num of asterisks, saved in $t5
				# (if it is, this means that a new char has indeed been found, with less asterisks remaining than before)
	
	bgtz $t5, found		#branch to found if num of chars found ($t5) is more than 0
	
	beqz $t5, notFound	#branch to notFound if otherwise
	
	j ask_again
	
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
	
	j append_guessed_preface

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
	
	sub $t7, $t7, 1		#decrements the number of attempts left in $t7 each time a letter is notFound
	
	printChar($s0)		#prints out the guessed char
	printStr(not_found)	#prints " was not found "
	
	printStr(numAttempts)	#print "\nAttempts left: "

	printInt($t7)
	
	beq $t7, 6, hangpost
	beq $t7, 5, head
	beq $t7, 4, torso
	beq $t7, 3, left_arm
	beq $t7, 2, right_arm
	beq $t7, 1, left_leg
	beq $t7, 0, right_leg
	
	j ask_again		#returns to ask_again for the next char input

################	winner
#	This prints messages when you found all the letters of the random word
#
winner:
	printHangMan("\n\n      O    O ")
	printHangMan("\n      ._____. ")
	printHangMan("\n       \\___/       I'M ALIVE!\n")
	printStr(youWon)	#prints "\nYou won! The hangman is spared.\nThe word was: "
	li $v0, 4
	move $a0, $t8		#prints the random word $t8
	syscall
	
	printStr(totAttempts)	#prints "\nYour total attempts remaining were: "
	printInt($t7)		#prints $t7, num of attempts remaining
	
	j retry			#jump to retry
	
################	loser
#	This prints messages when you've lost all your attempts ($t7 = 0 attempts left)
#
loser:
	printHangMan("\n\n      X   X ")
	printHangMan("\n        O       I'M DEAD!\n")
	printStr(youLost)	#prints "\nYou lost. The hangman is finished.\nThe word was: "
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
	
	beq $v0, 121, main	#if the answer is 'y' (ascii val = 121), go to random_word
	
	beq $v0, 10, exit	#KILL SWITCH (press "Enter" key incase stuck in an infinite loop)
	
	bne $v0, 110, retry	#if the answer is neither 'y' nor 'n' (ascii val = 110), loop until acceptable input is taken
	
	j exit		#default: if 'n' is entered, jump to exit
	
################	drawing the hangman
#	Quick heads up: since a string accepts a backslash '\' as a command, in order to print out a single backslash
#	it is necessary to add a double backslash in order to print out one
#
hangpost:
	printHangMan("\n\n    ______________")
	printHangMan("\n   //	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n /__\\___________\n")
	
	j ask_again

head:
	printHangMan("\n\n    ______________")
	printHangMan("\n   //	       |_")
	printHangMan("\n  ||	       (_)")
	printHangMan("\n  ||	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n /__\\___________\n")
	
	j ask_again
	
torso:
	printHangMan("\n\n    ______________")
	printHangMan("\n   //	       |_")
	printHangMan("\n  ||	       (_)")
	printHangMan("\n  ||	        |")
	printHangMan("\n  ||	        |")
	printHangMan("\n  ||	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n /__\\___________\n")
	
	j ask_again
	
left_arm:
	printHangMan("\n\n    ______________")
	printHangMan("\n   //	       |_")
	printHangMan("\n  ||	       (_)")
	printHangMan("\n  ||	       /|")
	printHangMan("\n  ||	      / |")
	printHangMan("\n  ||	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n /__\\___________\n")
	
	j ask_again
	
right_arm:
	printHangMan("\n\n    ______________")
	printHangMan("\n   //	       |_")
	printHangMan("\n  ||	       (_)")
	printHangMan("\n  ||	       /|\\ ")
	printHangMan("\n  ||	      / | \\ ")
	printHangMan("\n  ||	    ")
	printHangMan("\n  ||	    ")
	printHangMan("\n /__\\___________\n")
	
	j ask_again
	
left_leg:
	printHangMan("\n\n    ______________")
	printHangMan("\n   //	       |_")
	printHangMan("\n  ||	       (_)")
	printHangMan("\n  ||	       /|\\ ")
	printHangMan("\n  ||	      / | \\ ")
	printHangMan("\n  ||	       /")
	printHangMan("\n  ||	      / ")
	printHangMan("\n /__\\___________\n")
	
	j ask_again
	
right_leg:
	printHangMan("\n\n    ______________")
	printHangMan("\n   //	       |_")
	printHangMan("\n  ||	       (_)")
	printHangMan("\n  ||	       /|\\ ")
	printHangMan("\n  ||	      / | \\ ")
	printHangMan("\n  ||	       / \\ ")
	printHangMan("\n  ||	      /   \\ ")
	printHangMan("\n /__\\___________\n")
	
	j ask_again
	

################	exit
#	Exits the program. It is called at several points throughout the program
exit:
	printStr(nl)
	printStr(goodbye)	#prints "\nThanks for playing, goodbye!"
	
	li $v0, 10
	syscall

## FOOTNOTES - Joshua
##	* This version of the hangman project was completed after original date of this project's submission (5/14)
##	* The current version has updated a few things
##	 1) rearranged random word generator so that it can be called after main is called, referring to the retry
##	    section of code (This allows for a newly-generated random word to be issued each time a new round starts,
##	    thereby making it unecessary to terminate program and reassemble it in order to generate a new random word)
##	 2) new words have been added to the word bank
##	 3) $a1 in the random word generator has been incremeneted to include the new words
##	 4) array of words has been updated to include new words
##	 5) removed all syscalls that print the guessed_word
##	 6) added drawings of the hangman for each lost attempt, i.o.w. when branched to notFound
##
##	* Patches
##	 1) In place of the guessed_word syscalls, a loop was implemented that, much like the append_guessed_loop,
##	    takes in the addresses of both the guessed_word string and the random word string. Then, it only prints
##	    out the number of characters of the guessed_word as the word that is being guessed (random word). The
##	    issue before was that once a new word was being generated after retry, it would print out extra chars
##	    if the new word was of shorter length than the previous word that had been guessed for. Thereby, running
##	    a syscall would cause the whole string, even the extra characters, to be printed out. Refer to output example
##	    below.
##		Before:							After:
##			Round 1: computer					Round 1: computer
##			Round 2: yes						Round 2: yes
##			Output: The word is: ***uter \nEnter a letter:		Output: The word is: *** \nEnter a letter:
##			Input: y						Input: y
##			Output: y**uter						Output: y**
##
##	Explanation for this is that the .space directive allocates bytes of space for something, in this case a spring. So by
##	doing a syscall printing this string, it prints out every byte of space that is occupied by something. Hence, the syscall
##	approach is undesired for cases such as this. The looping approach is more effective in displaying only those bytes that
##	matter or are object of interest.
###################################################################################################################################
