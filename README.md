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

Open the workspace (`VSCode.X16.code-workspace`) in VSCode. Run **Terminal: Run Build Task** (`Ctrl+Shift+B`) or run the **Launch Emulator** task via `Ctrl+Shift+P` -> **Tasks: Run Task**. The **Launch Emulator** task depends on **Assemble Source**, so it assembles the active lesson source and then launches the emulator.

For a quick shortcut, add this to your [`keybindings.json`](https://code.visualstudio.com/docs/getstarted/keybindings#_advanced-customization) (`Ctrl+Shift+P` → "Open Keyboard Shortcuts (JSON)"):

```json
{
  "key": "ctrl+shift+r",
  "mac": "cmd+shift+r",
  "command": "workbench.action.tasks.runTask",
  "args": "Launch Emulator"
}
```

The **Assemble Source** task invokes KickAssembler directly:

```
java -cp Tools/Kick/KickAss_5.25.jar kickass.KickAssembler ${fileBasenameNoExtension}.asm -libdir Libraries -libdir Macros -libdir gameLibrary -libdir Assets -odir bin -o bin/Program.prg
```

## Import Paths

Top-level lesson source files use bare filenames for shared imports (e.g. `#import "constants.asm"`).

The assembler resolves them via `-libdir` flags passed in `tasks.json`. The VSCode extension resolves them via `kickassembler.assemblerLibraryPaths` in `VSCode.X16.code-workspace` — this is what enables F12 Go to Definition across library files.

Library files may still use relative imports internally when that is clearer, such as `Macros/macro.asm` importing `../Libraries/constants.asm`.

Both must list the same directories: `Libraries`, `Macros`, `gameLibrary`, `Assets`.
