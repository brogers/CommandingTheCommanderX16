.cpu _65c02
#import "Libraries/constants.asm"
#import "Libraries/petscii.asm"
#import "Macros/macro.asm"

BasicUpstart2(Main)

Main:
    addressRegisterByValue(
        DATA_PORT0,         // Set to DATA0
        $1B000              // The Address we want to start at
            +(15*$100) + 22,// then add the offset, to place 
                            // it in the same place as before
        ADDRESS_STEP_1,     // Every Byte
        ADDRESS_DIR_FORWARD // Going forwards
    )
    
    ldy #0              // initalise pointer
Looper:
    lda Message,y       // load character from message
    beq Exit            // if the character is zero, then message
                        // has finished
    sta VERADATA0       // poke the character on to the screen
    iny                 // increase pointer by 1
    bra Looper          // loop back round

Exit:
    jmp *               // stop execution

.encoding "screencode_mixed"
 
Message:
            .text "commander x16 says hello world"
            //.text "commander x16 for beginners"
            .byte $00



