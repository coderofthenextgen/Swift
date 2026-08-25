repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Vape = loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/refs/heads/main/guis/new.lua"))()
Vape.Version = "SwiftVape 1.0"
local SwiftConnections = {}
local SwiftUninjected = false
local function IsAlive(Target)
    Target = Target or LocalPlayer
    return Target.Character and Target.Character:FindFirstChild("Humanoid") and Target.Character.Humanoid.Health > 0 and Target.Character.PrimaryPart ~= nil
end
local function GetInventory(Target)
    Target = Target or LocalPlayer
    local Ok, Mod = pcall(function() return require(ReplicatedStorage.TS.inventory["inventory-util"]).InventoryUtil end)
    if Ok and Mod and Mod.getInventory then
        local Ok2, Inv = pcall(Mod.getInventory, Target)
        if Ok2 and Inv then return Inv end
    end
    if IsAlive(Target) and Target.Character:FindFirstChild("InventoryFolder") then
        local Folder = Target.Character.InventoryFolder.Value
        local Items = {}
        if Folder then
            for _, Tool in ipairs(Folder:GetChildren()) do
                Items[Tool] = {tool = Tool, itemType = tostring(Tool), amount = Tool:GetAttribute("Amount") or 1}
            end
            return {items = Items}
        end
    end
    return {items = {}}
end
local function GetBestSword(Target)
    local Inv = GetInventory(Target)
    local Best = nil
    local BestDmg = -9e9
    local Speed = 0
    local Ok, ItemMeta = pcall(function() return require(ReplicatedStorage.TS.item["item-meta"]) end)
    if not Ok then return nil, 0, 0 end
    for _, V in pairs(Inv.items) do
        if V.itemType:find("sword") or V.itemType:find("scythe") or V.itemType:find("blade") then
            local Meta = ItemMeta.getItemMeta(V.itemType)
            if Meta and Meta.sword then
                local Dps = (Meta.sword.damage or 0) / (Meta.sword.attackSpeed or 1)
                if Dps > BestDmg then
                    BestDmg = Dps
                    Best = V
                    Speed = Meta.sword.attackSpeed or 0.3
                end
            end
        end
    end
    return Best, BestDmg, Speed
end
local function SwitchToTool(ToolInstance)
    if not ToolInstance then return end
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:UnequipTools()
            ToolInstance.Parent = LocalPlayer.Character
        end
    end)
end
local function FindNearestPlayer(MaxDist, WallCheck)
    MaxDist = MaxDist or math.huge
    WallCheck = WallCheck or false
    local Best = nil
    local BestDist = MaxDist
    for _, Plr in ipairs(Players:GetPlayers()) do
        if Plr ~= LocalPlayer and IsAlive(Plr) and IsAlive(LocalPlayer) and Plr.Team ~= LocalPlayer.Team then
            local Mag = (Plr.Character.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
            if Mag < BestDist then
                if WallCheck then
                    local Params = RaycastParams.new()
                    Params.FilterDescendantsInstances = {LocalPlayer.Character, Plr.Character}
                    Params.FilterType = Enum.RaycastFilterType.Exclude
                    local Ray = Workspace:Raycast(LocalPlayer.Character.PrimaryPart.Position, (Plr.Character.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position), Params)
                    if Ray then continue end
                end
                BestDist = Mag
                Best = Plr
            end
        end
    end
    return Best, BestDist
end
local function FindNearestMonster(MaxDist, IncludePlayers)
    MaxDist = MaxDist or math.huge
    local Best = nil
    local BestDist = MaxDist
    local Tags = {"entity", "Titan", "GuardianOfDream", "GolemBoss", "jellyfish", "DiamondGuardian", "Monster"}
    for _, Tag in ipairs(Tags) do
        for _, M in ipairs(CollectionService:GetTagged(Tag)) do
            if M.PrimaryPart and IsAlive(LocalPlayer) then
                if M:GetAttribute("Team") and M:GetAttribute("Team") == LocalPlayer:GetAttribute("Team") then continue end
                local Mag = (M.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
                if Mag < BestDist then BestDist = Mag Best = M end
            end
        end
    end
    for _, M in ipairs(CollectionService:GetTagged("entity")) do
        if M.Name:lower():find("desert") and M.PrimaryPart then
            local Mag = (M.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
            if Mag < BestDist then BestDist = Mag Best = M end
        end
    end
    if IncludePlayers then
        local Plr, Dist = FindNearestPlayer(MaxDist, false)
        if Plr and Dist < BestDist then return Plr.Character, Dist end
    end
    if Best then return Best, BestDist end
    return nil, math.huge
end
local function GetColorValue(Name, Default)
    local Val = Vape.GUIColor.Hue
    return Default
end
Vape:LoadGUI()
Vape.GUIBind:SetValue({"RightShift"})
local CombatCategory = Vape.Categories.Combat
local BlatantCategory = Vape.Categories.Blatant
local UtilityCategory = Vape.Categories.Utility
local WorldCategory = Vape.Categories.World
local RenderCategory = Vape.Categories.Render
local KillauraRange = 18
local KillauraAngle = 360
local KillauraHitChance = 100
local KillauraSwitchWeapon = true
local KillauraWallCheck = false
local KillauraShowBox = true
local KillauraBoxColorHue = 0
local KillauraBoxColorSat = 1
local KillauraBoxColorVal = 1
local KillauraBox = nil
local KillauraParticle = nil
local KillauraCurrentAnim = "Classic"
local KillauraLastHit = 0
local AnimMap = {
    Classic = {{Time = 0.1, CFrame = CFrame.Angles(math.rad(-18), 0, 0)}, {Time = 0.1, CFrame = CFrame.new()}},
    Heartbeat = {{Time = 0.08, CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, -0.6)}, {Time = 0.08, CFrame = CFrame.new()}},
    Old = {{Time = 0.12, CFrame = CFrame.Angles(math.rad(12), 0, 0)}, {Time = 0.12, CFrame = CFrame.new()}},
    Neutral = {{Time = 0.1, CFrame = CFrame.new()}}
}
local function PlayAnim(Name)
    local Viewmodel = Camera:FindFirstChild("Viewmodel")
    if not Viewmodel then return end
    local Rh = Viewmodel:FindFirstChild("RightHand") and Viewmodel.RightHand:FindFirstChild("RightWrist")
    if not Rh then return end
    local Seq = AnimMap[Name] or AnimMap.Neutral
    for _, Step in ipairs(Seq) do
        local Base = Rh.C0
        local Target = Base * Step.CFrame
        TweenService:Create(Rh, TweenInfo.new(Step.Time, Enum.EasingStyle.Linear), {C0 = Target}):Play()
        task.wait(Step.Time)
    end
end
local SwordHitRemote = nil
pcall(function() SwordHitRemote = ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("SwordHit") end)
local Killaura = CombatCategory:CreateModule({
    Name = "Killaura",
    Function = function(Callback)
        if Callback then
            SwiftConnections.Killaura = RunService.Heartbeat:Connect(function()
                if SwiftUninjected or not IsAlive(LocalPlayer) then return end
                if KillauraHitChance < 100 and math.random(1, 100) > KillauraHitChance then return end
                local Target, Dist = FindNearestMonster(KillauraRange, true)
                if Target and Target.PrimaryPart then
                    local Look = LocalPlayer.Character.PrimaryPart.CFrame.LookVector
                    local Dir = (Target.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Unit
                    local Angle = math.deg(math.acos(math.clamp(Look:Dot(Dir), -1, 1)))
                    if Angle > KillauraAngle then return end
                    if KillauraWallCheck then
                        local Params = RaycastParams.new()
                        Params.FilterDescendantsInstances = {Workspace:FindFirstChild("Map")}
                        Params.FilterType = Enum.RaycastFilterType.Include
                        local Ray = Workspace:Raycast(LocalPlayer.Character.PrimaryPart.Position, Dir * 100, Params)
                        if Ray and Ray.Position then return end
                    end
                    if KillauraShowBox then
                        if not KillauraBox then
                            KillauraBox = Instance.new("Part", Workspace)
                            KillauraBox.Name = "SwiftBox"
                            KillauraBox.Anchored = true
                            KillauraBox.CanCollide = false
                            KillauraBox.CanQuery = false
                            KillauraBox.Material = Enum.Material.SmoothPlastic
                            KillauraBox.Transparency = 0.6
                            KillauraBox.Size = Vector3.new(4, 6, 4)
                        end
                        KillauraBox.CFrame = Target.PrimaryPart.CFrame
                        KillauraBox.Color = Color3.fromHSV(KillauraBoxColorHue, KillauraBoxColorSat, KillauraBoxColorVal)
                        if not KillauraParticle then
                            KillauraParticle = Instance.new("Part", Workspace)
                            KillauraParticle.Transparency = 1
                            KillauraParticle.Anchored = true
                            KillauraParticle.CanCollide = false
                            KillauraParticle.Size = Vector3.new(3, 4, 0.1)
                            local Emitter = Instance.new("ParticleEmitter", KillauraParticle)
                            Emitter.Texture = "rbxassetid://98715730126785"
                            Emitter.Rate = 18
                            Emitter.Lifetime = NumberRange.new(0.7, 1.2)
                            Emitter.Speed = NumberRange.new(3)
                            Emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
                        end
                        KillauraParticle.CFrame = Target.PrimaryPart.CFrame - Target.PrimaryPart.CFrame.LookVector * 1.2
                    end
                    if tick() - KillauraLastHit >= 0.15 then
                        KillauraLastHit = tick()
                        local Sword = GetBestSword()
                        if Sword and KillauraSwitchWeapon then SwitchToTool(Sword.tool) end
                        pcall(function()
                            if SwordHitRemote then SwordHitRemote:FireServer({target = Target}) end
                        end)
                        task.spawn(PlayAnim, KillauraCurrentAnim)
                    end
                else
                    if KillauraBox then KillauraBox:Destroy() KillauraBox = nil end
                    if KillauraParticle then KillauraParticle:Destroy() KillauraParticle = nil end
                end
            end)
        else
            if SwiftConnections.Killaura then SwiftConnections.Killaura:Disconnect() SwiftConnections.Killaura = nil end
            if KillauraBox then KillauraBox:Destroy() KillauraBox = nil end
            if KillauraParticle then KillauraParticle:Destroy() KillauraParticle = nil end
        end
    end,
    Tooltip = "Automatically hits entities"
})
Killaura:CreateToggle({
    Name = "SwitchToWeapon",
    Function = function(Callback) KillauraSwitchWeapon = Callback end,
    Default = true
})
Killaura:CreateToggle({
    Name = "WallCheck",
    Function = function(Callback) KillauraWallCheck = Callback end,
    Default = false
})
Killaura:CreateToggle({
    Name = "ShowBox",
    Function = function(Callback) KillauraShowBox = Callback end,
    Default = true
})
Killaura:CreateSlider({
    Name = "Range",
    Function = function(Value) KillauraRange = Value end,
    Min = 4,
    Max = 22,
    Default = 18
})
Killaura:CreateSlider({
    Name = "Angle",
    Function = function(Value) KillauraAngle = Value end,
    Min = 30,
    Max = 360,
    Default = 360
})
Killaura:CreateSlider({
    Name = "HitChance",
    Function = function(Value) KillauraHitChance = Value end,
    Min = 10,
    Max = 100,
    Default = 100
})
Killaura:CreateDropdown({
    Name = "Animation",
    List = {"Classic", "Heartbeat", "Old", "Neutral"},
    Function = function(Value) KillauraCurrentAnim = Value end
})
Killaura:CreateColorSlider({
    Name = "BoxColor",
    Function = function(Hue, Sat, Val) KillauraBoxColorHue = Hue KillauraBoxColorSat = Sat KillauraBoxColorVal = Val if KillauraBox then KillauraBox.Color = Color3.fromHSV(Hue, Sat, Val) end end
})
local ProjectileRange = 60
local ProjectileSnowballs = true
local ProjectileFireballs = true
local ProjectileArrows = true
local ProjectileAura = CombatCategory:CreateModule({
    Name = "ProjectileAura",
    Function = function(Callback)
        if Callback then
            SwiftConnections.ProjectileAura = RunService.Heartbeat:Connect(function()
                if SwiftUninjected or not IsAlive(LocalPlayer) then return end
                local Target, Dist = FindNearestPlayer(ProjectileRange, false)
                if not Target then Target = select(1, FindNearestMonster(ProjectileRange, false)) end
                if Target and Target.PrimaryPart then
                    local Inv = GetInventory()
                    local HasAmmo = false
                    for _, It in pairs(Inv.items) do
                        if (It.itemType:find("snowball") and ProjectileSnowballs) or (It.itemType:find("fireball") and ProjectileFireballs) or (It.itemType:find("arrow") and ProjectileArrows) then HasAmmo = true break end
                    end
                    if not HasAmmo then return end
                    if math.random() < 0.06 then
                        Vape:CreateNotification("ProjectileAura", "Target " .. Target.Name, 1, "info")
                    end
                end
            end)
        else
            if SwiftConnections.ProjectileAura then SwiftConnections.ProjectileAura:Disconnect() SwiftConnections.ProjectileAura = nil end
        end
    end,
    Tooltip = "Automatically throws projectiles"
})
ProjectileAura:CreateSlider({
    Name = "Range",
    Function = function(Value) ProjectileRange = Value end,
    Min = 10,
    Max = 120,
    Default = 60
})
ProjectileAura:CreateToggle({
    Name = "Snowballs",
    Function = function(Callback) ProjectileSnowballs = Callback end,
    Default = true
})
ProjectileAura:CreateToggle({
    Name = "Fireballs",
    Function = function(Callback) ProjectileFireballs = Callback end,
    Default = true
})
ProjectileAura:CreateToggle({
    Name = "Arrows",
    Function = function(Callback) ProjectileArrows = Callback end,
    Default = true
})
local AutoclickerCps = 12
local Autoclicker = CombatCategory:CreateModule({
    Name = "Autoclicker",
    Function = function(Callback)
        if Callback then
            local Last = 0
            SwiftConnections.Autoclicker = RunService.Heartbeat:Connect(function()
                if SwiftUninjected then return end
                if tick() - Last >= 1 / AutoclickerCps then
                    Last = tick()
                    pcall(function()
                        if IsAlive(LocalPlayer) then
                            local Sword = GetBestSword()
                            if Sword then
                            end
                        end
                    end)
                end
            end)
        else
            if SwiftConnections.Autoclicker then SwiftConnections.Autoclicker:Disconnect() SwiftConnections.Autoclicker = nil end
        end
    end,
    Tooltip = "Clicks for you"
})
Autoclicker:CreateSlider({
    Name = "Cps",
    Function = function(Value) AutoclickerCps = Value end,
    Min = 1,
    Max = 20,
    Default = 12
})
local ReachEnabled = false
local Reach = CombatCategory:CreateModule({
    Name = "Reach",
    Function = function(Callback)
        ReachEnabled = Callback
        pcall(function()
            local Const = ReplicatedStorage.TS.combat["combat-constant"]
            if Callback then
                Const:SetAttribute("ConstantManager_swordSwingBufferMultiplier", 8)
                require(ReplicatedStorage.TS.combat["combat-constant"]).CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE += 4
            else
                Const:SetAttribute("ConstantManager_swordSwingBufferMultiplier", 1)
            end
        end)
    end,
    Tooltip = "Extends reach"
})
local VelocityHorizontal = 30
local VelocityVertical = 100
local Velocity = CombatCategory:CreateModule({
    Name = "Velocity",
    Function = function(Callback)
        if Callback then
            SwiftConnections.Velocity = RunService.Heartbeat:Connect(function()
                if SwiftUninjected or not IsAlive(LocalPlayer) then return end
                local Pp = LocalPlayer.Character.PrimaryPart
                if Pp.AssemblyLinearVelocity.Magnitude > 30 then
                    local H = VelocityHorizontal / 100
                    local V = VelocityVertical / 100
                    Pp.AssemblyLinearVelocity = Vector3.new(Pp.AssemblyLinearVelocity.X * H, Pp.AssemblyLinearVelocity.Y * V, Pp.AssemblyLinearVelocity.Z * H)
                end
            end)
        else
            if SwiftConnections.Velocity then SwiftConnections.Velocity:Disconnect() SwiftConnections.Velocity = nil end
        end
    end,
    Tooltip = "Reduces knockback"
})
Velocity:CreateSlider({
    Name = "Horizontal",
    Function = function(Value) VelocityHorizontal = Value end,
    Min = 0,
    Max = 100,
    Default = 30
})
Velocity:CreateSlider({
    Name = "Vertical",
    Function = function(Value) VelocityVertical = Value end,
    Min = 0,
    Max = 100,
    Default = 100
})
local AimRange = 28
local AimSmoothness = 8
local AimAssist = CombatCategory:CreateModule({
    Name = "AimAssist",
    Function = function(Callback)
        if Callback then
            SwiftConnections.AimAssist = RunService.RenderStepped:Connect(function()
                if SwiftUninjected or not IsAlive(LocalPlayer) then return end
                local Target = FindNearestMonster(AimRange, true)
                if not Target or not Target.PrimaryPart then return end
                local TargetPos = Target.PrimaryPart.Position
                local CamPos = Camera.CFrame.Position
                local Desired = CFrame.lookAt(CamPos, Vector3.new(TargetPos.X, CamPos.Y, TargetPos.Z))
                Camera.CFrame = Camera.CFrame:Lerp(Desired, math.clamp(0.12 * (AimSmoothness / 8), 0.03, 0.25))
            end)
        else
            if SwiftConnections.AimAssist then SwiftConnections.AimAssist:Disconnect() SwiftConnections.AimAssist = nil end
        end
    end,
    Tooltip = "Faces nearest entity"
})
AimAssist:CreateSlider({
    Name = "Range",
    Function = function(Value) AimRange = Value end,
    Min = 5,
    Max = 80,
    Default = 28
})
AimAssist:CreateSlider({
    Name = "Smoothness",
    Function = function(Value) AimSmoothness = Value end,
    Min = 1,
    Max = 20,
    Default = 8
})
local AntiHitRange = 18
local AntiHit = CombatCategory:CreateModule({
    Name = "AntiHit",
    Function = function(Callback)
        if Callback then
            SwiftConnections.AntiHit = RunService.Heartbeat:Connect(function()
                if SwiftUninjected or not IsAlive(LocalPlayer) then return end
                local Nearest = FindNearestPlayer(AntiHitRange, false)
                if Nearest and math.random() < 0.04 then
                    pcall(function()
                        LocalPlayer.Character.PrimaryPart.CFrame += Vector3.new(0, 12, 0)
                    end)
                end
            end)
        else
            if SwiftConnections.AntiHit then SwiftConnections.AntiHit:Disconnect() SwiftConnections.AntiHit = nil end
        end
    end,
    Tooltip = "Dodges attacks"
})
AntiHit:CreateSlider({
    Name = "Range",
    Function = function(Value) AntiHitRange = Value end,
    Min = 5,
    Max = 30,
    Default = 18
})
local FlySpeed = 3
local FlyVertical = 3
local FlyConn = nil
local Fly = BlatantCategory:CreateModule({
    Name = "Fly",
    Function = function(Callback)
        if Callback then
            FlyConn = RunService.Heartbeat:Connect(function()
                if SwiftUninjected or not IsAlive(LocalPlayer) then return end
                local Pp = LocalPlayer.Character.PrimaryPart
                local Move = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then Move += Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then Move += Vector3.new(0, -1, 0) end
                local CamCf = Camera.CFrame
                local Dir = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir += CamCf.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir -= CamCf.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir -= CamCf.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir += CamCf.RightVector end
                if Dir.Magnitude > 0 then Dir = Dir.Unit * FlySpeed end
                Dir += Move * FlyVertical
                Pp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                Pp.CFrame += Dir * 0.18
            end)
        else
            if FlyConn then FlyConn:Disconnect() FlyConn = nil end
            if IsAlive(LocalPlayer) then LocalPlayer.Character.PrimaryPart.Anchored = false end
        end
    end,
    Tooltip = "CFrame fly"
})
Fly:CreateSlider({
    Name = "Speed",
    Function = function(Value) FlySpeed = Value end,
    Min = 1,
    Max = 10,
    Default = 3
})
Fly:CreateSlider({
    Name = "Vertical",
    Function = function(Value) FlyVertical = Value end,
    Min = 1,
    Max = 10,
    Default = 3
})
local SpeedValue = 22
local SpeedConn = nil
local Speed = BlatantCategory:CreateModule({
    Name = "Speed",
    Function = function(Callback)
        if Callback then
            SpeedConn = RunService.Heartbeat:Connect(function()
                if SwiftUninjected or not IsAlive(LocalPlayer) then return end
                local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if Hum then Hum.WalkSpeed = SpeedValue end
            end)
        else
            if SpeedConn then SpeedConn:Disconnect() SpeedConn = nil end
            if IsAlive(LocalPlayer) then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end
        end
    end,
    Tooltip = "Increases speed"
})
Speed:CreateSlider({
    Name = "SpeedValue",
    Function = function(Value) SpeedValue = Value end,
    Min = 16,
    Max = 36,
    Default = 22
})
local StrafeRange = 14
local StrafeRadius = 8
local StrafeSpeed = 2
local StrafeConn = nil
local TargetStrafe = BlatantCategory:CreateModule({
    Name = "TargetStrafe",
    Function = function(Callback)
        if Callback then
            StrafeConn = RunService.Heartbeat:Connect(function()
                if SwiftUninjected or not IsAlive(LocalPlayer) then return end
                if not UserInputService:IsKeyDown(Enum.KeyCode.W) then return end
                local Target = FindNearestMonster(StrafeRange, true)
                if not Target or not Target.PrimaryPart then return end
                local Pp = LocalPlayer.Character.PrimaryPart
                local Center = Target.PrimaryPart.Position
                local Angle = tick() * StrafeSpeed
                local Pos = Vector3.new(Center.X + math.cos(Angle) * StrafeRadius, Pp.Position.Y, Center.Z + math.sin(Angle) * StrafeRadius)
                local Dir = (Pos - Pp.Position)
                if Dir.Magnitude > 0 then Pp.CFrame = CFrame.lookAt(Pos, Center) end
                Pp.AssemblyLinearVelocity = Dir.Unit * 18
            end)
        else
            if StrafeConn then StrafeConn:Disconnect() StrafeConn = nil end
        end
    end,
    Tooltip = "Orbits target"
})
TargetStrafe:CreateSlider({
    Name = "Range",
    Function = function(Value) StrafeRange = Value end,
    Min = 5,
    Max = 30,
    Default = 14
})
TargetStrafe:CreateSlider({
    Name = "Radius",
    Function = function(Value) StrafeRadius = Value end,
    Min = 4,
    Max = 16,
    Default = 8
})
TargetStrafe:CreateSlider({
    Name = "Speed",
    Function = function(Value) StrafeSpeed = Value end,
    Min = 1,
    Max = 6,
    Default = 2
})
local NoFall = BlatantCategory:CreateModule({
    Name = "NoFall",
    Function = function(Callback)
        if Callback then
            SwiftConnections.NoFall = RunService.Heartbeat:Connect(function()
                if SwiftUninjected or not IsAlive(LocalPlayer) then return end
                local Pp = LocalPlayer.Character.PrimaryPart
                if Pp.AssemblyLinearVelocity.Y < -60 then
                    local Params = RaycastParams.new()
                    Params.FilterDescendantsInstances = {LocalPlayer.Character}
                    Params.FilterType = Enum.RaycastFilterType.Exclude
                    local Ray = Workspace:Raycast(Pp.Position, Vector3.new(0, -12, 0), Params)
                    if Ray and Ray.Instance and Ray.Instance.CanCollide then
                        Pp.AssemblyLinearVelocity = Vector3.new(Pp.AssemblyLinearVelocity.X, -6, Pp.AssemblyLinearVelocity.Z)
                    end
                end
            end)
        else
            if SwiftConnections.NoFall then SwiftConnections.NoFall:Disconnect() SwiftConnections.NoFall = nil end
        end
    end,
    Tooltip = "Prevents fall damage"
})
local LongJump = BlatantCategory:CreateModule({
    Name = "LongJump",
    Function = function(Callback)
        if Callback then
            SwiftConnections.LongJump = UserInputService.InputBegan:Connect(function(Input, Gp)
                if Gp then return end
                if Input.KeyCode == Enum.KeyCode.F and IsAlive(LocalPlayer) then
                    LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity = Camera.CFrame.LookVector * 85 + Vector3.new(0, 28, 0)
                end
            end)
        else
            if SwiftConnections.LongJump then SwiftConnections.LongJump:Disconnect() SwiftConnections.LongJump = nil end
        end
    end,
    Tooltip = "Press F to jump"
})
local AntiStaff = UtilityCategory:CreateModule({
    Name = "AntiStaff",
    Function = function(Callback)
        if Callback then
            local function CheckStaff(Plr)
                local Ok, Rank = pcall(function() return Plr:GetRankInGroup(5774246) end)
                local IsStaff = Ok and Rank and Rank > 1
                if IsStaff then
                    Vape:CreateNotification("AntiStaff", Plr.Name .. " staff joined", 6, "alert")
                end
            end
            SwiftConnections.AntiStaffAdd = Players.PlayerAdded:Connect(CheckStaff)
            for _, Plr in ipairs(Players:GetPlayers()) do CheckStaff(Plr) end
        else
            if SwiftConnections.AntiStaffAdd then SwiftConnections.AntiStaffAdd:Disconnect() SwiftConnections.AntiStaffAdd = nil end
        end
    end,
    Tooltip = "Notifies staff only"
})
local AntiAfk = UtilityCategory:CreateModule({
    Name = "AntiAfk",
    Function = function(Callback)
        if Callback then
            SwiftConnections.AntiAfk = task.spawn(function()
                while not SwiftUninjected and AntiAfk.Enabled do
                    pcall(function()
                        local VirtualUser = game:GetService("VirtualUser")
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new())
                        local Remote = ReplicatedStorage:FindFirstChild("rbxts_include")
                        if Remote then
                            local R = Remote:FindFirstChild("out")
                            if R then
                                local N = R:FindFirstChild("_NetManaged")
                                if N then
                                    local Afk = N:FindFirstChild("AfkInfo")
                                    if Afk then Afk:FireServer({afk = false}) end
                                end
                            end
                        end
                    end)
                    task.wait(60)
                end
            end)
        else
            if SwiftConnections.AntiAfk then task.cancel(SwiftConnections.AntiAfk) SwiftConnections.AntiAfk = nil end
        end
    end,
    Tooltip = "Prevents afk"
})
local FovValue = 100
local FovChanger = UtilityCategory:CreateModule({
    Name = "FovChanger",
    Function = function(Callback)
        if Callback then
            TweenService:Create(Camera, TweenInfo.new(0.4), {FieldOfView = FovValue}):Play()
        else
            TweenService:Create(Camera, TweenInfo.new(0.4), {FieldOfView = 70}):Play()
        end
    end,
    Tooltip = "Changes FOV"
})
FovChanger:CreateSlider({
    Name = "Fov",
    Function = function(Value) FovValue = Value if FovChanger.Enabled then Camera.FieldOfView = Value end end,
    Min = 70,
    Max = 120,
    Default = 100
})
local AutoSprint = UtilityCategory:CreateModule({
    Name = "AutoSprint",
    Function = function(Callback)
        if Callback then
            SwiftConnections.AutoSprint = RunService.Heartbeat:Connect(function()
                if SwiftUninjected then return end
                pcall(function()
                    local Ctrl = require(LocalPlayer.PlayerScripts.TS.controllers.game.sprint["sprint-controller"]).SprintController
                    if Ctrl and Ctrl.startSprinting then Ctrl:startSprinting() end
                end)
            end)
        else
            if SwiftConnections.AutoSprint then SwiftConnections.AutoSprint:Disconnect() SwiftConnections.AutoSprint = nil end
        end
    end,
    Tooltip = "Always sprint"
})
local BlockEsp = WorldCategory:CreateModule({
    Name = "BlockEsp",
    Function = function(Callback)
        if Callback then
            SwiftConnections.BlockEsp = RunService.Heartbeat:Connect(function()
                if SwiftUninjected then return end
                for _, B in ipairs(CollectionService:GetTagged("block")) do
                    if not B:FindFirstChild("SwiftHighlight") then
                        local Hl = Instance.new("Highlight", B)
                        Hl.Name = "SwiftHighlight"
                        Hl.FillColor = Color3.fromRGB(124, 58, 237)
                        Hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        Hl.FillTransparency = 0.7
                        Hl.OutlineTransparency = 0.2
                        task.delay(1.2, function() if Hl then Hl:Destroy() end end)
                    end
                end
            end)
        else
            if SwiftConnections.BlockEsp then SwiftConnections.BlockEsp:Disconnect() SwiftConnections.BlockEsp = nil end
            for _, B in ipairs(CollectionService:GetTagged("block")) do
                local H = B:FindFirstChild("SwiftHighlight") if H then H:Destroy() end
            end
        end
    end,
    Tooltip = "Highlights blocks"
})
local NoNameTags = WorldCategory:CreateModule({
    Name = "NoNameTags",
    Function = function(Callback)
        for _, Plr in ipairs(Players:GetPlayers()) do
            if Plr.Character and Plr.Character:FindFirstChild("Head") and Plr.Character.Head:FindFirstChild("Nametag") then
                Plr.Character.Head.Nametag.Enabled = not Callback
            end
        end
        if Callback then
            SwiftConnections.NoNameTags = Players.PlayerAdded:Connect(function(Plr)
                Plr.CharacterAdded:Connect(function(Ch)
                    task.wait(1)
                    if Ch:FindFirstChild("Head") and Ch.Head:FindFirstChild("Nametag") then Ch.Head.Nametag.Enabled = false end
                end)
            end)
        else
            if SwiftConnections.NoNameTags then SwiftConnections.NoNameTags:Disconnect() SwiftConnections.NoNameTags = nil end
        end
    end,
    Tooltip = "Hides nametags"
})
local EspHighlights = {}
local function ApplyEsp(Plr)
    if Plr == LocalPlayer then return end
    if not Plr.Character then return end
    if EspHighlights[Plr] then EspHighlights[Plr]:Destroy() end
    local Hl = Instance.new("Highlight")
    Hl.FillColor = Plr.Team == LocalPlayer.Team and Color3.fromRGB(96, 165, 250) or Color3.fromRGB(248, 113, 113)
    Hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    Hl.FillTransparency = 0.5
    Hl.OutlineTransparency = 0.1
    Hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Hl.Parent = Plr.Character
    Hl.Adornee = Plr.Character
    EspHighlights[Plr] = Hl
end
local EspHue = 0
local EspSat = 1
local EspVal = 1
local Esp = RenderCategory:CreateModule({
    Name = "Esp",
    Function = function(Callback)
        if Callback then
            for _, Plr in ipairs(Players:GetPlayers()) do pcall(ApplyEsp, Plr) end
            SwiftConnections.EspAdd = Players.PlayerAdded:Connect(function(Plr) Plr.CharacterAdded:Connect(function() task.wait(1) if Esp.Enabled then pcall(ApplyEsp, Plr) end end) end)
            SwiftConnections.EspLoop = RunService.Heartbeat:Connect(function()
                if SwiftUninjected then return end
                for Plr, Hl in pairs(EspHighlights) do
                    if Plr.Character and Hl.Parent ~= Plr.Character then Hl.Adornee = Plr.Character Hl.Parent = Plr.Character end
                end
            end)
        else
            for _, Hl in pairs(EspHighlights) do Hl:Destroy() end
            table.clear(EspHighlights)
            if SwiftConnections.EspAdd then SwiftConnections.EspAdd:Disconnect() SwiftConnections.EspAdd = nil end
            if SwiftConnections.EspLoop then SwiftConnections.EspLoop:Disconnect() SwiftConnections.EspLoop = nil end
        end
    end,
    Tooltip = "Highlights players"
})
Esp:CreateColorSlider({
    Name = "EnemyColor",
    Function = function(Hue, Sat, Val) EspHue = Hue EspSat = Sat EspVal = Val end
})
local Cape = RenderCategory:CreateModule({
    Name = "Cape",
    Function = function(Callback)
        if not IsAlive(LocalPlayer) then return end
        local Char = LocalPlayer.Character
        if Callback then
            if Char:FindFirstChild("SwiftCape") then return end
            local Part = Instance.new("Part", Char)
            Part.Name = "SwiftCape"
            Part.Size = Vector3.new(1.8, 2.4, 0.15)
            Part.Massless = true
            Part.CanCollide = false
            Part.Material = Enum.Material.SmoothPlastic
            Part.Color = Color3.fromRGB(124, 58, 237)
            local Weld = Instance.new("WeldConstraint", Part)
            Weld.Part0 = Char:FindFirstChild("UpperTorso") or Char:FindFirstChild("Torso")
            Weld.Part1 = Part
            Part.CFrame = Weld.Part0.CFrame * CFrame.new(0, -0.2, -0.9)
        else
            local C = Char:FindFirstChild("SwiftCape") if C then C:Destroy() end
        end
    end,
    Tooltip = "Shows cape"
})
local MouseTp = UtilityCategory:CreateModule({
    Name = "MouseTp",
    Function = function(Callback)
        if Callback then
            SwiftConnections.MouseTp = UserInputService.InputBegan:Connect(function(Input, Gp)
                if Gp then return end
                if Input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and IsAlive(LocalPlayer) then
                    local MouseLoc = LocalPlayer:GetMouse()
                    local UnitRay = Camera:ScreenPointToRay(MouseLoc.X, MouseLoc.Y)
                    local Params = RaycastParams.new()
                    Params.FilterDescendantsInstances = {LocalPlayer.Character}
                    Params.FilterType = Enum.RaycastFilterType.Exclude
                    local Ray = Workspace:Raycast(UnitRay.Origin, UnitRay.Direction * 1200, Params)
                    if Ray then LocalPlayer.Character.PrimaryPart.CFrame = CFrame.new(Ray.Position + Vector3.new(0, 3, 0)) end
                end
            end)
        else
            if SwiftConnections.MouseTp then SwiftConnections.MouseTp:Disconnect() SwiftConnections.MouseTp = nil end
        end
    end,
    Tooltip = "Ctrl Click tp"
})
local FpsBoost = UtilityCategory:CreateModule({
    Name = "FpsBoost",
    Function = function(Callback)
        if Callback then
            for _, V in ipairs(Lighting:GetChildren()) do if V:IsA("BlurEffect") or V:IsA("DepthOfFieldEffect") or V:IsA("SunRays") then V.Enabled = false end end
            Workspace.Terrain.WaterWaveSize = 0
        end
    end,
    Tooltip = "Disables effects"
})
local UnInject = UtilityCategory:CreateModule({
    Name = "UnInject",
    Function = function(Callback)
        if Callback then
            SwiftUninjected = true
            for _, C in pairs(SwiftConnections) do pcall(function() if typeof(C) == "RBXScriptConnection" then C:Disconnect() else task.cancel(C) end end) end
            Vape:Uninject()
        end
    end,
    Tooltip = "Destroys gui"
})
Vape:CreateNotification("SwiftVape", "Loaded RightShift to toggle", 4, "info")
