.cpu _65c02
#import "Libraries\\constants.asm"
#import "Libraries\\petscii.asm"
#import "Macros\\macro.asm"

BasicUpstart2(Main)

Main:
    lda VERA_DC_video               // Load VERA DC_Video Register
    ora #GLOBAL_SPRITE_ENABLE_ON    // Enable Sprites by setting the Bit On
    sta VERA_DC_video               // Store it back to Vera

    lda #DCSCALEx2                  // Set the Screen Scaling to be 
    sta VERA_DC_hscale              // Double Size for Horizontal
    sta VERA_DC_vscale              // and Vertical

    // this macro copies memory from the Commander X16
    // to the vera chip.
    copyDataToVera(
        Sprites,        // Source Address, thats where 
                        // the Sprite are located
        $8000,          // Destination Address, where we 
                        // want to put the sprites
        128             // Number of bytes to copy
    )

    // Now, to set up Sprite 0
    setUpSpriteInVera(
        0,                      // Set Sprite 0
        $8000,                  // Sprite Frame at Vera Addr $8000
        SPRITE_MODE_16_COLOUR,  // Set sprite to 16 Colour mode
        6,                      // Set X to be 250 pixels
        65,                     // Set Y to be 65 Pixels
        SPRITE_ZDEPTH_AFTERLAYER1,  // Put the sprite above Layer 1
        SPRITE_HEIGHT_16PX,     // Set Sprite Height to be 16 pixels
        SPRITE_WIDTH_16PX,      // Set Sprite Width to be 16 pixels
        0)                      // And set to Palette 0


Looper:
    wai                     // Wait for Next Frame
    clc                     // Clear the carry, ready for addition
    lda XPos                // load XPosition
    adc Direction           // Add the Direction Value
    sta XPos                // Store back to X Position

    lda XPos + 1
    adc #0
    sta XPos + 1

    moveSpriteInVera(0, XPos, YPos)

    jmp Looper               // stop execution

    XPos: .word 6
    YPos: .word 89
    Direction: .byte 1

Sprites:
#import "Assets\\ManicMiner.asm"
_Sprites:
