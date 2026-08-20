local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options

local Players = cloneref(game:GetService("Players"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local GameId = game.GameId

local KEY_API = "https://scripting.lollipopsyndrome.workers.dev/"
local KEY_EXPIRY_HOURS = 24
local KEY_FILE = "swift_key.json"

local vapeScript = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua", true))()
end

local GAMES = {
    {
        Name = "Rivals",
        PlaceIds = { 17625359962, 16583760599 },
        UniverseIds = { 6035872082 },
        Scripts = {
            function()
                loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/8a30cd5907985a2b8d68c8010312f185.lua"))()
            end,
        },
    },
    {
        Name = "MM2",
        PlaceIds = { 142823291 },
        UniverseIds = { 66654135 },
        Scripts = {
            function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/William2smod4u/Bunny-ware-script/refs/heads/main/Bunnyware"))()
            end,
        },
    },
    {
        Name = "BedWars",
        PlaceIds = { 6872265039 },
        UniverseIds = { 2619619496 },
        Scripts = {
            function()
                loadstring(game:HttpGet("https://api.catvape.dev/script?key=zf32415VmT8vEoHMijplLlzsiBtq9UYDcqF0V3VV529tqe1D"))({
                    Closet = false,
                })
            end,
        },
    },
    {
        Name = "Valley Prison",
        PlaceIds = { 15784744207 },
        UniverseIds = { 5456952508 },
        Scripts = {
            function()
                loadstring(game:HttpGet("https://api.lasion.world/loader"))()
            end,
        },
    },
    {
        Name = "SCP: Roleplay",
        PlaceIds = { 5041144419 },
        UniverseIds = { 1742264997 },
        Scripts = {
            function()
                loadstring(game:HttpGet("https://rawscripts.net/raw/SCP:-Roleplay-Highlights-any-Person-Thats-Equipping-a-tool-thats-a-weapon-71132"))()
            end,
            function()
                loadstring(game:HttpGet("https://rawscripts.net/raw/SCP:-Roleplay-AutoReload-And-its-useless-71136"))()
            end,
            function()
                getgenv().sneeky_silent_aim = true
                getgenv().sneeky_fov_size = 300
                loadstring(game:HttpGet("https://sneekysscripts.uk/Scripts/SCP_Roleplay/main.luau"))()
            end,
        },
    },
    {
        Name = "Block Tales",
        PlaceIds = { 16483433878 },
        UniverseIds = { 5678284602 },
        Scripts = { vapeScript },
    },
    {
        Name = "Frontlines",
        PlaceIds = { 5938036553 },
        UniverseIds = { 2132866904 },
        Scripts = { vapeScript },
    },
    {
        Name = "Skywars Voxel",
        PlaceIds = { 8542259458 },
        UniverseIds = { 3258873704 },
        Scripts = { vapeScript },
    },
    {
        Name = "Prison Life",
        PlaceIds = { 155615604 },
        UniverseIds = { 73885730 },
        Scripts = { vapeScript },
    },
    {
        Name = "1.8 Arena",
        PlaceIds = { 77790193039862 },
        UniverseIds = { 9984669476 },
        Scripts = { vapeScript },
    },
    {
        Name = "Blockwars",
        PlaceIds = { 12998806177 },
        UniverseIds = { 4544243950 },
        Scripts = { vapeScript },
    },
    {
        Name = "Jailbreak",
        PlaceIds = { 606849621 },
        UniverseIds = { 245662005 },
        Scripts = { vapeScript },
    },
    {
        Name = "Flee the Facility",
        PlaceIds = { 893973440 },
        UniverseIds = { 372226183 },
        Scripts = { vapeScript },
    },
    {
        Name = "Jujutsu Shenanigans",
        PlaceIds = { 9391468976 },
        UniverseIds = { 3508322461 },
        Scripts = {
            function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/NeziaReal/jjs/refs/heads/main/main.lua"))()
            end,
        },
    },
    {
        Name = "Da Hood",
        PlaceIds = { 2788229376 },
        UniverseIds = { 1008451066 },
        Scripts = {
            function()
                loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/606b846e88998801018fae498b9b8a3c.lua"))()
            end,
        },
    },
}

local function checkKey(key)
    local success, response = pcall(function()
        return game:HttpPost(KEY_API, HttpService:JSONEncode({ key = key }), "application/json")
    end)
    if success and response then
        local parseOk, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        if parseOk and type(data) == "table" then
            return data.valid == true or data.status == "valid"
        end
    end
    return false
end

local function saveKeyData(key, expiry)
    writefile(KEY_FILE, HttpService:JSONEncode({ key = key, expiry = expiry }))
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

local savedKey, savedExpiry = loadKeyData()
local keyValid = false

if savedKey and savedExpiry and os.time() < savedExpiry then
    keyValid = true
end

if not keyValid then
    local KeyWindow = Library:CreateWindow({
        Title = "swift key",
        Footer = "enter your key",
        NotifySide = "Right",
        ShowCustomCursor = true,
        AlwaysOnTop = true,
        Center = true,
        Size = UDim2.new(0, 420, 0, 220),
    })

    local KeyTab = KeyWindow:AddTab("Key", "key")
    local KeyGroup = KeyTab:AddLeftGroupbox("Enter Key", "key")

    KeyGroup:AddLabel("Enter your key below:")

    KeyGroup:AddInput("KeyInput", {
        Default = "",
        Numeric = false,
        Finished = false,
        ClearTextOnFocus = true,
        Text = "Key",
        Placeholder = "Paste key here...",

        Callback = function() end,
    })

    local keySubmitted = false
    local submittedKey = ""

    KeyGroup:AddButton({
        Text = "Submit",
        Func = function()
            submittedKey = Options.KeyInput.Value
            if submittedKey and #submittedKey > 0 then
                keySubmitted = true
            end
        end,
    })

    repeat task.wait(0.1) until keySubmitted or Library.Unloaded

    if Library.Unloaded then return end

    local valid = checkKey(submittedKey)
    if valid then
        saveKeyData(submittedKey, os.time() + (KEY_EXPIRY_HOURS * 60 * 60))
        keyValid = true
        KeyWindow:Toggle()
        task.wait(0.2)
    else
        Library:Notify({
            Title = "swift",
            Description = "Invalid key. Restart and try again.",
            Icon = "x-circle",
            Time = 5,
        })
        task.wait(2)
        Library:Unload()
        return
    end
end

local Loading = Library:CreateLoading({
    Title = "swift",
    TotalSteps = 100,
    WindowWidth = 420,
    WindowHeight = 200,
    LoadingIconTweenTime = 0,
})

Loading:SetMessage("Loading swift...")
Loading:SetDescription("Please wait")

for i = 1, 100 do
    Loading:SetCurrentStep(i)
    Loading:SetDescription(i .. "%")
    task.wait(math.random(1, 3) / 100)
end

Loading:SetMessage("Complete")
Loading:SetDescription("Starting...")
task.wait(0.3)
Loading:Continue()

local function findGame()
    for _, g in GAMES do
        if table.find(g.PlaceIds, PlaceId) or table.find(g.UniverseIds, GameId) then
            return g
        end
    end
end

local function getProfile(universeId)
    local success, response = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. universeId, true)
    end)
    if not success or not response then return nil end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    if ok and data and data.data and data.data[1] then
        return data.data[1]
    end
    return nil
end

local function searchScripts(gameName)
    local encoded = HttpService:UrlEncode(gameName)
    local success, response = pcall(function()
        return game:HttpGet("https://scriptblox.com/api/scripts?q=" .. encoded .. "&mode=free&sort=mostliked&limit=5", true)
    end)
    if not success or not response then return false end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    if not ok or not data or not data.scripts then return false end
    for _, s in data.scripts do
        if type(s) == "table" and s.script and (s.key or "") == "" and (s.likes or 0) >= 25 then
            return s
        end
    end
    return nil
end

local Window = Library:CreateWindow({
    Title = "swift",
    Footer = "script hub",
    NotifySide = "Right",
    ShowCustomCursor = true,
    AlwaysOnTop = true,
    Center = true,
    Size = UDim2.new(0, 620, 0, 560),
})

local Tab = Window:AddTab("Main", "zap")
local Group = Tab:AddLeftGroupbox("Game", "gamepad-2")

local gameInfo = findGame()

if gameInfo then
    local executing = false
    local executeButton
    executeButton = Group:AddButton({
        Text = "EXECUTE",
        Func = function()
            if executing then return end
            executing = true
            pcall(function()
                if executeButton and executeButton.SetDisabled then
                    executeButton:SetDisabled(true)
                    executeButton:SetText("Executing...")
                end
            end)
            task.spawn(function()
                for _, scriptFunc in gameInfo.Scripts do
                    local ok, err = pcall(scriptFunc)
                    if not ok then
                        Library:Notify({
                            Title = "swift",
                            Description = "Script error: " .. tostring(err),
                            Icon = "x-circle",
                            Time = 5,
                        })
                    end
                end
                Library:Notify({
                    Title = "swift",
                    Description = gameInfo.Name .. " scripts executed!",
                    Time = 3,
                })
                task.wait(1)
                pcall(function()
                    Window:Toggle()
                end)
            end)
        end,
    })

    Group:AddLabel("Game: " .. gameInfo.Name, true)
    Group:AddLabel("Place ID: " .. PlaceId, true)
    Group:AddLabel("Game ID: " .. GameId, true)

    Group:AddDivider()

    local profileLabel = Group:AddLabel("Loading profile...", true)

    task.spawn(function()
        local profile = getProfile(gameInfo.UniverseIds[1])
        if profile then
            local creatorName = profile.creator and profile.creator.name or "Unknown"
            local desc = profile.description or "No description"
            if #desc > 180 then
                desc = desc:sub(1, 180) .. "..."
            end
            profileLabel:SetText(
                "Creator: " .. creatorName
                .. "\nActive players: " .. tostring(profile.playing or 0)
                .. "\n\n" .. desc
            )
        else
            profileLabel:SetText("Could not fetch profile")
        end
    end)
else
    Group:AddLabel("Your game isn't supported", true)
    Group:AddLabel("Place ID: " .. PlaceId, true)
    Group:AddLabel("Game ID: " .. GameId, true)

    Group:AddDivider()

    local searchLabel = Group:AddLabel("Searching scriptblox.com...", true)

    task.spawn(function()
        local profile = getProfile(GameId)
        local gameName = profile and profile.name or nil
        if not gameName then
            searchLabel:SetText("Could not search: failed to get game name")
            return
        end
        local found = searchScripts(gameName)
        if found == false then
            searchLabel:SetText("Script search unavailable right now")
        elseif found then
            searchLabel:SetText(
                "Your game isn't supported, but we found a script for it:\n"
                .. tostring(found.title)
                .. "\n(" .. tostring(found.likes or 0) .. " likes, keyless)"
            )
            local execButton
            execButton = Group:AddButton({
                Text = "EXECUTE FOUND SCRIPT",
                Func = function()
                    if found.executing then return end
                    found.executing = true
                    pcall(function()
                        if execButton and execButton.SetDisabled then
                            execButton:SetDisabled(true)
                            execButton:SetText("Executing...")
                        end
                    end)
                    task.spawn(function()
                        local ok, err = pcall(function()
                            loadstring(found.script)()
                        end)
                        if not ok then
                            Library:Notify({
                                Title = "swift",
                                Description = "Script error: " .. tostring(err),
                                Icon = "x-circle",
                                Time = 5,
                            })
                        else
                            Library:Notify({
                                Title = "swift",
                                Description = "Script executed!",
                                Time = 3,
                            })
                        end
                        task.wait(1)
                        pcall(function()
                            Window:Toggle()
                        end)
                    end)
                end,
            })
        else
            searchLabel:SetText("No supported script found for this game")
        end
    end)
end

Library:Notify({
    Title = "swift",
    Description = "swift hub loaded!",
    Time = 4,
})