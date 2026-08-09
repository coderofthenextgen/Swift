local Fluent = loadstring(game:HttpGet("https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentPro"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function waitForInventoryUtil()
    local ok, InventoryUtil = pcall(function()
        local RT = require(ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
        return RT.import(script, ReplicatedStorage, "TS", "inventory", "inventory-util").InventoryUtil
    end)
    return ok and InventoryUtil or nil
end

local function getHandItem()
    local char = LocalPlayer.Character
    if not char then return nil end
    local handInv = char:FindFirstChild("HandInvItem")
    if handInv and handInv.Value then
        return handInv.Value
    end
    return nil
end

local function getInventory()
    local InventoryUtil = waitForInventoryUtil()
    if not InventoryUtil then return {hand = nil, items = {}, armor = {}, backpack = nil} end
    local ok, inv = pcall(function() return InventoryUtil.getInventory(LocalPlayer) end)
    return ok and inv or {hand = nil, items = {}, armor = {}, backpack = nil}
end

local function getHeldItemName()
    local item = getHandItem()
    return item and item.Name or "None"
end

local Window = Fluent:CreateWindow({
    Title = "Swift Hub | Bedwars",
    SubTitle = LocalPlayer.Name .. " | " .. LocalPlayer.UserId,
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 360),
    Acrylic = true,
    Theme = "GalaxyPurple",
    MinimizeKey = Enum.KeyCode.RightShift,
    Search = true,
    User = {
        Name = LocalPlayer.DisplayName,
        UserId = LocalPlayer.UserId,
    },
})

local MainTab = Window:AddTab({ Title = "Main", Icon = "solar/home-bold" })

MainTab:AddParagraph({ Title = "Profile", Content = "Player: " .. LocalPlayer.DisplayName .. "\nID: " .. LocalPlayer.UserId .. "\nHeld: " .. getHeldItemName() })

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local held = getHeldItemName()
            local inv = getInventory()
            local itemCount = #inv.items
            local armorCount = 0
            for _, v in inv.armor do if v ~= "empty" then armorCount = armorCount + 1 end end
            MainTab:AddParagraph({ Title = "Profile", Content = "Player: " .. LocalPlayer.DisplayName .. "\nID: " .. LocalPlayer.UserId .. "\nHeld: " .. held .. "\nItems: " .. itemCount .. "\nArmor: " .. armorCount })
        end)
    end
end)
