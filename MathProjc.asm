.data
#the grid we chose for our "Card" design.
grid: .asciiz "\n   1  2  3  4\n  +--+--+--+--+\nA |  |  |  |  |\n  +--+--+--+--+\nB |  |  |  |  |\n  +--+--+--+--+\nC |  |  |  |  |\n  +--+--+--+--+\nD |  |  |  |  |\n  +--+--+--+--+\n"

#game prompt messages for starting game, game conditions, user prompts, etc..
difficulty_prompt: .asciiz "\nSelect difficulty:\n1. Easy\nChoose: "
pick_card_prompt: .asciiz "\nPick a card (e.g., A1): "
invalid_input: .asciiz "\nInvalid input. Try again.\n"
match_message: .asciiz "\nMatch!\n"
no_match_message: .asciiz "\nNo match. Try again.\n"
finished_message: .asciiz "\nYay! You've matched all pairs!\n"
play_again_prompt: .asciiz "\nPlay again? (1 for Yes, 0 for No): "
exit_message: .asciiz "\nThank you for playing!\n"
revealed_card_msg: .asciiz "\nRevealed card: "
new_game_msg: .asciiz "\nStarting a new game...\n"
moves_message: .asciiz "\nTotal moves made: "
matches_message: .asciiz "\nTotal matches found: "
time_up_message: .asciiz "\nTime's up! Game over.\n"
timer_message: .asciiz "\nTime remaining: "
matches_remaining_message: .asciiz "\nMatches remaining: "

#values and equations
equations: .asciiz "4x2\0", "4x1\0", "4x3\0", "3x2\0", "3x3\0", "7x7\0", "4x5\0", "4x6\0"
values:    .word 8, 4, 12, 6, 9, 49, 20, 24, 8, 4, 12, 6, 9, 49, 20, 24  # Matching values

#variables for counters
matches: .word 0       #match counter
moves: .word 0         #move counter
matched_flags: .space 64  # 16 cards * 4 bytes each,word size initialized to 0

#timer settings
start_time: .word 0     #start time (miliseconds)
end_time: .word 0       #end time
time_limit: .word 120000 #2 mintues of total guessing time

buffer: .space 4  #buffer used for the input

.text
main:
   	#displays the difficulty and calls the prompt
   	li $v0, 4
   	la $a0, difficulty_prompt
   	syscall

   	#read difficulty level (1) eas
   	li $v0, 5
   	syscall
   	move $t0, $v0  #$t0 holds the difficulty which is 1 and easy
start_game:
    #displays the message for starting a new game
  	li $v0, 4
   	la $a0, new_game_msg
  	syscall

    #variables
   	li $t1, 8         #shows how many matches remain and starts with 8
   	la $s0, values    #loads values into the reg $s0
   	li $t9, 0         #match counter reset
   	sw $t9, matches   #reset value
   	li $t9, 0         # Reset moves counter
   	sw $t9, moves     # Store reset value

    # Record the start time
   	li $v0, 30         #retrieves the system time
   	syscall
   	move $t2, $a0      #save 32 bits of system time
   	sw $t2, start_time #stores the start time in the mem

game_loop:
    #displays current time and the current game being played
   	jal display_status

    #displays the 4x4 game board
   	li $v0, 4
   	la $a0, grid
   	syscall

    #first card selection
   	jal pick_card       #jump to card logic
   	move $t7, $t6       #save value to $t7

    #+1   the move counter
   	lw $t9, moves
   	addi $t9, $t9, 1
   	sw $t9, moves

    #prompts the second card
   	li $v0, 4
   	la $a0, pick_card_prompt
   	syscall

    #second card selection 
   	jal pick_card       #jal to card picking logic
   	move $t8, $t6       #save second card value to $t8

    # +1 the moves counter
   	lw $t9, moves
   	addi $t9, $t9, 1
   	sw $t9, moves

    # validate for match
   	beq $t7, $t8, matched
    #no match?
  	 li $v0, 4
  	 la $a0, no_match_message
 	 syscall
 	 j game_loop

matched:
    #display match message
   	li $v0, 4
   	la $a0, match_message
   	syscall
	
    # +1 match counter
   	lw $t9, matches
   	addi $t9, $t9, 1
   	sw $t9, matches

    # update matched flags for the cards
   	sb $t7, matched_flags($t7)  #first card
  	sb $t8, matched_flags($t8)  #second card

    #-1 remaining matches count
   	subi $t1, $t1, 1  #pairs matched

    # game condition that checks if its finished or not
   	beqz $t1, finished
    	j game_loop


pick_card:
    #prompt thge user to pick a card
   	li $v0, 4
   	la $a0, pick_card_prompt
    	syscall

    #read card choice
    	li $v0, 8
    	la $a0, buffer
	li $a1, 4
    	syscall

    #parse input
    	lb $t2, 0($a0)      #load row chars (letters)
	lb $t3, 1($a0)      #load column character (nums)

    #convert row to index
    	subi $t2, $t2, 65   #'A' =0, 'B' = 1

    #convert column to index
    	subi $t3, $t3, 49   #'1' = 0, '2' = 1

    #calculate the array index - row index * 4 + column index
    	li $t4, 4           #total num of cols
    	mul $t2, $t2, $t4   #row index * 4
    	add $t2, $t2, $t3   #col index

    # access the calculated index
   	 sll $t2, $t2, 2     #multiply index by 4 word size
    	add $t5, $s0, $t2   #address of values index
    	lw $t6, 0($t5)      #load value

    #determine if the card holds a value, or an equation
   	 blt $t2, 32, show_equation  # index < 8  = Equation
    	j show_value

show_equation:
    	#print equatoins
    	la $a0, equations
    	add $a0, $a0, $t2   #offset equations in an arr
    	li $v0, 4
    	syscall
    	jr $ra
show_value:
    #display the values
    	li $v0, 4
    	la $a0, revealed_card_msg
    	syscall
    	li $v0, 1
    	move $a0, $t6
    	syscall
    	jr $ra
display_status:
    #get the current time
    	li $v0, 30          #sys call to retriieve sys time
    	syscall
    	move $t3, $a0       #sys time

    #calculates the elapsed time
    	lw $t4, start_time  #laods the start
    	sub $t5, $t3, $t4   #elapsed time

    #calculates the time remainig of the game
    	lw $t6, time_limit  #time limit of 120,000 ms or 2 minutes
    	sub $t6, $t6, $t5   # $t6 holds the value of time remaining in milliseconds

    #display time remaining
    	li $v0, 4           #print syscall
    	la $a0, timer_message
    	syscall
    	div $t6, $t6, 1000  #converts the time from miliseconds to seconds and porints
    	li $v0, 1           #int syscall
    	move $a0, $t6
    	syscall

    # Display matches remaining
    	li $v0, 4           #string syscall
    	la $a0, matches_remaining_message
    	syscall
    	move $a0, $t1       #$t1 holds the value of matches remaining
    	li $v0, 1           #int syscall
    	syscall

    #check if the time has expired, if true, jump
    	blez $t6, time_up   #if the time less than or equal to 0, jump to time up function
    	jr $ra              #return to the caller

time_up:
    #"Times up message"
    	li $v0, 4
    	la $a0, time_up_message
    	syscall
    	j finished          #enbd game

finished:
    #finishewd message
    	li $v0, 4
    	la $a0, finished_message
    	syscall

    #display the total moves user had
    	li $v0, 4
    	la $a0, moves_message
    	syscall
    	lw $t9, moves
    	li $v0, 1
   	 move $a0, $t9
    	syscall

    #display the users statistics from the game, match message, guesses, pairs, etc
    	li $v0, 4
    	la $a0, matches_message
    	syscall
    	lw $t9, matches
    	li $v0, 1
    	move $a0, $t9
   	 syscall

    #prompt to play again with 2 conditions
    	li $v0, 4
    	la $a0, play_again_prompt
    	syscall

    # Read user input for replay
    	li $v0, 5
   	 syscall
    	beqz $v0, exit  # Exit if user chooses 0

    j start_game
	
exit:
    #display the exit msg
    	li $v0, 4
   	la $a0, exit_message
    	syscall
	
    #exit, and done.
    	li $v0, 10
   	 syscall
