--[[
    swift - Roblox Script
    Key system + Game support detection
    UI Library: Obsidian
]]

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local Players = cloneref(game:GetService("Players"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local KEY_API = "https://scripting.lollipopsyndrome.workers.dev/"
local KEY_EXPIRY_HOURS = 24
local KEY_FILE = "swift_key.json"

local SupportedGames = {
    [2753915549] = "Blox Fruits",
    [4252370517] = "Fisch",
    [537413528] = "Blox Fruits (Old)",
    [6872265039] = "Update 24",
    [4483381598] = "Block Mayhem",
    [65241] = "Natural Disaster Survival",
    [286090429] = "Arsenal",
    [155615605] = "Counter Blox",
    [115201024] = "Phantom Forces",
}

local function checkKey(key)
    local success, response = pcall(function()
        return game:HttpGet(KEY_API .. "?key=" .. key)
    end)
    if success and response then
        local data = HttpService:JSONDecode(response)
        return data.valid == true or data.status == "valid"
    end
    return false
end

local function saveKeyData(key, expiry)
    local data = {
        key = key,
        expiry = expiry,
    }
    writefile(KEY_FILE, HttpService:JSONEncode(data))
end

local function loadKeyData()
    if isfile(KEY_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(KEY_FILE))
        end)
        if success and data and data.key and data.expiry then
            if os.time() < data.expiry then
                return data.key, data.expiry
            end
        end
    end
    return nil, nil
end

local function isGameSupported(placeId)
    return SupportedGames[placeId] ~= nil, SupportedGames[placeId]
end

local function showInvalidKey(msg)
    Library:Notify({
        Title = "swift",
        Description = msg or "Invalid or expired key.",
        Icon = "x-circle",
        Time = 5,
    })
end

-- Main flow
local function main()
    -- Loading screen
    local Loading = Library:CreateLoading({
        Title = "swift",
        TotalSteps = 3,
    })

    Loading:SetMessage("Initializing...")
    Loading:SetDescription("Setting up swift...")
    task.wait(0.5)

    -- Step 1: Check saved key
    Loading:SetCurrentStep(1)
    Loading:SetDescription("Checking key...")
    task.wait(0.5)

    local savedKey, savedExpiry = loadKeyData()
    local keyValid = false

    if savedKey and savedExpiry and os.time() < savedExpiry then
        keyValid = true
    end

    -- Step 2: Key system
    Loading:SetCurrentStep(2)

    if not keyValid then
        Loading:SetDescription("Waiting for key input...")
        Loading:ShowSidebarPage(true)

        Loading.Sidebar:AddLabel("Enter your key below:")
        Loading.Sidebar:AddInput("KeyInput", {
            Placeholder = "Paste key here...",
            Text = "Key",
            Callback = function() end,
        })

        local keySubmitted = false
        local submittedKey = ""

        Loading.Sidebar:AddButton({
            Text = "Submit Key",
            Func = function()
                submittedKey = Options.KeyInput.Value
                if submittedKey and #submittedKey > 0 then
                    keySubmitted = true
                    Loading:SetDescription("Verifying key...")
                end
            end,
        })

        repeat task.wait(0.1) until keySubmitted or Library.Unloaded

        if Library.Unloaded then return end

        local valid = checkKey(submittedKey)
        if valid then
            local expiry = os.time() + (KEY_EXPIRY_HOURS * 60 * 60)
            saveKeyData(submittedKey, expiry)
            keyValid = true

            Loading:ShowSidebarPage(false)
            Loading:SetDescription("Key verified!")
        else
            Loading:ShowErrorPage(true)
            Loading:SetErrorMessage("Invalid key. Please restart and try again.")
            Loading:SetErrorButtons({
                Retry = {
                    Title = "Close",
                    Variant = "Primary",
                    Callback = function()
                        Loading:Destroy()
                    end,
                },
            })
            return
        end
    else
        Loading:SetDescription("Key already verified!")
    end

    task.wait(0.5)

    -- Step 3: Game support check
    Loading:SetCurrentStep(3)
    Loading:SetDescription("Checking game support...")
    task.wait(0.5)

    local supported, gameName = isGameSupported(PlaceId)

    -- Continue to main menu
    Loading:Continue()

    -- Create main window
    local Window = Library:CreateWindow({
        Title = "swift",
        Footer = gameName or "Game not supported",
        Icon = 95816097006870,
        NotifySide = "Right",
        ShowCustomCursor = true,
        AlwaysOnTop = true,
    })

    local Tab = Window:AddTab("Main", "zap")
    local Group = Tab:AddLeftGroupbox("Info", "info")

    if supported then
        Group:AddLabel({
            Text = "Game: " .. gameName,
            DoesWrap = true,
        })
        Group:AddLabel({
            Text = "Status: Supported",
            DoesWrap = true,
        })
        Group:AddLabel({
            Text = "Place ID: " .. PlaceId,
            DoesWrap = true,
        })
    else
        Group:AddLabel({
            Text = "Game not supported",
            DoesWrap = true,
        })
        Group:AddLabel({
            Text = "Place ID: " .. PlaceId,
            DoesWrap = true,
        })
        Group:AddLabel({
            Text = "This game is not currently supported by swift.",
            DoesWrap = true,
        })
    end

    Group:AddDivider()

    Group:AddButton({
        Text = "Close",
        Func = function()
            Library:Unload()
        end,
    })

    Library:Notify({
        Title = "swift",
        Description = supported and ("Loaded - " .. gameName) or "Loaded - Game not supported",
        Time = 4,
    })
end

main()