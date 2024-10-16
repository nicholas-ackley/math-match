.data
    diffPrompt:      .asciiz "Select Difficulty (1 for Easy): "
    
    gridPrompt:      .asciiz "\nGame starting... Here is the grid:\n"
    
    grid:            .asciiz "\nA B C D\nE F G H\nI J K L\nM N O P\n"
    
    matchCountPrompt:.asciiz "\nMatches found: "
    
    remaining_msg:   .asciiz "\nRemaining matches: "
    
    matchCounter:    .word 0 
    
    maxMatch:        .word 8    #  8 matches for the game
    
    matchPrompt:     .asciiz "\nSelect two cards (0-15): "
    
    invalidPrompt:   .asciiz "\nInvalid input"
    
    
    #Create a GUI display for the user to choose the cards.
    #Create 2 set of cards, 1 set must be an unflipped string value A-P, and the other set will be the value of the math equation
    #Reseach and implement the timer - MEET BACK ON THURSDAY OR FRIDAY
    card1:      .word -1   #  first card 
    
    card2:     .word -1   #  second card 
    
    
    
.text

.globl menu

menu:
    # Display difficulty prompt
    li $v0, 4
   
     la $a0, diffPrompt
    
    syscall

    # Get user input for difficulty
    li $v0, 5
    
    syscall
    
    move $t0, $v0   # only 1 for easy

    # Display initial grid
    
    li $v0, 4
    
    la $a0, gridPrompt
    
    syscall

    # Print the grid of letters or numbers
    li $v0, 4
    
    la $a0, grid
    
    syscall

    #  match counter
    li $t1, 0          # Initialize matches found
    
    li $t2, 8          # Total matches to be found

    j game_loop        # Jump to game loop


#  user selects two cards for game loop

game_loop:
    # Prompt for card selection
    
    li $v0, 4
    
    la $a0, matchPrompt
    
    syscall

    # Get the first card input
    li $v0, 5
    
    syscall
    
    move $t3, $v0  # First card choice

    # Validate first card input (must be between 0 and 15)
    blt $t3, 0, invalidMessage
    

    
    bgt $t3, 15, invalidMessage

    # Store the 1st card choice
    sw $t3, card1

    # Get the 2nd card input
    li $v0, 5
   
     syscall
   
     move $t4, $v0  # 2nd card choice

    # Validate second card input (must be between 0 and 15)
    blt $t4, 0, invalidMessage
    
    bgt $t4, 15, invalidMessage

    # Store the second card choice
    sw $t4, card2

    
   # game logic jump in a different module 
    
    # jump to game loop, but change later
    j game_loop

# Invalid input 

invalidMessage:
   
     #  message
    li $v0, 4
    
    la $a0, invalidPrompt
    
    syscall
    
    
    
    

    #  another attempt
    j game_loop
