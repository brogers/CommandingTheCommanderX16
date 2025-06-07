.cpu _65c02
#import "Libraries/constants.asm"
#import "Libraries/petscii.asm"
#import "Macros/macro.asm"
#import "gameLibrary/gameConstants.asm"

#define Step01

BasicUpstart2(Main)

Main:
    lda VERA_DC_video               // Load VERA DC_Video Register
    ora #GLOBAL_SPRITE_ENABLE_ON    // Enable Sprites by setting the Bit On
    sta VERA_DC_video               // Store it back to Vera

    lda #DCSCALEx2                  // Set the Screen Scaling to be 
    sta VERA_DC_hscale              // Double Size for Horizontal
    sta VERA_DC_vscale              // and Vertical

    // Creates Two Block Sprites, One Yellow (Player) and Green (Platform)
    addressRegisterByValue(0,$08000,ADDRESS_STEP_1,ADDRESS_DIR_FORWARD)
    ldy #0
!Looper:
    bmi !Green+
    lda #$77
    skip2Bytes()
!Green:
    lda #$55
    sta VERADATA0
    iny
    bne !Looper-

    jsr Elements.Initialise         // Initialise Sprite Array
    jsr Player.Add                  // Add Player To Array

    ldy #20
    jsr Platform.AddToBottom

MainLoop:
    jsr Sprites.DisplaySprites      // Display Sprites on Screen
    jsr Elements.Execute            // Execute Sprites Motions

    wai
    jmp MainLoop                    // Loop back round

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

            lda #accelerationFrac
            sta CurrentElement.Acceleration.XFrac

            lda #gravitaionaccelerationFrac
            sta CurrentElement.Acceleration.YFrac

            lda #collideWithPlatform | collideWithEnemies | collideWithPowerUps
            sta CurrentElement.CollisionMask

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
            jmp JoyTestNoButtonPressed      // Now work out new Position

        JoyTestForRight:
            lda Controls.JoyStickAResult    // load Acc Result
            and #joyPad_A_DRight            // Is Right DPad Button Pressed
            beq JoyTestNoButtonPressed      // No, ok, that means no buttons pressed
            lda #1                          // Yes, Change Direction
            sta CurrentElement.Direction.X

        JoyTestNoButtonPressed:
            lda CurrentElement.Direction.X
            beq ApplyFriction               // Apply Friction if No Direction is selected

            // Apply Acceleration To Velocity
            jsr Elements.ApplyAccelerationXToVelocityForCurrent
            bra WorkOutNowXPosition

        ApplyFriction:
            // Apply Friction To Velocity
            jsr Elements.ApplyFrictionXToVelocityForCurrent

        WorkOutNowXPosition:
            // Apply Velocity to the X Position of the Sprite
            jsr Elements.ApplyVelocityToXForCurrent

        TestRightHandEdge:
            lda CurrentElement.Velocity.X
            bmi TestLeftHandEdge   // Sprite is on the Left Hand Edge Somewhere

            lda CurrentElement.XHi
            cmp #1                  // Test Hi byte for Right hand edge of screen
            bne ApplyGravity

            lda CurrentElement.X
            cmp #$40                // if Hi Byte is 1 are we at end of screen
            bcc ApplyGravity                // No, then exit, were done
                                    // Yes, set player to far left of screen
                                    // to simulate wrapping round

            lda #$F1                // Set 16 bits before screen start
            sta CurrentElement.X
            lda #$FF
            sta CurrentElement.XHi

            bra ApplyGravity

        TestLeftHandEdge:
            lda CurrentElement.XHi
            cmp #$FF                // Check for Left hand side of screen
            bne ApplyGravity

            lda CurrentElement.X
            cmp #$F0                // gone off screen
            bcc ApplyGravity                // No, exit

            lda #$40                // Yes, then set player to right hand side
            sta CurrentElement.X    // To simulate screen wrapping
            lda #$01
            sta CurrentElement.XHi

        ApplyGravity:
            jsr DetectPlatform      // Before, are we above a platform
            bcs ResetVelocity       // Yes, then reset Velocity
            // Not, then apply gravity
            jsr Elements.ApplyAccelerationYToVelocityForCurrent.ApplyGravity
            // Apply Velocity to Y 
            jsr Elements.ApplyVelocityToYForCurrent

            bra Exit
            
        ResetVelocity:
            // Reset Velocity to Zero
            stz CurrentElement.Velocity.YFrac
            stz CurrentElement.Velocity.Y

        Exit:
            rts
        }

        DetectPlatform:
        {
            ldy #0
        Looper:
            lda SpriteArray.Type,y
            cmp #ElementTypes.Platform
            beq TestIfHitPlatform

        TryNextOne:
            iny
            cpy #maxElements
            bne Looper
            clc
            rts

        TestIfHitPlatform:
            clc
            lda CurrentElement.Y
            adc #17                 // Make Y Base of Sprite
            sta AdjustedYBottomLo
            lda CurrentElement.YHi
            adc #0
            sta AdjustedYBottomHi

            sec
            lda AdjustedYBottomLo: #$FF
            sbc SpriteArray.Y,y
            sta ComparisonYLo

            lda AdjustedYBottomHi: #$FF
            sbc SpriteArray.YHi,y
            sta ComparisonYHi

            lda ComparisonYHi: #$00
            ldx ComparisonYLo: #$00
            
            cmp #$FF
            beq TestYNegative

            // Test Positive
            txa
            cmp #12
            bcc YesItsAPlatform
            bra TryNextOne

        TestYNegative:
            txa
            cmp #$F4
            bcs YesItsAPlatform
            bra TryNextOne

        YesItsAPlatform:
            lda CurrentElement.X
            sec
            sbc SpriteArray.X,y
            sta ComparisonXLo

            lda CurrentElement.XHi
            sbc SpriteArray.XHi,y
            sta ComparisonXHi

            lda ComparisonXHi: #$00
            ldx ComparisonXLo: #$00
            
            cmp #$FF
            beq TestXNegative

            // Test Positive
            txa
            cmp #16
            bcc YesItsDeffoPlatform
            bra TryNextOne

        TestXNegative:
            txa
            cmp #$F0
            bcs YesItsDeffoPlatform
            bra TryNextOne

        YesItsDeffoPlatform:
            lda SpriteArray.Y,y
            sec
            sbc #16
            sta CurrentElement.Y

            lda SpriteArray.YHi,y
            sbc #0
            sta CurrentElement.YHi

            sec
            rts

        }
    }

    Platform:
    {
        AddToBottom:
        {
            // Y Reg : Number Of SPrites Required
            jsr Elements.Clear
            lda #ElementTypes.Platform
            sta CurrentElement.Type

            lda #220
            stz CurrentElement.X
            sta CurrentElement.Y
            lda #<$8080 >> 5
            sta CurrentElement.SpriteFrameAddr
            lda #>$8080 >> 5
            sta CurrentElement.SpriteFrameAddr + 1

        !Looper:
            phy
            jsr Elements.Add
            clc
            lda CurrentElement.X
            adc #16
            sta CurrentElement.X
            lda CurrentElement.XHi
            adc #0
            sta CurrentElement.XHi
            ply
            dey 
            bne !Looper-
            rts
        }

        Execute:
        {
            rts
        }
    }

#import "gameLibrary/gameConstants.asm"
#import "gameLibrary/gameElements.asm"
#import "gameLibrary/gameSprites.asm"
#import "Libraries/controls.asm"