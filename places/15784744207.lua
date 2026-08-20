local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(game:GetService("Workspace"))
local Lighting = cloneref(game:GetService("Lighting"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles

local Connections = {}
local function disconnect(name)
    if Connections[name] then
        Connections[name]:Disconnect()
        Connections[name] = nil
    end
end
local function connect(name, conn)
    disconnect(name)
    Connections[name] = conn
end

local isAimbotActive = false
local aimbotFOV = 150
local aimbotColor = Color3.fromRGB(255, 50, 50)
local showFOVCircle = true
local FOVCircle = nil

local ENEMY_TEAMS = {
    "Department of Corrections",
    "Sheriff's Office",
    "VCSO-SWAT",
}

local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not player.Team then return false end
    for _, t in ENEMY_TEAMS do
        if player.Team.Name == t then
            return true
        end
    end
    return false
end

local function getEnemyPlayers()
    local enemies = {}
    for _, player in Players:GetPlayers() do
        if isEnemy(player) and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                table.insert(enemies, player)
            end
        end
    end
    return enemies
end

local function getClosestEnemy()
    local camPos = Camera.CFrame.Position
    local closest = nil
    local closestDist = aimbotFOV

    for _, player in getEnemyPlayers() do
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
        end
    end

    return closest
end

local function updateFOVCircle()
    if not FOVCircle then return end
    FOVCircle.Visible = showFOVCircle and isAimbotActive
    FOVCircle.Radius = aimbotFOV
    FOVCircle.Color = aimbotColor
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
end

local function setupFOVCircle()
    local success, circle = pcall(function()
        return Drawing.new("Circle")
    end)
    if success and circle then
        FOVCircle = circle
        FOVCircle.Thickness = 1
        FOVCircle.NumSides = 64
        FOVCircle.Radius = aimbotFOV
        FOVCircle.Color = aimbotColor
        FOVCircle.Filled = false
        FOVCircle.Visible = false
        FOVCircle.Transparency = 1
        FOVCircle.ZIndex = 999
    end
end

local Window = Library:CreateWindow({
    Title = "swift - Valley Prison",
    Footer = "place: 15784744207",
    NotifySide = "Right",
    ShowCustomCursor = true,
    AlwaysOnTop = true,
    Center = true,
    Size = UDim2.new(0, 600, 0, 450),
})

local Tabs = {
    Combat = Window:AddTab("Combat", "crosshair"),
    Player = Window:AddTab("Player", "user"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Misc = Window:AddTab("Misc", "settings"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local CombatGroup = Tabs.Combat:AddLeftGroupbox("Aimbot", "crosshair")
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Player", "user")
local VisualGroup = Tabs.Visuals:AddLeftGroupbox("Visuals", "eye")
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Misc", "settings")

CombatGroup:AddToggle("SilentAim", {
    Text = "Silent Aim",
    Default = false,
    Tooltip = "Silently redirects bullets to the nearest enemy",
})

CombatGroup:AddSlider("AimbotFOV", {
    Text = "FOV Size",
    Default = 150,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        aimbotFOV = value
        if FOVCircle then
            FOVCircle.Radius = value
        end
    end,
})

CombatGroup:AddToggle("ShowFOV", {
    Text = "Show FOV",
    Default = true,
    Callback = function(value)
        showFOVCircle = value
        updateFOVCircle()
    end,
})

CombatGroup:AddColorpicker("FOVColor", {
    Text = "FOV Color",
    Default = Color3.fromRGB(255, 50, 50),
    Callback = function(value)
        aimbotColor = value
        if FOVCircle then
            FOVCircle.Color = value
        end
    end,
})

PlayerGroup:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 250,
    Rounding = 0,
    Callback = function(value)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = value end
        end
    end,
})

PlayerGroup:AddSlider("JumpPower", {
    Text = "Jump Power",
    Default = 50,
    Min = 50,
    Max = 400,
    Rounding = 0,
    Callback = function(value)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.UseJumpPower = true hum.JumpPower = value end
        end
    end,
})

PlayerGroup:AddToggle("NoClip", {
    Text = "No Clip",
    Default = false,
})

PlayerGroup:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Default = false,
})

PlayerGroup:AddButton({
    Text = "Teleport to Nearest Enemy",
    Func = function()
        local closest = getClosestEnemy()
        if closest and closest.Character then
            local hrp = closest.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myHrp then
                myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
            end
        end
    end,
})

PlayerGroup:AddButton({
    Text = "Teleport to Safe Zone",
    Func = function()
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myHrp then
            myHrp.CFrame = CFrame.new(0, 100, 0)
        end
    end,
})

VisualGroup:AddToggle("FullBright", {
    Text = "Full Bright",
    Default = false,
})

VisualGroup:AddToggle("NoFog", {
    Text = "No Fog",
    Default = false,
})

VisualGroup:AddToggle("ThirdPerson", {
    Text = "Third Person",
    Default = false,
})

MiscGroup:AddToggle("AntiAFK", {
    Text = "Anti AFK",
    Default = false,
})

MiscGroup:AddButton({
    Text = "Server Hop",
    Func = function()
        local servers = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(servers)
        if data and data.data then
            local ts = cloneref(game:GetService("TeleportService"))
            for _, server in data.data do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    ts:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    break
                end
            end
        end
    end,
})

MiscGroup:AddButton({
    Text = "Rejoin Server",
    Func = function()
        cloneref(game:GetService("TeleportService")):Teleport(game.PlaceId, LocalPlayer)
    end,
})

Toggles.SilentAim:OnChanged(function()
    isAimbotActive = Toggles.SilentAim.Value
    updateFOVCircle()
end)

Toggles.NoClip:OnChanged(function()
    if Toggles.NoClip.Value then
        connect("NoClip", RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in LocalPlayer.Character:GetDescendants() do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end))
    else
        disconnect("NoClip")
    end
end)

Toggles.InfiniteJump:OnChanged(function()
    if Toggles.InfiniteJump.Value then
        connect("InfiniteJump", UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end))
    else
        disconnect("InfiniteJump")
    end
end)

Toggles.FullBright:OnChanged(function()
    if Toggles.FullBright.Value then
        savedBrightness = Lighting.Brightness
        savedClockTime = Lighting.ClockTime
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    else
        Lighting.Brightness = savedBrightness
        Lighting.ClockTime = savedClockTime
    end
end)

Toggles.NoFog:OnChanged(function()
    if Toggles.NoFog.Value then
        savedFogEnd = Lighting.FogEnd
        savedFogStart = Lighting.FogStart
        Lighting.FogEnd = 999999
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = savedFogEnd
        Lighting.FogStart = savedFogStart
    end
end)

Toggles.ThirdPerson:OnChanged(function()
    if Toggles.ThirdPerson.Value then
        Camera.CameraType = Enum.CameraType.Custom
        LocalPlayer.CameraMinZoomDistance = 15
        LocalPlayer.CameraMaxZoomDistance = 15
    else
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 0.5
    end
end)

Toggles.AntiAFK:OnChanged(function()
    if Toggles.AntiAFK.Value then
        connect("AntiAFK", RunService.Heartbeat:Connect(function()
            cloneref(game:GetService("VirtualUser")):CaptureController()
            cloneref(game:GetService("VirtualUser")):ClickButton2(Vector2.new())
        end))
    else
        disconnect("AntiAFK")
    end
end)

setupFOVCircle()

connect("FOVUpdate", RunService.RenderStepped:Connect(function()
    updateFOVCircle()
end))

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and self == Mouse then
        if method == "__index" then
            local key = ...
            if key == "Hit" and isAimbotActive then
                local closest = getClosestEnemy()
                if closest and closest.Character then
                    local hrp = closest.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        return hrp.CFrame
                    end
                end
            end
        end
    end
    return oldNamecall(self, ...)
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() and self == Mouse then
        if key == "Hit" and isAimbotActive then
            local closest = getClosestEnemy()
            if closest and closest.Character then
                local hrp = closest.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    return hrp.CFrame
                end
            end
        end
    end
    return oldIndex(self, key)
end))

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = Library.ShowCustomCursor,
    Callback = function(value)
        Library.ShowCustomCursor = value
    end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

Library:OnUnload(function()
    for name, conn in Connections do
        conn:Disconnect()
    end
    Connections = {}
    if FOVCircle then
        FOVCircle:Remove()
        FOVCircle = nil
    end
end)

Library:Notify({
    Title = "swift",
    Description = "Valley Prison loaded! RightShift to toggle menu.",
    Time = 4,
})
