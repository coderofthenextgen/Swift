local DrawingLib = {}
local cloneref = cloneref or function(obj) return obj end
local Workspace = cloneref(game:GetService('Workspace'))
cache.invalidate(Workspace)
local RunService = cloneref(game:GetService('RunService'))
cache.invalidate(RunService)
local UserInputService = cloneref(game:GetService('UserInputService'))
cache.invalidate(UserInputService)

local drawings = {}
local renderConnection = nil

-- Fixed: use the native Drawing.new, not self-referencing
DrawingLib.new = function(type)
    local drawing = Drawing.new(type)
    table.insert(drawings, drawing)
    return drawing
end

DrawingLib.Types = {
    Line = "Line",
    Circle = "Circle",
    Square = "Square",
    Triangle = "Triangle",
    Text = "Text",
    Image = "Image",
    Quad = "Quad"
}

DrawingLib.Line = function(from, to, color, thickness, visible)
    local line = DrawingLib.new("Line")
    line.From = from
    line.To = to
    line.Color = color or Color3.fromRGB(255, 255, 255)
    line.Thickness = thickness or 1
    line.Visible = visible ~= false
    return line
end

DrawingLib.Circle = function(position, radius, color, thickness, filled, visible)
    local circle = DrawingLib.new("Circle")
    circle.Position = position
    circle.Radius = radius
    circle.Color = color or Color3.fromRGB(255, 255, 255)
    circle.Thickness = thickness or 1
    circle.Filled = filled or false
    circle.Visible = visible ~= false
    return circle
end

DrawingLib.Square = function(position, size, color, thickness, filled, visible)
    local square = DrawingLib.new("Square")
    square.Position = position
    square.Size = size
    square.Color = color or Color3.fromRGB(255, 255, 255)
    square.Thickness = thickness or 1
    square.Filled = filled or false
    square.Visible = visible ~= false
    return square
end

DrawingLib.Triangle = function(a, b, c, color, thickness, filled, visible)
    local triangle = DrawingLib.new("Triangle")
    triangle.PointA = a
    triangle.PointB = b
    triangle.PointC = c
    triangle.Color = color or Color3.fromRGB(255, 255, 255)
    triangle.Thickness = thickness or 1
    triangle.Filled = filled or false
    triangle.Visible = visible ~= false
    return triangle
end

DrawingLib.Text = function(position, text, color, size, center, outline, visible)
    local txt = DrawingLib.new("Text")
    txt.Position = position
    txt.Text = text
    txt.Color = color or Color3.fromRGB(255, 255, 255)
    txt.Size = size or 16
    txt.Center = center or false
    txt.Outline = outline or false
    txt.Visible = visible ~= false
    return txt
end

DrawingLib.Quad = function(a, b, c, d, color, thickness, visible)
    local quad = DrawingLib.new("Quad")
    quad.PointA = a
    quad.PointB = b
    quad.PointC = c
    quad.PointD = d
    quad.Color = color or Color3.fromRGB(255, 255, 255)
    quad.Thickness = thickness or 1
    quad.Visible = visible ~= false
    return quad
end

DrawingLib.clear = function()
    for _, drawing in ipairs(drawings) do
        if drawing and typeof(drawing.Remove) == "function" then
            drawing:Remove()
        end
    end
    drawings = {}
end

DrawingLib.remove = function(drawing)
    for i, draw in ipairs(drawings) do
        if draw == drawing then
            if draw and typeof(draw.Remove) == "function" then
                draw:Remove()
            end
            table.remove(drawings, i)
            break
        end
    end
end

DrawingLib.getMousePos = function()
    return UserInputService:GetMouseLocation()
end

DrawingLib.getViewportSize = function()
    return Workspace.CurrentCamera.ViewportSize
end

DrawingLib.worldToScreen = function(position)
    return Workspace.CurrentCamera:WorldToViewportPoint(position)
end

DrawingLib.screenToWorld = function(position)
    return Workspace.CurrentCamera:ViewportPointToRay(position)
end

DrawingLib.isVisible = function(position)
    local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(position)
    return onScreen
end

DrawingLib.onRender = function(callback)
    if renderConnection then
        renderConnection:Disconnect()
    end
    renderConnection = RunService.RenderStepped:Connect(callback)
end

DrawingLib.stopRender = function()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

DrawingLib.FOV = function(radius, color, thickness, visible)
    local circle = DrawingLib.new("Circle")
    circle.Position = DrawingLib.getMousePos()
    circle.Radius = radius
    circle.Color = color or Color3.fromRGB(255, 255, 255)
    circle.Thickness = thickness or 1
    circle.Filled = false
    circle.Visible = visible ~= false
    return circle
end

DrawingLib.Skeleton = function(character, color, thickness, visible)
    local skeleton = {}
    if character and character:FindFirstChild("HumanoidRootPart") then
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        local hrp = character.HumanoidRootPart
        if head and torso then
            table.insert(skeleton, DrawingLib.Line(torso.Position, head.Position, color, thickness, visible))
        end
        if hrp and torso then
            table.insert(skeleton, DrawingLib.Line(hrp.Position, torso.Position, color, thickness, visible))
        end
        local leftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
        local rightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
        local leftLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg")
        local rightLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
        if leftArm and torso then
            table.insert(skeleton, DrawingLib.Line(torso.Position, leftArm.Position, color, thickness, visible))
        end
        if rightArm and torso then
            table.insert(skeleton, DrawingLib.Line(torso.Position, rightArm.Position, color, thickness, visible))
        end
        if leftLeg and hrp then
            table.insert(skeleton, DrawingLib.Line(hrp.Position, leftLeg.Position, color, thickness, visible))
        end
        if rightLeg and hrp then
            table.insert(skeleton, DrawingLib.Line(hrp.Position, rightLeg.Position, color, thickness, visible))
        end
    end
    return skeleton
end

DrawingLib.Tracer = function(target, color, thickness, visible)
    local tracer = {}
    if target and target:FindFirstChild("HumanoidRootPart") then
        local hrp = target.HumanoidRootPart
        local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local mousePos = DrawingLib.getMousePos()
            table.insert(tracer, DrawingLib.Line(mousePos, Vector2.new(screenPos.x, screenPos.y), color, thickness, visible))
        end
    end
    return tracer
end

DrawingLib.Box = function(target, color, thickness, visible)
    local box = {}
    if target and target:FindFirstChild("HumanoidRootPart") then
        local hrp = target.HumanoidRootPart
        local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local size = Vector2.new(4, 4)
            local p1 = Vector2.new(screenPos.x - size.x, screenPos.y - size.y)
            local p2 = Vector2.new(screenPos.x + size.x, screenPos.y - size.y)
            local p3 = Vector2.new(screenPos.x + size.x, screenPos.y + size.y)
            local p4 = Vector2.new(screenPos.x - size.x, screenPos.y + size.y)
            table.insert(box, DrawingLib.Line(p1, p2, color, thickness, visible))
            table.insert(box, DrawingLib.Line(p2, p3, color, thickness, visible))
            table.insert(box, DrawingLib.Line(p3, p4, color, thickness, visible))
            table.insert(box, DrawingLib.Line(p4, p1, color, thickness, visible))
        end
    end
    return box
end

DrawingLib.HeadDot = function(target, color, radius, visible)
    local dot = {}
    if target and target:FindFirstChild("Head") then
        local head = target.Head
        local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
        if onScreen then
            table.insert(dot, DrawingLib.Circle(Vector2.new(screenPos.x, screenPos.y), radius, color, 1, true, visible))
        end
    end
    return dot
end

DrawingLib.HealthBar = function(target, visible)
    local healthbar = {}
    if target and target:FindFirstChild("Humanoid") and target:FindFirstChild("HumanoidRootPart") then
        local hum = target.Humanoid
        local hrp = target.HumanoidRootPart
        local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local health = hum.Health
            local maxHealth = hum.MaxHealth
            local healthPercent = health / maxHealth
            local barWidth = 50
            local barHeight = 4
            local x = screenPos.x - barWidth / 2
            local y = screenPos.y + 30
            local bg = DrawingLib.Square(Vector2.new(x, y), Vector2.new(barWidth, barHeight), Color3.fromRGB(0, 0, 0), 1, true, visible)
            local fg = DrawingLib.Square(Vector2.new(x, y), Vector2.new(barWidth * healthPercent, barHeight), Color3.fromRGB(0, 255, 0), 1, true, visible)
            table.insert(healthbar, bg)
            table.insert(healthbar, fg)
        end
    end
    return healthbar
end

DrawingLib.chams = function(target, color, transparency, visible)
    local chams = {}
    if target and target:FindFirstChild("HumanoidRootPart") then
        for _, part in ipairs(target:GetChildren()) do
            if part:IsA("BasePart") then
                local originalColor = part.Color
                local originalTransparency = part.Transparency
                part.Color = color
                part.Transparency = transparency or 0.5
                table.insert(chams, {
                    part = part,
                    originalColor = originalColor,
                    originalTransparency = originalTransparency
                })
            end
        end
    end
    return chams
end

DrawingLib.removeChams = function(chams)
    for _, data in ipairs(chams) do
        if data.part and data.part.Parent then
            data.part.Color = data.originalColor
            data.part.Transparency = data.originalTransparency
        end
    end
end

return DrawingLib
