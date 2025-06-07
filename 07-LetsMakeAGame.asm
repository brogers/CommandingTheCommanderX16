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

    // Creates Two Block Sprites, One Yellow (Player) and Green (Platform)
    addressRegisterByValue(
        0,                      // Use Data Port 0
        $08000,                 // Start ar Vera Address $08000
        ADDRESS_STEP_1,         // Increment in single byte steps
        ADDRESS_DIR_FORWARD     // going forward up the memory
        )
    ldy #0
!Looper:
    bmi !Green+
    lda #$77                // Create a Yellow Sprite
    skip2Bytes()
!Green:
    lda #$55                // Create a Green Sprite
    sta VERADATA0
    iny
    bne !Looper-

    jsr Elements.Initialise         // Initialise Sprite Array
    jsr Player.Add                  // Add Player To Array

// Main Loop ----------------------------------------------------------------
MainLoop:
    jsr Sprites.DisplaySprites      // Display Sprites on Screen
    jsr Elements.Execute            // Execute Sprite Behaviors

    wai
    jmp MainLoop                    // Loop back round
// Main Loop End ------------------------------------------------------------

    Player:
    {
        Add:
        {
            jsr Elements.Clear          // Clear the new Element
            lda #ElementTypes.Player    // Set Type of Element to "Player"
            sta CurrentElement.Type

            lda #100                    // Default X Position to 100
            sta CurrentElement.X
            sta CurrentElement.Y        // Default Y Position to 100
            lda #$80 >> 5               // Set Player Frame, to be stored in VERA
            sta CurrentElement.SpriteFrameAddr + 1

            jsr Elements.Add            // Add to the Sprite Array
            rts
        }
        Execute:
        {
            lda #0                          // Reset X and Y Directions
            sta CurrentElement.Direction.X
            sta CurrentElement.Direction.Y

            jsr Controls.GetJoyStick        // Get state of keyboard and Joy1
            lda Controls.JoyStickAResult    // load Acc Result
            and #joyPad_A_DLeft             // Is Left DPad Button Pressed
            beq JoyTestForRight             // No, ok, lets try the Right
            lda #255                        // Yes, Change Direction
            sta CurrentElement.Direction.X
            jmp WorkOutNowXPosition         // Now work out new Position

        JoyTestForRight:
            lda Controls.JoyStickAResult    // load Acc Result
            and #joyPad_A_DRight            // Is Right DPad Button Pressed
            beq JoyTestNoButtonPressed      // No, ok, that means no buttons pressed
            lda #1                          // Yes, Change Direction
            sta CurrentElement.Direction.X

        JoyTestNoButtonPressed:
        WorkOutNowXPosition:
            lda CurrentElement.Direction.X
            beq Exit                // No Moving, so bypass all
            bmi Subtract            // if bit 7 set, then its must be a subtraction

            // Set Player to Go Right
            clc                     // Clear the carry, ready for addition
            lda CurrentElement.X    // load XPosition
            adc #1                  // Add 1
            sta CurrentElement.X    // Store back to X Position

            lda CurrentElement.XHi  // Add Carry To Hi byte, just in case 
                                    // of page crossing
            adc #0
            sta CurrentElement.XHi

            cmp #1                  // Test Hi byte for end of screen
            bne Exit

            lda CurrentElement.X
            cmp #$40                // if Hi Byte is 1 are we at end of screen
            bcc Exit                // No, then exit, were done
                                    // Yes, set player to far left of screen
                                    // to simulate wrapping round

            lda #$F1                // Set 16 bits before screen start
            sta CurrentElement.X
            lda #$FF
            sta CurrentElement.XHi

            bra Exit

        Subtract:
            sec                     // set the carry, ready for subtraction
            lda CurrentElement.X    // load XPosition
            sbc #1                  // Subtract 1
            sta CurrentElement.X    // Store back to X Position

            lda CurrentElement.XHi  // Subtract carry from Hi Byte
                                    // just in case of page crossing
            sbc #0
            sta CurrentElement.XHi

            cmp #$FF                // Check for LEft hand side of screen
            bne Exit

            lda CurrentElement.X
            cmp #$F0                // gone off screen
            bcc Exit                // No, exit

            lda #$40                // Yes, then set player to right hand side
            sta CurrentElement.X    // To simulate screen wrapping
            lda #$01
            sta CurrentElement.XHi

        Exit:
            rts
        }
    }

#import "gameLibrary/gameConstants.asm"
#import "gameLibrary/gameElements.asm"
#import "gameLibrary/gameSprites.asm"
#import "Libraries/controls.asm"