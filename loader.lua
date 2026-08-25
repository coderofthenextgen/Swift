local Url = "https://raw.githubusercontent.com/coderofthenextgen/Swift/main/swift.lua"
local Success, Result = pcall(function()
    return game:HttpGet(Url)
end)
if not Success or type(Result) ~= "string" or Result == "" then
    warn("[Swift Loader] HttpGet failed: " .. tostring(Result))
    return
end
local Loader = loadstring or load
if not Loader then
    warn("[Swift Loader] no loadstring/load available")
    return
end
local Fn, LoadErr = Loader(Result)
if not Fn then
    warn("[Swift Loader] loadstring failed: " .. tostring(LoadErr))
    return
end
local Ok, ExecErr = pcall(Fn)
if not Ok then
    warn("[Swift Loader] execution failed: " .. tostring(ExecErr))
end
