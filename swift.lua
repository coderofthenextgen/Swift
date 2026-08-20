local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local Players = cloneref(game:GetService("Players"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local GITHUB_RAW = "https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main"

local Loading = Library:CreateLoading({
    Title = "swift",
    TotalSteps = 100,
    WindowWidth = 400,
    WindowHeight = 220,
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
    Size = UDim2.new(0, 420, 0, 280),
})

local Tab = Window:AddTab("Main", "zap")
local Group = Tab:AddLeftGroupbox("Status", "info")

local statusLabel = Group:AddLabel({
    Text = "Loading game...",
    DoesWrap = true,
})

Group:AddDivider()

local function checkPlaceFile()
    local success, result = pcall(function()
        return game:HttpGet(GITHUB_RAW .. "/places/" .. PlaceId .. ".lua", true)
    end)
    return success and result and #result > 0
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
    local found = checkPlaceFile()
    if found then
        loadPlaceScript()
    else
        statusLabel:SetText("Game script not found\nPlace ID: " .. PlaceId)
        Window:SetFooter("not found")
    end
end)