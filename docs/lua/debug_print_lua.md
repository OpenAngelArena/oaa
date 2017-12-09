# Debug Print Lua

Updated 2017-12-05

[< Lua][0]

This is documentation for the debug printing system found in `game/scripts/vscripts/internal/util.lua`.

# Usage
- `DebugPrint` can be used pretty much the same way as normal Lua `print`.
- `DebugPrintTable` is used for printing all keys in a given table. Does not expand nested tables.
Keep in mind that files must be explicitly whitelisted to enable usage of `DebugPrint` and `DebugPrintTable`. The process for whitelisting files is explained just below.

## Enabling Printing
By default, files won't be allowed to print debug information using `DebugPrint` and `DebugPrintTable`. Printing can be enabled by setting keys in the `Debug.EnabledModules` table to true.
- The keys are strings of the filepaths to enable printing for, with : as the file separator.
- \* can be used as the wildcard symbol, which will enable printing for all files in a folder and its subfolders.
- `game/scripts/vscripts` and `game/scripts/vscripts/components` are both considered as root directories.

So for example, to enable printing for the file `game/scripts/vscripts/components/abilities/level.lua`, you would write `Debug.EnabledModules['abilities:level'] = true` into `level.lua`, or alternatively, you could enable printing for the whole abilities folder: `Debug.EnabledModules['abilities:*'] = true` (this also enables printing for files in `game/scripts/vscripts/abilities`).

# Additional Debug Info
`DebugPrint` and `DebugPrintTable` automatically prepend the filepath and line number where they are called to assist in debugging.

[0]: README.md
