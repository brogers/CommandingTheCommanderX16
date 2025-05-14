.cpu _65c02
// play a boing?


* = $22 "zeropage" virtual
playstatus: .byte 0
playaddress: .word boing
playlength: .word _boing-boing

.macro break(){         
    .byte $db
}

* = $0801

//$9F3B	AUDIO_CTRL	FIFO Full / FIFO Reset(1)	FIFO Empty (read-only)(1)	16-Bit(1)	Stereo(1)	PCM Volume FIFO Loop (write-only)(4)
//$9F3C	AUDIO_RATE	PCM Sample Rate
//$9F3D	AUDIO_DATA	Audio FIFO data (write-only)

BasicUpstart2(Start)
Start: 
lda #<boing
sta playaddress
lda #>boing
sta playaddress+1
lda #<(_boing-boing-1)
sta playlength
lda #>(_boing-boing-1)
sta playlength+1

lda #1
sta playstatus
lda #$0F
sta $9F3B
lda #27
sta $9F3C
loop:
lda playstatus
cmp #01
bne done
waitforspace:
lda $9F3B
and #$40
beq waitforspace
lda (playaddress)
sta $9F3D
lda playaddress
inc
sta playaddress
bne l1
inc playaddress+1
l1:
lda playlength
dec
sta playlength
cmp #$ff
bne l2
dec playlength+1
lda playlength+1
cmp #$ff
bne l2
dec playstatus
l2:
bra loop
done:
lda #0
sta $9F3C
rts

boing:
.import binary "springsound.raw"   // sound data
_boing:

