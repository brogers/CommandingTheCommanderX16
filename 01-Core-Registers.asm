.cpu _65c02
#importonce 

BasicUpstart2(Main)

Main:
    // First we must set the Data Port we want to use.
    lda #0
    sta $9F25
    // This will also set the auto incrementor to Zero.

    lda #$A5        // Set VERA Memory Low Address
    sta $9F20

    lda #$38        // Set VERA Memory Middle Address
    sta $9F21

    lda #$01
    sta $9F22       // Set VERA Memory High (Data Bank)

    lda #$55        // load the value we want to store in VERA Memory
                    // location $138A5
    sta $9F23       // DATA0

    jmp *