local SwiftUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/swift-ui/UI.lua"))()

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/swift-ui/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/swift-ui/ThemeManager.lua"))()

SaveManager:SetLibrary(SwiftUI)
ThemeManager:SetLibrary(SwiftUI)

local Window = SwiftUI:CreateWindow({
    Title = "Swift UI",
    Footer = "Example • v1.0",
    Size = UDim2.fromOffset(640, 540),
    Center = true,
    ToggleKeybind = Enum.KeyCode.RightShift,
})

local MainTab = Window:AddTab("Main", "★")
local SettingsTab = Window:AddTab("Settings", "⚙")
local InfoTab = Window:AddTab("Info", "ℹ")

local CombatGroup = MainTab:AddLeftGroupbox("Combat")
CombatGroup:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = false,
    Callback = function(Value)
        print("AutoFarm:", Value)
    end,
})
CombatGroup:AddSlider("WalkSpeed", {
    Text = "WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Rounding = 0,
    Suffix = " studs",
    Callback = function(Value)
        if game.Players.LocalPlayer.Character then
            local Hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Hum then Hum.WalkSpeed = Value end
        end
    end,
})
CombatGroup:AddDropdown("Weapon", {
    Text = "Weapon",
    Values = {"Sword", "Gun", "Fists", "Magic"},
    Default = "Sword",
    Callback = function(Value)
        print("Weapon:", Value)
    end,
})
CombatGroup:AddDivider()
CombatGroup:AddButton({
    Text = "Execute Exploit",
    Func = function()
        SwiftUI:Notify({Title = "Swift", Description = "Executed!", Time = 3})
    end,
})

local VisualsGroup = MainTab:AddRightGroupbox("Visuals")
VisualsGroup:AddToggle("ESP", {
    Text = "ESP Enabled",
    Default = true,
    Callback = function(Value) print("ESP", Value) end,
})
VisualsGroup:AddColorPicker("ESPColor", {
    Text = "ESP Color",
    Default = Color3.fromRGB(124, 92, 255),
    Callback = function(Value) print("ESP Color", Value) end,
})
VisualsGroup:AddInput("PlayerName", {
    Text = "Target Player",
    Default = "",
    Placeholder = "Enter username...",
    Callback = function(Value) print("Target", Value) end,
})
VisualsGroup:AddKeyPicker("ESPKey", {
    Text = "ESP Toggle Key",
    Default = Enum.KeyCode.Q,
    Mode = "Toggle",
    Callback = function(Value) print("Key", Value) end,
})

local ConfigGroup = SettingsTab:AddLeftGroupbox("Configuration")
ConfigGroup:AddLabel("Change your settings and save them. They will persist across sessions via SaveManager.", true)
SaveManager:BuildConfigSection(SettingsTab)

local ThemeGroup = SettingsTab:AddRightGroupbox("Theme")
ThemeManager:BuildThemeSection(SettingsTab)
ThemeGroup:AddDivider()
ThemeGroup:AddLabel("Press RightShift to toggle window visibility.", true)

local InfoGroup = InfoTab:AddLeftGroupbox("About")
InfoGroup:AddLabel("Swift UI — Custom UI Library", true)
InfoGroup:AddDivider()
InfoGroup:AddLabel("Built with PascalCase, draggable window, toggle keybind, notifications, and full MVP controls.", true)
InfoGroup:AddButton({
    Text = "Copy Discord",
    Func = function()
        if setclipboard then setclipboard("https://discord.gg/swift") end
        SwiftUI:Notify({Title = "Copied", Description = "Discord link copied", Time = 2})
    end,
})

local DebugGroup = InfoTab:AddRightGroupbox("Debug")
DebugGroup:AddSlider("TestSlider", {
    Text = "Precision Slider",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Rounding = 2,
    Callback = function(V) print(V) end,
})
DebugGroup:AddDropdown("MultiDropdown", {
    Text = "Multi Select",
    Values = {"A", "B", "C", "D"},
    Multi = true,
    Default = {"A"},
    Callback = function(V) print(table.concat(V, ", ")) end,
})
DebugGroup:AddInput("NumericInput", {
    Text = "Numeric Input",
    Default = "100",
    Numeric = true,
    Placeholder = "0-100",
    Callback = function(V) print(V) end,
})

SaveManager:LoadAutoload()

SwiftUI:Notify({Title = "Swift UI", Description = "Loaded successfully!", Time = 3})
