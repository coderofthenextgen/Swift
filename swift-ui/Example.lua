local SwiftUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/swift-ui/UI.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/swift-ui/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/swift-ui/ThemeManager.lua"))()

SaveManager:SetLibrary(SwiftUI)
ThemeManager:SetLibrary(SwiftUI)

local Window = SwiftUI:CreateWindow({
    Title = "Swift UI",
    Footer = "Polished • v1.1",
    Size = UDim2.fromOffset(680, 560),
    ToggleKeybind = Enum.KeyCode.RightShift,
})

Window:SetFooter("swift-ui polished • place: " .. tostring(game.PlaceId))

local MainTab = Window:AddTab("Main", "★")
local CombatTab = Window:AddTab("Combat", "⚔")
local VisualsTab = Window:AddTab("Visuals", "👁")
local SettingsTab = Window:AddTab("Settings", "⚙")

local CombatLeft = MainTab:AddLeftGroupbox("Combat")
CombatLeft:AddLabel("Collapsible • search at top filters this", true)
local T1 = CombatLeft:AddToggle("AutoFarm", {Text = "Auto Farm", Default = false, Callback = function(V) print("Farm", V) end})
T1:AddColorPicker({Default = Color3.fromRGB(124,92,255), Callback = function(C) print("Farm color", C) end})
CombatLeft:AddToggle("AutoParry", {Text = "Auto Parry", Default = true, Color = Color3.fromRGB(46,204,113), Callback = function(V) print(V) end})
CombatLeft:AddDivider("Settings")
CombatLeft:AddSlider("WalkSpeed", {Text = "WalkSpeed", Min = 16, Max = 150, Default = 16, Suffix = " studs", Callback = function(V) game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = V end})
CombatLeft:AddDropdown("Weapon", {Text = "Weapon", Values = {"Sword","Gun","Fists","Magic"}, Default = "Sword", Callback = print})
CombatLeft:AddButton({Text = "Execute", Icon = "▶", Tooltip = "Run exploit", Func = function() SwiftUI:Notify({Title = "Swift", Description = "Executed!", Time = 2}) end})

local VisualsRight = MainTab:AddRightGroupbox("Visuals")
VisualsRight:AddToggle("ESP", {Text = "ESP Enabled", Default = true, Callback = print})
VisualsRight:AddColorPicker("ESPColor", {Text = "ESP Color", Default = Color3.fromRGB(124,92,255), Callback = print})
VisualsRight:AddInput("TargetInput", {Text = "Target Player", Placeholder = "Username...", Callback = print})
VisualsRight:AddKeyPicker("ESPKey", {Text = "ESP Toggle", Default = Enum.KeyCode.Q, Mode = "Toggle", Callback = print})
VisualsRight:AddDivider("Extra")
VisualsRight:AddSlider("FOV", {Text = "FOV", Min = 70, Max = 120, Default = 70, Suffix = "°", Callback = print})
VisualsRight:AddDropdown("Quality", {Text = "Quality", Values = {"Low","Medium","High","Ultra"}, Default = "High", Callback = print})

local PlayerGroup = CombatTab:AddLeftGroupbox("Player")
PlayerGroup:AddSlider("Speed", {Text = "Speed", Min = 0, Max = 300, Default = 100, Suffix = "%", Callback = print})
PlayerGroup:AddToggle("Noclip", {Text = "Noclip", Default = false})
PlayerGroup:AddDivider()
PlayerGroup:AddButton({Text = "Reset Character", Func = function() game.Players.LocalPlayer.Character:BreakJoints() end})

local WorldGroup = VisualsTab:AddLeftGroupbox("World")
WorldGroup:AddToggle("Fullbright", {Text = "Fullbright", Default = false})
WorldGroup:AddSlider("Brightness", {Text = "Brightness", Min = 0, Max = 5, Default = 2, Rounding = 1, Callback = print})
WorldGroup:AddColorPicker("Ambient", {Text = "Ambient", Default = Color3.fromRGB(150,150,150)})

SaveManager:SetFolder("SwiftUI")
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:BuildThemeSection(SettingsTab)

local CustomGroup = SettingsTab:AddLeftGroupbox("Customization")
CustomGroup:AddLabel("Make it very customizable", true)
CustomGroup:AddSlider("CornerRadius", {Text = "Corner Radius", Min = 0, Max = 12, Default = 0, Rounding = 0, Callback = function(V) SwiftUI:SetCornerRadius(V) end})
CustomGroup:AddSlider("UIScale", {Text = "UI Scale", Min = 80, Max = 120, Default = 100, Suffix = "%", Callback = function(V) SwiftUI:SetScale(V/100) end})
CustomGroup:AddSlider("Transparency", {Text = "Transparency", Min = 0, Max = 50, Default = 0, Suffix = "%", Callback = function(V) SwiftUI:SetTransparency(V/100) end})
CustomGroup:AddButton({Text = "Reset Custom", Func = function() SwiftUI:SetCornerRadius(0) SwiftUI:SetScale(1) SwiftUI:SetTransparency(0) SwiftUI:SetAccent(Color3.fromRGB(124,92,255)) end})

local Info = SettingsTab:AddRightGroupbox("About")
Info:AddLabel("Swift UI • Straight boxy dark • Accent updates live", true)
Info:AddDivider("Info")
Info:AddLabel("Search filters labels/toggles • Click groupbox header to collapse • RightShift toggles", true)
Info:AddButton({Text = "Copy Discord", Func = function() setclipboard("https://discord.gg/swift") SwiftUI:Notify({Title = "Copied", Description = "Discord copied", Time = 2}) end})

SaveManager:LoadAutoload()
SwiftUI:Notify({Title = "Swift UI", Description = "Polished loaded!", Time = 3})
