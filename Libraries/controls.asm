.cpu _65c02
#importonce 

.namespace Controls {

    JoyStickAResult:    .byte $00
    JoyStickXResult:    .byte $00
    JoystickPresent:    .byte $00

    GetJoyStick:
    {
            // Joystick Get Results
            // Acc: | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
            //  SNES| B | Y |SEL|STA| UP|DN |LFT|RGT|
            // X:
            //  SNES| A | X |LSB|RSB| 1 | 1 | 1 | 1 |
            // Y:
            //      $00 = Joystick Present, $FF = Not
            // Default State of Bits = 1; inverted 0 = Pressed

            // Acc and X Reg from this routine, will be inverted
            // for ease of use

            .label tmpAccumlator = JoyStickAResult
            .label tmpXReg = JoyStickXResult
            .label tmpYReg = JoystickPresent
        Looper:
            stz tmpAccumlator        // Clears Out Joystick Register
            stz tmpXReg
            stz tmpYReg

            lda #CONTROLLER_KBD
            jsr JOYSTICK_GET

            eor #$FF
            sta tmpAccumlator
            txa
            eor #$FF
            sta tmpXReg

            lda #CONTROLLER_SNES1
            jsr JOYSTICK_GET

            eor #$FF
            ora tmpAccumlator
            sta tmpAccumlator
            txa
            eor #$FF
            ora tmpXReg
            sta tmpXReg
        rts
    }   
}
