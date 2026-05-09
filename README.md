# Commanding the Commander X16

KickAssembler examples for the Commander X16, following the OldSkoolCoder tutorial series.

## Project Structure

```
.
├── Assets/          sprite and tile data
├── gameLibrary/     game-specific modules
├── Libraries/       shared constants, VERA, PETSCII, controls
├── Macros/          assembler macros
├── Tools/           KickAssembler JAR and X16 emulator binaries
├── bin/             assembler output (generated)
└── *.asm            lesson source files
```

## Building

Open the workspace (`VSCode.X16.code-workspace`) in VSCode and press `F5` to assemble and launch the emulator.

The build task invokes KickAssembler directly:

```
java -cp Tools/Kick/KickAss_5.25.jar kickass.KickAssembler <file>.asm -libdir Libraries -libdir Macros -libdir gameLibrary -libdir Assets -odir bin -o bin/Program.prg
```

## Import Paths

All `#import` statements use bare filenames (e.g. `#import "constants.asm"`).

The assembler resolves them via `-libdir` flags passed in `tasks.json`. The VSCode extension resolves them via `kickassembler.assemblerLibraryPaths` in `VSCode.X16.code-workspace` — this is what enables F12 Go to Definition across library files.

Both must list the same directories: `Libraries`, `Macros`, `gameLibrary`, `Assets`.
