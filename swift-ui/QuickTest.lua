local SwiftUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/swift-ui/UI.lua"))()

local Window = SwiftUI:CreateWindow({
    Title = "Swift UI",
    Footer = "Quick Test",
    Size = UDim2.fromOffset(520, 380),
    ToggleKeybind = Enum.KeyCode.RightShift,
})

local Tab = Window:AddTab("Test", "★")
local Left = Tab:AddLeftGroupbox("Controls")
local Right = Tab:AddRightGroupbox("Settings")

Left:AddLabel("Quick test — all MVP controls")
Left:AddButton({Text = "Notify", Func = function() SwiftUI:Notify({Title = "Swift", Description = "Button works!", Time = 2}) end})
Left:AddToggle("TestToggle", {Text = "Toggle", Default = false, Callback = function(V) print("Toggle", V) end})
Left:AddSlider("TestSlider", {Text = "Slider", Min = 0, Max = 100, Default = 50, Rounding = 0, Suffix = "%", Callback = function(V) print(V) end})
Left:AddDropdown("TestDropdown", {Text = "Dropdown", Values = {"A","B","C"}, Default = "A", Callback = function(V) print(V) end})

Right:AddInput("TestInput", {Text = "Input", Default = "", Placeholder = "Type...", Callback = function(V) print(V) end})
Right:AddColorPicker("TestColor", {Text = "Color", Default = Color3.fromRGB(124,92,255), Callback = function(V) print(V) end})
Right:AddKeyPicker("TestKey", {Text = "Key", Default = Enum.KeyCode.Q, Mode = "Toggle", Callback = function(V) print(V) end})
Right:AddDivider()
Right:AddLabel("RightShift to toggle window")

SwiftUI:Notify({Title = "Swift UI", Description = "Quick test loaded!", Time = 3})
