local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Lighting = cloneref(game:GetService("Lighting"))
local CollectionService = cloneref(game:GetService("CollectionService"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles

local CurrentRoundClient = require(game.ReplicatedStorage.Modules.CurrentRoundClient)
local GameplayRemotes = game.ReplicatedStorage.Remotes.Gameplay

local function getPlayerData()
    return CurrentRoundClient.PlayerData or {}
end

local function getRole(player)
    local data = getPlayerData()
    local info = data[player.Name]
    return info and info.Role
end

local function getPlayerInfo(player)
    return getPlayerData()[player.Name]
end

local function getAlivePlayers()
    local out = {}
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and p.Character then
            local info = getPlayerInfo(p)
            if info and not info.Dead then
                out[#out + 1] = p
            end
        end
    end
    return out
end

local function getByRole(role)
    for _, p in Players:GetPlayers() do
        if getRole(p) == role then
            return p
        end
    end
end

local function getCharacter(player)
    return player and player.Character
end

local function getHrp(player)
    local char = getCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getNearestPlayer(roleFilter)
    local myHrp = getHrp(LocalPlayer)
    if not myHrp then return end
    local nearest, nearestDist
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer then
            local info = getPlayerInfo(p)
            if info and not info.Dead and info.Role ~= "Murderer" then
                if not roleFilter or info.Role == roleFilter then
                    local hrp = getHrp(p)
                    if hrp then
                        local dist = (hrp.Position - myHrp.Position).Magnitude
                        if not nearestDist or dist < nearestDist then
                            nearest, nearestDist = p, dist
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function findKnifeTool(player)
    for _, t in player.Character:GetChildren() do
        if t:IsA("Tool") and t:FindFirstChild("KnifeServer") and t:FindFirstChild("KnifeClient") then
            return t
        end
    end
    for _, t in player.Backpack:GetChildren() do
        if t:IsA("Tool") and t:FindFirstChild("KnifeServer") and t:FindFirstChild("KnifeClient") then
            return t
        end
    end
end

local function findGunTool(player)
    for _, t in player.Character:GetChildren() do
        if t:IsA("Tool") and t:FindFirstChild("GunClient") and t.Events and t.Events:FindFirstChild("Shoot") then
            return t
        end
    end
    for _, t in player.Backpack:GetChildren() do
        if t:IsA("Tool") and t:FindFirstChild("GunClient") and t.Events and t.Events:FindFirstChild("Shoot") then
            return t
        end
    end
end

local function getGunInWorld()
    for _, obj in Workspace:GetDescendants() do
        if obj:IsA("Tool") and obj:FindFirstChild("GunClient") and obj.Events and obj.Events:FindFirstChild("Shoot") then
            return obj
        end
    end
end

local function getCoins()
    local out = {}
    for _, obj in CollectionService:GetTagged("CoinVisual") do
        if not obj:GetAttribute("Delete") then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then
                out[#out + 1] = part
            end
        end
    end
    return out
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
    Title = "swift - murder mystery 2",
    Footer = "place: 142823291",
    NotifySide = "Right",
    ShowCustomCursor = true,
    AlwaysOnTop = true,
    Center = true,
    Size = UDim2.new(0, 600, 0, 450),
})

local Tabs = {
    Main = Window:AddTab("Main", "crosshair"),
    Player = Window:AddTab("Player", "user"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Misc = Window:AddTab("Misc", "settings"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local MainGroup = Tabs.Main:AddLeftGroupbox("Combat", "crosshair")
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Player", "user")
local VisualGroup = Tabs.Visuals:AddLeftGroupbox("Visuals", "eye")
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Misc", "settings")

local RoleLabel = MainGroup:AddLabel("Role: Loading...", true, "RoleLabel")
local MurdererLabel = MainGroup:AddLabel("Murderer: -", true, "MurdererLabel")
local SheriffLabel = MainGroup:AddLabel("Sheriff: -", true, "SheriffLabel")

MainGroup:AddDivider()

MainGroup:AddToggle("AutoStab", {
    Text = "Auto Stab (Murderer)",
    Default = false,
    Tooltip = "Automatically teleports to and stabs the nearest alive innocent",
})

MainGroup:AddToggle("AutoShoot", {
    Text = "Auto Shoot (Sheriff)",
    Default = false,
    Tooltip = "Automatically aims and shoots the murderer",
})

MainGroup:AddToggle("AutoPickupGun", {
    Text = "Auto Pickup Gun",
    Default = false,
    Tooltip = "Teleports to and picks up the gun when it drops",
})

MainGroup:AddToggle("Hitbox", {
    Text = "Expand Hitboxes",
    Default = false,
    Tooltip = "Makes all player hitboxes much larger",
})

PlayerGroup:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 250,
    Rounding = 0,
    Callback = function(Value)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Value end
        end
    end,
})

PlayerGroup:AddSlider("JumpPower", {
    Text = "Jump Power",
    Default = 50,
    Min = 50,
    Max = 400,
    Rounding = 0,
    Callback = function(Value)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.UseJumpPower = true hum.JumpPower = Value end
        end
    end,
})

PlayerGroup:AddSlider("HipHeight", {
    Text = "Hip Height",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.HipHeight = Value end
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

PlayerGroup:AddDivider()

PlayerGroup:AddButton({
    Text = "Teleport to Murderer",
    Func = function()
        local m = getByRole("Murderer")
        local hrp = getHrp(m)
        local myHrp = getHrp(LocalPlayer)
        if hrp and myHrp then
            myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 5)
        end
    end,
})

PlayerGroup:AddButton({
    Text = "Teleport to Sheriff",
    Func = function()
        local s = getByRole("Sheriff")
        local hrp = getHrp(s)
        local myHrp = getHrp(LocalPlayer)
        if hrp and myHrp then
            myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 5)
        end
    end,
})

PlayerGroup:AddButton({
    Text = "Teleport to Nearest Player",
    Func = function()
        local nearest = getNearestPlayer()
        local hrp = getHrp(nearest)
        local myHrp = getHrp(LocalPlayer)
        if hrp and myHrp then
            myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
        end
    end,
})

PlayerGroup:AddButton({
    Text = "Teleport to Nearest Coin",
    Func = function()
        local myHrp = getHrp(LocalPlayer)
        if not myHrp then return end
        local coins = getCoins()
        local nearest, dist
        for _, coin in coins do
            local d = (coin.Position - myHrp.Position).Magnitude
            if not dist or d < dist then
                nearest, dist = coin, d
            end
        end
        if nearest then
            myHrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 3, 0))
        end
    end,
})

VisualGroup:AddToggle("MurdererESP", {
    Text = "Murderer ESP",
    Default = false,
})

VisualGroup:AddToggle("SheriffESP", {
    Text = "Sheriff ESP",
    Default = false,
})

VisualGroup:AddToggle("RoleESP", {
    Text = "Role ESP (All Players)",
    Default = false,
    Tooltip = "Shows a colored label + name above every alive player's head",
})

VisualGroup:AddToggle("KnifeESP", {
    Text = "Knife ESP",
    Default = false,
})

VisualGroup:AddToggle("GunESP", {
    Text = "Gun ESP",
    Default = false,
})

VisualGroup:AddToggle("CoinESP", {
    Text = "Coin ESP",
    Default = false,
})

VisualGroup:AddToggle("FullBright", {
    Text = "Full Bright",
    Default = false,
})

VisualGroup:AddToggle("NoFog", {
    Text = "No Fog",
    Default = false,
})

MiscGroup:AddToggle("AntiAFK", {
    Text = "Anti AFK",
    Default = false,
})

MiscGroup:AddToggle("AutoCollectCoins", {
    Text = "Auto Collect Coins",
    Default = false,
    Tooltip = "Teleports to and collects nearby coins",
})

MiscGroup:AddDivider()

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

MiscGroup:AddButton({
    Text = "Copy Murderer Name",
    Func = function()
        local m = getByRole("Murderer")
        if m and setclipboard then
            setclipboard(m.Name)
            Library:Notify({ Title = "swift", Description = "Copied: " .. m.Name, Time = 3 })
        end
    end,
})

MiscGroup:AddButton({
    Text = "Copy Sheriff Name",
    Func = function()
        local s = getByRole("Sheriff")
        if s and setclipboard then
            setclipboard(s.Name)
            Library:Notify({ Title = "swift", Description = "Copied: " .. s.Name, Time = 3 })
        end
    end,
})

Toggles.AutoStab:OnChanged(function()
    if Toggles.AutoStab.Value then
        connect("AutoStab", RunService.Heartbeat:Connect(function()
            if getRole(LocalPlayer) ~= "Murderer" then return end
            local knife = findKnifeTool(LocalPlayer)
            if not knife then return end
            local target = getNearestPlayer()
            local targetHrp = getHrp(target)
            local myHrp = getHrp(LocalPlayer)
            if not targetHrp or not myHrp then return end
            local dist = (targetHrp.Position - myHrp.Position).Magnitude
            if dist > 8 then
                myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 2)
            else
                myHrp.CFrame = targetHrp.CFrame
                local evt = knife:FindFirstChild("Events") and knife.Events:FindFirstChild("KnifeStabbed")
                if evt then
                    evt:FireServer()
                end
            end
        end))
    else
        disconnect("AutoStab")
    end
end)

Toggles.AutoShoot:OnChanged(function()
    if Toggles.AutoShoot.Value then
        connect("AutoShoot", RunService.Heartbeat:Connect(function()
            if getRole(LocalPlayer) ~= "Sheriff" and getRole(LocalPlayer) ~= "Hero" then return end
            local gun = findGunTool(LocalPlayer)
            if not gun then return end
            local m = getByRole("Murderer")
            local targetHrp = getHrp(m)
            local myHrp = getHrp(LocalPlayer)
            if not targetHrp or not myHrp then return end
            local dist = (targetHrp.Position - myHrp.Position).Magnitude
            if dist > 200 then return end
            local char = LocalPlayer.Character
            local attach = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("GunRaycastAttachment")
            local gunCFrame = attach and attach.WorldCFrame or (char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.CFrame) or CFrame.new()
            local head = m.Character and m.Character:FindFirstChild("Head")
            local target = head and head.CFrame or targetHrp.CFrame
            myHrp.CFrame = CFrame.new(myHrp.Position, Vector3.new(targetHrp.Position.X, myHrp.Position.Y, targetHrp.Position.Z))
            gun.Events.Shoot:FireServer(gunCFrame, target)
        end))
    else
        disconnect("AutoShoot")
    end
end)

Toggles.AutoPickupGun:OnChanged(function()
    if Toggles.AutoPickupGun.Value then
        connect("AutoPickupGun", RunService.Heartbeat:Connect(function()
            local gun = getGunInWorld()
            if not gun then return end
            local handle = gun:FindFirstChild("Handle")
            if not handle then return end
            local myHrp = getHrp(LocalPlayer)
            if not myHrp then return end
            local dist = (handle.Position - myHrp.Position).Magnitude
            if dist > 10 then
                myHrp.CFrame = CFrame.new(handle.Position + Vector3.new(0, 3, 0))
            else
                local hrp = getHrp(LocalPlayer)
                if hrp then
                    firetouchinterest(hrp, handle, 0)
                    firetouchinterest(hrp, handle, 1)
                end
            end
        end))
    else
        disconnect("AutoPickupGun")
    end
end)

Toggles.Hitbox:OnChanged(function()
    if Toggles.Hitbox.Value then
        connect("Hitbox", RunService.Heartbeat:Connect(function()
            for _, p in Players:GetPlayers() do
                if p ~= LocalPlayer and p.Character then
                    for _, part in p.Character:GetDescendants() do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.Size = Vector3.new(9, 9, 9)
                        end
                    end
                end
            end
        end))
    else
        disconnect("Hitbox")
        for _, p in Players:GetPlayers() do
            if p ~= LocalPlayer and p.Character then
                for _, part in p.Character:GetDescendants() do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        if part.Name:find("Right Arm") or part.Name:find("Left Arm") or part.Name:find("Right Leg") or part.Name:find("Left Leg") then
                            part.Size = Vector3.new(2, 2, 2)
                        end
                    end
                end
            end
        end
    end
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
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    else
        Lighting.Brightness = 0
        Lighting.ClockTime = 12
    end
end)

Toggles.NoFog:OnChanged(function()
    if Toggles.NoFog.Value then
        Lighting.FogEnd = 999999
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
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

Toggles.AutoCollectCoins:OnChanged(function()
    if Toggles.AutoCollectCoins.Value then
        connect("AutoCollectCoins", RunService.Heartbeat:Connect(function()
            local myHrp = getHrp(LocalPlayer)
            if not myHrp then return end
            local coins = getCoins()
            local nearest, dist
            for _, coin in coins do
                local d = (coin.Position - myHrp.Position).Magnitude
                if not dist or d < dist then
                    nearest, dist = coin, d
                end
            end
            if nearest and dist then
                if dist > 5 then
                    myHrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 2, 0))
                end
            end
        end))
    else
        disconnect("AutoCollectCoins")
    end
end)

local roleColors = {
    Murderer = Color3.fromRGB(255, 50, 50),
    Sheriff = Color3.fromRGB(50, 150, 255),
    Hero = Color3.fromRGB(255, 200, 50),
    Innocent = Color3.fromRGB(80, 255, 120),
    Assassin = Color3.fromRGB(255, 255, 255),
}

local function updateESP()
    local showMurderer = Toggles.MurdererESP.Value
    local showSheriff = Toggles.SheriffESP.Value
    local showRoles = Toggles.RoleESP.Value

    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and p.Character then
            local info = getPlayerInfo(p)
            local role = getRole(p)
            local isDead = info and info.Dead

            local oldHighlight = p.Character:FindFirstChild("SwiftESP_HL")
            local shouldShow = (showRoles and role) or (showMurderer and role == "Murderer") or (showSheriff and role == "Sheriff")
            shouldShow = shouldShow and not isDead

            if shouldShow then
                if not oldHighlight then
                    local color = roleColors[role] or Color3.fromRGB(255, 255, 255)
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "SwiftESP_HL"
                    highlight.FillColor = color
                    highlight.FillTransparency = 0.5
                    highlight.OutlineColor = color
                    highlight.OutlineTransparency = 0
                    highlight.Adornee = p.Character
                    highlight.Parent = p.Character
                end
            elseif oldHighlight then
                oldHighlight:Destroy()
            end

            local head = p.Character:FindFirstChild("Head")
            if head then
                local billboard = head:FindFirstChild("swift_role_tag")
                if showRoles and role and not isDead then
                    if not billboard then
                        billboard = Instance.new("BillboardGui")
                        billboard.Name = "swift_role_tag"
                        billboard.Size = UDim2.new(0, 160, 0, 40)
                        billboard.StudsOffset = Vector3.new(0, 3, 0)
                        billboard.AlwaysOnTop = true
                        billboard.Adornee = head
                        billboard.Parent = head

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.TextColor3 = roleColors[role] or Color3.new(1, 1, 1)
                        label.TextStrokeTransparency = 0
                        label.TextStrokeColor3 = Color3.new(0, 0, 0)
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 16
                        label.Text = role .. "\n" .. p.Name
                        label.Parent = billboard
                    end
                elseif billboard then
                    billboard:Destroy()
                end
            end
        end
    end
end

local function updateWeaponESP()
    local showKnife = Toggles.KnifeESP.Value
    local showGun = Toggles.GunESP.Value

    for _, obj in Workspace:GetDescendants() do
        if obj:IsA("Tool") then
            local oldKnife = obj:FindFirstChild("swift_knife_esp")
            local oldGun = obj:FindFirstChild("swift_gun_esp")
            local isKnife = obj:FindFirstChild("KnifeServer") ~= nil
            local isGun = obj:FindFirstChild("GunClient") ~= nil

            if showKnife and isKnife then
                if not oldKnife then
                    local h = Instance.new("Highlight")
                    h.Name = "swift_knife_esp"
                    h.FillColor = Color3.fromRGB(255, 80, 80)
                    h.FillTransparency = 0.3
                    h.OutlineColor = Color3.new(1, 1, 1)
                    h.OutlineTransparency = 0
                    h.Adornee = obj
                    h.Parent = obj
                end
            elseif oldKnife then
                oldKnife:Destroy()
            end

            if showGun and isGun then
                if not oldGun then
                    local h = Instance.new("Highlight")
                    h.Name = "swift_gun_esp"
                    h.FillColor = Color3.fromRGB(80, 120, 255)
                    h.FillTransparency = 0.3
                    h.OutlineColor = Color3.new(1, 1, 1)
                    h.OutlineTransparency = 0
                    h.Adornee = obj
                    h.Parent = obj
                end
            elseif oldGun then
                oldGun:Destroy()
            end
        end
    end
end

local function updateCoinESP()
    local show = Toggles.CoinESP.Value
    for _, coin in CollectionService:GetTagged("CoinVisual") do
        local existing = coin:FindFirstChild("swift_coin_esp")
        if show and not coin:GetAttribute("Delete") then
            if not existing then
                local part = coin:FindFirstChildWhichIsA("BasePart")
                if part then
                    local h = Instance.new("Highlight")
                    h.Name = "swift_coin_esp"
                    h.FillColor = Color3.fromRGB(255, 220, 50)
                    h.FillTransparency = 0.2
                    h.OutlineColor = Color3.fromRGB(255, 220, 50)
                    h.OutlineTransparency = 0
                    h.Adornee = part
                    h.Parent = part
                end
            end
        elseif existing then
            existing:Destroy()
        end
    end
end

connect("ESPUpdate", RunService.Heartbeat:Connect(function()
    pcall(updateESP)
    pcall(updateWeaponESP)
    pcall(updateCoinESP)
end))

local function refreshLabels()
    local role = getRole(LocalPlayer)
    RoleLabel:SetText("Role: " .. (role or "Unknown"))
    local m = getByRole("Murderer")
    local s = getByRole("Sheriff")
    MurdererLabel:SetText("Murderer: " .. (m and m.Name or "-"))
    SheriffLabel:SetText("Sheriff: " .. (s and s.Name or "-"))
end

GameplayRemotes.PlayerDataChanged.OnClientEvent:Connect(function()
    task.wait(0.1)
    refreshLabels()
end)

refreshLabels()

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = Library.ShowCustomCursor,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

Players.PlayerAdded:Connect(function()
    task.wait(0.2)
    refreshLabels()
end)

Library:OnUnload(function()
    for name, conn in Connections do
        conn:Disconnect()
    end
    Connections = {}
    for _, p in Players:GetPlayers() do
        if p.Character then
            for _, old in p.Character:GetDescendants() do
                if old.Name:find("swift_") then
                    old:Destroy()
                end
            end
        end
    end
end)

Library:Notify({
    Title = "swift",
    Description = "MM2 loaded! RightShift to toggle menu.",
    Time = 4,
})