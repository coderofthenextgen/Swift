local _version = "1.7.0"
local Fluent = loadstring(game:HttpGet("https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentPro"))()

local swiftRepo = 'https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/'
local v = '?v=' .. tostring(os.time())

local function safeLoad(url)
    local src = game:HttpGet(url)
    local fn, err = loadstring(src)
    if not fn then
        error('Failed to compile ' .. url .. '\nError: ' .. tostring(err))
    end
    return fn()
end

local DrawingLib = safeLoad(swiftRepo .. 'libs/drawinglib.lua' .. v)
local EntityLib = safeLoad(swiftRepo .. 'libs/entitylib.lua' .. v)
local JanitorLib = safeLoad(swiftRepo .. 'libs/janitor.lua' .. v)

local Players = cloneref(game:GetService('Players'))
cache.invalidate(Players)
local RunService = cloneref(game:GetService('RunService'))
cache.invalidate(RunService)
local UserInputService = cloneref(game:GetService('UserInputService'))
cache.invalidate(UserInputService)
local Lighting = cloneref(game:GetService('Lighting'))
cache.invalidate(Lighting)
local StarterGui = cloneref(game:GetService('StarterGui'))
cache.invalidate(StarterGui)
local Workspace = cloneref(game:GetService('Workspace'))
cache.invalidate(Workspace)
local TweenService = cloneref(game:GetService('TweenService'))
cache.invalidate(TweenService)
local HttpService = cloneref(game:GetService('HttpService'))
cache.invalidate(HttpService)
local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
cache.invalidate(ReplicatedStorage)
local ReplicatedFirst = cloneref(game:GetService('ReplicatedFirst'))
cache.invalidate(ReplicatedFirst)
local ContextActionService = cloneref(game:GetService('ContextActionService'))
cache.invalidate(ContextActionService)
local GuiService = cloneref(game:GetService('GuiService'))
cache.invalidate(GuiService)
local TeleportService = cloneref(game:GetService('TeleportService'))
cache.invalidate(TeleportService)
local SoundService = cloneref(game:GetService('SoundService'))
cache.invalidate(SoundService)
local Camera = cloneref(Workspace.CurrentCamera)
cache.invalidate(Camera)

local Raycast = clonefunction(Workspace.Raycast)
local GetPlayers = clonefunction(Players.GetPlayers)
local FindFirstChild = clonefunction(game.FindFirstChild)
local FindFirstChildOfClass = clonefunction(game.FindFirstChildOfClass)
local IsA = clonefunction(game.IsA)
local WaitForChild = clonefunction(game.WaitForChild)
local InstanceNew = clonefunction(Instance.new)

local LocalPlayer = Players.LocalPlayer
local isBoosting = false

getgenv().__HITBOX__ = {hooks = {}, spoofed = {}, originals = {}}
getgenv().WalkSpeedSpoof = {}
getgenv().JumpPowerSpoof = {}

local Drawing = DrawingLib
local EntityLib = EntityLib
local Janitor = JanitorLib

local janitor = Janitor.new()

local split = string.split
local GetDebugIdHandler = Instance.new("BindableFunction")
local TempHumanoid = Instance.new("Humanoid")
local cachedhumanoids = {}
local CurrentHumanoid
local newindexhook
local indexhook

function GetDebugIdHandler.OnInvoke(obj)
    return obj:GetDebugId()
end

local function GetDebugId(obj)
    return GetDebugIdHandler:Invoke(obj)
end

local function GetWalkSpeed(obj)
    TempHumanoid.WalkSpeed = obj
    return TempHumanoid.WalkSpeed
end

local function GetJumpPower(obj)
    TempHumanoid.JumpPower = obj
    return TempHumanoid.JumpPower
end

function cachedhumanoids:cacheHumanoid(DebugId, Humanoid)
    cachedhumanoids[DebugId] = {
        currentWalkSpeed = indexhook(Humanoid, "WalkSpeed"),
        currentJumpPower = indexhook(Humanoid, "JumpPower"),
        lastWalkSpeed = nil,
        lastJumpPower = nil
    }
    return self[DebugId]
end

indexhook = hookmetamethod(game, "__index", newcclosure(function(self, index)
    if not checkcaller() and typeof(self) == "Instance" then
        if self:IsA("Humanoid") then
            local DebugId = GetDebugId(self)
            local cached = cachedhumanoids[DebugId]

            if self:IsDescendantOf(LocalPlayer.Character) or cached then
                if type(index) == "string" then
                    local cleanindex = split(index, "\0")[1]

                    if cleanindex == "WalkSpeed" then
                        if not cached then
                            cached = cachedhumanoids:cacheHumanoid(DebugId, self)
                        end

                        if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                            CurrentHumanoid = cloneref(self)
                            cache.invalidate(CurrentHumanoid)
                        end

                        return cached.lastWalkSpeed or cached.currentWalkSpeed
                    elseif cleanindex == "JumpPower" then
                        if not cached then
                            cached = cachedhumanoids:cacheHumanoid(DebugId, self)
                        end

                        if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                            CurrentHumanoid = cloneref(self)
                            cache.invalidate(CurrentHumanoid)
                        end

                        return cached.lastJumpPower or cached.currentJumpPower
                    end
                end
            end
        end
    end

    return indexhook(self, index)
end))

newindexhook = hookmetamethod(game, "__newindex", newcclosure(function(self, index, newindex)
    if not checkcaller() and typeof(self) == "Instance" then
        if self:IsA("Humanoid") then
            local DebugId = GetDebugId(self)
            local cached = cachedhumanoids[DebugId]

            if self:IsDescendantOf(LocalPlayer.Character) or cached then
                if type(index) == "string" then
                    local cleanindex = split(index, "\0")[1]

                    if cleanindex == "WalkSpeed" then
                        if not cached then
                            cached = cachedhumanoids:cacheHumanoid(DebugId, self)
                        end

                        if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                            CurrentHumanoid = cloneref(self)
                            cache.invalidate(CurrentHumanoid)
                        end
                        cached.lastWalkSpeed = GetWalkSpeed(newindex)
                        return CurrentHumanoid.WalkSpeed
                    elseif cleanindex == "JumpPower" then
                        if not cached then
                            cached = cachedhumanoids:cacheHumanoid(DebugId, self)
                        end

                        if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                            CurrentHumanoid = cloneref(self)
                            cache.invalidate(CurrentHumanoid)
                        end
                        cached.lastJumpPower = GetJumpPower(newindex)
                        return CurrentHumanoid.JumpPower
                    end
                end
            end
        end
    end

    return newindexhook(self, index, newindex)
end))

getgenv().WalkSpeedSpoof.GetHumanoid = function()
    return CurrentHumanoid or (function()
        local char = LocalPlayer.Character
        local Humanoid = char and char:FindFirstChildWhichIsA("Humanoid") or nil

        if Humanoid then
            cachedhumanoids:cacheHumanoid(Humanoid:GetDebugId(), Humanoid)
            local ref = cloneref(Humanoid)
            cache.invalidate(ref)
            return ref
        end
    end)()
end

getgenv().WalkSpeedSpoof.SetWalkSpeed = function(speed)
    local Humanoid = getgenv().WalkSpeedSpoof.GetHumanoid()

    if Humanoid then
        local ref = cloneref(Humanoid)
        cache.invalidate(ref)
        local connections = {}
        local function AddConnectionsFromSignal(Signal)
            for i, v in getconnections(Signal) do
                if v.State then
                    v:Disable()
                    table.insert(connections, v)
                end
            end
        end
        AddConnectionsFromSignal(Humanoid.Changed)
        AddConnectionsFromSignal(Humanoid:GetPropertyChangedSignal("WalkSpeed"))
        Humanoid.WalkSpeed = speed
        for i, v in connections do
            v:Enable()
        end
    end
end

getgenv().JumpPowerSpoof.SetJumpPower = function(power)
    local Humanoid = getgenv().WalkSpeedSpoof.GetHumanoid()

    if Humanoid then
        local ref = cloneref(Humanoid)
        cache.invalidate(ref)
        local connections = {}
        local function AddConnectionsFromSignal(Signal)
            for i, v in getconnections(Signal) do
                if v.State then
                    v:Disable()
                    table.insert(connections, v)
                end
            end
        end
        AddConnectionsFromSignal(Humanoid.Changed)
        AddConnectionsFromSignal(Humanoid:GetPropertyChangedSignal("JumpPower"))
        Humanoid.JumpPower = power
        for i, v in connections do
            v:Enable()
        end
    end
end

getgenv().WalkSpeedSpoof.RestoreWalkSpeed = function()
    local Humanoid = getgenv().WalkSpeedSpoof.GetHumanoid()

    if Humanoid then
        local cached = cachedhumanoids[Humanoid:GetDebugId()]

        if cached then
            getgenv().WalkSpeedSpoof.SetWalkSpeed(cached.lastWalkSpeed or cached.currentWalkSpeed)
        end
    end
end

getgenv().JumpPowerSpoof.RestoreJumpPower = function()
    local Humanoid = getgenv().WalkSpeedSpoof.GetHumanoid()

    if Humanoid then
        local cached = cachedhumanoids[Humanoid:GetDebugId()]

        if cached then
            getgenv().JumpPowerSpoof.SetJumpPower(cached.lastJumpPower or cached.currentJumpPower)
        end
    end
end

local function getCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    local hum = char:FindFirstChildOfClass('Humanoid')
    if not hrp or not hum then return nil end
    return char, hrp, hum
end

getgenv().Originals = {
    WalkSpeed = 16,
    JumpPower = 50,
    JumpHeight = 7.2,
    HipHeight = 0,
    FOV = Workspace.CurrentCamera.FieldOfView,
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
}

local function storeOriginals()
    local char, hrp, hum = getCharacter()
    if hum then
        Originals.WalkSpeed = hum.WalkSpeed
        Originals.JumpPower = hum.JumpPower
        Originals.JumpHeight = hum.JumpHeight
        Originals.HipHeight = hum.HipHeight
    end
    Originals.FOV = Workspace.CurrentCamera.FieldOfView
    Originals.Brightness = Lighting.Brightness
    Originals.GlobalShadows = Lighting.GlobalShadows
    Originals.FogEnd = Lighting.FogEnd
    Originals.FogStart = Lighting.FogStart
    Originals.Ambient = Lighting.Ambient
    Originals.OutdoorAmbient = Lighting.OutdoorAmbient
    Originals.ClockTime = Lighting.ClockTime
end

task.delay(1, storeOriginals)

local Window = Fluent:CreateWindow({
    Title = "Swift Hub",
    SubTitle = "by coderofthenextgen",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Galaxy Purple",
    MinimizeKey = Enum.KeyCode.RightShift,
    Search = true,
    User = {
        Enabled = true,
        Title = LocalPlayer.Name,
        Subtitle = "ID: " .. LocalPlayer.UserId,
        Round = true,
    },
})

local MainTab = Window:AddTab({ Title = "Main", Icon = "solar/home-bold" })
local CombatTab = Window:AddTab({ Title = "Combat", Icon = "solar/target-bold" })
local VisualsTab = Window:AddTab({ Title = "Visuals", Icon = "solar/eye-bold" })
local ExploitsTab = Window:AddTab({ Title = "Exploits", Icon = "solar/code-bold" })
local MiscTab = Window:AddTab({ Title = "Misc", Icon = "solar/settings-bold" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "solar/cog-bold" })

getgenv().SpeedEnabled = false
getgenv().SpeedMethod = 'Velocity'
getgenv().MoveDirection = 'MoveDirection'
getgenv().SpeedValue = 50
getgenv().HeatseekerDuration = 0.3
getgenv().HeatseekerTicks = 0.3
getgenv().SpeedKeybind = 'None'

getgenv().MouseTPEnabled = false
getgenv().MouseTPMode = 'Instant'
getgenv().MouseTPMethod = 'CFrame'
getgenv().TweenSpeed = 1
getgenv().TPHeight = 3
getgenv().MouseTPKeybind = 'None'

getgenv().NoclipEnabled = false
getgenv().NoclipMode = 'Character'
getgenv().NoclipParts = {['Head'] = true}
getgenv().NoclipKeybind = 'None'

getgenv().JumpEnabled = false
getgenv().JumpProperty = 'JumpPower'
getgenv().JumpMethod = 'DirectSet'
getgenv().JumpValue = 100
getgenv().JumpKeybind = 'None'

getgenv().HitboxEnabled = false
getgenv().HitboxSize = 5
getgenv().HitboxShow = false
getgenv().HitboxColor = Color3.fromRGB(255, 0, 0)
getgenv().HitboxKeybind = 'None'

getgenv().TriggerbotEnabled = false
getgenv().TriggerbotWallCheck = true
getgenv().TriggerbotDelay = 0.1
getgenv().TriggerbotKeybind = 'None'

getgenv().AimbotEnabled = false
getgenv().AimbotMode = 'Hold'
getgenv().AimbotTargetPart = 'Head'
getgenv().AimbotTargetMode = 'Nearest'
getgenv().AimbotFOV = 150
getgenv().AimbotSmoothness = 10
getgenv().AimbotPrediction = 0.1
getgenv().AimbotShowFOV = true
getgenv().AimbotTeamCheck = false
getgenv().AimbotAliveCheck = false
getgenv().AimbotWallCheck = false
getgenv().AimbotSilentAim = false
getgenv().AimbotSticky = false
getgenv().AimbotKeybind = 'Q'

getgenv().ACBypassEnabled = false
getgenv().ACWalkSpeed = 16
getgenv().ACJumpPower = 50
getgenv().ACJumpHeight = 7.2
getgenv().ACBypassKeybind = 'None'

getgenv().FlyEnabled = false
getgenv().FlyMethod = 'CFrame'
getgenv().FlySpeed = 50
getgenv().FlyVerticalSpeed = 50
getgenv().FlyUpKey = 'Space'
getgenv().FlyDownKey = 'LeftShift'
getgenv().FlyAutoDisable = true
getgenv().FlyKeybind = 'None'

getgenv().InfJumpEnabled = false
getgenv().InfJumpHeight = 50
getgenv().InfJumpType = 'Velocity'
getgenv().InfJumpMethod = 'Hold'
getgenv().InfJumpKeybind = 'None'

getgenv().SpinbotEnabled = false
getgenv().SpinAxis = 'Y'
getgenv().SpinSpeed = 50
getgenv().SpinbotKeybind = 'None'

getgenv().AntiAFKEnabled = false
getgenv().AntiAFKMethod = 'Click'
getgenv().AntiAFKInterval = 60
getgenv().AntiAFKKeybind = 'None'

getgenv().MiscFOVEnabled = false
getgenv().MiscFOVValue = 70

getgenv().ChamsEnabled = false
getgenv().ChamsMode = 'Highlight'
getgenv().ChamsTarget = {['All'] = true}
getgenv().ChamsFillColor = Color3.fromRGB(255, 0, 0)
getgenv().ChamsFillTransparency = 0.5
getgenv().ChamsOutlineColor = Color3.fromRGB(255, 255, 255)
getgenv().ChamsOutlineTransparency = 0
getgenv().ChamsMaterial = 'ForceField'
getgenv().ChamsThroughWalls = true
getgenv().ChamsOccluded = true
getgenv().ChamsKeybind = 'None'

getgenv().FullbrightEnabled = false
getgenv().NoFogEnabled = false
getgenv().BrightnessValue = 2
getgenv().AmbientColor = Originals.Ambient

getgenv().ESPEnabled = false
getgenv().ESPItems = {['Box'] = true}
getgenv().ESPColor = Color3.fromRGB(255, 255, 255)
getgenv().ESPHealthLow = Color3.fromRGB(255, 0, 0)
getgenv().ESPHealthHigh = Color3.fromRGB(0, 255, 0)
getgenv().ESPTeamColor = Color3.fromRGB(0, 255, 0)
getgenv().ESPEnemyColor = Color3.fromRGB(255, 255, 255)
getgenv().ESPFont = 'Code'
getgenv().ESPThickness = 1
getgenv().ESPTextSize = 16
getgenv().ESPMaxDistance = 1000
getgenv().ESPShowTeam = true
getgenv().ESPKeybind = 'None'

getgenv().MenuKeybind = 'RightShift'


MainTab:AddParagraph({ Title = "Profile", Content = "Player: " .. LocalPlayer.Name .. "\nID: " .. LocalPlayer.UserId .. "\nGame: " .. game.Name .. "\nServer Time: " .. os.date("%H:%M:%S") })

local SpeedSection = MainTab:AddCollapsibleSection({ Title = "Speed" })

SpeedSection:AddToggle("speedEnabled", {
    Title = "Enable Speed",
    Default = false,
    Callback = function(state)
        getgenv().SpeedEnabled = state
        if not state then
            isBoosting = false
            getgenv().WalkSpeedSpoof.RestoreWalkSpeed()
        end
    end
})

SpeedSection:AddKeybind("speedKeybind", {
    Title = "Speed Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().SpeedKeybind = key
        if key ~= "None" then
            getgenv().SpeedEnabled = not getgenv().SpeedEnabled
            if not getgenv().SpeedEnabled then
                isBoosting = false
                getgenv().WalkSpeedSpoof.RestoreWalkSpeed()
            end
        end
    end
})

SpeedSection:AddDropdown("speedMethod", {
    Title = "Speed Method",
    Values = {"Velocity", "WalkSpeed", "Impulse", "Heatseeker"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().SpeedMethod = selected
    end
})

SpeedSection:AddDropdown("moveDirection", {
    Title = "Move Direction",
    Values = {"MoveDirection", "DirectMove"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().MoveDirection = selected
    end
})

SpeedSection:AddSlider("speedValue", {
    Title = "Speed",
    Default = 50,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        getgenv().SpeedValue = value
    end
})

SpeedSection:AddSlider("heatseekerDuration", {
    Title = "Duration",
    Default = 0.3,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(value)
        getgenv().HeatseekerDuration = value
    end
})

SpeedSection:AddSlider("heatseekerTicks", {
    Title = "Ticks",
    Default = 0.3,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(value)
        getgenv().HeatseekerTicks = value
    end
})

local JumpSection = MainTab:AddCollapsibleSection({ Title = "Jump" })

JumpSection:AddToggle("jumpEnabled", {
    Title = "Enable Jump",
    Default = false,
    Callback = function(state)
        getgenv().JumpEnabled = state
        if not state then
            getgenv().JumpPowerSpoof.RestoreJumpPower()
            local char, hrp, hum = getCharacter()
            if hum then
                hum.JumpHeight = Originals.JumpHeight
            end
        end
    end
})

JumpSection:AddKeybind("jumpKeybind", {
    Title = "Jump Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().JumpKeybind = key
        if key ~= "None" then
            getgenv().JumpEnabled = not getgenv().JumpEnabled
        end
    end
})

JumpSection:AddDropdown("jumpProperty", {
    Title = "Jump Property",
    Values = {"JumpPower", "JumpHeight"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().JumpProperty = selected
    end
})

JumpSection:AddDropdown("jumpMethod", {
    Title = "Jump Method",
    Values = {"DirectSet", "Velocity", "CFrame"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().JumpMethod = selected
    end
})

JumpSection:AddSlider("jumpValue", {
    Title = "Jump Value",
    Default = 100,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        getgenv().JumpValue = value
    end
})

local NoclipSection = MainTab:AddCollapsibleSection({ Title = "Noclip" })

NoclipSection:AddToggle("noclipEnabled", {
    Title = "Enable Noclip",
    Default = false,
    Callback = function(state)
        getgenv().NoclipEnabled = state
    end
})

NoclipSection:AddKeybind("noclipKeybind", {
    Title = "Noclip Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().NoclipKeybind = key
        if key ~= "None" then
            getgenv().NoclipEnabled = not getgenv().NoclipEnabled
        end
    end
})

NoclipSection:AddDropdown("noclipMode", {
    Title = "Noclip Mode",
    Values = {"Character", "Part", "CollisionGroup"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().NoclipMode = selected
    end
})

NoclipSection:AddDropdown("noclipParts", {
    Title = "Body Parts",
    Values = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().NoclipParts = {[selected] = true}
    end
})

local FlySection = MainTab:AddCollapsibleSection({ Title = "Fly" })

FlySection:AddToggle("flyEnabled", {
    Title = "Enable Fly",
    Default = false,
    Callback = function(state)
        getgenv().FlyEnabled = state
    end
})

FlySection:AddKeybind("flyKeybind", {
    Title = "Fly Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().FlyKeybind = key
        if key ~= "None" then
            getgenv().FlyEnabled = not getgenv().FlyEnabled
        end
    end
})

FlySection:AddDropdown("flyMethod", {
    Title = "Fly Method",
    Values = {"CFrame", "Velocity", "BodyVelocity", "LinearVelocity"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().FlyMethod = selected
    end
})

FlySection:AddSlider("flySpeed", {
    Title = "Horizontal Speed",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(value)
        getgenv().FlySpeed = value
    end
})

FlySection:AddSlider("flyVerticalSpeed", {
    Title = "Vertical Speed",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(value)
        getgenv().FlyVerticalSpeed = value
    end
})

FlySection:AddKeybind("flyUpKey", {
    Title = "Up Key",
    Default = "Space",
    Callback = function(key)
        getgenv().FlyUpKey = key
    end
})

FlySection:AddKeybind("flyDownKey", {
    Title = "Down Key",
    Default = "LeftShift",
    Callback = function(key)
        getgenv().FlyDownKey = key
    end
})

FlySection:AddToggle("flyAutoDisable", {
    Title = "Auto Disable on Death",
    Default = true,
    Callback = function(state)
        getgenv().FlyAutoDisable = state
    end
})

local InfJumpSection = MainTab:AddCollapsibleSection({ Title = "Infinite Jump" })

InfJumpSection:AddToggle("infJumpEnabled", {
    Title = "Enable Infinite Jump",
    Default = false,
    Callback = function(state)
        getgenv().InfJumpEnabled = state
    end
})

InfJumpSection:AddKeybind("infJumpKeybind", {
    Title = "Inf Jump Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().InfJumpKeybind = key
        if key ~= "None" then
            getgenv().InfJumpEnabled = not getgenv().InfJumpEnabled
        end
    end
})

InfJumpSection:AddDropdown("infJumpMethod", {
    Title = "Jump Method",
    Values = {"Hold", "Once"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().InfJumpMethod = selected
    end
})

InfJumpSection:AddSlider("infJumpHeight", {
    Title = "Jump Height",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        getgenv().InfJumpHeight = value
    end
})

InfJumpSection:AddDropdown("infJumpType", {
    Title = "Jump Type",
    Values = {"Velocity", "CFrame", "BodyVelocity"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().InfJumpType = selected
    end
})


local AimbotSection = CombatTab:AddCollapsibleSection({ Title = "Aimbot" })

AimbotSection:AddToggle("aimbotEnabled", {
    Title = "Enable Aimbot",
    Default = false,
    Callback = function(state)
        getgenv().AimbotEnabled = state
        if not state then
            getgenv().CamlockEnabled = false
            getgenv().TargetPlayer = nil
            if getgenv().aimbotFOVCircle then
                getgenv().aimbotFOVCircle.Visible = false
            end
        end
    end
})

AimbotSection:AddDropdown("aimbotMode", {
    Title = "Aimbot Mode",
    Values = {"Hold"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().AimbotMode = selected
    end
})

AimbotSection:AddKeybind("aimbotKeybind", {
    Title = "Aimbot Keybind",
    Default = "Q",
    Callback = function(key)
        getgenv().AimbotKeybind = key
    end
})

AimbotSection:AddDropdown("aimbotTargetPart", {
    Title = "Target Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().AimbotTargetPart = selected
    end
})

AimbotSection:AddDropdown("aimbotTargetMode", {
    Title = "Target Mode",
    Values = {"Nearest", "Crosshair", "Lowest Health"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().AimbotTargetMode = selected
    end
})

AimbotSection:AddSlider("aimbotFOV", {
    Title = "FOV",
    Default = 150,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        getgenv().AimbotFOV = value
    end
})

AimbotSection:AddSlider("aimbotSmoothness", {
    Title = "Smoothness",
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Callback = function(value)
        getgenv().AimbotSmoothness = value
    end
})

AimbotSection:AddSlider("aimbotPrediction", {
    Title = "Prediction",
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(value)
        getgenv().AimbotPrediction = value
    end
})

AimbotSection:AddToggle("aimbotShowFOV", {
    Title = "Show FOV Circle",
    Default = true,
    Callback = function(state)
        getgenv().AimbotShowFOV = state
    end
})

AimbotSection:AddToggle("aimbotTeamCheck", {
    Title = "Team Check",
    Default = false,
    Callback = function(state)
        getgenv().AimbotTeamCheck = state
    end
})

AimbotSection:AddToggle("aimbotAliveCheck", {
    Title = "Alive Check",
    Default = false,
    Callback = function(state)
        getgenv().AimbotAliveCheck = state
    end
})

AimbotSection:AddToggle("aimbotWallCheck", {
    Title = "Wall Check",
    Default = false,
    Callback = function(state)
        getgenv().AimbotWallCheck = state
    end
})

AimbotSection:AddToggle("aimbotSilentAim", {
    Title = "Silent Aim",
    Default = false,
    Callback = function(state)
        getgenv().AimbotSilentAim = state
    end
})

AimbotSection:AddToggle("aimbotSticky", {
    Title = "Sticky",
    Default = false,
    Callback = function(state)
        getgenv().AimbotSticky = state
    end
})

local TriggerbotSection = CombatTab:AddCollapsibleSection({ Title = "Triggerbot" })

TriggerbotSection:AddToggle("triggerbotEnabled", {
    Title = "Enable Triggerbot",
    Default = false,
    Callback = function(state)
        getgenv().TriggerbotEnabled = state
    end
})

TriggerbotSection:AddKeybind("triggerbotKeybind", {
    Title = "Triggerbot Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().TriggerbotKeybind = key
        if key ~= "None" then
            getgenv().TriggerbotEnabled = not getgenv().TriggerbotEnabled
        end
    end
})

TriggerbotSection:AddToggle("triggerbotWallCheck", {
    Title = "Wall Check",
    Default = true,
    Callback = function(state)
        getgenv().TriggerbotWallCheck = state
    end
})

TriggerbotSection:AddSlider("triggerbotDelay", {
    Title = "Click Delay",
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(value)
        getgenv().TriggerbotDelay = value
    end
})

local HitboxSection = CombatTab:AddCollapsibleSection({ Title = "Hitbox Extender" })

HitboxSection:AddToggle("hitboxEnabled", {
    Title = "Enable Hitbox",
    Default = false,
    Callback = function(state)
        getgenv().HitboxEnabled = state
    end
})

HitboxSection:AddKeybind("hitboxKeybind", {
    Title = "Hitbox Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().HitboxKeybind = key
        if key ~= "None" then
            getgenv().HitboxEnabled = not getgenv().HitboxEnabled
        end
    end
})

HitboxSection:AddSlider("hitboxSize", {
    Title = "Hitbox Size",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Callback = function(value)
        getgenv().HitboxSize = value
    end
})

HitboxSection:AddToggle("hitboxShow", {
    Title = "Show Hitbox",
    Default = false,
    Callback = function(state)
        getgenv().HitboxShow = state
    end
})

HitboxSection:AddColorpicker("hitboxColor", {
    Title = "Hitbox Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        getgenv().HitboxColor = color
    end
})

local SpinbotSection = CombatTab:AddCollapsibleSection({ Title = "Spinbot" })

SpinbotSection:AddToggle("spinbotEnabled", {
    Title = "Enable Spinbot",
    Default = false,
    Callback = function(state)
        getgenv().SpinbotEnabled = state
    end
})

SpinbotSection:AddKeybind("spinbotKeybind", {
    Title = "Spinbot Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().SpinbotKeybind = key
        if key ~= "None" then
            getgenv().SpinbotEnabled = not getgenv().SpinbotEnabled
        end
    end
})

SpinbotSection:AddDropdown("spinAxis", {
    Title = "Spin Axis",
    Values = {"Y", "X", "Z", "Random"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().SpinAxis = selected
    end
})

SpinbotSection:AddSlider("spinSpeed", {
    Title = "Spin Speed",
    Default = 50,
    Min = 1,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        getgenv().SpinSpeed = value
    end
})


local ChamsSection = VisualsTab:AddCollapsibleSection({ Title = "Chams" })

ChamsSection:AddToggle("chamsEnabled", {
    Title = "Enable Chams",
    Default = false,
    Callback = function(state)
        getgenv().ChamsEnabled = state
    end
})

ChamsSection:AddKeybind("chamsKeybind", {
    Title = "Chams Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().ChamsKeybind = key
        if key ~= "None" then
            getgenv().ChamsEnabled = not getgenv().ChamsEnabled
        end
    end
})

ChamsSection:AddDropdown("chamsMode", {
    Title = "Chams Mode",
    Values = {"Highlight", "Material", "Engine"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().ChamsMode = selected
    end
})

ChamsSection:AddDropdown("chamsTarget", {
    Title = "Chams Target",
    Values = {"All", "Head", "Body", "Arms", "Legs", "HumanoidRootPart"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().ChamsTarget = {[selected] = true}
    end
})

ChamsSection:AddColorpicker("chamsFillColor", {
    Title = "Chams Fill",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        getgenv().ChamsFillColor = color
    end
})

ChamsSection:AddSlider("chamsFillTransparency", {
    Title = "Fill Transparency",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(value)
        getgenv().ChamsFillTransparency = value
    end
})

ChamsSection:AddColorpicker("chamsOutlineColor", {
    Title = "Chams Outline",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        getgenv().ChamsOutlineColor = color
    end
})

ChamsSection:AddSlider("chamsOutlineTransparency", {
    Title = "Outline Transparency",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(value)
        getgenv().ChamsOutlineTransparency = value
    end
})

ChamsSection:AddDropdown("chamsMaterial", {
    Title = "Engine Material",
    Values = {"ForceField", "Neon", "Glass", "SmoothPlastic", "DiamondPlate", "Chrome", "WoodPlanks", "Marble", "Granite", "Cobblestone", "Brick", "Sand", "Grass"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().ChamsMaterial = selected
    end
})

ChamsSection:AddToggle("chamsThroughWalls", {
    Title = "Through Walls",
    Default = true,
    Callback = function(state)
        getgenv().ChamsThroughWalls = state
    end
})

ChamsSection:AddToggle("chamsOccluded", {
    Title = "Occluded",
    Default = true,
    Callback = function(state)
        getgenv().ChamsOccluded = state
    end
})

local ESPSection = VisualsTab:AddCollapsibleSection({ Title = "ESP" })

ESPSection:AddToggle("espEnabled", {
    Title = "Enable ESP",
    Default = false,
    Callback = function(state)
        getgenv().ESPEnabled = state
        if not state then
            removeAllESPObjects()
        end
    end
})

ESPSection:AddKeybind("espKeybind", {
    Title = "ESP Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().ESPKeybind = key
        if key ~= "None" then
            getgenv().ESPEnabled = not getgenv().ESPEnabled
            if not getgenv().ESPEnabled then
                removeAllESPObjects()
            end
        end
    end
})

ESPSection:AddDropdown("espElements", {
    Title = "ESP Elements",
    Values = {"Box", "Name", "Health", "Distance", "Tracers", "LookAngle", "Skeleton", "Tool"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().ESPItems = {[selected] = true}
    end
})

ESPSection:AddColorpicker("espColor", {
    Title = "ESP Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        getgenv().ESPColor = color
    end
})

ESPSection:AddColorpicker("espHealthLow", {
    Title = "Health Low",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        getgenv().ESPHealthLow = color
    end
})

ESPSection:AddColorpicker("espHealthHigh", {
    Title = "Health High",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(color)
        getgenv().ESPHealthHigh = color
    end
})

ESPSection:AddColorpicker("espTeamColor", {
    Title = "Team Color",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(color)
        getgenv().ESPTeamColor = color
    end
})

ESPSection:AddColorpicker("espEnemyColor", {
    Title = "Enemy Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        getgenv().ESPEnemyColor = color
    end
})

ESPSection:AddDropdown("espFont", {
    Title = "Font",
    Values = {"Code", "ArialBold", "GothamBold", "Gotham", "Legacy", "Highway", "Cartoon", "SciFi"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().ESPFont = selected
    end
})

ESPSection:AddSlider("espThickness", {
    Title = "Line Thickness",
    Default = 1,
    Min = 1,
    Max = 3,
    Rounding = 0,
    Callback = function(value)
        getgenv().ESPThickness = value
    end
})

ESPSection:AddSlider("espTextSize", {
    Title = "Text Size",
    Default = 16,
    Min = 10,
    Max = 30,
    Rounding = 0,
    Callback = function(value)
        getgenv().ESPTextSize = value
    end
})

ESPSection:AddSlider("espMaxDistance", {
    Title = "Max Distance",
    Default = 1000,
    Min = 100,
    Max = 5000,
    Rounding = 0,
    Callback = function(value)
        getgenv().ESPMaxDistance = value
    end
})

ESPSection:AddToggle("espShowTeam", {
    Title = "Show Teammates",
    Default = true,
    Callback = function(state)
        getgenv().ESPShowTeam = state
    end
})

local LightingSection = VisualsTab:AddCollapsibleSection({ Title = "Lighting" })

LightingSection:AddToggle("fullbrightEnabled", {
    Title = "Fullbright",
    Default = false,
    Callback = function(state)
        getgenv().FullbrightEnabled = state
    end
})

LightingSection:AddToggle("noFogEnabled", {
    Title = "No Fog",
    Default = false,
    Callback = function(state)
        getgenv().NoFogEnabled = state
    end
})

LightingSection:AddSlider("brightnessValue", {
    Title = "Brightness",
    Default = 2,
    Min = 0,
    Max = 10,
    Rounding = 0,
    Callback = function(value)
        getgenv().BrightnessValue = value
    end
})

LightingSection:AddColorpicker("ambientColor", {
    Title = "Ambient Color",
    Default = Originals.Ambient,
    Callback = function(color)
        getgenv().AmbientColor = color
    end
})

LightingSection:AddButton({
    Title = "Reset Lighting",
    Callback = function()
        Lighting.Brightness = Originals.Brightness
        Lighting.GlobalShadows = Originals.GlobalShadows
        Lighting.FogEnd = Originals.FogEnd
        Lighting.FogStart = Originals.FogStart
        Lighting.Ambient = Originals.Ambient
        Lighting.OutdoorAmbient = Originals.OutdoorAmbient
        Lighting.ClockTime = Originals.ClockTime
    end
})


local MouseTPSection = ExploitsTab:AddCollapsibleSection({ Title = "Mouse TP" })

MouseTPSection:AddToggle("mouseTPEnabled", {
    Title = "Enable Mouse TP",
    Default = false,
    Callback = function(state)
        getgenv().MouseTPEnabled = state
        if state then
            mouseTPTeleport()
            getgenv().MouseTPEnabled = false
        end
    end
})

MouseTPSection:AddKeybind("mouseTPKeybind", {
    Title = "Mouse TP Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().MouseTPKeybind = key
    end
})

MouseTPSection:AddDropdown("mouseTPMode", {
    Title = "TP Mode",
    Values = {"Instant", "Tween"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().MouseTPMode = selected
    end
})

MouseTPSection:AddDropdown("mouseTPMethod", {
    Title = "TP Method",
    Values = {"CFrame", "Velocity", "Impulse"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().MouseTPMethod = selected
    end
})

MouseTPSection:AddSlider("tweenSpeed", {
    Title = "Tween Speed",
    Default = 1,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Callback = function(value)
        getgenv().TweenSpeed = value
    end
})

MouseTPSection:AddSlider("tpHeight", {
    Title = "TP Height Offset",
    Default = 3,
    Min = 0,
    Max = 50,
    Rounding = 0,
    Callback = function(value)
        getgenv().TPHeight = value
    end
})

local ACBypassSection = ExploitsTab:AddCollapsibleSection({ Title = "AC Bypass" })

ACBypassSection:AddToggle("acBypassEnabled", {
    Title = "Enable AC Bypass",
    Default = false,
    Callback = function(state)
        getgenv().ACBypassEnabled = state
    end
})

ACBypassSection:AddKeybind("acBypassKeybind", {
    Title = "AC Bypass Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().ACBypassKeybind = key
        if key ~= "None" then
            getgenv().ACBypassEnabled = not getgenv().ACBypassEnabled
        end
    end
})

ACBypassSection:AddSlider("acWalkSpeed", {
    Title = "Walk Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        getgenv().ACWalkSpeed = value
    end
})

ACBypassSection:AddSlider("acJumpPower", {
    Title = "Jump Power",
    Default = 50,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        getgenv().ACJumpPower = value
    end
})

ACBypassSection:AddSlider("acJumpHeight", {
    Title = "Jump Height",
    Default = 7.2,
    Min = 0,
    Max = 50,
    Rounding = 1,
    Callback = function(value)
        getgenv().ACJumpHeight = value
    end
})

ACBypassSection:AddParagraph({ Title = "Status", Content = "Inactive" })


local AntiAFKSection = MiscTab:AddCollapsibleSection({ Title = "Anti-AFK" })

AntiAFKSection:AddToggle("antiAFKEnabled", {
    Title = "Enable Anti-AFK",
    Default = false,
    Callback = function(state)
        getgenv().AntiAFKEnabled = state
    end
})

AntiAFKSection:AddKeybind("antiAFKKeybind", {
    Title = "Anti-AFK Keybind",
    Default = "None",
    Callback = function(key)
        getgenv().AntiAFKKeybind = key
        if key ~= "None" then
            getgenv().AntiAFKEnabled = not getgenv().AntiAFKEnabled
        end
    end
})

AntiAFKSection:AddDropdown("antiAFKMethod", {
    Title = "Anti-AFK Method",
    Values = {"Click", "Jump"},
    Default = 1,
    Multi = false,
    Callback = function(selected)
        getgenv().AntiAFKMethod = selected
    end
})

AntiAFKSection:AddSlider("antiAFKInterval", {
    Title = "Interval (sec)",
    Default = 60,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(value)
        getgenv().AntiAFKInterval = value
    end
})

local FOVSection = MiscTab:AddCollapsibleSection({ Title = "FOV Changer" })

FOVSection:AddToggle("miscFOVEnabled", {
    Title = "Enable FOV Changer",
    Default = false,
    Callback = function(state)
        getgenv().MiscFOVEnabled = state
    end
})

FOVSection:AddSlider("miscFOVValue", {
    Title = "Field of View",
    Default = 70,
    Min = 30,
    Max = 120,
    Rounding = 0,
    Callback = function(value)
        getgenv().MiscFOVValue = value
    end
})

FOVSection:AddButton({
    Title = "Reset FOV",
    Callback = function()
        Workspace.CurrentCamera.FieldOfView = Originals.FOV
    end
})


SettingsTab:AddButton({
    Title = "Unload",
    Callback = function()
        getgenv().ESPEnabled = false
        getgenv().AimbotEnabled = false
        getgenv().CamlockEnabled = false
        getgenv().TargetPlayer = nil
        getgenv().TriggerbotEnabled = false
        getgenv().ChamsEnabled = false
        getgenv().FlyEnabled = false
        getgenv().NoclipEnabled = false
        getgenv().SpeedEnabled = false
        getgenv().InfJumpEnabled = false
        getgenv().SpinbotEnabled = false
        getgenv().AntiAFKEnabled = false
        getgenv().MiscFOVEnabled = false
        Workspace.CurrentCamera.FieldOfView = Originals.FOV

        removeAllESPObjects()

        if getgenv().aimbotFOVCircle then
            getgenv().aimbotFOVCircle:Remove()
            getgenv().aimbotFOVCircle = nil
        end

        pcall(function() DrawingLib.clear() end)
        pcall(function() EntityLib.stop() end)
        janitor:Cleanup()

        stopHitbox()
        getgenv().__HITBOX__ = nil
        gcinfo()
    end
})

SettingsTab:AddKeybind("menuKeybind", {
    Title = "Menu Keybind",
    Default = "RightShift",
    Callback = function(key)
        getgenv().MenuKeybind = key
    end
})

SettingsTab:AddParagraph({ Title = "Swift Hub", Content = "Version: " .. _version .. "\nUI: Fluent Modded\nby coderofthenextgen" })


local function getDirection()
    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return Vector3.zero end

    if getgenv().MoveDirection == 'MoveDirection' then
        return hum.MoveDirection
    else
        local cam = Workspace.CurrentCamera
        local cf = cam.CFrame
        local moveDir = (cf.LookVector * (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0))
            + (cf.RightVector * (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0))
            - (cf.LookVector * (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0))
            - (cf.RightVector * (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0))
        if moveDir.Magnitude > 0 then
            return moveDir.Unit
        end
        return Vector3.zero
    end
end

local MouseTPRaycastParams = RaycastParams.new()
MouseTPRaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function raycastToGround(position)
    local char = LocalPlayer.Character
    if char then
        MouseTPRaycastParams.FilterDescendantsInstances = { char }
    else
        MouseTPRaycastParams.FilterDescendantsInstances = {}
    end
    local result = Workspace:Raycast(position + Vector3.new(0, 500, 0), Vector3.new(0, -1000, 0), MouseTPRaycastParams)
    return result
end

local function getMouseGroundCF()
    local mouse = LocalPlayer:GetMouse()
    if not mouse.Hit then return nil end

    local mousePos = mouse.Hit.Position
    local result = raycastToGround(mousePos)

    if not result then
        return nil
    end

    return CFrame.new(result.Position + Vector3.new(0, getgenv().TPHeight, 0))
end

local function tweenToPosition(hrp, targetCFrame, speed)
    local startPos = hrp.CFrame
    local dist = (targetCFrame.Position - startPos.Position).Magnitude
    local duration = dist / (speed * 100)
    local startTime = tick()

    while tick() - startTime < duration do
        local alpha = math.min((tick() - startTime) / duration, 1)
        hrp.CFrame = startPos:Lerp(targetCFrame, alpha)
        RunService.RenderStepped:Wait()
    end
    hrp.CFrame = targetCFrame
end

local function moveToPosition(hrp, targetCF, method)
    local maxTime = 2
    local startTime = tick()

    while (hrp.Position - targetCF.Position).Magnitude > 2 do
        if tick() - startTime > maxTime then
            hrp.CFrame = targetCF
            break
        end

        local dir = (targetCF.Position - hrp.Position)
        local dist = dir.Magnitude

        if method == 'Velocity' then
            hrp.Velocity = dir.Unit * math.clamp(dist * 5, 50, 1000) + Vector3.new(0, 50, 0)
        elseif method == 'Impulse' then
            hrp:ApplyImpulse(dir.Unit * math.clamp(dist * 2, 50, 1000) * hrp.AssemblyMass)
        end

        RunService.RenderStepped:Wait()
    end

    hrp.CFrame = targetCF
    hrp.Velocity = Vector3.zero
end

local function mouseTPTeleport()
    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return end

    local targetCF = getMouseGroundCF()
    if not targetCF then return end

    if getgenv().MouseTPMode == 'Instant' then
        if getgenv().MouseTPMethod == 'CFrame' then
            hrp.CFrame = targetCF
        else
            moveToPosition(hrp, targetCF, getgenv().MouseTPMethod)
        end
    elseif getgenv().MouseTPMode == 'Tween' then
        if getgenv().MouseTPMethod == 'CFrame' then
            tweenToPosition(hrp, targetCF, getgenv().TweenSpeed)
        else
            moveToPosition(hrp, targetCF, getgenv().MouseTPMethod)
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if getgenv().MouseTPKeybind ~= 'None' then
        local key = getgenv().MouseTPKeybind
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == key then
            mouseTPTeleport()
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 and key == 'MB1' then
            mouseTPTeleport()
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 and key == 'MB2' then
            mouseTPTeleport()
        end
    end
end)

local noclipOriginalCollisions = {}
local noclipCollisionFolder = nil

local function getSelectedParts()
    local parts = {}

    local partMap = {
        ['Head'] = 'Head',
        ['Torso'] = 'Torso',
        ['Left Arm'] = 'Left Arm',
        ['Right Arm'] = 'Right Arm',
        ['Left Leg'] = 'Left Leg',
        ['Right Leg'] = 'Right Leg',
        ['HumanoidRootPart'] = 'HumanoidRootPart',
    }

    for name, _ in pairs(getgenv().NoclipParts) do
        if partMap[name] then
            table.insert(parts, partMap[name])
        end
    end

    if #parts == 0 then
        return nil
    end

    return parts
end

local function getCharacterParts(char, partNames)
    local parts = {}
    if not partNames then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA('BasePart') then
                table.insert(parts, part)
            end
        end
        return parts
    end

    for _, name in ipairs(partNames) do
        local part = char:FindFirstChild(name)
        if part and part:IsA('BasePart') then
            table.insert(parts, part)
        end
    end

    return parts
end

local noclipGroundPart = nil

local function updateGroundPart()
    local char, hrp, hum = getCharacter()
    if not hrp then return end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { char }

    local result = Workspace:Raycast(hrp.Position, Vector3.new(0, -50, 0), raycastParams)
    if result then
        noclipGroundPart = result.Instance
    else
        noclipGroundPart = nil
    end
end

local function setPartNoCollision(part, state)
    if part == noclipGroundPart then return end

    noclipOriginalCollisions[part] = noclipOriginalCollisions[part] or part.CanCollide
    part.CanCollide = state
end

local function restoreAllCollisions()
    for part, canCollide in pairs(noclipOriginalCollisions) do
        if part and part.Parent then
            part.CanCollide = canCollide
        end
    end
    noclipOriginalCollisions = {}
end

local function cleanupNoclip()
    restoreAllCollisions()

    if noclipCollisionFolder then
        noclipCollisionFolder:Destroy()
        noclipCollisionFolder = nil
    end
end

local function startNoclip()
    local char, hrp, hum = getCharacter()
    if not char then return end

    if getgenv().NoclipMode == 'CollisionGroup' then
        noclipCollisionFolder = Instance.new('Folder')
        noclipCollisionFolder.Name = 'NoclipCollisionFolder'
        noclipCollisionFolder.Parent = char

        local colPart = Instance.new('Part')
        colPart.Name = 'NoclipPart'
        colPart.Size = Vector3.new(1, 1, 1)
        colPart.Transparency = 1
        colPart.Anchored = true
        colPart.CanCollide = false
        colPart.Parent = noclipCollisionFolder
    end
end

local function stopNoclip()
    cleanupNoclip()
end

local function noclipCharacter()
    local char, hrp, hum = getCharacter()
    if not char then return end

    local selectedParts = getSelectedParts()
    local parts = getCharacterParts(char, selectedParts)

    for _, part in ipairs(parts) do
        setPartNoCollision(part, false)
    end
end

local function noclipPart()
    local char, hrp, hum = getCharacter()
    if not char then return end

    local mouse = LocalPlayer:GetMouse()
    if mouse.Target then
        setPartNoCollision(mouse.Target, false)
    end

    local selectedParts = getSelectedParts()
    local parts = getCharacterParts(char, selectedParts)

    for _, part in ipairs(parts) do
        setPartNoCollision(part, false)
    end
end

local function noclipCollisionGroup()
    local char, hrp, hum = getCharacter()
    if not char then return end

    local selectedParts = getSelectedParts()
    local parts = getCharacterParts(char, selectedParts)

    for _, part in ipairs(parts) do
        setPartNoCollision(part, false)
    end

    if noclipCollisionFolder then
        for _, obj in ipairs(noclipCollisionFolder:GetChildren()) do
            if obj:IsA('BasePart') then
                obj.CanCollide = false
            end
        end
    end
end

local function noclipLoop()
    updateGroundPart()

    if getgenv().NoclipMode == 'Character' then
        noclipCharacter()
    elseif getgenv().NoclipMode == 'Part' then
        noclipPart()
    elseif getgenv().NoclipMode == 'CollisionGroup' then
        noclipCollisionGroup()
    end
end

janitor:Add(RunService.Stepped:Connect(function()
    if getgenv().NoclipEnabled then
        noclipLoop()
    end
end), "Disconnect", "Noclip_Stepped")

janitor:Add(LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().NoclipEnabled then
        task.wait(0.5)
        startNoclip()
    end
end), "Disconnect", "Noclip_CharAdded")


getgenv().HBE = false

getgenv().CHAR_PARENT = Workspace
getgenv().hitboxConnections = {}

local function AssignHitboxes(player)
    if player == LocalPlayer then return end

    if getgenv().hitboxConnections[player] then
        getgenv().hitboxConnections[player]:Disconnect()
    end

    getgenv().hitboxConnections[player] = RunService.RenderStepped:Connect(function()
        local char = getgenv().CHAR_PARENT:FindFirstChild(player.Name)
        if getgenv().HBE then
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local hitboxSizeVec = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)

                if hrp.Size ~= hitboxSizeVec or hrp.Color ~= getgenv().HitboxColor then
                    hrp.Size = hitboxSizeVec
                    hrp.Color = getgenv().HitboxColor
                    hrp.CanCollide = false
                    hrp.Transparency = getgenv().HitboxShow and 0.5 or 1
                end
            end
        else
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.Size = Vector3.new(2,2,1)
                char.HumanoidRootPart.Transparency = 1
            end
        end
    end)
end

getgenv().hitboxActive = false
getgenv().hitboxSelectionBoxes = {}

local function clearSelectionBoxes(player)
    if player then
        if getgenv().hitboxSelectionBoxes[player] and getgenv().hitboxSelectionBoxes[player].Parent then
            getgenv().hitboxSelectionBoxes[player]:Destroy()
        end
        getgenv().hitboxSelectionBoxes[player] = nil
    else
        for player, sb in pairs(getgenv().hitboxSelectionBoxes) do
            if sb and sb.Parent then
                sb:Destroy()
            end
        end
        table.clear(getgenv().hitboxSelectionBoxes)
    end
end

local function updateSelectionBoxes(player)
    local char = Workspace:FindFirstChild(player.Name)
    if not char then return end

    if not getgenv().HitboxShow then
        clearSelectionBoxes(player)
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local sb = getgenv().hitboxSelectionBoxes[player]

    if not sb or not sb.Parent then
        sb = Instance.new('SelectionBox')
        sb.Adornee = hrp
        sb.LineThickness = 0.03
        sb.SurfaceTransparency = 0.7
        sb.Parent = hrp
        getgenv().hitboxSelectionBoxes[player] = sb
    end
    sb.Color3 = getgenv().HitboxColor
    sb.SurfaceColor3 = getgenv().HitboxColor
end

local function startHitbox()
    getgenv().hitboxActive = true
    getgenv().HBE = true

    for _, player in ipairs(Players:GetPlayers()) do
        AssignHitboxes(player)
    end
end

local function stopHitbox()
    getgenv().hitboxActive = false
    getgenv().HBE = false

    for player, connection in pairs(getgenv().hitboxConnections) do
        if connection then
            connection:Disconnect()
        end
        local char = Workspace:FindFirstChild(player.Name)
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Size = Vector3.new(2,2,1)
            char.HumanoidRootPart.Transparency = 1
        end
    end
    table.clear(getgenv().hitboxConnections)
    clearSelectionBoxes(nil)
end


task.spawn(function()
    while true do
        if getgenv().HitboxEnabled ~= getgenv().hitboxActive then
            if getgenv().HitboxEnabled then
                startHitbox()
            else
                stopHitbox()
            end
        end

        if getgenv().HitboxEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    updateSelectionBoxes(player)
                end
            end
        end
        task.wait(0.1)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if getgenv().hitboxConnections[player] then
        getgenv().hitboxConnections[player]:Disconnect()
        getgenv().hitboxConnections[player] = nil
    end
    clearSelectionBoxes(player)
end)

Players.PlayerAdded:Connect(function(player)
    if getgenv().HitboxEnabled then
        task.wait(1)
        AssignHitboxes(player)
    end
end)


local function getPlayerFromPart(part)
    if not part then return nil end
    local char = part:FindFirstAncestorOfClass("Model")
    if not char then return nil end
    local player = Players:GetPlayerFromCharacter(char)
    return player
end

local function isTargetValid(target)
    if not target then return false end
    if not target.Character then return false end

    local entity = EntityLib.getEntity(target)
    if not entity then return false end

    if entity.Health <= 0 then return false end

    if getgenv().TriggerbotWallCheck then
        local head = target.Character:FindFirstChild('Head')
        if head then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = { LocalPlayer.Character, target.Character }
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local rayResult = Workspace:Raycast(Workspace.CurrentCamera.CFrame.Position, (head.Position - Workspace.CurrentCamera.CFrame.Position).Unit * 500, rayParams)
            if rayResult and not rayResult.Instance:IsDescendantOf(target.Character) then
                return false
            end
        end
    end

    return true
end

getgenv()._triggerbotConnection = nil

function triggerbotLoop()
    local mouse = LocalPlayer:GetMouse()

    if getgenv()._triggerbotConnection then
        getgenv()._triggerbotConnection:Disconnect()
    end

    getgenv()._triggerbotConnection = RunService.Heartbeat:Connect(function()
        if getgenv().TriggerbotEnabled and mouse.Target then
            local target = getPlayerFromPart(mouse.Target)
            if target and target ~= LocalPlayer and isTargetValid(target) then
                mouse1press()
                task.wait(getgenv().TriggerbotDelay)
                mouse1release()
            end
        end
    end)
end

task.spawn(function()
    while true do
        if getgenv().TriggerbotEnabled and not getgenv()._triggerbotConnection then
            triggerbotLoop()
        elseif not getgenv().TriggerbotEnabled and getgenv()._triggerbotConnection then
            getgenv()._triggerbotConnection:Disconnect()
            getgenv()._triggerbotConnection = nil
        end
        task.wait(0.1)
    end
end)


getgenv().aimbotFOVCircle = nil
getgenv().CamlockEnabled = false
getgenv().TargetPlayer = nil

local function createFOVCircle()
    getgenv().aimbotFOVCircle = Drawing.new('Circle')
    getgenv().aimbotFOVCircle.Visible = false
    getgenv().aimbotFOVCircle.Thickness = 2
    getgenv().aimbotFOVCircle.NumSides = 64
    getgenv().aimbotFOVCircle.Radius = 100
    getgenv().aimbotFOVCircle.Color = Color3.fromRGB(255, 255, 255)
    getgenv().aimbotFOVCircle.Filled = false
    getgenv().aimbotFOVCircle.Transparency = 1
end

local function GetClosestPlayer()
    local cam = Workspace.CurrentCamera
    local validPlayers = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local hum = player.Character:FindFirstChildOfClass('Humanoid')
        local part = player.Character:FindFirstChild(getgenv().AimbotTargetPart)
        if not hum or not part then continue end

        if getgenv().AimbotAliveCheck and hum.Health <= 0 then continue end
        if getgenv().AimbotTeamCheck and player.Team == LocalPlayer.Team then continue end

        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        if getgenv().AimbotWallCheck then
            local origin = cam.CFrame.Position
            local rayResult = workspace:Raycast(origin, part.Position - origin)
            if rayResult then continue end
        end

        local mousePos = UserInputService:GetMouseLocation()
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

        if dist <= getgenv().AimbotFOV then
            table.insert(validPlayers, {
                player = player,
                distance = dist,
                health = hum.Health
            })
        end
    end

    if #validPlayers == 0 then return nil end

    if getgenv().AimbotTargetMode == 'Nearest' then
        table.sort(validPlayers, function(a, b) return a.distance < b.distance end)
        return validPlayers[1].player
    elseif getgenv().AimbotTargetMode == 'Crosshair' then
        table.sort(validPlayers, function(a, b) return a.distance < b.distance end)
        return validPlayers[1].player
    elseif getgenv().AimbotTargetMode == 'Lowest Health' then
        table.sort(validPlayers, function(a, b) return a.health < b.health end)
        return validPlayers[1].player
    end

    return validPlayers[1].player
end

local function updateFOVCircle()
    if not getgenv().aimbotFOVCircle then return end
    if not getgenv().AimbotShowFOV then
        getgenv().aimbotFOVCircle.Visible = false
        return
    end

    local mousePos = UserInputService:GetMouseLocation()
    getgenv().aimbotFOVCircle.Position = mousePos
    getgenv().aimbotFOVCircle.Radius = getgenv().AimbotFOV
    getgenv().aimbotFOVCircle.Visible = true
end

createFOVCircle()

local function ValidateTarget()
    if not getgenv().TargetPlayer then return false end
    if not getgenv().TargetPlayer.Character then return false end

    local targetPart = getgenv().TargetPlayer.Character:FindFirstChild(getgenv().AimbotTargetPart)
    if not targetPart then return false end

    local hum = getgenv().TargetPlayer.Character:FindFirstChildOfClass('Humanoid')
    if not hum then return false end

    if getgenv().AimbotAliveCheck and hum.Health <= 0 then return false end
    if getgenv().AimbotTeamCheck and getgenv().TargetPlayer.Team == LocalPlayer.Team then return false end

    local cam = Workspace.CurrentCamera
    local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
    if not onScreen then return false end

    local mousePos = UserInputService:GetMouseLocation()
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
    if dist > getgenv().AimbotFOV then return false end

    return true
end

janitor:Add(RunService.RenderStepped:Connect(function()
        updateFOVCircle()

        if getgenv().AimbotMode == 'Hold' then
            local keybind = getgenv().AimbotKeybind
            if keybind ~= 'None' then
                local keySuccess, isKeyDown = pcall(function()
                    return UserInputService:IsKeyDown(Enum.KeyCode[keybind])
                end)
                if keySuccess and isKeyDown then
                    if not getgenv().CamlockEnabled then
                        getgenv().CamlockEnabled = true
                        getgenv().TargetPlayer = GetClosestPlayer()
                    end
                else
                    if getgenv().CamlockEnabled then
                        getgenv().CamlockEnabled = false
                        getgenv().TargetPlayer = nil
                    end
                end
            end
        end

        if getgenv().CamlockEnabled then
            if getgenv().AimbotSticky then
                if not ValidateTarget() then
                    local newTarget = GetClosestPlayer()
                    if newTarget then
                        getgenv().TargetPlayer = newTarget
                    end
                end
            else
                local newTarget = GetClosestPlayer()
                if newTarget then
                    getgenv().TargetPlayer = newTarget
                end
            end
        end

        if getgenv().CamlockEnabled and getgenv().TargetPlayer and getgenv().TargetPlayer.Character and getgenv().TargetPlayer.Character:FindFirstChild(getgenv().AimbotTargetPart) then
            local cam = Workspace.CurrentCamera
            local part = getgenv().TargetPlayer.Character[getgenv().AimbotTargetPart]
            local smoothness = getgenv().AimbotSmoothness
            local prediction = getgenv().AimbotPrediction
            local silentAim = getgenv().AimbotSilentAim

            local targetPos = part.Position
            if prediction > 0 and getgenv().TargetPlayer.Character:FindFirstChild('HumanoidRootPart') then
                targetPos = targetPos + (getgenv().TargetPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity * prediction)
            end

            local targetCF = CFrame.new(cam.CFrame.Position, targetPos)

            local smoothFactor
            if silentAim then
                smoothFactor = 0.05
            else
                smoothFactor = math.clamp(1 / smoothness, 0.02, 1)
            end

            cam.CFrame = cam.CFrame:Lerp(targetCF, smoothFactor)
        end
    end), "Disconnect", "Aimbot_Render")

local function heatseekerLoop()
    while getgenv().SpeedEnabled and getgenv().SpeedMethod == 'Heatseeker' do
        local char, hrp, hum = getCharacter()
        if char and hrp and hum then
            isBoosting = true
            local dir = getDirection()
            if dir.Magnitude > 0 then
                hrp.Velocity = dir * getgenv().SpeedValue + Vector3.new(0, hrp.Velocity.Y, 0)
            end
            task.wait(getgenv().HeatseekerDuration)
            isBoosting = false
            hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
            task.wait(getgenv().HeatseekerTicks)
        else
            task.wait(0.1)
        end
    end
end

janitor:Add(RunService.Heartbeat:Connect(function()
    if not getgenv().SpeedEnabled then return end

    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return end

    local dir = getDirection()
    if dir.Magnitude == 0 then return end

    local vel = dir * getgenv().SpeedValue

    if getgenv().SpeedMethod == 'Velocity' then
        hrp.Velocity = vel + Vector3.new(0, hrp.Velocity.Y, 0)
    elseif getgenv().SpeedMethod == 'WalkSpeed' then
        getgenv().WalkSpeedSpoof.SetWalkSpeed(getgenv().SpeedValue)
    elseif getgenv().SpeedMethod == 'Impulse' then
        hrp:ApplyImpulse(Vector3.new(vel.X, 0, vel.Z) * hrp.AssemblyMass)
    end
end), "Disconnect", "Speed_Heartbeat")

task.spawn(function()
    while true do
        if getgenv().SpeedEnabled and getgenv().SpeedMethod == 'Heatseeker' then
            task.spawn(heatseekerLoop)
        end
        task.wait(0.5)
    end
end)

local function onJump()
    if not getgenv().JumpEnabled then return end

    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return end

    if getgenv().JumpMethod == 'DirectSet' then
        if getgenv().JumpProperty == 'JumpPower' then
            getgenv().JumpPowerSpoof.SetJumpPower(getgenv().JumpValue)
        else
            hum.JumpHeight = getgenv().JumpValue
        end
    elseif getgenv().JumpMethod == 'Velocity' then
        hrp.Velocity = Vector3.new(hrp.Velocity.X, getgenv().JumpValue, hrp.Velocity.Z)
    elseif getgenv().JumpMethod == 'CFrame' then
        hrp.CFrame = hrp.CFrame + Vector3.new(0, getgenv().JumpValue, 0)
    end
end

local function setupJumpListener()
    local char, hrp, hum = getCharacter()
    if not hum then return end

    hum.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping then
            onJump()
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    setupJumpListener()
end)

if LocalPlayer.Character then
    task.spawn(setupJumpListener)
end


local spoofedProperties = {
    WalkSpeed = 16,
    JumpPower = 50,
    JumpHeight = 7.2,
}

local oldIndex, oldNewIndex

task.delay(2, function()
    spoofedProperties.WalkSpeed = Originals.WalkSpeed
    spoofedProperties.JumpPower = Originals.JumpPower
    spoofedProperties.JumpHeight = Originals.JumpHeight
end)

oldIndex = hookmetamethod(game, '__index', newcclosure(function(self, index)
    if not checkcaller() and self:IsA('Humanoid') and self:IsDescendantOf(LocalPlayer.Character) then
        if type(index) == 'string' then
            local cleanindex = string.split(index, '\0')[1]
            if spoofedProperties[cleanindex] then
                return spoofedProperties[cleanindex]
            end
        end
    end
    return oldIndex(self, index)
end))

oldNewIndex = hookmetamethod(game, '__newindex', newcclosure(function(self, index, value)
    if not checkcaller() and self:IsA('Humanoid') and self:IsDescendantOf(LocalPlayer.Character) then
        if type(index) == 'string' then
            local cleanindex = string.split(index, '\0')[1]
            if spoofedProperties[cleanindex] then
                spoofedProperties[cleanindex] = value
                return
            end
        end
    end
    return oldNewIndex(self, index, value)
end))

task.spawn(function()
    while true do
        if getgenv().ACBypassEnabled then
            spoofedProperties.WalkSpeed = getgenv().ACWalkSpeed
            spoofedProperties.JumpPower = getgenv().ACJumpPower
            spoofedProperties.JumpHeight = getgenv().ACJumpHeight
        else
            spoofedProperties.WalkSpeed = Originals.WalkSpeed
            spoofedProperties.JumpPower = Originals.JumpPower
            spoofedProperties.JumpHeight = Originals.JumpHeight
        end
        task.wait(0.1)
    end
end)


local flyActive = false
local flyBV

local function startFly()
    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return end

    flyActive = true

    if getgenv().FlyMethod == 'CFrame' then
        flyBV = Instance.new('BodyVelocity')
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
    elseif getgenv().FlyMethod == 'Velocity' then
        flyBV = Instance.new('BodyVelocity')
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
    elseif getgenv().FlyMethod == 'BodyVelocity' then
        flyBV = Instance.new('BodyVelocity')
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
    elseif getgenv().FlyMethod == 'LinearVelocity' then
        flyBV = Instance.new('LinearVelocity')
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        flyBV.VectorVelocity = Vector3.zero
        flyBV.Attachment0 = hrp:FindFirstChildOfClass('Attachment') or Instance.new('Attachment', hrp)
        flyBV.Parent = hrp
    end

    if hum then
        hum.PlatformStand = true
    end
end

local function stopFly()
    flyActive = false

    if flyBV then
        flyBV:Destroy()
        flyBV = nil
    end

    local char, hrp, hum = getCharacter()
    if hum then
        hum.PlatformStand = false
    end
end

task.spawn(function()
    while true do
        if getgenv().FlyEnabled ~= flyActive then
            if getgenv().FlyEnabled then
                startFly()
            else
                stopFly()
            end
        end
        task.wait(0.1)
    end
end)

if getgenv().FlyAutoDisable then
    LocalPlayer.CharacterAdded:Connect(function(char)
        if getgenv().FlyEnabled then
            task.wait(0.5)
            stopFly()
            getgenv().FlyEnabled = false
        end
    end)
end

janitor:Add(RunService.Heartbeat:Connect(function(dt)
    if not flyActive then return end

    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then
        stopFly()
        return
    end

    local cam = Workspace.CurrentCamera
    local speed = getgenv().FlySpeed
    local vertSpeed = getgenv().FlyVerticalSpeed

    local moveDir = Vector3.zero
    local camCF = cam.CFrame

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDir = moveDir + camCF.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDir = moveDir - camCF.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDir = moveDir - camCF.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDir = moveDir + camCF.RightVector
    end

    local vertical = 0
    if UserInputService:IsKeyDown(Enum.KeyCode[getgenv().FlyUpKey]) then
        vertical = 1
    end
    if UserInputService:IsKeyDown(Enum.KeyCode[getgenv().FlyDownKey]) then
        vertical = -1
    end

    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit * speed
    end

    local finalVelocity = Vector3.new(moveDir.X, vertical * vertSpeed, moveDir.Z)

    if getgenv().FlyMethod == 'CFrame' then
        if flyBV then
            flyBV.Velocity = finalVelocity
        end
    elseif getgenv().FlyMethod == 'Velocity' then
        if flyBV then
            flyBV.Velocity = finalVelocity
        end
    elseif getgenv().FlyMethod == 'BodyVelocity' then
        if flyBV then
            flyBV.Velocity = finalVelocity
        end
    elseif getgenv().FlyMethod == 'LinearVelocity' then
        if flyBV then
            flyBV.VectorVelocity = finalVelocity
        end
    end

    if moveDir.Magnitude > 0 then
        local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z)
        if flatDir.Magnitude > 0 then
            local targetCF = CFrame.new(hrp.Position, hrp.Position + flatDir.Unit)
            hrp.CFrame = hrp.CFrame:Lerp(targetCF, 0.3)
        end
    end
end), "Disconnect", "Fly_Heartbeat")


getgenv().infJumpConnections = {}

task.spawn(function()
    while true do
        if getgenv().InfJumpEnabled then
            local function doJump()
                local c, h, m = getCharacter()
                if not c or not h or not m then return end

                if getgenv().InfJumpType == 'Velocity' then
                    local bv = Instance.new('BodyVelocity')
                    bv.MaxForce = Vector3.new(0, math.huge, 0)
                    bv.Velocity = Vector3.new(0, getgenv().InfJumpHeight, 0)
                    bv.Parent = h
                    game:GetService('Debris'):AddItem(bv, 0.15)
                elseif getgenv().InfJumpType == 'CFrame' then
                    h.CFrame = h.CFrame + Vector3.new(0, getgenv().InfJumpHeight * 0.1, 0)
                elseif getgenv().InfJumpType == 'BodyVelocity' then
                    local bv = Instance.new('BodyVelocity')
                    bv.MaxForce = Vector3.new(0, math.huge, 0)
                    bv.Velocity = Vector3.new(0, getgenv().InfJumpHeight, 0)
                    bv.Parent = h
                    game:GetService('Debris'):AddItem(bv, 0.2)
                end
            end

            if getgenv().InfJumpMethod == 'Hold' then
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    doJump()
                end
            elseif getgenv().InfJumpMethod == 'Once' then

            end
        else
            for _, conn in ipairs(getgenv().infJumpConnections) do
                if conn.Connected then
                    conn:Disconnect()
                end
            end
            getgenv().infJumpConnections = {}
        end
        task.wait(0.1)
    end
end)

getgenv().pressing = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Space and not getgenv().pressing and getgenv().InfJumpEnabled and getgenv().InfJumpMethod == 'Once' then
        getgenv().pressing = true
        local c, h, m = getCharacter()
        if not c or not h or not m then return end

        if getgenv().InfJumpType == 'Velocity' then
            local bv = Instance.new('BodyVelocity')
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.new(0, getgenv().InfJumpHeight, 0)
            bv.Parent = h
            game:GetService('Debris'):AddItem(bv, 0.15)
        elseif getgenv().InfJumpType == 'CFrame' then
            h.CFrame = h.CFrame + Vector3.new(0, getgenv().InfJumpHeight * 0.1, 0)
        elseif getgenv().InfJumpType == 'BodyVelocity' then
            local bv = Instance.new('BodyVelocity')
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.new(0, getgenv().InfJumpHeight, 0)
            bv.Parent = h
            game:GetService('Debris'):AddItem(bv, 0.2)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        getgenv().pressing = false
    end
end)


getgenv().spinAngle = 0

janitor:Add(RunService.Heartbeat:Connect(function(dt)
    if not getgenv().SpinbotEnabled then return end

    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return end

    getgenv().spinAngle = getgenv().spinAngle + (getgenv().SpinSpeed * dt)
    if getgenv().spinAngle > 360 then
        getgenv().spinAngle = getgenv().spinAngle - 360
    end

    if getgenv().SpinAxis == 'Y' then
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(getgenv().spinAngle), 0)
    elseif getgenv().SpinAxis == 'X' then
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(math.rad(getgenv().spinAngle), 0, 0)
    elseif getgenv().SpinAxis == 'Z' then
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, 0, math.rad(getgenv().spinAngle))
    elseif getgenv().SpinAxis == 'Random' then
        local rx = math.random() * 2 - 1
        local ry = math.random() * 2 - 1
        local rz = math.random() * 2 - 1
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(
            math.rad(rx * getgenv().SpinSpeed),
            math.rad(ry * getgenv().SpinSpeed),
            math.rad(rz * getgenv().SpinSpeed)
        )
    end
end), "Disconnect", "Spinbot_Heartbeat")


local VirtualUser = game:GetService('VirtualUser')

local function antiAFKClick()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end

local function antiAFKJump()
    local char, hrp, hum = getCharacter()
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function doAntiAFK()
    if getgenv().AntiAFKMethod == 'Click' then
        antiAFKClick()
    elseif getgenv().AntiAFKMethod == 'Jump' then
        antiAFKJump()
    end
end

task.spawn(function()
    while true do
        if getgenv().AntiAFKEnabled then
            doAntiAFK()
            task.wait(getgenv().AntiAFKInterval)
        else
            task.wait(0.5)
        end
    end
end)


task.spawn(function()
    while true do
        if getgenv().MiscFOVEnabled then
            Workspace.CurrentCamera.FieldOfView = getgenv().MiscFOVValue
        else
            Workspace.CurrentCamera.FieldOfView = Originals.FOV
        end
        task.wait(0.1)
    end
end)


task.spawn(function()
    while true do
        if getgenv().FullbrightEnabled then
            Lighting.Brightness = getgenv().BrightnessValue
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        else
            Lighting.Brightness = Originals.Brightness
            Lighting.GlobalShadows = Originals.GlobalShadows
            Lighting.Ambient = Originals.Ambient
            Lighting.OutdoorAmbient = Originals.OutdoorAmbient
        end

        if getgenv().NoFogEnabled then
            Lighting.FogEnd = 999999
            Lighting.FogStart = 999999
        else
            Lighting.FogEnd = Originals.FogEnd
            Lighting.FogStart = Originals.FogStart
        end
        task.wait(0.1)
    end
end)


getgenv().chamsInstances = {}
getgenv().chamsHighlights = {}

local function getChamsTargets()
    local targets = {}

    local targetMap = {
        ['All'] = { 'Head', 'Torso', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg', 'HumanoidRootPart' },
        ['Head'] = { 'Head' },
        ['Body'] = { 'Torso', 'HumanoidRootPart' },
        ['Arms'] = { 'Left Arm', 'Right Arm' },
        ['Legs'] = { 'Left Leg', 'Right Leg' },
        ['HumanoidRootPart'] = { 'HumanoidRootPart' },
    }

    for name, _ in pairs(getgenv().ChamsTarget) do
        if targetMap[name] then
            for _, partName in ipairs(targetMap[name]) do
                if not table.find(targets, partName) then
                    table.insert(targets, partName)
                end
            end
        end
    end

    return targets
end

local function clearChams(player)
    if getgenv().chamsHighlights[player] then
        for _, highlight in pairs(getgenv().chamsHighlights[player]) do
            pcall(function()
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
            end)
        end
        getgenv().chamsHighlights[player] = nil
    end

    if getgenv().chamsInstances[player] then
        for _, data in pairs(getgenv().chamsInstances[player]) do
            pcall(function()
                if type(data) == 'table' and data.part then
                    if data.part and data.part.Parent then
                        data.part.Color = data.originalColor
                        data.part.Transparency = data.originalTransparency
                        data.part.Material = data.originalMaterial
                        data.part.CustomPhysicalProperties = nil
                    end

                    for _, meshData in ipairs(data.meshes) do
                        if meshData.mesh and meshData.mesh.Parent then
                            if meshData.mesh:IsA('SpecialMesh') then
                                if meshData.originalVertexColor then
                                    meshData.mesh.VertexColor = meshData.originalVertexColor
                                end
                                if meshData.originalTextureId then
                                    meshData.mesh.TextureId = meshData.originalTextureId
                                end
                            end
                        end
                    end
                else
                    if data and data.Parent then
                        data:Destroy()
                    end
                end
            end)
        end
        getgenv().chamsInstances[player] = nil
    end
end

local function createHighlightChams(player, char)
    if getgenv().chamsHighlights[player] then return end
    getgenv().chamsHighlights[player] = {}

    local highlight = Instance.new('Highlight')
    highlight.Name = 'ChamsHighlight'
    highlight.FillColor = getgenv().ChamsFillColor
    highlight.OutlineColor = getgenv().ChamsOutlineColor
    highlight.FillTransparency = getgenv().ChamsFillTransparency
    highlight.OutlineTransparency = getgenv().ChamsOutlineTransparency
    highlight.DepthMode = getgenv().ChamsThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.Adornee = char
    highlight.Parent = char

    getgenv().chamsHighlights[player] = { highlight = highlight }
end

local function createMaterialChams(player, char)
    if getgenv().chamsInstances[player] then return end
    getgenv().chamsInstances[player] = {}

    local targets = getChamsTargets()
    local material = Enum.Material[getgenv().ChamsMaterial]

    for _, partName in ipairs(targets) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA('BasePart') then
            local chamsPart = Instance.new('Part')
            chamsPart.Name = 'ChamsPart_' .. partName
            chamsPart.Size = part.Size + Vector3.new(0.05, 0.05, 0.05)
            chamsPart.CFrame = part.CFrame
            chamsPart.Anchored = false
            chamsPart.CanCollide = false
            chamsPart.Transparency = getgenv().ChamsFillTransparency
            chamsPart.Color = getgenv().ChamsFillColor
            chamsPart.Material = material
            chamsPart.Parent = char

            local weld = Instance.new('WeldConstraint')
            weld.Part0 = part
            weld.Part1 = chamsPart
            weld.Parent = chamsPart

            table.insert(getgenv().chamsInstances[player], chamsPart)
        end
    end
end

local function createEngineChams(player, char)
    if getgenv().chamsInstances[player] then return end
    getgenv().chamsInstances[player] = {}

    local targets = getChamsTargets()

    for _, partName in ipairs(targets) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA('BasePart') then
            local meshData = {
                part = part,
                originalColor = part.Color,
                originalTransparency = part.Transparency,
                originalMaterial = part.Material,
                meshes = {},
            }

            for _, child in ipairs(part:GetDescendants()) do
                if child:IsA('DataModelMesh') then
                    local meshInfo = {
                        mesh = child,
                        originalVertexColor = child:IsA('SpecialMesh') and child.VertexColor or nil,
                        originalTextureId = child:IsA('SpecialMesh') and child.TextureId or nil,
                    }

                    if child:IsA('SpecialMesh') then
                        child.VertexColor = Vector3.new(getgenv().ChamsFillColor.R, getgenv().ChamsFillColor.G, getgenv().ChamsFillColor.B)
                        child.TextureId = ""
                    end

                    table.insert(meshData.meshes, meshInfo)
                end
            end

            part.Color = getgenv().ChamsFillColor
            part.Transparency = math.clamp(getgenv().ChamsFillTransparency, 0, 0.99)
            part.Material = Enum.Material.SmoothPlastic
            part.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0, 0, 0, 0)

            table.insert(getgenv().chamsInstances[player], meshData)
        end
    end
end

local function applyChams(player)
    if player == LocalPlayer then return end

    local char = player.Character
    if not char then return end
    if not char:FindFirstChildOfClass('Humanoid') then return end
    if not char:FindFirstChild('HumanoidRootPart') then return end

    clearChams(player)

    if getgenv().ChamsMode == 'Highlight' then
        createHighlightChams(player, char)
    elseif getgenv().ChamsMode == 'Material' then
        createMaterialChams(player, char)
    elseif getgenv().ChamsMode == 'Engine' then
        createEngineChams(player, char)
    end
end

local function removeChams(player)
    clearChams(player)
end

local function cleanupChams()
    for player, _ in pairs(getgenv().chamsHighlights) do
        clearChams(player)
    end
    for player, _ in pairs(getgenv().chamsInstances) do
        clearChams(player)
    end
    getgenv().chamsHighlights = {}
    getgenv().chamsInstances = {}
end

task.spawn(function()
    while true do
        if getgenv().ChamsEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                applyChams(player)
            end
        else
            cleanupChams()
        end
        task.wait(0.5)
    end
end)

local function connectPlayerChams(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        if getgenv().ChamsEnabled then
            pcall(function()
                clearChams(player)
                applyChams(player)
            end)
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        connectPlayerChams(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    connectPlayerChams(player)
end)

Players.PlayerRemoving:Connect(function(player)
    pcall(function()
        clearChams(player)
    end)
end)


getgenv().espObjects = {}

local function getSelectedESPItems()
    local items = {}
    for name, _ in pairs(getgenv().ESPItems) do
        items[name] = true
    end
    return items
end

local function getESPColor(player)
    if player.Team and player.Team == LocalPlayer.Team then
        return getgenv().ESPTeamColor
    end
    return getgenv().ESPEnemyColor
end

local function worldToScreen(position)
    local cam = Workspace.CurrentCamera
    local pos, onScreen = cam:WorldToViewportPoint(position)
    return Vector2.new(pos.X, pos.Y), onScreen, pos.Z
end

local function getBoxDimensions(player)
    local char = player.Character
    if not char then return nil end

    local hrp = char:FindFirstChild('HumanoidRootPart')
    local head = char:FindFirstChild('Head')
    if not hrp or not head then return nil end

    local topPos = head.Position + Vector3.new(0, 1.5, 0)
    local bottomPos = hrp.Position - Vector3.new(0, 3, 0)

    local topScreen, topOnScreen = worldToScreen(topPos)
    local bottomScreen, bottomOnScreen = worldToScreen(bottomPos)

    if not topOnScreen and not bottomOnScreen then return nil end

    local height = (bottomScreen - topScreen).Y
    local width = height / 2

    return {
        Top = topScreen,
        Bottom = bottomScreen,
        Width = width,
        Height = height,
        Center = Vector2.new((topScreen.X + bottomScreen.X) / 2, (topScreen.Y + bottomScreen.Y) / 2),
    }
end

local function createESPObjects(player)
    if getgenv().espObjects[player] then return end

    getgenv().espObjects[player] = {
        BoxOutline = {
            Drawing.new('Line'), Drawing.new('Line'),
            Drawing.new('Line'), Drawing.new('Line')
        },
        Box = {
            Drawing.new('Line'), Drawing.new('Line'),
            Drawing.new('Line'), Drawing.new('Line')
        },
        Name = Drawing.new('Text'),
        HealthBarOutline = Drawing.new('Line'),
        HealthBar = Drawing.new('Line'),
        HealthText = Drawing.new('Text'),
        Distance = Drawing.new('Text'),
        Tracer = Drawing.new('Line'),
        TracerOutline = Drawing.new('Line'),
        LookAngle = Drawing.new('Line'),
        LookAngleOutline = Drawing.new('Line'),
        Tool = Drawing.new('Text'),
        Skeleton = {
            Head = Drawing.new('Line'),
            Neck = Drawing.new('Line'),
            Spine = Drawing.new('Line'),
            LeftShoulder = Drawing.new('Line'),
            LeftArm = Drawing.new('Line'),
            RightShoulder = Drawing.new('Line'),
            RightArm = Drawing.new('Line'),
            LeftHip = Drawing.new('Line'),
            LeftLeg = Drawing.new('Line'),
            RightHip = Drawing.new('Line'),
            RightLeg = Drawing.new('Line'),
        }
    }

    local thickness = getgenv().ESPThickness
    local textSize = getgenv().ESPTextSize

    local fontMap = {
        ['Code'] = 2,
        ['ArialBold'] = 1,
        ['GothamBold'] = 3,
        ['Gotham'] = 4,
        ['Legacy'] = 5,
        ['Highway'] = 6,
        ['Cartoon'] = 7,
        ['SciFi'] = 8,
    }
    local font = fontMap[getgenv().ESPFont] or 2

    for _, line in ipairs(getgenv().espObjects[player].BoxOutline) do
        line.Visible = false
        line.Color = Color3.new(0, 0, 0)
        line.Thickness = thickness + 2
    end

    for _, line in ipairs(getgenv().espObjects[player].Box) do
        line.Visible = false
        line.Thickness = thickness
    end

    getgenv().espObjects[player].Name.Visible = false
    getgenv().espObjects[player].Name.Font = font
    getgenv().espObjects[player].Name.Size = textSize
    getgenv().espObjects[player].Name.Center = true
    getgenv().espObjects[player].Name.Outline = true
    getgenv().espObjects[player].Name.OutlineColor = Color3.new(0, 0, 0)

    getgenv().espObjects[player].HealthBarOutline.Visible = false
    getgenv().espObjects[player].HealthBarOutline.Color = Color3.new(0, 0, 0)
    getgenv().espObjects[player].HealthBarOutline.Thickness = 4

    getgenv().espObjects[player].HealthBar.Visible = false
    getgenv().espObjects[player].HealthBar.Thickness = 2

    getgenv().espObjects[player].HealthText.Visible = false
    getgenv().espObjects[player].HealthText.Font = font
    getgenv().espObjects[player].HealthText.Size = textSize - 2
    getgenv().espObjects[player].HealthText.Center = true
    getgenv().espObjects[player].HealthText.Outline = true
    getgenv().espObjects[player].HealthText.OutlineColor = Color3.new(0, 0, 0)

    getgenv().espObjects[player].Distance.Visible = false
    getgenv().espObjects[player].Distance.Font = font
    getgenv().espObjects[player].Distance.Size = textSize - 2
    getgenv().espObjects[player].Distance.Center = true
    getgenv().espObjects[player].Distance.Outline = true
    getgenv().espObjects[player].Distance.OutlineColor = Color3.new(0, 0, 0)

    getgenv().espObjects[player].Tracer.Visible = false
    getgenv().espObjects[player].Tracer.Thickness = thickness

    getgenv().espObjects[player].TracerOutline.Visible = false
    getgenv().espObjects[player].TracerOutline.Color = Color3.new(0, 0, 0)
    getgenv().espObjects[player].TracerOutline.Thickness = thickness + 2

    getgenv().espObjects[player].LookAngle.Visible = false
    getgenv().espObjects[player].LookAngle.Thickness = thickness

    getgenv().espObjects[player].LookAngleOutline.Visible = false
    getgenv().espObjects[player].LookAngleOutline.Color = Color3.new(0, 0, 0)
    getgenv().espObjects[player].LookAngleOutline.Thickness = thickness + 2

    getgenv().espObjects[player].Tool.Visible = false
    getgenv().espObjects[player].Tool.Font = font
    getgenv().espObjects[player].Tool.Size = textSize - 2
    getgenv().espObjects[player].Tool.Center = false
    getgenv().espObjects[player].Tool.Outline = true
    getgenv().espObjects[player].Tool.OutlineColor = Color3.new(0, 0, 0)

    for _, line in pairs(getgenv().espObjects[player].Skeleton) do
        line.Visible = false
        line.Thickness = thickness
    end
end

local function removeESPObjects(player)
    if not getgenv().espObjects[player] then return end

    for _, line in ipairs(getgenv().espObjects[player].BoxOutline) do line:Remove() end
    for _, line in ipairs(getgenv().espObjects[player].Box) do line:Remove() end
    getgenv().espObjects[player].Name:Remove()
    getgenv().espObjects[player].HealthBarOutline:Remove()
    getgenv().espObjects[player].HealthBar:Remove()
    getgenv().espObjects[player].HealthText:Remove()
    getgenv().espObjects[player].Distance:Remove()
    getgenv().espObjects[player].Tracer:Remove()
    getgenv().espObjects[player].TracerOutline:Remove()
    getgenv().espObjects[player].LookAngle:Remove()
    getgenv().espObjects[player].LookAngleOutline:Remove()
    getgenv().espObjects[player].Tool:Remove()
    for _, line in pairs(getgenv().espObjects[player].Skeleton) do line:Remove() end

    getgenv().espObjects[player] = nil
end

local function hideAll(player)
    if not getgenv().espObjects[player] then return end
    for _, line in ipairs(getgenv().espObjects[player].BoxOutline) do line.Visible = false end
    for _, line in ipairs(getgenv().espObjects[player].Box) do line.Visible = false end
    getgenv().espObjects[player].Name.Visible = false
    getgenv().espObjects[player].HealthBarOutline.Visible = false
    getgenv().espObjects[player].HealthBar.Visible = false
    getgenv().espObjects[player].HealthText.Visible = false
    getgenv().espObjects[player].Distance.Visible = false
    getgenv().espObjects[player].Tracer.Visible = false
    getgenv().espObjects[player].TracerOutline.Visible = false
    getgenv().espObjects[player].LookAngle.Visible = false
    getgenv().espObjects[player].LookAngleOutline.Visible = false
    getgenv().espObjects[player].Tool.Visible = false
    for _, line in pairs(getgenv().espObjects[player].Skeleton) do line.Visible = false end
end

local function hideAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            hideAll(player)
        end
    end
end

local function removeAllESPObjects()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            removeESPObjects(player)
        end
    end
end

local function updateESP(player)
    if not getgenv().ESPEnabled then return end

    local esp = getgenv().espObjects[player]
    if not esp then return end

    local char = player.Character
    if not char then hideAll(player) return end

    local hrp = char:FindFirstChild('HumanoidRootPart')
    local head = char:FindFirstChild('Head')
    local humanoid = char:FindFirstChildOfClass('Humanoid')
    if not hrp or not head or not humanoid then hideAll(player) return end
    if humanoid.Health <= 0 then hideAll(player) return end

    local cam = Workspace.CurrentCamera
    local myPos = cam.CFrame.Position
    local dist = (hrp.Position - myPos).Magnitude
    if dist > getgenv().ESPMaxDistance then hideAll(player) return end

    local _, onScreen = cam:WorldToViewportPoint(hrp.Position)
    if not onScreen then hideAll(player) return end

    if not getgenv().ESPShowTeam and player.Team == LocalPlayer.Team then hideAll(player) return end

    local items = getSelectedESPItems()
    local color = getESPColor(player)
    local box = getBoxDimensions(player)

    esp.Name.Visible = false
    esp.HealthBarOutline.Visible = false
    esp.HealthBar.Visible = false
    esp.HealthText.Visible = false
    esp.Distance.Visible = false
    esp.Tracer.Visible = false
    esp.TracerOutline.Visible = false
    esp.LookAngle.Visible = false
    esp.LookAngleOutline.Visible = false
    esp.Tool.Visible = false

    if box then
        local topLeft = Vector2.new(box.Center.X - box.Width / 2, box.Top.Y)
        local topRight = Vector2.new(box.Center.X + box.Width / 2, box.Top.Y)
        local bottomLeft = Vector2.new(box.Center.X - box.Width / 2, box.Bottom.Y)
        local bottomRight = Vector2.new(box.Center.X + box.Width / 2, box.Bottom.Y)

        if items['Box'] then
            local corners = {
                { esp.Box[1], topLeft, topRight },
                { esp.Box[2], topRight, bottomRight },
                { esp.Box[3], bottomRight, bottomLeft },
                { esp.Box[4], bottomLeft, topLeft },
            }
            for _, data in ipairs(corners) do
                data[1].From = data[2]
                data[1].To = data[3]
                data[1].Color = color
                data[1].Visible = true
            end

            local outlineCorners = {
                { esp.BoxOutline[1], Vector2.new(topLeft.X - 1, topLeft.Y - 1), Vector2.new(topRight.X + 1, topRight.Y - 1) },
                { esp.BoxOutline[2], Vector2.new(topRight.X + 1, topRight.Y - 1), Vector2.new(bottomRight.X + 1, bottomRight.Y + 1) },
                { esp.BoxOutline[3], Vector2.new(bottomRight.X + 1, bottomRight.Y + 1), Vector2.new(bottomLeft.X - 1, bottomLeft.Y + 1) },
                { esp.BoxOutline[4], Vector2.new(bottomLeft.X - 1, bottomLeft.Y + 1), Vector2.new(topLeft.X - 1, topLeft.Y - 1) },
            }
            for _, data in ipairs(outlineCorners) do
                data[1].From = data[2]
                data[1].To = data[3]
                data[1].Visible = true
            end
        else
            for _, line in ipairs(esp.Box) do line.Visible = false end
            for _, line in ipairs(esp.BoxOutline) do line.Visible = false end
        end

        if items['Name'] then
            esp.Name.Text = player.DisplayName
            esp.Name.Position = Vector2.new(box.Center.X, box.Top.Y - 18)
            esp.Name.Color = color
            esp.Name.Visible = true
        end

        if items['Distance'] then
            esp.Distance.Text = '[' .. math.floor(dist) .. 'm]'
            esp.Distance.Position = Vector2.new(box.Center.X, box.Top.Y - 36)
            esp.Distance.Color = color
            esp.Distance.Visible = true
        end

        if items['Health'] then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            local barHeight = box.Height
            local barX = box.Center.X - box.Width / 2 - 6

            local barTop = box.Top.Y
            local barBottom = box.Bottom.Y
            local fillY = barBottom - (barHeight * healthPercent)

            esp.HealthBarOutline.From = Vector2.new(barX, barTop)
            esp.HealthBarOutline.To = Vector2.new(barX, barBottom)
            esp.HealthBarOutline.Visible = true

            esp.HealthBar.From = Vector2.new(barX, barBottom)
            esp.HealthBar.To = Vector2.new(barX, fillY)
            esp.HealthBar.Color = healthPercent > 0.5 and getgenv().ESPHealthHigh or getgenv().ESPHealthLow
            esp.HealthBar.Visible = true

            esp.HealthText.Text = math.floor(humanoid.Health)
            esp.HealthText.Position = Vector2.new(barX, barBottom + 12)
            esp.HealthText.Color = color
            esp.HealthText.Visible = true
        end

        if items['Tracers'] then
            local mousePos = UserInputService:GetMouseLocation()
            esp.Tracer.From = mousePos
            esp.Tracer.To = box.Center
            esp.Tracer.Color = color
            esp.Tracer.Visible = true

            esp.TracerOutline.From = mousePos
            esp.TracerOutline.To = box.Center
            esp.TracerOutline.Visible = true
        end

        if items['LookAngle'] then
            local lookCF = hrp.CFrame
            local lookPos = lookCF.Position + lookCF.LookVector * 5
            local screenLook, onScreenLook = cam:WorldToViewportPoint(lookPos)

            if onScreenLook then
                esp.LookAngle.From = box.Center
                esp.LookAngle.To = Vector2.new(screenLook.X, screenLook.Y)
                esp.LookAngle.Color = color
                esp.LookAngle.Visible = true

                esp.LookAngleOutline.From = box.Center
                esp.LookAngleOutline.To = Vector2.new(screenLook.X, screenLook.Y)
                esp.LookAngleOutline.Visible = true
            end
        end

        if items['Tool'] then
            local tool = char:FindFirstChildOfClass('Tool')
            if tool then
                esp.Tool.Text = tool.Name
                esp.Tool.Position = Vector2.new(box.Center.X + box.Width / 2 + 5, box.Top.Y)
                esp.Tool.Color = color
                esp.Tool.Visible = true
            end
        end

        if items['Skeleton'] then
            local isR15 = char:FindFirstChild('UpperTorso') ~= nil
            local r15 = isR15

            local function getScreen(cf)
                if not cf then return nil end
                local p = cf.Position
                local pos, onScreen = cam:WorldToViewportPoint(p)
                if not onScreen then return nil end
                return Vector2.new(pos.X, pos.Y)
            end

            local function getPartScreen(name)
                local part = char:FindFirstChild(name)
                if not part then return nil end
                local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                if not onScreen then return nil end
                return Vector2.new(pos.X, pos.Y)
            end

            local function drawBone(lineName, from, to)
                if from and to then
                    esp.Skeleton[lineName].From = from
                    esp.Skeleton[lineName].To = to
                    esp.Skeleton[lineName].Color = color
                    esp.Skeleton[lineName].Visible = true
                else
                    esp.Skeleton[lineName].Visible = false
                end
            end

            if r15 then
                local head = getPartScreen('Head')
                local neck = getScreen(char:FindFirstChild('Neck', true) and char:FindFirstChild('Neck', true).CFrame)
                local upperTorso = getPartScreen('UpperTorso')
                local lowerTorso = getPartScreen('LowerTorso')
                local la = getPartScreen('LeftUpperArm')
                local lla = getPartScreen('LeftLowerArm')
                local ra = getPartScreen('RightUpperArm')
                local rla = getPartScreen('RightLowerArm')
                local lul = getPartScreen('LeftUpperLeg')
                local lll = getPartScreen('LeftLowerLeg')
                local rul = getPartScreen('RightUpperLeg')
                local rll = getPartScreen('RightLowerLeg')

                drawBone('Head', head, neck)
                drawBone('Neck', neck, upperTorso)
                drawBone('Spine', upperTorso, lowerTorso)
                drawBone('LeftShoulder', neck, la)
                drawBone('LeftArm', la, lla)
                drawBone('RightShoulder', neck, ra)
                drawBone('RightArm', ra, rla)
                drawBone('LeftHip', lowerTorso, lul)
                drawBone('LeftLeg', lul, lll)
                drawBone('RightHip', lowerTorso, rul)
                drawBone('RightLeg', rul, rll)
            else
                local head = getPartScreen('Head')
                local torso = getPartScreen('Torso')
                local la = getPartScreen('Left Arm')
                local ra = getPartScreen('Right Arm')
                local lul = getPartScreen('Left Leg')
                local rul = getPartScreen('Right Leg')

                drawBone('Head', head, torso)
                drawBone('Neck', torso, torso)
                drawBone('Spine', torso, torso)
                drawBone('LeftShoulder', torso, la)
                drawBone('LeftArm', la, la)
                drawBone('RightShoulder', torso, ra)
                drawBone('RightArm', ra, ra)
                drawBone('LeftHip', torso, lul)
                drawBone('LeftLeg', lul, lul)
                drawBone('RightHip', torso, rul)
                drawBone('RightLeg', rul, rul)
            end
        else
            for _, line in pairs(esp.Skeleton) do line.Visible = false end
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESPObjects(player)
    end
end

janitor:Add(Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        createESPObjects(player)
    end)
end), "Disconnect", "PlayerAdded")

janitor:Add(Players.PlayerRemoving:Connect(function(player)
    removeESPObjects(player)
end), "Disconnect", "PlayerRemoving")

janitor:Add(RunService.RenderStepped:Connect(function()
    if not getgenv().ESPEnabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not getgenv().espObjects[player] then
                createESPObjects(player)
            end
            pcall(function()
                updateESP(player)
            end)
        end
    end
end), "Disconnect", "ESP_Render")


