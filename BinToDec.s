  
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

value= $0200 ; 2 bytes
mod10= $0202 ; 2 bytes
message = $0204 ;6 bytes
counter = $020a ; 2 bytes

E = %10000000
RW = %01000000
RS = %00100000

    .org $8000
reset:  
    ldx #$ff 
    txs 
    cli

    lda #%11111111 ; Set all pins on Port B to output 
    sta DDRB
    lda #%11100000 ; Set pins 5-7 on Port B to output
    sta DDRA 

    lda #%00111000 ; Set 8-bit mode; two line display; 5 x 8 font
    jsr lcd_instruction
    lda #%00001110 ; Display on; cursor on; blink off
    jsr lcd_instruction
    lda #%00000110 ; Increment and shift cursor; don't shift display (scroll)
     jsr lcd_instruction
    lda #%00000001 ; Clear Display
    jsr lcd_instruction

    lda #0
    sta counter 
    sta counter + 1

loop:
    lda #%00000010 ; Home
    jsr lcd_instruction

    lda #0
    sta message

; Initialize Value to be the number we want to convert
    lda counter
    sta value
    lda counter + 1
    sta value + 1

divide: 
; Initialize remainder to be 0
    lda #0
    sta mod10
    sta mod10 + 1
    clc

    ldx #16
divloop:
;Rotate quotient and remainder
    rol value
    rol value + 1
    rol mod10
    rol mod10 + 1

; a,y = dividend - divisor
    sec 
    lda mod10
    sbc #10
    tay ; save low byte in Y
    lda mod10 + 1
    sbc #0
    bcc ignore_result ; branch if divident < divsor
    sty mod10
    sta mod10 + 1


ignore_result:
    dex
    bne divloop
    rol value ; shift in the last bit of the quotient
    rol value + 1
    lda mod10
    clc
    adc #"0"
    jsr push_char  

    ; if value !=0, then continue dividing
    lda value
    ora value + 1
    bne divide ; branch if value not zero

 
    ldx #0
loop1:
    lda message,x
    BEQ loop2 
    jsr print_char
    inx
    jmp loop1
loop2:   
    cli
    jmp loop

number: .word 1729

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

; Add the character in the A reg to the beginning of the null 
; -terminated string 'message'
push_char:
    pha ; Push new first char onto stack
    ldy #0 

char_loop: 
    lda message,y ; Get char on string and put into X
    tax
    pla 
    sta message,y ; Pull char off stack and add it to the string
    iny 
    txa
    pha ; Push char from string onto stack
    bne char_loop

    pla 
    sta message,y ;Pull the null off the stack and add to the end of the string

    rts


nmi:
    rti
irq:
    inc counter
    bne exit_irq
    inc counter + 1
    SEI 
exit_irq:
    rti

    .org $fffa
    .word nmi
    .word reset
    .word irq
