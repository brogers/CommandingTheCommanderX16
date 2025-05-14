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

    SetUpPSGVoice(
        0,                          // Voice Number to Set Up
        VERA_PSG_MAX_VOLUME,        // What Volume to set at
        VERA_PSG_WAVEFORM_PULSE     // Wave Form to use
    )

    ldx #$00
Looper:

    lda NotesTwinkleTwinkleLo,x // Load current Frequency Lo
    sta CurrentNote
    lda NotesTwinkleTwinkleHi,x // Load current Frequency Hi
    sta CurrentNote + 1

    // Play this current Note on Voice 0
    PlayNote(
        0,                      // Voice 0 Selected
        CurrentNote             // The Note To Play
    )    

    lda NotesDelay,x            // Load the delay for the note
    sta Delay                   // Apply it

    ldy #0                      // Initialise Y
FrameDelayLooper:
    wai                         // Wait a Video Frame
    iny                         // increase Y by One
    cpy Delay:#30               // have we hit the delay
    bne FrameDelayLooper        // No, loop back round till we do

    stz CurrentNote
    stz CurrentNote + 1
    PlayNote(
        0,                      // Voice 0 Selected
        CurrentNote             // The Note To Play
    )    

    wai                         // Wait two more frames for an 
    wai                         // audible silence

    inx                         // increase X by one
    cpx #NoOfNotes              // have we hit the totaL Notes
    bne Looper                  // No, then go back and get the next note

    StopPSGVoice(0)             // Turn off Voice

    jmp *                       // continue looping

Voice0: .word $0
CurrentNote: .word $0

// This is the delay data for each note
NotesDelay:
    .byte 30,30,30,30,30,30,60
    .byte 30,30,30,30,30,30,60
    .byte 30,30,30,30,30,30,60

NotesTwinkleTwinkleLo:
    .byte <VERA_PSG_NOTE_C4
    .byte <VERA_PSG_NOTE_C4
    .byte <VERA_PSG_NOTE_G4
    .byte <VERA_PSG_NOTE_G4
    .byte <VERA_PSG_NOTE_A4
    .byte <VERA_PSG_NOTE_A4
    .byte <VERA_PSG_NOTE_G4
    .byte <VERA_PSG_NOTE_F4
    .byte <VERA_PSG_NOTE_F4
    .byte <VERA_PSG_NOTE_E4
    .byte <VERA_PSG_NOTE_E4
    .byte <VERA_PSG_NOTE_D4
    .byte <VERA_PSG_NOTE_D4
    .byte <VERA_PSG_NOTE_C4
    .byte <VERA_PSG_NOTE_G4
    .byte <VERA_PSG_NOTE_G4
    .byte <VERA_PSG_NOTE_F4
    .byte <VERA_PSG_NOTE_F4
    .byte <VERA_PSG_NOTE_E4
    .byte <VERA_PSG_NOTE_E4
    .byte <VERA_PSG_NOTE_D4

NotesTwinkleTwinkleHi:
    .byte >VERA_PSG_NOTE_C4
    .byte >VERA_PSG_NOTE_C4
    .byte >VERA_PSG_NOTE_G4
    .byte >VERA_PSG_NOTE_G4
    .byte >VERA_PSG_NOTE_A4
    .byte >VERA_PSG_NOTE_A4
    .byte >VERA_PSG_NOTE_G4
    .byte >VERA_PSG_NOTE_F4
    .byte >VERA_PSG_NOTE_F4
    .byte >VERA_PSG_NOTE_E4
    .byte >VERA_PSG_NOTE_E4
    .byte >VERA_PSG_NOTE_D4
    .byte >VERA_PSG_NOTE_D4
    .byte >VERA_PSG_NOTE_C4
    .byte >VERA_PSG_NOTE_G4
    .byte >VERA_PSG_NOTE_G4
    .byte >VERA_PSG_NOTE_F4
    .byte >VERA_PSG_NOTE_F4
    .byte >VERA_PSG_NOTE_E4
    .byte >VERA_PSG_NOTE_E4
    .byte >VERA_PSG_NOTE_D4

.label NoOfNotes = 21
