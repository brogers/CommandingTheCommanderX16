.cpu _65c02
#import "Libraries/constants.asm"
#import "Libraries/petscii.asm"
#import "Macros/macro.asm"

BasicUpstart2(Main)

Main:
    addressRegisterByValue(
        DATA_PORT0,         // Set to DATA0
        $1B000,              // The Address we want to start at
        ADDRESS_STEP_1,     // Every Byte
        ADDRESS_DIR_FORWARD // Going forwards
    )
    
    ldx #0              // the X register will keep track of the rows
OuterLooper:
    ldy #0              // the Y register will keep track of the columns
Looper:
    tya                 // transfer column number to Accumuator
    and #%0000001       // is it an Odd Number
    beq DontChangeColourYet // No, then just store the colour
    lda Colour          // Yes, Load current colour value
    inc Colour          // increase Colour Value in memory
    bra StoreInDATA0    // Jump to Store

DontChangeColourYet:
    tya                 // Transfer column Number to Accumulator
    and #%00011111      // have we hit 31
    bne DontChangeCharacterYet  // No, then dont change the character
    inc Character       // Yes, increase the character value by 1
    
DontChangeCharacterYet:
    lda Character       // load character value

StoreInDATA0:
    sta VERADATA0       // Store either the colour or the character

NextLine:
    dey                 // increase pointer by 1
    bne Looper          // loop back round

    inx                 // Increase the row counter
    cpx #60             // have we hit the 60th Row
    bne OuterLooper     // No, loop back round then

Exit:
    jmp *               // stop execution

Colour:     .byte 0
Character:  .byte 0
