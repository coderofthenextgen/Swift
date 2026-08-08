local SwiftUI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Themes = {
	Dark = {
		Name = "Dark",
		Background = Color3.fromRGB(16, 16, 22),
		Surface = Color3.fromRGB(26, 26, 34),
		Surface2 = Color3.fromRGB(36, 36, 46),
		Primary = Color3.fromRGB(124, 92, 240),
		PrimaryHover = Color3.fromRGB(142, 112, 255),
		Text = Color3.fromRGB(238, 238, 246),
		TextDim = Color3.fromRGB(150, 150, 165),
		Border = Color3.fromRGB(48, 48, 60),
		ToggleOn = Color3.fromRGB(124, 92, 240),
		ToggleOff = Color3.fromRGB(60, 60, 72),
		Knob = Color3.fromRGB(255, 255, 255),
		SliderTrack = Color3.fromRGB(50, 50, 62),
		SliderFill = Color3.fromRGB(124, 92, 240),
		Success = Color3.fromRGB(80, 200, 120),
		Danger = Color3.fromRGB(230, 80, 90),
		Placeholder = Color3.fromRGB(120, 120, 135),
		Shadow = Color3.fromRGB(0, 0, 0),
	},
	Light = {
		Name = "Light",
		Background = Color3.fromRGB(244, 244, 248),
		Surface = Color3.fromRGB(255, 255, 255),
		Surface2 = Color3.fromRGB(236, 236, 244),
		Primary = Color3.fromRGB(110, 80, 230),
		PrimaryHover = Color3.fromRGB(124, 92, 240),
		Text = Color3.fromRGB(30, 30, 38),
		TextDim = Color3.fromRGB(110, 110, 124),
		Border = Color3.fromRGB(210, 210, 220),
		ToggleOn = Color3.fromRGB(110, 80, 230),
		ToggleOff = Color3.fromRGB(200, 200, 210),
		Knob = Color3.fromRGB(255, 255, 255),
		SliderTrack = Color3.fromRGB(220, 220, 228),
		SliderFill = Color3.fromRGB(110, 80, 230),
		Success = Color3.fromRGB(70, 180, 110),
		Danger = Color3.fromRGB(220, 70, 80),
		Placeholder = Color3.fromRGB(150, 150, 162),
		Shadow = Color3.fromRGB(60, 60, 80),
	},
}

SwiftUI.Themes = Themes
SwiftUI.CurrentTheme = Themes.Dark
SwiftUI._windows = {}
SwiftUI._memConfigs = {}
SwiftUI.IsTouch = false
SwiftUI.ActiveInput = "Mouse"

local themeRegistry = {}

local function registerThemed(fn)
	table.insert(themeRegistry, fn)
	return fn
end

local function unregisterThemed(fn)
	for i, v in ipairs(themeRegistry) do
		if v == fn then
			table.remove(themeRegistry, i)
			break
		end
	end
end

function SwiftUI.SetTheme(theme)
	if type(theme) == "string" then
		theme = Themes[theme] or Themes.Dark
	end
	SwiftUI.CurrentTheme = theme
	for _, fn in ipairs(themeRegistry) do
		pcall(fn)
	end
end

function SwiftUI.GetTheme()
	return SwiftUI.CurrentTheme
end

local function Create(className, props, parentOrChildren)
	local obj = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				obj[k] = v
			end
		end
		if props.Parent then
			obj.Parent = props.Parent
		end
	end
	if parentOrChildren then
		if typeof(parentOrChildren) == "Instance" then
			obj.Parent = parentOrChildren
		elseif type(parentOrChildren) == "table" then
			for _, c in ipairs(parentOrChildren) do
				c.Parent = obj
			end
		end
	end
	return obj
end

local function getGuiParent()
	if gethui then
		return gethui()
	end
	local ok, cg = pcall(function()
		return CoreGui
	end)
	if ok and cg then
		return cg
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function isPrimary(inputType)
	return inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch
end

local function beginDrag(inputObject, onMove, onEnd)
	local dragType = inputObject.UserInputType
	local moveType = (dragType == Enum.UserInputType.Touch) and Enum.UserInputType.Touch or Enum.UserInputType.MouseMovement
	local endType = (dragType == Enum.UserInputType.Touch) and Enum.UserInputType.Touch or Enum.UserInputType.MouseButton1
	local conn
	local endConn
	conn = UserInputService.InputChanged:Connect(function(inp)
		if inp.UserInputType == moveType then
			onMove(inp.Position)
		end
	end)
	endConn = UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == endType then
			if conn then
				conn:Disconnect()
			end
			if endConn then
				endConn:Disconnect()
			end
			if onEnd then
				onEnd()
			end
		end
	end)
	onMove(inputObject.Position)
	return { conn, endConn }
end

local function makeDraggable(dragBar, frame)
	local conns = {}
	local dragging = false
	local dragStart, startPos
	table.insert(conns, dragBar.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if isPrimary(input.UserInputType) then
			dragging = false
		end
	end))
	return conns
end

local function round(n, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(n * mult + 0.5) / mult
end

local function valuesEqual(val, target)
	if typeof(val) == "table" then
		for _, v in ipairs(val) do
			if v == target then
				return true
			end
		end
		return false
	end
	return val == target
end

local function makeElementShell(parent, height)
	height = height or 44
	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	return row
end

local function baseElementMethods(row)
	return {
		Show = function()
			row.Visible = true
		end,
		Hide = function()
			row.Visible = false
		end,
		Destroy = function()
			row:Destroy()
		end,
	}
end

local function addRowLabel(row, text)
	local theme = SwiftUI.CurrentTheme
	return Create("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = text or "",
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
	}, row)
end

local function makeToggle(parent, config)
	config = config or {}
	local theme = SwiftUI.CurrentTheme
	local row = makeElementShell(parent, 44)
	local label = addRowLabel(row, config.Text)

	local switch = Create("Frame", {
		Size = UDim2.new(0, 48, 0, 24),
		Position = UDim2.new(1, -58, 0.5, -12),
		BackgroundColor3 = theme.ToggleOff,
		BorderSizePixel = 0,
	}, row)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, switch)

	local knob = Create("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0, 3, 0, 3),
		BackgroundColor3 = theme.Knob,
		BorderSizePixel = 0,
	}, switch)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local value = config.Default and true or false
	local changedCallbacks = {}

	local function applyValue(animate)
		local goalX = value and 24 or 3
		if animate then
			TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, goalX, 0, 3) }):Play()
			TweenService:Create(switch, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = value and theme.ToggleOn or theme.ToggleOff }):Play()
		else
			knob.Position = UDim2.new(0, goalX, 0, 3)
			switch.BackgroundColor3 = value and theme.ToggleOn or theme.ToggleOff
		end
	end

	local function setValue(v, silent)
		value = v and true or false
		applyValue(true)
		if not silent then
			if config.Callback then
				pcall(config.Callback, value)
			end
			for _, c in ipairs(changedCallbacks) do
				pcall(c, value)
			end
		end
	end

	local function getValue()
		return value
	end

	local hitbox = Create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Active = true,
	}, row)

	hitbox.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			setValue(not value)
		end
	end)

	applyValue(false)

	local applyTheme = registerThemed(function()
		local t = SwiftUI.CurrentTheme
		label.TextColor3 = t.Text
		knob.BackgroundColor3 = t.Knob
		switch.BackgroundColor3 = value and t.ToggleOn or t.ToggleOff
	end)

	local obj = baseElementMethods(row)
	obj.SetValue = setValue
	obj.GetValue = getValue
	obj.OnChanged = function(cb)
		table.insert(changedCallbacks, cb)
	end
	obj._applyTheme = applyTheme
	obj._getState = function()
		return { type = "Toggle", value = value }
	end
	obj._setState = function(s)
		if s and s.value ~= nil then
			setValue(s.value, true)
		end
	end
	obj.Destroy = function()
		unregisterThemed(applyTheme)
		row:Destroy()
	end
	return obj
end

local function makeSlider(parent, config)
	config = config or {}
	local theme = SwiftUI.CurrentTheme
	local min = config.Min or 0
	local max = config.Max or 100
	local rounding = config.Rounding or 1
	local row = makeElementShell(parent, 48)
	local label = addRowLabel(row, config.Text)

	local valueLabel = Create("TextLabel", {
		Size = UDim2.new(0, 50, 1, 0),
		Position = UDim2.new(1, -60, 0, 0),
		BackgroundTransparency = 1,
		Text = "0",
		TextColor3 = theme.Primary,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, row)

	local track = Create("Frame", {
		Size = UDim2.new(1, -70, 0, 6),
		Position = UDim2.new(0, 10, 1, -14),
		BackgroundColor3 = theme.SliderTrack,
		BorderSizePixel = 0,
	}, row)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)

	local fill = Create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = theme.SliderFill,
		BorderSizePixel = 0,
	}, track)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

	local knob = Create("Frame", {
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Knob,
		BorderSizePixel = 0,
	}, track)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local hitbox = Create("TextButton", {
		Size = UDim2.new(1, -20, 0, 44),
		Position = UDim2.new(0, 10, 0, 2),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Active = true,
	}, row)

	local value = config.Default or min
	local changedCallbacks = {}

	local function clampValue(v)
		return math.clamp(v, min, max)
	end

	local function displayValue()
		return tostring(round(value, rounding))
	end

	local function update(silent)
		local pct = (max == min) and 0 or (value - min) / (max - min)
		pct = math.clamp(pct, 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, 0)
		valueLabel.Text = displayValue()
		if not silent then
			if config.Callback then
				pcall(config.Callback, value)
			end
			for _, c in ipairs(changedCallbacks) do
				pcall(c, value)
			end
		end
	end

	local function setValueFromX(x)
		local absPos = track.AbsolutePosition.X
		local absSize = track.AbsoluteSize.X
		if absSize <= 0 then
			return
		end
		local pct = (x - absPos) / absSize
		pct = math.clamp(pct, 0, 1)
		value = min + (max - min) * pct
		value = round(value, rounding)
		update()
	end

	hitbox.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			beginDrag(input, function(pos)
				setValueFromX(pos.X)
			end)
		end
	end)

	local function setValue(v, silent)
		value = clampValue(v)
		update(silent)
	end

	local function getValue()
		return value
	end

	update(true)

	local applyTheme = registerThemed(function()
		local t = SwiftUI.CurrentTheme
		label.TextColor3 = t.Text
		valueLabel.TextColor3 = t.Primary
		track.BackgroundColor3 = t.SliderTrack
		fill.BackgroundColor3 = t.SliderFill
		knob.BackgroundColor3 = t.Knob
	end)

	local obj = baseElementMethods(row)
	obj.SetValue = setValue
	obj.GetValue = getValue
	obj.OnChanged = function(cb)
		table.insert(changedCallbacks, cb)
	end
	obj._applyTheme = applyTheme
	obj._getState = function()
		return { type = "Slider", value = value }
	end
	obj._setState = function(s)
		if s and s.value ~= nil then
			setValue(s.value, true)
		end
	end
	obj.Destroy = function()
		unregisterThemed(applyTheme)
		row:Destroy()
	end
	return obj
end

local function makeButton(parent, config)
	config = config or {}
	local theme = SwiftUI.CurrentTheme
	local row = makeElementShell(parent, 48)
	local label = addRowLabel(row, "")

	local btn = Create("TextButton", {
		Size = UDim2.new(1, -20, 0, 40),
		Position = UDim2.new(0, 10, 0.5, -20),
		BackgroundColor3 = theme.Primary,
		Text = config.Text or "Button",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, row)
	Create("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)

	local function click()
		if config.Callback then
			pcall(config.Callback)
		end
	end

	btn.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			btn.BackgroundColor3 = theme.PrimaryHover
		end
	end)
	btn.InputEnded:Connect(function(input)
		if isPrimary(input.UserInputType) then
			btn.BackgroundColor3 = theme.Primary
		end
	end)
	btn.MouseButton1Click:Connect(click)

	local applyTheme = registerThemed(function()
		local t = SwiftUI.CurrentTheme
		btn.BackgroundColor3 = t.Primary
		btn.TextColor3 = t.Text
		label.TextColor3 = t.Text
	end)

	local obj = baseElementMethods(row)
	obj.Click = click
	obj._applyTheme = applyTheme
	obj.Destroy = function()
		unregisterThemed(applyTheme)
		row:Destroy()
	end
	return obj
end

local function makeLabel(parent, config)
	config = config or {}
	local theme = SwiftUI.CurrentTheme
	local row = makeElementShell(parent, 24)
	local label = Create("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = config.Text or "",
		TextColor3 = config.Color or theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
	}, row)

	local applyTheme = registerThemed(function()
		local t = SwiftUI.CurrentTheme
		label.TextColor3 = config.Color or t.TextDim
	end)

	local obj = baseElementMethods(row)
	obj.SetText = function(txt)
		label.Text = txt
	end
	obj._applyTheme = applyTheme
	obj.Destroy = function()
		unregisterThemed(applyTheme)
		row:Destroy()
	end
	return obj
end

local function makeTextInput(parent, config)
	config = config or {}
	local theme = SwiftUI.CurrentTheme
	local row = makeElementShell(parent, 48)
	local label = addRowLabel(row, config.Text)

	local box = Create("TextBox", {
		Size = UDim2.new(0, 160, 0, 40),
		Position = UDim2.new(1, -170, 0.5, -20),
		BackgroundColor3 = theme.Surface2,
		Text = config.Default or "",
		PlaceholderText = config.Placeholder or "",
		PlaceholderColor3 = theme.Placeholder,
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		BorderSizePixel = 0,
	}, row)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
	Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, box)

	local changedCallbacks = {}

	box.FocusLost:Connect(function()
		if config.Callback then
			pcall(config.Callback, box.Text)
		end
		for _, c in ipairs(changedCallbacks) do
			pcall(c, box.Text)
		end
	end)

	local applyTheme = registerThemed(function()
		local t = SwiftUI.CurrentTheme
		box.BackgroundColor3 = t.Surface2
		box.TextColor3 = t.Text
		box.PlaceholderColor3 = t.Placeholder
		label.TextColor3 = t.Text
	end)

	local obj = baseElementMethods(row)
	obj.SetValue = function(v, silent)
		box.Text = v
		if not silent then
			if config.Callback then
				pcall(config.Callback, v)
			end
			for _, c in ipairs(changedCallbacks) do
				pcall(c, v)
			end
		end
	end
	obj.GetValue = function()
		return box.Text
	end
	obj.OnChanged = function(cb)
		table.insert(changedCallbacks, cb)
	end
	obj._applyTheme = applyTheme
	obj._getState = function()
		return { type = "TextInput", value = box.Text }
	end
	obj._setState = function(s)
		if s and s.value ~= nil then
			box.Text = s.value
		end
	end
	obj.Destroy = function()
		unregisterThemed(applyTheme)
		row:Destroy()
	end
	return obj
end

local function makeDropdown(parent, config)
	config = config or {}
	local theme = SwiftUI.CurrentTheme
	local values = config.Values or {}
	local multi = config.Multi and true or false
	local selected = {}
	if config.Default then
		if multi and type(config.Default) == "table" then
			for _, v in ipairs(config.Default) do
				selected[v] = true
			end
		else
			selected[config.Default] = true
		end
	end

	local rowHeight = 48
	local row = makeElementShell(parent, rowHeight)
	local label = addRowLabel(row, config.Text)

	local header = Create("TextButton", {
		Size = UDim2.new(0, 180, 0, 40),
		Position = UDim2.new(1, -190, 0.5, -20),
		BackgroundColor3 = theme.Surface2,
		Text = "",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, row)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, header)
	Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, header)

	local valueLabel = Create("TextLabel", {
		Size = UDim2.new(1, -30, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
	}, header)

	local arrow = Create("TextLabel", {
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -20, 0, 0),
		BackgroundTransparency = 1,
		Text = "v",
		TextColor3 = theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
	}, header)

	local list = Create("ScrollingFrame", {
		Size = UDim2.new(0, 180, 0, 0),
		Position = UDim2.new(1, -190, 0, 42),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = theme.Border,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		ZIndex = 5,
	}, row)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, list)
	Create("UIListLayout", { Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center }, list)
	Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, list)

	local expanded = false
	local changedCallbacks = {}
	local optionButtons = {}
	local toggleList

	local function displayText()
		if multi then
			local count = 0
			for _ in pairs(selected) do
				count = count + 1
			end
			if count == 0 then
				return "None"
			elseif count == 1 then
				for k in pairs(selected) do
					return tostring(k)
				end
			else
				return count .. " selected"
			end
		else
			for k, v in pairs(selected) do
				if v then
					return tostring(k)
				end
			end
			return "None"
		end
	end

	local function fireCallbacks(silent)
		valueLabel.Text = displayText()
		if not silent then
			local out
			if multi then
				out = {}
				for k, v in pairs(selected) do
					if v then
						table.insert(out, k)
					end
				end
			else
				for k, v in pairs(selected) do
					if v then
						out = k
						break
					end
				end
			end
			if config.Callback then
				pcall(config.Callback, out)
			end
			for _, c in ipairs(changedCallbacks) do
				pcall(c, out)
			end
		end
	end

	local function rebuildList()
		for _, b in ipairs(optionButtons) do
			b:Destroy()
		end
		optionButtons = {}
		for _, val in ipairs(values) do
			local opt = Create("TextButton", {
				Size = UDim2.new(1, -8, 0, 36),
				BackgroundColor3 = theme.Surface2,
				Text = "",
				TextColor3 = theme.Text,
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				BorderSizePixel = 0,
			}, list)
			Create("UICorner", { CornerRadius = UDim.new(0, 4) }, opt)
			Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, opt)

			local check
			if multi then
				check = Create("TextLabel", {
					Size = UDim2.new(0, 16, 1, 0),
					Position = UDim2.new(1, -24, 0, 0),
					BackgroundTransparency = 1,
					Text = selected[val] and "X" or "",
					TextColor3 = theme.Primary,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					Font = Enum.Font.GothamBold,
					TextSize = 13,
				}, opt)
			end

			Create("TextLabel", {
				Size = UDim2.new(1, (multi and -30 or -16), 1, 0),
				BackgroundTransparency = 1,
				Text = tostring(val),
				TextColor3 = theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
			}, opt)

			opt.InputBegan:Connect(function(input)
				if isPrimary(input.UserInputType) then
					opt.BackgroundColor3 = theme.PrimaryHover
				end
			end)
			opt.InputEnded:Connect(function(input)
				if isPrimary(input.UserInputType) then
					opt.BackgroundColor3 = theme.Surface2
				end
			end)
			opt.MouseButton1Click:Connect(function()
				if multi then
					selected[val] = not selected[val]
					if check then
						check.Text = selected[val] and "X" or ""
					end
					fireCallbacks()
				else
					selected = {}
					selected[val] = true
					fireCallbacks()
					toggleList(false)
				end
			end)
			table.insert(optionButtons, opt)
		end
		list.CanvasSize = UDim2.new(0, 0, 0, #values * 38 + 4)
	end

	function toggleList(state)
		expanded = (state == nil) and (not expanded) or state
		local targetH = expanded and math.min(#values * 38 + 4, 200) or 0
		list.Visible = true
		arrow.Text = expanded and "^" or "v"
		local tw = TweenService:Create(list, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 180, 0, targetH) })
		tw:Play()
		tw.Completed:Connect(function()
			if not expanded then
				list.Visible = false
			end
		end)
		row.Size = UDim2.new(1, 0, 0, rowHeight + targetH)
	end

	header.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			header.BackgroundColor3 = theme.PrimaryHover
		end
	end)
	header.InputEnded:Connect(function(input)
		if isPrimary(input.UserInputType) then
			header.BackgroundColor3 = theme.Surface2
		end
	end)
	header.MouseButton1Click:Connect(function()
		toggleList()
	end)

	rebuildList()
	fireCallbacks(true)

	local applyTheme = registerThemed(function()
		local t = SwiftUI.CurrentTheme
		label.TextColor3 = t.Text
		valueLabel.TextColor3 = t.Text
		header.BackgroundColor3 = t.Surface2
		arrow.TextColor3 = t.TextDim
		list.BackgroundColor3 = t.Surface
		list.ScrollBarImageColor3 = t.Border
		for _, b in ipairs(optionButtons) do
			b.BackgroundColor3 = t.Surface2
			for _, child in ipairs(b:GetChildren()) do
				if child:IsA("TextLabel") then
					child.TextColor3 = (child.Text == "X") and t.Primary or t.Text
				end
			end
		end
	end)

	local obj = baseElementMethods(row)
	obj.SetValue = function(v, silent)
		selected = {}
		if multi and type(v) == "table" then
			for _, val in ipairs(v) do
				selected[val] = true
			end
		else
			selected[v] = true
		end
		rebuildList()
		fireCallbacks(silent)
	end
	obj.GetValue = function()
		if multi then
			local out = {}
			for k, val in pairs(selected) do
				if val then
					table.insert(out, k)
				end
			end
			return out
		else
			for k, val in pairs(selected) do
				if val then
					return k
				end
			end
			return nil
		end
	end
	obj.OnChanged = function(cb)
		table.insert(changedCallbacks, cb)
	end
	obj._applyTheme = applyTheme
	obj._getState = function()
		return { type = "Dropdown", value = obj.GetValue() }
	end
	obj._setState = function(s)
		if s and s.value ~= nil then
			obj.SetValue(s.value, true)
		end
	end
	obj.Destroy = function()
		unregisterThemed(applyTheme)
		row:Destroy()
	end
	return obj
end

local function makeKeybind(parent, config)
	config = config or {}
	local theme = SwiftUI.CurrentTheme
	local row = makeElementShell(parent, 48)
	local label = addRowLabel(row, config.Text)

	local btn = Create("TextButton", {
		Size = UDim2.new(0, 120, 0, 40),
		Position = UDim2.new(1, -130, 0.5, -20),
		BackgroundColor3 = theme.Surface2,
		Text = "",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, row)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)

	local modeBtn = Create("TextButton", {
		Size = UDim2.new(0, 50, 0, 40),
		Position = UDim2.new(1, -190, 0.5, -20),
		BackgroundColor3 = theme.Surface,
		Text = config.Mode or "Toggle",
		TextColor3 = theme.TextDim,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, row)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, modeBtn)

	local value = config.Default or Enum.KeyCode.Unknown
	local modes = { "Toggle", "Hold", "Always" }
	local modeIndex = 1
	for i, m in ipairs(modes) do
		if m == config.Mode then
			modeIndex = i
			break
		end
	end
	local recording = false
	local active = false
	local changedCallbacks = {}
	local listenConn
	local inputConns = {}

	local function keyName(kc)
		if typeof(kc) == "EnumItem" then
			return kc.Name
		end
		return tostring(kc)
	end

	local function updateLabel()
		btn.Text = recording and "Press a key..." or keyName(value)
	end

	local function fireCallbacks(state)
		if config.Callback then
			pcall(config.Callback, state)
		end
		for _, c in ipairs(changedCallbacks) do
			pcall(c, state)
		end
	end

	btn.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			btn.BackgroundColor3 = theme.PrimaryHover
			recording = true
			updateLabel()
			if listenConn then
				listenConn:Disconnect()
			end
			listenConn = UserInputService.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.Keyboard then
					value = inp.KeyCode
					recording = false
					updateLabel()
					if listenConn then
						listenConn:Disconnect()
						listenConn = nil
					end
				end
			end)
		end
	end)
	btn.InputEnded:Connect(function(input)
		if isPrimary(input.UserInputType) then
			btn.BackgroundColor3 = theme.Surface2
		end
	end)

	modeBtn.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			modeBtn.BackgroundColor3 = theme.PrimaryHover
		end
	end)
	modeBtn.InputEnded:Connect(function(input)
		if isPrimary(input.UserInputType) then
			modeBtn.BackgroundColor3 = theme.Surface
		end
	end)
	modeBtn.MouseButton1Click:Connect(function()
		modeIndex = (modeIndex % #modes) + 1
		modeBtn.Text = modes[modeIndex]
	end)

	table.insert(inputConns, UserInputService.InputBegan:Connect(function(input)
		if recording then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == value then
			if modes[modeIndex] == "Toggle" then
				active = not active
				fireCallbacks(active)
			elseif modes[modeIndex] == "Hold" then
				active = true
				fireCallbacks(true)
			elseif modes[modeIndex] == "Always" then
				fireCallbacks(true)
			end
		end
	end))
	table.insert(inputConns, UserInputService.InputEnded:Connect(function(input)
		if recording then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == value then
			if modes[modeIndex] == "Hold" then
				active = false
				fireCallbacks(false)
			end
		end
	end))

	updateLabel()

	local applyTheme = registerThemed(function()
		local t = SwiftUI.CurrentTheme
		label.TextColor3 = t.Text
		btn.BackgroundColor3 = t.Surface2
		btn.TextColor3 = t.Text
		modeBtn.BackgroundColor3 = t.Surface
		modeBtn.TextColor3 = t.TextDim
	end)

	local obj = baseElementMethods(row)
	obj.SetValue = function(v, silent)
		value = v
		updateLabel()
		if not silent then
			fireCallbacks(active)
		end
	end
	obj.GetValue = function()
		return value
	end
	obj.OnChanged = function(cb)
		table.insert(changedCallbacks, cb)
	end
	obj._applyTheme = applyTheme
	obj._getState = function()
		return { type = "Keybind", value = keyName(value), mode = modes[modeIndex] }
	end
	obj._setState = function(s)
		if s and s.value ~= nil then
			for _, code in ipairs(Enum.KeyCode:GetEnumItems()) do
				if code.Name == s.value then
					value = code
					break
				end
			end
			updateLabel()
		end
	end
	obj.Destroy = function()
		unregisterThemed(applyTheme)
		if listenConn then
			listenConn:Disconnect()
		end
		for _, c in ipairs(inputConns) do
			if c and c.Disconnect then
				c:Disconnect()
			end
		end
		row:Destroy()
	end
	return obj
end

local function makeColorPicker(parent, config)
	config = config or {}
	local theme = SwiftUI.CurrentTheme
	local row = makeElementShell(parent, 48)
	local label = addRowLabel(row, config.Title or config.Text or "Color")

	local swatch = Create("TextButton", {
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(1, -50, 0.5, -20),
		BackgroundColor3 = config.Default or Color3.fromRGB(124, 92, 240),
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, row)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, swatch)

	local screenGui = row:FindFirstAncestorWhichIsA("ScreenGui")

	local popup = Create("Frame", {
		Size = UDim2.new(0, 220, 0, 260),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 50,
	}, screenGui)
	Create("UICorner", { CornerRadius = UDim.new(0, 8) }, popup)
	Create("UIStroke", { Color = theme.Border, Thickness = 1 }, popup)

	local svBox = Create("Frame", {
		Size = UDim2.new(0, 200, 0, 150),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Color3.fromHSV(0, 1, 1),
		BorderSizePixel = 0,
	}, popup)

	local svWhite = Create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, svBox)
	Create("UIGradient", {
		Transparency = NumberSequence.new(0, 1),
		Rotation = 0,
	}, svWhite)

	local svBlack = Create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	}, svBox)
	Create("UIGradient", {
		Transparency = NumberSequence.new(1, 0),
		Rotation = 90,
	}, svBlack)

	local svKnob = Create("Frame", {
		Size = UDim2.new(0, 8, 0, 8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, svBox)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, svKnob)
	Create("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1 }, svKnob)

	local hueBar = Create("Frame", {
		Size = UDim2.new(0, 200, 0, 12),
		Position = UDim2.new(0, 10, 0, 170),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, popup)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, hueBar)
	Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
	}, hueBar)

	local hueKnob = Create("Frame", {
		Size = UDim2.new(0, 6, 0, 16),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, hueBar)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, hueKnob)
	Create("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1 }, hueKnob)

	local preview = Create("Frame", {
		Size = UDim2.new(0, 40, 0, 24),
		Position = UDim2.new(0, 10, 0, 195),
		BackgroundColor3 = config.Default or Color3.fromRGB(124, 92, 240),
		BorderSizePixel = 0,
	}, popup)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, preview)

	local closePopupBtn = Create("TextButton", {
		Size = UDim2.new(0, 70, 0, 24),
		Position = UDim2.new(1, -80, 0, 225),
		BackgroundColor3 = theme.Primary,
		Text = "Done",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, popup)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, closePopupBtn)

	local value = config.Default or Color3.fromRGB(124, 92, 240)
	local h, s, v = value:ToHSV()
	local changedCallbacks = {}
	local open = false

	local function updateColor(silent)
		svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		local col = Color3.fromHSV(h, s, v)
		swatch.BackgroundColor3 = col
		preview.BackgroundColor3 = col
		svKnob.Position = UDim2.new(s, 0, 1 - v, 0)
		hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
		value = col
		if not silent then
			if config.Callback then
				pcall(config.Callback, col)
			end
			for _, c in ipairs(changedCallbacks) do
				pcall(c, col)
			end
		end
	end

	local function positionPopup()
		local pos = swatch.AbsolutePosition
		local viewSize = workspace.CurrentCamera.ViewportSize
		local px = pos.X
		local py = pos.Y + 44
		if px + 220 > viewSize.X then
			px = math.max(0, viewSize.X - 230)
		end
		if py + 260 > viewSize.Y then
			py = math.max(0, pos.Y - 268)
		end
		popup.Position = UDim2.fromOffset(px, py)
	end

	svBox.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			beginDrag(input, function(pos)
				local rel = svBox.AbsolutePosition
				local size = svBox.AbsoluteSize
				if size.X > 0 and size.Y > 0 then
					s = math.clamp((pos.X - rel.X) / size.X, 0, 1)
					v = math.clamp(1 - (pos.Y - rel.Y) / size.Y, 0, 1)
					updateColor()
				end
			end)
		end
	end)

	hueBar.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			beginDrag(input, function(pos)
				local rel = hueBar.AbsolutePosition
				local size = hueBar.AbsoluteSize.X
				if size > 0 then
					h = math.clamp((pos.X - rel.X) / size, 0, 1)
					updateColor()
				end
			end)
		end
	end)

	swatch.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			open = not open
			popup.Visible = open
			if open then
				positionPopup()
			end
		end
	end)

	closePopupBtn.MouseButton1Click:Connect(function()
		open = false
		popup.Visible = false
	end)

	updateColor(true)

	local applyTheme = registerThemed(function()
		local t = SwiftUI.CurrentTheme
		label.TextColor3 = t.Text
		popup.BackgroundColor3 = t.Surface
		local stroke = popup:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = t.Border
		end
		closePopupBtn.BackgroundColor3 = t.Primary
		closePopupBtn.TextColor3 = t.Text
	end)

	local obj = baseElementMethods(row)
	obj.SetValue = function(col, silent)
		h, s, v = col:ToHSV()
		updateColor(silent)
	end
	obj.GetValue = function()
		return value
	end
	obj.OnChanged = function(cb)
		table.insert(changedCallbacks, cb)
	end
	obj._applyTheme = applyTheme
	obj._getState = function()
		return { type = "ColorPicker", value = { r = round(value.R, 3), g = round(value.G, 3), b = round(value.B, 3) } }
	end
	obj._setState = function(st)
		if st and st.value then
			obj.SetValue(Color3.new(st.value.r, st.value.g, st.value.b), true)
		end
	end
	obj.Destroy = function()
		unregisterThemed(applyTheme)
		popup:Destroy()
		row:Destroy()
	end
	return obj
end

local elementFactories = {
	Toggle = makeToggle,
	Slider = makeSlider,
	Dropdown = makeDropdown,
	Button = makeButton,
	Keybind = makeKeybind,
	ColorPicker = makeColorPicker,
	Label = makeLabel,
	TextInput = makeTextInput,
}

local function makeDependencyBox(parent)
	local container = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 4) }, container)

	local elements = {}
	local conditionMap = {}

	local function addElement(kind, config)
		local factory = elementFactories[kind]
		if not factory then
			return nil
		end
		local el = factory(container, config)
		table.insert(elements, el)
		return el
	end

	local box = {
		Show = function()
			container.Visible = true
		end,
		Hide = function()
			container.Visible = false
		end,
		Destroy = function()
			for _, el in ipairs(elements) do
				if el.Destroy then
					el.Destroy()
				end
			end
			container:Destroy()
		end,
		AddToggle = function(cfg)
			return addElement("Toggle", cfg)
		end,
		AddSlider = function(cfg)
			return addElement("Slider", cfg)
		end,
		AddDropdown = function(cfg)
			return addElement("Dropdown", cfg)
		end,
		AddButton = function(cfg)
			return addElement("Button", cfg)
		end,
		AddKeybind = function(cfg)
			return addElement("Keybind", cfg)
		end,
		AddColorPicker = function(cfg)
			return addElement("ColorPicker", cfg)
		end,
		AddLabel = function(cfg)
			return addElement("Label", cfg)
		end,
		AddTextInput = function(cfg)
			return addElement("TextInput", cfg)
		end,
	}

	function box.Refresh()
		local ok = true
		for _, cond in ipairs(conditionMap) do
			local src = cond.Toggle or cond.Option
			if src and src.GetValue then
				local val = src.GetValue()
				if not valuesEqual(val, cond.Value) then
					ok = false
					break
				end
			else
				ok = false
			end
		end
		container.Visible = ok
	end

	function box.SetupDependencies(conditions)
		conditionMap = conditions or {}
		for _, cond in ipairs(conditionMap) do
			local src = cond.Toggle or cond.Option
			if src and src.OnChanged then
				src.OnChanged(function()
					box.Refresh()
				end)
			end
		end
		box.Refresh()
	end

	return box
end

local function makeSection(parent, config)
	config = config or {}
	local theme = SwiftUI.CurrentTheme
	local container = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})

	local box = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = container,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8) }, box)
	Create("UIStroke", { Color = theme.Border, Thickness = 1 }, box)
	Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)

	local title = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = config.Name or "Section",
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, box)

	local list = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 0, 0, 24),
	}, box)
	Create("UIListLayout", { Padding = UDim.new(0, 6) }, list)

	local elements = {}
	local depBoxes = {}

	local function add(kind, cfg)
		local factory = elementFactories[kind]
		if not factory then
			return nil
		end
		local el = factory(list, cfg)
		table.insert(elements, el)
		return el
	end

	local applyTheme = registerThemed(function()
		local t = SwiftUI.CurrentTheme
		box.BackgroundColor3 = t.Surface
		local stroke = box:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = t.Border
		end
		title.TextColor3 = t.Text
	end)

	local section = {
		Show = function()
			container.Visible = true
		end,
		Hide = function()
			container.Visible = false
		end,
		Destroy = function()
			unregisterThemed(applyTheme)
			for _, el in ipairs(elements) do
				if el.Destroy then
					el.Destroy()
				end
			end
			container:Destroy()
		end,
		AddToggle = function(cfg)
			return add("Toggle", cfg)
		end,
		AddSlider = function(cfg)
			return add("Slider", cfg)
		end,
		AddDropdown = function(cfg)
			return add("Dropdown", cfg)
		end,
		AddButton = function(cfg)
			return add("Button", cfg)
		end,
		AddKeybind = function(cfg)
			return add("Keybind", cfg)
		end,
		AddColorPicker = function(cfg)
			return add("ColorPicker", cfg)
		end,
		AddLabel = function(cfg)
			return add("Label", cfg)
		end,
		AddTextInput = function(cfg)
			return add("TextInput", cfg)
		end,
		AddDependencyBox = function()
			local dep = makeDependencyBox(list)
			table.insert(depBoxes, dep)
			return dep
		end,
		RefreshDependencies = function()
			for _, d in ipairs(depBoxes) do
				if d.Refresh then
					d.Refresh()
				end
			end
		end,
		GetElements = function()
			return elements
		end,
	}
	return section
end

local function bindCanvasSize(scrollFrame, contentFrame)
	contentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentFrame.AbsoluteSize.Y)
	end)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentFrame.AbsoluteSize.Y)
end

function SwiftUI.CreateWindow(config)
	config = config or {}
	local theme = SwiftUI.CurrentTheme

	local screenGui = Create("ScreenGui", {
		Name = "SwiftUI_" .. tostring(math.random(100000, 999999)),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 9999,
	})
	screenGui.Parent = getGuiParent()

	local minSize = config.Size or Vector2.new(560, 400)
	local isMobile = SwiftUI.IsMobile()
	if isMobile then
		minSize = Vector2.new(math.min(minSize.X, 360), math.min(minSize.Y, 480))
	end

	local position = config.Position or UDim2.new(0.5, -minSize.X / 2, 0.5, -minSize.Y / 2)

	local shadow = Create("Frame", {
		Size = UDim2.new(0, minSize.X + 8, 0, minSize.Y + 8),
		Position = UDim2.new(0.5, -(minSize.X + 8) / 2, 0.5, -(minSize.Y + 8) / 2),
		BackgroundColor3 = theme.Shadow,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
	}, screenGui)
	Create("UICorner", { CornerRadius = UDim.new(0, 12) }, shadow)

	local window = Create("Frame", {
		Size = UDim2.new(0, minSize.X, 0, minSize.Y),
		Position = position,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
	}, screenGui)
	Create("UICorner", { CornerRadius = UDim.new(0, 10) }, window)
	Create("UIStroke", { Color = theme.Border, Thickness = 1 }, window)

	local titleBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
	}, window)
	Create("UICorner", { CornerRadius = UDim.new(0, 10) }, titleBar)

	local title = Create("TextLabel", {
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = config.Title or "SwiftUI",
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
	}, titleBar)

	local closeBtn = Create("TextButton", {
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -36, 0, 5),
		BackgroundColor3 = theme.Danger,
		Text = "X",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, titleBar)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, closeBtn)

	local minBtn = Create("TextButton", {
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -70, 0, 5),
		BackgroundColor3 = theme.Surface2,
		Text = "_",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, titleBar)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, minBtn)

	local tabBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
	}, window)

	local tabList = Create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, tabBar)
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }, tabList)
	Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, tabList)

	local content = Create("Frame", {
		Size = UDim2.new(1, 0, 1, -76),
		Position = UDim2.new(0, 0, 0, 76),
		BackgroundTransparency = 1,
	}, window)

	local tabs = {}
	local tabButtons = {}
	local minimized = false
	local originalSize = window.Size
	local dragConns = makeDraggable(titleBar, window)

	closeBtn.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 70)
		end
	end)
	closeBtn.InputEnded:Connect(function(input)
		if isPrimary(input.UserInputType) then
			closeBtn.BackgroundColor3 = theme.Danger
		end
	end)
	closeBtn.MouseButton1Click:Connect(function()
		screenGui.Visible = false
	end)

	minBtn.InputBegan:Connect(function(input)
		if isPrimary(input.UserInputType) then
			minBtn.BackgroundColor3 = theme.PrimaryHover
		end
	end)
	minBtn.InputEnded:Connect(function(input)
		if isPrimary(input.UserInputType) then
			minBtn.BackgroundColor3 = theme.Surface2
		end
	end)
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		local targetSize = minimized and UDim2.new(0, originalSize.X.Offset, 0, 40) or originalSize
		local tw = TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = targetSize })
		tw:Play()
		content.Visible = not minimized
		tabBar.Visible = not minimized
		shadow.Size = minimized and UDim2.new(0, originalSize.X.Offset + 8, 0, 48) or UDim2.new(0, minSize.X + 8, 0, minSize.Y + 8)
		shadow.Position = minimized and UDim2.new(0.5, -(originalSize.X.Offset + 8) / 2, 0.5, -24) or UDim2.new(0.5, -(minSize.X + 8) / 2, 0.5, -(minSize.Y + 8) / 2)
	end)

	local function selectTab(idx)
		for i, t in ipairs(tabs) do
			t.container.Visible = (i == idx)
			local btn = tabButtons[i]
			if btn then
				btn.BackgroundColor3 = (i == idx) and theme.Surface2 or theme.Background
				btn.TextColor3 = (i == idx) and theme.Text or theme.TextDim
			end
		end
	end

	local windowObj = {
		ScreenGui = screenGui,
		Window = window,
		Tabs = tabs,
	}

	function windowObj.AddTab(tabConfig)
		tabConfig = tabConfig or {}
		local idx = #tabs + 1

		local btn = Create("TextButton", {
			Size = UDim2.new(0, 90, 0, 30),
			BackgroundColor3 = theme.Background,
			Text = "",
			TextColor3 = theme.TextDim,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			AutoButtonColor = false,
			BorderSizePixel = 0,
		}, tabList)
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
		Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, btn)

		Create("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = (tabConfig.Icon and (tabConfig.Icon .. " ") or "") .. (tabConfig.Name or ("Tab " .. idx)),
			TextColor3 = theme.TextDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
		}, btn)

		btn.InputBegan:Connect(function(input)
			if isPrimary(input.UserInputType) then
				btn.BackgroundColor3 = theme.Surface2
			end
		end)
		btn.InputEnded:Connect(function(input)
			if isPrimary(input.UserInputType) then
				btn.BackgroundColor3 = (tabs[idx] and tabs[idx].container.Visible) and theme.Surface2 or theme.Background
			end
		end)
		btn.MouseButton1Click:Connect(function()
			selectTab(idx)
		end)
		table.insert(tabButtons, btn)

		local container = Create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = theme.Background,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = theme.Border,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Visible = false,
		}, content)
		Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, container)

		local inner = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, container)
		Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, inner)
		bindCanvasSize(container, inner)

		local pendingRow = nil
		local rowCounter = 0

		local function ensureRow()
			if pendingRow then
				return pendingRow
			end
			rowCounter = rowCounter + 1
			local rowFrame = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = rowCounter,
			}, inner)
			Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Top }, rowFrame)

			local leftCol = Create("Frame", {
				Size = UDim2.new(0.5, -4, 0, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
			}, rowFrame)
			Create("UIListLayout", { Padding = UDim.new(0, 8) }, leftCol)

			local rightCol = Create("Frame", {
				Size = UDim2.new(0.5, -4, 0, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
			}, rowFrame)
			Create("UIListLayout", { Padding = UDim.new(0, 8) }, rightCol)

			pendingRow = { frame = rowFrame, leftCol = leftCol, rightCol = rightCol }
			return pendingRow
		end

		local sections = {}
		local tabObj = {
			Container = container,
			container = container,
			Sections = sections,
			Show = function()
				selectTab(idx)
			end,
			AddSection = function(secConfig)
				secConfig = secConfig or {}
				local lay = secConfig.Layout or "Left"
				local parentCol
				if lay == "Full" then
					pendingRow = nil
					parentCol = inner
					local section = makeSection(inner, secConfig)
					table.insert(sections, section)
					return section
				else
					local row = ensureRow()
					parentCol = (lay == "Right") and row.rightCol or row.leftCol
					local section = makeSection(parentCol, secConfig)
					table.insert(sections, section)
					return section
				end
			end,
		}
		table.insert(tabs, tabObj)

		if idx == 1 then
			selectTab(1)
		end

		return tabObj
	end

	function windowObj.AddSection(secConfig)
		local tab = tabs[1]
		if not tab then
			tab = windowObj.AddTab({ Name = "Main" })
		end
		return tab.AddSection(secConfig or { Layout = "Full" })
	end

	function windowObj.AddElement(kind, cfg)
		local tab = tabs[1]
		if not tab then
			tab = windowObj.AddTab({ Name = "Main" })
		end
		local sec = tab.Sections[#tab.Sections]
		if not sec then
			sec = tab.AddSection({ Name = "Section", Layout = "Full" })
		end
		local method = sec["Add" .. tostring(kind)]
		if method then
			return method(cfg)
		end
		return nil
	end

	local applyTheme = registerThemed(function()
		local t = SwiftUI.CurrentTheme
		window.BackgroundColor3 = t.Background
		titleBar.BackgroundColor3 = t.Surface
		title.TextColor3 = t.Text
		closeBtn.BackgroundColor3 = t.Danger
		minBtn.BackgroundColor3 = t.Surface2
		tabBar.BackgroundColor3 = t.Background
		shadow.BackgroundColor3 = t.Shadow
		local stroke = window:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = t.Border
		end
		for i, btn in ipairs(tabButtons) do
			local isActive = tabs[i] and tabs[i].container.Visible
			btn.BackgroundColor3 = isActive and t.Surface2 or t.Background
			for _, child in ipairs(btn:GetChildren()) do
				if child:IsA("TextLabel") then
					child.TextColor3 = isActive and t.Text or t.TextDim
				end
			end
		end
		for _, tab in ipairs(tabs) do
			tab.container.ScrollBarImageColor3 = t.Border
			tab.container.BackgroundColor3 = t.Background
		end
	end)

	function windowObj.Destroy()
		unregisterThemed(applyTheme)
		for _, c in ipairs(dragConns) do
			if c and c.Disconnect then
				c:Disconnect()
			end
		end
		for _, tab in ipairs(tabs) do
			for _, section in ipairs(tab.Sections) do
				pcall(section.Destroy)
			end
		end
		screenGui:Destroy()
	end

	function windowObj.GetState()
		local state = { position = { x = window.Position.X.Offset, y = window.Position.Y.Offset }, visible = screenGui.Visible, theme = SwiftUI.CurrentTheme.Name }
		for ti, tab in ipairs(tabs) do
			state["tab" .. ti] = {}
			for si, section in ipairs(tab.Sections) do
				local els = section.GetElements()
				state["tab" .. ti]["section" .. si] = {}
				for ei, el in ipairs(els) do
					if el._getState then
						state["tab" .. ti]["section" .. si]["el" .. ei] = el._getState()
					end
				end
			end
		end
		return state
	end

	function windowObj.SetState(data)
		if not data then
			return
		end
		for ti, tab in ipairs(tabs) do
			local tdata = data["tab" .. ti]
			if tdata then
				for si, section in ipairs(tab.Sections) do
					local sdata = tdata["section" .. si]
					if sdata then
						local els = section.GetElements()
						for ei, el in ipairs(els) do
							if el._setState and sdata["el" .. ei] then
								pcall(el._setState, sdata["el" .. ei])
							end
						end
					end
				end
			end
		end
		if data.position then
			windowObj.SetPosition(UDim2.fromOffset(data.position.x, data.position.y))
		end
		if data.visible ~= nil then
			screenGui.Visible = data.visible
		end
		if data.theme then
			SwiftUI.SetTheme(data.theme)
		end
	end

	function windowObj.SetPosition(pos)
		window.Position = pos
	end

	function windowObj.SetSize(size)
		window.Size = UDim2.new(0, size.X, 0, size.Y)
		originalSize = window.Size
	end

	function windowObj.SetVisible(vis)
		screenGui.Visible = vis
	end

	table.insert(SwiftUI._windows, windowObj)
	return windowObj
end

function SwiftUI.SaveConfig(name, data)
	local ok, json = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	if not ok then
		return false
	end
	if writefile then
		pcall(writefile, "SwiftUI_" .. name .. ".json", json)
		return true
	end
	SwiftUI._memConfigs[name] = json
	return true
end

function SwiftUI.LoadConfig(name)
	if readfile then
		local ok, content = pcall(readfile, "SwiftUI_" .. name .. ".json")
		if ok and content then
			local ok2, data = pcall(function()
				return HttpService:JSONDecode(content)
			end)
			if ok2 then
				return data
			end
		end
	end
	local json = SwiftUI._memConfigs[name]
	if json then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(json)
		end)
		if ok then
			return data
		end
	end
	return nil
end

function SwiftUI.Unload()
	local wins = {}
	for _, w in ipairs(SwiftUI._windows) do
		table.insert(wins, w)
	end
	for _, w in ipairs(wins) do
		pcall(w.Destroy)
	end
	SwiftUI._windows = {}
	local copy = themeRegistry
	themeRegistry = {}
	for _, fn in ipairs(copy) do
		pcall(fn)
	end
end

function SwiftUI.IsMobile()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		SwiftUI.IsTouch = true
		SwiftUI.ActiveInput = "Touch"
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		SwiftUI.ActiveInput = "Mouse"
	end
end)

return SwiftUI
