local loadstring = loadstring or load

local function LoadSwiftHub()
    local Repo = 'https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/refs/heads/main/'
    
    local Success, Result = pcall(function()
        return game:HttpGet(Repo .. 'universal.lua', true)
    end)
    
    if Success and Result then
        local Func = loadstring(Result)
        if Func then
            Func()
            print('Swift Hub loaded successfully!')
        else
            error('Failed to compile Swift Hub script')
        end
    else
        error('Failed to load Swift Hub from repository: ' .. tostring(Result))
    end
end

local LoadSuccess, LoadError = pcall(LoadSwiftHub)

if not LoadSuccess then
    warn('Error loading Swift Hub: ' .. tostring(LoadError))
    local FallbackSuccess, FallbackResult = pcall(function()
        return game:HttpGet('https://raw.githubusercontent.com/coderofthenextgen/Swift-Hub/main/universal.lua', true)
    end)
    
    if FallbackSuccess and FallbackResult then
        local Func = loadstring(FallbackResult)
        if Func then
            Func()
            print('Swift Hub loaded via fallback!')
        end
    else
        error('Failed to load Swift Hub via fallback: ' .. tostring(FallbackResult))
    end
end