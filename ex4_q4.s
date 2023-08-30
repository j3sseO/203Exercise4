.text
.global main
main:
    # Copy value of $cctrl into $2
    movsg $2, $cctrl
    # Disable all interrupts
    andi $2, $2, 0x000f
    # Enable IRQ2, IRQ3 and IE
    ori $2, $2, 0xC2
    # Copy the new CPU control value back to $cctrl
    movgs $cctrl, $2

    # Sets parallel control register to 11
    lw $2, 0x73004($0)
    addi $2, $0, 11
    sw $2, 0x73004($0)

    # Copy old handler's address to $2
    movsg $2, $evec
    # Save it to memory
    sw $2, old_vector($0)
    # Get the address of the new handler
    la $2, handler
    # Copy it into $evec register
    movgs $evec, $2

    # Clear timer interrupt acknowledge register
    sw $0, 0x72003($0)
    # Load value to count down from
    addi $11, $0, 0x18
    sw $11, 0x72001($0)
    # Enable autorestart
    addi $11, $0, 0x2
    sw $11, 0x72000($0)

loop:
    # Loads count from counter
    lw $2, counter($0)
    # Divide digit by 100 so that it is displayed in seconds
    divi $2, $2, 100
    # Gets last digit
    remi $1, $2, 10
    # Displays digit on SSD
    sw $1, 0x73009($0)
    # Shift number
    divi $2, $2, 10
    # Gets last digit
    remi $1, $2, 10
    # Displays digit on SSD
    sw $1, 0x73008($0)

    # If termination flag is 1, jump to quit label
    lw $4, quitter($0)
    bnez $4, quit
    
    j loop

quit:
    jr $ra

handler:
    # Get the value of the exception status register
    movsg $13, $estat
    # Check if any interrupt other than IRQ2 is generated
    andi $13, $13, 0xFFB0
    # If it is IRQ3, go to handler
    beqz $13, IRQ2_interrupt
    # Check if any interrupt other than IRQ2 is generated
    andi $13, $13, 0xFF70
    # If it is IRQ3, go to handler
    beqz $13, IRQ3_interrupt

    # Otherwise, jump to default handler that was saved earlier
    lw $13, old_vector($0)
    jr $13

IRQ2_interrupt:
    # Increment counter by 1
    lw $13, counter($0)
    addi $13, $13, 1
    sw $13, counter($0)
    
    # Acknowledge interrupt
    sw $0, 0x72003($0)

    rfe

resume:
    # Acknowledge interrupt
    sw $0, 0x73005($0)
    
    # Restore registers and remove space from stack
    lw $2, 0($sp)
    addui $sp, $sp, 1

    rfe

IRQ3_interrupt:
    # Add space to stack and save register
    subui $sp, $sp, 1
    sw $2, 0($sp)
    
    # If push button register is not equal to zero,
    # jump to continue label
    lw $13, 0x73001($0)
    bnez $13, continue

    # Acknowledge interrupt
    sw $0, 0x73005($0)

    j resume

continue:
    # If button 2 is pushed, jump to exit label
    andi $2, $13, 0x4
    bnez $2, exit
    
    # If button 1 is pushed, jump to stopOrStart label
    andi $2, $13, 0x2
    bnez $2, stopOrStart

    # If button 0 is pushed, jump to reset label
    andi $2, $13, 0x1
    bnez $13, reset

    j resume

stopOrStart:
    # Load timer control register into $13
    lw $13, 0x72000($0)
    
    # If timer is enabled, jump to stop label
    andi $13, $13, 0x1
    bnez $13, stop
    
    # Enable timer
    addi $2, $0, 0x3
    sw $2, 0x72000($0)
    
    j resume

stop:
    # Stop timer
    sw $0, 0x72000($0)
    j resume

reset:
    # Load timer control register into $13
    lw $13, 0x72000($0)

    # If timer is running, jump to resume label
    andi $13, $13, 0x1
    bnez $13, split

    # Set counter to zero
    sw $0, counter($0)

    j resume

exit:
    # Set termination flag to 1
    addi $13, $0, 1
    sw $13, quitter($0)
    
    j resume

.data
counter:
    .word 0

quitter:
    .word 0

.bss
old_vector:
    .word