.cpu _65c02
#import "Libraries/constants.asm"
#import "Libraries/petscii.asm"
#import "Macros/macro.asm"

BasicUpstart2(Main)

Main:
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
            // HOME PETSCII Character
            .byte $13
            // CUR DOWN PETSCII Character
            .byte $11, $11, $11, $11, $11, $11, $11, $11, $11
            .byte $11, $11, $11, $11, $11, $11
            // CUR RIGHT PETSCII Character
            .byte $1D, $1D, $1D, $1D, $1D, $1D, $1D, $1D, $1D, $1D, $1D
            .text "commander x16 says hello world"
            //.text "commander x16 for beginners"
            .byte $00



