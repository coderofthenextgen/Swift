local Url = 'https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/universal.lua'

local ok, result = pcall(function()
    return game:HttpGet(Url, true)
end)

if not ok then
    warn('HttpGet failed: ' .. tostring(result))
    return
end

if not result or result == '' then
    warn('HttpGet returned empty response')
    return
end

print('Downloaded ' .. #result .. ' bytes')
print('First 100 chars: ' .. result:sub(1, 100))

local func, err = loadstring(result)

if not func then
    warn('loadstring failed: ' .. tostring(err))
    return
end

func()
print('Swift Hub loaded!')
