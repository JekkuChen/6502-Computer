  
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600C
IFR = $600D
IER = $600E


counter = $0200 ; 1 byte
pos = $0201 ; 1 byte
change = $0202 ; 1 byte
block1 = $0203 ; 1 byte
block2 = $0204 ; 1 byte
block3 = $0205 ; 1 byte
block4 = $0206 ; 1 byte
block_n = $0207 ; 1 byte
temp = $0208 ; 1 byte

E = %10000000
RW = %01000000
RS = %00100000

    .org $8000
reset:  
    LDX #$ff 
    TXS 
    
    LDA #$82
    STA IER
    LDA #$0
    STA PCR

    LDA #%11111111 ; Set all pins on Port B to output 
    STA DDRB
    LDA #%11100000 ; Set pins 5-7 on Port B to output
    STA DDRA 

    LDA #%00111000 ; Set 8-bit mode; two line display; 5 x 8 font
    JSR lcd_instruction
    LDA #%00001110 ; Display on; cursor on; blink off
    JSR lcd_instruction
    LDA #%00000110 ; Increment and shift cursor; don't shift display (scroll)
    JSR lcd_instruction
    LDA #%00000001 ; Clear Display
    JSR lcd_instruction

    ; Setup Code (Spawn Initial Wall and Player Ship)
    LDA #0
    STA counter
    STA pos
    STA change
    STA block1
    STA block2
    STA block3
    STA block4
    STA block_n


    LDA #%10101101 ; Send character ship to display
    JSR print_char
    JSR spawn_wall ; Spawn a wall
    CLI ; Allow Interrupts 

game_loop:
    jsr delay_5
    jsr move_display_left
    jsr delay_5
    jsr move_display_left
    jsr delay_5
    jsr move_display_left
    jsr delay_5
    jsr move_display_left
    jsr delay_5
    jsr move_display_left
    jsr spawn_wall ; Spawn a wall
    jmp game_loop



lcd_wait:
  pha ; Push Value of Reg A onto Reg Pointer
  lda #%00000000  ; Set port B to input
  sta DDRB
lcdbusy:
  lda #RW  ; Enable R/W ; Reset E & RS
  sta PORTA
  lda #(RW | E)  ; Enable E 
  sta PORTA
  lda PORTB      ;Bitwise AND contents of PORTB (Busy Flag) to determine if same
  and #%10000000 
  bne lcdbusy     ; if Z = 0, Busy, if Z = 1, Not Busy

  lda #RW
  sta PORTA
  lda #%11111111  ; Port B is output
  sta DDRB
  pla
  rts ; Pull Value of Reg Pointer back on Reg A

lcd_instruction:
    ; Send instruction to the LCD register
    ; Input: Register A contains the instruction that will be sent to the LCD register
    jsr lcd_wait
    sta PORTB
    lda #0         ; Clear RS/RW/E bits
    sta PORTA
    lda #E         ; Set E bit to send instruction
    sta PORTA
    lda #0         ; Clear RS/RW/E bits
    sta PORTA
    rts

print_char:
    jsr lcd_wait
    sta PORTB
    lda #RS         ; Set RS; Clear RW/E bits
    sta PORTA
    lda #(RS | E)   ; Set E bit to send instruction
    sta PORTA
    lda #RS         ; Clear E bits
    sta PORTA
    rts

delay_5: ; Generates a 0.5s delay (!# Note that this uses Y register) (About 500942 Cycles)
    PHA ; Push Accumulator
    TYA ; Move contents of Y into Accumulator
    PHA ; Push Y into stack 
    TXA ; Move contents of X into Accumulator
    PHA ; Push X into stack
    LDX #$2 ; Sets X to 2
    TXA ; Store X in Accumulator
delay_51:
    LDY #$F7 ; Sets Y to 247
delay_52:
    JSR delay ; Generate 1ms delay (This will change X so store it into A)
    DEY ; Decrease Y by 1
    BNE delay_52
    TAX ; Transfer A back into X
    DEX ; Decrease X by 1
    TXA ; Store updated X to A
    BNE delay_51
    PLA ; Pull X from stack
    TAX ; Move contents of Accumulator into X
    PLA ; Pull Y from Stack 
    TAY ; Move contents of Accumulator into Y
    PLA ; Pull Accumulator from Stack
    RTS 

delay: ; Generates a 1 ms delay (!# Note that this uses X register) (About 1002 Cycles)
    LDX change 
    CPX #$0
    BEQ delay_0
    SEI
    JSR move_ship
    CLI
    LDX #$0
    STX change
delay_0 
    LDX #$C5 ; Sets X to 197
delay_1:
    DEX ; Decrease X by 1 
    BNE delay_1 ; Continue delay if not finished
    RTS 
lose:
    LDA message,x
    BEQ end
    JSR print_char
    INX
    JMP lose
     
end:
    jmp end
message: .asciiz "You Lose!!"

print_move_n_wait: ; Use by lose_setup only
    JSR print_char
    TYA ; Move contents of Y into Accumulator
    JSR lcd_instruction ; Move A to either position $1 or $40
    JSR delay_5
    RTS

move_display_left:
    ; Move all walls to the left once 
    ; # NOTE: This cannot be called without having atleast 1 wall spawned in
    LDX #$4
move_walls:
    LDY $0202, X  ; Load moves blocks_counter to block_1, we use $0202 since X is from range 1 - 4
    TYA ; Move contents of Y into Accumulator
    CMP #$0 ; if block stores a 0, ignore into
    BEQ move_walls_3
    JSR lcd_instruction ; Move cursor to the walls
    LDA #%00100000 ; Print Clear to Display
    JSR print_char 

    CPY #%10000001
    BNE check_ship_position ; If wall is in pos 10000001, check if ship to the left
    LDA #%0 ; Check if ship is in position 0
    CMP pos
    BEQ lose_setup ; If Position of Ship is correct, you lost
    JMP move_walls_0 ; Else Continue
check_ship_position
    CPY #%11000001
    BNE move_walls_0 ; If wall is in pos 11000001, check if ship to the left
    LDA #%1 ; Check if ship is in position 1
    CMP pos
    BEQ lose_setup ; If Position of Ship is correct, you lost
    ; Else Continue
move_walls_0:
    CPY #%10000000 ; Check if Y is pos 0
    BEQ move_walls_1
    CPY #%11000000 ; Check if Y is pos 40
    BEQ move_walls_1
    JMP move_walls_2
move_walls_1:
    LDY #$0 ; Store Y with 0
    JMP move_walls_3
move_walls_2:
    DEY
    TYA ; Move contents of Y into Accumulator
    JSR lcd_instruction ; Move cursor to the walls
    LDA #%11111111 ; Print Wall to Display
    JSR print_char 
move_walls_3
    TYA ; Move contents of Y into Accumulator
    STA $0202, X
    DEX
    BNE move_walls
    RTS

lose_setup:
    ; From the position of Y-1 spawns an explosion and ends the game_loop
    SEI
    DEY
    DEC change
    TYA ; Move contents of Y into Accumulator
    JSR lcd_instruction ; Move A to either position $1 or $40
    LDA #%10100101  
    JSR print_move_n_wait
    LDA #%00101010
    JSR print_move_n_wait
    LDA #%11011011
    JSR print_move_n_wait

    LDA #%00100000
    JSR print_char
    JSR delay_5
    
    LDX #%0
    LDA #%11000011
    JSR lcd_instruction ; Move cursor message start
    JMP lose

move_ship:
    PHA
    TXA
    PHA
    TYA
    PHA 
    LDX pos
    CPX #$0 ; If ship is top, move to bottom
    BEQ move_to_bottom
    ; Move ship from bottom to top
    LDA #%11000000 ; Move current ship position
    JSR lcd_instruction ; 
    LDA #%00100000 ; Print Clear to Display
    JSR print_char 
    LDA #%10000000 ; Move new ship position
    JSR lcd_instruction 
    
    ; Check if ship is already on top
    LDX #$4
check_ship_move_loop_t:
    LDY $0202, X  ; Check all blocks
    INY
    CPY #%10000001
    BEQ lose_setup
    DEX ; Decrease X by 1
    BNE check_ship_move_loop_t

    LDA #%10101101 ; Print Ship to Display
    JSR print_char 
    LDA #$0
    STA pos ; Update ship position
    JMP move_ship_exit
move_to_bottom:
    ; Move ship from top to bottom
    LDA #%10000000 ; Move current ship position
    JSR lcd_instruction ; 
    LDA #%00100000 ; Print Clear to Display
    JSR print_char 
    LDA #%11000000 ; Move new ship position
    JSR lcd_instruction 
    
    ; Check if ship is already on bottom
    LDX #$4
check_ship_move_loop_b:
    LDY $0202, X  ; Check all blocks
    INY
    CPY #%11000001
    BEQ lose_setup
    DEX ; Decrease X by 1
    BNE check_ship_move_loop_b

    LDA #%10101101 ; Print Ship to Display
    JSR print_char 
    LDA #$1
    STA pos ; Update ship position  
move_ship_exit:
    PLA
    TAY 
    PLA
    TAX
    PLA
    RTS

rand_gen: ; Use Linear Congruence a = 3 and b = 5
    LDA counter ; Get Seed
    ASL A ; Multiply counter by 7
    ASL A ;
    ASL A ;
    SBC counter
    ADC #$29 ; Add 41 to Accum.
    STA counter; Store new seed
    AND #%00000001 ; AND with #1 to keep last bit
    RTS

spawn_wall:
    ; Decide Whether We Need to Spawn a top or bottom wall
    JSR rand_gen
    LDX block_n ; Load in block_n
    CMP #$1 ; Check if Accum. contains a 1
    BEQ bottom_wall ; If Accum contains a 1, spawn bottom wall, else spawn top wall
    LDA #%10001111 ; Move Cursor to End of Top Display
    STA $0203, X ; Store wall location
    JSR lcd_instruction
    JMP spawn_wall_end
bottom_wall:
    LDA #%11001111 ; Move Cursor to End of Bottom Display
    STA $0203, X ; Store wall location
    JSR lcd_instruction
spawn_wall_end:
    LDA #%11111111 ; Send wall to display
    JSR print_char
    ; Adjust settings of the blocks
    CPX #$3 ; If block_n is 3, reduce to 0
    BEQ block_n_reset
    INX ; Increase counter of X
    JMP counters_end
block_n_reset:
    LDX #$0 ; change X to 0
counters_end:
    STX block_n ; Store block counter 
    RTS


nmi:
    RTI
irq:
    PHA
    LDA #$1
    STA change
    INC counter
irq_exit:
    PLA
    BIT PORTA
    RTI 


    .org $fffa
    .word nmi
    .word reset
    .word irq


