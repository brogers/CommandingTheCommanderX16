.cpu _65c02

#importonce

#import "gameConstants.asm"
#import "gameElements.asm"

.namespace Sprites {

    SpriteIndex:    .byte 0

    DisplaySprites:
    {
        ldx #0
    !Looper:
        lda SpriteArray.Type,x
        cmp #ElementTypes.Empty
        bne !Found+

        stx SpriteIndex
        disableSpriteInVera(SpriteIndex)
    !NextOnePlease:
        inx
        cpx #maxElements
        bne !Looper-
        rts

    !Found:
        stx SpriteIndex

        jsr Elements.Load
        setUpSpriteInVeraWithColByAddr(
            SpriteIndex, 
            CurrentElement.SpriteFrameAddr, 
            SPRITE_MODE_16_COLOUR, 
            CurrentElement.X, 
            CurrentElement.Y, 
            SPRITE_ZDEPTH_AFTERLAYER1, 
            SPRITE_HEIGHT_16PX, 
            SPRITE_WIDTH_16PX, 
            0,
            CurrentElement.CollisionMask)

        ldx SpriteIndex
        bra !NextOnePlease-
    }
}
