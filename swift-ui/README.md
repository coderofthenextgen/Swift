# Swift UI

Custom Roblox UI Library — **PascalCase** — Dark Obsidian-inspired (but not a clone).

Single-file core `UI.lua` + separate `SaveManager.lua` / `ThemeManager.lua`.

## Features
- Draggable, resizable window with shadow + outline
- Toggle keybind (`RightShift` by default) to show/hide
- Tabs + Left/Right Groupboxes with auto-resize
- Full MVP controls: `Label`, `Divider`, `Button`, `Toggle`, `Slider`, `Dropdown` (single/multi), `Input`, `ColorPicker`, `KeyPicker`
- Notifications (`SwiftUI:Notify`)
- SaveManager (config JSON to `SwiftUI/` folder)
- ThemeManager (5 built-in themes + custom accent + save/load)

## Usage

```lua
local SwiftUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/swift-ui/UI.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/swift-ui/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/swift-ui/ThemeManager.lua"))()

SaveManager:SetLibrary(SwiftUI)
ThemeManager:SetLibrary(SwiftUI)

local Window = SwiftUI:CreateWindow({
    Title = "Swift UI",
    Footer = "v1.0",
    Size = UDim2.fromOffset(640, 540),
    ToggleKeybind = Enum.KeyCode.RightShift,
})

local Tab = Window:AddTab("Main", "★")
local Left = Tab:AddLeftGroupbox("Combat")
local Right = Tab:AddRightGroupbox("Visuals")

Left:AddToggle("AutoFarm", { Text = "Auto Farm", Default = false, Callback = function(V) print(V) end })
Left:AddSlider("Speed", { Text = "Speed", Min = 16, Max = 100, Default = 16, Callback = print })
Left:AddButton({ Text = "Execute", Func = function() print("clicked") end })

Right:AddDropdown("Weapon", { Text = "Weapon", Values = {"Sword","Gun"}, Default = "Sword", Callback = print })
Right:AddInput("Target", { Text = "Target", Placeholder = "Username...", Callback = print })
Right:AddColorPicker("ESPColor", { Text = "ESP Color", Default = Color3.fromRGB(124,92,255), Callback = print })
Right:AddKeyPicker("ToggleKey", { Text = "Toggle", Default = Enum.KeyCode.Q, Mode = "Toggle", Callback = print })

SaveManager:BuildConfigSection(Tab)
ThemeManager:BuildThemeSection(Tab)
```

See `Example.lua` for full demo.

## API (PascalCase)

- `SwiftUI:CreateWindow(Config)` -> `Window`
- `Window:AddTab(Name, Icon)` -> `Tab`
- `Tab:AddLeftGroupbox(Name)` / `AddRightGroupbox(Name)` -> `Groupbox`
- `Groupbox:AddLabel(Text, Wrap)` -> `Api:SetText`
- `Groupbox:AddDivider()`
- `Groupbox:AddButton({Text, Func})` -> `Api:SetText, SetDisabled`
- `Groupbox:AddToggle(Id, {Text, Default, Callback})` -> `Toggle:SetValue, OnChanged` + `SwiftUI.Options[Id]`
- `Groupbox:AddSlider(Id, {Text, Min, Max, Default, Rounding, Suffix, Callback})`
- `Groupbox:AddDropdown(Id, {Text, Values, Default, Multi, Callback})` -> `SetValue, SetValues`
- `Groupbox:AddInput(Id, {Text, Default, Placeholder, Numeric, Finished, Callback})`
- `Groupbox:AddColorPicker(Id, {Text, Default, Callback})`
- `Groupbox:AddKeyPicker(Id, {Text, Default, Mode, Callback})` -> `GetState`
- `SwiftUI:Notify({Title, Description, Time})`
- `Window:Toggle()` / `Window:Destroy()` / `Window:SetTitle()`
- `SwiftUI:Unload()`

## Managers

```lua
SaveManager:SetLibrary(SwiftUI)
SaveManager:Save("default")
SaveManager:Load("default")
SaveManager:SaveAutoload() / LoadAutoload()

ThemeManager:SetLibrary(SwiftUI)
ThemeManager:ApplyTheme("Midnight") -- SwiftDark, Midnight, Crimson, Forest, Ocean
ThemeManager:SetAccent(Color3.fromRGB(255,0,0))
```
