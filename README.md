# Roblox-SetClipboard

A Luau module that copies text to the user's clipboard by emulating real user interactions through the `UserInputService:CreateVirtualInput()` API.

## How it works

The module creates a hidden `TextBox`, fills it with your text, selects it, and simulates the `Ctrl + C` hotkey using a virtual keyboard and mouse.

### Bypassing the TextBox character limit

`TextBox.Text` has a character limit, so assigning very large strings directly doesn't work. When the text exceeds the limit, the module writes it manually through `VirtualInput:SendTextInput()` instead. This works because `MaxVisibleGraphemes` is effectively infinite, so the box accepts input beyond the normal limit.

## Usage

```lua
local setClipboard = require(path.to.setClipboard)

setClipboard("Hello, clipboard!")
```

The call yields until the copy process has finished.

## Notes

- PC only. A keyboard is required, otherwise the copy will fail.
- Set `DEBUG_MODE = true` to make the container GUI visible and print timing and selection info.

## Disclosure

This has been reported to Roblox.
