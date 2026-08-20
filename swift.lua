local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local Players = cloneref(game:GetService("Players"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local GITHUB_RAW = "https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main"
local GITHUB_API = "https://api.github.com/repos/coderofthenextgen/Swift-Hub/contents/places"

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