repeat task.wait() until game:IsLoaded()
if not isfile("newvape/profiles/commit.txt") then
    pcall(function()
        if not isfolder("newvape") then makefolder("newvape") end
        if not isfolder("newvape/profiles") then makefolder("newvape/profiles") end
        writefile("newvape/profiles/commit.txt", "main")
    end)
end
if not isfile("newvape/profiles/gui.txt") then
    pcall(function()
        writefile("newvape/profiles/gui.txt", "new")
    end)
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Vape = loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/refs/heads/main/guis/new.lua"))()
local Settings = {
    Enabled = true,
    Range = 18,
    HitChance = 100,
    MaxTargets = 1,
    AttackSpeed = 0.1,
    WallCheck = false,
    ShowTargets = true,
    UseMouse = false
}
local function GetSword()
    local Inventory = ReplicatedStorage:FindFirstChild("Inventories")
    if not Inventory then return nil end
    local PlayerInv = Inventory:FindFirstChild(LocalPlayer.Name)
    if not PlayerInv then return nil end
    for _, Item in ipairs(PlayerInv:GetChildren()) do
        if string.match(Item.Name, "_sword$") then
            return Item
        end
    end
    return nil
end
local function GetSwordHit()
    local Path = ReplicatedStorage
    local Parts = {"rbxts_include", "node_modules", "@rbxts", "net", "out", "_NetManaged", "SwordHit"}
    for _, Part in ipairs(Parts) do
        Path = Path:FindFirstChild(Part)
        if not Path then return nil end
    end
    return Path
end
local SwordHit = GetSwordHit()
local function GetTargets()
    local Character = LocalPlayer.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return {} end
    local Targets = {}
    local RootPos = RootPart.Position
    local LookVector = RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local TargetChar = Player.Character
            local TargetRoot = TargetChar and TargetChar:FindFirstChild("HumanoidRootPart")
            if TargetRoot then
                local Distance = (RootPos - TargetRoot.Position).Magnitude
                if Distance <= Settings.Range then
                    if Settings.WallCheck then
                        local Params = RaycastParams.new()
                        Params.FilterDescendantsInstances = {LocalPlayer.Character, TargetChar}
                        Params.FilterType = Enum.RaycastFilterType.Exclude
                        local Ray = Workspace:Raycast(RootPos, (TargetRoot.Position - RootPos), Params)
                        if Ray then continue end
                    end
                    local Direction = (TargetRoot.Position - RootPos) * Vector3.new(1, 0, 1)
                    local Angle = math.acos(math.clamp(LookVector:Dot(Direction.Unit), -1, 1))
                    if math.deg(Angle) <= 180 then
                        table.insert(Targets, {
                            Player = Player,
                            Character = TargetChar,
                            RootPart = TargetRoot,
                            Distance = Distance,
                            Position = TargetRoot.Position
                        })
                    end
                end
            end
        end
    end
    table.sort(Targets, function(A, B) return A.Distance < B.Distance end)
    return Targets
end
local function Attack(Target, Sword)
    if not Sword or not Target then return end
    local Character = LocalPlayer.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return end
    if math.random(1, 100) > Settings.HitChance then return end
    local TargetPos = Target.Position
    local RootPos = RootPart.Position
    local CameraPos = Camera.CFrame.Position
    if not SwordHit then SwordHit = GetSwordHit() end
    if not SwordHit then return end
    SwordHit:FireServer({
        chargedAttack = {chargeRatio = 0},
        entityInstance = Target.Character,
        validate = {
            targetPosition = {value = TargetPos},
            raycast = {
                cameraPosition = {value = CameraPos},
                cursorDirection = {value = (TargetPos - CameraPos).Unit}
            },
            selfPosition = {value = RootPos}
        },
        weapon = Sword
    })
end
Vape:LoadGUI()
pcall(function() Vape.GUIBind:SetValue({"RightShift"}) end)
local CombatCategory = Vape.Categories.Combat
local KillAura = CombatCategory:CreateModule({
    Name = "KillAura",
    Function = function(Callback)
        Settings.Enabled = Callback
    end,
    Tooltip = "SwiftVape KillAura"
})
KillAura:CreateToggle({
    Name = "Enabled",
    Function = function(Callback) Settings.Enabled = Callback end,
    Default = true
})
KillAura:CreateSlider({
    Name = "Range",
    Function = function(Value) Settings.Range = Value end,
    Min = 4,
    Max = 30,
    Default = 18
})
KillAura:CreateSlider({
    Name = "HitChance",
    Function = function(Value) Settings.HitChance = Value end,
    Min = 1,
    Max = 100,
    Default = 100
})
KillAura:CreateSlider({
    Name = "MaxTargets",
    Function = function(Value) Settings.MaxTargets = Value end,
    Min = 1,
    Max = 5,
    Default = 1
})
KillAura:CreateSlider({
    Name = "AttackSpeed",
    Function = function(Value) Settings.AttackSpeed = Value end,
    Min = 0,
    Max = 1,
    Default = 0.1,
    Decimal = 10
})
KillAura:CreateToggle({
    Name = "WallCheck",
    Function = function(Callback) Settings.WallCheck = Callback end,
    Default = false
})
KillAura:CreateToggle({
    Name = "ShowTargets",
    Function = function(Callback) Settings.ShowTargets = Callback end,
    Default = true
})
KillAura:CreateToggle({
    Name = "UseMouse",
    Function = function(Callback) Settings.UseMouse = Callback end,
    Default = false
})
local LastAttack = 0
local TargetBoxes = {}
local function ClearBoxes()
    for _, Box in ipairs(TargetBoxes) do
        Box:Destroy()
    end
    TargetBoxes = {}
end
RunService.Heartbeat:Connect(function()
    if not Settings.Enabled then
        if #TargetBoxes > 0 then ClearBoxes() end
        return
    end
    if Settings.UseMouse then
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            if #TargetBoxes > 0 then ClearBoxes() end
            return
        end
    end
    local Sword = GetSword()
    if not Sword then
        if #TargetBoxes > 0 then ClearBoxes() end
        return
    end
    local Targets = GetTargets()
    if #Targets == 0 then
        if #TargetBoxes > 0 then ClearBoxes() end
        return
    end
    if Settings.ShowTargets then
        ClearBoxes()
        for _, Target in ipairs(Targets) do
            if Target.Distance <= Settings.Range then
                local Box = Instance.new("BoxHandleAdornment")
                Box.Size = Vector3.new(3, 5, 3)
                Box.CFrame = CFrame.new(0, -0.5, 0)
                Box.Color3 = Color3.fromRGB(255, 0, 0)
                Box.Transparency = 0.5
                Box.AlwaysOnTop = true
                Box.ZIndex = 2
                Box.Adornee = Target.RootPart
                Box.Parent = Target.RootPart
                table.insert(TargetBoxes, Box)
            end
        end
    else
        if #TargetBoxes > 0 then ClearBoxes() end
    end
    local CurrentTime = tick()
    if CurrentTime - LastAttack < Settings.AttackSpeed then return end
    local MaxTargets = Settings.MaxTargets
    for Index = 1, math.min(MaxTargets, #Targets) do
        local Target = Targets[Index]
        if Target.Distance <= Settings.Range then
            Attack(Target, Sword)
            LastAttack = CurrentTime
        end
    end
end)
Vape:CreateNotification("SwiftVape", "Loaded RightShift to toggle", 4, "info")
