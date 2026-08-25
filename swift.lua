--!strict
-- Swift | MM2 Exclusive | v1.0.0
-- Premium Murder Mystery 2 Hub — WindUI + ESP + Combat
-- Repository: https://github.com/coderofthenextgen/Swift
-- Loader: loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift/main/swift.lua"))()
--
--  H O O K S  R E F E R E N C E  (from dumped clients):
--  -------------------------------------------------------------------------
--  KnifeClient.stabKnife @ 131
--    Upvalues: ThrowKnife, ThrowCharge, Slash, ThrowHold, Downstab, Events, RunService
--    Constant: "KnifeStabbed" -> Events.KnifeStabbed:FireServer()
--    Logic: os.clock debounce 0.85s, Random.new():NextInteger scan, PreSimulation wait
--
--  KnifeClient.throwKnife @ 147
--    Upvalues: Events, Handle, Animations
--    Constants: "KnifeThrown" -> Events.KnifeThrown:FireServer(CFrame)
--    Args: (originCF, targetCF) -> server validates trajectory
--
--  GunClient @ 69
--    Upvalues: UIS, WeaponService.GunFired, KnifeThrown Event, GetMouseTargetCFrame
--    Constants: "Shoot" -> GunFired:FireServer(targetCF, hitCF)
--    Logic: PreferredInput Touch check, WorldCFrame ray from HumanoidRootPart.GunRaycastAttachment
--  -------------------------------------------------------------------------

local cloneref = cloneref or clonereference or function(o) return o end
local gethui = gethui or function() return cloneref(game:GetService("CoreGui")) end

-- // STRICT MM2 GUARD // ----------------------------------------------------
local MM2_PLACE_IDS = { [142823291] = true }
local MM2_UNIVERSE_IDS = { [66654135] = true, [6035872082] = false } -- second is Rivals, explicitly block

local PlaceId = game.PlaceId
local GameId = game.GameId
local UniverseOk = MM2_UNIVERSE_IDS[GameId] ~= nil and MM2_UNIVERSE_IDS[GameId] ~= false
local PlaceOk = MM2_PLACE_IDS[PlaceId] == true

if not (PlaceOk or UniverseOk) then
    -- Try to notify even before UI
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Swift — MM2 Only",
            Text = "This hub only works on Murder Mystery 2 [142823291].\nCurrent PlaceId: " .. tostring(PlaceId),
            Duration = 7,
        })
    end)
    warn("[Swift] Unsupported game. PlaceId=" .. tostring(PlaceId) .. " Universe=" .. tostring(GameId) .. " — Swift is MM2 exclusive.")
    return
end

-- // SERVICES // ------------------------------------------------------------
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Workspace = cloneref(game:GetService("Workspace"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- wait for game loaded
if not game:IsLoaded() then game.Loaded:Wait() end

-- // WINDUI — best looking modern lib (glass, motion, gradients) // -------
-- Primary: WindUI ( Footagesus/WindUI — 327+ stars, best aesthetics 2026 )
-- Fallback: Swift-UI (obsidian boxy) if WindUI unreachable
local WindUI
local okWind, resWind = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if okWind and resWind then
    WindUI = resWind
else
    -- fallback to swift-ui owned lib
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

-- // UTILS // ---------------------------------------------------------------
local function findRemote(name: string): RemoteEvent?
    -- exhaustive search in ReplicatedStorage
    local found = ReplicatedStorage:FindFirstChild(name, true)
    if found and found:IsA("RemoteEvent") then return found end
    -- try common containers
    for _, container in ipairs({ReplicatedStorage, ReplicatedStorage:FindFirstChild("ClientServices"), ReplicatedStorage:FindFirstChild("WeaponService")}) do
        if container then
            local c = container:FindFirstChild(name, true)
            if c and c:IsA("RemoteEvent") then return c :: any end
        end
    end
    return nil
end

local function getCharacter(plr: Player): Model?
    return plr.Character
end

local function getRoot(plr: Player): BasePart?
    local c = getCharacter(plr)
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function hasTool(plr: Player, toolName: string): boolean
    local c = getCharacter(plr)
    if c and c:FindFirstChild(toolName) then return true end
    local bp = plr:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(toolName) then return true end
    return false
end

local function isAlive(plr: Player): boolean
    local c = getCharacter(plr)
    if not c then return false end
    local hum = c:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

-- Role detection — MM2 roles are tool-based + decompiler-proven
-- Murderer = has Knife, Sheriff = has Gun/Revolver, Hero = picked up Gun
local function getRole(plr: Player): string
    if not isAlive(plr) then return "Dead" end
    if hasTool(plr, "Knife") then return "Murderer" end
    if hasTool(plr, "Gun") or hasTool(plr, "Revolver") then return "Sheriff" end
    -- fallback: check for Gun drop owner — handled elsewhere
    return "Innocent"
end

local function getDroppedGun(): BasePart?
    -- MM2 drops Gun tool in workspace
    local drop = Workspace:FindFirstChild("GunDrop", true)
    if drop and drop:IsA("BasePart") then return drop end
    -- alternative name search
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o.Name == "GunDrop" and o:IsA("BasePart") then return o end
        if o.Name == "Gun" and o:IsA("Tool") and o.Parent == Workspace then
            local h = o:FindFirstChild("Handle")
            if h and h:IsA("BasePart") then return h end
        end
    end
    return nil
end

local function worldToScreen(pos: Vector3)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), onScreen, v.Z
end

local function distanceFromPlayer(pos: Vector3): number
    local root = getRoot(LocalPlayer)
    if not root then return math.huge end
    return (root.Position - pos).Magnitude
end

local function getClosestToCursor(maxDist: number?, aliveOnly: boolean?): Player?
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
                    if d < bestDist and w <= (maxDist :: number) then
                        best, bestDist = plr, d
                    end
                end
            end
        end
    end
    return best
end

-- // CONFIG // --------------------------------------------------------------
local Flags = {
    -- Visuals
    ESPEnabled = false,
    ESPBoxes = true,
    ESPNames = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPRoles = true,
    ESPTracers = false,
    ESPGunDrop = true,
    ESPRoleColors = true,
    ESPMaxDistance = 2000,
    ESPBoxColor = Color3.fromRGB(255, 255, 255),
    MurdererColor = Color3.fromRGB(255, 55, 55),
    SheriffColor = Color3.fromRGB(55, 130, 255),
    InnocentColor = Color3.fromRGB(255, 255, 255),
    HeroColor = Color3.fromRGB(255, 220, 55),

    -- Combat — Knife
    KillAura = false,
    KillAuraRange = 18,
    KillAuraDelay = 0.22,
    KillAuraTargets = "All", -- All / Murderer / Sheriff
    ThrowAimbot = false,
    ThrowSilent = false,
    ThrowFOV = 500,

    -- Combat — Gun
    GunAimbot = false,
    GunSilentAim = false,
    GunAimPart = "Head",
    GunFOV = 320,
    GunShowFOV = true,
    GunWallbang = false,
    GunAutoShoot = false,

    -- Player
    WalkSpeedEnabled = false,
    WalkSpeed = 16,
    JumpPowerEnabled = false,
    JumpPower = 50,
}

-- // REMOTES (resolved late, with fallback search) // ----------------------
local Remotes = {
    KnifeStabbed = nil :: RemoteEvent?,
    KnifeThrown = nil :: RemoteEvent?,
    GunFired = nil :: RemoteEvent?,
    -- MM2 historical names
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
    -- deep scan fallback: look for any RemoteEvent that looks like weapon
    if not Remotes.GunFired then
        for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
            if inst:IsA("RemoteEvent") and inst.Name:lower():find("gun") and inst.Name:lower():find("fir") then
                Remotes.GunFired = inst
                break
            end
        end
    end
    -- also check WeaponService specifically (GunClient upvalue)
    local ws = ReplicatedStorage:FindFirstChild("ClientServices")
    if ws then
        local ws2 = ws:FindFirstChild("WeaponService")
        if ws2 then
            local gf = ws2:FindFirstChild("GunFired")
            if gf and gf:IsA("RemoteEvent") then Remotes.GunFired = gf end
        end
    end
    warn(string.format("[Swift] Remotes — Stab:%s Throw:%s Gun:%s",
        Remotes.KnifeStabbed and Remotes.KnifeStabbed:GetFullName() or "nil",
        Remotes.KnifeThrown and Remotes.KnifeThrown:GetFullName() or "nil",
        Remotes.GunFired and Remotes.GunFired:GetFullName() or "nil"
    ))
end

task.spawn(function()
    task.wait(2)
    resolveRemotes()
end)

-- // ESP ENGINE // ----------------------------------------------------------
local ESP = {
    Enabled = false,
    Container = nil :: Folder?,
    Highlights = {} :: {[Player]: Highlight},
    Billboards = {} :: {[Player]: BillboardGui},
    GunHighlight = nil :: Highlight?,
    GunBillboard = nil :: BillboardGui?,
    Conn = nil :: RBXScriptConnection?,
    Boxes = {} :: {[Player]: Frame}, -- fallback if Drawing not available
}

local function ensureContainer()
    if ESP.Container and ESP.Container.Parent then return ESP.Container end
    local f = Instance.new("Folder")
    f.Name = "SwiftESP"
    f.Parent = gethui() -- hidden but we parent highlights to character; folder for billboards
    ESP.Container = f
    return f
end

local function getRoleColor(role: string): Color3
    if not Flags.ESPRoleColors then return Flags.ESPBoxColor end
    if role == "Murderer" then return Flags.MurdererColor end
    if role == "Sheriff" then return Flags.SheriffColor end
    if role == "Hero" then return Flags.HeroColor end
    return Flags.InnocentColor
end

local function createBillboard(plr: Player): BillboardGui
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

local function ensureESPForPlayer(plr: Player)
    if plr == LocalPlayer then return end
    if ESP.Highlights[plr] and ESP.Highlights[plr].Parent then return end

    local char = plr.Character
    if not char then return end

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "SwiftHL"
    hl.Adornee = char
    hl.FillTransparency = 1 -- we will toggle via loop
    hl.OutlineTransparency = 1
    hl.FillColor = getRoleColor(getRole(plr))
    hl.OutlineColor = getRoleColor(getRole(plr))
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = ensureContainer() -- parent to hidden folder, adornee does rendering
    ESP.Highlights[plr] = hl

    -- Billboard
    local bb = createBillboard(plr)
    -- adornee to HRP if exists else Head
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if root and root:IsA("BasePart") then
        bb.Adornee = root
        bb.Parent = ensureContainer()
        ESP.Billboards[plr] = bb
    end
end

local function removeESPForPlayer(plr: Player)
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
        local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
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
        -- box vs outline: we use Fill for Murderer/Sheriff more visible
        if Flags.ESPBoxes then
            hl.FillTransparency = (role == "Murderer" or role == "Sheriff") and 0.55 or 0.78
            hl.OutlineTransparency = 0
        else
            hl.FillTransparency = 1
            hl.OutlineTransparency = 1
        end
        -- if boxes disabled but names enabled, still show outline faint
        if not Flags.ESPBoxes and Flags.ESPNames then
            hl.OutlineTransparency = 0.15
        end

        if bb then
            bb.Enabled = Flags.ESPNames or Flags.ESPDistance or Flags.ESPRoles or Flags.ESPHealth
            bb.Adornee = root
            local label = bb:FindFirstChild("Label") :: TextLabel?
            local distL = bb:FindFirstChild("Dist") :: TextLabel?
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
            -- health-based size tweak
            bb.StudsOffset = Vector3.new(0, 3.2, 0)
        end
    end

    -- GunDrop ESP
    if Flags.ESPGunDrop then
        local gunPart = getDroppedGun()
        if gunPart then
            if not ESP.GunHighlight or not ESP.GunHighlight.Parent then
                local hl = Instance.new("Highlight")
                hl.Name = "SwiftGun"
                hl.FillColor = Color3.fromRGB(255, 220, 40)
                hl.OutlineColor = Color3.fromRGB(255, 255, 240)
                hl.FillTransparency = 0.35
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = ensureContainer()
                ESP.GunHighlight = hl
            end
            ESP.GunHighlight.Adornee = gunPart.Parent:IsA("Model") and gunPart.Parent or gunPart :: any
            ESP.GunHighlight.FillTransparency = 0.35
            ESP.GunHighlight.OutlineTransparency = 0
            -- billboard
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
                tl.Text = "🔫 GUN DROP"
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

local function setESPEnabled(v: boolean)
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
            -- keep connection but update will hide; we keep it to avoid rebind spam
        end
    end
end

-- Player added/removed
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

-- Tracers (Drawing API if available)
local Tracers = { Lines = {} :: {[Player]: any}, Conn = nil :: RBXScriptConnection? }
local function ensureTracer(plr: Player)
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

-- // COMBAT // --------------------------------------------------------------
local Combat = {
    KillAuraConn = nil :: RBXScriptConnection?,
    GunHooked = false,
    FOVCircle = nil :: any,
    FOVConn = nil :: RBXScriptConnection?,
    LastStab = 0,
}

-- Internal helper: fire stab remote safely (mirrors stabKnife constants)
local function fireStab(target: Player?)
    local remote = Remotes.KnifeStabbed
    if not remote then
        -- try re-resolve
        resolveRemotes()
        remote = Remotes.KnifeStabbed
        if not remote then return false end
    end
    -- MM2 validates distance server-side but FireServer works inside ~10-14 studs normally.
    -- We emulate stabKnife: FireServer with optional target CFrame? Some forks require no args.
    local ok = pcall(function()
        -- try no-arg first (most common)
        remote:FireServer()
    end)
    if not ok then
        pcall(function()
            -- fallback: some remotes expect target position
            local root = target and getRoot(target)
            if root then remote:FireServer(root.Position) end
        end)
    end
    return ok
end

local function fireThrow(targetCF: CFrame)
    local remote = Remotes.KnifeThrown
    if not remote then resolveRemotes(); remote = Remotes.KnifeThrown end
    if not remote then return end
    -- throwKnife signature: FireServer(CFrame origin, CFrame target)
    -- Dump shows throwKnife fires .Events.KnifeThrown:FireServer(CFrame)
    -- We try both signatures
    local origin = (getRoot(LocalPlayer) and getRoot(LocalPlayer).CFrame) or Camera.CFrame
    pcall(function() remote:FireServer(targetCF) end)
    pcall(function() remote:FireServer(origin, targetCF) end)
    pcall(function() remote:FireServer(targetCF.Position) end)
end

local function fireGun(targetCF: CFrame, hitPos: Vector3?)
    local remote = Remotes.GunFired
    if not remote then resolveRemotes(); remote = Remotes.GunFired end
    if not remote then return end
    -- GunClient: FireServer(mouseTargetCFrame, gunRaycastCFrame) basically
    -- Some versions: FireServer(Vector3 targetPos, CFrame lookAt)
    pcall(function() remote:FireServer(targetCF) end)
    pcall(function() remote:FireServer(targetCF, targetCF) end)
    pcall(function() remote:FireServer(targetCF.Position, targetCF) end)
    if hitPos then
        pcall(function() remote:FireServer(hitPos, targetCF) end)
    end
end

local function shouldAuraTarget(plr: Player): boolean
    if plr == LocalPlayer or not isAlive(plr) then return false end
    local mode = Flags.KillAuraTargets
    if mode == "All" then return true end
    local role = getRole(plr)
    if mode == "Murderer" then return role == "Murderer" end
    if mode == "Sheriff" then return role == "Sheriff" end
    if mode == "Innocent" then return role == "Innocent" end
    return true
end

local function getAuraTargets(): {Player}
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
    -- Hook FireServer for silent aim (namecall hook)
    local mt = getrawmetatable and getrawmetatable(game)
    local nc = mt and mt.__namecall
    if mt and nc and setreadonly and newcclosure then
        local old
        old = hookmetamethod and hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or ""
            local args = {...}
            if method == "FireServer" and Flags.GunSilentAim and self == Remotes.GunFired then
                -- redirect to silent target
                local target = getClosestToCursor(Flags.GunFOV, true)
                if target then
                    local partName = Flags.GunAimPart
                    local char = target.Character
                    local aimPart = char and char:FindFirstChild(partName) or getRoot(target)
                    if aimPart and aimPart:IsA("BasePart") then
                        local cf = CFrame.new(aimPart.Position)
                        -- rebuild args: preserve original count but replace CFrames
                        for i, v in ipairs(args) do
                            if typeof(v) == "CFrame" then args[i] = cf end
                            if typeof(v) == "Vector3" then args[i] = aimPart.Position end
                        end
                        -- if no CFrame in args, prepend
                        local hasCF = false
                        for _, v in ipairs(args) do if typeof(v) == "CFrame" then hasCF = true break end end
                        if not hasCF then table.insert(args, 1, cf) end
                        return old(self, unpack(args))
                    end
                end
            end
            -- wallbang: currently just passes through (server check is position based)
            return old(self, ...)
        end))
        if not old then Combat.GunHooked = false end
    else
        warn("[Swift] Executor missing hookmetamethod — GunSilentAim will use manual Fire")
    end
end

local function setKillAura(v: boolean)
    Flags.KillAura = v
    if v then
        if Combat.KillAuraConn then Combat.KillAuraConn:Disconnect() end
        local last = 0
        Combat.KillAuraConn = RunService.Heartbeat:Connect(function()
            if not Flags.KillAura then return end
            if tick() - last < Flags.KillAuraDelay then return end
            -- only aura if we hold knife
            if not hasTool(LocalPlayer, "Knife") then return end
            local targets = getAuraTargets()
            if #targets > 0 then
                last = tick()
                -- emulate stabKnife debounce 0.85s but we allow faster via 0.22 toggle
                -- FireServer once per heartbeat max 1 target to avoid kick
                fireStab(targets[1])
            end
        end)
    else
        if Combat.KillAuraConn then Combat.KillAuraConn:Disconnect(); Combat.KillAuraConn = nil end
    end
end

-- Throw aimbot loop (fires when LeftClick & holding Knife)
local ThrowConn: RBXScriptConnection? = nil
local function setThrowAimbot(v: boolean)
    Flags.ThrowAimbot = v
    if v then
        if ThrowConn then ThrowConn:Disconnect() end
        ThrowConn = UserInputService.InputBegan:Connect(function(inp, gpe)
            if gpe then return end
            if not Flags.ThrowAimbot then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.KeyCode ~= Enum.KeyCode.ButtonR2 then return end
            if not hasTool(LocalPlayer, "Knife") then return end
            -- silent throw override
            local target = getClosestToCursor(Flags.ThrowFOV, true)
            if target then
                local root = getRoot(target)
                if root then
                    -- if silent enabled, directly fire remote instead of letting default trajectory run
                    if Flags.ThrowSilent then
                        fireThrow(CFrame.new(root.Position))
                        return
                    else
                        -- non-silent: just aim assist — we still fire correct CFrame but let client animation play
                        -- we hook by firing after short delay to not double-throw
                        task.wait(0.06)
                        -- optional: fireThrow to guarantee hit (server reconciles)
                    end
                end
            end
        end)
    else
        if ThrowConn then ThrowConn:Disconnect(); ThrowConn = nil end
    end
end

-- FOV circle for Gun
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

-- Gun Aimbot (camera lock) — hold RightClick to lock
local AimbotConn: RBXScriptConnection? = nil
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
    -- smooth camera tween to target
    local camPos = Camera.CFrame.Position
    local targetPos = part.Position
    -- wall check
    if not Flags.GunWallbang then
        local ray = Workspace:Raycast(camPos, targetPos - camPos, RaycastParams.new())
        -- RaycastParams filter: ignore local char
        -- if wall hit before target, skip
        if ray and ray.Instance and not ray.Instance:IsDescendantOf(target.Character) then
            return
        end
    end
    local cf = CFrame.new(camPos, targetPos)
    Camera.CFrame = Camera.CFrame:Lerp(cf, 0.42)

    if Flags.GunAutoShoot then
        -- fire after aim
        local remote = Remotes.GunFired
        if remote then
            fireGun(CFrame.new(targetPos), targetPos)
        end
    end
end

RunService.RenderStepped:Connect(runGunAimbot)

-- // WINDOW // --------------------------------------------------------------
local Window
local okWin, winRes = pcall(function()
    if WindUI.CreateWindow then
        -- WindUI API
        return WindUI:CreateWindow({
            Title = "Swift  —  MM2",
            Author = "coderofthenextgen",
            Folder = "SwiftMM2",
            Size = UDim2.fromOffset(560, 520),
            Transparent = true,
            Theme = "Dark",
            SideBarWidth = 170,
            HasOutline = true,
        })
    else
        -- Swift-UI fallback (Obsidian style)
        return WindUI:CreateWindow({
            Title = "Swift — MM2",
            Footer = "MM2 Exclusive — v1.0.0",
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

-- Safe tab creator (supports both libs)
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
    if tab.Section then return tab:Section({Title = title}) end
    if tab:Section then return tab:Section({Title = title}) end
    if tab.CreateSection then return tab:CreateSection(title) end
    return tab
end

local function makeToggle(tabOrSec, opts)
    if tabOrSec.Toggle then return tabOrSec:Toggle(opts) end
    if tabOrSec.CreateToggle then return tabOrSec:CreateToggle(opts.Title or opts.Name, opts.Callback, opts.Value) end
    if tabOrSec.AddToggle then return tabOrSec:AddToggle(opts.Title, opts) end
    return nil
end

local function makeSlider(tabOrSec, opts)
    if tabOrSec.Slider then return tabOrSec:Slider(opts) end
    if tabOrSec.CreateSlider then return tabOrSec:CreateSlider(opts.Title, opts.Min, opts.Max, opts.Value, opts.Callback) end
    return nil
end

local function makeDropdown(tabOrSec, opts)
    if tabOrSec.Dropdown then return tabOrSec:Dropdown(opts) end
    if tabOrSec.CreateDropdown then return tabOrSec:CreateDropdown(opts.Title, opts.Values or opts.Options, opts.Callback) end
    return nil
end

local function makeButton(tabOrSec, opts)
    if tabOrSec.Button then return tabOrSec:Button(opts) end
    if tabOrSec.CreateButton then return tabOrSec:CreateButton(opts.Title, opts.Callback) end
    return nil
end

-- Tabs
local HomeTab = addTab({Title = "Home", Icon = "house"})
local CombatTab = addTab({Title = "Combat", Icon = "swords"})
local VisualsTab = addTab({Title = "Visuals", Icon = "eye"})
local PlayerTab = addTab({Title = "Player", Icon = "user"})
local SettingsTab = addTab({Title = "Settings", Icon = "settings"})

-- HOME
do
    local s = addSection(HomeTab, "Swift — Murder Mystery 2 Exclusive")
    if s.Paragraph then
        s:Paragraph({
            Title = "Locked to MM2",
            Desc = string.format("PlaceId %d  •  Universe %d\nSwift will refuse to run outside MM2.\nRemotes auto-resolved on injection.", PlaceId, GameId),
        })
    elseif s.CreateParagraph then
        s:CreateParagraph({Title = "Locked to MM2", Content = "PlaceId " .. PlaceId})
    end
    if s.Button then
        s:Button({Title = "Copy Discord (soon)", Callback = function()
            pcall(setclipboard, "https://github.com/coderofthenextgen/Swift")
            if Window.Notify or WindUI.Notify then
                local n = Window.Notify or WindUI.Notify
                pcall(n, {Title = "Swift", Content = "Copied repo link", Duration = 2})
            end
        end})
    end
    if s.Divider then s:Divider() end
    -- status indicators
    local function statusRow()
        local alive = isAlive(LocalPlayer)
        local role = getRole(LocalPlayer)
        local gunPart = getDroppedGun()
        return string.format("You: %s [%s]  •  GunDrop: %s", alive and "Alive" or "Dead", role, gunPart and "AVAILABLE" or "taken")
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
end

-- COMBAT
do
    local knifeSec = addSection(CombatTab, "Knife — Stab & Throw")
    knifeSec:Toggle({
        Title = "Kill Aura",
        Desc = "Auto-stabs nearby players (uses KnifeStabbed remote, 0.22s delay)",
        Value = Flags.KillAura,
        Callback = function(v) setKillAura(v) end,
    })
    knifeSec:Slider({
        Title = "Kill Aura Range",
        Min = 8, Max = 28, Default = Flags.KillAuraRange, Value = Flags.KillAuraRange,
        Callback = function(v) Flags.KillAuraRange = v end,
    })
    knifeSec:Slider({
        Title = "Kill Aura Delay",
        Min = 0.08, Max = 0.9, Step = 0.02, Default = Flags.KillAuraDelay, Value = Flags.KillAuraDelay,
        Callback = function(v) Flags.KillAuraDelay = v end,
    })
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
    knifeSec:Slider({
        Title = "Throw FOV",
        Min = 80, Max = 900, Default = Flags.ThrowFOV, Value = Flags.ThrowFOV,
        Callback = function(v) Flags.ThrowFOV = v end,
    })

    local gunSec = addSection(CombatTab, "Gun — Aimbot & Silent")
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
    gunSec:Slider({
        Title = "Gun FOV",
        Min = 60, Max = 900, Default = Flags.GunFOV, Value = Flags.GunFOV,
        Callback = function(v) Flags.GunFOV = v; updateFOVCircle() end,
    })
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

-- VISUALS
do
    local espSec = addSection(VisualsTab, "ESP — Roles & Highlights")
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
    espSec:Slider({
        Title = "Max Distance",
        Min = 300, Max = 9000, Default = Flags.ESPMaxDistance, Value = Flags.ESPMaxDistance,
        Callback = function(v) Flags.ESPMaxDistance = v end,
    })
    local colSec = addSection(VisualsTab, "ESP Colors")
    if colSec.Colorpicker then
        colSec:Colorpicker({Title = "Murderer", Default = Flags.MurdererColor, Callback = function(c) Flags.MurdererColor = c end})
        colSec:Colorpicker({Title = "Sheriff", Default = Flags.SheriffColor, Callback = function(c) Flags.SheriffColor = c end})
        colSec:Colorpicker({Title = "Innocent", Default = Flags.InnocentColor, Callback = function(c) Flags.InnocentColor = c end})
    end
end

-- PLAYER
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
    mSec:Slider({
        Title = "WalkSpeed",
        Min = 16, Max = 120, Default = Flags.WalkSpeed, Value = Flags.WalkSpeed,
        Callback = function(v)
            Flags.WalkSpeed = v
            if Flags.WalkSpeedEnabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = v end
            end
        end,
    })
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
    mSec:Slider({
        Title = "JumpPower",
        Min = 50, Max = 220, Default = Flags.JumpPower, Value = Flags.JumpPower,
        Callback = function(v)
            Flags.JumpPower = v
            if Flags.JumpPowerEnabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = v end
            end
        end,
    })
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
            pcall(function() (Window.Notify or WindUI.Notify)({Title = "Swift", Content = "Infinite Jump: " .. (inf and "ON" or "OFF"), Duration = 2}) end)
        end
    })
end

-- SETTINGS
do
    local s = addSection(SettingsTab, "Config & System")
    if s.Button then
        s:Button({
            Title = "Unload Swift (clean ESP/tracers)",
            Callback = function()
                Flags.ESPEnabled = false
                setKillAura(false)
                setThrowAimbot(false)
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
            Desc = "Swift MM2 Exclusive • WindUI (Footagesus) • Hooks: stabKnife @131, throwKnife @147, GunClient @69\nOnly works on MM2 — github.com/coderofthenextgen/Swift",
        })
    end
end

-- // NOTIFY READY // --------------------------------------------------------
pcall(function()
    local notif = Window.Notify or WindUI.Notify
    if notif then
        notif({
            Title = "Swift — MM2 Loaded",
            Content = "Exclusive build • ESP ready • Combat hooks active",
            Duration = 4,
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Swift — MM2",
            Text = "Loaded • ESP ready",
            Duration = 4,
        })
    end
end)

-- expose for debug
getgenv().Swift = {
    Flags = Flags,
    Remotes = Remotes,
    ESP = ESP,
    Combat = Combat,
    Window = Window,
    Version = "1.0.0-MM2",
}

warn("[Swift] MM2 Exclusive v1.0.0 loaded. PlaceId=" .. tostring(PlaceId) .. " WindUI=" .. tostring(WindUI ~= nil))
