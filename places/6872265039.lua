local Fluent = loadstring(game:HttpGet("https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentPro"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local LOBBY_PLACE = 6872265039
local UNIVERSE_ID = 2619619496
local isMatch = game.PlaceId ~= LOBBY_PLACE and game.GameId == UNIVERSE_ID
local isLobby = game.PlaceId == LOBBY_PLACE
local isBedwars = game.GameId == UNIVERSE_ID

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

local function getGameState()
    if not isBedwars then return "Not Bedwars" end
    if isLobby then return "Lobby" end
    if isMatch then return "In Match" end
    return "Unknown"
end

local Window = Fluent:CreateWindow({
    Title = "Swift Hub | Bedwars",
    SubTitle = getGameState() .. " | " .. LocalPlayer.Name,
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
local CombatTab = Window:AddTab({ Title = "Combat", Icon = "solar/target-bold" })
local VisualsTab = Window:AddTab({ Title = "Visuals", Icon = "solar/eye-bold" })
local MiscTab = Window:AddTab({ Title = "Misc", Icon = "solar/settings-bold" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "solar/cog-bold" })

MainTab:AddParagraph({
    Title = "Profile",
    Content = "Player: " .. LocalPlayer.DisplayName
        .. "\nID: " .. LocalPlayer.UserId
        .. "\nState: " .. getGameState()
        .. "\nPlace: " .. game.PlaceId
        .. "\nUniverse: " .. game.GameId
})

if isMatch then
    local heldItem = getHeldItemName()
    MainTab:AddParagraph({ Title = "Loadout", Content = "Held: " .. heldItem })

    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local held = getHeldItemName()
                local inv = getInventory()
                local itemCount = #inv.items
                local armorCount = 0
                for _, v in inv.armor do
                    if v ~= "empty" then armorCount = armorCount + 1 end
                end
                local backpackInfo = inv.backpack and inv.backpack.itemType or "None"
                MainTab:AddParagraph({
                    Title = "Loadout",
                    Content = "Held: " .. held
                        .. "\nBackpack: " .. backpackInfo
                        .. "\nItems: " .. itemCount
                        .. "\nArmor: " .. armorCount
                })
            end)
        end
    end)
end

SettingsTab:AddParagraph({ Title = "Swift Hub", Content = "by coderofthenextgen" })
