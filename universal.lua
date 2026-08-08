local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local swiftRepo = 'https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/'

local function safeLoad(url)
    local src = game:HttpGet(url)
    local fn, err = loadstring(src)
    if not fn then
        error('Failed to compile ' .. url .. '\nError: ' .. tostring(err))
    end
    return fn()
end

local Library = safeLoad(repo .. 'Library.lua')
local ThemeManager = safeLoad(repo .. 'addons/ThemeManager.lua')
local SaveManager = safeLoad(repo .. 'addons/SaveManager.lua')

local DrawingLib = safeLoad(swiftRepo .. 'drawinglib.lua')
local EntityLib = safeLoad(swiftRepo .. 'entitylib.lua')
local JanitorLib = safeLoad(swiftRepo .. 'janitor.lua')

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

local Originals = {
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

local Window = Library:CreateWindow({
    Title = 'Swift Hub',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
    ShowCustomCursor = false
})

local Tabs = {
    Movement = Window:AddTab('Movement'),
    Combat = Window:AddTab('Combat'),
    Visuals = Window:AddTab('Visuals'),
    Exploits = Window:AddTab('Exploits'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local LeftGroupBox = Tabs.Movement:AddLeftGroupbox('Speed')
local RightGroupBox = Tabs.Movement:AddRightGroupbox('Jump')

local function getDirection()
    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return Vector3.zero end

    local direction = Options.MoveDirection.Value

    if direction == 'MoveDirection' then
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

task.delay(1, storeOriginals)

task.delay(1, storeOriginals)

LeftGroupBox:AddToggle('SpeedToggle', {
    Text = 'Enable Speed',
    Default = false,
    Callback = function(Value)
        if not Value then
            isBoosting = false
            getgenv().WalkSpeedSpoof.RestoreWalkSpeed()
        end
    end
})

LeftGroupBox:AddLabel('Speed Keybind'):AddKeyPicker('SpeedKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Speed Keybind',
    Callback = function(Value)
        Toggles.SpeedToggle:SetValue(Value)
    end,
})

LeftGroupBox:AddDropdown('SpeedMethod', {
    Values = { 'Velocity', 'WalkSpeed', 'Impulse', 'Heatseeker' },
    Default = 1,
    Multi = false,
    Text = 'Speed Method',
})

LeftGroupBox:AddDropdown('MoveDirection', {
    Values = { 'MoveDirection', 'DirectMove' },
    Default = 1,
    Multi = false,
    Text = 'Move Direction',
})

LeftGroupBox:AddSlider('SpeedValue', {
    Text = 'Speed',
    Default = 50,
    Min = 0,
    Max = 500,
    Rounding = 0,
})

local HeatseekerDepBox = LeftGroupBox:AddDependencyBox()

HeatseekerDepBox:AddSlider('HeatseekerDuration', {
    Text = 'Duration',
    Default = 0.3,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
})

HeatseekerDepBox:AddSlider('HeatseekerTicks', {
    Text = 'Ticks',
    Default = 0.3,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
})

HeatseekerDepBox:SetupDependencies({
    { Toggles.SpeedToggle, true },
    { Options.SpeedMethod, 'Heatseeker' }
})

local MouseTPGroupBox = Tabs.Exploits:AddLeftGroupbox('Mouse TP')

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

    return CFrame.new(result.Position + Vector3.new(0, Options.TPHeight.Value, 0))
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

    local mode = Options.MouseTPMode.Value
    local method = Options.MouseTPMethod.Value

    if mode == 'Instant' then
        if method == 'CFrame' then
            hrp.CFrame = targetCF
        else
            moveToPosition(hrp, targetCF, method)
        end
    elseif mode == 'Tween' then
        if method == 'CFrame' then
            tweenToPosition(hrp, targetCF, Options.TweenSpeed.Value)
        else
            moveToPosition(hrp, targetCF, method)
        end
    end
end

MouseTPGroupBox:AddToggle('MouseTPToggle', {
    Text = 'Enable Mouse TP',
    Default = false,
    Callback = function(Value)
        if Value then
            mouseTPTeleport()
            Toggles.MouseTPToggle:SetValue(false)
        end
    end,
})

MouseTPGroupBox:AddLabel('Mouse TP Keybind'):AddKeyPicker('MouseTPKeybind', {
    Default = 'None',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'Mouse TP Keybind',
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if Options.MouseTPKeybind.Value ~= 'None' then
        local key = Options.MouseTPKeybind.Value
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == key then
            mouseTPTeleport()
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 and key == 'MB1' then
            mouseTPTeleport()
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 and key == 'MB2' then
            mouseTPTeleport()
        end
    end
end)

MouseTPGroupBox:AddDropdown('MouseTPMode', {
    Values = { 'Instant', 'Tween' },
    Default = 1,
    Multi = false,
    Text = 'TP Mode',
})

MouseTPGroupBox:AddDropdown('MouseTPMethod', {
    Values = { 'CFrame', 'Velocity', 'Impulse' },
    Default = 1,
    Multi = false,
    Text = 'TP Method',
})

MouseTPGroupBox:AddSlider('TweenSpeed', {
    Text = 'Tween Speed',
    Default = 1,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
})

local MouseTPDepBox = MouseTPGroupBox:AddDependencyBox()
MouseTPDepBox:AddSlider('TPHeight', {
    Text = 'TP Height Offset',
    Default = 3,
    Min = 0,
    Max = 50,
    Rounding = 0,
})
MouseTPDepBox:SetupDependencies({
    { Toggles.MouseTPToggle, true }
})

local NoclipGroupBox = Tabs.Movement:AddRightGroupbox('Noclip')

NoclipGroupBox:AddToggle('NoclipToggle', {
    Text = 'Enable Noclip',
    Default = false,
})

NoclipGroupBox:AddLabel('Noclip Keybind'):AddKeyPicker('NoclipKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Noclip Keybind',
    Callback = function(Value)
        Toggles.NoclipToggle:SetValue(Value)
    end,
})

NoclipGroupBox:AddDropdown('NoclipMode', {
    Values = { 'Character', 'Part', 'CollisionGroup' },
    Default = 1,
    Multi = false,
    Text = 'Noclip Mode',
})

NoclipGroupBox:AddDropdown('NoclipParts', {
    Values = { 'Head', 'Torso', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg', 'HumanoidRootPart' },
    Default = 1,
    Multi = true,
    Text = 'Body Parts',
})

local noclipOriginalCollisions = {}
local noclipCollisionFolder = nil

local function getSelectedParts()
    local selected = Options.NoclipParts.Value
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

    for name, _ in pairs(selected) do
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
    if not char or not hrp or not hum then return end

    local mode = Options.NoclipMode.Value

    if mode == 'CollisionGroup' then
        noclipCollisionFolder = Instance.new('Folder')
        noclipCollisionFolder.Name = 'NoclipCollisionGroups'
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

    local mode = Options.NoclipMode.Value

    if mode == 'Character' then
        noclipCharacter()
    elseif mode == 'Part' then
        noclipPart()
    elseif mode == 'CollisionGroup' then
        noclipCollisionGroup()
    end
end

Toggles.NoclipToggle:OnChanged(function()
    if Toggles.NoclipToggle.Value then
        startNoclip()
    else
        stopNoclip()
    end
end)

RunService.Stepped:Connect(function()
    if Toggles.NoclipToggle.Value then
        noclipLoop()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if Toggles.NoclipToggle.Value then
        task.wait(0.5)
        startNoclip()
    end
end)

RightGroupBox:AddToggle('JumpToggle', {
    Text = 'Enable Jump',
    Default = false,
    Callback = function(Value)
        if not Value then
            getgenv().JumpPowerSpoof.RestoreJumpPower()
            local char, hrp, hum = getCharacter()
            if hum then
                hum.JumpHeight = Originals.JumpHeight
            end
        end
    end
})

RightGroupBox:AddLabel('Jump Keybind'):AddKeyPicker('JumpKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Jump Keybind',
    Callback = function(Value)
        Toggles.JumpToggle:SetValue(Value)
    end,
})

RightGroupBox:AddDropdown('JumpProperty', {
    Values = { 'JumpPower', 'JumpHeight' },
    Default = 1,
    Multi = false,
    Text = 'Jump Property',
})

RightGroupBox:AddDropdown('JumpMethod', {
    Values = { 'DirectSet', 'Velocity', 'CFrame' },
    Default = 1,
    Multi = false,
    Text = 'Jump Method',
})

RightGroupBox:AddSlider('JumpValue', {
    Text = 'Jump Value',
    Default = 100,
    Min = 0,
    Max = 500,
    Rounding = 0,
})

local HitboxGroupBox = Tabs.Combat:AddRightGroupbox('Hitbox Extender')

HitboxGroupBox:AddToggle('HitboxToggle', {
    Text = 'Enable Hitbox',
    Default = false,
})

HitboxGroupBox:AddLabel('Hitbox Keybind'):AddKeyPicker('HitboxKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Hitbox Keybind',
    Callback = function(Value)
        Toggles.HitboxToggle:SetValue(Value)
    end,
})

HitboxGroupBox:AddDropdown('HitboxParts', {
    Values = { 'All', 'Head', 'Torso', 'HumanoidRootPart', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg' },
    Default = 1,
    Multi = true,
    Text = 'Hitbox Parts',
})

HitboxGroupBox:AddSlider('HitboxSize', {
    Text = 'Hitbox Size',
    Default = 1.5,
    Min = 1.0,
    Max = 3.0,
    Rounding = 1,
})

HitboxGroupBox:AddToggle('HitboxShow', {
    Text = 'Show Hitbox',
    Default = false,
})

HitboxGroupBox:AddLabel('Hitbox Color'):AddColorPicker('HitboxColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'Hitbox Color',
})

HitboxGroupBox:AddDropdown('HitboxMethod', {
    Values = { 'Hook', 'Spoof' },
    Default = 1,
    Multi = false,
    Text = 'Detection Method',
})

local hitboxConnections = {}
local hitboxOverlays = {}
local originalSizes = {}
local originalTransparency = {}
local originalCollision = {}
local hitboxActive = false
local connectionCache = {}

local function getPlayerFromPart(part)
    if not part then return nil end
    local entity = EntityLib.getEntity(part)
    return entity and entity.Player or nil
end

local function getSelectedHitboxParts()
    local selected = Options.HitboxParts.Value
    local parts = {}
    local partMap = {
        ['All'] = { 'Head', 'Torso', 'HumanoidRootPart', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg' },
        ['Head'] = { 'Head' },
        ['Torso'] = { 'Torso' },
        ['HumanoidRootPart'] = { 'HumanoidRootPart' },
        ['Left Arm'] = { 'Left Arm' },
        ['Right Arm'] = { 'Right Arm' },
        ['Left Leg'] = { 'Left Leg' },
        ['Right Leg'] = { 'Right Leg' },
    }
    for name, _ in pairs(selected) do
        if partMap[name] then
            for _, partName in ipairs(partMap[name]) do
                if not table.find(parts, partName) then
                    table.insert(parts, partName)
                end
            end
        end
    end
    return parts
end

local function isTargetPart(partName)
    local selected = getSelectedHitboxParts()
    for _, name in ipairs(selected) do
        if name == partName then return true end
    end
    return false
end

local oldIndex = nil
local oldNewIndex = nil
local oldNamecall = nil
local hitboxHooks = {}

local function setupSpoof()
    if oldIndex then return end

    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
        if not checkcaller() and self:IsA("BasePart") then
            if index == "Size" and originalSizes[self] then
                return originalSizes[self]
            elseif index == "Transparency" and originalTransparency[self] ~= nil then
                return originalTransparency[self]
            elseif index == "CanCollide" and originalCollision[self] ~= nil then
                return originalCollision[self]
            end
        end
        return oldIndex(self, index)
    end))

    oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, index, value)
        if not checkcaller() and self:IsA("BasePart") then
            if index == "Size" and originalSizes[self] then
                originalSizes[self] = value
                return
            elseif index == "Transparency" and originalTransparency[self] ~= nil then
                originalTransparency[self] = value
                return
            elseif index == "CanCollide" and originalCollision[self] ~= nil then
                originalCollision[self] = value
                return
            end
        end
        return oldNewIndex(self, index, value)
    end))

    hitboxHooks.index = oldIndex
    hitboxHooks.newindex = oldNewIndex
end

local function setupNamecallHook()
    if oldNamecall then return end

    oldNamecall = hookmetamethod(Workspace, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "Raycast" then
            local result = oldNamecall(self, unpack(args))

            if type(result) == "table" and result[1] and result[1]:IsA("BasePart") then
                local player = getPlayerFromPart(result[1])
                if player and player ~= LocalPlayer and isTargetPart(result[1].Name) then
                    local head = player.Character and player.Character:FindFirstChild("Head")
                    if head then
                        setnamecallmethod("GetChildren")
                        return head, head.Position, result[3], result[4]
                    end
                end
            end

            if result and result.Instance and result.Instance:IsA("BasePart") then
                local player = getPlayerFromPart(result.Instance)
                if player and player ~= LocalPlayer and isTargetPart(result.Instance.Name) then
                    local head = player.Character and player.Character:FindFirstChild("Head")
                    if head then
                        setnamecallmethod("GetChildren")
                        return head, head.Position, result.Material, result.Normal
                    end
                end
            end

            return result
        end

        return oldNamecall(self, ...)
    end))

    hitboxHooks.namecall = oldNamecall
end

local function removeSpoof()
    if oldIndex then
        hookmetamethod(game, "__index", oldIndex)
        oldIndex = nil
    end
    if oldNewIndex then
        hookmetamethod(game, "__newindex", oldNewIndex)
        oldNewIndex = nil
    end
    if oldNamecall then
        hookmetamethod(Workspace, "__namecall", oldNamecall)
        oldNamecall = nil
    end
    hitboxHooks = {}
end

local function disableConnections(part)
    if not connectionCache[part] then
        connectionCache[part] = {}
    end
    local changedConns = getconnections(part.Changed)
    for _, conn in ipairs(changedConns) do
        if conn.State then
            conn:Disable()
            table.insert(connectionCache[part], conn)
        end
    end
end

local function enableConnections(part)
    if connectionCache[part] then
        for _, conn in ipairs(connectionCache[part]) do
            if not conn.State then
                conn:Enable()
            end
        end
        connectionCache[part] = nil
    end
end

local function spoofHitbox(player)
    local char = player.Character
    if not char then return end

    local selectedParts = getSelectedHitboxParts()
    local hitboxSize = Options.HitboxSize.Value
    local hitboxColor = Options.HitboxColor.Value

    for _, partName in ipairs(selectedParts) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            if not originalSizes[part] then
                originalSizes[part] = part.Size
            end
            if originalTransparency[part] == nil then
                originalTransparency[part] = part.Transparency
            end
            if originalCollision[part] == nil then
                originalCollision[part] = part.CanCollide
            end

            local ref = cloneref(part)
            cache.invalidate(ref)

            disableConnections(part)

            local newSize = Vector3.new(
                originalSizes[part].X * hitboxSize,
                originalSizes[part].Y * hitboxSize,
                originalSizes[part].Z * hitboxSize
            )

            part.Size = newSize
            part.Transparency = 0.5
            part.CanCollide = false

            local hidden, exists = gethiddenproperty(part, "size_xml")
            if exists then
                sethiddenproperty(part, "size_xml", newSize)
            end

            enableConnections(part)
        end
    end
end

local function restoreHitbox(player)
    local char = player.Character
    if not char then return end

    local selectedParts = getSelectedHitboxParts()
    for _, partName in ipairs(selectedParts) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            disableConnections(part)

            if originalSizes[part] then
                part.Size = originalSizes[part]
                originalSizes[part] = nil
            end
            if originalTransparency[part] ~= nil then
                part.Transparency = originalTransparency[part]
                originalTransparency[part] = nil
            end
            if originalCollision[part] ~= nil then
                part.CanCollide = originalCollision[part]
                originalCollision[part] = nil
            end

            enableConnections(part)
        end
    end
end

local function clearOverlays(player)
    if hitboxOverlays[player] then
        for _, overlay in pairs(hitboxOverlays[player]) do
            if overlay then
                Drawing.remove(overlay)
            end
        end
        hitboxOverlays[player] = nil
    end
end

local function createOverlay(player, part, size, color)
    if not hitboxOverlays[player] then
        hitboxOverlays[player] = {}
    end
    if hitboxOverlays[player][part.Name] then
        Drawing.remove(hitboxOverlays[player][part.Name])
    end
    
    local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(part.Position)
    if onScreen then
        local overlay = Drawing.Square(Vector2.new(screenPos.x, screenPos.y), Vector2.new(size.x, size.y), color, 1, true, true)
        overlay.Thickness = 2
        hitboxOverlays[player][part.Name] = overlay
    end
end

local function assignHitbox(player)
    if player == LocalPlayer then return end
    if hitboxConnections[player] then
        hitboxConnections[player]:Disconnect()
    end

    local method = Options.HitboxMethod.Value
    hitboxConnections[player] = RunService.RenderStepped:Connect(function()
        local char = player.Character
        if not char then return end

        if method == "Spoof" then
            local selectedParts = getSelectedHitboxParts()
            local hitboxSize = Options.HitboxSize.Value
            local hitboxColor = Options.HitboxColor.Value

            for _, partName in ipairs(selectedParts) do
                local part = char:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    if not originalSizes[part] then
                        originalSizes[part] = part.Size
                    end
                    local newSize = Vector3.new(
                        originalSizes[part].X * hitboxSize,
                        originalSizes[part].Y * hitboxSize,
                        originalSizes[part].Z * hitboxSize
                    )
                    part.Size = newSize
                    part.Color = hitboxColor
                    part.CanCollide = false
                    part.Transparency = 0.5

                    local hidden, exists = gethiddenproperty(part, "size_xml")
                    if exists then
                        sethiddenproperty(part, "size_xml", newSize)
                    end
                end
            end
        end

        if Toggles.HitboxShow.Value then
            local selectedParts = getSelectedHitboxParts()
            for _, partName in ipairs(selectedParts) do
                local part = char:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    createOverlay(player, part, part.Size, Options.HitboxColor.Value)
                end
            end
        else
            clearOverlays(player)
        end
    end)
end

local function removeHitbox(player)
    if hitboxConnections[player] then
        hitboxConnections[player]:Disconnect()
        hitboxConnections[player] = nil
    end
    clearOverlays(player)
    restoreHitbox(player)
end

local function cleanupHitboxes()
    for player, connection in pairs(hitboxConnections) do
        connection:Disconnect()
        removeHitbox(player)
    end
    hitboxConnections = {}
    for player, _ in pairs(hitboxOverlays) do
        clearOverlays(player)
    end
    hitboxOverlays = {}
    removeSpoof()
    originalSizes = {}
    originalTransparency = {}
    originalCollision = {}
    connectionCache = {}
    hitboxActive = false
end

local function initializeHitbox()
    setupSpoof()
    setupNamecallHook()
    hitboxActive = true
    for _, player in ipairs(Players:GetPlayers()) do
        assignHitbox(player)
    end
end

Toggles.HitboxToggle:OnChanged(function()
    if Toggles.HitboxToggle.Value then
        initializeHitbox()
    else
        cleanupHitboxes()
    end
end)

local TriggerbotGroupBox = Tabs.Combat:AddLeftGroupbox('Triggerbot')

TriggerbotGroupBox:AddToggle('TriggerbotToggle', {
    Text = 'Enable Triggerbot',
    Default = false,
})

TriggerbotGroupBox:AddLabel('Triggerbot Keybind'):AddKeyPicker('TriggerbotKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Hold',
    Text = 'Triggerbot Keybind',
    Callback = function(Value)
        Toggles.TriggerbotToggle:SetValue(Value)
    end,
})

TriggerbotGroupBox:AddToggle('TriggerbotWallCheck', {
    Text = 'Wall Check',
    Default = true,
})

TriggerbotGroupBox:AddSlider('TriggerbotDelay', {
    Text = 'Click Delay',
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 2,
})

local triggerbotConnection = nil

local function isTargetValid(target)
    if not target then return false end
    if not target.Character then return false end

    local entity = EntityLib.getEntity(target)
    if not entity then return false end

    if entity.Health <= 0 then return false end

    if Toggles.TriggerbotWallCheck and Toggles.TriggerbotWallCheck.Value then
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

local function triggerbotLoop()
    local mouse = LocalPlayer:GetMouse()

    if triggerbotConnection then
        triggerbotConnection:Disconnect()
    end

    triggerbotConnection = RunService.Heartbeat:Connect(function()
        if Toggles.TriggerbotToggle.Value and mouse.Target then
            local target = getPlayerFromPart(mouse.Target)
            if target and target ~= LocalPlayer and isTargetValid(target) then
                mouse1press()
                local delay = Options.TriggerbotDelay and Options.TriggerbotDelay.Value or 0.1
                task.wait(delay)
                mouse1release()
            end
        end
    end)
end

Toggles.TriggerbotToggle:OnChanged(function()
    if Toggles.TriggerbotToggle.Value then
        triggerbotLoop()
    else
        if triggerbotConnection then
            triggerbotConnection:Disconnect()
            triggerbotConnection = nil
        end
    end
end)

Options.HitboxSize:OnChanged(function()
    if Toggles.HitboxToggle.Value then
        for _, player in ipairs(Players:GetPlayers()) do
            removeHitbox(player)
            assignHitbox(player)
        end
    end
end)

Options.HitboxColor:OnChanged(function()
    if Toggles.HitboxToggle.Value then
        for _, player in ipairs(Players:GetPlayers()) do
            removeHitbox(player)
            assignHitbox(player)
        end
    end
end)

Options.HitboxParts:OnChanged(function()
    if Toggles.HitboxToggle.Value then
        for _, player in ipairs(Players:GetPlayers()) do
            removeHitbox(player)
            assignHitbox(player)
        end
    end
end)

Options.HitboxMethod:OnChanged(function()
    if Toggles.HitboxToggle.Value then
        cleanupHitboxes()
        initializeHitbox()
    end
end)

Toggles.HitboxShow:OnChanged(function()
    if Toggles.HitboxToggle.Value then
        if not Toggles.HitboxShow.Value then
            for player, _ in pairs(hitboxOverlays) do
                clearOverlays(player)
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    if Toggles.HitboxToggle.Value then
        task.wait(1)
        assignHitbox(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    hitboxConnections[player] = nil
end)

local AimbotGroupBox = Tabs.Combat:AddLeftGroupbox('Aimbot')

AimbotGroupBox:AddToggle('AimbotToggle', {
    Text = 'Enable Aimbot',
    Default = false,
    Callback = function(Value)
        if not Value then
            CamlockEnabled = false
            TargetPlayer = nil
        end
    end,
})

AimbotGroupBox:AddDropdown('AimbotMode', {
    Values = { 'Hold' },
    Default = 1,
    Multi = false,
    Text = 'Aimbot Mode',
})

AimbotGroupBox:AddLabel('Aimbot Keybind'):AddKeyPicker('AimbotKeybind', {
    Default = 'Q',
    SyncToggleState = false,
    Mode = 'Hold',
    Text = 'Aimbot Keybind',
})

local function getAimbotMode()
    return 'Hold'
end


AimbotGroupBox:AddDropdown('AimbotTargetPart', {
    Values = { 'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso' },
    Default = 1,
    Multi = false,
    Text = 'Target Part',
})

AimbotGroupBox:AddDropdown('AimbotTargetMode', {
    Values = { 'Nearest', 'Crosshair', 'Lowest Health' },
    Default = 1,
    Multi = false,
    Text = 'Target Mode',
})

AimbotGroupBox:AddSlider('AimbotFOV', {
    Text = 'FOV',
    Default = 150,
    Min = 10,
    Max = 500,
    Rounding = 0,
})

AimbotGroupBox:AddSlider('AimbotSmoothness', {
    Text = 'Smoothness',
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 0,
})

AimbotGroupBox:AddSlider('AimbotPrediction', {
    Text = 'Prediction',
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 2,
})

AimbotGroupBox:AddToggle('AimbotShowFOV', {
    Text = 'Show FOV Circle',
    Default = true,
})

AimbotGroupBox:AddToggle('AimbotTeamCheck', {
    Text = 'Team Check',
    Default = false,
})

AimbotGroupBox:AddToggle('AimbotAliveCheck', {
    Text = 'Alive Check',
    Default = false,
})

AimbotGroupBox:AddToggle('AimbotWallCheck', {
    Text = 'Wall Check',
    Default = false,
})

AimbotGroupBox:AddToggle('AimbotSilentAim', {
    Text = 'Silent Aim',
    Default = false,
})

AimbotGroupBox:AddToggle('AimbotSticky', {
    Text = 'Sticky',
    Default = false,
})

-- Ensure keypicker mode matches AimbotMode dropdown
if Options.AimbotMode then
    Options.AimbotMode:OnChanged(function()
        local mode = getAimbotMode()
        if Options.AimbotKeybind and Options.AimbotKeybind.SetValue then
            local current = Options.AimbotKeybind.Value
            local key = 'Q'
            if type(current) == 'table' and current[1] then
                key = current[1]
            elseif type(current) == 'string' then
                key = current
            end
            pcall(function()
                Options.AimbotKeybind:SetValue({ key, mode })
            end)
        end
    end)
end

local aimbotFOVCircle
local CamlockEnabled = false
local TargetPlayer = nil

local function createFOVCircle()
    aimbotFOVCircle = Drawing.new('Circle')
    aimbotFOVCircle.Visible = false
    aimbotFOVCircle.Thickness = 2
    aimbotFOVCircle.NumSides = 64
    aimbotFOVCircle.Radius = 100
    aimbotFOVCircle.Color = Color3.fromRGB(255, 255, 255)
    aimbotFOVCircle.Filled = false
    aimbotFOVCircle.Transparency = 1
end

local function GetClosestPlayer()
    local cam = Workspace.CurrentCamera
    local targetMode = Options.AimbotTargetMode and Options.AimbotTargetMode.Value or 'Nearest'
    local fov = Options.AimbotFOV and Options.AimbotFOV.Value or 100
    local targetPart = Options.AimbotTargetPart and Options.AimbotTargetPart.Value or 'Head'
    local teamCheck = Options.AimbotTeamCheck and Options.AimbotTeamCheck.Value
    local aliveCheck = Options.AimbotAliveCheck and Options.AimbotAliveCheck.Value
    local wallCheck = Options.AimbotWallCheck and Options.AimbotWallCheck.Value

    local validPlayers = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local hum = player.Character:FindFirstChildOfClass('Humanoid')
        local part = player.Character:FindFirstChild(targetPart)
        if not hum or not part then continue end

        if aliveCheck and hum.Health <= 0 then continue end
        if teamCheck and player.Team == LocalPlayer.Team then continue end

        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local mousePos = UserInputService:GetMouseLocation()
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

        if dist > fov then continue end

        if wallCheck then
            local rayParams = RaycastParams.new()
            local filterList = {}
            if LocalPlayer.Character then
                table.insert(filterList, LocalPlayer.Character)
            end
            table.insert(filterList, player.Character)
            rayParams.FilterDescendantsInstances = filterList
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local rayResult = Workspace:Raycast(cam.CFrame.Position, (part.Position - cam.CFrame.Position).Unit * 500, rayParams)
            if rayResult and not rayResult.Instance:IsDescendantOf(player.Character) then
                continue
            end
        end

        table.insert(validPlayers, {
            player = player,
            distance = dist,
            health = hum.Health
        })
    end

    if #validPlayers == 0 then return nil end

    if targetMode == 'Nearest' then
        table.sort(validPlayers, function(a, b) return a.distance < b.distance end)
        return validPlayers[1].player
    elseif targetMode == 'Crosshair' then
        table.sort(validPlayers, function(a, b) return a.distance < b.distance end)
        return validPlayers[1].player
    elseif targetMode == 'Lowest Health' then
        table.sort(validPlayers, function(a, b) return a.health < b.health end)
        return validPlayers[1].player
    end

    return validPlayers[1].player
end

local function updateFOVCircle()
    if not aimbotFOVCircle then return end
    -- Only show FOV circle when Aimbot is enabled and user requested to show it
    if not Toggles.AimbotToggle.Value or not Toggles.AimbotShowFOV.Value then
        aimbotFOVCircle.Visible = false
        return
    end

    local mousePos = UserInputService:GetMouseLocation()
    aimbotFOVCircle.Position = mousePos
    aimbotFOVCircle.Radius = Options.AimbotFOV and Options.AimbotFOV.Value or 100
    aimbotFOVCircle.Visible = true
end

createFOVCircle()

Toggles.AimbotToggle:OnChanged(function()
    if not Toggles.AimbotToggle.Value then
        CamlockEnabled = false
        TargetPlayer = nil
    end
end)

local function ValidateTarget()
    if not TargetPlayer then return false end
    if not TargetPlayer.Character then return false end

    local targetPartName = Options.AimbotTargetPart and Options.AimbotTargetPart.Value or 'Head'
    local targetPart = TargetPlayer.Character:FindFirstChild(targetPartName)
    if not targetPart then return false end

    local hum = TargetPlayer.Character:FindFirstChildOfClass('Humanoid')
    if not hum then return false end

    local aliveCheck = false
    if Options.AimbotAliveCheck then aliveCheck = Options.AimbotAliveCheck.Value end
    if aliveCheck and hum.Health <= 0 then return false end

    local teamCheck = false
    if Options.AimbotTeamCheck then teamCheck = Options.AimbotTeamCheck.Value end
    if teamCheck and TargetPlayer.Team == LocalPlayer.Team then return false end

    local cam = Workspace.CurrentCamera
    local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
    if not onScreen then return false end

    local fov = Options.AimbotFOV and Options.AimbotFOV.Value or 100
    local mousePos = UserInputService:GetMouseLocation()
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
    if dist > fov then return false end

    return true
end

RunService.RenderStepped:Connect(function()
    updateFOVCircle()

    local aimbotMode = getAimbotMode()
    if aimbotMode == 'Hold' and Options.AimbotKeybind and Options.AimbotKeybind.GetState then
        if Options.AimbotKeybind:GetState() then
            if not CamlockEnabled then
                CamlockEnabled = true
                TargetPlayer = GetClosestPlayer()
            end
        else
            if CamlockEnabled then
                CamlockEnabled = false
                TargetPlayer = nil
            end
        end
    end

    if CamlockEnabled then
        if Options.AimbotSticky and Options.AimbotSticky.Value then
            if not ValidateTarget() then
                TargetPlayer = GetClosestPlayer()
            end
        else
            if not ValidateTarget() then
                TargetPlayer = GetClosestPlayer()
            end
        end
    end

    if CamlockEnabled and TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild(Options.AimbotTargetPart and Options.AimbotTargetPart.Value or 'Head') then
        local cam = Workspace.CurrentCamera
        local part = TargetPlayer.Character[Options.AimbotTargetPart.Value]
        local smoothness = Options.AimbotSmoothness.Value
        local prediction = Options.AimbotPrediction.Value
        local silentAim = Options.AimbotSilentAim and Options.AimbotSilentAim.Value or false

        print('[Aimbot] Locking onto:', TargetPlayer.Name, 'Part:', Options.AimbotTargetPart.Value, 'Smoothness:', smoothness, 'Prediction:', prediction, 'Silent:', silentAim)

        local targetPos = part.Position
        if prediction > 0 and TargetPlayer.Character:FindFirstChild('HumanoidRootPart') then
            targetPos = targetPos + (TargetPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity * prediction)
        end

        local targetCF = CFrame.new(cam.CFrame.Position, targetPos)

        local smoothFactor
        if silentAim then
            smoothFactor = 0.05
        else
            smoothFactor = math.clamp(1 / smoothness, 0.02, 1)
        end

        cam.CFrame = cam.CFrame:Lerp(targetCF, smoothFactor)
    else
        if CamlockEnabled then
            print('[Aimbot] CamlockEnabled is true but no valid target. TargetPlayer:', TargetPlayer and TargetPlayer.Name or 'nil')
        end
    end
end)

local function heatseekerLoop()
    while Toggles.SpeedToggle.Value and Options.SpeedMethod.Value == 'Heatseeker' do
        local char, hrp, hum = getCharacter()
        if char and hrp and hum then
            isBoosting = true
            local dir = getDirection()
            if dir.Magnitude > 0 then
                hrp.Velocity = dir * Options.SpeedValue.Value + Vector3.new(0, hrp.Velocity.Y, 0)
            end
            task.wait(Options.HeatseekerDuration.Value)
            isBoosting = false
            hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
            task.wait(Options.HeatseekerTicks.Value)
        else
            task.wait(0.1)
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not Toggles.SpeedToggle.Value then return end

    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return end

    local method = Options.SpeedMethod.Value
    local dir = getDirection()
    if dir.Magnitude == 0 then return end

    local speed = Options.SpeedValue.Value
    local vel = dir * speed

    if method == 'Velocity' then
        hrp.Velocity = vel + Vector3.new(0, hrp.Velocity.Y, 0)
    elseif method == 'WalkSpeed' then
        getgenv().WalkSpeedSpoof.SetWalkSpeed(speed)
    elseif method == 'Impulse' then
        hrp:ApplyImpulse(Vector3.new(vel.X, 0, vel.Z) * hrp.AssemblyMass)
    end
end)

Options.SpeedMethod:OnChanged(function()
    if Toggles.SpeedToggle.Value and Options.SpeedMethod.Value == 'Heatseeker' then
        task.spawn(heatseekerLoop)
    end
end)

Toggles.SpeedToggle:OnChanged(function()
    if Toggles.SpeedToggle.Value and Options.SpeedMethod.Value == 'Heatseeker' then
        task.spawn(heatseekerLoop)
    end
end)

local function onJump()
    if not Toggles.JumpToggle.Value then return end

    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return end

    local method = Options.JumpMethod.Value
    local prop = Options.JumpProperty.Value
    local value = Options.JumpValue.Value

    if method == 'DirectSet' then
        if prop == 'JumpPower' then
            getgenv().JumpPowerSpoof.SetJumpPower(value)
        else
            hum.JumpHeight = value
        end
    elseif method == 'Velocity' then
        hrp.Velocity = Vector3.new(hrp.Velocity.X, value, hrp.Velocity.Z)
    elseif method == 'CFrame' then
        hrp.CFrame = hrp.CFrame + Vector3.new(0, value, 0)
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

local ACBypassGroupBox = Tabs.Exploits:AddRightGroupbox('AC Bypass')

ACBypassGroupBox:AddToggle('ACBypass', {
    Text = 'Enable AC Bypass',
    Default = false,
})

ACBypassGroupBox:AddLabel('AC Bypass Keybind'):AddKeyPicker('ACBypassKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'AC Bypass Keybind',
    Callback = function(Value)
        Toggles.ACBypass:SetValue(Value)
    end,
})

ACBypassGroupBox:AddSlider('ACWalkSpeed', {
    Text = 'Spoofed WalkSpeed',
    Default = 16,
    Min = 0,
    Max = 500,
    Rounding = 0,
})

ACBypassGroupBox:AddSlider('ACJumpPower', {
    Text = 'Spoofed JumpPower',
    Default = 50,
    Min = 0,
    Max = 500,
    Rounding = 0,
})

ACBypassGroupBox:AddSlider('ACJumpHeight', {
    Text = 'Spoofed JumpHeight',
    Default = 7,
    Min = 0,
    Max = 100,
    Rounding = 1,
})

ACBypassGroupBox:AddButton('Kill AC Scripts', function()
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            local name = string.lower(obj.Name)
            if
                obj:IsA('LocalScript')
                or obj:IsA('ModuleScript')
            then
                local acNames = {
                    'anticheat', 'ac_', 'ac-', 'detector', 'detection',
                    'guard', 'protector', 'watchdog', 'sentinel',
                    'minimetrics', 'wally', 'byfron', 'hyperion',
                    'frida', 'tracer', 'check', 'validator',
                    'anticheatclient', 'anticheatserver',
                    'acclient', 'acserver',
                }
                for _, acName in ipairs(acNames) do
                    if string.find(name, acName) then
                        obj.Disabled = true
                        obj:Destroy()
                        break
                    end
                end
            end
        end
    end)
end)

ACBypassGroupBox:AddLabel('Status: Inactive')

local cloneref = cloneref or function(...)
    return ...
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

Options.ACWalkSpeed:OnChanged(function()
    spoofedProperties.WalkSpeed = Options.ACWalkSpeed.Value
end)

Options.ACJumpPower:OnChanged(function()
    spoofedProperties.JumpPower = Options.ACJumpPower.Value
end)

Options.ACJumpHeight:OnChanged(function()
    spoofedProperties.JumpHeight = Options.ACJumpHeight.Value
end)

Toggles.ACBypass:OnChanged(function()
    if Toggles.ACBypass.Value then
        spoofedProperties.WalkSpeed = Options.ACWalkSpeed.Value
        spoofedProperties.JumpPower = Options.ACJumpPower.Value
        spoofedProperties.JumpHeight = Options.ACJumpHeight.Value
    else
        spoofedProperties.WalkSpeed = Originals.WalkSpeed
        spoofedProperties.JumpPower = Originals.JumpPower
        spoofedProperties.JumpHeight = Originals.JumpHeight
    end
end)

local FlyGroupBox = Tabs.Movement:AddRightGroupbox('Fly')

FlyGroupBox:AddToggle('FlyToggle', {
    Text = 'Enable Fly',
    Default = false,
})

FlyGroupBox:AddLabel('Fly Keybind'):AddKeyPicker('FlyKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Fly Keybind',
    Callback = function(Value)
        Toggles.FlyToggle:SetValue(Value)
    end,
})

FlyGroupBox:AddDropdown('FlyMethod', {
    Values = { 'CFrame', 'Velocity', 'BodyVelocity', 'LinearVelocity' },
    Default = 1,
    Multi = false,
    Text = 'Fly Method',
})

FlyGroupBox:AddSlider('FlySpeed', {
    Text = 'Horizontal Speed',
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
})

FlyGroupBox:AddSlider('FlyVerticalSpeed', {
    Text = 'Vertical Speed',
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
})

FlyGroupBox:AddLabel('Up Key'):AddKeyPicker('FlyUpKey', {
    Default = 'Space',
    Mode = 'Hold',
    Text = 'Up Key',
})

FlyGroupBox:AddLabel('Down Key'):AddKeyPicker('FlyDownKey', {
    Default = 'LeftShift',
    Mode = 'Hold',
    Text = 'Down Key',
})

FlyGroupBox:AddToggle('FlyAutoDisable', {
    Text = 'Auto Disable on Death',
    Default = true,
})

local flyActive = false
local flyBV

local function startFly()
    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return end

    flyActive = true
    local method = Options.FlyMethod.Value

    if method == 'CFrame' then
        flyBV = Instance.new('BodyVelocity')
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
    elseif method == 'Velocity' then
        flyBV = Instance.new('BodyVelocity')
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
    elseif method == 'BodyVelocity' then
        flyBV = Instance.new('BodyVelocity')
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
    elseif method == 'LinearVelocity' then
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

Toggles.FlyToggle:OnChanged(function()
    if Toggles.FlyToggle.Value then
        startFly()
    else
        stopFly()
    end
end)

if Toggles.FlyAutoDisable and Toggles.FlyAutoDisable.Value then
    LocalPlayer.CharacterAdded:Connect(function(char)
        if Toggles.FlyToggle.Value then
            task.wait(0.5)
            stopFly()
            Toggles.FlyToggle:SetValue(false)
        end
    end)
end

RunService.Heartbeat:Connect(function(dt)
    if not flyActive then return end

    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then
        stopFly()
        return
    end

    local cam = Workspace.CurrentCamera
    local method = Options.FlyMethod.Value
    local speed = Options.FlySpeed.Value
    local vertSpeed = Options.FlyVerticalSpeed.Value

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
    if UserInputService:IsKeyDown(Options.FlyUpKey.Value) then
        vertical = 1
    end
    if UserInputService:IsKeyDown(Options.FlyDownKey.Value) then
        vertical = -1
    end

    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit * speed
    end

    local finalVelocity = Vector3.new(moveDir.X, vertical * vertSpeed, moveDir.Z)

    if method == 'CFrame' then
        if flyBV then
            flyBV.Velocity = finalVelocity
        end
    elseif method == 'Velocity' then
        if flyBV then
            flyBV.Velocity = finalVelocity
        end
    elseif method == 'BodyVelocity' then
        if flyBV then
            flyBV.Velocity = finalVelocity
        end
    elseif method == 'LinearVelocity' then
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
end)

local InfJumpGroupBox = Tabs.Movement:AddLeftGroupbox('Infinite Jump')
local infJumpConnections = {}

InfJumpGroupBox:AddToggle('InfJumpToggle', {
    Text = 'Enable Infinite Jump',
    Default = false,
})

InfJumpGroupBox:AddLabel('Inf Jump Keybind'):AddKeyPicker('InfJumpKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Inf Jump Keybind',
    Callback = function(Value)
        Toggles.InfJumpToggle:SetValue(Value)
    end,
})

InfJumpGroupBox:AddDropdown('InfJumpMethod', {
    Values = { 'Hold', 'Once' },
    Default = 1,
    Multi = false,
    Text = 'Jump Mode',
})

InfJumpGroupBox:AddSlider('InfJumpHeight', {
    Text = 'Jump Height',
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
})

InfJumpGroupBox:AddDropdown('InfJumpType', {
    Values = { 'Velocity', 'CFrame', 'BodyVelocity' },
    Default = 1,
    Multi = false,
    Text = 'Jump Type',
})

Toggles.InfJumpToggle:OnChanged(function()
    if Toggles.InfJumpToggle.Value then
        local function doJump()
            local c, h, m = getCharacter()
            if not c or not h or not m then return end

            local jumpType = Options.InfJumpType.Value
            local height = Options.InfJumpHeight.Value

            if jumpType == 'Velocity' then
                local bv = Instance.new('BodyVelocity')
                bv.MaxForce = Vector3.new(0, math.huge, 0)
                bv.Velocity = Vector3.new(0, height, 0)
                bv.Parent = h
                game:GetService('Debris'):AddItem(bv, 0.15)
            elseif jumpType == 'CFrame' then
                h.CFrame = h.CFrame + Vector3.new(0, height * 0.1, 0)
            elseif jumpType == 'BodyVelocity' then
                local bv = Instance.new('BodyVelocity')
                bv.MaxForce = Vector3.new(0, math.huge, 0)
                bv.Velocity = Vector3.new(0, height, 0)
                bv.Parent = h
                game:GetService('Debris'):AddItem(bv, 0.2)
            end
        end

        local method = Options.InfJumpMethod.Value

        if method == 'Hold' then
            local conn = RunService.Heartbeat:Connect(function()
                if not Toggles.InfJumpToggle.Value then
                    conn:Disconnect()
                    return
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    doJump()
                end
            end)
            table.insert(infJumpConnections, conn)
        elseif method == 'Once' then
            local pressing = false
            local conn = UserInputService.InputBegan:Connect(function(input, gpe)
                if not Toggles.InfJumpToggle.Value then
                    conn:Disconnect()
                    return
                end
                if gpe then return end
                if input.KeyCode == Enum.KeyCode.Space and not pressing then
                    pressing = true
                    doJump()
                end
            end)
            local conn2 = UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Space then
                    pressing = false
                end
            end)
            table.insert(infJumpConnections, conn)
            table.insert(infJumpConnections, conn2)
        end
    else
        for _, conn in ipairs(infJumpConnections) do
            if conn.Connected then
                conn:Disconnect()
            end
        end
        infJumpConnections = {}
    end
end)

local SpinbotGroupBox = Tabs.Combat:AddLeftGroupbox('Spinbot')

SpinbotGroupBox:AddToggle('SpinbotToggle', {
    Text = 'Enable Spinbot',
    Default = false,
})

SpinbotGroupBox:AddLabel('Spinbot Keybind'):AddKeyPicker('SpinbotKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Spinbot Keybind',
    Callback = function(Value)
        Toggles.SpinbotToggle:SetValue(Value)
    end,
})

SpinbotGroupBox:AddDropdown('SpinAxis', {
    Values = { 'Y', 'X', 'Z', 'Random' },
    Default = 1,
    Multi = false,
    Text = 'Spin Axis',
})

SpinbotGroupBox:AddSlider('SpinSpeed', {
    Text = 'Spin Speed',
    Default = 50,
    Min = 1,
    Max = 500,
    Rounding = 0,
})

local AntiAFKGroupBox = Tabs.Misc:AddLeftGroupbox('Anti-AFK')

AntiAFKGroupBox:AddToggle('AntiAFK', {
    Text = 'Enable Anti-AFK',
    Default = false,
})

AntiAFKGroupBox:AddLabel('Anti-AFK Keybind'):AddKeyPicker('AntiAFKKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Anti-AFK Keybind',
    Callback = function(Value)
        Toggles.AntiAFK:SetValue(Value)
    end,
})

AntiAFKGroupBox:AddDropdown('AntiAFKMethod', {
    Values = { 'Click', 'Jump' },
    Default = 1,
    Multi = false,
    Text = 'Anti-AFK Method',
})

AntiAFKGroupBox:AddSlider('AntiAFKInterval', {
    Text = 'Interval (sec)',
    Default = 60,
    Min = 10,
    Max = 300,
    Rounding = 0,
})

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
    local method = Options.AntiAFKMethod.Value

    if method == 'Click' then
        antiAFKClick()
    elseif method == 'Jump' then
        antiAFKJump()
    end
end

Toggles.AntiAFK:OnChanged(function()
    if Toggles.AntiAFK.Value then
        task.spawn(function()
            while Toggles.AntiAFK.Value do
                doAntiAFK()
                task.wait(Options.AntiAFKInterval.Value)
            end
        end)
    end
end)

local MiscVisualsGroup = Tabs.Misc:AddLeftGroupbox('Visuals')

MiscVisualsGroup:AddToggle('MiscFOVToggle', {
    Text = 'Enable FOV Changer',
    Default = false,
})

MiscVisualsGroup:AddSlider('MiscFOVValue', {
    Text = 'Field of View',
    Default = 70,
    Min = 30,
    Max = 120,
    Rounding = 0,
})

MiscVisualsGroup:AddButton('Reset FOV', function()
    Workspace.CurrentCamera.FieldOfView = Originals.FOV
end)

Toggles.MiscFOVToggle:OnChanged(function()
    if Toggles.MiscFOVToggle.Value then
        Workspace.CurrentCamera.FieldOfView = Options.MiscFOVValue.Value
    else
        Workspace.CurrentCamera.FieldOfView = Originals.FOV
    end
end)

Options.MiscFOVValue:OnChanged(function()
    if Toggles.MiscFOVToggle.Value then
        Workspace.CurrentCamera.FieldOfView = Options.MiscFOVValue.Value
    end
end)


local spinAngle = 0

RunService.Heartbeat:Connect(function(dt)
    if not Toggles.SpinbotToggle.Value then return end

    local char, hrp, hum = getCharacter()
    if not char or not hrp or not hum then return end

    local axis = Options.SpinAxis.Value
    local speed = Options.SpinSpeed.Value

    spinAngle = spinAngle + (speed * dt)
    if spinAngle > 360 then
        spinAngle = spinAngle - 360
    end

    if axis == 'Y' then
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
    elseif axis == 'X' then
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(math.rad(spinAngle), 0, 0)
    elseif axis == 'Z' then
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, 0, math.rad(spinAngle))
    elseif axis == 'Random' then
        local rx = math.random() * 2 - 1
        local ry = math.random() * 2 - 1
        local rz = math.random() * 2 - 1
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(
            math.rad(rx * speed),
            math.rad(ry * speed),
            math.rad(rz * speed)
        )
    end
end)

local ChamsGroupBox = Tabs.Visuals:AddLeftGroupbox('Chams')

ChamsGroupBox:AddToggle('ChamsToggle', {
    Text = 'Enable Chams',
    Default = false,
})

ChamsGroupBox:AddLabel('Chams Keybind'):AddKeyPicker('ChamsKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Chams Keybind',
    Callback = function(Value)
        Toggles.ChamsToggle:SetValue(Value)
    end,
})

ChamsGroupBox:AddDropdown('ChamsMode', {
    Values = { 'Highlight', 'Material', 'Engine' },
    Default = 1,
    Multi = false,
    Text = 'Chams Mode',
})

ChamsGroupBox:AddDropdown('ChamsTarget', {
    Values = { 'All', 'Head', 'Body', 'Arms', 'Legs', 'HumanoidRootPart' },
    Default = 1,
    Multi = true,
    Text = 'Chams Target',
})

ChamsGroupBox:AddLabel('Chams Fill'):AddColorPicker('ChamsFillColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'Fill Color',
})

ChamsGroupBox:AddLabel('Chams Outline'):AddColorPicker('ChamsOutlineColor', {
    Default = Color3.fromRGB(0, 0, 0),
    Title = 'Outline Color',
})

ChamsGroupBox:AddSlider('ChamsFillTransparency', {
    Text = 'Fill Transparency',
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
})

ChamsGroupBox:AddSlider('ChamsOutlineTransparency', {
    Text = 'Outline Transparency',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
})

ChamsGroupBox:AddDropdown('ChamsMaterial', {
    Values = { 'ForceField', 'Neon', 'Glass', 'SmoothPlastic', 'DiamondPlate', 'Chrome', 'WoodPlanks', 'Marble', 'Granite', 'Cobblestone', 'Brick', 'Sand', 'Grass' },
    Default = 1,
    Multi = false,
    Text = 'Engine Material',
})

ChamsGroupBox:AddToggle('ChamsThroughWalls', {
    Text = 'Through Walls',
    Default = true,
})

ChamsGroupBox:AddToggle('ChamsOccluded', {
    Text = 'Occluded',
    Default = true,
})

local chamsInstances = {}
local chamsHighlights = {}

local function getChamsTargets()
    local selected = Options.ChamsTarget.Value
    local targets = {}

    local targetMap = {
        ['All'] = { 'Head', 'Torso', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg', 'HumanoidRootPart' },
        ['Head'] = { 'Head' },
        ['Body'] = { 'Torso', 'HumanoidRootPart' },
        ['Arms'] = { 'Left Arm', 'Right Arm' },
        ['Legs'] = { 'Left Leg', 'Right Leg' },
        ['HumanoidRootPart'] = { 'HumanoidRootPart' },
    }

    for name, _ in pairs(selected) do
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
    if chamsHighlights[player] then
        for _, highlight in pairs(chamsHighlights[player]) do
            pcall(function()
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
            end)
        end
        chamsHighlights[player] = nil
    end

    if chamsInstances[player] then
        for _, data in pairs(chamsInstances[player]) do
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
        chamsInstances[player] = nil
    end
end

local function createHighlightChams(player, char)
    if chamsHighlights[player] then return end
    chamsHighlights[player] = {}

    local highlight = Instance.new('Highlight')
    highlight.Name = 'ChamsHighlight'
    highlight.FillColor = Options.ChamsFillColor.Value
    highlight.OutlineColor = Options.ChamsOutlineColor.Value
    highlight.FillTransparency = Options.ChamsFillTransparency.Value
    highlight.OutlineTransparency = Options.ChamsOutlineTransparency.Value
    highlight.DepthMode = Toggles.ChamsThroughWalls.Value and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.Adornee = char
    highlight.Parent = char

    chamsHighlights[player] = { highlight = highlight }
end

local function createMaterialChams(player, char)
    if chamsInstances[player] then return end
    chamsInstances[player] = {}

    local targets = getChamsTargets()
    local material = Enum.Material[Options.ChamsMaterial.Value]
    local fillColor = Options.ChamsFillColor.Value
    local fillTransparency = Options.ChamsFillTransparency.Value

    for _, partName in ipairs(targets) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA('BasePart') then
            local chamsPart = Instance.new('Part')
            chamsPart.Name = 'ChamsPart_' .. partName
            chamsPart.Size = part.Size + Vector3.new(0.05, 0.05, 0.05)
            chamsPart.CFrame = part.CFrame
            chamsPart.Anchored = false
            chamsPart.CanCollide = false
            chamsPart.Transparency = fillTransparency
            chamsPart.Color = fillColor
            chamsPart.Material = material
            chamsPart.Parent = char

            local weld = Instance.new('WeldConstraint')
            weld.Part0 = part
            weld.Part1 = chamsPart
            weld.Parent = chamsPart

            table.insert(chamsInstances[player], chamsPart)
        end
    end
end

local function createEngineChams(player, char)
    if chamsInstances[player] then return end
    chamsInstances[player] = {}

    local targets = getChamsTargets()
    local fillColor = Options.ChamsFillColor.Value

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
                        child.VertexColor = Vector3.new(fillColor.R, fillColor.G, fillColor.B)
                        child.TextureId = ""
                    end

                    table.insert(meshData.meshes, meshInfo)
                end
            end

            part.Color = fillColor
            part.Transparency = math.clamp(Options.ChamsFillTransparency.Value, 0, 0.99)
            part.Material = Enum.Material.SmoothPlastic
            part.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0, 0, 0, 0)

            table.insert(chamsInstances[player], meshData)
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

    local mode = Options.ChamsMode.Value

    if mode == 'Highlight' then
        createHighlightChams(player, char)
    elseif mode == 'Material' then
        createMaterialChams(player, char)
    elseif mode == 'Engine' then
        createEngineChams(player, char)
    end
end

local function removeChams(player)
    clearChams(player)
end

local function cleanupChams()
    for player, _ in pairs(chamsHighlights) do
        clearChams(player)
    end
    for player, _ in pairs(chamsInstances) do
        clearChams(player)
    end
    chamsHighlights = {}
    chamsInstances = {}
end

Toggles.ChamsToggle:OnChanged(function()
    if Toggles.ChamsToggle.Value then
        for _, player in ipairs(Players:GetPlayers()) do
            applyChams(player)
        end
    else
        cleanupChams()
    end
end)

Options.ChamsMode:OnChanged(function()
    if Toggles.ChamsToggle.Value then
        cleanupChams()
        for _, player in ipairs(Players:GetPlayers()) do
            applyChams(player)
        end
    end
end)

Options.ChamsTarget:OnChanged(function()
    if Toggles.ChamsToggle.Value then
        cleanupChams()
        for _, player in ipairs(Players:GetPlayers()) do
            applyChams(player)
        end
    end
end)

Options.ChamsFillColor:OnChanged(function()
    if Toggles.ChamsToggle.Value then
        cleanupChams()
        for _, player in ipairs(Players:GetPlayers()) do
            applyChams(player)
        end
    end
end)

Options.ChamsOutlineColor:OnChanged(function()
    if Toggles.ChamsToggle.Value then
        cleanupChams()
        for _, player in ipairs(Players:GetPlayers()) do
            applyChams(player)
        end
    end
end)

Options.ChamsFillTransparency:OnChanged(function()
    if Toggles.ChamsToggle.Value then
        cleanupChams()
        for _, player in ipairs(Players:GetPlayers()) do
            applyChams(player)
        end
    end
end)

Options.ChamsOutlineTransparency:OnChanged(function()
    if Toggles.ChamsToggle.Value and Options.ChamsMode.Value == 'Highlight' then
        for player, data in pairs(chamsHighlights) do
            if data.highlight then
                data.highlight.OutlineTransparency = Options.ChamsOutlineTransparency.Value
            end
        end
    end
end)

Options.ChamsMaterial:OnChanged(function()
    if Toggles.ChamsToggle.Value and Options.ChamsMode.Value == 'Material' then
        cleanupChams()
        for _, player in ipairs(Players:GetPlayers()) do
            applyChams(player)
        end
    end
end)

Toggles.ChamsThroughWalls:OnChanged(function()
    if Toggles.ChamsToggle.Value and Options.ChamsMode.Value == 'Highlight' then
        for player, data in pairs(chamsHighlights) do
            if data.highlight then
                data.highlight.DepthMode = Toggles.ChamsThroughWalls.Value and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        end
    end
end)

Toggles.ChamsOccluded:OnChanged(function()
    if Toggles.ChamsToggle.Value and Options.ChamsMode.Value == 'Highlight' then
        for player, data in pairs(chamsHighlights) do
            if data.highlight then
                data.highlight.Occluded = Toggles.ChamsOccluded.Value
            end
        end
    end
end)

local function connectPlayerChams(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        if Toggles.ChamsToggle.Value then
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


local LightingGroupBox = Tabs.Visuals:AddRightGroupbox('Lighting')

LightingGroupBox:AddToggle('FullbrightToggle', {
    Text = 'Fullbright',
    Default = false,
})

LightingGroupBox:AddToggle('NoFogToggle', {
    Text = 'No Fog',
    Default = false,
})

LightingGroupBox:AddSlider('BrightnessValue', {
    Text = 'Brightness',
    Default = 2,
    Min = 0,
    Max = 10,
    Rounding = 1,
})

LightingGroupBox:AddLabel('Time of Day'):AddColorPicker('AmbientColor', {
    Default = Originals.Ambient,
    Title = 'Ambient Color',
})

LightingGroupBox:AddButton('Reset Lighting', function()
    Lighting.Brightness = Originals.Brightness
    Lighting.GlobalShadows = Originals.GlobalShadows
    Lighting.FogEnd = Originals.FogEnd
    Lighting.FogStart = Originals.FogStart
    Lighting.Ambient = Originals.Ambient
    Lighting.OutdoorAmbient = Originals.OutdoorAmbient
    Lighting.ClockTime = Originals.ClockTime
end)

Toggles.FullbrightToggle:OnChanged(function()
    if Toggles.FullbrightToggle.Value then
        Lighting.Brightness = Options.BrightnessValue.Value
        Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = Originals.Brightness
        Lighting.GlobalShadows = Originals.GlobalShadows
        Lighting.Ambient = Originals.Ambient
        Lighting.OutdoorAmbient = Originals.OutdoorAmbient
    end
end)

Options.BrightnessValue:OnChanged(function()
    if Toggles.FullbrightToggle.Value then
        Lighting.Brightness = Options.BrightnessValue.Value
    end
end)

Toggles.NoFogToggle:OnChanged(function()
    if Toggles.NoFogToggle.Value then
        Lighting.FogEnd = 999999
        Lighting.FogStart = 999999
    else
        Lighting.FogEnd = Originals.FogEnd
        Lighting.FogStart = Originals.FogStart
    end
end)

local ESPGroupBox = Tabs.Visuals:AddLeftGroupbox('ESP')

ESPGroupBox:AddToggle('ESPToggle', {
    Text = 'Enable ESP',
    Default = false,
})

ESPGroupBox:AddLabel('ESP Keybind'):AddKeyPicker('ESPKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'ESP Keybind',
    Callback = function(Value)
        Toggles.ESPToggle:SetValue(Value)
    end,
})

ESPGroupBox:AddDropdown('ESPItems', {
    Values = { 'Box', 'Name', 'Health', 'Distance', 'Tracers', 'LookAngle', 'Skeleton', 'Tool' },
    Default = 1,
    Multi = true,
    Text = 'ESP Elements',
})

ESPGroupBox:AddLabel('ESP Color'):AddColorPicker('ESPColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'ESP Color',
})

ESPGroupBox:AddLabel('Health Low'):AddColorPicker('ESPHealthLow', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'Health Low',
})

ESPGroupBox:AddLabel('Health High'):AddColorPicker('ESPHealthHigh', {
    Default = Color3.fromRGB(0, 255, 0),
    Title = 'Health High',
})

ESPGroupBox:AddLabel('Team Color'):AddColorPicker('ESPTeamColor', {
    Default = Color3.fromRGB(0, 255, 0),
    Title = 'Team Color',
})

ESPGroupBox:AddLabel('Enemy Color'):AddColorPicker('ESPEnemyColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Enemy Color',
})

ESPGroupBox:AddDropdown('ESPFont', {
    Values = { 'Code', 'ArialBold', 'GothamBold', 'Gotham', 'Legacy', 'Highway', 'Cartoon', 'SciFi' },
    Default = 1,
    Multi = false,
    Text = 'Font',
})

ESPGroupBox:AddSlider('ESPThickness', {
    Text = 'Line Thickness',
    Default = 1,
    Min = 1,
    Max = 3,
    Rounding = 0,
})

ESPGroupBox:AddSlider('ESPTextSize', {
    Text = 'Text Size',
    Default = 16,
    Min = 10,
    Max = 30,
    Rounding = 0,
})

ESPGroupBox:AddSlider('ESPMaxDistance', {
    Text = 'Max Distance',
    Default = 1000,
    Min = 100,
    Max = 5000,
    Rounding = 0,
})

ESPGroupBox:AddToggle('ESPShowTeam', {
    Text = 'Show Teammates',
    Default = true,
})

local espObjects = {}

local function getSelectedESPItems()
    local selected = Options.ESPItems.Value
    local items = {}
    for name, _ in pairs(selected) do
        items[name] = true
    end
    return items
end

local function getESPColor(player)
    if player.Team and player.Team == LocalPlayer.Team then
        return Options.ESPTeamColor.Value
    end
    return Options.ESPEnemyColor.Value
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
    if espObjects[player] then return end

    espObjects[player] = {
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
            LeftShoulder = Drawing.new('Line'),
            LeftArm = Drawing.new('Line'),
            RightShoulder = Drawing.new('Line'),
            RightArm = Drawing.new('Line'),
            Spine = Drawing.new('Line'),
            LeftHip = Drawing.new('Line'),
            LeftLeg = Drawing.new('Line'),
            RightHip = Drawing.new('Line'),
            RightLeg = Drawing.new('Line'),
        },
    }

    local thickness = Options.ESPThickness.Value
    local textSize = Options.ESPTextSize.Value

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
    local font = fontMap[Options.ESPFont.Value] or 2

    for _, line in ipairs(espObjects[player].BoxOutline) do
        line.Visible = false
        line.Color = Color3.new(0, 0, 0)
        line.Thickness = thickness + 2
    end

    for _, line in ipairs(espObjects[player].Box) do
        line.Visible = false
        line.Thickness = thickness
    end

    espObjects[player].Name.Visible = false
    espObjects[player].Name.Font = font
    espObjects[player].Name.Size = textSize
    espObjects[player].Name.Center = true
    espObjects[player].Name.Outline = true
    espObjects[player].Name.OutlineColor = Color3.new(0, 0, 0)

    espObjects[player].HealthBarOutline.Visible = false
    espObjects[player].HealthBarOutline.Color = Color3.new(0, 0, 0)
    espObjects[player].HealthBarOutline.Thickness = 4

    espObjects[player].HealthBar.Visible = false
    espObjects[player].HealthBar.Thickness = 2

    espObjects[player].HealthText.Visible = false
    espObjects[player].HealthText.Font = font
    espObjects[player].HealthText.Size = textSize - 2
    espObjects[player].HealthText.Center = true
    espObjects[player].HealthText.Outline = true
    espObjects[player].HealthText.OutlineColor = Color3.new(0, 0, 0)

    espObjects[player].Distance.Visible = false
    espObjects[player].Distance.Font = font
    espObjects[player].Distance.Size = textSize - 2
    espObjects[player].Distance.Center = true
    espObjects[player].Distance.Outline = true
    espObjects[player].Distance.OutlineColor = Color3.new(0, 0, 0)

    espObjects[player].Tracer.Visible = false
    espObjects[player].Tracer.Thickness = thickness

    espObjects[player].TracerOutline.Visible = false
    espObjects[player].TracerOutline.Color = Color3.new(0, 0, 0)
    espObjects[player].TracerOutline.Thickness = thickness + 2

    espObjects[player].LookAngle.Visible = false
    espObjects[player].LookAngle.Thickness = thickness

    espObjects[player].LookAngleOutline.Visible = false
    espObjects[player].LookAngleOutline.Color = Color3.new(0, 0, 0)
    espObjects[player].LookAngleOutline.Thickness = thickness + 2

    espObjects[player].Tool.Visible = false
    espObjects[player].Tool.Font = font
    espObjects[player].Tool.Size = textSize - 2
    espObjects[player].Tool.Center = false
    espObjects[player].Tool.Outline = true
    espObjects[player].Tool.OutlineColor = Color3.new(0, 0, 0)

    for _, line in pairs(espObjects[player].Skeleton) do
        line.Visible = false
        line.Thickness = thickness
    end
end

local function removeESPObjects(player)
    if not espObjects[player] then return end

    for _, line in ipairs(espObjects[player].BoxOutline) do line:Remove() end
    for _, line in ipairs(espObjects[player].Box) do line:Remove() end
    espObjects[player].Name:Remove()
    espObjects[player].HealthBarOutline:Remove()
    espObjects[player].HealthBar:Remove()
    espObjects[player].HealthText:Remove()
    espObjects[player].Distance:Remove()
    espObjects[player].Tracer:Remove()
    espObjects[player].TracerOutline:Remove()
    espObjects[player].LookAngle:Remove()
    espObjects[player].LookAngleOutline:Remove()
    espObjects[player].Tool:Remove()
    for _, line in pairs(espObjects[player].Skeleton) do line:Remove() end

    espObjects[player] = nil
end

local function hideAll(player)
    if not espObjects[player] then return end
    for _, line in ipairs(espObjects[player].BoxOutline) do line.Visible = false end
    for _, line in ipairs(espObjects[player].Box) do line.Visible = false end
    espObjects[player].Name.Visible = false
    espObjects[player].HealthBarOutline.Visible = false
    espObjects[player].HealthBar.Visible = false
    espObjects[player].HealthText.Visible = false
    espObjects[player].Distance.Visible = false
    espObjects[player].Tracer.Visible = false
    espObjects[player].TracerOutline.Visible = false
    espObjects[player].LookAngle.Visible = false
    espObjects[player].LookAngleOutline.Visible = false
    espObjects[player].Tool.Visible = false
    for _, line in pairs(espObjects[player].Skeleton) do line.Visible = false end
end

local function updateESP(player)
    if not Toggles.ESPToggle.Value then return end

    local esp = espObjects[player]
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
    if dist > Options.ESPMaxDistance.Value then hideAll(player) return end

    local _, onScreen = cam:WorldToViewportPoint(hrp.Position)
    if not onScreen then hideAll(player) return end

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
            esp.HealthBar.Color = Options.ESPHealthLow.Value:Lerp(Options.ESPHealthHigh.Value, healthPercent)
            esp.HealthBar.Visible = true

            esp.HealthText.Text = math.floor(humanoid.Health) .. ' / ' .. math.floor(humanoid.MaxHealth)
            esp.HealthText.Position = Vector2.new(barX - 2 - (esp.HealthText.Size * string.len(esp.HealthText.Text) * 0.6), box.Center.Y)
            esp.HealthText.Center = false
            esp.HealthText.Color = color
            esp.HealthText.Visible = true
        end

        if items['Tracers'] then
            local screenSize = cam.ViewportSize
            local fromPos = Vector2.new(screenSize.X / 2, screenSize.Y)

            esp.TracerOutline.From = fromPos
            esp.TracerOutline.To = Vector2.new(box.Center.X, box.Bottom.Y)
            esp.TracerOutline.Visible = true

            esp.Tracer.From = fromPos
            esp.Tracer.To = Vector2.new(box.Center.X, box.Bottom.Y)
            esp.Tracer.Color = color
            esp.Tracer.Visible = true
        end

        if items['LookAngle'] then
            local lookDir = hrp.CFrame.LookVector
            local lookEnd = hrp.Position + lookDir * 5
            local lookScreen, lookOnScreen = worldToScreen(lookEnd)

            if lookOnScreen then
                esp.LookAngleOutline.From = Vector2.new(box.Center.X, box.Center.Y)
                esp.LookAngleOutline.To = lookScreen
                esp.LookAngleOutline.Visible = true

                esp.LookAngle.From = Vector2.new(box.Center.X, box.Center.Y)
                esp.LookAngle.To = lookScreen
                esp.LookAngle.Color = color
                esp.LookAngle.Visible = true
            else
                esp.LookAngle.Visible = false
                esp.LookAngleOutline.Visible = false
            end
        end

        if items['Tool'] then
            local tool = char:FindFirstChildOfClass('Tool')
            if tool then
                esp.Tool.Text = tool.Name
                esp.Tool.Position = Vector2.new(box.Center.X + box.Width / 2 + 4, box.Center.Y)
                esp.Tool.Color = color
                esp.Tool.Visible = true
            else
                esp.Tool.Visible = false
            end
        end
    else
        for _, line in ipairs(esp.Box) do line.Visible = false end
        for _, line in ipairs(esp.BoxOutline) do line.Visible = false end
    end

    if items['Skeleton'] then
        local r15 = char:FindFirstChild('UpperTorso') ~= nil

        local function jointWorldPos(name)
            local part
            for _, child in ipairs(char:GetDescendants()) do
                if child:IsA('Motor6D') and child.Name == name then
                    part = child
                    break
                end
            end
            if not part then return nil end
            local p0 = part.Part0
            if not p0 then return nil end
            return p0.CFrame * part.C0
        end

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
            local neck = getScreen(jointWorldPos('Neck'))
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

Toggles.ESPToggle:OnChanged(function()
    if not Toggles.ESPToggle.Value then
        for player, _ in pairs(espObjects) do
            hideAll(player)
        end
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESPObjects(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        createESPObjects(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESPObjects(player)
end)

RunService.RenderStepped:Connect(function()
    if not Toggles.ESPToggle.Value then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not espObjects[player] then
                createESPObjects(player)
            end
            pcall(function()
                updateESP(player)
            end)
        end
    end
end)

Options.ESPThickness:OnChanged(function()
    local thickness = Options.ESPThickness.Value
    for player, esp in pairs(espObjects) do
        for _, line in ipairs(esp.Box) do line.Thickness = thickness end
        esp.Tracer.Thickness = thickness
        esp.LookAngle.Thickness = thickness
        for _, line in pairs(esp.Skeleton) do line.Thickness = thickness end
    end
end)

Options.ESPTextSize:OnChanged(function()
    local textSize = Options.ESPTextSize.Value
    for player, esp in pairs(espObjects) do
        esp.Name.Size = textSize
        esp.HealthText.Size = textSize - 2
        esp.Distance.Size = textSize - 2
        esp.Tool.Size = textSize - 2
    end
end)

Options.ESPFont:OnChanged(function()
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
    local font = fontMap[Options.ESPFont.Value] or 2
    for player, esp in pairs(espObjects) do
        esp.Name.Font = font
        esp.HealthText.Font = font
        esp.Distance.Font = font
        esp.Tool.Font = font
    end
end)

Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

RunService.RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    Library:SetWatermark(('Swift Hub | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ))
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)

Library:OnUnload(function()
    cleanupHitboxes()
    for func, original in pairs(getgenv().__HITBOX__.hooks) do
        hookfunction(func, original)
    end
    getgenv().__HITBOX__ = nil
    gcinfo()
end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'RightShift',
    NoUI = false,
    Text = 'Menu keybind'
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('SwiftHub')
SaveManager:SetFolder('SwiftHub/specific-game')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

Library:OnUnload(function()
    print('Unloaded!')
    Library.Unloaded = true
end)