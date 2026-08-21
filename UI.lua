local Cloneref = (cloneref or clonereference or function(Instance) return Instance end)
local GetHui = (gethui or function() return Cloneref(game:GetService("CoreGui")) end)
local ProtectGui = (protectgui or (syn and syn.protect_gui) or function() end)

local CoreGui = Cloneref(game:GetService("CoreGui"))
local Players = Cloneref(game:GetService("Players"))
local TweenService = Cloneref(game:GetService("TweenService"))
local UserInputService = Cloneref(game:GetService("UserInputService"))
local RunService = Cloneref(game:GetService("RunService"))
local TextService = Cloneref(game:GetService("TextService"))
local HttpService = Cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local SwiftUI = {
    Opened = true,
    Unloaded = false,
    Windows = {},
    Options = {},
    Toggles = {},
    Theme = {},
    Registry = {},
    Signals = {},
    Notifications = {},
    ToggleKeybind = Enum.KeyCode.RightShift,
}

SwiftUI.Theme = {
    Background = Color3.fromRGB(10, 10, 12),
    Main = Color3.fromRGB(14, 14, 16),
    Sidebar = Color3.fromRGB(12, 12, 14),
    Element = Color3.fromRGB(22, 22, 26),
    ElementHover = Color3.fromRGB(30, 30, 34),
    Outline = Color3.fromRGB(48, 48, 52),
    OutlineLight = Color3.fromRGB(62, 62, 66),
    Accent = Color3.fromRGB(124, 92, 255),
    AccentHover = Color3.fromRGB(138, 110, 255),
    Font = Color3.fromRGB(240, 240, 240),
    FontDim = Color3.fromRGB(165, 165, 170),
    FontDark = Color3.fromRGB(110, 110, 115),
    Success = Color3.fromRGB(46, 204, 113),
    Warning = Color3.fromRGB(241, 196, 15),
    Danger = Color3.fromRGB(231, 76, 60),
    Shadow = Color3.fromRGB(0, 0, 0),
}

SwiftUI.Font = Font.fromEnum(Enum.Font.GothamMedium)
SwiftUI.FontBold = Font.fromEnum(Enum.Font.GothamBold)
SwiftUI.FontCode = Font.fromEnum(Enum.Font.Code)

local TweenInfoFast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenInfoMedium = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenInfoSlow = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function SwiftUI:Create(ClassName, Properties)
    local Instance = Instance.new(ClassName)
    for Property, Value in pairs(Properties) do
        if Property ~= "Parent" then
            pcall(function()
                Instance[Property] = Value
            end)
        end
    end
    if Properties.Parent then
        Instance.Parent = Properties.Parent
    end
    return Instance
end

function SwiftUI:ApplyCorner(Instance, Radius)
    return self:Create("UICorner", {
        CornerRadius = UDim.new(0, Radius or 0),
        Parent = Instance,
    })
end

function SwiftUI:ApplyStroke(Instance, Color, Thickness)
    return self:Create("UIStroke", {
        Color = Color or self.Theme.Outline,
        Thickness = Thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Instance,
    })
end

function SwiftUI:ApplyPadding(Instance, Padding)
    return self:Create("UIPadding", {
        PaddingTop = UDim.new(0, Padding),
        PaddingBottom = UDim.new(0, Padding),
        PaddingLeft = UDim.new(0, Padding),
        PaddingRight = UDim.new(0, Padding),
        Parent = Instance,
    })
end

function SwiftUI:Tween(Instance, Properties, Info)
    local Tween = TweenService:Create(Instance, Info or TweenInfoFast, Properties)
    Tween:Play()
    return Tween
end

function SwiftUI:GetTextBounds(Text, Size, Font, Width)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.Size = Size or 14
    Params.Font = Font or self.Font
    Params.Width = Width or 1000
    local Bounds = TextService:GetTextBoundsAsync(Params)
    return Bounds
end

function SwiftUI:SafeCallback(Callback, ...)
    if typeof(Callback) ~= "function" then return end
    local Success, Result = pcall(Callback, ...)
    if not Success then
        warn("[SwiftUI] Callback error: " .. tostring(Result))
        self:Notify({
            Title = "Callback Error",
            Description = tostring(Result),
            Time = 4,
        })
    end
    return Success
end

function SwiftUI:GiveSignal(Connection)
    table.insert(self.Signals, Connection)
    return Connection
end

function SwiftUI:MakeDraggable(DragHandle, MainFrame)
    local Dragging = false
    local DragStart, StartPos

    local InputBegan = DragHandle.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = Input.Position
            StartPos = MainFrame.Position
            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    local InputChanged = UserInputService.InputChanged:Connect(function(Input)
        if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            local Delta = Input.Position - DragStart
            MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)

    self:GiveSignal(InputBegan)
    self:GiveSignal(InputChanged)
end

function SwiftUI:HookHover(Instance, OnEnter, OnLeave)
    Instance.MouseEnter:Connect(OnEnter)
    Instance.MouseLeave:Connect(OnLeave)
end

local ScreenGui = SwiftUI:Create("ScreenGui", {
    Name = "SwiftUI",
    DisplayOrder = 999,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
})
pcall(ProtectGui, ScreenGui)
do
    local Success = pcall(function()
        ScreenGui.Parent = GetHui()
    end)
    if not Success then
        ScreenGui.Parent = CoreGui
        if not ScreenGui.Parent then
            ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end
end
SwiftUI.ScreenGui = ScreenGui

local NotificationHolder = SwiftUI:Create("Frame", {
    Name = "Notifications",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -14, 1, -14),
    Size = UDim2.new(0, 300, 1, -28),
    Parent = ScreenGui,
})
SwiftUI:Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = NotificationHolder,
})

function SwiftUI:Notify(Config)
    Config = Config or {}
    local Title = Config.Title or "Swift"
    local Description = Config.Description or Config.Text or ""
    local Time = Config.Time or 3

    local Frame = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Main,
        Size = UDim2.new(1, 0, 0, 64),
        Parent = NotificationHolder,
    })
    self:ApplyCorner(Frame, 0)
    self:ApplyStroke(Frame, self.Theme.Outline, 1)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Frame,
    })

    local Accent = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Accent,
        Size = UDim2.new(0, 3, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        Parent = Frame,
    })
    self:ApplyCorner(Accent, 0)

    local TitleLabel = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = Title,
        FontFace = self.FontBold,
        TextSize = 13,
        TextColor3 = self.Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 16),
        Parent = Frame,
    })
    local DescLabel = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = Description,
        FontFace = self.Font,
        TextSize = 12,
        TextColor3 = self.Theme.FontDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 18),
        Parent = Frame,
    })

    Frame.Size = UDim2.new(1, 0, 0, Description ~= "" and 64 or 40)
    Frame.BackgroundTransparency = 1
    TitleLabel.TextTransparency = 1
    DescLabel.TextTransparency = 1
    Accent.BackgroundTransparency = 1

    self:Tween(Frame, {BackgroundTransparency = 0}, TweenInfoMedium)
    self:Tween(TitleLabel, {TextTransparency = 0}, TweenInfoMedium)
    self:Tween(DescLabel, {TextTransparency = 0}, TweenInfoMedium)
    self:Tween(Accent, {BackgroundTransparency = 0}, TweenInfoMedium)

    task.delay(Time, function()
        self:Tween(Frame, {BackgroundTransparency = 1}, TweenInfoMedium)
        self:Tween(TitleLabel, {TextTransparency = 1}, TweenInfoMedium)
        self:Tween(DescLabel, {TextTransparency = 1}, TweenInfoMedium)
        task.wait(0.25)
        if Frame.Parent then Frame:Destroy() end
    end)
end

function SwiftUI:CreateWindow(Config)
    Config = Config or {}
    local Title = Config.Title or "Swift UI"
    local Footer = Config.Footer or "Swift"
    local Size = Config.Size or UDim2.fromOffset(620, 520)
    local Center = Config.Center
    if Center == nil then Center = true end
    local ToggleKeybind = Config.ToggleKeybind or self.ToggleKeybind

    local Container = self:Create("Frame", {
        Name = "WindowContainer",
        BackgroundTransparency = 1,
        Size = Size,
        Position = Center and UDim2.fromScale(0.5, 0.5) or UDim2.fromOffset(100, 100),
        AnchorPoint = Center and Vector2.new(0.5, 0.5) or Vector2.new(0, 0),
        Parent = ScreenGui,
    })

    local Shadow = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Shadow,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 10, 1, 10),
        Position = UDim2.new(0, -5, 0, -5),
        ZIndex = 0,
        Parent = Container,
    })
    self:ApplyCorner(Shadow, 0)

    local Main = self:Create("Frame", {
        Name = "Main",
        BackgroundColor3 = self.Theme.Main,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 1,
        Parent = Container,
    })
    self:ApplyCorner(Main, 0)
    self:ApplyStroke(Main, Color3.fromRGB(0, 0, 0), 2)
    self:ApplyStroke(Main, self.Theme.Outline, 1)

    local Titlebar = self:Create("Frame", {
        Name = "Titlebar",
        BackgroundColor3 = self.Theme.Sidebar,
        Size = UDim2.new(1, 0, 0, 44),
        ZIndex = 2,
        Parent = Main,
    })
    self:Create("Frame", {
        BackgroundColor3 = self.Theme.Outline,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = Titlebar,
    })

    local TitleLabel = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = Title,
        FontFace = self.FontBold,
        TextSize = 14,
        TextColor3 = self.Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        ZIndex = 2,
        Parent = Titlebar,
    })

    local FooterLabel = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = Footer,
        FontFace = self.Font,
        TextSize = 11,
        TextColor3 = self.Theme.FontDark,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 14, 0, 18),
        Size = UDim2.new(1, -100, 0, 14),
        ZIndex = 2,
        Visible = Footer ~= "",
        Parent = Titlebar,
    })
    if Footer == "" then
        TitleLabel.Position = UDim2.new(0, 14, 0, 0)
    else
        TitleLabel.Position = UDim2.new(0, 14, 0, -6)
        TitleLabel.AnchorPoint = Vector2.new(0, 0)
        TitleLabel.Size = UDim2.new(1, -100, 0, 16)
        TitleLabel.Position = UDim2.new(0, 14, 0, 6)
    end

    local Controls = self:Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(56, 28),
        ZIndex = 3,
        Parent = Titlebar,
    })
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = Controls,
    })

    local function CreateControlButton(Text, HoverColor)
        local Btn = self:Create("TextButton", {
            BackgroundColor3 = self.Theme.Element,
            Text = Text,
            FontFace = self.FontBold,
            TextSize = 14,
            TextColor3 = self.Theme.FontDim,
            Size = UDim2.fromOffset(26, 22),
            AutoButtonColor = false,
            ZIndex = 3,
            Parent = Controls,
        })
        self:ApplyCorner(Btn, 0)
        self:ApplyStroke(Btn, self.Theme.Outline, 1)
        self:HookHover(Btn, function()
            self:Tween(Btn, {BackgroundColor3 = HoverColor or self.Theme.ElementHover}, TweenInfoFast)
        end, function()
            self:Tween(Btn, {BackgroundColor3 = self.Theme.Element}, TweenInfoFast)
        end)
        return Btn
    end

    local MinimizeButton = CreateControlButton("–", self.Theme.ElementHover)
    local CloseButton = CreateControlButton("×", Color3.fromRGB(60, 28, 32))

    local Body = self:Create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        ZIndex = 1,
        Parent = Main,
    })

    local Sidebar = self:Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = self.Theme.Sidebar,
        Size = UDim2.new(0, 148, 1, 0),
        ZIndex = 1,
        Parent = Body,
    })
    self:Create("Frame", {
        BackgroundColor3 = self.Theme.Outline,
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        Parent = Sidebar,
    })
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 12),
        Parent = Sidebar,
    })
    local TabList = self:Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Sidebar,
    })
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabList,
    })

    local Content = self:Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 148, 0, 0),
        Size = UDim2.new(1, -148, 1, 0),
        Parent = Body,
    })

    local ResizeHandle = self:Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.fromOffset(18, 18),
        ZIndex = 10,
        Parent = Main,
    })
    local ResizeIcon = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = "⤡",
        FontFace = self.Font,
        TextSize = 12,
        TextColor3 = self.Theme.FontDark,
        Size = UDim2.fromScale(1, 1),
        Parent = ResizeHandle,
    })

    self:MakeDraggable(Titlebar, Container)

    do
        local Resizing = false
        local StartPos, StartSize
        ResizeHandle.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Resizing = true
                StartPos = Input.Position
                StartSize = Container.AbsoluteSize
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Resizing = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(Input)
            if Resizing and Input.UserInputType == Enum.UserInputType.MouseMovement then
                local Delta = Input.Position - StartPos
                local NewX = math.clamp(StartSize.X + Delta.X, 520, 900)
                local NewY = math.clamp(StartSize.Y + Delta.Y, 360, 700)
                Container.Size = UDim2.fromOffset(NewX, NewY)
            end
        end)
    end

    local Window = {
        Container = Container,
        Main = Main,
        Titlebar = Titlebar,
        Sidebar = Sidebar,
        Content = Content,
        TabList = TabList,
        Tabs = {},
        ActiveTab = nil,
        Title = Title,
        Visible = true,
    }

    function Window:Toggle()
        Window.Visible = not Window.Visible
        Container.Visible = Window.Visible
        if Window.Visible then
            SwiftUI:Tween(Container, {BackgroundTransparency = 1}, TweenInfoFast)
            Main.Visible = true
        end
    end

    function Window:SetTitle(NewTitle)
        TitleLabel.Text = NewTitle
    end

    function Window:Destroy()
        Container:Destroy()
        SwiftUI.Unloaded = true
    end

    local ToggleConnection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if GameProcessed then return end
        if Input.KeyCode == ToggleKeybind then
            Window:Toggle()
        end
    end)
    SwiftUI:GiveSignal(ToggleConnection)

    CloseButton.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)
    MinimizeButton.MouseButton1Click:Connect(function()
        Window:Toggle()
        task.delay(0.15, function()
            if not Window.Visible then
                SwiftUI:Notify({Title = "Swift UI", Description = "Press " .. ToggleKeybind.Name .. " to show again", Time = 3})
            end
        end)
    end)

    function Window:AddTab(Name, Icon)
        local TabButton = SwiftUI:Create("TextButton", {
            BackgroundColor3 = SwiftUI.Theme.Element,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 34),
            Parent = TabList,
        })
        SwiftUI:ApplyCorner(TabButton, 0)

        local TabIcon = SwiftUI:Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = Icon or "•",
            FontFace = SwiftUI.FontBold,
            TextSize = 12,
            TextColor3 = SwiftUI.Theme.FontDim,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromOffset(22, 22),
            Position = UDim2.new(0, 6, 0.5, -11),
            Parent = TabButton,
        })
        local TabLabel = SwiftUI:Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = Name,
            FontFace = SwiftUI.Font,
            TextSize = 13,
            TextColor3 = SwiftUI.Theme.FontDim,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 30, 0, 0),
            Size = UDim2.new(1, -36, 1, 0),
            Parent = TabButton,
        })

        local TabPage = SwiftUI:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 0,
            ScrollBarImageColor3 = SwiftUI.Theme.OutlineLight,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
            Visible = false,
            Parent = Content,
        })
        SwiftUI:Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = TabPage,
        })
        local LeftColumn = SwiftUI:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -5, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Parent = TabPage,
        })
        local RightColumn = SwiftUI:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -5, 1, 0),
            Position = UDim2.new(0.5, 5, 0, 0),
            Parent = TabPage,
        })
        for _, Col in ipairs({LeftColumn, RightColumn}) do
            SwiftUI:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Col,
            })
        end

        local function UpdateCanvas()
            local LeftSize = 0
            local RightSize = 0
            for _, Child in ipairs(LeftColumn:GetChildren()) do
                if Child:IsA("Frame") and Child.Visible then
                    LeftSize = LeftSize + Child.AbsoluteSize.Y + 8
                end
            end
            for _, Child in ipairs(RightColumn:GetChildren()) do
                if Child:IsA("Frame") and Child.Visible then
                    RightSize = RightSize + Child.AbsoluteSize.Y + 8
                end
            end
            local Max = math.max(LeftSize, RightSize) + 20
            TabPage.CanvasSize = UDim2.new(0, 0, 0, Max)
        end
        LeftColumn.ChildAdded:Connect(function() task.defer(UpdateCanvas) end)
        RightColumn.ChildAdded:Connect(function() task.defer(UpdateCanvas) end)
        RunService.RenderStepped:Connect(UpdateCanvas)

        local Tab = {
            Name = Name,
            Button = TabButton,
            Page = TabPage,
            Left = LeftColumn,
            Right = RightColumn,
            Groupboxes = {},
        }

        function Tab:Show()
            for _, T in ipairs(Window.Tabs) do
                T.Page.Visible = false
                T.Button.BackgroundTransparency = 1
                T.Button:FindFirstChildOfClass("TextLabel").TextColor3 = SwiftUI.Theme.FontDim
                for _, Label in ipairs(T.Button:GetChildren()) do
                    if Label:IsA("TextLabel") then
                        Label.TextColor3 = SwiftUI.Theme.FontDim
                    end
                end
            end
            TabPage.Visible = true
            TabButton.BackgroundTransparency = 0
            TabButton.BackgroundColor3 = SwiftUI.Theme.Element
            TabLabel.TextColor3 = SwiftUI.Theme.Font
            TabIcon.TextColor3 = SwiftUI.Theme.Accent
            Window.ActiveTab = Tab
            UpdateCanvas()
        end

        TabButton.MouseButton1Click:Connect(function()
            Tab:Show()
        end)
        SwiftUI:HookHover(TabButton, function()
            if Window.ActiveTab ~= Tab then
                SwiftUI:Tween(TabButton, {BackgroundTransparency = 0.5}, TweenInfoFast)
                TabButton.BackgroundColor3 = SwiftUI.Theme.Element
            end
        end, function()
            if Window.ActiveTab ~= Tab then
                SwiftUI:Tween(TabButton, {BackgroundTransparency = 1}, TweenInfoFast)
            end
        end)

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then
            Tab:Show()
        end

        local function CreateGroupbox(ParentColumn, Name)
            local Box = SwiftUI:Create("Frame", {
                BackgroundColor3 = SwiftUI.Theme.Main,
                Size = UDim2.new(1, 0, 0, 40),
                Parent = ParentColumn,
            })
            SwiftUI:ApplyCorner(Box, 0)
            SwiftUI:ApplyStroke(Box, Color3.fromRGB(0, 0, 0), 2)
            SwiftUI:ApplyStroke(Box, SwiftUI.Theme.Outline, 1)
            SwiftUI:Create("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box,
            })
            local TitleLbl = SwiftUI:Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = Name:upper(),
                FontFace = SwiftUI.FontBold,
                TextSize = 11,
                TextColor3 = SwiftUI.Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 14),
                LayoutOrder = 0,
                Parent = Box,
            })
            local Line = SwiftUI:Create("Frame", {
                BackgroundColor3 = SwiftUI.Theme.Outline,
                Size = UDim2.new(1, 0, 0, 1),
                LayoutOrder = 1,
                Parent = Box,
            })
            local ContainerFrame = SwiftUI:Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                LayoutOrder = 2,
                Parent = Box,
            })
            SwiftUI:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = ContainerFrame,
            })
            SwiftUI:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Box,
            })

            local Groupbox = {
                Box = Box,
                Container = ContainerFrame,
                Elements = {},
            }

            local function AutoResize()
                local Y = 14 + 1 + 8 + 8
                for _, Child in ipairs(ContainerFrame:GetChildren()) do
                    if Child:IsA("GuiObject") and Child.Visible and not Child:IsA("UIListLayout") then
                        Y = Y + Child.AbsoluteSize.Y + 6
                    end
                end
                local ContentSize = 0
                for _, Child in ipairs(ContainerFrame:GetChildren()) do
                    if Child:IsA("GuiObject") and Child.Visible and not Child:IsA("UIListLayout") then
                        ContentSize = ContentSize + Child.AbsoluteSize.Y + 6
                    end
                end
                Box.Size = UDim2.new(1, 0, 0, 28 + ContentSize + 12)
                task.defer(UpdateCanvas)
            end
            ContainerFrame.ChildAdded:Connect(function() task.defer(AutoResize) end)
            ContainerFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(AutoResize)
            RunService.RenderStepped:Connect(AutoResize)

            function Groupbox:Resize()
                AutoResize()
            end

            function Groupbox:AddLabel(Text, Wrap)
                local Label = SwiftUI:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = Text,
                    FontFace = SwiftUI.Font,
                    TextSize = 12,
                    TextColor3 = SwiftUI.Theme.FontDim,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = Wrap or true,
                    Size = UDim2.new(1, 0, 0, 16),
                    Parent = ContainerFrame,
                })
                local Bounds = SwiftUI:GetTextBounds(Text, 12, SwiftUI.Font, ContainerFrame.AbsoluteSize.X - 10)
                Label.Size = UDim2.new(1, 0, 0, math.clamp(Bounds.Y + 2, 16, 80))
                local Api = {}
                function Api:SetText(NewText)
                    Label.Text = NewText
                    local B = SwiftUI:GetTextBounds(NewText, 12, SwiftUI.Font, ContainerFrame.AbsoluteSize.X - 10)
                    Label.Size = UDim2.new(1, 0, 0, math.clamp(B.Y + 2, 16, 80))
                    AutoResize()
                end
                table.insert(Groupbox.Elements, {Type = "Label", Holder = Label})
                task.defer(AutoResize)
                return Api
            end

            function Groupbox:AddDivider()
                local Div = SwiftUI:Create("Frame", {
                    BackgroundColor3 = SwiftUI.Theme.Outline,
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = ContainerFrame,
                })
                table.insert(Groupbox.Elements, {Type = "Divider", Holder = Div})
                task.defer(AutoResize)
                return Div
            end

            function Groupbox:AddButton(Config)
                Config = Config or {}
                local Text = Config.Text or "Button"
                local Callback = Config.Callback or Config.Func or function() end

                local Btn = SwiftUI:Create("TextButton", {
                    BackgroundColor3 = SwiftUI.Theme.Element,
                    Text = Text,
                    FontFace = SwiftUI.Font,
                    TextSize = 13,
                    TextColor3 = SwiftUI.Theme.Font,
                    Size = UDim2.new(1, 0, 0, 30),
                    AutoButtonColor = false,
                    Parent = ContainerFrame,
                })
                SwiftUI:ApplyCorner(Btn, 0)
                SwiftUI:ApplyStroke(Btn, SwiftUI.Theme.Outline, 1)

                SwiftUI:HookHover(Btn, function()
                    SwiftUI:Tween(Btn, {BackgroundColor3 = SwiftUI.Theme.ElementHover}, TweenInfoFast)
                end, function()
                    SwiftUI:Tween(Btn, {BackgroundColor3 = SwiftUI.Theme.Element}, TweenInfoFast)
                end)

                Btn.MouseButton1Click:Connect(function()
                    SwiftUI:SafeCallback(Callback)
                    SwiftUI:Tween(Btn, {BackgroundColor3 = SwiftUI.Theme.Accent}, TweenInfoFast)
                    task.wait(0.08)
                    SwiftUI:Tween(Btn, {BackgroundColor3 = SwiftUI.Theme.ElementHover}, TweenInfoFast)
                end)

                local Api = {}
                function Api:SetText(NewText) Btn.Text = NewText end
                function Api:SetDisabled(Disabled)
                    Btn.AutoButtonColor = not Disabled
                    Btn.Active = not Disabled
                    Btn.TextTransparency = Disabled and 0.5 or 0
                end
                table.insert(Groupbox.Elements, {Type = "Button", Holder = Btn, Text = Text})
                task.defer(AutoResize)
                return Api
            end

            function Groupbox:AddToggle(Id, Config)
                if typeof(Id) == "table" then Config = Id; Id = Config.Text or "Toggle" end
                Config = Config or {}
                local Text = Config.Text or Id or "Toggle"
                local Default = Config.Default
                if Default == nil then Default = false end
                local Callback = Config.Callback or Config.Changed or function() end
                local Risky = Config.Risky or false

                local Holder = SwiftUI:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    Parent = ContainerFrame,
                })
                local Label = SwiftUI:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = Text,
                    FontFace = SwiftUI.Font,
                    TextSize = 12,
                    TextColor3 = Risky and SwiftUI.Theme.Danger or SwiftUI.Theme.FontDim,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, -50, 1, 0),
                    Parent = Holder,
                })
                local Track = SwiftUI:Create("Frame", {
                    BackgroundColor3 = SwiftUI.Theme.Element,
                    Size = UDim2.fromOffset(40, 20),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Parent = Holder,
                })
                SwiftUI:ApplyCorner(Track, 10)
                SwiftUI:ApplyStroke(Track, SwiftUI.Theme.Outline, 1)
                local Thumb = SwiftUI:Create("Frame", {
                    BackgroundColor3 = SwiftUI.Theme.FontDark,
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.new(0, 3, 0.5, -7),
                    Parent = Track,
                })
                SwiftUI:ApplyCorner(Thumb, 7)

                local Toggle = {
                    Value = Default,
                    Type = "Toggle",
                    Text = Text,
                }

                local function UpdateVisual(Value)
                    if Value then
                        SwiftUI:Tween(Track, {BackgroundColor3 = SwiftUI.Theme.Accent}, TweenInfoMedium)
                        SwiftUI:Tween(Thumb, {BackgroundColor3 = Color3.new(1,1,1), Position = UDim2.new(1, -17, 0.5, -7)}, TweenInfoMedium)
                    else
                        SwiftUI:Tween(Track, {BackgroundColor3 = SwiftUI.Theme.Element}, TweenInfoMedium)
                        SwiftUI:Tween(Thumb, {BackgroundColor3 = SwiftUI.Theme.FontDark, Position = UDim2.new(0, 3, 0.5, -7)}, TweenInfoMedium)
                    end
                end
                UpdateVisual(Default)

                function Toggle:SetValue(Value)
                    Toggle.Value = Value
                    UpdateVisual(Value)
                    SwiftUI:SafeCallback(Callback, Value)
                    if Id then
                        SwiftUI.Options[Id] = Toggle
                        SwiftUI.Toggles[Id] = Toggle
                    end
                end

                function Toggle:OnChanged(Func)
                    Callback = Func
                end

                local Button = SwiftUI:Create("TextButton", {
                    BackgroundTransparency = 1,
                    Text = "",
                    Size = UDim2.fromScale(1,1),
                    ZIndex = 2,
                    Parent = Holder,
                })
                Button.MouseButton1Click:Connect(function()
                    Toggle:SetValue(not Toggle.Value)
                end)

                if Id then
                    SwiftUI.Options[Id] = Toggle
                    SwiftUI.Toggles[Id] = Toggle
                end

                table.insert(Groupbox.Elements, {Type = "Toggle", Holder = Holder, Text = Text, Visible = true})
                task.defer(AutoResize)
                return Toggle
            end

            function Groupbox:AddSlider(Id, Config)
                if typeof(Id) == "table" then Config = Id; Id = Config.Text or "Slider" end
                Config = Config or {}
                local Text = Config.Text or Id or "Slider"
                local Min = Config.Min or 0
                local Max = Config.Max or 100
                local Default = Config.Default or Min
                local Rounding = Config.Rounding or 0
                local Suffix = Config.Suffix or Config.Prefix or ""
                local Prefix = Config.Prefix or ""
                if Config.Suffix and Config.Prefix == nil then Prefix = "" end
                local Callback = Config.Callback or Config.Changed or function() end

                local Holder = SwiftUI:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 44),
                    Parent = ContainerFrame,
                })
                local Top = SwiftUI:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Parent = Holder,
                })
                SwiftUI:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = Text,
                    FontFace = SwiftUI.Font,
                    TextSize = 12,
                    TextColor3 = SwiftUI.Theme.FontDim,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, -60, 1, 0),
                    Parent = Top,
                })
                local ValueLabel = SwiftUI:Create("TextLabel", {
                    BackgroundColor3 = SwiftUI.Theme.Element,
                    Text = tostring(Default) .. Suffix,
                    FontFace = SwiftUI.FontCode,
                    TextSize = 11,
                    TextColor3 = SwiftUI.Theme.Font,
                    Size = UDim2.fromOffset(56, 16),
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Parent = Top,
                })
                SwiftUI:ApplyCorner(ValueLabel, 0)
                SwiftUI:ApplyStroke(ValueLabel, SwiftUI.Theme.Outline, 1)

                local Track = SwiftUI:Create("Frame", {
                    BackgroundColor3 = SwiftUI.Theme.Element,
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 26),
                    Parent = Holder,
                })
                SwiftUI:ApplyCorner(Track, 0)
                SwiftUI:ApplyStroke(Track, SwiftUI.Theme.Outline, 1)
                local Fill = SwiftUI:Create("Frame", {
                    BackgroundColor3 = SwiftUI.Theme.Accent,
                    Size = UDim2.new(0, 0, 1, 0),
                    Parent = Track,
                })
                SwiftUI:ApplyCorner(Fill, 0)
                local Thumb = SwiftUI:Create("Frame", {
                    BackgroundColor3 = Color3.new(1,1,1),
                    Size = UDim2.fromOffset(12, 12),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Parent = Track,
                })
                SwiftUI:ApplyCorner(Thumb, 6)
                SwiftUI:ApplyStroke(Thumb, SwiftUI.Theme.Outline, 1)

                local Slider = {Value = Default, Type = "Slider", Text = Text}

                local function RoundValue(Value)
                    if Rounding == 0 then return math.floor(Value) end
                    local Mult = 10 ^ Rounding
                    return math.floor(Value * Mult + 0.5) / Mult
                end

                local function UpdateVisual(Value, Animate)
                    local Alpha = math.clamp((Value - Min) / (Max - Min), 0, 1)
                    local Goal = {Size = UDim2.new(Alpha, 0, 1, 0)}
                    if Animate then
                        SwiftUI:Tween(Fill, Goal, TweenInfoFast)
                        SwiftUI:Tween(Thumb, {Position = UDim2.new(Alpha, 0, 0.5, 0)}, TweenInfoFast)
                    else
                        Fill.Size = Goal.Size
                        Thumb.Position = UDim2.new(Alpha, 0, 0.5, 0)
                    end
                    ValueLabel.Text = tostring(Prefix .. tostring(Value) .. Suffix)
                end
                UpdateVisual(Default, false)

                function Slider:SetValue(Value)
                    Value = math.clamp(RoundValue(Value), Min, Max)
                    Slider.Value = Value
                    UpdateVisual(Value, true)
                    SwiftUI:SafeCallback(Callback, Value)
                    if Id then SwiftUI.Options[Id] = Slider end
                end
                function Slider:OnChanged(Func) Callback = Func end

                local Dragging = false
                local function UpdateFromInput(Input)
                    local Pos = Input.Position.X
                    local AbsPos = Track.AbsolutePosition.X
                    local AbsSize = Track.AbsoluteSize.X
                    local Alpha = math.clamp((Pos - AbsPos) / AbsSize, 0, 1)
                    local Value = Min + (Max - Min) * Alpha
                    Slider:SetValue(Value)
                end

                Track.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
                        UpdateFromInput(Input)
                    end
                end)
                Thumb.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(Input)
                    if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateFromInput(Input)
                    end
                end)

                if Id then SwiftUI.Options[Id] = Slider end
                table.insert(Groupbox.Elements, {Type = "Slider", Holder = Holder, Text = Text})
                task.defer(AutoResize)
                return Slider
            end

            function Groupbox:AddDropdown(Id, Config)
                if typeof(Id) == "table" then Config = Id; Id = Config.Text or "Dropdown" end
                Config = Config or {}
                local Text = Config.Text or Id or "Dropdown"
                local Values = Config.Values or {}
                local Default = Config.Default or Config.Value or Values[1]
                local Multi = Config.Multi or false
                local Callback = Config.Callback or Config.Changed or function() end

                local Holder = SwiftUI:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 44),
                    Parent = ContainerFrame,
                })
                SwiftUI:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = Text,
                    FontFace = SwiftUI.Font,
                    TextSize = 12,
                    TextColor3 = SwiftUI.Theme.FontDim,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 16),
                    Parent = Holder,
                })
                local Button = SwiftUI:Create("TextButton", {
                    BackgroundColor3 = SwiftUI.Theme.Element,
                    Text = "",
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.new(0, 0, 0, 18),
                    AutoButtonColor = false,
                    Parent = Holder,
                })
                SwiftUI:ApplyCorner(Button, 0)
                SwiftUI:ApplyStroke(Button, SwiftUI.Theme.Outline, 1)
                local SelectedLabel = SwiftUI:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = Multi and (type(Default) == "table" and table.concat(Default, ", ") or "None") or tostring(Default or "None"),
                    FontFace = SwiftUI.Font,
                    TextSize = 12,
                    TextColor3 = SwiftUI.Theme.Font,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Size = UDim2.new(1, -24, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    Parent = Button,
                })
                local Arrow = SwiftUI:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = ">",
                    FontFace = SwiftUI.FontBold,
                    TextSize = 13,
                    TextColor3 = SwiftUI.Theme.FontDim,
                    Size = UDim2.fromOffset(14, 14),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -6, 0.5, 0),
                    Rotation = 90,
                    Parent = Button,
                })

                local ListFrame = SwiftUI:Create("ScrollingFrame", {
                    BackgroundColor3 = SwiftUI.Theme.Element,
                    Size = UDim2.new(0, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 44),
                    Visible = false,
                    ZIndex = 20,
                    CanvasSize = UDim2.new(0,0,0,0),
                    ScrollBarThickness = 2,
                    Parent = Holder,
                })
                SwiftUI:ApplyCorner(ListFrame, 0)
                SwiftUI:ApplyStroke(ListFrame, SwiftUI.Theme.Outline, 1)
                SwiftUI:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding = UDim.new(0, 2),
                    Parent = ListFrame,
                })
                SwiftUI:Create("UIPadding", {
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                    Parent = ListFrame,
                })

                local Dropdown = {
                    Value = Default,
                    Values = Values,
                    Type = "Dropdown",
                    Text = Text,
                }
                local IsOpen = false

                local function RefreshOptions()
                    for _, Child in ipairs(ListFrame:GetChildren()) do
                        if Child:IsA("TextButton") then Child:Destroy() end
                    end
                    local Count = 0
                    for _, Value in ipairs(Values) do
                        Count = Count + 1
                        local IsSelected = false
                        if Multi and type(Dropdown.Value) == "table" then
                            IsSelected = table.find(Dropdown.Value, Value) ~= nil
                        else
                            IsSelected = Dropdown.Value == Value
                        end
                        local Opt = SwiftUI:Create("TextButton", {
                            BackgroundColor3 = IsSelected and SwiftUI.Theme.Accent or SwiftUI.Theme.Element,
                            Text = Value,
                            FontFace = SwiftUI.Font,
                            TextSize = 12,
                            TextColor3 = IsSelected and Color3.new(1,1,1) or SwiftUI.Theme.FontDim,
                            Size = UDim2.new(1, 0, 0, 24),
                            AutoButtonColor = false,
                            Parent = ListFrame,
                        })
                        SwiftUI:ApplyCorner(Opt, 0)
                        Opt.MouseButton1Click:Connect(function()
                            if Multi then
                                if type(Dropdown.Value) ~= "table" then Dropdown.Value = {} end
                                local Idx = table.find(Dropdown.Value, Value)
                                if Idx then table.remove(Dropdown.Value, Idx) else table.insert(Dropdown.Value, Value) end
                                SelectedLabel.Text = #Dropdown.Value > 0 and table.concat(Dropdown.Value, ", ") or "None"
                                RefreshOptions()
                                SwiftUI:SafeCallback(Callback, Dropdown.Value)
                            else
                                Dropdown.Value = Value
                                SelectedLabel.Text = Value
                                IsOpen = false
                                ListFrame.Visible = false
                                SwiftUI:Tween(Arrow, {Rotation = 90}, TweenInfoFast)
                                Holder.Size = UDim2.new(1, 0, 0, 44)
                                SwiftUI:SafeCallback(Callback, Value)
                                RefreshOptions()
                            end
                            if Id then SwiftUI.Options[Id] = Dropdown end
                        end)
                    end
                    ListFrame.CanvasSize = UDim2.new(0,0,0, Count * 26 + 8)
                end
                RefreshOptions()

                function Dropdown:SetValue(Value)
                    Dropdown.Value = Value
                    if Multi and type(Value) == "table" then
                        SelectedLabel.Text = #Value > 0 and table.concat(Value, ", ") or "None"
                    else
                        SelectedLabel.Text = tostring(Value)
                    end
                    RefreshOptions()
                    SwiftUI:SafeCallback(Callback, Value)
                end
                function Dropdown:OnChanged(Func) Callback = Func end
                function Dropdown:SetValues(NewValues)
                    Values = NewValues
                    Dropdown.Values = NewValues
                    RefreshOptions()
                end

                Button.MouseButton1Click:Connect(function()
                    IsOpen = not IsOpen
                    ListFrame.Visible = IsOpen
                    if IsOpen then
                        local Count = #Values
                        local Height = math.clamp(Count * 26 + 8, 0, 140)
                        ListFrame.Size = UDim2.new(1, 0, 0, Height)
                        Holder.Size = UDim2.new(1, 0, 0, 44 + Height + 6)
                        SwiftUI:Tween(Arrow, {Rotation = 270}, TweenInfoFast)
                    else
                        Holder.Size = UDim2.new(1, 0, 0, 44)
                        SwiftUI:Tween(Arrow, {Rotation = 90}, TweenInfoFast)
                    end
                    task.defer(AutoResize)
                end)

                if Id then SwiftUI.Options[Id] = Dropdown end
                table.insert(Groupbox.Elements, {Type = "Dropdown", Holder = Holder, Text = Text})
                task.defer(AutoResize)
                return Dropdown
            end

            function Groupbox:AddInput(Id, Config)
                if typeof(Id) == "table" then Config = Id; Id = Config.Text or "Input" end
                Config = Config or {}
                local Text = Config.Text or Id or "Input"
                local Default = Config.Default or ""
                local Placeholder = Config.Placeholder or Config.PlaceholderText or "Enter value..."
                local Numeric = Config.Numeric or false
                local Finished = Config.Finished or false
                local Callback = Config.Callback or Config.Changed or function() end

                local Holder = SwiftUI:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 44),
                    Parent = ContainerFrame,
                })
                SwiftUI:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = Text,
                    FontFace = SwiftUI.Font,
                    TextSize = 12,
                    TextColor3 = SwiftUI.Theme.FontDim,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 16),
                    Parent = Holder,
                })
                local BoxHolder = SwiftUI:Create("Frame", {
                    BackgroundColor3 = SwiftUI.Theme.Element,
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.new(0, 0, 0, 18),
                    Parent = Holder,
                })
                SwiftUI:ApplyCorner(BoxHolder, 0)
                SwiftUI:ApplyStroke(BoxHolder, SwiftUI.Theme.Outline, 1)
                local TextBox = SwiftUI:Create("TextBox", {
                    BackgroundTransparency = 1,
                    Text = Default,
                    PlaceholderText = Placeholder,
                    PlaceholderColor3 = SwiftUI.Theme.FontDark,
                    FontFace = SwiftUI.Font,
                    TextSize = 12,
                    TextColor3 = SwiftUI.Theme.Font,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = Config.ClearTextOnFocus or false,
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    Parent = BoxHolder,
                })

                local Input = {Value = Default, Type = "Input", Text = Text}

                function Input:SetValue(Value)
                    Input.Value = Value
                    TextBox.Text = Value
                    SwiftUI:SafeCallback(Callback, Value)
                end
                function Input:OnChanged(Func) Callback = Func end

                TextBox.FocusLost:Connect(function(EnterPressed)
                    if Finished and not EnterPressed then return end
                    local Value = TextBox.Text
                    if Numeric then
                        local Num = tonumber(Value)
                        if Num == nil and not Config.AllowEmpty then
                            TextBox.Text = tostring(Input.Value)
                            return
                        end
                        Value = Num or Value
                    end
                    Input.Value = Value
                    SwiftUI:SafeCallback(Callback, Value)
                    if Id then SwiftUI.Options[Id] = Input end
                end)
                TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                    if not Finished then
                        local Value = TextBox.Text
                        if Numeric and Value ~= "" and tonumber(Value) == nil then return end
                        Input.Value = Numeric and (tonumber(Value) or Value) or Value
                        SwiftUI:SafeCallback(Callback, Input.Value)
                    end
                end)

                if Id then SwiftUI.Options[Id] = Input end
                table.insert(Groupbox.Elements, {Type = "Input", Holder = Holder, Text = Text})
                task.defer(AutoResize)
                return Input
            end

            function Groupbox:AddColorPicker(Id, Config)
                if typeof(Id) == "table" then Config = Id; Id = Config.Text or "ColorPicker" end
                Config = Config or {}
                local Text = Config.Text or Id or "Color"
                local Default = Config.Default or Color3.fromRGB(124, 92, 255)
                local Callback = Config.Callback or Config.Changed or function() end

                local Holder = SwiftUI:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    Parent = ContainerFrame,
                })
                SwiftUI:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = Text,
                    FontFace = SwiftUI.Font,
                    TextSize = 12,
                    TextColor3 = SwiftUI.Theme.FontDim,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, -44, 1, 0),
                    Parent = Holder,
                })
                local Preview = SwiftUI:Create("Frame", {
                    BackgroundColor3 = Default,
                    Size = UDim2.fromOffset(28, 18),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Parent = Holder,
                })
                SwiftUI:ApplyCorner(Preview, 0)
                SwiftUI:ApplyStroke(Preview, SwiftUI.Theme.Outline, 1)
                local Button = SwiftUI:Create("TextButton", {
                    BackgroundTransparency = 1,
                    Text = "",
                    Size = UDim2.fromScale(1,1),
                    Parent = Holder,
                })

                local PickerOpen = false
                local PickerFrame
                local ColorPicker = {Value = Default, Type = "ColorPicker", Text = Text}

                function ColorPicker:SetValue(Value)
                    local OldAccent = SwiftUI.Theme.Accent
                    ColorPicker.Value = Value
                    Preview.BackgroundColor3 = Value
                    SwiftUI.Theme.Accent = Value
                    SwiftUI.Theme.AccentHover = Color3.fromRGB(
                        math.clamp(Value.R * 255 + 14, 0, 255),
                        math.clamp(Value.G * 255 + 14, 0, 255),
                        math.clamp(Value.B * 255 + 14, 0, 255)
                    )
                    for _, Desc in ipairs(SwiftUI.ScreenGui:GetDescendants()) do
                        if Desc:IsA("GuiObject") then
                            pcall(function()
                                if Desc.BackgroundColor3 == OldAccent then
                                    Desc.BackgroundColor3 = Value
                                end
                            end)
                        end
                    end
                    SwiftUI:SafeCallback(Callback, Value)
                    if Id then SwiftUI.Options[Id] = ColorPicker end
                end
                function ColorPicker:OnChanged(Func) Callback = Func end

                Button.MouseButton1Click:Connect(function()
                    PickerOpen = not PickerOpen
                    if PickerOpen then
                        if PickerFrame then PickerFrame:Destroy() end
                        PickerFrame = SwiftUI:Create("Frame", {
                            BackgroundColor3 = SwiftUI.Theme.Main,
                            Size = UDim2.fromOffset(162, 112),
                            Position = UDim2.new(1, -162, 0, 24),
                            ZIndex = 50,
                            Parent = Holder,
                        })
                        SwiftUI:ApplyCorner(PickerFrame, 0)
                        SwiftUI:ApplyStroke(PickerFrame, SwiftUI.Theme.Outline, 1)
                        SwiftUI:Create("UIPadding", {
                            PaddingTop = UDim.new(0, 8),
                            PaddingBottom = UDim.new(0, 8),
                            PaddingLeft = UDim.new(0, 8),
                            PaddingRight = UDim.new(0, 8),
                            Parent = PickerFrame,
                        })
                        SwiftUI:Create("UIListLayout", {
                            FillDirection = Enum.FillDirection.Vertical,
                            Padding = UDim.new(0, 6),
                            Parent = PickerFrame,
                        })
                        local Colors = {
                            Color3.fromRGB(124,92,255), Color3.fromRGB(46,204,113), Color3.fromRGB(52,152,219),
                            Color3.fromRGB(231,76,60), Color3.fromRGB(241,196,15), Color3.fromRGB(230,126,34),
                            Color3.fromRGB(255,255,255), Color3.fromRGB(150,150,150), Color3.fromRGB(0,0,0),
                        }
                        local Grid = SwiftUI:Create("Frame", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 60),
                            Parent = PickerFrame,
                        })
                        SwiftUI:Create("UIGridLayout", {
                            CellSize = UDim2.fromOffset(28, 28),
                            CellPadding = UDim2.fromOffset(6,6),
                            Parent = Grid,
                        })
                        for _, C in ipairs(Colors) do
                            local Btn = SwiftUI:Create("TextButton", {
                                BackgroundColor3 = C,
                                Text = "",
                                AutoButtonColor = false,
                                Parent = Grid,
                            })
                            SwiftUI:ApplyCorner(Btn, 0)
                            SwiftUI:ApplyStroke(Btn, SwiftUI.Theme.Outline, 1)
                            Btn.MouseButton1Click:Connect(function()
                                ColorPicker:SetValue(C)
                            end)
                        end
                        local RainbowBtn = SwiftUI:Create("TextButton", {
                            BackgroundColor3 = SwiftUI.Theme.Accent,
                            Text = "Rainbow",
                            FontFace = SwiftUI.FontBold,
                            TextSize = 11,
                            TextColor3 = Color3.new(1,1,1),
                            Size = UDim2.new(1, 0, 0, 24),
                            AutoButtonColor = false,
                            Parent = PickerFrame,
                        })
                        SwiftUI:ApplyCorner(RainbowBtn, 0)
                        RainbowBtn.MouseButton1Click:Connect(function()
                            local Hue = tick() % 5 / 5
                            local C = Color3.fromHSV(Hue, 0.8, 1)
                            ColorPicker:SetValue(C)
                        end)
                        Holder.Size = UDim2.new(1, 0, 0, 28 + 118)
                        task.defer(AutoResize)
                    else
                        if PickerFrame then PickerFrame:Destroy() PickerFrame=nil end
                        Holder.Size = UDim2.new(1, 0, 0, 28)
                        task.defer(AutoResize)
                    end
                end)

                if Id then SwiftUI.Options[Id] = ColorPicker end
                table.insert(Groupbox.Elements, {Type = "ColorPicker", Holder = Holder, Text = Text})
                task.defer(AutoResize)
                return ColorPicker
            end

            function Groupbox:AddKeyPicker(Id, Config)
                if typeof(Id) == "table" then Config = Id; Id = Config.Text or "KeyPicker" end
                Config = Config or {}
                local Text = Config.Text or Id or "Key"
                local Default = Config.Default or "None"
                local Mode = Config.Mode or "Toggle"
                local Callback = Config.Callback or Config.Changed or function() end
                local ChangedCallback = Config.ChangedCallback or function() end

                local Holder = SwiftUI:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    Parent = ContainerFrame,
                })
                SwiftUI:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = Text,
                    FontFace = SwiftUI.Font,
                    TextSize = 12,
                    TextColor3 = SwiftUI.Theme.FontDim,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, -80, 1, 0),
                    Parent = Holder,
                })
                local KeyButton = SwiftUI:Create("TextButton", {
                    BackgroundColor3 = SwiftUI.Theme.Element,
                    Text = typeof(Default) == "EnumItem" and Default.Name or tostring(Default),
                    FontFace = SwiftUI.FontCode,
                    TextSize = 11,
                    TextColor3 = SwiftUI.Theme.Font,
                    Size = UDim2.fromOffset(70, 20),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    AutoButtonColor = false,
                    Parent = Holder,
                })
                SwiftUI:ApplyCorner(KeyButton, 0)
                SwiftUI:ApplyStroke(KeyButton, SwiftUI.Theme.Outline, 1)

                local KeyPicker = {
                    Value = Default,
                    Toggled = false,
                    Mode = Mode,
                    Type = "KeyPicker",
                    Text = Text,
                }

                function KeyPicker:SetValue(Key, ModeValue)
                    KeyPicker.Value = Key
                    if ModeValue then KeyPicker.Mode = ModeValue end
                    local Name = typeof(Key) == "EnumItem" and Key.Name or tostring(Key)
                    KeyButton.Text = Name
                    SwiftUI:SafeCallback(Callback, Key)
                    SwiftUI:SafeCallback(ChangedCallback, Key)
                    if Id then SwiftUI.Options[Id] = KeyPicker end
                end
                function KeyPicker:OnChanged(Func) Callback = Func end
                function KeyPicker:OnClick(Func) ChangedCallback = Func end
                function KeyPicker:GetState() return KeyPicker.Toggled end
                function KeyPicker:SetState(State) KeyPicker.Toggled = State end

                local Listening = false
                local function UpdateToggledVisual()
                    if KeyPicker.Toggled then
                        KeyButton.BackgroundColor3 = SwiftUI.Theme.Accent
                        KeyButton.TextColor3 = Color3.new(1,1,1)
                    else
                        KeyButton.BackgroundColor3 = SwiftUI.Theme.Element
                        KeyButton.TextColor3 = SwiftUI.Theme.Font
                    end
                end

                KeyButton.MouseButton1Click:Connect(function()
                    if Listening then return end
                    Listening = true
                    KeyButton.Text = "..."
                    KeyButton.BackgroundColor3 = SwiftUI.Theme.Element
                    local Conn
                    Conn = SwiftUI:GiveSignal(UserInputService.InputBegan:Connect(function(Input, GameProcessed)
                        if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode ~= Enum.KeyCode.Unknown then
                            if Input.KeyCode == Enum.KeyCode.Escape then
                                KeyButton.Text = typeof(KeyPicker.Value) == "EnumItem" and KeyPicker.Value.Name or tostring(KeyPicker.Value)
                                Listening = false
                                Conn:Disconnect()
                                return
                            end
                            KeyPicker:SetValue(Input.KeyCode)
                            Listening = false
                            UpdateToggledVisual()
                            Conn:Disconnect()
                        end
                    end))
                end)

                if Mode == "Toggle" then
                    SwiftUI:GiveSignal(UserInputService.InputBegan:Connect(function(Input, GameProcessed)
                        if GameProcessed then return end
                        if typeof(KeyPicker.Value) == "EnumItem" and Input.KeyCode == KeyPicker.Value then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            UpdateToggledVisual()
                            SwiftUI:SafeCallback(ChangedCallback, KeyPicker.Toggled)
                        end
                    end))
                elseif Mode == "Hold" then
                    SwiftUI:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
                        if typeof(KeyPicker.Value) == "EnumItem" and Input.KeyCode == KeyPicker.Value then
                            KeyPicker.Toggled = true
                            UpdateToggledVisual()
                            SwiftUI:SafeCallback(ChangedCallback, true)
                        end
                    end))
                    SwiftUI:GiveSignal(UserInputService.InputEnded:Connect(function(Input)
                        if typeof(KeyPicker.Value) == "EnumItem" and Input.KeyCode == KeyPicker.Value then
                            KeyPicker.Toggled = false
                            UpdateToggledVisual()
                            SwiftUI:SafeCallback(ChangedCallback, false)
                        end
                    end))
                end
                UpdateToggledVisual()

                if Id then SwiftUI.Options[Id] = KeyPicker end
                table.insert(Groupbox.Elements, {Type = "KeyPicker", Holder = Holder, Text = Text})
                task.defer(AutoResize)
                return KeyPicker
            end

            table.insert(Tab.Groupboxes, Groupbox)
            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name)
            return CreateGroupbox(LeftColumn, Name)
        end
        function Tab:AddRightGroupbox(Name)
            return CreateGroupbox(RightColumn, Name)
        end
        function Tab:AddGroupbox(Name)
            return CreateGroupbox(LeftColumn, Name)
        end

        return Tab
    end

    table.insert(SwiftUI.Windows, Window)
    return Window
end

function SwiftUI:CreateLoading(Config)
    Config = Config or {}
    local Title = Config.Title or "Swift"
    local Window = self:CreateWindow({
        Title = Title,
        Footer = "Loading...",
        Size = UDim2.fromOffset(Config.WindowWidth or 420, Config.WindowHeight or 200),
        Center = true,
    })
    local Tab = Window:AddTab("Loading", "loader")
    local Group = Tab:AddLeftGroupbox("Status")
    local Label = Group:AddLabel(Config.Message or "Loading...")
    local BarHolder = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Element,
        Size = UDim2.new(1, 0, 0, 8),
        Parent = Group.Container,
    })
    self:ApplyCorner(BarHolder, 0)
    local BarFill = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Accent,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = BarHolder,
    })
    self:ApplyCorner(BarFill, 0)

    local Loading = {}
    function Loading:SetMessage(Text) Label:SetText(Text) end
    function Loading:SetDescription(Text) Label:SetText(Text) end
    function Loading:SetCurrentStep(Step) BarFill.Size = UDim2.new(math.clamp(Step/100,0,1), 0, 1, 0) end
    function Loading:Continue() task.delay(0.5, function() Window:Destroy() end) end
    return Loading
end

function SwiftUI:Unload()
    for _, Window in ipairs(self.Windows) do
        if Window.Container then Window.Container:Destroy() end
    end
    for _, Conn in ipairs(self.Signals) do
        pcall(function() Conn:Disconnect() end)
    end
    self.Unloaded = true
end

return SwiftUI
