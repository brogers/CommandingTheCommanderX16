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

	addressRegisterByValue(
        0,                                          // Data Port 0
        VERA_PSG_VOICE00 + VERA_PSG_VOLUME_OFFSET,  // Use Voice one and point
                                                    // To Volume Control Register
        1,                                          // Increment by 1 byte
        0                                           // Going Forward
    )

    // Set maximum volume and both left and right channels are on
    lda #VERA_PSG_STEREO_BOTH | %00111111
    sta VERADATA0

    lda #VERA_PSG_WAVEFORM_PULSE | $1F
    //lda #VERA_PSG_WAVEFORM_TRI | $00
    //lda #VERA_PSG_WAVEFORM_SAW | $00
    //lda #VERA_PSG_WAVEFORM_NOISE | $00
    sta VERADATA0

Looper:
    //jsr SetUpFloater
    //jsr SetUpSwoopers
    //jsr SetUpBuzzerDive
    jsr SetUpPods
    //jsr SetUpBullet

    //jsr SetUpExplosion

    // This is the sound effect execution routine
SimIRQ:
    // This works out the next note to be played on the PSG
    sec
    lda VoiceFreqFrac               // Load Frequency Fraction
    sbc VoiceFreqStepperFrac        // Add Frequency Stepper Fraction
    sta VoiceFreqFrac               // Save Frequency Fraction
    lda VoiceFreq                   // Load Frequency Lo
    sbc VoiceFreqStepper            // Add Frequency Stepper Lo
    sta VoiceFreq                   // Save Frequency Lo
    lda VoiceFreq + 1               // Load Frequency Hi
    sbc VoiceFreqStepper + 1        // Add Frequency Stepper Hi
    sta VoiceFreq + 1               // Save Frequency Hi

!ByPass:
    lda VoiceFreq + 1               // Load Frequency Hi
    cmp VoiceFreqThreshold + 1      // has it hit the threshold
    beq !CheckLo+                   // Yes its the same, then check lo frequency
    bcs !ByPassSwitchOffVoice+      // Yes, its above, then reset effect

!CheckLo:
    lda VoiceFreq                   // Load Frequency Lo
    cmp VoiceFreqThreshold          // has it hit the threshold
    bcs !ByPassSwitchOffVoice+      // Yes its above, then reset effect

    wai                             // Wait for next video frame

    jmp Looper                      // Loop back round

!ByPassSwitchOffVoice:
	addressRegisterByValue(
        0,                                          // Data Port 0
        VERA_PSG_VOICE00 + VERA_PSG_FREQLO_OFFSET,  // Use Voice one and point
                                                    // To Frequency Register low
        0,                                          // No Increment
        0                                           // Going Forward
    )

	addressRegisterByValue(
        1,                                          // Data Port 1
        VERA_PSG_VOICE00 + VERA_PSG_FREQHI_OFFSET,  // Use Voice one and point
                                                    // To Frequency Register low
        0,                                          // No Increment                        
        0                                           // Going Forward
    )

    lda VoiceFreq               // Effectively switches off the voice
    sta VERADATA0
    lda VoiceFreq + 1
    sta VERADATA1

    wai                         // Wait for next video frame

    jmp SimIRQ                  // Set up the effect again for a repeat run

VoiceFreqFrac: .byte 0         // Fraction
VoiceFreq:  .word $0
VoiceFreqStepperFrac: .byte 0   // Fraction
VoiceFreqStepper: .word $0
VoiceFreqThreshold: .word $0


SetUpFloater:
{
    // Reset Frequency Fraction
    stz VoiceFreqFrac
    // Load State Note Value
    // and Store in Voice Frequency
    lda #<VERA_PSG_NOTE_D1          
    sta VoiceFreq                   
    lda #>VERA_PSG_NOTE_D1
    sta VoiceFreq + 1

    // Load Voice Frequency Stepper
    // Store it away for the routine to use
    lda #$90
    sta VoiceFreqStepperFrac
    lda #$02
    sta VoiceFreqStepper
    stz VoiceFreqStepper + 1

// Load the Note Threshold, this determines
// when to step the sound effect
    lda #<VERA_PSG_NOTE_D0          
    sta VoiceFreqThreshold
    lda #>VERA_PSG_NOTE_D0
    sta VoiceFreqThreshold + 1
    rts
}

SetUpSwoopers:
{
    // Reset Frequency Fraction
    stz VoiceFreqFrac
    // Load State Note Value
    // and Store in Voice Frequency
    lda #<VERA_PSG_NOTE_ASharp5
    sta VoiceFreq
    lda #>VERA_PSG_NOTE_ASharp5
    sta VoiceFreq + 1

    // Load Voice Frequency Stepper
    // Store it away for the routine to use
    lda #$00
    sta VoiceFreqStepperFrac
    lda #$A2
    sta VoiceFreqStepper
    stz VoiceFreqStepper + 1

// Load the Note Threshold, this determines
// when to step the sound effect
    lda #<VERA_PSG_NOTE_CSharp4
    sta VoiceFreqThreshold
    lda #>VERA_PSG_NOTE_CSharp4
    sta VoiceFreqThreshold + 1
    rts
}

SetUpBuzzerDive:
{
    // Reset Frequency Fraction
    stz VoiceFreqFrac
    // Load State Note Value
    // and Store in Voice Frequency
    lda #<VERA_PSG_NOTE_ASharp4
    sta VoiceFreq
    lda #>VERA_PSG_NOTE_ASharp4
    sta VoiceFreq + 1

    // Load Voice Frequency Stepper
    // Store it away for the routine to use
    lda #$00
    sta VoiceFreqStepperFrac
    lda #$21
    sta VoiceFreqStepper
    stz VoiceFreqStepper + 1

// Load the Note Threshold, this determines
// when to step the sound effect
    lda #<VERA_PSG_NOTE_C2
    sta VoiceFreqThreshold
    lda #>VERA_PSG_NOTE_C2
    sta VoiceFreqThreshold + 1
    rts
}

SetUpPods:
{
    // Reset Frequency Fraction
    stz VoiceFreqFrac
    // Load State Note Value
    // and Store in Voice Frequency
    lda #<VERA_PSG_NOTE_G3
    sta VoiceFreq
    lda #>VERA_PSG_NOTE_G3
    sta VoiceFreq + 1

    // Load Voice Frequency Stepper
    // Store it away for the routine to use
    lda #$00
    sta VoiceFreqStepperFrac
    lda #$39
    sta VoiceFreqStepper
    stz VoiceFreqStepper + 1

// Load the Note Threshold, this determines
// when to step the sound effect
    lda #<VERA_PSG_NOTE_A2
    sta VoiceFreqThreshold
    lda #>VERA_PSG_NOTE_A2
    sta VoiceFreqThreshold + 1
    rts
}

SetUpExplosion:
{
    // Reset Frequency Fraction
    stz VoiceFreqFrac
    // Load State Note Value
    // and Store in Voice Frequency
    lda #<VERA_PSG_NOTE_ASharp3
    sta VoiceFreq
    lda #>VERA_PSG_NOTE_ASharp3
    sta VoiceFreq + 1

    // Load Voice Frequency Stepper
    // Store it away for the routine to use
    lda #$00
    sta VoiceFreqStepperFrac
    lda #$10
    sta VoiceFreqStepper
    stz VoiceFreqStepper + 1

// Load the Note Threshold, this determines
// when to step the sound effect
    lda #<VERA_PSG_NOTE_CSharp1
    sta VoiceFreqThreshold
    lda #>VERA_PSG_NOTE_CSharp1
    sta VoiceFreqThreshold + 1
    rts
}

SetUpBullet:
{
    // Reset Frequency Fraction
    stz VoiceFreqFrac
    // Load State Note Value
    // and Store in Voice Frequency
    lda #<VERA_PSG_NOTE_ASharp4
    sta VoiceFreq
    lda #>VERA_PSG_NOTE_ASharp4
    sta VoiceFreq + 1

    // Load Voice Frequency Stepper
    // Store it away for the routine to use
    lda #$00
    sta VoiceFreqStepperFrac
    lda #$36
    sta VoiceFreqStepper
    stz VoiceFreqStepper + 1

// Load the Note Threshold, this determines
// when to step the sound effect
    lda #<VERA_PSG_NOTE_CSharp3
    sta VoiceFreqThreshold
    lda #>VERA_PSG_NOTE_CSharp3
    sta VoiceFreqThreshold + 1
    rts
}