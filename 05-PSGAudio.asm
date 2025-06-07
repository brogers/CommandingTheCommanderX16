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

    // Select your waveform
    lda #VERA_PSG_WAVEFORM_PULSE | $1F
    //lda #VERA_PSG_WAVEFORM_TRI | $00
    //lda #VERA_PSG_WAVEFORM_SAW | $00
    //lda #VERA_PSG_WAVEFORM_NOISE | $00
    sta VERADATA0

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

    lda #<VERA_PSG_NOTE_C2      // Load Note C in Octave 2
    sta VERADATA0               // Store Voice 1 Frequency Lo Register

    lda #>VERA_PSG_NOTE_C2      // Load Note C in Octave 2
    sta VERADATA1               // Store Voice 1 Frequency Hi Register

    jmp *                   // stop execution