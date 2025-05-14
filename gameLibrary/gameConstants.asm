.cpu _65c02
#importonce

.const maxElements      = 64                // Max Number of Sprites On Screen
.const accelerationFrac = 32                // Acceleration Constant
.const gravitaionaccelerationFrac = 16      // Gravity Acceleration Constant
.const friction         = 32                // Friction Constant

.const collideWithPlatform  = %0001         // Collision Masks
.const collideWithEnemies   = %0010
.const collideWithPowerUps  = %0100

.const playerStoodStillSprNo = 0            // Sprite Frame Player Stood Still
.const playerWalkingSprNo   = 2             // Sprite Frame Player Walking
.const landscapeSingle      = 4             // Sprite Frame for Single Platform
.const landscapeMultiStart  = 5             // Sprite Frame for Platform Start
.const landscapeMultiMiddle = 6             // Sprite Frame for Platform Middle
.const landscapeMultiEnd    = 7             // Sprite Frame for Platform End
.const scoreNumberZero      = 8             // Sprite Frame for Score Digit 'Zero'

.const soundFxOff           = 0
.const soundFxJump          = 1
.const soundFxLand          = 2 + 128
.const soundFxFalling       = 3 + 128