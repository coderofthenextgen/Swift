local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local UserInputService = cloneref(game:GetService("UserInputService"))

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

local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not player.Team or not LocalPlayer.Team then return false end
    if player.Team == LocalPlayer.Team then return false end
    if player.Team.Name == "Menu" then return false end
    return true
end

local function getCharacter(player)
    return player and player.Character
end

local function getHrp(player)
    local char = getCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not player.Team or not LocalPlayer.Team then return false end
    if player.Team == LocalPlayer.Team then return false end
    if player.Team.Name == "Menu" then return false end
    return true
end

local function getClosestEnemy()
    local camPos = Camera.CFrame.Position
    local closest = nil
    local closestDist = aimbotFOV
    local screenCenter = Camera.ViewportSize / 2

    for _, player in Players:GetPlayers() do
        if isEnemy(player) then
            local hrp = getHrp(player)
            if hrp then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = player
                        end
                    end
                end
            end
        end
    end

    return closest
end

local function getAimCFrame()
    local closest = getClosestEnemy()
    if not closest or not closest.Character then return nil end
    local head = closest.Character:FindFirstChild("Head")
    if head then return head.CFrame end
    local hrp = getHrp(closest)
    if hrp then return hrp.CFrame end
    return nil
end

local function updateFOVCircle()
    if not FOVCircle then return end
    FOVCircle.Visible = showFOVCircle and isAimbotActive
    FOVCircle.Radius = aimbotFOV
    FOVCircle.Color = aimbotColor
    FOVCircle.Position = Camera.ViewportSize / 2
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
        FOVCircle.Transparency = 0
        FOVCircle.Visible = false
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
    Size = UDim2.new(0, 500, 0, 300),
})

local Tabs = {
    Combat = Window:AddTab("Combat", "crosshair"),
}

local CombatGroup = Tabs.Combat:AddLeftGroupbox("Aimbot", "crosshair")

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

CombatGroup:AddColorPicker("FOVColor", {
    Text = "FOV Color",
    Default = Color3.fromRGB(255, 50, 50),
    Callback = function(value)
        aimbotColor = value
        if FOVCircle then
            FOVCircle.Color = value
        end
    end,
})

Toggles.SilentAim:OnChanged(function()
    isAimbotActive = Toggles.SilentAim.Value
    updateFOVCircle()
end)

setupFOVCircle()

connect("FOVUpdate", RunService.RenderStepped:Connect(function()
    updateFOVCircle()
end))

local rawMeta = getrawmetatable(Mouse)
local oldIndex = rawMeta.__index

setreadonly(rawMeta, false)

rawMeta.__index = newcclosure(function(self, key)
    if not checkcaller() and self == Mouse and key == "Hit" and isAimbotActive then
        local aim = getAimCFrame()
        if aim then
            return aim
        end
    end
    return oldIndex(self, key)
end)

setreadonly(rawMeta, true)

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
    Description = "Valley Prison loaded!",
    Time = 4,
})