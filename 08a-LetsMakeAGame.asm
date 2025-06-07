.cpu _65c02
#import "Libraries/constants.asm"
#import "Libraries/petscii.asm"
#import "Macros/macro.asm"
#import "Macros/longBranchMacros.asm"
#import "gameLibrary/gameConstants.asm"

#define Step01
#define Step08

BasicUpstart2(Main)

Main:
    lda #PETSCII_CLEAR
    jsr CHROUT

    lda VERA_DC_video               // Load VERA DC_Video Register
    ora #GLOBAL_SPRITE_ENABLE_ON    // Enable Sprites by setting the Bit On
    sta VERA_DC_video               // Store it back to Vera

    lda #DCSCALEx2                  // Set the Screen Scaling to be 
    sta VERA_DC_hscale              // Double Size for Horizontal
    sta VERA_DC_vscale              // and Vertical

    // this macro copies memory from the Commander X16
    // to the vera chip.
    copyDataToVera(
        spriteAssets,   // Source Address, thats where 
                        // the Sprite are located
        $8000,          // Destination Address, where we 
                        // want to put the sprites
        (_spriteNumberAssets - spriteAssets)  // Number of bytes to copy
    )

    // this macro copies memory from the Commander X16
    // to the vera chip.
    copyDataToVera(
        Characters,         // Source Address, thats where 
                            // the Characters are located
        VRAM_petscii,       // Destination Address, where we 
                            // want to put the characters
        (255*8)             // Number of bytes to copy
    )

    // Set Up Voice 00 on the Vera PSG Audio Device
	addressRegisterByValue(
        0,                                          // Data Port 0
        VERA_PSG_VOICE00 + VERA_PSG_VOLUME_OFFSET,  // Use Voice one and point
                                                    // To Volume Control Register
        1,                                          // Increment by 1 byte
        0                                           // Going Forward
    )

    // Set maximum volume and both left and right channels are on
    lda #VERA_PSG_STEREO_BOTH | %00001111
    sta VERADATA0

    lda #VERA_PSG_WAVEFORM_PULSE | $1F
    //lda #VERA_PSG_WAVEFORM_TRI | $00
    //lda #VERA_PSG_WAVEFORM_SAW | $00
    //lda #VERA_PSG_WAVEFORM_NOISE | $00
    sta VERADATA0


GameStart:
    stz GameData.CurrentPlatformIndex
    lda #5
    sta GameData.NoOfLives

    jsr Elements.Initialise         // Initialise Sprite Array
    jsr Player.Add                  // Add Player To Array
    jsr Score.AddScoreDigit
    jsr Lives.AddLife

    jsr Platform.AddToBottom
    jsr Platform.AddToBottom
    jsr Platform.AddToBottom
    jsr Platform.AddToBottom

MainLoop:
    jsr Sprites.DisplaySprites      // Display Sprites on Screen
    jsr Elements.Execute            // Execute Sprites Motions

    jsr SoundEffects.Execute

    lda GameData.PlayerState
    bpl NotDiedYet
    dec GameData.NoOfLives
    beq GameOver
    jsr Platform.ClearAllPlatforms

    stz GameData.CurrentPlatformIndex

    jsr Platform.AddToBottom
    jsr Platform.AddToBottom
    jsr Platform.AddToBottom
    jsr Platform.AddToBottom

    lda #100
    sta SpriteArray.Y
    stz GameData.PlayerState

NotDiedYet:
    jsr CheckPlatformIsOffScreen

    lda PlatformRemoved: #$00
    beq Exit

    jsr Platform.AddToBottom
    stz PlatformRemoved
Exit:

    wai
    jmp MainLoop                    // Loop back round

    GameOver:
    {
        stz Counter
        ldx #soundFxFalling
        jsr SoundEffects.Add
        Looper:
            jsr MoveEveryoneUpByOne
            jsr Sprites.DisplaySprites      // Display Sprites on Screen
            inc Counter
            lda Counter
            cmp #160
            beq DisplayGameOver
            jsr SoundEffects.Execute
            wai
            jmp Looper
        Counter: .byte 0

        DisplayGameOver:
            ldy #0
        TextLoop:
            lda GameOverText,y
            beq getKey
            jsr CHROUT
            iny
            bra TextLoop

        getKey:
            StopPSGVoice(0)
            rts
        
        .encoding "petscii_mixed"
        GameOverText:
            .byte PETSCII_HOME
            .fill 15, PETSCII_CUR_DOWN
            .fill 8, PETSCII_CUR_RIGHT
            .text "game over, man! game over"
            .byte 0
    }

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
            beq JoyTestForJump              // No, ok, that means no buttons pressed
            lda #1                          // Yes, Change Direction
            sta CurrentElement.Direction.X

        JoyTestForJump:
            lda Controls.JoyStickAResult    // load Acc Result
            and #joyPad_A_DUp               // Is Right DPad Button Pressed
            beq JoyTestNoButtonPressed      // No, ok, that means no buttons pressed
            lda CurrentElement.Spare        // Are we on a platform
            bpl JoyTestNoButtonPressed      // No, we are jumping
            lda #$FD                         // Yes, Change Direction
            sta CurrentElement.Velocity.Y
            stz CurrentElement.Spare
            ldx #soundFxJump
            jsr SoundEffects.Add

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
            lda CurrentElement.Velocity.X   // Get Velocity Of Player
            bmi GoingToTheLeft              // going to left (- V)
            setSpriteFlip(0, 0, 0)          // No, then point sprite Right
            bra StoodStillOrMoving

        GoingToTheLeft:
            setSpriteFlip(0, 1, 0)          // Yes, Then Point Sprite Left

        StoodStillOrMoving:
            lda CurrentElement.Velocity.XFrac
            ora CurrentElement.Velocity.X
            bne ThenMoving
            // StoodStill
            lda CurrentElement.SpriteFrameAddr
            and #($8100) >> 5               // Check Frame Bit for Frame 2
            beq NextFrame                   // Bit = 0 then Stood Still Frame
            stz CurrentElement.SpriteFrameAddr  // Moving Frame is Previous, 
                                            // clear for stood still Frame
            bra NextFrame

        ThenMoving:
            // Moving
            lda CurrentElement.SpriteFrameAddr  // Set Waling Frame
            and #($8100) >> 5
            bne NextFrame
            lda #($8100) >> 5
            sta CurrentElement.SpriteFrameAddr

        NextFrame:
            lda CurrentElement.FrameCounter     // Frame Counter For Animation
            inc                                 // as described in Example 4E
            and #%00001111
            sta CurrentElement.FrameCounter
            bne ContinueWithY
            lda CurrentElement.SpriteFrameAddr
            eor #$04
            sta CurrentElement.SpriteFrameAddr

        ContinueWithY:
            jsr ApplyGravityYToVelocityForCurrent
            jsr Elements.ApplyVelocityToYForCurrent

            lda CurrentElement.Velocity.Y
            bmi Continue
            jsr DetectPlatform
            bcc Continue

            stz CurrentElement.Velocity.YFrac
            stz CurrentElement.Velocity.Y
            lda #128
            sta CurrentElement.Spare

        Continue:
            lda CurrentElement.YHi
            bne DoWeNeedToMoveTheSprites
            lda CurrentElement.Y
            cmp #220
            bcc DoWeNeedToMoveTheSprites
            lda #128
            sta GameData.PlayerState

        DoWeNeedToMoveTheSprites:
            lda CurrentElement.YHi
            bne Exit
            lda CurrentElement.Y
            cmp #50
            bcs Exit
            jsr MoveEveryoneDownByOne
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
            cmp #4
            bcc YesItsAPlatform
            bra TryNextOne

        TestYNegative:
            txa
            cmp #$FC
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
            cmp #$10
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

            lda CurrentElement.Velocity.Y
            beq NotFalling
            ldx #soundFxLand
            jsr SoundEffects.Add

        NotFalling:
            lda CurrentElement.Spare
            bmi Exit
            lda #$11
            jsr Scoring.ApplyScore

            ldx #soundFxLand
            jsr SoundEffects.Add

        Exit:
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

            stz CurrentElement.X
            stz CurrentElement.XHi
            stz CurrentElement.Y
            stz CurrentElement.YHi

            lda #<$8080 >> 5
            sta CurrentElement.SpriteFrameAddr
            lda #>$8080 >> 5
            sta CurrentElement.SpriteFrameAddr + 1

            ldy GameData.CurrentPlatformIndex

            lda GameData.PlatformXLPos,y
            sta CurrentElement.X
            lda GameData.PlatformXHPos,y
            sta CurrentElement.XHi
            lda GameData.PlatformYPos,y
            bne StoreY

            lda #$FF
            sta CurrentElement.YHi
            lda #$EF

        StoreY:
            sta CurrentElement.Y

            ldx GameData.PlatformSize,y
            stx SetPlatformFrameNumber.PlatformLength
        !Looper:
            phx

            jsr SetPlatformFrameNumber
            jsr Elements.Add

            clc
            lda CurrentElement.X
            adc #16
            sta CurrentElement.X
            lda CurrentElement.XHi
            adc #0
            sta CurrentElement.XHi

            plx
            dex 
            bpl !Looper-
            inc GameData.CurrentPlatformIndex
            rts
        }

        Execute:
        {
            rts
        }

        ClearAllPlatforms:
        {
            ldx #maxElements
        !Looper:
            lda SpriteArray.Type,x
            cmp #ElementTypes.Platform
            bne !Next+
            lda #ElementTypes.Empty
            sta SpriteArray.Type,x
            lda #$FF
            sta SpriteArray.Frame,x
            stz SpriteArray.FrameCounter,x
        !Next:
            dex
            cpx #$FF
            bne !Looper-            
        }

        SetPlatformFrameNumber:
        {
            phx
            ldx PlatformLength: #1
            //cpx #1
            bne BiggerThanOne

            lda #<($8000 + (landscapeSingle * 128)) >> 5
            sta CurrentElement.SpriteFrameAddr
            lda #>($8000 + (landscapeSingle * 128)) >> 5
            sta CurrentElement.SpriteFrameAddr + 1
            plx
            rts

        BiggerThanOne:
            cpx #1
            bne BiggerThanTwo
            plx
            cpx PlatformLength
            bne SetEndPlatformFrame

        SetStartPlatformFrame:
            lda #<($8000 + (landscapeMultiStart * 128)) >> 5
            sta CurrentElement.SpriteFrameAddr
            lda #>($8000 + (landscapeMultiStart * 128)) >> 5
            sta CurrentElement.SpriteFrameAddr + 1
            rts

        SetEndPlatformFrame:
            lda #<($8000 + (landscapeMultiEnd * 128)) >> 5
            sta CurrentElement.SpriteFrameAddr
            lda #>($8000 + (landscapeMultiEnd * 128)) >> 5
            sta CurrentElement.SpriteFrameAddr + 1
            rts

        BiggerThanTwo:
            plx
            cpx PlatformLength
            beq SetStartPlatformFrame
            cpx #0
            beq SetEndPlatformFrame
            lda #<($8000 + (landscapeMultiMiddle * 128)) >> 5
            sta CurrentElement.SpriteFrameAddr
            lda #>($8000 + (landscapeMultiMiddle * 128)) >> 5
            sta CurrentElement.SpriteFrameAddr + 1
            rts


        }
    }

    Score:
    {
        AddScoreDigit:
        {
            // Y Reg : Number Of SPrites Required
            jsr Elements.Clear
            lda #ElementTypes.Score
            sta CurrentElement.Type

            stz CurrentElement.X
            stz CurrentElement.XHi
            stz CurrentElement.Y
            stz CurrentElement.YHi

            lda #<($8000 + (scoreNumberZero * 128)) >> 5
            sta CurrentElement.SpriteFrameAddr
            lda #>($8000 + (scoreNumberZero * 128)) >> 5
            sta CurrentElement.SpriteFrameAddr + 1

            ldx #5
        !Looper:
            phx

            jsr Elements.Add

            clc
            lda CurrentElement.X
            adc #8
            sta CurrentElement.X
            lda CurrentElement.XHi
            adc #0
            sta CurrentElement.XHi

            plx
            dex 
            bpl !Looper-
            rts
        }

        Execute:
        {
            dex             // Convert Sprite# to Sprite #-1 = ScorePosition
            lda GameData.Score,x
            clc
            adc #scoreNumberZero
            asl
            asl
            sta CurrentElement.SpriteFrameAddr
            rts
        }
    }

    Lives:
    {
        AddLife:
        {
            // Y Reg : Number Of SPrites Required
            jsr Elements.Clear
            lda #ElementTypes.Lives
            sta CurrentElement.Type

            lda #$30
            sta CurrentElement.X
            lda #1
            sta CurrentElement.XHi
            stz CurrentElement.Y
            stz CurrentElement.YHi

            lda #<$8000 >> 5
            sta CurrentElement.SpriteFrameAddr
            lda #>$8000 >> 5
            sta CurrentElement.SpriteFrameAddr + 1

            ldx GameData.NoOfLives
        !Looper:
            phx

            jsr Elements.Add

            sec
            lda CurrentElement.X
            sbc #11
            sta CurrentElement.X
            lda CurrentElement.XHi
            sbc #0
            sta CurrentElement.XHi

            plx
            dex 
            bne !Looper-
            rts
        }

        Execute:
        {
            lda CurrentElement.FrameCounter     // Frame Counter For Animation
            inc                                 // as described in Example 4E
            and #%00001111
            sta CurrentElement.FrameCounter
            bne ContinueWithY
            lda CurrentElement.SpriteFrameAddr
            eor #$04
            sta CurrentElement.SpriteFrameAddr

        ContinueWithY:
            txa
            sec
            sbc #7
            cmp GameData.NoOfLives
            bcc Exit
            //beq Exit
            lda #255
            sta CurrentElement.YHi

        Exit:
            rts
        }
    }

    SoundEffects:
    {
        Add:
        {
            // Inputs : X Reg = Sound Fx to set up, 0 = off
            //          Bit 7 = Down the Scales, else up the scales
            stx GameData.SoundEffects.SoundEffect
            txa
            and #%01111111
            tax
            dex

            lda GameData.SoundFxData.StartFreqH,x
            sta GameData.SoundEffects.StartFreqHi

            lda GameData.SoundFxData.StartFreqL,x
            sta GameData.SoundEffects.StartFreqLo
            stz GameData.SoundEffects.StartFreqFrac

            lda GameData.SoundFxData.EndFreqH,x
            sta GameData.SoundEffects.EndFreqHi

            lda GameData.SoundFxData.EndFreqL,x
            sta GameData.SoundEffects.EndFreqLo
            stz GameData.SoundEffects.EndFreqFrac

            lda GameData.SoundFxData.StepperFreqL,x
            sta GameData.SoundEffects.StepperFreqLo
            lda GameData.SoundFxData.StepperFreqFrac,x
            sta GameData.SoundEffects.StepperFreqFrac
            rts
        }

        Execute:
        {
            lda GameData.SoundEffects.SoundEffect
            jeq(!NoSound+)

            bmi !DownTheScale+
            // Work out next Note by adding the stepper
            clc
            lda GameData.SoundEffects.StartFreqFrac
            adc GameData.SoundEffects.StepperFreqFrac
            sta GameData.SoundEffects.StartFreqFrac

            lda GameData.SoundEffects.StartFreqLo
            adc GameData.SoundEffects.StepperFreqLo
            sta GameData.SoundEffects.StartFreqLo

            lda GameData.SoundEffects.StartFreqHi
            adc #0
            sta GameData.SoundEffects.StartFreqHi

            lda GameData.SoundEffects.EndFreqHi

            lda GameData.SoundEffects.EndFreqLo
            stz GameData.SoundEffects.EndFreqFrac

            sta GameData.SoundEffects.StepperFreqLo

            lda GameData.SoundEffects.StartFreqHi   // Load Frequency Hi
            cmp GameData.SoundEffects.EndFreqHi     // has it hit the threshold
            beq !CheckLo+                           // Yes its the same, then check lo frequency
            bcs !ByPassSwitchOffVoice+              // Yes, its above, then reset effect
            bra SetVoice

        !CheckLo:
            lda GameData.SoundEffects.StartFreqLo   // Load Frequency Lo
            cmp GameData.SoundEffects.EndFreqLo     // has it hit the threshold
            bcs !ByPassSwitchOffVoice+              // Yes its above, then reset effect
            bra SetVoice

        !DownTheScale:
            // Work out next Note by subtracting the stepper
            sec
            lda GameData.SoundEffects.StartFreqFrac
            sbc GameData.SoundEffects.StepperFreqFrac
            sta GameData.SoundEffects.StartFreqFrac

            lda GameData.SoundEffects.StartFreqLo
            sbc GameData.SoundEffects.StepperFreqLo
            sta GameData.SoundEffects.StartFreqLo

            lda GameData.SoundEffects.StartFreqHi
            sbc #0
            sta GameData.SoundEffects.StartFreqHi

            lda GameData.SoundEffects.StartFreqHi   // Load Frequency Hi
            cmp GameData.SoundEffects.EndFreqHi     // has it hit the threshold
            beq !CheckLo+                           // Yes its the same, then check lo frequency
            bcc !ByPassSwitchOffVoice+              // Yes, its above, then reset effect
            bra SetVoice

        !CheckLo:
            lda GameData.SoundEffects.StartFreqLo   // Load Frequency Lo
            cmp GameData.SoundEffects.EndFreqLo     // has it hit the threshold
            bcc !ByPassSwitchOffVoice+              // Yes its above, then reset effect

        SetVoice:
            PlayNote(0,GameData.SoundEffects.StartFreqLo)

        !NoSound:
            rts

        !ByPassSwitchOffVoice:
            addressRegisterByValue(
                0,                                          // Data Port 0
                VERA_PSG_VOICE00 + VERA_PSG_FREQLO_OFFSET,  // Use Voice one and point
                                                            // To Frequency Register low
                ADDRESS_STEP_1,                             // No Increment
                0                                           // Going Forward
            )
            stz VERADATA0
            stz VERADATA0
            stz GameData.SoundEffects.SoundEffect
            rts
        }
    }

    GameData:
    {
        PlatformXLPos:
        {
            .byte 0, 150, 50, 100
            .fill 250, round(random() * 225)
        }

        PlatformXHPos:
        {
            .byte 0, 0, 0, 0
            .fill 250, 0
        }

        PlatformSize:
        {
            .byte 19, 3, 2, 4
            .fill 250, round(random() * 4)
        }

        PlatformYPos:
        {
            .byte 220, 160, 100, 40
            .fill 250, 0
        }
        CurrentPlatformIndex: .byte 0
        Score: .byte 0,0,0,0,0,0
        NoOfLives: .byte 0
        PlayerState: .byte 0

        SoundFxData:
        {
            StartFreqL: .byte <VERA_PSG_NOTE_C2, <VERA_PSG_NOTE_G3, <VERA_PSG_NOTE_A5 
            StartFreqH: .byte >VERA_PSG_NOTE_C2, >VERA_PSG_NOTE_G3, >VERA_PSG_NOTE_A5

            StepperFreqFrac: .byte 0, 0, $0
            StepperFreqL: .byte 21, $39, $10

            EndFreqL: .byte <VERA_PSG_NOTE_ASharp4, <VERA_PSG_NOTE_A2, <VERA_PSG_NOTE_A0
            EndFreqH: .byte >VERA_PSG_NOTE_ASharp4, >VERA_PSG_NOTE_A2, >VERA_PSG_NOTE_A0
        }

        SoundEffects:
        {
            SoundEffect: .byte 0        // What Sound Effect

            StartFreqFrac: .byte 0
            StartFreqLo: .byte 0
            StartFreqHi: .byte 0

            StepperFreqFrac: .byte 0
            StepperFreqLo: .byte 0
            StepperFreqHi: .byte 0

            EndFreqFrac: .byte 0
            EndFreqLo: .byte 0
            EndFreqHi: .byte 0
        }
    }

    ApplyGravityYToVelocityForCurrent:
    {
        clc
        lda CurrentElement.Velocity.YFrac
        adc CurrentElement.Acceleration.YFrac
        sta CurrentElement.Velocity.YFrac

        lda CurrentElement.Velocity.Y
        adc CurrentElement.Acceleration.Y
        sta CurrentElement.Velocity.Y
        bra !Exit+

    !Exit:
        rts
    }

    MoveEveryoneDownByOne:
    {
        // Outputs  : 
        //          : 
        ldx #0
    !Looper:
        lda SpriteArray.Type,x
        cmp #ElementTypes.Platform
        //cmp #ElementTypes.Empty
        beq !Found+

    !NextOnePlease:
        inx
        cpx #maxElements
        bne !Looper-
        rts

    !Found:
        clc
        lda SpriteArray.Y,x
        adc #1
        sta SpriteArray.Y,x
        lda SpriteArray.YHi,x
        adc #0
        sta SpriteArray.YHi,x
        bra !NextOnePlease-
    }

    MoveEveryoneUpByOne:
    {
        // Outputs  : 
        //          : 
        ldx #0
    !Looper:
        lda SpriteArray.Type,x
        cmp #ElementTypes.Platform
        //cmp #ElementTypes.Empty
        beq !Found+

    !NextOnePlease:
        inx
        cpx #maxElements
        bne !Looper-
        rts

    !Found:
        sec
        lda SpriteArray.Y,x
        sbc #2
        sta SpriteArray.Y,x
        lda SpriteArray.YHi,x
        sbc #0
        sta SpriteArray.YHi,x
        bra !NextOnePlease-
    }

    CheckPlatformIsOffScreen:
    {
        // Outputs  : 
        //          : 
        ldx #0
        stz PlatformRemoved
    !Looper:
        lda SpriteArray.Type,x
        cmp #ElementTypes.Empty
        bne !Found+

    !NextOnePlease:
        inx
        cpx #maxElements
        bne !Looper-
        rts

    !Found:
        lda SpriteArray.YHi,x
        bne !NextOnePlease-
        lda SpriteArray.Y,x
        cmp #240
        bcc !NextOnePlease-
        lda #ElementTypes.Empty
        sta SpriteArray.Type,x

        lda #1
        sta PlatformRemoved
        bra !NextOnePlease-
    }

#import "gameLibrary/gameConstants.asm"
#import "gameLibrary/gameElements.asm"
#import "gameLibrary/gameSprites.asm"
#import "gameLibrary/gameScoring.asm"
#import "Libraries/controls.asm"


spriteAssets:
#import "gameLibrary/spriteAssets.asm"
_spriteAssets:

spriteNumberAssets:
#import "gameLibrary/spriteNumbers.asm"
_spriteNumberAssets:

Characters:
#import "Assets/data.asm"
_Characters:
