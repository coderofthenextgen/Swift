local Fluent = loadstring(game:HttpGet("https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentPro"))()

local Window = Fluent:CreateWindow({
    Title = "Swift Hub",
    SubTitle = "Murder vs Sheriffs",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 360),
    Acrylic = true,
    Theme = "GalaxyPurple",
    MinimizeKey = Enum.KeyCode.RightShift,
    Search = false,
})

Window:Tab({ Title = "Main", Icon = "solar/home-bold" })
