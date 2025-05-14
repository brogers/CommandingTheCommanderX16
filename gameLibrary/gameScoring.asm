.cpu _65c02
#importonce

.namespace Scoring {

    ResetScore:
    {
        // Reset Score back to Zero
        ldy #0
    !Looper:
        lda #0
        // Set every Digit to Zero
        sta GameData.Score,y
        iny
        cpy #6
        bne !Looper-
        rts
    }

    ApplyScore:
    {
        // XXXX XXXX
        // 0000      = Value Digit Position, 0=1s, 1=10s, 2=100s, 3=1000s, 4=10000s... to 5
        //      0000 = The Value of that digit position = 0 -> 9

        // Input : Accumulator : Contain Score Value

        pha         // Store on Stack Temporarily
        lsr         // divide by 2
        lsr         // divide by 4
        lsr         // divide by 8
        lsr         // divide by 16

        // 012356 = Display Index
        // 543210 = Digit Index
        // 000000
        // ^^^^^^- 1's
        // |||||-- 10's
        // ||||--- 100's
        // |||---- 1000's
        // ||----- 10000's
        // |------ 100000's

        // Work out which digit to change
        // Scoring Digit = 6 - Digit Index
        eor #$FF
        sec
        adc #5
        sta ScoringDigit

        // Grab Value to apply to the digit
        pla
        and #%00001111
        sta ScoringValue

        ldy ScoringDigit
    !AddToNextDigit:
        lda GameData.Score,y
        clc
        adc ScoringValue
        cmp #$0A
        bcs !AddCarryToNextDigit+
        sta GameData.Score,y
    !Exit:
        rts

    !AddCarryToNextDigit:
        sec
        sbc #$0A
        sta GameData.Score,y
        dey
        bmi !Exit-
        lda #1
        sta ScoringValue
        jmp !AddToNextDigit-

        ScoringDigit: .byte $00
        ScoringValue: .byte $00
    }
}
