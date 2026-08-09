local placeId = game.PlaceId
local repo = 'https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/'
local v = '?v=' .. tostring(os.time())

local ok, res = pcall(function()
    return game:HttpGet(repo .. 'places/' .. placeId .. '.lua' .. v)
end)

if ok and res and not res:find('404') then
    loadstring(res)()
else
    loadstring(game:HttpGet(repo .. 'universal.lua' .. v))()
end
