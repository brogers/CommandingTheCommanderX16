.cpu _65c02
#import "Libraries/constants.asm"
#import "Libraries/petscii.asm"
#import "Macros/macro.asm"

BasicUpstart2(Main)

Main:
    // this macro copies memory from the Commander X16
    // to the vera chip.
    copyDataToVera(
        Characters,         // Source Address, thats where 
                            // the Characters are located
        VRAM_petscii,       // Destination Address, where we 
                            // want to put the characters
        (255*8)             // Number of bytes to copy
    )
    jmp *               // stop execution

Characters:
#import "Assets/data.asm"
//#import "Assets/gothic.asm"
_Characters:
