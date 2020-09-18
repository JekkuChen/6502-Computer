  
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E = %10000000
RW = %01000000
RS = %00100000

    .org $8000
reset:  
    ldx #$ff 
    txs 

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

    ldx #0
loop1:
    lda message,x
    BEQ loop
    jsr print_char
    inx
    jmp loop1
     
loop:
    jmp loop

message: .asciiz "Hello, World!                            Goodbye, World!  "


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

nmi:
    rti
irq:
    inc counter
    bne exit_irq
    inc counter + 1
    rti 


    .org $fffa
    .word nmi
    .word reset
    .word irq


