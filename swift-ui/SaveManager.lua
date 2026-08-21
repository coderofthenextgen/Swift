local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Ignore = {}
SaveManager.Parser = {}
SaveManager.Folder = "SwiftUI"
SaveManager.FileName = "SwiftUI/config.json"
SaveManager.Library = nil

function SaveManager:SetLibrary(Library)
    SaveManager.Library = Library
end

function SaveManager:SetIgnoreIndexes(List)
    for _, Key in ipairs(List) do
        SaveManager.Ignore[Key] = true
    end
end

function SaveManager:SetFolder(Folder)
    SaveManager.Folder = Folder
    SaveManager.FileName = Folder .. "/config.json"
end

function SaveManager:MakeFolder()
    if isfolder and makefolder then
        if not isfolder(SaveManager.Folder) then
            makefolder(SaveManager.Folder)
        end
        local Segments = SaveManager.FileName:split("/")
        local Path = ""
        for i = 1, #Segments - 1 do
            Path = Path .. Segments[i] .. "/"
            if not isfolder(Path:sub(1, -2)) and Path ~= "" then
                pcall(makefolder, Path:sub(1, -2))
            end
        end
    end
end

function SaveManager:Save(Name)
    if not SaveManager.Library then
        warn("[SaveManager] Library not set. Call SaveManager:SetLibrary(SwiftUI)")
        return false
    end
    SaveManager:MakeFolder()

    local FileName = SaveManager.Folder .. "/" .. (Name or "default") .. ".json"
    local Data = {
        Version = 1,
        Timestamp = os.time(),
        Options = {},
    }

    for Id, Option in pairs(SaveManager.Library.Options) do
        if not SaveManager.Ignore[Id] then
            if Option.Type == "ColorPicker" then
            Data.Options[Id] = {
                Type = "ColorPicker",
                Value = {R = Option.Value.R, G = Option.Value.G, B = Option.Value.B},
            }
        elseif Option.Type == "KeyPicker" then
            Data.Options[Id] = {
                Type = "KeyPicker",
                Value = typeof(Option.Value) == "EnumItem" and Option.Value.Name or tostring(Option.Value),
                Mode = Option.Mode,
            }
        else
            Data.Options[Id] = {
                Type = Option.Type,
                Value = Option.Value,
                Values = Option.Values,
            }
            end
        end
    end

    local Success, Encoded = pcall(HttpService.JSONEncode, HttpService, Data)
    if not Success then
        warn("[SaveManager] Encode failed: " .. tostring(Encoded))
        return false
    end

    if writefile then
        local Ok, Err = pcall(writefile, FileName, Encoded)
        if not Ok then
            warn("[SaveManager] Write failed: " .. tostring(Err))
            return false
        end
        if FileName ~= SaveManager.FileName then
            pcall(writefile, SaveManager.FileName, Encoded)
        end
        return true
    else
        warn("[SaveManager] writefile not available (unsupported executor)")
        return false
    end
end

function SaveManager:Load(Name)
    if not SaveManager.Library then
        warn("[SaveManager] Library not set.")
        return false
    end

    local FileName = SaveManager.Folder .. "/" .. (Name or "default") .. ".json"
    local TargetFile = FileName
    if isfile then
        if not isfile(TargetFile) and isfile(SaveManager.FileName) then
            TargetFile = SaveManager.FileName
        end
        if not isfile(TargetFile) then
            return false
        end
    else
        return false
    end

    local Content
    local Ok, Err = pcall(function()
        Content = readfile(TargetFile)
    end)
    if not Ok then
        warn("[SaveManager] Read failed: " .. tostring(Err))
        return false
    end

    local Success, Data = pcall(HttpService.JSONDecode, HttpService, Content)
    if not Success or type(Data) ~= "table" or not Data.Options then
        warn("[SaveManager] Decode failed")
        return false
    end

    for Id, Saved in pairs(Data.Options) do
        local Option = SaveManager.Library.Options[Id]
        if Option and not SaveManager.Ignore[Id] then
            if Saved.Type == "ColorPicker" and Saved.Value then
            local C = Saved.Value
            local Color = Color3.new(C.R, C.G, C.B)
            if Option.SetValue then Option:SetValue(Color) end
        elseif Saved.Type == "KeyPicker" and Saved.Value then
            local KeyCode = Enum.KeyCode[Saved.Value]
            if KeyCode and Option.SetValue then
                Option:SetValue(KeyCode, Saved.Mode)
            end
        else
            if Option.SetValue and Saved.Value ~= nil then
                pcall(function() Option:SetValue(Saved.Value) end)
            end
            end
        end
    end

    return true
end

function SaveManager:LoadAutoload()
    return SaveManager:Load("autoload")
end

function SaveManager:SaveAutoload()
    return SaveManager:Save("autoload")
end

function SaveManager:GetConfigList()
    local List = {}
    if isfolder and listfiles then
        local Ok, Files = pcall(listfiles, SaveManager.Folder)
        if Ok and Files then
            for _, File in ipairs(Files) do
                local Name = File:match("([^/\\]+)%.json$")
                if Name then table.insert(List, Name) end
            end
        end
    end
    return List
end

function SaveManager:DeleteConfig(Name)
    local FileName = SaveManager.Folder .. "/" .. Name .. ".json"
    if isfile and delfile and isfile(FileName) then
        pcall(delfile, FileName)
        return true
    end
    return false
end

function SaveManager:BuildConfigSection(Tab)
    local Group = Tab:AddLeftGroupbox("Configuration")
    Group:AddInput("ConfigName", {
        Text = "Config Name",
        Default = "default",
        Placeholder = "config name...",
    })
    Group:AddButton({
        Text = "Create / Save",
        Func = function()
            local Name = SaveManager.Library.Options.ConfigName and SaveManager.Library.Options.ConfigName.Value or "default"
            SaveManager:Save(Name)
            SaveManager.Library:Notify({Title = "Config", Description = "Saved " .. Name, Time = 2})
        end,
    })
    Group:AddButton({
        Text = "Load",
        Func = function()
            local Name = SaveManager.Library.Options.ConfigName and SaveManager.Library.Options.ConfigName.Value or "default"
            local Ok = SaveManager:Load(Name)
            SaveManager.Library:Notify({
                Title = "Config",
                Description = Ok and ("Loaded " .. Name) or ("Failed to load " .. Name),
                Time = 2,
            })
        end,
    })
    Group:AddDivider()
    Group:AddButton({
        Text = "Save Autoload",
        Func = function()
            SaveManager:SaveAutoload()
            SaveManager.Library:Notify({Title = "Config", Description = "Autoload saved", Time = 2})
        end,
    })
    Group:AddButton({
        Text = "Delete Config",
        Func = function()
            local Name = SaveManager.Library.Options.ConfigName and SaveManager.Library.Options.ConfigName.Value or "default"
            SaveManager:DeleteConfig(Name)
            SaveManager.Library:Notify({Title = "Config", Description = "Deleted " .. Name, Time = 2})
        end,
    })
    return Group
end

return SaveManager
