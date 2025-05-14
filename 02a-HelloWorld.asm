.cpu _65c02
#import "Libraries\\constants.asm"
#import "Libraries\\petscii.asm"
#import "Macros\\macro.asm"

BasicUpstart2(Main)

Main:
    clc                 // Set to 'place at Position'
    ldx #15             // Start at Row 15
    ldy #11             // Start at Column 11
    jsr PLOT
    
    ldy #0              // initalise pointer
Looper:
    lda Message,y       // load character from message
    beq Exit            // if the character is zero, then message
                        // has finished
    jsr CHROUT          // print the character out to the screen
    iny                 // increase pointer by 1
    bra Looper          // loop back round

Exit:
    jmp *               // stop execution

.encoding "petscii_mixed"
Message:
            .text "commander x16 says hello world"
            //.text "commander x16 for beginners"
            .byte $00



