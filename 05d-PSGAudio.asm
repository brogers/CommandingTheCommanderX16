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

Looper:
    wai
    jsr IRQ_playTitleMusic
    jmp Looper


IRQ_playTitleMusic:{
    lda voiceM1Ptr
    tay
    asl
    tax  
    lda titleTune.Voice01+1,x         
    bpl decvoiceM1Time               // freq_hi < $80 so must be valid data
    inc finished                     //otherwise we hit end so set finished flag   
    jmp IRQ_playTitleMusicX       


decvoiceM1Time:
    addressRegisterByValue(0,VERAPSG14,1,0)
    dec voiceM1Time
    lda voiceM1Time
    beq setVoice1       // count is 0 so get next note
    cmp #$01            // check if count is 1, if so, turn vol off/end note
    bne doVoice2        // otherwise count is not 1 so go deal with voice 2 
    stz VERADATA0       //
    stz VERADATA0
    stz VERADATA0
    bra doVoice2

setVoice1:
    lda titleTune.Voice01,x         //freq low 
    sta VERADATA0
    lda titleTune.Voice01+1,x       //freq hi
    sta VERADATA0
    ora titleTune.Voice01,x 
    beq v1setVol                    //put 0 in vol if freqis 0
    lda #192 | VERA_PSG_MAX_VOLUME  //both channels, max vol
v1setVol:
    sta VERADATA0
    lda #$3f                // %10111111  triangle, 50% duty                
    sta VERADATA0
    lda titleTune.Voice01Time,y       
    sta voiceM1Time 
    inc voiceM1Ptr

doVoice2:
    addressRegisterByValue(0,VERAPSG15,1,0)
    dec voiceM2Time    
    lda voiceM2Time
    beq setVoice2               // timer = 0 , set next note
    cmp #$01
    bne IRQ_playTitleMusicX     // timer not 1 so do nothing
    stz VERADATA0
    stz VERADATA0
    stz VERADATA0               // set vol to 0 at count of 1 (end note)
    bra IRQ_playTitleMusicX

setVoice2:
    lda voiceM2Ptr
    tay
    asl
    tax
    lda titleTune.Voice02,x
    sta VERADATA0
    lda titleTune.Voice02+1,x         
    sta VERADATA0
    ora titleTune.Voice02,x 
    beq v2setVol                    //put 0 in vol if freqis 0
    lda #192 | VERA_PSG_MAX_VOLUME  // both channels, vol $3f max
v2setVol:
    sta VERADATA0
    lda #$bf                // %10111111  triangle, 50% duty   
    sta VERADATA0
    lda titleTune.Voice02Time,y     
    sta voiceM2Time    
    inc voiceM2Ptr

IRQ_playTitleMusicX:
    rts
}

voiceM1Ptr:      .byte 0    // voice M1 and M2 are used to play tune sequences
voiceM2Ptr:      .byte 0    // title music uses M1 and M2 on voices 14/15   
voiceM1Time:     .byte 0    // game music uses M1 on voice 14
voiceM2Time:     .byte 0

// voice 0-3  are available for sound effects
// populate top 9 bytes, playtime is last since this will then trigger playback
//              VOICE 0  1  2  3   
voiceFreqLo:    .byte 0, 0, 0, 0    
voiceFreqHi:    .byte 0, 0, 0, 0
voiceVol:       .byte 0, 0, 0, 0    // volume 0-3f
voiceShape:     .byte 0, 0, 0, 0    // bits 6/7 00 = pulse, 01 = saw, 02 = tri, 03 = noise. bits 0-5 = pulse width (3f = 50%)
voiceFreqStep:  .byte 0, 0, 0, 0    // +127 to -128
voiceStepTime:  .byte 0, 0, 0, 0    // ticks between frequency steps
voicedecay:     .byte 0, 0, 0, 0    // volume decay value
voicedecayTime: .byte 0, 0, 0, 0    // ticks between volume decay
voicePlayTime:  .byte 0, 0, 0, 0    // length of sound in game ticks 60 = 1second.  zero = inactive voice
voiceStepTick:  .byte 0, 0, 0, 0
voicedecayTick: .byte 0, 0, 0, 0

GameMusicOn:    .byte 0 // 0 = off, 1 = playing, 2 = Start, 3 = stop
SoundMode:      .byte 0 // 0 = off, 1 = title music, 2 = ingame sound+music, 128 = turn sounds off (stop all)
finished:       .byte 0
jumpHeight:     .byte 0
fallHeight:     .byte 0

titleTune:{

    .align $100
    Voice01: //hi,lo
    .word $0567
    .word $06CF
    .word $0819
    .word $0819
    .word $0000
    .word $1032
    .word $1032
    .word $0000
    .word $0D9F
    .word $0D9F
    .word $0000
    .word $0567
    .word $0567
    .word $06CF
    .word $0819
    .word $0819
    .word $0000
    .word $1032
    .word $1032
    .word $0000
    .word $0E6E
    .word $0E6E
    .word $0000
    .word $051A
    .word $051A
    .word $0611
    .word $0917
    .word $0917
    .word $0000
    .word $122E
    .word $122E
    .word $0000
    .word $0E6E
    .word $0E6E
    .word $0000
    .word $051A
    .word $051A
    .word $0611
    .word $0917
    .word $0917
    .word $0000
    .word $122E
    .word $122E
    .word $0000
    .word $0D9F
    .word $0D9F
    .word $0000
    .word $0567
    .word $0567
    .word $06CF
    .word $0819
    .word $0ACF
    .word $0000
    .word $159F
    .word $159F
    .word $0000
    .word $1032
    .word $1032
    .word $0000
    .word $0567
    .word $0567
    .word $06CF
    .word $0819
    .word $0ACF
    .word $0000
    .word $159F
    .word $159F
    .word $0000
    .word $122E
    .word $122E
    .word $0000
    .word $0611
    .word $0611
    .word $0737
    .word $0917
    .word $0917
    .word $0917
    .word $07A5
    .word $0819
    .word $0D9F
    .word $0D9F
    .word $0ACF
    .word $06CF
    .word $06CF
    .word $0737
    .word $0917
    .word $0819
    .word $0567
    .word $0567
    .word $0567
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $ffff

    .align $100
    Voice01Time:
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $2d 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $2d 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $1e 
    .byte $0f 
    .byte $1e 
    .byte $0f 
    .byte $16 
    .byte $08 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 

    .align $100
    Voice02:  //hi,lo
    .word $0000
    .word $0000
    .word $0000
    .word $0245
    .word $02B3
    .word $02B3
    .word $01B3
    .word $02B3
    .word $02B3
    .word $0245
    .word $02B3
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $028D
    .word $0308
    .word $0308
    .word $01B3
    .word $0308
    .word $0308
    .word $028D
    .word $0308
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $028D
    .word $0308
    .word $0308
    .word $01B3
    .word $0308
    .word $0308
    .word $028D
    .word $0308
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0245
    .word $02B3
    .word $02B3
    .word $01B3
    .word $02B3
    .word $02B3
    .word $0245
    .word $02B3
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $02B3
    .word $0367
    .word $0367
    .word $02B3
    .word $0367
    .word $0367
    .word $02B3
    .word $0367
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0308
    .word $039B
    .word $039B
    .word $0308
    .word $039B
    .word $039B
    .word $0308
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0367
    .word $040C
    .word $040C
    .word $0367
    .word $040C
    .word $040C
    .word $0245
    .word $02B3
    .word $02B3
    .word $0245
    .word $0000
    .word $0000
    .word $0308
    .word $0308
    .word $0245
    .word $0000
    .word $0245
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0000
    .word $0000

    .align $100
    Voice02Time:
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $2d 
    .byte $2d 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
    .byte $0f 
}

    gameTune:{
    .word $02BE
    .word $0314
    .word $0374
    .word $03A9
    .word $041C
    .word $0374
    .word $03A9
    .word $03A9
    .word $045A
    .word $03A9
    .word $045A
    .word $045A
    .word $041C
    .word $0374
    .word $041C
    .word $041C
    .word $02BE
    .word $0314
    .word $0374
    .word $03A9
    .word $041C
    .word $0374
    .word $03A9
    .word $03A9
    .word $045A
    .word $03A9
    .word $045A
    .word $045A
    .word $041C
    .word $041C
    .word $041C
    .word $041C
    .word $02BE
    .word $0314
    .word $0374
    .word $03A9
    .word $041C
    .word $0374
    .word $03A9
    .word $03A9
    .word $045A
    .word $03A9
    .word $045A
    .word $045A
    .word $041C
    .word $0374
    .word $041C
    .word $041C
    .word $02BE
    .word $0314
    .word $0374
    .word $03A9
    .word $041C
    .word $0374
    .word $041C
    .word $057C
    .word $041C
    .word $0374
    .word $02BE
    .word $0374
    .word $041C
    .word $041C
    .word $041C
    .word $041C
    .word $0000
    .word $ffff
}