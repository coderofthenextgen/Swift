local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Lighting = cloneref(game:GetService("Lighting"))
local CollectionService = cloneref(game:GetService("CollectionService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Teams = cloneref(game:GetService("Teams"))
local StarterGui = cloneref(game:GetService("StarterGui"))

local LocalPlayer = Players.LocalPlayer

local savedPos = nil
local savedBrightness = Lighting.Brightness
local savedClockTime = Lighting.ClockTime
local savedFogEnd = Lighting.FogEnd
local savedFogStart = Lighting.FogStart

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GunRemotes = ReplicatedStorage:WaitForChild("GunRemotes")
local meleeEvent = ReplicatedStorage:WaitForChild("meleeEvent")

local function getTeam()
    return LocalPlayer.Team
end

local function isGuard()
    return getTeam() == Teams.Guards
end

local function isInmate()
    return getTeam() == Teams.Inmates
end

local function isCriminal()
    return getTeam() == Teams.Criminals
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHrp()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getGun()
    local char = getCharacter()
    if char then
        for _, t in char:GetChildren() do
            if t:IsA("Tool") and (t:FindFirstChild("GunScript") or t:FindFirstChild("Handle")) then
                return t
            end
        end
    end
    for _, t in LocalPlayer.Backpack:GetChildren() do
        if t:IsA("Tool") then
            return t
        end
    end
end

local function getTaser()
    local char = getCharacter()
    if char then
        for _, t in char:GetChildren() do
            if t:IsA("Tool") and t.Name == "Taser" then
                return t
            end
        end
    end
    for _, t in LocalPlayer.Backpack:GetChildren() do
        if t:IsA("Tool") and t.Name == "Taser" then
            return t
        end
    end
end

local function getNearestEnemy()
    local myHrp = getHrp()
    if not myHrp then return end
    local nearest, nearestDist
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and p.Character and p.Team ~= getTeam() then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                if not nearestDist or dist < nearestDist then
                    nearest, nearestDist = p, dist
                end
            end
        end
    end
    return nearest
end

local function getNearestPlayer()
    local myHrp = getHrp()
    if not myHrp then return end
    local nearest, nearestDist
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                if not nearestDist or dist < nearestDist then
                    nearest, nearestDist = p, dist
                end
            end
        end
    end
    return nearest
end

local function findGunInWorld()
    for _, obj in Workspace:GetDescendants() do
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
            local player = game.Players:GetPlayerFromCharacter(obj.Parent)
            if not player then
                return obj
            end
        end
    end
end

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

local Window = Library:CreateWindow({
    Title = "swift - prison life",
    Size = UDim2.new(0, 600, 0, 450),
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Combat = Window:AddTab("Combat", "crosshair"),
    Player = Window:AddTab("Player", "user"),
    Teams = Window:AddTab("Teams", "users"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Misc = Window:AddTab("Misc", "settings"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local CombatGroup = Tabs.Combat:AddLeftGroupbox("Combat", "crosshair")
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Player", "user")
local TeamsGroup = Tabs.Teams:AddLeftGroupbox("Teams", "users")
local VisualGroup = Tabs.Visuals:AddLeftGroupbox("Visuals", "eye")
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Misc", "settings")

local RoleLabel = CombatGroup:AddLabel("Team: Loading...", true, "TeamLabel")

CombatGroup:AddToggle("AutoPunch", {
    Text = "Auto Punch",
    Default = false,
    Tooltip = "Punches nearest enemy automatically",
})

CombatGroup:AddToggle("AutoShoot", {
    Text = "Auto Shoot",
    Default = false,
    Tooltip = "Shoots nearest enemy (need gun)",
})

CombatGroup:AddToggle("AutoArrest", {
    Text = "Auto Arrest",
    Default = false,
    Tooltip = "Arrests nearest inmate/criminal (guard only)",
})

CombatGroup:AddToggle("AutoTase", {
    Text = "Auto Tase",
    Default = false,
    Tooltip = "Tases nearest enemy (need taser, guard only)",
})

CombatGroup:AddToggle("KillAura", {
    Text = "Kill Aura",
    Default = false,
    Tooltip = "Punches everyone within range",
})

CombatGroup:AddSlider("KillAuraRange", {
    Text = "Kill Aura Range",
    Default = 15,
    Min = 5,
    Max = 30,
    Rounding = 0,
})

local lastPunchTime = 0
Toggles.AutoPunch:OnChanged(function()
    if Toggles.AutoPunch.Value then
        connect("AutoPunch", RunService.Heartbeat:Connect(function()
            if tick() - lastPunchTime < 0.5 then return end
            local target = getNearestEnemy()
            if not target then return end
            local targetHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = getHrp()
            if not targetHrp or not myHrp then return end
            local dist = (targetHrp.Position - myHrp.Position).Magnitude
            if dist > 10 then return end
            lastPunchTime = tick()
            meleeEvent:FireServer(target, 1, 1)
        end))
    else
        disconnect("AutoPunch")
    end
end)

local lastShootTime = 0
Toggles.AutoShoot:OnChanged(function()
    if Toggles.AutoShoot.Value then
        connect("AutoShoot", RunService.Heartbeat:Connect(function()
            if tick() - lastShootTime < 0.5 then return end
            local gun = getGun()
            if not gun then return end
            local target = getNearestEnemy()
            if not target then return end
            local targetHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = getHrp()
            if not targetHrp or not myHrp then return end
            local dist = (targetHrp.Position - myHrp.Position).Magnitude
            if dist > 200 then return end
            lastShootTime = tick()
            myHrp.CFrame = CFrame.new(myHrp.Position, Vector3.new(targetHrp.Position.X, myHrp.Position.Y, targetHrp.Position.Z))
            local head = target.Character:FindFirstChild("Head")
            local targetCFrame = head and head.CFrame or targetHrp.CFrame
            local shootRemote = GunRemotes:FindFirstChild("ShootEvent")
            if shootRemote then
                shootRemote:FireServer({{targetHrp.Position, targetHrp.Position, targetHrp}})
            end
        end))
    else
        disconnect("AutoShoot")
    end
end)

local lastArrestTime = 0
Toggles.AutoArrest:OnChanged(function()
    if Toggles.AutoArrest.Value then
        connect("AutoArrest", RunService.Heartbeat:Connect(function()
            if not isGuard() then return end
            if tick() - lastArrestTime < 1 then return end
            local target = getNearestEnemy()
            if not target then return end
            local targetHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = getHrp()
            if not targetHrp or not myHrp then return end
            local dist = (targetHrp.Position - myHrp.Position).Magnitude
            if dist > 10 then
                myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 2)
            else
                lastArrestTime = tick()
                Remotes:WaitForChild("ArrestPlayer"):InvokeServer(target, 1)
            end
        end))
    else
        disconnect("AutoArrest")
    end
end)

local lastTaseTime = 0
Toggles.AutoTase:OnChanged(function()
    if Toggles.AutoTase.Value then
        connect("AutoTase", RunService.Heartbeat:Connect(function()
            if not isGuard() then return end
            local taser = getTaser()
            if not taser then return end
            if tick() - lastTaseTime < 2 then return end
            local target = getNearestEnemy()
            if not target then return end
            local targetHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = getHrp()
            if not targetHrp or not myHrp then return end
            local dist = (targetHrp.Position - myHrp.Position).Magnitude
            if dist > 50 then return end
            lastTaseTime = tick()
            myHrp.CFrame = CFrame.new(myHrp.Position, Vector3.new(targetHrp.Position.X, myHrp.Position.Y, targetHrp.Position.Z))
            GunRemotes:WaitForChild("PlayerTased"):FireServer(target)
        end))
    else
        disconnect("AutoTase")
    end
end)

local lastAuraTime = 0
Toggles.KillAura:OnChanged(function()
    if Toggles.KillAura.Value then
        connect("KillAura", RunService.Heartbeat:Connect(function()
            if tick() - lastAuraTime < 0.5 then return end
            local myHrp = getHrp()
            if not myHrp then return end
            local range = Toggles.KillAuraRange and Toggles.KillAuraRange.Value or 15
            for _, p in Players:GetPlayers() do
                if p ~= LocalPlayer and p.Team ~= getTeam() and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local dist = (hrp.Position - myHrp.Position).Magnitude
                        if dist <= range then
                            lastAuraTime = tick()
                            meleeEvent:FireServer(p, 1, 1)
                            break
                        end
                    end
                end
            end
        end))
    else
        disconnect("KillAura")
    end
end)

PlayerGroup:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 250,
    Rounding = 0,
    Callback = function(Value)
        local hum = getHum()
        if hum then hum.WalkSpeed = Value end
    end,
})

PlayerGroup:AddSlider("JumpPower", {
    Text = "Jump Power",
    Default = 50,
    Min = 50,
    Max = 400,
    Rounding = 0,
    Callback = function(Value)
        local hum = getHum()
        if hum then hum.JumpPower = Value end
    end,
})

PlayerGroup:AddToggle("NoClip", {
    Text = "No Clip",
    Default = false,
    Tooltip = "Walk through walls",
})

PlayerGroup:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Default = false,
    Tooltip = "Jump as many times as you want",
})

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
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end))
    else
        disconnect("InfiniteJump")
    end
end)

local lastAFK = 0
Toggles.AntiAFK:OnChanged(function()
    if Toggles.AntiAFK.Value then
        connect("AntiAFK", RunService.Heartbeat:Connect(function()
            if tick() - lastAFK < 30 then return end
            lastAFK = tick()
            cloneref(game:GetService("VirtualUser")):ClickButton2(Vector2.new())
        end))
    else
        disconnect("AntiAFK")
    end
end)

TeamsGroup:AddButton({
    Text = "Join Guards",
    Func = function()
        Remotes:WaitForChild("RequestTeamChange"):InvokeServer("Guards")
    end,
})

TeamsGroup:AddButton({
    Text = "Join Inmates",
    Func = function()
        Remotes:WaitForChild("RequestTeamChange"):InvokeServer("Inmates")
    end,
})

TeamsGroup:AddButton({
    Text = "Join Criminals",
    Func = function()
        Remotes:WaitForChild("RequestTeamChange"):InvokeServer("Criminals")
    end,
})

local teamColors = {
    Guards = Color3.fromRGB(50, 120, 255),
    Inmates = Color3.fromRGB(255, 160, 40),
    Criminals = Color3.fromRGB(255, 50, 50),
    Neutral = Color3.fromRGB(200, 200, 200),
}

local function refreshLabels()
    local team = getTeam()
    RoleLabel:SetText("Team: " .. (team and team.Name or "Unknown"))
end

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(refreshLabels)
refreshLabels()

local function updateESP()
    local showPlayer = Toggles.PlayerESP and Toggles.PlayerESP.Value
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and p.Character then
            local oldHighlight = p.Character:FindFirstChild("PL_ESP_HL")
            if showPlayer then
                if not oldHighlight then
                    local teamName = p.Team and p.Team.Name
                    local color = teamColors[teamName] or Color3.new(1, 1, 1)
                    local h = Instance.new("Highlight")
                    h.Name = "PL_ESP_HL"
                    h.FillColor = color
                    h.FillTransparency = 0.5
                    h.OutlineColor = color
                    h.OutlineTransparency = 0
                    h.Adornee = p.Character
                    h.Parent = p.Character
                end
            elseif oldHighlight then
                oldHighlight:Destroy()
            end

            local head = p.Character:FindFirstChild("Head")
            if head then
                local billboard = head:FindFirstChild("PL_role_tag")
                if showPlayer then
                    if not billboard then
                        billboard = Instance.new("BillboardGui")
                        billboard.Name = "PL_role_tag"
                        billboard.Size = UDim2.new(0, 160, 0, 40)
                        billboard.StudsOffset = Vector3.new(0, 3, 0)
                        billboard.AlwaysOnTop = true
                        billboard.Adornee = head
                        billboard.Parent = head

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.TextColor3 = teamColors[p.Team and p.Team.Name] or Color3.new(1, 1, 1)
                        label.TextStrokeTransparency = 0
                        label.TextStrokeColor3 = Color3.new(0, 0, 0)
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 14
                        label.Text = (p.Team and p.Team.Name or "?") .. "\n" .. p.Name
                        label.Parent = billboard
                    end
                elseif billboard then
                    billboard:Destroy()
                end
            end
        end
    end
end

VisualGroup:AddToggle("PlayerESP", {
    Text = "Player ESP",
    Default = false,
    Tooltip = "Shows team colors on all players",
})

VisualGroup:AddToggle("FullBright", {
    Text = "Full Bright",
    Default = false,
})

VisualGroup:AddToggle("NoFog", {
    Text = "No Fog",
    Default = false,
})

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

local lastESPUpdate = 0
connect("ESPUpdate", RunService.Heartbeat:Connect(function()
    if tick() - lastESPUpdate < 0.1 then return end
    lastESPUpdate = tick()
    pcall(updateESP)
end))

MiscGroup:AddButton({
    Text = "Get All Guns",
    Func = function()
        if not isGuard() then
            Library:Notify({ Title = "swift", Description = "Must be guard to get guns", Time = 3 })
            return
        end
        Remotes:WaitForChild("GiverPressed"):FireServer("M9")
        task.wait(0.2)
        Remotes:WaitForChild("GiverPressed"):FireServer("Remington 870")
        task.wait(0.2)
        Remotes:WaitForChild("GiverPressed"):FireServer("AK-47")
        task.wait(0.2)
        Remotes:WaitForChild("GiverPressed"):FireServer("Riot Shield")
        task.wait(0.2)
        Remotes:WaitForChild("GiverPressed"):FireServer("Sniper")
        Library:Notify({ Title = "swift", Description = "Requested all guns", Time = 3 })
    end,
})

MiscGroup:AddButton({
    Text = "Get Taser",
    Func = function()
        if not isGuard() then
            Library:Notify({ Title = "swift", Description = "Must be guard to get taser", Time = 3 })
            return
        end
        Remotes:WaitForChild("GiverPressed"):FireServer("Taser")
    end,
})

MiscGroup:AddButton({
    Text = "Unlock Doors",
    Func = function()
        Remotes:WaitForChild("RequestCollisionChange"):FireServer()
    end,
})

MiscGroup:AddButton({
    Text = "Copy Name",
    Func = function()
        if setclipboard then
            setclipboard(LocalPlayer.Name)
            Library:Notify({ Title = "swift", Description = "Copied: " .. LocalPlayer.Name, Time = 3 })
        end
    end,
})

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

Library:Notify({ Title = "swift", Description = "Prison Life loaded - swift - prison life", Time = 3 })
