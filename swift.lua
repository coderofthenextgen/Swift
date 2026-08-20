local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local Players = cloneref(game:GetService("Players"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local GITHUB_RAW = "https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main"
local GITHUB_API = "https://api.github.com/repos/coderofthenextgen/Swift-Hub/contents/places"
local KEY_API = "https://scripting.lollipopsyndrome.workers.dev/"
local KEY_EXPIRY_HOURS = 24
local KEY_FILE = "swift_key.json"

local function checkKey(key)
    local success, response = pcall(function()
        return game:HttpGet(KEY_API .. "?key=" .. key, true)
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
    local data = { key = key, expiry = expiry }
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
        Size = UDim2.new(0, 320, 0, 160),
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
        local expiry = os.time() + (KEY_EXPIRY_HOURS * 60 * 60)
        saveKeyData(submittedKey, expiry)
        keyValid = true
        KeyWindow:Toggle()
        task.wait(0.3)
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
    WindowWidth = 380,
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

local Window = Library:CreateWindow({
    Title = "swift",
    Footer = "checking games...",
    NotifySide = "Right",
    ShowCustomCursor = true,
    AlwaysOnTop = true,
    Center = true,
    Size = UDim2.new(0, 380, 0, 250),
})

local Tab = Window:AddTab("Main", "zap")
local Group = Tab:AddLeftGroupbox("Status", "info")

local statusLabel = Group:AddLabel({
    Text = "Loading game...",
    DoesWrap = true,
})

Group:AddDivider()

local function isGameScriptAvailable()
    local success, response = pcall(function()
        return game:HttpGet(GITHUB_API, true)
    end)
    if not success or not response then
        return false
    end
    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    if not parseSuccess or type(data) ~= "table" then
        return false
    end
    local targetFile = PlaceId .. ".lua"
    for _, item in data do
        if item.name == targetFile then
            return true
        end
    end
    return false
end

local function loadPlaceScript()
    local success, scriptContent = pcall(function()
        return game:HttpGet(GITHUB_RAW .. "/places/" .. PlaceId .. ".lua", true)
    end)
    if success and scriptContent and #scriptContent > 0 then
        Window:SetFooter("found game!")
        statusLabel:SetText("Found game!\nExecuting script...")
        task.wait(1)
        Window:Toggle()
        loadstring(scriptContent)()
    end
end

task.spawn(function()
    task.wait(1)
    local found = isGameScriptAvailable()
    if found then
        loadPlaceScript()
    else
        statusLabel:SetText("Game script not found\nPlace ID: " .. PlaceId)
        Window:SetFooter("not found")
    end
end)