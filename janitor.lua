--!nocheck
-- Janitor
-- Original by Validark
-- Modifications by pobammer
-- roblox-ts support by OverHash and Validark

local RunService = cloneref(game:GetService('RunService'))
cache.invalidate(RunService)
local Heartbeat = RunService.Heartbeat

local Janitors = setmetatable({}, {__mode = "k"})
local Janitor = {__index = {CurrentlyCleaning = true}}

local newproxy = newproxy or function(hasMeta)
	if hasMeta then
		local t = {}
		local mt = {}
		setmetatable(t, mt)
		return t
	end
	return {}
end

local LinkToInstanceIndex = newproxy(true)
getmetatable(LinkToInstanceIndex).__tostring = function()
	return "LinkToInstanceIndex"
end

local function Wait(Seconds)
	local TimeRemaining = Seconds
	while TimeRemaining > 0 do
		TimeRemaining -= Heartbeat:Wait()
	end
end

local function FastSpawn(Function, a, b, c, d)
	local BindableEvent = Instance.new("BindableEvent")

	BindableEvent.Event:Connect(function()
		Function(a, b, c, d)
	end)

	BindableEvent:Fire()
	BindableEvent:Destroy()
end

local TypeDefaults = {
	["function"] = true;
	["RBXScriptConnection"] = "Disconnect";
	["RBXScriptSignal"] = "Disconnect";
	["Instance"] = "Destroy";
}

function Janitor.new()
	return setmetatable({CurrentlyCleaning = false}, Janitor)
end

function Janitor.__index:Add(Object, MethodName, Index)
	if Index then
		self:Remove(Index)

		local This = Janitors[self]

		if not This then
			This = {}
			Janitors[self] = This
		end

		This[Index] = Object
	end

	self[Object] = MethodName or TypeDefaults[typeof(Object)] or "Destroy"
	return Object
end

function Janitor.__index:Remove(Index)
	local This = Janitors[self]

	if This then
		local Object = This[Index]

		if Object then
			local MethodName = self[Object]

			if MethodName then
				if MethodName == true then
					Object()
				else
					Object[MethodName](Object)
				end
				self[Object] = nil
			end

			This[Index] = nil
		end
	end
end

function Janitor.__index:Cleanup()
	if not self.CurrentlyCleaning then
		self.CurrentlyCleaning = true

		for Object, MethodName in next, self do
			if MethodName == true then
				Object()
			else
				Object[MethodName](Object)
			end
			self[Object] = nil
		end

		local This = Janitors[self]

		if This then
			for Index in next, This do
				This[Index] = nil
			end
			Janitors[self] = nil
		end

		self.CurrentlyCleaning = false
	end
end

function Janitor.__index:Destroy()
	self:Cleanup()
	setmetatable(self, nil)
end

function Janitor.__index:LinkToInstance(Instance, Index)
	self:Add(Instance, "Destroy", Index or LinkToInstanceIndex)

	if Index ~= LinkToInstanceIndex then
		local Connection = Instance.Destroying:Connect(function()
			if self then
				self:Cleanup()
			end
		end)

		self:Add(Connection)
	else
		local Connection = Instance.Destroying:Connect(function()
			if self then
				self:Remove(LinkToInstanceIndex)
				self:Cleanup()
			end
		end)

		self:Add(Connection)
	end
end

function Janitor.__index:Call(F, A, B, C, D)
	local Object = self:Add(A, B, C, D)
	return FastSpawn(function()
		local Success, Result = pcall(F, A, B, C, D)
		if not Success then
			warn(string.format("Janitor:Call error: %s", tostring(Result)))
		end
		self:Remove(Object)
	end)
end

Janitor.__call = Janitor.__index.Add

return Janitor