local ThemeManager = {}
ThemeManager.Library = nil
ThemeManager.Folder = "SwiftUI"
ThemeManager.FileName = "SwiftUI/theme.json"
ThemeManager.BuiltInThemes = {
    SwiftDark = {
        Background = Color3.fromRGB(13, 13, 15),
        Main = Color3.fromRGB(20, 20, 22),
        Sidebar = Color3.fromRGB(16, 16, 18),
        Element = Color3.fromRGB(28, 28, 31),
        Outline = Color3.fromRGB(42, 42, 46),
        Accent = Color3.fromRGB(124, 92, 255),
        Font = Color3.fromRGB(240, 240, 240),
    },
    Midnight = {
        Background = Color3.fromRGB(8, 10, 14),
        Main = Color3.fromRGB(14, 16, 20),
        Sidebar = Color3.fromRGB(10, 12, 16),
        Element = Color3.fromRGB(24, 26, 32),
        Outline = Color3.fromRGB(36, 38, 46),
        Accent = Color3.fromRGB(88, 101, 242),
        Font = Color3.fromRGB(235, 235, 245),
    },
    Crimson = {
        Background = Color3.fromRGB(18, 10, 12),
        Main = Color3.fromRGB(26, 16, 18),
        Sidebar = Color3.fromRGB(20, 12, 14),
        Element = Color3.fromRGB(38, 24, 28),
        Outline = Color3.fromRGB(52, 32, 38),
        Accent = Color3.fromRGB(231, 76, 60),
        Font = Color3.fromRGB(245, 235, 235),
    },
    Forest = {
        Background = Color3.fromRGB(10, 16, 12),
        Main = Color3.fromRGB(16, 22, 18),
        Sidebar = Color3.fromRGB(12, 18, 14),
        Element = Color3.fromRGB(26, 34, 28),
        Outline = Color3.fromRGB(38, 48, 40),
        Accent = Color3.fromRGB(46, 204, 113),
        Font = Color3.fromRGB(235, 245, 235),
    },
    Ocean = {
        Background = Color3.fromRGB(10, 14, 20),
        Main = Color3.fromRGB(16, 20, 28),
        Sidebar = Color3.fromRGB(12, 16, 24),
        Element = Color3.fromRGB(24, 30, 42),
        Outline = Color3.fromRGB(36, 44, 58),
        Accent = Color3.fromRGB(52, 152, 219),
        Font = Color3.fromRGB(235, 240, 250),
    },
}

ThemeManager.AccentColors = {
    Swift = Color3.fromRGB(124, 92, 255),
    Blurple = Color3.fromRGB(88, 101, 242),
    Red = Color3.fromRGB(231, 76, 60),
    Orange = Color3.fromRGB(230, 126, 34),
    Yellow = Color3.fromRGB(241, 196, 15),
    Green = Color3.fromRGB(46, 204, 113),
    Cyan = Color3.fromRGB(0, 200, 200),
    Pink = Color3.fromRGB(232, 67, 147),
    White = Color3.fromRGB(240, 240, 240),
}

function ThemeManager:SetLibrary(Library)
    ThemeManager.Library = Library
end

function ThemeManager:SetFolder(Folder)
    ThemeManager.Folder = Folder
    ThemeManager.FileName = Folder .. "/theme.json"
end

function ThemeManager:ApplyTheme(ThemeName)
    if not ThemeManager.Library then
        warn("[ThemeManager] Library not set. Call ThemeManager:SetLibrary(SwiftUI)")
        return
    end
    local Theme = ThemeManager.BuiltInThemes[ThemeName]
    if not Theme then
        warn("[ThemeManager] Unknown theme: " .. tostring(ThemeName))
        return
    end
    for Key, Color in pairs(Theme) do
        ThemeManager.Library.Theme[Key] = Color
    end
    if Theme.Accent then
        ThemeManager.Library.Theme.AccentHover = Color3.fromRGB(
            math.clamp(Theme.Accent.R * 255 + 14, 0, 255),
            math.clamp(Theme.Accent.G * 255 + 14, 0, 255),
            math.clamp(Theme.Accent.B * 255 + 14, 0, 255)
        )
    end
    ThemeManager.Library:Notify({Title = "Theme", Description = "Applied " .. ThemeName, Time = 2})
end

function ThemeManager:SetAccent(Color)
    if not ThemeManager.Library then return end
    ThemeManager.Library.Theme.Accent = Color
    ThemeManager.Library.Theme.AccentHover = Color3.fromRGB(
        math.clamp(Color.R * 255 + 14, 0, 255),
        math.clamp(Color.G * 255 + 14, 0, 255),
        math.clamp(Color.B * 255 + 14, 0, 255)
    )
end

function ThemeManager:SaveTheme()
    if not ThemeManager.Library then return false end
    local Data = {}
    for Key, Color in pairs(ThemeManager.Library.Theme) do
        if typeof(Color) == "Color3" then
            Data[Key] = {R = Color.R, G = Color.G, B = Color.B}
        end
    end
    if writefile and isfolder then
        if not isfolder(ThemeManager.Folder) then pcall(makefolder, ThemeManager.Folder) end
        local HttpService = game:GetService("HttpService")
        local Encoded = HttpService:JSONEncode(Data)
        pcall(writefile, ThemeManager.FileName, Encoded)
        return true
    end
    return false
end

function ThemeManager:LoadTheme()
    if not ThemeManager.Library or not isfile or not readfile then return false end
    if not isfile(ThemeManager.FileName) then return false end
    local Content = readfile(ThemeManager.FileName)
    local HttpService = game:GetService("HttpService")
    local Success, Data = pcall(HttpService.JSONDecode, HttpService, Content)
    if not Success or type(Data) ~= "table" then return false end
    for Key, Value in pairs(Data) do
        if type(Value) == "table" and Value.R then
            ThemeManager.Library.Theme[Key] = Color3.new(Value.R, Value.G, Value.B)
        end
    end
    return true
end

function ThemeManager:BuildThemeSection(Tab)
    local Group = Tab:AddLeftGroupbox("Theme")
    local ThemeNames = {}
    for Name in pairs(ThemeManager.BuiltInThemes) do table.insert(ThemeNames, Name) end
    table.sort(ThemeNames)

    Group:AddDropdown("ThemeName", {
        Text = "Theme",
        Values = ThemeNames,
        Default = "SwiftDark",
        Callback = function(Value)
            ThemeManager:ApplyTheme(Value)
        end,
    })

    local AccentNames = {}
    for Name in pairs(ThemeManager.AccentColors) do table.insert(AccentNames, Name) end
    table.sort(AccentNames)

    Group:AddDropdown("AccentName", {
        Text = "Accent",
        Values = AccentNames,
        Default = "Swift",
        Callback = function(Value)
            local Color = ThemeManager.AccentColors[Value]
            if Color then ThemeManager:SetAccent(Color) end
        end,
    })

    Group:AddColorPicker("CustomAccent", {
        Text = "Custom Accent",
        Default = ThemeManager.Library and ThemeManager.Library.Theme.Accent or Color3.fromRGB(124, 92, 255),
        Callback = function(Value)
            ThemeManager:SetAccent(Value)
        end,
    })

    Group:AddDivider()
    Group:AddButton({
        Text = "Save Theme",
        Func = function()
            ThemeManager:SaveTheme()
            ThemeManager.Library:Notify({Title = "Theme", Description = "Theme saved", Time = 2})
        end,
    })

    return Group
end

return ThemeManager
