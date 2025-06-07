.cpu _65c02
#import "Libraries/constants.asm"
#import "Libraries/petscii.asm"
#import "Macros/macro.asm"

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
        (8 * 128)       // Number of bytes to copy
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
    sta XPos                // Stor back to X Position

    cmp #5                  // Have we reached the left hand edge ?
    bne TestRightHandSide   // No, then continue with the move

    lda #1                  // Yes, we did, Change Direction To 1 (Right)
    sta Direction           // Store Direction
    setSpriteFlip(0, 0, 0)  // Reset Horizontal Flip on sprite
    jmp UpdateSpriteLocation

TestRightHandSide:
    cmp #250                // Have we reach the right hand edge ?
    bne UpdateSpriteLocation// No, then continue with the move

    lda #255                // Yes, we did, Change Direction To 255 (Left)
    sta Direction           // Store Direction
    setSpriteFlip(0, 1, 0)  // Activate Horizontal Flip on sprite

UpdateSpriteLocation:
    // Update Sprite Zero's XPosition and Y Position
    moveSpriteInVera(0, XPos, YPos)

    inc FrameCounter        // Increase our frame counter by 1
    lda FrameCounter        // Load Frame Counter
    and #%00111111          // Mask off the lower 31, as only 8 frames x 4 = 32
                            // 0 -> 31
    sta FrameCounter        // Store back into Frame Counter
    lsr                     // Divide by 2
    and #%11111100          // Clear out the bottom 2 bits
    sta SpriteFrameAddr     // Store in Sprite Frame Address

    // This effectively changes the sprite frame every 4 frames of the video

    setSpriteAddressInVeraByAddr(0, SpriteFrameAddr, SPRITE_MODE_16_COLOUR)
    jmp Looper               // stop execution

    XPos: .word 6
    YPos: .word 89
    Direction: .byte 1
    FrameCounter: .byte 0
    SpriteFrameAddr: .word $8000 >> 5

Sprites:
#import "Assets/ManicMinerWalking.asm"
_Sprites:
