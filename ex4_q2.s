.text
.global main
main:
    # Copy value of $cctrl into $2
    movsg $2, $cctrl
    # Disable all interrupts
    andi $2, $2, 0x000f
    # Enable IRQ2 and IE
    ori $2, $2, 0x42
    # Copy the new CPU control value back to $cctrl
    movgs $cctrl, $2

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
    addi $11, $0, 0x960
    sw $11, 0x72001($0)
    # Enable the timer and autorestart
    addi $11, $0, 0x3
    sw $11, 0x72000($0)

loop:
    # Loads count from counter
    lw $2, counter($0)
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
    
    j loop

handler:
    # Get the value of the exception status register
    movsg $13, $estat
    # Check if any interrupt other than IRQ2 is generated
    andi $13, $13, 0xFFB0
    # If it is IRQ3, go to handler
    beqz $13, IRQ2_interrupt

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

.data
counter:
    .word 0

.bss
old_vector:
    .word