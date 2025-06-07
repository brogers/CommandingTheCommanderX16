.cpu _65c02
#import "Libraries/constants.asm"
#import "Libraries/petscii.asm"
#import "Macros/macro.asm"

BasicUpstart2(Main)

Main:
    addressRegisterByValue(
        DATA_PORT0,         // Set to DATA0
        VRAM_petscii + (128*8), // The Address of the 128th
                                // Character Definition
        ADDRESS_STEP_1,     // Every Byte
        ADDRESS_DIR_FORWARD // Going forwards
    )
    
    ldx #0              // the X register will keep of the number of bytes
Looper:
    lda Character,x     // load the character definition row
    sta VERADATA0       // store it into the Vera Char definition Row
    inx                 // next byte
    cpx #8              // Did we copy 8 bytes?
    bne Looper          // No, then loop back round

    addressRegisterByValue(
        DATA_PORT0,         // Set to DATA0
        VRAM_layer1_map     // The Address we want show
            + (15 * $100) + 10, // the character on screen
        ADDRESS_STEP_1,     // Every Byte
        ADDRESS_DIR_FORWARD // Going forwards
    )

    lda #128            // load the character code
    sta VERADATA0       // store it on screen in vera

    jmp *               // stop execution

Character:
// Custom smiley face tile (8x8 pixels)
// Each byte represents one row of pixels in the tile
    .byte %00111100  // Row 1
    .byte %01000010  // Row 2
    .byte %10100101  // Row 3
    .byte %10000001  // Row 4
    .byte %10100101  // Row 5
    .byte %10011001  // Row 6
    .byte %01000010  // Row 7
    .byte %00111100  // Row 8
