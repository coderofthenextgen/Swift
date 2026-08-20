local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace = cloneref(game:GetService("Workspace"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local Lighting = cloneref(game:GetService("Lighting"))

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "swift - murder mystery 2",
    Footer = "place: 142823291",
    NotifySide = "Right",
    ShowCustomCursor = true,
    AlwaysOnTop = true,
    Center = true,
    Size = UDim2.new(0, 500, 0, 350),
})

local Tabs = {
    Main = Window:AddTab("Main", "crosshair"),
    Player = Window:AddTab("Player", "user"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Misc = Window:AddTab("Misc", "settings"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local function getRole(player)
    if player == LocalPlayer then
        local success, role = pcall(function()
            return player:GetAttribute("Role")
        end)
        if success and role then return role end
    end
    local success, role = pcall(function()
        return player:GetAttribute("Role")
    end)
    if success and role then return role end
    return nil
end

local function get murderer()
    for _, player in Players:GetPlayers() do
        if getRole(player) == "Murderer" then
            return player
        end
    end
    return nil
end

local function get sheriff()
    for _, player in Players:GetPlayers() do
        if getRole(player) == "Sheriff" then
            return player
        end
    end
    return nil
end

local function getCharacterParts(player)
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hrp, hum, char
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

local MainGroup = Tabs.Main:AddLeftGroupbox("Roles", "crosshair")
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Player", "user")
local VisualGroup = Tabs.Visuals:AddLeftGroupbox("Visuals", "eye")
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Misc", "settings")

MainGroup:AddLabel("Role: Loading..."):AddTag("RoleLabel")

MainGroup:AddButton({
    Text = "Refresh Roles",
    Func = function()
        local role = getRole(LocalPlayer)
        Options.RoleLabel:SetText("Role: " .. (role or "Unknown"))
    end,
})

MainGroup:AddDivider()

MainGroup:AddToggle("AutoPickupGun", {
    Text = "Auto Pickup Gun",
    Default = false,
    Tooltip = "Automatically picks up the sheriff gun when dropped",
})

MainGroup:AddToggle("AutoShootMurderer", {
    Text = "Auto Shoot Murderer",
    Default = false,
    Tooltip = "Auto aims and shoots the murderer if you are sheriff",
})

MainGroup:AddToggle("ShowRoles", {
    Text = "Show All Roles",
    Default = false,
    Tooltip = "Shows what role each player has",
})

MainGroup:AddButton({
    Text = "Copy Murderer Name",
    Func = function()
        local m = murderer
        if m then
            if setclipboard then
                setclipboard(m.Name)
            end
            Library:Notify({
                Title = "swift",
                Description = "Copied: " .. m.Name,
                Time = 3,
            })
        else
            Library:Notify({
                Title = "swift",
                Description = "No murderer found",
                Time = 3,
            })
        end
    end,
})

MainGroup:AddButton({
    Text = "Copy Sheriff Name",
    Func = function()
        local s = sheriff
        if s then
            if setclipboard then
                setclipboard(s.Name)
            end
            Library:Notify({
                Title = "swift",
                Description = "Copied: " .. s.Name,
                Time = 3,
            })
        else
            Library:Notify({
                Title = "swift",
                Description = "No sheriff found",
                Time = 3,
            })
        end
    end,
})

PlayerGroup:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 0,

    Callback = function(Value)
        local hrp, hum = getCharacterParts(LocalPlayer)
        if hum then hum.WalkSpeed = Value end
    end,
})

PlayerGroup:AddSlider("JumpPower", {
    Text = "Jump Power",
    Default = 50,
    Min = 50,
    Max = 300,
    Rounding = 0,

    Callback = function(Value)
        local hrp, hum = getCharacterParts(LocalPlayer)
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = Value
        end
    end,
})

PlayerGroup:AddSlider("HipHeight", {
    Text = "Hip Height",
    Default = 0,
    Min = 0,
    Max = 50,
    Rounding = 1,

    Callback = function(Value)
        local hrp, hum = getCharacterParts(LocalPlayer)
        if hum then hum.HipHeight = Value end
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
    Tooltip = "Jump forever",
})

PlayerGroup:AddToggle("GodMode", {
    Text = "God Mode",
    Default = false,
    Tooltip = "Makes you harder to kill",
})

PlayerGroup:AddButton({
    Text = "Teleport to Sheriff",
    Func = function()
        local s = sheriff
        if s then
            local hrp, _ = getCharacterParts(s)
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myHrp then
                myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 5)
            end
        end
    end,
})

PlayerGroup:AddButton({
    Text = "Teleport to Murderer",
    Func = function()
        local m = murderer
        if m then
            local hrp, _ = getCharacterParts(m)
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myHrp then
                myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 5)
            end
        end
    end,
})

VisualGroup:AddToggle("MurdererESP", {
    Text = "Murderer ESP",
    Default = false,
    Highlights the murderer with a red glow",
})

VisualGroup:AddToggle("SheriffESP", {
    Text = "Sheriff ESP",
    Default = false,
    Tooltip = "Highlights the sheriff with a blue glow",
})

VisualGroup:AddToggle("KnifeESP", {
    Text = "Knife ESP",
    Default = false,
    Tooltip = "Shows where the knife is",
})

VisualGroup:AddToggle("GunESP", {
    Text = "Gun ESP",
    Default = false,
    Tooltip = "Shows where the gun is",
})

VisualGroup:AddToggle("FullBright", {
    Text = "Full Bright",
    Default = false,
    Tooltip = "Makes everything bright",
})

VisualGroup:AddToggle("NoFog", {
    Text = "No Fog",
    Default = false,
    Tooltip = "Removes all fog",
})

VisualGroup:AddToggle("ThirdPerson", {
    Text = "Third Person",
    Default = false,
    Tooltip = "Enables third person view",
})

VisualGroup:AddSlider("ThirdPersonDist", {
    Text = "Third Person Distance",
    Default = 15,
    Min = 5,
    Max = 50,
    Rounding = 0,
})

VisualGroup:AddToggle("NameTag", {
    Text = "Show Name Tags",
    Default = false,
    Tooltip = "Shows player name tags above heads",
})

MiscGroup:AddToggle("AntiAFK", {
    Text = "Anti AFK",
    Default = false,
    Tooltip = "Prevents being kicked for idling",
})

MiscGroup:AddToggle("AutoRejoin", {
    Text = "Auto Rejoin",
    Default = false,
    Tooltip = "Rejoins if disconnected",
})

MiscGroup:AddButton({
    Text = "Rejoin Server",
    Func = function()
        local ts = cloneref(game:GetService("TeleportService"))
        ts:Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscGroup:AddButton({
    Text = "Server Hop",
    Func = function()
        local ts = cloneref(game:GetService("TeleportService"))
        local HttpService = cloneref(game:GetService("HttpService"))
        local servers = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(servers)
        if data and data.data then
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
    Text = "Copy Server ID",
    Func = function()
        if setclipboard then
            setclipboard(game.JobId)
        end
        Library:Notify({
            Title = "swift",
            Description = "Server ID copied!",
            Time = 3,
        })
    end,
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
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end))
    else
        disconnect("InfiniteJump")
    end
end)

Toggles.AntiAFK:OnChanged(function()
    if Toggles.AntiAFK.Value then
        connect("AntiAFK", RunService.Heartbeat:Connect(function()
            VirtualUser = cloneref(game:GetService("VirtualUser"))
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end))
    else
        disconnect("AntiAFK")
    end
end)

Toggles.AutoRejoin:OnChanged(function()
    if Toggles.AutoRejoin.Value then
        connect("AutoRejoin", Players.LocalPlayer.CharacterRemoving:Connect(function()
            task.wait(5)
            local ts = cloneref(game:GetService("TeleportService"))
            ts:Teleport(game.PlaceId, LocalPlayer)
        end))
    else
        disconnect("AutoRejoin")
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

Toggles.ThirdPerson:OnChanged(function()
    if Toggles.ThirdPerson.Value then
        LocalPlayer.CameraMinZoomDistance = 1
        LocalPlayer.CameraMaxZoomDistance = Options.ThirdPersonDist.Value
    else
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 0.5
    end
end)

Toggles.MurdererESP:OnChanged(function()
    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character then
            local existing = player.Character:FindFirstChild("swift_esp_murderer")
            if existing then existing:Destroy() end
            if Toggles.MurdererESP.Value and getRole(player) == "Murderer" then
                local highlight = Instance.new("Highlight")
                highlight.Name = "swift_esp_murderer"
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineTransparency = 0
                highlight.Adornee = player.Character
                highlight.Parent = player.Character
            end
        end
    end
end)

Toggles.SheriffESP:OnChanged(function()
    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character then
            local existing = player.Character:FindFirstChild("swift_esp_sheriff")
            if existing then existing:Destroy() end
            if Toggles.SheriffESP.Value and getRole(player) == "Sheriff" then
                local highlight = Instance.new("Highlight")
                highlight.Name = "swift_esp_sheriff"
                highlight.FillColor = Color3.fromRGB(0, 100, 255)
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.fromRGB(0, 100, 255)
                highlight.OutlineTransparency = 0
                highlight.Adornee = player.Character
                highlight.Parent = player.Character
            end
        end
    end
end)

Toggles.ShowRoles:OnChanged(function()
    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character then
            local existing = player.Character:FindFirstChild("swift_role_billboard")
            if existing then existing:Destroy() end
            if Toggles.ShowRoles.Value then
                local role = getRole(player)
                if role then
                    local head = player.Character:FindFirstChild("Head")
                    if head then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "swift_role_billboard"
                        billboard.Size = UDim2.new(0, 200, 0, 50)
                        billboard.StudsOffset = Vector3.new(0, 3, 0)
                        billboard.AlwaysOnTop = true
                        billboard.Adornee = head
                        billboard.Parent = player.Character

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.TextColor3 = role == "Murderer" and Color3.fromRGB(255, 0, 0) or role == "Sheriff" and Color3.fromRGB(0, 100, 255) or Color3.fromRGB(0, 255, 0)
                        label.TextStrokeTransparency = 0
                        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 16
                        label.Text = role
                        label.Parent = billboard
                    end
                end
            end
        end
    end
end)

Toggles.NameTag:OnChanged(function()
    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local existing = head:FindFirstChild("swift_nametag")
                if existing then existing:Destroy() end
                if Toggles.NameTag.Value then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "swift_nametag"
                    billboard.Size = UDim2.new(0, 200, 0, 30)
                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Adornee = head
                    billboard.Parent = head

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                    label.TextStrokeTransparency = 0
                    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 14
                    label.Text = player.Name
                    label.Parent = billboard
                end
            end
        end
    end
end)

Toggles.KnifeESP:OnChanged(function()
    if Toggles.KnifeESP.Value then
        connect("KnifeESP", RunService.Heartbeat:Connect(function()
            for _, obj in Workspace:GetDescendants() do
                if obj:IsA("Tool") and obj.Name:lower():find("knife") then
                    local existing = obj:FindFirstChild("swift_knife_esp")
                    if not existing then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "swift_knife_esp"
                        highlight.FillColor = Color3.fromRGB(255, 0, 0)
                        highlight.FillTransparency = 0.3
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.OutlineTransparency = 0
                        highlight.Parent = obj
                    end
                end
            end
        end))
    else
        disconnect("KnifeESP")
        for _, obj in Workspace:GetDescendants() do
            if obj:IsA("Tool") and obj.Name:lower():find("knife") then
                local existing = obj:FindFirstChild("swift_knife_esp")
                if existing then existing:Destroy() end
            end
        end
    end
end)

Toggles.GunESP:OnChanged(function()
    if Toggles.GunESP.Value then
        connect("GunESP", RunService.Heartbeat:Connect(function()
            for _, obj in Workspace:GetDescendants() do
                if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("revolver") or obj.Name:lower():find("pistol")) then
                    local existing = obj:FindFirstChild("swift_gun_esp")
                    if not existing then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "swift_gun_esp"
                        highlight.FillColor = Color3.fromRGB(0, 100, 255)
                        highlight.FillTransparency = 0.3
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.OutlineTransparency = 0
                        highlight.Parent = obj
                    end
                end
            end
        end))
    else
        disconnect("GunESP")
        for _, obj in Workspace:GetDescendants() do
            if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("revolver") or obj.Name:lower():find("pistol")) then
                local existing = obj:FindFirstChild("swift_gun_esp")
                if existing then existing:Destroy() end
            end
        end
    end
end)

Toggles.AutoPickupGun:OnChanged(function()
    if Toggles.AutoPickupGun.Value then
        connect("AutoPickupGun", Workspace.DescendantAdded:Connect(function(obj)
            task.wait(0.1)
            if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("revolver") or obj.Name:lower():find("pistol")) then
                local hrp, _ = getCharacterParts(LocalPlayer)
                if hrp then
                    local toolPart = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
                    if toolPart then
                        local dist = (toolPart.Position - hrp.Position).Magnitude
                        if dist < 15 then
                            firetouchinterest(hrp, toolPart, 0)
                            firetouchinterest(hrp, toolPart, 1)
                        end
                    end
                end
            end
        end))
    else
        disconnect("AutoPickupGun")
    end
end)

Toggles.AutoShootMurderer:OnChanged(function()
    if Toggles.AutoShootMurderer.Value then
        connect("AutoShoot", RunService.Heartbeat:Connect(function()
            local role = getRole(LocalPlayer)
            if role ~= "Sheriff" then return end
            local m = murderer
            if not m then return end
            local mHrp, _ = getCharacterParts(m)
            local myHrp, myHum = getCharacterParts(LocalPlayer)
            if not mHrp or not myHrp or not myHum then return end
            local dist = (mHrp.Position - myHrp.Position).Magnitude
            if dist < 60 then
                local dir = (mHrp.Position - myHrp.Position).Unit
                myHrp.CFrame = CFrame.new(myHrp.Position, myHrp.Position + dir)
                local mouse = LocalPlayer:GetMouse()
                if mouse then
                    mouse.Hit = mHrp.CFrame
                    mouse1click()
                end
            end
        end))
    else
        disconnect("AutoShoot")
    end
end)

Toggles.GodMode:OnChanged(function()
    if Toggles.GodMode.Value then
        connect("GodMode", RunService.Heartbeat:Connect(function()
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.Health = hum.MaxHealth
                end
            end
        end))
    else
        disconnect("GodMode")
    end
end)

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

Players.PlayerAdded:Connect(function(player)
    player:GetAttributeChangedSignal("Role"):Wait()
    if Toggles.ShowRoles.Value then
        Toggles.ShowRoles:SetValue(false)
        Toggles.ShowRoles:SetValue(true)
    end
    if Toggles.MurdererESP.Value then
        Toggles.MurdererESP:SetValue(false)
        Toggles.MurdererESP:SetValue(true)
    end
    if Toggles.SheriffESP.Value then
        Toggles.SheriffESP:SetValue(false)
        Toggles.SheriffESP:SetValue(true)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        for _, obj in player.Character:GetDescendants() do
            if obj.Name:find("swift_") then
                obj:Destroy()
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local role = getRole(LocalPlayer)
    Options.RoleLabel:SetText("Role: " .. (role or "Unknown"))
end)

Library:OnUnload(function()
    for name, conn in Connections do
        conn:Disconnect()
    end
    Connections = {}
end)

Library:Notify({
    Title = "swift",
    Description = "MM2 loaded! RightShift to toggle menu.",
    Time = 4,
})