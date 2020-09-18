  
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003


    .org $8000
reset:   
    lda #$ff
    sta DDRB

    lda #$50
    sta PORTB

loop:
    ror
    sta $6000

    jmp loop

    .org $fffc
    .word reset
    .word $0000

