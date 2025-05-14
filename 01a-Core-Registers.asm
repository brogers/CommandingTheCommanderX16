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

    lda #$01        // Set VERA Memory High (Data Bank)
    ora #$05 << 4   // This loads 5, then shift left 4 places as the Address
                    // Increment uses the high nibble of the byte, so easier to 
                    // let the assembler work it out :) Incrementents by 16
    sta $9F22       // Set VERA Memory High (Data Bank), 
                    // Appendix A ADDR_H ($9F22) for details on auto-increment values

    ldx #$08
Looper:
    lda #$55        // load the value we want to store in VERA Memory
                    // location $138A5 and every 8 bytes after that
    sta $9F23       // DATA0
    dex
    bne Looper
    jmp *