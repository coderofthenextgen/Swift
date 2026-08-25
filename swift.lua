--!strict

local cloneref = cloneref or clonereference or function(o) return o end
local gethui = gethui or function() return cloneref(game:GetService("CoreGui")) end

local Mm2PlaceIds = { [142823291] = true }
local Mm2UniverseIds = { [66654135] = true, [6035872082] = false }

local PlaceId = game.PlaceId
local GameId = game.GameId
local UniverseOk = Mm2UniverseIds[GameId] ~= nil and Mm2UniverseIds[GameId] ~= false
local PlaceOk = Mm2PlaceIds[PlaceId] == true

if not (PlaceOk or UniverseOk) then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Swift - MM2 Only",
            Text = "This hub only works on Murder Mystery 2 [142823291].\nCurrent PlaceId: " .. tostring(PlaceId),
            Duration = 7,
        })
    end)
    warn("[Swift] Unsupported game. PlaceId=" .. tostring(PlaceId) .. " Universe=" .. tostring(GameId) .. " - Swift is MM2 exclusive.")
    return
end

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Workspace = cloneref(game:GetService("Workspace"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not game:IsLoaded() then game.Loaded:Wait() end

local WindUI
local okWind, resWind = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if okWind and resWind then
    WindUI = resWind
else
    local ok2, res2 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/swift-ui/main/UI.lua"))()
    end)
    if ok2 and res2 then
        WindUI = res2
        warn("[Swift] WindUI failed, using Swift-UI fallback")
    else
        error("[Swift] Failed to load UI library: " .. tostring(resWind))
    end
end

local function findRemote(name)
    local found = ReplicatedStorage:FindFirstChild(name, true)
    if found and found:IsA("RemoteEvent") then return found end
    for _, container in ipairs({ReplicatedStorage, ReplicatedStorage:FindFirstChild("ClientServices"), ReplicatedStorage:FindFirstChild("WeaponService")}) do
        if container then
            local c = container:FindFirstChild(name, true)
            if c and c:IsA("RemoteEvent") then return c end
        end
    end
    return nil
end

local function getCharacter(plr)
    return plr.Character
end

local function getRoot(plr)
    local c = getCharacter(plr)
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function hasTool(plr, toolName)
    local c = getCharacter(plr)
    if c and c:FindFirstChild(toolName) then return true end
    local bp = plr:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(toolName) then return true end
    return false
end

local function isAlive(plr)
    local c = getCharacter(plr)
    if not c then return false end
    local hum = c:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function getRole(plr)
    if not isAlive(plr) then return "Dead" end
    if hasTool(plr, "Knife") then return "Murderer" end
    if hasTool(plr, "Gun") or hasTool(plr, "Revolver") then return "Sheriff" end
    return "Innocent"
end

local function getDroppedGun()
    local drop = Workspace:FindFirstChild("GunDrop", true)
    if drop and drop:IsA("BasePart") then return drop end
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o.Name == "GunDrop" and o:IsA("BasePart") then return o end
        if o.Name == "Gun" and o:IsA("Tool") and o.Parent == Workspace then
            local h = o:FindFirstChild("Handle")
            if h and h:IsA("BasePart") then return h end
        end
    end
    return nil
end

local function worldToScreen(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), onScreen, v.Z
end

local function distanceFromPlayer(pos)
    local root = getRoot(LocalPlayer)
    if not root then return math.huge end
    return (root.Position - pos).Magnitude
end

local function getClosestToCursor(maxDist, aliveOnly)
    maxDist = maxDist or math.huge
    local mouse = UserInputService:GetMouseLocation()
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (not aliveOnly or isAlive(plr)) then
            local root = getRoot(plr)
            if root then
                local scr, onScreen = worldToScreen(root.Position)
                if onScreen then
                    local d = (mouse - scr).Magnitude
                    local w = distanceFromPlayer(root.Position)
                    if d < bestDist and w <= maxDist then
                        best, bestDist = plr, d
                    end
                end
            end
        end
    end
    return best
end

local Flags = {
    ESPEnabled = false,
    ESPBoxes = true,
    ESPNames = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPRoles = true,
    ESPTracers = false,
    ESPGunDrop = true,
    AutoTpGun = false,
    ESPRoleColors = true,
    ESPMaxDistance = 2000,
    ESPBoxColor = Color3.fromRGB(255, 255, 255),
    MurdererColor = Color3.fromRGB(255, 55, 55),
    SheriffColor = Color3.fromRGB(55, 130, 255),
    InnocentColor = Color3.fromRGB(255, 255, 255),
    HeroColor = Color3.fromRGB(255, 220, 55),

    KillAura = false,
    KillAuraRange = 18,
    KillAuraDelay = 0.22,
    KillAuraTargets = "All",
    ThrowAimbot = false,
    ThrowSilent = false,
    ThrowFOV = 500,

    GunAimbot = false,
    GunSilentAim = false,
    GunAimPart = "Head",
    GunFOV = 320,
    GunShowFOV = true,
    GunWallbang = false,
    GunAutoShoot = false,

    WalkSpeedEnabled = false,
    WalkSpeed = 16,
    JumpPowerEnabled = false,
    JumpPower = 50,
}

local Remotes = {
    KnifeStabbed = nil,
    KnifeThrown = nil,
    GunFired = nil,
    Aliases = {
        KnifeStabbed = {"KnifeStabbed", "StabKnife", "KnifeHit", "Slash"},
        KnifeThrown = {"KnifeThrown", "ThrowKnife", "KnifeThrow"},
        GunFired = {"GunFired", "ShootGun", "GunShoot", "FireGun", "GunShot"},
    }
}

local function resolveRemotes()
    for canonical, aliases in pairs(Remotes.Aliases) do
        for _, name in ipairs(aliases) do
            local r = findRemote(name)
            if r then
                Remotes[canonical] = r
                break
            end
        end
    end
    if not Remotes.GunFired then
        for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
            if inst:IsA("RemoteEvent") and inst.Name:lower():find("gun") and inst.Name:lower():find("fir") then
                Remotes.GunFired = inst
                break
            end
        end
    end
    local ws = ReplicatedStorage:FindFirstChild("ClientServices")
    if ws then
        local ws2 = ws:FindFirstChild("WeaponService")
        if ws2 then
            local gf = ws2:FindFirstChild("GunFired")
            if gf and gf:IsA("RemoteEvent") then Remotes.GunFired = gf end
        end
    end
    warn(string.format("[Swift] Remotes - Stab:%s Throw:%s Gun:%s",
        Remotes.KnifeStabbed and Remotes.KnifeStabbed:GetFullName() or "nil",
        Remotes.KnifeThrown and Remotes.KnifeThrown:GetFullName() or "nil",
        Remotes.GunFired and Remotes.GunFired:GetFullName() or "nil"
    ))
end

task.spawn(function()
    task.wait(2)
    resolveRemotes()
end)

local ESP = {
    Enabled = false,
    Container = nil,
    Highlights = {},
    Billboards = {},
    GunHighlight = nil,
    GunBillboard = nil,
    Conn = nil,
    Boxes = {},
}

local function ensureContainer()
    if ESP.Container and ESP.Container.Parent then return ESP.Container end
    local f = Instance.new("Folder")
    f.Name = "SwiftESP"
    f.Parent = gethui()
    ESP.Container = f
    return f
end

local function getRoleColor(role)
    if not Flags.ESPRoleColors then return Flags.ESPBoxColor end
    if role == "Murderer" then return Flags.MurdererColor end
    if role == "Sheriff" then return Flags.SheriffColor end
    if role == "Hero" then return Flags.HeroColor end
    return Flags.InnocentColor
end

local function createBillboard(plr)
    local bb = Instance.new("BillboardGui")
    bb.Name = "Swift_" .. plr.Name
    bb.Size = UDim2.fromOffset(200, 50)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = Flags.ESPMaxDistance
    bb.Enabled = true

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextStrokeTransparency = 0.2
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = plr.Name
    label.Parent = bb

    local distL = Instance.new("TextLabel")
    distL.Name = "Dist"
    distL.Size = UDim2.fromOffset(200, 12)
    distL.Position = UDim2.fromOffset(0, 38)
    distL.BackgroundTransparency = 1
    distL.Font = Enum.Font.Gotham
    distL.TextSize = 11
    distL.TextColor3 = Color3.fromRGB(200, 200, 200)
    distL.TextStrokeTransparency = 0.4
    distL.Text = ""
    distL.Parent = bb

    return bb
end

local function ensureESPForPlayer(plr)
    if plr == LocalPlayer then return end
    if ESP.Highlights[plr] and ESP.Highlights[plr].Parent then return end

    local char = plr.Character
    if not char then return end

    local hl = Instance.new("Highlight")
    hl.Name = "SwiftHL"
    hl.Adornee = char
    hl.FillTransparency = 1
    hl.OutlineTransparency = 1
    hl.FillColor = getRoleColor(getRole(plr))
    hl.OutlineColor = getRoleColor(getRole(plr))
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = ensureContainer()
    ESP.Highlights[plr] = hl

    local bb = createBillboard(plr)
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if root and root:IsA("BasePart") then
        bb.Adornee = root
        bb.Parent = ensureContainer()
        ESP.Billboards[plr] = bb
    end
end

local function removeESPForPlayer(plr)
    local hl = ESP.Highlights[plr]
    if hl then hl:Destroy() end
    ESP.Highlights[plr] = nil
    local bb = ESP.Billboards[plr]
    if bb then bb:Destroy() end
    ESP.Billboards[plr] = nil
end

local function updateESP()
    if not Flags.ESPEnabled then
        for _, hl in pairs(ESP.Highlights) do
            hl.FillTransparency = 1
            hl.OutlineTransparency = 1
        end
        for _, bb in pairs(ESP.Billboards) do bb.Enabled = false end
        if ESP.GunHighlight then ESP.GunHighlight.FillTransparency = 1; ESP.GunHighlight.OutlineTransparency = 1 end
        if ESP.GunBillboard then ESP.GunBillboard.Enabled = false end
        return
    end

    local localRoot = getRoot(LocalPlayer)
    local localPos = localRoot and localRoot.Position or Camera.CFrame.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        ensureESPForPlayer(plr)
        local hl = ESP.Highlights[plr]
        local bb = ESP.Billboards[plr]
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hl or not char or not root or not hum or hum.Health <= 0 then
            if hl then hl.FillTransparency = 1; hl.OutlineTransparency = 1 end
            if bb then bb.Enabled = false end
            continue
        end
        local role = getRole(plr)
        local dist = (localPos - root.Position).Magnitude
        if dist > Flags.ESPMaxDistance then
            hl.FillTransparency = 1; hl.OutlineTransparency = 1
            if bb then bb.Enabled = false end
            continue
        end

        local col = getRoleColor(role)
        hl.FillColor = col
        hl.OutlineColor = col
        hl.Adornee = char
        if Flags.ESPBoxes then
            hl.FillTransparency = (role == "Murderer" or role == "Sheriff") and 0.55 or 0.78
            hl.OutlineTransparency = 0
        else
            hl.FillTransparency = 1
            hl.OutlineTransparency = 1
        end
        if not Flags.ESPBoxes and Flags.ESPNames then
            hl.OutlineTransparency = 0.15
        end

        if bb then
            bb.Enabled = Flags.ESPNames or Flags.ESPDistance or Flags.ESPRoles or Flags.ESPHealth
            bb.Adornee = root
            local label = bb:FindFirstChild("Label")
            local distL = bb:FindFirstChild("Dist")
            if label then
                local parts = {}
                if Flags.ESPNames then table.insert(parts, plr.Name) end
                if Flags.ESPRoles then table.insert(parts, "[" .. role .. "]") end
                if Flags.ESPHealth and hum then table.insert(parts, math.floor(hum.Health) .. "HP") end
                label.Text = table.concat(parts, " ")
                label.TextColor3 = col
            end
            if distL then
                if Flags.ESPDistance then
                    distL.Text = string.format("%dm", math.floor(dist))
                    distL.Visible = true
                else
                    distL.Visible = false
                end
            end
            bb.StudsOffset = Vector3.new(0, 3.2, 0)
        end
    end

    if Flags.ESPGunDrop then
        local gunPart = getDroppedGun()
        if gunPart then
            if not ESP.GunHighlight or not ESP.GunHighlight.Parent then
                local hl = Instance.new("Highlight")
                hl.Name = "SwiftGun"
                hl.FillColor = Color3.fromRGB(255, 220, 40)
                hl.OutlineColor = Color3.fromRGB(255, 215, 0)
                hl.FillTransparency = 1
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = ensureContainer()
                ESP.GunHighlight = hl
            end
            ESP.GunHighlight.Adornee = gunPart
            ESP.GunHighlight.FillTransparency = 1
            ESP.GunHighlight.OutlineTransparency = 0
            if not ESP.GunBillboard or not ESP.GunBillboard.Parent then
                local bb = Instance.new("BillboardGui")
                bb.Name = "SwiftGunBB"
                bb.Size = UDim2.fromOffset(120, 22)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.Enabled = true
                local tl = Instance.new("TextLabel")
                tl.Size = UDim2.fromScale(1, 1)
                tl.BackgroundTransparency = 1
                tl.Text = "Gun Drop"
                tl.Font = Enum.Font.GothamBold
                tl.TextSize = 12
                tl.TextColor3 = Color3.fromRGB(255, 220, 40)
                tl.TextStrokeTransparency = 0.1
                tl.Parent = bb
                bb.Parent = ensureContainer()
                ESP.GunBillboard = bb
            end
            ESP.GunBillboard.Adornee = gunPart
            ESP.GunBillboard.Enabled = true
        else
            if ESP.GunHighlight then ESP.GunHighlight.FillTransparency = 1; ESP.GunHighlight.OutlineTransparency = 1 end
            if ESP.GunBillboard then ESP.GunBillboard.Enabled = false end
        end
    else
        if ESP.GunHighlight then ESP.GunHighlight.FillTransparency = 1; ESP.GunHighlight.OutlineTransparency = 1 end
        if ESP.GunBillboard then ESP.GunBillboard.Enabled = false end
    end
end

local function setESPEnabled(v)
    Flags.ESPEnabled = v
    if v then
        ensureContainer()
        for _, plr in ipairs(Players:GetPlayers()) do ensureESPForPlayer(plr) end
        if not ESP.Conn then
            ESP.Conn = RunService.RenderStepped:Connect(updateESP)
        end
    else
        updateESP()
        if ESP.Conn then
        end
    end
end

local function setAutoTpGun(v)
    Flags.AutoTpGun = v
    if v then
        getgenv()._swiftLastGunTp = 0
        task.spawn(function()
            while Flags.AutoTpGun do
                task.wait(0.25)
                if not Flags.AutoTpGun then break end
                if not isAlive(LocalPlayer) then continue end
                if hasTool(LocalPlayer, "Gun") or hasTool(LocalPlayer, "Revolver") then continue end
                local gunPart = getDroppedGun()
                if not gunPart then continue end
                local hrp = getRoot(LocalPlayer)
                if not hrp then continue end
                if tick() - (getgenv()._swiftLastGunTp or 0) < 2.5 then continue end
                getgenv()._swiftLastGunTp = tick()
                local startCF = hrp.CFrame
                hrp.CFrame = gunPart.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.35)
                task.wait(0.15)
                local hrp2 = getRoot(LocalPlayer)
                if hrp2 then hrp2.CFrame = startCF end
                pcall(function()
                    if Window.Notify or WindUI.Notify then
                        (Window.Notify or WindUI.Notify)({Title = "Swift - MM2", Content = "Gun grabbed - returned", Duration = 2})
                    end
                end)
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.6)
        if Flags.ESPEnabled then ensureESPForPlayer(plr) end
    end)
end)
Players.PlayerRemoving:Connect(removeESPForPlayer)
for _, plr in ipairs(Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function()
        task.wait(0.6)
        if Flags.ESPEnabled then ensureESPForPlayer(plr) end
    end)
end

local Tracers = { Lines = {}, Conn = nil }
local function ensureTracer(plr)
    if not (Drawing and Flags.ESPEnabled and Flags.ESPTracers) then return nil end
    if Tracers.Lines[plr] then return Tracers.Lines[plr] end
    local ok, line = pcall(function() return Drawing.new("Line") end)
    if not ok or not line then return nil end
    line.Visible = false
    line.Thickness = 1.5
    line.Transparency = 0.85
    Tracers.Lines[plr] = line
    return line
end

local function updateTracers()
    if not (Flags.ESPEnabled and Flags.ESPTracers and Drawing) then
        for _, l in pairs(Tracers.Lines) do pcall(function() l.Visible = false end) end
        return
    end
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local root = getRoot(plr)
        local line = ensureTracer(plr)
        if not root or not line then
            if line then line.Visible = false end
            continue
        end
        local pos, onScreen = worldToScreen(root.Position)
        local role = getRole(plr)
        if onScreen and isAlive(plr) and distanceFromPlayer(root.Position) <= Flags.ESPMaxDistance then
            line.Visible = true
            line.From = viewportCenter
            line.To = pos
            line.Color = getRoleColor(role)
        else
            line.Visible = false
        end
    end
end

if Drawing then
    Tracers.Conn = RunService.RenderStepped:Connect(updateTracers)
end

local Combat = {
    KillAuraConn = nil,
    GunHooked = false,
    FOVCircle = nil,
    FOVConn = nil,
    LastStab = 0,
}

local function fireStab(target)
    local remote = Remotes.KnifeStabbed
    if not remote then
        resolveRemotes()
        remote = Remotes.KnifeStabbed
        if not remote then return false end
    end
    local ok = pcall(function()
        remote:FireServer()
    end)
    if not ok then
        pcall(function()
            local root = target and getRoot(target)
            if root then remote:FireServer(root.Position) end
        end)
    end
    return ok
end

local function fireThrow(targetCF)
    local remote = Remotes.KnifeThrown
    if not remote then resolveRemotes(); remote = Remotes.KnifeThrown end
    if not remote then return end
    local origin = (getRoot(LocalPlayer) and getRoot(LocalPlayer).CFrame) or Camera.CFrame
    pcall(function() remote:FireServer(targetCF) end)
    pcall(function() remote:FireServer(origin, targetCF) end)
    pcall(function() remote:FireServer(targetCF.Position) end)
end

local function fireGun(targetCF, hitPos)
    local remote = Remotes.GunFired
    if not remote then resolveRemotes(); remote = Remotes.GunFired end
    if not remote then return end
    pcall(function() remote:FireServer(targetCF) end)
    pcall(function() remote:FireServer(targetCF, targetCF) end)
    pcall(function() remote:FireServer(targetCF.Position, targetCF) end)
    if hitPos then
        pcall(function() remote:FireServer(hitPos, targetCF) end)
    end
end

local function shouldAuraTarget(plr)
    if plr == LocalPlayer or not isAlive(plr) then return false end
    local mode = Flags.KillAuraTargets
    if mode == "All" then return true end
    local role = getRole(plr)
    if mode == "Murderer" then return role == "Murderer" end
    if mode == "Sheriff" then return role == "Sheriff" end
    if mode == "Innocent" then return role == "Innocent" end
    return true
end

local function getAuraTargets()
    local out = {}
    local myRoot = getRoot(LocalPlayer)
    if not myRoot then return out end
    for _, plr in ipairs(Players:GetPlayers()) do
        if shouldAuraTarget(plr) then
            local r = getRoot(plr)
            if r and (r.Position - myRoot.Position).Magnitude <= Flags.KillAuraRange then
                table.insert(out, plr)
            end
        end
    end
    return out
end

local function hookGunFired()
    if Combat.GunHooked then return end
    Combat.GunHooked = true
    local mt = getrawmetatable and getrawmetatable(game)
    local nc = mt and mt.__namecall
    if mt and nc and setreadonly and newcclosure then
        local old
        old = hookmetamethod and hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or ""
            local args = {...}
            if method == "FireServer" and Flags.GunSilentAim and self == Remotes.GunFired then
                local target = getClosestToCursor(Flags.GunFOV, true)
                if target then
                    local partName = Flags.GunAimPart
                    local char = target.Character
                    local aimPart = char and char:FindFirstChild(partName) or getRoot(target)
                    if aimPart and aimPart:IsA("BasePart") then
                        local cf = CFrame.new(aimPart.Position)
                        for i, v in ipairs(args) do
                            if typeof(v) == "CFrame" then args[i] = cf end
                            if typeof(v) == "Vector3" then args[i] = aimPart.Position end
                        end
                        local hasCF = false
                        for _, v in ipairs(args) do if typeof(v) == "CFrame" then hasCF = true break end end
                        if not hasCF then table.insert(args, 1, cf) end
                        return old(self, unpack(args))
                    end
                end
            end
            return old(self, ...)
        end))
        if not old then Combat.GunHooked = false end
    else
        warn("[Swift] Executor missing hookmetamethod - GunSilentAim will use manual Fire")
    end
end

local function setKillAura(v)
    Flags.KillAura = v
    if v then
        if Combat.KillAuraConn then Combat.KillAuraConn:Disconnect() end
        local last = 0
        Combat.KillAuraConn = RunService.Heartbeat:Connect(function()
            if not Flags.KillAura then return end
            if tick() - last < Flags.KillAuraDelay then return end
            if not hasTool(LocalPlayer, "Knife") then return end
            local targets = getAuraTargets()
            if #targets > 0 then
                last = tick()
                fireStab(targets[1])
            end
        end)
    else
        if Combat.KillAuraConn then Combat.KillAuraConn:Disconnect(); Combat.KillAuraConn = nil end
    end
end

local ThrowConn = nil
local function setThrowAimbot(v)
    Flags.ThrowAimbot = v
    if v then
        if ThrowConn then ThrowConn:Disconnect() end
        ThrowConn = UserInputService.InputBegan:Connect(function(inp, gpe)
            if gpe then return end
            if not Flags.ThrowAimbot then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.KeyCode ~= Enum.KeyCode.ButtonR2 then return end
            if not hasTool(LocalPlayer, "Knife") then return end
            local target = getClosestToCursor(Flags.ThrowFOV, true)
            if target then
                local root = getRoot(target)
                if root then
                    if Flags.ThrowSilent then
                        fireThrow(CFrame.new(root.Position))
                        return
                    else
                        task.wait(0.06)
                    end
                end
            end
        end)
    else
        if ThrowConn then ThrowConn:Disconnect(); ThrowConn = nil end
    end
end

local function ensureFOVCircle()
    if not Drawing then return end
    if Combat.FOVCircle then return Combat.FOVCircle end
    local ok, c = pcall(function() return Drawing.new("Circle") end)
    if not ok or not c then return nil end
    c.Visible = false
    c.NumSides = 64
    c.Thickness = 1.5
    c.Transparency = 0.75
    c.Filled = false
    c.Color = Color3.fromRGB(124, 92, 255)
    c.Radius = Flags.GunFOV
    Combat.FOVCircle = c
    return c
end

local function updateFOVCircle()
    local c = ensureFOVCircle()
    if not c then return end
    local show = Flags.GunShowFOV and (Flags.GunAimbot or Flags.GunSilentAim)
    c.Visible = show
    if not show then return end
    c.Position = UserInputService:GetMouseLocation()
    c.Radius = Flags.GunFOV
    c.Color = Flags.GunSilentAim and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(124, 92, 255)
end

if Drawing then
    Combat.FOVConn = RunService.RenderStepped:Connect(updateFOVCircle)
end

local AimbotConn = nil
local Aiming = false
UserInputService.InputBegan:Connect(function(inp, gpe)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then Aiming = true end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then Aiming = false end
end)

local function runGunAimbot()
    if not Flags.GunAimbot then return end
    if not Aiming then return end
    if not hasTool(LocalPlayer, "Gun") and not hasTool(LocalPlayer, "Revolver") then return end
    local target = getClosestToCursor(Flags.GunFOV, true)
    if not target then return end
    local partName = Flags.GunAimPart
    local part = target.Character and target.Character:FindFirstChild(partName) or getRoot(target)
    if not part or not part:IsA("BasePart") then return end
    local camPos = Camera.CFrame.Position
    local targetPos = part.Position
    if not Flags.GunWallbang then
        local ray = Workspace:Raycast(camPos, targetPos - camPos, RaycastParams.new())
        if ray and ray.Instance and not ray.Instance:IsDescendantOf(target.Character) then
            return
        end
    end
    local cf = CFrame.new(camPos, targetPos)
    Camera.CFrame = Camera.CFrame:Lerp(cf, 0.42)

    if Flags.GunAutoShoot then
        local remote = Remotes.GunFired
        if remote then
            fireGun(CFrame.new(targetPos), targetPos)
        end
    end
end

RunService.RenderStepped:Connect(runGunAimbot)

local Window
local okWin, winRes = pcall(function()
    if WindUI.CreateWindow then
        local w = WindUI:CreateWindow({
            Title = "Swift - MM2",
            Author = "coderofthenextgen",
            Icon = "sparkles",
            Folder = "SwiftMM2",
            Size = UDim2.fromOffset(580, 560),
            Transparent = true,
            Theme = "Dark",
            Resizable = true,
            SideBarWidth = 185,
            NewElements = true,
            HideSearchBar = false,
            HasOutline = true,
            BackgroundImageTransparency = 0.88,
            OpenButton = {
                Title = "Swift - MM2",
                CornerRadius = UDim.new(1, 0),
                StrokeThickness = 2,
                Enabled = true,
                Draggable = true,
                OnlyMobile = false,
                Scale = 0.65,
                Color = ColorSequence.new(Color3.fromHex("#a855f7"), Color3.fromHex("#ec4899")),
            },
            Topbar = {
                Height = 42,
                ButtonsType = "Mac",
            },
        })
        pcall(function()
            w:Tag({Title = "v1.0.0", Color = Color3.fromHex("#a855f7")})
            w:Tag({Title = "RightShift", Icon = "keyboard", Color = Color3.fromHex("#1a1a1a")})
        end)
        pcall(function()
            if w.SetToggleKey then w:SetToggleKey(Enum.KeyCode.RightShift) end
        end)
        return w
    else
        return WindUI:CreateWindow({
            Title = "Swift - MM2",
            Footer = "Swift - MM2",
            NotifySide = "Right",
            ShowCustomCursor = true,
            Center = true,
            Size = UDim2.fromOffset(620, 520),
        })
    end
end)

if not okWin or not winRes then
    error("[Swift] Window creation failed: " .. tostring(winRes))
end
Window = winRes
pcall(function()
    if Window.SetToggleKey then Window:SetToggleKey(Enum.KeyCode.RightShift) end
end)

local function addTab(opts)
    if Window.Tab then
        return Window:Tab(opts)
    elseif Window.AddTab then
        return Window:AddTab(opts.Title or opts.Name, opts.Icon)
    elseif Window.CreateTab then
        return Window:CreateTab(opts)
    else
        error("No Tab API")
    end
end

local function addSection(tab, title)
    if not tab then return nil end
    if tab.Section then return tab:Section({Title = title}) end
    if tab.CreateSection then return tab:CreateSection(title) end
    return tab
end

local function makeToggle(tabOrSec, opts)
    if not tabOrSec then return nil end
    if tabOrSec.Toggle then return tabOrSec:Toggle(opts) end
    if tabOrSec.CreateToggle then return tabOrSec:CreateToggle(opts.Title or opts.Name, opts.Callback, opts.Value) end
    if tabOrSec.AddToggle then return tabOrSec:AddToggle(opts.Title, opts) end
    return nil
end

local function makeSlider(tabOrSec, opts)
    if not tabOrSec then return nil end
    if tabOrSec.Slider then return tabOrSec:Slider(opts) end
    if tabOrSec.CreateSlider then return tabOrSec:CreateSlider(opts.Title, opts.Min, opts.Max, opts.Value, opts.Callback) end
    return nil
end

local function makeDropdown(tabOrSec, opts)
    if not tabOrSec then return nil end
    if tabOrSec.Dropdown then return tabOrSec:Dropdown(opts) end
    if tabOrSec.CreateDropdown then return tabOrSec:CreateDropdown(opts.Title, opts.Values or opts.Options, opts.Callback) end
    return nil
end

local function makeButton(tabOrSec, opts)
    if not tabOrSec then return nil end
    if tabOrSec.Button then return tabOrSec:Button(opts) end
    if tabOrSec.CreateButton then return tabOrSec:CreateButton(opts.Title, opts.Callback) end
    return nil
end

local HomeTab = addTab({Title = "Home", Icon = "house", IconColor = Color3.fromHex("#a855f7")})
local CombatTab = addTab({Title = "Combat", Icon = "swords", IconColor = Color3.fromHex("#ef4444")})
local VisualsTab = addTab({Title = "Visuals", Icon = "eye", IconColor = Color3.fromHex("#06b6d4")})
local PlayerTab = addTab({Title = "Player", Icon = "user", IconColor = Color3.fromHex("#22c55e")})
local SettingsTab = addTab({Title = "Settings", Icon = "settings", IconColor = Color3.fromHex("#64748b")})

do
    local s = addSection(HomeTab, "Swift - MM2")
    pcall(function()
        if s.Paragraph then
            s:Paragraph({
                Title = "Swift - MM2 - Modern",
                Desc = string.format("PlaceId %d  -  Universe %d\nAcrylic Dark - Gradient OpenButton - RightShift toggle.\nRemotes auto-resolved on injection.", PlaceId, GameId),
            })
        end
    end)
    if s.Paragraph then
        s:Paragraph({
            Title = "Locked to MM2",
            Desc = "WindUI NewElements + Mac Topbar + SearchBar. Press RightShift to toggle UI.",
        })
    elseif s.CreateParagraph then
        s:CreateParagraph({Title = "Locked to MM2", Content = "PlaceId " .. PlaceId})
    end
    if s.Divider then s:Divider() end
    if s.Button then
        s:Button({
            Title = "Copy Discord",
            Desc = "github.com/coderofthenextgen/Swift",
            Icon = "link",
            Variant = "Primary",
            Callback = function()
                pcall(setclipboard, "https://github.com/coderofthenextgen/Swift")
                if Window.Notify or WindUI.Notify then
                    local n = Window.Notify or WindUI.Notify
                    pcall(n, {Title = "Swift", Content = "Copied repo link", Duration = 2})
                end
            end
        })
    end
    if s.Space then s:Space({Height = 12}) end
    local function statusRow()
        local alive = isAlive(LocalPlayer)
        local role = getRole(LocalPlayer)
        local gunPart = getDroppedGun()
        return string.format("You: %s [%s]  -  GunDrop: %s", alive and "Alive" or "Dead", role, gunPart and "Available" or "Taken")
    end
    if s.Label then
        local lbl = s:Label({Title = statusRow()})
        task.spawn(function()
            while Window do
                task.wait(1.2)
                pcall(function() lbl:Set(statusRow()) end)
            end
        end)
    end
    if s.Space then s:Space() end
    pcall(function()
        if s.Keybind then
            s:Keybind({
                Title = "Quick Toggle",
                Desc = "RightShift - native WindUI bind",
                Value = "RightShift",
                Callback = function(v)
                    pcall(function() if Window.SetToggleKey then Window:SetToggleKey(Enum.KeyCode[v]) end end)
                end,
            })
        end
    end)
end

do
    local knifeSec = addSection(CombatTab, "Knife - Stab & Throw")
    knifeSec:Toggle({
        Title = "Kill Aura",
        Desc = "Auto-stabs nearby players (uses KnifeStabbed remote, 0.22s delay)",
        Value = Flags.KillAura,
        Callback = function(v) setKillAura(v) end,
    })
    knifeSec:Slider({Title = "Kill Aura Range", Value = {Min = 8, Max = 28, Default = Flags.KillAuraRange}, Callback = function(v) Flags.KillAuraRange = v end})
    knifeSec:Slider({Title = "Kill Aura Delay", Step = 0.02, Value = {Min = 0.08, Max = 0.9, Default = Flags.KillAuraDelay}, Callback = function(v) Flags.KillAuraDelay = v end})
    knifeSec:Dropdown({
        Title = "Aura Targets",
        Values = {"All", "Murderer", "Sheriff", "Innocent"},
        Value = Flags.KillAuraTargets,
        Callback = function(v) Flags.KillAuraTargets = v end,
    })
    knifeSec:Toggle({
        Title = "Throw Aimbot",
        Desc = "Closest to cursor within FOV when clicking with Knife",
        Value = Flags.ThrowAimbot,
        Callback = function(v) setThrowAimbot(v) end,
    })
    knifeSec:Toggle({
        Title = "Silent Throw (no arc)",
        Desc = "Fires KnifeThrown remote directly to target (bypasses trajectory)",
        Value = Flags.ThrowSilent,
        Callback = function(v) Flags.ThrowSilent = v end,
    })
    knifeSec:Slider({Title = "Throw FOV", Value = {Min = 80, Max = 900, Default = Flags.ThrowFOV}, Callback = function(v) Flags.ThrowFOV = v end})

    local gunSec = addSection(CombatTab, "Gun - Aimbot & Silent")
    gunSec:Toggle({
        Title = "Gun Aimbot (Hold RMB)",
        Desc = "Camera locks to closest in FOV. Hold right click.",
        Value = Flags.GunAimbot,
        Callback = function(v) Flags.GunAimbot = v end,
    })
    gunSec:Toggle({
        Title = "Gun Silent Aim",
        Desc = "Hooks GunFired:FireServer to redirect to closest (from dump: GunClient @69)",
        Value = Flags.GunSilentAim,
        Callback = function(v)
            Flags.GunSilentAim = v
            if v then hookGunFired() end
        end,
    })
    gunSec:Dropdown({
        Title = "Aim Part",
        Values = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"},
        Value = Flags.GunAimPart,
        Callback = function(v) Flags.GunAimPart = v end,
    })
    gunSec:Slider({Title = "Gun FOV", Value = {Min = 60, Max = 900, Default = Flags.GunFOV}, Callback = function(v) Flags.GunFOV = v; updateFOVCircle() end})
    gunSec:Toggle({
        Title = "Show FOV Circle",
        Value = Flags.GunShowFOV,
        Callback = function(v) Flags.GunShowFOV = v; updateFOVCircle() end,
    })
    gunSec:Toggle({
        Title = "Wallbang (ignore walls)",
        Value = Flags.GunWallbang,
        Callback = function(v) Flags.GunWallbang = v end,
    })
    gunSec:Toggle({
        Title = "Auto Shoot on Lock",
        Desc = "Fires GunFired remote automatically when aimbot locks",
        Value = Flags.GunAutoShoot,
        Callback = function(v) Flags.GunAutoShoot = v end,
    })
    gunSec:Button({
        Title = "Re-resolve Remotes",
        Callback = function()
            resolveRemotes()
            pcall(function()
                (Window.Notify or WindUI.Notify)({Title = "Swift", Content = "Remotes rescanned", Duration = 2})
            end)
        end
    })
end

do
    local espSec = addSection(VisualsTab, "ESP - Roles & Highlights")
    espSec:Toggle({
        Title = "Enable ESP",
        Desc = "Highlights + Billboard name/role/dist (role colors)",
        Value = Flags.ESPEnabled,
        Callback = function(v) setESPEnabled(v) end,
    })
    espSec:Toggle({Title = "Boxes (Highlight Fill)", Value = Flags.ESPBoxes, Callback = function(v) Flags.ESPBoxes = v end})
    espSec:Toggle({Title = "Names", Value = Flags.ESPNames, Callback = function(v) Flags.ESPNames = v end})
    espSec:Toggle({Title = "Roles [Murderer/Sheriff]", Value = Flags.ESPRoles, Callback = function(v) Flags.ESPRoles = v end})
    espSec:Toggle({Title = "Distance", Value = Flags.ESPDistance, Callback = function(v) Flags.ESPDistance = v end})
    espSec:Toggle({Title = "Health", Value = Flags.ESPHealth, Callback = function(v) Flags.ESPHealth = v end})
    espSec:Toggle({Title = "Role Colors", Value = Flags.ESPRoleColors, Callback = function(v) Flags.ESPRoleColors = v end})
    espSec:Toggle({Title = "Tracers (Drawing)", Desc = "Requires Drawing API", Value = Flags.ESPTracers, Callback = function(v) Flags.ESPTracers = v end})
    espSec:Toggle({Title = "Gun Drop ESP", Value = Flags.ESPGunDrop, Callback = function(v) Flags.ESPGunDrop = v end})
    espSec:Toggle({
        Title = "Auto TP to Gun & Back",
        Desc = "Auto teleports to dropped gun, grabs it, and returns",
        Value = Flags.AutoTpGun,
        Callback = function(v) setAutoTpGun(v) end
    })
    espSec:Button({
        Title = "TP to Gun Once",
        Desc = "Instant teleport to gun and back",
        Callback = function()
            local gunPart = getDroppedGun()
            local hrp = getRoot(LocalPlayer)
            if gunPart and hrp then
                local startCF = hrp.CFrame
                hrp.CFrame = gunPart.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.35)
                task.wait(0.2)
                local hrp2 = getRoot(LocalPlayer)
                if hrp2 then hrp2.CFrame = startCF end
            end
        end
    })
    espSec:Slider({Title = "Max Distance", Value = {Min = 300, Max = 9000, Default = Flags.ESPMaxDistance}, Callback = function(v) Flags.ESPMaxDistance = v end})
    local colSec = addSection(VisualsTab, "ESP Colors")
    if colSec.Colorpicker then
        colSec:Colorpicker({Title = "Murderer", Default = Flags.MurdererColor, Callback = function(c) Flags.MurdererColor = c end})
        colSec:Colorpicker({Title = "Sheriff", Default = Flags.SheriffColor, Callback = function(c) Flags.SheriffColor = c end})
        colSec:Colorpicker({Title = "Innocent", Default = Flags.InnocentColor, Callback = function(c) Flags.InnocentColor = c end})
    end
end

do
    local mSec = addSection(PlayerTab, "Movement")
    mSec:Toggle({
        Title = "WalkSpeed Override",
        Value = Flags.WalkSpeedEnabled,
        Callback = function(v)
            Flags.WalkSpeedEnabled = v
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v and Flags.WalkSpeed or 16 end
        end,
    })
    mSec:Slider({Title = "WalkSpeed", Value = {Min = 16, Max = 120, Default = Flags.WalkSpeed}, Callback = function(v) Flags.WalkSpeed = v; if Flags.WalkSpeedEnabled then local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.WalkSpeed = v end end end})
    mSec:Toggle({
        Title = "JumpPower Override",
        Value = Flags.JumpPowerEnabled,
        Callback = function(v)
            Flags.JumpPowerEnabled = v
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = v
                if v then hum.JumpPower = Flags.JumpPower end
            end
        end,
    })
    mSec:Slider({Title = "JumpPower", Value = {Min = 50, Max = 220, Default = Flags.JumpPower}, Callback = function(v) Flags.JumpPower = v; if Flags.JumpPowerEnabled then local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.JumpPower = v end end end})
    LocalPlayer.CharacterAdded:Connect(function(c)
        c:WaitForChild("Humanoid")
        task.wait(0.4)
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if Flags.WalkSpeedEnabled then hum.WalkSpeed = Flags.WalkSpeed end
        if Flags.JumpPowerEnabled then hum.UseJumpPower = true; hum.JumpPower = Flags.JumpPower end
    end)
    mSec:Button({
        Title = "Infinite Jump (toggle)",
        Callback = function()
            local inf = not (getgenv()._swiftInfJump)
            getgenv()._swiftInfJump = inf
            if inf and not getgenv()._swiftInfConn then
                getgenv()._swiftInfConn = UserInputService.JumpRequest:Connect(function()
                    if getgenv()._swiftInfJump then
                        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end
                end)
            end
            pcall(function() (Window.Notify or WindUI.Notify)({Title = "Swift", Content = "Infinite Jump: " .. (inf and "On" or "Off"), Duration = 2}) end)
        end
    })
end

do
    local s = addSection(SettingsTab, "Config & System")
    if s.Keybind then
        s:Keybind({
            Title = "Toggle UI Keybind",
            Desc = "RightShift to hide/show Swift - modern WindUI bind",
            Value = "RightShift",
            Callback = function(v)
                pcall(function()
                    if Window.SetToggleKey then Window:SetToggleKey(Enum.KeyCode[v]) end
                end)
            end,
        })
        if s.Divider then s:Divider() end
    end
    if s.Dropdown and WindUI and WindUI.GetThemes then
        local ok, themes = pcall(function() return WindUI:GetThemes() end)
        if ok and themes and #themes > 0 then
            s:Dropdown({
                Title = "Theme",
                Desc = "WindUI theme - pick modern palette",
                Values = themes,
                Value = "Dark",
                Callback = function(v)
                    pcall(function() Window:SetTheme(v) end)
                end,
            })
            if s.Divider then s:Divider() end
        end
    end
    if s.Button then
        s:Button({
            Title = "Unload Swift (clean ESP/tracers)",
            Callback = function()
                Flags.ESPEnabled = false
                setKillAura(false)
                setThrowAimbot(false)
                setAutoTpGun(false)
                if ESP.Conn then ESP.Conn:Disconnect(); ESP.Conn = nil end
                for _, hl in pairs(ESP.Highlights) do pcall(function() hl:Destroy() end) end
                for _, bb in pairs(ESP.Billboards) do pcall(function() bb:Destroy() end) end
                if ESP.GunHighlight then pcall(function() ESP.GunHighlight:Destroy() end) end
                if ESP.GunBillboard then pcall(function() ESP.GunBillboard:Destroy() end) end
                if ESP.Container then pcall(function() ESP.Container:Destroy() end) end
                for _, l in pairs(Tracers.Lines) do pcall(function() l:Remove() end) end
                if Combat.FOVCircle then pcall(function() Combat.FOVCircle:Remove() end) end
                if Window.Destroy then Window:Destroy() end
                if Window.Close then Window:Close() end
            end
        })
        s:Button({
            Title = "Re-inject UI",
            Callback = function()
                pcall(function() (Window.Notify or WindUI.Notify)({Title = "Swift", Content = "Re-execute loader to reinject", Duration = 3}) end)
            end
        })
    end
    if s.Paragraph then
        s:Paragraph({
            Title = "Credits",
            Desc = "Swift - MM2 - WindUI (Footagesus) - Hooks: stabKnife @131, throwKnife @147, GunClient @69\nOnly works on MM2 - github.com/coderofthenextgen/Swift",
        })
    end
end

pcall(function()
    local notif = Window.Notify or WindUI.Notify
    if notif then
        notif({
            Title = "Swift - MM2 Loaded",
            Content = "Exclusive build - ESP ready - Combat hooks active",
            Duration = 4,
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Swift - MM2",
            Text = "Loaded - ESP ready",
            Duration = 4,
        })
    end
end)

getgenv().Swift = {
    Flags = Flags,
    Remotes = Remotes,
    ESP = ESP,
    Combat = Combat,
    Window = Window,
    Version = "1.0.0-MM2",
}

warn("[Swift] Swift - MM2 loaded. PlaceId=" .. tostring(PlaceId) .. " WindUI=" .. tostring(WindUI ~= nil))
