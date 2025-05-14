.cpu _65c02
#importonce 

#import "Libraries\\constants.asm"
#import "Macros\\macro.asm"

BasicUpstart2(Main)

Main:
    addressRegisterByValue(
        DATA_PORT0,         // Set to DATA0
        $138A5,             // The Address we want to start at
        ADDRESS_STEP_16,    // Every 16th Byte
        ADDRESS_DIR_FORWARD // Going forwards
    )

    ldx #$08
Looper:
    lda #$55        // load the value we want to store in VERA Memory
                    // location $138A5 and every 8 bytes after that
    sta $9F23       // DATA0
    dex
    bne Looper
    jmp *