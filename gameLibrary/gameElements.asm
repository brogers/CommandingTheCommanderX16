.cpu _65c02
#importonce
#import "gameConstants.asm"

.align $100
// world x/y 0-7ff,0-bf (2047,192) 
//sprite table for maxElements entries. 12 bytes/sprite
SpriteArray:
{
    Type: .fill maxElements, 0 
    Frame: .fill maxElements,0  // .byte 0        // $ff = Disable sprite
    FrameCounter: .fill maxElements,0 //.byte 0
    XFrac: .fill maxElements,0  //.byte 0  - world position
    X: .fill maxElements,0      //.byte 0  - world position
    XHi: .fill maxElements,0    //.byte 0 - world position
    YFrac: .fill maxElements,0  //.byte 0  - world position
    Y: .fill maxElements,0      //.byte 0 - world position
    YHi: .fill maxElements, 0

    Spare: .fill maxElements,0  //
    Velocity:
    {
        XFrac: .fill maxElements,0  //
        X: .fill maxElements,0      //
        YFrac: .fill maxElements,0  //
        Y: .fill maxElements,0      //
    } 
    Acceleration:
    {
        XFrac: .fill maxElements,0  //
        X: .fill maxElements,0      //
        YFrac: .fill maxElements,0  //
        Y: .fill maxElements,0      //
    } 
    Direction:
    {
        X: .fill maxElements,0  //
        Y: .fill maxElements,0  //
    } 
    SpriteFrameAddr:    .fill maxElements*2,0   //
    CollisionMask:  .fill maxElements, 0        //
    // --------------------------
}

CurrentElement:{
    Type: .byte 0
    Frame: .byte 0
    FrameCounter: .byte 0
    XFrac: .byte 0
    X: .byte 0
    XHi: .byte 0
    YFrac: .byte 0
    Y: .byte 0
    YHi: .byte 0

    Spare: .byte 0

    Velocity:
    {
        XFrac: .byte 0
        X: .byte 0
        YFrac: .byte 0
        Y: .byte 0
    } 
    Acceleration:
    {
        XFrac: .byte 0
        X: .byte 0
        YFrac: .byte 0
        Y: .byte 0
    } 
    Direction:
    {
        X: .byte 0
        Y: .byte 0
    } 
    SpriteFrameAddr: .word $0000
    CollisionMask:  .byte 0
    // --------------------------
}
_CurrentElement:

TempElement:{
    .fill (_CurrentElement - CurrentElement), 0
}

ElementTypes:
{
    .label Player   = 1
    .label Platform = 2
    .label Score    = 3
    .label Lives    = 4
    .label Empty    = 255
}

.namespace Elements {

    InsertedIndex:  .byte 0
    CurrentIndex:   .byte 0
    BackedUpIndex:  .byte 0

    Initialise:
    {
        ldx #maxElements
    !Looper:
        lda #ElementTypes.Empty
        sta SpriteArray.Type,x
        lda #$FF
        sta SpriteArray.Frame,x
        stz SpriteArray.FrameCounter,x
        dex
        cpx #$FF
        bne !Looper-
        rts
    }

    FindAFreeSlot:
    {
        // Outputs  : X Reg = Empty Slot
        //          : Carry Set = Found, Carry Clear = Full
        ldx #0              // 0 = Player, 1 = Flame
    !Looper:
        lda SpriteArray.Type,x
        cmp #ElementTypes.Empty
        beq !FoundEmpty+

        inx
        cpx #maxElements + 1
        bne !Looper-
        clc
        skip1Byte()
    !FoundEmpty:
        sec
        rts
    }

    Add:
    {
        // Inputs   : Current Element Area
        jsr FindAFreeSlot
        bcc !Exit+
        jsr Save

    !Exit:
        rts
    }

    Save:
    {
        // Inputs   : X Reg, index to store Element

        lda CurrentElement.Type
        sta SpriteArray.Type,x
        lda CurrentElement.Frame
        sta SpriteArray.Frame,x
        lda CurrentElement.FrameCounter
        sta SpriteArray.FrameCounter,x
        lda CurrentElement.XFrac
        sta SpriteArray.XFrac,x
        lda CurrentElement.X
        sta SpriteArray.X,x
        lda CurrentElement.XHi
        sta SpriteArray.XHi,x
        lda CurrentElement.YFrac
        sta SpriteArray.YFrac,x
        lda CurrentElement.Y
        sta SpriteArray.Y,x
        lda CurrentElement.YHi
        sta SpriteArray.YHi,x

        lda CurrentElement.Spare
        sta SpriteArray.Spare,x

        lda CurrentElement.Velocity.XFrac
        sta SpriteArray.Velocity.XFrac,x
        lda CurrentElement.Velocity.X
        sta SpriteArray.Velocity.X,x
        lda CurrentElement.Velocity.YFrac
        sta SpriteArray.Velocity.YFrac,x
        lda CurrentElement.Velocity.Y
        sta SpriteArray.Velocity.Y,x

        lda CurrentElement.Acceleration.XFrac
        sta SpriteArray.Acceleration.XFrac,x
        lda CurrentElement.Acceleration.X
        sta SpriteArray.Acceleration.X,x
        lda CurrentElement.Acceleration.YFrac
        sta SpriteArray.Acceleration.YFrac,x
        lda CurrentElement.Acceleration.Y
        sta SpriteArray.Acceleration.Y,x

        lda CurrentElement.Direction.X
        sta SpriteArray.Direction.X,x
        lda CurrentElement.Direction.Y
        sta SpriteArray.Direction.Y,x

        lda CurrentElement.SpriteFrameAddr
        sta SpriteArray.SpriteFrameAddr,x

        lda CurrentElement.CollisionMask
        sta SpriteArray.CollisionMask,x

        rts
    }

    Load:
    {
        // Inputs   : X Reg, index to store Element

        lda SpriteArray.Type,x
        sta CurrentElement.Type
        lda SpriteArray.Frame,x
        sta CurrentElement.Frame
        lda SpriteArray.FrameCounter,x
        sta CurrentElement.FrameCounter
        lda SpriteArray.XFrac,x
        sta CurrentElement.XFrac
        lda SpriteArray.X,x
        sta CurrentElement.X
        lda SpriteArray.XHi,x
        sta CurrentElement.XHi
        lda SpriteArray.YFrac,x
        sta CurrentElement.YFrac
        lda SpriteArray.Y,x
        sta CurrentElement.Y
        lda SpriteArray.YHi,x
        sta CurrentElement.YHi

        lda SpriteArray.Spare,x
        sta CurrentElement.Spare

        lda SpriteArray.Velocity.XFrac,x
        sta CurrentElement.Velocity.XFrac
        lda SpriteArray.Velocity.X,x
        sta CurrentElement.Velocity.X
        lda SpriteArray.Velocity.YFrac,x
        sta CurrentElement.Velocity.YFrac
        lda SpriteArray.Velocity.Y,x
        sta CurrentElement.Velocity.Y

        lda SpriteArray.Acceleration.XFrac,x
        sta CurrentElement.Acceleration.XFrac
        lda SpriteArray.Acceleration.X,x
        sta CurrentElement.Acceleration.X
        lda SpriteArray.Acceleration.YFrac,x
        sta CurrentElement.Acceleration.YFrac
        lda SpriteArray.Acceleration.Y,x
        sta CurrentElement.Acceleration.Y

        lda SpriteArray.Direction.X,x
        sta CurrentElement.Direction.X
        lda SpriteArray.Direction.Y,x
        sta CurrentElement.Direction.Y

        lda SpriteArray.SpriteFrameAddr,x
        sta CurrentElement.SpriteFrameAddr

        lda SpriteArray.CollisionMask,x
        sta CurrentElement.CollisionMask

        rts
    }

    Delete:
    {
        // Inputs   : X Reg, index to store Element
        jsr Clear
        lda #ElementTypes.Empty
        sta CurrentElement.Type
        jsr Save
        rts
    }

    Clear:  // does not clear type!
    {
        //stz CurrentElement.Type
        lda #$ff
        sta CurrentElement.Frame

        stz CurrentElement.FrameCounter
        stz CurrentElement.XFrac
        stz CurrentElement.X
        stz CurrentElement.XHi
        stz CurrentElement.YFrac
        stz CurrentElement.Y
        stz CurrentElement.YHi

        stz CurrentElement.Spare

        stz CurrentElement.Velocity.XFrac
        stz CurrentElement.Velocity.X
        stz CurrentElement.Velocity.YFrac
        stz CurrentElement.Velocity.Y

        stz CurrentElement.Acceleration.XFrac
        stz CurrentElement.Acceleration.X
        stz CurrentElement.Acceleration.YFrac
        stz CurrentElement.Acceleration.Y

        stz CurrentElement.Direction.X
        stz CurrentElement.Direction.Y

        stz CurrentElement.SpriteFrameAddr
        stz CurrentElement.SpriteFrameAddr + 1
        rts
    }

    BackUp:
    {
        phy

        ldy #0
    !Loop:
        lda CurrentElement,y
        sta TempElement,y
        iny
        cpy #(_CurrentElement - CurrentElement)
        bne !Loop-

        ply
        rts
    }

    Restore:
    {
        phy

        ldy #0
    !Loop:
        lda TempElement,y
        sta CurrentElement,y
        iny
        cpy #(_CurrentElement - CurrentElement)
        bne !Loop-

        ply
        rts
    }

    FindType:
    {
        // Inputs   : Acc = Type To Find
        // Outputs  : X Reg = Slot
        //          : Carry Set = Found, Carry Clear = Not Found
        stz ElementIndex
        sta TypeToFind
    FindNext:
        ldx ElementIndex
    !Looper:
        lda SpriteArray.Type,x
        cmp TypeToFind: #$FF
        beq !FoundType+

        inx
        cpx #maxElements + 1
        bne !Looper-
        stz ElementIndex
        clc
        rts
    !FoundType:
        stx ElementIndex
        sec
        rts
    }

    ElementIndex: .byte 0
    ElementCollisonIndex: .byte 0

    FindNextType:
    {
        inc ElementIndex
        jsr FindType.FindNext
        rts
    }

    Execute:
    {
        // Outputs  : 
        //          : 
        ldx #0
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
        stx ElementIndex
        lda SpriteArray.Type,x
        tax
        dex

        lda ExecutionJumpTableLo,x
        sta GoSubJumpLocation
        lda ExecutionJumpTableHi,x
        sta GoSubJumpLocation + 1

        ldx ElementIndex
        jsr Load

        jsr ExecuteElementType

        ldx ElementIndex
        jsr Save

        ldx ElementIndex
        bra !NextOnePlease-
    }

    NotMovingThisType:
    {
        rts
    }

    ExecuteElementType:
    {
        jmp (GoSubJumpLocation)
    }

    GoSubJumpLocation: .word $C0DE

    ExecutionJumpTableLo:
        .byte <Player.Execute
#if Step01
        .byte <Platform.Execute
#endif
#if Step08
        .byte <Score.Execute
        .byte <Lives.Execute
#endif
        .byte <NotMovingThisType

    ExecutionJumpTableHi:
        .byte >Player.Execute
#if Step01
        .byte >Platform.Execute
#endif
#if Step08
        .byte >Score.Execute
        .byte >Lives.Execute
#endif
        .byte >NotMovingThisType

    IsCurrentElementOnScreen:
    {
        lda CurrentElement.YHi
        cmp #$00
        bmi isOnScreen
        lda CurrentElement.Y
        cmp #$F0
        bcs notOnScreen

    isOnScreen:
        sec
        skip1Byte()

    notOnScreen:
        clc
        rts
    }

    IsElementOnScreen:
    {
        phy
        lda SpriteArray.YHi,x
        cmp #$00
        bmi isOnScreen
        lda SpriteArray.Y,x
        cmp #$F0
        bcs notOnScreen

    isOnScreen:
        sec
        skip1Byte()

    notOnScreen:
        clc
        ply
        rts
    }

    ApplyAccelerationXToVelocityForCurrent:
    {
        lda CurrentElement.Direction.X
        beq !Exit+
        bmi !GoingLeft+

        clc
        lda CurrentElement.Velocity.XFrac
        adc CurrentElement.Acceleration.XFrac
        sta CurrentElement.Velocity.XFrac

        lda CurrentElement.Velocity.X
        adc CurrentElement.Acceleration.X
        sta CurrentElement.Velocity.X
        bra !Exit+

    !GoingLeft:
        sec
        lda CurrentElement.Velocity.XFrac
        sbc CurrentElement.Acceleration.XFrac
        sta CurrentElement.Velocity.XFrac

        lda CurrentElement.Velocity.X
        sbc CurrentElement.Acceleration.X
        sta CurrentElement.Velocity.X

    !Exit:
        rts
    }

    ApplyFrictionXToVelocityForCurrent:
    {
        // if Velocity is Zero, dont apply friction
        lda CurrentElement.Velocity.XFrac
        ora CurrentElement.Velocity.X
        beq !Exit+

        lda CurrentElement.Velocity.X
        bmi !GoingLeft+

        sec
        lda CurrentElement.Velocity.XFrac
        sbc #friction
        sta CurrentElement.Velocity.XFrac

        lda CurrentElement.Velocity.X
        sbc #0
        sta CurrentElement.Velocity.X

        bra !Exit+

    !GoingLeft:
        clc
        lda CurrentElement.Velocity.XFrac
        adc #friction
        sta CurrentElement.Velocity.XFrac

        lda CurrentElement.Velocity.X
        adc #0
        sta CurrentElement.Velocity.X

    !Exit:
        rts
    }

    ApplyAccelerationYToVelocityForCurrent:
    {
        lda CurrentElement.Direction.Y
        beq !Exit+
        bmi !GoingUp+

    ApplyGravity:
        clc
        lda CurrentElement.Velocity.YFrac
        adc CurrentElement.Acceleration.YFrac
        sta CurrentElement.Velocity.YFrac

        lda CurrentElement.Velocity.Y
        adc CurrentElement.Acceleration.Y
        sta CurrentElement.Velocity.Y
        bra !Exit+

    !GoingUp:
        sec
        lda CurrentElement.Velocity.YFrac
        sbc CurrentElement.Acceleration.YFrac
        sta CurrentElement.Velocity.YFrac

        lda CurrentElement.Velocity.Y
        sbc CurrentElement.Acceleration.Y
        sta CurrentElement.Velocity.Y

    !Exit:
        rts
    }

    ApplyVelocityToXForCurrent:
    {
        lda CurrentElement.Velocity.X
        bmi !GoingLeft+

        clc
        lda CurrentElement.XFrac
        adc CurrentElement.Velocity.XFrac
        sta CurrentElement.XFrac

        lda CurrentElement.X
        adc CurrentElement.Velocity.X
        sta CurrentElement.X
        
        bcc !Exit+
        inc CurrentElement.XHi
        lda CurrentElement.XHi
        sta CurrentElement.XHi

        bra !Exit+

    !GoingLeft:
        lda CurrentElement.Velocity.XFrac
        eor #$FF
        sta VelocityFrac

        lda CurrentElement.Velocity.X
        eor #$FF
        sta Velocity

        inc VelocityFrac
        bne !ByPass+
        inc Velocity
    !ByPass:

        sec
        lda CurrentElement.XFrac
        sbc VelocityFrac: #$FF
        sta CurrentElement.XFrac

        lda CurrentElement.X
        sbc Velocity: #$FF
        sta CurrentElement.X

        bcs !Exit+
        dec CurrentElement.XHi
        lda CurrentElement.XHi
        sta CurrentElement.XHi

    !Exit:
        rts
    }

    ApplyVelocityToYForCurrent:
    {
        lda CurrentElement.Velocity.Y
        bmi !GoingUp+

        clc
        lda CurrentElement.YFrac
        adc CurrentElement.Velocity.YFrac
        sta CurrentElement.YFrac

        lda CurrentElement.Y
        adc CurrentElement.Velocity.Y
        sta CurrentElement.Y

        bcc !Exit+
        inc CurrentElement.YHi
        lda CurrentElement.YHi
        and #%00000111
        sta CurrentElement.YHi

        bra !Exit+

    !GoingUp:
        lda CurrentElement.Velocity.YFrac
        eor #$FF
        sta VelocityFrac

        lda CurrentElement.Velocity.Y
        eor #$FF
        sta Velocity

        inc VelocityFrac
        bne !ByPass+
        inc Velocity
    !ByPass:

        sec
        lda CurrentElement.YFrac
        sbc VelocityFrac: #$FF
        sta CurrentElement.YFrac

        lda CurrentElement.Y
        sbc Velocity: #$FF
        sta CurrentElement.Y

        bcs !Exit+
        dec CurrentElement.YHi
        lda CurrentElement.YHi
        and #%00000111
        sta CurrentElement.YHi

    !Exit:
        rts
    }
}
